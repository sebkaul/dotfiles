#!/usr/bin/env bash
# Deploy the server zshrc and make zsh the login shell.
#   server/deploy.sh user@host [more hosts...]   (anything ssh accepts, incl. ~/.ssh/config aliases)
# Installs zsh (+ git, fzf, plugins where available) with apt/dnf/pacman/apk, backs up an
# existing ~/.zshrc to ~/.zshrc.bak, then chsh. Safe to re-run to push config updates.
# If server/.p10k.zsh exists (see p10k-configure.sh), also installs powerlevel10k into
# ~/.powerlevel10k and uploads the config as ~/.p10k.zsh.
set -euo pipefail
(( $# )) || { echo "usage: $0 user@host [user@host...]" >&2; exit 1; }
here="$(dirname "$(realpath "$0")")"
zshrc=$here/.zshrc p10k=$here/.p10k.zsh

# shellcheck disable=SC2016  # expands on the remote host
remote='set -e
SUDO=; [ "$(id -u)" -ne 0 ] && SUDO=sudo
if command -v apt-get >/dev/null; then
  $SUDO apt-get update -qq && $SUDO apt-get install -y -qq zsh git fzf zsh-autosuggestions zsh-syntax-highlighting >/dev/null
elif command -v dnf >/dev/null; then
  $SUDO dnf install -y -q zsh git fzf zsh-autosuggestions zsh-syntax-highlighting
elif command -v pacman >/dev/null; then
  $SUDO pacman -S --needed --noconfirm zsh git fzf zsh-autosuggestions zsh-syntax-highlighting
elif command -v apk >/dev/null; then
  $SUDO apk add -q zsh git fzf zsh-autosuggestions zsh-syntax-highlighting
else
  command -v zsh >/dev/null || { echo "no known package manager and no zsh installed" >&2; exit 1; }
fi
[ -f ~/.zshrc ] && [ "$(cksum < ~/.zshrc)" != "$(cksum < ~/.zshrc.new)" ] && cp ~/.zshrc ~/.zshrc.bak
mv ~/.zshrc.new ~/.zshrc
if [ -f ~/.p10k.zsh.new ]; then
  mv ~/.p10k.zsh.new ~/.p10k.zsh
  if [ -d ~/.powerlevel10k/.git ]; then git -C ~/.powerlevel10k pull -q --ff-only || echo "warn: powerlevel10k update failed" >&2
  else git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k || echo "warn: powerlevel10k clone failed, using plain prompt" >&2
  fi
fi
ZSH=$(command -v zsh)
grep -qx "$ZSH" /etc/shells || echo "$ZSH" | $SUDO tee -a /etc/shells >/dev/null
user=$(id -un)
if [ "$(getent passwd "$user" | cut -d: -f7)" != "$ZSH" ]; then
  $SUDO usermod -s "$ZSH" "$user" 2>/dev/null || chsh -s "$ZSH" 2>/dev/null ||
    $SUDO sed -i "s#^\($user:.*:\)[^:]*\$#\1$ZSH#" /etc/passwd  # e.g. Alpine without shadow
fi
echo "zsh ready on $(uname -n) (login shell: $(getent passwd "$user" | cut -d: -f7))"'

for host in "$@"; do
  echo "==> $host"
  # upload as *.new; the remote script moves them into place
  { scp -q "$zshrc" "$host:.zshrc.new" && { [[ ! -f $p10k ]] || scp -q "$p10k" "$host:.p10k.zsh.new"; } &&
    ssh -t "$host" "$remote"; } || echo "!! $host failed" >&2
done
