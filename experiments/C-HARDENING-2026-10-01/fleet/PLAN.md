# Native fleet validation: Os versus O3

The primary revision is PR #158 at
`d21d0843b492023077553b3eba26b3efa16c15f5`, verified against GitHub's PR head.
This includes the recording-path fix chosen after the earlier local audit.
The older `bcb5c1f78f3ee50aaf33fb4898eb1c6bab73de13` is a supplemental
reference, not the proposed release tip.

Run on separate idle AWS Intel x86_64, AMD x86_64 and ARM64 machines. Keep
connection details outside the public repository. Preserve fleet coordinators;
wait while busy and discard/retry our own measurements if competing CPU work
appears. Pin each same-machine comparison to one core and check its SMT sibling.

For each machine:

1. Build current/reference Os/O3 libraries with GCC 13 and Clang 18, keeping
   caller compilation fixed. Run all five CTest tests for every configuration.
   Preserve both immutable benchmark driver files byte-for-byte.
2. Build the Redis/Valkey consumer snapshots with the current HDR source and
   preserved allocator adapters/iterator extension. Measure Os/O3 and each
   combined with HDR-private visibility and section garbage collection, on
   actual server and benchmark executables. Consumer size builds use GCC;
   core timing/correctness builds cover both compilers.
3. Run the full unchanged write/read benchmark drivers through run-bench.sh
   in alternating Os/O3/O3/Os order per compiler at the current revision.
   Add samples if the repeated invocations show excessive variation.
4. Run the bounded Redis-shaped probe for both revisions and compilers, with
   alternating flag order. Do not substitute these for the full referee runs.
5. Sample both paths with hardware counters, using the same compiled drivers.
   Profile intervals may be bounded externally; benchmark runs are complete.
6. Collect source/build hashes, flags, test results, timing logs, sizes and
   sanitized profiles. Separate within-machine flag ratios from differences
   between architectures; do not compare absolute rates across different hosts
   as if they were an optimization result.

Follow-up checks prompted by the measurements:

- Run the existing allocator/iterator contract fixture against every actual
  measured consumer archive. Verify emitted caller flags, independent of
  checkout paths containing the strings `-Os`/`-O3`.
- Time a fixed caller against actual GCC Redis HDR archives in both orders:
  ordinary Os/O3 and private+GC Os/O3. These are bounded supplemental probes,
  not substitutes for the immutable referee or end-to-end server benchmarks.
- The Intel private-O3 probe showed a substantial recording slowdown despite
  byte-identical recording instructions in the diagnostic executables. Check
  ordinary/private O3 again with full unchanged drivers, in opposite order,
  while ARM's original runs finish. Keep this diagnostic separate from the
  primary Os/O3 comparison and do not silently promote the smaller build.

These runs validate the compiler tradeoff. They do not imply an end-to-end
Redis throughput improvement or replace the required upstream review.
