local ImageValidator = require("image_validator")

local ImageReader = {}

function ImageReader.read_rgba(filepath)
  local cmd = string.format("magick '%s' -depth 8 RGBA:-", filepath)
  local p_handle = io.popen(cmd, "r")

  if not p_handle then return nil end

  local raw_data = p_handle:read("*all")
  p_handle:close()
  return raw_data
end

function ImageReader.validate(filepath, path)
  local w, h = ImageValidator.check_dimensions(filepath, path)
  if not w then return nil, nil, { { type = "DELETE", path = path } } end

  if not ImageValidator.check_colors(filepath, path) then
    return nil, nil, { { type = "DELETE", path = path } }
  end
  return w, h, nil
end

return ImageReader
