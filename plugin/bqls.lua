local vim = vim
local configs = require('lspconfig.configs')

configs.bqls = {
  default_config = {
    cmd = {'bqls'},
    filetypes = {'sql', 'bigquery'},
    handlers = require('bqls').handlers,
    single_file_support=true
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
      if not file_path:match('^.+://.*') then
        if not file_path:match('^/.*') then
          file_path = vim.fn.getcwd() .. '/' .. file_path
        end
        file_path = 'file://' .. file_path
      end

      vim.lsp.buf_request(0, 'workspace/executeCommand', {
        command = 'bqls.saveResult',
        arguments = { vim.fn.expand('%:p'), file_path },
      }, require('bqls').handlers['workspace/executeCommand'])
    end, { desc = "Save bqls result", nargs = '*' })
  end
})
