local a = require('plenary.async_lib')
local async, await = a.async, a.await
local await_all = a.await_all
local channel = a.util.channel
local protected = a.util.protected

local eq = function(a, b)
  assert.are.same(a, b)
end

describe('async await', function()
  it('should block_on', function()
    local fn = async(function()
      await(a.util.sleep(100))
      return 'hello'
    end)

    local res = a.block_on(fn())
    eq(res, 'hello')
  end)

  describe('protect', function()
    it('should be able to protect a non-leaf future', function()
      local fn = async(function()
        error("This should error")
        return 'return'
      end)

      local main = async(function()
        local stat, ret = await(a.util.protected_non_leaf(fn()))
        eq(false, stat)
        assert(ret:match("This should error"))
        return 'hello'
      end)

      local res = a.block_on(main())
      eq(res, 'hello')
    end)

    it('should be able to protect a non-leaf future that doesnt fail', function()
      local fn = async(function()
        return 'didnt fail'
      end)

      local main = async(function()
        local stat, ret = await(a.util.protected_non_leaf(fn()))
        eq(stat, true)
        eq(ret, 'didnt fail')
      end)

      a.block_on(main())
    end)

    it('should be able to protect a leaf future', function()
      local fn = a.wrap(function(callback)
        error("This should error")
        callback()
      end, 1)

      local main = async(function()
        local stat, ret = await(a.util.protected(fn()))
        eq(stat, false)
        assert(ret:match("This should error") ~= nil)
      end)

      a.block_on(main())
    end)

    it('should be able to protect a leaf future that doesnt fail', function()
      local fn = a.wrap(function(callback)
        callback('didnt fail')
      end, 1)

      local main = async(function()
        local stat, ret = await(a.util.protected(fn()))
        eq(stat, true)
        eq(ret, 'didnt fail')
      end)

      a.block_on(main())
    end)

    it('should be able to protect a oneshot channel that was called twice', function ()
      local main = async(function()
        local tx, rx = channel.oneshot()
        tx(true)
        await(rx())
        local stat, ret = await(protected(rx()))
        eq(stat, false)
        assert(ret:match('Oneshot channel can only receive one value!'))
      end)

      a.block_on(main())
    end)
  end)
end)
