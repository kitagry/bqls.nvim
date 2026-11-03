describe("lsp/bqls.lua", function()
	-- bqls rejects a settings array in workspace/didChangeConfiguration, and a
	-- plain Lua {} is encoded as one.
	it("encodes the default settings as a JSON object", function()
		local config = vim.lsp.config.bqls

		assert.are.same('{"settings":{}}', vim.json.encode({ settings = config.settings }))
	end)

	it("merges user settings over the defaults", function()
		vim.lsp.config("bqls", { settings = { project_id = "p" } })

		assert.are.same({ project_id = "p" }, vim.lsp.config.bqls.settings)
	end)
end)
