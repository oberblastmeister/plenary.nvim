local a = require("plenary.async_lib")
local uv = vim.loop
local async, await = a.async, a.await
local Job = require("plenary.job_future").Job

local fn = async(function()
  -- local handle = Job { "sleep", "2" }:spawn()
  -- local res = await(handle:stop())
  local output = await(Job { "sleep", "2" }:output())
  dump(output)

  -- dump(handle)
  -- dump(res)
  -- assert(res:success())
end)

local rg = async(function()
  local handle = Job { "rg", "--vimgrep", ".*", cwd = "/home/brian" }:spawn { raw_read = true }
  for i = 1, 2000 do
    print(await(handle:raw_read("stdout")))
    await(a.util.sleep(5))
  end
  await(a.util.sleep(2000))
  await(handle:stop())
end)

local fd = async(function()
  local output = await(Job { "fd", cwd = "/home/brian" }:output())
end)

a.run(rg())
