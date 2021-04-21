local uv = vim.loop
local fs = require('plenary/fs/core')
local a = require('plenary.async_lib')
local async, await = a.async, a.await

local add = async(function(path, initial_add)
  local stats = await(fs.stat(path))
  dump(stats)
end)

local function handle_file(file, stats, initial_add)
end

a.run(add("/home/brian/testing_file"))
