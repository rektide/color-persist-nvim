local M = {}

local defaults = {
  env_file = '.env.editor',
  augroup = 'NvimColorPersist',
  nvim_color_key = 'NVIM_COLOR',
  editor_color_key = 'EDITOR_COLOR',
}

local config = vim.deepcopy(defaults)

function M.get()
  return vim.deepcopy(config)
end

function M.get_env_file()
  return config.env_file
end

function M.get_augroup()
  return config.augroup
end

function M.get_nvim_color_key()
  return config.nvim_color_key
end

function M.get_editor_color_key()
  return config.editor_color_key
end

function M.setup(opts)
  opts = opts or {}
  local errors = {}
  
  if opts.env_file and type(opts.env_file) ~= 'string' then
    table.insert(errors, 'env_file must be a string')
  end
  
  if opts.augroup and type(opts.augroup) ~= 'string' then
    table.insert(errors, 'augroup must be a string')
  end
  
  if #errors > 0 then
    error('Configuration errors: ' .. table.concat(errors, ', '))
  end
  
  config = vim.tbl_deep_extend('force', defaults, opts)
end

function M.check_loaded()
  local ok, _ = pcall(require, 'nvim-color-persist.config')
  return ok
end

function M.validate()
  local results = {
    valid = true,
    errors = {},
    warnings = {},
  }
  
  if type(config.env_file) ~= 'string' or config.env_file == '' then
    table.insert(results.errors, 'env_file must be a non-empty string')
    results.valid = false
  end
  
  if type(config.augroup) ~= 'string' or config.augroup == '' then
    table.insert(results.errors, 'augroup must be a non-empty string')
    results.valid = false
  end
  
  return results
end

return M
