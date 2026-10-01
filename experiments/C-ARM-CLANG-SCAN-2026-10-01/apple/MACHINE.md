# Apple Clang measurement host

- Apple M6, arm64; 2 Super, 4 Performance, 6 Efficiency logical CPUs (`sysctl hw.perflevel*`).
- macOS 27.0; Apple Clang 21.0.0 (clang-2100.3.34.2), target arm64-apple-darwin27.0.0.
- AC power; `pmset -g therm` reported no thermal, performance, or CPU-power warning before and during the paired runs.
- CMake Release, static library, benchmarks enabled; unchanged repository benchmark drivers.
- Base `05e06cc597748e6e6c00c7347d2730a917397226`; PR #167 head `cd8e9ef12386bd0d23d6fe5bb49fe23455b676ed`.

This is one Apple-silicon machine and one compiler build. No host identifiers are recorded.
