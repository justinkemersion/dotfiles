
## Installation On a fresh system: 

1. **Clone the repository**: ```bash git clone <repository-url> ~/dotfiles```

2.  **Run the install script**:
    
    `cd ~/dotfiles ./install.sh`
    
    This symlinks:
    -   ~/.zshrc to ~/dotfiles/.zshrc
    -   ~/.local/bin/* to ~/dotfiles/.local/bin/*
    -   ~/.config/<app> to ~/dotfiles/.config/<app> for all versioned configs
3.  **Create ~/.zshrc.local for sensitive data** (e.g., API keys):
    
    `echo  'export API_KEY="your-api-key"' > ~/.zshrc.local chmod 600 ~/.zshrc.local`
    
4.  **Test the setup**:

    `source ~/.zshrc ls -l ~/.config/ # Verify symlinks`
    

## Versioned Configs

-   **Shell**: .zshrc
-   **Scripts**: .local/bin/
-   **Configs in .config/**:
    -   alacritty/ (terminal emulator)
    -   beets/ (music library manager)
    -   mpv/ (media player)
    -   ncmpcpp/ (MPD client)
    -   ranger/ (file manager)
    -   sway/ (Wayland compositor)
    -   waybar/ (status bar)

## Managing Updates

-   **Edit configs** in ~/.config/ or ~/.zshrc; changes reflect in ~/dotfiles/ via symlinks.
-   **Commit changes** using commit-configs.sh, which checks for sensitive data:

    `./commit-configs.sh`
    
    If key, token, or password is found in .config/, you’ll be warned to move sensitive data to ~/.zshrc.local or update .gitignore.
-   **Push to GitHub**:

    `git push`
    

## Sensitive Data

-   Store API keys, tokens, etc., in ~/.zshrc.local, which is excluded via .gitignore.
-   commit-configs.sh scans .config/ for sensitive terms before committing.
-   Check for sensitive data manually:

    `grep -r "key\|token\|password" .config/`
    
