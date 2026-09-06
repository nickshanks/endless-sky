#!/bin/bash
set -euo pipefail

function usage() {
	echo "Usage: $0 <endless-sky-executable> <resources-path> [benchmark-name] [benchmark-ticks] [seed] [repeats] [warmups]"
}

if [ $# -lt 2 ] || [ $# -gt 7 ]; then
	usage
	exit 1
fi

ES_EXEC_PATH="$1"
RESOURCES="$2"
BENCHMARK_NAME="${3:-fast-forward}"
BENCHMARK_TICKS="${4:-3600}"
BENCHMARK_SEED="${5:-1}"
BENCHMARK_REPEATS="${6:-5}"
BENCHMARK_WARMUPS="${7:-1}"
ES_CONFIG_TEMPLATE_PATH="${RESOURCES}/tests/integration/config"
export MallocNanoZone=0

if [ ! -x "${ES_EXEC_PATH}" ]; then
	echo "Endless Sky executable not found or not executable: ${ES_EXEC_PATH}" >&2
	exit 1
fi

if [ ! -d "${ES_CONFIG_TEMPLATE_PATH}" ]; then
	echo "Integration config template not found: ${ES_CONFIG_TEMPLATE_PATH}" >&2
	exit 1
fi

TEST_CONFIG=$(mktemp -d "${TMPDIR:-/tmp}/endless-sky-benchmark.XXXXXX")
trap 'rm -rf "${TEST_CONFIG}"' EXIT

cp -R "${ES_CONFIG_TEMPLATE_PATH}/." "${TEST_CONFIG}"

"${ES_EXEC_PATH}" \
	--resources "${RESOURCES}" \
	--config "${TEST_CONFIG}" \
	--benchmark "${BENCHMARK_NAME}" \
	--benchmark-ticks "${BENCHMARK_TICKS}" \
	--benchmark-seed "${BENCHMARK_SEED}" \
	--benchmark-repeats "${BENCHMARK_REPEATS}" \
	--benchmark-warmups "${BENCHMARK_WARMUPS}"
