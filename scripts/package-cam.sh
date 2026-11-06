#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/images"

mkdir -p "$OUTPUT_DIR"

echo "=== Packaging Unified 4MB ESP32-CAM Linux Binary ==="

BOOTLOADER="$ROOT_DIR/bootloader/build/bootloader/bootloader.bin"
PARTITION_TABLE="$ROOT_DIR/bootloader/build/partition_table/partition-table.bin"
LINUX_BOOT="$ROOT_DIR/bootloader/build/linux_boot.bin"
XIP_IMAGE="$ROOT_DIR/build/images/xipImage"
ROOTFS="$ROOT_DIR/build/images/rootfs.cramfs"

for f in "$BOOTLOADER" "$PARTITION_TABLE" "$LINUX_BOOT" "$XIP_IMAGE" "$ROOTFS"; do
    if [ ! -f "$f" ]; then
        echo "Error: Required binary not found: $f"
        exit 1
    fi
done

echo "Found all required components."
echo " - Bootloader:      $(ls -lh "$BOOTLOADER" | awk '{print $5}')"
echo " - Partition Table: $(ls -lh "$PARTITION_TABLE" | awk '{print $5}')"
echo " - App Bootloader:  $(ls -lh "$LINUX_BOOT" | awk '{print $5}')"
echo " - Linux Kernel:    $(ls -lh "$XIP_IMAGE" | awk '{print $5}')"
echo " - CramFS RootFS:   $(ls -lh "$ROOTFS" | awk '{print $5}')"

# Merging into 4MB unified flash image
UNIFIED_BIN="$OUTPUT_DIR/linux-esp32cam-4m.bin"

esptool.py --chip esp32 merge_bin \
    -o "$UNIFIED_BIN" \
    --flash_mode dio \
    --flash_freq 40m \
    --flash_size 4MB \
    --fill-flash-size 4MB \
    0x1000 "$BOOTLOADER" \
    0x8000 "$PARTITION_TABLE" \
    0x10000 "$LINUX_BOOT" \
    0x40000 "$XIP_IMAGE" \
    0x200000 "$ROOTFS"

# Copy individual pieces as well
cp "$BOOTLOADER" "$OUTPUT_DIR/bootloader.bin"
cp "$PARTITION_TABLE" "$OUTPUT_DIR/partition-table.bin"
cp "$LINUX_BOOT" "$OUTPUT_DIR/linux_boot.bin"
cp "$XIP_IMAGE" "$OUTPUT_DIR/xipImage"
cp "$ROOTFS" "$OUTPUT_DIR/rootfs.cramfs"

cd "$OUTPUT_DIR"
sha256sum *.bin *.cramfs xipImage > SHA256SUMS.txt

echo "=== Packaging complete ==="
ls -lah "$OUTPUT_DIR"
cat "$OUTPUT_DIR/SHA256SUMS.txt"
