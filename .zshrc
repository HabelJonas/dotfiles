# Enable Powerlevel10k instant prompt (falls installiert, hier optional)
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# --- HISTORY ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# --- ALIASES ---
alias update='sudo pacman -Syu'
alias vim='nvim'
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -la'
alias grep='grep --color=auto'

# --- STARSHIP INIT ---
eval "$(starship init zsh)"

# --- AUTOSTART FASTFETCH ---
# Nur ausführen wenn interaktiv
if [[ -o interactive ]]; then
    fastfetch
fi
