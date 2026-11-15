-- General keymaps. Plugin-specific keymaps live next to their plugin setup.
-- See `:help vim.keymap.set()` and `:help map-modes`.
--
--   vim.keymap.set(mode, lhs, rhs, opts)
--     mode  "n" normal, "i" insert, "v" visual+select, "x" visual only,
--           "o" operator-pending, "t" terminal, or a list: { "n", "x" }
--     lhs   the keys you press
--     rhs   keys to run instead, OR a Lua function to call
--     opts  { desc = "..." } shows up in :map and later in which-key;
--           also silent, buffer, expr, remap, ...

-- Leader must be set before any mapping that uses <leader> is defined
-- (it is read at definition time), and before plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set -- functions are values: store one in a local

-- Insert mode ------------------------------------------------------------------
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Search highlight -------------------------------------------------------------
map("n", "<leader>nh", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
map("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { desc = "Clear search highlights" })
-- <cmd>...<CR> runs an Ex command without entering command-line mode, so it
-- is silent and doesn't change mode. Prefer it over ":...<CR>".

-- Move selected lines up/down (and re-indent) ------------------------------------
-- These need ":" because :move takes the visual range '<,'>, which <cmd> skips.
map("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Keep the selection after indenting
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

-- Scrolling ----------------------------------------------------------------------
-- Replaces the old `scroll = 1` option, which Neovim resets on every resize.
-- A count on <C-d>/<C-u> sets 'scroll' first, so "1<C-d>" always moves 1 line.
map({ "n", "x" }, "<C-d>", "10<C-d>", { desc = "Scroll down one line" })
map({ "n", "x" }, "<C-u>", "10<C-u>", { desc = "Scroll up one line" })

-- Numbers ------------------------------------------------------------------------
map("n", "<leader>+", "<C-a>", { desc = "Increment number" })
map("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- Splits ---------------------------------------------------------------------------
-- Moving between splits (<C-h/j/k/l>) comes with the tmux integration (#21).
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Equalize split sizes" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close split" })

-- Tabs -----------------------------------------------------------------------------
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open buffer in new tab" })

-- A Lua function as rhs ----------------------------------------------------------
-- Anything a key string can't express goes in a function. This one is
-- anonymous: `function() ... end` written inline, never given a name.
map("n", "<leader>ow", function()
	vim.wo.wrap = not vim.wo.wrap -- window-local, so only this window changes
	print("wrap: " .. tostring(vim.wo.wrap))
end, { desc = "Toggle line wrap" })
