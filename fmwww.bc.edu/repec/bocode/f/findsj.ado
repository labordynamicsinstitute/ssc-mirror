*! version 3.1  03Feb2026
*! Yujun Lian (arlionn@163.com), Chucheng Wan (chucheng.wan@outlook.com)

* Search Stata Journal and Stata Technical Bulletin articles
* v2.1.2: Bug fix - hyphenated keywords now supported
*   - Fixed: Keywords with hyphens (e.g., "difference-in-differences") now work correctly
*   - Added: "everything" subitem to syntax to prevent "in" range misinterpretation
* v2.1.1: Bug fixes - BibTeX/RIS download improvements
*   - Fixed: BibTeX/RIS now correctly downloads to current directory by default
*   - Fixed: setpath() configuration now properly saved and loaded across sessions
*   - Fixed: Download path correctly handles Chinese characters in directory names
*   - Fixed: Path separators normalized for Windows compatibility
* v2.1.0: Major update - Bug fixes and performance optimization
*   - Fixed Bug #1: Citation count display (results < n)
*   - Fixed Bug #3: Author name order (via citation_apa)
*   - Fixed Bug #4: Added text/txt options as aliases for plain format
* v1.6.0: Use local citation_apa field for offline citations (no need to call getiref)
* v1.5.0: 'added by Yujun Lian 2025/12/31', add number list before ref
* v1.4.0: Auto-check for database updates (monthly reminder with download option)
* v1.3.0: Direct getiref integration - click .md/.latex/.txt calls getiref with DOI
* v1.2.0: Simplified to single 'ref' option with three format buttons
* v1.1.1: Added individual "Ref" button for each article to copy citation
* v1.1.0: Removed local data file dependency, all info fetched online

*===============================================================================
* Helper program: findsj_download (defined first to be available for buttons)
* Download BibTeX or RIS file on-demand when user clicks the button
*===============================================================================
// cap program drop findsj_download
program define findsj_download
    version 14
    syntax anything(name=artid), Type(string) [DOWNloadpath(string)]
    
    * Set download path (read from config file, use global if set, otherwise current directory)
    if "`downloadpath'" == "" {
        * First try to read from config file
        local config_file "`c(sysdir_personal)'findsj_config.txt"
        capture confirm file "`config_file'"
        if _rc == 0 {
            tempname fh
            file open `fh' using "`config_file'", read text
            file read `fh' line
            file close `fh'
            local downloadpath = strtrim("`line'")
        }
        * If still empty, check global variable
        if "`downloadpath'" == "" & "$findsj_download_path" != "" {
            local downloadpath "$findsj_download_path"
        }
        * If still empty, use current directory
        if "`downloadpath'" == "" {
            local downloadpath "`c(pwd)'"
        }
    }
    
    * Build URL based on article ID and type
    if "`type'" == "bib" {
        local url "https://www.stata-journal.com/ris.php?articlenum=`artid'&abs=1&type=bibtex"
    }
    else if "`type'" == "ris" {
        local url "https://www.stata-journal.com/ris.php?articlenum=`artid'&abs=1&type=ris"
    }
    else {
        dis as error "Error: type must be 'bib' or 'ris'"
        exit 198
    }
    
    * Determine file extension
    local file_ext = cond("`type'"=="bib", "bib", "ris")
    local file_name "`artid'.`file_ext'"
    * Normalize path separators and build full path
    if "`c(os)'" == "Windows" {
        local downloadpath = subinstr("`downloadpath'", "/", "\", .)
        local full_file = "`downloadpath'" + "\" + "`file_name'"
    }
    else {
        local full_file = "`downloadpath'" + "/" + "`file_name'"
    }
    local url_article "https://www.stata-journal.com/article.html?article=`artid'"
    
    * Generate unique temp script file name in system temp directory
    local script_file "`c(tmpdir)'_findsj_dl_`artid'_`type'.`=cond("`c(os)'"=="Windows","ps1","sh")'"
    
    * Create and execute download script
    quietly {
        tempname fh
        
        if "`c(os)'" == "MacOSX" | "`c(os)'" == "Unix" {
            * Unix/Mac shell script with curl
            local full_file_esc = subinstr("`full_file'", `"""', `"\""', .)
            local full_file_esc = subinstr("`full_file_esc'", "$", "\$", .)
            local full_file_esc = subinstr("`full_file_esc'", "`", "\`", .)
            
            file open `fh' using "`script_file'", write replace
            file write `fh' "#!/bin/bash" _n
            file write `fh' "OUTPUT_FILE=" `"""' "`full_file_esc'" `"""' _n
            file write `fh' "curl -sSL -H 'Referer: `url_article'' -H 'User-Agent: Mozilla/5.0' -o " `"""' "$" "{OUTPUT_FILE}" `"""' " '`url'' > /dev/null 2>&1" _n
            file write `fh' "if [ -f " `"""' "$" "{OUTPUT_FILE}" `"""' " ] && [ -s " `"""' "$" "{OUTPUT_FILE}" `"""' " ]; then" _n
            file write `fh' "    echo " `"""' "Downloaded: $" "{OUTPUT_FILE}" `"""' _n
            file write `fh' "    open " `"""' "$" "{OUTPUT_FILE}" `"""' " > /dev/null 2>&1" _n
            file write `fh' "else" _n
            file write `fh' "    echo " `"""' "Download failed" `"""' " >&2" _n
            file write `fh' "fi" _n
            file write `fh' "rm -f " `"""' "`script_file'" `"""' " > /dev/null 2>&1" _n
            file close `fh'
            
            shell chmod +x "`script_file'" > /dev/null 2>&1
            shell bash "`script_file'" &
        }
        else {
            * Windows PowerShell: use -Command instead of -File for better encoding support
            * Escape single quotes and backslashes in paths
            local full_file_ps = subinstr("`full_file'", "'", "''", .)
            local script_ps = subinstr("`script_file'", "'", "''", .)
            
            local ps_command = "try { " + ///
                "Invoke-WebRequest -Uri '`url'' " + ///
                "-Headers @{'Referer'='`url_article'';'User-Agent'='Mozilla/5.0'} " + ///
                "-OutFile '`full_file_ps''; " + ///
                "if (Test-Path '`full_file_ps'') { " + ///
                "Write-Host 'Downloaded: `full_file_ps'' -ForegroundColor Green; " + ///
                "Start-Process '`full_file_ps'' } " + ///
                "else { Write-Host 'Download failed!' -ForegroundColor Red } " + ///
                "} catch { Write-Host " + char(36) + "_.Exception.Message -ForegroundColor Red }"
            
            shell powershell -ExecutionPolicy Bypass -Command "`ps_command'"
        }
    }
    
    dis as text "Downloading `file_ext' file for `artid'..."
end



*===============================================================================
* Main program: findsj
*===============================================================================
// cap program drop findsj
program define findsj, rclass
version 14

syntax [anything(name=keywords id="keywords" everything)] [, ///
    Author  ///
	  Title ///
	  Keyword ///
    REF  ///
    MD  ///
	  Markdown ///
	  Latex ///
	  TEX   ///
	  Plain  ///
	  TEXT   ///
	  TXT    ///
    NOBrowser ///
	  NOPDF ///
	  NOPkg ///
	  NOCLip ///
    N(integer 10) ///
	ALLresults ///
    GETDOI ///
    Clear  ///
	Debug  ///
    OFFline ///
    CHECKdb ///
    INSTALLdb(string) ///
    SETPath(string) ///
	  QUERYpath ///
	  RESETpath ///
    UPdate ///
    UPdatesource ///
    SOUrce(string) ///
    Type(string) ///
    ]

	
* Check if getiref is installed (needed for online citation fetching and individual article buttons)
* Note: With local database (findsj.dta), citations can be generated without getiref
capture which getiref
if _rc != 0 {
    dis as text "{p}command getiref is unrecognized. Installing from SSC...{p_end}"
    capture ssc install getiref
    if _rc != 0 {
        dis as error "{p}Failed to install getiref. Please check your internet connection or install manually: {stata ssc install getiref}{p_end}"
    }
    else {
        dis as result "{p}getiref successfully installed!{p_end}"
    }
}



* Check for updates (once per day)
findsj_check_update


* Handle download subcommand (findsj artid, type(bib|ris))
if "`type'" != "" {
    if "`type'" != "bib" & "`type'" != "ris" {
        dis as error "Error: type must be 'bib' or 'ris'"
        exit 198
    }
    findsj_download `keywords', type(`type')
    exit
}

