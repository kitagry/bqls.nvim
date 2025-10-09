return {
	cmd = { "bqls" },
	filetypes = { "sql" },
	root_markers = { ".git" },
	handlers = require("bqls").handlers,
	settings = {},
}
