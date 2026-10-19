# Target customization

Use the repository's existing runner and CI contract. Do not add build targets
for projects with nothing to compile, or assume `test` means unit tests alone.
Always expose a `test` action that runs the project's actual verification
gate. Production uses a `test.sh` lint gate; webpub-viewer combines lint,
format, root tests, and workspace tests. A final success must cover the whole
gate. CI must invoke the runner, not stop after installing its environment.

## Test execution is separate from building

For compiled projects, keep running tests separate from building binaries.
Tests run only from compilation or link recipes can be skipped when binaries
are current, and changing a filter alone may not retrigger those recipes.
Use an explicit test-running target or runner that executes on every request;
keep compilation as a prerequisite where needed. Preserve project-specific
wrappers, environment, filters, and multi-configuration coverage.

Verify two successive test invocations on an unchanged checkout both run the
suite. Then change a supported selector or filter without source edits and
confirm the intended checks execute. Verify that a failure early in a loop or
suite sequence cannot be hidden by a later success, and that CI reaches this
same gate. Successful environment installation or image construction is not
evidence that tests ran.

## Runtime-specific choices

| Project | Dependency setup | Typical commands |
| --- | --- | --- |
| Node.js | Runtime from project requirements; `npm ci` or frozen Yarn lock | `npm run build`, `npm test`, focused Jest/webpack targets |
| Ruby | `.ruby-version`, locked gems, frozen Bundler | `bundle exec ruby ...`, `bundle exec rails test`, RuboCop |
| Python | Compatible pinned runtime and locked requirements; venv outside source mount | `./test.sh`, `pytest`, project lint commands |
| C/C++ | Compiler, Make/CMake and required libraries | `make -j ... -k`, `make test`, focused test binaries |
| Go | Project's Go version and modules | `go build ./...`, `go test ./...` |
| Rust | Project toolchain and lockfile | `cargo build`, `cargo test` |

Forward selectors using the actual runner. For example:

```bash
jstest)
    maybe_build_nocache dev-sh
    docker_compose run --no-deps --rm --build dev-sh yarn test:coverage "$@"
    ;;
```

Do not append selectors after a service and expect its default command to
remain: Compose treats supplied arguments as the replacement command.

## Development versus test dependencies

A named dependency volume makes development fast if refreshed when the lock
or runtime changes. If concurrent services can install into it, serialize
installers (for example, a lock on the volume directory). Do not assume that
this protects applications already reading the directory during replacement.

Tests can use anonymous installed-dependency volumes and a fresh locked install,
sharing only a package download cache. Alternatively, bake locked dependencies
and source into a test image without host mounts. Keep local and CI behavior
aligned; a warm host checkout must not be necessary for tests to pass.

## Application and database targets

Expose `run`/`dev` with needed ports and dependency readiness; Compose `run`
does not publish service ports unless requested with `--service-ports` or `-p`.
Use `up` for the normal multi-service app lifecycle. Keep test databases local
and disposable. Put optional integration suites behind an explicit target if
they are costly or unnecessary for most edits. See
[compose-pattern.md](compose-pattern.md) for concurrent stacks and cleanup.

## Focused verification

Separate independent expensive work when useful: a webpack build or JS suite
need not start MySQL just because Rails tests do. Use `--no-deps` only when
the job genuinely has no dependency requirement. Add format/docs/lint targets
when the project has corresponding commands; avoid speculative targets or
commands that silently do something different from CI.
