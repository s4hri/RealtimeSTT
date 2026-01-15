ARG DOCKER_SRC=ubuntu:22.04
FROM ${DOCKER_SRC}

# Re-declare to make it available inside the image
ARG DOCKER_SRC
RUN echo "Building from: "${DOCKER_SRC:?err}

USER root
WORKDIR /workdir

# Copy the repository content into the image
COPY . ./

# System packages
RUN apt-get update && xargs -a packages.apt apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# GitHub host key (avoid interactive prompts when git is used)
RUN mkdir -p /etc/ssh \
    && ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

# ALSA sound configuration
COPY asound.conf /etc/asound.conf

# -----------------------------
# Python tooling: uv
# -----------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# Make uv available without sourcing shell snippets
ENV PATH="/root/.local/bin:${PATH}"
RUN uv --version

# -----------------------------
# Python/pip network settings (PyPI + NVIDIA NGC index)
# -----------------------------
ENV PIP_INDEX_URL=https://pypi.org/simple
ENV PIP_EXTRA_INDEX_URL=https://pypi.ngc.nvidia.com
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
# Force uv to use the system trust store (useful behind corporate TLS inspection)
ENV UV_NATIVE_TLS=1

# -----------------------------
# --- Forza uv a usare il trust store di sistema (utile in reti corporate) ---
ENV UV_NATIVE_TLS=1

# --- Build CTranslate2 con CUDA e install in /usr/local ---
RUN git clone --depth 1 --branch v4.6.3 --recurse-submodule https://github.com/OpenNMT/CTranslate2.git /opt/CTranslate2 \
&& cmake -S /opt/CTranslate2 -B /opt/CTranslate2/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_MKL=OFF \
      -DWITH_OPENBLAS=ON \
      -DWITH_CUDA=ON \
      -DWITH_CUDNN=ON \
      -DCUDA_ARCH_LIST=8.7 \
&& cmake --build /opt/CTranslate2/build -j"$(nproc)" \
&& cmake --install /opt/CTranslate2/build \
&& ldconfig

# --- Build wheel Python (richiede pybind11) e install ---
RUN python3 -m pip install --upgrade pip setuptools wheel pybind11
RUN cd /opt/CTranslate2/python \
&& python3 setup.py bdist_wheel \
&& python3 -m pip install --force-reinstall dist/*.whl

# -----------------------------
# Virtual environment (keeps system site-packages visible for system-provided CUDA Torch)
# -----------------------------
RUN uv venv -p /usr/bin/python3 --system-site-packages /workdir/tests/.venv
ENV VIRTUAL_ENV=/workdir/tests/.venv
ENV PATH="/workdir/tests/.venv/bin:${PATH}"

# Use a fixed venv for the project
ENV UV_PROJECT_ENVIRONMENT=/workdir/tests/.venv

# -----------------------------
# Install project deps from uv.lock/pyproject, but DO NOT replace torch packages
# -----------------------------
WORKDIR /workdir
RUN uv sync --frozen --active \
    --no-install-package torch \
    --no-install-package torchaudio \
    --no-install-package torchvision

# -----------------------------
# Overrides observed in the previous container session:
# - NumPy < 2 for compatibility with onnxruntime 1.16.3 (Py3.10 / aarch64)
# - Install onnxruntime without pulling dependency upgrades
# -----------------------------
RUN python3 -m pip install --no-cache-dir --index-url https://pypi.org/simple \
    --no-deps "numpy==1.26.4"
RUN python3 -m pip install --no-cache-dir --index-url https://pypi.org/simple \
    --no-deps "onnxruntime==1.16.3"

# Minimal diagnostics during build (CUDA visibility + core versions)
RUN python3 -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda, 'is_available', torch.cuda.is_available())"
RUN python3 -c "import numpy, onnxruntime; print('numpy', numpy.__version__); print('onnxruntime', onnxruntime.__version__)"

ENV PYTHONPATH="/workdir:${PYTHONPATH}"
WORKDIR /workdir
