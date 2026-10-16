#!/bin/bash
set -euo pipefail

# Resolve Compose relative to this script, regardless of the caller's cwd.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
docker_compose() {
    docker compose -f "$script_dir/compose.yml" "$@"
}

BUILD_NOCACHE=""
usage() {
    echo "Usage: $0 [-b] build|test|sh|down [arguments...]"
    echo "  -b  Rebuild the selected service without Docker cache"
}
while getopts ":b" opt; do
    case "$opt" in
        b) BUILD_NOCACHE=1 ;;
        *) usage >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
action="${1:-}"
if [ "$#" -gt 0 ]; then shift; fi

maybe_build_nocache() {
    if [ -n "$BUILD_NOCACHE" ]; then
        docker_compose build --no-cache "$1"
    fi
}

case "$action" in
    build)
        maybe_build_nocache dev-compile
        if [ "$#" -eq 0 ]; then
            docker_compose run --rm --build dev-compile
        else
            # Adapt this runner when changing the project's build system.
            docker_compose run --rm --build dev-compile /bin/bash -c \
                'exec make -j "$(nproc)" -k "$@"' -- "$@"
        fi
        ;;
    test)
        maybe_build_nocache dev-test
        if [ "$#" -eq 0 ]; then
            docker_compose run --rm --build dev-test
        else
            # Adapt this runner when changing the project's test system.
            docker_compose run --rm --build dev-test make test "$@"
        fi
        ;;
    sh)
        maybe_build_nocache dev-sh
        docker_compose up -d --build dev-sh
        shell_status=0
        docker_compose exec dev-sh /usr/local/bin/entrypoint.sh /bin/bash "$@" || shell_status=$?

        # Count interactive bash terminals, excluding the sleep process.
        # Cleanup must also run when the shell returns a nonzero status.
        cleanup_status=0
        num_shells=$(docker_compose exec -T dev-sh ps -eo tty,comm |
            awk '$1 ~ /^pts\// && $2=="bash" {print $1}' | sort -u | wc -l) || cleanup_status=$?
        if [ "$cleanup_status" -ne 0 ]; then
            echo "Could not check remaining shells; leaving dev-sh running." >&2
        elif [ "$num_shells" -ne 0 ]; then
            echo "${num_shells} shells still running."
        else
            docker_compose stop dev-sh || cleanup_status=$?
            if [ "$cleanup_status" -ne 0 ]; then
                echo "Could not stop dev-sh." >&2
            fi
        fi
        if [ "$shell_status" -eq 0 ]; then shell_status=$cleanup_status; fi
        exit "$shell_status"
        ;;
    down)
        docker_compose down
        ;;
    *)
        usage >&2
        if [ -n "$action" ]; then
            echo "Unrecognised action: $action" >&2
        fi
        exit 1
        ;;
esac
