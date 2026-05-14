local Generator = {}

local function append_metadata(output, map)
  output[#output+1] = "local _metadata = {"
  output[#output+1] = string.format("  width = %d,", map.width)
  output[#output+1] = string.format("  height = %d,", map.height)
  output[#output+1] = string.format("  tile_size = %d,", map.tilewidth)
  output[#output+1] = "}"
end

local function append_tilesets(output, tileset_dictionary)
  output[#output+1] = "local _tilesets = {"
  for name, image in pairs(tileset_dictionary) do
    output[#output+1] = string.format("  [%q] = %q,", name, image)
  end
  output[#output+1] = "}"
end

local function append_tileset_tiles(output, tileset_name, tiles)
  output[#output+1] = "  [" .. string.format("%q", tileset_name) .. "] = {"
  for i, tile_id in pairs(tiles) do
    output[#output+1] = "    [" .. i .. "] = " .. tile_id .. ","
  end
  output[#output+1] = "  },"
end

local function append_layer(output, layer)
  local quoted_name = string.format("%q", layer.name)
  output[#output+1] = "_M[" .. quoted_name .. "] = {"
  for tileset_name, tiles in pairs(layer.data) do
    append_tileset_tiles(output, tileset_name, tiles)
  end
  output[#output+1] = "}"
end

local function append_shared_references(output, layers_data)
  output[#output+1] = "_M.metadata = _metadata"
  output[#output+1] = "_M.tilesets = _tilesets"

  for _, layer in ipairs(layers_data) do
    local quoted_name = string.format("%q", layer.name)
    output[#output+1] = "_M[" .. quoted_name .. "].metadata = _metadata"
    output[#output+1] = "_M[" .. quoted_name .. "].tilesets = _tilesets"
  end
end

function Generator.generate_lua_map_string(map, layers_data, tileset_dictionary)
  local output = { "local _M = {}" }

  append_metadata(output, map)
  append_tilesets(output, tileset_dictionary)

  for _, layer in ipairs(layers_data) do
    append_layer(output, layer)
  end

  append_shared_references(output, layers_data)

  output[#output+1] = "return _M"
  return table.concat(output, "\n")
end

return Generator
