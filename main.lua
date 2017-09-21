local ffi = require("ffi")
local C = ffi.C
local canvas = require("sk.canvas")

ffi.cdef[[
typedef struct GLFWwindow GLFWwindow;
void glfwSwapBuffers(GLFWwindow* window);
void glfwPollEvents(void);
int glfwWindowShouldClose(GLFWwindow* window);
double glfwGetTime();

typedef struct {
    point pos;
    bool pressed;
} mouse_info;
mouse_info get_mouse_info(GLFWwindow* window);

]]

local mouse = {
    pressed_rect = function(self, pos, size)
        local xmin, xmax = pos.x - size.x/2, pos.x + size.x/2
        local ymin, ymax = pos.y - size.y/2, pos.y + size.y/2
        local x, y = self.pos.x, self.pos.y
        return xmin <= x and x <= xmax and ymin <= y and y <= ymax and self.pressed
    end,
}

ffi.metatype("mouse_info", { __index = mouse })

local state = {}
function setup(w)
    state.window = ffi.cast("GLFWwindow*", w)

    canvas.mouse_info.prev = C.get_mouse_info(state.window)
    canvas.mouse_info.curr = C.get_mouse_info(state.window)

    canvas.setup()
end

function run()
    while C.glfwWindowShouldClose(state.window) == 0 do

        canvas.mouse_info.prev = canvas.mouse_info.curr
        canvas.mouse_info.curr = C.get_mouse_info(state.window)
        canvas.draw()

        C.glfwPollEvents()
        C.glfwSwapBuffers(state.window)
        io.flush()
    end
end
