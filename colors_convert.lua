local bit = require("bit")

local Convert = {}

function Convert.rgb_to_bgr555(r, g, b)
  local r5 = bit.rshift(bit.band(r, 0xFF), 3)
  local g5 = bit.rshift(bit.band(g, 0xFF), 3)
  local b5 = bit.rshift(bit.band(b, 0xFF), 3)

  return bit.bor(
    bit.bor(
      bit.lshift(b5, 10),
      bit.lshift(g5, 5)
    ),
    r5
  )
end

function Convert.to_hex_string(val)
  return string.format("0x%04X", val)
end

local function expand_5to8(val)
  return bit.bor(bit.lshift(val, 3), bit.rshift(val, 2))
end

function Convert.parse_hex_color(hex_str)
  local val = tonumber(hex_str)
  if not val then return 0, 0, 0 end

  local b5 = bit.band(bit.rshift(val, 10), 0x1F)
  local g5 = bit.band(bit.rshift(val, 5), 0x1F)
  local r5 = bit.band(val, 0x1F)

  return expand_5to8(r5), expand_5to8(g5), expand_5to8(b5)
end

function Convert.color_dist_sq(r1, g1, b1, r2, g2, b2)
  local dr, dg, db = r1 - r2, g1 - g2, b1 - b2
  return dr*dr + dg*dg + db*db
end

return Convert
