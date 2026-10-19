# Docker development practices

These practices come from reviewing all eight `/home/jeff/src/jellybooks/*/docker/`
directories: analytics, candy-wrapper, danube, discovery_ingest, jellybooks-ng,
production, streamer-js-web, and webpub-viewer. They capture useful lessons
from those implementations; older scripts still contain patterns that should
not be copied into new setups.

## Keep Docker focused on the project

Run agents on the host. Let them call `docker-manage.sh` for builds, lint,
tests, and shells. Agent CLI targets, agent-specific Dockerfile stages,
credential mounts, and entrypoint workarounds for launching agents are obsolete.

Expose the repository's actual workflows. Always provide a `test` action
mapped to the project's verification gate. This may mean `./test.sh`, Ruby
unit tests, browser suites, or a combined lint/format/test gate; a lint-only
project can use its checks as the gate. A project without a compilation step
need not have `build`. Add useful focused commands such as `lint`, `jstest`,
`webpack`, or an opt-in database integration suite.
Keep CI and local commands on the same service and dependency setup. CI must
invoke the verification runner, not merely install its environment.

A successful command must actually run the checks. In compiled projects,
separate execution from compilation: tests embedded only in link recipes can
silently disappear when binaries are up to date. Re-run the test action on an
unchanged checkout, then change a supported selector or filter without editing
source. Confirm both runs execute the intended tests and preserve failures,
including failures early in a loop or before a later successful suite.

## Make invocation predictable

Resolve the Compose file from the script's own directory, as candy-wrapper
and production do, or change to that directory before issuing commands.
Support both `./docker/docker-manage.sh test` from the root and
`./docker-manage.sh test` from `docker/`. The `dm` shell helper is a
convenience, not a prerequisite; it currently expects the repository root.

Use `set -euo pipefail`, a safe missing action (`${1:-}`), and a nonzero
status for invalid actions/options. Forward runner arguments with `"$@"`.
Decide whether these are test selectors or replacement commands; document
that contract. Do not build command strings from unquoted arguments.

Normal commands should build with cache. Reserve `-b` for an explicit
`docker compose build --no-cache <service>` before running the action.
A no-cache rebuild does not clear dependency volumes or test databases.

## Give every repository its own Compose identity

Always set a repository-specific top-level `name:`. Otherwise projects whose
Compose files live in `docker/` share the default project name `docker`,
causing service, network, and volume collisions. This was addressed explicitly
in streamer-js-web and webpub-viewer.

Use project-specific image tags too; Compose project names do not namespace
an explicit `image:` tag. Distinct Dockerfile stages should not overwrite the
same tag with different content. When using multiple worktrees, choose a
project-name override if they need independent development stacks.

## Use disposable containers for commands

Prefer `docker compose run --rm --build <service> ...` for builds, lint, and
tests. It returns the command's status and removes the command container.
Reserve `up` for persistent applications, dependency services, and shells.
When a job really uses `up`, explicitly select its exit status with
`--exit-code-from <job-service>` and arrange dependency shutdown.

Logs must not turn failures into success. Use `pipefail` for `tee` or `cat`
pipelines, including Dockerfile package-install pipelines. If several suites
should run despite failures, aggregate their statuses and print one final
verdict. webpub-viewer's test service does this so a final passing suite
cannot obscure an earlier failed lint or test run.

Editor-oriented targets such as analytics' `build-emacs` can disable TTY
formatting (`run -T`) and pipe output for parsing. Preserve failures and make
container paths usable from the editor; local path symlinks are not a generic
template requirement.

## Keep interactive shells shared

Use `up -d --build` followed by `exec` for `sh`, so terminals can inspect the
same processes, logs, and filesystem. An exec does not run the image's
entrypoint automatically; invoke it explicitly when UID/GID setup is needed.

After the shell exits, check for other interactive bash terminals before
stopping the shell service. Counting `ps` terminals avoids counting a
background `sleep` or unrelated noninteractive shell. Run cleanup even after
a shell exits nonzero, and retain its exit status. This check is a convenience,
not synchronization: a shell opening during cleanup can race the stop.
Use `down` for explicit development-stack shutdown, not after each shell or
one-shot command that shares the stack with other work.

## Limit the build context

Add or review a project-specific `.dockerignore` at the actual build-context
root, as selected by Compose's `build.context`. With this template's
`context: ..`, place it at the repository root, not inside `docker/`. Review
each context separately when a project has several builds.

Exclude files the image does not need, such as applicable host dependencies,
generated output, private local configuration, and build artefacts. This
limits context transfer and accidental `COPY` contents, and reduces needless
cache invalidation and build-cache growth when those files would be copied.
There is no universal exclusion list: retain source and dependency inputs,
and retain Git metadata if version generation requires it. A toolchain-only
image and an image that builds or tests copied source need different rules.
Check Dockerfile `COPY`/`ADD` inputs and version-generation steps against the
exclusions before building; review context size and cache reuse afterwards.

