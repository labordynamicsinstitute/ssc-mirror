*! googlesheets_addchart v0.2.0  2026-06-28
*! Insert a chart object into a Google Sheet via spreadsheets.batchUpdate.
*! Brand defaults available via `tx2036style' -- Montserrat title, navy
*! title colour, and the Texas 2036 palette for series colours.
*!
*!   googlesheets addchart using "<id-or-url>" ,                          ///
*!       sheet("Sheet1")                                                  ///
*!       type(column | bar | stacked_column | stacked_bar | line | area | ///
*!            scatter | pie | donut)                                      ///
*!       domain("A2:A6")                                                  ///
*!       series("B2:B6")        (one or more, pipe-separated for multi)   ///
*!       [names("Texas|ESC 13|ESC 4")]                                    ///
*!       [colors("#1B2D55|#D44500|#2B6CB0")]                              ///
*!       [title("Finding-first headline")]                                ///
*!       [xlabel("...")] [ylabel("...")]                                  ///
*!       [legendpos(TOP|RIGHT|BOTTOM|LEFT|NONE)]                          ///
*!       [tx2036style]                                                    ///
*!       [pie_hole(0.5)]    (donut hole; donut sets 0.5 by default)       ///
*!       [targetsheet("Charts")] [anchor(H1)]                            ///
*!       [width(540)] [height(360)]                                       ///
*!       [keyfile() tokenfile() verbose]
*!
*! Multiple series: pass them in `series()' separated by `|', and pass
*! parallel lists in `names()' and `colors()'.

program define googlesheets_addchart
    version 17.0
    syntax using/, SHeet(string) TYPE(string) DOMain(string) SEries(string) ///
        [ NAMEs(string) COLors(string)                                 ///
          TITLE(string) SUBtitle(string) XLAbel(string) YLAbel(string) ///
          LEGENDPos(string)                                            ///
          TX2036STyle                                                  ///
          PIEhole(real 0)                                             ///
          TARGETsheet(string) ANCHor(string)                          ///
          WIDTH(integer 540) HEIGHT(integer 360)                       ///
          HEADER                                                       ///
          KEYfile(string) TOKENfile(string) VERBose ]

    if "`anchor'" == "" local anchor "H1"
    * Map user-supplied legendpos (top|right|bottom|left|none) to the
    * Sheets API enum (TOP_LEGEND, ..., NO_LEGEND).  Use explicit branches
    * rather than `upper() + "_LEGEND"' because Stata's expression parser
    * trips on the bare keyword "none" in some contexts.
    local _lp = lower("`legendpos'")
    if "`_lp'" == ""        local legendpos "BOTTOM_LEGEND"
    else if "`_lp'" == "top"    local legendpos "TOP_LEGEND"
    else if "`_lp'" == "right"  local legendpos "RIGHT_LEGEND"
    else if "`_lp'" == "bottom" local legendpos "BOTTOM_LEGEND"
    else if "`_lp'" == "left"   local legendpos "LEFT_LEGEND"
    else if "`_lp'" == "none"   local legendpos "NO_LEGEND"
    else if "`_lp'" == "labeled" local legendpos "LABELED_LEGEND"
    else {
        display as error "googlesheets addchart: legendpos(`legendpos') -- valid: top|right|bottom|left|none|labeled"
        exit 198
    }

    * Apply tx2036 defaults: Montserrat title, navy title colour, and (if
    * the user didn't pass colors()) the Texas 2036 palette for the
    * first few series.
    if "`tx2036style'" != "" {
        local font_family "Montserrat"
        local title_color "#1B2D55"
        if `"`colors'"' == "" {
            local colors "#1B2D55|#D44500|#2B6CB0|#6C7A8D|#7A9D54|#A67B36|#9C5BA5"
        }
    }

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
    _gs_jesc, raw(`"`domain'"')
    local dom `"`r(escaped)'"'
    _gs_jesc, raw(`"`series'"')
    local ser `"`r(escaped)'"'
    _gs_jesc, raw(`"`names'"')
    local nms `"`r(escaped)'"'
    _gs_jesc, raw(`"`colors'"')
    local cls `"`r(escaped)'"'
    _gs_jesc, raw(`"`title'"')
    local ti `"`r(escaped)'"'
    _gs_jesc, raw(`"`subtitle'"')
    local sb `"`r(escaped)'"'
    _gs_jesc, raw(`"`xlabel'"')
    local xl `"`r(escaped)'"'
    _gs_jesc, raw(`"`ylabel'"')
    local yl `"`r(escaped)'"'
    _gs_jesc, raw(`"`targetsheet'"')
    local tgs `"`r(escaped)'"'
    _gs_jesc, raw(`"`anchor'"')
    local anc `"`r(escaped)'"'
    _gs_jesc, raw(`"`font_family'"')
    local ff `"`r(escaped)'"'
    _gs_jesc, raw(`"`title_color'"')
    local tc `"`r(escaped)'"'

    tempfile argjson
    file open _h using `"`argjson'"', write text replace
    file write _h `"{"' _n
    file write _h `"  "subcommand":"add_chart","' _n
    file write _h `"  "client_json":"`cj'","' _n
    file write _h `"  "token_json":"`tj'","' _n
    file write _h `"  "spreadsheet":"`ss'","' _n
    file write _h `"  "sheet":"`sh'","' _n
    file write _h `"  "chart_type":"`type'","' _n
    file write _h `"  "domain_range":"`dom'","' _n
    file write _h `"  "series_ranges":"`ser'""'
    if `"`nms'"' != "" file write _h `","' _n `"  "series_names":"`nms'""'
    if `"`cls'"' != "" file write _h `","' _n `"  "series_colors":"`cls'""'
    if `"`ti'"'  != "" file write _h `","' _n `"  "title":"`ti'""'
    if `"`sb'"'  != "" file write _h `","' _n `"  "subtitle":"`sb'""'
    if `"`xl'"'  != "" file write _h `","' _n `"  "xlabel":"`xl'""'
    if `"`yl'"'  != "" file write _h `","' _n `"  "ylabel":"`yl'""'
    file write _h `","' _n `"  "legend_position":"`legendpos'""'
    if `"`tgs'"' != "" file write _h `","' _n `"  "target_sheet":"`tgs'""'
    file write _h `","' _n `"  "target_cell":"`anc'""'
    file write _h `","' _n `"  "width":`width'"'
    file write _h `","' _n `"  "height":`height'"'
    if `piehole' > 0 {
        * Stata prints .5 not 0.5; JSON requires the leading zero.
        local _ph = strofreal(`piehole', "%18.0g")
        if substr("`_ph'", 1, 1) == "." local _ph "0`_ph'"
        file write _h `","' _n `"  "pie_hole":`_ph'"'
    }
    if "`header'" != "" file write _h `","' _n `"  "has_header":true"'
    if `"`ff'"' != "" file write _h `","' _n `"  "font_family":"`ff'""'
    if `"`tc'"' != "" file write _h `","' _n `"  "title_color":"`tc'""'
    file write _h _n `"}"' _n
    file close _h

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets addchart: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("chartId")
    local cid `"`r(value)'"'

    display as result _n "[googlesheets addchart]"
    display as text   "  spreadsheet:   `using'"
    display as text   "  data sheet:    `sheet'"
    display as text   "  chart type:    `type'"
    display as text   "  anchored at:   `=cond("`targetsheet'" != "", "`targetsheet'", "`sheet'")'!`anchor'"
    display as text   "  new chartId:   `cid'"
end
