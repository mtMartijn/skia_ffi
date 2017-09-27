local canvas = require("sk.canvas")
local P = require("sk.point")
local color = require("sk.color")

local sin, cos, pi, floor, sqrt = math.sin, math.cos, math.pi, math.floor, math.sqrt
local COL = color.new

canvas.record({
  name = "node_link", 
  args = { "A", "B", "offset", "radius" },
  call = function(self) 
    local A = self.args.A
    local B = self.args.B
    local offset = P(self.args.offset, 0)
    local radius = self.args.radius
    local rad_offset = P(radius, 0)
    self:shape("path"):move_to(A + rad_offset):cubic_to(A + offset, B - offset, B - rad_offset)
    self:shape("circle", { A, radius })
    self:shape("circle", { B, radius })
  end,
})

canvas.record({
  name = "node_link2", 
  args = { "A", "B", "offset", "radius" },
  call = function(self) 
    local A = self.args.A
    local B = self.args.B
    local offset = P(self.args.offset, 0)
    local radius = self.args.radius
    local rad_offset = P(radius, 0)
    self:shape("path"):move_to(A + rad_offset):cubic_to(A + offset, B - offset, B - rad_offset)
    self:shape("circle", { A, radius })
    self:shape("circle", { B, radius })
    self:style("fill", { COL(0.8, 0.8, 0.8) })
    self:shape("circle", { A, radius*0.6 })
    self:shape("circle", { B, radius*0.6 })
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

    self:shape("rect", { self.args.corner, self.args.size, 1 })

    for i=0, floor(w/unit) do
      self:shape("arrow", { P(x_off + i*unit, y_off), P(0, h) })
    end

    for i=0, floor(h/unit) do
      self:shape("arrow", { P(x_off, y_off + i*unit), P(w, 0) })
    end
  end,
})

canvas.record({
  name = "bezier_editor",
  args = { "corner", "size", "anchorA", "anchorB" },
  call = function(self)
    local corner = self.args.corner
    local size = self.args.size

    local A = corner + P(0, size)
    local B = A + self.args.anchorA:Ymirror()
    local D = corner + P(size, 0)
    local C = D + self.args.anchorB:Ymirror()

    -- self:style("fill", { COL(0.2, 0.2, 0.2) })
    -- self:shape("rect", { corner, P(size, size), 1 })

    self:draw("grid", { corner, P(size, size), size/10 })
    self:style("stroke", { COL(1, 1, 1), 3 })

    self:shape("path"):move_to(A):cubic_to(B, C, D)
    self:shape("line", { A, B })
    self:shape("line", { C, D })

  end,
})

