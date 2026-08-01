-- Manual smoke-test entrypoint for bqls.nvim: loads the plugin straight
-- from this checkout (no plugin manager / no reinstall step) so a change
-- can be tried against a real bqls server and BigQuery project.
--
-- Usage (from the plugin root):
--   nvim -u scripts/dev_init.lua
--
-- Override the BigQuery project (defaults to "bigquery-public-data"):
--   BQLS_PROJECT_ID=my-project nvim -u scripts/dev_init.lua

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(plugin_root)

-- plugin/bqls.lua registers the "bqls" server via lspconfig.configs, so
-- nvim-lspconfig needs to be reachable too. Reuse whatever copy the
-- user's real config already manages instead of vendoring one here.
local lspconfig_path = vim.fn.stdpath("data") .. "/lazy/nvim-lspconfig"
if vim.fn.isdirectory(lspconfig_path) == 1 then
	vim.opt.rtp:append(lspconfig_path)
else
	vim.notify(
		"dev_init: nvim-lspconfig not found at " .. lspconfig_path .. "; install it or edit this script",
		vim.log.levels.WARN
	)
end

vim.cmd("runtime! plugin/**/*.lua")

local project_id = os.getenv("BQLS_PROJECT_ID") or "bigquery-public-data"

vim.lsp.config("bqls", {
	init_options = { project_id = project_id },
})
vim.lsp.enable("bqls")

require("bqls").setup({ project_ids = { project_id } })

vim.keymap.set("n", "<leader>db", function()
	require("bqls").sidebar.toggle()
end, { silent = true, desc = "Toggle BigQuery sidebar" })

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		require("bqls").sidebar.open()
	end,
})
