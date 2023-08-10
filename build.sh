#!/bin/bash
set -euo pipefail

cmake -S . -B build
cmake -DCMAKE_BUILD_TYPE=Release -S . -B build
cmake --build build
cmake --build build --target wasm