require("settings.devicons")
require("settings.nvim-tree")
require("settings.nvim-treesitter")
require("settings.status-line")
require("settings.telescope")
require("settings.easyalign")
require("settings.tmux-runner")
require("settings.lsp")
require("settings.dashboard")
require("settings.theme")
require("settings.null-ls")
require("settings.float-term")

local M = {}
local options = vim.opt
local cmd = vim.cmd

function M.vim_auto_cmds()
	cmd("filetype plugin indent on")
	cmd("highlight ColorColumn ctermbg=red")
	cmd("syntax on")
	cmd("syntax enable")
	cmd("colorscheme kanagawa")
	--cmd("autocmd BufWritePre * :lua vim.lsp.buf.formatting_seq_sync()")
end

function M.lua_auto_cmds()
	options.mouse = "a"
	options.colorcolumn = "80"
	options.encoding = "utf-8"
	options.number = true
	options.relativenumber = true
	options.autoindent = true
	options.autoread = true
	options.ruler = true
	options.showcmd = true
	options.smartcase = true
	options.termguicolors = true
	options.cursorline = true
	options.autoread = true
	options.ruler = true
	options.laststatus = 2
	options.scrolloff = 3
	options.shiftwidth = 2
	options.backspace = "2"
	options.softtabstop = 2
	options.tabstop = 8
	options.hidden = true
	options.expandtab = true
	options.wrap = true
end

function M.setup()
	M.vim_auto_cmds()
	M.lua_auto_cmds()
end

return M
