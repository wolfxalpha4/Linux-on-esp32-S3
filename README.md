# Linux on ESP32-CAM (4MB Flash / 4MB PSRAM)

Native Linux (kernel 6.11-esp32) for the AI-Thinker ESP32-CAM and compatible boards with external PSRAM and onboard MicroSD slot.

## Hardware Specifications
- **CPU**: Espressif ESP32 (Xtensa LX6 dual-core, Call0 ABI)
- **RAM**: 4MB Quad-SPI external PSRAM
- **Flash**: 4MB SPI Flash
- **Storage**: Internal CramFS XIP + MicroSD card slot auto-mounted at `/sd`
- **Networking**: 802.11 b/g/n Wi-Fi
- **Services**: Dropbear SSH on port 22, BusyBox userspace, Nano editor

## Flash Partition Layout (4MB)
| Offset | Size | Name | Purpose |
| :--- | :--- | :--- | :--- |
| `0x1000` | `0x7000` (28KB) | Bootloader | 2nd stage bootloader |
| `0x8000` | `0x1000` (4KB) | Partition Table | Custom 4MB partition table |
| `0x9000` | `0x5000` (20KB) | NVS | Non-volatile storage |
| `0xf000` | `0x1000` (4KB) | PHY Init | RF calibration data |
| `0x10000` | `0x30000` (192KB) | Factory (`linux_boot`) | Mmap kernel/rootfs & jump to Linux |
| `0x40000` | `0x1c0000` (1.75MB) | Linux | `xipImage` (Kernel linear XIP) |
| `0x200000` | `0x200000` (2.0MB) | RootFS | `rootfs.cramfs` (XIP userspace) |

## Flashing Instructions
Download `linux-esp32cam-4m-build.zip` from GitHub Actions artifacts, extract `linux-esp32cam-4m.bin`, then run:

```bash
# Put ESP32-CAM into bootloader mode (bridge GPIO 0 to GND and press RESET)
./flash.sh /dev/ttyUSB0
```

Or manually using `esptool.py`:
```bash
esptool.py --chip esp32 -p /dev/ttyUSB0 -b 460800 write_flash 0x0 images/linux-esp32cam-4m.bin
```

## Serial Console
Connect FTDI / USB-TTL adapter (TX -> U0R, RX -> U0T, GND -> GND):
```bash
picocom -b 115200 /dev/ttyUSB0
```

## SSH Login
- **Host**: IP assigned by Wi-Fi DHCP
- **Port**: 22
- **User**: `root`
- **Password**: `12345678`
