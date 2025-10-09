local vim = vim
local renderer = require('neo-tree.ui.renderer')
local manager = require('neo-tree.sources.manager')
local events = require('neo-tree.events')
local commands = require('bqls.commands')

local M = { name = 'bqls' }

M.get_node_stat = function(node)
  return {}
end

---@param state table State of the tree
---@param path string Path to navigate to. If empty, will navigate to the cwd.
M.navigate = function(state, path)
  if path == nil then
    local items = {}
    for _, project_id in ipairs(M.project_ids) do
      local project_node = {
        id = project_id,
        name = project_id,
        type = 'directory',
        stat_provider = M.name,
        loaded = false,
        children = {},
      }
      table.insert(items, project_node)
    end
    renderer.show_nodes(items, state)
    return
  end
end

M.show_new_children = function(state, node_or_path)
  local node = node_or_path
  if node_or_path == nil then
    node = state.tree:get_node()
    node_or_path = node:get_id()
  end

  if node.type ~= 'directory' then
    return
  end

  M.navigate(state, nil, node_or_path)
end

M.toggle_directory = function(state, node, path_to_reveal, skip_redraw, recursive, callback)
  if node == nil then
    return
  end

  if node.type ~= 'directory' then
    return
  end

  state.explicitly_opened_directories = state.explicitly_opened_directories or {}
  if node.loaded == false then
    local id = node:get_id()
    state.explicitly_opened_directories[id] = true
    renderer.position.set(state, nil)

    local ind = string.find(node:get_id(), ':')
    -- dataset
    if ind then
      local project_id = string.sub(node:get_id(), 0, ind - 1)
      local dataset_id = string.sub(node:get_id(), ind + 1)

      ---@param err lsp.ResponseError
      ---@param result any
      ---@param params table
      local callback_func = function(err, result, params)
        if err then
          vim.notify('bqls: ' .. err.message, vim.log.levels.ERROR)
          return
        end
        if not result then
          return
        end
        local table_ids = result.tables
        node.children = {}
        for _, table_id in ipairs(table_ids) do
          local table_node = {
            id = string.format('bqls://project/%s/dataset/%s/table/%s', project_id, dataset_id, table_id),
            name = table_id,
            type = 'file',
            stat_provider = M.name,
            children = {},
          }
          table.insert(node.children, table_node)
        end
        node.loaded = true
        renderer.show_nodes(node.children, state, node:get_id())
      end
      commands.execute_list_tables(project_id, dataset_id, callback_func)
    -- project
    else
      local project_id = node:get_id()

      ---@param err lsp.ResponseError
      ---@param result any
      ---@param params table
      local callback_func = function(err, result, params)
        if err then
          vim.notify('bqls: ' .. err.message, vim.log.levels.ERROR)
          return
        end
        if not result then
          return
        end
        local dataset_ids = result.datasets
        node.children = {}
        for _, dataset_id in ipairs(dataset_ids) do
          local dataset_node = {
            id = string.format('%s:%s', project_id, dataset_id),
            name = dataset_id,
            type = 'directory',
            stat_provider = M.name,
            loaded = false,
            children = {},
          }
          table.insert(node.children, dataset_node)
        end
        node.loaded = true
        renderer.show_nodes(node.children, state, node:get_id())
      end
      commands.execute_list_datasets(project_id, callback_func)
    end
  elseif node:has_children() then
    local updated = false
    if node:is_expanded() then
      updated = node:collapse()
      state.explicitly_opened_directories[node:get_id()] = false
    else
      updated = node:expand()
      state.explicitly_opened_directories[node:get_id()] = true
    end
    if updated and not skip_redraw then
      renderer.redraw(state)
    end
    if path_to_reveal then
      renderer.focus_node(state, path_to_reveal)
    end
  end
end

---@param config table Configuration table containing any keys that user wants to change from the defaults. May be empty to accept default values.
M.setup = function(config, global_config)
  M.project_ids = config.project_ids or { 'bigquery-public-data' }
  require('neo-tree.utils').register_stat_provider('bqls', M.get_node_stat)
  manager.subscribe(M.name, {
    event = events.NEO_TREE_BUFFER_ENTER,
    handler = function(args)
      local client = vim.lsp.get_clients({ name = 'bqls' })
      if #client == 1 then
        vim.lsp.buf_attach_client(0, client[1].id)
      else
        vim.lsp.start(vim.lsp.config['bqls'])
      end
      manager.refresh(M.name)
    end,
  })
end

return M
