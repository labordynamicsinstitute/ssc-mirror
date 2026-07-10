*! trop_check — Verify TROP installation and runtime environment

/*
    trop_check — Diagnostic utility for the trop package.

    Reports the status of Stata version compatibility, native plugin
    availability, Mata function compilation, and optional third-party
    packages.  Exit silently on success; emit error messages for any
    component that prevents trop from running.
*/

program define trop_check
    version 17.0

    local n_pass = 0
    local n_fail = 0
    local n_warn = 0

    display as text ""
    display as text "{hline 60}"
    display as text "TROP System Check"
    display as text "{hline 60}"

    // Stata version -------------------------------------------------------
    display as text ""
    display as text "{bf:Check 1: Stata Version}"
    if c(stata_version) < 17 {
        display as error "  [FAIL] TROP requires Stata 17+"
        display as error "    Current version: " c(stata_version)
        local n_fail = `n_fail' + 1
    }
    else {
        display as result "  [OK] Stata " c(stata_version) " (>=17 required)"
        local n_pass = `n_pass' + 1
    }

    // Native plugin -------------------------------------------------------
    display as text ""
    display as text "{bf:Check 2: Native Plugin (required)}"
    display as text "  Platform: `c(os)' `c(machine_type)'"

    capture _trop_load_plugin
    if _rc == 0 {
        display as result "  [OK] Plugin found: `_plugin_name'"
        display as result "    Platform: `_platform_desc'"
        if "`_plugin_path'" != "" {
            display as text "    Path: `_plugin_path'"
        }
        local n_pass = `n_pass' + 1
    }
    else {
        display as error "  [FAIL] Native plugin not found"
        display as error "    trop cannot run without the compiled plugin."
        display as error "    See {help trop##installation:trop installation} for details."
        local n_fail = `n_fail' + 1
    }

    // Mata functions ------------------------------------------------------
    display as text ""
    display as text "{bf:Check 3: Mata Functions}"

    local mata_ok = 1
    foreach fn in trop_main trop_store_results trop_prepare_data {
        capture mata: mata which `fn'()
        if _rc == 0 {
            display as result "  [OK] `fn'() available"
        }
        else {
            display as text "  - `fn'() not yet loaded (compiled on first use)"
            local mata_ok = 0
        }
    }

    if `mata_ok' {
        local n_pass = `n_pass' + 1
    }
    else {
        display as text "    Mata functions compile automatically on first invocation."
        local n_warn = `n_warn' + 1
    }

    // Optional third-party packages ---------------------------------------
    display as text ""
    display as text "{bf:Check 4: External Packages (optional)}"

    foreach pkg in synth sdid reghdfe {
        capture which `pkg'
        if _rc == 0 {
            display as result "  [OK] `pkg' installed"
        }
        else {
            display as text "  - `pkg' not found (optional)"
        }
    }

    // Summary -------------------------------------------------------------
    display as text ""
    display as text "{hline 60}"

    if `n_fail' == 0 {
        local warn_str = cond(`n_warn'>0, ", `n_warn' warnings", "")
        display as result "[OK] TROP system check passed (`n_pass' checks OK`warn_str')"
        display as text ""
        display as text "TROP is ready to use."
    }
    else {
        display as error "[FAIL] TROP system check FAILED (`n_fail' critical issue(s))"
        display as error ""
        display as error "Please resolve the issues above before using trop."
    }

    display as text "{hline 60}"
    display as text ""

end
