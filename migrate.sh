#!/usr/bin/env bash
# migrate.sh — moves existing configs from ~ into dotfiles/ and stows them.
# Run ONCE on the first machine. After this, use install.sh on other machines.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

info()  { echo "  → $1"; }
warn()  { echo "  ! $1"; }
title() { echo ""; echo "[$1]"; }

# Moves a file/dir only if it is not already a symlink.
# Usage: move_to SRC DST_DIR
move_to() {
    local src="$1" dst_dir="$2"
    local name
    name="$(basename "$src")"
    if [[ -L "$src" ]]; then
        info "Already a symlink — skipping: $src"
        return 0
    fi
    if [[ ! -e "$src" ]]; then
        info "Not found — skipping: $src"
        return 0
    fi
    mkdir -p "$dst_dir"
    mv "$src" "$dst_dir/$name"
    info "Moved $src → $dst_dir/$name"
}

# Moves an entire config dir (e.g. ~/.config/foo → dotfiles/foo/.config/foo)
move_config_dir() {
    local name="$1" src="${HOME}/.config/$1" pkg="$DOTFILES/$1"
    if [[ -L "$src" ]]; then
        info "Already a symlink — skipping: $src"
        return 0
    fi
    if [[ ! -d "$src" ]]; then
        info "Not found — skipping: $src"
        return 0
    fi
    mkdir -p "$pkg/.config"
    mv "$src" "$pkg/.config/$name"
    info "Moved $src → $pkg/.config/$name"
    stow "$1"
    info "Stowed $1"
}

echo "=== Migrating configs into dotfiles/ and stowing ==="
echo "Run this once. If a stow step fails, fix conflicts then re-run."

# ── WM & Desktop ─────────────────────────────────────────────────────────────

title "hypr"
if [[ -d "${HOME}/.config/hypr" && ! -L "${HOME}/.config/hypr" ]]; then
    # Save monitors.conf as template (it's gitignored)
    [[ -f "${HOME}/.config/hypr/monitors.conf" ]] && \
        cp "${HOME}/.config/hypr/monitors.conf" "$DOTFILES/hypr/.config/hypr/monitors.conf.template" && \
        info "Saved monitors.conf.template"
    mkdir -p "$DOTFILES/hypr/.config"
    mv "${HOME}/.config/hypr" "$DOTFILES/hypr/.config/hypr"
    # Remove machine-specific files so they are gitignored (each machine makes their own)
    rm -f "$DOTFILES/hypr/.config/hypr/monitors.conf"
    rm -f "$DOTFILES/hypr/.config/hypr/workspaces.conf"
    stow hypr
    info "Stowed hypr"
    warn "IMPORTANT: monitors.conf is gitignored. After migration:"
    warn "  cp ~/.config/hypr/monitors.conf.template ~/.config/hypr/monitors.conf"
    warn "  Edit monitors.conf for this machine's displays."
    warn "  Also: hyprland.conf has inline monitor= lines — consider removing them"
    warn "  and using 'source = ~/.config/hypr/monitors.conf' instead."
else
    info "Skipping"
fi

title "waybar"
move_config_dir waybar

title "swaync"
move_config_dir swaync

title "wlogout"
move_config_dir wlogout

title "wofi"
move_config_dir wofi

title "rofi"
move_config_dir rofi

title "nwg-dock"
if [[ -d "${HOME}/.config/nwg-dock-hyprland" && ! -L "${HOME}/.config/nwg-dock-hyprland" ]]; then
    mkdir -p "$DOTFILES/nwg-dock/.config"
    mv "${HOME}/.config/nwg-dock-hyprland" "$DOTFILES/nwg-dock/.config/nwg-dock-hyprland"
    stow nwg-dock
    info "Stowed nwg-dock"
else
    info "Skipping"
fi

# ── Terminal & Shell ──────────────────────────────────────────────────────────

title "ghostty"
move_config_dir ghostty

title "tmux"
move_config_dir tmux

title "zsh"
mkdir -p "$DOTFILES/zsh"
move_to "${HOME}/.zshrc"    "$DOTFILES/zsh"
move_to "${HOME}/.zprofile" "$DOTFILES/zsh"
move_to "${HOME}/.p10k.zsh" "$DOTFILES/zsh"
# Add local.zsh sourcing if not already there
if [[ -f "$DOTFILES/zsh/.zshrc" ]] && ! grep -q "local.zsh" "$DOTFILES/zsh/.zshrc"; then
    printf '\n# Machine-specific settings (gitignored, lives in ~/.local.zsh)\n[[ -f ~/.local.zsh ]] && source ~/.local.zsh\n' \
        >> "$DOTFILES/zsh/.zshrc"
    info "Added ~/.local.zsh source to .zshrc"
