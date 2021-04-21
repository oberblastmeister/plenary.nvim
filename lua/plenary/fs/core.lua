local a = require('plenary.async_lib')
local async, await = a.async, a.await
local tbl = require('plenary.tbl')

local fs = {}

do
  local Stats = {}
  Stats.__index = Stats

  function Stats:is_file()
    return self.type == "file"
  end

  function Stats:is_dir()
    return self.type == "directory"
  end

  local newStats = function(raw_stats)
    return tbl.freeze(setmetatable(raw_stats, Stats))
  end

  fs.stat = async(function(path)
    local err, stats = await(a.uv.fs_stat(path))
    if err then
      return err, nil
    end
    return err, newStats(stats)
  end)
end

return fs
