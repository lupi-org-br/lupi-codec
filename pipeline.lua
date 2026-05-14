local Codecs = require("codecs")
local json = require("dkjson")

local Pipeline = {}

local function get_file_size(path)
  local handle = io.popen("stat -c %s '" .. path .. "'")
  local size = handle:read("*a")
  handle:close()
  return tonumber(size) or 0
end

local function handle_result_new(res, release_path, ts_num, final_items)
  local res_path = release_path .. "/" .. res.path
  local out = io.open(res_path, "w")
  if out then
    out:write(res.content)
    out:close()
    local size = get_file_size(res_path)
    table.insert(final_items, { path = res.path, ts = ts_num, size = size, metadata = res.metadata })
  end
end

local function handle_result_keep(res, release_path, ts_num, final_items)
  local res_path = release_path .. "/" .. res.path
  local size = get_file_size(res_path)
  table.insert(final_items, { path = res.path, ts = ts_num, size = size, metadata = res.metadata })
end

local function handle_result_delete(res, release_path)
  local res_path = release_path .. "/" .. res.path
  os.remove(res_path)
end

local function handle_codec_results(results, release_path, ts_num, final_items)
  if not results then return end

  for _, res in ipairs(results) do
    if res.type == "NEW" then
      handle_result_new(res, release_path, ts_num, final_items)
    elseif res.type == "KEEP" then
      handle_result_keep(res, release_path, ts_num, final_items)
    elseif res.type == "DELETE" then
      handle_result_delete(res, release_path)
    end
  end
end

local function process_file(release_path, ts, path, context, final_items)
  local full_path = release_path .. "/" .. path
  local codec = Codecs.get_codec(path, full_path)
  local ts_num = tonumber(ts)

  local results = codec.process(full_path, path, context)
  handle_codec_results(results, release_path, ts_num, final_items)
end

function Pipeline.load_master_palette(repo_root)
  local path = repo_root .. "/master_palette.json"
  local f = io.open(path, "r")
  if not f then return {} end
  local content = f:read("*all")
  f:close()
  local ok, data = pcall(json.decode, content)
  return ok and data or {}
end

function Pipeline.run_transformations(release_path, repo_root)
  local master_palette = Pipeline.load_master_palette(repo_root)
  local context = {
    palette = master_palette,
    color_cache = {},
    repo_id = nil
  }

  local final_items = {}
  local manifest_file = io.open(release_path .. "/lupi_manifest.txt", "r")

  if manifest_file then
    for line in manifest_file:lines() do
      local ts, path = line:match("^(%d+) (.+)$")
      if ts and path then
        process_file(release_path, ts, path, context, final_items)
      end
    end
    manifest_file:close()
  end

  return final_items, master_palette
end

return Pipeline
