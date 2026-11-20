# nv cheat sheet

Everything below works in the current config. Leader = **Space**.
Forgot something? **`<leader>fk`** and type a word: it searches every keymap
by its description.

Tip: open this file in `nv` and set **`mC`** on it. From then on, **`'C`**
brings you here from anywhere.

---

## Tier 1: learn these first (week 1)

The daily loop: find a file, move around, edit, copy, switch, repeat.

| Keys | What it does |
|---|---|
| `<leader>ff` | Find a file by name |
| `<leader>fs` | Search text in the whole project |
| `<leader>ee` | File explorer (`h` back, `l` in, **Enter** open + close, `q` quit) |
| `<leader><leader>` | Jump to the previous file, and back again |
| `Ctrl+o` / `Ctrl+i` | Back / forward through where you've been |
| `Ctrl+d` / `Ctrl+u` | Scroll 10 lines down / up, cursor stays centered (`zz`) |
| `Ctrl+h/j/k/l` | Move between splits |
| `<leader>sv` / `<leader>sx` | Split vertically / close the split |
| `"+y` / `"+p` | Copy to / paste from the system clipboard |
| `jk` | Leave insert mode |
| `Esc` | Also clears search highlighting |

## Tier 2: once Tier 1 feels automatic

| Keys | What it does |
|---|---|
| `<leader>fr` | Recent files |
| `<leader>fb` | Open buffers (files already loaded) |
| `<leader>fc` | Search the word under the cursor in the project |
| `mA` … `mZ` then `'A` … `'Z` | Pin a file to a letter, jump to it from anywhere |
| `<leader>fm` | List all marks |
| `]b` / `[b` | Next / previous buffer |
| `"0p` | Paste the last *yank*, even after deleting things |
| `"_d…` | Delete without touching any register |
| `J` / `K` (visual) | Move the selected lines down / up |
| `<` / `>` (visual) | Indent and keep the selection |

## Tier 3: nice to have

| Keys | What it does |
|---|---|
| `<leader>sh` / `<leader>se` | Split horizontally / make splits equal |
| `<leader>to` `tx` `tn` `tp` `tf` | Tab: new, close, next, previous, current file in new tab |
| `<leader>fh` | Search Neovim's help |
| `<leader>fj` | Searchable jumplist |
| `<leader>ow` | Toggle line wrap (Markdown, text, commit messages wrap automatically) |
| `gj` / `gk` | Down / up one *screen* line inside a wrapped line |
| `zz` / `zt` / `zb` | Put the cursor line in the middle / top / bottom of the screen |
| `<leader>+` / `<leader>-` | Increment / decrement the number under the cursor |
| `<C-r>0` (insert/`:`) | Insert the last yank while typing |
| `:reg` | Show what's in every register |

## Files: create, save, rename

| Command | What it does |
|---|---|
| `nv notes.md` (shell) | Open a file; if it doesn't exist, it's created on the first `:w` |
| `:e notes.md` | Same, from inside Neovim (**e**dit) |
| `:e %:h/notes.md` | New file next to the current file (`%:h` = current file's folder) |
| `:w` | Save |
| `:w notes.md` | Unnamed buffer: save it under that name. Named buffer: writes a *copy*, you stay in the original |
| `:w ++p sub/dir/notes.md` | Same, and create missing folders (`++p` = parents) |
| `:sav notes.md` | Save as: write under the new name *and* continue editing that one |
| `:wq` or `:x` | Save and quit (`:x` only writes if something changed) |
| `:q!` | Quit and throw away changes |
| `:e!` | Reload the file from disk, discarding changes |
| `:enew` | New empty, unnamed buffer |
| `<leader>ee` then `o`, name, `Esc`, `=`, `y` | Create a file in the explorer; only then Enter opens it |
| `<Tab>` after `:e ` | Complete file and folder names |

`%` stands for the current file name in any `:` command (`:!python %` runs it).

## Inside the explorer (`<leader>ee`)

| Keys | What it does |
|---|---|
| `h` / `l` | Out of / into a folder (`l` on a file opens it, explorer stays) |
| **Enter** | Open file and close the explorer |
| `<BS>` | Back to where you started |
| `g?` | All keys |
| Edit like text, then **`=`** (before Enter!) | `o` new file (`name/` = folder), retype to rename, `dd` delete (to trash), `yy`/`p` copy, `dd`/`p` move |

## Inside the fuzzy finder popup

`Ctrl+j` / `Ctrl+k` move · Enter opens · `Ctrl+v` / `Ctrl+s` open in a split ·
`Esc` closes · `F1` all keys

## When something is off

| Command | Use |
|---|---|
| `:messages` | Show recent errors and messages (paste these to Claude) |
| `:verbose map <keys>` | Which file defined a keymap last |
| `:verbose set <option>?` | Current value of an option and who set it |
| `:checkhealth` | Health of Neovim and its plugins |
| `␣` in the text | A non-breaking space (AltGr+Space): Lua breaks on it |