* Handle showref subcommand (findsj artid, ref)
if "`ref'" != "" & "`keywords'" != "" & "`author'" == "" & "`title'" == "" & "`keyword'" == "" {
    * Check if keywords looks like an article ID (not a search term)
    * Article IDs are typically alphanumeric strings like "st0001", "dm0065", or "st0136_1"
    if regexm("`keywords'", "^[a-z]+[0-9_]+$") | regexm("`keywords'", "^ï»¿[a-z]+[0-9_]+$") {
        findsj_show_ref `keywords'
        exit
    }
}

* Handle database update subcommand
* If user specifies 'update' without 'updatesource', default to 'both'
if "`update'" != "" & "`updatesource'" == "" {
    local updatesource "updatesource"
    local source "both"
}

* If user specifies 'updatesource' without source(), show menu
if "`updatesource'" != "" & "`source'" == "" {
    local source ""  // Empty will trigger menu in findsj_update_db
}

if "`updatesource'" != "" {
    * source parameter contains the source choice (empty = show menu)
    findsj_update_db "`source'"
    exit
}

* Handle checkdb subcommand - show database location and status
if "`checkdb'" != "" {
    dis ""
    dis as text "{hline 70}"
    dis as result "  findsj Database Location Check"
    dis as text "{hline 70}"
    dis ""
    
    * Find findsj.ado location
    local ado_path = ""
    capture findfile findsj.ado
    if _rc == 0 {
        local ado_fullpath = r(fn)
        dis as text "findsj.ado: " as result "`ado_fullpath'"
        
        * Extract directory
        local rev_path = reverse("`ado_fullpath'")
        local pos_slash = strpos("`rev_path'", "/")
        local pos_backslash = strpos("`rev_path'", "\")
        local last_sep = 0
        if `pos_slash' > 0 & `pos_backslash' > 0 {
            local last_sep = min(`pos_slash', `pos_backslash')
        }
        else if `pos_slash' > 0 {
            local last_sep = `pos_slash'
        }
        else if `pos_backslash' > 0 {
            local last_sep = `pos_backslash'
        }
        if `last_sep' > 0 {
            local ado_path = substr("`ado_fullpath'", 1, length("`ado_fullpath'") - `last_sep' + 1)
        }
        
        * List files in findsj.ado directory
        dis ""
        dis as text "Files in findsj.ado directory:"
        if c(os) == "Windows" {
            local clean_path = subinstr("`ado_path'", "/", "\", .)
            shell dir /b "`clean_path'findsj*.*"
        }
        else {
            shell ls -lh "`ado_path'"findsj* 2>/dev/null || echo "No files found or permission denied"
        }
    }
    
    * Build search paths using numbered locals (to handle paths with spaces)
    local n_paths = 0
    
    if "`ado_path'" != "" {
        local n_paths = `n_paths' + 1
        local path`n_paths' `"`ado_path'"'
    }
    
    local plus_f `"`c(sysdir_plus)'f`c(dirsep)'"'
    local n_paths = `n_paths' + 1
    local path`n_paths' `"`plus_f'"'
    
    local n_paths = `n_paths' + 1
    local path`n_paths' `"`c(sysdir_plus)'"'
    
    local n_paths = `n_paths' + 1
    local path`n_paths' `"`c(sysdir_personal)'"'
    
    local n_paths = `n_paths' + 1
    local path`n_paths' `"`c(pwd)'"'
    
    dis ""
    dis as text "Search paths:"
    forvalues i = 1/`n_paths' {
        dis as text "  - `path`i''"
    }
    
    * Search for database
    dis ""
    dis as text "Searching for findsj.dta..."
    dis ""
    local found = 0
    forvalues i = 1/`n_paths' {
        local p `"`path`i''"'
        local file_found = 0
        local rc1 = .
        local rc2 = .
        
        * Try with forward slash (use compound quotes for paths with spaces)
        capture confirm file `"`p'/findsj.dta"'
        local rc1 = _rc
        if `rc1' == 0 {
            local file_found = 1
            local file_path `"`p'/findsj.dta"'
        }
        
        * Try without separator
        if `file_found' == 0 {
            capture confirm file `"`p'findsj.dta"'
            local rc2 = _rc
            if `rc2' == 0 {
                local file_found = 1
                local file_path `"`p'findsj.dta"'
            }
        }
        
        * Debug: show what we tried
        dis as text "  Checking: " as text `"`p'/findsj.dta"' _c
        if `rc1' == 0 {
            dis as result " ✓"
        }
        else {
            dis as error " ✗ (rc=`rc1')"
            if `rc2' != . {
                dis as text "  Checking: " as text `"`p'findsj.dta"' _c
                if `rc2' == 0 {
                    dis as result " ✓"
                }
                else {
                    dis as error " ✗ (rc=`rc2')"
                }
            }
        }
        
        if `file_found' == 1 {
            * Clean up display path (remove double slashes)
            local display_path = subinstr(`"`file_path'"', "//", "/", .)
            local display_path = subinstr(`"`display_path'"', "\\", "/", .)
            
            dis ""
            dis as result "  [FOUND] " as text `"`display_path'"'
            local found = 1
            
            * Get file info
            capture {
                use `"`file_path'"', clear
                local n_records = _N
                dis as text "          Records: " as result "`n_records'" as text " articles"
                clear
            }
            
            * Found in this path, skip remaining paths
            continue, break
        }
    }
    
    if `found' == 0 {
        dis as error "  [NOT FOUND] findsj.dta not found"
        dis ""
        dis as text "To download the database:"
        dis as text "  {stata findsj, updatesource source(both):findsj, updatesource source(both)}"
        dis ""
        dis as text "If you have findsj.dta file, manually install it:"
        dis as text "  1. Drag findsj.dta into Stata to get its full path"
        dis as text "  2. Run: findsj, installdb(" as result "/full/path/to/findsj.dta" as text ")"
    }
    
    dis ""
    dis as text "{hline 70}"
    exit
}

* Handle manual database installation
if "`installdb'" != "" {
    dis ""
    dis as text "{hline 70}"
    dis as result "  Manual Database Installation"
    dis as text "{hline 70}"
    dis ""
    
    * Check if source file exists
    capture confirm file "`installdb'"
    if _rc != 0 {
        dis as error "Error: Cannot find file: `installdb'"
        dis ""
        dis as text "To get the full path:"
        dis as text "  1. Drag findsj.dta file into Stata command window"
        dis as text "  2. Copy the displayed path"
        dis as text "  3. Use: findsj, installdb(" as result "paste-path-here" as text ")"
        exit 601
    }
    
    * Verify it's a valid .dta file
    capture use "`installdb'", clear
    if _rc != 0 {
        dis as error "Error: File is not a valid Stata dataset"
        exit 610
    }
    local n_records = _N
    clear
    
    * Find findsj.ado location to install database alongside
    local ado_path = ""
    capture findfile findsj.ado
    if _rc == 0 {
        local ado_fullpath = r(fn)
        
        * Extract directory
        local rev_path = reverse("`ado_fullpath'")
        local pos_slash = strpos("`rev_path'", "/")
        local pos_backslash = strpos("`rev_path'", "\")
        local last_sep = 0
        if `pos_slash' > 0 & `pos_backslash' > 0 {
            local last_sep = min(`pos_slash', `pos_backslash')
        }
        else if `pos_slash' > 0 {
            local last_sep = `pos_slash'
        }
        else if `pos_backslash' > 0 {
            local last_sep = `pos_backslash'
        }
        if `last_sep' > 0 {
            local ado_path = substr("`ado_fullpath'", 1, length("`ado_fullpath'") - `last_sep' + 1)
        }
    }
    
    if "`ado_path'" == "" {
        dis as error "Error: Cannot locate findsj.ado directory"
        exit 601
    }
    
    * Copy file to ado directory
    local dest_path "`ado_path'findsj.dta"
    
    * Check if source and destination are the same
    local source_clean = subinstr("`installdb'", "\", "/", .)
    local dest_clean = subinstr("`dest_path'", "\", "/", .)
    local source_clean = subinstr("`source_clean'", "//", "/", .)
    local dest_clean = subinstr("`dest_clean'", "//", "/", .)
    
    if "`source_clean'" == "`dest_clean'" {
        dis as result "Database is already in the correct location!"
        dis as text "Location: " as result "`dest_path'"
        dis as text "Total articles: " as result "`n_records'"
        dis ""
        dis as text "Test offline mode:"
        dis as text "  {stata findsj machine learning, offline n(3):findsj machine learning, offline n(3)}"
        dis ""
        dis as text "{hline 70}"
        exit
    }
    
    dis as text "Source: " as result "`installdb'"
    dis as text "Destination: " as result "`dest_path'"
    dis ""
    dis as text "Installing..." _c
    
    capture copy "`installdb'" "`dest_path'", replace
    if _rc != 0 {
        dis as error " Failed! (rc=`_rc')"
        dis ""
        dis as error "Error: Cannot copy file. Possible reasons:"
        dis as text "  - Permission denied"
        dis as text "  - Destination path not writable"
        dis as text "  - File in use"
        exit `_rc'
    }
    
    dis as result " Success!"
    dis ""
    dis as text "{hline 70}"
    dis as result "  Installation Complete!"
    dis as text "{hline 70}"
    dis as text "Database installed: " as result "`dest_path'"
    dis as text "Total articles: " as result "`n_records'"
    dis ""
    dis as text "Test offline mode:"
    dis as text "  {stata findsj machine learning, offline n(3):findsj machine learning, offline n(3)}"
    dis ""
    dis as text "{hline 70}"
    exit
}

* Handle download path configuration subcommands
if "`querypath'" != "" | "`resetpath'" != "" | "`setpath'" != "" {
    local config_file "`c(sysdir_personal)'findsj_config.txt"
    
    * Query current path
    if "`querypath'" != "" {
        capture confirm file "`config_file'"
        if _rc == 0 {
            tempname fh
            file open `fh' using "`config_file'", read text
            file read `fh' line
            file close `fh'
            local saved_path = strtrim("`line'")
            if "`saved_path'" != "" {
                dis as result "Current download path: " as text "`saved_path'"
            }
            else {
                dis as result "Current download path: " as text "`c(pwd)'" as text " (default)"
            }
        }
        else {
            dis as result "Current download path: " as text "`c(pwd)'" as text " (default)"
        }
        exit
    }
    
    * Reset to default
    if "`resetpath'" != "" {
        capture erase "`config_file'"
        global findsj_download_path ""
        dis as result "Download path reset to default (current working directory)"
        dis as text "Use " as result "findsj ..., setpath(path)" as text " to set a custom download path"
        exit
    }
    
    * Set new path
    if "`setpath'" != "" {
        * Try to change to the directory as validation
        local current_dir = c(pwd)
        quietly capture cd "`setpath'"
        if _rc != 0 {
            dis as error "Directory does not exist: `setpath'"
            exit 601
        }
        quietly cd "`current_dir'"
        
        * Save path to config file
        tempname fh
        file open `fh' using "`config_file'", write replace
        file write `fh' "`setpath'"
        file close `fh'
        
        * Also set global variable for immediate effect in current session
        global findsj_download_path "`setpath'"
        
        dis as result "Download path set to: " as text "`setpath'"
        dis as text "This setting will be remembered for future sessions."
        exit
    }
}

if "`debug'" != "" set trace on

* Handle TEX as alias for latex
if "`tex'" != "" local latex "latex"

* Handle MD and Markdown options (both supported)
if "`md'" != "" | "`markdown'" != "" {
    local md "md"
}

* Handle TEXT, TXT, and Plain options (all map to plain)
if "`text'" != "" | "`txt'" != "" | "`plain'" != "" {
    local plain "plain"
}

* Validate export format options
local args_export "`md' `latex' `plain'"
local num_export = wordcount("`args_export'")
if `num_export' > 1 {
    dis as error "Specify only one export format: markdown, latex, or plain"
    exit 198
}

* Auto-enable getdoi when ref option is specified
if "`ref'" != "" {
    local getdoi "getdoi"
}

* Read download path from config file
local config_file "`c(sysdir_personal)'findsj_config.txt"
local download_path ""
capture confirm file "`config_file'"
if _rc == 0 {
    tempname fh
    file open `fh' using "`config_file'", read text
    file read `fh' line
    file close `fh'
    local download_path = strtrim("`line'")
}
* Use current directory as default if no config or empty config
if "`download_path'" == "" {
    local download_path "`c(pwd)'"
}

local keywords = strtrim(`"`keywords'"')   
local keywords = stritrim(`"`keywords'"')
if wordcount(`"`keywords'"') > 1 {
    local keywords_url = subinstr(`"`keywords'"', " ", "+", .)
}
else {
    local keywords_url `"`keywords'"'
}

local args_scope "`author' `title' `keyword'"
local num_scope = wordcount("`args_scope'")
if `num_scope' > 1 {
    dis as error "Specify only one: author, title, or keyword"
    exit 198
}
if `num_scope' == 0 local scope "keyword"
else {
    if "`author'" != "" local scope "author"
    if "`title'"  != "" local scope "title"
    if "`keyword'"!= "" local scope "keyword"
}

* Check if findsj.dta exists, if not and ref option is used, show one-time reminder
* Priority 1: Same directory as findsj.ado (ensures version compatibility)
local dta_found = 0
local ado_path = ""
capture findfile findsj.ado
if _rc == 0 {
    local ado_fullpath = r(fn)
    * Extract directory from full path (cross-platform compatible)
    * Find the last path separator (/ or \), handle mixed separators
    local rev_path = reverse("`ado_fullpath'")
    local pos_slash = strpos("`rev_path'", "/")
    local pos_backslash = strpos("`rev_path'", "\")
    local last_sep = 0
    if `pos_slash' > 0 & `pos_backslash' > 0 {
        local last_sep = min(`pos_slash', `pos_backslash')
    }
    else if `pos_slash' > 0 {
        local last_sep = `pos_slash'
    }
    else if `pos_backslash' > 0 {
        local last_sep = `pos_backslash'
    }
    if `last_sep' > 0 {
        local ado_path = substr("`ado_fullpath'", 1, length("`ado_fullpath'") - `last_sep' + 1)
    }
}

* Build search paths with findsj.ado directory as highest priority
* Use numbered locals to handle paths with spaces correctly
local n_paths = 0

if "`ado_path'" != "" {
    local n_paths = `n_paths' + 1
    local path`n_paths' `"`ado_path'"'
}

* Add PLUS/f/ subdirectory (where net install puts files starting with 'f')
local plus_f `"`c(sysdir_plus)'f`c(dirsep)'"'
local n_paths = `n_paths' + 1
local path`n_paths' `"`plus_f'"'

local n_paths = `n_paths' + 1
local path`n_paths' `"`c(sysdir_plus)'"'

local n_paths = `n_paths' + 1
local path`n_paths' `"`c(sysdir_personal)'"'

local n_paths = `n_paths' + 1
local path`n_paths' `"`c(pwd)'"'

* Debug mode: show search paths
if "`debug'" != "" {
    dis as text _n "Debug: Searching for findsj.dta in the following paths:"
    forvalues i = 1/`n_paths' {
        dis as text "  - `path`i''"
    }
}

forvalues i = 1/`n_paths' {
    local p `"`path`i''"'
    * Try both path separators for cross-platform compatibility
    * Use compound quotes for paths with spaces
    capture confirm file `"`p'/findsj.dta"'
    if _rc != 0 {
        capture confirm file `"`p'findsj.dta"'
    }
    if _rc == 0 {
        local dta_found = 1
        local dta_found_path `"`p'"'
        continue, break
    }
}

* Debug: show result of dta search
if "`debug'" != "" {
    if `dta_found' == 1 {
        dis as result "Debug: Found findsj.dta at: `dta_found_path'"
    }
    else {
        dis as error "Debug: findsj.dta NOT found in any search path"
    }
}

if `dta_found' == 0 & "`ref'" != "" {
    dis as text _n "{hline 70}"
    dis as text " " as result "Notice:" as text " Local database (findsj.dta) not found."
    dis as text " DOI information will be fetched online (may be slower)."
    dis as text _n " For faster performance, update the database:"
    dis as text "   {stata findsj, updatesource source(github):findsj, updatesource source(github)}  " as text "(international users)"
    dis as text "   {stata findsj, updatesource source(gitee):findsj, updatesource source(gitee)}   " as text "(China users, faster)"
    dis as text "   {stata findsj, updatesource source(both):findsj, updatesource source(both)}    " as text "(auto fallback)"
    dis as text "{hline 70}" _n
}

*===============================================================================
* OFFLINE SEARCH: Use local findsj.dta if available
*===============================================================================
local use_offline = 0
local dta_path = ""

