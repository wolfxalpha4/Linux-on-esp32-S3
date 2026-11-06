#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Building Linux for ESP32-CAM ==="
cd "$ROOT_DIR"

# 1. Setup Dynconfig for ESP32 (Call0 ABI)
if [ ! -f "$ROOT_DIR/xtensa-dynconfig/esp32.so" ]; then
    echo "=== Building xtensa-dynconfig esp32.so ==="
    mkdir -p "$ROOT_DIR/xtensa-dynconfig"
    if [ ! -d "$ROOT_DIR/xtensa-dynconfig/repo" ]; then
        git clone https://github.com/jcmvbkbc/xtensa-dynconfig -b original "$ROOT_DIR/xtensa-dynconfig/repo"
    fi
    if [ ! -f "$ROOT_DIR/xtensa-dynconfig/esp32.tar.gz" ]; then
        wget -q https://github.com/jcmvbkbc/xtensa-toolchain-build/raw/e46089b8418f27ecd895881f071aa192dd7f42b5/overlays/original/esp32.tar.gz -O "$ROOT_DIR/xtensa-dynconfig/esp32.tar.gz"
    fi
    mkdir -p "$ROOT_DIR/xtensa-dynconfig/esp32"
    tar -xf "$ROOT_DIR/xtensa-dynconfig/esp32.tar.gz" -C "$ROOT_DIR/xtensa-dynconfig/esp32"
    sed -i 's/\(XSHAL_ABI\s\+\)XTHAL_ABI_WINDOWED/\1XTHAL_ABI_CALL0/' "$ROOT_DIR/xtensa-dynconfig/esp32"/{binutils,gcc}/xtensa-config.h
    make -C "$ROOT_DIR/xtensa-dynconfig/repo" ORIG=1 CONF_DIR="$ROOT_DIR/xtensa-dynconfig" esp32.so
    cp "$ROOT_DIR/xtensa-dynconfig/repo/esp32.so" "$ROOT_DIR/xtensa-dynconfig/esp32.so"
fi

export XTENSA_GNU_CONFIG="$ROOT_DIR/xtensa-dynconfig/esp32.so"
echo "XTENSA_GNU_CONFIG set to: $XTENSA_GNU_CONFIG"

# 2. Check / Build Cross-Toolchain
TOOLCHAIN_DIR="$ROOT_DIR/toolchain/xtensa-esp32-linux-uclibcfdpic"
if [ -x "$TOOLCHAIN_DIR/bin/xtensa-esp32-linux-uclibcfdpic-gcc" ]; then
    echo "Using existing toolchain at: $TOOLCHAIN_DIR"
elif [ -x "/opt/xtensa-esp32s3-linux-uclibcfdpic/bin/xtensa-esp32s3-linux-uclibcfdpic-gcc" ]; then
    echo "Using host toolchain with esp32.so overlay"
    TOOLCHAIN_DIR="/opt/xtensa-esp32s3-linux-uclibcfdpic"
    TOOLCHAIN_PREFIX="xtensa-esp32s3-linux-uclibcfdpic"
else
    echo "=== Building crosstool-NG toolchain ==="
    mkdir -p "$ROOT_DIR/crosstool-NG"
    git clone https://github.com/jcmvbkbc/crosstool-NG.git -b xtensa-fdpic "$ROOT_DIR/crosstool-NG"
    pushd "$ROOT_DIR/crosstool-NG"
    ./bootstrap && ./configure --enable-local && make
    ./ct-ng xtensa-esp32-linux-uclibcfdpic
    CT_PREFIX="$ROOT_DIR/toolchain" ./ct-ng build
    popd
fi

# 3. Buildroot (Userspace + Kernel)
BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

if [ ! -d "$ROOT_DIR/buildroot" ]; then
    echo "=== Cloning Buildroot ==="
    git clone https://github.com/jcmvbkbc/buildroot -b xtensa-2024.05-fdpic "$ROOT_DIR/buildroot"
fi

echo "=== Configuring Buildroot for ESP32-CAM ==="
make -C "$ROOT_DIR/buildroot" O="$BUILD_DIR" defconfig BR2_DEFCONFIG="$ROOT_DIR/configs/esp32cam_4m_defconfig"

# Set toolchain path
"$ROOT_DIR/buildroot/utils/config" --file "$BUILD_DIR/.config" --set-str TOOLCHAIN_EXTERNAL_PATH "$TOOLCHAIN_DIR"
if [ -n "$TOOLCHAIN_PREFIX" ]; then
    "$ROOT_DIR/buildroot/utils/config" --file "$BUILD_DIR/.config" --set-str TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX "$TOOLCHAIN_PREFIX"
fi
"$ROOT_DIR/buildroot/utils/config" --file "$BUILD_DIR/.config" --set-str ROOTFS_OVERLAY "$ROOT_DIR/rootfs_overlay"
"$ROOT_DIR/buildroot/utils/config" --file "$BUILD_DIR/.config" --set-str LINUX_KERNEL_CUSTOM_CONFIG_FILE "$ROOT_DIR/configs/esp32cam_4m_linux.config"

echo "=== Compiling Userspace and Kernel ==="
make -C "$ROOT_DIR/buildroot" O="$BUILD_DIR" -j"$(nproc)"

echo "=== Buildroot artifacts: ==="
ls -lh "$BUILD_DIR/images"
