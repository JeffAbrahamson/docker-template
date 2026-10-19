#!/bin/bash
set -euo pipefail

# Run on the host: Docker is mocked, so no images or containers are needed.
repository_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
launcher="$repository_dir/docker/docker-manage.sh"
compose_file="$repository_dir/docker/compose.yml"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT
export DOCKER_TEST_LOG="$temporary_dir/calls"
export PATH="$temporary_dir:$PATH"

cat > "$temporary_dir/docker" <<'MOCK'
#!/bin/bash
set -euo pipefail
printf '%q ' "$@" >> "$DOCKER_TEST_LOG"
printf '\n' >> "$DOCKER_TEST_LOG"
[ "$1" = compose ] && [ "$2" = -f ] || exit 99
shift 3
case "$1" in
    build) exit "${BUILD_STATUS:-0}" ;;
    run) exit "${RUN_STATUS:-0}" ;;
    up) exit "${UP_STATUS:-0}" ;;
    exec)
        if [ "${2:-}" = -T ]; then
            printf '%s' "${OTHER_SHELLS:-}"
            exit "${PS_STATUS:-0}"
        fi
        exit "${SHELL_STATUS:-0}"
        ;;
    stop) exit "${STOP_STATUS:-0}" ;;
    down) exit "${DOWN_STATUS:-0}" ;;
esac
MOCK
chmod +x "$temporary_dir/docker"

fail() { echo "FAIL: $*" >&2; exit 1; }
run_launcher() {
    : > "$DOCKER_TEST_LOG"
    status=0
    (cd "$temporary_dir" && "$launcher" "$@") > "$temporary_dir/output" 2>&1 || status=$?
    mapfile -t calls < "$DOCKER_TEST_LOG"
}
expect_status() { [ "$status" -eq "$1" ] || fail "Expected status $1, got $status"; }
expect_count() { [ "${#calls[@]}" -eq "$1" ] || fail "Expected $1 Docker calls, got ${#calls[@]}"; }
expect_call() {
    local index="$1" expected
    shift
    printf -v expected '%q ' compose -f "$compose_file" "$@"
    [ "${calls[index]}" = "$expected" ] || fail "Unexpected Docker call: ${calls[index]} (expected $expected)"
}

# Resolve Compose independently of cwd and preserve selector boundaries.
run_launcher test
expect_status 0
expect_count 1
expect_call 0 run --rm --build dev-test
run_launcher test 'TESTOPTS=title with spaces' 'quote"and$literal'
expect_status 0
expect_call 0 run --rm --build dev-test make test 'TESTOPTS=title with spaces' 'quote"and$literal'
run_launcher build
expect_status 0
expect_call 0 run --rm --build dev-compile
run_launcher build 'target with spaces'
expect_status 0
expect_call 0 run --rm --build dev-compile /bin/bash -c 'exec make -j "$(nproc)" -k "$@"' -- 'target with spaces'

for action in build test sh; do
    case "$action" in build) service=dev-compile ;; *) service="dev-$action" ;; esac
    run_launcher -b "$action"
    expect_status 0
    expect_call 0 build --no-cache "$service"
    # Retain --build so adapted projects can build dependency services too.
    if [ "$action" = sh ]; then
        expect_call 1 up -d --build "$service"
    else
        expect_call 1 run --rm --build "$service"
    fi
    BUILD_STATUS=42 run_launcher -b "$action"
    expect_status 42
    expect_count 1
    expect_call 0 build --no-cache "$service"
done
RUN_STATUS=43 run_launcher test
expect_status 43
UP_STATUS=44 run_launcher sh
expect_status 44
expect_count 1

# Cleanup runs after failed shells and never hides their original status.
SHELL_STATUS=45 run_launcher sh 'argument with spaces'
expect_status 45
expect_count 4
expect_call 0 up -d --build dev-sh
expect_call 1 exec dev-sh /usr/local/bin/entrypoint.sh /bin/bash 'argument with spaces'
expect_call 2 exec -T dev-sh ps -eo tty,comm
expect_call 3 stop dev-sh
STOP_STATUS=46 run_launcher sh
expect_status 46
SHELL_STATUS=45 STOP_STATUS=46 run_launcher sh
expect_status 45
PS_STATUS=47 run_launcher sh
expect_status 47
expect_count 3
OTHER_SHELLS=$'pts/1 bash\npts/1 bash\n? sleep\n' run_launcher sh
expect_status 0
expect_count 3

run_launcher down
expect_status 0
expect_count 1
expect_call 0 down
DOWN_STATUS=48 run_launcher down
expect_status 48
for invalid in '' unknown -x; do
    run_launcher "$invalid"
    expect_status 1
    expect_count 0
done

cmp "$launcher" "$repository_dir/skills/update-docker-manage/examples/docker-manage.sh" || fail 'Launcher example differs'
echo 'Docker launcher regression checks passed.'
