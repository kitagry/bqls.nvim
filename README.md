## bqls.nvim

Neovim plugin for [BigQuery Language Server](https://github.com/kitagry/bqls).

### Prerequisites

Before using this plugin, you need to install the bqls language server:

#### Requirements
- Go 1.16 or later
- CGO enabled (`CGO_ENABLED=1`)
- Recommended: `clang++` compiler

#### Installation

1. **Install from Releases** (Recommended):
   Download the latest binary from [GitHub Releases](https://github.com/kitagry/bqls/releases) and place it in your PATH.

2. **Build from Source**:
   ```bash
   export CGO_ENABLED=1
   export CXX=clang++
   go install github.com/kitagry/bqls@latest
   ```

#### Authentication

Login to BigQuery API:
```bash
gcloud auth login
gcloud auth application-default login
```

### Setting

```lua
require("lspconfig").bqls.setup({
  settings = {
    project_id = "YOUR_PROJECT_ID",
    location = "YOUR_LOCATION"
  }
})
```

If you change project_id or location after vim started:

```lua
vim.lsp.buf_notify(0, "workspace/didChangeConfiguration", {
  settings = {
    project_id = "ANOTHER_PROJECT_ID",
    location = "ANOTHER_LOCATION"
  }
})
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
