local co = coroutine
local vararg = require('plenary.vararg')
local errors = require('plenary.errors')
local traceback_error = errors.traceback_error
local f = require('plenary.functional')

local M = {}

---because we can't store varargs
local function callback_or_next(step, thread, callback, ...)
  local stat = f.first(...)

  if not stat then
    error(string.format("The coroutine failed with this message: %s", f.second(...)))
  end

  if co.status(thread) == "dead" then
    (callback or function() end)(select(2, ...))
  else
    local returned_function = f.second(...)
    assert(type(returned_function) == "function", "type error :: expected func")
    local stat, msg = pcall(returned_function, vararg.rotate(step, select(3, ...)))
    if not stat then
      error(('Failed to call leaf async function: %s'):format(msg))
    end
  end
end

---@class Future
---Something that will give a value when run

---Executes a future with a callback when it is done
---@param async_function Future: the future to execute
---@param callback function: the callback to call when done
local execute = function(async_function, callback)
  assert(type(async_function) == "function", "type error :: expected func")

  local thread = co.create(async_function)

  local step
  step = function(...)
    callback_or_next(step, thread, callback, co.resume(thread, ...))
  end

  step()
end

local add_leaf_function
do
  ---A table to store all leaf async functions
  local leaf_table = setmetatable({}, {
    __mode = "k",
  })

  add_leaf_function = function(async_func)
    assert(leaf_table[async_func] == nil, "Async function should not already be in the table")
    leaf_table[async_func] = true
  end

  function M.is_leaf_function(async_func)
    return leaf_table[async_func] ~= nil
  end
end

---Creates an async function with a callback style function.
---@param func function: A callback style function to be converted. The last argument must be the callback.
---@param argc number: The number of arguments of func. Must be included.
---@return function: Returns an async function
M.wrap = function(func, argc)
  if type(func) ~= "function" then
    traceback_error("type error :: expected func, got " .. type(func))
  end

  if type(argc) ~= "number" then
    traceback_error("type error :: expected number, got " .. type(argc))
  end

  local function leaf(...)
    return co.yield(func, ...)
  end

  add_leaf_function(leaf)

  return leaf
end

---Use this to either run a future concurrently and then do something else
---or use it to run a future with a callback in a non async context
---@param future Future
---@param callback function
M.run = function(async_function, callback)
  if M.is_leaf_function(async_function) then
    async_function(callback)
  else
    execute(async_function, callback)
  end
end

---Doenst do anything, just for compat
M.await = function(...)
  return ...
end

---Same as await but can await multiple futures.
---If the futures have libuv leaf futures they will be run concurrently
---@param futures table
---@return table: returns a table of results that each future returned. Note that if the future returns multiple values they will be packed into a table.
M.await_all = function(futures)
  assert(type(futures) == "table", "type error :: expected table")
  return M.await(M.join(futures))
end

M.void = function(async_func)
  return co.wrap(function(...)
    return async_func(...)
  end)
end

---creates an async function
---@param func function
---@return function: returns an async function
M.async = function(func)
  return func
end

---An async function that when awaited will await the scheduler to be able to call the api.
M.scheduler = M.wrap(vim.schedule, 1)

return M