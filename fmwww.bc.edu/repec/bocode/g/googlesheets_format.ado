*! googlesheets_format v0.1.0  2026-06-27
*! Apply cell formatting (background colour, font, weight, number format)
*! to a range in a Google Sheet.
*!
*!   googlesheets format using "<id-or-url>" , sheet("Tab") range("A1:E1") ///
*!       [bgcolor("#1B2D55")] [fgcolor("#FFFFFF")] [bold]                  ///
*!       [font("Montserrat")] [fontsize(12)]                               ///
*!       [numfmt("0.0%")] [halign(left|center|right)] [wrap]               ///
*!       [keyfile() tokenfile() verbose]
*!
*! At least one styling option must be supplied.

program define googlesheets_format
    version 17.0
    syntax using/, SHeet(string) RANGE(string)              ///
        [ BGcolor(string) FGcolor(string) BOLD ITALic       ///
          FONT(string) FONTSIZE(integer 0) NUMFMT(string)   ///
          HALign(string) WRAP                               ///
          KEYfile(string) TOKENfile(string) VERBose ]

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
    file write _h `"  "subcommand":"format_range","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "sheet":"`sh'","' _n
    file write _h `"  "range":"`rg'""'
    if `"`bgcolor'"' != "" {
        _gs_jesc, raw(`"`bgcolor'"')
        file write _h `","' _n `"  "bgcolor":"`r(escaped)'""'
    }
    if `"`fgcolor'"' != "" {
        _gs_jesc, raw(`"`fgcolor'"')
        file write _h `","' _n `"  "fgcolor":"`r(escaped)'""'
    }
    if "`bold'" != ""    file write _h `","' _n `"  "bold":true"'
    if "`italic'" != ""  file write _h `","' _n `"  "italic":true"'
    if `"`font'"' != "" {
        _gs_jesc, raw(`"`font'"')
        file write _h `","' _n `"  "font":"`r(escaped)'""'
    }
    if `fontsize' > 0    file write _h `","' _n `"  "font_size":`fontsize'"'
    if `"`numfmt'"' != "" {
        _gs_jesc, raw(`"`numfmt'"')
        file write _h `","' _n `"  "number_format":"`r(escaped)'""'
    }
    if `"`halign'"' != "" {
        _gs_jesc, raw(`"`halign'"')
        file write _h `","' _n `"  "horizontal_align":"`r(escaped)'""'
    }
    if "`wrap'" != ""    file write _h `","' _n `"  "wrap":true"'
    file write _h _n `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets format: `r(error)' -- `r(message)'"
        exit 198
    }

    display as result _n "[googlesheets format]"
    display as text   "  spreadsheet: `using'"
    display as text   "  range:       `sheet'!`range'"
end
