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

### Optional Dependencies

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim): If installed, job history selection (e.g. `:BqlsListJobHistory`) uses a telescope picker with SQL preview. Without it, `vim.ui.select` is used as a fallback.

### Setting

If using neovim >=0.11

```lua
vim.lsp.config("bqls", {
    settings = {
        project_id = "YOUR_PROJECT_ID",
        location = "YOUR_LOCATION",
    },
})

vim.lsp.enable("bqls")
```

If using neovim <0.10

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

## BigQuery Explorer (Sidebar)

A built-in sidebar to browse projects, datasets, and tables without any extra dependencies.

### Setup

```lua
require("bqls").setup({
  project_ids = { "YOUR_GOOGLE_CLOUD_PROJECT_ID1", "YOUR_GOOGLE_CLOUD_PROJECT_ID2" },
})
```

`project_ids` defaults to `{ "bigquery-public-data" }` if not specified.

### Opening the Sidebar

```lua
require("bqls").sidebar.toggle()  -- toggle open/close
require("bqls").sidebar.open()
require("bqls").sidebar.close()
```

Example keybinding:

```lua
vim.keymap.set("n", "<leader>db", require("bqls").sidebar.toggle)
```

### Sidebar Keymaps

| Key | Action |
|-----|--------|
| `<CR>` / `o` | Expand/collapse project or dataset; open table in current window |
| `s` | Open table in horizontal split |
| `v` | Open table in vertical split |
| `f` | Search tables across sidebar projects (requires bqls v0.6.0+) |
| `q` | Close sidebar |
