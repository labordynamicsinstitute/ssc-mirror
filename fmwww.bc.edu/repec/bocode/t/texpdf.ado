*! version 0.1.0 28aug2026
program define texpdf, rclass
    version 14.1
    syntax [using/] [, SAVing(string) REPLACE VERSION VIEW]

    if "`version'" != "" {
        if `"`using'"' != "" | `"`saving'"' != "" | "`replace'" != "" | ///
                "`view'" != "" {
            display as error "option version may not be combined with using, saving(), replace, or view"
            exit 198
        }

        quietly _texpdf_load_plugin
        tempfile result
        capture noisily plugin call _texpdf_plugin, version `"`result'"'
        local plugin_rc = _rc
        if `plugin_rc' {
            display as error "texpdf native plugin invocation failed (r(`plugin_rc'))"
            exit `plugin_rc'
        }
        quietly _texpdf_read_result using `"`result'"'
        local native_status `"`r(status)'"'
        local native_rc = r(rc)
        local native_message `"`r(message)'"'
        local native_diagnostics `"`r(diagnostics)'"'
        local engine `"`r(engine)'"'
        local engine_version `"`r(engine_version)'"'
        local bundle_version `"`r(bundle_version)'"'
        local bundle_digest `"`r(bundle_digest)'"'
        local bundle_zip_sha256 `"`r(bundle_zip_sha256)'"'
        local warnings = r(warnings)

        if `"`native_status'"' != "success" {
            if `"`native_message'"' != "" display as error `"`native_message'"'
            if `"`native_diagnostics'"' != "" display as error `"`native_diagnostics'"'
            if missing(`native_rc') | `native_rc' == 0 local native_rc 710
            exit `native_rc'
        }

        display as text "texpdf 0.1.0; engine " as result "Tectonic `engine_version'"
        return local engine `"`engine'"'
        return local engine_version `"`engine_version'"'
        return local bundle_version `"`bundle_version'"'
        return local bundle_digest `"`bundle_digest'"'
        return local bundle_zip_sha256 `"`bundle_zip_sha256'"'
        return scalar warnings = `warnings'
        exit
    }

    if `"`using'"' == "" {
        display as error "using filename is required"
        exit 198
    }

    local input `"`using'"'
    local output `"`saving'"'
    if `"`output'"' == "" {
        local input_length = ustrlen(`"`input'"')
        local suffix ""
        if `input_length' >= 4 {
            local suffix_start = `input_length' - 3
            local suffix = ustrlower(usubstr(`"`input'"', `suffix_start', 4))
        }
        if `"`suffix'"' == ".tex" {
            local prefix_length = `input_length' - 4
            if `prefix_length' > 0 {
                local prefix = usubstr(`"`input'"', 1, `prefix_length')
                local output `"`prefix'.pdf"'
            }
            else local output `"`input'.pdf"'
        }
        else local output `"`input'.pdf"'
    }

    local replace_flag = cond("`replace'" == "", 0, 1)
    quietly _texpdf_load_plugin
    tempfile result
    capture noisily plugin call _texpdf_plugin, compile `"`input'"' `"`output'"' `"`result'"' `replace_flag' 0
    local plugin_rc = _rc
    if `plugin_rc' {
        display as error "texpdf native plugin invocation failed (r(`plugin_rc'))"
        exit `plugin_rc'
    }

    quietly _texpdf_read_result using `"`result'"'
    local native_status `"`r(status)'"'
    local native_rc = r(rc)
    local native_message `"`r(message)'"'
    local native_diagnostics `"`r(diagnostics)'"'
    local pdf `"`r(pdf)'"'
    local engine `"`r(engine)'"'
    local engine_version `"`r(engine_version)'"'
    local bundle_version `"`r(bundle_version)'"'
    local bundle_digest `"`r(bundle_digest)'"'
    local bundle_zip_sha256 `"`r(bundle_zip_sha256)'"'
    local warnings = r(warnings)

    if `"`native_status'"' != "success" {
        if `"`native_message'"' != "" display as error `"`native_message'"'
        if `"`native_diagnostics'"' != "" display as error `"`native_diagnostics'"'
        if missing(`native_rc') | `native_rc' == 0 local native_rc 710
        exit `native_rc'
    }

    display as text "PDF written to " as result `"`pdf'"'
    if "`view'" != "" {
        capture noisily _texpdf_view_pdf `"`pdf'"'
        if _rc {
            display as text "PDF was written but could not be opened automatically"
        }
    }
    return local pdf `"`pdf'"'
    return local engine `"`engine'"'
    return local engine_version `"`engine_version'"'
    return local bundle_version `"`bundle_version'"'
    return local bundle_digest `"`bundle_digest'"'
    return local bundle_zip_sha256 `"`bundle_zip_sha256'"'
    return scalar warnings = `warnings'
end

program define _texpdf_load_plugin
    version 14.1

    local operating_system `"`c(os)'"'
    if `"`operating_system'"' == "MacOSX" | ///
            (`"`operating_system'"' == "Unix" & ///
            strmatch(`"`c(machine_type)'"', "Mac*")) {
        local plugin_file "_texpdf_plugin_macosx.plugin"
    }
    else if `"`operating_system'"' == "Unix" {
        local plugin_file "_texpdf_plugin_unix.plugin"
    }
    else if `"`operating_system'"' == "Windows" {
        local plugin_file "_texpdf_plugin_windows.plugin"
    }
    else {
        display as error "texpdf does not include a native plugin for `operating_system'"
        display as error "install a texpdf package for macOS, Linux, or 64-bit Windows"
        exit 601
    }

    local generic_plugin "_texpdf_plugin.plugin"
    capture quietly findfile `"`plugin_file'"'
    local canonical_found = (_rc == 0)
    capture quietly findfile `"`generic_plugin'"'
    local generic_found = (_rc == 0)
    capture quietly findfile "_texpdf_ssc_install.ado"
    local ssc_marker_found = (_rc == 0)

    if `canonical_found' & (`generic_found' | `ssc_marker_found') {
        display as error "texpdf found files from both GitHub and SSC installations"
        display as error "run ado uninstall texpdf, restart Stata, and reinstall from one channel"
        exit 601
    }

    if `canonical_found' {
        local selected_plugin `"`plugin_file'"'
    }
    else if `ssc_marker_found' {
        if !`generic_found' {
            display as error "texpdf found an incomplete SSC installation"
            display as error "run ssc install texpdf, replace and restart Stata"
            exit 601
        }
        capture quietly _texpdf_ssc_install
        local marker_rc = _rc
        if `marker_rc' {
            display as error "texpdf could not validate its SSC installation marker"
            display as error "run ssc install texpdf, replace and restart Stata"
            exit 601
        }
        local marker_version `"`r(package_version)'"'
        local marker_distribution `"`r(distribution)'"'
        local marker_plugin `"`r(plugin_file)'"'
        if `"`marker_version'"' != "0.1.0" | ///
                `"`marker_distribution'"' != "ssc-gh-v1" | ///
                `"`marker_plugin'"' != `"`generic_plugin'"' {
            display as error "texpdf found an obsolete or invalid SSC installation marker"
            display as error "run ssc install texpdf, replace and restart Stata"
            exit 601
        }
        local selected_plugin `"`generic_plugin'"'
    }
    else if `generic_found' {
        display as error "texpdf found a stale generic native plugin without an SSC marker"
        display as error "run ado uninstall texpdf, restart Stata, and reinstall texpdf"
        exit 601
    }
    else {
        display as error "texpdf could not find `plugin_file'"
        display as error "reinstall texpdf for `operating_system' and restart Stata"
        exit 601
    }

    * A native plugin cannot be unloaded and safely reopened for every call.
    * Reuse only a binding created by this dispatcher for the selected and
    * validated installation channel.
    capture program _texpdf_plugin, plugin using("`selected_plugin'")
    local load_rc = _rc
    if `load_rc' == 110 {
        local loaded_plugin "$TEXPDF_NATIVE_PLUGIN_FILE"
        if `"`loaded_plugin'"' == `"`selected_plugin'"' exit
        display as error "texpdf found an unknown or stale native plugin in this Stata session"
        display as error "restart Stata after reinstalling texpdf"
        exit 601
    }
    if `load_rc' {
        display as error "texpdf could not load `selected_plugin'"
        display as error "reinstall texpdf for `operating_system' and restart Stata"
        exit 601
    }
    global TEXPDF_NATIVE_PLUGIN_FILE "`selected_plugin'"
