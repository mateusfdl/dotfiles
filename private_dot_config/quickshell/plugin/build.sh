#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

CMAKE_EXTRA_ARGS=()
if [ -d /nix/store ]; then
    QT6_BASE=$(nix-store -q --references "$(which quickshell)" 2>/dev/null | grep qtbase | head -1 || true)
    QT6_DECL=$(nix-store -q --references "$(which quickshell)" 2>/dev/null | grep qtdeclarative | head -1 || true)
    LIBGLVND=$(nix-store -q --references "$(which quickshell)" 2>/dev/null | grep "libglvnd-[0-9]" | grep -v dev | head -1 || true)
    LIBGLVND_DEV=$(nix-build '<nixpkgs>' -A libglvnd.dev --no-out-link 2>/dev/null || true)
    PIPEWIRE_DEV=$(nix-build '<nixpkgs>' -A pipewire.dev --no-out-link 2>/dev/null || true)
    PIPEWIRE_LIB=$(nix-store -q --references "$(which quickshell)" 2>/dev/null | grep "pipewire-[0-9]" | grep -v dev | head -1 || true)
    FFTW_DEV=$(nix-build '<nixpkgs>' -A fftw.dev --no-out-link 2>/dev/null || true)
    FFTW_LIB=$(nix-build '<nixpkgs>' -A fftw.out --no-out-link 2>/dev/null || true)
    PREFIX_PATH=""
    [ -n "$QT6_BASE" ] && PREFIX_PATH="${QT6_BASE}"
    [ -n "$QT6_DECL" ] && PREFIX_PATH="${PREFIX_PATH:+${PREFIX_PATH};}${QT6_DECL}"
    [ -n "$LIBGLVND" ] && PREFIX_PATH="${PREFIX_PATH:+${PREFIX_PATH};}${LIBGLVND}"
    [ -n "$LIBGLVND_DEV" ] && PREFIX_PATH="${PREFIX_PATH:+${PREFIX_PATH};}${LIBGLVND_DEV}"
    [ -n "$PIPEWIRE_DEV" ] && PREFIX_PATH="${PREFIX_PATH:+${PREFIX_PATH};}${PIPEWIRE_DEV}"
    [ -n "$PIPEWIRE_LIB" ] && PREFIX_PATH="${PREFIX_PATH:+${PREFIX_PATH};}${PIPEWIRE_LIB}"
    [ -n "$FFTW_DEV" ] && PREFIX_PATH="${PREFIX_PATH:+${PREFIX_PATH};}${FFTW_DEV}"
    [ -n "$FFTW_LIB" ] && PREFIX_PATH="${PREFIX_PATH:+${PREFIX_PATH};}${FFTW_LIB}"
    if [ -n "$PREFIX_PATH" ]; then
        CMAKE_EXTRA_ARGS+=(-DCMAKE_PREFIX_PATH="${PREFIX_PATH}")
    fi
fi

cmake -B "${BUILD_DIR}" -S "${SCRIPT_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    "${CMAKE_EXTRA_ARGS[@]}"

cmake --build "${BUILD_DIR}"

QML_DIR="${BUILD_DIR}/qml"
export QML_IMPORT_PATH="${QML_DIR}:${QML_IMPORT_PATH:-}"
export QML2_IMPORT_PATH="${QML_DIR}:${QML2_IMPORT_PATH:-}"
