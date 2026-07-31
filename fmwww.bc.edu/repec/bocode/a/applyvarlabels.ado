*! version 1.0.0  20260718  Eric A. Booth, Sr Researcher, Texas 2036
*! applyvarlabels: label the variables in memory from a two-column
*!                 (Variable, Label) crosswalk held in Excel or a CSV
*
*  The problem (Statalist 1768839): you are handed a dataset of 100+ variables,
*  none of them labeled, alongside a spreadsheet that lists each variable name
*  beside the label it should carry.  The tempting loop -- levelsof the labels,
*  tokenize the variables, march down both -- fails, because levelsof returns
*  the distinct labels sorted ALPHABETICALLY, so pairing them positionally with
*  the variables lines them up in the wrong order.
*
*  applyvarlabels reads the crosswalk in ROW ORDER and matches every label to
*  its variable BY NAME, never by position.  It WRITES a capture-guarded relabel
*  do-file (a variable named in the crosswalk but absent from your data is simply
*  skipped, not an error), RUNS that do-file to apply the labels, and prints an
*  inventory of everything that did not line up: crosswalk rows with no such
*  variable, and variables in memory that the crosswalk never mentions.
*
*  The data in memory are never sorted, dropped, or reordered -- the crosswalk is
*  read in its own frame, so nothing changes but the variable labels themselves.
*  The generated do-file is a keepable, rerunnable artifact (see dofile()).

