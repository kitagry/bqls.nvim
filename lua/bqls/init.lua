local vim = vim
local commands = require('bqls.commands')

local M = {}

M.handlers = {
  ['workspace/executeCommand'] = function(err, result, params)
    if params.params.command == 'executeQuery' then
      commands.execute_query_handler(err, result, params)
    else
      vim.lsp.handlers['workspace/executeCommand'](err, result, params)
    end
  end,
}

return M
