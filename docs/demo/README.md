# README demo

The demo GIF in the top-level README is rendered from [`demo.html`](./demo.html), a scripted mock of Neovim with bqls.nvim. It is not a screen capture: the page draws every frame from a timestamp, so the recording needs no BigQuery credentials, costs nothing, and comes out the same every time.

`demo.html` is forked from [kitagry/bqls `docs/demo/`](https://github.com/kitagry/bqls/tree/main/docs/demo), which shows the language server features. This copy adds an Explorer scene in front for the bqls.nvim sidebar, which the server's demo does not cover. When the shared scenes change in bqls, port the change here too.

The scenes are:

1. Explorer: open the sidebar, expand `bigquery-public-data` → `samples`, and open `shakespeare`'s table document
2. Completion of tables and columns
3. Hover on a table (metadata and schema)
4. A lint warning (`null-comparison`) fixed with its quick fix
5. The dry-run cost estimate shown on save
6. `Execute Query` and the job result in a split

## Regenerating

Requirements: Node.js, [ffmpeg](https://ffmpeg.org/), and network access to Google Fonts (JetBrains Mono and Inter).

```sh
cd docs/demo
npm ci
npx playwright install chromium   # or set CHROME_PATH, see below
npm run gif                       # writes demo.gif (git-ignored)
npm run mp4                       # optional: demo.mp4 (git-ignored)
```

To use an installed Chrome or Chromium instead of the one Playwright downloads (for example on NixOS, where that one does not run), set `CHROME_PATH`:

```sh
CHROME_PATH=$(command -v google-chrome-stable) npm run gif
```

On NixOS, ffmpeg can come from a temporary shell:

```sh
CHROME_PATH=$(command -v google-chrome-stable) nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#ffmpeg -c npm run gif
```

To preview while editing, open `demo.html` in a browser; it plays in a loop.

## Publishing

The GIF does not live on `main`: plugin managers clone this repository onto every user's machine, and a ~1 MB image there would only weigh down installs. It lives on the orphan [`assets`](https://github.com/kitagry/bqls.nvim/tree/assets) branch instead, which the README links through `raw.githubusercontent.com`. A blobless clone (lazy.nvim's default) never downloads it.

To publish a new recording, commit it to that branch:

```sh
git worktree add ../bqls.nvim-assets assets
cp docs/demo/demo.gif ../bqls.nvim-assets/demo.gif
git -C ../bqls.nvim-assets commit -am "update demo.gif"
git -C ../bqls.nvim-assets push origin assets
git worktree remove ../bqls.nvim-assets
```

## Editing the demo

The timeline is the list of steps at the bottom of the `<script>` in `demo.html` (`type`, `keys`, `wait`, `scene`). The texts shown on screen must match what bqls and bqls.nvim actually produce, so update them together with the code they come from:

| On screen | Source |
| --- | --- |
| Sidebar tree, its width, and its statusline | `lua/bqls/sidebar.lua` (`render`, `M.open`) |
| Table document opened from the sidebar | `virtual_text_document_handler` / `publish_virtual_text_document_handler` in `lua/bqls/init.lua`, `convert_schema_to_markdown` in `lua/bqls/commands.lua`, and `buildBigQueryTableMetadataMarkedString` in bqls |
| Table and column completion items | bqls `langserver/internal/source/completion/table_path.go`, `completion.go` |
| Table hover | bqls `buildBigQueryTableMetadataMarkedString` and `createBigQuerySchemaMarkdownTable` in `langserver/internal/source/` |
| Lint message and quick fix | bqls `langserver/internal/lint/null_comparison.go`, `langserver/code_action.go` |
| Code action list | bqls `langserver/execute_command.go` (`Execute Query`) and Neovim's `vim.ui.select` prompt |
| Dry-run message | bqls `langserver/diagnostic.go` (`This query will process ... when run.`) |
| Job document and result table | bqls `buildBigQueryJobMarkedString` in `langserver/internal/source/project.go`, and `convert_data_to_markdown` in `lua/bqls/commands.lua` |

The table metadata and schema descriptions, the 4.88 MiB estimate, and the result rows are real values for `bigquery-public-data.samples.shakespeare`. The dataset list in the sidebar is shortened to a few real datasets around `samples` so the tree fits on screen. The job ID, timestamps, and slot milliseconds are made up, and `my-project` stands in for the billing project.
