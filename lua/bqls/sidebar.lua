local vim = vim
local api = vim.api

local M = {}

local _state = {
	bufnr = nil,
	winnr = nil,
	roots = {},
	visible = {},
}

local function project_node(id)
	return { id = id, name = id, type = "project", depth = 1, expanded = false, loaded = false, children = {} }
end

local function dataset_node(project_id, dataset_id)
	return {
		id = project_id .. ":" .. dataset_id,
		name = dataset_id,
		type = "dataset",
		depth = 2,
		expanded = false,
		loaded = false,
		children = {},
		project_id = project_id,
		dataset_id = dataset_id,
	}
end

local function table_node(project_id, dataset_id, table_id)
	return {
		id = string.format("bqls://project/%s/dataset/%s/table/%s", project_id, dataset_id, table_id),
		name = table_id,
		type = "table",
		depth = 3,
		loaded = true,
		children = {},
		project_id = project_id,
		dataset_id = dataset_id,
	}
end

local function flatten(nodes, result)
	for _, node in ipairs(nodes) do
		table.insert(result, node)
		if node.expanded then
			flatten(node.children, result)
		end
	end
end

local function render()
	if not (_state.bufnr and api.nvim_buf_is_valid(_state.bufnr)) then
		return
	end

	_state.visible = {}
	flatten(_state.roots, _state.visible)

	local lines = {}
	for _, node in ipairs(_state.visible) do
		local indent = string.rep("  ", node.depth - 1)
		local prefix
		if node.type == "table" then
			prefix = "  "
		elseif node.expanded then
			prefix = "▼ "
		else
			prefix = "▶ "
		end
		table.insert(lines, indent .. prefix .. node.name)
	end

	api.nvim_set_option_value("modifiable", true, { buf = _state.bufnr })
	api.nvim_buf_set_lines(_state.bufnr, 0, -1, false, lines)
	api.nvim_set_option_value("modifiable", false, { buf = _state.bufnr })
end

local function get_target_win()
	for _, win in ipairs(api.nvim_list_wins()) do
		if win ~= _state.winnr then
			return win
		end
	end
end

local function open_table(node, how)
	local uri = node.id
	local target_bufnr = vim.uri_to_bufnr(uri)

	if how == "split" then
		local win = get_target_win()
		if win then
			api.nvim_set_current_win(win)
		end
		vim.cmd("split")
	elseif how == "vsplit" then
		local win = get_target_win()
		if win then
			api.nvim_set_current_win(win)
		end
		vim.cmd("vsplit")
	else
		local win = get_target_win()
		if win then
			api.nvim_win_set_buf(win, target_bufnr)
			api.nvim_set_current_win(win)
		else
			vim.cmd("vsplit")
		end
	end

	api.nvim_win_set_buf(api.nvim_get_current_win(), target_bufnr)
	vim.lsp.buf_request(
		target_bufnr,
		"bqls/virtualTextDocument",
		{ textDocument = { uri = uri } },
		require("bqls").handlers["bqls/virtualTextDocument"]
	)
end

local function load_datasets(node)
	vim.lsp.buf_request(_state.bufnr, "workspace/executeCommand", {
		command = "bqls.listDatasets",
		arguments = { node.id },
	}, function(err, result)
		if err then
			vim.notify("bqls: " .. err.message, vim.log.levels.ERROR)
			return
		end
		if not result then
			return
		end
		node.children = {}
		for _, dataset_id in ipairs(result.datasets) do
			table.insert(node.children, dataset_node(node.id, dataset_id))
		end
		node.loaded = true
		node.expanded = true
		vim.schedule(render)
	end)
end

local function load_tables(node)
	vim.lsp.buf_request(_state.bufnr, "workspace/executeCommand", {
		command = "bqls.listTables",
		arguments = { node.project_id, node.dataset_id },
	}, function(err, result)
		if err then
			vim.notify("bqls: " .. err.message, vim.log.levels.ERROR)
			return
		end
		if not result then
			return
		end
		node.children = {}
		for _, table_id in ipairs(result.tables) do
			table.insert(node.children, table_node(node.project_id, node.dataset_id, table_id))
		end
		node.loaded = true
		node.expanded = true
		vim.schedule(render)
	end)
end

local function get_node()
	local line = api.nvim_win_get_cursor(0)[1]
	return _state.visible[line]
end

local function toggle_node()
	local node = get_node()
	if not node then
		return
	end

	if node.type == "table" then
		open_table(node)
		return
	end

	if not node.loaded then
		if node.type == "project" then
			load_datasets(node)
		elseif node.type == "dataset" then
			load_tables(node)
		end
		return
	end

	node.expanded = not node.expanded
	render()
end

