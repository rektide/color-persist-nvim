local M = {}
local config = require('nvim-color-persist.config')

function M.parse(filepath)
  local vars = {}
  local file = io.open(filepath, 'r')
  if not file then
    return vars
  end

  for line in file:lines() do
    line = line:match("^%s*(.-)%s*$")
    if line ~= '' and not line:match("^#") then
      local key, value = line:match("^([^=]+)=(.*)$")
      if key and value then
        key = key:match("^%s*(.-)%s*$")
        value = value:match("^%s*(.-)%s*$")
        if key then
          vars[key] = value
        end
      end
    end
  end

  file:close()
  return vars
end

function M.write(filepath, vars)
  if type(vars) ~= 'table' then
    error('vars must be a table')
  end
  
  local file = io.open(filepath, 'r')
  if not file then
    return
  end
  
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  local lines = {}
  
  for line in file:lines() do
    local trimmed = line:match("^%s*(.-)%s*$")
    local key = trimmed:match("^([^=]+)")
    if key then
      key = key:match("^%s*(.-)%s*$")
    end
    
    if key == nvim_color_key or key == editor_color_key then
      table.insert(lines, '')
    else
      table.insert(lines, line)
    end
  end
  file:close()

  if vars[nvim_color_key] then
    table.insert(lines, nvim_color_key .. '=' .. vars[nvim_color_key])
  end
  if vars[editor_color_key] then
    table.insert(lines, editor_color_key .. '=' .. vars[editor_color_key])
  end

  file = io.open(filepath, 'w')
  if file then
    for _, line in ipairs(lines) do
      file:write(line .. '\n')
    end
    file:close()
  else
    error('Failed to write to env file: ' .. filepath)
  end
end

function M.get_filepath()
  local env_file = config.get_env_file()
  return vim.loop.cwd() .. '/' .. env_file
end

function M.get_file_status()
  local filepath = M.get_filepath()
  local stat = vim.loop.fs_stat(filepath)
  
  if stat then
    stat.path = filepath
  end
  
  return stat
end

function M.validate_vars(vars)
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  return {
    has_nvim_color = vars[nvim_color_key] and vars[nvim_color_key] ~= '',
    has_editor_value = vars[editor_color_key] and vars[editor_color_key] ~= '',
  }
end

return M
