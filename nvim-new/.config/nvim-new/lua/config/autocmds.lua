-- Autocommands: run a callback when an event fires. See `:help autocmd`,
-- `:help events` for the event list, and `:help nvim_create_autocmd()`.

-- An augroup collects related autocmds. `clear = true` deletes the group's
-- old autocmds first, so re-running this file (`:source %`) doesn't register
-- every autocmd twice.
local group = vim.api.nvim_create_augroup("config", { clear = true })

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
