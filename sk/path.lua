local sk = require("sk.cdef")

local path = {}
path.__index = path

function path.new()
    local p = {
        obj = sk.path_new()
    }
    return setmetatable(p, path)
end

function path.reset(self)
    sk.path_reset(self.obj)
    return self
end

function path.rewind(self)
    sk.path_rewind(self.obj)
    return self
end

function path.close(self)
    sk.path_close(self.obj)
    return self
end

function path.move_to(self, p)
    sk.path_move(self.obj, p)
    return self
end

function path.line_to(self, p)
    sk.path_line(self.obj, p)
    return self
end

function path.quad_to(self, a, fin)
    sk.path_quad(self.obj, a, fin)
    return self
end

function path.cubic_to(self, a1, a2, fin)
    sk.path_cubic(self.obj, a1, a2, fin)
    return self
end

function path.conic_to(self, a, fin, weight)
    sk.path_conic(self.obj, a, fin, weight)
    return self
end

-- This doesn't work in lua 5.1, need to recompile luaJIT so that it's 5.2 compatible
function path.__gc(self)
    sk.path_delete(self.obj)
end

return path
