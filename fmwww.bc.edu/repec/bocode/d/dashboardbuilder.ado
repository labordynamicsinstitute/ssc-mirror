*! version 1.3.1  15jul2026  Eric Booth / Texas 2036 Data & Research
*! dashboardbuilder — build a self-contained, interactive HTML dashboard from Stata
*! ----------------------------------------------------------------------------
*!  A putdocx-style BUILDER: you call it several times, feeding it one analytic
*!  subset at a time (each -panel- call snapshots the data currently in memory),
*!  then -build- writes ONE self-contained HTML file: no CDN, no internet, no
*!  external files. Charts are readable hand-rolled SVG/JS meant as a STARTER
*!  WIREFRAME a human can open and tweak.
*!
*!      dashboardbuilder init , title(...) [subtitle() selector() refvalue() tx2036]
*!      dashboardbuilder tab  , name(...) label(...)
*!      dashboardbuilder panel <kpi|line|bar|hbar|compare|table|html> , [options]
*!      dashboardbuilder build using file.html [, nocsv nopng notooltip pdf truepdf ///
*!                                                 callout() sourcenote() replace noopen]
*!      dashboardbuilder describe | clear | openlast | openfolder
*!
*!  ENGINE: Stata orchestrates; Stata's built-in Python integration (PyStata,
*!  Stata 16+) does the JSON serialization and HTML templating using ONLY the
*!  Python standard library (json, os). Nothing to pip install, ever.
*!  See -help dashboardbuilder- for the full story and worked examples.
*! ----------------------------------------------------------------------------

program define dashboardbuilder, rclass
    version 16
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower(`"`sub'"')

    if      `"`sub'"' == "init"     _dbb_init `0'
    else if `"`sub'"' == "tab"      _dbb_tab `0'
    else if `"`sub'"' == "panel"    _dbb_panel `0'
    else if `"`sub'"' == "build" {
        _dbb_build `0'
        return local file    `"${DBB_R_FILE}"'
        return local ntabs   "${DBB_NTABS}"
        return local npanels "${DBB_NPANELS}"
        return local bytes   "${DBB_R_BYTES}"
    }
    else if `"`sub'"' == "describe"   _dbb_describe
    else if `"`sub'"' == "clear"      _dbb_clear
    else if `"`sub'"' == "openlast"   _dbb_openpath `"${DBB_R_FILE}"'
    else if `"`sub'"' == "openfolder" _dbb_openpath `"${DBB_R_FILE}"' , folder
    else {
        di as err `"dashboardbuilder: unknown subcommand "`sub'""'
        di as err "  valid: init | tab | panel | build | describe | clear"
        di as err "  see {help dashboardbuilder}"
        exit 198
    }
end

