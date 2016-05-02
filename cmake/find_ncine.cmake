if(MSVC)
	get_filename_component(NCINE_REGISTRY_PATH "[HKEY_LOCAL_MACHINE\\SOFTWARE\\nCine]" ABSOLUTE)
	if(IS_DIRECTORY ${NCINE_REGISTRY_PATH})
		set(NCINE_INSTALL_DIR ${NCINE_REGISTRY_PATH})
		file(TO_CMAKE_PATH ${NCINE_INSTALL_DIR} NCINE_INSTALL_DIR)
		message(STATUS "nCine installation path: ${NCINE_INSTALL_DIR}")
		find_package(nCine QUIET PATHS ${NCINE_INSTALL_DIR} NO_DEFAULT_PATH)
		set(NCINE_ANDROID_DIR ${NCINE_INSTALL_DIR}/android)
	endif()
elseif(APPLE)
	set(NCINE_BUNDLE_APP "/Applications/nCine.app")
	if(IS_DIRECTORY ${NCINE_BUNDLE_APP})
		message(STATUS "nCine bundle app: ${NCINE_BUNDLE_APP}")
		set(NCINE_INSTALL_DIR "${NCINE_BUNDLE_APP}/Contents/Resources")
		find_package(nCine PATHS ${NCINE_INSTALL_DIR} NO_DEFAULT_PATH)
		set(NCINE_ANDROID_DIR ${NCINE_INSTALL_DIR}/android)
	endif()
else()
	find_package(nCine QUIET)
	get_filename_component(NCINE_SHARE_DIR ${NCINE_MAIN_CPP} DIRECTORY)
	set(NCINE_ANDROID_DIR ${NCINE_SHARE_DIR}/android)
endif()

if(NOT nCine_FOUND)
	message(STATUS "nCine installation not found")
	get_filename_component(PARENT_SOURCE_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)

	set(NCINE_SRC_DIR ${PARENT_SOURCE_DIR}/nCine CACHE PATH "Path to the nCine source directory")
	set(NCINE_BUILD_DIR ${PARENT_SOURCE_DIR}/nCine-build CACHE PATH "Path to the nCine build directory")
	set(NCINE_ANDROID_DIR ${NCINE_BUILD_DIR}/android)
	set(NCINE_EXTERNAL_DIR ${PARENT_SOURCE_DIR}/nCine-external CACHE PATH "Path to the nCine external libraries directory")

	if(IS_DIRECTORY ${NCINE_SRC_DIR})
		message(STATUS "nCine source directory: ${NCINE_SRC_DIR}")
	else()
		message(FATAL_ERROR "nCine source directory not found at: ${NCINE_SRC_DIR}")
	endif()

	if(IS_DIRECTORY ${NCINE_BUILD_DIR})
		message(STATUS "nCine binary directory: ${NCINE_BUILD_DIR}")
	else()
		message(FATAL_ERROR "nCine binary directory not found at: ${NCINE_BUILD_DIR}")
	endif()

	if(NOT EXISTS ${NCINE_BUILD_DIR}/generated/shader_strings.cpp)
		set(NCINE_SHADERS_DIR ${NCINE_SRC_DIR}/src/shaders)
	endif()
	find_path(NCINE_INCLUDE_DIR Application.h PATH_SUFFIXES include PATHS ${NCINE_SRC_DIR})
	find_library(NCINE_LIBRARY ncine PATH_SUFFIXES Debug Release PATHS ${NCINE_BUILD_DIR})
	find_file(NCINE_MAIN_CPP main.cpp PATHS ${NCINE_SRC_DIR}/tests)
	set(nCine_FOUND 1)
endif()

message(STATUS "nCine library: ${NCINE_LIBRARY}")
message(STATUS "nCine include directory: ${NCINE_INCLUDE_DIR}")
message(STATUS "nCine main.cpp: ${NCINE_MAIN_CPP}")

if(NCPONG_PREPARE_ANDROID)
	if(IS_DIRECTORY ${NCINE_ANDROID_DIR})
		message(STATUS "nCine Android directory: ${NCINE_ANDROID_DIR}")
	else()
		message(WARNING "nCine Android directory not found at: ${NCINE_ANDROID_DIR}")
	endif()
endif()

if(MSVC)
	if(NCINE_INSTALL_DIR)
		set(BINDIR ${NCINE_INSTALL_DIR}/bin)
		set(NCINE_DLL ${BINDIR}/ncine.dll)
		if(NOT EXISTS ${NCINE_DLL})
			message(FATAL_ERROR "nCine DLL not found at: ${NCINE_DLL}")
		endif()
	else()
		if(MSVC_C_ARCHITECTURE_ID MATCHES 64 OR MSVC_CXX_ARCHITECTURE_ID MATCHES 64)
			set(BINDIR "${NCINE_EXTERNAL_DIR}/bin/x64")
		else()
			set(BINDIR "${NCINE_EXTERNAL_DIR}/bin/x86")
		endif()
	endif()

	if(IS_DIRECTORY ${BINDIR})
		message(STATUS "nCine MSVC DLLs directory: ${BINDIR}")
	else()
		message(FATAL_ERROR "nCine MSVC DLLs directory not found at: ${BINDIR}")
	endif()
elseif(APPLE)
	if(NCINE_INSTALL_DIR)
		set(FRAMEWORKS_DIR ${NCINE_BUNDLE_APP}/Contents/Frameworks)
	else()
		set(FRAMEWORKS_DIR ${NCINE_EXTERNAL_DIR})
	endif()

	if(IS_DIRECTORY ${FRAMEWORKS_DIR})
		message(STATUS "nCine frameworks directory: ${FRAMEWORKS_DIR}")
	else()
		message(FATAL_ERROR "nCine frameworks directory not found at: ${FRAMEWORKS_DIR}")
	endif()
elseif(MINGW)
	set(NCINE_DLL ${NCINE_LIBRARY})
endif()

if (DEFINED NCINE_DLL)
	message(STATUS "nCine DLL: ${NCINE_DLL}")
endif()