* Find local database path first
if `dta_found' == 1 {
    forvalues i = 1/`n_paths' {
        local p `"`path`i''"'
        capture confirm file `"`p'/findsj.dta"'
        if _rc == 0 {
            local dta_path `"`p'/findsj.dta"'
            continue, break
        }
        * Try without separator (in case path already ends with one)
        capture confirm file `"`p'findsj.dta"'
        if _rc == 0 {
            local dta_path `"`p'findsj.dta"'
            continue, break
        }
    }
}

* Check if user explicitly requested offline mode
if "`offline'" != "" {
    if `dta_found' == 0 | `"`dta_path'"' == "" {
        dis as error "Offline mode requested but findsj.dta not found."
        dis as text "Please download the database first:"
        dis as text "  {stata findsj, updatesource source(both):findsj, updatesource source(both)}"
        dis ""
        dis as text "Run " as result "findsj, checkdb" as text " to diagnose the issue"
        exit 601
    }
    local use_offline = 1
}
else if `dta_found' == 1 & `"`dta_path'"' != "" {
    * Auto-enable offline mode if database is available
    local use_offline = 1
}

if `use_offline' == 1 {
    * ===== OFFLINE SEARCH MODE =====
    * Removed search progress message for cleaner output
    
    preserve //===================preserve begin======
    
    qui {
        use "`dta_path'", clear
        
        * Normalize variable names (handle both artid and art_id)
        cap confirm variable artid
        if _rc == 0 {
            rename artid art_id
        }
        cap confirm variable DOI
        if _rc == 0 {
            rename DOI doi
        }
        
        * Handle authors vs author field name
        cap confirm variable authors
        if _rc == 0 {
            rename authors author
        }
        
        * ========================================
        * Search Logic (matches Stata Journal website):
        * 1. Case-insensitive (convert all to lowercase)
        * 2. Substring matching (strpos > 0)
        * 3. Multiple words use AND logic (all words must appear)
        * 4. Author search: only first word is used
        * 5. Keyword search: searches in title, author, AND abstract
        * 6. Abbreviation expansion: automatically expands common abbreviations
        * ========================================
        
        * Generate lowercase versions of search fields
        gen title_lower = lower(title)
        gen author_lower = lower(author)
        gen abstract_lower = lower(abstract)
        
        * Parse keywords into individual words (use compound quotes for spaces)
        local keywords_lower = lower(`"`keywords'"')
        local keywords_clean : subinstr local keywords_lower "  " " ", all
        local keywords_clean = strtrim("`keywords_clean'")
        
        * Check if keyword is a common abbreviation and prepare expanded search
        local keywords_upper = upper("`keywords_clean'")
        local expanded_keywords = ""
        local is_abbreviation = 0
        
        if "`keywords_upper'" == "PSM" {
            local expanded_keywords "propensity score"
            local is_abbreviation = 1
        }
        else if "`keywords_upper'" == "IV" {
            local expanded_keywords "instrumental variable"
            local is_abbreviation = 1
        }
        else if "`keywords_upper'" == "DID" | "`keywords_upper'" == "DD" {
            local expanded_keywords "difference in differences"
            local is_abbreviation = 1
        }
        else if "`keywords_upper'" == "RDD" | "`keywords_upper'" == "RD" {
            local expanded_keywords "regression discontinuity"
            local is_abbreviation = 1
        }
        else if "`keywords_upper'" == "GMM" {
            local expanded_keywords "generalized method of moments"
            local is_abbreviation = 1
        }
        else if "`keywords_upper'" == "VAR" {
            local expanded_keywords "vector autoregression"
            local is_abbreviation = 1
        }
        
        * Count number of words
        local n_words = wordcount(`"`keywords_clean'"')
        
        * Initialize match priority (1=exact match, 2=expanded match)
        gen match_priority = .
        gen matched = 0
        
        * First pass: exact match with original keywords
        if "`scope'" == "author" {
            * Author search: only first word matters
            local first_word = word(`"`keywords_clean'"', 1)
            replace matched = 1 if strpos(author_lower, "`first_word'") > 0
            replace match_priority = 1 if matched == 1
        }
        else if "`scope'" == "keyword" {
            * Keyword search: ALL words must appear somewhere (title/author/abstract)
            gen temp_match = 1
            forvalues i = 1/`n_words' {
                local word = word(`"`keywords_clean'"', `i')
                replace temp_match = 0 if strpos(title_lower, "`word'") == 0 & ///
                                          strpos(author_lower, "`word'") == 0 & ///
                                          strpos(abstract_lower, "`word'") == 0
            }
            replace matched = 1 if temp_match == 1
            replace match_priority = 1 if matched == 1
            drop temp_match
        }
        else if "`scope'" == "title" {
            * Title search: ALL words must appear in title
            gen temp_match = 1
            forvalues i = 1/`n_words' {
                local word = word(`"`keywords_clean'"', `i')
                replace temp_match = 0 if strpos(title_lower, "`word'") == 0
            }
            replace matched = 1 if temp_match == 1
            replace match_priority = 1 if matched == 1
            drop temp_match
        }
        
        * Second pass: expanded keywords (if abbreviation detected and scope is keyword)
        if `is_abbreviation' == 1 & "`scope'" == "keyword" {
            local n_expanded = wordcount(`"`expanded_keywords'"')
            gen temp_match = 1
            forvalues i = 1/`n_expanded' {
                local word = word(`"`expanded_keywords'"', `i')
                replace temp_match = 0 if strpos(title_lower, "`word'") == 0 & ///
                                          strpos(author_lower, "`word'") == 0 & ///
                                          strpos(abstract_lower, "`word'") == 0
            }
            * Add expanded matches with lower priority
            replace matched = 1 if temp_match == 1 & matched == 0
            replace match_priority = 2 if temp_match == 1 & match_priority == .
            drop temp_match
        }
        
        * Keep only matched results
        keep if matched == 1
        drop matched title_lower author_lower abstract_lower
        
        * Sort by priority first, then by year (newest first), volume, number
        gsort match_priority -year -volume -number
        drop match_priority
        
        local n_results = _N
        
        if `n_results' == 0 {
            noi dis as error "No articles found matching: `keywords'"
            noi dis as text "Try different keywords or search scope."
            restore
            exit
        }
        
        * Create variables to match online search format
        gen selected = 1
        gen volnum_str = string(volume) + "(" + string(number) + ")"
        gen volnum_url = string(volume) + "-" + string(number)
        
        * Create URL variables
        local url_base "https://www.stata-journal.com/article.html?article="
        gen art_id_clean = art_id
        qui replace art_id_clean = subinstr(art_id_clean, "ï»¿", "%EF%BB%BF", .)
        gen url_html = "`url_base'" + art_id_clean
        
        local url_pdf_base "https://journals.sagepub.com/doi/pdf/"
        gen url_pdf = "`url_pdf_base'" + doi if doi != "" & doi != "."
        
        * Page string (if available)
        cap confirm variable page
        if _rc != 0 {
            gen page = "."
        }
        gen page_str = ": " + page if page != "" & page != "."
        replace page_str = "" if page_str == ": ."
        
        * Convert year to string for display
        gen year_str = string(year)
        drop year
        rename year_str year
        
        gen volume_str = string(volume)
        gen number_str = string(number)
        drop volume number
        rename volume_str volume
        rename number_str number
    }
    
    local total_results = _N
}
else {
    * ===== ONLINE SEARCH MODE =====
    dis _n as text "  Searching ... " _c

    preserve //===================preserve begin======

    clear   // added by Yujun Lian, 2025/12/31 16:13
    qui {
        tempfile sj_search_result
        local url_sj "https://www.stata-journal.com/sjsearch.html?choice=`scope'&q=`keywords_url'"
        
        cap copy "`url_sj'" "`sj_search_result'.txt", replace
        if _rc {
            noi dis as error "Failed to connect to Stata Journal website."
            noi dis as error "Please check your internet connection."
            restore
            exit 631
        }
        
        * Use import delimited for better encoding handling
        cap import delimited "`sj_search_result'.txt", delim("@#@") clear varnames(nonames) stringcols(_all)
        if _rc {
            * Fallback to infix if import delimited fails
            cap infix strL v 1-20000 using "`sj_search_result'.txt", clear
            if _rc {
                noi dis as error "Failed to parse search results."
                noi dis as error "Error code: " _rc
                restore
                exit 198
            }
        }
        else {
            * Rename first variable to v for consistency
            rename v1 v
        }
    } // End of online search qui block

    * Continue processing online search results (inside else block)
    qui {
    * Clean the data
    cap drop if v == ""
    keep if regexm(v, ".*<d[td]>.*")
    if _N == 0 {
        noi dis as error "No articles found matching: `keywords'"
        noi dis as text "Try different keywords or search scope."
        restore
        exit
    }
    
    * Extract article information from HTML
    findsj_strget v, gen(art_id) begin(`"article="') end(`"">"')
    findsj_strget v, gen(title) begin(`"">"') end(`"</a></dt>"')
    
    * Extract author and year (first <dd> tag after <dt>)
    gen author_year_raw = ""
    gen n = _n
    forvalues i = 1/`=_N' {
        if art_id[`i'] != "" & `i' < _N {
            if regexm(v[`i'+1], "<dd>(.+)</dd>") {
                qui replace author_year_raw = regexs(1) in `i'
            }
        }
    }
    drop n
    
    * Extract volume and number from HTML (second <dd> tag)
    gen volume_html = ""
    gen number_html = ""
    gen n = _n
    forvalues i = 1/`=_N' {
        if art_id[`i'] != "" & `i' < _N - 1 {
            if regexm(v[`i'+2], "Volume ([0-9]+) Number ([0-9]+)") {
                qui replace volume_html = regexs(1) in `i'
                qui replace number_html = regexs(2) in `i'
            }
        }
    }
    drop n
    
    * Extract year from author_year_raw (format: "Author. Year." or "Author. Year")
    * First, trim whitespace from author_year_raw to ensure clean matching
    replace author_year_raw = strtrim(author_year_raw)
    gen year_from_html = ""
    * Try matching with trailing dot first, then without
    replace year_from_html = regexs(1) if regexm(author_year_raw, "\.[ ]*([0-9]{4})\.?[ ]*$")
    * If no match, try alternative pattern (year at end without preceding dot)
    replace year_from_html = regexs(1) if year_from_html == "" & regexm(author_year_raw, "[ ]([0-9]{4})\.?[ ]*$")
    
    * Clean up extracted data - remove year from author string
    gen author = regexr(author_year_raw, "\.?[ ]*[0-9]{4}\.?[ ]*$", "")
    replace author = strtrim(author)
    * Remove trailing dots and spaces from author
    replace author = regexr(author, "\.[ ]*$", "")
    replace author = author[_n+1] if author == "" & author[_n+1] != ""
    drop author_year_raw
    
    drop v 
    keep if art_id != ""
    gen selected = 1
    local n_results = _N
    
    * Use HTML-extracted data as primary source
    gen volume = volume_html
    gen number = number_html
    gen year = real(year_from_html)
    gen volnum_str = volume + "(" + number + ")" if volume != "" & volume != "."
    gen volnum_url = volume + "-" + number if volume != "" & volume != "."
    
    * Initialize optional fields (will be fetched on-demand if getdoi is specified)
    gen doi = "."
    gen page = "."
    gen volnum = real(volume + "." + number) if volume != "" & volume != "."
    
    keep if selected == 1
    
    * Check if title and author variables exist and clean
    cap confirm variable title
    if _rc == 0 {
        drop if missing(title) | title == "" | title == "."
    }
    else {
        noi dis as error "Failed to extract article titles from search results."
        noi dis as text "Please try again or check your internet connection."
        restore
        exit 198
    }
    
    cap confirm variable author
    if _rc == 0 {
        drop if missing(author) | author == "" | author == "."
    }
    else {
        * If author is missing, create placeholder
        gen author = "Author information not available"
    }
    
    local n_results = _N
    if `n_results' == 0 {
        noi dis as error "No valid articles with complete information."
        restore
        exit
    }
    
    * Clean art_id by manually encoding BOM characters to avoid double encoding
    gen art_id_clean = art_id
    qui replace art_id_clean = subinstr(art_id_clean, "ï»¿", "%EF%BB%BF", .)
    
    local url_base "https://www.stata-journal.com/article.html?article="
    gen url_html = "`url_base'" + art_id_clean
    
    local url_pdf_base "https://journals.sagepub.com/doi/pdf/"
    gen url_pdf = "`url_pdf_base'" + doi if doi != "" & doi != "."
    
    * Page string for display
    gen page_str = ": " + page if page != "" & page != "."
    replace page_str = "" if page_str == ": ."
    
    local total_results = _N
    } // End of online search qui block
} // End of else (online search mode)

* ===== COMMON DISPLAY CODE FOR BOTH ONLINE AND OFFLINE =====
if "`allresults'" != "" local n_display = `total_results'
else local n_display = min(`n', `total_results')

* Display search results summary - removed for cleaner output
local url_sj "https://www.stata-journal.com/sjsearch.html?choice=`scope'&q=`keywords_url'"

* If export format specified, skip displaying search results
if `num_export' > 0 {
    * Save results count but don't display search results
    local n_results = `total_results'
}
else {
    * Save and increase line size to prevent wrapping
    local old_linesize = c(linesize)
    quietly set linesize 255

    local n = `n_display'
    forvalues i = 1/`n' {
    local volnum_i  = volnum_str[`i']
    local author_i  = author[`i']
    local title_i   = title[`i']
    local year_i    = year[`i']
    local art_id_i  = art_id[`i']
    local art_id_clean_i = art_id_clean[`i']
    local url_html_i = url_html[`i']
    
    * Create BOM-free version for Stata commands (search, etc.)
    local art_id_nobom = subinstr("`art_id_i'", "ï»¿", "", .)
    
    * Clean HTML entities in title for display
    local title_display = `"`title_i'"'
    local title_display = subinstr(`"`title_display'"', "&amp;", "&", .)
    local title_display = subinstr(`"`title_display'"', "&ndash;", "-", .)
    local title_display = subinstr(`"`title_display'"', "&mdash;", "--", .)
    local title_display = subinstr(`"`title_display'"', "&lt;", "<", .)
    local title_display = subinstr(`"`title_display'"', "&gt;", ">", .)
    local title_display = subinstr(`"`title_display'"', "&quot;", `"""', .)
    
    * Clean HTML entities in author for display
    local author_display = "`author_i'"
    local author_display = subinstr("`author_display'", "&amp;", "&", .)
    local author_display = subinstr("`author_display'", "&ndash;", "-", .)
    local author_display = subinstr("`author_display'", "&mdash;", "--", .)
    local author_display = subinstr("`author_display'", "&lt;", "<", .)
    local author_display = subinstr("`author_display'", "&gt;", ">", .)
    local author_display = subinstr("`author_display'", "&quot;", `"""', .)
    local author_display = subinstr("`author_display'", "&auml;", "ä", .)
    local author_display = subinstr("`author_display'", "&ouml;", "ö", .)
    local author_display = subinstr("`author_display'", "&uuml;", "ü", .)
    local author_display = subinstr("`author_display'", "&Auml;", "Ä", .)
    local author_display = subinstr("`author_display'", "&Ouml;", "Ö", .)
    local author_display = subinstr("`author_display'", "&Uuml;", "Ü", .)
    local author_display = subinstr("`author_display'", "&aacute;", "á", .)
    local author_display = subinstr("`author_display'", "&eacute;", "é", .)
    local author_display = subinstr("`author_display'", "&iacute;", "í", .)
    local author_display = subinstr("`author_display'", "&oacute;", "ó", .)
    local author_display = subinstr("`author_display'", "&uacute;", "ú", .)
    local author_display = subinstr("`author_display'", "&Aacute;", "Á", .)
    local author_display = subinstr("`author_display'", "&Eacute;", "É", .)
    local author_display = subinstr("`author_display'", "&Iacute;", "Í", .)
    local author_display = subinstr("`author_display'", "&Oacute;", "Ó", .)
    local author_display = subinstr("`author_display'", "&Uacute;", "Ú", .)
    local author_display = subinstr("`author_display'", "&ntilde;", "ñ", .)
    local author_display = subinstr("`author_display'", "&Ntilde;", "Ñ", .)
    local author_display = subinstr("`author_display'", "&agrave;", "à", .)
    local author_display = subinstr("`author_display'", "&egrave;", "è", .)
    local author_display = subinstr("`author_display'", "&igrave;", "ì", .)
    local author_display = subinstr("`author_display'", "&ograve;", "ò", .)
    local author_display = subinstr("`author_display'", "&ugrave;", "ù", .)
    local author_display = subinstr("`author_display'", "&acirc;", "â", .)
    local author_display = subinstr("`author_display'", "&ecirc;", "ê", .)
    local author_display = subinstr("`author_display'", "&icirc;", "î", .)
    local author_display = subinstr("`author_display'", "&ocirc;", "ô", .)
    local author_display = subinstr("`author_display'", "&ucirc;", "û", .)
    local author_display = subinstr("`author_display'", "&ccedil;", "ç", .)
    local author_display = subinstr("`author_display'", "&Ccedil;", "Ç", .)
    local author_display = subinstr("`author_display'", "&aring;", "å", .)
    local author_display = subinstr("`author_display'", "&Aring;", "Å", .)
    local author_display = subinstr("`author_display'", "&oslash;", "ø", .)
    local author_display = subinstr("`author_display'", "&Oslash;", "Ø", .)
    local author_display = subinstr("`author_display'", "&atilde;", "ã", .)
    local author_display = subinstr("`author_display'", "&otilde;", "õ", .)
    
    * First line: Article number and title (use smcl to prevent wrapping)
    dis as text "{p 0 0 0}[" as result `i' as text "] " as result `"`title_display'"' as text "{p_end}"
    
    * Second line: Author, year, and journal info
    dis as text "{p 4 4 4}" as result "`author_display'" as text " (" as result "`year_i'" as text "). " ///
        as text "Stata Journal" _c
    if "`volnum_i'" != "" & "`volnum_i'" != "." {
        dis as text " " as result "`volnum_i'" _c
    }
    
    cap local page_i = page[`i']
    if "`page_i'" != "" & "`page_i'" != "." {
        dis as text ": " as result "`page_i'" _c
    }
    dis as text "{p_end}"
    
    * Get DOI and page info from data file or fetch real-time
    cap local doi_i = doi[`i']
    local has_doi = 0
    if "`doi_i'" != "" & "`doi_i'" != "." {
        local has_doi = 1
    }

    * Priority 1: try to find DOI in a local `findsj.dta' by matching art_id
    * Try several likely locations: current working directory, personal plus, and system plus
    if `has_doi' == 0 {
        qui {
            * Clean art_id for matching (remove BOM if present)
            local art_id_match = subinstr("`art_id_i'", "ï»¿", "", .)
            
            * Build search paths (ado directory has highest priority, cross-platform)
            local search_paths ""
            capture findfile findsj.ado
            if _rc == 0 {
                local ado_fullpath = r(fn)
                local rev_path = reverse("`ado_fullpath'")
                local pos_slash = strpos("`rev_path'", "/")
                local pos_backslash = strpos("`rev_path'", "\")
                local last_sep = 0
                if `pos_slash' > 0 & `pos_backslash' > 0 {
                    local last_sep = min(`pos_slash', `pos_backslash')
                }
                else if `pos_slash' > 0 {
                    local last_sep = `pos_slash'
                }
                else if `pos_backslash' > 0 {
                    local last_sep = `pos_backslash'
                }
                if `last_sep' > 0 {
                    local ado_dir = substr("`ado_fullpath'", 1, length("`ado_fullpath'") - `last_sep' + 1)
                    local search_paths "`ado_dir'"
                }
            }
            local search_paths "`search_paths' `c(sysdir_plus)'f `c(sysdir_plus)' `c(sysdir_personal)' `c(pwd)'"
            foreach p of local search_paths {
                capture confirm file "`p'/findsj.dta"
                if _rc != 0 capture confirm file "`p'findsj.dta"
                if _rc == 0 & `has_doi' == 0 {
                    * Use frame to avoid nested preserve issue (Stata 16+)
                    * Generate unique frame name to avoid conflicts
                    local framename = "findsj_temp_" + string(floor(runiform()*100000))
                    capture {
                        frame create `framename'
                        frame `framename': use "`p'/findsj.dta", clear
                        * Check if artid or art_id variable exists
                        frame `framename' {
                            cap confirm variable artid
                            if _rc == 0 {
                                qui keep if artid == "`art_id_match'"
                                if _N > 0 {
                                    cap local doi_tmp = DOI[1]
                                    if _rc != 0 cap local doi_tmp = doi[1]
                                    if "`doi_tmp'" != "" & "`doi_tmp'" != "." {
                                        local doi_i = "`doi_tmp'"
                                        local has_doi = 1
                                    }
                                }
                            }
                            else {
                                cap confirm variable art_id
                                if _rc == 0 {
                                    qui keep if art_id == "`art_id_match'"
                                    if _N > 0 {
                                        cap local doi_tmp = DOI[1]
                                        if _rc != 0 cap local doi_tmp = doi[1]
                                        cap local page_tmp = page[1]
                                        if "`doi_tmp'" != "" & "`doi_tmp'" != "." {
                                            local doi_i = "`doi_tmp'"
                                            local page_i = "`page_tmp'"
                                            local has_doi = 1
                                        }
                                    }
                                }
                            }
                        }
                        cap frame drop `framename'
                    }
                    * If frame failed (Stata < 16), silently skip local lookup
                }
            }
        }
    }

    * Priority 2 (fallback): if still not found, fetch online automatically
    if `has_doi' == 0 {
        qui {
            cap findsj_doi `art_id_nobom'
            if _rc == 0 {
                local doi_i = r(doi)
                local page_i = r(page)
                if "`doi_i'" != "" & "`doi_i'" != "." {
                    local has_doi = 1
                }
            }
        }
    }
    
    * Display DOI information if getdoi option is specified and DOI is found
    if "`getdoi'" != "" {
        if `has_doi' == 1 {
            dis as text "    DOI: " as result "`doi_i'"
        }
        else {
            dis as text "    DOI: " as error "(not found)"
        }
    }
    
    if "`nobrowser'" == "" {
        dis as text "    " _c
        dis as text `"{browse "`url_html_i'":Web}"' _c
        
        * Display PDF link - use DOI-based URL (only if DOI is available)
        if "`nopdf'" == "" & `has_doi' == 1 {
            local url_pdf_i "https://journals.sagepub.com/doi/pdf/`doi_i'"
            dis as text " | " _c
            dis as text `"{browse "`url_pdf_i'":PDF}"' _c
        }
        
        * Display Google Scholar link
        local title_search = subinstr(`"`title_i'"', " ", "+", .)
        local title_search = subinstr(`"`title_search'"', "&amp;", "%26", .)
        local title_search = subinstr(`"`title_search'"', "&ndash;", "-", .)
        local url_google "https://scholar.google.com/scholar?q=`title_search'"
        dis as text " | " _c
        dis as text `"{browse "`url_google'":Google}"' _c
        
        * Add package search on same line
        if "`nopkg'" == "" {
            dis as text " | " _c
            dis as text `"{stata "search `art_id_nobom'":Install}"' _c
        }
        
        * Display .md .latex .txt buttons (citation formats) using getiref with DOI
        if `has_doi' == 1 {
            dis as text "  |  " _c
            dis as text `"{stata "getiref `doi_i', md":.md}"' _c
            dis as text " | " _c
            dis as text `"{stata "getiref `doi_i', latex":.latex}"' _c
            dis as text " | " _c
            dis as text `"{stata "getiref `doi_i', text":.txt}"' _c
        }
        
        * Display BibTeX and RIS buttons (on-demand download via helper program)
        dis as text " | " _c
        dis as text `"{stata "findsj `art_id_nobom', type(bib)":BibTeX}"' _c
        dis as text " | " _c
        dis as text `"{stata "findsj `art_id_nobom', type(ris)":RIS}"'
    }
    else {
        dis ""  // End line if nobrowser
    }
    
    * ref option is deprecated - citation buttons are now directly available in main button row
    
}


* Restore original line size
quietly set linesize `old_linesize'

* Save total number of displayed results
global findsj_n_display `n_display'

if `total_results' > `n_display' {
    dis _n as text "Showing " as result "`n_display'" as text " of " _c
    dis as text `"{stata "findsj `keywords', allresults":`total_results'}"' as text " results. " _c
    dis as text "(" `"{browse "`url_sj'":web}"' as text ")"
}

* Note: Batch clipboard copy removed. Users can click individual "Ref" buttons to copy citations.
* This provides better user experience and avoids command-line length limitations.

} // End of else block for non-export display

* Common return values
local n_results = `total_results'

return local keywords   = "`keywords'"
return local scope      = "`scope'"
return local url        = "`url_sj'"
return scalar n_results = `n_results'

if `n_results' > 0 {
    return local art_id_1  = art_id[1]
    return local title_1   = title[1]
    return local author_1  = author[1]
    cap return local doi_1 = doi[1]
    return local url_1     = url_html[1]
}