* ═══════════════════════════════════════════════════════════════════════════
* openpath — auto-open a file in the default app, or its folder in the OS file
* manager. Backs the auto-open (default; -noopen- suppresses) and the -openlast- /
* -openfolder- subcommands. The receipt's clickable links are native {browse}
* directives, so they need no subprogram.
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_openpath
    gettoken path 0 : 0, parse(",")
    syntax [, folder]
    local path = trim(`"`path'"')
    if `"`path'"' == "" {
        di as err "nothing to open yet — run {bf:dashboardbuilder build} first."
        exit 198
    }
    local path = subinstr(`"`path'"', char(92), "/", .)              // forward slashes
    if "`folder'" != "" local path = substr(`"`path'"', 1, strrpos(`"`path'"', "/") - 1)

    * Open in the OS default app: the browser for an .html file, Finder/Explorer
    * for a folder. Cross-platform branch mirrors sparkta2_open: macOS -open-,
    * Windows -start-, Linux -xdg-open- (Linux has no -open-). Plain subprocess
    * calls with no URL parsing, so they are crash-safe.
    * IMPORTANT — never hand -view browse- (or a {browse} link) a file:// URL. On
    * macOS (observed on Stata 19.5 / macOS 26) Stata parses it through
    * NSURLComponents, which THROWS on a path holding '@' (e.g. a Google Drive
    * path) and ABORTS Stata. The receipt's clickable links use {browse} on the
    * RAW path (no file:// scheme, so no authority/userinfo parse), which is safe.
    local _os = lower("`c(os)'")
    if      strpos("`_os'", "win") capture winexec cmd /c start "" `"`path'"'
    else if strpos("`_os'", "mac") capture shell open `"`path'"'
    else                           capture shell xdg-open `"`path'"' &
    if _rc di as txt `"(could not auto-open; open this path yourself:  `path')"'
end

* ═══════════════════════════════════════════════════════════════════════════
* pycheck — verify Stata's Python integration works BEFORE we depend on it,
* and print exact fix-it commands when it does not (per-machine setup).
* Only the Python STANDARD LIBRARY is used, so no pip installs are needed.
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_pycheck
    capture python query
    if _rc {
        di as err "dashboardbuilder needs Stata's built-in Python integration (Stata 16+)."
        di as err "Stata could not find a usable Python. To fix:"
        di as err `"  1. see what Stata can find:      {stata python search}"'
        di as err `"  2. point Stata at a Python 3, for example:"'
        di as err `"       . python set exec /usr/local/bin/python3, permanently   (Mac/Linux)"'
        di as err `"       . python set exec C:\Python312\python.exe, permanently  (Windows)"'
        di as err `"  3. verify:                        {stata python query}"'
        di as err "No extra Python packages are required (standard library only)."
        exit 198
    }
    capture python: import sys; assert sys.version_info[0] >= 3
    if _rc {
        di as err "dashboardbuilder needs Python 3; Stata is currently linked to Python 2."
        di as err `"Point Stata at a Python 3 install:"'
        di as err `"  . python search"'
        di as err `"  . python set exec <path-to-python3>, permanently"'
        exit 198
    }
    capture python: import json, os
    if _rc {
        di as err "Python was found, but importing the standard library (json, os) failed,"
        di as err "which suggests a broken Python install. Try pointing Stata at another one:"
        di as err `"  . python search"'
        di as err `"  . python set exec <path-to-python3>, permanently"'
        exit 198
    }
end

program define _dbb_require_active
    if "${DBB_ACTIVE}" != "1" {
        di as err "no dashboard in progress — run {bf:dashboardbuilder init} first."
        di as err "see {help dashboardbuilder##examples:examples}"
        exit 198
    }
end

* ═══════════════════════════════════════════════════════════════════════════
* init — start a dashboard; registers title/theme/selector, makes a temp dir
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_init
    syntax , TItle(string) [SUBtitle(string) SELector(name) SELLABel(string) ///
                            REFVALue(string) TX2036 THEME(string)]
    _dbb_pycheck
    _dbb_pysetup
    if "${DBB_ACTIVE}" == "1" {
        di as txt "(discarding the previous unfinished dashboard; starting fresh)"
        _dbb_clear
    }

    * theme: tx2036 flag wins; else theme(); else simple
    if "`tx2036'" != "" local theme "tx2036"
    if "`theme'" == ""  local theme "simple"
    local theme = lower("`theme'")
    if !inlist("`theme'", "simple", "tx2036") {
        di as err `"theme(`theme') not recognized — use theme(simple) or theme(tx2036)"'
        exit 198
    }
    if `"`refvalue'"' != "" & "`selector'" == "" {
        di as err "refvalue() requires selector() — the reference is a value OF the selector"
        exit 198
    }

    * working dir for panel snapshots (unique per init; lives in c(tmpdir)).
    * tempfile numbers can be REUSED once a program returns, so a directory from
    * an earlier init may still exist — loop with a suffix until mkdir succeeds.
    tempfile tf
    local base = subinstr(`"`tf'"', char(92), "/", .) + "_dbb"
    local dir `"`base'"'
    capture mkdir `"`dir'"'
    local k 0
    while _rc & `k' < 100 {
        local ++k
        local dir `"`base'`k'"'
        capture mkdir `"`dir'"'
    }
    if _rc {
        di as err `"could not create a working directory under `base'"'
        exit 693
    }

    global DBB_ACTIVE   "1"
    global DBB_DIR      `"`dir'"'
    global DBB_TITLE    `"`title'"'
    global DBB_SUBTITLE `"`subtitle'"'
    global DBB_THEME    "`theme'"
    global DBB_SEL      "`selector'"
    global DBB_SELLAB   `"`sellabel'"'
    global DBB_REFVAL   `"`refvalue'"'
    global DBB_NTABS    "0"
    global DBB_NPANELS  "0"
    global DBB_LASTTAB  ""

    di as txt "dashboardbuilder: started " as res `"`title'"' ///
       as txt " (theme: " as res "`theme'" as txt ")"
    if "`selector'" != "" {
        di as txt "  selector: " as res "`selector'" ///
           as txt cond(`"`refvalue'"' != "", `" (reference value: "`refvalue'")"', "")
        di as txt "  panels whose data contain a variable named " ///
           as res "`selector'" as txt " will be filtered by the dropdown."
    }
    di as txt "  next: {bf:dashboardbuilder tab}, then {bf:dashboardbuilder panel}, then {bf:dashboardbuilder build}"
