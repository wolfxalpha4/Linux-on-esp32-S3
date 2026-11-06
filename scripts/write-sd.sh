#!/usr/bin/env bash
# Write Linux RootFS to MicroSD card
set -e

SD_DEV="$1"

if [ -z "$SD_DEV" ]; then
    echo "Usage: sudo $0 /dev/sdX  (or /dev/mmcblkX)"
    echo "Example: sudo $0 /dev/sdb"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo $0 $SD_DEV)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE="$ROOT_DIR/images/sdcard-rootfs.ext4"

if [ ! -f "$IMAGE" ]; then
    echo "Error: $IMAGE not found! Download the artifact or run the build first."
    exit 1
fi

echo "=========================================="
echo " Writing Linux RootFS to MicroSD: $SD_DEV "
echo "=========================================="
echo "WARNING: All data on $SD_DEV will be replaced!"
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Determine partition target: if /dev/sdb -> /dev/sdb1, if /dev/mmcblk0 -> /dev/mmcblk0p1
if [[ "$SD_DEV" =~ [0-9]$ ]]; then
    PART="${SD_DEV}p1"
else
    PART="${SD_DEV}1"
fi

echo "1. Creating MBR partition table on $SD_DEV..."
parted -s "$SD_DEV" mklabel msdos mkpart primary ext4 1MiB 100%
sleep 1

echo "2. Writing ext4 rootfs to $PART..."
dd if="$IMAGE" of="$PART" bs=4M status=progress conv=fsync

echo "3. Resizing ext4 filesystem to fill card..."
e2fsck -f -y "$PART" || true
resize2fs "$PART"

sync
echo "=========================================="
echo " MicroSD card ready!"
echo " Insert it into your ESP32-CAM and boot."
echo "=========================================="
