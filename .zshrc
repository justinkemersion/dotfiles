# ~/.zshrc - Zsh configuration file
# This file is managed via dotfiles repo. Sensitive/private settings should go in ~/.zshrc.local (gitignored).

# --- Oh My Zsh Setup ---

# Path to Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme configuration.
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes for options.
ZSH_THEME="robbyrussell"

# Uncomment to load a random theme each time (from candidates list).
# ZSH_THEME="random"
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Plugins to load (add wisely to avoid slowdowns).
# Standard plugins are in $ZSH/plugins/; custom in $ZSH_CUSTOM/plugins/.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting pass pip)

# Source Oh My Zsh.
source $ZSH/oh-my-zsh.sh

# --- Path and Environment Variables ---

# Extend PATH with user-local bins, Cargo, npm, Android SDK, etc.
# Consolidated to avoid duplicates; order matters (user paths first).
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:$PATH"

# Android SDK setup (adjust paths if SDK location changes).
export ANDROID_HOME="$HOME/Android/Sdk"  # Common default; was /opt/android-sdk in old config.
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

# Java setup (for Android or other tools).
export JAVA_HOME="/usr/lib/jvm/default"  # Use 'default' for flexibility; was java-17-openjdk.

# DBUS for desktop sessions (e.g., if running in a non-standard environment).
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

# --- SSH Key Management ---

# Load keychain for SSH keys if interactive shell and key exists.
# Adjust key name/path as needed; keep actual keys secure.
#if [[ -n "$PS1" && -f ~/.ssh/id_ed25519 ]]; then
#    eval $(keychain --eval --quiet ~/.ssh/id_ed25519)
#fi

# --- Aliases ---

# Dotfiles management with bare Git repo.
# Usage: config status, config add .zshrc, etc.
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'

# Qutebrowser profiles (for separated browsing sessions, e.g., personal/work/AI).
# Default: personal.
alias qute='qutebrowser --basedir ~/.config/qutebrowser-personal'
alias qute-work='qutebrowser --basedir ~/.config/qutebrowser-work'
alias qute-grok='qutebrowser --basedir ~/.config/qutebrowser-grok'
alias qute-gemini='qutebrowser --basedir ~/.config/qutebrowser-gemini'
alias qute-claude='qutebrowser --basedir ~/.config/qutebrowser-claude'

# Add more personal aliases here or in $ZSH_CUSTOM/aliases.zsh.
# Example: alias ll='ls -la'

# --- Functions ---

# Update Pacman mirrors using reflector (for Arch/EndeavorOS).
# Fetches fastest mirrors from specified countries.
# Usage: pacman_update_mirrors
# Customize via env var: export REFLECTOR_COUNTRIES="US,Canada" before running.
# Requires sudo; run 'sudo pacman -Syu' after to sync.
pacman_update_mirrors() {
    # Configuration defaults (override with env vars if needed).
    local countries="${REFLECTOR_COUNTRIES:-US}"  # Comma-separated list.
    local num_latest=20                           # Number of mirrors.
    local protocol="https"                        # Preferred protocol.
    local sort_method="rate"                      # Sort by download speed.
    local output_file="/etc/pacman.d/mirrorlist"  # Requires sudo.

    echo "🚀 Updating Pacman mirrorlist..."
    echo "   Countries: $countries"
    echo "   Protocol: $protocol"
    echo "   Sort: $sort_method"
    echo "   Latest: $num_latest"
    echo "   Output: $output_file"

    # Run reflector with sudo.
    sudo reflector --verbose \
        --country "$countries" \
        --protocol "$protocol" \
        --latest "$num_latest" \
        --sort "$sort_method" \
        --save "$output_file" && \
        echo "✅ Updated! Run 'sudo pacman -Syu' next." || \
        echo "❌ Error updating mirrors."
}

# --- Oh My Zsh Options (Uncomment to Enable) ---

# Auto-update behavior.
zstyle ':omz:update' mode reminder  # Remind to update; alternatives: auto, disabled.
zstyle ':omz:update' frequency 13   # Check every 13 days.

# Case-sensitive completion.
# CASE_SENSITIVE="true"

# Hyphen-insensitive completion (_ and - interchangeable).
# HYPHEN_INSENSITIVE="true"

# Disable magic functions if pasting URLs causes issues.
# DISABLE_MAGIC_FUNCTIONS="true"

# Enable command auto-correction.
# ENABLE_CORRECTION="true"

# Show waiting dots for completion.
# COMPLETION_WAITING_DOTS="true"

# History timestamp format.
# HIST_STAMPS="yyyy-mm-dd"

# Preferred editor.
export EDITOR='lvim'  # Or vim; can override based on SSH.
# if [[ -n $SSH_CONNECTION ]]; then
#     export EDITOR='vim'
# fi

# Language environment (if needed).
# export LANG=en_US.UTF-8

# --- Local/Private Overrides ---

# Source local file for sensitive settings (e.g., API keys). Gitignore this!
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
