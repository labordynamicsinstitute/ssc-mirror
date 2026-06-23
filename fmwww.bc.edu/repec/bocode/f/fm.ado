*! fm.ado v1.0.1 — File classification manager
*! Classifies files in a directory by their first English character
*! and organizes them into corresponding subdirectories.
*!
*! Syntax: fm [directory_path] [, REPLACE DRYrun]
*!
*! Category rules:
*!   a-z   -> a/ through z/  (case-insensitive)
*!   0-9   -> 0-9/
*!   other -> _other/
*!
*! Date:    22June2026
*!
*! Authors:
*!   Wu Lianghai
*!     School of Business, Anhui University of Technology (AHUT)
*!     Ma'anshan, Anhui, China
*!     agd2010@yeah.net
*!
*!   Chen Liwen
*!     School of Business, Anhui University of Technology (AHUT)
*!     Ma'anshan, Anhui, China
*!     2184844526@qq.com
*!
*!   Wu Hanyan
*!     School of Economics and Management, NUAA
*!     Nanjing, Jiangsu, China
*!     2325476320@qq.com

program define fm

    version 16.0

    // ============================================================
    // 1. Parse syntax
    // ============================================================
    syntax [anything(name=dirpath id="directory path")] [, REPLACE DRYrun]

    // ============================================================
    // 2. Resolve and normalize the directory path
    // ============================================================
    if `"`dirpath'"' == "" {
        local dirpath `"`c(pwd)'"'
    }

    // Convert backslashes to forward slashes
    local dirpath : subinstr local dirpath "\" "/", all

    // Strip trailing slash(es)
    while substr(`"`dirpath'"', -1, 1) == "/" {
        local dirpath = substr(`"`dirpath'"', 1, length(`"`dirpath'"') - 1)
    }

    // Resolve relative path to absolute
    if substr(`"`dirpath'"', 1, 1) != "/" & substr(`"`dirpath'"', 2, 1) != ":" {
        local dirpath `"`c(pwd)'/`dirpath'"'
    }

    // ============================================================
    // 3. Validate that the directory exists
    // ============================================================
    capture confirmdir `"`dirpath'"'
    if _rc {
        display as error `"Directory not found: `dirpath'"'
        display as error "Usage: fm [directory_path] [, replace dryrun]"
        exit 601
    }

    display as text "{hline 60}"
    display as text "Target directory: `dirpath'"

    // ============================================================
    // 4. List all files in the top level only
    // ============================================================
    local filelist : dir `"`dirpath'"' files "*"

    if `"`filelist'"' == "" {
        display as text "No files found in this directory."
        display as text "{hline 60}"
        exit
    }

    local filecount : word count `filelist'
    display as text "Files found: `filecount'"
    display as text "{hline 60}"

    // ============================================================
    // 5. Process each file
    // ============================================================
    local moved   = 0
    local skipped = 0
    local failed  = 0
    local cats    ""

    foreach file of local filelist {
        // ----------------------------------------------------
        // 5a. Classify by first character (lowercased)
        // ----------------------------------------------------
        local firstchar = lower(substr(`"`file'"', 1, 1))

        if inrange("`firstchar'", "a", "z") {
            local cat = "`firstchar'"
        }
        else if inrange("`firstchar'", "0", "9") {
            local cat = "0-9"
        }
        else {
            local cat = "_other"
        }

        // Track which categories are used
        if strpos(`"`cats'"', `" `cat' "') == 0 {
            local cats `"`cats' `cat' "'
        }

        // Build path macros
        local catdir `"`dirpath'/`cat'"'
        local src    `"`dirpath'/`file'"'
        local dst    `"`catdir'/`file'"'

        // ----------------------------------------------------
        // 5b. Dry-run: preview only
        // ----------------------------------------------------
        if "`dryrun'" == "dryrun" {
            display as text "  [DRYRUN] `file'  ->  `cat'/"
            local moved = `moved' + 1
            continue
        }

        // ----------------------------------------------------
        // 5c. Ensure category subdirectory exists
        // ----------------------------------------------------
        capture mkdir `"`catdir'"'
        // Double-check the directory now exists
        capture confirmdir `"`catdir'"'
        if _rc {
            display as error "  [FAIL] Cannot create directory: `catdir'"
            local failed = `failed' + 1
            continue
        }

        // ----------------------------------------------------
        // 5d. Check for existing file in destination
        // ----------------------------------------------------
        capture confirm file `"`dst'"'
        if !_rc & "`replace'" == "" {
            display as text "  [SKIP] `file' already exists in `cat'/"
            display as text "         (use replace to overwrite)"
            local skipped = `skipped' + 1
            continue
        }

        // ----------------------------------------------------
        // 5e. Copy file to destination
        // ----------------------------------------------------
        capture copy `"`src'"' `"`dst'"', replace
        if _rc {
            display as error "  [FAIL] Cannot copy `file' (rc=`_rc')"
            local failed = `failed' + 1
            continue
        }

        // ----------------------------------------------------
        // 5f. Erase original file
        // ----------------------------------------------------
        capture erase `"`src'"'
        if _rc {
            display as error "  [WARN] Copied but cannot erase `file' (rc=`_rc')"
            local failed = `failed' + 1
            continue
        }

        display as text "  [OK]   `file'  ->  `cat'/"
        local moved = `moved' + 1
    }

    // ============================================================
    // 6. Print summary
    // ============================================================
    display as text "{hline 60}"
    if "`dryrun'" == "dryrun" {
        display as result "DRY RUN complete."
        display as text "  `filecount' file(s) would be organized."
    }
    else {
        display as result "Organization complete."
        display as text "  Moved:   `moved'"
        if `skipped' > 0 {
            display as text "  Skipped: `skipped' (already existed, use replace to overwrite)"
        }
        if `failed' > 0 {
            display as text "  Failed:  `failed'"
        }
    }
    display as text "  Categories used:`cats'"
    display as text "{hline 60}"

end
