local vim = vim
local configs = require("lspconfig.configs")

local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local local_bin = plugin_dir .. "/bin/bqls"

configs.bqls = {
	default_config = {
		cmd = vim.fn.executable(local_bin) == 1 and { local_bin } or { "bqls" },
		filetypes = { "sql", "bigquery" },
		handlers = require("bqls").handlers,
		single_file_support = true,
	},
}

vim.api.nvim_create_augroup("BqlsCommands", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost" }, {
	pattern = { "bqls://*" },
	group = "BqlsCommands",
	callback = function(ev)
		vim.api.nvim_buf_create_user_command(0, "BqlsSave", function(args)
			if #args["fargs"] == 0 then
				vim.notify("should specify save file path", vim.log.levels.ERROR)
				return
			end

			local file_path = args["fargs"][1]
			if not file_path:match("^.+://.*") then
				if not file_path:match("^/.*") then
					file_path = vim.fn.getcwd() .. "/" .. file_path
				end
				file_path = "file://" .. file_path
			end

			vim.lsp.buf_request(0, "workspace/executeCommand", {
				command = "bqls.saveResult",
				arguments = { vim.fn.expand("%:p"), file_path },
			}, require("bqls").handlers["workspace/executeCommand"])
		end, { desc = "Save bqls result", nargs = "*" })
	end,
})
vim.api.nvim_create_autocmd("BufNew", {
	pattern = { "bqls://*" },
	group = "BqlsCommands",
	callback = function(ev)
		local params = {
			textDocument = {
				uri = ev.file,
			},
		}
		vim.lsp.buf_request(0, "bqls/virtualTextDocument", params, require("bqls").handlers["bqls/virtualTextDocument"])
	end,
})
