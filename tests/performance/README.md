# Performance Test Harness

This directory contains local performance-test helpers. The current harness is
macOS-oriented and runs the existing headless integration-test path directly,
without Xvfb.

## Running

From the repository root:

```sh
./tests/performance/run_tests_macos.sh ./build/macos-arm/Release/endless-sky . "Afterburner-flight"
./tests/performance/run_benchmarks_macos.sh ./build/macos-arm/Release/endless-sky . fast-forward 3600 1
```

`run_tests_macos.sh` arguments are:

1. Path to the `endless-sky` executable.
2. Path to the repository resources directory.
3. Optional regular expression used to select tests from `--tests`.

`run_benchmarks_macos.sh` arguments are:

1. Path to the `endless-sky` executable.
2. Path to the repository resources directory.
3. Optional benchmark name.
4. Optional baseline tick count.
5. Optional random seed.

`run_tests_macos.sh` emits TAP version 13 output and includes elapsed wall-clock
time for each selected scenario as diagnostic lines. `run_benchmarks_macos.sh`
runs in-process headless benchmarks and prints JSON metrics.

`run_benchmarks_macos.sh` accepts optional benchmark name, tick count, and random
seed arguments. It defaults to `fast-forward`, `3600`, and seed `1`. The
benchmark resets the random seed before each measured sub-run so the normal and
fast-forward paths begin from the same random stream.

Both scripts set `MallocNanoZone=0` to suppress macOS's harmless `nano zone
abandoned due to inability to reserve vm space` allocator warning. That warning
is emitted by Darwin's malloc implementation before the game starts doing useful
work; it is not a game bug.

## Current Scope

This is an early local harness, not a stable benchmark suite yet. The scenario
runner measures the whole process run for each selected integration scenario,
including data loading and test setup.

The `fast-forward` benchmark injects the `Three Earthly Barges Save` integration
save, launches from Earth, and measures serialized engine ticks in two modes:
normal ticks with draw preparation every tick, a same-simulated-duration normal
run, and fast-forward ticks with draw preparation every third tick. It reports
simulated ticks, draw-preparation ticks, wall time, engine calculation time, wait
time, and ticks per second.

Use Release builds for meaningful comparisons. Debug and sanitizer builds are
useful for validating that the harness runs, but they heavily distort absolute
performance.
