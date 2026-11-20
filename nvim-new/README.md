# nvim-new

A Neovim config rebuilt from scratch, one step at a time, to learn Lua and
Neovim internals instead of copying a prebuilt setup. Tracked in
[#13](https://github.com/sebkaul/dotfiles/issues/13).

The old config (`../nvim`, based on josean's setup with lazy.nvim) keeps working
untouched until the cutover step. Both live side by side.

## Dependencies

All programs the config calls (Neovim, git, fzf, ripgrep, every language
server, ...) are listed in `packages.txt`, official Arch repos only. On a new
machine, or after adding a server:

```bash
grep -Ev '^\s*(#|$)' ~/dotfiles/nvim-new/packages.txt | sudo pacman -S --needed -
```

`--needed` skips what's already installed; `-` makes pacman read the package
names from the pipe. Servers that aren't installed are skipped quietly at
startup (`lua/config/lsp.lua` checks `vim.fn.executable`).

## Running it

```bash
nv            # alias for: NVIM_APPNAME=nvim-new nvim
```

`NVIM_APPNAME` tells Neovim which folder name to use everywhere, so `nv` reads
`~/.config/nvim-new` and keeps its plugins, undo history and state in
`~/.local/share/nvim-new` and `~/.local/state/nvim-new`. Plain `nvim` is not
affected.

This folder is a Stow package: `stow nvim-new` links `.config/nvim-new` to
`~/.config/nvim-new`. This README, `CLAUDE.md` and `docs/` are not linked
(`.stow-local-ignore`).

## Goals

- IDE-like workflow: working go-to-definition and references (LSP was never
  actually started in the old config), completion, diagnostics, formatting.
- A floating file explorer and fast fuzzy file jumping.
- Fast movement between Neovim splits (`<C-h/j/k/l>`); tmux panes keep
  their own keys (prefix + o, prefix + q + number).
- Only built-in machinery where it is good enough: `vim.pack` (Neovim 0.12)
  as plugin manager, `vim.lsp.config` for LSP. No lazy.nvim, no mason, no
  nvim-lspconfig unless there is a reason.
- Languages: Python, JS/TS/HTML/CSS, Lua; C later.

## Layout

```
.config/nvim-new/
├── init.lua               entry point; only require()s modules, in order
├── nvim-pack-lock.json    lockfile: exact plugin revisions (never edit by hand)
├── lsp/                   one file per language server (16: lua_ls.lua, pyright.lua, ...)
└── lua/
    ├── config/
    │   ├── options.lua    editor options (vim.o / vim.opt)
    │   ├── keymaps.lua    leader key and general keymaps
    │   ├── autocmds.lua   autocommands (highlight on yank, ...)
    │   └── lsp.lua        vim.lsp.enable, diagnostics, LspAttach keymaps
    └── plugins/           one file per plugin: vim.pack.add + setup + its keys
        ├── init.lua       require()s the files below, in order
        ├── colorscheme.lua  tokyonight (first, so the rest uses it)
        ├── treesitter.lua
        ├── fzf.lua        fzf-lua + <leader>f… keys
        ├── files.lua      mini.files + <leader>ee
        ├── animate.lua    mini.animate (scroll only)
        ├── pairs.lua      mini.pairs
        └── whichkey.lua   which-key: key hints popup, <leader> group names
```

Next to it: `CLAUDE.md` (working notes and current status, for Claude
sessions) and `docs/` (topic guides, e.g. `clipboard-and-registers.md`).

`require("config.options")` finds `lua/config/options.lua`: Neovim searches
the `lua/` folder of every directory on `runtimepath`, and dots in the name
become slashes. `require("plugins")` with no file name loads the folder's
`init.lua` (`lua/plugins/init.lua`); `require` has no wildcards, so that file
lists each plugin file by name. A new plugin = a new file + one line there.
which-key reads every map's `desc`, so good descriptions pay off;
`wk.add({ { "<leader>f", group = "find" } })` names a prefix (a list of
small tables, one per entry).

## Steps

Each step is a sub-issue of #13, done in order, all on the branch
`feat/13-nvim-from-scratch`. Every step has its own commit, `(#N)` in the
message.

| Step | Issue | Topic | Status |
|---|---|---|---|
| 0 | [#14](https://github.com/sebkaul/dotfiles/issues/14) | Setup + Lua primer | ✅ |
| 1 | [#15](https://github.com/sebkaul/dotfiles/issues/15) | Options | ✅ |
| 2 | [#16](https://github.com/sebkaul/dotfiles/issues/16) | Keymaps + autocommands | ✅ |
| 3 | [#17](https://github.com/sebkaul/dotfiles/issues/17) | Plugins via `vim.pack` + colorscheme | ✅ |
| 4 | [#18](https://github.com/sebkaul/dotfiles/issues/18) | Treesitter | ✅ |
| 5 | [#19](https://github.com/sebkaul/dotfiles/issues/19) | Fuzzy finder | ✅ |
| 6 | [#20](https://github.com/sebkaul/dotfiles/issues/20) | Floating file explorer | ✅ |
| 7 | [#21](https://github.com/sebkaul/dotfiles/issues/21) | Moving between files + tmux | ✅ |
| 8 | [#22](https://github.com/sebkaul/dotfiles/issues/22) | LSP | ✅ |
| 9 | [#23](https://github.com/sebkaul/dotfiles/issues/23) | Completion + snippets | 🚧 autopairs done, popup later |
| 10 | [#24](https://github.com/sebkaul/dotfiles/issues/24) | Diagnostics, formatting, linting | |
| 11 | [#25](https://github.com/sebkaul/dotfiles/issues/25) | Git integration | |
| 12 | [#26](https://github.com/sebkaul/dotfiles/issues/26) | UI polish + extras review | |
| 13 | [#27](https://github.com/sebkaul/dotfiles/issues/27) | C support | |
| 14 | [#28](https://github.com/sebkaul/dotfiles/issues/28) | Cutover: replace the old config | |

### Wishlist (after the core steps, no issues yet)

Collected 2026-11-17. Order and scope still open; each becomes its own step
and issue when we get there.

| Idea | Likely tool | Notes |
|---|---|---|
| ~~Key hints popup~~ ✅ | which-key.nvim (2026-11-20) | Shows the next possible keys after `<leader>`, `g`, `z`, `"`, ... |
| Theme rework | `:FzfLua colorschemes` to preview candidates | Goes with step 12; maybe match Ghostty / tmux (nord) |
| LaTeX: live compile + PDF | VimTeX + latexmk + zathura (SyncTeX) | zathura is VimTeX's recommended Linux viewer; needs `latexmk` (`texlive-binextra`); `texlab` LSP for completion |
| Images in Neovim | snacks.nvim `image` (kitty graphics protocol) | Ghostty supports it; inside tmux needs `allow-passthrough`. GIFs show as a still frame |
| Databases | vim-dadbod + vim-dadbod-ui | Browse schemas/tables and run queries in Neovim; or a TUI (harlequin, lazysql) in a tmux pane |
| Undo history tree | built-in `nvim.undotree` (`:packadd nvim.undotree`) | Ships with Neovim 0.12, no plugin |
| Markdown rendering | render-markdown.nvim | Headings, tables, checkboxes rendered in the buffer |

## Lua and Neovim notes, by step

**0 – Setup.** Neovim runs `init.lua` from the config folder at startup.
`local` makes a variable private to its file or block. Tables (`{}`) are
Lua's only data structure, serving as both lists and maps. A module is a
file that returns a table; `require` runs it once and caches the result.
Use `:lua <code>` to try things, `:messages` to see earlier output, `:help <topic>` for everything.

**1 – Options.** `vim.o.x = v` is `:set x=v` with plain values. `vim.opt.x`
returns an Option object with methods such as `:get()`, `:append()` and
`:remove()`, and accepts Lua tables for list and map options. `vim.wo` and
`vim.bo` are window-local and buffer-local only. `obj:method(arg)` is shorthand for
`obj.method(obj, arg)`. To find out who set an option last, use `:verbose set <name>?`.

**2 – Keymaps + autocommands.** `vim.keymap.set(mode, lhs, rhs, opts)`, where
`rhs` is either a key string or a Lua function. Functions are values: they
can be stored in variables and passed as arguments, and `function() ... end`
without a name is an anonymous function, used as a callback. Autocommands
run a callback on an event (`:help events`); putting them in an augroup with
`clear = true` keeps them from piling up when the file is re-sourced.
The system clipboard is not the default register (no `unnamedplus`): copy
with `"+y`, paste with `"+p` (see `docs/clipboard-and-registers.md`).

**3 – Plugins.** A plugin is a Git repo of Lua code. `vim.pack.add({ urls })`
clones missing ones into `~/.local/share/nvim-new/site/pack/core/opt/` and
puts them on the runtimepath, which is why `require("tokyonight")` then works.
Most plugins are configured with `require("name").setup({ options })`.
`vim.cmd.colorscheme("x")` runs `:colorscheme x`. The lockfile pins each
plugin to a commit; update with `:lua vim.pack.update()` (review, then
`:write` to accept).

**4 – Treesitter.** A parser per language turns the file into a syntax tree,
which gives exact highlighting (and later: text objects, folds). nvim-treesitter
only downloads and compiles parsers (`install({...})`, `:TSUpdate`); Neovim
itself does the highlighting via `vim.treesitter.start()`, which a `FileType`
autocmd calls for every buffer. `pcall(f, arg)` calls `f(arg)` but catches
errors instead of showing them (filetypes without a parser). Look around with
`:Inspect`, `:InspectTree`, `:checkhealth nvim-treesitter`.

**5 – Fuzzy finder.** fzf-lua drives the `fzf` binary (plus `fd` and `rg`).
`local fzf = require("fzf-lua")` keeps the module in a variable; mappings pass
its functions as rhs *without* `()` so they run on keypress, not at startup.
Plugin keymaps live next to the plugin: `keymaps.lua` runs before the plugins
are loaded, so `require` of a plugin there would fail. (A `"<cmd>FzfLua
files<CR>"` string would work, since it is only looked up on keypress.)

**6 – File explorer.** mini.files: yazi-style columns, `h`/`l` to move out/in,
and each column is a buffer you edit with normal Vim commands (`o` new file,
rename by typing, `dd` delete, `yy`/`p` copy), then apply with `=`. Options go
into nested tables (`windows = { ... }`, `options = { ... }`); a key in the
wrong group is silently ignored. `if not files.close() then files.open(...) end`
is a toggle. Removing a plugin: drop its URL, restart, `vim.pack.del({ "name" })`.
Watch out for `␣` (non-breaking space, AltGr+Space on the Norwegian layout):
Lua treats it as a name, not whitespace.

**7a – Splits.** `<C-w>` is Vim's window-command key (`<C-w>h` = go to the
left window), so `map("n", "<C-h>", "<C-w>h")` makes it a single key. Load
order matters: the plugin files run after `keymaps.lua`, so a plugin that maps
the same keys silently overrides yours (`:verbose map <C-h>` shows who won).
In mini.files, `mappings = { go_in_plus = "<CR>" }` makes Enter open a file
and close the explorer.

**7b – Moving between files.** Mostly built-in: buffers (`]b`/`[b`, `:bd`),
the alternate file (`<C-^>`, mapped to `<leader><leader>`), the jumplist
(`<C-o>` back, `<C-i>` forward), and marks: lowercase `ma`/`'a` within a file,
UPPERCASE `mA`/`'A` across files and restarts (a built-in harpoon). fzf-lua
adds searchable lists: `<leader>fm` marks, `<leader>fj` jumps.

**8 – LSP.** A language server is a separate program (from pacman) that
understands a whole project; Neovim's built-in client talks to it. Each
`lsp/<name>.lua` returns a table: `cmd` (program to start), `filetypes`,
`root_markers` (how to find the project root), `settings` (server-specific).
`vim.lsp.enable({ names })` switches them on. `LspAttach` fires when a server
connects; `{ buffer = args.buf }` makes a keymap exist only in that buffer.
Defaults: `K`, `grr`, `grn`, `gra`, `gri`, `gO`, `]d`/`[d`. Without a server,
`K` falls back to `man` and `gd` is Vim's plain "find local declaration".

**9 – Autopairs (completion popup postponed).** mini.pairs closes `( [ { " '`
as you type, steps over a closing bracket you type yourself, and Enter between
a pair puts the cursor on an indented empty line. Insert mode has its own
events: `CursorMoved` fires only in normal mode, `CursorMovedI` in insert
mode; an autocmd can listen to both with `{ "CursorMoved", "CursorMovedI" }`.
`for _, name in ipairs(list) do ... end` loops over a list. In Lua only
`false` and `nil` are false, so `vim.fn.executable(...)` (returns 0/1) needs
`== 1`.

## Checking things

```vim
:checkhealth            " general health, per-plugin checks later
:verbose set tabstop?   " current value and which file set it
:verbose map <leader>sv " which file defined a keymap
:lua =vim.o.tabstop     " '=' prints the value of a Lua expression
```
