cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(Code_SDK_Nordic_nRF52840)

target_sources(app PRIVATE src/main.c)