restore    //==================preserve over=================



* Display search completion message only if not exporting
* Simplified: removed redundant messages per user request
if `num_export' == 0 & `total_results' <= `n_display' {
    * Only show summary when all results are displayed
    dis _n as text "Showing " as result "`n_display'" as text " of " as result "`total_results'" as text " results. " _c
    dis as text "(" `"{browse "`url_sj'":web}"' as text ")"
}

* Generate formatted citations if export format specified
if `num_export' > 0 {
    
    * ===== OFFLINE EXPORT: Use local database directly =====
    if `use_offline' == 1 {
        preserve
        qui {
            use "`dta_path'", clear
            
            * Normalize variable names
            cap confirm variable artid
            if _rc == 0 {
                rename artid art_id
            }
            cap confirm variable DOI
            if _rc == 0 {
                rename DOI doi
            }
            cap confirm variable authors
            if _rc == 0 {
                rename authors author
            }
            
            * Perform search (same as display mode - includes abstract and abbreviation expansion)
            gen title_lower = lower(title)
            gen author_lower = lower(author)
            gen abstract_lower = lower(abstract)
            local keywords_lower = lower(`"`keywords'"')
            local keywords_clean : subinstr local keywords_lower "  " " ", all
            local keywords_clean = strtrim("`keywords_clean'")
            
            * Check for abbreviation expansion
            local keywords_upper = upper("`keywords_clean'")
            local expanded_keywords = ""
            local is_abbreviation = 0
            
            if "`keywords_upper'" == "PSM" {
                local expanded_keywords "propensity score"
                local is_abbreviation = 1
            }
            else if "`keywords_upper'" == "IV" {
                local expanded_keywords "instrumental variable"
                local is_abbreviation = 1
            }
            else if "`keywords_upper'" == "DID" | "`keywords_upper'" == "DD" {
                local expanded_keywords "difference in differences"
                local is_abbreviation = 1
            }
            else if "`keywords_upper'" == "RDD" | "`keywords_upper'" == "RD" {
                local expanded_keywords "regression discontinuity"
                local is_abbreviation = 1
            }
            else if "`keywords_upper'" == "GMM" {
                local expanded_keywords "generalized method of moments"
                local is_abbreviation = 1
            }
            else if "`keywords_upper'" == "VAR" {
                local expanded_keywords "vector autoregression"
                local is_abbreviation = 1
            }
            
            local n_words = wordcount(`"`keywords_clean'"')
            
            gen match_priority = .
            gen matched = 0
            
            * First pass: exact match
            if "`scope'" == "author" {
                local first_word = word(`"`keywords_clean'"', 1)
                replace matched = 1 if strpos(author_lower, "`first_word'") > 0
                replace match_priority = 1 if matched == 1
            }
            else if "`scope'" == "keyword" {
                gen temp_match = 1
                forvalues i = 1/`n_words' {
                    local word = word(`"`keywords_clean'"', `i')
                    replace temp_match = 0 if strpos(title_lower, "`word'") == 0 & ///
                                              strpos(author_lower, "`word'") == 0 & ///
                                              strpos(abstract_lower, "`word'") == 0
                }
                replace matched = 1 if temp_match == 1
                replace match_priority = 1 if matched == 1
                drop temp_match
            }
            else if "`scope'" == "title" {
                gen temp_match = 1
                forvalues i = 1/`n_words' {
                    local word = word(`"`keywords_clean'"', `i')
                    replace temp_match = 0 if strpos(title_lower, "`word'") == 0
                }
                replace matched = 1 if temp_match == 1
                replace match_priority = 1 if matched == 1
                drop temp_match
            }
            
            * Second pass: expanded keywords
            if `is_abbreviation' == 1 & "`scope'" == "keyword" {
                local n_expanded = wordcount(`"`expanded_keywords'"')
                gen temp_match = 1
                forvalues i = 1/`n_expanded' {
                    local word = word(`"`expanded_keywords'"', `i')
                    replace temp_match = 0 if strpos(title_lower, "`word'") == 0 & ///
                                              strpos(author_lower, "`word'") == 0 & ///
                                              strpos(abstract_lower, "`word'") == 0
                }
                replace matched = 1 if temp_match == 1 & matched == 0
                replace match_priority = 2 if temp_match == 1 & match_priority == .
                drop temp_match
            }
            
            keep if matched == 1
            drop matched title_lower author_lower abstract_lower
            gsort match_priority -year -volume -number
            drop match_priority
            
            if _N == 0 {
                noi dis as error "No articles found."
                restore
                exit
            }
            
            * Create URL variables
            local url_base "https://www.stata-journal.com/article.html?article="
            gen art_id_clean = art_id
            qui replace art_id_clean = subinstr(art_id_clean, "ï»¿", "%EF%BB%BF", .)
            gen url_html = "`url_base'" + art_id_clean
            
            local url_pdf_base "https://journals.sagepub.com/doi/pdf/"
            gen url_pdf = "`url_pdf_base'" + doi if doi != "" & doi != "."
            
            gen volnum_str = string(volume) + "(" + string(number) + ")"
            
            * Clean HTML entities in title
            replace title = subinstr(title, "&amp;", "&", .)
            replace title = subinstr(title, "&ndash;", "-", .)
            replace title = subinstr(title, "&mdash;", "--", .)
            replace title = subinstr(title, "&lt;", "<", .)
            replace title = subinstr(title, "&gt;", ">", .)
            replace title = subinstr(title, "&quot;", char(34), .)
            
            gen title_for_url = subinstr(title, " ", "%20", .)
            gen url_google = "https://scholar.google.com/scholar?q=" + title_for_url
            
            gen title_display = proper(title)
            
            * Limit to n results
            if "`allresults'" == "" {
                local actual_n = _N
                if `actual_n' > `n' {
                    keep in 1/`n'
                }
            }
            
            * Use citation_apa directly (it exists in the database)
            cap confirm variable citation_apa
            local use_citation_apa = 0
            if _rc == 0 {
                qui count if citation_apa != "" & citation_apa != "."
                if r(N) > 0 {
                    local use_citation_apa = 1
                }
            }
            
            if `use_citation_apa' == 1 {
                * Use citation_apa from database
                if "`md'" != "" {
                    gen cite_text = citation_apa + " [Link](" + url_html + ")"
                    if "`nopdf'" == "" replace cite_text = cite_text + ", [PDF](" + url_pdf + ")" if url_pdf != "" & url_pdf != "."
                    replace cite_text = cite_text + ", [Google](<" + url_google + ">)"
                }
                else if "`latex'" != "" {
                    gen cite_text = citation_apa + " \\href{" + url_html + "}{Link}"
                    if "`nopdf'" == "" replace cite_text = cite_text + ", \\href{" + url_pdf + "}{PDF}" if url_pdf != "" & url_pdf != "."
                    replace cite_text = cite_text + ", \\href{" + url_google + "}{Google}"
                }
                else if "`plain'" != "" {
                    gen cite_text = citation_apa + " Link: " + url_html
                    if "`nopdf'" == "" replace cite_text = cite_text + ", PDF: " + url_pdf if url_pdf != "" & url_pdf != "."
                    replace cite_text = cite_text + ", Google: " + url_google
                }
            }
            else {
                * Fallback: generate citations manually
                tostring year, replace
                if "`md'" != "" {
                    gen cite_text = author + " (" + year + "). " + title_display + ". The Stata Journal, " + volnum_str + ". "
                    replace cite_text = cite_text + "[Link](" + url_html + ")"
                    if "`nopdf'" == "" replace cite_text = cite_text + ", [PDF](" + url_pdf + ")" if url_pdf != "" & url_pdf != "."
                    replace cite_text = cite_text + ", [Google](<" + url_google + ">)"
                }
                else if "`latex'" != "" {
                    gen cite_text = author + " (" + year + "). " + title_display + ". The Stata Journal, " + volnum_str + ". "
                    replace cite_text = cite_text + "\\href{" + url_html + "}{Link}"
                    if "`nopdf'" == "" replace cite_text = cite_text + ", \\href{" + url_pdf + "}{PDF}" if url_pdf != "" & url_pdf != "."
                    replace cite_text = cite_text + ", \\href{" + url_google + "}{Google}"
                }
                else if "`plain'" != "" {
                    gen cite_text = author + " (" + year + "). " + title_display + ". The Stata Journal, " + volnum_str + ". "
                    replace cite_text = cite_text + "Link: " + url_html
                    if "`nopdf'" == "" replace cite_text = cite_text + ", PDF: " + url_pdf if url_pdf != "" & url_pdf != "."
                    replace cite_text = cite_text + ", Google: " + url_google
                }
            }
            
            * Save citations to local macros
            local n_cite = _N
            forvalues i = 1/`n_cite' {
                local cite_`i' = cite_text[`i']
            }
            
            global findsj_n_cite `n_cite'
            
            * Combine all citations for clipboard
            gen cite_combined = "1. " + cite_text[1] if _n == 1
            forvalues i = 2/`n_cite' {
                qui replace cite_combined = cite_combined + char(10) + "`i'. " + cite_text[`i'] in 1
            }
            local all_cites = cite_combined[1]
            global findsj_all_citations `"`all_cites'"'
            
            * Export to file
            if "`md'" != "" local fn_suffix ".md"
            else if "`latex'" != "" local fn_suffix ".txt"
            else if "`plain'" != "" local fn_suffix ".txt"
            
            local saving "_findsj_temp_out_`fn_suffix'"
            local save_path "`c(pwd)'"
            local save_path = subinstr("`save_path'", "\", "/", .)
            
            qui export delimited cite_text using "`save_path'/`saving'", novar nolabel noq replace
            
            global findsj_export_path "`save_path'"
            global findsj_export_file "`saving'"
        }
        
        * Display results
        local n_cite = $findsj_n_cite
        
        noi dis _n as text "{hline 60}"
        if "`md'" != "" noi dis as text "  Markdown format:"
        else if "`latex'" != "" noi dis as text "  LaTeX format:"
        else if "`plain'" != "" noi dis as text "  Plain text format:"
        noi dis as text "{hline 60}" _n
        
        forvalues i = 1/`n_cite' {
            noi dis `"`i'. `cite_`i''"'
        }
        noi dis ""
        
        * Copy to clipboard
        if "`noclip'" == "" {
            local all_cites "$findsj_all_citations"
            findsj_clipout `"`all_cites'"'
        }
        
        * Display file actions
        local file_path "$findsj_export_path"
        local file_name "$findsj_export_file"
        local full_path "`file_path'/`file_name'"
        
        noi dis _dup(58) "-"
        noi dis _col(3) as text `"{stata `"view "`full_path'""':View}"' _col(15) as text `"{stata `"shell open "`file_path'""':Open_Mac}"' _col(30) as text `"{stata `"shell explorer /select,"`full_path'""':Open_Win}"' _c
        
        if "`c(os)'" == "Windows" {
            noi dis _col(48) as text `"{stata `"shell explorer /select,"`full_path'""':dir}"'
        }
        else {
            noi dis _col(48) as text `"{stata `"shell open "`file_path'""':dir}"'
        }
        noi dis _dup(58) "-"
        
        * Clean up globals
        global findsj_export_path ""
        global findsj_export_file ""
        global findsj_all_citations ""
        global findsj_n_cite ""
        
        restore
    }
    else {
    * ===== ONLINE EXPORT: Fetch from website =====
    preserve
	clear      // added by Yujun Lian, 2025/12/31 16:14
    qui {
        tempfile sj_search_result
        local url_sj "https://www.stata-journal.com/sjsearch.html?choice=`scope'&q=`keywords_url'"
        
        cap copy "`url_sj'" "`sj_search_result'.txt", replace
        if _rc == 0 {
            cap import delimited "`sj_search_result'.txt", delim("@#@") clear varnames(nonames) stringcols(_all)
            if _rc {
                cap infix strL v 1-20000 using "`sj_search_result'.txt", clear
            }
            else {
                rename v1 v
            }
            
            if _rc == 0 {
                cap drop if v == ""
                keep if regexm(v, ".*<d[td]>.*")
                
                if _N > 0 {
                    findsj_strget v, gen(art_id) begin(`"article="') end(`"">"')
                    findsj_strget v, gen(title) begin(`"">"') end(`"</a></dt>"')
                    
                    gen author_year_raw = ""
                    gen n = _n
                    forvalues i = 1/`=_N' {
                        if art_id[`i'] != "" & `i' < _N {
                            if regexm(v[`i'+1], "<dd>(.+)</dd>") {
                                qui replace author_year_raw = regexs(1) in `i'
                            }
                        }
                    }
                    drop n
                    
                    gen volume_html = ""
                    gen number_html = ""
                    gen n = _n
                    forvalues i = 1/`=_N' {
                        if art_id[`i'] != "" & `i' < _N - 1 {
                            if regexm(v[`i'+2], "Volume ([0-9]+) Number ([0-9]+)") {
                                qui replace volume_html = regexs(1) in `i'
                                qui replace number_html = regexs(2) in `i'
                            }
                        }
                    }
                    drop n
                    
                    * Extract year - handle both "Author. Year." and "Author. Year" formats
                    replace author_year_raw = strtrim(author_year_raw)
                    gen year = ""
                    replace year = regexs(1) if regexm(author_year_raw, "\.[ ]*([0-9]{4})\.?[ ]*$")
                    replace year = regexs(1) if year == "" & regexm(author_year_raw, "[ ]([0-9]{4})\.?[ ]*$")
                    
                    gen author = regexr(author_year_raw, "\.?[ ]*[0-9]{4}\.?[ ]*$", "")
                    replace author = strtrim(author)
                    replace author = regexr(author, "\.[ ]*$", "")
                    
                    drop v author_year_raw
                    keep if art_id != ""
                    
                    gen volume = volume_html
                    gen number = number_html
                    gen volnum_str = volume + "(" + number + ")" if volume != "" & volume != "."
                    
                    local url_base "https://www.stata-journal.com/article.html?article="
                    gen art_id_clean = art_id
                    qui replace art_id_clean = subinstr(art_id_clean, "ï»¿", "%EF%BB%BF", .)
                    gen url_html = "`url_base'" + art_id_clean
                    
                    * Try to get DOI for PDF links from local database
                    gen doi = "."
                    gen page = "."
                    
                    * Simplified DOI lookup: merge with local database if available
                    * Build search paths (ado directory has highest priority, cross-platform)
                    local search_paths ""
                    capture findfile findsj.ado
                    if _rc == 0 {
                        local ado_fullpath = r(fn)
                        local rev_path = reverse("`ado_fullpath'")
                        local pos_slash = strpos("`rev_path'", "/")
                        local pos_backslash = strpos("`rev_path'", "\")
                        local last_sep = 0
                        if `pos_slash' > 0 & `pos_backslash' > 0 {
                            local last_sep = min(`pos_slash', `pos_backslash')
                        }
                        else if `pos_slash' > 0 {
                            local last_sep = `pos_slash'
                        }
                        else if `pos_backslash' > 0 {
                            local last_sep = `pos_backslash'
                        }
                        if `last_sep' > 0 {
                            local ado_dir = substr("`ado_fullpath'", 1, length("`ado_fullpath'") - `last_sep' + 1)
                            local search_paths "`ado_dir'"
                        }
                    }
                    local search_paths "`search_paths' `c(sysdir_plus)'f `c(sysdir_plus)' `c(sysdir_personal)' `c(pwd)'"
                    local found_db = 0
                    foreach p of local search_paths {
                        if `found_db' == 0 {
                            capture confirm file "`p'/findsj.dta"
                            if _rc != 0 capture confirm file "`p'findsj.dta"
                            if _rc == 0 {
                                tempfile current_data
                                save "`current_data'", replace
                                
                                capture {
                                    use "`p'/findsj.dta", clear
                                    cap confirm variable art_id
                                    if _rc == 0 {
                                        keep art_id DOI page citation_apa
                                        cap rename DOI doi
                                        replace art_id = subinstr(art_id, "ï»¿", "", .)
                                        tempfile doi_data
                                        save "`doi_data'", replace
                                        
                                        use "`current_data'", clear
                                        merge 1:1 art_id using "`doi_data'", update replace nogen keep(master match)
                                        local found_db = 1
                                    }
                                    else {
                                        cap confirm variable artid
                                        if _rc == 0 {
                                            keep artid DOI citation_apa
                                            cap rename DOI doi
                                            cap gen page = "."
                                            rename artid art_id
                                            replace art_id = subinstr(art_id, "ï»¿", "", .)
                                            tempfile doi_data
                                            save "`doi_data'", replace
                                            
                                            use "`current_data'", clear
                                            merge 1:1 art_id using "`doi_data'", update replace nogen keep(master match)
                                            local found_db = 1
                                        }
                                        else {
                                            use "`current_data'", clear
                                        }
                                    }
                                }
                                if _rc != 0 {
                                    use "`current_data'", clear
                                }
                            }
                        }
                    }
                    
                    local url_pdf_base "https://journals.sagepub.com/doi/pdf/"
                    gen url_pdf = "`url_pdf_base'" + doi if doi != "" & doi != "."
                    gen page_str = ": " + page if page != "" & page != "."
                    replace page_str = "" if page_str == ": ."
                    
                    * Clean HTML entities in title BEFORE generating Google link
                    replace title = subinstr(title, "&amp;", "&", .)
                    replace title = subinstr(title, "&ndash;", "-", .)
                    replace title = subinstr(title, "&mdash;", "--", .)
                    replace title = subinstr(title, "&lt;", "<", .)
                    replace title = subinstr(title, "&gt;", ">", .)
                    replace title = subinstr(title, "&quot;", char(34), .)
                    
                    * Generate Google Scholar link (simplified - use space for now)
                    gen title_for_url = subinstr(title, " ", "%20", .)
                    gen url_google = "https://scholar.google.com/scholar?q=" + title_for_url
                    
                    * Convert author format: "N. J. Cox" -> "Cox, N. J."
                    * Use word() function to extract last word (surname)
                    gen author_getiref = ""
                    gen n_words = wordcount(author)
                    * Get last word (surname) - remove trailing period if exists
                    gen lastname = word(author, n_words)
                    replace lastname = subinstr(lastname, ".", "", .) if substr(lastname, -1, 1) == "."
                    * Get everything before last word (first/middle names)
                    gen firstname = ""
                    replace firstname = substr(author, 1, length(author) - length(word(author, n_words)) - 1)
                    replace firstname = strtrim(firstname)
                    * Combine as "Lastname, Firstname"
                    replace author_getiref = lastname + ", " + firstname if firstname != ""
                    replace author_getiref = lastname if firstname == ""
                    drop n_words lastname firstname
                    
                    * Title case for title (capitalize first letter of each major word)
                    gen title_display = proper(title)
                    
                    * Limit to display count
                    if "`allresults'" == "" {
                        * Get actual number of results
                        local actual_n = _N
                        * Keep only min(n, actual_n) results
                        if `actual_n' > `n' {
                            keep in 1/`n'
                        }
                    }
                    
                    * Generate formatted citations using local citation_apa field
                    * Check if citation_apa field exists in database AND has non-empty values
                    cap confirm variable citation_apa
                    local use_citation_apa = 0
                    if _rc == 0 {
                        * Check if any citation_apa values are non-empty
                        qui count if citation_apa != "" & citation_apa != "."
                        if r(N) > 0 {
                            local use_citation_apa = 1
                        }
                    }
                    
                    if `use_citation_apa' == 1 {
                        * Use citation_apa from database with added links
                        if "`md'" != "" {
                            gen cite_text = citation_apa + " [Link](" + url_html + ")"
                            if "`nopdf'" == "" replace cite_text = cite_text + ", [PDF](" + url_pdf + ")" if url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ", [Google](<" + url_google + ">)"
                        }
                        else if "`latex'" != "" {
                            gen cite_text = citation_apa + " \\href{" + url_html + "}{Link}"
                            if "`nopdf'" == "" replace cite_text = cite_text + ", \\href{" + url_pdf + "}{PDF}" if url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ", \\href{" + url_google + "}{Google}"
                        }
                        else if "`plain'" != "" {
                            gen cite_text = citation_apa + " Link: " + url_html
                            if "`nopdf'" == "" replace cite_text = cite_text + ", PDF: " + url_pdf if url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ", Google: " + url_google
                        }
                    }
                    else {
                        * Fallback: Generate citations manually (old method)
                        if "`md'" != "" {
                            gen cite_text = author_getiref + " (" + year + "). " + title_display + ". The Stata Journal, " + volnum_str
                            replace cite_text = cite_text + ", " + page if page != "" & page != "."
                            replace cite_text = cite_text + ". "
                            replace cite_text = cite_text + "[Link](" + url_html + ")"
                            if "`nopdf'" == "" replace cite_text = cite_text + ", [PDF](" + url_pdf + ")" if url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ", [Google](<" + url_google + ">)"
                        }
                        else if "`latex'" != "" {
                            gen cite_text = author_getiref + " (" + year + "). " + title_display + ". The Stata Journal, " + volnum_str
                            replace cite_text = cite_text + ", " + page if page != "" & page != "."
                            replace cite_text = cite_text + ". "
                            replace cite_text = cite_text + "\\href{" + url_html + "}{Link}"
                            if "`nopdf'" == "" replace cite_text = cite_text + ", \\href{" + url_pdf + "}{PDF}" if url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ", \\href{" + url_google + "}{Google}"
                        }
                        else if "`plain'" != "" {
                            gen cite_text = author_getiref + " (" + year + "). " + title_display + ". The Stata Journal, " + volnum_str
                            replace cite_text = cite_text + ", " + page if page != "" & page != "."
                            replace cite_text = cite_text + ". "
                            replace cite_text = cite_text + "Link: " + url_html
                            if "`nopdf'" == "" replace cite_text = cite_text + ", PDF: " + url_pdf if url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ", Google: " + url_google
                        }
                    }
                    
                    * Save citations to local macros for later display
                    local n_cite = _N
                    forvalues i = 1/`n_cite' {
                        local cite_`i' = cite_text[`i']
                    }
                    
                    * Save n_cite to global for use outside qui block
                    global findsj_n_cite `n_cite'
                    
                    * Combine all citations for clipboard
                    * Generate a single string with line breaks by concatenating cite_text
                    gen cite_combined = "1. " + cite_text[1] if _n == 1
                    forvalues i = 2/`n_cite' {
                        qui replace cite_combined = cite_combined + char(10) + "`i'. " + cite_text[`i'] in 1
                    }
                    local all_cites = cite_combined[1]
                    
                    * Save combined citations to global for clipboard
                    global findsj_all_citations `"`all_cites'"'
                    
                    * Save to file
                    * Determine file extension and save path
                    if "`md'" != "" local fn_suffix ".md"
                    else if "`latex'" != "" local fn_suffix ".txt"
                    else if "`plain'" != "" local fn_suffix ".txt"
                    
                    local saving "_findsj_temp_out_`fn_suffix'"
                    
                    * Get save path (use current working directory)
                    local save_path "`c(pwd)'"
                    local save_path = subinstr("`save_path'", "\", "/", .)
                    
                    * Export citations to file
                    qui export delimited cite_text using "`save_path'/`saving'", ///
                        novar nolabel delimiter(tab) replace
                    
                    * Save file location info to global (will be cleaned up later)
                    global findsj_export_path "`save_path'"
                    global findsj_export_file "`saving'"
                }
            }
        }
    }
    
    * Display formatted citations (outside qui block)
    if `num_export' > 0 {
        * Get actual citation count from global
        local n_cite = $findsj_n_cite
        
        noi dis _n as text "{hline 60}"
        if "`md'" != ""	noi dis as text "  Markdown format:"
        else if "`latex'" != "" noi dis as text "  LaTeX format:"
        else if "`plain'" != "" noi dis as text "  Plain text format:"
        noi dis as text "{hline 60}" _n
        
        forvalues i = 1/`n_cite' {
            noi dis `"`i'. `cite_`i''"'
            noi dis ""
        }
        
        *noi dis as text "{hline 60}" _n
        
        * Copy to clipboard (unless noclip specified)
        if "`noclip'" == "" {
            * Get combined citations from global
            local all_cites "$findsj_all_citations"
            * Call clipboard function
            findsj_clipout `"`all_cites'"'
        }
        
        * Display file location with four buttons (View/Open_Mac/Open_Win/dir)
        * Use globals saved from qui block
        local file_path "$findsj_export_path"
        local file_name "$findsj_export_file"
        local full_path "`file_path'/`file_name'"
        
        noi dis " "
        noi dis _dup(58) "-"
        * Show first 3 buttons
        noi dis _col(3)  as text `"{stata `"view "`full_path'""':View}"' ///
                _col(15) as text `"{stata `"shell open "`full_path'""':Open_Mac}"' ///
                _col(30) as text `"{stata `"shell start "" "`full_path'""':Open_Win}"' _c
        * Show dir button based on OS
        if "`c(os)'" == "Windows" {
            noi dis _col(48) as text `"{stata `"shell explorer /select,"`full_path'""':dir}"'
        }
        else {
            noi dis _col(48) as text `"{stata `"shell open "`file_path'""':dir}"'
        }
        noi dis _dup(58) "-"
        
        * Clean up globals
        global findsj_export_path ""
        global findsj_export_file ""
        global findsj_all_citations ""
        global findsj_n_cite ""
    }
    
    restore
    } // End of else (online export mode)
} // End of if num_export > 0

