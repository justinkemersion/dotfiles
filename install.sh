# ~/dotfiles/install.sh
#!/bin/bash
DOTFILES_DIR=~/dotfiles

# Symlink .zshrc
ln -sf $DOTFILES_DIR/.zshrc ~/.zshrc

# Symlink .local/bin scripts
mkdir -p ~/.local/bin
for script in $DOTFILES_DIR/.local/bin/*; do
    ln -sf "$script" ~/.local/bin/
done

# Add to install.sh
mkdir -p ~/.config
for config in $DOTFILES_DIR/.config/*; do
    ln -sf "$config" ~/.config/
done


echo "Dotfiles installed. Create ~/.zshrc.local for sensitive configs."
