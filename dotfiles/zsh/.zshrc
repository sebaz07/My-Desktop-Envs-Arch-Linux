export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)
source "$ZSH/oh-my-zsh.sh"

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH"
if [[ -d "$HOME/.linuxbrew" ]]; then
  export PATH="$HOME/.linuxbrew/bin:$PATH"
  export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
  export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"
fi

(( $+commands[bat] )) && alias cat='bat'
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
else
  alias ls='command ls --color=auto --group-directories-first'
fi
alias lsd='command ls --color=auto --group-directories-first -lh'

prepend-sudo() {
  BUFFER="sudo $BUFFER"
  CURSOR=$#BUFFER
}
zle -N prepend-sudo
bindkey '\e\e' prepend-sudo
export SHELL="$HOME/.local/bin/zsh"
