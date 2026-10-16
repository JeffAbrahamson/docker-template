FROM ubuntu:26.04 AS compile-dev-base

RUN mkdir -p   /usr/local/

WORKDIR /devsrc

# These COPY commands ought not to invalidate cache unless the copied
# file has changed.
COPY --chmod=755 docker/stuff/packages-runtime.sh ./
RUN bash -o pipefail -c './packages-runtime.sh 2>&1 | tee /var/packages-runtime.out'

COPY --chmod=755 docker/stuff/packages-dev.sh ./
RUN bash -o pipefail -c './packages-dev.sh 2>&1 | tee /var/packages-dev.out'

RUN useradd -ms /bin/bash dev
# RUN chown -R dev:dev /home/dev /devsrc
RUN apt-get update && apt-get install -y --no-install-recommends \
      gosu \
    && rm -rf /var/lib/apt/lists/*
COPY --chmod=755 docker/stuff/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]



FROM compile-dev-base AS compile-for-dev
