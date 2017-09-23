local sk = require("sk.cdef")
local command = require("sk.command")
local input = require("sk.input")
local color = require("sk.color").new
local P = require("sk.point")

local insert = table.insert

local canvas = {}

local queue = {}

-- TODO: ability to create custom draw methods, reliable mouse_drag callback, reimplement sk.path and sk.paint
-- TODO: record a custom draw method with modifyable parameters (i.e. custom .set function)
-- TODO: implement text

-- Node:
command.record("node", function()
  local c = command.new()
  c:shader("fill"):color(0.4, 0.4, 0.4)
  local A = P(1000, 500)
  local B = P(800, 400)
  c:draw("crect"):set("mouse_clicked_pos", P(200, 200), 1)
  c:draw("crect"):set(B, P(200, 150), 1)
  c:shader("stroke"):color(0.8, 1, 0.9):stroke_width(4)
  local offset = P(100, 0)
  c:draw("path"):move_to(A):cubic_to(A + offset, B - offset, B)
  c:draw("circle"):set(A, 3)
  c:draw("circle"):set(B, 3)
  return c
end)

-- Hexagon:
command.record("hexagon", function()
  local c = command.new()
  c:shader("fill"):color(0.5, 0.5, 0.5)

  local sin, cos, pi = math.sin, math.cos, math.pi
  local function hex(i)
    local C = P(800, 800)
    local R = 120
    local cs = cos(pi*2/6*i)
    local sn = sin(pi*2/6*i)
    return C + R*P(sn, cs)
  end

  c:transform("translate"):set(P(0, -200))
  c:draw("path")
    :move_to(hex(0))
    :line_to(hex(1))
    :line_to(hex(2))
    :line_to(hex(3))
    :line_to(hex(4))
    :line_to(hex(5))
    :close()
  return c
end)

-- Bezier:
command.record("bezier", function() 
  local c = command.new()
  c:shader("stroke"):stroke_width(3)
  local cen = P(200, 200)
  local size = P(100, 100)
  local a1 = P(80, 10)
  local a2 = P(-20, 0)

  local A = cen - (size/2):Ymirror()
  local D = cen + (size/2):Ymirror()
  local B = A + a1:Ymirror()
  local C = D + a2:Ymirror()
  c:draw("path"):move_to(A):cubic_to(B, C, D)
  c:draw("path"):move_to(A):line_to(B):move_to(D):line_to(C)
  c:draw("circle"):set(B, 4)
  c:draw("circle"):set(C, 4)
  return c
end)

-- Test:
command.record("test", function()
  local c = command.new()
  c:shader("fill"):color(1, 1, 0)
  c:draw("circle"):set(P(300, 300), 50)
  c:shader("stroke"):color(1, 1, 1)
  c:draw("crect"):set(P(500, 200), P(750, 100), 20)
  c:draw("path"):move_to(P(400,400)):line_to(P(100,100))
  return c
end)

function canvas.setup()
  queue = {
    command.create("test"),
    command.create("bezier"),
    -- command.create("node"),
    command.create("hexagon"),
  }
end

function canvas.draw()
  sk.clear(color(0.15, 0.15, 0.15))
  for i=1, #queue do
    queue[i]:submit()
  end
  sk.flush()
end

return canvas