## Match runtimes and dependency locks

Choose runtime versions from project files and production requirements.
candy-wrapper uses Python 3.9 for its locked dependencies; discovery_ingest
builds Ruby from `.ruby-version`. A generic Ubuntu upgrade is not a reason
to change a consuming project's runtime.

Copy manifests and lockfiles before application source so dependency layers
remain cached across source edits. Use lock-preserving installers (`npm ci`,
`yarn --frozen-lockfile`, frozen Bundler configuration, or the project's Python
lock workflow). Ignore host-only dependency settings when needed, such as
`.bundle/config` pointing at a host path. Keep dependencies outside a source
bind mount, or give their directories dedicated volumes: mounting the host
checkout hides files installed at the same path during image construction.

Projects with native libraries beyond distro packages may need a separate
installation layer, before changing application source. Adapt its layout to
the project, pin fetched dependencies to known versions or commits, and make
nested installer scripts fail on errors; an outer `pipefail` cannot detect a
child script that hides its own failure. Install required libraries outside
the source bind mount, or use an appropriate dependency volume. The exact
installer and directory layout are project-specific.

For fast development, a named dependency volume can be refreshed when the
lockfile or runtime changes. streamer-js-web stamps and locks its shared
`node_modules` installation. Tests use a separate anonymous dependency volume
and fresh `npm ci`, while sharing only the download cache. Do not let a test
install replace dependencies under a running development server.

An image-only test service is another useful option: jellybooks-ng's isolated
test Compose file runs against the copied source and dependencies without a
host bind mount. Rebuild it to include source changes.

## Respect ownership

Do not assume the host user is UID 1000; CI may use 1001. Either map UID/GID
at startup from the mounted checkout, as this template does, or use a build
argument and a matching non-root `USER`, as streamer-js-web does. Account for
existing numeric users/groups and align `HOME` after dropping privileges.

Keep ownership repairs limited to writable container homes and dependency
volumes. Avoid recursively changing the source checkout or mounted host
credentials. Verify files written by commands and interactive shells remain
writable by the host user. With a shared shell, remember `exec` must also
select the mapped user, directly or through the entrypoint.

## Isolate test infrastructure and clean it up

Use a disposable local database for database tests, with service DNS names,
explicit test credentials, and `tmpfs` or disposable volumes for test data.
Keep staging SSH tunnels and real database secrets in development services;
tests should not need them. When development needs a remote connection,
a separate optional SSH-tunnel service can keep SSH tooling out of the
compiler image. Hosts, ports, authentication, readiness, and service
relationships are project-specific; this is a possibility, not a required
service in every project. `--no-deps` is useful for focused jobs that do
not require a database, such as jellybooks-ng's webpack and Jest commands.

Wait for readiness with healthchecks and `depends_on: condition:
service_healthy`. Prefer a TCP query as the application's user against its
database: an early socket ping can succeed before initialization finishes,
as streamer-js-web documents. Use `service_completed_successfully` for a
required one-shot dependency installer.

`run --rm` removes the job container, not its dependency containers. For
concurrent database suites, use a unique, valid lowercase project name per
run, and trap cleanup of that project's containers and volumes while
preserving the test status. jellybooks-ng uses `mktemp` to reserve names and
a dedicated `compose.test.yml`. Keep shared explicit image tags out of a
cleanup that removes images. Report cleanup failures; do not silently leak
per-run stacks or stop another run's database with a shared `down`.

Retries belong only around identified transient infrastructure failures,
with a bounded attempt count and the final status retained. Do not copy
jellybooks-ng's application-specific MySQL log patterns into unrelated
projects or retry arbitrary failed tests.

## Prepare browser dependencies in the image

Install browser binaries and system libraries during the image build rather
than downloading them for every test. Match Playwright binaries to the
project's locked Playwright version and use a location readable by the mapped
user, as webpub-viewer does. Where browser/driver drift has caused failures,
pin matching versions and verify downloaded checksums, as jellybooks-ng does.
Add browser sandbox capabilities only to services that demonstrably need them;
they are not part of the generic template.

## Upgrade from the repository's behavior

Inventory existing targets, CI jobs, ports, mounts, dependencies, and runtime
versions before changing a setup. Preserve working project customizations.
Adopt these practices where relevant rather than copying a whole different
project's stack, hardcoded secrets, legacy agent targets, or transient fixes.

Validate shell syntax and rendered Compose configuration first. Then exercise
the affected workflow, including failure status, quoted arguments, ownership,
and cleanup where those changed. For this template, use mocked Docker calls
to check dispatch; run real build/tests in the consuming project with its
actual source and toolchain. Verify that tests execute on successive unchanged
runs and after a selector change, and that CI invokes the same verification
gate. Syntax checks and environment installation do not establish this.
