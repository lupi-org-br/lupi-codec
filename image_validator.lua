local ImageValidator = {}

function ImageValidator.check_dimensions(filepath, path)
  local handle = io.popen(string.format("magick identify -format '%%w %%h' '%s'", filepath))
  local dim_str = handle:read("*a")
  handle:close()

  local w, h = dim_str:match("(%d+) (%d+)")
  w, h = tonumber(w), tonumber(h)

  if not w or not h then
    print("[ImageValidator] Failed to read dimensions for: " .. path)
    return nil, nil
  end

  if w > 512 or h > 512 then
    print("[ImageValidator] Image too large ("..w.."x"..h.."): " .. path)
    return nil, nil
  end

  return w, h
end

function ImageValidator.check_colors(filepath, path)
  local handle = io.popen(string.format("magick identify -format '%%k' '%s'", filepath))
  local count_str = handle:read("*a")
  handle:close()

  local colors_count = tonumber(count_str)

  if colors_count and colors_count > 256 then
    print("[ImageValidator] Too many colors ("..colors_count.."): " .. path)
    return false
  end
  return true
end

return ImageValidator
