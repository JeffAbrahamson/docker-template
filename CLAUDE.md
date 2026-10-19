# Repository guidance

This repository supplies a Docker development template and the
`skills/update-docker-manage/` skill. Read [BEST-PRACTICES.md](BEST-PRACTICES.md)
before adapting either. Agents invoke Docker commands from the host.
Do not reintroduce agent CLI targets, credential mounts, or image stages.

## Working files

- `docker/`: files copied into new projects.
- `skills/update-docker-manage/examples/`: flat copies of the templates in
  `docker/` and `docker/stuff/`. Keep corresponding files identical here;
  consuming projects choose their own runtimes and commands.
- `skills/update-docker-manage/references/`: conditional implementation guidance.
- `bash/docker-manage-rc.sh`: `dm` wrapper and dynamic action completion.

## Commands and behavior

`./docker/docker-manage.sh [-b] build|test|sh|down` works from any directory.
`build` and `test` use disposable containers and propagate failures. `sh`
shares a persistent container between terminals and stops it after the last
interactive bash exits. `down` stops the development stack without deleting
named data volumes. `-b` rebuilds the selected service without cache.

The sample commands use Make; this repository has no Makefile, so adapt
commands before running them in a consuming project. UID/GID mapping in
`docker/stuff/entrypoint.sh` lets container commands write host-owned files.
The entrypoint needs root for setup, then executes the command through gosu.

## Verification

Run `bash tests/docker-manage-test.sh` for Docker-free launcher regression
checks, including argument boundaries, failures and shared-shell cleanup.
Check changed shell files with `bash -n`, and render both Compose examples
with `docker compose -f <file> config --quiet`. Run behavior checks for script
changes, including failures and quoted arguments. Do not build the template's
images just to validate documentation. Preserve existing project customizations
when applying the skill elsewhere.
