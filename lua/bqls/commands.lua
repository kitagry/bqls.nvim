local vim = vim
local api = vim.api

local M = {}

---@param bufnr integer
---@param result table
local function write_result(bufnr, result)
  if not result then
      return
  end

  local txt = ''
  for _, column in pairs(result.columns) do
    txt = txt .. column .. ' | '
  end
  txt = string.sub(txt, 1, #txt - 3) .. '\n'

  local i = 0
  for _, line in pairs(result.data) do
    if i > 100 then
      txt = txt .. '...\n'
      break
    end

    for _, value in pairs(line) do
      if type(value) == 'boolean' then
        value = value and 'true' or 'false'
      end
      if type(value) == 'number' then
        value = tostring(value)
      end
      if value == vim.NIL then
        value = "NULL"
      end
      txt = txt .. value .. ' | '
    end
    txt = string.sub(txt, 1, #txt - 3) .. '\n'
    i = i + 1
  end

  api.nvim_buf_set_lines(bufnr, 0, 1, false, vim.split(txt, '\n'))
  api.nvim_buf_set_option(bufnr, 'readonly', true)
  api.nvim_buf_set_option(bufnr, 'modified', false)
  api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

---@param err lsp.ResponseError
---@param result any
---@param params table
M.execute_query_handler = function(err, result, params)
  if err then
    vim.notify('bqls: ' .. err.message, vim.log.levels.ERROR)
    return
  end
  if not result then
    return
  end

  local bufnr = vim.uri_to_bufnr(result.textDocument.uri)
  local current_buf = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #current_buf == 0 then
    write_result(bufnr, result.result)
    vim.lsp.buf_attach_client(bufnr, params.client_id)
  end

  vim.cmd('split')
  local win = api.nvim_get_current_win()
  api.nvim_win_set_buf(win, bufnr)
end

---@param project_id string Google Cloud project id
---@param callback fun(request_results: table<integer, {error: lsp.ResponseError, result: any}>) (function)
--- The callback to call when all requests are finished.
--- Unlike `buf_request`, this will collect all the responses from each server instead of handling them.
--- A map of client_id:request_result will be provided to the callback.
M.execute_list_datasets = function(project_id, callback)
  vim.lsp.buf_request_all(0, 'workspace/executeCommand', {
    command = 'listDatasets',
    arguments = { project_id },
  }, callback)
end

---@param project_id string Google Cloud project id
---@param dataset_id string Google Cloud project id
---@param callback fun(request_results: table<integer, {error: lsp.ResponseError, result: any}>) (function)
--- The callback to call when all requests are finished.
--- Unlike `buf_request`, this will collect all the responses from each server instead of handling them.
--- A map of client_id:request_result will be provided to the callback.
M.execute_list_tables = function(project_id, dataset_id, callback)
  vim.lsp.buf_request_all(0, 'workspace/executeCommand', {
    command = 'listTables',
    arguments = { project_id, dataset_id },
  }, callback)
end

M.exec = function (cmd)
  local result = vim.fn.systemlist(cmd)
  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, result)
  api.nvim_buf_set_option(bufnr, 'readonly', true)
  api.nvim_buf_set_option(bufnr, 'modified', false)
  api.nvim_buf_set_option(bufnr, 'modifiable', false)
  api.nvim_set_current_buf(bufnr)
end

return M
