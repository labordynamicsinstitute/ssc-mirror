*! version 2.0.0  07jul2026  Eric A. Booth, Sr Researcher, Texas 2036
*!                           Elizabeth Teas, Sr Research Scientist, Far Harbor, LLC
*! projectbuilder -- scaffold a data-analysis project folder with a
*!                   numbered do-file pipeline, then (optionally) ingest
*!                   data, convert it, combine it, and build documentation.
*!
*! No organization-locked pieces: no shared-drive discovery, no template
*! folder, no logo fetcher.  Everything the scaffold needs is written by
*! this program with -file write-; nothing external is required.
*!
*! Cross-OS: uses only Stata's mkdir, copy, cd, and file commands;
*! no shell calls.  Companion to "Applied Program Evaluation Using Stata".
*! Support: eric.a.booth@gmail.com

program define projectbuilder, rclass
    version 16
    syntax anything(name=projspec id="source[/subsource]") [, ///
        PATH(string)         ///
        DEScription(string)  ///
        URL(string)          ///
        DATA(string)         ///
        TOPIC(string)        ///
        PUBlicfacing(string) ///
        TIMEline(string)     ///
        OTHERnotes(string)   ///
        OUTcomes(string)     ///
        OVer(string)         ///
        DESCsave             ///
        REBUILD              ///
        REPLACE              ///
        BUILDDOCS            ///
        NOAUTOconvert]

    * ---- validate publicfacing ------------------------------------------
    if !inlist(lower(`"`publicfacing'"'), "", "yes", "no", "unsure") {
        di as err `"projectbuilder: publicfacing() must be yes, no, unsure, or empty (got "`publicfacing'")"'
        exit 198
    }
    local publicfacing = lower(`"`publicfacing'"')

    * ---- cap outcomes / over at 10 each ---------------------------------
    local outcomes_trim
    local n = 0
    foreach w of local outcomes {
        local ++n
        if `n' > 10 continue
        local outcomes_trim `outcomes_trim' `w'
    }
    if `n' > 10 di as txt "projectbuilder: outcomes() had `n' items; using first 10."
    local outcomes : copy local outcomes_trim

    local over_trim
    local n = 0
    foreach w of local over {
        local ++n
        if `n' > 10 continue
        local over_trim `over_trim' `w'
    }
    if `n' > 10 di as txt "projectbuilder: over() had `n' items; using first 10."
    local over : copy local over_trim

    * ---- base path: path() overrides the current working directory ------
    local base `"`c(pwd)'"'
    if `"`path'"' != "" local base `"`path'"'
    if inlist(substr(`"`base'"', -1, 1), "/", "\") {
        local base = substr(`"`base'"', 1, strlen(`"`base'"') - 1)
    }

    * ---- reject a stray extra token -------------------------------------
    * -anything- absorbs every word after the command name, so an unquoted
    * second word would silently become part of the folder name.  A project
    * name is exactly one token; quote it if it contains spaces.
    local pbrest `"`projspec'"'
    gettoken pbfirst pbrest : pbrest
    local pbrest = strtrim(`"`pbrest'"')
    if `"`pbrest'"' != "" {
        di as err `"projectbuilder: too many project names -- "`projspec'""'
        di as err  "                Give one name (source or source/subsource);"
        di as err `"                the extra token was "`pbrest'"."'
        di as err  "                Quote the name if it contains spaces."
        exit 198
    }

    * ---- parse source[/subsource] ---------------------------------------
    local projspec = subinstr(`"`projspec'"', char(34), "", .)
    local projspec = strtrim(`"`projspec'"')
    if `"`projspec'"' == "" {
        di as err "projectbuilder: project name is empty"
        exit 198
    }
    local pos = strpos(`"`projspec'"', "/")
    if `pos' > 0 {
        local parent = substr(`"`projspec'"', 1, `pos' - 1)
        local leaf   = substr(`"`projspec'"', `pos' + 1, .)
        local proj_label = subinstr(`"`projspec'"', "/", "_", .)
    }
    else {
        local parent ""
        local leaf   `"`projspec'"'
        local proj_label `"`leaf'"'
    }

    * ---- validate names (no path tricks) --------------------------------
    if strpos(`"`projspec'"', "..") | strpos(`"`projspec'"', "\") {
        di as err `"projectbuilder: "`projspec'" is not a valid project name (no ".." or "\" allowed)"'
        exit 198
    }
    if strpos(`"`leaf'"', "/") {
        di as err `"projectbuilder: at most one level of nesting -- use source or source/subsource"'
        exit 198
    }
    if `"`leaf'"' == "" | (`pos' > 0 & `"`parent'"' == "") {
        di as err "projectbuilder: source and subsource names cannot be empty"
        exit 198
    }

    if `"`parent'"' != "" local target `"`base'/`parent'/`leaf'"'
    else                  local target `"`base'/`leaf'"'

    * ---- rebuild vs. fresh scaffold; refuse to clobber ------------------
    * A fresh call never overwrites an existing project (exit 602).
    * -rebuild- opts in to working on an existing project; it preserves
    * any do-file in _code that the user edited unless -replace- is given.
    capture confirm file `"`target'/."'
    local exists = (_rc == 0)
    if `exists' & "`rebuild'" == "" {
        di as err `"projectbuilder: target already exists -- `target'"'
        di as err  "                projectbuilder never overwrites an existing project."
        di as err  "                Rerun with -rebuild- to refresh it, or rename it and re-run."
        exit 602
    }
    * writecode=1 means (over)write the numbered do-files; on rebuild we
    * only write a code file that is missing, unless -replace- is given.
    local writecode = cond("`rebuild'" != "" & "`replace'" == "", 0, 1)

    if `exists' di as txt `"projectbuilder: rebuilding `target'"'
    else        di as txt `"projectbuilder: scaffolding `target'"'

    * ---- build the folder tree (Stata's mkdir is cross-OS) --------------
    capture mkdir `"`base'"'
    capture confirm file `"`base'/."'
    if _rc {
        di as err `"projectbuilder: base path not found and could not be created -- `base'"'
        di as err  "                Create its parent directories first, or check path()."
        exit 601
    }
    if `"`parent'"' != "" capture mkdir `"`base'/`parent'"'
    capture mkdir `"`target'"'
    foreach sub in 01_raw 02_cleaned 03_output _code _documentation _archive {
        capture mkdir `"`target'/`sub'"'
    }
    capture mkdir `"`target'/01_raw/_archive"'
    capture mkdir `"`target'/01_raw/_converted"'
    capture mkdir `"`target'/02_cleaned/_archive"'
    capture mkdir `"`target'/03_output/_archive"'
    capture mkdir `"`target'/_code/_archive"'
    capture mkdir `"`target'/_documentation/_archive"'
    capture mkdir `"`target'/_documentation/website"'

    * ---- convenient path locals -----------------------------------------
    local raw       `"`target'/01_raw"'
    local converted `"`target'/01_raw/_converted"'
    local cleaned   `"`target'/02_cleaned"'
    local output    `"`target'/03_output"'
    local code      `"`target'/_code"'
    local docs      `"`target'/_documentation"'
    local web       `"`docs'/website"'

    * ---- metadata persistence -------------------------------------------
    * A plain -rebuild- must not discard what the scaffold recorded.  The
    * metadata is stored beside the documentation and read back whenever the
    * current call does not supply a value, so refreshing a project keeps its
    * description, topic, and the rest instead of replacing them with
    * placeholders.  An option given on this call always wins.
    local metaf `"`docs'/_project_meta.txt"'
    capture confirm file `"`metaf'"'
    if _rc == 0 {
        tempname mfh
        capture file open `mfh' using `"`metaf'"', read text
        if _rc == 0 {
            file read `mfh' mline
            while r(eof) == 0 {
                if regexm(`"`macval(mline)'"', "^([a-z]+)=(.*)$") {
                    local mkey = regexs(1)
                    local mval = regexs(2)
                    foreach m in description url topic publicfacing timeline ///
                                 othernotes outcomes over created {
                        if "`mkey'" == "`m'" {
                            if `"``m''"' == "" local `m' `"`mval'"'
                        }
                    }
                }
                file read `mfh' mline
            }
            file close `mfh'
        }
    }

    * ---- values stamped into the scaffold files -------------------------
    local today : di %tdCCYY-NN-DD daily(`"`c(current_date)'"', "DMY")
    * -created- is the date the project was first scaffolded; -today- is when
    * this build ran.  They differ after a rebuild, so keep them separate.
    if `"`created'"' == "" local created `"`today'"'
    local lastbuilt `"`today'"'

    local author `"`c(username)'"'
    * The generated 000_control.do pins the language version to this package's
    * own floor rather than to the running Stata.  c(stata_version) can report
    * a release (19.5, say) that no earlier installation will accept, which
    * would make the generated file unrunnable for a teammate on Stata 16-19.
    * Raise the pin by hand if a project comes to rely on newer syntax.
    local sver "16.0"
    local descfull `"`description'"'
    if `"`descfull'"' == "" local descfull "(add a one-line description of the project here)"
    local url_show `"`url'"'
    if `"`url_show'"' == "" local url_show "(none recorded)"
    foreach m in topic publicfacing timeline othernotes {
        local `m'_show `"``m''"'
        if `"``m'_show'"' == "" local `m'_show "(not recorded)"
    }
    local gh "https://raw.githubusercontent.com/ericabooth"
    local urlbase ""
    if `"`url'"' != "" pb_base urlbase `"`url'"'

    * ---- record the metadata for the next rebuild ------------------------
    capture mkdir `"`docs'"'
    tempname mfw
    capture file open `mfw' using `"`metaf'"', write text replace
    if _rc == 0 {
        file write `mfw' "* projectbuilder metadata.  Read back on -rebuild- so a" _n
        file write `mfw' "* refresh keeps what the scaffold recorded.  Edit freely;" _n
        file write `mfw' "* one key=value per line." _n
        foreach m in description url topic publicfacing timeline othernotes ///
                     outcomes over created {
            file write `mfw' "`m'=" `"``m''"' _n
        }
        file close `mfw'
    }

    *=====================================================================*
    * WRITE THE NUMBERED PIPELINE (do-files in _code)                     *
    * Each file is guarded: on -rebuild- without -replace-, a file that   *
    * already exists (i.e., the user may have edited it) is left alone.   *
    *=====================================================================*
    tempname fh

    * ---- _code/000_control.do -------------------------------------------
    pb_guard dowrite `writecode' `"`code'/000_control.do"'
    if `dowrite' {
        quietly file open `fh' using `"`code'/000_control.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* 000_control.do -- `proj_label'"'
        pb_wl `fh' `"* Created `created' by `author' (scaffolded by projectbuilder v2.0.0)"'
        pb_wl `fh' `"* Last built `lastbuilt'"'
        pb_wl `fh' `"* The control file: every path in one place."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `""'
        pb_wl `fh' `"clear all"'
        pb_wl `fh' `"version `sver'      // projectbuilder's floor; raise if you need newer syntax"'
        pb_wl `fh' `"set more off"'
        pb_wl `fh' `"set varabbrev off    // abbreviations hide bugs"'
        pb_wl `fh' `""'
        pb_wl `fh' `"*---------------------------------------------------------------"'
        pb_wl `fh' `"* >>> THE ONE PLACE YOU EDIT: the project root. <<<"'
        pb_wl `fh' `"* projectbuilder stamped the absolute path it scaffolded below."'
        pb_wl `fh' `"* If this project ever MOVES -- new machine, new teammate, new"'
        pb_wl `fh' `"* drive -- edit ONLY the global root line, then rerun this file."'
        pb_wl `fh' `"*---------------------------------------------------------------"'
        pb_wl `fh' `"global root "`target'""'
        pb_wl `fh' `""'
        pb_wl `fh' `"* Derived from root; you should not need to touch these."'
        pb_wl `fh' `"global raw       "~Droot/01_raw"            // untouched source files"'
        pb_wl `fh' `"global converted "~Droot/01_raw/_converted" // raw -> .dta, one per file"'
        pb_wl `fh' `"global cleaned   "~Droot/02_cleaned"        // the analytic file(s)"'
        pb_wl `fh' `"global output    "~Droot/03_output"         // logs, tables, exhibits"'
        pb_wl `fh' `"global code      "~Droot/_code"             // the do-files"'
        pb_wl `fh' `"global docs      "~Droot/_documentation"    // the documentation site"'
        pb_wl `fh' `"foreach d in raw converted cleaned output code docs {"'
        pb_wl `fh' `"    capture mkdir "~D{~Bd'}"     // safe to rerun"'
        pb_wl `fh' `"}"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* set scheme stcolor    // uncomment to pin one graphics style"'
        pb_wl `fh' `""'
        pb_wl `fh' `"*---------------------------------------------------------------"'
        pb_wl `fh' `"* Optional: run the whole numbered pipeline, in order."'
        pb_wl `fh' `"*---------------------------------------------------------------"'
        pb_wl `fh' `"local run_all 0    // flip to 1 to run every numbered step"'
        pb_wl `fh' `"if ~Brun_all' {"'
        pb_wl `fh' `"    do "~Dcode/100_data_download.do""'
        pb_wl `fh' `"    do "~Dcode/200_data_management.do""'
        pb_wl `fh' `"    do "~Dcode/300_labels.do""'
        pb_wl `fh' `"    do "~Dcode/400_data_profiler.do""'
        pb_wl `fh' `"    do "~Dcode/500_aggregation.do""'
        pb_wl `fh' `"    do "~Dcode/600_analysis.do""'
        pb_wl `fh' `"}"'
        file close `fh'
    }

    * ---- _code/100_data_download.do -------------------------------------
    pb_guard dowrite `writecode' `"`code'/100_data_download.do"'
    if `dowrite' {
        quietly file open `fh' using `"`code'/100_data_download.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* 100_data_download.do -- `proj_label'"'
        pb_wl `fh' `"* Single job: get the raw source files into ~Draw."'
        pb_wl `fh' `"* Raw files are write-once: downloaded/copied, never edited by hand."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* Globals come from 000_control.do -- run that first."'
        pb_wl `fh' `""'
        if `"`url'"' != "" {
            pb_wl `fh' `"* Source URL recorded from the url() option:"'
            pb_wl `fh' `"*   `url'"'
            pb_wl `fh' `"* Fetch it with Stata's -copy- (works for http/https URLs):"'
            pb_wl `fh' `"capture copy "`url'" "~Draw/`urlbase'", replace"'
            pb_wl `fh' `"if _rc di as txt "100: could not fetch the URL; check the address or drop the file into ~Draw by hand.""'
        }
        else {
            pb_wl `fh' `"* No source URL was recorded at scaffold time."'
            pb_wl `fh' `"* If the source lives at a URL, note it here and fetch with -copy-:"'
            pb_wl `fh' `"* copy "https://example.com/data.csv" "~Draw/data.csv", replace"'
            pb_wl `fh' `"* If the files arrive by hand (email, thumb drive, shared folder),"'
            pb_wl `fh' `"* drop them into ~Draw and record who sent them, and when, below."'
        }
        pb_wl `fh' `""'
        pb_wl `fh' `"* Provenance notes (who/where/when the raw files came from):"'
        pb_wl `fh' `"*   `othernotes_show'"'
        file close `fh'
    }

    * ---- _code/200_data_management.do -----------------------------------
    pb_guard dowrite `writecode' `"`code'/200_data_management.do"'
    if `dowrite' {
        quietly file open `fh' using `"`code'/200_data_management.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* 200_data_management.do -- `proj_label'"'
        pb_wl `fh' `"* Single job: turn the raw drop in ~Draw into ONE analytic file"'
        pb_wl `fh' `"* in ~Dcleaned, in two passes:"'
        pb_wl `fh' `"*   Pass 1  convertanything : every csv/xlsx/dta in ~Draw -> .dta"'
        pb_wl `fh' `"*                             in ~Dconverted (names cleaned)."'
        pb_wl `fh' `"*   Pass 2  combineall      : append those .dta into the analytic file."'
        pb_wl `fh' `"* projectbuilder runs both passes for you at scaffold/rebuild time"'
        pb_wl `fh' `"* when the packages are installed; this file is the reproducible"'
        pb_wl `fh' `"* record of what it ran (and a teaching artifact if they are not)."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* Globals come from 000_control.do -- run that first."'
        pb_wl `fh' `""'
        pb_wl `fh' `"* --- Pass 1: convert every raw file to .dta -----------------------"'
        pb_wl `fh' `"capture which convertanything"'
        pb_wl `fh' `"if _rc {"'
        pb_wl `fh' `"    di as txt "convertanything not installed. Install it with:""'
        pb_wl `fh' `"    di as txt `"    net install convertanything, from("`gh'/convertanything-stata-public/main/") replace"'"'
        pb_wl `fh' `"}"'
        pb_wl `fh' `"else {"'
        pb_wl `fh' `"    convertanything using "~Draw", recursive ///"'
        pb_wl `fh' `"        saving("~Dconverted") replace clear cleannames compress"'
        pb_wl `fh' `"}"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* --- Pass 2: append the converted files into the analytic file ----"'
        pb_wl `fh' `"capture which combineall"'
        pb_wl `fh' `"if _rc {"'
        pb_wl `fh' `"    di as txt "combineall not installed. Install it with:""'
        pb_wl `fh' `"    di as txt `"    net install combineall, from("`gh'/combineall-stata-public/main/") replace"'"'
        pb_wl `fh' `"}"'
        pb_wl `fh' `"else {"'
        pb_wl `fh' `"    capture noisily combineall using "~Dcleaned/`proj_label'_analytic", ///"'
        pb_wl `fh' `"        cmethod(append) directory("~Dconverted") filetype(dta) replace"'
        pb_wl `fh' `"    if _rc di as txt "combineall found nothing to append; run Pass 1 first.""'
        pb_wl `fh' `"}"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* From here, load the analytic file and reshape/merge as the project needs:"'
        pb_wl `fh' `"* use "~Dcleaned/`proj_label'_analytic.dta", clear"'
        file close `fh'
    }

    * ---- _code/300_labels.do --------------------------------------------
    pb_guard dowrite `writecode' `"`code'/300_labels.do"'
    if `dowrite' {
        quietly file open `fh' using `"`code'/300_labels.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* 300_labels.do -- `proj_label'"'
        pb_wl `fh' `"* Single job: variable/value labels and provenance on the analytic"'
        pb_wl `fh' `"* file, plus (optionally) a codebook export for the documentation."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* Globals come from 000_control.do -- run that first."'
        pb_wl `fh' `""'
        pb_wl `fh' `"use "~Dcleaned/`proj_label'_analytic.dta", clear"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* label variable somevar "Human-readable label""'
        pb_wl `fh' `"* label define yesno 0 "No" 1 "Yes""'
        pb_wl `fh' `"* label values flagvar yesno"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* --- Source lineage: tag each variable with the raw file it came"'
        pb_wl `fh' `"* from, then make that lineage searchable (author's -srctag-/-srcfind-)."'
        pb_wl `fh' `"capture which srctag"'
        pb_wl `fh' `"if _rc {"'
        pb_wl `fh' `"    di as txt "srctag/srcfind not installed (author's GitHub); skipping lineage tags.""'
        pb_wl `fh' `"}"'
        pb_wl `fh' `"else {"'
        pb_wl `fh' `"    * srctag, source("~Draw") // record which raw file/vintage each var came from"'
        pb_wl `fh' `"    * srcfind somevar         // later: search a variable's source lineage"'
        pb_wl `fh' `"}"'
        if "`descsave'" != "" {
            pb_wl `fh' `""'
            pb_wl `fh' `"* --- Codebook export via -descsave- (SSC: ssc install descsave) ----"'
            pb_wl `fh' `"capture which descsave"'
            pb_wl `fh' `"if _rc {"'
            pb_wl `fh' `"    di as txt "descsave not installed. Install it with:  ssc install descsave""'
            pb_wl `fh' `"}"'
            pb_wl `fh' `"else {"'
            pb_wl `fh' `"    descsave using "~Ddocs/`proj_label'_codebook.xlsx", ///"'
            pb_wl `fh' `"        list(name type format varlab vallab) replace"'
            pb_wl `fh' `"}"'
        }
        pb_wl `fh' `""'
        pb_wl `fh' `"compress"'
        pb_wl `fh' `"save "~Dcleaned/`proj_label'_analytic.dta", replace"'
        file close `fh'
    }

    * ---- _code/400_data_profiler.do -------------------------------------
    pb_guard dowrite `writecode' `"`code'/400_data_profiler.do"'
    if `dowrite' {
        quietly file open `fh' using `"`code'/400_data_profiler.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* 400_data_profiler.do -- `proj_label'"'
        pb_wl `fh' `"* Single job: profile the analytic file -- distributions of the"'
        pb_wl `fh' `"* outcome variables, optionally broken down by the -over- variables."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* Globals come from 000_control.do -- run that first."'
        pb_wl `fh' `""'
        pb_wl `fh' `"use "~Dcleaned/`proj_label'_analytic.dta", clear"'
        pb_wl `fh' `""'
        pb_wl `fh' `"local outcomes "`outcomes'"   // recorded from outcomes(); edit freely"'
        pb_wl `fh' `"local over     "`over'"   // recorded from over(); edit freely"'
        pb_wl `fh' `""'
        pb_wl `fh' `"foreach y of local outcomes {"'
        pb_wl `fh' `"    capture confirm variable ~By'"'
        pb_wl `fh' `"    if _rc continue          // silently skip vars not in this file"'
        pb_wl `fh' `"    summarize ~By', detail"'
        pb_wl `fh' `"    foreach g of local over {"'
        pb_wl `fh' `"        capture confirm variable ~Bg'"'
        pb_wl `fh' `"        if _rc continue"'
        pb_wl `fh' `"        table ~Bg', statistic(mean ~By') statistic(count ~By')"'
        pb_wl `fh' `"    }"'
        pb_wl `fh' `"}"'
        file close `fh'
    }

    * ---- _code/500_aggregation.do ---------------------------------------
    pb_guard dowrite `writecode' `"`code'/500_aggregation.do"'
    if `dowrite' {
        quietly file open `fh' using `"`code'/500_aggregation.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* 500_aggregation.do -- `proj_label'"'
        pb_wl `fh' `"* Single job: build the aggregated/collapsed tables the analysis"'
        pb_wl `fh' `"* needs (e.g., one row per unit-period), written to ~Dcleaned."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* Globals come from 000_control.do -- run that first."'
        pb_wl `fh' `""'
        pb_wl `fh' `"use "~Dcleaned/`proj_label'_analytic.dta", clear"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* Typical shape of this step:"'
        pb_wl `fh' `"* collapse (mean) `outcomes', by(`over')"'
        pb_wl `fh' `"* save "~Dcleaned/`proj_label'_agg.dta", replace"'
        file close `fh'
    }

    * ---- _code/600_analysis.do ------------------------------------------
    pb_guard dowrite `writecode' `"`code'/600_analysis.do"'
    if `dowrite' {
        quietly file open `fh' using `"`code'/600_analysis.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* 600_analysis.do -- `proj_label'"'
        pb_wl `fh' `"* Single job: the analysis itself -- models, estimates, and the"'
        pb_wl `fh' `"* tables/figures for the deliverable, written to ~Doutput."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* Globals come from 000_control.do -- run that first."'
        pb_wl `fh' `""'
        pb_wl `fh' `"use "~Dcleaned/`proj_label'_analytic.dta", clear"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* Suggested per-run log (dated, so runs never overwrite):"'
        pb_wl `fh' `"* log using "~Doutput/600_analysis_~DS_DATE.log", replace text"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* ... regress / logit / margins / graph / collect export ..."'
        pb_wl `fh' `"* graph export "~Doutput/fig01.png", replace width(2400)"'
        pb_wl `fh' `""'
        pb_wl `fh' `"* capture log close"'
        file close `fh'
    }

    *=====================================================================*
    * DOCUMENTATION SOURCES (index.do, _runall.do)                        *
    * Guarded like code: these are do-files the user may customize.       *
    *=====================================================================*

    * ---- _documentation/index.do ----------------------------------------
    pb_guard dowrite `writecode' `"`docs'/index.do"'
    if `dowrite' {
        quietly file open `fh' using `"`docs'/index.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* index.do -- documentation source for `proj_label'"'
        pb_wl `fh' `"* Rendered to website/index.html by _runall.do (needs webdoc2)."'
        pb_wl `fh' `"* If webdoc2 is absent, projectbuilder writes a plain index.html"'
        pb_wl `fh' `"* directly, so the documentation always exists."'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `""'
        pb_wl `fh' `"* Build it with:  webdoc2 "index.do"   (see _runall.do)"'
        pb_wl `fh' `"* Content subcommands: wdinit, wputh1, wput (edit freely)."'
        pb_wl `fh' `""'
        pb_wl `fh' `"wdinit index, replace"'
        pb_wl `fh' `"wputh1 `proj_label'"'
        pb_wl `fh' `"wput `descfull'"'
        pb_wl `fh' `"wput <b>Source URL:</b> `url_show'"'
        pb_wl `fh' `"wput <b>Topic:</b> `topic_show'"'
        pb_wl `fh' `"wput <b>Public-facing:</b> `publicfacing_show'"'
        pb_wl `fh' `"wput <b>Refresh timeline:</b> `timeline_show'"'
        pb_wl `fh' `"wput <b>Other notes:</b> `othernotes_show'"'
        file close `fh'
    }

    * ---- _documentation/_runall.do --------------------------------------
    pb_guard dowrite `writecode' `"`docs'/_runall.do"'
    if `dowrite' {
        quietly file open `fh' using `"`docs'/_runall.do"', write text replace
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* _runall.do -- build website/index.html for `proj_label'"'
        pb_wl `fh' `"*==============================================================="'
        pb_wl `fh' `"* Prettier docs use webdoc2 (author's GitHub; needs -ssc install webdoc-)."'
        pb_wl `fh' `"* projectbuilder always writes website/index.html directly as a"'
        pb_wl `fh' `"* fallback; this renders the webdoc2 version when it is available."'
        pb_wl `fh' `"capture which webdoc2"'
        pb_wl `fh' `"if _rc {"'
        pb_wl `fh' `"    di as txt "webdoc2 not installed; using the built-in website/index.html.""'
        pb_wl `fh' `"    di as txt "  ssc install webdoc""'
        pb_wl `fh' `"    di as txt `"  net install webdoc2, from("`gh'/webdoc2-stata-public/main/") replace"'"'
        pb_wl `fh' `"}"'
        pb_wl `fh' `"else {"'
        pb_wl `fh' `"    * cd so webdoc2 finds index.do and writes index.html beside it"'
        pb_wl `fh' `"    cd "~Ddocs""'
        pb_wl `fh' `"    capture noisily webdoc2 "index.do""'
        pb_wl `fh' `"    if _rc di as txt "webdoc2 render skipped; the built-in website/index.html remains.""'
        pb_wl `fh' `"}"'
        file close `fh'
    }

    *=====================================================================*
    * METHOD A: INGEST DATA NOW  (data() and/or url())                    *
    *=====================================================================*
    if `"`data'"' != "" {
        local dsrc `"`data'"'
        if inlist(substr(`"`dsrc'"', -1, 1), "/", "\") {
            local dsrc = substr(`"`dsrc'"', 1, strlen(`"`dsrc'"') - 1)
        }
        capture confirm file `"`dsrc'/."'
        if !_rc {
            * a directory: copy every (non-hidden) file into 01_raw/
            local dfiles : dir `"`dsrc'"' files "*"
            local ncopy = 0
            foreach f of local dfiles {
                if substr(`"`f'"', 1, 1) == "." continue
                capture copy `"`dsrc'/`f'"' `"`raw'/`f'"', replace
                if !_rc local ++ncopy
            }
            di as txt `"projectbuilder: copied `ncopy' file(s) from `dsrc' into 01_raw/"'
        }
        else {
            capture confirm file `"`dsrc'"'
            if !_rc {
                pb_base bn `"`dsrc'"'
                copy `"`dsrc'"' `"`raw'/`bn'"', replace
                di as txt `"projectbuilder: copied 1 file into 01_raw/ (`bn')"'
            }
            else {
                di as txt `"projectbuilder: data("`data'") not found; nothing copied into 01_raw/."'
            }
        }
    }
    if `"`url'"' != "" {
        local ubn `"`urlbase'"'
        capture copy `"`url'"' `"`raw'/`ubn'"', replace
        if !_rc di as txt `"projectbuilder: fetched `url' into 01_raw/ (`ubn')"'
        else    di as txt `"projectbuilder: url() not reachable now; the fetch is written into 100_data_download.do to run later."'
    }

    * ---- count raw files -------------------------------------------------
    pb_count nraw `"`raw'"' "*"

    *=====================================================================*
    * AUTO-PASS: convertanything -> combineall over 01_raw/               *
    * (projectbuilder's own run; the do-file holds the reproducible copy) *
    *=====================================================================*
    if `nraw' > 0 & "`noautoconvert'" == "" {
        capture which convertanything
        if _rc {
            di as txt "projectbuilder: convertanything not installed; skipping auto-convert."
            di as txt `"                install: net install convertanything, from("`gh'/convertanything-stata-public/main/") replace"'
        }
        else {
            di as txt "projectbuilder: converting 01_raw/ -> 01_raw/_converted/ ..."
            capture noisily convertanything using `"`raw'"', recursive ///
                saving(`"`converted'"') replace clear cleannames compress
        }
        * combine only if there is something converted to combine
        pb_count nconverted `"`converted'"' "*.dta"
        if `nconverted' > 0 {
            capture which combineall
            if _rc {
                di as txt "projectbuilder: combineall not installed; skipping auto-combine."
                di as txt `"                install: net install combineall, from("`gh'/combineall-stata-public/main/") replace"'
            }
            else {
                di as txt "projectbuilder: appending converted files -> 02_cleaned/`proj_label'_analytic.dta ..."
                capture noisily combineall using "`cleaned'/`proj_label'_analytic", ///
                    cmethod(append) directory("`converted'") filetype(dta) replace
            }
        }
        else {
            di as txt "projectbuilder: nothing converted yet; skipping auto-combine."
            di as txt "                (install convertanything, or add .dta files to 01_raw/_converted/)."
        }
    }
    else if `nraw' == 0 {
        di as txt "projectbuilder: 01_raw/ is empty -- scaffold only (Method B)."
    }

    * ---- count converted files ------------------------------------------
    pb_count nconverted `"`converted'"' "*.dta"

    *=====================================================================*
    * DOCUMENTATION OUTPUT: always build website/index.html + Readme.md   *
    * webdoc2 (via builddocs) only makes it prettier.                     *
    *=====================================================================*
    local built_stamp `"`today' `c(current_time)'"'

    pb_docs `"`web'/index.html"' `"`docs'/Readme.md"' `"`raw'"' `"`converted'"' `"`cleaned'"' ///
        , project(`"`proj_label'"') date(`"`created'"') author(`"`author'"') ///
          desc(`"`descfull'"') url(`"`url_show'"') topic(`"`topic_show'"') ///
          public(`"`publicfacing_show'"') timeline(`"`timeline_show'"') ///
          othernotes(`"`othernotes_show'"') stamp(`"`built_stamp'"')

    if "`builddocs'" != "" {
        capture which webdoc2
        if _rc {
            di as txt "projectbuilder: webdoc2 not installed; used the built-in HTML fallback."
            di as txt "                install: ssc install webdoc"
            di as txt `"                         net install webdoc2, from("`gh'/webdoc2-stata-public/main/") replace"'
        }
        else {
            di as txt "projectbuilder: rendering documentation with webdoc2 ..."
            * _runall.do cd's into _documentation; save and restore the cwd.
            local pb_pwd `"`c(pwd)'"'
            capture noisily do `"`docs'/_runall.do"'
            quietly cd `"`pb_pwd'"'
        }
    }

    *=====================================================================*
    * SUMMARY + NEXT STEPS                                                *
    *=====================================================================*
    di as txt _n "{hline 66}"
    di as txt "projectbuilder OK  (v2.0.0)"
    di as txt `"  Project       : `proj_label'"'
    di as txt `"  Location      : `target'"'
    di as txt `"  Description   : `descfull'"'
    di as txt `"  Source URL    : `url_show'"'
    di as txt `"  Raw files     : `nraw'"'
    di as txt `"  Converted     : `nconverted'"'
    di as txt `"  Outcomes      : `outcomes'"'
    di as txt `"  Over          : `over'"'
    di as txt `"  Descsave      : `=cond("`descsave'" != "", "yes", "no")'"'
    di as txt `"  Topic         : `topic_show'"'
    di as txt `"  Public-facing : `publicfacing_show'"'
    di as txt `"  Timeline      : `timeline_show'"'
    di as txt `"  Mode          : `=cond(`exists', "rebuild", "fresh scaffold")'"'
    di as txt "{hline 66}"
    di as txt _n "Next steps:"
    if `nraw' == 0 {
        di as txt  "  1. Put the raw source files in 01_raw/ (or edit"
        di as txt  "     _code/100_data_download.do to fetch them by URL)."
        di as txt `"  2. Rerun:  projectbuilder `projspec', rebuild"'
        di as txt  "     -- this converts, combines, and rebuilds the docs."
        di as txt `"  3. do "`code'/000_control.do"   then work down 100..600."'
    }
    else {
        di as txt `"  1. do "`code'/000_control.do"    (sets the path globals)"'
        di as txt  "  2. Review 02_cleaned/`proj_label'_analytic.dta, then work down"
        di as txt  "     the pipeline: 300_labels -> 400_data_profiler ->"
        di as txt  "     500_aggregation -> 600_analysis."
        di as txt  "  3. Every data refresh is just another:"
        di as txt `"       projectbuilder `projspec', rebuild"'
    }
    di as txt `"  Docs: `web'/index.html"'

    * ---- stored results --------------------------------------------------
    return local project     `"`proj_label'"'
    return local path        `"`target'"'
    return scalar nraw       = `nraw'
    return scalar nconverted = `nconverted'
    return scalar rebuilt    = cond(`exists', 1, 0)
end


*=====================================================================*
* HELPERS                                                             *
*=====================================================================*

* --- pb_wl: write one line, turning ~D into a literal $ and ~B into a
*     literal backtick.  The line is written as a string EXPRESSION, so the
*     substituted characters are never re-parsed by the macro processor --
*     which lets a self-contained ado emit files full of $globals and
*     `locals' without any template folder or -filefilter-.
program define pb_wl
    gettoken fh 0 : 0
    file write `fh' (subinstr(subinstr(`0', "~D", char(36), .), "~B", char(96), .)) _n
end

* --- pb_guard: set the caller's local `flag' to 1 if the code file should
*     be (over)written -- i.e., writecode==1, or the file does not yet exist.
program define pb_guard
    gettoken flag 0 : 0
    gettoken wc   0 : 0
    gettoken f    0 : 0
    local go = `wc'
    capture confirm file `"`f'"'
    if _rc local go = 1
    c_local `flag' `go'
end

* --- pb_base: set the caller's local `retname' to the basename (last path
*     segment) of a path/URL.  Strips any trailing ? query.  Falls back to
*     download.dat.
program define pb_base
    gettoken retname 0 : 0
    gettoken p 0 : 0
    local q = strpos(`"`p'"', "?")
    if `q' > 0 local p = substr(`"`p'"', 1, `q' - 1)
    local s = max(strrpos(`"`p'"', "/"), strrpos(`"`p'"', "\"))
    if `s' > 0 local p = substr(`"`p'"', `s' + 1, .)
    if `"`p'"' == "" local p "download.dat"
    c_local `retname' `"`p'"'
end

* --- pb_count: set the caller's local `retname' to the count of non-hidden
*     files matching a pattern in a directory.
program define pb_count
    gettoken retname 0 : 0
    gettoken dir 0 : 0
    gettoken pat 0 : 0
    local list : dir `"`dir'"' files `"`pat'"'
    local k = 0
    foreach f of local list {
        if substr(`"`f'"', 1, 1) == "." continue
        local ++k
    }
    c_local `retname' `k'
end

* --- pb_docs: write the fallback website/index.html and _documentation/
*     Readme.md, stamped with metadata and a listing of what is in 01_raw/,
*     01_raw/_converted/, and 02_cleaned/.  Always run, so docs always exist.
program define pb_docs
    gettoken html   0 : 0
    gettoken readme 0 : 0
    gettoken rawd   0 : 0
    gettoken convd  0 : 0
    gettoken cleand 0 : 0
    syntax [, project(string) date(string) author(string) desc(string) ///
        url(string) topic(string) public(string) timeline(string) ///
        othernotes(string) stamp(string) ]

    * ---- escape the recorded metadata -----------------------------------
    * The metadata is free text, so topic("a&b <tag>") has to appear as
    * itself rather than as markup.  &, <, and > become HTML entities for
    * both outputs; the Markdown table additionally needs | escaped, or a
    * value could open an extra column.
    foreach m in project date author desc url topic public timeline ///
                 othernotes stamp {
        local `m' = subinstr(`"``m''"', "&", "&amp;", .)
        local `m' = subinstr(`"``m''"', "<", "&lt;",  .)
        local `m' = subinstr(`"``m''"', ">", "&gt;",  .)
        local md_`m' = subinstr(`"``m''"', "|", "\|", .)
    }

    tempname fh

    * ---- website/index.html ---------------------------------------------
    quietly file open `fh' using `"`html'"', write text replace
    file write `fh' "<!doctype html>" _n
    file write `fh' `"<html lang="en"><head><meta charset="utf-8">"' _n
    file write `fh' `"<meta name="viewport" content="width=device-width, initial-scale=1">"' _n
    file write `fh' `"<title>`project' -- project documentation</title>"' _n
    file write `fh' "<style>" _n
    file write `fh' "body{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;" _n
    file write `fh' "max-width:820px;margin:2rem auto;padding:0 1rem;line-height:1.5;color:#1a1a1a}" _n
    file write `fh' "h1{margin-bottom:.2rem} table{border-collapse:collapse;margin:1rem 0}" _n
    file write `fh' "th,td{text-align:left;padding:.3rem .8rem;border-bottom:1px solid #ddd;vertical-align:top}" _n
    file write `fh' "code{background:#f4f4f4;padding:.1rem .3rem;border-radius:3px}" _n
    file write `fh' ".muted{color:#666;font-size:.9rem}</style></head><body>" _n
    file write `fh' `"<h1>`project'</h1>"' _n
    file write `fh' `"<p>`desc'</p>"' _n
    file write `fh' "<table>" _n
    file write `fh' `"<tr><th>Created</th><td>`date'</td></tr>"' _n
    file write `fh' `"<tr><th>Author</th><td>`author'</td></tr>"' _n
    file write `fh' `"<tr><th>Source URL</th><td>`url'</td></tr>"' _n
    file write `fh' `"<tr><th>Topic</th><td>`topic'</td></tr>"' _n
    file write `fh' `"<tr><th>Public-facing</th><td>`public'</td></tr>"' _n
    file write `fh' `"<tr><th>Refresh timeline</th><td>`timeline'</td></tr>"' _n
    file write `fh' `"<tr><th>Other notes</th><td>`othernotes'</td></tr>"' _n
    file write `fh' "</table>" _n
    pb_htmllist `fh' `"`rawd'"'   "*"      "Raw files (01_raw/)"
    pb_htmllist `fh' `"`convd'"'  "*.dta"  "Converted files (01_raw/_converted/)"
    pb_htmllist `fh' `"`cleand'"' "*.dta"  "Analytic files (02_cleaned/)"
    file write `fh' `"<p class="muted">Built `stamp' by projectbuilder v2.0.0."' _n
    file write `fh' " Install webdoc2 for a richer rendering.</p>" _n
    file write `fh' "</body></html>" _n
    file close `fh'

    * ---- _documentation/Readme.md ---------------------------------------
    quietly file open `fh' using `"`readme'"', write text replace
    file write `fh' `"# `md_project'"' _n _n
    file write `fh' `"`md_desc'"' _n _n
    file write `fh' "| Field | Value |" _n
    file write `fh' "|-------|-------|" _n
    file write `fh' `"| Created | `md_date' |"' _n
    file write `fh' `"| Author | `md_author' |"' _n
    file write `fh' `"| Source URL | `md_url' |"' _n
    file write `fh' `"| Topic | `md_topic' |"' _n
    file write `fh' `"| Public-facing | `md_public' |"' _n
    file write `fh' `"| Refresh timeline | `md_timeline' |"' _n
    file write `fh' `"| Other notes | `md_othernotes' |"' _n
    file write `fh' _n
    pb_mdlist `fh' `"`rawd'"'   "*"     "Raw files (01_raw/)"
    pb_mdlist `fh' `"`convd'"'  "*.dta" "Converted files (01_raw/_converted/)"
    pb_mdlist `fh' `"`cleand'"' "*.dta" "Analytic files (02_cleaned/)"
    file write `fh' _n `"_Built `md_stamp' by projectbuilder v2.0.0._"' _n
    file close `fh'
end

program define pb_htmllist
    gettoken fh  0 : 0
    gettoken dir 0 : 0
    gettoken pat 0 : 0
    gettoken hdr 0 : 0
    file write `fh' `"<h3>`hdr'</h3>"' _n
    local list : dir `"`dir'"' files `"`pat'"'
    local any = 0
    file write `fh' "<ul>" _n
    foreach f of local list {
        if substr(`"`f'"', 1, 1) == "." continue
        local fe = subinstr(`"`f'"',  "&", "&amp;", .)
        local fe = subinstr(`"`fe'"', "<", "&lt;",  .)
        local fe = subinstr(`"`fe'"', ">", "&gt;",  .)
        file write `fh' `"<li><code>`fe'</code></li>"' _n
        local any = 1
    }
    if !`any' file write `fh' "<li class=""muted"">(none yet)</li>" _n
    file write `fh' "</ul>" _n
end

program define pb_mdlist
    gettoken fh  0 : 0
    gettoken dir 0 : 0
    gettoken pat 0 : 0
    gettoken hdr 0 : 0
    file write `fh' `"## `hdr'"' _n _n
    local list : dir `"`dir'"' files `"`pat'"'
    local any = 0
    foreach f of local list {
        if substr(`"`f'"', 1, 1) == "." continue
        local fe = subinstr(`"`f'"',  "&", "&amp;", .)
        local fe = subinstr(`"`fe'"', "<", "&lt;",  .)
        local fe = subinstr(`"`fe'"', ">", "&gt;",  .)
        local fe = subinstr(`"`fe'"', "|", "\|",    .)
        file write `fh' `"- `fe'"' _n
        local any = 1
    }
    if !`any' file write `fh' "- (none yet)" _n
    file write `fh' _n
end
