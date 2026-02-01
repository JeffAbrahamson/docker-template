# Dockerfile Pattern

The Dockerfile uses multi-stage builds for different development scenarios.

## Base Stage

```dockerfile
FROM ubuntu:24.04 AS compile-dev-base

RUN mkdir -p /usr/local/

WORKDIR /devsrc

# Install runtime packages
COPY --chmod=755 docker/stuff/packages-runtime.sh ./
RUN ./packages-runtime.sh 2>&1 | tee /var/packages-runtime.out

# Install development packages
COPY --chmod=755 docker/stuff/packages-dev.sh ./
RUN ./packages-dev.sh 2>&1 | tee /var/packages-dev.out

# Create dev user for non-root operations
RUN useradd -ms /bin/bash dev

# Install gosu for privilege management
RUN apt-get update && apt-get install -y --no-install-recommends \
      gosu \
    && rm -rf /var/lib/apt/lists/*

# Add entrypoint script
COPY --chmod=755 docker/stuff/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
```

Key features:
- Ubuntu 24.04 base for stability
- Package scripts for cache efficiency
- Non-root user for security
- gosu for privilege dropping
- Custom entrypoint for UID/GID mapping

## Development Stage

```dockerfile
FROM compile-dev-base AS compile-for-dev
# No changes - just provides a named target
```

Simple extension for general development.

## AI Tool Stages

### Claude Code

```dockerfile
FROM compile-dev-base AS compile-for-claude

RUN apt-get update && apt-get install -y nodejs npm

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code
```

### OpenAI Codex

```dockerfile
FROM compile-dev-base AS compile-for-codex

RUN apt-get update && apt-get install -y nodejs npm

# Install OpenAI Codex CLI
RUN npm install -g @openai/codex
```

## Package Scripts

### packages-runtime.sh

Minimal runtime dependencies:
```bash
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git
```

Add language runtimes as needed (python3, nodejs, golang, etc.).

### packages-dev.sh

Development tools:
```bash
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    curl \
    emacs-nox \
    fd-find \
    jq \
    ripgrep
```

Add project-specific dev tools.

## Cache Optimization

The COPY + RUN pattern for package scripts optimizes caching:
- Scripts only copied when changed
- apt-get only runs when scripts change
- Layer reuse across builds

## Adding Custom Stages

For specialized tools, add new stages:

```dockerfile
FROM compile-dev-base AS compile-for-mytools

# Install custom tools
RUN apt-get update && apt-get install -y mytool

# Or from npm/pip/cargo
RUN pip install mytool
```

Then reference in compose.yml:
```yaml
dev-mytools:
  extends: dev-base
  build:
    target: compile-for-mytools
```

## entrypoint.sh Function

The entrypoint script:
1. Reads UID/GID of /devsrc (host files)
2. Creates matching group if needed
3. Modifies or identifies user with that UID
4. Runs command as that user with gosu

This ensures files created in container have correct ownership on host.
