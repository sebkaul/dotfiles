-- LSP: servers are defined in ../../lsp/<name>.lua, switched on here.
-- See `:help lsp`.

-- vim.lsp.enable({ "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls", "bashls" })
local servers = {
    "lua_ls",
    "pyright",
    "ruff",
    "ts_ls",
    "html",
    "cssls",
    "jsonls",
    "bashls",
    "clangd",
    "rust_analyzer",
    "gopls",
    "yamlls",
    "taplo",
    "marksman",
    "texlab",
    "tinymist",
    "dockerls",
}

-- Enable only servers whose program is installed (see packages.txt),
-- so a machine missing some of them starts without errors
for _, name in ipairs(servers) do
    local config = vim.lsp.config[name]
    if config and vim.fn.executable(config.cmd[1]) == 1 then
        vim.lsp.enable(name)
    end
end

-- Show errors/warnings at the end of the line (off by default since 0.11).
vim.diagnostic.config({
    virtual_text = true, -- message at the end of the line (off by default since 0.11)
    severity_sort = true, -- two problems on one line: show the error, not the hint
    float = { source = true }, -- popup names who complained: "ruff", "Pyright", ...
})

-- The message at the end of the line gets cut off by the window edge.
-- This opens the full text in a popup (built-in: Ctrl+w d does the same).
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Show diagnostic in popup" })

-- Keymaps that only make sense when a server is running in this buffer.
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp", { clear = true }),
    desc = "LSP keymaps",
    callback = function(args)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
        -- pyright and ruff both answer K in Python files. Keep pyright's.
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
        end
    end,
})
