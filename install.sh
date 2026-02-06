#!/bin/bash

# This is pretty specific to me, but this is my personal script...
echo "Installing bash functions"
dest_dir="$HOME/.dotfiles/bash/rc_post/"
if [[ -d "$dest_dir" ]]; then
    cp bash/docker-manage-rc.sh "$dest_dir"
else
    echo "Don't know where to install to."
fi
