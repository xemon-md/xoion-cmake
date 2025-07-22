# ==============================================================================
# Holon Utilities - Lightweight TOML Parser for CMake
#
# Provides basic parsing for simplified TOML content, supporting section
# detection, key-value extraction, array handling, and comment stripping.
# Useful for minimal configuration file parsing in CMake-based systems.
# ==============================================================================



# Extracts section headers and corresponding content blocks from TOML text.
# Results are returned in indexed variables with the given return_prefix.
function(holon_parse_reduced_toml_sections_raw content return_prefix)
    set(return_names "${return_prefix}_names")
    set(return_last_idx "${return_prefix}_last_idx")
    set(return_contents "${return_prefix}_contents")

    string(REGEX MATCHALL "\\[([a-zA-Z0-9_.-]+)\\]" SECTION_MATCHES "${content}")

    set(section_names "")
    foreach(M ${SECTION_MATCHES})
        string(REGEX REPLACE "^\\[(.+)\\]$" "\\1" section_name "${M}")
        list(APPEND section_names "${section_name}")
    endforeach()

    list(LENGTH section_names sections_count)
    math(EXPR sections_last_idx "${sections_count} - 1")

    set(${return_names} ${section_names} PARENT_SCOPE)
    set(${return_last_idx} ${sections_last_idx} PARENT_SCOPE)

    foreach(idx RANGE 0 ${sections_last_idx})
        list(GET section_names ${idx} section_name)
        set(section_header "\\[${section_name}\\]")
        string(REGEX MATCH "${section_header}" _match "${content}")
        string(FIND "${content}" "${_match}" SECTION_START)

        if(NOT ${idx} EQUAL ${sections_last_idx})
            math(EXPR NEXT_INDEX "${idx} + 1")
            list(GET section_names ${NEXT_INDEX} NEXT_SECTION_NAME)
            set(NEXT_HEADER "\\[${NEXT_SECTION_NAME}\\]")
            string(REGEX MATCH "${NEXT_HEADER}" _next_match "${content}")
            string(FIND "${content}" "${_next_match}" SECTION_END)
        else()
            string(LENGTH "${content}" SECTION_END)
        endif()

        math(EXPR CONTENT_LEN "${SECTION_END} - ${SECTION_START}")
        string(SUBSTRING "${content}" ${SECTION_START} ${CONTENT_LEN} section_content)

        string(REPLACE "\r\n" "\n" section_content "${section_content}")
        string(REPLACE "\r" "\n" section_content "${section_content}")
        string(FIND "${section_content}" "\n" POS)
        if(NOT POS EQUAL -1)
            math(EXPR POS_NEXT "${POS} + 1")
            string(SUBSTRING "${section_content}" ${POS_NEXT} -1 section_content)
        else()
            set(section_content "")
        endif()
        string(STRIP "${section_content}" section_content)

        set("${return_contents}_${idx}" "${section_content}" PARENT_SCOPE)
    endforeach()
endfunction()



# Removes comments from TOML input, ignoring '#' inside quoted strings.
# Returns the cleaned content to the output variable.
function(holon_strip_toml_comments input output_var)
    set(clean_lines "")
    string(REPLACE "\r" "" input "${input}")
    string(REPLACE "\n" ";" lines "${input}")

    foreach(line IN LISTS lines)
        string(STRIP "${line}" line)
        if(line STREQUAL "")
            list(APPEND clean_lines "")
            continue()
        endif()

        set(comment_pos -1)
        string(FIND "${line}" "\"" first_quote_pos)
        string(FIND "${line}" "#" hash_pos)

        if(first_quote_pos EQUAL -1 OR hash_pos LESS first_quote_pos)
            set(comment_pos ${hash_pos})
        else()
            string(REGEX MATCH "^([^\"]*\"[^\"]*\")[ \t]*#" _ "" "${line}")
            if(NOT "${CMAKE_MATCH_1}" STREQUAL "")
                string(LENGTH "${CMAKE_MATCH_1}" match_len)
                string(SUBSTRING "${line}" ${match_len} -1 after)
                string(FIND "${after}" "#" hash_pos_after)
                if(NOT hash_pos_after EQUAL -1)
                    math(EXPR comment_pos "${match_len} + ${hash_pos_after}")
                endif()
            else()
                string(FIND "${line}" "#" comment_pos)
            endif()
        endif()

        if(NOT comment_pos EQUAL -1)
            string(SUBSTRING "${line}" 0 ${comment_pos} line)
        endif()

        string(STRIP "${line}" line)
        list(APPEND clean_lines "${line}")
    endforeach()

    string(REPLACE ";" "\n" result "${clean_lines}")
    set(${output_var} "${result}" PARENT_SCOPE)
endfunction()



