# Dotfiles

Personal configuration files managed with **GNU Stow** and **Git**.

---

## Architecture

The system is split into three separate pieces:

```
~/dotfiles/             ← PUBLIC git repo (GitHub). All shareable config.
~/dotfiles/private/     ← PRIVATE git repo (GitHub, private). Secrets + machine-specific files.
~/Wallpapers/           ← Synced from server via rsync. Not in git.
```

These never mix. The only connections are:
- `~/.zshrc` sources `~/.local.zsh` (symlink → `~/dotfiles/private/local.zsh`)
- `hyprpaper.conf` references `~/Wallpapers/`

---

## Tool 1: GNU Stow

### What it is
Stow is a symlink manager. It takes files from inside `~/dotfiles/` and creates
symlinks for them in `~` (your home directory). Your applications never know the
difference — they read their config from the usual path, which is secretly a symlink
pointing into `~/dotfiles/`.

### How it works
Each subdirectory inside `~/dotfiles/` is called a **package**. The directory
structure inside a package mirrors where the files should live in `~`. For example:

```
~/dotfiles/waybar/.config/waybar/config.jsonc
              ↕  (stow creates this symlink)
~/.config/waybar/config.jsonc  →  ../dotfiles/waybar/.config/waybar/config.jsonc
```

Stow is always run from inside `~/dotfiles/`:

```bash
cd ~/dotfiles
stow waybar       # creates symlink for waybar
stow -D waybar    # removes symlink (unstow)
stow -R waybar    # remove + recreate (restow, useful after changes)
stow -n waybar    # dry-run: shows what WOULD happen without doing it
```

### Why this is powerful
- You edit files directly inside `~/dotfiles/` (or through their symlinks — same thing)
- Every change is immediately tracked by git
- One `git push` and your changes are available on all machines
- One `./install.sh` on a new machine and every symlink is created instantly

---

## Tool 2: Git

### Repository
- **Remote:** `https://github.com/sebkaul/dotfiles.git`
- **Branch:** `main`
- **Identity:** `sebkaul` (set in `~/.gitconfig`)
- **Visibility:** Public

### What is committed
Everything inside `~/dotfiles/` except what is listed in `.gitignore`:
- `hypr/.config/hypr/monitors.conf` (machine-specific)
- `hypr/.config/hypr/workspaces.conf` (machine-specific)
- `tmux/.config/tmux/plugins/` (installed at runtime by TPM)
- `*.bak` files

### Git history
The history has been deliberately kept minimal. All previous commits containing
private data (SSH hosts, IPs, wrong email addresses) were wiped by nuking `.git`
and recommitting from scratch.

### Day-to-day git workflow
When you edit a config file (e.g., change your hyprland keybindings):

```bash
# The file at ~/.config/hypr/keybindings.conf is a symlink, so this is the same as:
nvim ~/dotfiles/hypr/.config/hypr/keybindings.conf

# Then commit and push:
cd ~/dotfiles
git add hypr/.config/hypr/keybindings.conf
git commit -m "feat: add new keybinding for screenshot"
git push
```

On another machine, pull to get the update:
```bash
cd ~/dotfiles && git pull
```
Because the configs are symlinks, the new version is live immediately after pull.
No stow re-run needed.

---

## Tool 3: The Stow Packages (what is tracked)

Each package below is a directory inside `~/dotfiles/`. Running `stow <package>`
from `~/dotfiles/` creates the symlinks shown.

### Window Manager & Desktop

| Package | Symlink created | Contents |
|---|---|---|
| `hypr` | `~/.config/hypr/` | hyprland.conf, keybindings.conf, animations.conf, hyprpaper.conf, windowrules.conf, scripts/ |
| `waybar` | `~/.config/waybar/` | config.jsonc, style.css, scripts/ (weather, wallpaper switcher, power menu) |
| `swaync` | `~/.config/swaync/` | Notification daemon config and CSS |
| `wlogout` | `~/.config/wlogout/` | Logout screen layout, CSS, icons |
| `wofi` | `~/.config/wofi/` | App launcher config and CSS |
| `rofi` | `~/.config/rofi/` | Power menu config |
| `nwg-dock` | `~/.config/nwg-dock-hyprland/` | Dock CSS styling |

### Terminal & Shell