end

* ═══════════════════════════════════════════════════════════════════════════
* tab — register a tab (optional; panels without tabs share one implicit page)
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_tab
    _dbb_require_active
    syntax , NAme(name) [LABel(string)]
    if `"`label'"' == "" local label "`name'"
    forvalues i = 1/${DBB_NTABS} {
        if "${DBB_TAB_NAME_`i'}" == "`name'" {
            di as err `"tab name "`name'" already declared"'
            exit 198
        }
    }
    local k = ${DBB_NTABS} + 1
    global DBB_NTABS       "`k'"
    global DBB_TAB_NAME_`k' "`name'"
    global DBB_TAB_LAB_`k'  `"`label'"'
    global DBB_LASTTAB      "`name'"
    di as txt `"  tab `k' registered: "' as res `"`label'"' as txt `" (name: `name')"'
end

* ═══════════════════════════════════════════════════════════════════════════
* panel — snapshot the CURRENT data in memory as one dashboard panel
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_panel
    _dbb_require_active
    _dbb_pysetup
    gettoken ptype 0 : 0, parse(" ,")
    local ptype = lower(`"`ptype'"')
    if !inlist("`ptype'", "kpi", "line", "bar", "hbar", "compare", "table", "html") {
        di as err `"panel type "`ptype'" not recognized"'
        di as err "  valid: kpi | line | bar | hbar | compare | table | html"
        exit 198
    }
    * html panels embed an external file (no data), so they skip the data checks
    if _N == 0 & "`ptype'" != "html" {
        di as err "no observations in memory — load/derive the panel's data first"
        exit 2000
    }

    * ---- per-type option parsing (spec vars differ by type) ----
    local x ""
    local y ""
    local ref ""
    local vals ""
    local vars ""
    if "`ptype'" == "kpi" {
        syntax , VALues(varlist numeric) [TAB(name) TItle(string) NOTE(string) INTERP(string)]
        local vals "`values'"
    }
    else if "`ptype'" == "line" {
        syntax , X(varname) Y(varlist numeric) [TAB(name) TItle(string) NOTE(string) ///
            INTERP(string) YTItle(string)]
    }
    else if inlist("`ptype'", "bar", "hbar") {
        syntax , X(varname) Y(varname numeric) [TAB(name) TItle(string) NOTE(string) ///
            INTERP(string) YTItle(string)]
    }
    else if "`ptype'" == "compare" {
        syntax , X(varname) Y(varname numeric) [REF(varname numeric) TAB(name) ///
            TItle(string) NOTE(string) INTERP(string) YTItle(string)]
    }
    else if "`ptype'" == "table" {
        syntax [, VARs(varlist) TAB(name) TItle(string) NOTE(string) INTERP(string)]
        if "`vars'" == "" unab vars : _all
    }
    else {                                             // html — embed an external file
        syntax , FIle(string) [TAB(name) TItle(string) NOTE(string) INTERP(string) HEIGHT(integer 520)]
    }

    * ---- resolve the tab this panel belongs to (auto-create "main" if none) ----
    if "`tab'" == "" local tab "${DBB_LASTTAB}"
    if "`tab'" == "" {
        _dbb_tab , name(main) label("Dashboard")
        local tab "main"
    }
    local found 0
    forvalues i = 1/${DBB_NTABS} {
        if "${DBB_TAB_NAME_`i'}" == "`tab'" local found 1
    }
    if !`found' {
        di as err `"tab(`tab') was never declared — run:  dashboardbuilder tab, name(`tab') label("...")"'
        exit 198
    }

    * ---- html panel: register an external file to inline; no data capture ------
    if "`ptype'" == "html" {
        * absolutize the path (Python reads the file at build time; its cwd differs)
        local hf = subinstr(`"`file'"', char(92), "/", .)
        if substr(`"`hf'"', 1, 1) != "/" & strpos(`"`hf'"', ":") == 0 {
            local hf `"`c(pwd)'/`hf'"'
            local hf = subinstr(`"`hf'"', char(92), "/", .)
        }
        capture confirm file `"`hf'"'
        if _rc {
            di as err `"panel html: file not found — `hf'"'
            di as err "  build the HTML first (e.g. a sparkta2 map with export()/offline), then pass its path in file()."
            exit 601
        }
        local k = ${DBB_NPANELS} + 1
        global DBB_NPANELS        "`k'"
        global DBB_P_`k'_TYPE     "html"
        global DBB_P_`k'_TAB      "`tab'"
        global DBB_P_`k'_TITLE    `"`title'"'
        global DBB_P_`k'_NOTE     `"`note'"'
        global DBB_P_`k'_INTERP   `"`interp'"'
        global DBB_P_`k'_YTITLE   ""
        global DBB_P_`k'_X        ""
        global DBB_P_`k'_Y        ""
        global DBB_P_`k'_REF      ""
        global DBB_P_`k'_SELCOL   ""
        global DBB_P_`k'_NROWS    "0"
        global DBB_P_`k'_XDATE    "0"
        global DBB_P_`k'_CAPVARS  ""
        global DBB_P_`k'_HTMLFILE `"`hf'"'
        global DBB_P_`k'_HEIGHT   "`height'"
        di as txt `"  panel `k' captured: "' as res "html" ///
           cond(`"`title'"' != "", `" "`title'""', "") ///
           as txt `" — inlines `hf' (iframe, `height'px), tab(`tab')"'
        exit
    }

    * ---- assemble capture varlists ----
    * capvars = every column this panel embeds, in display order
    * rawvars = value columns kept NUMERIC (never value-label decoded)
    local rawvars "`y' `ref' `vals'"
    if "`ptype'" == "table" local capvars "`vars'"
    else                    local capvars "`x' `y' `ref' `vals'"
    * selector column rides along when present in this dataset (enables filtering)
    * (exact: never let "state" abbreviation-match a variable like state2)
    local selcol ""
    if "${DBB_SEL}" != "" {
        capture confirm variable ${DBB_SEL}, exact
        if !_rc {
            local selcol "${DBB_SEL}"
            local capvars "`selcol' `capvars'"
        }
    }
    local capvars : list uniq capvars

    * x that looks like a Stata date gets a receipt warning later
    local xdate 0
    if "`x'" != "" {
        local xfmt : format `x'
        if strpos("`xfmt'", "%t") == 1 local xdate 1
    }

    * ---- register spec globals ----
    local k = ${DBB_NPANELS} + 1
    global DBB_NPANELS       "`k'"
    global DBB_P_`k'_TYPE    "`ptype'"
    global DBB_P_`k'_TAB     "`tab'"
    global DBB_P_`k'_TITLE   `"`title'"'
    global DBB_P_`k'_NOTE    `"`note'"'
    global DBB_P_`k'_INTERP  `"`interp'"'
    global DBB_P_`k'_YTITLE  `"`ytitle'"'
    global DBB_P_`k'_X       "`x'"
    global DBB_P_`k'_Y       "`y' `vals'"
    global DBB_P_`k'_REF     "`ref'"
    global DBB_P_`k'_SELCOL  "`selcol'"
    global DBB_P_`k'_NROWS   "`=_N'"
    global DBB_P_`k'_XDATE   "`xdate'"
    global DBB_P_`k'_CAPVARS "`capvars'"

    * ---- snapshot the data to JSON via PyStata (stdlib only) ----
    global DBB_K       "`k'"
    global DBB_CAP     "`capvars'"
    global DBB_CAPRAW  "`rawvars'"
    global DBB_PYERR   ""
    * NOTE: ado-file python one-liners run in a per-ado namespace, so reach the
    * script-defined engine through __main__ explicitly.
    capture python: import __main__; __main__._dbb_capture()
    if _rc {
        di as err "the Python helper functions are missing (was -python clear- run?)."
        di as err "recover with:  {stata discard}   then start again from {bf:dashboardbuilder init}"
        exit 498
    }
    if `"${DBB_PYERR}"' != "" {
        di as err `"panel snapshot failed in Python: ${DBB_PYERR}"'
        exit 498
    }

    local nc : word count `capvars'
    di as txt `"  panel `k' captured: "' as res "`ptype'" as txt ///
       cond(`"`title'"' != "", `" "`title'""', "") ///
       as txt " — `=_N' rows x `nc' cols, tab(`tab')" ///
       cond("`selcol'" != "", " [filterable by `selcol']", "")
