*! Load the trop Mata library into memory.
*! Uses a cascading search: precompiled library, then source compilation.

program _trop_load_mata
    version 17

    local mata_loaded = 0

    // Check whether trop Mata functions are already available.
    // `mata which` searches both in-memory and mlib-indexed functions,
    // unlike `mata describe` which only checks in-memory functions.
    capture mata: mata which trop_main()
    if _rc == 0 {
        local mata_loaded = 1
    }

    // --- Strategy 1: Precompiled mlib library ---
    // Refresh the Mata library index so that ltrop.mlib on the adopath
    // becomes available.  After `net install`, ltrop.mlib resides in
    // c(sysdir_plus)l/ and is auto-loaded; for development use the
    // explicit index refresh is needed.
    if !`mata_loaded' {
        capture mata: mata mlib index
        capture mata: mata which trop_main()
        if _rc == 0 {
            local mata_loaded = 1
        }
    }

    // Strategy 1b: Explicitly locate and load ltrop.mlib via findfile.
    if !`mata_loaded' {
        capture qui findfile ltrop.mlib
        if !_rc {
            local _mlib_path "`r(fn)'"
            capture mata: mata mlib add ltrop using "`_mlib_path'"
            capture mata: mata which trop_main()
            if _rc == 0 {
                local mata_loaded = 1
            }
        }
    }

    // Strategy 1c: Derive mlib path from trop.ado location.
    if !`mata_loaded' {
        capture qui findfile trop.ado
        if !_rc {
            local ado_path "`r(fn)'"
            // Normalize path separators (Windows uses backslash)
            local ado_path : subinstr local ado_path "\" "/", all
            local trop_dir = subinstr("`ado_path'", "/ado/trop.ado", "", 1)
            capture confirm file "`trop_dir'/ltrop.mlib"
            if !_rc {
                capture mata: mata mlib add ltrop using "`trop_dir'/ltrop.mlib"
                capture mata: mata which trop_main()
                if _rc == 0 {
                    local mata_loaded = 1
                }
            }
        }
    }

    // --- Strategy 2: Source compilation via load_mata_once.do ---

    // Try load_mata_once.do in the current working directory.
    if !`mata_loaded' {
        capture qui do "`c(pwd)'/load_mata_once.do"
        if _rc == 0 {
            local mata_loaded = 1
        }
    }

    // Try trop_stata/ subdirectory relative to the working directory.
    if !`mata_loaded' {
        capture qui do "`c(pwd)'/trop_stata/load_mata_once.do"
        if _rc == 0 {
            local mata_loaded = 1
        }
    }

    // Derive the package root from the installed location of trop.ado.
    if !`mata_loaded' {
        capture qui findfile trop.ado
        if !_rc {
            local ado_path "`r(fn)'"
            local ado_path : subinstr local ado_path "\" "/", all
            local trop_dir = subinstr("`ado_path'", "/ado/trop.ado", "", 1)
            capture qui do "`trop_dir'/load_mata_once.do"
            if _rc == 0 {
                capture mata: mata describe trop_main()
                if _rc == 0 {
                    local mata_loaded = 1
                }
            }
        }
    }

    // Search the adopath for load_mata_once.do.
    if !`mata_loaded' {
        capture qui findfile load_mata_once.do
        if !_rc {
            capture qui do "`r(fn)'"
            if _rc == 0 {
                local mata_loaded = 1
            }
        }
    }

    // --- Strategy 3: Source compilation fallback ---

    // Compile all Mata sources via compile_all.do.
    if !`mata_loaded' {
        capture qui findfile trop.ado
        if !_rc {
            local ado_path "`r(fn)'"
            local ado_path : subinstr local ado_path "\" "/", all
            local trop_dir = subinstr("`ado_path'", "/ado/trop.ado", "", 1)
            capture qui do "`trop_dir'/mata/compile_all.do"
            if _rc == 0 {
                local mata_loaded = 1
            }
        }
    }

    // Compile individual .mata files found on the adopath.
    if !`mata_loaded' {
        capture qui findfile trop_constants.mata
        if !_rc {
            foreach mf in trop_constants ///
                trop_rust_interface trop_data_transfer trop_lambda_grid ///
                trop_backend_select trop_ereturn_store ///
                trop_validation ///
                trop_loocv_validation trop_bootstrap_diagnostics ///
                trop_estat_helpers ///
                trop_main {
                capture qui findfile `mf'.mata
                if !_rc {
                    capture qui do "`r(fn)'"
                }
            }
            capture mata: mata which trop_main()
            if _rc == 0 {
                local mata_loaded = 1
            }
        }
    }

    if !`mata_loaded' {
        di as error "failed to load trop Mata library"
        di as error "ensure ltrop.mlib or Mata source files are on the adopath"
        exit 601
    }

    c_local mata_loaded 1
end
