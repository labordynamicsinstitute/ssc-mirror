*! googlesheets_create v0.1.1  2026-07-04
*! Create a brand-new Google Sheet (spreadsheet) in the user's Drive and
*! return its id and URL, so a script can build a report from scratch.
*!   googlesheets create, title("My report") [sheettitle("Data")            ///
*!       keyfile() tokenfile() verbose]
*!
*! Returns:
*!   r(id)          the new spreadsheet id
*!   r(url)         the new spreadsheet URL (open it in a browser)
*!   r(spreadsheet) the URL as well (drop-in for later spreadsheet()/using)
*!   r(title)       the spreadsheet title

program define googlesheets_create, rclass
    version 17.0
    syntax , TITLE(string) [ SHEETtitle(string)                 ///
        KEYfile(string) TOKENfile(string) VERBose ]

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    _gs_jesc, raw(`"`client_json'"')
    local cj `"`r(escaped)'"'
    _gs_jesc, raw(`"`token_json'"')
    local tj `"`r(escaped)'"'
    _gs_jesc, raw(`"`title'"')
    local ti `"`r(escaped)'"'

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"create_spreadsheet","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "title":"`ti'""'
    if `"`sheettitle'"' != "" {
        _gs_jesc, raw(`"`sheettitle'"')
        file write _h `","' _n `"  "sheet_title":"`r(escaped)'""'
    }
    file write _h _n `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets create: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("spreadsheetId")
    local new_id `"`r(value)'"'
    _gs_field, content(`"`content'"') key("spreadsheetUrl")
    local new_url `"`r(value)'"'
    _gs_field, content(`"`content'"') key("title")
    local new_title `"`r(value)'"'

    display as result _n "[googlesheets create]"
    display as text   "  created:  `new_title'"
    display as text   "  id:       `new_id'"
    display as text   `"  url:      {browse "`new_url'":`new_url'}"'

    return local id          `"`new_id'"'
    return local url         `"`new_url'"'
    return local spreadsheet `"`new_url'"'
    return local title       `"`new_title'"'
end
