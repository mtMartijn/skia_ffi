local ffi = require("ffi")
local input = require("sk.input")
local canvas = require("sk.canvas")
local P = require("sk.point")

local flush = io.flush
local C = ffi.C

ffi.cdef[[
typedef struct GLFWwindow GLFWwindow;
void glfwSwapBuffers(GLFWwindow* window);
void glfwPollEvents(void);
int glfwWindowShouldClose(GLFWwindow* window);

typedef struct {
  point pos;
  bool pressed;
  double time;
} mouse_info;
mouse_info get_mouse_info(GLFWwindow* window);
]]

canvas.custom_draw({
  name = "node",
  args = { "center", "size" },
  call = function(self)
    self:style("fill"):color(1, 0, 0)
    self:shape("crect"):set(P(300, 300), P(50, 50), 1)
    return self
  end,
})

local state = {}
function setup(w)
  state.window = ffi.cast("GLFWwindow*", w)

  canvas.draw("node")
end

function run()
  while C.glfwWindowShouldClose(state.window) == 0 do
    input.update(C.get_mouse_info(state.window))

    canvas.update()

    C.glfwPollEvents()
    C.glfwSwapBuffers(state.window)
    flush()
  end
end

-- -- Node:
-- canvas.record("node", function(c)
--   c:shader("fill"):color(0.4, 0.4, 0.4)
--   local A = P(1000, 500)
--   local B = P(800, 400)
--   c:draw("crect"):set("mouse_clicked_pos", P(200, 200), 1)
--   c:draw("crect"):set(B, P(200, 150), 1)
--   c:shader("stroke"):color(0.8, 1, 0.9):stroke_width(4)
--   local offset = P(100, 0)
--   c:draw("path"):move_to(A):cubic_to(A + offset, B - offset, B)
--   c:draw("circle"):set(A, 3)
--   c:draw("circle"):set(B, 3)
--   return c
-- end)

-- -- Hexagon:
-- canvas.record("hexagon", function(self)
--   self:style("fill"):color(0.5, 0.5, 0.5)

--   local sin, cos, pi = math.sin, math.cos, math.pi
--   local function hex(i)
--     local C = P(800, 800)
--     local R = 120
--     local cs = cos(pi*2/6*i)
--     local sn = sin(pi*2/6*i)
--     return C + R*P(sn, cs)
--   end

--   self:transform("translate"):set(P(0, -200))
--   self:shape("path")
--     :move_to(hex(0))
--     :line_to(hex(1))
--     :line_to(hex(2))
--     :line_to(hex(3))
--     :line_to(hex(4))
--     :line_to(hex(5))
--     :close()
--   return self
-- end)

