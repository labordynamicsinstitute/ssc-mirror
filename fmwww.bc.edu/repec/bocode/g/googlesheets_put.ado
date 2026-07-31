*! googlesheets_put v0.1.0  2026-06-27
*! Surgical placement of a single value, formula, or matrix into specific
*! cells of a Google Sheet.  Modelled on Stata's `putexcel'.
*!
*!   googlesheets put using "<id-or-url>" , sheet("Tab") cell(A1)               ///
*!       ( value(.)   |  string("text")  |  formula("=SUM(...)")  |  matrix(M) ) ///
*!       [keyfile() tokenfile() verbose]
*!
*! Exactly one of value/string/formula/matrix must be supplied.

program define googlesheets_put
    version 17.0
    syntax using/, SHeet(string) CELL(string)             ///
        [ VALue(string) STRing(string) FORMula(string) MATrix(string) ///
          KEYfile(string) TOKENfile(string) VERBose ]

    * Validate exactly-one source.
    local _n = 0
    if `"`value'"' != ""   local _n = `_n' + 1
    if `"`string'"' != ""  local _n = `_n' + 1
    if `"`formula'"' != "" local _n = `_n' + 1
    if `"`matrix'"' != ""  local _n = `_n' + 1
    if `_n' != 1 {
        display as error "googlesheets put: pass exactly one of value() / string() / formula() / matrix()."
        exit 198
    }

    * Build a 2D values list as JSON.
    if `"`matrix'"' != "" {
        capture confirm matrix `matrix'
        if _rc {
            display as error "googlesheets put: matrix(`matrix') -- no such matrix in memory"
            exit 198
        }
        local nr = rowsof(`matrix')
        local nc = colsof(`matrix')
        local rows_json "["
        forvalues i = 1/`nr' {
            if `i' > 1 local rows_json `"`rows_json',"'
            local rows_json `"`rows_json'["'
            forvalues j = 1/`nc' {
                local v = `matrix'[`i', `j']
                if `j' > 1 local rows_json `"`rows_json',"'
                if `v' < . {
                    * JSON requires a leading 0 before the decimal -- e.g.
                    * "0.42" not ".42".  strofreal pads it correctly.
                    local _vstr = strofreal(`v', "%18.0g")
                    if substr("`_vstr'", 1, 1) == "." {
                        local _vstr "0`_vstr'"
                    }
                    else if substr("`_vstr'", 1, 2) == "-." {
                        local _vstr = "-0" + substr("`_vstr'", 2, .)
                    }
                    local rows_json `"`rows_json'`_vstr'"'
                }
                else local rows_json `"`rows_json'null"'
            }
            local rows_json `"`rows_json']"'
        }
        local rows_json `"`rows_json']"'
        local range `"`cell'"'
    }
    else {
        if `"`value'"' != "" {
            * Validate numeric.  Treat Stata missing (`.') as JSON null;
            * any other non-numeric input fails confirm and aborts.
            if `"`value'"' == "." {
                local rows_json `"[[null]]"'
            }
            else {
                confirm number `value'
                * JSON requires a leading zero on .42 -> 0.42
                local _vs = "`value'"
                if substr("`_vs'", 1, 1) == "."          local _vs "0`_vs'"
                else if substr("`_vs'", 1, 2) == "-."   local _vs = "-0" + substr("`_vs'", 2, .)
                local rows_json `"[[`_vs']]"'
            }
        }
        else if `"`string'"' != "" {
            _gs_jesc, raw(`"`string'"')
            local rows_json `"[["`r(escaped)'"]]"'
        }
        else {
            _gs_jesc, raw(`"`formula'"')
            local rows_json `"[["`r(escaped)'"]]"'
        }
        local range `"`cell'"'
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

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"write_range","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "sheet":"`sh'","' _n
    file write _h `"  "range":"`rg'","' _n
    file write _h `"  "values":`rows_json'"' _n
    file write _h `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets put: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("updatedRange")
    local upd `"`r(value)'"'

    display as result _n "[googlesheets put]"
    display as text   "  spreadsheet: `using'"
    display as text   "  cell:        `sheet'!`cell'"
    display as text   "  updated:     `upd'"
end