end

* ═══════════════════════════════════════════════════════════════════════════
* describe — show what has been registered so far (pre-build)
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_describe
    _dbb_require_active
    di as txt "{hline 64}"
    di as txt "dashboardbuilder — in progress: " as res `"${DBB_TITLE}"'
    di as txt "  theme: " as res "${DBB_THEME}" ///
       as txt cond("${DBB_SEL}" != "", "   selector: {res}${DBB_SEL}{txt}", "")
    di as txt "  tabs: ${DBB_NTABS}   panels: ${DBB_NPANELS}"
    forvalues i = 1/${DBB_NPANELS} {
        di as txt `"    `i'. [${DBB_P_`i'_TAB}] ${DBB_P_`i'_TYPE} "' ///
           as res `"${DBB_P_`i'_TITLE}"' ///
           as txt "  (${DBB_P_`i'_NROWS} rows)" ///
           cond("${DBB_P_`i'_SELCOL}" != "", " filterable", "")
    }
    di as txt "  finish with: {bf:dashboardbuilder build using yourfile.html}"
    di as txt "{hline 64}"
end

* ═══════════════════════════════════════════════════════════════════════════
* clear — abandon the current build and drop all state
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_clear
    capture macro drop DBB_*
    di as txt "dashboardbuilder: state cleared."
