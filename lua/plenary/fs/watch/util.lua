local M = {}

do
  local throttled = {}

  M.throttle = function(action_type, path, timeout)
    if throttled[action_type] == nil then
      throttled[action_type] = {}
    end

    local action = throttled[action_type]
    local action_path = action[path]

    if action_path then
      return false
    end

    vim.defer_fn(function()
      action[path] = nil
    end, timeout)

    action[path] = true

    return true
  end
end

return M
