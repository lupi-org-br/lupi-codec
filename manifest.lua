local json = require("dkjson")

local Manifest = {}

function Manifest.generate_source_list_from_files(files_with_ts, release_path)
  local f = io.open(release_path .. "/lupi_manifest.txt", "w")
  if not f then return false end

  for _, entry in ipairs(files_with_ts) do
    f:write(string.format("%d %s\n", entry.ts, entry.path))
  end

  f:close()
  return true
end

function Manifest.save_final(items, release_path)
  table.sort(items, function(a, b)
    if a.ts == b.ts then
      return a.path < b.path
    end
    return a.ts < b.ts
  end)

  local f = io.open(release_path .. "/lupi_manifest.txt", "w")
  if not f then return false end

  local seen_timestamps = {}

  for _, item in ipairs(items) do
    local ts = tonumber(item.ts)
    if not seen_timestamps[ts] then
      seen_timestamps[ts] = 0
    end

    local index = seen_timestamps[ts]
    seen_timestamps[ts] = seen_timestamps[ts] + 1

    local cursor = (ts * 10000) + index
    local size = item.size or 0
    local meta_json = "{}"
    if item.metadata then
       local ok, json_str = pcall(json.encode, item.metadata)
       if ok then meta_json = json_str end
    end

    f:write(string.format("%d %d %s %s\n", cursor, size, item.path, meta_json))
  end

  f:close()
  return true
end

return Manifest
