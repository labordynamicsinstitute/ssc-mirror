*! googlesheets_import v0.1.0  2026-06-27
*! Import a range of cells from a Google Sheet into the current Stata
*! dataset.  Modelled on `import excel using ...'.
*!
*!   googlesheets import using "<id-or-url>" , sheet("Tab name") [range("A1:Z")]   ///
*!       [firstrow] [clear] [stringall] [since(timestamp=2026-01-01)] [tail(50)] ///
*!       [keyfile() tokenfile() verbose]
*!
*! Options:
*!   sheet(name)    sheet (tab) to read from
*!   range(A1:Z)    optional cell range (default: all cells on the sheet)
*!   firstrow       treat the first row as variable names (like `import excel')
*!   clear          drop current data before importing (like `import excel')
*!   stringall      force all columns to string (skip Stata's type detection)
*!   since(col=val) keep only rows where `col' (header name or 0-based int) >= val
*!   tail(N)        keep only the last N rows (after `since' filter)
*!
*! Form-data shortcuts: combine `since' + `tail' to grab "new responses
*! since X" or "the most recent N responses" without dragging the full
*! Form Responses tab through every refresh.

program define googlesheets_import
    version 17.0
    syntax using/, SHeet(string) [ RANGE(string) FIRSTrow CLEAR STRINGall ///
        SInce(string) TAIL(integer 0) KEYfile(string) TOKENfile(string) VERBose ]

    if "`clear'" != "" {
        clear
    }

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

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

    * Data-out path (TSV the helper will write).
    tempfile dataout

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"read_range","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "sheet":"`sh'""'
    if "`range'" != "" file write _h `","' _n `"  "range":"`rg'""'
    if `tail' > 0     file write _h `","' _n `"  "tail":`tail'"'
    if "`since'" != "" {
        * since() is parsed as "column=value"
        local _eqp = strpos("`since'", "=")
        if `_eqp' == 0 {
            display as error "since() must be in the form column=value"
            exit 198
        }
        local _scol = substr("`since'", 1, `_eqp' - 1)
        local _sval = substr("`since'", `_eqp' + 1, .)
        _gs_jesc, raw(`"`_scol'"')
        local _scol_j `"`r(escaped)'"'
        _gs_jesc, raw(`"`_sval'"')
        local _sval_j `"`r(escaped)'"'
        file write _h `","' _n `"  "since":{"column":"`_scol_j'","value":"`_sval_j'"}"'
    }
    file write _h `","' _n `"  "data_out_path":"`dataout'""' _n
    file write _h `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets import: `r(error)' -- `r(message)'"
        exit 198
    }

    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("nrows")
    local nrows = real("`r(value)'")
    _gs_field, content(`"`content'"') key("ncols")
    local ncols = real("`r(value)'")

    capture confirm file `"`dataout'"'
    if _rc {
        display as error "googlesheets import: no data file written (`nrows' rows reported)."
        exit 198
    }

    * Load via import delimited.  Stata's option is varnames(#) -- 1 for
    * "row 1 holds variable names", "nonames" for "every row is data".
    local _vn = cond("`firstrow'" != "", "varnames(1)", "varnames(nonames)")
    local _sa = cond("`stringall'" != "", "stringcols(_all)", "")
    quietly import delimited using `"`dataout'"', delimiter(tab) `_vn' `_sa' clear

    display as result _n "[googlesheets import]"
    display as text   "  spreadsheet: `using'"
    display as text   "  sheet:       `sheet'"
    if "`range'" != "" display as text "  range:       `range'"
    if "`since'" != "" display as text "  since:       `since'"
    if `tail'  > 0     display as text "  tail:        `tail'"
    display as text   "  loaded:      `=_N' obs x `=c(k)' vars  (helper reported `nrows' x `ncols')"
end
