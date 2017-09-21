local sk = require("sk.cdef")
local ffi = require("ffi")

local type, format, sqrt = type, string.format, math.sqrt

local point = {}
point.__index = point
point._type = "point"

ffi.metatype("point", point)

function point.new(x, y)
    return ffi.new("point", x or 0, y or 0)
end

function point.copy(self)
    return point.new(self.x, self.y)
end

function point.__add(a, b)
    return point.new(a.x + b.x, a.y + b.y)
end

function point.__sub(a, b)
    return point.new(a.x - b.x, a.y - b.y)
end

function point.__mul(a, b)
    if type(a) == "number" and type(b) == "cdata" then
        return point.new(b.x * a, b.y * a)
    elseif type(b) == "number" and type(a) == "cdata" then
        return point.new(a.x * b, a.y * b)
    end
end

function point.__div(a, b)
    return point.new(a.x/b, a.y/b)
end

function point.dot(a, b)
    return a.x*b.x + a.y*b.y
end

function point.length(self)
    return sqrt(self.x*self.x + self.y*self.y)
end

function point.mag(self)
    return self.x*self.x + self.y*self.y
end

function point.dist(a, b)
    return point.length(a - b)
end

function point.X(self)
    return point.new(self.x, 0)
end

function point.Y(self)
    return point.new(0, self.y)
end

function point.Ymirror(self)
    return point.new(self.x, -self.y)
end

function point.__tostring(self)
    return format("P(%i, %i)", self.x, self.y)
end

return setmetatable(point, { __call = function(_, x, y) return point.new(x, y) end })
