#!/bin/bash
set -euo pipefail

function usage() {
	echo "Usage: $0 <endless-sky-executable> <resources-path> [test-filter-regex]"
}

function now_seconds() {
	perl -MTime::HiRes=time -e 'printf "%.6f\n", time'
}

function elapsed_ms() {
	perl -e 'printf "%.3f", 1000 * ($ARGV[1] - $ARGV[0])' "$1" "$2"
}

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
	usage
	exit 1
fi

ES_EXEC_PATH="$1"
RESOURCES="$2"
TEST_FILTER="${3:-.}"
ES_CONFIG_TEMPLATE_PATH="${RESOURCES}/tests/integration/config"
export MallocNanoZone=0

echo "TAP version 14"
echo "# Endless Sky macOS performance scenario runner"
echo "# executable: ${ES_EXEC_PATH}"
echo "# resources: ${RESOURCES}"
echo "# filter: ${TEST_FILTER}"

if [ ! -f "${ES_EXEC_PATH}" ]; then
	echo "1..0"
	echo "Bail out! Endless Sky executable not found."
	exit 1
fi

if [ ! -x "${ES_EXEC_PATH}" ]; then
	echo "1..0"
	echo "Bail out! Endless Sky executable not executable."
	exit 1
fi

if [ ! -d "${ES_CONFIG_TEMPLATE_PATH}" ]; then
	echo "1..0"
	echo "Bail out! Integration config template not found."
	exit 1
fi

TEST_CONFIG=$(mktemp -d "${TMPDIR:-/tmp}/endless-sky-perf.XXXXXX")
cp -R "${ES_CONFIG_TEMPLATE_PATH}/." "${TEST_CONFIG}"
GAME_PID=""
cleanup() {
	if [ -n "${GAME_PID}" ]; then
		kill "${GAME_PID}" 2>/dev/null || true
		wait "${GAME_PID}" 2>/dev/null || true
	fi
	rm -rf "${TEST_CONFIG}"
}
trap cleanup EXIT
trap 'exit 143' HUP INT TERM

SUITE_START=$(now_seconds)
if [ "${TEST_FILTER}" = "." ]; then
	echo "# Running all integration tests in one game process."
	TEST_ARGUMENT=all
else
	echo "# Discovering integration tests matching: ${TEST_FILTER}"
	TESTS=()
	while IFS= read -r test_name; do
		TESTS+=("${test_name}")
	done < <("${ES_EXEC_PATH}" --tests --resources "${RESOURCES}" --config "${TEST_CONFIG}" | grep -E "${TEST_FILTER}" || true)

	NUM_TOTAL=${#TESTS[@]}
	if [ ${NUM_TOTAL} -eq 0 ]; then
		echo "1..0"
		echo "Bail out! No tests matched filter."
		exit 1
	fi

	TEST_LIST_FILE="${TEST_CONFIG}/test-list.txt"
	printf '%s\n' "${TESTS[@]}" > "${TEST_LIST_FILE}"
	TEST_ARGUMENT="${TEST_LIST_FILE}"
fi

"${ES_EXEC_PATH}" --resources "${RESOURCES}" --config "${TEST_CONFIG}" --tests "${TEST_ARGUMENT}" &
GAME_PID=$!
if wait "${GAME_PID}"; then
	GAME_PID=""
	SUITE_END=$(now_seconds)
	echo "# integration_suite_elapsed_ms: $(elapsed_ms "${SUITE_START}" "${SUITE_END}")"
else
	GAME_PID=""
	SUITE_END=$(now_seconds)
	echo "# integration_suite_elapsed_ms: $(elapsed_ms "${SUITE_START}" "${SUITE_END}")"
	exit 1
fi
