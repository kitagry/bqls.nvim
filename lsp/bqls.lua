local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local local_bin = plugin_dir .. "/bin/bqls"

---@type vim.lsp.Config
return {
	cmd = vim.fn.executable(local_bin) == 1 and { local_bin } or { "bqls" },
	filetypes = { "sql" },
	root_markers = { ".git" },
	handlers = require("bqls").handlers,
	settings = {},
}
