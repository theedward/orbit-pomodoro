#!/bin/zsh
set -eu
cd "$(dirname "$0")"
mkdir -p build
xcrun swiftc -module-cache-path "${TMPDIR:-/tmp}/orbit-swift-cache" Sources/TimerEngine.swift Tests/main.swift -o build/timer-tests
build/timer-tests
