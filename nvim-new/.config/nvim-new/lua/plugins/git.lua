vim.pack.add({
    "https://github.com/lewis6991/gitsigns.nvim",
})

-- Git signs --------------------------------------------------------------------------------------
-- Marks changed lines in the sign column, compared to the last commit.
local gs = require("gitsigns")
gs.setup({})

local map = vim.keymap.set
map("n", "]h", function()
    gs.nav_hunk("next")
end, { desc = "Next git change (hunk)" })
map("n", "[h", function()
    gs.nav_hunk("prev")
end, { desc = "Previous git change (hunk)" })
map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview change (old vs new)" })
map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset change (back to last commit)" })
map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage / unstage change" })
map("n", "<leader>gb", gs.blame_line, { desc = "Who wrote this line (blame)" })
map("n", "<leader>gd", gs.diffthis, { desc = "Diff file against last commit" })

-- Lazygit in a floating window -----------------------------------------------------------------
-- No plugin: a terminal buffer (:help terminal) shown in a floating window
-- (:help api-floatwin). q in lazygit quits it and closes the window.
local function lazygit()
    -- An empty buffer: false = not in the buffer list (]b skips it),
    -- true = "scratch" (no file behind it, never asks to save).
    local buf = vim.api.nvim_create_buf(false, true)
    -- Wipe the buffer completely as soon as its window closes.
    vim.bo[buf].bufhidden = "wipe"

    -- 90% of the editor size, centered.
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
    })

    -- Run lazygit inside the current buffer (the one we just made)
    vim.fn.jobstart({ "lazygit" }, {
        term = true,
        on_exit = function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
            vim.cmd.checktime() -- reload files lazygit changed (discard, checkout, ...)
        end,
    })
    vim.cmd.startinsert() -- terminal mode: keys go to lazygit right away
end

map("n", "<leader>gg", lazygit, { desc = "Lazygit" })
