*! version 1.2  25may2026
*! convertanything: Multi-format importer and converter for Stata
*! Author: Eric A. Booth (eric.a.booth@gmail.com)
*!
*! v1.2 changes vs v1.1:
*!   • Input path now uses `syntax [using/]` — Stata strips quotes cleanly so
*!     compound-quote delimiter contamination (the silent-failure bug) is gone.
*!   • `recursive` mode now MIRRORS the source directory tree into saving/:
*!     src/2019/file.xls → saving/2019/file.dta  (was: flat dump into saving/).
*!   • New SKIP(string) option: space-separated subdir names to skip.
*!     Default: "_converted _archive" (prevents infinite recursion & archive churn).
*!   • All internal path operations use compound-quotes so paths with spaces
*!     (e.g. Google Drive's "Shared drives/Data and Research Team") are handled correctly throughout.
*!   • Sub-programs renamed with _ca_ prefix to avoid namespace collisions.

program define convertanything
    version 16

    syntax [using/] ///
    [, ///
        SAVing(string)     /// destination directory for .dta output
        RECURsive          /// recurse into subdirectories (mirrors tree into saving/)
        ALLsheets          /// import every worksheet of each Excel file
        REPLACE            /// overwrite existing .dta files
        CLEAR              /// clear memory before each import
        EXtension(string)  /// restrict to these extensions (e.g. "csv xlsx")
        VERbose            /// show per-file progress
        COMPress           /// compress every converted dataset
        CLEANnames         /// lowercase + strtoname all variable names
        DESTRing           /// destring with ignore("$,%") percent
        SKIP(string)       /// subdir names to skip (default: _converted _archive)
    ]

    * `using' is stripped of all outer quotes by syntax [using/] — always clean.
    local input `"`using'"'

    if `"`input'"' == "" {
        if "`recursive'" != "" {
            local input "."
        }
        else {
            di as error "convertanything: specify a file or directory path."
            di as error "  Example: convertanything using myfile.xlsx, replace clear"
            exit 198
        }
    }

    if `"`skip'"' == "" local skip "_converted _archive"

    * ── File vs. Directory ────────────────────────────────────────────────────
    * Check if it's a directory first (more reliable on macOS)
    capture confirm file `"`input'/."'
    if _rc == 0 {
        _ca_dir `"`input'"' "`recursive'" `"`saving'"' "`allsheets'" "`replace'" ///
            "`clear'" "`extension'" "`verbose'" "`compress'" "`cleannames'" "`destring'" ///
            `"`skip'"'
    }
    else {
        * Try file mode
        capture confirm file `"`input'"'
        if _rc == 0 {
            _ca_file `"`input'"' `"`saving'"' "`allsheets'" "`replace'" "`clear'" ///
                "`verbose'" "`compress'" "`cleannames'" "`destring'"
        }
        else {
            di as error "convertanything: path not found — `input'"
            exit 601
        }
    }
end


* ─────────────────────────────────────────────────────────────────────────────
* _ca_dir: Process a directory (optionally recursive, mirrors tree into saving/)
* args:    dir  recursive  saving  allsheets  replace  clear  filter
*          verbose  compress  cleannames  destring  skip
* ─────────────────────────────────────────────────────────────────────────────
program define _ca_dir
    args dir recursive saving allsheets replace clear filter ///
         verbose compress cleannames destring skip

    if "`verbose'" != "" di as result _n "Directory: `dir'"

    * Ensure destination exists when saving is specified
    if `"`saving'"' != "" cap mkdir `"`saving'"'

    if "`filter'" == "" local filter "csv txt xls xlsx dta tab raw"

    * ── Convert files at this level ──────────────────────────────────────────
    foreach ext in `filter' {
        local files : dir `"`dir'"' files "*.`ext'"
        foreach f of local files {
            _ca_file `"`dir'/`f'"' `"`saving'"' "`allsheets'" "`replace'" "`clear'" ///
                "`verbose'" "`compress'" "`cleannames'" "`destring'"
        }
    }

    * ── Recurse into subdirectories ─────────────────────────────────────────
    if "`recursive'" != "" {
        local subdirs : dir `"`dir'"' dirs "*"
        foreach s of local subdirs {
            if "`s'" == "." | "`s'" == ".." continue

            * Skip any name in the skip list
            local skip_this 0
            foreach skn of local skip {
                if `"`s'"' == `"`skn'"' local skip_this 1
            }
            if `skip_this' continue

            * Mirror saving/ tree: saving/subdir (or empty if no saving)
            local sub_save ""
            if `"`saving'"' != "" local sub_save `"`saving'/`s'"'

            _ca_dir `"`dir'/`s'"' "`recursive'" `"`sub_save'"' "`allsheets'" "`replace'" ///
                "`clear'" "`filter'" "`verbose'" "`compress'" "`cleannames'" "`destring'" ///
                `"`skip'"'
        }
    }
end


