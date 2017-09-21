local sk = require("sk.cdef")
local path = require("sk.path")
local paint = require("sk.paint")

local insert = table.insert

local command = {}
command.__index = command
command._type = "command"

function command.new()
    local b = {
        _shaders = {
            paint.new() -- Default shader
        },
        _ops = {},
        _listeners = {},
        _draw_flag = false,
    }

    return setmetatable(b, command)
end

local transform_list = {
    ["translate"] = {
        args = function(self, dir) self.dir = dir end,
        call = function(self) sk.translate(self.dir) end,
    },
    ["rotate"] = {
        args = function(self, angle) self.angle = angle end,
        call = function(self) sk.rotate(self.angle) end,
    },
    ["scale"] = {
        args = function(self, size) self.size = size end,
        call = function(self) sk.scale(self.size) end,
    },
    ["skew"] = {
        args = function(self, sx, sy) self.sx = sx; self.sy = sy end,
        call = function(self) sk.skew(self.sx, self.sy) end,
    },
}

function command.transform(self, op)
    local transform_op = transform_list[op]
    assert(transform_op)

    local op = {
        args = transform_op.args,
        call = transform_op.call,
    }

    insert(self._ops, op)
    return op
end

function command.shader(self, sh)
    -- If no draw op has been made yet, substitute the default shader.
    local sh = sh or paint.new()
    if not self._draw_flag then
        self._shaders = { sh } 
    else
        insert(self._shaders, sh)
    end
    return sh
end

local draw_list = {
    ["point"] = {
        args = function(self, p) self.p = p end,
        call = function(self) sk.draw_point(self.p, self.shader.obj) end,
    },
    ["line"] = {
        args = function(self, s, e) self.s = s; self.e = e end,
        call = function(self) sk.draw_line(self.s, self.e, self.shader.obj) end,
    },
    ["arrow"] = {
        args = function(self, s, dir) self.s = s; self.dir = dir end,
        call = function(self) sk.draw_arrow(self.s, self.dir, self.shader.obj) end,
    },
    ["rect"] = {
        args = function(self, c, sz, rad) self.c = c; self.sz = sz; self.rad = rad end,
        call = function(self) sk.draw_rect(self.c, self.sz, self.rad, self.shader.obj) end,
    },
    ["crect"] = {
        args = function(self, c, sz, rad) self.c = c; self.sz = sz; self.rad = rad end,
        call = function(self) sk.draw_crect(self.c, self.sz, self.rad, self.shader.obj) end,
    },
    ["quad"] = {
        args = function(self, a, b, rad) self.a = a; self.b = b; self.rad = rad end,
        call = function(self) sk.draw_quad(self.a, self.b, self.rad, self.shader.obj) end,
    },
    ["circle"] = {
        args = function(self, c, r) self.c = c; self.r = r end,
        call = function(self) sk.draw_circle(self.c, self.r, self.shader.obj) end,
    },
    ["oval"] = {
        args = function(self, c, r) self.c = c; self.r = r end,
        call = function(self) sk.draw_oval(self.c, self.r, self.shader.obj) end,
    },
}

function command.path(self)
    local pth = path.new()
    pth.shader = self._shaders[#self._shaders]
    pth.call = function(self) sk.draw_path(self.obj, self.shader.obj) end
    insert(self._ops, pth)
    return pth
end

function command.draw(self, shape, cbfn)
    if shape == "path" then return self:path() end

    local draw_op = draw_list[shape]
    assert(draw_op)

    local op = {
        shader = self._shaders[#self._shaders], -- Attach last shader in list
        args = draw_op.args,
        call = draw_op.call,
    }

    -- Optional callback fn
    -- if cbfn then
    --     op.call = function(self)
    --         cnfn(self)
    --         draw_op.call(self)
    --     end
    -- end

    insert(self._ops, op)
    self._draw_flag = true
    return op
end

function command.submit(self)
    for i=1, #self._ops do
        self._ops[i]:call()
    end
    sk.reset_matrix()
end

return command

