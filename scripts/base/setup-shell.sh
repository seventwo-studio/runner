#!/bin/bash
# Setup shell configurations for a user
set -e

USER=${1:-"zero"}
HOME="/home/$USER"

mkdir -p "$HOME"

cat > "$HOME/.bashrc" << 'EOF'
PS1="> "
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi
EOF

cat > "$HOME/.zshrc" << 'EOF'
PROMPT="> "
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi
setopt AUTO_CD
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
EOF

cat > "$HOME/.bash_profile" << 'EOF'
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF

cat > "$HOME/.profile" << 'EOF'
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF

cat > "$HOME/.zshenv" << 'EOF'
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF

touch "$HOME/.zprofile"

chown -R "$USER:$USER" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshenv" "$HOME/.zprofile"

echo "Shell configurations created for user: $USER"
