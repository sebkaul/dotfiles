-- Plugins, installed and loaded by Neovim's built-in vim.pack.
-- See `:help vim.pack`.

vim.pack.add({
	"https://github.com/folke/tokyonight.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/ibhagwan/fzf-lua",
	-- "https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-mini/mini.files",
	"https://github.com/nvim-mini/mini.animate",
})

-- Theme ------------------------------------------------------------
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

map("n", "<leader>fm", fzf.marks, { desc = "Find marks" })
map("n", "<leader>fj", fzf.jumps, { desc = "Find in jumplist" })

map("n", "<leader>fd", fzf.diagnostics_document, { desc = "Find diagnostics (this file)" })
map("n", "<leader>fD", fzf.diagnostics_workspace, { desc = "Find diagnostics (all files)" })

-- -- File Explorer Oil ------------------------------------------------------------
-- local oil = require("oil")
-- oil.setup({
--     view_options = {
--         max_width = 0.6, -- at most 60& of the screen wide...
--         max_height = 0.7, -- ... and 700% high
--     },
-- })
-- 
-- map("n", "<leader>ee", oil.toggle_float, { desc = "Toggle file explorer" })
-- map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

-- File Explorer mini.files --------------------------------------------------------
local files = require("mini.files")
files.setup({
    windows = {
        preview = true, -- show a preview column of the file/folder under the cursor
        width_preview = 50, -- preview column width, in characters
    },
    options = {
        permanent_delete = false, -- deleted files go to a trash folder instead
    },
    mappings = {
        go_in_plus = "<CR>", -- Enter: open file and close the explorer (default: L)
    },
})

map("n", "<leader>ee", function()
    if not files.close() then
        files.open(vim.api.nvim_buf_get_name(0))
    end
end, { desc = "Toggle file explorer" })


-- Smooth scrolling ----------------------------------------------------------------
local animate = require("mini.animate")
animate.setup({
    scroll = {
        timing = animate.gen_timing.linear({ duration = 80, unit = "total" }),
    },
    cursor = { enable = false },
    resize = { enable = false },
    open = { enable = false },
    close = { enable = false },
})

