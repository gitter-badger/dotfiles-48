
# add extra things to the PATH
if [ -d "$HOME/.local/bin" ]; then
   PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.local/sbin" ]; then
   PATH="$HOME/.local/sbin:$PATH"
fi

# set some defaults
export EDITOR="vim"
export PAGER="less -r"


# added by Anaconda 2.3.0 installer
export PATH="/Users/jvaneenwyk/anaconda/bin:$PATH"
