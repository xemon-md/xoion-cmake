# ------------------------------------------------------------------------------------------
# Xoion Build System - Core Script
#
# This file is the main entry point for the Xoion module-based build system.
# It handles:
#   - Initialization of the module system
#   - Registry definition (local and git-based)
#   - Automatic include/source/library discovery
#   - Module dependency loading via TOML and CMake configs
#   - Git version handling for remote modules
#
# Supported features:
#   - TOML-based module definitions
#   - Cross-platform static and dynamic libraries
#   - Lazy module loading with caching
# ------------------------------------------------------------------------------------------

include(${CMAKE_CURRENT_LIST_DIR}/xoion_logout.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/xoion_utils.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/reduced_toml_parser.cmake)

set(xoion_registries "")

# Initializes xoion system state. Currently prints all cache variables.
function(xoion_init)
    message(STATUS xoion_init)
    get_cmake_property(all_cache_vars VARIABLES)
    foreach(var ${all_cache_vars})
        message(STATUS "${var} ${${var}}")
    endforeach()
endfunction()

# Prints all current CMake cache variable names.
function(xoion_struct)
    get_cmake_property(all_cache_vars VARIABLES)
    foreach(var ${all_cache_vars})
        message(STATUS ${var})
    endforeach()
endfunction()

# Registers a Git-based registry with a given name and path prefix.
function(xoion_add_git_registry name path_prefix)
    args_default(group_name "all" 0 ${ARGN})
    get_global(xoion_registries_keys)

    if("${name}" IN_LIST xoion_registries_keys)
        message(FATAL_ERROR "A module with the name '${name}' already exists.")
    endif()

    list(APPEND xoion_registries_keys ${name})
    set_global(xoion_registries_keys ${xoion_registries_keys})

    set_globalval(xoion_registries_items_${name}_type "git")
    set_globalval(xoion_registries_items_${name}_path_prefix ${path_prefix})
    set_globalval(xoion_registries_items_${name}_group_name ${group_name})
endfunction()

# Registers a local registry with a given name and local path.
function(xoion_add_local_registry name path)
    get_global(xoion_registries_keys)

    if("${name}" IN_LIST xoion_registries_keys)
        message(FATAL_ERROR "A module with the name '${name}' already exists.")
    endif()

    list(APPEND xoion_registries_keys ${name})
    set_global(xoion_registries_keys)

    set_globalval(xoion_registries_items_${name}_type "local")
    set_globalval(xoion_registries_items_${name}_path ${path})
endfunction()

# Adds include directories to the global list from specified paths.
function(xoion_add_includes)
    get_global(xoion_include_directories)
    args_default(inc_dirs "inc" 0 ${ARGN})
    args_default(root_dir "${CMAKE_CURRENT_LIST_DIR}" 1 ${ARGN})

    string(REPLACE "," ";" inc_dirs ${inc_dirs})

    foreach(inc_path IN LISTS inc_dirs)
        if(NOT inc_path MATCHES "^/")
            set(inc_path "${root_dir}/${inc_path}")
        endif()
        if(EXISTS "${inc_path}" AND IS_DIRECTORY ${inc_path})
            list(APPEND xoion_include_directories "${inc_path}")
        endif()
    endforeach()

    set_global(xoion_include_directories)
endfunction()

# Adds files to a global list by matching formats in a given directory.
function(xoion__add_files_by_format target_global_list formats_default)
    get_global(${target_global_list})
    args_default(formats ${formats_default} 0 ${ARGN})
    args_default(root_dir "${CMAKE_CURRENT_LIST_DIR}" 1 ${ARGN})
    string(REPLACE "," ";" formats ${formats})

    foreach(format IN LISTS formats)
        if(NOT format MATCHES "^/")
            set(format "${root_dir}/${format}")
        endif()
        file(GLOB files ${format})
        list(APPEND ${target_global_list} ${files})
    endforeach()

    set_global(${target_global_list})
endfunction()

# Adds source files (default patterns: src/*.c, src/*.cpp).
function(xoion_add_sources)
    xoion__add_files_by_format(xoion_source_files "src/*.c,src/*.cpp" ${ARGN})
endfunction()

# Adds static libraries (default patterns: lib/*.a, lib/*.lib).
function(xoion_add_libraries_static)
    xoion__add_files_by_format(xoion_libraries_static "lib/*.a,lib/*.lib" ${ARGN})
endfunction()

# Adds dynamic libraries (default patterns: dll/*.so, dll/*.dll).
function(xoion_add_libraries_dynamic)
    xoion__add_files_by_format(xoion_libraries_dynamic "dll/*.so,dll/*.dll" ${ARGN})
endfunction()

