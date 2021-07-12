local uv = vim.loop

local log = require("plenary.log")
local async = require("plenary.async")
local channel = async.control.channel
local j_utils = require('plenary.process.util')
local Emitter = require('plenary.emitter')
local pipes = require("plenary.process.pipes")
local NullPipe = pipes.NullPipe

local M = {}

local Process = {}
Process.__index = Process

function Process.new(opts)
  local self = setmetatable({}, Process)

  self.command, self.uv_opts = j_utils.convert_opts(opts)

  self.stdin = opts.stdin or NullPipe.new()
  self.stdout = opts.stdout or NullPipe.new()
  self.stderr = opts.stderr or NullPipe.new()

  self.uv_opts.stdio = {
    self.stdin.handle,
    self.stdout.handle,
    self.stderr.handle,
  }

  self.emitter = Emitter.new()

  return self
end

function Process:_for_each_pipe(f)
  if self.stdin ~= nil then
    f(self.stdin)
  end
  if self.stdout ~= nil then
    f(self.stdout)
  end
  if self.stderr ~= nil then
    f(self.stderr)
  end
end

function Process:kill(force)
  local signal = force and "sigkill" or "sigterm"
  self.handle:kill(signal)
end

function Process:stop()
  self:_for_each_pipe(function(p)
    p:close()
  end)
  self.handle:close()
end

function Process:status()
  local tx, rx = channel.oneshot()

  self.emitter:on('exit', function(code, signal)
    tx(code, signal)
  end)

  return rx()
end

M.spawn = function(opts)
  local self = Process.new(opts)

  self.emitter:on('exit', function()
    self:stop()
  end)

  self.handle = uv.spawn(self.command, self.uv_opts, function(code, signal)
    assert(false)
    self.emitter.emit('exit', code, signal)
  end)

  return self
end

return M
