*! googlesheets_renamesheet v0.1.0  2026-06-27
*!   googlesheets renamesheet, spreadsheet("<id-or-url>") from("Old") to("New")

program define googlesheets_renamesheet
    version 17.0
    syntax , SPReadsheet(string) FROM(string) TO(string) [ KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local cj_raw `"`r(client_json)'"'
    local tj_raw `"`r(token_json)'"'

    _gs_jesc, raw(`"`cj_raw'"')
    local cj `"`r(escaped)'"'
    _gs_jesc, raw(`"`tj_raw'"')
    local tj `"`r(escaped)'"'
    _gs_jesc, raw(`"`spreadsheet'"')
    local ss `"`r(escaped)'"'
    _gs_jesc, raw(`"`from'"')
    local fr `"`r(escaped)'"'
    _gs_jesc, raw(`"`to'"')
    local to_j `"`r(escaped)'"'

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"rename_sheet","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "old_title":"`fr'","' _n
    file write _h `"  "new_title":"`to_j'""' _n
    file write _h `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets renamesheet: `r(error)' -- `r(message)'"
        exit 198
    }
    display as result _n "[googlesheets renamesheet]"
    display as text   "  renamed:   `from' -> `to'"
end
