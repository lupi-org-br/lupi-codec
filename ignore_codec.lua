local IgnoreCodec = {}

function IgnoreCodec.process(_filepath, relative_path, _context)
  local path = relative_path
  return {
    { type = "DELETE", path = path }
  }
end

return IgnoreCodec
