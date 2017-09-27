local canvas = require("sk.canvas")
local P = require("sk.point")
local color = require("sk.color")

local sin, cos, pi = math.sin, math.cos, math.pi
local COL = color.new

canvas.record({
  name = "node_link", 
  args = { "A", "B", "offset" },
  call = function(self) 
    local A = self.args.A
    local B = self.args.B
    self:style("stroke", { COL(0.8, 1, 0.4), 4 })
    local offset = P(self.args.offset, 0)
    self:shape("path"):move_to(A):cubic_to(A + offset, B - offset, B)
    self:shape("circle", {A, 3})
    self:shape("circle", {B, 3})
  end,
})

canvas.record({
  name = "hexagon",
  args = { "pos", "size" },
  call = function(self)
    self:style("fill", { COL(0.5, 0.5, 0.5) })

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
  name = "arrow",
  args = { "pos", "angle" },
  call = function(self)
  end,
})

canvas.record({
  name = "grid",
  args = { "center", "size", "spacing" },
  call = function(self)
    self:style("stroke", { COL(0.5, 0.5, 0.5, 0.5), 1 })
  end,
})
