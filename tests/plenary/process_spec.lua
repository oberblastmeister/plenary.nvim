require('plenary.async').tests.add_to_env()

local eq = assert.are.same

function dump(...)
  print(vim.inspect(...))
end

local process = require('plenary.process')
local pipes = require('plenary.process.pipes')
local Pipe = pipes.Pipe

describe('process', function()
  a.it('should read lines', function()
    local handle = process.spawn { "echo", "hello", "world", stdout = Pipe.new() }
    eq("hello world\n", handle.stdout:read_line())
    eq("", handle.stdout:read_line())
    -- handle.handle:kill("sigkill")
    -- handle:kill()
    -- handle:status()
    -- handle.emitter:on('exit', function()
    --   assert(false)
    -- end)
    -- assert(handle.handle:is_closing())
  end)
end)
