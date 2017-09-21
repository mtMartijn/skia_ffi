local sk = require("sk.cdef")
local ffi = require("ffi")

local color = {}
color.__index = color
color._type = "color"

ffi.metatype("rgba", color)

function color.new(r, g, b, a)
    return ffi.new("rgba", r, g, b, a or 1)
end

return color
