local commands = require("bqls.commands")

describe("bqls.commands.convert_data_to_markdown", function()
	it("renders columns and rows as a markdown table", function()
		local result = commands.convert_data_to_markdown({
			columns = { "id", "name" },
			data = {
				{ 1, "alice" },
				{ 2, "bob" },
			},
		})

		assert.are.same(
			"| id | name  |\n| :---: | :---: |\n| 1 | alice  |\n| 2 | bob  |\n",
			result,
			"expected a markdown table with a header row, divider, and one row per record"
		)
	end)

	it("renders only the header and divider when there are no rows", function()
		local result = commands.convert_data_to_markdown({
			columns = { "id" },
			data = {},
		})

		assert.are.same("| id  |\n| :---: |\n", result, "expected no data rows when data is empty")
	end)

	it("returns an empty string when columns are missing", function()
		local result = commands.convert_data_to_markdown({ data = { { 1 } } })

		assert.are.same("", result, "expected no output when there are no columns to render")
	end)

	it("returns an empty string when data is vim.NIL", function()
		local result = commands.convert_data_to_markdown({ columns = { "id" }, data = vim.NIL })

		assert.are.same("", result, "expected no output when data is the JSON null sentinel")
	end)

	describe("cell value formatting", function()
		local cases = {
			{ name = "boolean true becomes the string true", value = true, expected = "true" },
			{ name = "boolean false becomes the string false", value = false, expected = "false" },
			{ name = "vim.NIL becomes the string NULL", value = vim.NIL, expected = "NULL" },
			{
				name = "a table value becomes its JSON encoding",
				value = { a = 1 },
				expected = vim.json.encode({ a = 1 }),
			},
		}

		for _, case in ipairs(cases) do
			it(case.name, function()
				local result = commands.convert_data_to_markdown({
					columns = { "value" },
					data = { { case.value } },
				})

				assert.are.same(
					"| value  |\n| :---: |\n| " .. case.expected .. "  |\n",
					result,
					"expected the cell to render as " .. case.expected
				)
			end)
		end
	end)
end)

describe("bqls.commands.convert_schema_to_markdown", function()
	it("renders a flat schema as a markdown table with name/type/mode/description", function()
		local result = commands.convert_schema_to_markdown({
			{ name = "id", type = "INTEGER", required = true, description = "primary key" },
			{ name = "name", type = "STRING" },
		})

		assert.are.same(
			"| Name | Type | Mode | Description |\n"
				.. "| --- | --- | --- | --- |\n"
				.. "| id | INTEGER | REQUIRED | primary key |\n"
				.. "| name | STRING | NULLABLE |  |\n",
			result,
			"expected a markdown table listing each column's name, type, mode, and description"
		)
	end)

	it("marks repeated fields as REPEATED", function()
		local result = commands.convert_schema_to_markdown({
			{ name = "tags", type = "STRING", repeated = true },
		})

		assert.is_true(
			vim.tbl_contains(vim.split(result, "\n"), "| tags | STRING | REPEATED |  |"),
			"expected the repeated field's mode to be REPEATED"
		)
	end)

	it("indents nested RECORD fields under their parent", function()
		local result = commands.convert_schema_to_markdown({
			{
				name = "address",
				type = "RECORD",
				fields = {
					{ name = "city", type = "STRING" },
				},
			},
		})

		local lines = vim.split(result, "\n")
		assert.is_true(
			vim.tbl_contains(lines, "| address | RECORD | NULLABLE |  |"),
			"expected the parent RECORD field as its own row"
		)
		assert.is_true(
			vim.tbl_contains(lines, "| &nbsp;&nbsp;city | STRING | NULLABLE |  |"),
			"expected the nested field indented under its parent"
		)
	end)

	it("returns an empty string when the schema is empty, nil, or vim.NIL", function()
		assert.are.same("", commands.convert_schema_to_markdown(nil))
		assert.are.same("", commands.convert_schema_to_markdown(vim.NIL))
		assert.are.same("", commands.convert_schema_to_markdown({}))
	end)
end)

describe("bqls.commands.cancel_query", function()
	local original_buf_request
	local original_notify

	before_each(function()
		original_buf_request = vim.lsp.buf_request
		original_notify = vim.notify
	end)

	after_each(function()
		vim.lsp.buf_request = original_buf_request
		vim.notify = original_notify
	end)

	it("sends bqls.cancelQuery with the buffer's job uri when a query is pending", function()
		local uri = "bqls://project/p/job/j/location/l"
		local bufnr = vim.uri_to_bufnr(uri)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Loading..." })

		local requested
		vim.lsp.buf_request = function(bufnr_arg, method, params, handler)
			requested = { bufnr = bufnr_arg, method = method, params = params, handler = handler }
		end

		commands.cancel_query(bufnr)

		assert.is_not_nil(requested, "expected a workspace/executeCommand request to be sent")
		assert.are.same("workspace/executeCommand", requested.method)
		assert.are.same("bqls.cancelQuery", requested.params.command)
		assert.are.same({ uri }, requested.params.arguments)
		assert.are.same(bufnr, requested.bufnr)
		assert.is_function(requested.handler)
	end)

	it("does not send a request and warns when the buffer is not showing a pending query", function()
		local uri = "bqls://project/p/job/j/location/l2"
		local bufnr = vim.uri_to_bufnr(uri)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "| id |", "| :---: |", "| 1 |" })

		local requested = false
		vim.lsp.buf_request = function()
			requested = true
		end

		local notified_level
		vim.notify = function(_, level)
			notified_level = level
		end

		commands.cancel_query(bufnr)

		assert.is_false(requested, "expected no request to be sent once the query already finished")
		assert.are.same(vim.log.levels.WARN, notified_level, "expected a warning explaining there is nothing to cancel")
	end)
end)

describe("bqls.commands.cancel_query_handler", function()
	local original_notify

	before_each(function()
		original_notify = vim.notify
	end)

	after_each(function()
		vim.notify = original_notify
	end)

	it("notifies success when the server cancels the query", function()
		local notified
		vim.notify = function(msg, level)
			notified = { msg = msg, level = level }
		end

		commands.cancel_query_handler(nil, nil, {})

		assert.are.same(vim.log.levels.INFO, notified.level, "expected an info notification on success")
	end)

	it("notifies an error when the server fails to cancel the query", function()
		local notified
		vim.notify = function(msg, level)
			notified = { msg = msg, level = level }
		end

		commands.cancel_query_handler({ message = "boom" }, nil, {})

		assert.are.same("bqls: boom", notified.msg, "expected the server error message to be surfaced")
		assert.are.same(vim.log.levels.ERROR, notified.level)
	end)
end)
