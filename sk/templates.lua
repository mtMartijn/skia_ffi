local canvas = require("sk.canvas")
local P = require("sk.point")
local color = require("sk.color")

local sin, cos, pi, floor, sqrt = math.sin, math.cos, math.pi, math.floor, math.sqrt
local COL = color.new

canvas.record({
  name = "node_link", 
  args = { "A", "B", "offset" },
  call = function(self) 
    local A = self.args.A
    local B = self.args.B
    local offset = P(self.args.offset, 0)
    self:shape("path"):move_to(A):cubic_to(A + offset, B - offset, B)
    self:shape("circle", { A, 3 })
    self:shape("circle", { B, 3 })
  end,
})

canvas.record({
  name = "hexagon",
  args = { "pos", "size" },
  call = function(self)

    local function hex(i)
      local cs = cos(pi*2/6*i)
      local sn = sin(pi*2/6*i)
      return P(sn, cs)
    end

    local r = self.args.size
    local pos = self.args.pos
    self:shape("path")
      :move_to(pos + r*hex(0))
      :line_to(pos + r*hex(1))
      :line_to(pos + r*hex(2))
      :line_to(pos + r*hex(3))
      :line_to(pos + r*hex(4))
      :line_to(pos + r*hex(5))
      :close()
  end,
})

canvas.record({
  name = "hex_grid",
  args = { "x", "y", "z", "radius", "margin" },
  call = function(self)
    self:draw("hexagon", { P(0, 0), 60 })
  end,
})

canvas.record({ 
  name = "triangle",
  args = { "pos", "size", "angle" },
  call = function(self)
    self:style("fill", { COL(0.8, 1, 0.4) })

    local pos = self.args.pos
    local size = self.args.size
    local angle = self.args.angle

    local h = size * (sqrt(3)/2)

    self:transform("save")

    self:transform("translate", { pos })
    self:transform("rotate", { angle })
    self:shape("path"):move_to(P(h, 0)):line_to(P(0, size/2)):line_to(P(0, -size/2)):close()

    self:transform("restore")
  end,
})

canvas.record({
  name = "grid",
  args = { "corner", "size", "spacing" },
  call = function(self)
    self:style("stroke", { COL(0.5, 0.5, 0.5, 0.2), 1 })
    local w, h = self.args.size:decompose()
    local x_off, y_off = self.args.corner:decompose()
    local unit = self.args.spacing

    for i=0, floor(w/unit) do
      self:shape("arrow", { P(x_off + i*unit, y_off), P(0, h) })
    end

    for i=0, floor(h/unit) do
      self:shape("arrow", { P(x_off, y_off + i*unit), P(w, 0) })
    end
  end,
})
