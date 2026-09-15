[[ $- != *i* ]] && return

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize autocd

export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"

alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'
alias dots='cd ~/dots'
alias theme='~/dots/theme/apply.sh'

# path in accent colour, git branch dimmed, prompt on its own line
PS1='\[\e[35m\]\w\[\e[0m\] \[\e[2m\]$(git branch --show-current 2>/dev/null)\[\e[0m\]\n\$ '

eval "$(fzf --bash)"
