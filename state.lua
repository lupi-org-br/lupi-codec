local State = {}

function State.get_last_commit(repo_root)
  local f = io.open(repo_root .. "/last_processed_commit.txt", "r")
  if not f then return nil end
  local hash = f:read("*a")
  f:close()
  if hash then hash = hash:gsub("%s+", "") end
  return hash
end

function State.save_last_commit(repo_root, hash)
  local f = io.open(repo_root .. "/last_processed_commit.txt", "w")
  if not f then return false end
  f:write(hash)
  f:close()
  return true
end

return State
