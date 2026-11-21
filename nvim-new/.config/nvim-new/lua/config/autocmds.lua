-- Autocommands: run a callback when an event fires. See `:help autocmd`,
-- `:help events` for the event list, and `:help nvim_create_autocmd()`.

-- An augroup collects related autocmds. `clear = true` deletes the group's
-- old autocmds first, so re-running this file (`:source %`) doesn't register
-- every autocmd twice.
local group = vim.api.nvim_create_augroup("config", { clear = true })

-- Replace non-breaking spaces (U+00A0) with normal spaces on save.
-- They sneak in when pasting from the web/chat, and Lua treats them as a name.
vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    desc = "Replace non-breaking spaces on save",
    callback = function()
        local view = vim.fn.winsaveview()
        vim.cmd([[keeppatterns silent! %s/\%u00a0/ /g]])
        vim.fn.winrestview(view)
    end,
})

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    desc = "Highlight yanked text",
    callback = function()
        vim.hl.on_yank({ timeout = 150 })
    end,
})

-- Reopen a file at the line where you left it. The '" mark holds that
-- position (saved in ShaDa, `:help shada`).
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    desc = "Restore last cursor position",
    -- The callback receives a table describing the event; args.buf is the buffer.
    callback = function(args)
        if vim.bo[args.buf].filetype == "gitcommit" then
            return -- commit messages should always start at the top
        end
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"') -- { line, col }
        local line_count = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= line_count then
            vim.api.nvim_win_set_cursor(0, mark) -- 0 = current window
        end
    end,
})

-- Keep splits evenly sized when the terminal (or tmux pane) is resized.
-- A named local function works as a callback just like an anonymous one.
local function equalize_splits()
    vim.cmd("tabdo wincmd =")
end

vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    desc = "Equalize splits on resize",
    callback = equalize_splits, -- pass the function itself: no ()
})

-- Wrap long lines in prose files, keep code unwrapped.
-- vim.opt_local is `:setlocal`: only this buffer in this window. Plain vim.wo
-- would also become the window's default, so the next file opened in the
-- same window (e.g. a .lua file) would wrap too.
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "markdown", "text", "gitcommit" },
    desc = "Wrap prose",
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
    end,
})

-- With wrap off, Vim only scrolls sideways as far as needed to show the cursor
-- On a line that fits the window, scroll fully back to the left.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    desc = "Scroll left on lines that fit the window",
    callback = function()
        if vim.wo.wrap then
            return -- wrapped windows never scroll sideways
        end
        local view = vim.fn.winsaveview()
        if view.leftcol == 0 then
            return -- already at the left edge
        end
        local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
        local text_width = info.width - info.textoff
        if vim.fn.strdisplaywidth(vim.api.nvim_get_current_line()) < text_width then
            vim.fn.winrestview({ leftcol = 0 })
        end
    end,
})
