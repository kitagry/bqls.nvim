## bqls.nvim

Neovim plugin for [BigQuery Language Server](https://github.com/kitagry/bqls).

### Prerequisites

Before using this plugin, you need to install the bqls language server:

#### Installation

1. **Via plugin manager** (Recommended):
   Use the `build` hook to automatically download the latest binary:
   ```lua
   -- lazy.nvim
   {
     "kitagry/bqls.nvim",
     build = "./install.sh",
   }
   ```

2. **Install from Releases**:
   Download the latest binary from [GitHub Releases](https://github.com/kitagry/bqls/releases) and place it in your PATH.

3. **Build from Source**:
   Requires Go 1.16 or later.
   ```bash
   go install github.com/kitagry/bqls@latest
   ```

#### Updating

`install.sh` always downloads the latest release, but plugin managers only re-run the `build` hook when the plugin itself is updated, not on every startup. To pull in a new bqls release without waiting for a plugin update:

- lazy.nvim: run `:Lazy build bqls.nvim` (or press `b` on `bqls.nvim` in the `:Lazy` UI) to re-run `install.sh`.
- Or run the script directly: `sh ~/.local/share/nvim/lazy/bqls.nvim/install.sh` (adjust the path for your plugin manager).

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
| `f` | Search tables across all projects in the sidebar |
| `q` | Close sidebar |

### Table Search

Press `f` in the sidebar to search tables across all displayed projects. Results are shown via telescope picker (falls back to `vim.ui.select` if telescope is not installed). Selecting a result opens the table in a non-sidebar window.

> **Note:** Table search requires bqls server **v0.6.0 or above**.

## Development

Run the test suite (requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)):

```sh
make test
```

To manually try changes against a real bqls server without touching your own Neovim config, use the dev entrypoint (requires a `bqls` binary on your `PATH` and [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)):

```sh
nvim -u scripts/dev_init.lua
# or against a project other than bigquery-public-data:
BQLS_PROJECT_ID=my-project nvim -u scripts/dev_init.lua
```
