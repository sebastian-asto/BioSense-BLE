cmake_minimum_required(VERSION 3.20.0)

# Allow normal (non-sysbuild) builds to discover the board stored in this
# application's boards/ directory.
list(APPEND BOARD_ROOT ${CMAKE_CURRENT_SOURCE_DIR})

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(BioSense_BLE_code_nrf52840)

target_sources(app PRIVATE
    src/main.c
    app/biosense_ble.c
    app/htu21d_monitor.c
    app/supply_voltage.c
    app/wf100dpz.c
)

target_include_directories(app PRIVATE app)
