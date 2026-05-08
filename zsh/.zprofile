# Source .zshrc if it exists
[[ -f ~/.zshrc ]] && source ~/.zshrc

# Start Hyprland on tty1 automatically
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    exec start-hyprland
fi

