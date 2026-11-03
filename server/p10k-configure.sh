#!/usr/bin/env bash
# Pick the servers' powerlevel10k look with the normal wizard, without touching this machine.
#   server/p10k-configure.sh
# Runs `p10k configure` in a throwaway ZDOTDIR + cache dir (so ~/.p10k.zsh and the laptop's
# instant-prompt cache stay untouched). After the wizard you get a preview shell; `exit` it to
# save the result as server/.p10k.zsh, which deploy.sh uploads to every host.
set -euo pipefail
here="$(dirname "$(realpath "$0")")"
theme=${P10K_THEME:-/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme}
[[ -r $theme ]] || { echo "powerlevel10k not found at $theme (set P10K_THEME)" >&2; exit 1; }

sandbox=$(mktemp -d); trap 'rm -rf "$sandbox"' EXIT
[[ -f $here/.p10k.zsh ]] && cp "$here/.p10k.zsh" "$sandbox/.p10k.zsh"
cat > "$sandbox/.zshrc" <<ZSHRC
source ${theme@Q}
[[ -f \$ZDOTDIR/.p10k.zsh ]] && source \$ZDOTDIR/.p10k.zsh
if [[ -z \$P10K_SANDBOX_STARTED ]]; then
  export P10K_SANDBOX_STARTED=1
  p10k configure
  print -P '%F{yellow}Server prompt preview. Type exit to save it to server/.p10k.zsh.%f'
fi
ZSHRC

ZDOTDIR=$sandbox XDG_CACHE_HOME=$sandbox/cache POWERLEVEL9K_CONFIG_FILE=$sandbox/.p10k.zsh zsh -i || true

if [[ -s $sandbox/.p10k.zsh ]]; then
  cp "$sandbox/.p10k.zsh" "$here/.p10k.zsh"
  echo "saved $here/.p10k.zsh. Run server/deploy.sh <host> to push it."
else
  echo "wizard did not write a config; nothing saved" >&2; exit 1
fi
