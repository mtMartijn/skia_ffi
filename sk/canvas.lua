local sk = require("sk.cdef")
local color = require("sk.color").new
local P = require("sk.point")
local utils = require("utils.table")

local type, assert, tostring = type, assert, tostring
local insert, remove = table.insert, table.remove
local key_unique = utils.key_unique

local master_queue = {}

local canvas = {}
canvas.__index = canvas

-- Need to figure out where to put canvas.queue(), i.e. have one large ops array or have many smaller ones
-- Perhaps only do it once, and have every draw/shape/translate operation append an op to a master ops array
-- But how would one delete a composite operation?
--
-- One:
--  -would make it easier to implement hierarchical draw operations
--
-- Many:
--  -would make it easier to delete a draw-group, and control the scope of its arguments
--
-- Solution: make template functions (see canvas.record) and use these to draw hierarchical objects and 
-- only use queue when you want to instantiate them.
--
-- Creating a callback mechanism will be tricky for 'paint/path' because its arguments are set only once at creation
-- 
-- Update: I feel like I'm overthinking it, maybe a callback mechanism is unnecessary. Will first try without

function canvas.queue()
  local b = {
    args = {},
    styles = {},
    ops = {},
    callbacks = {},
  }

  insert(master_queue, b)
  return setmetatable(b, canvas)
end

function canvas.reset(self)
  self.args = {}
  self.styles = {}
  self.ops = {}
  self.callbacks = {}
end

local function setup_args(template, args)
  local arg_list = {}
  for i=1, #template.args do
    local arg_name = template.args[i]
    arg_list[arg_name] = args[i]
  end
  return arg_list
end

------------------------
-------- STYLE ---------
------------------------

local style_list = {
  ["stroke"] = {
    args = { "color", "width" },
    call = function(self)
      sk.set_style(self.obj, "stroke")
      sk.set_color(self.obj, self.args.color)
      sk.set_stroke_width(self.obj, self.args.width)
      sk.set_stroke_cap(self.obj, "round_cap")
      sk.set_stroke_join(self.obj, "round_join")
    end,
  },
  ["path"] = {
    args = { "color", "width", "cap", "join" },
    call = function(self)
      sk.set_style(self.obj, "stroke")
      sk.set_color(self.obj, self.args.color)
      sk.set_stroke_width(self.obj, self.args.width)
      sk.set_stroke_cap(self.obj, self.args.cap)
      sk.set_stroke_join(self.obj, self.args.join)
    end,
  },
  ["fill"] = {
    args = { "color" },
    call = function(self)
      sk.set_style(self.obj, "fill")
      sk.set_color(self.obj, self.args.color)
    end,
  },
  ["text"] = {
    args = { "color", "size" },
    call = function(self)
      sk.set_style(self.obj, "fill")
      sk.set_color(self.obj, self.args.color)
      sk.set_text_size(self.obj, self.args.size)
    end,
  },
}

function canvas.style(self, name, args)
  local style_op = style_list[name]
  assert(style_op)

  local sh = {
    obj = sk.paint_new(),
    args = setup_args(style_op, args),
    call = style_op.call,
  }

  sh:call()
  insert(self.styles, sh)
end

------------------------
--------- PATH ---------
------------------------

local path_list = {
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

function canvas.path(self)
  local p = {
    obj = sk.path_new(),
    style = self.styles[#self.styles],
    call = function(self) sk.draw_path(self.obj, self.style.obj) end,
  }
  insert(self.ops, p)
  return setmetatable(p, path_list)
end

------------------------
-------- SHAPE ---------
------------------------

local shape_list = {
  ["point"] = {
    args = { "point" },
    call = function(self) sk.draw_point(self.args.point, self.style.obj) end,
  },
  ["line"] = {
    args = { "start", "end" },
    call = function(self) sk.draw_line(self.args.start, self.args["end"], self.style.obj) end,
  },
  ["arrow"] = {
    args = { "start", "direction" },
    call = function(self) sk.draw_arrow(self.args.start, self.args.direction, self.style.obj) end,
  },
  ["rect"] = {
    args = { "corner", "size", "radius" },
    call = function(self) sk.draw_rect(self.args.corner, self.args.size, self.args.radius, self.style.obj) end,
  },
  ["crect"] = {
    args = { "center", "size", "radius" },
    call = function(self) sk.draw_crect(self.args.center, self.args.size, self.args.radius, self.style.obj) end,
  },
  ["circle"] = {
    args = { "center", "radius" },
    call = function(self) sk.draw_circle(self.args.center, self.args.radius, self.style.obj) end,
  },
  ["oval"] = {
    args = { "center", "radius" },
    call = function(self) sk.draw_oval(self.args.center, self.args.radius, self.style.obj) end,
  },
  ["text"] = {
    args = { "text", "position" },
    call = function(self) sk.draw_text(self.args.text, #self.args.text, self.args.position, self.style.obj) end,
  },
}

function canvas.shape(self, shape, args)
  if #self.styles == 0 then self:style("stroke", {}) end

  if shape == "path" then return self:path() end

  local shape_op = shape_list[shape]
  assert(shape_op)

  local op = {
    style = self.styles[#self.styles], -- Attach last style in list
    args = setup_args(shape_op, args),
    call = shape_op.call,
  }

  insert(self.ops, op)
end

------------------------
------ TRANSFORM -------
------------------------

local transform_list = {
  ["translate"] = {
    args = { "direction" },
    call = function(self) sk.translate(self.args.direction) end,
  },
  ["rotate"] = {
    args = { "angle" },
    call = function(self) sk.rotate(self.args.angle) end,
  },
  ["scale"] = {
    args = { "size" },
    call = function(self) sk.scale(self.args.size) end,
  },
  ["skew"] = {
    args = { "sx", "sy" },
    call = function(self) sk.skew(self.args.sx, self.args.sy) end,
  },
  ["reset"] = {
    args = {},
    call = function(self) sk.reset_matrix() end,
  },
  ["save"] = {
    args = {},
    call = function(self) sk.save_matrix() end,
  },
  ["restore"] = {
    args = {},
    call = function(self) sk.restore_matrix() end,
  },
}

function canvas.transform(self, op, args)
  local transform_op = transform_list[op]
  assert(transform_op)

  local op = {
    args = setup_args(transform_op, args),
    call = transform_op.call,
  }

  insert(self.ops, op)
end

------------------------
--------- DRAW ---------
------------------------

local draw_list = {}

function canvas.record(conf)
  assert(key_unique(draw_list, conf.name))
  draw_list[conf.name] = conf
end

function canvas.draw(self, name, args)
  local draw_op = draw_list[name]
  assert(draw_op)

  self.args = setup_args(draw_op, args)

  draw_op.call(self)
end

function canvas.update(self)
  sk.save_matrix()
  for i=1, #self.ops do
    self.ops[i]:call()
  end
  sk.restore_matrix()
end

function canvas.flush()
  sk.clear(color(0.12, 0.12, 0.12))
  for i=1, #master_queue do
    master_queue[i]:update()
  end
  sk.flush()
end

return canvas
