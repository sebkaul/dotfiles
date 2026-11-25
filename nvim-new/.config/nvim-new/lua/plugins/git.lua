vim.pack.add({
    "https://github.com/lewis6991/gitsigns.nvim",
})

-- Git signs --------------------------------------------------------------------------------------
-- Marks changed lines in the sign column, compared to the last commit.
local gs = require("gitsigns")
gs.setup({})

local map = vim.keymap.set
map("n", "]h", function() gs.nav_hunk("next") end, { desc = "Next git change (hunk)" })
map("n", "[h", function() gs.nav_hunk("prev") end, { desc = "Previous git change (hunk)" })
map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview change (old vs new)" })
map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset change (back to last commit)" })
map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage / unstage change" })
map("n", "<leader>gb", gs.blame_line, { desc = "Who wrote this line (blame)" })
map("n", "<leader>gd", gs.diffthis, { desc = "Diff file against last commit" })