* ─────────────────────────────────────────────────────────────────────────────
* _ca_file: Convert a single file to .dta
* args:     file  saving  allsheets  replace  clear  verbose  compress
*           cleannames  destring
* ─────────────────────────────────────────────────────────────────────────────
program define _ca_file
    args file saving allsheets replace clear verbose compress cleannames destring

    * Parse filename components (file is a clean path from args)
    local ext      = lower(substr(`"`file'"', strrpos(`"`file'"', ".")+1, .))
    local filename = substr(`"`file'"', strrpos(`"`file'"', "/")+1, .)
    local basename = substr(`"`filename'"', 1, strrpos(`"`filename'"', ".")-1)

    if "`verbose'" != "" di as text "  -> `filename' (`ext')"

    * ── Determine output directory ───────────────────────────────────────────
    if `"`saving'"' != "" {
        local outdir `"`saving'"'
        * Ensure trailing slash
        if !inlist(substr(`"`outdir'"', -1, 1), "/", "\") ///
            local outdir `"`outdir'/"'
        cap mkdir `"`outdir'"'
    }
    else {
        * No saving specified → save next to source file
        local outdir = substr(`"`file'"', 1, strrpos(`"`file'"', "/"))
    }

    local success = 0

    * ── Excel (.xls / .xlsx) ─────────────────────────────────────────────────
    if inlist("`ext'", "xls", "xlsx") {
        if "`allsheets'" != "" {
            capture import excel using `"`file'"', describe
            if _rc == 0 {
                local n_sheets = r(N_worksheet)
                * Snapshot sheet names BEFORE any import loop resets r()
                forval i = 1/`n_sheets' {
                    local sn_`i' = r(worksheet_`i')
                }
                forval i = 1/`n_sheets' {
                    local sname     "`sn_`i''"
                    local sname_var = strtoname("`sname'")
                    if "`verbose'" != "" di as text "     sheet: `sname'"
                    capture import excel using `"`file'"', ///
                        sheet("`sname'") firstrow `clear'
                    if _rc == 0 & c(k) > 0 {
                        capture noi _ca_post "`cleannames'" "`destring'" "`compress'"
                        capture save `"`outdir'`basename'_`sname_var'.dta"', `replace'
                        if _rc == 0 local success = 1
                    }
                    else if "`verbose'" != "" di as text "       (skipped: empty or unreadable)"
                }
            }
        }
        else {
            capture import excel using `"`file'"', firstrow `clear'
            if _rc == 0 {
                _ca_post "`cleannames'" "`destring'" "`compress'"
                save `"`outdir'`basename'.dta"', `replace'
                local success = 1
            }
        }
    }

    * ── Delimited text (.csv / .txt / .tab) ──────────────────────────────────
    else if inlist("`ext'", "csv", "txt", "tab") {
        capture import delimited using `"`file'"', `clear'
        if _rc == 0 {
            _ca_post "`cleannames'" "`destring'" "`compress'"
            save `"`outdir'`basename'.dta"', `replace'
            local success = 1
        }
    }

    * ── Stata dataset (.dta) — copy to destination ───────────────────────────
    else if "`ext'" == "dta" {
        local src_dir = substr(`"`file'"', 1, strrpos(`"`file'"', "/"))
        if `"`outdir'"' != `"`src_dir'"' {
            capture use `"`file'"', `clear'
            if _rc == 0 {
                _ca_post "`cleannames'" "`destring'" "`compress'"
                save `"`outdir'`basename'.dta"', `replace'
                local success = 1
            }
        }
    }

    * ── Fixed-format / raw ───────────────────────────────────────────────────
    else if "`ext'" == "raw" {
        capture infile using `"`file'"', `clear'
        if _rc == 0 {
            _ca_post "`cleannames'" "`destring'" "`compress'"
            save `"`outdir'`basename'.dta"', `replace'
            local success = 1
        }
    }

    if `success' == 0 & "`verbose'" != "" di as error "     Failed/Skipped: `filename'"
end


* ─────────────────────────────────────────────────────────────────────────────
* _ca_post: Post-import cleanup (cleannames / destring / compress)
* ─────────────────────────────────────────────────────────────────────────────
program define _ca_post
    args cleannames destring compress

    if c(k) == 0 exit 0     // nothing in memory

    if "`cleannames'" != "" {
        foreach v of varlist _all {
            local nv = strtoname(lower("`v'"))
            if "`v'" != "`nv'" capture rename `v' `nv'
        }
    }

    if "`destring'" != "" capture destring _all, replace ignore("$,%") percent

    if "`compress'" != "" capture compress
end


* ─────────────────────────────────────────────────────────────────────────────
* Keep legacy sub-program names as aliases so any code that called
* ProcessFile / ProcessDirectory / PostProcess directly still compiles.
* ─────────────────────────────────────────────────────────────────────────────
program define ProcessFile
    _ca_file `0'
end

program define PostProcess
    _ca_post `0'
end
