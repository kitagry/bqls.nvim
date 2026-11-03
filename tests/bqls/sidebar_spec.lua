local sidebar = require("bqls.sidebar")

local ns = vim.api.nvim_create_namespace("bqls_sidebar")

local original_buf_request = vim.lsp.buf_request
local original_lsp_start = vim.lsp.start

-- The bqls server is an external dependency, so stand it in with canned
-- responses to listDatasets / listTables.
local requests

local function stub_server()
	requests = {}
	vim.lsp.start = function() end
	vim.lsp.buf_request = function(_, method, params, handler)
		table.insert(requests, { method = method, params = params })
		if params.command == "bqls.listDatasets" then
			handler(nil, { datasets = { "samples" } })
		elseif params.command == "bqls.listTables" then
			handler(nil, { tables = { "shakespeare" } })
		end
	end
end

local function sidebar_lines()
	local bufnr = vim.api.nvim_win_get_buf(0)
	return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function wait_for_line_count(n)
	vim.wait(1000, function()
		return #sidebar_lines() == n
	end)
end

local function press(keys)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

local function open_and_expand_all(config)
	sidebar.setup(config)
	sidebar.open()
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	press("<CR>")
	wait_for_line_count(2)
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	press("<CR>")
	wait_for_line_count(3)
end

-- Returns the highlight groups covering [start_col, end_col) on a 0-indexed row.
local function highlights_at(row)
	local bufnr = vim.api.nvim_win_get_buf(0)
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, { row, 0 }, { row, -1 }, { details = true })
	local result = {}
	for _, mark in ipairs(marks) do
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
		local text = line:sub(mark[3] + 1, mark[4].end_col)
		result[mark[4].hl_group] = text
	end
	return result
end

describe("bqls sidebar", function()
	before_each(function()
		stub_server()
	end)

	after_each(function()
		sidebar.close()
		vim.lsp.buf_request = original_buf_request
		vim.lsp.start = original_lsp_start
	end)

	it("distinguishes projects, datasets and tables with default Nerd Font icons", function()
		open_and_expand_all({ project_ids = { "bigquery-public-data" } })

		assert.are.same({
			"▼ 󰆼 bigquery-public-data",
			"  ▼ 󰉋 samples",
			"      󰓫 shakespeare",
		}, sidebar_lines())
	end)

	it("shows the collapsed marker before a project that is not expanded", function()
		sidebar.setup({ project_ids = { "p" } })
		sidebar.open()

		assert.are.same({ "▶ 󰆼 p" }, sidebar_lines())
	end)

	it("merges user icons over the defaults", function()
		open_and_expand_all({
			project_ids = { "p" },
			icons = { project = "P", table = "T", expanded = "-" },
		})

		assert.are.same({
			"- P p",
			"  - 󰉋 samples",
			"      T shakespeare",
		}, sidebar_lines())
	end)

	it("omits the icon column when an icon is set to an empty string", function()
		open_and_expand_all({
			project_ids = { "p" },
			icons = { project = "", dataset = "", table = "" },
		})

		assert.are.same({
			"▼ p",
			"  ▼ samples",
			"      shakespeare",
		}, sidebar_lines())
	end)

	it("highlights each node's icon and name with a group per node type", function()
		open_and_expand_all({ project_ids = { "p" } })

		local project = highlights_at(0)
		assert.are.same("󰆼", project.BqlsSidebarProjectIcon)
		assert.are.same("p", project.BqlsSidebarProject)

		local dataset = highlights_at(1)
		assert.are.same("󰉋", dataset.BqlsSidebarDatasetIcon)
		assert.are.same("samples", dataset.BqlsSidebarDataset)

		local tbl = highlights_at(2)
		assert.are.same("󰓫", tbl.BqlsSidebarTableIcon)
		assert.are.same("shakespeare", tbl.BqlsSidebarTable)
	end)

	it("defines the highlight groups as default links so colorschemes can override them", function()
		for _, group in ipairs({
			"BqlsSidebarExpander",
			"BqlsSidebarProjectIcon",
			"BqlsSidebarProject",
			"BqlsSidebarDatasetIcon",
			"BqlsSidebarDataset",
			"BqlsSidebarTableIcon",
			"BqlsSidebarTable",
		}) do
			local hl = vim.api.nvim_get_hl(0, { name = group })
			assert.is_not_nil(hl.link, group .. " should link to another group")
			assert.is_true(hl.default, group .. " should be defined with default = true")
		end
	end)

	it("keeps resolving the node under the cursor", function()
		open_and_expand_all({ project_ids = { "p" } })

		assert.are.same({ "bqls.listDatasets", "bqls.listTables" }, {
			requests[1].params.command,
			requests[2].params.command,
		})
		assert.are.same({ "p", "samples" }, requests[2].params.arguments)
	end)
end)
