local Colors = require("colors_manager")
local Manifest = require("manifest")
local Pipeline = require("pipeline")

local function ensure_dir(path)
  os.execute("mkdir -p '" .. path .. "'")
end

local function copy_file(src, dst)
  ensure_dir(dst:match("(.*/)") or ".")
  os.execute(string.format("cp '%s' '%s'", src, dst))
end

local function is_hidden_file(name)
  return name:match("^%.") ~= nil
end

local function list_files_recursive(dir, prefix, result)
  prefix = prefix or ""
  result = result or {}
  local handle = io.popen("ls -A '" .. dir .. "'")
  if not handle then return result end

  for name in handle:lines() do
    if not is_hidden_file(name) then
      local full_path = dir .. "/" .. name
      local rel_path = prefix .. name
      local attr = io.popen("test -d '" .. full_path .. "' && echo dir || echo file"):read("*a")
      if attr:match("dir") then
        list_files_recursive(full_path, rel_path .. "/", result)
      else
        table.insert(result, rel_path)
      end
    end
  end
  handle:close()
  return result
end

local function get_file_mtime(path)
  local handle = io.popen("stat -c %Y '" .. path .. "'")
  if not handle then return 0 end
  local mtime = handle:read("*a")
  handle:close()
  return tonumber(mtime) or 0
end

local function collect_png_files(release_path, files)
  local pngs = {}
  for _, path in ipairs(files) do
    if path:match("%.png$") then
      table.insert(pngs, release_path .. "/" .. path)
    end
  end
  return pngs
end

local function generate_manifest_entries(release_path, files)
  local entries = {}
  for _, path in ipairs(files) do
    local mtime = get_file_mtime(release_path .. "/" .. path)
    table.insert(entries, { ts = mtime, path = path })
  end
  return entries
end

local function perform_atomic_swap(output_dir, release_path)
  local current_link = output_dir .. "/current"
  local tmp_link = output_dir .. "/current_tmp"
  os.execute(string.format("ln -sfn %s %s && mv -Tf %s %s", release_path, tmp_link, tmp_link, current_link))
end

local function main()
  local input_dir = arg[1]
  local output_dir = arg[2]

  if not input_dir or not output_dir then
    print("Uso: lua run.lua <input_dir> <output_dir>")
    os.exit(1)
  end

  local release_path = output_dir .. "/releases/" .. os.time()
  ensure_dir(release_path)

  local files = list_files_recursive(input_dir)
  for _, path in ipairs(files) do
    copy_file(input_dir .. "/" .. path, release_path .. "/" .. path)
  end

  local png_files = collect_png_files(release_path, files)
  Colors.update_palette(output_dir, png_files)

  local manifest_entries = generate_manifest_entries(release_path, files)
  Manifest.generate_source_list_from_files(manifest_entries, release_path)

  local final_items, master_palette = Pipeline.run_transformations(release_path, output_dir)

  local version = 1
  local pal_item = Colors.generate_lua_map(master_palette, release_path, version)
  table.insert(final_items, pal_item)

  Manifest.save_final(final_items, release_path)
  perform_atomic_swap(output_dir, release_path)

  print("Processamento concluido. Release em: " .. release_path)
end

main()
