/*
 * Linux Bootloader for ESP32-CAM
 * Based on jcmvbkbc linux_boot for ESP-IDF
 */
#include <stdio.h>
#include "sdkconfig.h"
#include "esp_system.h"
#include "spi_flash_mmap.h"
#include "esp_partition.h"

static const void * IRAM_ATTR map_partition(const char *name)
{
    const void *ptr;
    spi_flash_mmap_handle_t handle;
    esp_partition_iterator_t it;
    const esp_partition_t *part;

    it = esp_partition_find(ESP_PARTITION_TYPE_ANY, ESP_PARTITION_SUBTYPE_ANY, name);
    if (!it) {
        printf("[ERROR] Partition '%s' not found!\n", name);
        abort();
    }
    part = esp_partition_get(it);
    esp_partition_iterator_release(it);
    if (esp_partition_mmap(part, 0, part->size, SPI_FLASH_MMAP_INST, &ptr, &handle) != ESP_OK) {
        printf("[ERROR] Failed to mmap partition '%s'!\n", name);
        abort();
    }
    return ptr;
}

static void IRAM_ATTR map_flash_and_go(void)
{
    const void *ptr0, *ptr;

    printf("\n=========================================\n");
    printf("   Booting Linux on ESP32-CAM (4MB)     \n");
    printf("=========================================\n");
    ptr0 = map_partition("linux");
    printf("Kernel mapped at: %p\n", ptr0);
    ptr = map_partition("rootfs");
    printf("RootFS mapped at: %p\n", ptr);
    printf("Transferring control to Linux kernel...\n\n");

    asm volatile ("jx %0" :: "r"(ptr0));
}

void app_main(void)
{
    map_flash_and_go();
    esp_restart();
}
