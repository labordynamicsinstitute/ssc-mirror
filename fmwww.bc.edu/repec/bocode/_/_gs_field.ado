*! _gs_field v0.1.0  2026-06-27
*! Extract `key=value' from a content blob returned by googlesheets_runpy.
*! INTERNAL helper.  Used by every googlesheets_* subcommand that needs
*! to pull individual result fields out of the runpy r(content) blob.
*!
*! Usage:
*!   googlesheets_runpy, args(...)
*!   local content `"`r(content)'"'
*!   _gs_field, content(`"`content'"') key("title")
*!   local title `"`r(value)'"'

program define _gs_field, rclass
version 17.0
    syntax , CONTENT(string) KEY(string)

    local _val ""
    local _nl = char(10)
    local _rest `"`content'"'
    while `"`_rest'"' != "" {
        local _pos = strpos(`"`_rest'"', "`_nl'")
        if `_pos' > 0 {
            local _line = substr(`"`_rest'"', 1, `_pos' - 1)
            local _rest = substr(`"`_rest'"', `_pos' + 1, .)
        }
        else {
            local _line `"`_rest'"'
            local _rest ""
        }
        local _eqpos = strpos(`"`_line'"', "=")
        if `_eqpos' > 0 {
            local _k = substr(`"`_line'"', 1, `_eqpos' - 1)
            if `"`_k'"' == `"`key'"' {
                local _val = substr(`"`_line'"', `_eqpos' + 1, .)
            }
        }
    }
    return local value `"`_val'"'
end
