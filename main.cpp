#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include "GLFW/glfw3.h"
#include <luajit-2.1/lua.hpp>
#include "skia_ffi.h"

extern "C" {

  typedef struct {
    point pos;
    bool pressed;
    double time;
  } mouse_info;

  mouse_info get_mouse_info(GLFWwindow* window) {
    double x, y;
    glfwGetCursorPos(window, &x, &y);
    auto state = glfwGetMouseButton(window, 0);

    mouse_info info;
    info.pos.x = static_cast<float>(x);
    info.pos.y = static_cast<float>(y);
    info.pressed = state == GLFW_PRESS ? true : false;
    info.time = glfwGetTime();
    return info;
  }

}

static void error_callback(int error, const char* description) {
  fputs(description, stderr);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
  if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
    glfwSetWindowShouldClose(window, GL_TRUE);
}

int main(int argc, char* argv[]) {
  GLFWwindow* window;
  glfwSetErrorCallback(error_callback);
  if (!glfwInit()) {
    exit(EXIT_FAILURE);
  }

  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  glfwWindowHint(GLFW_SRGB_CAPABLE, GL_TRUE);

  /* const int width = 1920; */
  /* const int height = 1080; */

  const int width = 1400;
  const int height = 900;

  window = glfwCreateWindow(width, height, "MT", NULL, NULL);
  if (!window) {
    glfwTerminate();
    exit(EXIT_FAILURE);
  }
  glfwMakeContextCurrent(window);
  glfwSetKeyCallback(window, key_callback);
  glfwSwapInterval(1);

  init_skia(width, height);

  lua_State* L = luaL_newstate();
  luaL_openlibs(L);
  if(luaL_dofile(L, "main.lua"))
    printf("%s\n", lua_tostring(L, -1));

  lua_getglobal(L, "setup");
  lua_pushlightuserdata(L, window);
  if(lua_pcall(L, 1, 0, 0))
    printf("%s\n", lua_tostring(L, -1));

  lua_getglobal(L, "run");
  if(lua_pcall(L, 0, 0, 0))
    printf("%s\n", lua_tostring(L, -1));

  lua_close(L);
  cleanup_skia();

  glfwDestroyWindow(window);
  glfwTerminate();
  exit(EXIT_SUCCESS);
}

