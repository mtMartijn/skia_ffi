local sk = require("sk.cdef")
local command = require("sk.command")
local input = require("sk.input")
local color = require("sk.color").new
local P = require("sk.point")

local canvas = {}

local node_cmd = command.new()
function node_setup(pos)
  node_cmd:shader():color(0.4, 0.4, 0.4):style("fill")
  local A = pos
  local B = P(800, 400)
  node_cmd:draw("crect"):args(A, P(200, 200), 1)
  node_cmd:draw("crect"):args(B, P(200, 150), 1)
  node_cmd:shader():color(0.8, 1, 0.9):stroke_width(4)
  local offset = P(100, 0)
  node_cmd:draw("path"):move_to(A):cubic_to(A + offset, B - offset, B)
  node_cmd:draw("circle"):args(A, 3)
  node_cmd:draw("circle"):args(B, 3)
end

local hex_cmd = command.new()
function hex_setup()
  hex_cmd:shader():color(0.2, 0.2, 0.2):style("fill")

  local sin, cos, pi = math.sin, math.cos, math.pi
  local function hex(i)
    local C = P(800, 800)
    local R = 120
    local cs = cos(pi*2/6*i)
    local sn = sin(pi*2/6*i)
    return C + R*P(sn, cs)
  end

  hex_cmd:draw("path"):move_to(hex(0))
  :line_to(hex(1))
  :line_to(hex(2))
  :line_to(hex(3))
  :line_to(hex(4))
  :line_to(hex(5))
  :close()
end

local test_cmd = command.new()
local bez_cmd = command.new()
function canvas.setup()
  -- Test:
  test_cmd:shader():color(1, 1, 0):style("fill")
  test_cmd:draw("circle"):args(P(300, 300), 50)
  test_cmd:shader():color(1, 1, 1):style("stroke")
  test_cmd:draw("crect"):args(P(500, 200), P(750, 100), 20)
  test_cmd:draw("path"):move_to(P(400,400)):line_to(P(100,100))

  -- Bezier editor:
  bez_cmd:shader():stroke_width(3)
  local cen = P(200, 200)
  local size = P(100, 100)
  local a1 = P(80, 10)
  local a2 = P(-20, 0)

  local A = cen - (size/2):Ymirror()
  local D = cen + (size/2):Ymirror()
  local B = A + a1:Ymirror()
  local C = D + a2:Ymirror()
  bez_cmd:draw("path"):move_to(A):cubic_to(B, C, D)
  bez_cmd:draw("path"):move_to(A):line_to(B):move_to(D):line_to(C)
  bez_cmd:draw("circle"):args(B, 4)
  bez_cmd:draw("circle"):args(C, 4)

  node_setup(P(500, 500))
  hex_setup()
end

function canvas.draw()
  sk.clear(color(0.15, 0.15, 0.15))

  -- TODO: think of scalable callback mechanism, improve mouse sensitivity, and make sk.command nestable
  -- TODO: looping structures inside a command buffer?
  -- local clicked = mouse():pressed_rect(node_cmd._ops[1].c, node_cmd._ops[1].sz)
  local inside = input.clicked_inside(node_cmd._ops[1].c, node_cmd._ops[1].sz)
  local down = input.mouse_down()
  if inside and down then
    local p = node_cmd._ops[1].c
    node_cmd = command.new()
    node_setup(p + input.mouse_pos_delta())
  end

  test_cmd:submit()
  node_cmd:submit()
  bez_cmd:submit()
  hex_cmd:submit()

  sk.flush()
end

return canvas
