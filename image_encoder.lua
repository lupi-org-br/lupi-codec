local PixelIndexer = require("pixel_indexer")

local ImageEncoder = {}

local function encode_pixel_at(raw_data, idx, context)
  local r, g, b, a = string.byte(raw_data, idx, idx+3)

  if r and g and b and a then
    local index = PixelIndexer.get_index(r, g, b, a, context)
    return string.char(index - 1)
  end
  return nil
end

local function encode_linear_pixels(raw_data, context)
  local pixels = {}

  for i = 1, #raw_data, 4 do
    local pixel = encode_pixel_at(raw_data, i, context)
    if pixel then
      table.insert(pixels, pixel)
    end
  end
  return pixels
end

local function encode_single_tile(raw_data, w, tile_x, tile_y, tile_w, tile_h, context)
  local pixels = {}

  for row = 1, tile_h do
    for col = 1, tile_w do
      local pixel_y = tile_y * tile_h + row
      local pixel_x = tile_x * tile_w + col

      local idx = ((pixel_y - 1) * w + (pixel_x - 1)) * 4 + 1
      local pixel = encode_pixel_at(raw_data, idx, context)

      if pixel then
        table.insert(pixels, pixel)
      end
    end
  end
  return pixels
end

local function encode_tiled_pixels(raw_data, w, h, tile_w, tile_h, context)
  local pixels = {}
  local num_tiles_x = math.floor(w / tile_w)
  local num_tiles_y = math.floor(h / tile_h)

  for tile_y = 0, num_tiles_y - 1 do
    for tile_x = 0, num_tiles_x - 1 do
      local is_margin = tile_x == 0 or tile_y == 0

      if not is_margin then
        local tile_pixels = encode_single_tile(raw_data, w, tile_x, tile_y, tile_w, tile_h, context)
        for _, pixel in ipairs(tile_pixels) do
          table.insert(pixels, pixel)
        end
      end
    end
  end
  return pixels
end

function ImageEncoder.encode(w, h, tile_w, tile_h, raw_data, context, is_tiled)
  local pixels
  if is_tiled then
    pixels = encode_tiled_pixels(raw_data, w, h, tile_w, tile_h, context)
  else
    pixels = encode_linear_pixels(raw_data, context)
  end
  return table.concat(pixels)
end

return ImageEncoder
