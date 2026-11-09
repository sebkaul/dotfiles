#!/usr/bin/env bash
# Deploy the server zsh setup for the SSH user. Never uses root; only writes to that user's $HOME.
#   server/deploy.sh user@host [more hosts...]   (anything ssh accepts, incl. ~/.ssh/config aliases)
# The host needs zsh and git; system packages (also eza/fzf) belong to host provisioning.
# Backs up a changed ~/.zshrc to ~/.zshrc.bak. Safe to re-run to push config updates.
# If server/.p10k.zsh exists (see p10k-configure.sh), also installs powerlevel10k into
# ~/.powerlevel10k and uploads the config as ~/.p10k.zsh.
# If the login shell isn't zsh, interactive logins start zsh from the shell profile instead.
set -euo pipefail
(( $# )) || { echo "usage: $0 user@host [user@host...]" >&2; exit 1; }
here="$(dirname "$(realpath "$0")")"
zshrc=$here/.zshrc p10k=$here/.p10k.zsh

remote=$(cat <<'REMOTE'
set -e
missing=
for tool in zsh git; do command -v "$tool" >/dev/null || missing="$missing $tool"; done
if [ -n "$missing" ]; then
  rm -f ~/.zshrc.new ~/.p10k.zsh.new
  echo "missing on $(uname -n):$missing (install with your host provisioning first)" >&2
  exit 1
fi
[ -f ~/.zshrc ] && [ "$(cksum < ~/.zshrc)" != "$(cksum < ~/.zshrc.new)" ] && cp ~/.zshrc ~/.zshrc.bak
mv ~/.zshrc.new ~/.zshrc
if [ -f ~/.p10k.zsh.new ]; then
  mv ~/.p10k.zsh.new ~/.p10k.zsh
  if [ -d ~/.powerlevel10k/.git ]; then git -C ~/.powerlevel10k pull -q --ff-only || echo "warn: powerlevel10k update failed" >&2
  else git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k || echo "warn: powerlevel10k clone failed, using plain prompt" >&2
  fi
fi
case ${SHELL:-} in
  */zsh) how="login shell" ;;
  *)
    how="started from shell profile"
    # bash reads only the first of these that exists; other shells read ~/.profile
    profile=~/.profile
    case ${SHELL:-} in */bash)
      if [ -f ~/.bash_profile ]; then profile=~/.bash_profile
      elif [ -f ~/.bash_login ]; then profile=~/.bash_login
      fi ;;
    esac
    marker='# server-zsh-hook'
    grep -qsF "$marker" "$profile" ||
      printf '%s\n' "case \$- in *i*) if command -v zsh >/dev/null; then SHELL=\$(command -v zsh); export SHELL; exec zsh -l; fi ;; esac $marker" >> "$profile"
    ;;
esac
echo "zsh ready on $(uname -n) for $(id -un) ($how)"
REMOTE
)

status=0
for host in "$@"; do
  echo "==> $host"
  # upload as *.new; the remote script moves them into place
  { scp -q "$zshrc" "$host:.zshrc.new" && { [[ ! -f $p10k ]] || scp -q "$p10k" "$host:.p10k.zsh.new"; } &&
    ssh -T "$host" sh -s <<<"$remote"; } || { echo "!! $host failed" >&2; status=1; }
done
exit "$status"
