# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Docker-based development environment template. Copy it to new projects and modify as needed.

## Commands

All commands are run from the `docker/` directory:

```bash
cd docker

# Build the project (runs make inside container)
./docker-manage.sh build

# Start an interactive shell in the dev container
./docker-manage.sh sh

# Start Claude Code inside a container with Claude configs mounted
./docker-manage.sh claude
```

Note that `sh` is expected to run each instance in the same container
to permit observing running programs and logs.  The `claude` instance
runs each instance in a separate container.


## Architecture

The template provides three Docker Compose services built on Ubuntu 24.04:

- **dev-compile**: Runs `make` to build the project
- **dev-sh**: Interactive shell for development
- **dev-claude**: Interactive shell with Claude Code installed (mounts `~/.claude` and `~/.claude.json`)

All services mount the project root to `/devsrc` in the container. The entrypoint script (`docker/stuff/entrypoint.sh`) automatically matches container user UID/GID to the host user for proper file permissions.

Package installation is split into:
- `docker/stuff/packages-runtime.sh`: Runtime dependencies (git)
- `docker/stuff/packages-dev.sh`: Development tools (emacs, ripgrep, fd-find, jq, etc.)
