local json = require("dkjson")

local Validator = {}

function Validator.is_tiled_map(path)
  if not path then return false end
  local f = io.open(path, "r")
  if not f then return false end
  local content = f:read("*a")
  f:close()

  local is_likely_tiled = content:match('"tiledversion"') and content:match('"type"%s*:%s*"map"')
  if not is_likely_tiled then
    return false
  end

  local ok, data = pcall(json.decode, content)
  if not ok then return false end
  return data.tiledversion and data.type == "map"
end

local function raise_error(msg)
  error(msg)
end

function Validator.validate_map_attributes(map)
  if map.compressionlevel ~= -1 then
    raise_error("Ops! Apenas mapas sem compressao (csv) sao suportados")
  end

  if map.infinite then
    raise_error("Ops! Mapas infinitos nao sao suportados")
  end

  if map.orientation ~= "orthogonal" then
    raise_error("Ops! Apenas mapas com orientacao ortogonal sao suportados")
  end

  if map.renderorder ~= "right-down" then
    raise_error("Ops! Apenas mapas com render order right-down sao suportados")
  end

  if map.type ~= "map" then
    raise_error("Ops! Apenas mapas sao suportados")
  end
end

function Validator.validate_layer_attributes(layer)
  if layer.type ~= "tilelayer" then
    raise_error("Ops! Apenas camadas de tile sao suportadas")
  end

  if layer.x ~= 0 or layer.y ~= 0 then
    raise_error("Ops! O mapa precisa comecar em x = 0 e y = 0")
  end
end

local function validate_tileset_image(tileset)
  if tileset.imagewidth * tileset.imageheight > 512 * 96 then
    raise_error("Ops! O tamanho da imagem do tileset excede o limite de 49 mil pixels")
  end

  if not tileset.image:match("%.png$") then
    raise_error("Ops! Apenas tilesets .png sao suportados")
  end

  if not tileset.image:match("^[%w_]+%.png$") or #tileset.image > 32 then
    raise_error("Ops! O nome da imagem do tileset " .. tileset.image .. " deve conter apenas letras, numeros\ne underline e ter menos de 24 caracteres")
  end
end

local function validate_tileset_metrics(tileset)
  local is_square = tileset.tileheight == tileset.tilewidth
  local has_margin = tileset.tileheight == tileset.margin

  if not is_square or not has_margin then
    raise_error("Ops! Apenas tilesets com tileheight, tilewidth e margin iguais sao suportados\nOs tiles precisam ser quadrados e com margem configurada")
  end

  if tileset.spacing ~= 0 then
    raise_error("Ops! Apenas tilesets com spacing igual a zero sao suportados")
  end
end

function Validator.validate_tileset(tileset)
  validate_tileset_metrics(tileset)
  validate_tileset_image(tileset)
end

local RESERVED_LAYER_NAMES = { metadata = true, tilesets = true }

function Validator.validate_reserved_layer_names(layers)
  for _, layer in ipairs(layers) do
    if RESERVED_LAYER_NAMES[layer.name] then
      raise_error(string.format(
        "Ops! O nome '%s' eh reservado e nao pode ser usado como nome de camada",
        layer.name
      ))
    end
  end
end

function Validator.validate_tileset_name(tileset)
  if not tileset.name or tileset.name == "" then
    raise_error("Ops! Cada tileset precisa ter um nome definido no Tiled")
  end
end

return Validator
