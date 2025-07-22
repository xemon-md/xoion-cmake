# Holon

Holon CMake is a lightweight modular layer for CMake.
It helps organize projects into reusable modules with clear dependencies, using TOML-based configuration files.

Holon CMake avoids direct script inclusion and encourages separation between build logic and module structure.
It’s simple to integrate and designed for clarity, portability, and composability.

## How to Start

1. Include Holon in your CMake project (simply copy the contents of this repository into a folder inside your project):

   ```cmake
   include(cfg/holon_cmake/holon_main.cmake)

   holon_load_registries_config("${CMAKE_SOURCE_DIR}/cfg/registries.toml")
   holon_logout_registries()

   holon_require_module("local" "main")
   holon_get_loaded(logout)

   add_executable(${MAIN_TARGET} ${holon_source_files})
   target_include_directories(${MAIN_TARGET} PRIVATE ${holon_include_directories})
   ```

2. Create a module directory, e.g. `src/init/main/`, with:
   - `src/` — source files
   - `inc/` — header files
   - `module.toml` — module configuration file

3. Declare the module in `module.toml`:

   ```toml
   [dependencies]
   local.main = "*"
   local.utils = "*"
   xemon.haversine = "*"

   [platform.all]
   includes = ["inc"]
   sources = ["src/*.c"]
   ```

4. Configure registries in `registries.toml`:

   ```toml
   [registries.local]
   local = "src/init"

   [registries.git.xemon]
   xemon = "ssh://git@github.com/xemon-md/modules"
   ```

## Module Structure

A Holon module is a folder that contains:

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

Holon is composed of modular CMake scripts:

- `holon_main.cmake` — loading and dependency resolution
- `holon_utils.cmake` — utility functions
- `holon_logout.cmake` — debugging and introspection output
- `arrays.cmake` — array utils
- `reduced_toml_parser.cmake` — TOML parser in CMake

The system does not require external TOML parsers or CMake extensions.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