program define applyvarlabels, rclass
    version 16.0

    syntax using/ [, Variable(name) Label(name) SHEET(string)          ///
        DOfile(string) SMCL(string) REPLACE NOCASE NORUN ]

    * ------------------------------------------------------------------ setup --
    if "`variable'" == "" local variable Variable
    if "`label'"    == "" local label    Label

    if c(k) == 0 {
        di as err "no variables in memory to label; use or import your data first"
        exit 2000
    }
    capture confirm file `"`using'"'
    if _rc {
        di as err `"crosswalk file not found: `using'"'
        exit 601
    }

    * exact name matching: turn off abbreviation so a crosswalk row "inc" never
    * silently lands on a variable named "income".  Restored on the way out.
    local va = c(varabbrev)
    set varabbrev off

    quietly ds
    local mainvars `r(varlist)'
    local nmain : word count `mainvars'

    * pick the importer from the file extension (Excel by default) --------------
    local low = lower(`"`using'"')
    if regexm(`"`low'"', "\.(csv|tsv|txt)$") local how delim
    else                                     local how excel
    local sheetopt ""
    if `"`sheet'"' != "" {
        if "`how'" == "excel" local sheetopt `"sheet(`"`sheet'"')"'
        else di as txt "note: sheet() ignored for a delimited crosswalk"
    }

    * where the relabel do-file will be written --------------------------------
    if `"`dofile'"' == "" {
        local dofile `"`c(tmpdir)'applyvarlabels_relabel.do"'
        local dodefault 1
    }
    else {
        if !regexm(lower(`"`dofile'"'), "\.do$") local dofile `"`dofile'.do"'
        if "`replace'" == "" {
            capture confirm new file `"`dofile'"'
            if _rc {
                set varabbrev `va'
                di as err `"do-file `dofile' already exists; specify replace"'
                exit 602
            }
        }
    }

    * where the inventory SMCL will be written (validated up front, like dofile) -
    if `"`smcl'"' == "" local smclout `"`c(tmpdir)'applyvarlabels_inventory.smcl"'
    else {
        local smclout `"`smcl'"'
        if !regexm(lower(`"`smclout'"'), "\.smcl$") local smclout `"`smclout'.smcl"'
        if "`replace'" == "" {
            capture confirm new file `"`smclout'"'
            if _rc {
                set varabbrev `va'
                di as err `"smcl file `smclout' already exists; specify replace"'
                exit 602
            }
        }
    }

    * ------------------------------------------------ read the crosswalk frame --
    tempname cw
    frame create `cw'
    frame `cw' {
        if "`how'" == "excel" ///
            capture noisily import excel using `"`using'"', `sheetopt' firstrow allstring clear
        else ///
            capture noisily import delimited using `"`using'"', varnames(1) stringcols(_all) clear
        if _rc {
            local importrc = _rc
        }
        else {
            quietly ds
            local cols `r(varlist)'
            local vcol ""
            local lcol ""
            foreach c of local cols {
                if strlower("`c'") == strlower("`variable'") local vcol `c'
                if strlower("`c'") == strlower("`label'")    local lcol `c'
            }
            local ncross = _N
        }
    }
    if "`importrc'" != "" {
        capture frame drop `cw'
        set varabbrev `va'
        di as err `"could not read the crosswalk (import returned r(`importrc'))"'
        exit `importrc'
    }
    if "`vcol'" == "" | "`lcol'" == "" {
        capture frame drop `cw'
        set varabbrev `va'
        if "`vcol'" == "" di as err `"variable-name column "`variable'" not found in crosswalk (columns: `cols')"'
        if "`lcol'" == "" di as err `"label column "`label'" not found in crosswalk (columns: `cols')"'
        di as err "use variable() and label() to name the crosswalk columns"
        exit 111
    }

    * ---------------------------------------- write the capture-guarded do-file --
    local bq = char(96)     // `  -- placeholders so the generated file carries a
    local fq = char(39)     // '  -- LITERAL `avl_va', not this program's macro
    tempname fh
    capture file open `fh' using `"`dofile'"', write text replace
    if _rc {
        capture frame drop `cw'
        set varabbrev `va'
        di as err `"cannot write the relabel do-file: `dofile'"'
        exit _rc
    }
    file write `fh' `"*! relabel do-file written by -applyvarlabels- on `c(current_date)' `c(current_time)'"' _n
    file write `fh' `"*! crosswalk: `using'"' _n
    file write `fh' `"*! Each line is capture-guarded: a variable absent from the data is skipped,"' _n
    file write `fh' `"*! so this file is safe to rerun on any dataset that shares these names."' _n
    file write `fh' "" _n
    file write `fh' "local avl_va = c(varabbrev)" _n
    file write `fh' "set varabbrev off" _n

    local matched  ""       // real variable names that received a label
    local missing  ""       // crosswalk rows with no such variable in memory
    local dups     ""       // variables named more than once in the crosswalk
    local blanks   ""       // crosswalk rows whose label cell was empty
    local normalized ""     // labels altered for Stata (curly quotes, apostrophes)
    local nlong    = 0      // labels over Stata's 80-character limit
    local seen     ""
    local napplied = 0
    local nmisses  = 0      // crosswalk ROWS with no matching variable
    local dq = char(34)     // "  -- a straight double quote
    local cq = uchar(8221)  // "  -- its typographic replacement
    local bd = char(92) + char(36)   // \$ -- written escape that survives -do-

    frame `cw' {
        forvalues i = 1/`ncross' {
            local vname = strtrim(`vcol'[`i'])
            local vlab  = strtrim(`lcol'[`i'])
            if "`vname'" == "" continue          // blank / spacer row

            * resolve the crosswalk name to a real variable in memory ----------
            local realname ""
            local hit : list posof "`vname'" in mainvars
            if `hit' local realname `vname'
            else if "`nocase'" != "" {
                foreach m of local mainvars {
                    if strlower("`m'") == strlower("`vname'") local realname `m'
                }
            }
            if "`realname'" == "" {
                local missing `missing' `vname'
                local ++nmisses
                continue
            }
            if `"`vlab'"' == "" {
                local blanks `blanks' `realname'
                continue
            }
            * Two characters cannot be carried as-is and are normalized (the
            * label still reads; the affected variables are reported):
            *   - a straight double quote " -- -label variable- cannot parse one;
            *   - a backtick ` -- no do-file escape exists for it, and it would
            *     open a macro reference when the relabel do-file runs.
            if strpos(`"`macval(vlab)'"', `"`dq'"') {
                local vlab : subinstr local vlab `"`dq'"' `"`cq'"', all
                local normalized `normalized' `realname'
            }
            if strpos(`"`macval(vlab)'"', char(96)) {
                local vlab = subinstr(`"`macval(vlab)'"', char(96), char(39), .)
                local normalized `normalized' `realname'
            }
            local wasseen : list posof "`realname'" in seen
            if `wasseen' local dups `dups' `realname'
            local seen `seen' `realname'
            if length(`"`macval(vlab)'"') > 80 local ++nlong

            * A dollar sign IS preserved: escape $ -> \$ in the WRITTEN line so it
            * is not macro-expanded when the relabel do-file is run; the label
            * applied to the data keeps a real $.
            local vlabw = subinstr(`"`macval(vlab)'"', char(36), `"`macval(bd)'"', .)

            * capture label variable <name> `"<label>"'  (compound quotes keep
            * apostrophes and ampersands intact) ------------------------------
            local line `"capture label variable `realname' `"`macval(vlabw)'"'"'
            file write `fh' `"`macval(line)'"' _n
            local matched `matched' `realname'
            local ++napplied
        }
    }

    file write `fh' "set varabbrev `bq'avl_va`fq'" _n
    file close `fh'
    capture frame drop `cw'

    * ------------------------------------------------------- apply the labels --
    local dorc = 0
    if "`norun'" == "" {
        capture noisily quietly do `"`dofile'"'
        local dorc = _rc
    }
    set varabbrev `va'      // always restored, even if the do-file aborted
    if `dorc' di as err "warning: the relabel do-file did not run cleanly (r(`dorc')); some labels may be unapplied"

    * what did not line up ------------------------------------------------------
    local applied  : list uniq matched
    local unlabeled : list mainvars - matched
    local dupsu    : list uniq dups
    local normalizedu : list uniq normalized
    local nmiss  = `nmisses'                // row count (robust to spaced names)
    local nunlab : word count `unlabeled'
    local nappliedv : word count `applied'
    local nnorm     : word count `normalizedu'

    * ------------------------------------------------------- SMCL inventory ----
    capture {
        tempname sf
        file open `sf' using `"`smclout'"', write text replace
        file write `sf' "{smcl}" _n
        file write `sf' "{txt}{bf:applyvarlabels inventory}  {c -}  `c(current_date)' `c(current_time)'" _n
        file write `sf' "{hline 72}" _n
        file write `sf' `"{txt}crosswalk : `using'"' _n
        if "`norun'" == "" file write `sf' "{txt}applied   : `nappliedv' label(s) to `nappliedv' of `nmain' variables in memory" _n
        else               file write `sf' "{txt}applied   : none (norun) -- `nappliedv' variable(s) would be labeled; do-file written, not run" _n
        file write `sf' "{hline 72}" _n
        file write `sf' "{txt}{bf:Crosswalk rows with no matching variable} (`nmiss')" _n
        if `nmiss'  file write `sf' `"{res}  `missing'"' _n
        else        file write `sf' "{txt}  (none -- every crosswalk variable was found)" _n
        file write `sf' "{txt}{bf:Variables in memory with no crosswalk row} (`nunlab')" _n
        if `nunlab' file write `sf' `"{res}  `unlabeled'"' _n
        else        file write `sf' "{txt}  (none -- every variable got a crosswalk label)" _n
        if "`dupsu'" != "" file write `sf' `"{txt}{bf:Variables labeled more than once} (last wins): {res}`dupsu'"' _n
        if "`blanks'" != "" file write `sf' `"{txt}{bf:Crosswalk rows with an empty label} (skipped): {res}`blanks'"' _n
        if "`normalizedu'" != "" file write `sf' `"{txt}{bf:Labels normalized for Stata} (straight quotes {c 45}> curly, backticks {c 45}> apostrophes): {res}`normalizedu'"' _n
        if `nlong'          file write `sf' "{txt}{bf:Labels over 80 characters} (Stata truncates): {res}`nlong'" _n
        file write `sf' "{hline 72}" _n
        file close `sf'
    }
    capture confirm file `"`smclout'"'
    local haveinv = (_rc == 0)

    * ------------------------------------------------------- console report ----
    di as txt _n "{hline 72}"
    di as txt "{bf:applyvarlabels}  {c -}  " as res `"`using'"'
    di as txt "{hline 72}"
    if "`norun'" == "" di as txt "labels applied: " as res "`nappliedv'" as txt " of " as res "`nmain'" as txt " variables in memory"
    else               di as txt "norun: " as res "`nappliedv'" as txt " variable(s) would be labeled; do-file written, none applied"

    di as txt _n "crosswalk rows with {bf:no matching variable} " as res "(`nmiss')" as txt ":"
    if `nmiss' di as res "  `missing'"
    else       di as txt "  (none -- every crosswalk variable was found in memory)"

    di as txt _n "variables in memory with {bf:no crosswalk row} " as res "(`nunlab')" as txt ":"
    if `nunlab' di as res "  `unlabeled'"
    else        di as txt "  (none -- every variable got a crosswalk label)"

    if "`dupsu'" != ""  di as txt _n "note: labeled more than once (last label wins): " as res "`dupsu'"
    if "`blanks'" != "" di as txt "note: crosswalk rows with an empty label were skipped: " as res "`blanks'"
    if "`normalizedu'" != "" di as txt "note: labels normalized for Stata (straight quotes {c 45}> curly, backticks {c 45}> apostrophes): " as res "`normalizedu'"
    if `nlong'          di as txt "caution: " as res "`nlong'" as txt " label(s) exceed 80 characters and were truncated by Stata"

    di as txt _n "the relabel do-file:"
    di as smcl `"  {view "`dofile'":>> click to VIEW the capture-guarded relabel do-file}"'
    if `haveinv' di as smcl `"  {view "`smclout'":>> click to VIEW this inventory}"'
    di as txt "{hline 72}"

    * ------------------------------------------------------------ returns ------
    return local nolabel `"`unlabeled'"'
    return local nomatch `"`missing'"'
    return local applied `"`applied'"'
    return local dups    `"`dupsu'"'
    return local blanks  `"`blanks'"'
    return local normalized `"`normalizedu'"'
    if `haveinv' return local smcl `"`smclout'"'
    return local dofile  `"`dofile'"'
    return scalar N_normalized = `nnorm'
    return scalar N_long     = `nlong'
    return scalar N_nolabel  = `nunlab'
    return scalar N_nomatch  = `nmiss'
    return scalar N_applied  = `nappliedv'
    return scalar N_variables = `nmain'
end
