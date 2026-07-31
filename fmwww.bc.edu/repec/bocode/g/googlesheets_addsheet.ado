*! googlesheets_addsheet v0.1.0  2026-06-27
*! Add a new sheet (tab) to a Google Sheet.
*!   googlesheets addsheet, spreadsheet("<id-or-url>") title("New Tab")    ///
*!       [rows(1000) cols(26) index(0) keyfile() tokenfile() verbose]

program define googlesheets_addsheet, rclass
    version 17.0
    syntax , SPReadsheet(string) TITLE(string)              ///
        [ ROWS(integer 0) COLS(integer 0) INDex(integer -1) ///
          KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    _gs_jesc, raw(`"`client_json'"')
    local cj `"`r(escaped)'"'
    _gs_jesc, raw(`"`token_json'"')
    local tj `"`r(escaped)'"'
    _gs_jesc, raw(`"`spreadsheet'"')
    local ss `"`r(escaped)'"'
    _gs_jesc, raw(`"`title'"')
    local ti `"`r(escaped)'"'

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"add_sheet","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "title":"`ti'""'
    if `rows' > 0  file write _h `","' _n `"  "rows":`rows'"'
    if `cols' > 0  file write _h `","' _n `"  "cols":`cols'"'
    if `index' >= 0 file write _h `","' _n `"  "index":`index'"'
    file write _h _n `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets addsheet: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("title")
    local new_title `"`r(value)'"'
    _gs_field, content(`"`content'"') key("sheetId")
    local new_id `"`r(value)'"'

    display as result _n "[googlesheets addsheet]"
    display as text   "  added tab:  `new_title'  (sheetId=`new_id')"
    display as text   "  in:         `spreadsheet'"

    return local title    `"`new_title'"'
    return local sheetId  `"`new_id'"'
end
