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

echo "TAP version 13"
echo "# Endless Sky macOS performance scenario runner"
echo "# executable: ${ES_EXEC_PATH}"
echo "# resources: ${RESOURCES}"
echo "# filter: ${TEST_FILTER}"

if [ ! -x "${ES_EXEC_PATH}" ]; then
	echo "1..1"
	echo "not ok 1 Endless Sky executable not found or not executable"
	exit 1
fi

if [ ! -d "${ES_CONFIG_TEMPLATE_PATH}" ]; then
	echo "1..1"
	echo "not ok 1 integration config template not found"
	exit 1
fi

IFS=$'\n'
TESTS=($("${ES_EXEC_PATH}" --tests --resources "${RESOURCES}" --config "${ES_CONFIG_TEMPLATE_PATH}" | grep -E "${TEST_FILTER}" || true))
unset IFS

NUM_TOTAL=${#TESTS[@]}
if [ ${NUM_TOTAL} -eq 0 ]; then
	echo "1..1"
	echo "not ok 1 no tests matched filter"
	exit 1
fi

echo "1..${NUM_TOTAL}"

NUM_FAILED=0
for ((i = 0; i < NUM_TOTAL; ++i)); do
	TEST_NAME="${TESTS[$i]}"
	TEST_NUMBER=$((i + 1))
	TEST_CONFIG=$(mktemp -d "${TMPDIR:-/tmp}/endless-sky-perf.XXXXXX")
	TEST_OUTPUT="${TEST_CONFIG}/output.txt"

	cp -R "${ES_CONFIG_TEMPLATE_PATH}/." "${TEST_CONFIG}"

	START=$(now_seconds)
	if "${ES_EXEC_PATH}" --resources "${RESOURCES}" --config "${TEST_CONFIG}" --test "${TEST_NAME}" > "${TEST_OUTPUT}" 2>&1; then
		END=$(now_seconds)
		echo "ok ${TEST_NUMBER} ${TEST_NAME}"
		echo "# elapsed_ms: $(elapsed_ms "${START}" "${END}")"
		rm -rf "${TEST_CONFIG}"
	else
		END=$(now_seconds)
		NUM_FAILED=$((NUM_FAILED + 1))
		echo "not ok ${TEST_NUMBER} ${TEST_NAME}"
		echo "# elapsed_ms: $(elapsed_ms "${START}" "${END}")"
		echo "# temporary_config: ${TEST_CONFIG}"
		sed 's/^/#     /' "${TEST_OUTPUT}"
	fi
done

echo "# tests ${NUM_TOTAL}"
echo "# failed ${NUM_FAILED}"

if [ ${NUM_FAILED} -ne 0 ]; then
	exit 1
fi