function(generate_build_script SCRIPT_FN_G_VAR SCRIPT_CONTENT)
    #set(options )
    #set(oneValueArgs )
    #set(multiValueArgs GENERATE_ARGS)
    #cmake_parse_arguments(MY_INSTALL "${options}" "${oneValueArgs}"
    #                    "${multiValueArgs}" ${ARGN} )
    string(SHA3_256 _BR_VERB_HASH ${SCRIPT_CONTENT})
    set(_BR_FN_DIR "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/buildscripts")
    if(NOT EXISTS ${_BR_FN_DIR})
        file(MAKE_DIRECTORY ${_BR_FN_DIR})
    endif()
    set(_BR_VERB_HASH_FN "${_BR_FN_DIR}/verb_${_BR_VERB_HASH}.cmake")
    file(CONFIGURE OUTPUT "${_BR_VERB_HASH_FN}" CONTENT ${SCRIPT_CONTENT} @ONLY ESCAPE_QUOTES)
    set(_BR_HASH_FN_G "${_BR_FN_DIR}/$<CONFIG>_${_BR_VERB_HASH}.cmake")
    file(GENERATE OUTPUT "${_BR_HASH_FN_G}" INPUT "${_BR_VERB_HASH_FN}" ${ARGN})
    set(${SCRIPT_FN_G_VAR} "${CMAKE_COMMAND} -P ${_BR_HASH_FN_G}" PARENT_SCOPE)
endfunction()




#Generate a function that will be used to add a custom script to the build process.
