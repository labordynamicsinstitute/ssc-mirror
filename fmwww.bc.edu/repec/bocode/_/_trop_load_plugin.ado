/*
    _trop_load_plugin -- Resolve the platform-specific compiled plugin binary.

    Detects the host operating system and CPU architecture, then searches
    for the corresponding plugin file in the following order:

      0. Same directory as this ado-file (net install layout).
      1. Relative to this ado-file (../plugin/).
      2. c(pwd)/trop_stata/plugin/
      3. c(pwd)/../plugin/
      4. c(pwd)/plugin/
      5. Along the adopath (PERSONAL, PLUS, SITE).

    Supported platforms:
      macOS ARM64, macOS x64, Linux x64, Windows x64.

    Returns via c_local:
      _plugin_name      Plugin filename.
      _plugin_path      Resolved absolute path to the binary.
      _platform_desc    Human-readable platform label.

    Exit codes:
      198   Unsupported OS or architecture.
      601   Plugin binary not found in any search path.
*/

program define _trop_load_plugin
    version 17.0

    local os = c(os)
    local machine = c(machine_type)

    // Detect macOS: c(os) returns "Unix" on some macOS configurations
    local is_mac_machine = strpos("`machine'", "Mac")
    local is_apple_silicon = strpos("`machine'", "Apple Silicon")
    local is_arm = strpos("`machine'", "ARM")
    local is_arm64 = strpos("`machine'", "arm64")

    local is_macos = 0
    if "`os'" == "MacOSX" {
        local is_macos = 1
    }
    else if "`os'" == "Unix" & `is_mac_machine' > 0 {
        local is_macos = 1
    }

    // Map platform to plugin filename
    if `is_macos' {
        if `is_apple_silicon' > 0 | `is_arm' > 0 | `is_arm64' > 0 {
            local plugin_name "trop_macos_arm64.plugin"
            local platform_desc "macOS ARM64 (Apple Silicon)"
        }
        else {
            local plugin_name "trop_macos_x64.plugin"
            local platform_desc "macOS x64 (Intel)"
        }
    }
    else if "`os'" == "Unix" {
        local plugin_name "trop_linux_x64.plugin"
        local platform_desc "Linux x64"
    }
    else if "`os'" == "Windows" {
        local plugin_name "trop_windows_x64.plugin"
        local platform_desc "Windows x64"
    }
    else {
        di as error "Unsupported platform: `os' (`machine')"
        di as error "This package supports: macOS (ARM64/x64), Linux x64, Windows x64."
        exit 198
    }

    // Search for the plugin binary across candidate locations
    local plugin_path ""

    // (0) Same directory as this ado file (net install places plugin alongside ado)
    capture findfile _trop_load_plugin.ado
    if !_rc {
        local ado_fullpath "`r(fn)'"
        // Normalize path separators (Windows uses backslash)
        local ado_fullpath : subinstr local ado_fullpath "\" "/", all
        // Extract directory containing this ado file
        local _spos0 = strrpos("`ado_fullpath'", "/")
        if `_spos0' > 0 {
            local _ado_dir0 = substr("`ado_fullpath'", 1, `_spos0')
            capture confirm file "`_ado_dir0'`plugin_name'"
            if !_rc {
                local plugin_path "`_ado_dir0'`plugin_name'"
            }
        }
    }

    // (1) Relative to this ado-file (../plugin/ for development layout)
    if "`plugin_path'" == "" {
    capture findfile _trop_load_plugin.ado
    if !_rc {
        local ado_fullpath "`r(fn)'"
        // Normalize path separators (Windows uses backslash)
        local ado_fullpath : subinstr local ado_fullpath "\" "/", all
        // (1a) Replace /ado/ segment with /plugin/ in the resolved path
        local _plugin_candidate : subinstr local ado_fullpath ///
            "/ado/_trop_load_plugin.ado" "/plugin/`plugin_name'"
        if "`_plugin_candidate'" != "`ado_fullpath'" {
            capture confirm file "`_plugin_candidate'"
            if !_rc {
                local plugin_path "`_plugin_candidate'"
            }
        }
        // (1b) Traverse to parent directory of ado/ and check plugin/
        if "`plugin_path'" == "" {
            local _spos = strrpos("`ado_fullpath'", "/")
            if `_spos' > 0 {
                local _ado_dir = substr("`ado_fullpath'", 1, `_spos' - 1)
                local _spos2 = strrpos("`_ado_dir'", "/")
                if `_spos2' > 0 {
                    local _pkg_root = substr("`_ado_dir'", 1, `_spos2' - 1)
                    capture confirm file "`_pkg_root'/plugin/`plugin_name'"
                    if !_rc {
                        local plugin_path "`_pkg_root'/plugin/`plugin_name'"
                    }
                }
            }
        }
    }
    }

    // (2)--(4) Paths relative to the current working directory
    local pwd = c(pwd)

    if "`plugin_path'" == "" {
        capture confirm file "`pwd'/trop_stata/plugin/`plugin_name'"
        if !_rc {
            local plugin_path "`pwd'/trop_stata/plugin/`plugin_name'"
        }
    }

    if "`plugin_path'" == "" {
        capture confirm file "`pwd'/../plugin/`plugin_name'"
        if !_rc {
            local plugin_path "`pwd'/../plugin/`plugin_name'"
        }
    }

    if "`plugin_path'" == "" {
        capture confirm file "`pwd'/plugin/`plugin_name'"
        if !_rc {
            local plugin_path "`pwd'/plugin/`plugin_name'"
        }
    }

    // (5) Search along adopath
    if "`plugin_path'" == "" {
        capture findfile `plugin_name'
        if !_rc {
            local plugin_path = r(fn)
        }
    }

    // Report failure with diagnostic information
    if "`plugin_path'" == "" {
        di as error "Plugin binary not found: `plugin_name'"
        di as error ""
        di as error "Platform: `platform_desc'"
        di as error "Current directory: `pwd'"
        di as error ""
        di as error "Locations searched:"
        if "`ado_fullpath'" != "" {
            di as error "  0. Same dir as ado: `ado_fullpath' -> ./"
            di as error "  1. Relative to ado file: `ado_fullpath' -> ../plugin/"
        }
        else {
            di as error "  0-1. (ado file not found in adopath)"
        }
        di as error "  2. `pwd'/trop_stata/plugin/"
        di as error "  3. `pwd'/../plugin/"
        di as error "  4. `pwd'/plugin/"
        di as error "  5. adopath (PERSONAL, PLUS, SITE)"
        di as error ""
        di as error "Ensure the package directory structure is intact,"
        di as error "or add the ado directory to adopath:"
        di as error `"  . adopath + "/path/to/trop_stata/ado""'
        exit 601
    }

    // Return resolved plugin details to the caller
    c_local _plugin_name `plugin_name'
    c_local _plugin_path `plugin_path'
    c_local _platform_desc `platform_desc'
end
