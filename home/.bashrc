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
# not 'dots': that name belongs to bin/dots, and an alias would shadow it
alias cdd='cd ~/dots'
alias theme='~/dots/theme/apply.sh'

# path in accent colour, git branch dimmed, prompt on its own line
PS1='\[\e[35m\]\w\[\e[0m\] \[\e[2m\]$(git branch --show-current 2>/dev/null)\[\e[0m\]\n\$ '

eval "$(fzf --bash)"
alias wall='~/dots/theme/wall.sh'

# --- dev environment ---
export GOPATH="$HOME/go"
export ANDROID_HOME="$HOME/Android/Sdk"
export CHROME_EXECUTABLE=/usr/bin/chromium
[ -d /usr/lib/jvm/java-17-openjdk ] && export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

for p in "$GOPATH/bin" "$HOME/.local/bin" "$HOME/development/flutter/bin" \
         "$ANDROID_HOME/emulator" "$ANDROID_HOME/platform-tools" \
         "$ANDROID_HOME/cmdline-tools/latest/bin" "$HOME/.npm-global/bin" "$HOME/.opencode/bin"; do
    case ":$PATH:" in *":$p:"*) ;; *) [ -d "$p" ] && PATH="$PATH:$p" ;; esac
done
export PATH

command -v starship >/dev/null && eval "$(starship init bash)"
command -v zoxide   >/dev/null && eval "$(zoxide init bash)"

# machine-local and untracked: anything naming hosts, IPs or secrets
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
