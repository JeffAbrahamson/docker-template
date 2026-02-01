#!/bin/bash

set -euo pipefail

export SSH_USER=$LOGNAME

action="$1"
shift || true
case "$action" in
    build)
        # Run build command (typically make)
        # Adapt the -C path and command as needed for the project
        docker compose -f compose.yml up --build dev-compile
        ;;
    test)
        # Run test suite
        # Similar to build but runs tests instead
        docker compose -f compose.yml run --rm --build dev-compile make test
        ;;
    sh)
        # Interactive shell - shares container across multiple shells
        docker compose up -d --build dev-sh
        docker compose exec dev-sh /usr/local/bin/entrypoint.sh /bin/bash

        # When shell exits, check if other shells are still running
        echo "Checking if other shells are running..."
        num_shells=$(docker compose exec dev-sh ps -eo tty,comm | awk '$1 ~ /^pts\// && $2=="bash" {print $1}' | sort -u | wc -l)
        if [ "$num_shells" -ne 0 ]; then
            echo "${num_shells} still running."
        else
            echo "No more shells detected, stopping container..."
            docker compose stop dev-sh
        fi
        ;;
    claude)
        # Claude Code - runs in ephemeral container
        # The entrypoint handles the special invocation needed for claude
        docker compose run --rm --build dev-claude claude
        ;;
    codex)
        # OpenAI Codex - runs in ephemeral container
        docker compose run --rm --build dev-codex codex
        ;;

    *)
        echo "Usage: ./docker-manage.sh build|test|sh|claude|codex"
        echo "** Unrecognised action: \"$action\"."
        ;;
esac
