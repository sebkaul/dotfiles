# nvim-new

A Neovim config rebuilt from scratch, one step at a time, to learn Lua and
Neovim internals instead of copying a prebuilt setup. Tracked in
[#13](https://github.com/sebkaul/dotfiles/issues/13).

The old config (`../nvim`, based on josean's setup with lazy.nvim) keeps working
untouched until the cutover step. Both live side by side.

## Running it

```bash
nv            # alias for: NVIM_APPNAME=nvim-new nvim
```

`NVIM_APPNAME` tells Neovim which folder name to use everywhere, so `nv` reads
`~/.config/nvim-new` and keeps its plugins, undo history and state in
`~/.local/share/nvim-new` and `~/.local/state/nvim-new`. Plain `nvim` is not
affected.

This folder is a Stow package: `stow nvim-new` links `.config/nvim-new` to
`~/.config/nvim-new`. This README is not linked (Stow ignores `README.*` by
default).

## Goals

- IDE-like workflow: working go-to-definition and references (LSP was never
  actually started in the old config), completion, diagnostics, formatting.
- A floating file explorer and fast fuzzy file jumping.
- Seamless movement between Neovim splits and tmux panes.
- Only built-in machinery where it is good enough: `vim.pack` (Neovim 0.12)
  as plugin manager, `vim.lsp.config` for LSP. No lazy.nvim, no mason, no
  nvim-lspconfig unless there is a reason.
- Languages: Python, JS/TS/HTML/CSS, Lua; C later.

## Layout

```
.config/nvim-new/
├── init.lua               entry point; only require()s modules, in order
└── lua/config/
    ├── options.lua        editor options (vim.o / vim.opt)
    ├── keymaps.lua        leader key and general keymaps
    ├── autocmds.lua       autocommands (highlight on yank, ...)
    └── hello.lua          step 0 Lua primer, not loaded any more
```

`require("config.options")` finds `lua/config/options.lua`: Neovim searches
the `lua/` folder of every directory on `runtimepath`, and dots in the name
become slashes.

## Steps

Each step is a sub-issue of #13, done in order, all on the branch
`feat/13-nvim-from-scratch`. Every step has its own commit, `(#N)` in the
message.

| Step | Issue | Topic | Status |
|---|---|---|---|
| 0 | [#14](https://github.com/sebkaul/dotfiles/issues/14) | Setup + Lua primer | ✅ |
| 1 | [#15](https://github.com/sebkaul/dotfiles/issues/15) | Options | ✅ |
| 2 | [#16](https://github.com/sebkaul/dotfiles/issues/16) | Keymaps + autocommands | 🚧 |
| 3 | [#17](https://github.com/sebkaul/dotfiles/issues/17) | Plugins via `vim.pack` + colorscheme | |
| 4 | [#18](https://github.com/sebkaul/dotfiles/issues/18) | Treesitter | |
| 5 | [#19](https://github.com/sebkaul/dotfiles/issues/19) | Fuzzy finder | |
| 6 | [#20](https://github.com/sebkaul/dotfiles/issues/20) | Floating file explorer | |
| 7 | [#21](https://github.com/sebkaul/dotfiles/issues/21) | Moving between files + tmux | |
| 8 | [#22](https://github.com/sebkaul/dotfiles/issues/22) | LSP | |
| 9 | [#23](https://github.com/sebkaul/dotfiles/issues/23) | Completion + snippets | |
| 10 | [#24](https://github.com/sebkaul/dotfiles/issues/24) | Diagnostics, formatting, linting | |
| 11 | [#25](https://github.com/sebkaul/dotfiles/issues/25) | Git integration | |
| 12 | [#26](https://github.com/sebkaul/dotfiles/issues/26) | UI polish + extras review | |
| 13 | [#27](https://github.com/sebkaul/dotfiles/issues/27) | C support | |
| 14 | [#28](https://github.com/sebkaul/dotfiles/issues/28) | Cutover: replace the old config | |

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

## Checking things

```vim
:checkhealth            " general health, per-plugin checks later
:verbose set tabstop?   " current value and which file set it
:verbose map <leader>sv " which file defined a keymap
:lua =vim.o.tabstop     " '=' prints the value of a Lua expression
```