fi
stow zsh
info "Stowed zsh"
warn "Move private aliases (IPs, SSH jump hosts) from .zshrc to ~/.local.zsh"
warn "  ~/.local.zsh is NOT in this repo — it stays only on each machine."

# ── CLI Tools ─────────────────────────────────────────────────────────────────

title "nvim"
move_config_dir nvim

title "yazi"
move_config_dir yazi

title "zathura"
move_config_dir zathura

title "lazygit"
move_config_dir lazygit

title "fastfetch"
move_config_dir fastfetch

title "btop"
move_config_dir btop

title "mpv"
move_config_dir mpv

# ── System / Theming ──────────────────────────────────────────────────────────

title "git"
mkdir -p "$DOTFILES/git"
move_to "${HOME}/.gitconfig" "$DOTFILES/git"
stow git
info "Stowed git"

title "gtk"
mkdir -p "$DOTFILES/gtk/.config/gtk-4.0" "$DOTFILES/gtk/.config/nwg-look"
move_to "${HOME}/.gtkrc-2.0"                  "$DOTFILES/gtk"
move_to "${HOME}/.config/gtk-4.0/settings.ini" "$DOTFILES/gtk/.config/gtk-4.0"
move_to "${HOME}/.config/nwg-look/config"      "$DOTFILES/gtk/.config/nwg-look"
stow gtk
info "Stowed gtk"

title "fontconfig"
move_config_dir fontconfig

title "xkb"
move_config_dir xkb

title "mimeapps"
mkdir -p "$DOTFILES/mimeapps/.config"
move_to "${HOME}/.config/mimeapps.list" "$DOTFILES/mimeapps/.config"
stow mimeapps
info "Stowed mimeapps"

# ── Local files ───────────────────────────────────────────────────────────────

title "local-bin"
mkdir -p "$DOTFILES/local-bin/.local/bin"
for script in alacritty-tmux.sh battery_notify.sh mpvv; do
    move_to "${HOME}/.local/bin/$script" "$DOTFILES/local-bin/.local/bin"
done
stow local-bin
info "Stowed local-bin"

title "local-applications"
mkdir -p "$DOTFILES/local-applications/.local/share/applications"
custom_desktops=(
    archbox.desktop archmc.desktop barch.desktop
    chatGPT.desktop claude-code-url-handler.desktop
    debianbox.desktop discordgames.desktop
    facebook.desktop github.desktop gmail.desktop
    google-calendar.desktop google-drive.desktop
    googlekeep.desktop immich.desktop instagram.desktop
    layoutchanger.desktop pacseek.desktop sbm.desktop
    sebkaulmail.desktop snapchat.desktop spond.desktop
    stack-overflow.desktop tailscale.desktop
    wikipedia.desktop youtube.desktop
    # excluded: ncarch.desktop, ncdebian.desktop (contain private Tailscale IPs — create per-machine)
    # excluded: passwordmanager.desktop (Brave PWA, machine-specific)
)
for d in "${custom_desktops[@]}"; do
    move_to "${HOME}/.local/share/applications/$d" \
        "$DOTFILES/local-applications/.local/share/applications"
done
# skule/ subdirectory
if [[ -d "${HOME}/.local/share/applications/skule" && ! -L "${HOME}/.local/share/applications/skule" ]]; then
    mv "${HOME}/.local/share/applications/skule" \
        "$DOTFILES/local-applications/.local/share/applications/skule"
    info "Moved applications/skule/"
fi
stow local-applications
info "Stowed local-applications"

title "wallpapers"
if [[ -d "${HOME}/Wallpapers" && ! -L "${HOME}/Wallpapers" ]]; then
    mkdir -p "$DOTFILES/wallpapers"
    mv "${HOME}/Wallpapers" "$DOTFILES/wallpapers/Wallpapers"
    stow wallpapers
    info "Stowed wallpapers"
else
    info "Skipping"
fi

# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "=== Migration complete ==="
echo ""
echo "Next steps:"
echo "  1. Create ~/.config/hypr/monitors.conf from the template:"
echo "       cp ~/.config/hypr/monitors.conf.template ~/.config/hypr/monitors.conf"
echo "  2. Create ~/.local.zsh and move sensitive aliases there:"
echo "       touch ~/.local.zsh"
echo "  3. Review what was migrated:"
echo "       cd $DOTFILES && git status"
echo "  4. Commit and push:"
echo "       git add -A && git commit -m 'feat: initial dotfiles'"
echo "       git remote add origin <repo-url>"
echo "       git push -u origin main"