local function search_tables()
	vim.ui.input({ prompt = "Search tables: " }, function(query)
		if not query or query == "" then
			return
		end

		local arguments = { query }
		for _, root in ipairs(_state.roots) do
			table.insert(arguments, root.id)
		end

		vim.lsp.buf_request(_state.bufnr, "workspace/executeCommand", {
			command = "bqls.searchTables",
			arguments = arguments,
		}, function(err, result)
			if err then
				vim.notify("bqls: " .. err.message, vim.log.levels.ERROR)
				return
			end
			if not result or not result.tables or #result.tables == 0 then
				vim.notify("bqls: no tables found", vim.log.levels.INFO)
				return
			end

			local function on_choice(item)
				local node = table_node(item.projectId, item.datasetId, item.tableId)
				open_table(node)
			end

			if pcall(require, "telescope") then
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				pickers
					.new({}, {
						prompt_title = "Search Tables",
						finder = finders.new_table({
							results = result.tables,
							entry_maker = function(item)
								local display = string.format("%s.%s.%s", item.projectId, item.datasetId, item.tableId)
								return {
									value = item,
									display = display,
									ordinal = display,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(prompt_bufnr)
							actions.select_default:replace(function()
								actions.close(prompt_bufnr)
								local selection = action_state.get_selected_entry()
								if selection then
									on_choice(selection.value)
								end
							end)
							return true
						end,
					})
					:find()
			else
				vim.ui.select(result.tables, {
					prompt = "Search Tables",
					format_item = function(item)
						return string.format("%s.%s.%s", item.projectId, item.datasetId, item.tableId)
					end,
				}, function(item)
					if item then
						on_choice(item)
					end
				end)
			end
		end)
	end)
end

local function setup_keymaps(bufnr)
	local opts = { noremap = true, silent = true, nowait = true }
	local function map(lhs, fn)
		api.nvim_buf_set_keymap(bufnr, "n", lhs, "", vim.tbl_extend("force", opts, { callback = fn }))
	end
	map("<CR>", toggle_node)
	map("o", toggle_node)
	map("s", function()
		local node = get_node()
		if node and node.type == "table" then
			open_table(node, "split")
		end
	end)
	map("v", function()
		local node = get_node()
		if node and node.type == "table" then
			open_table(node, "vsplit")
		end
	end)
	map("f", search_tables)
	map("q", function()
		M.close()
	end)
end

local function ensure_lsp_attached()
	local clients = vim.lsp.get_clients({ name = "bqls" })
	if #clients > 0 then
		vim.lsp.buf_attach_client(_state.bufnr, clients[1].id)
	elseif vim.lsp.config and vim.lsp.config["bqls"] then
		vim.lsp.start(vim.lsp.config["bqls"])
	end
end

M.setup = function(config)
	config = config or {}
	_state.roots = {}
	for _, id in ipairs(config.project_ids or {}) do
		table.insert(_state.roots, project_node(id))
	end
end

M.open = function()
	if _state.winnr and api.nvim_win_is_valid(_state.winnr) then
		api.nvim_set_current_win(_state.winnr)
		return
	end

	if not (_state.bufnr and api.nvim_buf_is_valid(_state.bufnr)) then
		_state.bufnr = api.nvim_create_buf(false, true)
		api.nvim_set_option_value("buftype", "nofile", { buf = _state.bufnr })
		api.nvim_set_option_value("bufhidden", "hide", { buf = _state.bufnr })
		api.nvim_set_option_value("swapfile", false, { buf = _state.bufnr })
		api.nvim_set_option_value("filetype", "bqls-sidebar", { buf = _state.bufnr })
		api.nvim_buf_set_name(_state.bufnr, "BigQuery")
		setup_keymaps(_state.bufnr)
	end

	vim.cmd("topleft vsplit")
	_state.winnr = api.nvim_get_current_win()
	api.nvim_win_set_buf(_state.winnr, _state.bufnr)
	api.nvim_win_set_width(_state.winnr, 40)
	api.nvim_set_option_value("number", false, { win = _state.winnr })
	api.nvim_set_option_value("relativenumber", false, { win = _state.winnr })
	api.nvim_set_option_value("signcolumn", "no", { win = _state.winnr })
	api.nvim_set_option_value("winfixwidth", true, { win = _state.winnr })

	ensure_lsp_attached()
	render()
end

M.close = function()
	if _state.winnr and api.nvim_win_is_valid(_state.winnr) then
		api.nvim_win_close(_state.winnr, true)
		_state.winnr = nil
	end
end

M.toggle = function()
	if _state.winnr and api.nvim_win_is_valid(_state.winnr) then
		M.close()
	else
		M.open()
	end
end

return M
