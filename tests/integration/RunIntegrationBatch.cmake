file(REMOVE_RECURSE "${TEST_CONFIG_PARENT}")
file(MAKE_DIRECTORY "${TEST_CONFIG_PARENT}")
file(COPY "${ES_CONFIG}" DESTINATION "${TEST_CONFIG_PARENT}")

execute_process(
	COMMAND $ENV{ES_INTEGRATION_PREFIX} "${ES}" --config "${TEST_CONFIG}" --resources "${RESOURCE_PATH}" --tq-threads 2 --tests "${TEST_LIST}"
	COMMAND_ECHO STDOUT
	RESULT_VARIABLE TEST_RESULT
)

if(TEST_RESULT)
	message(FATAL_ERROR "Integration test batch failed with '${TEST_RESULT}'.")
endif()
