local vim = vim
local util = require("vim.lsp.util")
local commands = require("bqls.commands")

local M = {}

local function virtual_text_document_handler(uri, res, client_id)
	if not res then
		return nil
	end

	local lines = util.convert_input_to_markdown_lines(res.contents)

	local result_lines = vim.split(commands.convert_data_to_markdown(res.result), "\n")

	vim.list_extend(lines, result_lines)
	local bufnr = vim.uri_to_bufnr(uri)

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
	vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
	vim.lsp.buf_attach_client(bufnr, client_id)
end

local function definition_handler(err, result, ctx, config)
	if not result or vim.tbl_isempty(result) then
		return nil
	end

	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if not client then
		return nil
	end
	for _, res in pairs(result) do
		local uri = res.uri or res.targetUri
		if uri:match("^bqls:") then
			local params = {
				textDocument = {
					uri = uri,
				},
			}
			vim.lsp.buf_request(
				0,
				"bqls/virtualTextDocument",
				params,
				require("bqls").handlers["bqls/virtualTextDocument"]
			)
			res["uri"] = uri
			res["targetUri"] = uri
		end
	end

	vim.lsp.handlers[ctx.method](err, result, ctx, config)
end

M.handlers = {
	["workspace/executeCommand"] = function(err, result, params)
		if params.params.command == "bqls.executeQuery" then
			commands.execute_query_handler(err, result, params)
		elseif params.params.command == "bqls.listJobHistories" then
			commands.list_job_history_handler(err, result, params)
		elseif params.params.command == "bqls.saveResult" then
			commands.save_result_handler(err, result, params)
		else
			vim.lsp.handlers["workspace/executeCommand"](err, result, params)
		end
	end,
	["textDocument/definition"] = definition_handler,
	["bqls/virtualTextDocument"] = function(err, result, ctx)
		if err then
			print(err)
			return
		end

		virtual_text_document_handler(ctx.params.textDocument.uri, result, ctx.client_id)
	end,
}

return M
