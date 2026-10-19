# Docker Template

Copy `docker/` into a project and adapt its build and test commands. Docker
provides the project's toolchain, tests, and shared development shell.
Agents run on the host and invoke the same commands as humans and CI.

```bash
./docker/docker-manage.sh build
./docker/docker-manage.sh test
./docker/docker-manage.sh sh
./docker/docker-manage.sh -b test
./docker/docker-manage.sh down
```

The script works from any current directory. `-b` before the action forces
an image rebuild without Docker cache; normal runs use `--build` with cache.
Without arguments, build and test use their Compose service's `command:`.
With arguments, the sample wrappers invoke Make explicitly, for example
`build src/my_test` or `test TESTOPTS=-v`. Adapt those runners alongside the
Compose commands when changing the project's build or test system.

For the `dm` shorthand and action completion, source
[bash/docker-manage-rc.sh](bash/docker-manage-rc.sh). The function expects
invocation from the repository root and preserves quoted arguments.

Before copying, read [BEST-PRACTICES.md](BEST-PRACTICES.md). Change the Compose
project name and image tag, select a base image compatible with the project's
runtime, and replace the sample Make commands. Always expose a `test` action
that executes the project's verification gate, even if that gate is lint-only.
The template itself has no Makefile. Run its Docker-free launcher regression
checks with `bash tests/docker-manage-test.sh` on the host.

Add or review a project-specific `.dockerignore` at each build-context root;
with the sample Compose file's `context: ..`, that is the repository root,
not `docker/`. Exclude unnecessary context and generated output to avoid
needless transfers, copied files, and build-cache growth. Contents depend on
the project: keep source, lockfiles, and Git metadata when the build needs them.
See [build-context guidance](BEST-PRACTICES.md#limit-the-build-context).

The [update-docker-manage skill](skills/update-docker-manage/SKILL.md) includes
adaptable examples and detailed references. `./install-skills.sh` copies it
to `~/.claude/skills/`; `./install.sh` installs the shell helper into the
author's dotfiles layout.
