*! googlesheets_list v0.1.0  2026-06-27
*! List the sheets (tabs) in a Google Sheet.
*!   googlesheets list, spreadsheet("<id-or-url>") [keyfile() tokenfile() verbose]
*! Returns:
*!   r(sheets) -- pipe-separated list of tab titles
*!   r(title)  -- the spreadsheet name

program define googlesheets_list, rclass
    version 17.0
    syntax , SPReadsheet(string) [ KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    _gs_jesc, raw(`"`client_json'"')
    local cj `"`r(escaped)'"'
    _gs_jesc, raw(`"`token_json'"')
    local tj `"`r(escaped)'"'
    _gs_jesc, raw(`"`spreadsheet'"')
    local ss `"`r(escaped)'"'

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"list_sheets","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'""' _n
    file write _h `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets list: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("sheets")
    local sheets `"`r(value)'"'

    display as result _n "[googlesheets list]"
    display as text   "  spreadsheet: `spreadsheet'"
    display as text   "  tabs: `sheets'"

    return local sheets `"`sheets'"'
end
