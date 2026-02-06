# docker-manage.sh Pattern

The docker-manage.sh script is the main entry point for Docker development operations.

## Structure

```bash
#!/bin/bash
set -euo pipefail

export SSH_USER=$LOGNAME

BUILD_NOCACHE=""
while getopts "b" opt; do
    case "$opt" in
	b) BUILD_NOCACHE=1 ;;
	*) ;;
    esac
done
shift $((OPTIND - 1))

action="$1"
shift || true

maybe_build_nocache() {
    local service="$1"
    if [ -n "$BUILD_NOCACHE" ]; then
	echo "Explicit build requested."
	docker compose build --no-cache "$service"
    fi
}

case "$action" in
    target-name)
        maybe_build_nocache dev-service
        # commands for this target
        ;;
    *)
        echo "Usage: ./docker-manage.sh [-b] target1|target2|..."
        echo "  -b  Rebuild container from scratch (no cache)"
        echo "** Unrecognised action: \"$action\"."
        ;;
esac
```

## The -b Flag (No-Cache Rebuild)

Pass `-b` before the action to force a full `docker compose build --no-cache` before running the container. This is useful when packages or base images have changed and cached layers are stale.

```bash
./docker-manage.sh -b sh      # Rebuild from scratch, then start shell
./docker-manage.sh -b claude   # Rebuild from scratch, then start Claude
```

The `maybe_build_nocache` function should be called at the start of each target's case block, passing the service name. It only triggers when `-b` is set.

## Shell Convenience Function (dm)

Users typically invoke docker-manage.sh via a `dm()` bash function that handles the `cd docker/` automatically:

```bash
dm ()
{
    if [ -r docker/docker-manage.sh -a -x docker/docker-manage.sh ]; then
        ( cd docker && ./docker-manage.sh "$@" );
    else
        echo "No docker-manage.sh present.";
    fi
}
```

This lets users run `dm sh`, `dm -b claude`, etc. from any directory in the repo. The function can be placed in the user's shell rc file or sourced from a project-provided `bash/docker-manage-rc.sh`.

## Target Patterns

### Ephemeral Build Targets (build, test)

Run a command and exit:

```bash
build)
    maybe_build_nocache dev-compile
    docker compose -f compose.yml up --build dev-compile
    ;;
```

The container runs the command defined in compose.yml and exits when done.

### Interactive Shell Target (sh)

Maintains a persistent container for multiple shell sessions:

```bash
sh)
    maybe_build_nocache dev-sh
    # Start container in background
    docker compose up -d --build dev-sh
    # Execute shell in running container
    docker compose exec dev-sh /usr/local/bin/entrypoint.sh /bin/bash

    # When this shell exits, check for other shells
    echo "Checking if other shells are running..."
    num_shells=$(docker compose exec dev-sh ps -eo tty,comm | awk '$1 ~ /^pts\// && $2=="bash" {print $1}' | sort -u | wc -l)
    if [ "$num_shells" -ne 0 ]; then
        echo "${num_shells} still running."
    else
        echo "No more shells detected, stopping container..."
        docker compose stop dev-sh
    fi
    ;;
```

Key features:
- Uses `up -d` to keep container running in background
- Uses `exec` to attach to running container
- Counts active shells before stopping container
- Allows multiple developers to share the same container

### AI Tool Targets (claude, codex)

Run in ephemeral containers with credential mounts:

```bash
claude)
    maybe_build_nocache dev-claude
    docker compose run --rm --build dev-claude claude
    ;;
```

Key features:
- Uses `run --rm` for ephemeral container (removed after exit)
- The compose.yml mounts credential directories (~/.claude, ~/.codex)
- entrypoint.sh handles special invocation for these tools

## Adding Custom Targets

To add a new target:

1. Add case entry to docker-manage.sh
2. Add service to compose.yml if needed
3. Add Dockerfile stage if custom image needed

Example custom target for linting:

```bash
lint)
    docker compose run --rm --build dev-compile make lint
    ;;
```

## Error Handling

The script uses `set -euo pipefail`:
- `-e`: Exit on error
- `-u`: Error on undefined variables
- `-o pipefail`: Pipeline fails if any command fails

## SSH Agent Forwarding

`export SSH_USER=$LOGNAME` is used by compose.yml to set up SSH agent forwarding for git operations inside containers.
