--This file should contain all commands meant to be used by mappings.
local cc = require('neo-tree.sources.common.commands')
local manager = require('neo-tree.sources.manager')
local bqls = require('neo-tree.sources.bqls')
local utils = require('neo-tree.utils')

local vim = vim

local M = {}

M.refresh = function(state)
  manager.refresh('bqls', state)
end

local function virtual_text(state)
  local tree = state.tree
  local success, node = pcall(tree.get_node, tree)
  if node.type == 'message' then
    return
  end
  if not (success and node) then
    return
  end

  if node.type ~= 'file' then
    return
  end

  local params = {
    textDocument = {
      uri = node:get_id(),
    },
  }

  vim.lsp.buf_request(0, 'bqls/virtualTextDocument', params, require('bqls').handlers['bqls/virtualTextDocument'])
end

M.open = function(state)
  virtual_text(state)
  cc.open(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_split = function(state)
  virtual_text(state)
  cc.open_split(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_vsplit = function(state)
  virtual_text(state)
  cc.open_vsplit(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_tabnew = function(state)
  virtual_text(state)
  cc.open_tabnew(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_drop = function(state)
  cc.open_drop(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_tab_drop = function(state)
  cc.open_tab_drop(state, utils.wrap(bqls.toggle_directory, state))
end

M.toggle_node = function(state)
  cc.toggle_node(state, utils.wrap(bqls.toggle_directory, state))
end

cc._add_common_commands(M)
return M
