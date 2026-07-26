local M = {}

--- `bqls/*` methods are custom LSP methods that only the bqls server
--- understands. `vim.lsp.buf_request` broadcasts to every client attached
--- to the buffer, so other clients (e.g. copilot) reply with MethodNotFound.
--- Send these requests to the bqls client specifically instead.
---@param bufnr integer
---@param method string
---@param params table
---@param handler function
function M.bqls_request(bufnr, method, params, handler)
	local client = vim.lsp.get_clients({ name = "bqls" })[1]
	if not client then
		vim.notify("bqls: bqls client is not attached", vim.log.levels.ERROR)
		return
	end
	client:request(method, params, handler, bufnr)
end

return M
