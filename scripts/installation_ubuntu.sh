#!/bin/bash

set -e  # Exit on error
set -u  # Treat unset variables as errors

# === CONFIGURATION ===
export MOFEM_INSTALL_DIR=$HOME/mofem_install
export SPACK_ROOT=$MOFEM_INSTALL_DIR/spack
export MOFEM_REPO=$MOFEM_INSTALL_DIR/mofem_cephas
export MOFEM_SRC_DIR=$MOFEM_INSTALL_DIR/mofem-cephas
export MOFEM_BRANCH=Version0.15.0
export TZ=Europe/London
export DEBIAN_FRONTEND=noninteractive

# === CREATE DIRECTORIES ===
mkdir -p "$MOFEM_INSTALL_DIR"
mkdir -p "$MOFEM_REPO"

# === INSTALL SYSTEM PACKAGES ===
sudo apt-get update
sudo apt-get install -y \
    file \
    zlib1g-dev \
    openssh-server \
    wget \
    valgrind \
    curl \
    git \
    g++ \
    gfortran \
    gdb \
    m4 \
    automake \
    build-essential \
    libtool \
    libsigsegv2 \
    libjpeg-dev \
    graphviz \
    doxygen \
    cmake \
    pkg-config \
    gnuplot \
    ca-certificates \
    python3-setuptools \
    libx11-dev \
    xauth \
    xterm \
    unzip \
    mesa-common-dev \
    libglu1-mesa-dev \
    libxmu-dev \
    libxi-dev \
    libssl-dev \
    gawk \
    locales \
    gettext \
    python3-dev \
    python3-numpy \
    python3-scipy \
    libboost-all-dev \
    libboost-python-dev \
    openmpi-bin \
    libopenmpi-dev

sudo locale-gen en_US.UTF-8

# === INSTALL SPACK ===
if [ ! -d "$SPACK_ROOT" ]; then
  curl -L https://github.com/spack/spack/archive/refs/tags/v0.23.1.tar.gz | \
    tar -xz -C "$MOFEM_INSTALL_DIR" && \
    mv "$MOFEM_INSTALL_DIR/spack-0.23.1" "$SPACK_ROOT"
fi

# === SETUP SHELL ENV ===
export PATH="$SPACK_ROOT/bin:$PATH"
. "$SPACK_ROOT/share/spack/setup-env.sh"

# === ADD TO BASHRC ===
SPACK_ENV_LINE=". $SPACK_ROOT/share/spack/setup-env.sh"
grep -qxF "$SPACK_ENV_LINE" ~/.bashrc || echo "$SPACK_ENV_LINE" >> ~/.bashrc

# === SETUP SPACK ENVIRONMENT ===
spack compiler find
spack external find
spack config add "packages:all:target:[x86_64]"
spack config add "packages:all:variants:build_type=Release"

cat <<EOF | tee ~/.spack/packages.yaml
packages:
  openmpi:
    externals:
    - spec: openmpi@4.1.6
      prefix: /usr
    buildable: false
  python:
    externals:
    - spec: python@3.12.3
      prefix: /usr
    buildable: false
  py-numpy:
    externals:
    - spec: py-numpy@1.26.4 ^python@3.12.3
      prefix: /usr
    buildable: false
  boost:
    externals:
    - spec: boost@1.83.0
      prefix: /usr
    buildable: false
  icu4c:
    externals:
    - spec: icu4c@74.2
      prefix: /usr
    buildable: false
EOF

# === COPY REPO FILES ===
# (You must provide these yourself)

# === CLONE MoFEM SOURCES ===
git clone -b "$MOFEM_BRANCH" https://bitbucket.org/mofem/mofem-cephas.git "$MOFEM_SRC_DIR"

# === REGISTER MoFEM REPO ===
spack repo add "$MOFEM_REPO"

# === INSTALL DEPENDENCIES ONLY ===
spack install --only dependencies mofem-cephas@0.15.0+mgis ^petsc+X
spack clean -a


# === CREATE SPACK ENV ===
spack env create mofem
spack env activate mofem
spack add mofem-cephas@0.15.0+adol-c+med+mgis~shared+slepc+tetgen install_id=0 ^petsc+X
spack develop -p "$MOFEM_SRC_DIR" mofem-cephas@0.15.0
spack concretize -f
spack install -v test=root mofem-cephas@0.15.0+adol-c+med+mgis~shared+slepc+tetgen install_id=0 ^petsc+X
spack clean -a

# === FINAL MESSAGE ===
echo
echo "✅ MoFEM installed successfully in: $MOFEM_INSTALL_DIR"
echo "🔁 You can activate the Spack environment with:"
echo "    spack env activate mofem"
echo
