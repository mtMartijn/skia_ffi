local ffi = require("ffi")
local canvas = require("sk.canvas")
local input = require("sk.input")

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

  canvas.setup()
end

function run()
  while C.glfwWindowShouldClose(state.window) == 0 do
    input.update(C.get_mouse_info(state.window))

    canvas.draw()

    C.glfwPollEvents()
    C.glfwSwapBuffers(state.window)
    io.flush()
  end
end