end

program define _texpdf_view_pdf
    version 14.1
    args pdf

    * Release CI supplies an isolated capture file so runnable help examples
    * verify the view request without launching a desktop application.
    local viewer_log : environment TEXPDF_VIEW_LOG
    if `"`viewer_log'"' != "" {
        tempname viewer_handle
        capture file open `viewer_handle' using `"`viewer_log'"', write text append
        if _rc {
            display as error "texpdf could not record the PDF viewer request"
            exit 603
        }
        file write `viewer_handle' `"`pdf'"' _n
        file close `viewer_handle'
        exit
    }

    local unsafe = strpos(`"`pdf'"', char(36)) | ///
        strpos(`"`pdf'"', char(96)) | strpos(`"`pdf'"', char(34)) | ///
        strpos(`"`pdf'"', char(10)) | strpos(`"`pdf'"', char(13))
    if "`=c(os)'" == "Windows" {
        local unsafe = `unsafe' | strpos(`"`pdf'"', "%")
    }
    if `unsafe' {
        display as error "PDF viewer path contains unsupported shell-expansion characters"
        exit 198
    }

    if "`=c(os)'" == "Windows" {
        shell start "" "`pdf'"
    }
    else if "`c(os)'" == "MacOSX" | ///
            ("`c(os)'" == "Unix" & strmatch("`c(machine_type)'", "Mac*")) {
        shell open "`pdf'"
    }
    else if "`=c(os)'" == "Unix" {
        shell xdg-open "`pdf'"
    }
    else {
        display as error "automatic PDF viewing is unsupported on this operating system"
        exit 198
    }
