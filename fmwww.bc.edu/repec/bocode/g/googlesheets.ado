*! googlesheets v0.1.1  2026-07-04
*! Stata wrapper for the Google Sheets API.
*!
*! Read, write, and structurally edit Google Sheets from Stata, the way
*! `import excel' / `export excel' / `putexcel' work but against a Sheet
*! identified by URL or spreadsheet ID.  Surgical placement of values
*! and matrices, on-demand cell formatting, sheet (tab) management, and
*! filtered reads of Google Forms response sheets.
*!
*! Subcommand interface:
*!     googlesheets import      using "<id-or-url>" [, ...]
*!     googlesheets export      using "<id-or-url>" [, ...]
*!     googlesheets put         using "<id-or-url>" , cell() ...
*!     googlesheets list                            , spreadsheet()
*!     googlesheets ping                            , spreadsheet()
*!     googlesheets create                          , title() [sheettitle()]
*!     googlesheets addsheet                        , spreadsheet() title()
*!     googlesheets deletesheet                     , spreadsheet() title()
*!     googlesheets renamesheet                     , spreadsheet() ...
*!     googlesheets format                          , spreadsheet() ...
*!
*! Setup: see `help googlesheets##setup'.
*!
*! Authorship: Eric Booth, Texas 2036.  MIT-licensed.

program define googlesheets
    version 17.0
    * Subcommand may be followed immediately by a comma (no space) when
    * the user types e.g. `googlesheets ping, spreadsheet(...)'.  Use
    * parse(", ") so gettoken peels just the keyword and leaves the
    * leading comma on `0' for the subcommand handler's syntax line.
    gettoken sub 0 : 0, parse(", ")
    if "`sub'" == "" {
        display as error "googlesheets: missing subcommand"
        display as error "  Valid: create | import | export | put | list | ping | addsheet"
        display as error "         | deletesheet | renamesheet | format"
        display as error "  See {bf:help googlesheets}."
        exit 198
    }
    local sub = lower(strtrim("`sub'"))
    local _valid "create import export put list ping addsheet deletesheet renamesheet format addchart help"
    if !`:list sub in _valid' {
        display as error "googlesheets: unknown subcommand '`sub''"
        display as error "  Valid: `_valid'"
        exit 198
    }
    if "`sub'" == "help" {
        help googlesheets
        exit 0
    }
    googlesheets_`sub' `0'
end
