local util = require("bqls.util")

describe("bqls.util.bqls_request", function()
	local original_get_clients
	local original_notify

	before_each(function()
		original_get_clients = vim.lsp.get_clients
		original_notify = vim.notify
	end)

	after_each(function()
		vim.lsp.get_clients = original_get_clients
		vim.notify = original_notify
	end)

	it("sends the request only to the client named bqls, not every attached client", function()
		local requested
		local get_clients_opts
		local bqls_client = {
			request = function(self, method, params, handler, bufnr)
				requested = { method = method, params = params, bufnr = bufnr }
			end,
		}

		vim.lsp.get_clients = function(opts)
			get_clients_opts = opts
			return { bqls_client }
		end

		local params = { textDocument = { uri = "bqls://project/foo" } }
		util.bqls_request(3, "bqls/virtualTextDocument", params, function() end)

		assert.are.same(
			"bqls",
			get_clients_opts.name,
			"expected clients to be looked up by name=bqls instead of broadcasting to every attached client"
		)
		assert.are.same({
			method = "bqls/virtualTextDocument",
			params = params,
			bufnr = 3,
		}, requested, "expected the bqls client to receive the request with the original method/params/bufnr")
	end)

	it("does not send a request when no bqls client is attached", function()
		vim.lsp.get_clients = function()
			return {}
		end

		local notified = false
		vim.notify = function()
			notified = true
		end

		local handler_called = false
		util.bqls_request(3, "bqls/virtualTextDocument", {}, function()
			handler_called = true
		end)

		assert.is_true(notified, "expected a notification when no bqls client is attached")
		assert.is_false(handler_called, "handler must not run since no request was ever sent")
	end)
end)
