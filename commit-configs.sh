#!/bin/bash
cd ~/dotfiles

# Check for sensitive data
echo "Checking for sensitive data in .config/..."
SENSITIVE=$(grep -r --exclude-dir={library.db,*.bak,*.log} "key\|token\|password" .config/)

if [ -n "$SENSITIVE" ]; then
    echo "WARNING: Potential sensitive data found:"
    echo "$SENSITIVE"
    echo "Please review and move sensitive data to ~/.zshrc.local or update .gitignore."
    echo "Continue with commit? (y/N)"
    read -r RESPONSE
    if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
        echo "Commit aborted."
        exit 1
    fi
fi

# Proceed with commit and push
git add .config .zshrc .local install.sh README.md .gitignore
git commit -m "Update dotfiles $(date)"
git push

echo "Changes committed and pushed successfully."
