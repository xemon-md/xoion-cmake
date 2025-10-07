# Xoion

Xoion CMake is a lightweight modular layer for CMake.
It helps organize projects into reusable modules with clear dependencies, using TOML-based configuration files.

Xoion CMake avoids direct script inclusion and encourages separation between build logic and module structure.
It’s simple to integrate and designed for clarity, portability, and composability.

## How to Start

1. **Add Xoion to your CMake project.**
   If `xoion-cmake` is not yet cloned, it will be fetched automatically:

   ```cmake
   # Ensure xoion-cmake is present
   set(xoion_cmake_dir "${CMAKE_SOURCE_DIR}/cfg/xoion-cmake")
   if(NOT EXISTS "${xoion_cmake_dir}")
     message(STATUS "Cloning xoion-cmake into ${xoion_cmake_dir}")
     execute_process(
       COMMAND git clone https://github.com/xemon-md/xoion-cmake "${xoion_cmake_dir}"
       RESULT_VARIABLE GIT_CLONE_RESULT
     )
     if(NOT GIT_CLONE_RESULT EQUAL 0)
       message(FATAL_ERROR "Failed to clone xoion-cmake")
     endif()
   endif()

   # Include main entrypoint
   include(${xoion_cmake_dir}/xoion_main.cmake)

   # Load registries configuration
   xoion_load_registries_config("${CMAKE_SOURCE_DIR}/cfg/registries.toml")
   xoion_logout_registries()

   # Require main module
   xoion_require_module("local" "main")
   xoion_get_loaded(logout)

   # Build target
   add_executable(${MAIN_TARGET} ${xoion_source_files})
   target_include_directories(${MAIN_TARGET} PRIVATE ${xoion_include_directories})
   ```

2. **Create a module directory**, for example `src/init/main/`, with:
   - `src/` — source files
   - `inc/` — header files
   - `module.toml` — module configuration file

3. **Declare the module** in `module.toml`:

   ```toml
   [dependencies]
   local.main = "*"
   local.utils = "*"
   xemon.haversine = "*"

   [platform.all]
   includes = ["inc"]
   sources = ["src/*.c"]
   ```

4. **Configure registries** in `cfg/registries.toml`:

   ```toml
   [registries.local]
   local = "src/init"

   [registries.git.xemon]
   xemon = "ssh://git@github.com/xemon-md/modules"
   ```

## Module Structure

A Xoion module is a folder that contains:

- `src/` — implementation source files
- `inc/` — exported headers
- `module.toml` — module descriptor

Modules are resolved and loaded by the system. Direct inclusion of CMake scripts is not required or encouraged.

## module.toml Format

A typical module file may include:

```toml
[dependencies]
local.utils = "*"

[platform.all]
includes = ["inc"]
sources = ["src/*.c"]
libraries_static = []
libraries_dynamic = []

[platform.windows]
sources = ["src_win/win_specific.c"]

[platform.linux]
libraries_dynamic = ["dyn/*.so"]
```

Fields:
- `dependencies` — other modules to load, using registry and name
- `includes` — include paths
- `sources` — C/C++ sources (supports globs)
- `libraries_static` / `libraries_dynamic` — extra libraries to link

## registries.toml Format

Specifies where to find named registries:

```toml
[registries.local]
local = "src/init"

[registries.git.company]
company = "ssh://git@example.com/your/modules"
```

Registries act as namespaces that map to local folders or Git repositories.

## Internal Architecture

Xoion is composed of modular CMake scripts:

- `xoion_main.cmake` — loading and dependency resolution
- `xoion_utils.cmake` — utility functions
- `xoion_logout.cmake` — debugging and introspection output
- `arrays.cmake` — array utils
- `git_utils.cmake` — git utils
- `reduced_toml_parser.cmake` — TOML parser in CMake

The system does not require external TOML parsers or CMake extensions.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
