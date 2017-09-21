local sk = require("sk.cdef")
local ffi = require("ffi")

local input = {}
input.__index = input
input._type = "input"

ffi.metatype("mouse_info", input)

return input
