# Clipboard and registers

Every yank, delete and paste in Vim goes through a **register**, a named slot
that holds text. The system clipboard is just one of those registers.

## The registers you'll actually use

| Register | What's in it |
|---|---|
| `"` | **unnamed**: the default. Holds whatever you last yanked *or deleted*. |
| `0` | **last yank only**. Deletes never touch it. This is the one to use. |
| `1`–`9` | last 9 *line-or-bigger* deletes, newest in `1`, shifting down. |
| `-` | last small delete (less than a line, e.g. `dw`, `x`). |
| `a`–`z` | yours. `"ayy` stores in `a`; `"Ayy` (capital) **appends** to `a`. |
| `+` | **system clipboard** (Ctrl+C / Ctrl+V in other apps). |
| `*` | X11 "primary selection" (middle-click paste). On Wayland, also wl-clipboard. |
| `_` | **black hole**: whatever goes in is thrown away. |
| `.` `:` `/` | last inserted text, last `:` command, last search. Read-only. |

Using a register: put `"x` before the command.

```
"ayiw     yank inner word into register a
"ap       paste register a
"+yy      yank line to the system clipboard
"_dd      delete line without touching any register
"0p       paste the last *yank*, even after you deleted things since
```

In insert mode or on the `:` command line: `<C-r>x` pastes register `x`
(`<C-r>+` = clipboard, `<C-r>0` = last yank, `<C-r>/` = last search).

See everything: `:registers` (or `:reg a 0 +` for just those).

## What our config does

**Decision (2026-11-16): option 2 below.** `clipboard` is left empty, so
yanks and deletes stay inside Neovim, and the system clipboard only changes
with `"+y` / `"+p`.

For reference, `clipboard=unnamedplus` (the old setup) makes `+` the default
register, so:

- `yy` in Neovim → Ctrl+V in the browser works. Ctrl+C in the browser → `p` in
  Neovim works. No `"+` needed.
- **Catch:** `dd`, `x`, `cw`, `ciw` etc. also go to the clipboard. Yank a URL in
  the browser, delete a line in Neovim to make room, press `p`, and you get
  the deleted line back instead of the URL. The URL is gone from the clipboard.

The classic trick: **`"0p` still has your last Neovim yank**, whatever you
deleted after it. (It won't have text copied in another app, though.)

## Options for fixing the catch (pick one)

1. **Keep `unnamedplus`, learn `"0p` and `"_d`.** No config change. Good
   practice for registers.
2. **Turn `unnamedplus` off, map explicit clipboard keys.** Vim's registers
   stay internal and the clipboard changes only when you say so:
   `<leader>y` → `"+y`, `<leader>p` → `"+p`. Common setup; very predictable.
3. **Keep `unnamedplus`, make some deletes not clobber it.** E.g. `x` →
   `"_x` (single-char deletes are never worth keeping), and in visual mode
   `<leader>p` → `"_dP` (paste over a selection without losing what you
   pasted). Middle ground.

## Outside Neovim

- Shell: `wl-copy < file`, `cmd | wl-copy`, `wl-paste > file`,
  `wl-paste | jq .`. Check what's in the clipboard: `wl-paste`.
- Clipboard **history** (get back the URL from the example above) needs a
  manager such as `cliphist`. Not set up yet. Worth considering.
- **tmux:** copy mode (`prefix [`) has its own buffers, separate from the
  system clipboard, and our tmux.conf has no clipboard config yet. Planned
  with the tmux step (#21): vi keys in copy mode plus copying to wl-copy.
- **Over SSH:** `"+` needs a clipboard tool on the *remote* host. Neovim 0.10+
  can use OSC 52 instead (the terminal, Ghostty, sets your local clipboard).
  To look at later if it comes up.

## Practice

1. `yiw` a word, `dd` a line, then `p` vs `"0p`. Look at `:reg 0 "`.
2. `"ayy` on one line, `"Ayy` on another, then `"ap`.
3. In insert mode, `<C-r>0`. On the command line, `:%s/<C-r>0/new/g`.
4. Copy something in the browser, then `:reg +` in Neovim.
