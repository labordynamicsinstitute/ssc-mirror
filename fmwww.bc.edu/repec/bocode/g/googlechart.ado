*! googlechart v0.1.3  2026-07-04
*! Stata wrapper for the Google Charts (Visualization API) library.
*!
*! SIBLING to sparkta2 -- different use case, not a replacement.
*! Trade-off:
*!   - sparkta2 ships d3 + topojson inline; HTML works offline.
*!   - googlechart uses Google Charts CDN (https://www.gstatic.com);
*!     HTML requires network at view time per Google ToS.  In return:
*!     14 native chart types, free interactive filters via
*!     google.visualization.Dashboard + ControlWrapper, native animations,
*!     polished default tooltips.
*!
*! Authorship: Eric Booth, Texas 2036.  Built atop Google Charts
*! (https://developers.google.com/chart) -- not affiliated with Google.
*!
*! Supported types (v0.1):
*!   column, bar, line, area, combo, pie, donut, scatter, bubble, geo,
*!   timeline, table, histogram, divbar.
*!
*! Common features (apply to most types):
*!   tx2036style    Texas 2036 brand + Montserrat font
*!   download       Export menu (PNG/SVG)
*!   datatable      View data table + CSV download
*!   animate        IntersectionObserver-gated initial draw
*!   filters()      Filter dropdowns via Google Dashboard + Controls
*!   downloadpos    side (default) | below | none

program define googlechart, rclass
    version 17.0

    syntax [varlist(numeric default=none)] [if] [in], TYPE(string) [ ///
        NAME(varname)                                              ///
        OVER(varname)                                              ///
        LEVel(varname)                                             ///
        LEVELORDer(string)                                         ///
        CENTERlevel(string)                                        ///
        TIME(varname)                                              ///
        STARTvar(varname)                                          ///
        ENDvar(varname)                                            ///
        SIZEvar(varname numeric)                                   ///
        HORIzontal                                                 ///
        STACKed                                                    ///
        NORMAlize                                                  ///
        DIRECTlabels                                               ///
        SCHEME(string)                                             ///
        TX2036STyle                                                ///
        DOWNload                                                   ///
        DATATable                                                  ///
        ANIMate                                                    ///
        DOWNLOADPos(string)                                        ///
        FILTERS(varlist)                                           ///
        TOOLTIPvars(varlist)                                       ///
        TITLE(string) SUBtitle(string) NOTE(string)                ///
        XLABel(string) YLABel(string)                              ///
        NAMELabel(string) VALUELabel(string)                       ///
        LABELWRap(string)                                          ///
        LEGENDPos(string)                                          ///
        TABLESEArch                                                ///
        TABLEHEAdersticky                                          ///
        TABLEFRozencols(integer 0)                                 ///
        GEOREGion(string) GEORESolution(string)                    ///
        COMBOTypes(string) COMBODflt(string)                        ///
        INNERradius(real 0.45)                                     ///
        BUCKETSize(real 0)                                         ///
        WIDTH(integer 980) HEIGHT(integer 644)                     ///
        EXPORT(string) NOOPEN                                      ///
    ]

    marksample touse, novarlist

    local type = lower("`type'")
    local _valid_types "column bar line area combo pie donut scatter bubble geo timeline table histogram divbar"
    if !`:list type in _valid_types' {
        display as error "googlechart: type(`type') not recognised."
        display as error "  Valid: `_valid_types'"
        exit 198
    }

    * Validation of feature flags
    local is_tx2036st   = cond("`tx2036style'"  != "", 1, 0)
    local is_download   = cond("`download'"     != "", 1, 0)
    local is_datatable  = cond("`datatable'"    != "", 1, 0)
    local is_animate    = cond("`animate'"      != "", 1, 0)
    local is_stacked    = cond("`stacked'"      != "", 1, 0)
    local is_normalize  = cond("`normalize'"    != "", 1, 0)
    local is_directlbl  = cond("`directlabels'" != "", 1, 0)
    local is_tblsearch  = cond("`tablesearch'"   != "", 1, 0)
    local is_tblsticky  = cond("`tableheadersticky'" != "", 1, 0)

    * Guard: on a bar/column chart, directlabels adds an annotation-role
    * column, and Google Charts throws on animation.startup when that column
    * is present -- the chart then renders blank.  The two options are
    * mutually exclusive here, so drop animate and tell the user rather than
    * emit a page that silently fails to draw.
    if `is_animate' & `is_directlbl' & inlist("`type'","bar","column") {
        display as text "googlechart: animate is incompatible with directlabels on " ///
            "type(`type') (Google Charts errors on the annotation column); ignoring animate."
        local is_animate = 0
    }

    if "`legendpos'" == "" local legendpos ""
    local legendpos = lower("`legendpos'")

    if "`downloadpos'" == "" local downloadpos "side"
    local downloadpos = lower("`downloadpos'")
    local _vd "side below none"
    if !`:list downloadpos in _vd' {
        display as error "googlechart: downloadpos(`downloadpos') -- valid: side | below | none"
        exit 198
    }

    if "`scheme'" == "" {
        if `is_tx2036st' local scheme "tx2036"
        else if "`type'" == "divbar" local scheme "rdbu"
        else                          local scheme "tx2036"
    }
    local scheme = lower("`scheme'")

    * For BAR type, the user often expects HORIZONTAL.  Google Charts'
    * BarChart class IS horizontal; ColumnChart is vertical.  Resolve here.
    local _engine_type "`type'"
    if "`type'" == "column" & "`horizontal'" != "" local _engine_type "bar"
    if "`type'" == "bar"    & "`horizontal'" == "" {
        * Bar in googlechart means horizontal by convention.
        * No change needed.
    }

    * Per-type required-input checks (kept minimal so the engine can
    * surface its own errors when something's off)
    local nvar : word count `varlist'
    local _v1 : word 1 of `varlist'
    local _v2 : word 2 of `varlist'

    * When user calls `googlechart y x, over(series) type(line|area|combo)'
    * with 2 numeric vars and no explicit name(), treat _v2 as the category
    * dimension (x-axis) and _v1 as the value.  Without this, the engine
    * gets every row with name="" and reshapes them onto a single x slot.
    if (inlist("`type'","line","area","combo")) & (`nvar' == 2) & ("`name'" == "") {
        local name "`_v2'"
        local _v2 ""
        local nvar = 1
        display as txt "googlechart: type(`type') with two vars + no name() -- using `name' as the x-axis category."
    }

    * String inlist() caps at ~10 args -- split.
    if inlist("`type'","column","bar","line","area","combo") | ///
       inlist("`type'","pie","donut","geo","histogram","divbar") {
        if `nvar' < 1 {
            display as error "googlechart: type(`type') requires at least one numeric var"
            exit 198
        }
    }
    if inlist("`type'","scatter","bubble") {
        if `nvar' < 2 {
            display as error "googlechart: type(`type') requires two numeric vars (x y)"
            exit 198
        }
    }
    if "`type'" == "divbar" {
        if "`level'" == "" {
            display as error "googlechart: type(divbar) requires level(varname)"
            exit 198
        }
        if "`name'" == "" {
            display as error "googlechart: type(divbar) requires name(varname) -- the item label"
            exit 198
        }
    }
    if "`type'" == "timeline" {
        if "`startvar'" == "" | "`endvar'" == "" {
            display as error "googlechart: type(timeline) requires startvar() and endvar()"
            exit 198
        }
        if "`name'" == "" {
            display as error "googlechart: type(timeline) requires name(varname) -- the row label"
            exit 198
        }
    }
    if "`type'" == "geo" {
        if "`name'" == "" {
            display as error "googlechart: type(geo) requires name(varname) -- region/country code"
            exit 198
        }
        display as txt "googlechart: type(geo) supports country and US-state level only."
        display as txt "  For county or school-district choropleths, use a mapping command that reads shapefiles."
    }

    if "`title'" == "" {
        if      "`type'" == "donut"    local title "Donut chart"
        else if "`type'" == "divbar"   local title "Diverging stacked bar"
        else if "`type'" == "timeline" local title "Timeline"
        else {
            local _tprop = proper("`type'")
            local title  "`_tprop' chart"
        }
    }
    if "`export'" == "" local export "`c(pwd)'/googlechart_`type'.html"

    * --- Discover the engine and helpers --------------------------
    * The engine is shipped as googlechart_engine.sthlp because Stata's
    * net install only copies files with a small set of recognised
    * extensions (.ado, .sthlp, .mata, .mlib, .dta, ...).  .js is NOT in
    * that list -- net install silently skips it -- so we use .sthlp as
    * a safe container for the JavaScript text.  The contents are not
    * Stata syntax; the file is treated as opaque text and embedded
    * into the output HTML via googlechart_embedjs.
    capture findfile googlechart_engine.sthlp
    if _rc {
        display as error "googlechart: googlechart_engine.sthlp not on adopath."
        display as error "  Make sure the googlechart package is in your _codeshare or local clone."
        exit 601
    }
    local engpath "`r(fn)'"

    * --- Build the long-form row JSON ------------------------------------
    * Schema: each row is one observation with optional fields --
    * name, value, g (series), lev (level), t (time), x, y, start, end,
    * size, t__VAR.  Empty values omitted to keep the JSON tight.
    tempfile rowjson
    tempname rfh
    quietly file open `rfh' using "`rowjson'", write text replace

    local _first 1
    local _rows_written = 0
    quietly {
        forvalues _i = 1/`=_N' {
            if !`touse'[`_i'] continue

            * --- Build the per-row record -----------------------------
            * For bubble: _v1=x, _v2=y.  For scatter: _v1=x, _v2=y.
            * For timeline: no varlist; uses start/end.
            * For everything else: _v1=value, _v2 unused.
            * The engine knows which fields to consume per type.
            local _xv .
            local _yv .
            if `nvar' >= 1 local _xv = `_v1'[`_i']
            if `nvar' >= 2 local _yv = `_v2'[`_i']

            * Skip rows where the primary numeric is missing.  Two
            * exceptions: divbar treats missing share as 0; timeline
            * relies on start/end (no primary numeric).
            if "`type'" != "timeline" & "`type'" != "table" & missing(`_xv') {
                if "`type'" != "divbar" continue
            }
            if inlist("`type'","scatter","bubble") & missing(`_yv') continue

            * Resolve string-or-label fields
            local _nm ""
            if "`name'" != "" {
                capture confirm string variable `name'
                if !_rc {
                    local _nm = `name'[`_i']
                }
                else {
                    local _lab : value label `name'
                    local _num = `name'[`_i']
                    if "`_lab'" != "" & !missing(`_num') local _nm : label `_lab' `_num'
                    else if !missing(`_num') local _nm = strofreal(`_num')
                }
            }
            local _nm : subinstr local _nm `"\"' `"\\"', all
            local _nm : subinstr local _nm `"""' `"\""', all

            local _ov ""
            if "`over'" != "" {
                capture confirm string variable `over'
                if !_rc {
                    local _ov = `over'[`_i']
                }
                else {
                    local _olab : value label `over'
                    local _onum = `over'[`_i']
                    if "`_olab'" != "" & !missing(`_onum') local _ov : label `_olab' `_onum'
                    else if !missing(`_onum') local _ov = strofreal(`_onum')
                }
            }
            local _ov : subinstr local _ov `"\"' `"\\"', all
            local _ov : subinstr local _ov `"""' `"\""', all

            local _lv ""
            if "`level'" != "" {
                capture confirm string variable `level'
                if !_rc {
                    local _lv = `level'[`_i']
                }
                else {
                    local _llab : value label `level'
                    local _lnum = `level'[`_i']
                    if "`_llab'" != "" & !missing(`_lnum') local _lv : label `_llab' `_lnum'
                    else if !missing(`_lnum') local _lv = strofreal(`_lnum')
                }
            }
            local _lv : subinstr local _lv `"\"' `"\\"', all
            local _lv : subinstr local _lv `"""' `"\""', all

            * Numeric helper fields
            local _start ""
            local _end   ""
            local _size  .
            if "`startvar'" != "" {
                * Try to format as ISO date if the var has format suggesting Stata date
                local _fmt : format `startvar'
                local _sv = `startvar'[`_i']
                if missing(`_sv') continue
                if regexm("`_fmt'", "^%[dt]") {
                    local _start = string(`_sv', "%tdCCYY-NN-DD")
                }
                else {
                    local _start = strofreal(`_sv')
                }
            }
            if "`endvar'" != "" {
                local _fmt : format `endvar'
                local _ev = `endvar'[`_i']
                if missing(`_ev') continue
                if regexm("`_fmt'", "^%[dt]") {
                    local _end = string(`_ev', "%tdCCYY-NN-DD")
                }
                else {
                    local _end = strofreal(`_ev')
                }
            }
            if "`sizevar'" != "" {
                local _size = `sizevar'[`_i']
            }

            * Emit the row
            if `_first' local _first 0
            else file write `rfh' "," _n
            file write `rfh' "        {"

            * Map varlist to fields per type.  Important: Stata writes a
            * literal "." for missing numerics via file write, which is NOT
            * valid JSON.  Emit `null' explicitly for any missing primary
            * numeric -- otherwise the whole payload fails to parse and the
            * chart never renders (the type=table case has no varlist at all,
            * so _xv is always missing there).
            if inlist("`type'","scatter","bubble") {
                if !missing(`_xv') file write `rfh' `""x":"' (`_xv')
                else                file write `rfh' `""x":null"'
                if !missing(`_yv') file write `rfh' `","y":"' (`_yv')
                else                file write `rfh' `","y":null"'
                if "`type'" == "bubble" {
                    if !missing(`_size') file write `rfh' `","size":"' (`_size')
                    else                 file write `rfh' `","size":null"'
                }
            }
            else if "`type'" == "table" {
                * type(table) typically passes no varlist -- columns come
                * from tooltipvars() instead.  Emit an opening placeholder
                * so the row JSON is valid even when no fields follow.
                file write `rfh' `""_":null"'
            }
            else {
                * For column/bar/line/area/pie/donut/geo/divbar/histogram/combo:
                * primary numeric is the value, optionally with a series.
                if !missing(`_xv') file write `rfh' `""value":"' (`_xv')
                else                file write `rfh' `""value":null"'
            }

            if "`_nm'" != ""    file write `rfh' `","name":"`_nm'""'
            if "`_ov'" != ""    file write `rfh' `","g":"`_ov'""'
            if "`_lv'" != ""    file write `rfh' `","lev":"`_lv'""'
            if "`_start'" != "" file write `rfh' `","start":"`_start'""'
            if "`_end'"   != "" file write `rfh' `","end":"`_end'""'

            * Time dimension (numeric) -- used by bubble/play and reserved
            * for future per-type uses.
            if "`time'" != "" {
                local _tv = `time'[`_i']
                if !missing(`_tv') file write `rfh' `","t":"' (`_tv')
            }

            * Tooltipvars (extra columns shown in the data table)
            if "`tooltipvars'" != "" {
            foreach _tv of varlist `tooltipvars' {
                local _val ""
                capture confirm string variable `_tv'
                if !_rc {
                    local _val = `_tv'[`_i']
                    local _val : subinstr local _val `"\"' `"\\"', all
                    local _val : subinstr local _val `"""' `"\""', all
                    file write `rfh' `","t__`_tv'":"`_val'""'
                }
                else {
                    local _tlab : value label `_tv'
                    local _tnum = `_tv'[`_i']
                    if "`_tlab'" != "" & !missing(`_tnum') {
                        local _tdisp : label `_tlab' `_tnum'
                        local _tdisp : subinstr local _tdisp `"\"' `"\\"', all
                        local _tdisp : subinstr local _tdisp `"""' `"\""', all
                        file write `rfh' `","t__`_tv'":"`_tdisp'""'
                    }
                    else if missing(`_tnum') {
                        file write `rfh' `","t__`_tv'":null"'
                    }
                    else {
                        file write `rfh' `","t__`_tv'":"' (`_tnum')
                    }
                }
            }
            }

            file write `rfh' "}" _n
            local ++_rows_written
        }
    }
    file close `rfh'

    if `_rows_written' == 0 {
        display as error "googlechart: no rows to plot (check [if] / [in] / missing values)"
        exit 459
    }

    * --- Build filter spec JSON ------------------------------------------
    tempfile filterjson
    quietly file open `rfh' using "`filterjson'", write text replace
    file write `rfh' "["
    local _fcount = 0
    if "`filters'" != "" {
    foreach _fv of varlist `filters' {
        if `_fcount' > 0 file write `rfh' ","
        local ++_fcount
        local _lbl : variable label `_fv'
        if "`_lbl'" == "" local _lbl "`_fv'"
        local _lbl : subinstr local _lbl `"""' `"\""', all
        capture confirm numeric variable `_fv'
        local _isnum = (_rc == 0)
        local _vlab : value label `_fv'
        * Treat numeric with a value label as categorical, not numeric range
        local _numeric_filter = cond(`_isnum' & "`_vlab'" == "", 1, 0)
        file write `rfh' `"{"var":"`_fv'","label":"`_lbl'","numeric":`_numeric_filter'}"'
    }
    }
    file write `rfh' "]"
    file close `rfh'

    * --- Build placeholder meta JSON (engine still needs the meta block) -
    tempfile metajson
    quietly file open `rfh' using "`metajson'", write text replace
    file write `rfh' "{}"
    file close `rfh'

    * --- Emit final HTML -------------------------------------------------
    local _v1_name "`_v1'"
    if "`_v1_name'" == "" local _v1_name "value"
    local _v2_name "`_v2'"

    googlechart_writehtml,                                                  ///
        engpath("`engpath'") rowjson("`rowjson'") metajson("`metajson'")    ///
        filterjson("`filterjson'") export(`"`export'"')                     ///
        type("`_engine_type'") scheme("`scheme'")                           ///
        title(`"`title'"') subtitle(`"`subtitle'"') note(`"`note'"')        ///
        xlabel(`"`xlabel'"') ylabel(`"`ylabel'"')                           ///
        xvar("`_v1_name'") yvar("`_v2_name'") name("`name'") over("`over'") ///
        level("`level'") time("`time'")                                     ///
        namelabel(`"`namelabel'"') valuelabel(`"`valuelabel'"')             ///
        levelorder(`"`levelorder'"') centerlevel(`"`centerlevel'"')         ///
        labelwrap("`labelwrap'")                                            ///
        isdownload(`is_download') isdatatable(`is_datatable')               ///
        isanimate(`is_animate') istx2036style(`is_tx2036st')                ///
        downloadpos("`downloadpos'")                                        ///
        isstacked(`is_stacked') isnormalize(`is_normalize')                 ///
        isdirectlabels(`is_directlbl')                                      ///
        innerradius(`innerradius') bucketsize(`bucketsize')                 ///
        georegion("`georegion'") georesolution("`georesolution'")           ///
        combotypes("`combotypes'") combodefault("`combodflt'")              ///
        legendpos("`legendpos'")                                            ///
        istblsearch(`is_tblsearch') istblsticky(`is_tblsticky')              ///
        tblfrozencols(`tablefrozencols')                                    ///
        width(`width') height(`height')

    display as text _n "[googlechart]  `type' written:"
    display as text `"  {browse "`export'":`export'}"'
    display as text "  Rows: `_rows_written'  Scheme: `scheme'"

    return local export "`export'"
    return local type   "`type'"
    return scalar n_rows = `_rows_written'

end
