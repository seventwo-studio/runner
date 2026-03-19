#!/bin/bash
# Setup shell configurations for runner user
# This ensures mise and other shell integrations work properly

set -e

USER="runner"
HOME="/home/$USER"

# Ensure user home directory exists
mkdir -p "$HOME"

# Setup .bashrc with simple prompt and mise integration
cat > "$HOME/.bashrc" << 'EOF'
# Simple bash configuration

# Set simple prompt
PS1="> "

# Basic aliases
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"

# Enable color support for ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# mise-en-place integration
export BUN_INSTALL="${HOME}/.bun"
export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:${HOME}/.bun/bin:${PATH}"
export MISE_AUTO_TRUST="true"
# Auto-initialize mise on first use
if [ ! -f "${HOME}/.local/share/mise/.initialized" ] && [ -x /usr/local/bin/mise-init ]; then
    /usr/local/bin/mise-init
fi
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi
EOF

# Setup .zshrc with simple prompt and mise integration
cat > "$HOME/.zshrc" << 'EOF'
# Simple zsh configuration

# Set simple prompt
PROMPT="> "

# Basic aliases
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"

# Enable color support for ls
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Basic zsh settings
setopt AUTO_CD
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# mise-en-place integration
export BUN_INSTALL="${HOME}/.bun"
export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:${HOME}/.bun/bin:${PATH}"
export MISE_AUTO_TRUST="true"
# Auto-initialize mise on first use
if [ ! -f "${HOME}/.local/share/mise/.initialized" ] && [ -x /usr/local/bin/mise-init ]; then
    /usr/local/bin/mise-init
fi
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi
EOF

# Setup .bash_profile (sourced for login bash shells)
cat > "$HOME/.bash_profile" << 'EOF'
# Bash profile configuration

# Source .bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF

# Setup .profile (POSIX shell profile, sourced by various shells)
cat > "$HOME/.profile" << 'EOF'
# POSIX shell profile

# Set PATH including mise shims
export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Source .bashrc if running bash and .bashrc exists
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF

# Setup .zshenv (always sourced by zsh - only place we need PATH for zsh)
cat > "$HOME/.zshenv" << 'EOF'
# Zsh environment configuration

# Set PATH including mise shims
export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF

# Setup .zprofile (empty placeholder for login zsh shells)
touch "$HOME/.zprofile"

# Set proper ownership
chown -R "$USER:$USER" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshenv" "$HOME/.zprofile"

echo "Shell configurations created for user: $USER"
