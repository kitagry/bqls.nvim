local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local local_bin = plugin_dir .. "/bin/bqls"

---@type vim.lsp.Config
return {
	cmd = vim.fn.executable(local_bin) == 1 and { local_bin } or { "bqls" },
	filetypes = { "sql" },
	root_markers = { ".git" },
	handlers = require("bqls").handlers,
	-- A plain {} is encoded as a JSON array, which bqls rejects as settings.
	settings = vim.empty_dict(),
	init_options = { supports_async_virtual_text_document = true },
}
