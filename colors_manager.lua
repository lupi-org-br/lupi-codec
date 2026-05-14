local json = require("dkjson")
local Extract = require("colors_extract")
local Convert = require("colors_convert")

local Manager = {}

local TRANSPARENT_COLOR_SENTINEL = "0x0000"

local function build_palette_with_transparency_sentinel(raw_palette)
  local palette = { TRANSPARENT_COLOR_SENTINEL }
  local existing = { [TRANSPARENT_COLOR_SENTINEL] = true }

  for _, color in ipairs(raw_palette) do
    local is_not_duplicate = not existing[color]
    local is_not_sentinel = color ~= TRANSPARENT_COLOR_SENTINEL
    if is_not_duplicate and is_not_sentinel then
      table.insert(palette, color)
      existing[color] = true
    end
  end

  return palette, existing
end

function Manager.load_palette(path)
  local f = io.open(path, "r")
  if not f then return {} end

  local content = f:read("*all")
  f:close()

  local ok, data = pcall(json.decode, content)
  if not ok then return {} end
  return data
end

local function save_palette(path, palette)
  local f = io.open(path, "w")
  if not f then return false end
  f:write(json.encode(palette))
  f:close()
  return true
end

function Manager.update_palette(repo_root, files)
  local palette_path = repo_root .. "/master_palette.json"
  local raw_palette = Manager.load_palette(palette_path)
  local palette, existing = build_palette_with_transparency_sentinel(raw_palette)

  for _, file_path in ipairs(files) do
    local colors = Extract.scan_file(file_path)
    for _, c in ipairs(colors) do
      local bgr555 = Convert.rgb_to_bgr555(c.r, c.g, c.b)
      local hex_str = Convert.to_hex_string(bgr555)

      if not existing[hex_str] then
        table.insert(palette, hex_str)
        existing[hex_str] = true
      end
    end
  end

  local palette_exceeds_lupi_limit = #palette > 256
  if palette_exceeds_lupi_limit then
    print("[ColorsManager] Palette size exceeds 256 colors for repo: " .. repo_root)
  end

  save_palette(palette_path, palette)
  return true
end

function Manager.generate_lua_map(palette, release_path, version)
  local lines = {}
  table.insert(lines, "Palette = {")
  for i, color in ipairs(palette) do
    table.insert(lines, string.format("  [%d] = %s,", i, color))
  end
  table.insert(lines, "}")

  local p_path = "palette.lua"
  local f = io.open(release_path .. "/" .. p_path, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
  end

  local handle = io.popen("stat -c %s '" .. release_path .. "/" .. p_path .. "'")
  local size = handle:read("*a")
  handle:close()

  return {
    path = p_path,
    ts = version,
    size = tonumber(size) or 0,
    metadata = { type = "lua_code" }
  }
end

return Manager