if "`debug'" != "" set trace off

end

*==========================================
* SUB-PROGRAMS
*==========================================

// cap program drop findsj_show_ref
program define findsj_show_ref
    version 14
    args art_id
    
    * Clean art_id (remove BOM if present)
    local art_id_clean = subinstr("`art_id'", "ï»¿", "", .)
    
    dis as text _n "{hline 70}"
    dis as text "Article ID: " as result "`art_id_clean'"
    dis as text "{hline 70}" _n
    
    * Try to get DOI - Priority 1: local database
    local doi ""
    local has_doi = 0
    
    qui {
        * Build search paths (ado directory has highest priority)
        * Build search paths (ado directory has highest priority, cross-platform)
        local search_paths ""
        capture findfile findsj.ado
        if _rc == 0 {
            local ado_fullpath = r(fn)
            local rev_path = reverse("`ado_fullpath'")
            local pos_slash = strpos("`rev_path'", "/")
            local pos_backslash = strpos("`rev_path'", "\")
            local last_sep = 0
            if `pos_slash' > 0 & `pos_backslash' > 0 {
                local last_sep = min(`pos_slash', `pos_backslash')
            }
            else if `pos_slash' > 0 {
                local last_sep = `pos_slash'
            }
            else if `pos_backslash' > 0 {
                local last_sep = `pos_backslash'
            }
            if `last_sep' > 0 {
                local ado_dir = substr("`ado_fullpath'", 1, length("`ado_fullpath'") - `last_sep' + 1)
                local search_paths "`ado_dir'"
            }
        }
        local search_paths "`search_paths' `c(sysdir_plus)'f `c(sysdir_plus)' `c(sysdir_personal)' `c(pwd)'"
        foreach p of local search_paths {
            if `has_doi' == 0 {
                capture confirm file "`p'/findsj.dta"
                if _rc != 0 capture confirm file "`p'findsj.dta"
                if _rc == 0 {
                    * Use frame to avoid nested preserve issue (Stata 16+)
                    local framename = "findsj_temp_" + string(floor(runiform()*100000))
                    capture {
                        frame create `framename'
                        frame `framename': use "`p'/findsj.dta", clear
                        frame `framename' {
                            cap confirm variable artid
                            if _rc == 0 {
                                qui keep if artid == "`art_id_clean'"
                                if _N > 0 {
                                    cap local doi_tmp = DOI[1]
                                    if _rc != 0 cap local doi_tmp = doi[1]
                                    if "`doi_tmp'" != "" & "`doi_tmp'" != "." {
                                        local doi = "`doi_tmp'"
                                        local has_doi = 1
                                    }
                                }
                            }
                            else {
                                cap confirm variable art_id
                                if _rc == 0 {
                                    qui keep if art_id == "`art_id_clean'"
                                    if _N > 0 {
                                        cap local doi_tmp = DOI[1]
                                        if _rc != 0 cap local doi_tmp = doi[1]
                                        if "`doi_tmp'" != "" & "`doi_tmp'" != "." {
                                            local doi = "`doi_tmp'"
                                            local has_doi = 1
                                        }
                                    }
                                }
                            }
                        }
                        cap frame drop `framename'
                    }
                }
            }
        }
    }
    
    * Priority 2: fetch online
    if `has_doi' == 0 {
        dis as text "Fetching DOI information online..." _n
        qui {
            cap findsj_doi `art_id_clean'
            if _rc == 0 {
                local doi = r(doi)
                if "`doi'" != "" & "`doi'" != "." {
                    local has_doi = 1
                }
            }
        }
    }
    
    * Display citation buttons or error message
    if `has_doi' == 1 {
        dis as text "Cite: " _c
        dis as text `"{stata "getiref `doi', md":.md}"' _c
        dis as text " | " _c
        dis as text `"{stata "getiref `doi', latex":.latex}"' _c
        dis as text " | " _c
        dis as text `"{stata "getiref `doi', text":.txt}"'
    }
    else {
        dis as text "" as error "(No DOI found)" as text " - Try: " _c
        dis as text `"{stata "findsj, updatesource source(both)":Update database}"'
    }
    
    dis as text "{hline 70}" _n
