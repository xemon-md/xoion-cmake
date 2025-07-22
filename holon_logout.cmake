# ==============================================================================
# Holon Utilities - Logging for Registries and Loaded Components
#
# Provides functions to log registered repositories and loaded components
# (such as include directories, source files, and libraries) for debugging
# and diagnostic purposes.
# ==============================================================================

include(${CMAKE_CURRENT_LIST_DIR}/arrays.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/holon_utils.cmake)

# Logs information about a local registry.
# Prints its name, type, and path.
function(holon_logout_registry_local registry_name)
    get_globalval(holon_registries_items_${registry_name}_type registry_type)
    get_globalval(holon_registries_items_${registry_name}_path registry_path)
    message(STATUS "${registry_name}\t\t\t${registry_type}\t\t${registry_path}")
endfunction()

# Logs information about a git registry.
# Prints its name, type, and path prefix.
function(holon_logout_registry_git registry_name)
    get_globalval(holon_registries_items_${registry_name}_type registry_type)
    get_globalval(holon_registries_items_${registry_name}_path_prefix registry_path)
    message(STATUS "${registry_name}\t\t${registry_type}\t\t\t${registry_path}")
endfunction()

# Logs all registered registries, delegating to specific loggers
# depending on registry type ("local" or "git").
function(holon_logout_registries)
    get_global(holon_registries_keys)

    foreach(registry_name IN LISTS holon_registries_keys)
        get_globalval(holon_registries_items_${registry_name}_type registry_type)

        if(${registry_type} STREQUAL "local")
            holon_logout_registry_local(${registry_name})
        elseif(${registry_type} STREQUAL "git")
            holon_logout_registry_git(${registry_name})
        else()
            message(STATUS "${registry_name} ${registry_type}")
        endif()
    endforeach()

    message(STATUS "")
endfunction()

# Logs lists of loaded include directories, source files,
# and both static and dynamic libraries.
function(holon_logout_loaded)
    print_list_lines("include directories" holon_include_directories)
    print_list_lines("source files" holon_source_files)
    print_list_lines("libraries static" holon_libraries_static)
    print_list_lines("libraries dynamic" holon_libraries_dynamic)
endfunction()