# Loads module configuration from TOML or CMake and processes includes, sources, and dependencies.
function(xoion_load_module_config module_path)
    set(module_toml "${module_path}/module.toml")
    set(module_file "${module_path}/module.cmake")

    if(EXISTS "${module_file}")
        include("${module_file}")
    endif()

    if(NOT EXISTS "${module_toml}")
        xoion_add_includes(${module_path}/inc)
        xoion_add_sources(${module_path}/src/*.c,${module_path}/src/*.cpp)
        return()
    endif()

    file(READ "${module_toml}" toml_content)
    if(NOT toml_content)
        return()
    endif()

    xoion_toml_content_check(${toml_content})
    xoion_strip_toml_comments(${toml_content} toml_content)
    xoion_parse_reduced_toml(${toml_content} sections)

    foreach(sec_idx RANGE 0 ${sections_last_idx})
        list(GET sections_names ${sec_idx} section_name)
        set(section_variables_names ${sections_vars_${sec_idx}_names})
        set(section_variables_last_idx ${sections_vars_${sec_idx}_last_idx})

        if(${section_name} STREQUAL "platform.all")
            foreach(var_idx RANGE 0 ${section_variables_last_idx})
                list(GET section_variables_names ${var_idx} variable_name)
                set(variable_value ${sections_vars_${sec_idx}_values_${var_idx}})
                if(${variable_name} STREQUAL "includes")
                    foreach(value ${variable_value})
                        xoion_add_includes(${value} ${module_path})
                    endforeach()
                elseif(${variable_name} STREQUAL "sources")
                    foreach(value ${variable_value})
                        xoion_add_sources(${value} ${module_path})
                    endforeach()
                elseif(${variable_name} STREQUAL "libraries_static")
                    foreach(value ${variable_value})
                        xoion_add_libraries_static(${value} ${module_path})
                    endforeach()
                elseif(${variable_name} STREQUAL "libraries_dynamic")
                    foreach(value ${variable_value})
                        xoion_add_libraries_dynamic(${value} ${module_path})
                    endforeach()
                endif()
            endforeach()
        elseif(${section_name} STREQUAL "dependencies")
            foreach(var_idx RANGE 0 ${section_variables_last_idx})
                list(GET section_variables_names ${var_idx} variable_name)
                set(variable_value ${sections_vars_${sec_idx}_values_${var_idx}})
                string(REPLACE "." ";" target_pair "${variable_name}")
                list(GET target_pair 0 repo)
                list(GET target_pair 1 module)
                set(version ${variable_value})
                xoion_require_module(${repo} ${module} ${version})
            endforeach()
        endif()
    endforeach()
endfunction()

# Loads registry definitions from a TOML or CMake file.
function(xoion_load_registries_config registries_file)
    get_filename_component(FILE_EXT "${registries_file}" EXT)

    if(FILE_EXT STREQUAL ".cmake")
        include("${registries_file}")
    elseif(NOT FILE_EXT STREQUAL ".toml")
        message(WARNING "Unknown file extension: ${FILE_EXT}")
        return()
    endif()

    file(READ "${registries_file}" toml_content)
    if(NOT toml_content)
        return()
    endif()

    xoion_toml_content_check(${toml_content})
    xoion_strip_toml_comments(${toml_content} toml_content)
    xoion_parse_reduced_toml(${toml_content} sections)

    foreach(sec_idx RANGE 0 ${sections_last_idx})
        list(GET sections_names ${sec_idx} section_name)
        set(section_variables_names ${sections_vars_${sec_idx}_names})
        set(section_variables_last_idx ${sections_vars_${sec_idx}_last_idx})

        if(${section_name} STREQUAL "registries.local")
            foreach(var_idx RANGE 0 ${section_variables_last_idx})
                list(GET section_variables_names ${var_idx} variable_name)
                set(variable_value ${sections_vars_${sec_idx}_values_${var_idx}})
                xoion_add_local_registry(${variable_name} ${variable_value})
            endforeach()
            continue()
        endif()

        string(REGEX MATCH "^registries\\.git(\\.(.+))?$" _ "${section_name}")
        if(NOT "${CMAKE_MATCH_0}" STREQUAL "")
            if("${CMAKE_MATCH_2}" STREQUAL "")
                set(group_name "all")
            else()
                set(group_name "${CMAKE_MATCH_2}")
            endif()

            foreach(var_idx RANGE 0 ${section_variables_last_idx})
                list(GET section_variables_names ${var_idx} variable_name)
                set(variable_value ${sections_vars_${sec_idx}_values_${var_idx}})
                xoion_add_git_registry(${variable_name} ${variable_value} ${group_name})
            endforeach()
            continue()
        endif()
    endforeach()
endfunction()

# Declares a dependency on a module from a given registry and loads it if not already loaded.
function(xoion_require_module registry module)
    args_default(version "*" 0 ${ARGN})
    get_global(xoion_registries_keys)
    get_global(xoion_loaded_keys)

    set(module_id_string "${registry}:${module}")

    if(${module_id_string} IN_LIST xoion_loaded_keys)
        message(STATUS "${module_id_string} already loaded...")
        return()
    else()
        message(STATUS "${module_id_string} loading...")
        list(APPEND xoion_loaded_keys ${module_id_string})
        set_global(xoion_loaded_keys)
    endif()

    if(NOT "${registry}" IN_LIST xoion_registries_keys)
        message(FATAL_ERROR "Registry '${registry}' not exists.")
    endif()

    get_globalval(xoion_registries_items_${registry}_type registry_type)

    if(registry_type STREQUAL "local")
        xoion_require_module_local(${registry} ${module} ${version})
    elseif(registry_type STREQUAL "git")
        xoion_require_module_git(${registry} ${module} ${version})
    else()
        message(FATAL_ERROR "Unknown registry type: ${registry_type}")
    endif()
endfunction()

# Loads a module from a local registry.
function(xoion_require_module_local registry module version)
    get_globalval(xoion_registries_items_${registry}_path registry_path)

    if(NOT registry_path MATCHES "^/")
        set(registry_path "${CMAKE_SOURCE_DIR}/${registry_path}")
    endif()

    set(module_path "${registry_path}/${module}")

    if(NOT EXISTS "${module_path}")
        message(FATAL_ERROR "Directory '${module_path}' does not exist.")
    endif()

    if(NOT version STREQUAL "*")
        message(STATUS "Local module - version '${version}' is ignored.")
    endif()

    xoion_load_module_config(${module_path})
endfunction()

# Verifies or checks out specific commit SHA in a git module.
function(xoion_git_module_check_commit module_path sha_ref)
    if(sha_ref STREQUAL "*")
        return()
    endif()

    string(LENGTH "${sha_ref}" REF_LENGTH)

    if(REF_LENGTH GREATER 40 OR REF_LENGTH LESS 7)
        message(FATAL_ERROR "Invalid SHA '${sha_ref}', wrong length ${REF_LENGTH}")
    elseif(REF_LENGTH EQUAL 40)
        set(GET_SHA_CMD "git" "rev-parse" "HEAD")
    else()
        set(GET_SHA_CMD "git" "rev-parse" "--short=${REF_LENGTH}" "HEAD")
    endif()

    execute_process(
        COMMAND ${GET_SHA_CMD}
        WORKING_DIRECTORY ${module_path}
        OUTPUT_VARIABLE TARGET_SHA
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${sha_ref}" STREQUAL "${TARGET_SHA}")
        message(STATUS "SHA is already correct.")
        return()
    endif()

    execute_process(
        COMMAND git rev-parse --verify ${sha_ref}
        WORKING_DIRECTORY ${module_path}
        RESULT_VARIABLE REVPARSE_RESULT
        OUTPUT_VARIABLE RESOLVED_SHA
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT REVPARSE_RESULT EQUAL 0)
        message(FATAL_ERROR "SHA '${sha_ref}' not found.")
    endif()

    execute_process(
        COMMAND git checkout ${RESOLVED_SHA}
        WORKING_DIRECTORY ${module_path}
        RESULT_VARIABLE CHECKOUT_RESULT
    )

    if(NOT CHECKOUT_RESULT EQUAL 0)
        message(FATAL_ERROR "Error checking out SHA ${RESOLVED_SHA}")
    else()
        message(STATUS "Checked out to SHA ${RESOLVED_SHA} successfully")
    endif()
endfunction()

# Loads a module from a git registry, optionally checking out to a specific version.
function(xoion_require_module_git registry_name module version)
    get_globalval(xoion_registries_items_${registry_name}_path_prefix registry_path_prefix)
    get_globalval(xoion_registries_items_${registry_name}_group_name registry_group_name)

    set(module_remote_path "${registry_path_prefix}/${module}")
    set(module_group_path "${CMAKE_SOURCE_DIR}/modules/${registry_group_name}")
    set(module_local_path "${module_group_path}/${module}")

    if(NOT EXISTS "${module_local_path}")
        message(STATUS "Cloning git module ${module_remote_path}...")
        file(MAKE_DIRECTORY ${module_group_path})
        execute_process(
            COMMAND git clone ${module_remote_path} ${module_local_path}
            RESULT_VARIABLE GIT_CLONE_RESULT
        )
        if(NOT GIT_CLONE_RESULT EQUAL 0)
            message(FATAL_ERROR "Git clone failed with code ${GIT_CLONE_RESULT}")
        endif()
    else()
        message(STATUS "${registry_name}:${module} local copy exists. Skipping clone.")
    endif()

    xoion_git_module_check_commit(${module_local_path} ${version})
    xoion_load_module_config(${module_local_path})
endfunction()

# Returns all globally loaded sources, libraries and includes to the caller.
function(xoion_get_loaded)
    args_default(do_logout "no_logout" 0 ${ARGN})
    get_global(xoion_include_directories)
    get_global(xoion_source_files)
    get_global(xoion_libraries_static)
    get_global(xoion_libraries_dynamic)

    set(xoion_include_directories ${xoion_include_directories} PARENT_SCOPE)
    set(xoion_source_files ${xoion_source_files} PARENT_SCOPE)
    set(xoion_libraries_static ${xoion_libraries_static} PARENT_SCOPE)
    set(xoion_libraries_dynamic ${xoion_libraries_dynamic} PARENT_SCOPE)

    if(do_logout STREQUAL "logout")
        xoion_logout_loaded()
    endif()
endfunction()
