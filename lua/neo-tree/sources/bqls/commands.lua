--This file should contain all commands meant to be used by mappings.
local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")
local bqls = require("neo-tree.sources.bqls")
local utils = require("neo-tree.utils")

local vim = vim

local M = {}

M.refresh = function(state)
  manager.refresh("bqls", state)
end

M.open = function(state)
  cc.open(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_split = function(state)
  cc.open_split(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_vsplit = function(state)
  cc.open_vsplit(state, utils.wrap(bqls.toggle_directory, state))
end
M.open_tabnew = function(state)
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
