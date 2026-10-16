# Dockerfile pattern

Adapt [the example Dockerfile](../examples/Dockerfile). `compile-dev-base`
installs dependencies and the UID/GID entrypoint; `compile-for-dev` provides
a named development target. No agent-specific stages are needed.

## Runtime and caching

Select the image/runtime from the project's version files, locks, and
production requirements. Do not replace a required Python/Ruby/Node version
with the distro default merely to follow this template. For downloaded
runtimes or tools, pin versions and verify checksums where applicable.

Copy package scripts and dependency manifests before changing source. Install
locked dependencies before `COPY . .` so source edits reuse dependency layers.
Use frozen/locked installers and avoid modifying host lockfiles during tests.
For example, Bundler may need `BUNDLE_APP_CONFIG` outside the checkout to
ignore a host-only `.bundle/config`, plus `BUNDLE_FROZEN=true`.

Package scripts should fail on installation errors. When recording output
with `tee`, enable pipefail in the RUN shell:

```dockerfile
RUN bash -o pipefail -c './packages-dev.sh 2>&1 | tee /var/packages-dev.out'
```

## Source ownership and entrypoints

The example's root entrypoint maps the mounted source's UID/GID to a container
user, then executes through gosu with `HOME=/home/dev`. Keep ownership repairs
to the container home and necessary dependency volumes, not the source tree.
`docker compose exec` bypasses ENTRYPOINT: use the entrypoint explicitly or
select the mapped user. Ensure `procps` exists for shared-shell tracking.

An alternative is to build a non-root user with `ARG DEV_UID`, passing the
host UID (including a CI runner's or sudo caller's UID) and using a matching
image tag. That approach avoids root startup but requires rebuilding for a
changed UID and deliberate group handling. Preserve a working project's
existing strategy rather than combining both without a reason.

## Dependencies and browser tests

Bind-mounted source hides dependencies copied into that path. Install them
outside it, use separate dependency volumes, or run tests against an image
without the source mount. Keep test dependency installs separate from a
running development service's shared dependency directory. Download caches
can often be shared; installed dependencies cannot always be shared safely.

Install browser binaries and their libraries during the image build. Match
Playwright's browser version to the locked package version and use a path
readable by the runtime user. If Chrome/driver drift causes failures, pin a
matched pair and verify downloads. Add sandbox capabilities only where the
actual browser runner requires them, not to all services by default.
