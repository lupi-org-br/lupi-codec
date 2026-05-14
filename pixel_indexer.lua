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

  return add_new_color(context, hex, key)
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
