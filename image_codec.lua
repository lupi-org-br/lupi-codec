local ImageReader = require("image_reader")
local PixelIndexer = require("pixel_indexer")
local ImageEncoder = require("image_encoder")
local TileDetector = require("tile_detector")

local ImageCodec = {}

local function build_metadata(w, h, is_tiled, tile_w, tile_h)
  local metadata = { type = "bitmap", width = w, height = h }

  if is_tiled then
    local tiles_count = math.floor(w / tile_w) * math.floor(h / tile_h)
    metadata.width = tile_w
    metadata.height = tile_h
    metadata.tiles = tiles_count
  end

  return metadata
end

function ImageCodec.process(filepath, relative_path, context)
  local w, h, error_res = ImageReader.validate(filepath, relative_path)
  if error_res then return error_res end

  PixelIndexer.ensure_palette_rgb(context)

  local raw_data = ImageReader.read_rgba(filepath)
  if not raw_data then return nil end

  local is_tiled, tile_w, tile_h = TileDetector.detect_tiles(raw_data, w, h, 4)
  local content = ImageEncoder.encode(w, h, tile_w, tile_h, raw_data, context, is_tiled)
  local metadata = build_metadata(w, h, is_tiled, tile_w, tile_h)

  local artifact = {
      type = "NEW",
      path = relative_path:gsub("%.png$", ""),
      content = content,
      metadata = metadata
  }

  local delete_artifact = {
      type = "DELETE",
      path = relative_path
  }

  return { delete_artifact, artifact }
end

return ImageCodec
