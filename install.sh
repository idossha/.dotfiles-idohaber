#!/bin/bash

########################################
# dotfiles installation script of Ido Haber
# Last update: December 20, 2024
########################################

set -e  # Exit immediately if a command exits with a non-zero status

# ============================
# Variables and Configuration
# ============================

# Home directory
HOME_DIR="$HOME"

# Directory where the dotfiles are located
DOTFILES_DIR="$HOME/.dotfiles"

# Oh My Zsh installation directory
OH_MY_ZSH_DIR="$HOME/oh-my-zsh"

# Define common and OS-specific packages
COMMON_CONFS=("bash" "nvim" "tmux" "vscode" "github" "neofetch" "alacritty" "htop" "ghostty" "nushell" "misc" "sketchybar" "karabiner") #kitty
MACOS_CONFS=("zsh" "aerospace") 
LINUX_CONFS=()  # Add any Linux-specific packages if needed

# Define Homebrew Cask and Brew packages (macOS)
BREW_CASK_PACKAGES=(
  keyboardcleantool     
  #raycask
  zen-browser
  ghostty
  # kitty                     # Kitty terminal emulator
)

BREW_PACKAGES=(
  tmux
  neovim
  git
  ripgrep
  fzf
  tree-sitter
  zoxide
  bat
  direnv
  sketchybar
  htop
  lazygit
  lazydocker
  neofetch
  node
  jq
  pillow
  pandoc
  ffmpeg
  nikitabobko/tap/aerospace   
  stats
  nushell
  imagemagick
  # alacritty
)

# Define APT packages (Linux)
APT_PACKAGES=(
  tmux
  git
  bat
  zoxide
  neovim
  ripgrep
  nodejs
  npm
  jq
  direnv
  tree
  pandoc
  ffmpeg
  htop
  fzf
  zsh
  neofetch
  ghostty
  # kitty
  # alacritty
)

# Function to print messages with separators for better readability
print_message() {
  echo "========================================"
  echo "$1"
  echo "========================================"
}

# ============================
# OS Detection
# ============================

OS="$(uname)"
is_mac=false
is_linux=false

if [ "$OS" == "Darwin" ]; then
  is_mac=true
elif [ "$OS" == "Linux" ]; then
  is_linux=true
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# ============================
# Package Manager Installation
# ============================

install_homebrew() {
  print_message "Checking for Homebrew..."
  sleep 1
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if $is_mac; then
      # For Apple Silicon Macs
      if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        # For Intel Macs
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    elif $is_linux; then
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  else
    echo "Homebrew is already installed."
  fi

  # Update Homebrew
  print_message "Updating Homebrew..."
  brew update
}

install_apt_packages() {
  print_message "Updating APT..."
  sudo apt update

  print_message "Upgrading existing packages..."
  sudo apt upgrade -y

  print_message "Installing APT packages..."
  for package in "${APT_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
      echo "Installing $package..."
      sudo apt install -y "$package"
    else
      echo "$package is already installed."
    fi
  done
}

# ============================
# GNU Stow Installation
# ============================

install_stow() {
  print_message "Checking for GNU Stow..."
  sleep 1
  if ! command -v stow &> /dev/null; then
    echo "GNU Stow not found. Installing GNU Stow..."
    if $is_mac; then
      brew install stow
    elif $is_linux; then
      sudo apt install -y stow
    fi
  else
    echo "GNU Stow is already installed."
  fi
}

# ============================
# Backup Existing Config Files
# ============================

backup_existing_configs() {
  print_message "Backing Up Existing Config Files..."
  sleep 1
  # List of config files to check
  CONFIG_FILES=(
    ".zshrc"
    ".bashrc"
    ".tmux.conf"
    ".zprofile"
    ".bash_profile"
    ".config/kitty/kitty.conf"
  )

  for config in "${CONFIG_FILES[@]}"; do
    target="$HOME/$config"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "Backing up $target to $target.backup"
      mv "$target" "$target.backup"
    fi
  done
}

# ============================
# Stow Dotfiles
# ============================

stow_dotfiles() {
  print_message "Stowing Dotfiles..."
  sleep 1
  cd "$DOTFILES_DIR"

  # Stow common packages
  for pkg in "${COMMON_CONFS[@]}"; do
    echo "Stowing $pkg..."
    stow --ignore='\.DS_Store' "$pkg"
  done

  # Stow OS-specific packages
  if $is_mac; then
    for pkg in "${MACOS_CONFS[@]}"; do
      echo "Stowing $pkg..."
      stow --ignore='\.DS_Store' "$pkg"
    done
  elif $is_linux; then
    for pkg in "${LINUX_CONFS[@]}"; do
      echo "Stowing $pkg..."
      stow "$pkg"
    done
  fi

  echo "Dotfiles have been symlinked successfully."

  cd -
}

# ============================
# Install Homebrew Cask Packages (macOS only)
# ============================

install_brew_cask_packages() {
  if $is_mac; then
    print_message "Installing Homebrew Cask packages..."
    sleep 1
    for package in "${BREW_CASK_PACKAGES[@]}"; do
      if ! brew list --cask | grep -q "^$package\$"; then
        echo "Installing $package..."
        brew install --cask "$package"
      else
        echo "$package is already installed."
      fi
    done
  fi
}

# ============================
# Install Homebrew Packages
# ============================

