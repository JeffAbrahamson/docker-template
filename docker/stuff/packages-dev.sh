#!/bin/bash

echo; echo "==== packages-dev.sh ===="

export DEBIAN_FRONTEND=noninteractive

# Note that emacs-bin-common is only for etags.
apt-get update
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

#   python3                                     \
#   ipython3                                    \
