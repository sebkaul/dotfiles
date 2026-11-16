-- Plugins, installed and loaded by Neovim's built-in vim.pack.
-- See `:help vim.pack`.

vim.pack.add({
    "https://github.com/folke/tokyonight.nvim",
})

require("tokyonight").setup({
    style = "night",
})

vim.cmd.colorscheme("tokyonight")

