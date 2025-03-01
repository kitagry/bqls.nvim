local vim = vim
local api = vim.api

local M = {}

---@param data {columns: table<string>, data: table<table<any>>}
M.convert_data_to_markdown = function(data)
  local txt = ''
  if not data.columns or not data.data then
    return txt
  end
  for _, column in pairs(data.columns) do
    txt = txt .. '| ' .. column .. ' '
  end
  txt = txt .. ' |\n'

  for _, _ in pairs(data.columns) do
    txt = txt .. '| :---: '
  end
  txt = txt .. '|\n'

  for _, line in pairs(data.data) do
    for _, value in pairs(line) do
      if type(value) == 'boolean' then
        value = value and 'true' or 'false'
      end
      if type(value) == 'number' then
        value = tostring(value)
      end
      if type(value) == 'table' then
        value = vim.json.encode(value)
      end
      if value == vim.NIL then
        value = "NULL"
      end
      txt = txt .. '| ' .. value .. ' '
    end
    txt = txt .. ' |\n'
  end

  return txt
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
  vim.cmd('split')
  local win = api.nvim_get_current_win()
  api.nvim_win_set_buf(win, bufnr)
  vim.lsp.buf_attach_client(bufnr, params.client_id)

  local virtual_text_document_params = {
    textDocument = {
      uri = result.textDocument.uri,
    },
  }
  vim.lsp.buf_request(bufnr, 'bqls/virtualTextDocument', virtual_text_document_params, require("bqls").handlers['bqls/virtualTextDocument'])
end

---@class JobHistory
---@field textDocument `TextDocumentIdentifier`
---@field id string
---@field owner string
---@field summary string

---@param err lsp.ResponseError
---@param result {jobs: JobHistory[]}
---@param params table
M.list_job_history_handler = function(err, result, params)
  if err then
    vim.notify('bqls: ' .. err.message, vim.log.levels.ERROR)
    return
  end
  if not result then
    return
  end

  -- jump to virtual text buffer
  ---@param item JobHistory
  local on_choice = function(item)
    local bufnr = vim.uri_to_bufnr(item.textDocument.uri)
    vim.cmd('split')
    local win = api.nvim_get_current_win()
    api.nvim_win_set_buf(win, bufnr)
    vim.lsp.buf_attach_client(bufnr, params.client_id)

    local virtual_text_document_params = {
      textDocument = {
        uri = item.textDocument.uri,
      },
    }
    vim.lsp.buf_request(bufnr, 'bqls/virtualTextDocument', virtual_text_document_params, require("bqls").handlers['bqls/virtualTextDocument'])
  end

  -- format item
  ---@param item JobHistory
  local format_item = function(item)
    return item.summary:gsub('\n', ' ')
  end

  vim.ui.select(result.jobs, { prompt = "Select a job", format_item = format_item }, on_choice)
end

---@param err lsp.ResponseError
---@param result {url: string}
---@param params table
M.save_result_handler = function(err, result, params)
  if err then
    vim.notify('bqls: ' .. err.message, vim.log.levels.ERROR)
    return
  end
  if not result then
    return
  end
  vim.notify('bqls: save result to ' .. result.url, vim.log.levels.INFO)
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
