-- Plugins, installed and loaded by Neovim's built-in vim.pack.
-- See `:help vim.pack`.

vim.pack.add({
	"https://github.com/folke/tokyonight.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/ibhagwan/fzf-lua",
})

require("tokyonight").setup({
	style = "night",
})

vim.cmd.colorscheme("tokyonight")

-- Treeesitter -------------------------------------------------------------------
-- Parsers to download and compile (runs in the background, skips installed ones).
require("nvim-treesitter").install({
	"python",
	"javascript",
	"typescript",
	"tsx",
	"html",
	"css",
	"bash",
	"json",
})

-- Turn on treesitter highlighting whenever a file's type is detected.
vim.api.nvim_create_autocmd("FileType", {
	desc = "Start treesitter highlighting",
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})

-- Fuzzy Finder ----------------------------------------------------------------
local fzf = require("fzf-lua")
fzf.setup({})

local map = vim.keymap.set
map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Find recent files" })
map("n", "<leader>fs", fzf.live_grep, { desc = "Find string in project" })
map("n", "<leader>fc", fzf.grep_cword, { desc = "Find word under cursor" })
map("n", "<leader>fb", fzf.buffers, { desc = "Find open buffers" })
map("n", "<leader>fh", fzf.helptags, { desc = "Find help" })
map("n", "<leader>fk", fzf.keymaps, { desc = "Find keymaps" })
