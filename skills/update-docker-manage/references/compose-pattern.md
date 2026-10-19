# Compose pattern

Adapt [compose.yml](../examples/compose.yml). The base service holds the common
build, working directory, and source mount; command services extend it.

## Project and image identity

Set a top-level repository-specific `name:`. The default name would otherwise
be `docker` in every repository, causing services, networks, and volumes to
collide. Give explicit `image:` tags repository-specific names too. Different
Dockerfile stages need different tags if their contents differ.

Use `--project-name` to isolate worktrees or concurrent test stacks where
needed. Do not hardcode `container_name`, which defeats project isolation.

## Commands and mounts

- `dev-compile`/`dev-test`: one-shot commands, invoked with `run --rm --build`.
- `dev-sh`: `sleep infinity`, kept alive for multiple exec sessions.
- App servers: explicit run service, ports, and only needed dependencies.

The example mounts `..:/devsrc` and sets `working_dir: /devsrc`. Make
`TARGET_DIR` in the entrypoint match a different source path. Mounts hide
image contents at their destination: use a dedicated dependency volume or
install dependencies outside the checkout. An image-only test service can
omit the source mount for tests independent of host state; rebuild after edits.

Use YAML command arrays for clear argument boundaries. Container shell
variables need `$$` to survive Compose interpolation, for example
`command: ["bash", "-c", 'exec make -j "$$(nproc)" -k']`.

Do not advertise an SSH agent socket without mounting it. Add socket mounts
and `SSH_AUTH_SOCK` only for workflows needing SSH. Keep staging tunnels and
private configuration out of test services. No agent credential mounts belong
in this pattern.

A separate optional development SSH-tunnel service may keep SSH tooling out
of the compiler image when a project needs remote connections. Its hosts,
ports, authentication, readiness, and dependency relationships must follow
the project; do not add a generic tunnel stack or make tests depend on it.

## Test databases and dependency readiness

Use a disposable local database, explicit test-only credentials and service
DNS names, without publishing a host port unless needed. Wait with a
healthcheck and `depends_on: condition: service_healthy`. A TCP query as the
app user verifies database/user initialization better than a socket ping.
Use `condition: service_completed_successfully` for required one-shot setup.
Use `--no-deps` for focused commands that do not require the database.

`run --rm` does not remove dependencies. For concurrent suites, create a
unique lowercase Compose project per run, often with a separate
`compose.test.yml`. Reserve names with `mktemp`, not platform-specific inode
commands. Define an EXIT cleanup trap before starting services. Run cleanup
against the same project and files, remove that run's disposable volumes, and
preserve failures. Report cleanup failure even if tests passed. Avoid deleting
shared explicitly tagged images or calling `down` on another run's stack.

For isolated tests use tmpfs or disposable database volumes and consistent
credentials independent of host environment overrides. Reuse common service
definitions via `extends` when useful, but do not inherit host source mounts,
staging tunnels, or secrets into an image-only test service.
