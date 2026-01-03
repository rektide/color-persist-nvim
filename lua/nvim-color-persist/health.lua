local M = {}

local function check_plugin_loaded()
  local ok, _ = pcall(require, "nvim-color-persist")
  if ok then
    vim.health.ok("nvim-color-persist plugin loaded")
    return true
  else
    vim.health.error("nvim-color-persist plugin not loaded")
    return false
  end
end

local function check_theme_status()
  local theme_name = vim.g.colors_name
  if theme_name then
    vim.health.ok("Current theme: " .. theme_name)
  else
    vim.health.warn("No theme loaded")
  end
end

local function check_env_file()
  local ok, module = pcall(require, "nvim-color-persist")
  if not ok then
    vim.health.info("Cannot check env file (module not loaded)")
    return
  end

  local env_file = vim.loop.cwd() .. "/.env.editor"
  local stat = vim.loop.fs_stat(env_file)

  if stat then
    if stat.type == "file" then
      vim.health.ok("Env file exists: " .. env_file)
      
      local file = io.open(env_file, "r")
      if file then
        local has_nvim_color = false
        local has_editor_color = false
        
        for line in file:lines() do
          if line:match("^NVIM_COLOR=") then
            has_nvim_color = true
            local value = line:match("^NVIM_COLOR=(.*)$")
            if value and value ~= "" then
              vim.health.ok("NVIM_COLOR set to: " .. value)
            else
              vim.health.warn("NVIM_COLOR is empty")
            end
          elseif line:match("^EDITOR_COLOR=") then
            has_editor_color = true
            local value = line:match("^EDITOR_COLOR=(.*)$")
            if value and value ~= "" then
              vim.health.ok("EDITOR_COLOR set to: " .. value)
            else
              vim.health.warn("EDITOR_COLOR is empty")
            end
          end
        end
        file:close()
        
        if not has_nvim_color then
          vim.health.info("NVIM_COLOR not set in env file")
        end
        if not has_editor_color then
          vim.health.info("EDITOR_COLOR not set in env file")
        end
      else
        vim.health.warn("Could not open env file for reading")
      end
    else
      vim.health.error("Env file exists but is not a regular file: " .. env_file)
    end
  else
    vim.health.info("No env file found: " .. env_file)
  end
end

local function check_autocmd()
  local ok = pcall(vim.api.nvim_get_autocmds, {
    group = "NvimColorPersist",
    event = "ColorScheme"
  })
  
  if ok then
    vim.health.ok("ColorScheme autocmd registered")
  else
    vim.health.error("ColorScheme autocmd not registered")
  end
end

function M.check()
  vim.health.start("nvim-color-persist")

  check_plugin_loaded()
  check_theme_status()
  check_env_file()
  check_autocmd()
end

return M
