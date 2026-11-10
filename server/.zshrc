# Server zshrc — self-contained, no hard dependencies. Deployed by server/deploy.sh.
# Optional tools (eza, zoxide, fzf, zsh plugins) are used only if installed; deploy.sh puts
# eza, zoxide and fzf in ~/.local/bin.
# Host-specific additions go in ~/.zshrc.local (never overwritten).

# p10k instant prompt (only once deploy.sh has installed powerlevel10k). Keep near the top.
if [[ -r ~/.powerlevel10k/powerlevel10k.zsh-theme && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -U path
path=(~/.local/bin $path)

# -- History -- #
HISTFILE=~/.zsh_history HISTSIZE=12000 SAVEHIST=10000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE HIST_IGNORE_ALL_DUPS \
       HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP

# -- Completion -- #
autoload -Uz compinit && compinit -d ~/.zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# -- Keys (emacs mode; up/down and ^K/^J search history by prefix) -- #
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search '^[OA' up-line-or-beginning-search '^K' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search '^[OB' down-line-or-beginning-search '^J' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line '^[[F' end-of-line '^[[3~' delete-char

# -- Prompt: powerlevel10k with the server config (server/.p10k.zsh) if deployed, -- #
# -- else plain user@host:cwd (branch) — host in yellow, red when root            -- #
if [[ -r ~/.powerlevel10k/powerlevel10k.zsh-theme && -r ~/.p10k.zsh ]]; then
  source ~/.powerlevel10k/powerlevel10k.zsh-theme
  source ~/.p10k.zsh
else
  autoload -Uz vcs_info && precmd() { vcs_info }
  zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'
  setopt PROMPT_SUBST
  PROMPT='%(!.%F{red}.%F{green})%n%f@%F{yellow}%m%f:%F{blue}%~%f${vcs_info_msg_0_} %(?..%F{red}[%?]%f )%(!.#.$) '
fi

# -- Environment -- #
export EDITOR=$(command -v nvim || command -v vim || echo vi) PAGER=less LESS=-R

# -- Aliases -- #
# same as the laptop (zsh/.zshrc); icons need a Nerd Font in the *local* terminal
if (( $+commands[eza] )); then
  alias ls='eza --icons --long --header --color=always' la='eza --long --header --icons --git --all --color=always'
  alias lss='eza --tree --icons --level=2 --color=always'
else
  alias ls='ls -lhF --color=auto' la='ls -lAhF --color=auto'
  (( $+commands[tree] )) && alias lss='tree -C -L 2'
fi
alias c=clear cl='clear && ls' ..='cd ..' ...='cd ../..' grep='grep --color=auto' please=sudo
alias df='df -h' du='du -h' free='free -h' ports='ss -tulpn' myip='curl -s ifconfig.me; echo'
alias zshconf='$EDITOR ~/.zshrc' reload='exec zsh'
# tmux
alias t=tmux tls='tmux ls' ta='tmux attach' tma='tmux attach -t'
# git
alias g=git gs='git status -sb' gl='git log --oneline --graph -20' gd='git diff' gp='git pull'
# systemd
alias sc='sudo systemctl' scs='systemctl status' scr='sudo systemctl restart' jf='journalctl -fu' jx='journalctl -xeu'
# docker
alias d=docker dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"' dc='docker compose' dcl='docker compose logs -f'

mkcd() { mkdir -p -- "$1" && cd -- "$1" }
extract() {
  case $1 in
    *.tar.gz|*.tgz) tar xzf $1 ;; *.tar.xz) tar xJf $1 ;; *.tar.bz2) tar xjf $1 ;;
    *.tar) tar xf $1 ;; *.zip) unzip $1 ;; *.gz) gunzip $1 ;; *.7z) 7z x $1 ;;
    *) echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
  esac
}

# -- Optional tools and plugins (Debian/Ubuntu, Fedora and Arch paths) -- #
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
# fzf: built-in integration (fzf >= 0.48, e.g. the ~/.local/bin one from deploy.sh), else distro key-bindings
if (( $+commands[fzf] )) && fzf --zsh &>/dev/null; then
  source <(fzf --zsh)
else
  for f in /usr/share/{fzf/key-bindings.zsh,doc/fzf/examples/key-bindings.zsh,fzf/shell/key-bindings.zsh}; do
    [[ -r $f ]] && { source $f; break; }
  done
fi
# zsh-syntax-highlighting must be sourced last
for f in /usr/share/{zsh/plugins/,}zsh-autosuggestions/zsh-autosuggestions.zsh \
         /usr/share/{zsh/plugins/,}zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r $f ]] && source $f
done; unset f

if [[ -f ~/.zshrc.local ]]; then source ~/.zshrc.local; fi
