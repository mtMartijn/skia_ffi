local ffi = require("ffi")
local input = require("sk.input")
local canvas = require("sk.canvas")
local P = require("sk.point")
local COL = require("sk.color").new
local temps = require("sk.templates")

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

local state = {}
function setup(w)
  state.window = ffi.cast("GLFWwindow*", w)

  local q = canvas.queue()
  -- q:style("stroke", { COL(0.8, 0.8, 0.8), 2 })
  -- q:draw("node_link2", { P(800, 500), P(1000, 400), 75, 10 })
  -- q:draw("triangle", { P(400, 400), 20, 0 })
  -- q:transform("translate", { P(500, 500) })
  -- q:draw("hex_grid", { 1, 1, 1, 75, 5 })
  q:draw("bezier_editor", { P(100, 100), 200, P(120, 25), P(-100, 5)})

end

function run()
  while C.glfwWindowShouldClose(state.window) == 0 do
    input.update(C.get_mouse_info(state.window))

    canvas.flush()

    C.glfwPollEvents()
    C.glfwSwapBuffers(state.window)
    flush()
  end
end

