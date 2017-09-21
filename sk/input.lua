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

local info = {
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
  return info.released_pos - info.clicked_pos
end

local function mouse_clicked()
  return not info.prev.pressed and info.curr.pressed
end

local function mouse_released()
  return info.prev.pressed and not info.curr.pressed
end

local function mouse_down()
  return info.curr.pressed
end

local function mouse_pos()
  return info.curr.pos
end

local function mouse_pos_delta()
  return info.curr.pos - info.prev.pos
end

local function clicked_inside(center, size)
  return inside_rect(info.clicked_pos, center, size)
end

local function update(mouse)
  info.prev = info.curr
  info.curr = mouse

  if mouse_clicked() then
    info.clicked_pos = mouse.pos
  elseif mouse_released() then
    info.released_pos = mouse.pos
  end
end

return {
  update = update,
  clicked_inside = clicked_inside,
  mouse_down = mouse_down,
  mouse_pos = mouse_pos,
  mouse_pos_delta = mouse_pos_delta,
}
