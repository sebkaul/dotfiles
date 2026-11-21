vim.pack.add({
    "https://github.com/stevearc/conform.nvim",
})

-- Formatting --------------------------------------------------------------------------------------
local conform = require("conform")
conform.setup({
    -- Which formatter for which filetype.
    -- A list, because some filetypes could chain several (run one after the other).
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
    },
    -- No formatter listed (C, Rust, Go, TOML)? Ask the language server instead.
    default_format_opts = { lsp_format = "fallback" },
    -- Format on every :w. Give up after 500ms so saving never hangs.
    format_on_save = { timeout_ms = 500 },
    -- Extra arguments for one formatter: shfmt uses tabs unless told "-i 4".
    formatters = {
        shfmt = { prepend_args = { "-i", "4" } },
    },
})

local map = vim.keymap.set
map({ "n", "x" }, "<leader>cf", conform.format, { desc = "Format file (or selection)" })
