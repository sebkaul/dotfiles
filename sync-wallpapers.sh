#!/usr/bin/env bash
# sync-wallpapers.sh — pull wallpapers from your server into ~/Wallpapers/.
# Usage: ./sync-wallpapers.sh [user@host]   (or set WALLPAPER_SERVER env var)
set -euo pipefail

SERVER="${1:-${WALLPAPER_SERVER:-}}"

if [[ -z "$SERVER" ]]; then
    echo "Usage: $0 user@hostname"
    echo "       or: export WALLPAPER_SERVER=user@hostname"
    exit 1
fi

# If ~/Wallpapers is a stow symlink from the old setup, replace it with a real dir
if [[ -L ~/Wallpapers ]]; then
    echo "Replacing ~/Wallpapers symlink with a real directory..."
    LINK_TARGET="$(readlink ~/Wallpapers)"
    rm ~/Wallpapers
    mkdir -p ~/Wallpapers
    if [[ -d "$LINK_TARGET" ]]; then
        cp -r "$LINK_TARGET"/. ~/Wallpapers/
    fi
fi

mkdir -p ~/Wallpapers

echo "Syncing wallpapers from $SERVER:~/Wallpapers/ → ~/Wallpapers/ ..."
rsync -av --progress --delete "$SERVER:~/Wallpapers/" ~/Wallpapers/

echo ""
echo "Done. $(ls ~/Wallpapers | wc -l) wallpapers in ~/Wallpapers/"
