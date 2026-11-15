-- Editor options.  See `:help options` and `:help lua-guide-options`.
--
-- Three ways to set an option from Lua:
--   vim.o.number = true        -- like `:set number`. Plain Lua values in and out.
--   vim.opt.number = true      -- same, but reading it gives an Option *object*
--                              -- with methods (:get(), :append(), :remove(), ...).
--   vim.wo / vim.bo            -- window-local / buffer-local only (`:setlocal`).
--
-- Rule of thumb used here: vim.o for simple values, vim.opt when the method
-- calls or table syntax for list/map options make it cleaner.

local o = vim.o
local opt = vim.opt

-- Line numbers ---------------------------------------------------------------
o.number = true -- show the absolute number on the cursor line...
o.relativenumber = true -- ...and relative numbers everywhere else (5j, 12k)
o.signcolumn = "yes" -- always reserve the sign column so text never shifts
o.cursorline = true -- highlight the cursor line

-- Indentation ----------------------------------------------------------------
o.tabstop = 4 -- a <Tab> character is displayed 4 columns wide
o.shiftwidth = 4 -- >>, << and auto-indent move by 4 columns
o.expandtab = true -- pressing <Tab> inserts spaces
o.smartindent = true -- add indent after `{` etc. (treesitter/LSP refine this later)
o.breakindent = true -- wrapped lines keep their indentation

-- Display --------------------------------------------------------------------
o.wrap = false -- long lines run off screen instead of wrapping
o.list = true -- show invisible characters, using the table below
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- table -> "tab:» ,trail:·,nbsp:␣"
o.winborder = "rounded" -- default border for floating windows (0.11+)

-- Scrolling (personal preference carried over from the old config) ----------
o.scrolloff = 0 -- cursor may touch the top/bottom edge before scrolling
o.mousescroll = "ver:1,hor:1" -- mouse wheel scrolls one line at a time
-- The old config also had `scroll = 1` (makes <C-d>/<C-u> move one line).
-- 'scroll' is window-local and is reset whenever a window is resized, so it
-- only works reliably as a keymap or autocommand. Revisit in step #16.

-- Search ---------------------------------------------------------------------
o.ignorecase = true -- /foo matches Foo...
o.smartcase = true -- ...unless the pattern itself contains a capital
o.inccommand = "split" -- live preview of :s/// in a split window

-- Splits ---------------------------------------------------------------------
o.splitright = true -- :vsplit opens to the right
o.splitbelow = true -- :split opens below

-- Files & history ------------------------------------------------------------
o.swapfile = false -- no .swp files
o.undofile = true -- persistent undo: u still works after closing a file
o.confirm = true -- ask to save instead of failing on :q with changes

-- Timing ---------------------------------------------------------------------
o.updatetime = 250 -- ms of idle before CursorHold fires / swap is written (default 4000)
o.timeoutlen = 400 -- ms to wait for the rest of a key sequence (default 1000)

-- Clipboard ------------------------------------------------------------------
-- Yank/paste go through the system clipboard (wl-copy/wl-paste on Wayland).
-- Wrapped in vim.schedule() because detecting the clipboard tool takes a few
-- ms; scheduling it runs it after startup instead of blocking it.
vim.schedule(function()
	opt.clipboard:append("unnamedplus") -- method call: note the colon
end)

-- Dropped from the old config, because they are already the default in
-- Neovim 0.10+ (check any of them with `:set <name>?` or `:verbose set <name>?`):
--   autoindent = true, backspace = "indent,eol,start",
--   termguicolors = true (auto-detected), background = "dark" (auto-detected)
-- Also dropped: `g:netrw_liststyle` - netrw is replaced by the file explorer (#20).
