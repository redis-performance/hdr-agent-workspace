# Native Os/O3 audit — running

Current revision: PR #158 `d21d0843b492023077553b3eba26b3efa16c15f5`.
The earlier local report pinned `bcb5c1f`; its results are historical and are
not the current fleet comparison.

Three native AWS runners (Intel x86_64, AMD x86_64, ARM64) run independently,
with timed work pinned to one core. GCC 13.3 and Clang 18.1 are available.
All eight core configurations per runner passed all five CTest tests (120
successful tests across the fleet). Immutable drivers match their git objects.

Intel and AMD consumer builds and all four size variants per project have
passed smoke checks. ARM consumer builds are finishing. Repeated full driver
runs are in progress; preliminary timing ratios are not final conclusions.
The controller discards measurements if competing CPU activity appears and
leaves existing fleet coordinators alone.

Owned remote work directory: `/tmp/hdr-os-o3-fleet-20261001`.
The per-machine `results/status.json`, `results/events.jsonl` and controller.log
record progress. Connection details remain outside this public repository.
Do not launch a second audit into that directory while its owner lock is held.

Remaining: complete alternating GCC/Clang runs, Redis-shaped probes at both
revisions, hardware profiles, then collect and analyze size/performance results.
No source or build default has been accepted; upstream review is still a
separate gate. See [protocol](PLAN.md) and [input hashes](inputs.json).
