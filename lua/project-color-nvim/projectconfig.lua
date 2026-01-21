local M = {}

function M.get()
  local ok, pc = pcall(require, 'nvim-projectconfig')
  if not ok then return nil, "nvim-projectconfig not available" end
  return pc
end

function M.read()
  local pc, err = M.get()
  if not pc then return {}, err end
  local ok, data = pcall(pc.load_json)
  if not ok or not data then return {}, nil end
  return data, nil
end

function M.write(data)
  local pc, err = M.get()
  if not pc then return false, err end
  local ok, save_err = pcall(pc.save_json, data)
  return ok, save_err
end

return M
