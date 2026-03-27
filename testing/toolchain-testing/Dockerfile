FROM ubuntu:24.04

# Install dependencies
RUN apt update && apt install -y \
    make nasm mtools mbr \
    qemu-system-x86 \
    build-essential wget bison flex \
    libgmp3-dev libmpc-dev libmpfr-dev \
    texinfo xz-utils

WORKDIR /root

# Optional: speed up builds
ENV PATH="/opt/i686-elf-toolchain/bin:$PATH"
