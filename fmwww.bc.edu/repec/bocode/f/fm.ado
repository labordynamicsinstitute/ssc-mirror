*! fm.ado v1.3.0 — File manager
*! Classifies files in a directory by their first English character
*! and organizes them into corresponding subdirectories.
*! Also supports flattening — moving all files from subdirectories
*! back to the current directory.
*!
*! Syntax:
*!   fm [directory_path] [, REPLACE DRYrun]
*!   fm [directory_path] , FLATTEN [REPLACE DRYrun]
*!
*! Category rules (default mode):
*!   a-z   -> a/ through z/  (case-insensitive)
*!   0-9   -> 0-9/
*!   other -> _other/
*!
*! Flatten mode:
*!   Recursively moves all files from subdirectories into the
*!   target directory. Name collisions are skipped unless REPLACE.
*!
*! Date:    13July2026
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
    syntax [anything(name=dirpath id="directory path")] [, REPLACE DRYrun FLATTEN]

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
        display as error "Usage: fm [directory_path] [, replace dryrun flatten]"
        exit 601
    }

    display as text "{hline 60}"
    display as text "Target directory: `dirpath'"

    // ============================================================
    // 4. Branch: flatten mode vs. classify mode
    // ============================================================
    if "`flatten'" == "flatten" {
        // ========================================================
        // FLATTEN MODE — move all files from subdirs to root
        // ========================================================
        display as text "Mode: flatten (subdirectories -> current folder)"

        // ----------------------------------------------------
        // 4a. Recursively list all files using OS command.
        //     Output is one file per line — handles filenames
        //     with spaces correctly, unlike Stata's dir macro
        //     which splits on spaces.
        // ----------------------------------------------------
        tempname fh
        tempfile flist

        // Try primary listing methods in order:
        //   Platform-native command first, then cross-platform fallback.
        // This ensures filenames with spaces and special characters
        // are preserved correctly regardless of the underlying shell.
        // (Windows find.exe is a string-search tool, not Unix find,
        // so we must try dir first on Windows.)

        if c(os) == "Windows" {
            // Primary: Windows dir command (works in cmd.exe)
            local windir : subinstr local dirpath "/" "\", all
            capture shell dir /s /b /a:-d `"`windir'"' > `"`flist'"' 2>nul
            // If dir failed, fall back to find (Git Bash / WSL)
            capture file open `fh' using `"`flist'"', read
            if _rc {
                capture shell find `"`dirpath'"' -type f > `"`flist'"' 2>/dev/null
            }
            else {
                file read `fh' line
                if r(eof) {
                    file close `fh'
                    capture shell find `"`dirpath'"' -type f > `"`flist'"' 2>/dev/null
                }
                else {
                    file close `fh'
                }
            }
        }
        else {
            // macOS / Linux / Unix: find is standard
            capture shell find `"`dirpath'"' -type f > `"`flist'"' 2>/dev/null
        }

        // ----------------------------------------------------
        // 4b. Read the file list and store relative paths.
        //     Use numbered macros (file_1, file_2, ...) instead
        //     of a space-separated list to preserve spaces.
        // ----------------------------------------------------
        local filecount = 0
        capture file open `fh' using `"`flist'"', read
        if _rc {
            // Shell-produced listing is empty or missing;
            // fall back to manual recursive collection below.
        }
        else {
            file read `fh' line
            while r(eof) == 0 {
                local fullpath = strtrim(`"`line'"')

                // Normalize backslashes to forward slashes
                local fullpath : subinstr local fullpath "\" "/", all

                // Strip dirpath prefix to get relative path
                local prefix_len = length(`"`dirpath'"') + 1
                local relpath = substr(`"`fullpath'"', `prefix_len' + 1, .)

                // Only collect files inside subdirectories
                if strpos(`"`relpath'"', "/") > 0 {
                    local filecount = `filecount' + 1
                    local file_`filecount' `"`relpath'"'
                }

                file read `fh' line
            }
            file close `fh'
        }

        // ----------------------------------------------------
        // 4c. Fallback: if shell listing produced nothing,
        //     use manual recursive walk with local macros.
        //     This preserves backward compatibility on systems
        //     where shell commands are restricted.
        // ----------------------------------------------------
        if `filecount' == 0 {
            display as text "(Shell listing unavailable; using built-in fallback)"
            // Manual BFS recursive collection.
            // We store full paths in numbered macros to avoid
            // Stata's space-splitting issue with foreach.
            local q_head = 1
            local q_tail = 1
            local q_1    `"`dirpath'"'

            while `q_head' <= `q_tail' {
                local curdir `"`q_`q_head''"'
                local q_head = `q_head' + 1

                // Only collect from subdirectories (not root)
                if `"`curdir'"' != `"`dirpath'"' {
                    // Use file open/read with shell listing for
                    // this single directory to avoid the space-
                    // splitting problem of the dir macro.
                    // Platform-native command first, then fallback.
                    tempname dh
                    tempfile dlist

                    if c(os) == "Windows" {
                        // Primary: Windows dir (cmd.exe)
                        local wdir : subinstr local curdir "/" "\", all
                        capture shell dir /b /a:-d `"`wdir'"' > `"`dlist'"' 2>nul
                        // If dir failed, fall back to ls (Git Bash / WSL)
                        capture file open `dh' using `"`dlist'"', read
                        if _rc {
                            capture shell ls -1 `"`curdir'"' > `"`dlist'"' 2>/dev/null
                        }
                        else {
                            file read `dh' dline
                            if r(eof) {
                                file close `dh'
                                capture shell ls -1 `"`curdir'"' > `"`dlist'"' 2>/dev/null
                            }
                            else {
                                file close `dh'
                            }
                        }
                    }
                    else {
                        // macOS / Linux / Unix: ls is standard
                        capture shell ls -1 `"`curdir'"' > `"`dlist'"' 2>/dev/null
                    }

                    capture file open `dh' using `"`dlist'"', read
                    if !_rc {
                        file read `dh' dline
                        while r(eof) == 0 {
                            local f = strtrim(`"`dline'"')
                            if `"`f'"' != "" {
                                local fullpath `"`curdir'/`f'"'
                                local prefix_len = length(`"`dirpath'"') + 1
                                local relpath = substr(`"`fullpath'"', `prefix_len' + 1, .)
                                local filecount = `filecount' + 1
                                local file_`filecount' `"`relpath'"'
                            }
                            file read `dh' dline
                        }
                        file close `dh'
                    }
                    else {
                        // Fallback to Stata's dir macro for file listing
                        // (less safe with spaces and special characters,
                        // but works when shell commands are unavailable)
                        local filelist : dir `"`curdir'"' files "*"
                        foreach f of local filelist {
                            local fullpath `"`curdir'/`f'"'
                            local prefix_len = length(`"`dirpath'"') + 1
                            local relpath = substr(`"`fullpath'"', `prefix_len' + 1, .)
                            local filecount = `filecount' + 1
                            local file_`filecount' `"`relpath'"'
                        }
                    }
                }

                // Enqueue subdirectories using shell listing
                // to avoid Stata's space-splitting dir macro.
                // Platform-native command first, then fallback.
                // NOTE: We avoid the ls "path" plus glob pattern
                // because Stata's parser would see a block-comment
                // start, consuming the rest of the file.
                tempname sh2
                tempfile slist2
                if c(os) == "Windows" {
                    // Primary: Windows dir (cmd.exe)
                    // dir /b /ad returns bare directory names
                    local wdir3 : subinstr local curdir "/" "\", all
                    capture shell dir /b /ad `"`wdir3'"' > `"`slist2'"' 2>nul
                    // If dir failed, fall back to find (Git Bash / WSL)
                    capture file open `sh2' using `"`slist2'"', read
                    if _rc {
                        capture shell find `"`curdir'"' -mindepth 1 -maxdepth 1 -type d > `"`slist2'"' 2>/dev/null
                    }
                    else {
                        file read `sh2' sdline
                        if r(eof) {
                            file close `sh2'
                            capture shell find `"`curdir'"' -mindepth 1 -maxdepth 1 -type d > `"`slist2'"' 2>/dev/null
                        }
                        else {
                            file close `sh2'
                        }
                    }
                }
                else {
                    // macOS / Linux / Unix: find is standard
                    capture shell find `"`curdir'"' -mindepth 1 -maxdepth 1 -type d > `"`slist2'"' 2>/dev/null
                }
                capture file open `sh2' using `"`slist2'"', read
                if !_rc {
                    file read `sh2' sdline
                    while r(eof) == 0 {
                        local sd = strtrim(`"`sdline'"')
                        // Strip trailing / if present (from some ls output)
                        while substr(`"`sd'"', -1, 1) == "/" {
                            local sd = substr(`"`sd'"', 1, length(`"`sd'"') - 1)
                        }
                        // Strip curdir prefix if present (find outputs
                        // full paths, dir /b outputs bare names)
                        local prefix_len = length(`"`curdir'"') + 1
                        local sd = substr(`"`sd'"', `prefix_len' + 1, .)
                        if `"`sd'"' != "" {
                            local q_tail = `q_tail' + 1
                            local q_`q_tail' `"`curdir'/`sd'"'
                        }
                        file read `sh2' sdline
                    }
                    file close `sh2'
                }
                else {
                    // Fallback to Stata's dir macro (less safe with spaces)
                    local subdirs : dir `"`curdir'"' dirs "*"
                    foreach d of local subdirs {
                        local q_tail = `q_tail' + 1
                        local q_`q_tail' `"`curdir'/`d'"'
                    }
                }
            }
        }

        // ----------------------------------------------------
        // 4d. Check if any files were found
        // ----------------------------------------------------
        if `filecount' == 0 {
            display as text "No files found in subdirectories."
            display as text "{hline 60}"
            exit
        }

        display as text "Files found in subdirectories: `filecount'"
        display as text "{hline 60}"

        // ----------------------------------------------------
        // 4e. Process each file — move from subdir to root
        //     Use forvalues + numbered macros to preserve
        //     filenames with spaces.
        // ----------------------------------------------------
        local moved   = 0
        local skipped = 0
        local failed  = 0

        forvalues i = 1/`filecount' {
            local relfile `"`file_`i''"'
            local filename = substr(`"`relfile'"', strrpos(`"`relfile'"', "/") + 1, .)
            local src  `"`dirpath'/`relfile'"'
            local dst  `"`dirpath'/`filename'"'

            // Safety: skip if src == dst (should not happen)
            if `"`src'"' == `"`dst'"' {
                display as text "  [SKIP] `relfile' (already at root)"
                local skipped = `skipped' + 1
                continue
            }

            // DRY RUN: preview only
            if "`dryrun'" == "dryrun" {
                display as text "  [DRYRUN] `relfile'  ->  ./`filename'"
                local moved = `moved' + 1
                continue
            }

            // Check for name collision at destination
            capture confirm file `"`dst'"'
            local cf_rc = _rc
            if !`cf_rc' & "`replace'" == "" {
                display as text "  [SKIP] `relfile' -> `filename' (already exists)"
                local skipped = `skipped' + 1
                continue
            }

            // Move: copy then erase
            capture copy `"`src'"' `"`dst'"', replace
            local cp_rc = _rc
            if `cp_rc' {
                display as error "  [FAIL] Cannot copy `relfile' (rc=`cp_rc')"
                local failed = `failed' + 1
                continue
            }

            capture erase `"`src'"'
            local er_rc = _rc
            if `er_rc' {
                display as error "  [WARN] Copied but cannot erase `relfile' (rc=`er_rc')"
                local failed = `failed' + 1
                continue
            }

            display as text "  [OK]   `relfile'  ->  ./`filename'"
            local moved = `moved' + 1
        }

        // ----------------------------------------------------
        // 4f. Clean up empty subdirectories left behind
        // ----------------------------------------------------
        // After moving all files, subdirectories may be empty.
        // Collect them recursively, then remove in multiple
        // passes (a parent dir only becomes empty once its
        // children have been removed).

        // --- Collect subdirectory paths ---
        tempname dh3
        tempfile dlist3
        local dirtotal = 0

        if c(os) == "Windows" {
            local wdir4 : subinstr local dirpath "/" "\", all
            capture shell dir /s /b /ad `"`wdir4'"' > `"`dlist3'"' 2>nul
            capture file open `dh3' using `"`dlist3'"', read
            if _rc {
                capture shell find `"`dirpath'"' -type d > `"`dlist3'"' 2>/dev/null
            }
            else {
                file read `dh3' dline3
                if r(eof) {
                    file close `dh3'
                    capture shell find `"`dirpath'"' -type d > `"`dlist3'"' 2>/dev/null
                }
                else {
                    file close `dh3'
                }
            }
        }
        else {
            capture shell find `"`dirpath'"' -type d > `"`dlist3'"' 2>/dev/null
        }

        capture file open `dh3' using `"`dlist3'"', read
        if !_rc {
            file read `dh3' dline3
            while r(eof) == 0 {
                local d3 = strtrim(`"`dline3'"')
                local d3 : subinstr local d3 "\" "/", all
                if `"`d3'"' != "" & `"`d3'"' != `"`dirpath'"' {
                    local dirtotal = `dirtotal' + 1
                    local dir_`dirtotal' `"`d3'"'
                }
                file read `dh3' dline3
            }
            file close `dh3'
        }
        else {
            // Fallback: BFS with Stata dir macro
            local qh = 1
            local qt = 1
            local q_1 `"`dirpath'"'
            while `qh' <= `qt' {
                local cdir `"`q_`qh''"'
                local qh = `qh' + 1
                if `"`cdir'"' != `"`dirpath'"' {
                    local dirtotal = `dirtotal' + 1
                    local dir_`dirtotal' `"`cdir'"'
                }
                local sdirs : dir `"`cdir'"' dirs "*"
                foreach sd of local sdirs {
                    local qt = `qt' + 1
                    local q_`qt' `"`cdir'/`sd'"'
                }
            }
        }

        // --- Remove empty directories (multi-pass) ---
        local dremoved = 0
        if `dirtotal' > 0 {
            if "`dryrun'" == "dryrun" {
                display as text "{hline 60}"
                display as text "Empty directories that would be removed:"
                forvalues j = 1/`dirtotal' {
                    if `"`dir_`j''"' != "" {
                        display as text "  [DRYRUN] rmdir `dir_`j''"
                        local dremoved = `dremoved' + 1
                    }
                }
            }
            else {
                display as text "{hline 60}"
                display as text "Removing empty directories..."
                local dpass = 0
                while `dpass' < 50 & `dremoved' < `dirtotal' {
                    local dpass = `dpass' + 1
                    local dchanged = 0
                    forvalues j = 1/`dirtotal' {
                        if `"`dir_`j''"' != "" {
                            capture rmdir `"`dir_`j''"'
                            if !_rc {
                                display as text "  [RM] `dir_`j''"
                                local dremoved = `dremoved' + 1
                                local dir_`j' ""
                                local dchanged = 1
                            }
                        }
                    }
                    if `dchanged' == 0 {
                        // No more removable — exit loop
                        local dpass = 50
                    }
                }
                local dleft = `dirtotal' - `dremoved'
                if `dleft' > 0 {
                    display as text "  (`dleft' non-empty director(y/ies) retained)"
                }
            }
        }

        // ----------------------------------------------------
        // 4g. Print summary for flatten mode
        // ----------------------------------------------------
        display as text "{hline 60}"
        if "`dryrun'" == "dryrun" {
            display as result "DRY RUN complete."
            display as text "  `filecount' file(s) would be moved."
            if `dremoved' > 0 {
                display as text "  `dremoved' empty director(y/ies) would be removed."
            }
        }
        else {
            display as result "Flatten complete."
            display as text "  Moved:   `moved'"
            if `skipped' > 0 {
                display as text "  Skipped: `skipped' (already existed, use replace to overwrite)"
            }
            if `failed' > 0 {
                display as text "  Failed:  `failed'"
            }
            if `dremoved' > 0 {
                display as text "  Removed: `dremoved' empty director(y/ies)"
            }
        }
        display as text "{hline 60}"
        exit
    }

    // ============================================================
    // 5. CLASSIFY MODE — list all files in the top level only
    // ============================================================
    display as text "Mode: classify (by first character)"

    // Use shell + file read to handle filenames with spaces
    // (Stata's dir macro splits on spaces).
    // Platform-native command first, then cross-platform fallback.
    tempname cfh
    tempfile cflist
    if c(os) == "Windows" {
        // Primary: Windows dir (cmd.exe)
        local wdir_c : subinstr local dirpath "/" "\", all
        capture shell dir /b /a:-d `"`wdir_c'"' > `"`cflist'"' 2>nul
        // If dir failed, fall back to ls (Git Bash / WSL)
        capture file open `cfh' using `"`cflist'"', read
        if _rc {
            capture shell ls -1 `"`dirpath'"' > `"`cflist'"' 2>/dev/null
        }
        else {
            file read `cfh' cline
            if r(eof) {
                file close `cfh'
                capture shell ls -1 `"`dirpath'"' > `"`cflist'"' 2>/dev/null
            }
            else {
                file close `cfh'
            }
        }
    }
    else {
        // macOS / Linux / Unix: ls is standard
        capture shell ls -1 `"`dirpath'"' > `"`cflist'"' 2>/dev/null
    }

    local filecount = 0
    capture file open `cfh' using `"`cflist'"', read
    if !_rc {
        file read `cfh' cline
        while r(eof) == 0 {
            local fname = strtrim(`"`cline'"')
            if `"`fname'"' != "" {
                local filecount = `filecount' + 1
                local cfile_`filecount' `"`fname'"'
            }
            file read `cfh' cline
        }
        file close `cfh'
    }
    else {
        // Fallback to Stata's dir macro (less safe with spaces)
        local filelist : dir `"`dirpath'"' files "*"
        local idx = 0
        foreach f of local filelist {
            local idx = `idx' + 1
            local cfile_`idx' `"`f'"'
        }
        local filecount = `idx'
    }

    if `filecount' == 0 {
        display as text "No files found in this directory."
        display as text "{hline 60}"
        exit
    }

    display as text "Files found: `filecount'"
    display as text "{hline 60}"

    // ============================================================
    // 5a. Process each file
    // ============================================================
    local moved   = 0
    local skipped = 0
    local failed  = 0
    local cats    ""

    forvalues i = 1/`filecount' {
        local file `"`cfile_`i''"'
        // ----------------------------------------------------
        // 5b. Classify by first character (lowercased)
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
        // 5c. Dry-run: preview only
        // ----------------------------------------------------
        if "`dryrun'" == "dryrun" {
            display as text "  [DRYRUN] `file'  ->  `cat'/"
            local moved = `moved' + 1
            continue
        }

        // ----------------------------------------------------
        // 5d. Ensure category subdirectory exists
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
        // 5e. Check for existing file in destination
        // ----------------------------------------------------
        capture confirm file `"`dst'"'
        if !_rc & "`replace'" == "" {
            display as text "  [SKIP] `file' already exists in `cat'/"
            display as text "         (use replace to overwrite)"
            local skipped = `skipped' + 1
            continue
        }

        // ----------------------------------------------------
        // 5f. Copy file to destination
        // ----------------------------------------------------
        capture copy `"`src'"' `"`dst'"', replace
        if _rc {
            display as error "  [FAIL] Cannot copy `file' (rc=`_rc')"
            local failed = `failed' + 1
            continue
        }

        // ----------------------------------------------------
        // 5g. Erase original file
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
