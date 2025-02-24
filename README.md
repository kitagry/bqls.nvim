## bqls.nvim

Neovim plugin for [BigQuery Language Server](https://github.com/kitagry/bqls).

### Setting

```lua
require("lspconfig").bqls.setup{
    settings = {
      project_id = "YOUR_GOOGLE_CLOUD_PROJECT_ID",
    }
}
```

If you change project_id after vim started.

```vim
:lua vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", {settings = {project_id = "YOUR_GOOGLE_CLOUD_PROJECT_ID"}})
```

If you want to show by [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim).

```lua
require("neo-tree").setup({
    sources = {
      "filesystem",
      "buffers",
      "git_status",
      "bqls"
    },
    bqls = {
      project_ids = { "YOUR_GOOGLE_CLOUD_PROJECT_ID1", "YOUR_GOOGLE_CLOUD_PROJECT_ID2" },  -- default is {"bigquery-public-data"}
    },
})
```

And then, you can open dataset and table by `:Neotree bqls`.
