local uv = vim.loop
local errors = require('plenary/errors')
local todo = errors.todo
local a = require('plenary.async_lib')
local fs = require('plenary/fs/core')
local util = require('plenary/fs/watch/util')
local async, await, async_void = a.async, a.await, a.async_void
local throttle = util.throttle

local IS_LINUX = jit.os == "Linux"
local THROTTLE_MODE_WATCH = 'WATCH'

local closers = {}

local function close_file(file)
  local closer = closers[file]
  if closer == nil then return end
  if not closer:is_closing() then
    closer:close()
  end
  closers[file] = nil
end

local function add_path_closer(path, closer)
  closers[path] = closer
end

local function remove()
end

local function watch(path, listener)
  local handle = uv.new_fs_event()
  handle:start(path, {}, listener)
  return handle
end

local function handle_file(file, stats, initial_add)
  local prev_stats = stats

  local listener
  listener = async_void(function(err, _filename, _events)
    assert(not err, err)

    if not throttle(THROTTLE_MODE_WATCH, file, 5) then return end

    local err, new_stats = await(fs.stat(file))
    if err then
      close_file(file)
      print('remove')
      return
    end

    local at = new_stats.atime.nsec
    local mt = new_stats.mtime.nsec
    if not at or at <= mt or mt ~= prev_stats.mtime.nsec then
      print('change')
    end

    if IS_LINUX and (prev_stats.ino ~= new_stats.ino) then
      close_file(file)
      prev_stats = new_stats;
      add_path_closer(file, watch(file, listener))
    else
      prev_stats = new_stats;
    end

  end)

  local closer = watch(file, listener)
  add_path_closer(closer)
end

local add = async(function(path, initial_add)
  local err, stats = await(fs.stat(path))
  assert(not err, err)

  if stats:is_dir() then
    todo()
  elseif stats:is_file() then
    handle_file(path, stats, initial_add)
  else
    todo()
  end
end)

a.run(add("/home/brian/testing_file"))
