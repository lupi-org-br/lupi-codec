local bit = require("bit")

local TileDetector = {}

local MAGIC_COLOR_BGR555 = 8456

local function get_pixel_rgb(raw_data, x, y, w, bpp)
  bpp = bpp or 3
  local idx = ((y - 1) * w + (x - 1)) * bpp + 1
  if idx > #raw_data then return nil, nil, nil end
  return string.byte(raw_data, idx, idx + 2)
end

local function rgb_to_bgr555(r, g, b)
  local r5 = bit.rshift(bit.band(r, 0xFF), 3)
  local g5 = bit.rshift(bit.band(g, 0xFF), 3)
  local b5 = bit.rshift(bit.band(b, 0xFF), 3)
  return bit.bor(bit.bor(bit.lshift(b5, 10), bit.lshift(g5, 5)), r5)
end

local function scan_tile_width(raw_data, w, _h, bpp)
  for x = 1, w do
    local r, g, b = get_pixel_rgb(raw_data, x, 1, w, bpp)
    if not r then break end

    local color = rgb_to_bgr555(r, g, b)
    if color ~= MAGIC_COLOR_BGR555 then
      return x - 1
    end
  end
  return w
end

local function scan_tile_height(raw_data, w, h, bpp)
  for y = 1, h do
    local r, g, b = get_pixel_rgb(raw_data, 1, y, w, bpp)
    if not r then break end

    local color = rgb_to_bgr555(r, g, b)
    if color ~= MAGIC_COLOR_BGR555 then
      return y - 1
    end
  end
  return h
end

function TileDetector.detect_tiles(raw_data, w, h, bpp)
  bpp = bpp or 3
  local r, g, b = get_pixel_rgb(raw_data, 1, 1, w, bpp)
  if not r then return false, w, h end

  local top_left_color = rgb_to_bgr555(r, g, b)

  if top_left_color ~= MAGIC_COLOR_BGR555 then
    return false, w, h
  end

  local tile_w = scan_tile_width(raw_data, w, h, bpp)
  local tile_h = scan_tile_height(raw_data, w, h, bpp)

  if tile_w > 0 and tile_h > 0 then
    return true, tile_w, tile_h
  end

  return false, w, h
end

return TileDetector
