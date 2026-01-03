local M = {}
local config = {
  env_file = '.env.editor',
  augroup = 'NvimColorPersist'
}

local function get_theme_name()
  return vim.g.colors_name or ''
end

local function parse_env_file(filepath)
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

local function write_env_file(filepath, vars)
  local lines = {}
  local file = io.open(filepath, 'r')
  
  if file then
    for line in file:lines() do
      local trimmed = line:match("^%s*(.-)%s*$")
      local key = trimmed:match("^([^=]+)")
      if key then
        key = key:match("^%s*(.-)%s*$")
      end
      
      if key == 'NVIM_COLOR' or key == 'EDITOR_COLOR' then
        table.insert(lines, '')
      else
        table.insert(lines, line)
      end
    end
    file:close()
  end

  if vars.NVIM_COLOR then
    table.insert(lines, 'NVIM_COLOR=' .. vars.NVIM_COLOR)
  end
  if vars.EDITOR_COLOR then
    table.insert(lines, 'EDITOR_COLOR=' .. vars.EDITOR_COLOR)
  end

  file = io.open(filepath, 'w')
  if file then
    for _, line in ipairs(lines) do
      file:write(line .. '\n')
    end
    file:close()
  end
end

local function load_theme(theme_name)
  if theme_name and theme_name ~= '' then
    local ok = pcall(vim.cmd.colorscheme, theme_name)
    if not ok then
      vim.notify('Failed to load theme: ' .. theme_name, vim.log.levels.WARN)
    end
  end
end

local function setup_autocmd()
  vim.api.nvim_create_augroup(config.augroup, { clear = true })

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = config.augroup,
    callback = function()
      local current_theme = get_theme_name()
      if current_theme == '' then
        return
      end

      local env_file = vim.loop.cwd() .. '/' .. config.env_file
      local vars = parse_env_file(env_file)
      
      vars.NVIM_COLOR = current_theme
      
      if not vars.EDITOR_COLOR or vars.EDITOR_COLOR == current_theme then
        vars.EDITOR_COLOR = current_theme
      end
      
      write_env_file(env_file, vars)
    end,
  })
end

local function load_from_env()
  local env_file = vim.loop.cwd() .. '/' .. config.env_file
  local vars = parse_env_file(env_file)
  
  if vars.NVIM_COLOR and vars.NVIM_COLOR ~= '' then
    load_theme(vars.NVIM_COLOR)
  elseif vars.EDITOR_COLOR and vars.EDITOR_COLOR ~= '' then
    load_theme(vars.EDITOR_COLOR)
  end
end

function M.setup(opts)
  opts = opts or {}
  if opts.env_file then
    config.env_file = opts.env_file
  end

  load_from_env()
  setup_autocmd()
end

return M
