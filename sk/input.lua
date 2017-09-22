local sk = require("sk.cdef")
local ffi = require("ffi")
local P = require("sk.point")

ffi.cdef[[
typedef struct {
  point pos;
  bool pressed;
  double time;
} mouse_info;
]]

local state = {
  prev = ffi.new("mouse_info"),
  curr = ffi.new("mouse_info"),
  clicked_pos = P(0, 0),
  released_pos = P(0, 0),
}

local function inside_rect(pos, center, size)
  local xmin, xmax = center.x - size.x/2, center.x + size.x/2
  local ymin, ymax = center.y - size.y/2, center.y + size.y/2
  local x, y = pos.x, pos.y
  return xmin <= x and x <= xmax and ymin <= y and y <= ymax
end

local function drag_delta()
  return state.released_pos - state.clicked_pos
end

local function mouse_clicked()
  return not state.prev.pressed and state.curr.pressed
end

local function mouse_released()
  return state.prev.pressed and not state.curr.pressed
end

local function mouse_down()
  return state.curr.pressed
end

local function mouse_pos()
  return state.curr.pos
end

local function mouse_pos_delta()
  return state.curr.pos - state.prev.pos
end

local function mouse_clicked_pos()
  return state.clicked_pos
end

local function clicked_inside(center, size)
  return inside_rect(state.clicked_pos, center, size)
end

local function update(mouse)
  state.prev = state.curr
  state.curr = mouse

  if mouse_clicked() then
    state.clicked_pos = mouse.pos
  elseif mouse_released() then
    state.released_pos = mouse.pos
  end
end

return {
  update = update,
  clicked_inside = clicked_inside,
  mouse_down = mouse_down,
  mouse_pos = mouse_pos,
  mouse_pos_delta = mouse_pos_delta,
  mouse_clicked_pos = mouse_clicked_pos,
}