install_brew_packages() {
  if $is_mac || $is_linux; then
    print_message "Installing Homebrew packages..."
    sleep 1

    # Taps required for certain packages
    # Tap for aerospace
    if ! brew tap | grep -q "nikitabobko/tap"; then
      echo "Tapping nikitabobko/tap..."
      brew tap nikitabobko/tap
    fi

    # Tap for sketchybar
    if ! brew tap | grep -q "FelixKratz/formulae"; then
      echo "Tapping FelixKratz/formulae..."
      brew tap FelixKratz/formulae
    fi

    for package in "${BREW_PACKAGES[@]}"; do
      if ! brew list | grep -q "^$package\$"; then
        echo "Installing $package..."
        brew install "$package"
      else
        echo "$package is already installed."
      fi
    done
  fi
}

# ============================
# Install Fonts
# ============================

install_font_hack() {
  print_message "Installing font-hack-nerd-font..."
  sleep 1
  if $is_mac; then
    if ! brew list --cask | grep -q "^font-hack-nerd-font\$"; then
      brew tap homebrew/cask-fonts
      brew install --cask font-hack-nerd-font
    else
      echo "font-hack-nerd-font is already installed."
    fi
  elif $is_linux; then
    if ! fc-list | grep -i "Hack Nerd Font" &> /dev/null; then
      echo "Installing Hack Nerd Font..."
      mkdir -p ~/.local/share/fonts
      cd ~/.local/share/fonts
      curl -fLo "Hack Regular Nerd Font Complete.ttf" \
        https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete.ttf
      fc-cache -fv
    else
      echo "font-hack-nerd-font is already installed."
    fi
  fi
}

# ============================
# Install Oh My Zsh
# ============================

install_oh_my_zsh() {
  print_message "Setting Up Oh My Zsh..."
  sleep 1
  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "Oh My Zsh not found. Installing Oh My Zsh..."

    # Set ZSH environment variable to install to $HOME/oh-my-zsh
    export ZSH="$OH_MY_ZSH_DIR"

    # Install Oh My Zsh without modifying .zshrc
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "Oh My Zsh is already installed."
  fi
}

# ============================
# Install Zsh Plugins
# ============================

install_zsh_plugins() {
  print_message "Installing Zsh plugins..."
  sleep 1
  ZSH_CUSTOM_PLUGINS="$OH_MY_ZSH_DIR/custom/plugins"

  # Ensure the custom/plugins directory exists
  mkdir -p "$ZSH_CUSTOM_PLUGINS"

  # Define Zsh plugins
  ZSH_PLUGINS=(
    zsh-autosuggestions
    zsh-syntax-highlighting
  )

  # Clone each plugin if not present
  for plugin in "${ZSH_PLUGINS[@]}"; do
    if [ ! -d "${ZSH_CUSTOM_PLUGINS}/$plugin" ]; then
      echo "Cloning $plugin..."
      git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM_PLUGINS}/$plugin"
    else
      echo "$plugin is already installed."
    fi
  done
}

# ============================
# Install Neovim Plugins
# ============================

install_neovim_plugins() {
  print_message "Installing Neovim plugins with lazy.nvim..."
  sleep 1
  if command -v nvim &> /dev/null; then
    # Install lazy.nvim if not already installed
    LAZY_NVIM_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
    if [ ! -d "$LAZY_NVIM_DIR" ]; then
      echo "Installing lazy.nvim plugin manager..."
      git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZY_NVIM_DIR"
    else
      echo "lazy.nvim is already installed."
    fi

    echo "Running Neovim to install plugins via lazy.nvim..."
    nvim --headless "+Lazy! sync" +qa

    echo "Neovim plugins installed successfully using lazy.nvim."
  else
    echo "Neovim is not installed. Skipping Neovim plugin installation."
  fi
}


# ============================
# Install Atuin
# ============================
install_atuin() {
  print_message "Intalling Atuin with Curl command"
  sleep 1
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  echo "Finishe installing Atuin"
}


# ============================
# Install Tmux Plugins
# ============================

install_tmux_plugins() {
  print_message "Installing Tmux plugins..."
  sleep 1
  TPM_DIR="$HOME/.tmux/plugins/tpm"

  if [ ! - "$TPM_DIR" ]; then
    echo "Tmux Plugin Manager (TPM) not found. Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  else
    echo "Tmux Plugin Manager is already installed."
  fi

  # Install Tmux plugins
  if command -v tmux &> /dev/null; then
    echo "Installing Tmux plugins..."

    # Start a new detached tmux session that runs the necessary commands
    tmux new-session -d -s plugin_install_session \
      "tmux source-file ~/.tmux.conf; ~/.tmux/plugins/tpm/scripts/install_plugins.sh; sleep 5"

    # Wait for the session to complete
    sleep 15  # Adjust this if needed

    # Kill the temporary session
    tmux kill-session -t plugin_install_session

    echo "Tmux plugins installed successfully."
  else
    echo "Tmux is not installed. Skipping Tmux plugin installation."
  fi
}

# ============================
# Source .zshrc
# ============================

source_zshrc() {
  print_message "Sourcing .zshrc..."
  sleep 1
  # Source .zshrc if Zsh is the current shell
  if [ -n "$ZSH_VERSION" ]; then
    echo "Sourcing $HOME/.zshrc"
    source "$HOME/.zshrc"
    echo ".zshrc has been sourced."
  else
    echo "Current shell is not Zsh. Please restart your terminal or run 'source ~/.zshrc' manually."
  fi
}

# ============================
# Main Installation Flow
# ============================

main() {

  if $is_mac; then
    install_homebrew
  fi

  install_stow
  backup_existing_configs
  stow_dotfiles

  if $is_mac; then
    install_brew_cask_packages
    install_brew_packages
  elif $is_linux; then
    install_apt_packages
  fi

  install_font_hack
  install_oh_my_zsh
  install_zsh_plugins
  install_neovim_plugins
  install_tmux_plugins
  source_zshrc

  print_message "Installation Completed!"
  echo "Your development environment is set up successfully."
}

main
