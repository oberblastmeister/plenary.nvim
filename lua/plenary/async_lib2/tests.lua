local a = require('plenary.async_lib2.async')
local util = require('plenary.async_lib2.util')

local M = {}

M.describe = function(s, async_func)
  describe(s, async_func)
end

M.it = function(s, async_func)
  it(s, util.will_block(async_func))
end

return M