end


// cap program drop findsj_strget   
program define findsj_strget, rclass 
version 14 
  syntax varname, Generate(string) [Begin(string) Endwith(string) Match(string) Jthmatch(integer 1)]
  
  cap noi confirm new variable `generate'
  if `jthmatch' < 0 {
      dis as error "'#' in -jthmatch(#)- must be nonnegative."
      exit 198
  }
  if `"`match'"' == "" local match ".*"
  local regex `"(?<=`begin')(`match')(?=`endwith')"'  
  qui gen `generate' = ustrregexs(`jthmatch') if ustrregexm(`varlist', `"`regex'"') 
  qui count if `generate'!=""
  if r(N) == 0 dis `"Note: nothing matched. Try different patterns."'
end   

// cap program drop findsj_current
program define findsj_current, rclass
version 14
qui {
preserve
  tempvar v VolNum vol num volnum
  tempname matrix_vn 
  local fn "sjarchive"
  local url_fn "https://www.stata-journal.com/archives/"    
  cap copy "`url_fn'" "`fn'.txt", replace
  if _rc == 0 {
      infix strL `v' 1-1000 using "`fn'.txt", clear
      local begin   `"<b><a href="http://fmwww.bc.edu/sj"'
      local endwith `".html"'
      local regex `"(?<=`begin')(.*)(?=`endwith')"'  
      gen `VolNum' = ustrregexs(1) if ustrregexm(`v', `"`regex'"')
      keep if `VolNum' != "" 
      if _N > 0 {
          split `VolNum', parse("-") destring
          gen `volnum' = `VolNum'1 + `VolNum'2/10
          mkmat `VolNum'1 `VolNum'2 `volnum', mat(`matrix_vn')  
          mat colnames `matrix_vn' = vol num volnum
          return matrix all = `matrix_vn'
          qui keep in 1
          local volnum_str = `VolNum'[1]
          tokenize `volnum_str', parse(-)
          return local volnum "`volnum_str'"
          return scalar vol = `1'
          return scalar num = `3'
          return scalar vn  = `=`1'.`3''
      }
  }
restore
}
end