| Package | Symlink created | Contents |
|---|---|---|
| `ghostty` | `~/.config/ghostty/` | Terminal config, custom GLSL shaders (cursor smear effects) |
| `tmux` | `~/.config/tmux/` | tmux.conf (mouse, colors, keybindings). Plugins gitignored, installed by TPM. |
| `zsh` | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh` | Full zsh config, Powerlevel10k prompt, PATH exports, all public aliases. Sources `~/.local.zsh` for private aliases. |

### CLI Tools

| Package | Symlink created | Contents |
|---|---|---|
| `nvim` | `~/.config/nvim/` | Full Neovim config (lazy.nvim, LSP, treesitter, telescope, all plugins via lua/) |
| `yazi` | `~/.config/yazi/` | File manager config |
| `zathura` | `~/.config/zathura/` | PDF viewer config |
| `lazygit` | `~/.config/lazygit/` | Git TUI config |
| `fastfetch` | `~/.config/fastfetch/` | System info display config |
| `btop` | `~/.config/btop/` | System monitor config and themes |
| `mpv` | `~/.config/mpv/` | Video player config |

### System & Theming

| Package | Symlink created | Contents |
|---|---|---|
| `git` | `~/.gitconfig` | Global git identity, credential helper |
| `gtk` | `~/.gtkrc-2.0`, `~/.config/gtk-4.0/settings.ini`, `~/.config/nwg-look/config` | GTK2/4 theming, nwg-look theme settings |
| `fontconfig` | `~/.config/fontconfig/` | Font rendering rules, emoji font config |
| `xkb` | `~/.config/xkb/` | Custom keyboard layout (us_custom) |
| `mimeapps` | `~/.config/mimeapps.list` | Default application associations |

### Local Files

| Package | Symlinks created | Contents |
|---|---|---|
| `local-bin` | `~/.local/bin/alacritty-tmux.sh`, `battery_notify.sh`, `mpvv` | Custom shell scripts. Other files in `~/.local/bin/` (pip scripts, claude binary) are left unmanaged. |
| `local-applications` | `~/.local/share/applications/*.desktop` (individual symlinks) | Custom app launchers: web apps (Gmail, YouTube, etc.), school tools (skule/). Private shortcuts (SSH containers, Immich, private mail) live in `dotfiles-private` instead. |

---

## Tool 4: The Private System (`~/dotfiles/private/`)

This directory is a **separate private GitHub repo**. It is never part of the public dotfiles repo — `.gitignore` excludes `private/`.

### Structure

```
~/dotfiles/private/
├── local.zsh            ← private shell aliases (SSH hosts, server IPs, proxies)
├── monitors.conf        ← monitor layout for THIS machine (machine-specific)
├── sync.sh              ← git add + commit + push to GitHub
├── deploy.sh            ← wire up private files after cloning on a new machine
└── applications/        ← private .desktop launchers (SSH containers, Immich,
                            Nextcloud, NTNU mail, personal timetable, etc.)
```

### `local.zsh`
Contains all aliases that involve private IP addresses, server credentials, or
SSH connection details. Referenced from `~/.zshrc` via:
```zsh
[[ -f ~/.local.zsh ]] && source ~/.local.zsh
```
`~/.local.zsh` itself is a symlink: `~/.local.zsh → ~/dotfiles/private/local.zsh`
This symlink is created by `deploy.sh`.

### `monitors.conf`
Hyprland monitor configuration for this specific machine.
After cloning to a new machine, edit it for the new hardware:
```bash
hyprctl monitors all   # lists monitor names on the new machine
nvim ~/dotfiles/private/monitors.conf
```
`deploy.sh` copies (not symlinks) this to `~/.config/hypr/monitors.conf`.

### `sync.sh` — pushing changes to GitHub
```bash
~/dotfiles/private/sync.sh              # auto-commit + push
~/dotfiles/private/sync.sh "message"   # custom commit message
```

### `deploy.sh` — wiring up after cloning
Run this on a new machine after cloning the private repo:
```bash
~/dotfiles/private/deploy.sh
# Creates ~/.local.zsh symlink
# Copies monitors.conf to ~/.config/hypr/monitors.conf
# Symlinks private .desktop files into ~/.local/share/applications/
```

### Cloning the private repo on a new machine
```bash
git clone https://github.com/sebkaul/dotfiles-private.git ~/dotfiles/private
~/dotfiles/private/deploy.sh
# Then edit ~/.config/hypr/monitors.conf for this machine's displays
```

---

## Full New Machine Setup (step by step)

```bash
# 1. Install stow and git (on Arch: sudo pacman -S stow git)

# 2. Clone and stow the public dotfiles
git clone https://github.com/sebkaul/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh

# 3. Clone and deploy private files (monitors.conf, local.zsh, private .desktop files)
git clone https://github.com/sebkaul/dotfiles-private.git ~/dotfiles/private
~/dotfiles/private/deploy.sh
# Edit monitors.conf for this machine's displays:
hyprctl monitors all
nvim ~/.config/hypr/monitors.conf

# 4. Sync wallpapers from server
~/dotfiles/sync-wallpapers.sh bastel@YOUR_SERVER

# 5. Install runtime dependencies:
#    oh-my-zsh (if used):
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#    tmux plugins: open tmux, press prefix + I
#    nvim plugins: open nvim (lazy.nvim installs automatically)
```

---

## Day-to-Day Usage

### Editing a config
Just edit the file normally. Since everything is symlinked, editing through
the symlink path or the dotfiles path is identical:
```bash
nvim ~/.config/waybar/config.jsonc
# is exactly the same as:
nvim ~/dotfiles/waybar/.config/waybar/config.jsonc
```

### Pushing a config change to git
```bash
cd ~/dotfiles
git add .
git commit -m "feat: update waybar layout"
git push
```

### Pulling changes on another machine
```bash
cd ~/dotfiles && git pull
# Changes are live immediately — no stow re-run needed
```

### Updating private aliases
```bash
nvim ~/dotfiles/private/local.zsh
# Then push to GitHub:
~/dotfiles/private/sync.sh
# Pull on other machines:
cd ~/dotfiles/private && git pull
```

### Adding a new app's config to dotfiles
```bash
# 1. Create the package structure
mkdir -p ~/dotfiles/myapp/.config/myapp

# 2. Move the config into dotfiles
mv ~/.config/myapp ~/dotfiles/myapp/.config/myapp

# 3. Stow it (creates the symlink back)
cd ~/dotfiles && stow myapp

# 4. Add to install.sh packages array
nvim ~/dotfiles/install.sh   # add "myapp" to the packages=() array

# 5. Commit
git add myapp install.sh
git commit -m "feat: add myapp config"
git push
```

### Removing an app from dotfiles
```bash
cd ~/dotfiles
stow -D myapp              # removes symlinks
rm -rf myapp/              # removes from dotfiles
# optionally git commit the removal
```

---

## Scalability

### Multiple machines
The system is designed for this. Each machine:
- Clones the same git repo and runs `install.sh` — identical for all machines
- Has its own `~/dotfiles/private/` with machine-specific `monitors.conf`
- Has its own `~/.local.zsh` (symlinked from `~/dotfiles/private/local.zsh`), which
  can be different per machine if needed (just edit after syncing)

### Machine-specific config without forking
For settings that differ per machine (e.g., different monitor names, different
PATH entries), two mechanisms exist:
1. **`~/.local.zsh`** — for shell-level differences (PATHs, aliases, env vars)
2. **`~/.config/hypr/monitors.conf`** — for display layout

If a config file itself needs machine-specific sections, you can use hostname
checks inside the file:
```zsh
# In ~/.local.zsh
if [[ "$(hostname)" == "galaxybook" ]]; then
    alias klight0="echo 0 | sudo tee /sys/class/leds/samsung-galaxybook::kbd_backlight/brightness"
fi
```

### Adding a new private file type
If you have other sensitive files to track privately (e.g., VPN configs,
API key files, SSH known_hosts):
1. Add the file to `~/dotfiles/private/`
2. Add a deploy step in `~/dotfiles/private/deploy.sh` to symlink/copy it to the right place
3. Sync with `~/dotfiles/private/sync.sh`

### Branching strategy (optional, for heavy divergence)
If two machines are very different (e.g., desktop vs. laptop with completely
different Hyprland configs), consider:
```bash
git checkout -b desktop   # machine-specific branch
# make desktop-only changes, push branch
# on the desktop machine: git checkout desktop
```
Common changes go on `main`, machine-specific on branches. Pull `main` into
branches to stay up to date.

---

## What Is NOT Tracked and Why

| File/Directory | Reason |
|---|---|
| `~/.config/hypr/monitors.conf` | Different monitors on every machine |
| `~/.config/hypr/workspaces.conf` | Machine-specific workspace assignments |
| `~/.config/tmux/plugins/` | Installed at runtime by TPM (Tmux Plugin Manager) |
| `~/.local.zsh` | Symlink into `~/dotfiles/private/` — not a real file to track |
| `~/dotfiles/private/` | Separate private GitHub repo — never part of the public repo |
| `~/dotfiles/private/applications/*.desktop` | Contain private Tailscale IPs |
| `~/Wallpapers/` | Synced from server via `sync-wallpapers.sh` — binary files bloat git history |
| Browser profiles (Brave, Firefox) | User data, session state — not configuration |
| App state (Discord, Signal, Obsidian, Notion, Slack) | Runtime state, not config |
| `~/.cargo/`, `~/.rustup/`, `~/.npm/`, `~/.bun/` | Package manager caches, rebuilt on install |
| `~/.ssh/` | Private keys — never ever in git |
| `*.bak` files | Editor/manual backup artifacts |

---

## File Locations Cheat Sheet

| What | Where |
|---|---|
| All tracked configs | `~/dotfiles/<package>/.config/<name>/` |
| Install script (new machine) | `~/dotfiles/install.sh` |
| Migration script (first machine) | `~/dotfiles/migrate.sh` |
| AI assistant instructions | `~/dotfiles/CLAUDE.md` |
| Private aliases | `~/dotfiles/private/local.zsh` (symlinked to `~/.local.zsh`) |
| Monitor config | `~/.config/hypr/monitors.conf` (copy of `~/dotfiles/private/monitors.conf`) |
| Private push script | `~/dotfiles/private/sync.sh` |
| Private deploy script | `~/dotfiles/private/deploy.sh` |
| Private desktop files | `~/dotfiles/private/applications/` |
| Wallpaper sync script | `~/dotfiles/sync-wallpapers.sh` |
| Wallpapers | `~/Wallpapers/` (populated by sync-wallpapers.sh) |
| Public git remote | `https://github.com/sebkaul/dotfiles.git` |
| Private git remote | `https://github.com/sebkaul/dotfiles-private.git` |
