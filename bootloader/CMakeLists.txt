cmake_minimum_required(VERSION 3.16)
set(COMPONENTS main esp_system esp_partition spi_flash esp_rom esp_common hal soc esp_hw_support xtensa log newlib freertos bootloader_support esp_app_format)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(linux_boot)
