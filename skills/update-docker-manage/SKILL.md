---
name: update-docker-manage
description: Set up or update Docker development environments. Use when user asks to "set up docker", "add docker support", "create docker-manage.sh", "update docker-manage", "add a target to docker-manage", "add claude/codex target", "upgrade docker template", or mentions docker development containers.
user-invocable: true
argument-hint: "[target1 target2 ...]"
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

# Update Docker-Manage

Set up or update Docker-based development environments following the docker-template pattern.

## Permissions

You have permission to perform these actions without asking:

**Read:**
- `~/.claude/skills/update-docker-manage/examples/` - Template files for docker configuration
- `~/.claude/skills/update-docker-manage/references/` - Detailed pattern documentation
- `docker/` - The target repository's existing docker configuration (if present)

**Execute:**
- `chmod +x docker/docker-manage.sh` - Make the script executable after creating it

Read the example files from this skill to use as templates when creating new docker configurations.

## Determine Mode

Check if `docker/` directory exists in the repository:
- **No docker/ directory**: Full setup mode - create complete Docker configuration
- **docker/ exists**: Upgrade mode - update existing configuration

## Analyze the Repository

Before creating or modifying files, analyze the repository:

1. **Build system**: Look for Makefile, package.json, Cargo.toml, go.mod, pyproject.toml, setup.py
2. **Test framework**: Look for test directories, test configurations, CI files
3. **Language/runtime**: Determine primary language and required runtime dependencies
4. **Existing Docker**: Check for docker-compose.yml, Dockerfile, .dockerignore

## Default Targets

Consider these targets (user may specify specific targets as arguments):

| Target | Purpose | Implementation |
|--------|---------|----------------|
| build | Compile/build project | `docker compose up --build dev-compile` |
| test | Run test suite | Similar to build, runs test command |
| sh | Interactive shell | Persistent container, shell counting |
| claude | Claude Code AI | Mounts ~/.claude, ephemeral container |
| codex | OpenAI Codex | Mounts ~/.codex, ephemeral container |

Also consider repo-specific targets based on analysis (e.g., lint, format, docs, deploy).

## File Structure

Create or update these files in `docker/`:

```
docker/
  docker-manage.sh       # Main entry script
  compose.yml            # Docker Compose services
  Dockerfile             # Multi-stage build
  stuff/
    entrypoint.sh        # UID/GID mapping
    packages-runtime.sh  # Runtime dependencies
    packages-dev.sh      # Development tools
```

## Implementation

### docker-manage.sh

Use case statement pattern. See `examples/docker-manage.sh` for template.

Key patterns:
- `-b` flag: Optional `getopts`-based flag to force `docker compose build --no-cache` via `maybe_build_nocache()` helper
- `build`/`test`: Use `docker compose up --build` (ephemeral)
- `sh`: Use `docker compose up -d` then `exec` (persistent, count shells)
- `claude`/`codex`: Use `docker compose run --rm` (ephemeral)
- Each target calls `maybe_build_nocache <service>` before its main command

Users typically invoke via a `dm()` shell function (see `references/docker-manage-pattern.md`) that auto-cds into `docker/`, e.g. `dm sh`, `dm -b claude`.

### compose.yml

Use extends pattern from dev-base service. See `examples/compose.yml` for template.

Key patterns:
- All services extend `dev-base` for shared configuration
- Mount project root to `/devsrc`
- Special services mount credential directories (e.g., ~/.claude)

### Dockerfile

Use multi-stage build. See `examples/Dockerfile` for template.

Key patterns:
- `compile-dev-base`: Base image with common packages
- `compile-for-dev`: Development target
- `compile-for-claude`: Adds Node.js and Claude Code
- `compile-for-codex`: Adds Node.js and OpenAI Codex

### entrypoint.sh

Copy from `examples/entrypoint.sh` - rarely needs modification.

Handles UID/GID mapping between host and container for proper file permissions.

### packages-*.sh

Customize based on repository needs:
- `packages-runtime.sh`: Minimal runtime deps (git, language runtimes)
- `packages-dev.sh`: Development tools (editors, linters, utilities)

## Customization Points

Adapt templates for specific project types:

**Node.js projects**: Add `nodejs npm` to runtime packages, change build command to `npm run build`

**Python projects**: Add `python3 python3-pip` to runtime, change build to `pip install -e .` or similar

**Go projects**: Add `golang` to packages, change build to `go build ./...`

**Rust projects**: Add `rustc cargo` to packages, change build to `cargo build`

**Projects with databases**: Add database service to compose.yml, configure networking

## Upgrade Mode

When docker/ already exists:

1. Compare current docker-manage.sh targets to requested/default targets
2. Identify missing targets to add
3. Check for outdated patterns (old compose syntax, missing features)
4. Propose specific changes to user
5. Preserve existing customizations

## Reference Files

For detailed patterns and templates, see:
- `references/docker-manage-pattern.md` - Detailed script structure
- `references/compose-pattern.md` - Service configuration
- `references/dockerfile-pattern.md` - Multi-stage builds
- `references/target-customization.md` - Language-specific adaptations
- `examples/` - Complete template files
