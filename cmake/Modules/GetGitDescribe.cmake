# Gets Git repository version info and sets corresponding variables
function(get_git_describe _var)
	if(NOT GIT_FOUND)
		find_package(Git QUIET)
	endif()
	if(NOT GIT_FOUND)
		set(${_var} "unknown-version" PARENT_SCOPE)
		return()
	endif()
	
	execute_process(COMMAND ${GIT_EXECUTABLE} describe --tags --dirty --match "v[0-9]*.[0-9]*.[0-9]*"
		WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
		OUTPUT_VARIABLE GIT_DESCRIBE_VERSION
		RESULT_VARIABLE GIT_DESCRIBE_RESULT
		ERROR_VARIABLE GIT_DESCRIBE_ERROR
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)

	if(GIT_DESCRIBE_RESULT EQUAL 0)
		set(${_var} "${GIT_DESCRIBE_VERSION}" PARENT_SCOPE)
	else()
		execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
			WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
			OUTPUT_VARIABLE GIT_REV
			RESULT_VARIABLE GIT_REV_RESULT
			ERROR_VARIABLE GIT_REV_ERROR
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		if(GIT_REV_RESULT EQUAL 0)
			set(${_var} "git-${GIT_REV}" PARENT_SCOPE)
		else()
			set(${_var} "unknown-version" PARENT_SCOPE)
		endif()
	endif()
endfunction()

# Sets package metadata using Git version info
macro(set_pkg_metadata)
	get_git_describe(PROJECT_VERSION_STRING)
	message(STATUS "Configuring Sandboxy ${PROJECT_VERSION_STRING}")

	if(NOT PROJECT_NAME)
		set(PROJECT_NAME "sandboxy")
	endif()
	if(NOT PROJECT_NAME_CAPITALIZED)
		set(PROJECT_NAME_CAPITALIZED "Sandboxy")
	endif()
	
	string(REGEX MATCH "^v([0-9]+)\.([0-9]+)\.([0-9]+)" VERSION_MATCH ${PROJECT_VERSION_STRING})
	if(VERSION_MATCH)
		set(VERSION_MAJOR ${CMAKE_MATCH_1})
		set(VERSION_MINOR ${CMAKE_MATCH_2}) 
		set(VERSION_PATCH ${CMAKE_MATCH_3})
	else()
		set(VERSION_MAJOR 1)
		set(VERSION_MINOR 0)
		set(VERSION_PATCH 0)
	endif()

	set(VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
	if(VERSION_EXTRA)
		set(VERSION_STRING "${VERSION_STRING}-${VERSION_EXTRA}")
	endif()
	
	if(DEVELOPMENT_BUILD)
		set(VERSION_STRING "${VERSION_STRING}-dev")
	endif()

	if(CMAKE_BUILD_TYPE STREQUAL Debug)
		set(VERSION_STRING "${VERSION_STRING}-debug") 
	endif()
endmacro()