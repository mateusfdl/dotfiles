cmake_minimum_required(VERSION 3.19)
project(qs-plugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Sql)
find_package(PkgConfig REQUIRED)

include(CTest)

pkg_check_modules(PIPEWIRE REQUIRED libpipewire-0.3)
pkg_check_modules(FFTW3 REQUIRED fftw3)

qt_add_qml_module(qsutils
    URI QsUtils
    VERSION 1.0
    SOURCES
        src/utils/colors.hpp src/utils/colors.cpp
        src/utils/files.hpp src/utils/files.cpp
        src/utils/fuzzysort.hpp src/utils/fuzzysort.cpp
        src/utils/jsonvalidator.hpp src/utils/jsonvalidator.cpp
        src/config/appearance.hpp src/config/appearance.cpp
        src/tasks/tasks.hpp src/tasks/tasks.cpp
        src/audio/audiospectrum.hpp src/audio/audiospectrum.cpp
        src/hyprland/hyprlandworkspace.hpp src/hyprland/hyprlandworkspace.cpp
        src/launcher/appsearch.hpp src/launcher/appsearch.cpp
        src/system/systeminfo.hpp src/system/systeminfo.cpp
        src/recorder/screenrecorder.hpp src/recorder/screenrecorder.cpp
        src/common/directories.hpp src/common/directories.cpp
        src/common/persistent.hpp src/common/persistent.cpp
        src/db/keyvaluestore.hpp src/db/keyvaluestore.cpp
        src/db/sqlite.hpp src/db/sqlite.cpp
        src/reminder/reminder.hpp src/reminder/reminder.cpp
        src/reminder/reminderstore.hpp src/reminder/reminderstore.cpp
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/QsUtils"
)

target_compile_options(qsutils PRIVATE -Wall -Wextra -Wpedantic -Wshadow)

target_include_directories(qsutils PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utils
    ${CMAKE_CURRENT_SOURCE_DIR}/src/config
    ${CMAKE_CURRENT_SOURCE_DIR}/src/tasks
    ${CMAKE_CURRENT_SOURCE_DIR}/src/audio
    ${CMAKE_CURRENT_SOURCE_DIR}/src/hyprland
    ${CMAKE_CURRENT_SOURCE_DIR}/src/launcher
    ${CMAKE_CURRENT_SOURCE_DIR}/src/system
    ${CMAKE_CURRENT_SOURCE_DIR}/src/recorder
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common
    ${CMAKE_CURRENT_SOURCE_DIR}/src/db
    ${CMAKE_CURRENT_SOURCE_DIR}/src/reminder
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
    Qt6::Sql
    ${PIPEWIRE_LIBRARIES}
    ${FFTW3_LIBRARIES}
)

if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)

    qt_add_executable(tasks_test
        tests/tasks_test.cpp
        src/tasks/tasks.hpp src/tasks/tasks.cpp
    )

    target_include_directories(tasks_test PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/tasks
    )

    target_compile_options(tasks_test PRIVATE -Wall -Wextra -Wpedantic -Wshadow)

    target_link_libraries(tasks_test PRIVATE
        Qt6::Core
        Qt6::Qml
        Qt6::Test
    )

    add_test(NAME tasks_test COMMAND tasks_test)
endif()
