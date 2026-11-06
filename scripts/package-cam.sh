#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/images"

mkdir -p "$OUTPUT_DIR"

echo "=== Packaging Unified 4MB ESP32-CAM Linux Binary & SD Card Image ==="

BOOTLOADER="$ROOT_DIR/bootloader/build/bootloader/bootloader.bin"
PARTITION_TABLE="$ROOT_DIR/bootloader/build/partition_table/partition-table.bin"
LINUX_BOOT="$ROOT_DIR/bootloader/build/linux_boot.bin"
XIP_IMAGE="$ROOT_DIR/build/images/xipImage"
ROOTFS_EXT4="$ROOT_DIR/build/images/rootfs.ext4"
ROOTFS_TAR="$ROOT_DIR/build/images/rootfs.tar.gz"

for f in "$BOOTLOADER" "$PARTITION_TABLE" "$LINUX_BOOT" "$XIP_IMAGE"; do
    if [ ! -f "$f" ]; then
        echo "Error: Required flash component not found: $f"
        exit 1
    fi
done

echo "Found flash components:"
echo " - Bootloader:      $(ls -lh "$BOOTLOADER" | awk '{print $5}')"
echo " - Partition Table: $(ls -lh "$PARTITION_TABLE" | awk '{print $5}')"
echo " - App Bootloader:  $(ls -lh "$LINUX_BOOT" | awk '{print $5}')"
echo " - Linux Kernel:    $(ls -lh "$XIP_IMAGE" | awk '{print $5}')"

UNIFIED_BIN="$OUTPUT_DIR/linux-esp32cam-4m.bin"

echo "Creating unified 4MB flash image: $UNIFIED_BIN"
esptool.py --chip esp32 merge_bin \
    -o "$UNIFIED_BIN" \
    --flash_mode dio \
    --flash_freq 40m \
    --flash_size 4MB \
    --fill-flash-size 4MB \
    0x1000 "$BOOTLOADER" \
    0x8000 "$PARTITION_TABLE" \
    0x10000 "$LINUX_BOOT" \
    0x40000 "$XIP_IMAGE"

# Copy components to images/
cp "$BOOTLOADER" "$OUTPUT_DIR/bootloader.bin"
cp "$PARTITION_TABLE" "$OUTPUT_DIR/partition-table.bin"
cp "$LINUX_BOOT" "$OUTPUT_DIR/linux_boot.bin"
cp "$XIP_IMAGE" "$OUTPUT_DIR/xipImage"

if [ -f "$ROOTFS_EXT4" ]; then
    echo "Found MicroSD rootfs ext4 image: $(ls -lh "$ROOTFS_EXT4" | awk '{print $5}')"
    cp "$ROOTFS_EXT4" "$OUTPUT_DIR/sdcard-rootfs.ext4"
fi

if [ -f "$ROOTFS_TAR" ]; then
    echo "Found MicroSD rootfs tar archive: $(ls -lh "$ROOTFS_TAR" | awk '{print $5}')"
    cp "$ROOTFS_TAR" "$OUTPUT_DIR/sdcard-rootfs.tar.gz"
fi

cd "$OUTPUT_DIR"
sha256sum *.bin *.ext4 *.tar.gz 2>/dev/null > SHA256SUMS.txt || sha256sum *.bin > SHA256SUMS.txt

echo "=== Packaging complete ==="
ls -lah "$OUTPUT_DIR"
cat "$OUTPUT_DIR/SHA256SUMS.txt"
