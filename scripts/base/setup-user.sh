#!/bin/bash
# Create the zero user (base devcontainer user)
set -e

USER=${1:-zero}
USER_ID=${2:-1000}
USER_GROUP=${3:-1000}

HOME=/home/$USER

echo "Creating user '$USER' (UID=$USER_ID, GID=$USER_GROUP)..."

if ! getent group "$USER_GROUP" &>/dev/null; then
    groupadd -g "$USER_GROUP" "$USER"
fi

useradd --uid "$USER_ID" --gid "$USER_GROUP" -m -s /bin/bash "$USER"

# Passwordless sudo
mkdir -p /etc/sudoers.d
echo "$USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER"
chmod 0440 "/etc/sudoers.d/$USER"

# Create user directories
mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/.local/bin" "$HOME/.cache"
chown -R "$USER:$USER" "$HOME"
touch "$HOME/.sudo_as_admin_successful"

echo "Created user '$USER'"
