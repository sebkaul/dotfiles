vim.pack.add({
    "https://github.com/nvim-treesitter/nvim-treesitter",
})

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
    callback = function(args) pcall(vim.treesitter.start, args.buf) end,
})
