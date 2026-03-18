cmake_minimum_required(VERSION 3.19)
project(qs-plugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(PkgConfig REQUIRED)

pkg_check_modules(PIPEWIRE REQUIRED libpipewire-0.3)
pkg_check_modules(FFTW3 REQUIRED fftw3)

qt_add_qml_module(qsutils
    URI QsUtils
    VERSION 1.0
    SOURCES
        src/utils/colors.hpp src/utils/colors.cpp
        src/utils/strings.hpp src/utils/strings.cpp
        src/utils/files.hpp src/utils/files.cpp
        src/utils/levendist.hpp src/utils/levendist.cpp
        src/utils/fuzzysort.hpp src/utils/fuzzysort.cpp
        src/obsidian/obsidiantodo.hpp src/obsidian/obsidiantodo.cpp
        src/audio/audiospectrum.hpp src/audio/audiospectrum.cpp
        src/hyprland/hyprlandworkspace.hpp src/hyprland/hyprlandworkspace.cpp
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/QsUtils"
)

target_compile_options(qsutils PRIVATE -Wall -Wextra -Wpedantic -Wshadow)

target_include_directories(qsutils PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utils
    ${CMAKE_CURRENT_SOURCE_DIR}/src/obsidian
    ${CMAKE_CURRENT_SOURCE_DIR}/src/audio
    ${CMAKE_CURRENT_SOURCE_DIR}/src/hyprland
)

# Mark external C library headers as SYSTEM to suppress their warnings
target_include_directories(qsutils SYSTEM PRIVATE
    ${PIPEWIRE_INCLUDE_DIRS}
    ${FFTW3_INCLUDE_DIRS}
)

get_target_property(_qt6_core_inc Qt6::Core INTERFACE_INCLUDE_DIRECTORIES)
list(GET _qt6_core_inc 0 _qt6_inc_first)
get_filename_component(_qt6_inc_root "${_qt6_inc_first}" DIRECTORY)
target_include_directories(qsutils SYSTEM PRIVATE "${_qt6_inc_root}")

target_link_directories(qsutils PRIVATE
    ${PIPEWIRE_LIBRARY_DIRS}
    ${FFTW3_LIBRARY_DIRS}
)

target_link_libraries(qsutils PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    ${PIPEWIRE_LIBRARIES}
    ${FFTW3_LIBRARIES}
)