// cap program drop findsj_doi   
program define findsj_doi, rclass
version 14
args art_id
preserve 
qui {
  local art_url "https://www.stata-journal.com/article.html?article=`art_id'"
  tempfile sj_art
  copy "`art_url'"  "`sj_art'.txt" , replace   
  tempvar v
  infix strL `v' 1-1000 using "`sj_art'.txt", clear
  keep if regexm(`v', "^pp.") | strpos(`v',"doi/pdf/") 
  local regex `"(?<=doi/pdf/)(.*)(?=">)"' 
  gen doi  = ustrregexs(1) if ustrregexm(`v', `"`regex'"')
  replace doi = "." if doi==""
  local regex `"(?<=pp. )(.*)(?=</span)"' 
  gen page = ustrregexs(1) if ustrregexm(`v', `"`regex'"')
  local doi  =  doi[2]
  local page = page[1]
  ret local id  = "`art_id'"
  ret local doi = "`doi'"
  ret local page= "`page'"
}
restore 
end

// cap program drop findsj_volnum
program define findsj_volnum, rclass
version 14
  syntax, Volume(integer) Number(integer) [More]
preserve 
qui{	
  local vol = `volume'
  local num = `number'
  local sjlink "https://www.stata-journal.com/sj"
  local url "`sjlink'`vol'-`num'.html" 
  local fn "sj`vol'_`num'"
  tempfile sjFILE
  copy "`url'"  "`sjFILE'.txt" , replace
  infix strL v 1-1000 using "`sjFILE'.txt", clear
  keep if regexm(v, ".*<d[td]>.*")
  findsj_strget v, gen(title)  begin(`"">"')     end(`"</a></dt>"')
  findsj_strget v, gen(author) begin(`"<dd>"')   end(`"</dd>"')
  findsj_strget v, gen(DOI)    begin("doi/pdf/") end(`"">"') 
  replace author = author[_n+1] if author==""
  drop if title == ""
  replace author = "" if author=="&nbsp;"
  if "`more'" !=""{
  	  gen year   = 2000 + `vol' 
  	  gen volume = `vol'
	  gen number = `num'
  } 
  drop v
  save "`fn'.dta", replace	
  return scalar vol = `vol'      
  return scalar num = `num'      
  return local data = "`fn'.dta" 
}
restore  
end

// cap program drop findsj_frmark
program define findsj_frmark
version 16 
  qui pwf
  global Frame__User__ = r(currentframe)
end

// cap program drop findsj_frback
program define findsj_frback
version 16
  cap frame change $Frame__User__
  if _rc {
  	  dis as error "Nothing to back. Use {help findsj_frmark} first."
	  exit
  }
  macro drop Frame__User__
end

// cap program drop findsj_sjarchive
program define findsj_sjarchive, rclass
version 14
  syntax [, Saving(string)]
preserve 
qui{	
  tempfile sjarc 
  local url "https://www.stata-journal.com/archives/"    
  copy "`url'"  "`sjarc'.txt" , replace
  infix strL v 1-1000 using "`sjarc'.txt", clear
  local begin `"<b><a href="http://fmwww.bc.edu/sj"'
  local end   `".html"'
  local match ".*"
  local regex `"(?<=`begin')(`match')(?=`end')"'  
  qui gen VolNum = ustrregexs(1) if ustrregexm(v, `"`regex'"') 
  keep if VolNum != "" 
  split VolNum, parse(-) gen(x) destring
  rename (x1 x2) (vol num)
  drop v	
  return local archive "https://www.stata-journal.com/archives/"
  return local sjurl "https://www.stata-journal.com/sj"
  qui gsort -vol -num
  return scalar vol = vol[1]
  return scalar num = num[1]
  return local volnum = VolNum[1]
  if "`saving'" != "" save "`saving'.dta", replace 
}
restore  
end

// cap program drop findsj_data_id
program define   findsj_data_id, rclass
version 14
syntax [, Savepwd Filename(string)]
preserve 
qui{
  tempname sj_search 
  local url_sj "https://www.stata-journal.com/sjsearch.html?choice=title&q="
  copy "`url_sj'"           "`sj_search'.txt" , replace
  infix strL v 1-1000 using "`sj_search'.txt", clear
  keep if regexm(v, ".*<d[td]>.*")
  findsj_strget v, gen(title)  begin(`"">"')    end(`"</a></dt>"')
  findsj_strget v, gen(author) begin(`"<dd>"')  end(`"\.\s[0-9]{4}\.</dd>"')
  findsj_strget v, gen(volume) begin(`"Volume "') match([\d]{1,2})
  findsj_strget v, gen(number) begin(`"Number "') match([\d]{1})  
  findsj_strget v, gen(art_id) begin(`"article="') end(`"">"')
  drop v 
  egen tag = tag(art_id)
  gen id = sum(tag)
  bysort id: replace author = author[_n+1] if author[_n]==""
  bysort id: replace volume = volume[_n+2] if volume[_n]==""
  bysort id: replace number = number[_n+2] if number[_n]==""
  keep if tag==1
  drop tag 
  gen volnum = real(volume + "." + number)
  if `"`filename'"' == "" local filename "sj_data_id"
  else local filename = subinstr("`filename'", ".dta", "", .)
  if "`savepwd'" != "" save "`filename'.dta", replace 
  else save "`c(sysdir_plus)'s/`filename'.dta", replace
  cap noi erase "`sj_search'.txt"
}
restore 
end

// cap program drop findsj_add_data
program define findsj_add_data, rclass
version 14
dis as error "Note: findsj_add_data is deprecated. Local data file support has been removed."
dis as text "DOI and page information are now fetched in real-time when using the 'getdoi' option."
exit 199
syntax, From(string) 
  tempfile sj_tempdata 
  local vn_local = "`from'"
  findsj_data_id, save file("`sj_tempdata'")
  use "`sj_tempdata'.dta", clear
  qui keep if volnum> `vn_local'
  local N = _N	
  qui gen doi  = ""
  qui gen page = "" 
  forvalues i=1/`N'{
  	local art_id = art_id[`i']
	qui findsj_doi `art_id'
  	qui replace doi  = r(doi)  in `i'	
  	qui replace page = r(page) in `i'
  	if mod(`i',3)==0 dis _c "." 	
  } 
  qui duplicates drop doi, force 
  qui format title author doi %-20s
  qui format volume number %4s
  qui format art_id page %10s
  qui save `"`fn'"', replace 	
  local vn_old = subinstr("`from'", ".", "-",1)
  qui sum volnum
  local vn_new = subinstr("`r(max)'", ".", "-",1)
  dis _n "Update finished: " _c
  dis _c in yellow "SJ `vn_old'" as text " --> " in y "SJ `vn_new'"  
  return local vn  = r(max)
  return local vn_old = `vn_old'
  return local vn_new = `vn_new'
end

// cap program drop findsj_compact_name
program define findsj_compact_name, rclass
version 8
syntax varlist(min=1) [, Add(string) Back Symbol(string) Generate(string)] 
foreach var of varlist `varlist'{
  if "`generate'" == "" {
      local genrep "replace"
	  local varname "`var'"
  }
  else{
	  cap noi confirm new variable `generate'
	  if _rc exit 198
	  else{
	  	local genrep  "generate"
		local varname "`generate'"
	  }
  } 	
	if `'"`symbol'"' == "" local symbol "~_~"
	if "`back'" != ""{
		local nchanges = 0	
		qui `genrep' `varname' = subinstr(`var', `"`symbol'"', " ", .)
		qui count if strpos(`var', `"`symbol'"')
		local nchanges = `nchanges' + r(N)		
		exit 
	}
    #delimit ;
    local list `"
	 "van de" "von der" von van de mc mac la "st." st "`add'"
     "'  ;
    #delimit cr	
	local nchanges = 0
    foreach name in `list'{
        qui `genrep' `varname' = subinstr(`var', " `name' ", `" `name'`symbol'"', .)
		qui count if strpos(`var', "`name'")
		local nchanges = `nchanges' + `r(N)'
    }	
	dis "(`nchanges' real changes made)"
	return scalar N = `nchanges'
}	
end

// cap program drop findsj_author_name_abb  
program define findsj_author_name_abb, rclass
  syntax varname [, SJformat Order(integer 1) Suffix(string) REPLACE]
  if "`suffix'" == "" local suffix "_full"
  else{
	  cap qui confirm new variable `varlist'`suffix' 
	  if _rc{
	  	  dis as error "Invalid suffix. Use only [0-9], _, or letters"
		  exit 198
	  }
  } 
qui{ 
  tempvar var 
  clonevar `var' = `varlist'
  findsj_compact_name `var'  
  gen   `var'_wordcount = wordcount(`var')
  gen   `var'_rev = ustrreverse(`var')
  split `var'_rev, parse(" ")
  qui sum `var'_wordcount
  local max_length = r(max)
  forvalues j = 2/`max_length'{
  	  replace `var'_rev`j' = ustrreverse(`var'_rev`j')
	  replace `var'_rev`j' = substr(`var'_rev`j',1,1) + "." ///
	          if strpos(`var'_rev`j', ".")==0 & `var'_rev`j' != "" & ///
				 ustrregexm(substr(`var'_rev`j',1,1), "[A-Z]")
  }
  tempvar `var'_Last  `var'_rest
  replace `var'_rev1 = ustrreverse(`var'_rev1)
  rename  `var'_rev1 `var'_Last
  gen      `var'_rest = `var'_rev3 if `var'_rev3 != ""
  gen str1 `var'_blank = cond(`var'_wordcount>=3, " ", "")
  replace  `var'_rest = `var'_rest + `var'_blank + `var'_rev2 
  gen `var'`suffix' = ""
  if "`sjformat'" != "" & `order' != 1 replace `var'`suffix' = `var'_rest + " " + `var'_Last 
  else replace `var'`suffix' = `var'_Last + " " + `var'_rest
  findsj_compact_name `var'_full, back
  if "`replace'" == "" gen `varlist'`suffix' = `var'`suffix'
  else replace `varlist' = `var'`suffix'
  drop `var'_wordcount `var'_rev* `var'_Last  `var'_rest  `var'`suffix'  
}  
end


*===============================================================================
* Database Update Check and Download Functions
*===============================================================================

// cap program drop findsj_update_db
program define findsj_update_db
    args source_choice
    
    dis as text "{hline 70}"
    dis as result "  Stata Journal Database Update"
    dis as text "{hline 70}"
    dis ""
    
    * Find findsj.ado location and normalize path
    qui findfile findsj.ado
    local ado_path = r(fn)
    
    * First normalize all path separators to forward slash (handle mixed paths)
    local ado_path = subinstr("`ado_path'", "\", "/", .)
    
    * Get directory by removing filename
    local ado_dir = substr("`ado_path'", 1, strlen("`ado_path'") - strlen("findsj.ado"))
    
    * Remove trailing slash if present
    if substr("`ado_dir'", -1, 1) == "/" {
        local ado_dir = substr("`ado_dir'", 1, strlen("`ado_dir'") - 1)
    }
    
    * Convert to OS-appropriate format and create full path
    if c(os) == "Windows" {
        local ado_dir = subinstr("`ado_dir'", "/", "\", .)
        local dta_file "`ado_dir'\findsj.dta"
        * Normalize for display
        local dta_file = subinstr("`dta_file'", "/", "\", .)
    }
    else {
        local dta_file "`ado_dir'/findsj.dta"
    }
    
    dis as text "Database location: " as result "`dta_file'"
    dis ""
    
    * Define download sources
    local github_url "https://raw.githubusercontent.com/BlueDayDreeaming/findsj/main/findsj.dta"
    local gitee_url "https://gitee.com/ChuChengWan/findsj/raw/main/findsj.dta"
    
    * Determine source based on argument
    if "`source_choice'" == "" | "`source_choice'" == "auto" {
        dis as text "Download source options:"
        dis as text "  {stata findsj, updatesource source(github):github} = GitHub"
        dis as text "  {stata findsj, updatesource source(gitee):gitee}  = Gitee (Fallback when GitHub is unavailable)"
        dis as text "  {stata findsj, updatesource source(both):both}   = Try both (auto-detect language)"
        dis as text ""
        dis as text "Click on a source above to download."
        dis as text "{hline 70}"
        exit
    }
    
    local sources ""
    local source_names ""
    
    if "`source_choice'" == "github" {
        local sources "`github_url'"
        local source_names "GitHub"
    }
    else if "`source_choice'" == "gitee" {
        local sources "`gitee_url'"
        local source_names "Gitee"
    }
    else if "`source_choice'" == "both" {
        * Auto-detect user's Stata language setting to determine optimal source order
        * Chinese users (zh_CN): Gitee first (faster access in China)
        * Non-Chinese users: GitHub first (global CDN)
        local locale_ui = c(locale_ui)
        if "`locale_ui'" == "zh_CN" {
            local sources "`gitee_url' `github_url'"
            local source_names "Gitee GitHub"
            dis as text "Language detected: Chinese (优先使用 Gitee)"
        }
        else {
            local sources "`github_url' `gitee_url'"
            local source_names "GitHub Gitee"
            dis as text "Language detected: Non-Chinese (Using GitHub first)"
        }
    }
    else {
        dis as error "Invalid source: `source_choice'"
        dis as text "Valid options: github, gitee, both"
        exit 198
    }
    
    * Try each source (stop after first success)
    local n_sources = wordcount("`sources'")
    local update_success = 0
    forvalues i = 1/`n_sources' {
        local source_url = word("`sources'", `i')
        local source_name = word("`source_names'", `i')
        
        dis ""
        dis as text "Downloading from `source_name'..." _c
        
        cap copy "`source_url'" "`dta_file'", replace
        
        if _rc == 0 {
            dis as result " Success!"
            
            * Verify the file
            cap use "`dta_file'", clear
            if _rc == 0 {
                qui count
                local n_records = r(N)
                * Normalize path for display
                local display_path = "`dta_file'"
                if c(os) == "Windows" {
                    local display_path = subinstr("`display_path'", "/", "\", .)
                }
                dis ""
                dis as text "{hline 70}"
                dis as result "  Update Complete!"
                dis as text "{hline 70}"
                dis as text "Database updated successfully from `source_name'"
                dis as text "Total articles: " as result "`n_records'"
                dis as text "Location: " as result "`display_path'"
                dis as text "{hline 70}"
                local update_success = 1
                * Exit immediately after successful update (don't try other sources)
                exit
            }
            else {
                dis as error " File corrupted."
                if `i' < `n_sources' {
                    dis as text "Trying next source..."
                }
            }
        }
        else {
            dis as error " Failed."
            if `i' < `n_sources' {
                dis as text "Trying next source..."
            }
        }
    }
    
    * All sources failed
    * Normalize ado_dir for display
    local display_dir = "`ado_dir'"
    if c(os) == "Windows" {
        local display_dir = subinstr("`display_dir'", "/", "\", .)
    }
    
    dis ""
    dis as text "{hline 70}"
    dis as error "  Update Failed"
    dis as text "{hline 70}"
    dis as error "Could not download database from selected source(s)"
    dis as text "Possible reasons:"
    dis as text "  - No internet connection"
    dis as text "  - Firewall blocking access"
    dis as text "  - Repository temporarily unavailable"
    dis ""
    dis as text "Manual download instructions:"
    dis as text "  1. Visit: " as result "https://github.com/BlueDayDreeaming/findsj"
    dis as text "     (China: " as result "https://gitee.com/ChuChengWan/findsj" as text ")"
    dis as text "  2. Download findsj.dta"
    dis as text "  3. Copy to: " as result "`display_dir'"
    dis as text "{hline 70}"
end

*===============================================================================
* Helper program: findsj_check_update
* Check if findsj.ado needs update (once per day)
*===============================================================================
// cap program drop findsj_check_update
program define findsj_check_update
    version 14
    
    * Silently check for updates - don't interrupt user workflow
    capture {
        local today_str = c(current_date)
        
        * Try to find findsj_version.dta
        local version_found = 0
        local version_file_path = ""
        
        * Search in multiple locations
        capture findfile findsj.ado
        if !_rc {
            local ado_dir = subinstr(r(fn), "/findsj.ado", "", .)
            local ado_dir = subinstr("`ado_dir'", "\findsj.ado", "", .)
        }
        else {
            local ado_dir ""
        }
        
        foreach location in "`c(sysdir_plus)'f" "`c(sysdir_personal)'" "`ado_dir'" "`c(pwd)'" {
            if "`location'" == "" continue
            if `version_found' == 1 continue
            capture confirm file "`location'/findsj_version.dta"
            if !_rc {
                local version_found = 1
                local version_file_path = "`location'/findsj_version.dta"
            }
        }
        
        * If version file not found, skip check silently
        if `version_found' == 0 {
            exit
        }
        
        * Check last_update date from version file
        preserve
        quietly use "`version_file_path'", clear
        
        * Get last_update variable (format: YYYY-MM-DD or similar)
        capture confirm variable last_update
        if _rc {
            restore
            exit
        }
        
        local last_update_str = last_update[1]
        restore
        
        * Parse last_update date and compare with today
        * Format expected: "2025-12-08" or similar
        if strlen("`last_update_str'") >= 10 {
            local update_year = substr("`last_update_str'", 1, 4)
            local update_month = substr("`last_update_str'", 6, 2)
            local update_day = substr("`last_update_str'", 9, 2)
            
            * Calculate days difference
            local update_date_num = mdy(real("`update_month'"), real("`update_day'"), real("`update_year'"))
            local today = date("`today_str'", "DMY")
            local days_diff = `today' - `update_date_num'
            
            * If older than 90 days, show update reminder
            if `days_diff' > 90 {
                noi dis ""
                noi dis as text "{hline 70}"
                noi dis as result "  📢 Database may need updating"
                noi dis as text "{hline 70}"
                noi dis as text "Last updated: " as result "`last_update_str'" as text " (" as result "`days_diff'" as text " days ago)"
                noi dis as text "Update: " `"{stata "findsj, updatesource source(both)":findsj, updatesource source(both)}"`
                noi dis as text "{hline 70}"
                noi dis ""
            }
        }
    }
end


*==========================================
* Clipboard function (similar to getiref's get_clipout)
*==========================================
// cap program drop findsj_clipout
program define findsj_clipout
    version 14
    args text
    
    if "`c(os)'" == "Windows" {
        * Windows: use PowerShell to handle multi-line text properly
        tempfile cliptemp
        quietly {
            file open fh using "`cliptemp'.txt", write replace
            file write fh `"`text'"'
            file close fh
        }
        shell powershell -Command "Get-Content '`cliptemp'.txt' | Set-Clipboard"
        local shortcut "Ctrl+V"
    }
    else if "`c(os)'" == "MacOSX" {
        * Mac: use pbcopy
        tempfile cliptemp
        quietly {
            file open fh using "`cliptemp'.txt", write replace
            file write fh `"`text'"'
            file close fh
        }
        shell cat "`cliptemp'.txt" | pbcopy
        local shortcut "Command+V"
    }
    else {
        * Linux or other OS - skip clipboard
        dis as text "{txt}Note: Clipboard not supported on this OS. Text saved to file."
        exit
    }
    
    dis as text _n "{txt}Tips: Text is on clipboard. Press '{res}`shortcut'{txt}' to paste, ^-^"
end

