local async = require('plenary.async')
local channel = async.channel

-- very simple emitters
local M = {}

local CallbackEmitter = {}
CallbackEmitter.__index = CallbackEmitter

function CallbackEmitter.new()
  return setmetatable({}, CallbackEmitter)
end

function CallbackEmitter:next_idx(event)
  return (#self[event]) + 1
end

function CallbackEmitter:on(event, listener)
  assert(type(event) == "string")
  assert(type(listener) == "function")

  if self[event] == nil then
    self[event] = {}
  end

  self[event][self:next_idx(event)] = listener
end

function CallbackEmitter:once(event, listener)
  local idx = self:next_idx(event)

  self:on(event, function(...)
    listener(...)
    self[event][idx] = nil
  end)
end

function CallbackEmitter:emit(event, ...)
  assert(type(event) == "string")

  for _, listener in ipairs(self[event]) do
    listener(...)
  end
end

M.CallbackEmitter = CallbackEmitter

local ChannelEmitter = {}
ChannelEmitter.__index = ChannelEmitter

function ChannelEmitter.new()
  return setmetatable({}, ChannelEmitter)
end

function ChannelEmitter:rx(event)
end

function ChannelEmitter:tx(event, ...)
end

return M
