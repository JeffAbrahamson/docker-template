#!/bin/bash

echo; echo "==== packages-dev.sh ===="

export DEBIAN_FRONTEND=noninteractive

apt-get update

# Development tools
# Customize based on project preferences
apt-get install -y                              \
    curl                                        \
    emacs-bin-common                            \
    emacs-nox                                   \
    fd-find                                     \
    iproute2                                    \
    jq                                          \
    lsb-release                                 \
    ripgrep                                     \
    rsync                                       \
    strace                                      \

# Examples of additional dev tools:
# Python development:
#   python3 ipython3 python3-pytest
# Node.js development:
#   nodejs npm
# Code formatting:
#   clang-format prettier
# Documentation:
#   pandoc
