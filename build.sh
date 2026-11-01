#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mkdir -p "$root/build"
nasm -Werror -f bin -I "$root/../sdk/include/" \
    "$root/src/DEVINFO.asm" -o "$root/build/DEVINFO.BIN"
echo "built $root/build/DEVINFO.BIN"
