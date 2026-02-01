# Target Customization Guide

Adapt the Docker template for different project types.

## Node.js Projects

### packages-runtime.sh
```bash
apt-get install -y \
    git \
    nodejs \
    npm
```

### compose.yml dev-compile command
```yaml
command: >
  /bin/bash -c "
  npm ci && npm run build"
```

### Test target
```bash
test)
    docker compose run --rm --build dev-compile npm test
    ;;
```

## Python Projects

### packages-runtime.sh
```bash
apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-venv
```

### compose.yml dev-compile command
```yaml
command: >
  /bin/bash -c "
  pip install -e . && python -m build"
```

### Test target
```bash
test)
    docker compose run --rm --build dev-compile pytest
    ;;
```

### Virtual environment mount (optional)
```yaml
dev-compile:
  volumes:
    - ..:/devsrc
    - venv:/devsrc/.venv
```

## Go Projects

### packages-runtime.sh
```bash
apt-get install -y \
    git \
    golang
```

### compose.yml dev-compile command
```yaml
command: >
  /bin/bash -c "
  go build ./..."
```

### Test target
```bash
test)
    docker compose run --rm --build dev-compile go test ./...
    ;;
```

### Go module cache mount
```yaml
dev-compile:
  volumes:
    - ..:/devsrc
    - ~/go:/home/dev/go
```

## Rust Projects

### packages-runtime.sh
```bash
apt-get install -y \
    git \
    rustc \
    cargo
```

### compose.yml dev-compile command
```yaml
command: >
  /bin/bash -c "
  cargo build --release"
```

### Test target
```bash
test)
    docker compose run --rm --build dev-compile cargo test
    ;;
```

### Cargo cache mount
```yaml
dev-compile:
  volumes:
    - ..:/devsrc
    - ~/.cargo:/home/dev/.cargo
```

## C/C++ Projects (Make-based)

### packages-runtime.sh
```bash
apt-get install -y \
    git \
    build-essential \
    cmake
```

### compose.yml dev-compile command
```yaml
command: >
  /bin/bash -c "
  make -C . -j $(nproc) -k"
```

Default template already supports this pattern.

## Projects with Databases

Add database service to compose.yml:

```yaml
dev-db:
  image: postgres:15
  environment:
    POSTGRES_PASSWORD: devpassword
    POSTGRES_DB: devdb
  volumes:
    - pgdata:/var/lib/postgresql/data
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
    interval: 5s
    timeout: 5s
    retries: 5

dev-compile:
  extends: dev-base
  depends_on:
    dev-db:
      condition: service_healthy
  environment:
    DATABASE_URL: postgres://postgres:devpassword@dev-db:5432/devdb

volumes:
  pgdata:
```

## Additional Targets

### Lint Target
```bash
lint)
    docker compose run --rm --build dev-compile make lint
    ;;
```

### Format Target
```bash
format)
    docker compose run --rm --build dev-compile make format
    ;;
```

### Documentation Target
```bash
docs)
    docker compose run --rm --build dev-compile make docs
    ;;
```

### Watch/Dev Server Target
For projects with hot reload:

```bash
dev)
    docker compose run --rm -p 3000:3000 --build dev-compile npm run dev
    ;;
```

## Multi-Language Projects

For projects with multiple languages:

1. Add all runtimes to packages-runtime.sh
2. Create separate compile services if needed:

```yaml
dev-compile-frontend:
  extends: dev-base
  command: npm run build

dev-compile-backend:
  extends: dev-base
  command: cargo build
```

3. Add combined targets:

```bash
build)
    docker compose up --build dev-compile-frontend dev-compile-backend
    ;;
```
