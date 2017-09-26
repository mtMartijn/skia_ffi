local sk = require("sk.cdef")
local input = require("sk.input")
local color = require("sk.color").new

local insert, type, assert, tostring = table.insert, type, assert, tostring
local random = math.random

local master_queue = {}

local shader_list = {
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
shader_list.__index = shader_list

local draw_list = {
  ["point"] = {
    arg_names = { "point" },
    call = function(self) sk.draw_point(self.point, self.shader.obj) end,
  },
  ["line"] = {
    arg_names = { "start", "end" },
    call = function(self) sk.draw_line(self.start, self["end"], self.shader.obj) end,
  },
  ["arrow"] = {
    arg_names = { "start", "direction" },
    call = function(self) sk.draw_arrow(self.start, self.direction, self.shader.obj) end,
  },
  ["rect"] = {
    arg_names = { "corner", "size", "radius" },
    call = function(self) sk.draw_rect(self.corner, self.size, self.radius, self.shader.obj) end,
  },
  ["crect"] = {
    arg_names = { "center", "size", "radius" },
    call = function(self) sk.draw_crect(self.center, self.size, self.radius, self.shader.obj) end,
  },
  ["quad"] = {
    arg_names = { "A", "B", "radius" },
    call = function(self) sk.draw_quad(self.A, self.B, self.radius, self.shader.obj) end,
  },
  ["circle"] = {
    arg_names = { "center", "radius" },
    call = function(self) sk.draw_circle(self.center, self.radius, self.shader.obj) end,
  },
  ["oval"] = {
    arg_names = { "center", "radius" },
    call = function(self) sk.draw_oval(self.center, self.radius, self.shader.obj) end,
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
    arg_names = { "direction" },
    call = function(self) sk.translate(self.direction) end,
  },
  ["rotate"] = {
    arg_names = { "angle" },
    call = function(self) sk.rotate(self.angle) end,
  },
  ["scale"] = {
    arg_names = { "size" },
    call = function(self) sk.scale(self.size) end,
  },
  ["skew"] = {
    arg_names = { "sx", "sy" },
    call = function(self) sk.skew(self.sx, self.sy) end,
  },
  ["reset"] = {
    arg_names = {},
    call = function(self) sk.reset_matrix() end,
  },
}

local custom_list = {}

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

local function map_insert(self, item)
  assert(type(item) == "table")

  local id = tostring(random(999999))
  while not key_unique(self, id) do
    id = tostring(random(999999))
  end
  item._id = id

  insert(self, item)
  self[id] = item
  return id
end

local function map()
  return {
    insert = map_insert,
  }
end

local command = {}
command.__index = command
command._type = "command"

function command.new(name)
  local b = {
    _shaders = {},
    _ops = {},
    _callbacks = {},
    _values = {},
  }

  return setmetatable(b, command)
end

function command.record(name, fn)
  assert(key_unique(custom_list, name))
  custom_list[name] = fn
end

function command.create(name)
  assert(custom_list[name])
  return custom_list[name]()
end

local function set_value(self, val)
  self._raw = val
  return self
end

local function return_value(self)
  return self._raw
end

function command.value(self, name)
  assert(type(name) == "string")
  assert(key_unique(self._values, name))

  local val = {
    set = set_value,
    call = return_value,
  }

  self._values[name] = val
  return val
end


function command.shader(self, tp)
  local sh = {
    obj = sk.paint_new()
  }
  setmetatable(sh, shader_list)
  insert(self._shaders, sh)

  return sh[tp](sh)
end

local function new_path(cmd)
  local p = {
    obj = sk.path_new(),
    shader = cmd._shaders[#cmd._shaders],
    call = function(self) sk.draw_path(self.obj, self.shader.obj) end,
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
  local names = self.arg_names
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

function command.draw(self, shape)
  if #self._shaders == 0 then self:shader("stroke") end

  if shape == "path" then return new_path(self) end

  local draw_op = draw_list[shape]
  assert(draw_op)

  local op = {
    base = self,
    shader = self._shaders[#self._shaders], -- Attach last shader in list
    arg_names = draw_op.arg_names,
    set = set_args,
    call = draw_op.call,
  }

  insert(self._ops, op)
  return op
end

function command.transform(self, op)
  local transform_op = transform_list[op]
  assert(transform_op)

  local op = {
    base = self,
    arg_names = transform_op.arg_names,
    set = set_args,
    call = transform_op.call,
  }

  insert(self._ops, op)
  return op
end


function command.add_callback(self, cb)
  insert(self._callbacks, cb)
end

function command.submit(self)
  for i=1, #self._callbacks do
    self._callbacks[i]:call()
  end
  for i=1, #self._ops do
    self._ops[i]:call()
  end
  sk.reset_matrix()
end

function command.update()
  for i=1, #master_queue do
    master_queue[i]:submit()
  end
end

return command
