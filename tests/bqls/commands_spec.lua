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
