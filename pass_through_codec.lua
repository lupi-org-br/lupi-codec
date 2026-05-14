local PassThroughCodec = {}

function PassThroughCodec.process(_filepath, relative_path, _context)
  local path = relative_path
  return {
    { type = "KEEP", path = path, metadata = { type = "lua_code" } }
  }
end

return PassThroughCodec
