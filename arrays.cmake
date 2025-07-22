#------------------------------------------------------------------------------
# Holon Build System - Internal Array Utilities
#
# This file provides internal array manipulation helpers.
#------------------------------------------------------------------------------
function(print_list_lines arr_name arr_items)
    message(STATUS "")
    message(STATUS "------- ${arr_name} -------")
    foreach(item IN LISTS ${arr_items})
        message(STATUS "${item}")
    endforeach()
    message(STATUS "")
endfunction()