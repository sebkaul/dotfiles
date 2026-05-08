# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each subdirectory is a **Stow package** that mirrors the structure of `$HOME`. Running `stow <package>` from this directory creates symlinks in `~`.

## Package map

| Package | Symlinks to |
|---|---|
| `hypr` | `~/.config/hypr/` |
| `waybar` | `~/.config/waybar/` |
| `ghostty` | `~/.config/ghostty/` |
| `tmux` | `~/.config/tmux/` |
| `zsh` | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh` |
| `nvim` | `~/.config/nvim/` |
| `yazi` | `~/.config/yazi/` |
| `zathura` | `~/.config/zathura/` |
| `git` | `~/.gitconfig` |
| `lazygit` | `~/.config/lazygit/` |
| `btop` | `~/.config/btop/` |
| `mpv` | `~/.config/mpv/` |
| `fastfetch` | `~/.config/fastfetch/` |
| `swaync` | `~/.config/swaync/` |
| `rofi` | `~/.config/rofi/` |
| `wlogout` | `~/.config/wlogout/` |
| `wofi` | `~/.config/wofi/` |
| `nwg-dock` | `~/.config/nwg-dock-hyprland/` |
| `fontconfig` | `~/.config/fontconfig/` |
| `xkb` | `~/.config/xkb/` |
| `gtk` | `~/.gtkrc-2.0`, `~/.config/gtk-4.0/settings.ini`, `~/.config/nwg-look/config` |
| `mimeapps` | `~/.config/mimeapps.list` |
| `local-bin` | `~/.local/bin/{alacritty-tmux.sh,battery_notify.sh,mpvv}` |
| `local-applications` | `~/.local/share/applications/{custom .desktop files}` |

## Fresh machine setup

```bash
# 1. Clone and stow public dotfiles
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && ./install.sh

# 2. Clone and deploy private dotfiles (monitors.conf, local.zsh, private .desktop files)
git clone http://YOUR_SERVER:3000/sebkaul/dotfiles-private.git ~/dotfiles/private
~/dotfiles/private/deploy.sh
# Then edit ~/.config/hypr/monitors.conf for this machine's displays

# 3. Sync wallpapers from server
~/dotfiles/sync-wallpapers.sh bastel@YOUR_SERVER

# 4. Runtime installs
#    oh-my-zsh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#    tmux plugins — open tmux, press: prefix + I
#    nvim plugins  — open nvim (lazy.nvim auto-installs)
```

## First machine — migrating existing configs

Run once to move live configs into this repo and stow them:

```bash
cd ~/dotfiles
./migrate.sh
```

Then commit and push:

```bash
git add -A
git status          # review what was migrated
git commit -m "feat: initial dotfiles"
git remote add origin <repo-url>
git push -u origin main
```

## Machine-specific overrides

### Monitor layout

`~/.config/hypr/monitors.conf` is **gitignored**. Each machine creates its own:

```bash
cp ~/.config/hypr/monitors.conf.template ~/.config/hypr/monitors.conf
# edit for this hardware
```

`hyprpaper.conf` references monitor names — update it after setting up monitors.conf.

Note: `hyprland.conf` currently has inline `monitor=` lines that are also machine-specific. Long-term, consider removing those and using only `monitors.conf` via:
```ini
source = ~/.config/hypr/monitors.conf
```

### Private aliases and settings

`~/.local.zsh` is tracked in the **private Gitea repo** (`dotfiles-private`), not this public repo.
It is symlinked to `~/dotfiles/private/local.zsh` by `private/deploy.sh`.

`.zshrc` sources it automatically:
```zsh
[[ -f ~/.local.zsh ]] && source ~/.local.zsh
```

To update and push private aliases:
```bash
nvim ~/dotfiles/private/local.zsh
~/dotfiles/private/sync.sh
```

## Adding a new package

```bash
# 1. Create the package mirroring $HOME structure
mkdir -p ~/dotfiles/myapp/.config/myapp
mv ~/.config/myapp ~/dotfiles/myapp/.config/myapp

# 2. Stow it
cd ~/dotfiles && stow myapp

# 3. Add it to the packages array in install.sh

# 4. Commit
git add myapp install.sh && git commit -m "feat: add myapp config"
```

## Removing a package (unstow)

```bash
cd ~/dotfiles
stow -D myapp      # removes symlinks, real files stay in dotfiles/
```

## What is NOT tracked

| What | Why |
|---|---|
| `monitors.conf`, `workspaces.conf` | Machine-specific display/workspace setup |
| `tmux/plugins/` | Installed at runtime by TPM |
| `private/` | Separate private Gitea repo — never part of this public repo |
| `~/Wallpapers/` | Synced from server via `sync-wallpapers.sh` — binary blobs don't belong in git |
| Browser profiles (Brave, Firefox) | User data, not config |
| App state (Signal, Slack, Discord, Obsidian, Notion) | State, not config |
| `.cargo/`, `.rustup/`, `.npm/`, `.bun/` | Package manager caches |
| `*.bak` | Editor/manual backup files |

## Stow reference

```bash
stow <pkg>         # create symlinks
stow -D <pkg>      # remove symlinks (unstow)
stow -R <pkg>      # restow (remove + recreate)
stow --adopt <pkg> # pull existing files INTO the package (careful!)
stow -n <pkg>      # dry-run, show what would happen
```
