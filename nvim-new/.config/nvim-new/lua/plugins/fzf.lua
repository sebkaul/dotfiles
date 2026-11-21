vim.pack.add({
    "https://github.com/ibhagwan/fzf-lua",
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
