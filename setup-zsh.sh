#!/bin/env bash

# This script sets up a complete Zsh development environment.
# It installs packages, Oh My Zsh, NVM, Node.js, and configures the .zshrc file.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Updating package list ---"
sudo apt-get update

echo "--- Installing prerequisites: zsh, git, curl, fzf, fd-find, tmux, vim ---"
sudo apt-get install -y zsh git curl fzf fd-find tmux vim

# On Ubuntu, the 'fd' command is installed as 'fdfind'.
# We'll create a symlink from 'fd' to 'fdfind' in the user's local bin.
echo "--- Creating a symlink for fd -> fdfind ---"
mkdir -p "$HOME/.local/bin"
ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"

# Install Oh My Zsh non-interactively if it's not already installed.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "--- Installing Oh My Zsh ---"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "--- Oh My Zsh is already installed. Skipping. ---"
fi

# Define the custom plugins and themes directory
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# Install zsh-autosuggestions plugin
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    echo "--- Installing zsh-autosuggestions plugin ---"
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
else
    echo "--- zsh-autosuggestions plugin already installed. Skipping. ---"
fi

# Install zsh-syntax-highlighting plugin
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    echo "--- Installing zsh-syntax-highlighting plugin ---"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
else
    echo "--- zsh-syntax-highlighting plugin already installed. Skipping. ---"
fi

# Install Pure prompt theme
if [ ! -d "$HOME/.zsh/pure" ]; then
    echo "--- Installing Pure prompt theme ---"
    mkdir -p "$HOME/.zsh"
    git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
else
    echo "--- Pure prompt theme already installed. Skipping. ---"
fi

# Install NVM
echo "--- Installing NVM (Node Version Manager) ---"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Source NVM script to make it available in this script session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "--- Installing latest LTS version of Node.js via NVM ---"
nvm install --lts
nvm alias default 'lts/*' # Set the default node version for new shells

echo "--- Installing Google Gemini CLI ---"
npm install -g @google/gemini-cli

echo "--- Creating .zshrc configuration file ---"

# Use a heredoc to write the .zshrc file.
# This overwrites the existing file with the new, Pi-compatible configuration.
cat > "$HOME/.zshrc" << 'EOF'
# This file was generated to replicate a macOS zsh environment on a Raspberry Pi.
# Some macOS-specific configurations have been adapted for Ubuntu Server.

# Add ~/.local/bin to the PATH for custom scripts and symlinks (like fd)
export PATH="$HOME/.local/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"

# NVM (Node Version Manager)
# This loads nvm and its bash completion
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# hyphen-insensitive auto-complete
HYPHEN_INSENSITIVE="true"

# command auto-correction.
ENABLE_CORRECTION="false"

# display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# disable marking untracked files under VCS as dirty for performance.
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# Set vim as the default editor for remote sessions.
export EDITOR='vim'

alias zconfig="$EDITOR $HOME/.zshrc"
alias zsource="source $HOME/.zshrc"

# Pure theme setup
fpath+=($HOME/.zsh/pure)
autoload -Uz promptinit
promptinit
prompt pure

# fzf and fd configuration
# fd is used for finding files and directories.
export FZF_DEFAULT_COMMAND="fd -a -t d . $HOME"
alias f="cd \$(fzf)"
alias ff="fd -t f . $HOME | fzf"
alias fff="fd -t f . | fzf"

# Override cat to use fzf for file selection if no arguments are given
cat() {
    if [ "$#" -eq 0 ]; then
        command cat "$(fff)"
    else
        command cat "$@"
    fi
}

# python alias
alias python=python3
alias pip=pip3

# tmux alias
alias note="tmux a -t note-taker"
alias tmuxconf="$EDITOR $HOME/.tmux.conf"

# gemini cli
# This assumes the Gemini CLI was installed via npm and is in the NVM path.
if [ -f "$HOME/.gemini/init.sh" ]; then
  source "$HOME/.gemini/init.sh"
fi

# The gcloud CLI configuration from the original .zshrc was removed
# as it contained macOS-specific paths. You may need to reinstall
# and reconfigure gcloud CLI on this machine if needed.
EOF

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Make Zsh your default shell by running: chsh -s \$(which zsh)"
echo "   (You will be prompted for your password)."
echo "2. Log out and log back in to apply all changes."
