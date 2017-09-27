local type, assert, tostring = type, assert, tostring
local insert, remove = table.insert, table.remove
local random = math.random

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

return {
  key_unique = key_unique,
  ordered_map = ordered_map.new,
}
