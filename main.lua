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
  q:draw("grid", { P(0, 0), P(1400, 900), 50 })
  q:style("fill", { COL(0.5, 0.5, 0.5) })
  -- q:draw("triangle", { P(400, 400), 20, 0 })
  -- q:transform("translate", { P(500, 500) })
  q:draw("hex_grid", { 1, 1, 1, 75, 5 })

  q:style("text", { COL(1, 1, 1), 18 })
  q:shape("text", { "Something", P(500, 400) })

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