end

* ═══════════════════════════════════════════════════════════════════════════
* build — assemble the single self-contained HTML file + print the receipt
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_build
    _dbb_require_active
    _dbb_pysetup
    syntax using/ [, replace noCSV noPNG noTOOLtip PDF TRUEpdf ///
                     CALLout(string) SOURCEnote(string) NOOPEN CORNer]
    if ${DBB_NPANELS} < 1 {
        di as err "no panels captured — add at least one {bf:dashboardbuilder panel} first"
        exit 198
    }
    local using = subinstr(`"`using'"', char(92), "/", .)
    if strpos(`"`using'"', ".html") == 0 & strpos(`"`using'"', ".htm") == 0 {
        local using `"`using'.html"'
    }
    * absolutize BEFORE handing to Python (its cwd can differ from Stata's)
    if substr(`"`using'"', 1, 1) != "/" & strpos(`"`using'"', ":") == 0 {
        local using `"`c(pwd)'/`using'"'
        local using = subinstr(`"`using'"', char(92), "/", .)
    }
    capture confirm file `"`using'"'
    if !_rc & "`replace'" == "" {
        di as err `"file `using' already exists — add the {bf:replace} option"'
        exit 602
    }

    global DBB_OUT     `"`using'"'
    * per-panel CSV + PNG buttons and hover tooltips are ON by default
    * (all self-contained); noCSV / noPNG / noTOOLtip turn them off.
    global DBB_CSVDL   = cond("`csv'"     == "nocsv",     "0", "1")
    global DBB_PNGDL   = cond("`png'"     == "nopng",     "0", "1")
    global DBB_TOOLTIP = cond("`tooltip'" == "notooltip", "0", "1")
    global DBB_PDFDL   = cond("`pdf'"     != "", "1", "0")   // self-contained print-to-PDF button
    global DBB_TRUEPDF = cond("`truepdf'" != "", "1", "0")   // one-click PDF via CDN library
    global DBB_CORNER  = cond("`corner'"  != "", "1", "0")   // float the PDF button(s) bottom-right
    global DBB_CALLOUT `"`callout'"'
    global DBB_SOURCES `"`sourcenote'"'
    global DBB_PYERR   ""
    capture python: import __main__; __main__._dbb_assemble()
    if _rc {
        di as err "the Python helper functions are missing (was -python clear- run?)."
        di as err "recover with:  {stata discard}   then start again from {bf:dashboardbuilder init}"
        exit 498
    }
    if `"${DBB_PYERR}"' != "" {
        di as err `"build failed in Python: ${DBB_PYERR}"'
        exit 498
    }

    * ---- the receipt ----
    di as txt "{hline 68}"
    di as res "dashboardbuilder: build receipt"
    di as txt "{hline 68}"
    di as txt "  file     : " as res `"${DBB_R_FILE}"'
    di as txt "  size     : " as res "${DBB_R_KB} KB" as txt "  (self-contained; no internet needed to view)"
    di as txt "  theme    : " as res "${DBB_THEME}"
    if "${DBB_SEL}" != "" {
        di as txt "  selector : " as res "${DBB_SEL}" as txt " — ${DBB_R_NSELOPT} options in the dropdown" ///
           cond(`"${DBB_REFVAL}"' != "", `"; reference = "${DBB_REFVAL}""', "")
    }
    di as txt "  tabs     : " as res "${DBB_NTABS}" as txt "   panels : " as res "${DBB_NPANELS}"
    forvalues i = 1/${DBB_NPANELS} {
        di as txt `"    `i'. [${DBB_P_`i'_TAB}] ${DBB_P_`i'_TYPE}"' ///
           cond(`"${DBB_P_`i'_TITLE}"' != "", `" "${DBB_P_`i'_TITLE}""', " (untitled)") ///
           as txt "  ${DBB_P_`i'_NROWS} rows" ///
           cond("${DBB_P_`i'_SELCOL}" != "", "  [filters with dropdown]", "  [static]")
    }
    di as txt "  per-panel : CSV " as res cond("${DBB_CSVDL}"=="1","on","off") ///
       as txt "  |  PNG " as res cond("${DBB_PNGDL}"=="1","on","off") ///
       as txt "  |  hover tooltips " as res cond("${DBB_TOOLTIP}"=="1","on","off") as txt "  (all self-contained)"
    di as txt "  download  : save-as-PDF (print) " as res cond("${DBB_PDFDL}"=="1","on","off") ///
       as txt "  |  one-click PDF " as res cond("${DBB_TRUEPDF}"=="1","on","off")
    if "${DBB_TRUEPDF}" == "1" {
        di as txt "            {err:note}: one-click PDF loads a JS library from a CDN, so that button"
        di as txt "            needs internet — it will NOT work on an air-gapped machine (the rest of"
        di as txt "            the dashboard still works offline). save-as-PDF (print) is fully offline."
    }
    di as txt "  notes     : callout " as res cond(`"${DBB_CALLOUT}"' != "","yes","no") ///
       as txt "  |  sources " as res cond(`"${DBB_SOURCES}"' != "","yes","no")
    di as txt "{hline 68}"
    di as res "  what likely needs further building (this file is a STARTER):"
    forvalues t = 1/${DBB_R_NTODO} {
        di as txt `"   - ${DBB_R_TODO_`t'}"'
    }
    di as txt "{hline 68}"
    * Open + navigate: native SMCL {browse} links. A click opens the file (or the
    * folder) in the default app; the path is the link text, so it also shows in
    * the clear to copy. {browse} takes the RAW path, never a file:// URL — a
    * file:// URL aborts Stata on macOS via NSURLComponents when the path holds
    * '@' (e.g. a Google Drive path); see _dbb_openpath.
    local _fw  = subinstr(`"${DBB_R_FILE}"', char(92), "/", .)
    local _dir = substr(`"`_fw'"', 1, strrpos(`"`_fw'"', "/") - 1)
    di as txt   "  open      : " as smcl `"{browse `"`_fw'"'}"'
    di as txt   "  folder    : " as smcl `"{browse `"`_dir'/"'}"'
    di as txt `"  builder state kept — rerun {bf:build} with other options, or {bf:dashboardbuilder clear}."'

    * auto-open is ON by default (matches sparkta2); -noopen- suppresses it.
    if "`noopen'" == "" _dbb_openpath `"${DBB_R_FILE}"'
end

* ═══════════════════════════════════════════════════════════════════════════
* pysetup — load the Python engine from dashboardbuilder.py (ships with the
* package; found on the adopath or in the current folder). Loading a real .py
* via -python script- avoids embedding python blocks in the ado (the program
* reader cannot store them) and keeps the engine readable/maintainable.
* Idempotent: re-running just redefines the same functions, which also
* self-heals after a -python clear-.
* ═══════════════════════════════════════════════════════════════════════════
program define _dbb_pysetup
    capture findfile dashboardbuilder.py
    if _rc {
        di as err "cannot find dashboardbuilder.py — it installs alongside dashboardbuilder.ado."
        di as err "reinstall the package, or copy dashboardbuilder.py next to the ado / into"
        di as err "your current folder. (searched the adopath and the working directory)"
        exit 601
    }
    local eng `"`r(fn)'"'
    capture python script `"`eng'"', global
    if _rc {
        di as err `"failed to load the Python engine from `eng'"'
        di as err "check {stata python query} and see {help dashboardbuilder##python}"
        exit 498
    }
end
