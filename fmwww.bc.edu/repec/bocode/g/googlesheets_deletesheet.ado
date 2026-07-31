*! googlesheets_deletesheet v0.1.0  2026-06-27
*! Delete a sheet (tab) from a Google Sheet by title.
*!   googlesheets deletesheet, spreadsheet("<id-or-url>") title("Old Tab")

program define googlesheets_deletesheet
    version 17.0
    syntax , SPReadsheet(string) TITLE(string) [ KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local cj_raw `"`r(client_json)'"'
    local tj_raw `"`r(token_json)'"'

    _gs_jesc, raw(`"`cj_raw'"')
    local cj `"`r(escaped)'"'
    _gs_jesc, raw(`"`tj_raw'"')
    local tj `"`r(escaped)'"'
    _gs_jesc, raw(`"`spreadsheet'"')
    local ss `"`r(escaped)'"'
    _gs_jesc, raw(`"`title'"')
    local ti `"`r(escaped)'"'

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"delete_sheet","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "title":"`ti'""' _n
    file write _h `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets deletesheet: `r(error)' -- `r(message)'"
        exit 198
    }
    display as result _n "[googlesheets deletesheet]"
    display as text   "  deleted tab: `title'"
end
