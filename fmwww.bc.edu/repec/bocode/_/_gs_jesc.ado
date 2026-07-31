*! _gs_jesc v0.1.0  2026-06-27
*! JSON-escape a Stata string for embedding in a JSON value.  Internal
*! helper used by every googlesheets_* subcommand that writes the args
*! JSON file consumed by googlesheets_helper.py.
*!
*! Usage:
*!   _gs_jesc, raw("some \backslashes and \"quotes\"")
*!   local escaped `"`r(escaped)'"'
*!
*! Why a Stata wrapper instead of inline subinstr?  Because every
*! subcommand needs the same six-line escape sequence; centralising it
*! avoids drift if (when) the escape rules change.

program define _gs_jesc, rclass
version 17.0
    syntax , [ RAW(string) ]
    local s `"`raw'"'
    local s : subinstr local s `"\"' `"\\"', all
    local s : subinstr local s `"""' `"\""', all
    * Newline and CR are unusual inside spreadsheet IDs or paths, but a
    * value() option could carry a long string -- handle them anyway.
    local s : subinstr local s `"`=char(10)'"' `"\n"', all
    local s : subinstr local s `"`=char(13)'"' `"\r"', all
    local s : subinstr local s `"`=char(9)'"'  `"\t"', all
    return local escaped `"`s'"'
end
