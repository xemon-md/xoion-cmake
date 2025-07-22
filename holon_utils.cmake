# ==============================================================================
# Holon Utilities - Global Variable & Argument Helpers for CMake
#
# Provides helper functions for setting and retrieving global properties,
# as well as default argument resolution in macro/function calls.
# ==============================================================================

# Sets a global property using the current value of the given variable.
function(set_global var)
    set_property(GLOBAL PROPERTY ${var} ${${var}})
endfunction()

# Sets a global property to an explicit value.
function(set_globalval var value)
    set_property(GLOBAL PROPERTY ${var} ${value})
endfunction()

# Retrieves the value of a global property and assigns it to a variable
# with the same name in the parent scope.
function(get_global var)
    get_property(tmp GLOBAL PROPERTY ${var})
    set(${var} ${tmp} PARENT_SCOPE)
endfunction()

# Retrieves the value of a global property and assigns it to a custom
# variable name in the parent scope.
function(get_globalval var val)
    get_property(tmp GLOBAL PROPERTY ${var})
    set(${val} ${tmp} PARENT_SCOPE)
endfunction()

# Resolves an argument by index from a variadic argument list.
# If the index is out of bounds, assigns a default value instead.
function(args_default argname default arg_idx)
    set(argslist ${ARGN})
    list(LENGTH argslist args_count)
    math(EXPR argslimit "${args_count} - 1")

    if(${argslimit} LESS ${arg_idx})
        set(${argname} ${default} PARENT_SCOPE)
    else()
        list(GET argslist ${arg_idx} arg_val)
        set(${argname} ${arg_val} PARENT_SCOPE)
    endif()
endfunction()
