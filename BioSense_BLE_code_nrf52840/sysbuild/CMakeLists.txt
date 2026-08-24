# SPDX-License-Identifier: Apache-2.0

# Sysbuild is a separate CMake project, so it needs its own BOARD_ROOT.
# The parent directory is the application root that contains boards/.
list(APPEND BOARD_ROOT ${CMAKE_CURRENT_LIST_DIR}/..)

find_package(Sysbuild REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(sysbuild LANGUAGES)
