message(FATAL_ERROR "FAILED!")
function(_version_tag_ctransform VTAG TAGOUT)
	foreach(i RANGE 0 61 2)
		string(SUBSTRING ${VTAG} ${i} 2 VPART)
		string(APPEND ${TAGOUT} "0x${VPART},")
	endforeach()
	string(SUBSTRING ${VTAG} 62 2 VPART)
	string(APPEND ${TAGOUT} "0x${VPART}")
endfunction()

function(_version_git_tag VAROUT GROOT)
	execute_process(COMMAND git rev-parse --short=8 HEAD
		WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
		OUTPUT_VARIABLE VARTMP
	)
	string(LENGTH "${VARTMP}" VRLEN)
	if(${VRLEN} LESS 8)
		set(VARTMP "00000000")
	endif()
	
	string(STRIP "${VARTMP}" VARTMP)
	set(${VAROUT} ${VARTMP} PARENT_SCOPE)
endfunction()

function(_version_git_branch VAROUT GROOT)
	execute_process(COMMAND git rev-parse --abbrev-ref HEAD
		WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
		OUTPUT_VARIABLE VARTMP
	)
	string(LENGTH "${VARTMP}" VRLEN)
	if(${VRLEN} LESS 8)
		set(VARTMP "no-git-repo")
	endif()
	
	string(STRIP "${VARTMP}" VARTMP)
	set(${VAROUT} ${VARTMP} PARENT_SCOPE)
endfunction()

function(_version_git_fullref VAROUT GROOT)
	execute_process(COMMAND git rev-parse --symbolic-full-name HEAD
		WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
		OUTPUT_VARIABLE VARTMP
	)
	string(LENGTH "${VARTMP}" VRLEN)
	if(${VRLEN} LESS 8)
		set(VARTMP "")
	endif()
	
	string(STRIP "${VARTMP}" VARTMP)
	set(${VAROUT} ${VARTMP} PARENT_SCOPE)
endfunction()

if(VERSION_INTERNAL_RUN_AS_SCRIPT)
	set(VERSION_MAJOR 0)
	set(VERSION_MINOR 0)
	set(VERSION_PATCH 0)
	include(${VF})
	_version_git_tag(VERSION_REVISION ${GROOT})
	string(SHA256 VERSION_TAG "${NAME}_version_tag")
	foreach(i RANGE 0 61 2)
		string(SUBSTRING ${VERSION_TAG} ${i} 2 VPART)
		string(APPEND TAGOUT "0x${VPART},")
	endforeach()
	string(SUBSTRING ${VERSION_TAG} 62 2 VPART)
	string(APPEND TAGOUT "0x${VPART}")
	set(VF_C_CONTENTS
"#include \"${NAME}_version.h\"
const struct { unsigned char tag[32]; ${NAME}_vdtype_t vers; } ${NAME}_version_data={\n\
\t{${TAGOUT}},\n\
\t{${VERSION_MAJOR},${VERSION_MINOR},${VERSION_PATCH},0x${VERSION_REVISION}}\n\
};\n\
const ${NAME}_vdtype_t* const ${NAME}_version_ptr=&(${NAME}_version_data.vers);\n\
const unsigned char* const ${NAME}_tag_ptr=${NAME}_version_data.tag;\n\
")
	set(VF_TXT_CONTENTS "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}.${VERSION_REVISION}")
	set(VF_H_CONTENTS
"#ifndef ${NAME}_VERSION_H
#define ${NAME}_VERSION_H
#ifdef __cplusplus
extern \"C\" {
#endif
typedef struct {unsigned long major,minor,patch,revision; } ${NAME}_vdtype_t;
extern const ${NAME}_vdtype_t* const ${NAME}_version_ptr;\n\
extern const unsigned char* const ${NAME}_tag_ptr;\n\
#ifdef __cplusplus
}
#endif
#endif
")

	file(WRITE "${VERSION_CFILE}" "${VF_C_CONTENTS}")
	file(WRITE "${VERSION_HFILE}" "${VF_H_CONTENTS}")
	file(WRITE "${VERSION_TXTFILE}" "${VF_TXT_CONTENTS}")
	if(CALLBACKFILE)
		include(${CALLBACKFILE})
	endif()
else()


set(VERSION_INTERNAL_VERSION_LOCATION ${CMAKE_CURRENT_LIST_FILE}) 

function(version_add_target NAME VERSIONFILE GROOT)
set(VERSION_MAJOR 0)
set(VERSION_MINOR 0)
set(VERSION_PATCH 0)
set(VERSION_REVISION 0)
include(${VERSIONFILE})
_version_git_tag(VERSION_REVISION ${GROOT})
_version_git_branch(VERSION_BRANCH ${GROOT})
_version_git_fullref(GIT_VERSION_FULLREF ${GROOT})
set(VERSION_FULL "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}.${VERSION_REVISION}")
set(VERSION_MOST "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

set(${NAME}_VERSION_MAJOR ${VERSION_MAJOR} PARENT_SCOPE)
set(${NAME}_VERSION_MINOR ${VERSION_MINOR} PARENT_SCOPE)
set(${NAME}_VERSION_PATCH ${VERSION_PATCH} PARENT_SCOPE)
set(${NAME}_VERSION_REVISION ${VERSION_REVISION} PARENT_SCOPE)
set(${NAME}_VERSION_TWEAK ${VERSION_REVISION} PARENT_SCOPE)
set(${NAME}_VERSION_FULL ${VERSION_FULL} PARENT_SCOPE)
set(${NAME}_VERSION_MOST ${VERSION_MOST} PARENT_SCOPE)
set(${NAME}_VERSION_BRANCH ${VERSION_BRANCH} PARENT_SCOPE)

message(STATUS "Configuring ${NAME} ${VERSION_FULL}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${GROOT}/.git/HEAD")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${GROOT}/.git/${GIT_VERSION_FULLREF}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${VERSIONFILE})
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${CALLBACKFILE})

 #CALLBACKFILE ADDITIONAL_OUTPUTS
get_filename_component(VABS "${VERSIONFILE}" ABSOLUTE)
add_custom_command(OUTPUT 
		"${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.txt"
		"${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.h"
		"${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.c"
	COMMAND ${CMAKE_COMMAND} -DVERSION_INTERNAL_RUN_AS_SCRIPT=TRUE
		-DGROOT="${GROOT}" -DNAME="${NAME}" -DVF="${VABS}" 
		-DCALLBACKFILE="${CALLBACKFILE}" 
		-DVERSION_CFILE="${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.c"
		-DVERSION_TXTFILE="${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.txt"
		-DVERSION_HFILE="${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.h"
		-DPROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR}"
		-P "${VERSION_INTERNAL_VERSION_LOCATION}" 
	WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}" 
	DEPENDS "${VERSIONFILE}" "${CALLBACKFILE}" "${VERSION_INTERNAL_LOCATION}" "${GROOT}/.git/${GIT_VERSION_FULLREF}")
	
add_library(${NAME}_version
		"${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.txt"
		"${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.h"
		"${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version/${NAME}_version.c"
)
target_include_directories(${NAME}_version PUBLIC "${CMAKE_CURRENT_BINARY_DIR}/${NAME}_version")
endfunction()

endif()
