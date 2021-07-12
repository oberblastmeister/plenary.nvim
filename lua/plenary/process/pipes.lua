local uv = vim.loop
local async = require("plenary.async")
local channel = async.control.channel
local strings = require('plenary.strings')
local Emitter = require('plenary.emitter')

local M = {}

local Pipe = {}
Pipe.__index = Pipe

function Pipe.new()
  local self = setmetatable({
    handle = uv.new_pipe(false),
    emitter = Emitter.new()
  }, Pipe)

  self.emitter:on("eof", function()
    self.handle:close()
  end)

  return self
end

function Pipe:close()
  self.handle.close()
end

function Pipe:read_till_end_with_callback(callback)
  self.handle:read_start(function(err, data)
    assert(not err, err)

    if data == nil then
      self.handle:read_stop()
      self.emitter:emit('eof')
    else
      callback(data)
    end
  end)
end

function Pipe:read()
  if self.stored then
    local data = self.stored
    self.stored = nil
    return data
  end

  local tx, rx = channel.oneshot()

  self.handle:read_start(function(err, data)
    assert(not err, err)
    self.handle:read_stop()

    if data == nil then
      self.emitter:emit('eof')
    else
      tx(data)
    end
  end)

  return rx()
end

local split_first = function(s, split)
  local idx = string.find(s, split, 1, true)

  if idx == nil then
    return s
  end

  local rest = string.sub(s, idx + 1)

  -- if rest == "" then
  --   rest = nil
  -- end

  return string.sub(s, 1, idx), rest
end

function Pipe:read_line()
  if self.stored then
    local data, new = strings.split_first(self.stored, "\n") -- no windows
    self.stored = new
    return data
  end

  local got = self:read()
  local data, new = split_first(got, "\n")
  self.stored = new
  return data
end

function Pipe:chunks()
  return function()
    return self:read()
  end
end

function Pipe:lines()
  return function()
    return self:read_line()
  end
end

function Pipe:read_till_end()
  local buffer = {}
  local tx, rx = channel.oneshot()

  if self.stored then
    buffer[#buffer+1] = self.stored
    self.stored = nil
  end

  self.emitter:on('eof', function()
    tx(table.concat(buffer))
  end)

  self:read_till_end_with_callback(function(data)
    buffer[#buffer + 1] = data
  end)

  return rx()
end

M.Pipe = Pipe

local NullPipe = {}
NullPipe.__index = NullPipe

function NullPipe.new()
  return {}
end

M.NullPipe = NullPipe

return M
