# nvim-new — context for Claude

Read `README.md` in this folder first: it has the goals, the step table and
the Lua notes per step. This file is the part the README doesn't say: how we
work and where we left off.

## How we work

- **The user is learning, not just collecting a config.** Claude has written
  almost all of the code so far, so every change comes with an explanation: what
  it does, the Lua or Neovim idea behind it, and how to check it (`:verbose
  map`, `:lua =...`, `:help ...`). Keep the teaching comments in the files.
  They are deliberate, so don't strip them as clutter.
- **The user wants to be hands-on from step 2 onward** (asked 2026-11-16).
  They can't read keymap/Lua syntax well yet. So: explain a concept and its
  syntax first, let the user write or type the lines, then review. Don't
  write a whole step yourself unless asked. Decode syntax piece by piece
  (what `"x"`, `<cmd>...<CR>`, `{ desc = ... }` mean) rather than assuming it.
- Prefer the built-in machinery (`vim.pack`, `vim.lsp.config`) over plugins and
  wrappers unless there's a concrete reason (see README Goals).
- One step = one sub-issue of #13 = one commit on `feat/13-nvim-from-scratch`,
  message `feat(nvim-new): <topic> (#N)`. One PR for the whole rebuild, opened
  later. No PR exists yet.
- **Merge that PR with "Create a merge commit", NOT squash** (overrides the
  global squash habit). The user wants the per-day commits (13, 15, 16 Nov
  2026, ...) to show on their GitHub contribution graph, and squashing
  collapses them into one commit dated on the merge day.
- After each step, update the README: the step table status, the Layout tree,
  and a "Lua and Neovim notes" paragraph for that step.
- Run it with `nv` (`NVIM_APPNAME=nvim-new nvim`). Quick check that it loads
  with no errors:
  `NVIM_APPNAME=nvim-new nvim --headless -c 'qa'`
- The old config (`../nvim`) must keep working until step 14 (cutover).
- This file and the README are kept out of `~` by `.stow-local-ignore`.

## Where we are

Update this section at the end of every session.

- **Done:** step 0 (#14, setup + Lua primer) and step 1 (#15, options).
- **In progress: step 2 (#16, keymaps + autocmds).** `keymaps.lua` and
  `autocmds.lua` are written and `require`d from `init.lua`, and they load
  cleanly. Clipboard decided (option 2): `unnamedplus` removed from
  options.lua; the user copies with `"+y` by habit. Still **uncommitted**.
  Next: walk the user through reading `keymaps.lua`, let them try the binds
  and (optionally) write `<leader>y`/`<leader>p` clipboard maps themselves,
  then commit `(#16)` and mark step 2 ✅ in the README.
- **Next step:** 3 (#17), plugins via `vim.pack` plus a colorscheme.

## Open questions / flagged by the user

- **Clipboard and registers.** The user wants to use registers and the system
  clipboard well, both inside and outside Neovim. Guide:
  `docs/clipboard-and-registers.md`. Decided 2026-11-16: option 2 (no
  `unnamedplus`, explicit `"+`).
- tmux has no clipboard/copy-mode config yet (`tmux/.config/tmux/tmux.conf`).
  It belongs with step 7 (#21, tmux), or earlier if the clipboard work needs it.

## Environment facts

- Neovim 0.12.6, Arch, Hyprland (Wayland), Ghostty, tmux.
- Clipboard provider: `wl-copy`/`wl-paste` (wl-clipboard). No xclip.
