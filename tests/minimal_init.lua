local plenary_lazy_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
local plenary_ci_path = "/tmp/plenary.nvim"

if vim.fn.isdirectory(plenary_lazy_path) == 1 then
	vim.opt.rtp:append(plenary_lazy_path)
else
	if vim.fn.isdirectory(plenary_ci_path) == 0 then
		vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/nvim-lua/plenary.nvim", plenary_ci_path })
	end
	vim.opt.rtp:append(plenary_ci_path)
end

vim.opt.rtp:append(".")
vim.cmd("runtime plugin/plenary.vim")
