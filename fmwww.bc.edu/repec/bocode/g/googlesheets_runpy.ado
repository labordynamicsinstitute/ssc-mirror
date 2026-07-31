*! googlesheets_runpy v0.1.0  2026-06-27
*! Shell into googlesheets_helper.py with an args JSON file, then surface
*! the status/message/error fields PLUS the raw result-file contents in
*! r() macros.  INTERNAL helper.
*!
*! Returns:
*!   r(status)    "ok" or "error"
*!   r(message)   error message text (empty when ok)
*!   r(error)     exception name (empty when ok)
*!   r(content)   the full result-file contents as one string -- the
*!                caller passes this to _gs_outfield_str() to extract
*!                individual key=value fields.  We can't return a path
*!                because Stata frees tempfiles when the sub-program
*!                ends, deleting the underlying file before the caller
*!                gets to read it.

program define googlesheets_runpy, rclass
    version 17.0
    syntax , ARGS(string) [ VERBose ]

    capture findfile googlesheets_helper.py
    if _rc {
        display as error "googlesheets: googlesheets_helper.py not on adopath."
        display as error "  Reinstall the package."
        exit 601
    }
    local helper "`r(fn)'"

    tempfile outjson
    file open _gsfh using `"`outjson'"', write text replace
    file close _gsfh

    if lower("`c(os)'") == "windows" {
        local PY "python"
    }
    else {
        local PY "python3"
    }

    if "`verbose'" != "" {
        display as text `"[googlesheets] `PY' "`helper'" "`args'" "`outjson'""'
    }
    quietly shell `PY' "`helper'" "`args'" "`outjson'"

    capture confirm file `"`outjson'"'
    if _rc {
        display as error "googlesheets: helper produced no output file."
        display as error "  Is python3 on PATH?  Run the printed command in a terminal to debug."
        exit 198
    }

    * Slurp the entire result-file into a single local so it survives the
    * tempfile cleanup at end-of-program.  These files are small (a few
    * lines of key=value).
    tempname jh
    file open `jh' using `"`outjson'"', read text
    local _content ""
    file read `jh' line
    while r(eof) == 0 {
        if "`_content'" == "" {
            local _content `"`line'"'
        }
        else {
            local _content `"`_content'`=char(10)'`line'"'
        }
        file read `jh' line
    }
    file close `jh'

    if "`verbose'" != "" {
        display as text "[googlesheets] result content:"
        display as text `"`_content'"'
    }

    * Extract the three universal status fields from the in-memory copy.
    _gs_field, content(`"`_content'"') key("status")
    return local status  `"`r(value)'"'
    _gs_field, content(`"`_content'"') key("message")
    return local message `"`r(value)'"'
    _gs_field, content(`"`_content'"') key("error")
    return local error   `"`r(value)'"'

    return local content `"`_content'"'
    return local helper  `"`helper'"'
end
