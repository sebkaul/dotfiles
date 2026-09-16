#!/usr/bin/env bash
# install.sh — stow all packages on a fresh machine after cloning.
# Run from ~/dotfiles after: git clone <repo> ~/dotfiles
#
#   ./install.sh            stow packages into ~ (no root needed)
#   ./install.sh --system   copy root-owned files into / (needs sudo)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# Files that live outside $HOME, as <package>/system/<path under />.
# These are COPIED as root, never symlinked: pacman runs hooks as root, and a
# symlink into this user-writable repo would let anything running as you
# change what root executes on the next upgrade. Re-run after editing them.
system_files=(
    syscheck/system/etc/pacman.d/hooks/95-reboot-pending.hook
)

if [[ "${1:-}" == "--system" ]]; then
    for src in "${system_files[@]}"; do
        dst="/${src#*/system/}"
        echo "Installing $dst (root)..."
        sudo install -D -m 644 -o root -g root "$src" "$dst"
    done
    exit 0
fi

packages=(
    hypr waybar ghostty tmux
    zsh nvim yazi zathura
    git lazygit btop mpv fastfetch
    swaync rofi wlogout wofi nwg-dock
    fontconfig xkb gtk mimeapps
    local-bin local-applications
    opencode syscheck
)
# Note: wallpapers are NOT stowed — run ./sync-wallpapers.sh user@server to populate ~/Wallpapers/

for pkg in "${packages[@]}"; do
    if [[ -d "$pkg" ]]; then
        echo "Stowing $pkg..."
        stow "$pkg"
    else
        echo "  (skipping $pkg — directory not found)"
    fi
done

echo ""
echo "Done. Post-install checklist:"
echo "  1. Clone and deploy private files (contains monitors.conf, local.zsh, private .desktop files):"
echo "       git clone http://YOUR_SERVER:3000/sebkaul/dotfiles-private.git ~/dotfiles/private"
echo "       ~/dotfiles/private/deploy.sh"
echo "       # then edit ~/.config/hypr/monitors.conf for this machine's displays"
echo "       # run: hyprctl monitors all"
echo "  2. Sync wallpapers from server:"
echo "       ~/dotfiles/sync-wallpapers.sh user@YOUR_SERVER"
echo "  3. Install oh-my-zsh (if not already):"
echo "       sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
echo "  4. Install tmux plugins: open tmux, press prefix + I"
echo "  5. Install nvim plugins: open nvim (lazy.nvim runs automatically)"
echo "  6. Deploy root-owned system files (pacman reboot-pending hook) — needs root:"
echo "       ~/dotfiles/install.sh --system"
