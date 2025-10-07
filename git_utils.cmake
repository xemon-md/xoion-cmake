include(${CMAKE_CURRENT_LIST_DIR}/arrays.cmake)

# Function: inspect_git_repos
# Description:
#   Scans a directory tree for Git repositories and inspects their state.
#   It checks if repositories are clean, dirty (uncommitted changes), or unpushed (commits not pushed to remote).
# Arguments:
#   inspected_root - Root directory to search for Git repositories.
#   logout_all     - If TRUE, logs all repositories (even clean ones). Otherwise, logs only non-clean repos.
function(inspect_git_repos inspected_root logout_all)
   
    # Find all directories named ".git" within the inspected_root
    execute_process(
        COMMAND find "${inspected_root}" -type d -name ".git"
        OUTPUT_VARIABLE git_dirs_raw
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Convert newline-separated list into a semicolon-separated CMake list
    string(REPLACE "\n" ";" git_dirs "${git_dirs_raw}")

    # Iterate through each Git directory found
    foreach(git_dir IN LISTS git_dirs)
        # Get the repository directory path (parent of .git)
        get_filename_component(repo_dir "${git_dir}" DIRECTORY)

        # Check repository working tree status (empty if clean)
        execute_process(
            COMMAND git -C "${repo_dir}" status --porcelain
            OUTPUT_VARIABLE status_output
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Try to get the upstream branch reference
        execute_process(
            COMMAND git -C "${repo_dir}" rev-parse --abbrev-ref --symbolic-full-name @{u}
            OUTPUT_VARIABLE upstream_output
            ERROR_QUIET
            RESULT_VARIABLE upstream_result
        )

        # Count commits ahead of upstream (unpushed commits)
        execute_process(
            COMMAND git -C "${repo_dir}" rev-list --count @{u}..HEAD
            OUTPUT_VARIABLE ahead_output
            ERROR_QUIET
            RESULT_VARIABLE ahead_result
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Default repository state is "clean"
        set(repo_state "clean")
        
        # If there are uncommitted changes
        if(NOT status_output STREQUAL "")
            set(repo_state "dirty")
        # If there is an upstream branch and there are unpushed commits
        elseif(upstream_result EQUAL 0 AND ahead_output GREATER 0)
            set(repo_state "unpushed")
        endif()

        # Log repository state:
        # - if logout_all is TRUE → log all repos
        # - otherwise → log only dirty or unpushed repos
        if(logout_all OR NOT repo_state STREQUAL "clean")
            message(STATUS "[${repo_state}] ${repo_dir}")
        endif()
    endforeach()
endfunction()
