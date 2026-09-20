local bit = require("bit")
local Convert = require("colors_convert")

local PixelIndexer = {}

local function ensure_lookup(context)
  if context.palette_lookup then return end
  context.palette_lookup = {}

  for i = 2, #context.palette do
    local hex = context.palette[i]
    if not context.palette_lookup[hex] then
      context.palette_lookup[hex] = i
    end
  end
end

local function add_new_color(context, hex, key)
  table.insert(context.palette, hex)

  local qr, qg, qb = Convert.parse_hex_color(hex)
  table.insert(context.palette_rgb, {r=qr, g=qg, b=qb})

  local idx = #context.palette
  context.palette_lookup[hex] = idx
  context.color_cache[key] = idx

  return idx
end

local function nearest_index(context, r, g, b)
  local best_i, best_d = 1, math.huge
  for i = 2, #context.palette_rgb do
    local c = context.palette_rgb[i]
    local d = Convert.color_dist_sq(r, g, b, c.r, c.g, c.b)
    if d < best_d then
      best_d = d
      best_i = i
    end
  end
  return best_i
end

function PixelIndexer.get_index(r, g, b, a, context)
  local is_transparent = a == 0
  if is_transparent then
    return 1
  end

  local key = bit.bor(bit.bor(bit.lshift(r, 16), bit.lshift(g, 8)), b)
  local cached_idx = context.color_cache[key]

  if cached_idx then return cached_idx end

  local bgr555 = Convert.rgb_to_bgr555(r, g, b)
  local hex = Convert.to_hex_string(bgr555)

  ensure_lookup(context)

  local existing_idx = context.palette_lookup[hex]
  if existing_idx then
    context.color_cache[key] = existing_idx
    return existing_idx
  end

  -- Scan (magick -depth 5 -flatten) and encode (RGBA 8-bit) disagree, so
  -- unmatched pixels used to grow the palette past 256 and crash string.char.
  local qr, qg, qb = Convert.parse_hex_color(hex)
  local idx
  if #context.palette < 256 then
    idx = add_new_color(context, hex, key)
  else
    idx = nearest_index(context, qr, qg, qb)
    context.palette_lookup[hex] = idx
    context.color_cache[key] = idx
  end
  return idx
end

function PixelIndexer.ensure_palette_rgb(context)
  if context.palette_rgb then return end
  context.palette_rgb = {}
  context.palette = context.palette or {}

  for i, hex in ipairs(context.palette) do
    local r, g, b = Convert.parse_hex_color(hex)
    context.palette_rgb[i] = {r=r, g=g, b=b}
  end
  ensure_lookup(context)
end

return PixelIndexer
