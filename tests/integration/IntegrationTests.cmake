set(ES_CONFIG "${CMAKE_CURRENT_SOURCE_DIR}/integration/config")
set(INTEGRATION_BATCH_COUNT 4)

# Get the test names once while generating the CTest manifest, then distribute
# independent cases round-robin across a small number of game processes.
execute_process(
	COMMAND ${ES} --config "${ES_CONFIG}" --tests
	OUTPUT_VARIABLE INTEGRATION_TESTS
	ERROR_QUIET
)
string(STRIP "${INTEGRATION_TESTS}" INTEGRATION_TESTS)
string(REPLACE "\n" ";" INTEGRATION_TESTS_LIST "${INTEGRATION_TESTS}")

list(LENGTH INTEGRATION_TESTS_LIST INTEGRATION_TEST_COUNT)
if(INTEGRATION_TEST_COUNT LESS INTEGRATION_BATCH_COUNT)
	set(INTEGRATION_BATCH_COUNT ${INTEGRATION_TEST_COUNT})
endif()

math(EXPR LAST_BATCH "${INTEGRATION_BATCH_COUNT} - 1")
foreach(batch RANGE ${LAST_BATCH})
	file(REMOVE "${BINARY_PATH}/integration-tests-${batch}.txt")
endforeach()

math(EXPR LAST_TEST_INDEX "${INTEGRATION_TEST_COUNT} - 1")
foreach(test_index RANGE ${LAST_TEST_INDEX})
	list(GET INTEGRATION_TESTS_LIST ${test_index} test)
	math(EXPR batch "${test_index} % ${INTEGRATION_BATCH_COUNT}")
	file(APPEND "${BINARY_PATH}/integration-tests-${batch}.txt" "${test}\n")
endforeach()

set(TEST_SCRIPT "")
foreach(batch RANGE ${LAST_BATCH})
	set(TEST_CONFIG_PARENT "${BINARY_PATH}/integration-config-${batch}")
	set(TEST_CONFIG "${TEST_CONFIG_PARENT}/config")
	set(TEST_LIST "${BINARY_PATH}/integration-tests-${batch}.txt")
	string(APPEND TEST_SCRIPT
"add_test(\"integration-${batch}\" \"${CMAKE_COMMAND}\"
	\"-DES=${ES}\"
	\"-DTEST_CONFIG_PARENT=${TEST_CONFIG_PARENT}\"
	\"-DTEST_CONFIG=${TEST_CONFIG}\"
	\"-DTEST_LIST=${TEST_LIST}\"
	\"-DRESOURCE_PATH=${RESOURCE_PATH}\"
	\"-DES_CONFIG=${ES_CONFIG}\"
	-P \"${CMAKE_CURRENT_SOURCE_DIR}/integration/RunIntegrationBatch.cmake\")
set_tests_properties(\"integration-${batch}\" PROPERTIES
	WORKING_DIRECTORY \"${CMAKE_CURRENT_SOURCE_DIR}\"
	TIMEOUT 600
	LABELS integration)
")
endforeach()

file(WRITE "${BINARY_PATH}/IntegrationTests_tests.cmake" "${TEST_SCRIPT}")
