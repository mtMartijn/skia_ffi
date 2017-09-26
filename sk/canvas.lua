local sk = require("sk.cdef")
local input = require("sk.input")
local color = require("sk.color").new

local insert, remove, type, assert, tostring = table.insert, table.remove, type, assert, tostring
local random = math.random

local master_queue = {}

local style_list = {
  ["color"] = function(self, r, g, b, a) 
    if type(r) == "number" then
      sk.set_color(self.obj, color(r, g, b, a))
    else
      sk.set_color(self.obj, r)
    end
    return self
  end,
  ["alpha"] = function(self, a) 
    sk.set_alpha(self.obj, a)
    return self
  end,
  ["style"] = function(self, s)
    sk.set_style(self.obj, s)
    return self
  end,
  ["fill"] = function(self) 
    sk.set_style(self.obj, "fill")
    return self
  end,
  ["stroke"] = function(self) 
    sk.set_style(self.obj, "stroke")
    return self
  end,
  ["stroke_and_fill"] = function(self) 
    sk.set_style(self.obj, "stroke_and_fill")
    return self
  end,
  ["stroke_join"] = function(self, j)
    sk.set_stroke_join(self.obj, j)
    return self
  end,
  ["stroke_cap"] = function(self, c)
    sk.set_stroke_cap(self.obj, c)
    return self
  end,
  ["stroke_width"] = function(self, w)
    sk.set_stroke_width(self.obj, w)
    return self
  end,
}
style_list.__index = style_list

local shape_list = {
  ["point"] = {
    args = { "point" },
    call = function(self) sk.draw_point(self.point, self.style.obj) end,
  },
  ["line"] = {
    args = { "start", "end" },
    call = function(self) sk.draw_line(self.start, self["end"], self.style.obj) end,
  },
  ["arrow"] = {
    args = { "start", "direction" },
    call = function(self) sk.draw_arrow(self.start, self.direction, self.style.obj) end,
  },
  ["rect"] = {
    args = { "corner", "size", "radius" },
    call = function(self) sk.draw_rect(self.corner, self.size, self.radius, self.style.obj) end,
  },
  ["crect"] = {
    args = { "center", "size", "radius" },
    call = function(self) sk.draw_crect(self.center, self.size, self.radius, self.style.obj) end,
  },
  ["quad"] = {
    args = { "A", "B", "radius" },
    call = function(self) sk.draw_quad(self.A, self.B, self.radius, self.style.obj) end,
  },
  ["circle"] = {
    args = { "center", "radius" },
    call = function(self) sk.draw_circle(self.center, self.radius, self.style.obj) end,
  },
  ["oval"] = {
    args = { "center", "radius" },
    call = function(self) sk.draw_oval(self.center, self.radius, self.style.obj) end,
  },
}

local path_list = {
  ["reset"] = function(self)
    sk.path_reset(self.obj)
    return self
  end,
  ["rewind"] = function(self)
    sk.path_rewind(self.obj)
    return self
  end,
  ["close"] = function(self)
    sk.path_close(self.obj)
    return self
  end,
  ["move_to"] = function(self, p)
    sk.path_move(self.obj, p)
    return self
  end,
  ["line_to"] = function(self, p)
    sk.path_line(self.obj, p)
    return self
  end,
  ["quad_to"] = function(self, a, fin)
    sk.path_quad(self.obj, a, fin)
    return self
  end,
  ["cubic_to"] = function(self, a1, a2, fin)
    sk.path_cubic(self.obj, a1, a2, fin)
    return self
  end,
  ["conic_to"] = function(self, a, fin, weight)
    sk.path_conic(self.obj, a, fin, weight)
    return self
  end,
}
path_list.__index = path_list

local transform_list = {
  ["translate"] = {
    args = { "direction" },
    call = function(self) sk.translate(self.direction) end,
  },
  ["rotate"] = {
    args = { "angle" },
    call = function(self) sk.rotate(self.angle) end,
  },
  ["scale"] = {
    args = { "size" },
    call = function(self) sk.scale(self.size) end,
  },
  ["skew"] = {
    args = { "sx", "sy" },
    call = function(self) sk.skew(self.sx, self.sy) end,
  },
  ["reset"] = {
    args = {},
    call = function(self) sk.reset_matrix() end,
  },
}

local draw_list = {}

local callback_list = {
  ["mouse_clicked_pos"] = input.mouse_clicked_pos,
  ["mouse_released_pos"] = input.mouse_released_pos,
  ["mouse_pos"] = input.mouse_pos,
}

