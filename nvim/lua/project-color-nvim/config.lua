local M = {}

local defaults = {
  enabled = true,
  autoload = true,
  persist = true,
  key = 'color-persist',
  notify = true,
}

local config = vim.deepcopy(defaults)

function M.get()
  return vim.deepcopy(config)
end

function M.is_enabled()
  return config.enabled
end

function M.should_autoload()
  return config.autoload
end

function M.should_persist()
  return config.persist
end

function M.get_key()
  return config.key
end

function M.should_notify()
  return config.notify
end

function M.setup(opts)
  opts = opts or {}
  local errors = {}

  if opts.enabled ~= nil and type(opts.enabled) ~= 'boolean' then
    table.insert(errors, 'enabled must be a boolean')
  end

  if opts.autoload ~= nil and type(opts.autoload) ~= 'boolean' then
    table.insert(errors, 'autoload must be a boolean')
  end

  if opts.persist ~= nil and type(opts.persist) ~= 'boolean' then
    table.insert(errors, 'persist must be a boolean')
  end

  if opts.key ~= nil and type(opts.key) ~= 'string' then
    table.insert(errors, 'key must be a string')
  end

  if opts.notify ~= nil and type(opts.notify) ~= 'boolean' then
    table.insert(errors, 'notify must be a boolean')
  end

  if #errors > 0 then
    error('Configuration errors: ' .. table.concat(errors, ', '))
  end

  config = vim.tbl_deep_extend('force', defaults, opts)
end

function M.check_loaded()
  local ok, _ = pcall(require, 'project-color-nvim.config')
  return ok
end

function M.validate()
  return {
    valid = true,
    errors = {},
    warnings = {},
  }
end

return M
