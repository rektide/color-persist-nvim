local M = {}
local config = require('nvim-color-persist.config')

function M.parse(filepath)
  local vars = {}
  local open_ok, file = pcall(io.open, filepath, 'r')
  if not open_ok or not file then
    return vars, err
  end

  local lines_ok, lines = pcall(function() return file:lines() end)
  if not lines_ok then
    pcall(file.close, file)
    return vars, 'Failed to read file lines'
  end

  for line in lines do
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

  local close_ok, close_err = pcall(file.close, file)
  if not close_ok then
    return vars, 'Failed to close file'
  end
  
  return vars, nil
end

function M.get_system_env()
  local vars = {}
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  if vim.env[nvim_color_key] then
    vars[nvim_color_key] = vim.env[nvim_color_key]
  end
  
  if vim.env[editor_color_key] then
    vars[editor_color_key] = vim.env[editor_color_key]
  end
  
  return vars, nil
end

function M.write(filepath, vars)
  if type(vars) ~= 'table' then
    return false, 'vars must be a table'
  end
  
  local nvim_color_key = config.get_nvim_color_key()
  local editor_color_key = config.get_editor_color_key()
  
  local lines = {}
  local written = {
    [nvim_color_key] = false,
    [editor_color_key] = false,
  }
  
  local open_ok, file = pcall(io.open, filepath, 'r')
  if open_ok and file then
    local lines_ok, read_lines = pcall(function() return file:lines() end)
    if not lines_ok then
      pcall(file.close, file)
      return false, 'Failed to read file lines'
    end

    for line in read_lines do
      local trimmed = line:match("^%s*(.-)%s*$")
      local key = trimmed:match("^([^=]+)")
      if key then
        key = key:match("^%s*(.-)%s*$")
      end

      if key == nvim_color_key and vars[nvim_color_key] then
        table.insert(lines, nvim_color_key .. '=' .. vars[nvim_color_key])
        written[nvim_color_key] = true
      elseif key == editor_color_key and vars[editor_color_key] then
        table.insert(lines, editor_color_key .. '=' .. vars[editor_color_key])
        written[editor_color_key] = true
      else
        table.insert(lines, line)
      end
    end

    local close_ok, close_err = pcall(file.close, file)
    if not close_ok then
      return false, 'Failed to close file after reading'
    end
  end

  if not written[nvim_color_key] and vars[nvim_color_key] then
    table.insert(lines, nvim_color_key .. '=' .. vars[nvim_color_key])
  end
  if not written[editor_color_key] and vars[editor_color_key] then
    table.insert(lines, editor_color_key .. '=' .. vars[editor_color_key])
  end

  local write_ok, write_file = pcall(io.open, filepath, 'w')
  if not write_ok or not write_file then
    return false, 'Failed to open file for writing'
  end

  local write_success, write_err = pcall(function() return write_file:write(table.concat(lines, '\n') .. '\n') end)
  pcall(write_file.close, write_file)

  if not write_success then
    return false, 'Failed to write to env file: ' .. write_err
  end

  return true
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
