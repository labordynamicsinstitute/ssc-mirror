program define mchs, rclass
    version 17

    gettoken subcommand 0 : 0, parse(" ,")
    local subcommand = lower("`subcommand'")

    if "`subcommand'" == "" | "`subcommand'" == "help" {
        _mchs_usage
        exit
    }

    if "`subcommand'" == "import" {
        _mchs_import `0'
        return add
        exit
    }

    if "`subcommand'" == "run" {
        _mchs_run `0'
        return add
        exit
    }

    if "`subcommand'" == "validate" {
        _mchs_validate `0'
        return add
        exit
    }

    display as error "unknown mchs subcommand: `subcommand'"
    _mchs_usage
    exit 198
end

program define _mchs_usage
    version 17
    display as text "MCHS Stata file/CLI boundary adapter"
    display as text "  mchs import using results.csv [, clear saveas(results.dta) replace]"
    display as text "  mchs run using input.csv, calculator(acute) year(2025) output(results.csv) [import clear replace cli(funding-calculator)]"
    display as text "  mchs validate [, required(contract_version calculator_id pricing_year fixture_gate)]"
    display as text "All calculations are delegated to the shared-core CLI; no formula logic runs in Stata."
end

program define _mchs_import, rclass
    version 17
    syntax using/ [, CLEAR SAVEAS(string asis) REPLACE]

    confirm file `"`using'"'
    import delimited using `"`using'"', varnames(1) `clear'

    return local mode "file-import"
    return local input_path `"`using'"'

    if `"`saveas'"' != "" {
        local save_replace ""
        if "`replace'" != "" {
            local save_replace "replace"
        }
        save `"`saveas'"', `save_replace'
        return local dta_output_path `"`saveas'"'
    }
end

program define _mchs_run, rclass
    version 17
    syntax using/ , CALCulator(string) YEAR(string) OUTPUT(string asis) ///
        [CLI(string asis) PARAMS(string asis) IMPORT CLEAR REPLACE]

    confirm file `"`using'"'

    if `"`cli'"' == "" {
        local cli "funding-calculator"
    }

    if "`replace'" == "" {
        capture confirm new file `"`output'"'
        if _rc {
            display as error "output already exists; specify replace to overwrite: `output'"
            exit 602
        }
    }

    local cmd `"`cli' `calculator' "`using'" --output "`output'" --year "`year'""'
    if `"`params'"' != "" {
        local cmd `"`cmd' --params "`params'""'
    }

    display as text "Invoking shared-core CLI through Stata shell boundary."
    quietly display as text `"`cmd'"'
    shell `cmd'
    local rc = _rc
    if `rc' != 0 {
        display as error "shared-core CLI invocation failed with return code `rc'"
        exit `rc'
    }

    confirm file `"`output'"'

    return local mode "cli-invocation"
    return local calculator_id "`calculator'"
    return local pricing_year "`year'"
    return local input_path `"`using'"'
    return local output_path `"`output'"'
    return local cli_command `"`cmd'"'

    if "`import'" != "" {
        import delimited using `"`output'"', varnames(1) `clear'
        return local imported "true"
    }
end

program define _mchs_validate, rclass
    version 17
    syntax [, REQUIRED(string asis)]

    if `"`required'"' == "" {
        local required "contract_version calculator_id pricing_year fixture_gate"
    }

    local missing ""
    local checked = 0
    foreach variable of local required {
        local checked = `checked' + 1
        capture confirm variable `variable'
        if _rc {
            local missing "`missing' `variable'"
        }
    }

    local missing : list retokenize missing
    return scalar checked = `checked'

    if "`missing'" != "" {
        return scalar failed = wordcount("`missing'")
        return local missing "`missing'"
        display as error "missing required file-boundary columns: `missing'"
        exit 459
    }

    return scalar failed = 0
    return local mode "file-import"
    display as text "MCHS Stata file-boundary columns validated."
end
