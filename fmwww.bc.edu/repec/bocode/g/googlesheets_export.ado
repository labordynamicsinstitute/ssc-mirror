*! googlesheets_export v0.1.0  2026-06-27
*! Export the current Stata dataset to a Google Sheet range.
*! Modelled on `export excel using ...'.
*!
*!   googlesheets export using "<id-or-url>" , sheet("Tab name") [range("A1")] ///
*!       [replace] [append] [firstrow(variables)] [keyfile() tokenfile() verbose]
*!
*! Options:
*!   sheet(name)            sheet (tab) to write to
*!   range(A1)              top-left cell (default: A1).  Ignored when append.
*!   replace                overwrite (default behaviour); kept for symmetry
*!                          with `export excel'
*!   append                 append rows to the end of the existing data
*!   firstrow(variables)    write the variable names as the first row
*!
*! The tab named in sheet() must already exist.  Create it first with
*! `googlesheets addsheet, ...' if needed.

program define googlesheets_export
    version 17.0
    syntax using/, SHeet(string) [ RANGE(string) REPLACE APPEND  ///
        FIRSTrow(string) KEYfile(string) TOKENfile(string) VERBose ]

    if "`firstrow'" != "" & "`firstrow'" != "variables" {
        display as error "firstrow() accepts only `variables' (write var names as row 1)"
        exit 198
    }
    if "`range'" == "" local range "A1"

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    * Dump current data to a temp TSV.  The helper will read it.
    tempfile datain
    quietly export delimited using `"`datain'"', delimiter(tab) ///
        `=cond("`firstrow'" != "", "", "novarnames")' replace

    _gs_jesc, raw(`"`client_json'"')
    local cj `"`r(escaped)'"'
    _gs_jesc, raw(`"`token_json'"')
    local tj `"`r(escaped)'"'
    _gs_jesc, raw(`"`using'"')
    local ss `"`r(escaped)'"'
    _gs_jesc, raw(`"`sheet'"')
    local sh `"`r(escaped)'"'
    _gs_jesc, raw(`"`range'"')
    local rg `"`r(escaped)'"'
    _gs_jesc, raw(`"`datain'"')
    local di `"`r(escaped)'"'

    local sub = cond("`append'" != "", "append_range", "write_range")

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"`sub'","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "sheet":"`sh'","' _n
    file write _h `"  "range":"`rg'","' _n
    file write _h `"  "data_in_path":"`di'""' _n
    file write _h `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets export: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("updatedRange")
    local updated `"`r(value)'"'
    _gs_field, content(`"`content'"') key("updatedCells")
    local cells `"`r(value)'"'

    display as result _n "[googlesheets export]"
    display as text   "  spreadsheet: `using'"
    display as text   "  sheet:       `sheet'"
    display as text   "  mode:        `=cond("`append'" != "", "append", "replace")'"
    display as text   "  updated:     `updated'   (`cells' cells)"
end
