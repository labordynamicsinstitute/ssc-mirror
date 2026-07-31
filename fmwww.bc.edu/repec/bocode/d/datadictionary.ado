*! version 1.0.0  20260714  Eric A. Booth, Sr Researcher, Texas 2036
*! datadictionary: enhanced, over-time-ready codebook generator (a modern descsave)
*
*  version 16.0 is the floor the package is tested against; no feature above
*  that baseline is required.  The caller's data are preserved and restored
*  untouched in both modes (restore happens automatically at program exit).

program define datadictionary, rclass
    version 16.0

    syntax [varlist(default=none)] [if] [in] [,          ///
        WAve(varname) FILes(string) FOLder(string)       ///
        PATtern(string) WAVENames(string)                ///
        EXcel(string) SAVing(string) REPlace             ///
        DOfile(string) DICTionary(string) NORECast       ///
        EXAMples(integer 3) TOP(integer 5)               ///
        NOCHars NONotes ]

    * ---- option validation ---------------------------------------------------
    if `examples' < 1 {
        di as err "examples() must be a positive integer"
        exit 198
    }
    if `top' < 1 {
        di as err "top() must be a positive integer"
        exit 198
    }
    if `"`files'"' != "" & `"`folder'"' != "" {
        di as err "files() and folder() may not be combined; use one or the other"
        exit 198
    }
    if `"`pattern'"' != "" & `"`folder'"' == "" {
        di as err "pattern() requires folder()"
        exit 198
    }
    local filesmode = (`"`files'"' != "" | `"`folder'"' != "")
    if !`filesmode' & `"`wavenames'"' != "" {
        di as err "wavenames() applies to files mode only; specify files() or folder()"
        exit 198
    }
    if `filesmode' {
        if "`wave'" != "" {
            di as err "wave() applies to in-memory mode only; in files mode each file is a wave (name them with wavenames())"
            exit 198
        }
        if `"`if'`in'"' != "" | "`varlist'" != "" {
            di as err "varlist, if, and in apply to in-memory mode only"
            exit 198
        }
        if `"`dofile'"' != "" | `"`dictionary'"' != "" {
            di as err "dofile() and dictionary() describe a single dataset and run in in-memory mode only; load one wave and run datadictionary without files()/folder()"
            exit 198
        }
    }
    if `filesmode' & "`norecast'" != "" {
        di as err "norecast applies to dofile() only"
        exit 198
    }

    * ---- output file names, checked before any work ---------------------------
    if `"`excel'"' != "" {
        if lower(substr(`"`excel'"', -5, .)) != ".xlsx" local excel `"`excel'.xlsx"'
        if "`replace'" == "" {
            capture confirm new file `"`excel'"'
            if _rc {
                di as err `"excel file `excel' already exists; specify the replace option"'
                exit 602
            }
        }
    }
    if `"`saving'"' != "" {
        if lower(substr(`"`saving'"', -4, .)) != ".dta" local saving `"`saving'.dta"'
        if "`replace'" == "" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err `"saving file `saving' already exists; specify the replace option"'
                exit 602
            }
        }
    }
    if `"`dofile'"' != "" {
        if lower(substr(`"`dofile'"', -3, .)) != ".do" local dofile `"`dofile'.do"'
        if "`replace'" == "" {
            capture confirm new file `"`dofile'"'
            if _rc {
                di as err `"dofile `dofile' already exists; specify the replace option"'
                exit 602
            }
        }
    }
    if `"`dictionary'"' != "" {
        if lower(substr(`"`dictionary'"', -4, .)) != ".dct" local dictionary `"`dictionary'.dct"'
        if "`replace'" == "" {
            capture confirm new file `"`dictionary'"'
            if _rc {
                di as err `"dictionary `dictionary' already exists; specify the replace option"'
                exit 602
            }
        }
    }

    * ---- resolve the file list (files mode) ------------------------------------
    local nfiles 0
    if `"`folder'"' != "" {
        if `"`pattern'"' == "" local pattern "*.dta"
        if substr(`"`folder'"', -1, .) == "/" {
            local folder = substr(`"`folder'"', 1, strlen(`"`folder'"') - 1)
        }
        local fnames : dir `"`folder'"' files `"`pattern'"'
        local fnames : list sort fnames
        foreach f of local fnames {
            local ++nfiles
            local file`nfiles' `"`folder'/`f'"'
        }
        if `nfiles' == 0 {
            di as err `"no files in folder(`folder') match pattern(`pattern')"'
            exit 601
        }
    }
    else if `"`files'"' != "" {
        local rest `"`files'"'
        gettoken f rest : rest
        while `"`f'"' != "" {
            local ++nfiles
            local file`nfiles' `"`f'"'
            gettoken f rest : rest
        }
    }
    if `filesmode' {
        forvalues i = 1/`nfiles' {
            confirm file `"`file`i''"'
        }
        * wave names: wavenames() tokens, else the file basename minus .dta
        local nwn 0
        local restwn `"`wavenames'"'
        gettoken w restwn : restwn
        while `"`w'"' != "" {
            local ++nwn
            local wn`nwn' `"`w'"'
            gettoken w restwn : restwn
        }
        if `nwn' > 0 & `nwn' != `nfiles' {
            di as err "wavenames() lists `nwn' names for `nfiles' files"
            exit 198
        }
        if `nwn' == 0 {
            forvalues i = 1/`nfiles' {
                local bn `"`file`i''"'
                local sl = strrpos(`"`bn'"', "/")
                if `sl' > 0 local bn = substr(`"`bn'"', `sl' + 1, .)
                local dt = strrpos(`"`bn'"', ".")
                if `dt' > 0 local bn = substr(`"`bn'"', 1, `dt' - 1)
                local wn`i' `"`bn'"'
            }
        }
        local nw = `nfiles'
    }

    * ---- in-memory mode: sample selection ---------------------------------------
    if !`filesmode' {
        if "`varlist'" == "" {
            if c(k) == 0 {
                di as err "no variables to document: the dataset in memory is empty and no files() or folder() was specified"
                exit 2000
            }
            unab varlist : _all
        }
        marksample touse, novarlist strok
        quietly count if `touse'
        if r(N) == 0 {
            di as err "no observations selected by the varlist/if/in restriction"
            exit 2000
        }
    }

    * ---- everything below runs on scratch copies; the caller's data are
    * ---- restored automatically when the program exits --------------------------
    capture preserve
    local srcname = cond(`"`c(filename)'"' == "", "data in memory", `"`c(filename)'"')

    tempname MH VH CH FF
    tempfile MAIN VLAB CHG SIG CHGF
    postfile `MH' int wavenum str80 wave str32 name str12 type str49 format ///
        str80 varlab str32 vallab double n double pctmiss double distinct   ///
        double mean double sd double min double p50 double max              ///
        str2000 examples str2000 notes str2000 srctag str2000 chars         ///
        using `MAIN'
    postfile `VH' int wavenum str32 lname double value str2000 label using `VLAB'

    local totnotes 0
    local lbls ""

    * ============================ FILES MODE ======================================
    if `filesmode' {
        forvalues i = 1/`nfiles' {
            quietly use `"`file`i''"', clear
            local N`i' = _N
            _dd_rows, mh(`MH') wavenum(`i') wave(`"`wn`i''"')  ///
                examples(`examples') top(`top') `nochars' `nonotes'
            local k`i' = r(k)
            local totnotes = `totnotes' + r(nnotes)
            local flbl `"`r(lblnames)'"'
            if `"`flbl'"' != "" {
                quietly uselabel `flbl', clear
                forvalues r = 1/`=_N' {
                    local ln = lname[`r']
                    local vv = value[`r']
                    local lt = substr(label[`r'], 1, 2000)
                    post `VH' (`i') ("`ln'") (`vv') (`"`lt'"')
                }
            }
        }
        local nw = `nfiles'
    }

    * =========================== IN-MEMORY MODE ===================================
    else {
        quietly keep if `touse'
        local keepvars `varlist'
        if "`wave'" != "" local keepvars : list keepvars | wave
        quietly keep `keepvars'
        local NKEPT = _N

        * ---- relabel do-file and/or dictionary, from the full documented data
        * ---- in memory (harvesting below may subset or overwrite it) -----------
        if `"`dofile'"' != "" {
            _dd_dofile, dofile(`"`dofile'"') srcname(`"`srcname'"') ///
                `nochars' `nonotes' `norecast'
        }
        if `"`dictionary'"' != "" {
            _dd_dict, dictionary(`"`dictionary'"') srcname(`"`srcname'"')
        }

        if "`wave'" == "" {
            * ---- cross-sectional: one codebook row per variable ----
            _dd_rows, mh(`MH') wavenum(0) wave("") vars(`varlist') ///
                examples(`examples') top(`top') `nochars' `nonotes'
            local totnotes = r(nnotes)
            local lbls `"`r(lblnames)'"'
            local nw 0
            if `"`lbls'"' != "" {
                quietly uselabel `lbls', clear
                forvalues r = 1/`=_N' {
                    local ln = lname[`r']
                    local vv = value[`r']
                    local lt = substr(label[`r'], 1, 2000)
                    post `VH' (0) ("`ln'") (`vv') (`"`lt'"')
                }
            }
        }
        else {
            * ---- stitched panel: one codebook row per variable per wave.
            * ---- Stitching leaves one value-label set per variable, so per-wave
            * ---- value labels and label-change detection are not available here
            * ---- (use files mode for those); per-wave statistics and missingness
            * ---- are.  A variable all-missing within a wave shows 100% missing. -
            capture confirm string variable `wave'
            local strwave = (_rc == 0)
            quietly levelsof `wave', local(wlevs)
            local wvallab : value label `wave'
            local nw 0
            foreach L of local wlevs {
                local ++nw
                if `strwave' local wn`nw' `"`L'"'
                else if "`wvallab'" != "" local wn`nw' : label (`wave') `L'
                else local wn`nw' `"`L'"'
                local wlev`nw' `"`L'"'
            }
            local gvars : list keepvars - wave
            tempfile MEMALL
            quietly save `MEMALL'
            forvalues w = 1/`nw' {
                quietly use `MEMALL', clear
                if `strwave' quietly keep if `wave' == `"`wlev`w''"'
                else quietly keep if `wave' == `wlev`w''
                local N`w' = _N
                quietly keep `gvars'
                _dd_rows, mh(`MH') wavenum(`w') wave(`"`wn`w''"') vars(`gvars') ///
                    examples(`examples') top(`top') `nochars' `nonotes'
                local k`w' = r(k)
                local totnotes = `totnotes' + r(nnotes)
                local lbls `"`lbls' `r(lblnames)'"'
            }
            local lbls : list uniq lbls
            * surviving value labels (one set per variable in a stitched file);
            * repeated per wave so the ValueLabels sheet lines up with Variables
            quietly use `MEMALL', clear
            if `"`lbls'"' != "" {
                quietly uselabel `lbls', clear
                local nvl = _N
                forvalues r = 1/`nvl' {
                    local ln = lname[`r']
                    local vv = value[`r']
                    local lt = substr(label[`r'], 1, 2000)
                    forvalues w = 1/`nw' {
                        post `VH' (`w') ("`ln'") (`vv') (`"`lt'"')
                    }
                }
            }
        }
    }

    postclose `MH'
    postclose `VH'

    quietly use `MAIN', clear
    local nvars = _N

    * ---- change detection across waves (files mode only: stitching waves into
    * ---- one file destroys per-wave value labels, so this cannot be done on a
    * ---- combined in-memory file) ------------------------------------------------
    local nchanges 0
    if `filesmode' {
        * one signature string per (wave, value-label set): "v=label | v=label"
        local havesig 0
        quietly use `VLAB', clear
        if _N > 0 {
            sort wavenum lname value
            quietly gen strL _p = string(value, "%13.0g") + "=" + label
            quietly by wavenum lname: gen strL _s = _p if _n == 1
            quietly by wavenum lname: replace _s = _s[_n - 1] + " | " + _p if _n > 1
            quietly by wavenum lname: keep if _n == _N
            quietly gen str2000 vsig = substr(_s, 1, 2000)
            keep wavenum lname vsig
            rename lname vallab
            quietly save `SIG'
            local havesig 1
        }
        quietly use `MAIN', clear
        if `havesig' {
            quietly merge m:1 wavenum vallab using `SIG', keep(1 3) ///
                keepusing(vsig) nogenerate
            quietly replace vsig = "" if vallab == ""
        }
        else quietly gen str1 vsig = ""
        tempfile MAINS
        quietly save `MAINS'

        postfile `CH' str80 wavepair str32 name str40 change ///
            str2000 before str2000 after using `CHG'
        postfile `FF' int wavenum str32 name str24 kind using `CHGF'
        forvalues i = 1/`= `nfiles' - 1' {
            local j = `i' + 1
            local wp `"`wn`i'' -> `wn`j''"'
            quietly use `MAINS', clear
            quietly keep if wavenum == `i'
            keep name type format varlab vallab vsig
            foreach x in type format varlab vallab vsig {
                rename `x' `x'0
            }
            tempfile A
            quietly save `A'
            quietly use `MAINS', clear
            quietly keep if wavenum == `j'
            keep name type format varlab vallab vsig
            quietly merge 1:1 name using `A'
            sort name
            forvalues r = 1/`=_N' {
                local nm = name[`r']
                if _merge[`r'] == 2 {
                    post `CH' (`"`wp'"') ("`nm'") ("variable dropped") ("") ("")
                }
                else if _merge[`r'] == 1 {
                    post `CH' (`"`wp'"') ("`nm'") ("variable added") ("") ("")
                }
                else {
                    foreach x in type format varlab {
                        local b = `x'0[`r']
                        local a = `x'[`r']
                        if `"`b'"' != `"`a'"' {
                            if "`x'" == "type"   local ct "storage type changed"
                            if "`x'" == "format" local ct "display format changed"
                            if "`x'" == "varlab" local ct "variable label changed"
                            post `CH' (`"`wp'"') ("`nm'") ("`ct'") (`"`b'"') (`"`a'"')
                            if "`x'" == "varlab" post `FF' (`j') ("`nm'") ("label")
                        }
                    }
                    local lb = vallab0[`r']
                    local la = vallab[`r']
                    local sb = vsig0[`r']
                    local sa = vsig[`r']
                    if `"`lb'"' != `"`la'"' | `"`sb'"' != `"`sa'"' {
                        local btxt = cond(`"`lb'"' == "", "(none)", `"`lb': `sb'"')
                        local atxt = cond(`"`la'"' == "", "(none)", `"`la': `sa'"')
                        local btxt = substr(`"`btxt'"', 1, 2000)
                        local atxt = substr(`"`atxt'"', 1, 2000)
                        post `CH' (`"`wp'"') ("`nm'") ("value label set changed") ///
                            (`"`btxt'"') (`"`atxt'"')
                        post `FF' (`j') ("`nm'") ("categories")
                    }
                }
            }
        }
        postclose `CH'
        postclose `FF'
        quietly use `CHG', clear
        local nchanges = _N
    }

    * ---- attach a "changed since previous wave" flag to each codebook row.
    * ---- Only files mode can detect it: a stitched panel keeps one label set
    * ---- per variable, so a wave-to-wave label change leaves no trace.  The
    * ---- flag marks a variable whose meaning may have shifted between waves. --
    local haveflags 0
    if `filesmode' {
        quietly use `CHGF', clear
        if _N > 0 {
            quietly gen byte _lab = (kind == "label")
            quietly gen byte _cat = (kind == "categories")
            collapse (max) _lab _cat, by(wavenum name)
            quietly gen str24 changed = cond(_lab & _cat, "label+categories", ///
                cond(_lab == 1, "label", "categories"))
            keep wavenum name changed
            tempfile FLAGS
            quietly save `FLAGS'
            local haveflags 1
        }
    }
    quietly use `MAIN', clear
    quietly gen long _seq = _n
    if `haveflags' {
        quietly merge 1:1 wavenum name using `FLAGS', keep(1 3) nogenerate
    }
    sort _seq
    quietly drop _seq
    capture confirm variable changed
    if _rc quietly gen str24 changed = ""
    quietly replace changed = "" if changed == "."
    quietly save `MAIN', replace

    * ---- display ---------------------------------------------------------------------
    local overtime = (`nw' > 0)
    di as txt _n "datadictionary 1.0.0"
    if `filesmode' {
        di as txt "  mode: " as res "files" as txt "    files: " as res `nfiles' ///
            as txt "    codebook rows: " as res `nvars'
        di as txt "  changes detected across waves: " as res `nchanges'
    }
    else {
        di as txt "  mode: " as res "in-memory" as txt "    source: " as res `"`srcname'"'
        di as txt "  observations: " as res `NKEPT' as txt "    variables documented: " as res `nvars'
        if `overtime' di as txt "  stitched waves (" as res "`wave'" as txt "): " as res `nw'
    }

    quietly use `MAIN', clear
    local lastw = -1
    forvalues r = 1/`=_N' {
        if wavenum[`r'] != `lastw' {
            local lastw = wavenum[`r']
            if `overtime' {
                di as txt _n "{hline 80}"
                di as txt "wave " as res `"`wn`lastw''"' as txt ///
                    "  (N = " as res `N`lastw'' as txt ", variables = " as res `k`lastw'' as txt ")"
            }
            di as txt "{hline 80}"
            di as txt %-13s "name" %-8s "type" %-9s "format" ///
                %8s "N" %7s "miss%" %6s "dist" "  " %-24s "label" ///
                cond(`overtime', "  changed", "")
            di as txt "{hline 80}"
        }
        local nm = name[`r']
        local ty = type[`r']
        local fm = format[`r']
        local vl = varlab[`r']
        local cf = changed[`r']
        di as res %-13s abbrev("`nm'", 12) as txt %-8s "`ty'" ///
            %-9s abbrev("`fm'", 8) as res %8.0f n[`r'] %7.1f pctmiss[`r'] ///
            %6.0f distinct[`r'] as txt "  " %-24s abbrev(`"`vl'"', 24) _c
        if `overtime' & "`cf'" != "" di as err "  <- `cf'"
        else di ""
    }
    di as txt "{hline 80}"

    if `filesmode' & `nchanges' > 0 {
        di as txt _n "Changes detected across waves:"
        quietly use `CHG', clear
        forvalues r = 1/`=_N' {
            local wp = wavepair[`r']
            local nm = name[`r']
            local ct = change[`r']
            local b  = before[`r']
            local a  = after[`r']
            di as txt "  " %-16s `"`wp'"' as res %-13s abbrev("`nm'", 12) ///
                as txt %-26s "`ct'" _c
            if `"`b'`a'"' != "" {
                di as txt "  " abbrev(`"`b'"', 24) " -> " abbrev(`"`a'"', 24)
            }
            else di ""
        }
    }

    * ---- saving(): the machine-readable codebook -----------------------------------
    if `"`saving'"' != "" {
        quietly use `MAIN', clear
        if !`overtime' quietly drop wave wavenum changed
        else order wave name, first
        label variable name     "variable name"
        label variable type     "storage type"
        label variable format   "display format"
        label variable varlab   "variable label"
        label variable vallab   "value-label name"
        label variable n        "N nonmissing"
        label variable pctmiss  "% missing"
        label variable distinct "distinct nonmissing values"
        label variable mean     "mean"
        label variable sd       "std. dev."
        label variable min      "minimum"
        label variable p50      "median"
        label variable max      "maximum"
        label variable examples "example values / top categories"
        label variable notes    "stored notes"
        label variable srctag   "char [srctag] (combineall/projectbuilder)"
        label variable chars    "other characteristics"
        if `overtime' {
            label variable wave    "wave"
            label variable wavenum "wave order"
            capture label variable changed "changed vs previous wave"
        }
        label data "datadictionary codebook: `srcname'"
        quietly compress
        quietly save `"`saving'"', replace
        di as txt _n "wrote " as res `"`saving'"'
    }

    * ---- excel(): multi-sheet workbook ------------------------------------------------
    if `"`excel'"' != "" {
        * Overview sheet (created first so it is the workbook's first sheet)
        putexcel set `"`excel'"', sheet("Overview") replace open
        putexcel A1 = "datadictionary codebook", bold
        putexcel A2 = "Generated"
        putexcel B2 = "`c(current_date)' `c(current_time)'"
        putexcel A3 = "Mode"
        local modestr = cond(`filesmode', "files", "in-memory")
        putexcel B3 = "`modestr'"
        putexcel A4 = "Source"
        if `filesmode' {
            local srclist ""
            forvalues i = 1/`nfiles' {
                local srclist `"`srclist'`file`i''; "'
            }
            local srclist = substr(`"`srclist'"', 1, max(1, strlen(`"`srclist'"') - 2))
            putexcel B4 = `"`srclist'"'
        }
        else putexcel B4 = `"`srcname'"'
        putexcel A5 = "Codebook rows"
        putexcel B5 = `nvars'
        putexcel A6 = "Variable notes harvested"
        putexcel B6 = `totnotes'
        local rr 7
        if `filesmode' {
            putexcel A`rr' = "Changes detected"
            putexcel B`rr' = `nchanges'
            local ++rr
        }
        local ++rr
        if `overtime' {
            putexcel A`rr' = "Wave", bold
            putexcel B`rr' = "N", bold
            putexcel C`rr' = "Variables", bold
            forvalues w = 1/`nw' {
                local ++rr
                putexcel A`rr' = `"`wn`w''"'
                putexcel B`rr' = `N`w''
                putexcel C`rr' = `k`w''
            }
        }
        else {
            putexcel A`rr' = "N", bold
            putexcel B`rr' = "Variables", bold
            local ++rr
            putexcel A`rr' = `NKEPT'
            putexcel B`rr' = `nvars'
        }
        putexcel save

        * Variables sheet: the codebook.  % missing sits beside the statistics,
        * common values, labels, and notes; over-time modes add a wave column
        * and a "changed vs previous wave" flag.  (No separate Missingness sheet:
        * pctmiss is a column here.)
        quietly use `MAIN', clear
        quietly drop wavenum
        if !`overtime' quietly drop wave changed
        else order wave name, first
        if _N > 0 {
            quietly export excel using `"`excel'"', sheet("Variables") ///
                sheetreplace firstrow(variables)
        }
        _dd_bold, file(`"`excel'"') sheet("Variables")

        * ValueLabels sheet
        quietly use `VLAB', clear
        if `overtime' {
            quietly gen str80 wave = ""
            forvalues w = 1/`nw' {
                quietly replace wave = `"`wn`w''"' if wavenum == `w'
            }
            order wave lname value label
        }
        quietly drop wavenum
        if _N > 0 {
            quietly export excel using `"`excel'"', sheet("ValueLabels") ///
                sheetreplace firstrow(variables)
        }
        _dd_bold, file(`"`excel'"') sheet("ValueLabels")

        * Changes sheet (files mode only: see the change-detection note above)
        if `filesmode' {
            quietly use `CHG', clear
            if _N > 0 {
                quietly export excel using `"`excel'"', sheet("Changes") ///
                    sheetreplace firstrow(variables)
            }
            _dd_bold, file(`"`excel'"') sheet("Changes")
        }

        di as txt "wrote " as res `"`excel'"'
    }

    if `"`dofile'"' != ""     di as txt "wrote " as res `"`dofile'"' as txt " (relabel do-file)"
    if `"`dictionary'"' != "" di as txt "wrote " as res `"`dictionary'"' as txt " (infile dictionary)"

    * ---- clickable links to open the outputs and their folder --------------------------
    if `"`excel'`saving'`dofile'`dictionary'"' != "" {
        di as txt _n "Open:"
        if `"`excel'"'      != "" _dd_link, path(`"`excel'"')      tag("codebook (Excel)")
        if `"`saving'"'     != "" _dd_link, path(`"`saving'"')     tag("codebook (.dta)")
        if `"`dofile'"'     != "" _dd_link, path(`"`dofile'"')     tag("relabel do-file")
        if `"`dictionary'"' != "" _dd_link, path(`"`dictionary'"') tag("infile dictionary")
        _dd_link, path(`"`excel'`saving'`dofile'`dictionary'"') tag("containing folder") folder
    }

    * ---- stored results -----------------------------------------------------------------
    return scalar nvars    = `nvars'
    return scalar nchanges = `nchanges'
    if `"`excel'"' != ""      return local xlsx `"`excel'"'
    if `"`saving'"' != ""     return local dta `"`saving'"'
    if `"`dofile'"' != ""     return local dofile `"`dofile'"'
    if `"`dictionary'"' != "" return local dct `"`dictionary'"'
end


* ---------------------------------------------------------------------------
* _dd_link: print a clickable SMCL link that opens a file (or its folder) in
* the OS.  The path is made absolute against the current directory so the link
* works no matter where the Results window scrolls to.
* ---------------------------------------------------------------------------
program define _dd_link
    version 16.0
    syntax , PATH(string) TAG(string) [ FOLDER ]
    * absolute path
    local p `"`path'"'
    if substr(`"`p'"', 1, 1) != "/" & substr(`"`p'"', 2, 1) != ":" {
        local p `"`c(pwd)'/`p'"'
    }
    if "`folder'" != "" {
        * strip to the directory
        local sl = strrpos(`"`p'"', "/")
        if `sl' > 1 local p = substr(`"`p'"', 1, `sl' - 1)
    }
    local q = char(34)
    di as txt `"  {browse `q'`p'`q':`tag'}"'
end


* ---------------------------------------------------------------------------
* _dd_rows: harvest one codebook row per variable of the dataset in memory
* and post it to the main postfile.  Returns r(k) (variables documented),
* r(nnotes) (variable notes seen), and r(lblnames) (value labels attached).
* The routine sorts the data while computing distinct counts and example
* values; callers must not rely on row order afterward.
* ---------------------------------------------------------------------------
program define _dd_rows, rclass
    version 16.0
    syntax , MH(name) WAVENUM(integer) EXAMPLES(integer) TOP(integer) ///
        [ WAVE(string) VARS(string) NOCHARS NONOTES ]

    if `"`vars'"' == "" unab vars : _all
    local NT = _N
    local wavelab = substr(`"`wave'"', 1, 80)
    local nnotes 0
    local lblnames ""
    local k 0

    foreach v of local vars {
        local ++k
        local ty : type `v'
        local fm : format `v'
        local vl : variable label `v'
        local ll : value label `v'
        if "`ll'" != "" local lblnames `lblnames' `ll'
        local isstr = (strpos("`ty'", "str") == 1)

        * N nonmissing and % missing
        if `isstr' quietly count if `v' != ""
        else quietly count if !missing(`v')
        local nn = r(N)
        local pctm = cond(`NT' > 0, 100 * (`NT' - `nn') / `NT', .)

        * distinct nonmissing values
        local dist 0
        if `nn' > 0 {
            tempvar tg
            if `isstr' {
                quietly bysort `v': gen byte `tg' = (_n == 1 & `v' != "")
            }
            else quietly bysort `v': gen byte `tg' = (_n == 1 & !missing(`v'))
            quietly count if `tg'
            local dist = r(N)
            drop `tg'
        }

        * numeric summary statistics (blank for strings)
        local mn .
        local sd .
        local mi .
        local md .
        local mx .
        if !`isstr' & `nn' > 0 {
            quietly summarize `v', detail
            local mn = r(mean)
            local sd = r(sd)
            local mi = r(min)
            local md = r(p50)
            local mx = r(max)
        }

        * example values: distinct examples for strings; top categories by
        * frequency, as "label (n, pct%)", for value-labeled variables
        local ex ""
        if `isstr' & `nn' > 0 {
            sort `v'
            local ct 0
            local last ""
            local o 1
            while `ct' < `examples' & `o' <= `NT' {
                local cur = `v'[`o']
                if `"`cur'"' != "" & `"`cur'"' != `"`last'"' {
                    local ++ct
                    if `ct' == 1 local ex `"`cur'"'
                    else local ex `"`ex', `cur'"'
                    local last `"`cur'"'
                }
                local ++o
            }
        }
        else if "`ll'" != "" & `nn' > 0 {
            tempname F R
            capture quietly tabulate `v', sort matcell(`F') matrow(`R')
            if _rc == 0 {
                local tot = r(N)
                local take = min(`top', rowsof(`R'))
                forvalues j = 1/`take' {
                    local vv = `R'[`j', 1]
                    local ff = `F'[`j', 1]
                    local pc = strtrim(string(100 * `ff' / `tot', "%5.1f"))
                    capture local lb : label (`v') `vv'
                    if _rc local lb "`vv'"
                    if `j' == 1 local ex `"`lb' (`ff', `pc'%)"'
                    else local ex `"`ex', `lb' (`ff', `pc'%)"'
                }
            }
        }
        local ex = substr(`"`ex'"', 1, 2000)

        * stored notes
        local ntxt ""
        if "`nonotes'" == "" {
            local k0 : char `v'[note0]
            capture local k0 = int(real("`k0'"))
            if "`k0'" == "" | "`k0'" == "." local k0 0
            forvalues j = 1/`k0' {
                local t : char `v'[note`j']
                if `j' == 1 local ntxt `"`j'. `t'"'
                else local ntxt `"`ntxt' | `j'. `t'"'
            }
            local nnotes = `nnotes' + `k0'
            local ntxt = substr(`"`ntxt'"', 1, 2000)
        }

        * characteristics: srctag in its own column, all others concatenated
        local st ""
        local ch ""
        if "`nochars'" == "" {
            local st : char `v'[srctag]
            local st = substr(`"`st'"', 1, 2000)
            local allc : char `v'[]
            foreach c of local allc {
                if "`c'" == "srctag" continue
                if regexm("`c'", "^note[0-9]+$") | "`c'" == "note0" continue
                local cv : char `v'[`c']
                if `"`ch'"' == "" local ch `"`c'=`cv'"'
                else local ch `"`ch'; `c'=`cv'"'
            }
            local ch = substr(`"`ch'"', 1, 2000)
        }

        post `mh' (`wavenum') (`"`wavelab'"') ("`v'") ("`ty'") ("`fm'")   ///
            (`"`vl'"') ("`ll'") (`nn') (`pctm') (`dist')                  ///
            (`mn') (`sd') (`mi') (`md') (`mx')                            ///
            (`"`ex'"') (`"`ntxt'"') (`"`st'"') (`"`ch'"')
    }

    local lblnames : list uniq lblnames
    return local lblnames `lblnames'
    return scalar nnotes = `nnotes'
    return scalar k = `k'
end


* ---------------------------------------------------------------------------
* _dd_bold: bold the header row of one sheet via putexcel.  Headers come from
* the dataset in memory (variable names, or variable labels with -labels-).
* putexcel creates the sheet when it does not exist yet, so this also writes
* header-only sheets for empty tables.
* ---------------------------------------------------------------------------
program define _dd_bold
    version 16.0
    syntax , FILE(string) SHEET(string) [ LABels ]
    unab allv : _all
    local k : word count `allv'
    putexcel set `"`file'"', sheet("`sheet'") modify open
    forvalues c = 1/`k' {
        local v : word `c' of `allv'
        if "`labels'" != "" {
            local h : variable label `v'
            if `"`h'"' == "" local h "`v'"
        }
        else local h "`v'"
        if `c' <= 26 local L = char(64 + `c')
        else local L = char(64 + int((`c' - 1) / 26)) + char(65 + mod(`c' - 1, 26))
        putexcel `L'1 = `"`h'"', bold
    }
    putexcel save
end


* ---------------------------------------------------------------------------
* _dd_dofile: write a do-file that re-applies variable labels, value labels,
* display formats, storage types, notes, and characteristics to a dataset
* after a CSV/Excel round-trip.  Runs on the documented data in memory.  Every
* restore is -capture-d so a renamed/dropped column is skipped, not fatal, and
* a receipt at the foot reports what did not match on re-ingestion.
* ---------------------------------------------------------------------------
program define _dd_dofile
    version 16.0
    syntax , DOfile(string) SRCname(string) [ NOCHars NONotes NORECast ]

    unab vars : _all

    * attached value labels, in variable order, unique
    local lblnames ""
    foreach v of local vars {
        local ll : value label `v'
        if "`ll'" != "" local lblnames `lblnames' `ll'
    }
    local lblnames : list uniq lblnames
    tempfile lbldo
    if "`lblnames'" != "" quietly label save `lblnames' using `"`lbldo'"', replace

    * basename for the -do- hint in the header
    local base `"`dofile'"'
    local sl = strrpos(`"`base'"', "/")
    if `sl' > 0 local base = substr(`"`base'"', `sl' + 1, .)

    tempname fh
    file open `fh' using `"`dofile'"', write text replace
    file write `fh' `"*! Relabel do-file written by datadictionary 1.0.0"' _n
    file write `fh' `"*! Source: `srcname'"' _n
    file write `fh' `"*! Generated: `c(current_date)' `c(current_time)'"' _n
    file write `fh' `"*!"' _n
    file write `fh' `"*! Restores variable labels, value labels, display formats, storage types,"' _n
    file write `fh' `"*! notes, and characteristics after a CSV/Excel round-trip (e.g. a file sent"' _n
    file write `fh' `"*! to a collaborator working in R, Python, or Excel and returned as data)."' _n
    file write `fh' `"*! Typical round-trip:"' _n
    file write `fh' `"*!     export delimited using "share.csv", nolabel replace"' _n
    file write `fh' `"*!     * ...collaborator edits share.csv in R/Python/Excel and returns it..."' _n
    file write `fh' `"*!     import delimited using "share.csv", varnames(1) case(preserve) clear"' _n
    file write `fh' `"*!     do `base'"' _n
    file write `fh' `"*! Export with -nolabel- so value-labeled variables travel as their numeric"' _n
    file write `fh' `"*! codes; this file reattaches the code-to-label mappings.  Every command below"' _n
    file write `fh' `"*! is -capture-d, so a column the collaborator renamed or dropped is skipped"' _n
    file write `fh' `"*! rather than stopping the run; the receipt at the foot reports what did not"' _n
    file write `fh' `"*! match."' _n
    file write `fh' "" _n

    * match column names exactly (not by abbreviation), so a renamed column is
    * skipped, never fuzzily relabeled; the prior setting is restored at the end
    file write `fh' `"local __dd_va = c(varabbrev)"' _n
    file write `fh' `"set varabbrev off"' _n
    file write `fh' "" _n

    * value-label definitions, inlined verbatim from -label save-
    if "`lblnames'" != "" {
        file write `fh' `"* ---- value-label definitions ----"' _n
        tempname lh
        file open `lh' using `"`lbldo'"', read text
        file read `lh' line
        while r(eof) == 0 {
            file write `fh' `"`macval(line)'"' _n
            file read `lh' line
        }
        file close `lh'
        file write `fh' "" _n
    }

    * per-variable: storage type, variable label, format, value label
    file write `fh' `"* ---- variable labels, storage types, formats, value labels ----"' _n
    foreach v of local vars {
        local ty : type `v'
        local fm : format `v'
        local vl : variable label `v'
        local ll : value label `v'
        if "`norecast'" == "" file write `fh' `"capture recast `ty' `v'"' _n
        if `"`vl'"' != "" {
            local L `"capture label variable `v' `"`vl'"'"'
            file write `fh' `"`macval(L)'"' _n
        }
        file write `fh' `"capture format `v' `fm'"' _n
        if "`ll'" != "" file write `fh' `"capture label values `v' `ll'"' _n
    }
    file write `fh' "" _n

    * notes
    if "`nonotes'" == "" {
        local wrotehdr 0
        foreach v of local vars {
            local k0 : char `v'[note0]
            capture local k0 = int(real("`k0'"))
            if "`k0'" == "" | "`k0'" == "." local k0 0
            forvalues j = 1/`k0' {
                if !`wrotehdr' {
                    file write `fh' `"* ---- notes ----"' _n
                    local wrotehdr 1
                }
                local t : char `v'[note`j']
                local L `"capture note `v' : `t'"'
                file write `fh' `"`macval(L)'"' _n
            }
        }
        if `wrotehdr' file write `fh' "" _n
    }

    * characteristics (srctag and any others; notes handled above)
    if "`nochars'" == "" {
        local wrotehdr 0
        foreach v of local vars {
            local allc : char `v'[]
            foreach c of local allc {
                if regexm("`c'", "^note[0-9]+$") | "`c'" == "note0" continue
                local cv : char `v'[`c']
                if !`wrotehdr' {
                    file write `fh' `"* ---- characteristics (including srctag) ----"' _n
                    local wrotehdr 1
                }
                local L `"capture char define `v'[`c'] `"`cv'"'"'
                file write `fh' `"`macval(L)'"' _n
            }
        }
        if `wrotehdr' file write `fh' "" _n
    }

    * re-ingestion receipt: what matched, what did not.  The receipt is plain
    * Stata that runs when the collaborator's file is re-imported.  It contains
    * `macro' references, which cannot be emitted through ordinary macro
    * expansion (the produced backtick would re-expand); each line is stored as
    * a template with @ standing for the open-quote ` and | for the close-quote
    * ', then subinstr swaps in the real characters and -macval- writes the
    * result verbatim.
    local T1  `"* ---- re-ingestion receipt: what matched, what did not ----"'
    local T2  `"local __dd_expected "`vars'""'
    local T3  `"local __dd_missing """'
    local T4  `"foreach __dd_v of local __dd_expected {"'
    local T5  `"    capture confirm variable @__dd_v|, exact"'
    local T6  `"    if _rc local __dd_missing "@__dd_missing| @__dd_v|""'
    local T7  `"}"'
    local T8  `"capture unab __dd_present : _all"'
    local T9  `"local __dd_extra : list __dd_present - __dd_expected"'
    local T10 `"local __dd_ne : word count @__dd_expected|"'
    local T11 `"local __dd_nm : word count @__dd_missing|"'
    local T12 `"local __dd_nr = @__dd_ne| - @__dd_nm|"'
    local T13 `"display as text _n "{hline 64}""'
    local T14 `"display as text "datadictionary relabel receipt""'
    local T15 `"display as text "  expected variables : @__dd_ne|""'
    local T16 `"display as text "  restored (matched) : @__dd_nr|""'
    local T17 `"if "@__dd_missing|" != "" display as text "  NOT found (renamed or dropped?):@__dd_missing|""'
    local T18 `"if "@__dd_extra|" != "" display as text "  extra columns (added, not in codebook):@__dd_extra|""'
    local T19 `"display as text "{hline 64}""'
    local T20 `"set varabbrev @__dd_va|"'
    forvalues i = 1/20 {
        local L = subinstr(subinstr(`"`T`i''"', "@", char(96), .), "|", char(39), .)
        file write `fh' `"`macval(L)'"' _n
    }
    file close `fh'
end


* ---------------------------------------------------------------------------
* _dd_dict: write a free-format -infile- dictionary (.dct) describing storage
* type and variable label per variable, for teams that want a Stata dictionary
* for archival or single-step typed ingestion.  A dictionary is legacy and
* narrower than the relabel do-file: free-format -infile- is WHITESPACE- (not
* comma-) delimited and a dictionary carries type + variable label only (no
* value labels, notes, or chars).  It reads a tab/space-delimited file whose
* strings are quoted and whose value-labeled variables are exported as numeric
* codes, with the header row skipped by _first(2).  For the general CSV
* round-trip use -import delimited- plus the relabel do-file instead.
* ---------------------------------------------------------------------------
program define _dd_dict
    version 16.0
    syntax , DICTionary(string) SRCname(string)

    unab vars : _all

    * default data-file reference: same basename as the dictionary, .txt
    local dbase `"`dictionary'"'
    local sl = strrpos(`"`dbase'"', "/")
    if `sl' > 0 local dbase = substr(`"`dbase'"', `sl' + 1, .)
    local dt = strrpos(`"`dbase'"', ".")
    if `dt' > 0 local dbase = substr(`"`dbase'"', 1, `dt' - 1)
    local dataref `"`dbase'.txt"'

    tempname fh
    file open `fh' using `"`dictionary'"', write text replace
    file write `fh' `"infile dictionary using "`dataref'" {"' _n
    file write `fh' `"    _first(2)"' _n
    file write `fh' `"    * datadictionary dictionary for `srcname'"' _n
    file write `fh' `"    * generated `c(current_date)' `c(current_time)'"' _n
    file write `fh' `"    * Storage type + variable label only.  Value labels, notes, and"' _n
    file write `fh' `"    * characteristics need the companion relabel do-file (datadictionary,"' _n
    file write `fh' `"    * dofile()).  Free-format -infile- is WHITESPACE-delimited, so prepare the"' _n
    file write `fh' `"    * data file with:"' _n
    file write `fh' `"    *     export delimited using "`dataref'", delimiter(tab) nolabel quote replace"' _n
    file write `fh' `"    * (numeric codes for labeled variables, strings quoted, tab separators)."' _n
    file write `fh' `"    * The header row is skipped by _first(2).  Read it back with:"' _n
    file write `fh' `"    *     infile using "`dictionary'", clear"' _n
    file write `fh' `"    * For a general comma-delimited CSV use import delimited + the do-file."' _n
    foreach v of local vars {
        local ty : type `v'
        local vl : variable label `v'
        * a dictionary quotes labels with "; embedded double quotes would break
        * the line, so soften them to single quotes (the do-file keeps them exact)
        local vl = subinstr(`"`vl'"', char(34), "'", .)
        if `"`vl'"' != "" {
            file write `fh' `"    `ty' `v' "`vl'""' _n
        }
        else file write `fh' `"    `ty' `v'"' _n
    }
    file write `fh' `"}"' _n
    file close `fh'
end
