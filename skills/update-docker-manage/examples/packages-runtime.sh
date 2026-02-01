#!/bin/bash

echo; echo "==== packages-runtime.sh ===="

export DEBIAN_FRONTEND=noninteractive

apt-get update

# Minimal runtime dependencies
# Customize for your project's needs
apt-get install -y                              \
    git                                         \

# Examples of additional runtime packages:
# Node.js projects:
#   nodejs npm
# Python projects:
#   python3 python3-pip python3-venv
# Go projects:
#   golang
# Rust projects:
#   rustc cargo
# Java projects:
#   openjdk-17-jdk maven
