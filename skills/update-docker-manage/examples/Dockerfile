FROM ubuntu:26.04 AS compile-dev-base

RUN mkdir -p /usr/local/

WORKDIR /devsrc

# Install runtime packages
# These COPY commands only invalidate cache if the copied file has changed
COPY --chmod=755 docker/stuff/packages-runtime.sh ./
RUN bash -o pipefail -c './packages-runtime.sh 2>&1 | tee /var/packages-runtime.out'

# Install development packages
COPY --chmod=755 docker/stuff/packages-dev.sh ./
RUN bash -o pipefail -c './packages-dev.sh 2>&1 | tee /var/packages-dev.out'

# Create dev user for non-root operations
RUN useradd -ms /bin/bash dev

# Install gosu for privilege management
RUN apt-get update && apt-get install -y --no-install-recommends \
      gosu \
    && rm -rf /var/lib/apt/lists/*

# Add entrypoint script for UID/GID mapping
COPY --chmod=755 docker/stuff/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]


# Development target - extends base with no changes
FROM compile-dev-base AS compile-for-dev
