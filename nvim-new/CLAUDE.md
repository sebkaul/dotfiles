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

- **Done:** steps 0–4 (#14 setup, #15 options, #16 keymaps + autocmds,
  #17 vim.pack + tokyonight, #18 treesitter). Clipboard: option 2 (no
  `unnamedplus`, explicit `"+y`/`"+p`).
- Treesitter notes: nvim-treesitter `main` branch (the rewrite); not done yet
  (maybe later): folds, indentexpr (experimental), a `PackChanged` autocmd
  that runs `:TSUpdate` automatically. Until then, after `vim.pack.update()`,
  run `:TSUpdate`. The user hit "one error" while setting it up (2026-11-16)
  but didn't paste it, and Claude couldn't reproduce it (health all green). If
  it comes back, ask for the `:messages` output.
- **In progress: step 5 (#19), fuzzy finder.** fzf-lua (uses the `fzf`
  binary the user already uses in the shell). Instructions given 2026-11-16;
  the user writes it. Review, commit `(#19)`, mark ✅.
- **The user prefers small, spelled-out tasks:** say exactly which file and
  which lines, and explain every line. No puzzles.

## Open questions / flagged by the user

- **Clipboard and registers.** The user wants to use registers and the system
  clipboard well, both inside and outside Neovim. Guide:
  `docs/clipboard-and-registers.md`. Decided 2026-11-16: option 2 (no
  `unnamedplus`, explicit `"+`).
- tmux has no clipboard/copy-mode config yet (`tmux/.config/tmux/tmux.conf`).
  It belongs with step 7 (#21, tmux), or earlier if the clipboard work needs it.

- **Theme customization deferred.** The user likes tokyonight "night" for
  now but wants to iterate on it later (colors, maybe transparency, maybe
  another theme). Do it in step 12 (#26, UI polish) or whenever they ask.
- The user's files are indented with spaces, Claude's with tabs. A formatter
  (stylua, step 10) will make that consistent; no need to fix by hand.

## Environment facts

- Neovim 0.12.6, Arch, Hyprland (Wayland), Ghostty, tmux.
- Clipboard provider: `wl-copy`/`wl-paste` (wl-clipboard). No xclip.
