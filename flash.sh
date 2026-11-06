#!/usr/bin/env bash
# Flash unified Linux image to ESP32-CAM
set -e

PORT="${1:-/dev/ttyUSB0}"
BAUD="${2:-460800}"
IMAGE="images/linux-esp32cam-4m.bin"

if [ ! -f "$IMAGE" ]; then
    echo "Error: $IMAGE not found! Run the build or download the artifact first."
    exit 1
fi

echo "=========================================="
echo " Flashing Linux to ESP32-CAM (4MB Flash)  "
echo " Port: $PORT | Baud: $BAUD"
echo "=========================================="
echo "Note: Make sure GPIO 0 is connected to GND when entering bootloader mode."
echo ""

esptool.py --chip esp32 \
    --port "$PORT" \
    --baud "$BAUD" \
    --before default_reset \
    --after hard_reset \
    write_flash \
    --flash_mode dio \
    --flash_freq 40m \
    --flash_size 4MB \
    0x0 "$IMAGE"

echo ""
echo "=========================================="
echo " Flashing Complete!                      "
echo " Disconnect GPIO 0 from GND and reboot.   "
echo " Connect serial terminal at 115200 baud:  "
echo "   picocom -b 115200 $PORT                "
echo "=========================================="
