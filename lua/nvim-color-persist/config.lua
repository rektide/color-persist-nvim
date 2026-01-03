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
  config = vim.tbl_deep_extend('force', defaults, opts)
end

return M