end

program define _texpdf_read_result, rclass
    version 14.1
    syntax using/

    capture confirm file `"`using'"'
    if _rc {
        display as error "texpdf native plugin did not create a result record"
        exit 710
    }

    tempname handle
    capture file open `handle' using `"`using'"', read text
    if _rc {
        display as error "texpdf could not open the native result record"
        exit 710
    }

    local schema_version ""
    local status ""
    local native_rc ""
    local operation ""
    local message ""
    local diagnostics ""
    local pdf ""
    local engine ""
    local engine_version ""
    local bundle_version ""
    local bundle_digest ""
    local bundle_zip_sha256 ""
    local warnings "0"
    local diagnostic_count "0"

    file read `handle' line
    while r(eof) == 0 {
        local equals = ustrpos(`"`line'"', "=")
        if `equals' > 1 {
            local key = usubstr(`"`line'"', 1, `equals' - 1)
            local value_length = ustrlen(`"`line'"') - `equals'
            local value = usubstr(`"`line'"', `equals' + 1, `value_length')

            if `"`key'"' == "schema_version" local schema_version `"`value'"'
            else if `"`key'"' == "status" local status `"`value'"'
            else if `"`key'"' == "rc" local native_rc `"`value'"'
            else if `"`key'"' == "operation" local operation `"`value'"'
            else if `"`key'"' == "message" local message `"`value'"'
            else if `"`key'"' == "pdf" local pdf `"`value'"'
            else if `"`key'"' == "engine" local engine `"`value'"'
            else if `"`key'"' == "engine_version" local engine_version `"`value'"'
            else if `"`key'"' == "bundle_version" local bundle_version `"`value'"'
            else if `"`key'"' == "bundle_digest" local bundle_digest `"`value'"'
            else if `"`key'"' == "bundle_zip_sha256" local bundle_zip_sha256 `"`value'"'
            else if `"`key'"' == "warnings" local warnings `"`value'"'
            else if `"`key'"' == "diagnostic_count" local diagnostic_count `"`value'"'
            else if regexm(`"`key'"', "^diagnostic_[0-9]+_message$") {
                if `"`diagnostics'"' == "" local diagnostics `"`value'"'
                else local diagnostics `"`diagnostics' | `value'"'
            }
        }
        file read `handle' line
    }
    file close `handle'

    if `"`schema_version'"' != "1" {
        display as error "unsupported or malformed texpdf native result record"
        exit 710
    }
    if !inlist(`"`status'"', "success", "failure") {
        display as error "malformed texpdf native status"
        exit 710
    }

    local rc_number = real(`"`native_rc'"')
    if missing(`rc_number') {
        display as error "malformed texpdf native return code"
        exit 710
    }
    local warning_number = real(`"`warnings'"')
    if missing(`warning_number') local warning_number 0
    local diagnostic_number = real(`"`diagnostic_count'"')
    if missing(`diagnostic_number') local diagnostic_number 0

    return local status `"`status'"'
    return scalar rc = `rc_number'
    return local operation `"`operation'"'
    return local message `"`message'"'
    return local diagnostics `"`diagnostics'"'
    return local pdf `"`pdf'"'
    return local engine `"`engine'"'
    return local engine_version `"`engine_version'"'
    return local bundle_version `"`bundle_version'"'
    return local bundle_digest `"`bundle_digest'"'
    return local bundle_zip_sha256 `"`bundle_zip_sha256'"'
    return scalar warnings = `warning_number'
    return scalar diagnostic_count = `diagnostic_number'
end
