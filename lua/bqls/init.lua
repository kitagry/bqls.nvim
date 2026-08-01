local vim = vim
local util = require("vim.lsp.util")
local commands = require("bqls.commands")

local M = {}

M.sidebar = require("bqls.sidebar")

M.setup = function(config)
	M.sidebar.setup(config)
end

-- Details received via bqls/publishVirtualTextDocument, keyed by uri, held
-- until the matching preview notification arrives so the two can be
-- rendered together in the same buffer.
local pending_details = {}

local function write_virtual_document(bufnr, lines, client_id)
	-- A buffer whose contents already arrived (e.g. "details") is
	-- readonly, so re-enable writes before overwriting it with the next
	-- notification (e.g. "preview") to avoid a W10 warning.
	vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })
	vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
	vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
	vim.lsp.buf_attach_client(bufnr, client_id)
end

local function virtual_text_document_handler(uri, res, client_id)
	if not res then
		return nil
	end

	local bufnr = vim.uri_to_bufnr(uri)

	if res.pending then
		-- Discard details from any earlier fetch of this uri: the server
		-- only publishes notifications for the latest request, so a stale
		-- cache entry here would otherwise leak into the next preview.
		pending_details[uri] = nil
		write_virtual_document(bufnr, { "Loading..." }, client_id)
		return
	end

	local lines = util.convert_input_to_markdown_lines(res.contents)

	local schema_markdown = commands.convert_schema_to_markdown(res.schema)
	if schema_markdown ~= "" then
		vim.list_extend(lines, { "", "### Schema", "" })
		vim.list_extend(lines, vim.split(schema_markdown, "\n"))
	end

	local result_lines = vim.split(commands.convert_data_to_markdown(res.result), "\n")

	vim.list_extend(lines, result_lines)
	write_virtual_document(bufnr, lines, client_id)
end

local function publish_virtual_text_document_handler(_, params, ctx)
	local uri = params.textDocument.uri
	local bufnr = vim.uri_to_bufnr(uri)

	if params.error then
		pending_details[uri] = nil
		write_virtual_document(bufnr, { "Error: " .. params.error }, ctx.client_id)
		return
	end

	if params.kind == "details" then
		local lines = util.convert_input_to_markdown_lines(params.contents)

		local schema_markdown = commands.convert_schema_to_markdown(params.schema)
		if schema_markdown ~= "" then
			vim.list_extend(lines, { "", "### Schema", "" })
			vim.list_extend(lines, vim.split(schema_markdown, "\n"))
		end

		pending_details[uri] = lines
		local buffer_lines = vim.list_extend({}, lines)
		vim.list_extend(buffer_lines, { "", "Loading preview..." })
		write_virtual_document(bufnr, buffer_lines, ctx.client_id)
	elseif params.kind == "preview" then
		local lines = pending_details[uri] or {}
		pending_details[uri] = nil
		local result_lines = vim.split(commands.convert_data_to_markdown(params.result), "\n")
		vim.list_extend(lines, result_lines)
		write_virtual_document(bufnr, lines, ctx.client_id)
	end
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
			client:request("bqls/virtualTextDocument", params, require("bqls").handlers["bqls/virtualTextDocument"], 0)
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
	["bqls/publishVirtualTextDocument"] = publish_virtual_text_document_handler,
}

return M
