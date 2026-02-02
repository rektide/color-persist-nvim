local M = {}

local npc = nil
local npc_loaded = false

local function ensure_npc_loaded()
  if not npc then
    local ok, result = pcall(require, 'nvim-project-config')
    if not ok then return nil, 'nvim-project-config not available' end
    npc = result
  end

  if not npc_loaded and npc then
    local ok, err = pcall(npc.setup, {})
    if not ok then return nil, 'setup failed: ' .. err end
    npc_loaded = true
  end

  return npc
end

function M.get()
  local ok, err = ensure_npc_loaded()
  if not ok then return nil, err end
  return ok
end

function M.get_ctx()
  local npc = M.get()
  if not npc or not npc.ctx then return nil end
  return npc.ctx
end

function M.load_json()
  local ctx = M.get_ctx()
  if not ctx or not ctx.json then return {} end
  return ctx.json
end

function M.save_json(data)
  local ctx = M.get_ctx()
  if not ctx then return false, 'no context' end

  if not ctx.json then
    ctx.json = {}
  end

  for k, v in pairs(data) do
    ctx.json[k] = v
  end

  return true
end

return M
