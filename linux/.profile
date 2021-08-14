#!/usr/bin/env sh

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Add extra things to the PATH
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.local/sbin" ]; then
    export PATH="$HOME/.local/sbin:$PATH"
fi

if [ -d "$HOME/.config/git-fuzzy" ]; then
    export PATH="$HOME/.config/git-fuzzy/bin:$PATH"
fi

if [ -d "/mnt/c/Program Files/Microsoft VS Code/bin" ]; then
    export PATH="/mnt/c/Program Files/Microsoft VS Code/bin:$PATH"
fi

# Add extra things to the PATH
if [ -d "/usr/local/gnupg/bin" ]; then
    export PATH="/usr/local/gnupg/bin:$PATH"
fi

# set some defaults
export EDITOR="micro"
export PAGER="less -r"

# If running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
