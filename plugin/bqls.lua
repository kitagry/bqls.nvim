local vim = vim
local lsputil = require('lspconfig.util')
local configs = require('lspconfig.configs')

configs.bqls = {
  default_config = {
    cmd = {'bqls'},
    filetypes = {'sql', 'bigquery', 'neo-tree', 'bqls'},
    root_dir = function(fname) return
      lsputil.find_git_ancestor(fname)
      or vim.fn.fnamemodify(fname, ':h')
    end,
    handlers = require('bqls').handlers
  },
}
