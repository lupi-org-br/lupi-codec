local Extract = {}

local function parse_rgb555_quantized_color_line(line)
  local r, g, b = line:match("%((%d+),(%d+),(%d+)")
  if r and g and b then
    return tonumber(r), tonumber(g), tonumber(b)
  end
  return nil
end

local function build_rgb555_scan_command(file_path)
  return string.format(
    "magick '%s' -background white -flatten -unique-colors -depth 5 txt:-",
    file_path
  )
end

function Extract.scan_file(file_path)
  local cmd = build_rgb555_scan_command(file_path)
  local handle = io.popen(cmd)
  if not handle then return {} end

  local colors = {}
  for line in handle:lines() do
    local r, g, b = parse_rgb555_quantized_color_line(line)
    if r then
      table.insert(colors, {r = r, g = g, b = b})
    end
  end
  handle:close()

  return colors
end

return Extract
