local bqls = require("bqls")

local function get_lines(bufnr)
	return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

describe("bqls/virtualTextDocument handler", function()
	it("renders contents and result synchronously when the response is not pending", function()
		local uri = "bqls://project/p/dataset/d/table/sync"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/virtualTextDocument"](nil, {
			contents = { "# sync table" },
			result = { columns = { "id" }, data = { { 1 } } },
		}, {
			client_id = 0,
			params = { textDocument = { uri = uri } },
		})

		local lines = get_lines(bufnr)
		assert.are.same("# sync table", lines[1])
		assert.is_true(vim.tbl_contains(lines, "| id  |"), "expected the result table header in the buffer")
	end)

	it("renders the table schema when the response includes one", function()
		local uri = "bqls://project/p/dataset/d/table/schema"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/virtualTextDocument"](nil, {
			contents = { "# schema table" },
			schema = {
				{ name = "id", type = "INTEGER", required = true },
			},
			result = { columns = { "id" }, data = { { 1 } } },
		}, {
			client_id = 0,
			params = { textDocument = { uri = uri } },
		})

		local lines = get_lines(bufnr)
		assert.is_true(
			vim.tbl_contains(lines, "| id | INTEGER | REQUIRED |  |"),
			"expected the table's column schema to be rendered in the buffer"
		)
	end)

	it("shows a loading placeholder instead of crashing when the response is pending", function()
		local uri = "bqls://project/p/dataset/d/table/pending"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/virtualTextDocument"](nil, { pending = true }, {
			client_id = 0,
			params = { textDocument = { uri = uri } },
		})

		assert.are.same({ "Loading..." }, get_lines(bufnr))
	end)
end)

describe("bqls/publishVirtualTextDocument handler", function()
	it("renders details and marks the preview as still loading", function()
		local uri = "bqls://project/p/dataset/d/table/details"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/publishVirtualTextDocument"](nil, {
			textDocument = { uri = uri },
			kind = "details",
			contents = { "# details table" },
		}, { client_id = 0 })

		local lines = get_lines(bufnr)
		assert.are.same("# details table", lines[1])
		assert.is_true(
			vim.tbl_contains(lines, "Loading preview..."),
			"expected a placeholder for the not-yet-arrived preview"
		)
	end)

	it("renders the table schema included with the details notification", function()
		local uri = "bqls://project/p/dataset/d/table/details-schema"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/publishVirtualTextDocument"](nil, {
			textDocument = { uri = uri },
			kind = "details",
			contents = { "# details table" },
			schema = {
				{ name = "id", type = "INTEGER", required = true },
			},
		}, { client_id = 0 })

		local lines = get_lines(bufnr)
		assert.is_true(
			vim.tbl_contains(lines, "| id | INTEGER | REQUIRED |  |"),
			"expected the table's column schema to be rendered in the buffer"
		)
	end)

	it("appends the preview table below the previously rendered details", function()
		local uri = "bqls://project/p/dataset/d/table/preview"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/publishVirtualTextDocument"](nil, {
			textDocument = { uri = uri },
			kind = "details",
			contents = { "# preview table" },
		}, { client_id = 0 })

		bqls.handlers["bqls/publishVirtualTextDocument"](nil, {
			textDocument = { uri = uri },
			kind = "preview",
			result = { columns = { "id" }, data = { { 1 } } },
		}, { client_id = 0 })

		local lines = get_lines(bufnr)
		assert.are.same("# preview table", lines[1])
		assert.is_true(vim.tbl_contains(lines, "| id  |"), "expected the preview table header in the buffer")
		assert.is_false(
			vim.tbl_contains(lines, "Loading preview..."),
			"expected the loading placeholder to be replaced once the preview arrives"
		)
	end)

	it("shows an error message when the fetch failed", function()
		local uri = "bqls://project/p/dataset/d/table/error"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/publishVirtualTextDocument"](nil, {
			textDocument = { uri = uri },
			kind = "details",
			error = "boom",
		}, { client_id = 0 })

		assert.are.same({ "Error: boom" }, get_lines(bufnr))
	end)

	it("does not carry over stale details from a previous pending request", function()
		local uri = "bqls://project/p/dataset/d/table/stale"
		local bufnr = vim.uri_to_bufnr(uri)

		bqls.handlers["bqls/publishVirtualTextDocument"](nil, {
			textDocument = { uri = uri },
			kind = "details",
			contents = { "# stale details" },
		}, { client_id = 0 })

		-- A fresh request for the same uri resets to the pending placeholder,
		-- so leftover details from the previous fetch must not leak into the
		-- next preview.
		bqls.handlers["bqls/virtualTextDocument"](nil, { pending = true }, {
			client_id = 0,
			params = { textDocument = { uri = uri } },
		})

		bqls.handlers["bqls/publishVirtualTextDocument"](nil, {
			textDocument = { uri = uri },
			kind = "preview",
			result = { columns = { "id" }, data = { { 2 } } },
		}, { client_id = 0 })

		local lines = get_lines(bufnr)
		assert.is_false(
			vim.tbl_contains(lines, "# stale details"),
			"expected stale details from the cancelled fetch to be discarded"
		)
	end)
end)

describe("bqls.on_init", function()
	local original_notify

	before_each(function()
		original_notify = vim.notify
	end)

	after_each(function()
		vim.notify = original_notify
		-- Reset any min_version configured by a test so state doesn't leak.
		bqls.setup({})
	end)

	local function capture_notify()
		local calls = {}
		vim.notify = function(msg, level)
			table.insert(calls, { msg = msg, level = level })
		end
		return calls
	end

	it("does not warn when min_version is not configured", function()
		bqls.setup({})
		local calls = capture_notify()

		bqls.on_init(nil, { serverInfo = { version = "v0.1.0" } })

		assert.are.same({}, calls)
	end)

	it("warns when the server version is older than min_version", function()
		bqls.setup({ min_version = "0.6.0" })
		local calls = capture_notify()

		bqls.on_init(nil, { serverInfo = { version = "v0.5.0" } })

		assert.are.same(1, #calls)
		assert.are.same(vim.log.levels.WARN, calls[1].level)
		assert.truthy(calls[1].msg:find("0.5.0", 1, true))
		assert.truthy(calls[1].msg:find("0.6.0", 1, true))
	end)

	it("does not warn when the server version meets min_version", function()
		bqls.setup({ min_version = "0.6.0" })
		local calls = capture_notify()

		bqls.on_init(nil, { serverInfo = { version = "v0.6.0" } })

		assert.are.same({}, calls)
	end)

	it("does not warn when the server does not report a version", function()
		bqls.setup({ min_version = "0.6.0" })
		local calls = capture_notify()

		bqls.on_init(nil, {})

		assert.are.same({}, calls)
	end)
end)
