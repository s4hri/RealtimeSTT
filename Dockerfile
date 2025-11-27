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


# Fix for ctranslate2 ----------------------------------------
WORKDIR /cudnn_installation

# Download and unpack cuDNN 9.1 archive
# COPY cudnn-linux-x86_64-9.1.0.70_cuda12-archive.tar.xz ./cudnn-linux-x86_64-9.1.0.70_cuda12-archive.tar.xz
RUN wget https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-9.1.0.70_cuda12-archive.tar.xz

RUN tar -xvf cudnn-linux-x86_64-9.1.0.70_cuda12-archive.tar.xz && \
    cp cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib/libcudnn* /usr/lib/x86_64-linux-gnu/ && \
    ldconfig && \
    cd /usr/lib/x86_64-linux-gnu && \
    ln -sf libcudnn_cnn.so.9.1.0 libcudnn_cnn.so.9 && \
    ln -sf libcudnn_ops.so.9.1.0 libcudnn_ops.so.9 && \
    ln -sf libcudnn_adv.so.9.1.0 libcudnn_adv.so.9 && \
    ln -sf libcudnn.so.9.1.0 libcudnn.so.9 && \
    ln -sf libcudnn_heuristic.so.9.1.0 libcudnn_heuristic.so.9 && \
    ln -sf libcudnn_graph.so.9.1.0 libcudnn_graph.so.9 && \
    ln -sf libcudnn_engines_precompiled.so.9.1.0 libcudnn_engines_precompiled.so.9 && \
    ln -sf libcudnn_engines_runtime_compiled.so.9.1.0 libcudnn_engines_runtime_compiled.so.9 && \
    ldconfig && \
    rm -rf /tmp/cudnn* /var/lib/apt/lists/*

# install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PYTHONPATH="/workdir:${PYTHONPATH}"

WORKDIR /workdir
