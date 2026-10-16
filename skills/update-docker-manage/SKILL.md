---
name: update-docker-manage
description: Set up or update a project's Docker development environment, docker-manage.sh targets, Compose services, and development images. Use for adding Docker support or adapting an existing docker-manage workflow.
user-invocable: true
argument-hint: "[target1 target2 ...]"
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

# Update Docker-Manage

Create or adapt Docker workflows for project commands and a shared shell.
Agents invoke these commands from the host. Do not add agent CLI targets,
agent images, credential mounts, or special agent launching logic.

## Inspect before adapting

Read the repository's instructions, build/test scripts, CI configuration,
runtime version files, dependency locks, and existing `docker/` files.
Determine what `build`, `test`, and any focused commands actually mean here.
Some repositories need only tests/lint and a shell. Preserve custom targets,
ports, dependencies, and runtime choices unless the task changes them.

For a new setup, adapt the files in [examples/](examples/) relative to this
skill. For an upgrade, apply the relevant improvements to the existing files;
do not replace them wholesale. Make scripts executable when needed.

## Workflow conventions

- Resolve Compose relative to the script, independent of the caller's cwd.
- Give Compose a repository-specific `name:` and explicit images unique tags.
- Use `run --rm --build` for commands so their status reaches the caller.
  `-b` before the action triggers a no-cache image build first.
- Keep `sh` persistent with `up -d` and `exec`; stop it after the last
  interactive shell exits, including after nonzero shell exits.
- Provide `down` for explicit development-stack shutdown.
- Preserve quoted runner arguments with `"$@"`. Missing/unknown actions and
  invalid options should print usage and return nonzero.
- Keep local and CI test entry points aligned. A test target may include lint,
  formatting checks, and multiple suites; its final status must cover all of them.
- Match the host UID/GID for writable bind mounts, then run commands as that
  user with a usable `HOME`. An `exec` needs the same user handling.

The examples use Make; replace commands with the project's actual workflow.
Choose the base image from runtime requirements rather than copying a generic
Ubuntu version. Keep the project's lockfiles authoritative and dependency
layers cached separately from changing source.

## Conditional guidance

Read the relevant reference when implementing these parts:

- [docker-manage-pattern.md](references/docker-manage-pattern.md): script
  dispatch, argument forwarding, command status, and shell lifetime.
- [compose-pattern.md](references/compose-pattern.md): service identity,
  mounts, dependency readiness, and isolated database tests.
- [dockerfile-pattern.md](references/dockerfile-pattern.md): runtime choices,
  cached dependencies, ownership, and browser tools.
- [target-customization.md](references/target-customization.md): adapting
  language-specific runners, focused targets, and CI behavior.

In the source docker-template repository, [BEST-PRACTICES.md](../../BEST-PRACTICES.md)
provides the full rationale and examples from eight Jellybooks projects. The
references here remain usable when this skill is installed on its own.

## Verification

Run `bash -n` on changed shell files and `docker compose -f <file> config
--quiet` on changed Compose files. Check dispatch and failure propagation
when the wrapper changes. Run the affected project's real command when its
toolchain and dependencies are available. For database changes, verify
readiness, isolation, and cleanup without affecting a running development
stack. Do not treat a syntax/configuration check as a passing test suite.
