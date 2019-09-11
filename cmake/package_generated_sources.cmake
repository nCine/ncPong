# Has to be included after package_get_version.cmake

set(GENERATED_SOURCE_DIR "${CMAKE_BINARY_DIR}/generated")
set(GENERATED_INCLUDE_DIR "${GENERATED_SOURCE_DIR}/include")

# Version strings
if(GIT_EXECUTABLE)
	message(STATUS "Exporting git version information to C strings")
endif()

set(VERSION_H_FILE "${GENERATED_INCLUDE_DIR}/version.h")
set(VERSION_CPP_FILE "${GENERATED_SOURCE_DIR}/version.cpp")
if(EXISTS ${VERSION_H_FILE})
	file(REMOVE ${VERSION_H_FILE})
endif()
if(EXISTS ${VERSION_CPP_FILE})
	file(REMOVE ${VERSION_CPP_FILE})
endif()

set(VERSION_STRUCT_NAME "VersionStrings")
set(VERSION_STRING_NAME "Version")
set(REVCOUNT_STRING_NAME "GitRevCount")
set(SHORTHASH_STRING_NAME "GitShortHash")
set(LASTCOMMITDATE_STRING_NAME "GitLastCommitDate")
set(BRANCH_STRING_NAME "GitBranch")
set(TAG_STRING_NAME "GitTag")
set(COMPILATION_DATE_STRING_NAME "CompilationDate")
set(COMPILATION_TIME_STRING_NAME "CompilationTime")

get_filename_component(VERSION_H_FILENAME ${VERSION_H_FILE} NAME)
file(APPEND ${VERSION_H_FILE} "#ifndef PACKAGE_VERSION\n")
file(APPEND ${VERSION_H_FILE} "#define PACKAGE_VERSION\n\n")
file(APPEND ${VERSION_H_FILE} "struct ${VERSION_STRUCT_NAME}\n{\n")
file(APPEND ${VERSION_CPP_FILE} "#include \"${VERSION_H_FILENAME}\"\n\n")

if(GIT_EXECUTABLE)
	target_compile_definitions(${PACKAGE_EXE_NAME} PRIVATE "WITH_GIT_VERSION")
	list(APPEND ANDROID_GENERATED_FLAGS WITH_GIT_VERSION)

	file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${VERSION_STRING_NAME};\n")
	file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${VERSION_STRING_NAME} = \"${PACKAGE_VERSION}\";\n")
	file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${REVCOUNT_STRING_NAME};\n")
	file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${REVCOUNT_STRING_NAME} = \"${GIT_REV_COUNT}\";\n")
	file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${SHORTHASH_STRING_NAME};\n")
	file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${SHORTHASH_STRING_NAME} = \"${GIT_SHORT_HASH}\";\n")
	file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${LASTCOMMITDATE_STRING_NAME};\n")
	file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${LASTCOMMITDATE_STRING_NAME} = \"${GIT_LAST_COMMIT_DATE}\";\n")
	file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${BRANCH_STRING_NAME};\n")
	file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${BRANCH_STRING_NAME} = \"${GIT_BRANCH_NAME}\";\n")
	file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${TAG_STRING_NAME};\n")
	if(NOT GIT_NO_TAG)
		file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${TAG_STRING_NAME} = \"${GIT_TAG_NAME}\";\n")
	else()
		file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${TAG_STRING_NAME} = \"\";\n")
	endif()
endif()
file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${COMPILATION_DATE_STRING_NAME};\n")
file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${COMPILATION_DATE_STRING_NAME} = __DATE__;\n")
file(APPEND ${VERSION_H_FILE} "\tstatic char const * const ${COMPILATION_TIME_STRING_NAME};\n")
file(APPEND ${VERSION_CPP_FILE} "char const * const ${VERSION_STRUCT_NAME}::${COMPILATION_TIME_STRING_NAME} = __TIME__;\n")

file(APPEND ${VERSION_H_FILE} "};\n\n")
file(APPEND ${VERSION_H_FILE} "#endif")

list(APPEND HEADERS ${VERSION_H_FILE})
list(APPEND GENERATED_SOURCES ${VERSION_CPP_FILE})

if(WIN32 AND EXISTS ${PACKAGE_DATA_DIR}/icons/icon.ico)
	message(STATUS "Writing a resource file for executable icon")

	set(RESOURCE_RC_FILE "${GENERATED_SOURCE_DIR}/resource.rc")
	file(WRITE ${RESOURCE_RC_FILE} "IDI_ICON1 ICON DISCARDABLE \"icon.ico\"")
	file(COPY ${PACKAGE_DATA_DIR}/icons/icon.ico DESTINATION ${GENERATED_INCLUDE_DIR})
	target_sources(${PACKAGE_EXE_NAME} PRIVATE ${RESOURCE_RC_FILE})
endif()

if(WIN32)
	message(STATUS "Writing a version info resource file")

	set(FILEVERSION_THIRD_WORD ${PACKAGE_PATCH_VERSION})
	if(DEFINED GIT_REV_COUNT)
		set(FILEVERSION_THIRD_WORD ${GIT_REV_COUNT})
	endif()

	set(VERSION_RC_FILE "${GENERATED_SOURCE_DIR}/version.rc")
	file(WRITE ${VERSION_RC_FILE}
"#include \"winresrc.h\"\n\
\n\
LANGUAGE LANG_ENGLISH, SUBLANG_ENGLISH_US\n\
\n\
VS_VERSION_INFO VERSIONINFO\n\
 FILEVERSION ${PACKAGE_MAJOR_VERSION},${PACKAGE_MINOR_VERSION},${FILEVERSION_THIRD_WORD},0\n\
 PRODUCTVERSION ${PACKAGE_MAJOR_VERSION},${PACKAGE_MINOR_VERSION},${FILEVERSION_THIRD_WORD},0\n\
 FILEFLAGSMASK VS_FFI_FILEFLAGSMASK\n\
#ifdef PACAKGE_DEBUG\n\
 FILEFLAGS VS_FF_DEBUG\n\
#else\n\
 FILEFLAGS 0x0L\n\
#endif\n\
 FILEOS VOS_NT_WINDOWS32\n\
 FILETYPE VFT_APP\n\
 FILESUBTYPE VFT2_UNKNOWN\n\
BEGIN\n\
    BLOCK \"StringFileInfo\"\n\
    BEGIN\n\
        BLOCK \"040904b0\"\n\
        BEGIN\n\
            VALUE \"CompanyName\", \"${PACKAGE_VENDOR}\\0\"\n\
            VALUE \"FileDescription\", \"${PACKAGE_DESCRIPTION}\\0\"\n\
            VALUE \"FileVersion\", \"${PACKAGE_MAJOR_VERSION},${PACKAGE_MINOR_VERSION},${FILEVERSION_THIRD_WORD},0\\0\"\n\
            VALUE \"InternalName\", \"${PACKAGE_NAME}\\0\"\n\
            VALUE \"LegalCopyright\", \"${PACKAGE_COPYRIGHT}\\0\"\n\
            VALUE \"OriginalFilename\", \"${PACKAGE_EXE_NAME}.exe\\0\"\n\
            VALUE \"ProductName\", \"${PACKAGE_NAME}\\0\"\n\
            VALUE \"ProductVersion\", \"${PACKAGE_VERSION} (${GIT_BRANCH_NAME})\\0\"\n\
        END\n\
    END\n\
    BLOCK \"VarFileInfo\"\n\
    BEGIN\n\
        VALUE \"Translation\", 0x409, 1200\n\
    END\n\
END")
	list(APPEND GENERATED_SOURCES ${VERSION_RC_FILE})
endif()
