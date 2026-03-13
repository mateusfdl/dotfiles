cmake_minimum_required(VERSION 3.19)
project(qs-plugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_add_qml_module(colors
    URI Colors
    VERSION 1.0
    SOURCES
        src/utils/colors.hpp src/utils/colors.cpp
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/Colors"
)

target_include_directories(colors PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src/utils)

get_target_property(_qt6_core_inc Qt6::Core INTERFACE_INCLUDE_DIRECTORIES)
list(GET _qt6_core_inc 0 _qt6_inc_first)
get_filename_component(_qt6_inc_root "${_qt6_inc_first}" DIRECTORY)
target_include_directories(colors SYSTEM PRIVATE "${_qt6_inc_root}")

target_link_libraries(colors PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)
