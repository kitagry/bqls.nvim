local vim = vim
local lsputil = require('lspconfig.util')
local configs = require('lspconfig.configs')

configs.bqls = {
  default_config = {
    cmd = {'bqls'},
    filetypes = {'sql', 'bigquery', 'neo-tree', 'markdown'},
    root_dir = function(fname) return
      lsputil.find_git_ancestor(fname)
      or vim.fn.fnamemodify(fname, ':h')
    end,
    handlers = require('bqls').handlers
  },
}

vim.api.nvim_create_augroup('BqlsCommands', { clear = true })
vim.api.nvim_create_autocmd({'BufEnter', 'BufFilePost'}, {
  pattern = { 'bqls://*' },
  group = 'BqlsCommands',
  callback = function(ev)
    vim.api.nvim_buf_create_user_command(0, 'BqlsSave', function(args)
      if #args['fargs'] == 0 then
        vim.notify('should specify save file path', vim.log.levels.ERROR)
        return
      end

      local file_path = args['fargs'][1]
      if not file_path:match('^/.*') then
        file_path = vim.fn.getcwd() .. '/' .. file_path
      end

      vim.lsp.buf_request_all(0, 'workspace/executeCommand', {
        command = 'saveResult',
        arguments = { vim.fn.expand('%:p'), 'file://' .. file_path },
      }, function(results)
        for _, result in ipairs(results) do
          if result.error then
            vim.notify('bqls: ' .. result.error.message, vim.log.levels.ERROR)
            return
          end
        end
        vim.notify('bqls: save result to ' .. file_path, vim.log.levels.INFO)
      end)
    end, { desc = "Save bqls result", nargs = '*' })
  end
})
