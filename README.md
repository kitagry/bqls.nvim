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

## Execute Query

You can choose `lua vim.lsp.buf.code_action()`.
In order to save result to local file, you can use `:BqlsSave ./path/to/file.csv`.

https://github.com/user-attachments/assets/2f5aef83-f341-4c04-bb37-88db45badb6d

## BigQuery Explorer

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

![image](https://github.com/user-attachments/assets/83d37922-50fa-4c24-b9fd-7355238328fa)
