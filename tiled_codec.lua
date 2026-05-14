local json = require("dkjson")
local Validator = require("tiled_validator")
local Processor = require("tiled_processor")
local Generator = require("tiled_generator")

local TiledCodec = {}

function TiledCodec.process(filepath, relative_path, _context)
  local path = relative_path
  local f = io.open(filepath, "rb")
  if not f then return nil end
  local content = f:read("*all")
  f:close()

  local map = json.decode(content)
  Validator.validate_map_attributes(map)
  Validator.validate_reserved_layer_names(map.layers)

  local sorted_tilesets, tileset_dictionary = Processor.process_tilesets(map)
  local processed_layers = {}

  for _, layer in ipairs(map.layers) do
    Validator.validate_layer_attributes(layer)
    local data = Processor.process_layer_data(layer, sorted_tilesets)
    table.insert(processed_layers, { name = layer.name, data = data })
  end

  local lua_content = Generator.generate_lua_map_string(
    map, processed_layers, tileset_dictionary
  )

  return {
    { type = "DELETE", path = path },
    {
      type = "NEW",
      path = path:gsub("%.json$", ".lua"),
      content = lua_content,
      metadata = {
        type = "lua_code"
      }
    }
  }
end

return TiledCodec
