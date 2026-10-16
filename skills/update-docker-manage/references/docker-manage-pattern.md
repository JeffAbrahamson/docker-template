# docker-manage.sh pattern

Start with [the example script](../examples/docker-manage.sh). It resolves
`compose.yml` from `BASH_SOURCE[0]` and wraps `docker compose -f ...` in a
function. Apply the same wrapper to every action, including no-cache builds
and cleanup; callers should not need to `cd docker` first.

Use strict shell options, safe action parsing, usage on invalid input, and
`"$@"` for forwarded arguments. `-b` before the action performs
`build --no-cache <service>`; normal commands use `--build` with cache.

## One-shot commands

Use `run --rm --build` for a build, test, or lint command. A service can define
the default command; supplied arguments after the service replace that
command, so forward selectors explicitly through the runner:

```bash
test)
    maybe_build_nocache dev-test
    if [ "$#" -eq 0 ]; then
        docker_compose run --rm --build dev-test
    else
        docker_compose run --rm --build dev-test pytest "$@"
    fi
    ;;
```

Keep the no-argument path using the service's configured command. Adapt the
explicit runner on the argument path alongside that command when changing
build/test systems. discovery_ingest does this and explicitly constructs its
Ruby runner when test filenames are passed.

A persistent app uses `up`; a job that uses `up` must select its exit status
with `--exit-code-from <service>` and handle dependency shutdown. For editor
output use `run -T` and `pipefail` if piping to `cat`/`tee`. Preserve the real
command failure, and make build paths resolvable by the editor.

## Shared shells

The example starts `dev-sh` with `up -d --build` and attaches with `exec`.
Invoke the UID/GID entrypoint explicitly because exec bypasses the image's
entrypoint. Capture a failed shell status so strict mode does not skip cleanup.
After exit, count distinct terminals running interactive bash with
`exec -T ... ps -eo tty,comm`; install `procps` in images that use this check.
Stop only the shell service when none remain, and return the shell status.
If the terminal check fails, leave the service running rather than stopping
other sessions. Report cleanup failures; return a cleanup failure when the
shell succeeded, and retain the original shell failure otherwise.

This is a convenience check, not a lock against concurrent shell creation.
Do not call project-wide `down` after every shared shell or command. Provide
`down` as an explicit action; do not delete named data volumes by default.

## Shell shorthand

The repository's `bash/docker-manage-rc.sh` defines `dm` and action completion.
It looks for `docker/docker-manage.sh` relative to the current directory, so
invoke `dm` from the repository root. Preserve argument boundaries:

```bash
dm() {
    local file="docker/docker-manage.sh"
    if [ ! -e "$file" ]; then
        echo "$file does not exist." >&2
        return 1
    elif [ ! -r "$file" ]; then
        echo "$file is not readable." >&2
        return 1
    elif [ ! -x "$file" ]; then
        echo "$file is not executable." >&2
        return 1
    fi
    (cd docker && ./docker-manage.sh "$@")
}
```

## Failure handling

Strict mode does not replace deliberate status handling. Capture status before
cleanup; enable `pipefail` for logging pipelines. If a full gate runs multiple
suites after failures, accumulate failures and return nonzero with an aggregate
verdict. Bounded retries are appropriate only for demonstrated infrastructure
failures, never arbitrary test failures.
