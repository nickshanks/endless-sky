# Performance Test Harness

This directory contains local performance-test helpers. The current harness is
macOS-oriented and runs the existing headless integration-test path directly,
without Xvfb.

## Running

From the repository root:

```sh
./tests/performance/run_tests_macos.sh ./build/macos-arm/Debug/endless-sky . "Afterburner-flight"
```

Arguments are:

1. Path to the `endless-sky` executable.
2. Path to the repository resources directory.
3. Optional regular expression used to select tests from `--tests`.

The script emits TAP version 13 output and includes elapsed wall-clock time for
each selected scenario as diagnostic lines.

## Current Scope

This is a prerequisite harness, not a stable benchmark suite yet. It measures the
whole process run for each selected integration scenario, including data loading
and test setup. That is useful for proving that command-line playable scenarios
can run on macOS, but it is not yet precise enough to gate engine tick
performance.

Future benchmark-specific tests should report in-process metrics such as engine
calculation time, draw-preparation time, simulated ticks, and ticks per second.