-- Utils:
local function key_unique(tbl, key)
  for k, v in pairs(tbl) do
    if k == key then return false end
  end
  return true
end

local ordered_map = {}
ordered_map.__index = ordered_map

function ordered_map.insert(self, item)
  assert(type(item) == "table")

  local key = tostring(random(999999))
  while not key_unique(self, key) do
    key = tostring(random(999999))
  end
  item._key = key
  item._it = #self

  self[#self] = item
  self[key] = item

  return key
end

function ordered_map.remove(self, id)
  local it, key
  if type(id) == "number" then
    it = id
    key = self[id]._key
  elseif type(id) == "string" then
    it = self[id]._it
    key = id
  elseif type(id) == "table" then
    it = id._it
    key = id._key
  end
  remove(self, it)
  self[key] = nil
end

function ordered_map.new()
  return setmetatable({}, ordered_map)
end

local canvas = {}
canvas.__index = canvas

-- Need to figure out where to put canvas.new(), i.e. have one large _ops array or have many smaller ones
-- Perhaps only do it once, and have every draw/shape/translate operation append an op to a master _ops array
-- But how would one delete a composite operation?
--
-- One:
--  -would make it easier to implement hierarchical draw operations
--
-- Many:
--  -would make it easier to delete a draw-group, and control the scope of its arguments

function canvas.new(name)
  local b = {
    _styles = {},
    _ops = {},
    _callbacks = {},
    _values = {},
  }

  return setmetatable(b, canvas)
end

function canvas.record(name, fn)
  assert(key_unique(draw_list, name))
  draw_list[name] = fn
end

function canvas.custom_draw(conf)
  local key = conf.name
  assert(key_unique(draw_list, key))
  draw_list[key] = conf
end

function canvas.create(name)
  assert(draw_list[name])
  local cmd = canvas.new()
  return draw_list[name](cmd)
end

function canvas.style(self, tp)
  local sh = {
    obj = sk.paint_new()
  }
  setmetatable(sh, style_list)
  insert(self._styles, sh)

  return sh[tp](sh)
end

local function new_path(cmd)
  local p = {
    obj = sk.path_new(),
    style = cmd._styles[#cmd._styles],
    call = function(self) sk.draw_path(self.obj, self.style.obj) end,
  }
  insert(cmd._ops, p)
  return setmetatable(p, path_list)
end

local function return_arg_callback(tbl, key, fn)
  return {
    tbl = tbl,
    key = key,
    call = function(self) 
      self.tbl[self.key] = fn() -- Needs argument in fn
    end,
  }
end

local function set_args(self, a, b, c, d, e, f, g) -- Max 7 parameters
  local arg_list = { a, b, c, d, e, f, g }
  local names = self.args
  for i=1, #names do
    local name = names[i]
    if type(arg_list[i]) == "function" then
      self.base:add_callback(return_arg_callback(self, name, arg_list[i]))
    elseif type(arg_list[i]) == "string" then
      local cb_name = arg_list[i]
      self.base:add_callback(return_arg_callback(self, name, callback_list[cb_name]))
    else
      self[name] = arg_list[i]
    end
  end
end

function canvas.draw(name)
  local draw_op = draw_list[name]
  assert(draw_op)

  local cmd = canvas.new()
  draw_op.call(cmd)

  insert(master_queue, cmd)
  return cmd
end

function canvas.shape(self, shape)
  if #self._styles == 0 then self:style("stroke") end

  if shape == "path" then return new_path(self) end

  local shape_op = shape_list[shape]
  assert(shape_op)

  local op = {
    base = self,
    style = self._styles[#self._styles], -- Attach last style in list
    args = shape_op.args,
    set = set_args,
    call = shape_op.call,
  }

  insert(self._ops, op)
  return op
end

function canvas.transform(self, op)
  local transform_op = transform_list[op]
  assert(transform_op)

  local op = {
    base = self,
    args = transform_op.args,
    set = set_args,
    call = transform_op.call,
  }

  insert(self._ops, op)
  return op
end


function canvas.add_callback(self, cb)
  insert(self._callbacks, cb)
end

function canvas.submit(self)
  for i=1, #self._callbacks do
    self._callbacks[i]:call()
  end
  for i=1, #self._ops do
    self._ops[i]:call()
  end
  sk.reset_matrix()
end

function canvas.update()
  sk.clear(color(0.15, 0.15, 0.15))
  for i=1, #master_queue do
    master_queue[i]:submit()
  end
  sk.flush()
end

return canvas
