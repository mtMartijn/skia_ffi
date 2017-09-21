local sk = require("sk.cdef")
local color = require("sk.color").new

local type = type

local paint = {}
paint.__index = paint

function paint.new()
  local p = {
    obj = sk.paint_new()
  }
  return setmetatable(p, paint)
end

function paint.color(self, r, g, b, a)
  if type(r) == "number" then
    sk.set_color(self.obj, color(r, g, b, a))
  else
    sk.set_color(self.obj, r)
  end
  return self
end

function paint.alpha(self, a)
  sk.set_alpha(self.obj, a)
  return self
end

function paint.style(self, s)
  sk.set_style(self.obj, s)
  return self
end

function paint.stroke_join(self, j)
  sk.set_stroke_join(self.obj, j)
  return self
end

function paint.stroke_cap(self, c)
  sk.set_stroke_cap(self.obj, c)
  return self
end

function paint.stroke_width(self, w)
  sk.set_stroke_width(self.obj, w)
  return self
end

-- This doesn't work in lua 5.1, need to recompile luaJIT so that it's 5.2 compatible
function paint.__gc(self)
  sk.paint_delete(self.obj)
end

return paint
