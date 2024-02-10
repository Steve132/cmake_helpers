function(target_generate_disassembly TARG)
    #do standard cmake parser
    #set(options DO_FILTER)
    #set(oneValueArgs "")
    #set(multiValueArgs TARGETS)

    #cmake_parse_arguments(VIEW_DISASSEMBLY "${options}" "${oneValueArgs}"
    #"${multiValueArgs}" ${ARGN})

    if(MSVC)
        message(WARNING "Disassembly view not supported on MSVC")
        return()
    endif()

    set(OBJDUMP_OPTS --no-addresses --no-show-raw-insn --source -l -C --visualize-jumps -d)
        
    set(OUTPUT_GEXPR "$<TARGET_FILE:${TARG}>.view.s")
    add_custom_command(TARGET ${TARG} POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} ${OBJDUMP_OPTS} $<TARGET_OBJECTS:${TARG}> > ${OUTPUT_GEXPR}
        #BYPRODUCTS ${OUTPUT_GEXPR}
        COMMENT "Disassembling ${TARG} to ${OUTPUT_GEXPR}"
        VERBATIM
    )
endfunction()
