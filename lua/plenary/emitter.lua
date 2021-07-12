-- very simple listener

local Emitter = {}
Emitter.__index = Emitter

function Emitter.new()
  return setmetatable({}, Emitter)
end

function Emitter:next_idx(event)
  return (#self[event]) + 1
end

function Emitter:on(event, listener)
  assert(type(event) == "string")
  assert(type(listener) == "function")

  if self[event] == nil then
    self[event] = {}
  end

  self[event][self:next_idx()] = listener
end

function Emitter:once(event, listener)
  local idx = self:next_idx()

  self:on(event, function(...)
    listener(...)
    self[event][idx] = nil
  end)
end

function Emitter:emit(event, ...)
  assert(type(event) == "string")

  for _, listener in ipairs(self[event]) do
    listener(...)
  end
end

return Emitter
