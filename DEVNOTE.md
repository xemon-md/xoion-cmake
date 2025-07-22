# Holon – Development Notes

This document describes internal variable structures used during Holon processing.  
It may be useful for contributors or advanced debugging.

---

## `modules`

### `registries`

```json
{
  "keys": ["<string>", "..."],
  "items": [
    {
      "type": "local",
      "path": "<string>"
    },
    {
      "type": "git",
      "prefix_path": "<string>",
      "group_name": "<string>"
    }
  ]
}
```

### `loaded`

```json
{
  "keys": ["<registry_name>_<module_name>", "..."],
  "items": [
    {
      "loaded_version": "<string>"
    }
  ]
}
```

### File/Link Collections

```json
"holon_source_files": ["<string>"],
"holon_include_directories": ["<string>"],
"holon_libraries_static": ["<string>"],
"holon_libraries_dynamic": ["<string>"]
```

---

## `sections`

This structure is typically used for TOML parsing results or module config transformation.

```json
{
  "names": ["..."],
  "vars": [
    {
      "names": ["..."],
      "values": ["...", "...", "..."]
    }
  ]
}
```

---

## Notes

- The data structure is dynamic and may be extended.
- All keys/fields are stored as CMake variables in dictionary-like form.
- Internally used in `holon_utils.cmake`, `holon_main.cmake` and TOML parsing.
