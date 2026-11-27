-- Theme ------------------------------------------------------------
vim.pack.add({
    "https://github.com/folke/tokyonight.nvim",
})

require("tokyonight").setup({
    style = "night",
})

vim.cmd.colorscheme("tokyonight")

-- Unused code (e.g. a function not called yet) is dimmed as a whole block by default.
-- Too loud while writing; the hint at the line end is enough.
vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {})
