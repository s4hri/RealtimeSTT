ARG DOCKER_SRC=ubuntu:22.04
FROM ${DOCKER_SRC}

# Re-declare to make it available inside the image
ARG DOCKER_SRC
RUN echo "Building from: "${DOCKER_SRC:?err}

# Uncomment the following command to avoid the use of cache on all the following other commands
# Source: https://stackoverflow.com/questions/35134713/disable-cache-for-specific-run-commands
# ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache

USER root
WORKDIR /workdir

COPY . ./

RUN apt-get update && xargs -a packages.apt apt-get install -y

RUN mkdir -p /etc/ssh \
    && ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

# Add sound configuration
COPY asound.conf /etc/asound.conf

# install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# Optional: Verify UV installation
RUN ["/bin/bash", "-c", "source $HOME/.local/bin/env && uv --version"]

ENV PYTHONPATH="/workdir:${PYTHONPATH}"

WORKDIR /workdir
