local bit = require("bit")
local Validator = require("tiled_validator")

local Processor = {}

local function tiled_id_to_lupi_id(gid)
  local flipped_horizontally = bit.band(gid, 0x80000000) ~= 0
  local flipped_vertically = bit.band(gid, 0x40000000) ~= 0
  local tile_id = bit.band(gid, 0x1FFFFFFF)

  local h_flip = flipped_horizontally and 1024 or 0
  local v_flip = flipped_vertically and 2048 or 0

  return tile_id + h_flip + v_flip
end

local function raise_error(msg)
  error(msg)
end

local function strip_png_extension(filename)
  return filename:sub(1, #filename - 4)
end

function Processor.process_tilesets(map)
  local sorted_tilesets = {}
  local tileset_dictionary = {}

  for _, tileset in ipairs(map.tilesets) do
    Validator.validate_tileset(tileset)
    Validator.validate_tileset_name(tileset)

    local image_without_extension = strip_png_extension(tileset.image)

    table.insert(sorted_tilesets, {
      name = tileset.name,
      image = image_without_extension,
      start = tileset.firstgid,
    })

    tileset_dictionary[tileset.name] = image_without_extension
  end

  table.sort(sorted_tilesets, function(a, b) return a.start > b.start end)
  return sorted_tilesets, tileset_dictionary
end

local function find_tileset_for_gid(gid, sorted_tilesets)
  local gid_base = bit.band(gid, 0x3FF)
  for _, tileset in ipairs(sorted_tilesets) do
    if gid_base >= tileset.start then
      return tileset
    end
  end
  raise_error(string.format("Ops! GID %d nao encontrado", gid))
end

function Processor.process_layer_data(layer, sorted_tilesets)
  local data = {}
  for i, gid in pairs(layer.data) do
    if gid > 0 then
      local tileset = find_tileset_for_gid(gid, sorted_tilesets)
      local tile_id = tiled_id_to_lupi_id(gid - tileset.start)

      data[tileset.name] = data[tileset.name] or {}
      data[tileset.name][i] = tile_id
    end
  end
  return data
end

return Processor
