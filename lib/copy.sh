#!/bin/sh

# change to your base path
BASE="$(dirname "$0")/.."
echo $BASE

cp $NVIM_CONFIG "${BASE}/init.lua"
cp $ZSH_CONFIG "${BASE}/.zshrc"
cp $ALACRITTY_CONFIG "${BASE}/.alacritty.yml"
cp $TMUX_CONFIG "${BASE}/.tmux.conf"
