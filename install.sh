#!/usr/bin/env bash
# install.sh — stow all packages on a fresh machine after cloning.
# Run from ~/dotfiles after: git clone <repo> ~/dotfiles
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

packages=(
    hypr waybar ghostty tmux
    zsh nvim yazi zathura
    git lazygit btop mpv fastfetch
    swaync rofi wlogout wofi nwg-dock
    fontconfig xkb gtk mimeapps
    local-bin local-applications
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
