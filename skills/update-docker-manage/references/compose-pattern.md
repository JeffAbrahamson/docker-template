# compose.yml Pattern

The compose.yml file defines Docker services using an extends pattern for shared configuration.

## Base Service

All services extend from a base service:

```yaml
services:
  dev-base:
    build:
      context: ..
      dockerfile: docker/Dockerfile
      target: compile-for-dev
    image: dev-build
    volumes:
      - ..:/devsrc
    environment:
      SSH_AUTH_SOCK: /ssh-agent
      SSH_USER: ${LOGNAME}
```

Key configuration:
- `context: ..` - Build context is project root
- `dockerfile: docker/Dockerfile` - Dockerfile location
- `target` - Multi-stage build target
- `volumes: ..:/devsrc` - Mount project root
- `SSH_AUTH_SOCK` - For git SSH operations

## Service Patterns

### Compile Service (build, test)

```yaml
dev-compile:
  extends: dev-base
  image: dev-build
  command: >
    /bin/bash -c "
    make -C . -j $(nproc) -k"
```

Runs build command and exits. Customize command for your build system.

### Shell Service

```yaml
dev-sh:
  extends: dev-base
  image: dev-sh
  command: sleep infinity
```

Stays running for shell attach. The `sleep infinity` keeps container alive.

### AI Tool Services

```yaml
dev-claude:
  extends: dev-base
  build:
    target: compile-for-claude
  command: sleep infinity
  environment:
    HOME: /home/dev
  volumes:
    - ~/.claude:/home/dev/.claude
    - ~/.claude.json:/home/dev/.claude.json
```

Key features:
- Different build target (compile-for-claude)
- `HOME: /home/dev` ensures correct home directory
- Mount credential files from host

## Volume Mounts

### Project Mount

All services mount the project:
```yaml
volumes:
  - ..:/devsrc
```

### Credential Mounts

AI tools need their config directories:
```yaml
volumes:
  - ~/.claude:/home/dev/.claude
  - ~/.claude.json:/home/dev/.claude.json
```

### Cache Mounts (Optional)

For faster builds, mount caches:
```yaml
volumes:
  - ~/.npm:/home/dev/.npm
  - ~/.cargo:/home/dev/.cargo
```

## Adding New Services

To add a service:

1. Define it extending dev-base
2. Set appropriate build target if needed
3. Add command or leave for docker-manage.sh to specify
4. Add volume mounts for any needed credentials/caches

Example database service:

```yaml
dev-db:
  image: postgres:15
  environment:
    POSTGRES_PASSWORD: devpassword
  volumes:
    - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

## Environment Variables

- `SSH_AUTH_SOCK`: For SSH agent forwarding
- `SSH_USER`: Host username for entrypoint.sh
- `HOME`: Override for correct home directory in some services
