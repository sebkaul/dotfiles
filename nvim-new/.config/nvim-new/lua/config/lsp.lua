-- LSP: servers are defined in ../../lsp/<name>.lua, switched on here.
-- See `:help lsp`.

vim.lsp.enable({ "lua_ls", "pyright" })

-- Show errors/warnings at the end of the line (off by default since 0.11).
vim.diagnostic.config({ virtual_text = true })

-- Keymaps that only make sense when a server is running in this buffer.
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp", { clear = true }),
    desc = "LSP keymaps",
    callback = function(args)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
    end,
})

