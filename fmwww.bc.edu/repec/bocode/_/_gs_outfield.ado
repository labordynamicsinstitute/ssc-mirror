*! _gs_outfield v0.1.0  2026-06-27
*! Read a key=value summary file written by googlesheets_helper.py and
*! return the value of `key' as r(value).  INTERNAL helper.
*!
*! File format (written by the Python helper):
*!   status=ok
*!   title=My Spreadsheet
*!   sheets=Sheet1|Sheet2|Sheet3
*!
*! Usage:
*!   _gs_outfield, path("/tmp/out.tsv") key("title")
*!   local title `"`r(value)'"'

program define _gs_outfield, rclass
version 17.0
    syntax , SRC(string) KEY(string)

    tempname jh
    capture file open `jh' using `"`src'"', read text
    if _rc {
        return local value ""
        exit 0
    }
    local _val ""
    local _found = 0
    file read `jh' line
    while r(eof) == 0 {
        local _eqpos = strpos(`"`line'"', "=")
        if `_eqpos' > 0 {
            local _k = substr(`"`line'"', 1, `_eqpos' - 1)
            if `"`_k'"' == `"`key'"' {
                local _val = substr(`"`line'"', `_eqpos' + 1, .)
                local _found = 1
                * Keep scanning -- last occurrence wins if duplicated.
            }
        }
        file read `jh' line
    }
    file close `jh'

    return local value `"`_val'"'
    return scalar found = `_found'
end