# Parses a TOML value: number, quoted string, or array. Outputs cleaned value.
function(holon_parse_toml_value input output_var)
    if("${input}" MATCHES "^[0-9]+$")
        set(${output_var} "${input}" PARENT_SCOPE)
        return()
    endif()

    if("${input}" MATCHES "^\".*\"$")
        string(REGEX REPLACE "^\"(.*)\"$" "\\1" unquoted "${input}")
        set(${output_var} "${unquoted}" PARENT_SCOPE)
        return()
    endif()

    if("${input}" MATCHES "^\\[.*\\]$")
        string(REGEX REPLACE "^\\[" "" input "${input}")
        string(REGEX REPLACE "\\]$" "" input "${input}")
        string(REPLACE "," ";" items "${input}")

        set(clean_items "")
        foreach(item IN LISTS items)
            string(STRIP "${item}" item)
            string(REGEX REPLACE "^\"(.*)\"$" "\\1" item "${item}")
            list(APPEND clean_items "${item}")
        endforeach()

        list(JOIN clean_items ";" result)
        set(${output_var} "${result}" PARENT_SCOPE)
        return()
    endif()

    set(${output_var} "${input}" PARENT_SCOPE)
endfunction()



# Extracts key-value pairs from a section of TOML content.
# Returns indexed variable names and values with the given prefix.
function(holon_parse_reduced_toml_variables_raw content return_prefix)
    set(return_names "${return_prefix}_names")
    set(return_last_idx "${return_prefix}_last_idx")
    set(return_contents "${return_prefix}_contents")

    string(REPLACE "\r" "" content "${content}")
    string(REPLACE "\n" ";" content_lines "${content}")
    list(LENGTH content_lines line_count)
    math(EXPR line_last_idx "${line_count} - 1")

    set(var_names "")
    set(var_values "")

    foreach(i RANGE 0 ${line_last_idx})
        list(GET content_lines ${i} line)
        string(STRIP "${line}" line)
        string(REPLACE ";" "" line "${line}")

        if(line STREQUAL "")
            continue()
        endif()

        string(REGEX MATCH "^([a-zA-Z0-9_.-]+)[ \t]*=[ \t]*(.+)" _ "" "${line}")
        if(NOT "${CMAKE_MATCH_1}" STREQUAL "")
            set(current_name "${CMAKE_MATCH_1}")
            set(current_value "${CMAKE_MATCH_2}")
            list(APPEND var_names "${current_name}")
            list(APPEND var_values "${current_value}")
        endif()
    endforeach()

    list(LENGTH var_names count)
    math(EXPR last_idx "${count} - 1")
    set(${return_names} "${var_names}" PARENT_SCOPE)
    set(${return_last_idx} "${last_idx}" PARENT_SCOPE)

    foreach(i RANGE 0 ${last_idx})
        list(GET var_values ${i} val)
        set("${return_contents}_${i}" "${val}" PARENT_SCOPE)
    endforeach()
endfunction()



# Parses complete TOML content with sections and variables.
# Results are returned using the given return_prefix.
function(holon_parse_reduced_toml content retrun_prefix)
    holon_parse_reduced_toml_sections_raw(${content} sections)

    set("${retrun_prefix}_last_idx" ${sections_last_idx} PARENT_SCOPE)
    set("${retrun_prefix}_names" ${sections_names} PARENT_SCOPE)

    foreach(sec_idx RANGE 0 ${sections_last_idx})
        list(GET sections_names ${sec_idx} section_name)
        set(section_content ${sections_contents_${sec_idx}})

        if(NOT section_content)
            continue()
        endif()

        holon_parse_reduced_toml_variables_raw(${section_content} section_variables)

        set("${retrun_prefix}_vars_${sec_idx}_last_idx" ${section_variables_last_idx} PARENT_SCOPE)
        set("${retrun_prefix}_vars_${sec_idx}_names" ${section_variables_names} PARENT_SCOPE)

        foreach(var_idx RANGE 0 ${section_variables_last_idx})
            list(GET section_variables_names ${var_idx} variable_name)
            set(variable_content ${section_variables_contents_${var_idx}})
            holon_parse_toml_value(${variable_content} variable_content)
            set("${retrun_prefix}_vars_${sec_idx}_values_${var_idx}" ${variable_content} PARENT_SCOPE)
        endforeach()
    endforeach()
endfunction()



# Runs a full parse and optionally prints parsed structure for debug.
function(holon_toml_content_check toml_content)
    holon_strip_toml_comments(${toml_content} toml_content)
    holon_parse_reduced_toml(${toml_content} sections)

    foreach(sec_idx RANGE 0 ${sections_last_idx})
        list(GET sections_names ${sec_idx} section_name)
        set(section_variables_names ${sections_vars_${sec_idx}_names})
        set(section_variables_last_idx ${sections_vars_${sec_idx}_last_idx})

        foreach(var_idx RANGE 0 ${section_variables_last_idx})
            list(GET section_variables_names ${var_idx} variable_name)
            set(variable_value ${sections_vars_${sec_idx}_values_${var_idx}})
            # Optionally log or validate values here
        endforeach()
    endforeach()
endfunction()
