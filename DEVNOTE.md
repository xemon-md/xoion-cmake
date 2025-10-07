# Xoion – Development Notes

This document describes internal variable structures used during Xoion processing.  
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
"xoion_source_files": ["<string>"],
"xoion_include_directories": ["<string>"],
"xoion_libraries_static": ["<string>"],
"xoion_libraries_dynamic": ["<string>"]
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
- Internally used in `xoion_utils.cmake`, `xoion_main.cmake` and TOML parsing.
