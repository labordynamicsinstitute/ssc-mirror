*! version 3.2.9  02Aug2026
*! Yujun Lian (arlionn@163.com), Chucheng Wan (chucheng.wan@outlook.com)

* Search Stata Journal articles
* v3.2.9: Expose a single database-update interface, findsj, update; download,
*   validate, and transactionally install both runtime files from GitHub while
*   preserving caller data; remove source-selection options
* v3.2.8: Cache true APA-style citation strings, use record-level citation
*   fallbacks, and keep single-article and batch citation presentation aligned
* v3.2.7: Ensure the bundled runtime database and version metadata are
*   installed alongside the command on fresh SSC and net installations
* v3.2.6: Write batch exports as plain text, produce valid escaped LaTeX,
*   validate n(), reuse parsed online results, and strengthen stored results
* v3.2.5: Add online option to preserve website-supplied matches without an
*   additional query-term post-filter; report the source, retain online in
*   the all-results link, and repair year parsing plus metadata ordering
* v3.2.4: Require every author-query term to match a complete name token;
*   accept quoted multiword queries; preserve the caller's linesize
* v3.2.3: Create Stata's PERSONAL ado directory before saving setpath()
*   configuration on installations where that directory does not yet exist
* v3.2.2: Make BibTeX/RIS downloads synchronous and validate the returned
*   payload; normalize the malformed opening brace returned by the SJ BibTeX
*   endpoint
* v3.2.1: Fix author searches by matching complete name tokens instead of
*   arbitrary substrings; replace the generic type() download interface with
*   explicit bib/ris options; validate article IDs before downloads
* v3.2: Option pruning and getiref bundling (in response to SJ peer review)
*   - Bundled: getiref.ado/getiref.sthlp now ship with findsj; removed the
*     runtime "ssc install getiref" auto-install block
*   - Removed options: checkdb, installdb(), debug, clear, nobrowser,
*     nopdf, nopkg, offline. Their behavior is either obsolete or now
*     handled automatically (e.g. offline mode is auto-enabled when the
*     local findsj.dta is present)
*   - Aligned: ado syntax, findsj.sthlp option table, and the manuscript
*     (myarticle_v3.tex) now list an identical, smaller option set
*   - Docs: README/README_CN/findsj.sthlp recommend
*     "ssc install findsj, all replace" so the ancillary findsj.dta is
*     downloaded together with the program files
* v3.1: Final pre-submission cleanup (interactive button row, citation export)
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
* v1.5.0: 'added by Yujun Lian 2026/02/03', add number list before ref
* v1.4.0: Auto-check for database updates (monthly reminder with download option)
* v1.3.0: Direct getiref integration - click .md/.latex/.txt calls getiref with DOI
* v1.2.0: Simplified to single 'ref' option with three format buttons
* v1.1.1: Added individual "Ref" button for each article to copy citation
* v1.1.0: Removed local data file dependency, all info fetched online

*===============================================================================
* Helper program: findsj_author_match
* Match every query term as a complete author-name token (AND logic).  This
* prevents "lian" from matching Iliana, Julian, or Galiani and supports full
* author queries such as "Christopher F. Baum".
*===============================================================================
program define findsj_author_match
    version 14
    syntax varname, Generate(name) Query(string)

    confirm new variable `generate'

    local query_clean = ustrlower(ustrregexra(`"`query'"', "[^\p{L}\p{N}_]+", " "))
    local query_clean = strtrim(stritrim(`"`query_clean'"'))

    if `"`query_clean'"' == "" {
        gen byte `generate' = 0
        exit
    }

    tempvar author_tokens
    gen strL `author_tokens' = ustrlower(`varlist')
    replace `author_tokens' = ustrregexra(`author_tokens', "[^\p{L}\p{N}_]+", " ")
    replace `author_tokens' = " " + strtrim(stritrim(`author_tokens')) + " "
    gen byte `generate' = 1

    local n_words = wordcount(`"`query_clean'"')
    forvalues i = 1/`n_words' {
        local query_word = word(`"`query_clean'"', `i')
        replace `generate' = 0 if ///
            strpos(`author_tokens', " `query_word' ") == 0
    }
end


*===============================================================================
* Helper program: findsj_tex_escape
* Escape plain citation text or link destinations for use in LaTeX.  Private-use
* Unicode markers prevent the backslashes and braces introduced by one
* replacement from being escaped again by a later replacement.
*===============================================================================
program define findsj_tex_escape
    version 14
    syntax varname, Generate(name) [URL]

    confirm new variable `generate'

    local mark_bs      = uchar(57344)
    local mark_lbrace  = uchar(57345)
    local mark_rbrace  = uchar(57346)
    local mark_percent = uchar(57347)
    local mark_dollar  = uchar(57348)
    local mark_hash    = uchar(57349)
    local mark_under   = uchar(57350)
    local mark_amp     = uchar(57351)
    local mark_tilde   = uchar(57352)
    local mark_caret   = uchar(57353)

    gen strL `generate' = `varlist'
    replace `generate' = subinstr(`generate', char(92), "`mark_bs'", .)
    replace `generate' = subinstr(`generate', "{", "`mark_lbrace'", .)
    replace `generate' = subinstr(`generate', "}", "`mark_rbrace'", .)
    replace `generate' = subinstr(`generate', "%", "`mark_percent'", .)
    replace `generate' = subinstr(`generate', char(36), "`mark_dollar'", .)
    replace `generate' = subinstr(`generate', "#", "`mark_hash'", .)
    replace `generate' = subinstr(`generate', "_", "`mark_under'", .)
    replace `generate' = subinstr(`generate', "&", "`mark_amp'", .)
    replace `generate' = subinstr(`generate', "~", "`mark_tilde'", .)
    replace `generate' = subinstr(`generate', "^", "`mark_caret'", .)

    if "`url'" == "" {
        replace `generate' = subinstr(`generate', "`mark_bs'", ///
            char(92) + "textbackslash{}", .)
        replace `generate' = subinstr(`generate', "`mark_lbrace'", ///
            char(92) + "{", .)
        replace `generate' = subinstr(`generate', "`mark_rbrace'", ///
            char(92) + "}", .)
        replace `generate' = subinstr(`generate', "`mark_percent'", ///
            char(92) + "%", .)
        replace `generate' = subinstr(`generate', "`mark_dollar'", ///
            char(92) + char(36), .)
        replace `generate' = subinstr(`generate', "`mark_hash'", ///
            char(92) + "#", .)
        replace `generate' = subinstr(`generate', "`mark_under'", ///
            char(92) + "_", .)
        replace `generate' = subinstr(`generate', "`mark_amp'", ///
            char(92) + "&", .)
        replace `generate' = subinstr(`generate', "`mark_tilde'", ///
            char(92) + "textasciitilde{}", .)
        replace `generate' = subinstr(`generate', "`mark_caret'", ///
            char(92) + "textasciicircum{}", .)
    }
    else {
        * Percent-encode characters that are not safe link destinations, and
        * TeX-escape characters that must survive literally in the URL.
        replace `generate' = subinstr(`generate', "`mark_bs'", ///
            char(92) + "%5C", .)
        replace `generate' = subinstr(`generate', "`mark_lbrace'", ///
            char(92) + "%7B", .)
        replace `generate' = subinstr(`generate', "`mark_rbrace'", ///
            char(92) + "%7D", .)
        replace `generate' = subinstr(`generate', "`mark_percent'", ///
            char(92) + "%", .)
        replace `generate' = subinstr(`generate', "`mark_dollar'", ///
            char(92) + "%24", .)
        replace `generate' = subinstr(`generate', "`mark_hash'", ///
            char(92) + "#", .)
        replace `generate' = subinstr(`generate', "`mark_under'", ///
            char(92) + "_", .)
        replace `generate' = subinstr(`generate', "`mark_amp'", ///
            char(92) + "&", .)
        replace `generate' = subinstr(`generate', "`mark_tilde'", ///
            char(92) + "%7E", .)
        replace `generate' = subinstr(`generate', "`mark_caret'", ///
            char(92) + "%5E", .)
    }
end


*===============================================================================
* Helper program: findsj_fix_bibtex
* The SJ export endpoint currently returns "@article \{key,".  Normalize that
* first line so the downloaded file can be imported by BibTeX tools.
*===============================================================================
program define findsj_fix_bibtex
    version 14
    args filename

    tempname source target
    tempfile cleaned

    file open `source' using `"`filename'"', read text
    file open `target' using `"`cleaned'"', write text replace

    file read `source' line
    local first_line = 1
    while r(eof) == 0 {
        if `first_line' {
            local line = subinstr(`"`line'"', " \{", "{", 1)
            local first_line = 0
        }
        file write `target' `"`line'"' _n
        file read `source' line
    }

    file close `source'
    file close `target'
    copy `"`cleaned'"' `"`filename'"', replace
end


*===============================================================================
* Helper program: findsj_download (defined first to be available for buttons)
* Download BibTeX or RIS file on-demand when user clicks the button
*===============================================================================
program define findsj_download
    version 14
    syntax anything(name=artid), Type(string) [DOWNloadpath(string)]

    * Article IDs are used in URLs and filenames.  Accept only
    * the alphanumeric/underscore form used by the SJ archive.
    if !regexm("`artid'", "^[A-Za-z0-9_]+$") {
        dis as error "Invalid Stata Journal article ID: `artid'"
        exit 198
    }
    
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

    dis as text "Downloading `file_ext' file for `artid'..." _c

    if "`c(os)'" == "MacOSX" | "`c(os)'" == "Unix" {
        local full_file_esc = subinstr("`full_file'", `"""', `"\""', .)
        local full_file_esc = subinstr("`full_file_esc'", "$", "\$", .)
        local full_file_esc = subinstr("`full_file_esc'", "`", "\`", .)
        capture shell curl -fsSL -H "Referer: `url_article'" -H "User-Agent: Mozilla/5.0" -o "`full_file_esc'" "`url'"
    }
    else {
        local full_file_ps = subinstr("`full_file'", "'", "''", .)
        local ps_command = "try { " + ///
            char(36) + "ProgressPreference='SilentlyContinue'; " + ///
            "Invoke-WebRequest -Uri '`url'' " + ///
            "-Headers @{'Referer'='`url_article'';'User-Agent'='Mozilla/5.0'} " + ///
            "-OutFile '`full_file_ps''; exit 0 " + ///
            "} catch { Write-Host " + char(36) + "_.Exception.Message; exit 1 }"
        capture shell powershell -NoProfile -ExecutionPolicy Bypass -Command "`ps_command'"
    }

    capture confirm file `"`full_file'"'
    if _rc != 0 {
        dis as error " failed."
        dis as error "Could not download the citation file; check the connection and download path."
        exit 631
    }

    * A headerless request to this endpoint can return an HTML page with a
    * successful transport status.  Reject that response before reporting
    * completion.
    tempname payload
    file open `payload' using `"`full_file'"', read text
    file read `payload' first_line
    file close `payload'
    if substr(strtrim(`"`first_line'"'), 1, 1) == "<" {
        capture erase `"`full_file'"'
        dis as error " failed."
        dis as error "The Stata Journal server returned HTML instead of a citation file."
        exit 677
    }

    if "`type'" == "bib" {
        quietly findsj_fix_bibtex `"`full_file'"'
    }

    dis as result " done."
    dis as result `"Save to: {browse "`full_file'"}"'
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
	  NOCLip ///
    N(integer 10) ///
	ALLresults ///
    GETDOI ///
    SETPath(string) ///
	  QUERYpath ///
    RESETpath ///
    UPdate ///
    BIB ///
    RIS ///
    ONLINE ///
    ]

if `n' < 1 {
    dis as error "Option n() must specify a positive integer."
    exit 198
}


* Check for updates (once per day)
findsj_check_update

* syntax, anything preserves grouping quotes.  Treat one pair of surrounding
* double quotes as command-line grouping, not as part of the search text.
local keywords = strtrim(stritrim(`"`keywords'"'))
if strlen(`"`keywords'"') >= 2 {
    if substr(`"`keywords'"', 1, 1) == char(34) & ///
       substr(`"`keywords'"', -1, 1) == char(34) {
        local keywords = substr(`"`keywords'"', 2, strlen(`"`keywords'"') - 2)
        local keywords = strtrim(stritrim(`"`keywords'"'))
    }
}

* online is a search-mode option, not a modifier for administrative or
* article-download subcommands.
if "`online'" != "" {
    local online_conflict ""
    if "`bib'" != ""          local online_conflict "bib"
    else if "`ris'" != ""     local online_conflict "ris"
    else if "`update'" != ""  local online_conflict "update"
    else if "`setpath'" != ""  local online_conflict "setpath()"
    else if "`querypath'" != "" local online_conflict "querypath"
    else if "`resetpath'" != "" local online_conflict "resetpath"

    if "`online_conflict'" != "" {
        dis as error "Option online cannot be combined with `online_conflict'."
        dis as error "Option online is available only for article searches."
        exit 198
    }
}


* Handle citation-file download subcommands (findsj artid, bib|ris)
if "`bib'" != "" | "`ris'" != "" {
    if "`bib'" != "" & "`ris'" != "" {
        dis as error "Options bib and ris may not be combined"
        exit 198
    }
    if strtrim(`"`keywords'"') == "" {
        dis as error "An article ID is required with the bib or ris option"
        exit 198
    }
    local download_type = cond("`bib'" != "", "bib", "ris")
    findsj_download `keywords', type(`download_type')
    exit
}

* Handle showref subcommand (findsj artid, ref)
if "`ref'" != "" & "`online'" == "" & "`keywords'" != "" & "`author'" == "" & "`title'" == "" & "`keyword'" == "" {
    * Check if keywords looks like an article ID (not a search term)
    * Article IDs are typically alphanumeric strings like "st0001", "dm0065", or "st0136_1"
    if regexm("`keywords'", "^[a-z]+[0-9_]+$") | regexm("`keywords'", "^ï»¿[a-z]+[0-9_]+$") {
        findsj_show_ref `keywords'
        exit
    }
}

* Handle database update subcommand
if "`update'" != "" {
    findsj_update_db
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
        capture mkdir "`c(sysdir_personal)'"
        tempname fh
        capture file open `fh' using "`config_file'", write replace
        if _rc != 0 {
            dis as error "Could not create the download-path configuration file:"
            dis as error "`config_file'"
            exit 603
        }
        file write `fh' "`setpath'"
        file close `fh'
        
        * Also set global variable for immediate effect in current session
        global findsj_download_path "`setpath'"
        
        dis as result "Download path set to: " as text "`setpath'"
        dis as text "This setting will be remembered for future sessions."
        exit
    }
}

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

local url_sj "https://www.stata-journal.com/sjsearch.html?choice=`scope'&q=`keywords_url'"

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

if `dta_found' == 0 & "`ref'" != "" {
    dis as text _n "{hline 70}"
    dis as text " " as result "Notice:" as text " Local database (findsj.dta) not found."
    dis as text " DOI information will be fetched online (may be slower)."
    dis as text _n " For faster performance, update the database:"
    dis as text "   {stata findsj, update:findsj, update}"
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

* Use the local database by default when available.  online explicitly
* bypasses it for the search itself.
if `dta_found' == 1 & `"`dta_path'"' != "" & "`online'" == "" {
    local use_offline = 1
}

local search_source = cond(`use_offline' == 1, "local", "online")

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
        * Local search logic:
        * 1. Case-insensitive (convert all to lowercase)
        * 2. Substring matching for titles/keywords; token matching for authors
        * 3. Multiple words use AND logic (all words must appear)
        * 4. Author search: all query terms use complete-token AND matching
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
            * Author search: every query term must be a complete name token
            findsj_author_match author, generate(author_match) query(`"`keywords_clean'"')
            replace matched = author_match
            replace match_priority = 1 if matched == 1
            drop author_match
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
            return local keywords = "`keywords'"
            return local scope = "`scope'"
            return local url = "`url_sj'"
            return local search_source = "`search_source'"
            return scalar n_results = 0
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
    dis _n as text "{hline 70}"
    dis as text "Source: " as result "Stata Journal website"
    dis as text "The website supplies matching and ordering."
    dis as text "findsj applies no query-term post-filter."
    dis as text "{hline 70}"
    dis _n as text "  Searching ... " _c

    preserve //===================preserve begin======

    clear   // added by Yujun Lian, 2026/02/03 16:13
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
        return local keywords = "`keywords'"
        return local scope = "`scope'"
        return local url = "`url_sj'"
        return local search_source = "`search_source'"
        return scalar n_results = 0
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
    replace year_from_html = ustrregexs(1) if ///
        ustrregexm(author_year_raw, "\.[ ]*([0-9]{4})\.?[ ]*$")
    * If no match, try alternative pattern (year at end without preceding dot)
    replace year_from_html = ustrregexs(1) if year_from_html == "" & ///
        ustrregexm(author_year_raw, "[ ]([0-9]{4})\.?[ ]*$")
    
    * Clean up extracted data - remove year from author string
    gen author = ustrregexra(author_year_raw, ///
        "\.?[ ]*[0-9]{4}\.?[ ]*$", "")
    replace author = strtrim(author)
    * Remove trailing dots and spaces from author
    replace author = ustrregexra(author, "\.[ ]*$", "")
    replace author = author[_n+1] if author == "" & author[_n+1] != ""
    drop author_year_raw
    
    drop v 
    keep if art_id != ""
    recast str20 art_id
    gen selected = 1
    local n_results = _N
    
    * Use HTML-extracted data as primary source
    gen volume = volume_html
    gen number = number_html
    gen year = real(year_from_html)
    gen volnum_str = volume + "(" + number + ")" if volume != "" & volume != "."
    gen volnum_url = volume + "-" + number if volume != "" & volume != "."
    
    * Initialize optional fields (will be fetched on-demand if getdoi is specified)
    gen str80 doi = "."
    gen str20 page = "."
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
        return local keywords = "`keywords'"
        return local scope = "`scope'"
        return local url = "`url_sj'"
        return local search_source = "`search_source'"
        return scalar n_results = 0
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
    if `num_export' > 0 {
        tempfile online_export_data
        save "`online_export_data'", replace
    }
    } // End of online search qui block
} // End of else (online search mode)

* ===== COMMON DISPLAY CODE FOR BOTH ONLINE AND OFFLINE =====
if "`allresults'" != "" local n_display = `total_results'
else local n_display = min(`n', `total_results')

* Display search results summary - removed for cleaner output
local url_sj "https://www.stata-journal.com/sjsearch.html?choice=`scope'&q=`keywords_url'"
local all_cmd `"findsj `keywords', allresults"'
if "`scope'" != "keyword" local all_cmd `"findsj `keywords', `scope' allresults"'
if "`search_source'" == "online" {
    local all_cmd `"findsj `keywords', online allresults"'
    if "`scope'" != "keyword" local all_cmd `"findsj `keywords', `scope' online allresults"'
}

* If export format specified, skip displaying search results
if `num_export' > 0 {
    * Save results count but don't display search results
    local n_results = `total_results'
}
else {
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

    * Keep enriched metadata in the search-result data so stored results,
    * especially r(doi_1), agree with the DOI/PDF actions shown to the user.
    if `has_doi' == 1 {
        capture quietly replace doi = "`doi_i'" in `i'
        if "`page_i'" != "" & "`page_i'" != "." {
            capture quietly replace page = "`page_i'" in `i'
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
    
    dis as text "    " _c
    dis as text `"{browse "`url_html_i'":Web}"' _c
    
    * Display PDF link - use DOI-based URL (only if DOI is available)
    if `has_doi' == 1 {
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
    dis as text " | " _c
    dis as text `"{stata "search `art_id_nobom'":Install}"' _c
    
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
    dis as text `"{stata "findsj `art_id_nobom', bib":BibTeX}"' _c
    dis as text " | " _c
    dis as text `"{stata "findsj `art_id_nobom', ris":RIS}"'
    
    * ref option is deprecated - citation buttons are now directly available in main button row
    
}

* Save total number of displayed results
global findsj_n_display `n_display'

if `total_results' > `n_display' {
    dis _n as text "Showing " as result "`n_display'" as text " of " _c
    dis as result "`total_results'" as text " results. " _c
    dis as text "(" `"{stata "`all_cmd'":all}"' as text ")"
}

* Note: Batch clipboard copy removed. Users can click individual "Ref" buttons to copy citations.
* This provides better user experience and avoids command-line length limitations.

} // End of else block for non-export display

* Common return values
local n_results = `total_results'

return local keywords   = "`keywords'"
return local scope      = "`scope'"
return local url        = "`url_sj'"
return local search_source = "`search_source'"
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
    dis _n as text "Showing " as result "`total_results'" as text " of " as result "`total_results'" as text " results. " _c
    dis as text "(" `"{stata "`all_cmd'":all}"' as text ")"
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
                findsj_author_match author, generate(author_match) query(`"`keywords_clean'"')
                replace matched = author_match
                replace match_priority = 1 if matched == 1
                drop author_match
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
            
            * Build a record-level fallback first, then replace it with the
            * cached APA citation wherever that field is available.  This
            * avoids link-only output when a result set mixes complete and
            * incomplete database records.
            tempvar year_cite title_cite page_cite journal_cite citation_base
            gen str8 `year_cite' = string(year, "%9.0g")
            replace `year_cite' = "" if missing(year)

            gen strL `title_cite' = strtrim(title)
            replace `title_cite' = `title_cite' + "." if ///
                `title_cite' != "" & ///
                !ustrregexm(`title_cite', "[.!?]$")

            gen strL `page_cite' = strtrim(page)
            replace `page_cite' = subinstr(`page_cite', "-", "–", .)

            gen strL `journal_cite' = "The Stata Journal"
            replace `journal_cite' = `journal_cite' + ", " + ///
                string(volume, "%9.0g") if !missing(volume)
            replace `journal_cite' = `journal_cite' + "(" + ///
                string(number, "%9.0g") + ")" if !missing(number)
            replace `journal_cite' = `journal_cite' + ", " + ///
                `page_cite' if `page_cite' != "" & `page_cite' != "."
            replace `journal_cite' = `journal_cite' + "."

            gen strL `citation_base' = ""
            replace `citation_base' = strtrim(author) + ///
                cond(`year_cite' != "", " (" + `year_cite' + "). ", ". ") + ///
                `title_cite' if author != "" & author != "."
            replace `citation_base' = `title_cite' + ///
                cond(`year_cite' != "", " (" + `year_cite' + ").", "") ///
                if author == "" | author == "."
            replace `citation_base' = strtrim(`citation_base') + ///
                " " + `journal_cite'

            cap confirm variable citation_apa
            if _rc == 0 {
                replace `citation_base' = citation_apa if ///
                    citation_apa != "" & citation_apa != "."
            }

            * LaTeX requires separate escaping for visible citation text and
            * link destinations.  Build these once and use a single literal
            * backslash for each \href command below.
            if "`latex'" != "" {
                tempvar citation_base_tex url_html_tex url_pdf_tex ///
                    url_google_tex
                findsj_tex_escape `citation_base', ///
                    generate(`citation_base_tex')
                findsj_tex_escape url_html, generate(`url_html_tex') url
                findsj_tex_escape url_pdf, generate(`url_pdf_tex') url
                findsj_tex_escape url_google, generate(`url_google_tex') url
            }

            if "`md'" != "" {
                gen cite_text = `citation_base' + ///
                    " [Link](" + url_html + ")"
                replace cite_text = cite_text + ///
                    ", [PDF](" + url_pdf + ")" ///
                    if url_pdf != "" & url_pdf != "."
                replace cite_text = cite_text + ///
                    ", [Google](<" + url_google + ">)"
            }
            else if "`latex'" != "" {
                gen cite_text = `citation_base_tex' + " " + ///
                    char(92) + "href{" + `url_html_tex' + "}{Link}"
                replace cite_text = cite_text + ", " + char(92) + ///
                    "href{" + `url_pdf_tex' + "}{PDF}" ///
                    if url_pdf != "" & url_pdf != "."
                replace cite_text = cite_text + ", " + char(92) + ///
                    "href{" + `url_google_tex' + "}{Google}"
            }
            else if "`plain'" != "" {
                gen cite_text = `citation_base' + " Link: " + url_html
                replace cite_text = cite_text + ", PDF: " + url_pdf ///
                    if url_pdf != "" & url_pdf != "."
                replace cite_text = cite_text + ///
                    ", Google: " + url_google
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
            else if "`latex'" != "" local fn_suffix ".tex"
            else if "`plain'" != "" local fn_suffix ".txt"
            
            local saving "_findsj_temp_out_`fn_suffix'"
            local save_path "`c(pwd)'"
            local save_path = subinstr("`save_path'", "\", "/", .)

            capture confirm file "`save_path'/`saving'"
            if _rc == 0 {
                noi dis as text ///
                    "Note: replacing existing export file: `saving'"
            }

            tempname export_fh
            file open `export_fh' using "`save_path'/`saving'", ///
                write text replace
            forvalues j = 1/`=_N' {
                file write `export_fh' (cite_text[`j']) _n
            }
            file close `export_fh'
            
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
        * ===== ONLINE EXPORT: Reuse the already parsed website results =====
        preserve
        quietly use "`online_export_data'", clear
        qui {
            capture confirm numeric variable year
            if _rc == 0 {
                tostring year, replace format(%9.0g) force
                replace year = "" if year == "."
            }

            tempvar online_order merge_flag
            gen long `online_order' = _n
                    
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
                                        cap confirm variable DOI
                                        if _rc == 0 rename DOI doi
                                        cap confirm variable doi
                                        if _rc != 0 gen str80 doi = "."
                                        cap confirm variable page
                                        if _rc != 0 gen str20 page = "."
                                        cap confirm variable citation_apa
                                        if _rc != 0 gen strL citation_apa = ""
                                        keep art_id doi page citation_apa
                                        replace art_id = subinstr(art_id, "ï»¿", "", .)
                                        tempfile doi_data
                                        save "`doi_data'", replace
                                        
                                        use "`current_data'", clear
                                        merge 1:1 art_id using "`doi_data'", ///
                                            update replace generate(`merge_flag')
                                        drop if `merge_flag' == 2
                                        drop `merge_flag'
                                        local found_db = 1
                                    }
                                    else {
                                        cap confirm variable artid
                                        if _rc == 0 {
                                            cap confirm variable DOI
                                            if _rc == 0 rename DOI doi
                                            cap confirm variable doi
                                            if _rc != 0 gen str80 doi = "."
                                            cap confirm variable page
                                            if _rc != 0 gen str20 page = "."
                                            cap confirm variable citation_apa
                                            if _rc != 0 gen strL citation_apa = ""
                                            keep artid doi page citation_apa
                                            rename artid art_id
                                            replace art_id = subinstr(art_id, "ï»¿", "", .)
                                            tempfile doi_data
                                            save "`doi_data'", replace
                                            
                                            use "`current_data'", clear
                                            merge 1:1 art_id using "`doi_data'", ///
                                                update replace generate(`merge_flag')
                                            drop if `merge_flag' == 2
                                            drop `merge_flag'
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

                    * merge sorts on art_id; restore the website's ordering
                    sort `online_order'
                    drop `online_order'

                    * Save the first enriched DOI so the post-export r() list
                    * agrees with the metadata used in the exported citation.
                    local export_doi_1 = doi[1]
                    
                    capture drop url_pdf page_str
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
                    
                    * Preserve the website's author-list order in the fallback
                    * citation text.  Inverting only the final word is not valid
                    * for multi-author lists.
                    gen author_getiref = author
                    
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
                    
                    * Start with website-derived fallback citations so that
                    * newly published records absent from the local database
                    * are never reduced to link-only output.
                    gen strL citation_base = author_getiref + " (" + year + ///
                        "). " + title_display + ". The Stata Journal, " + ///
                        volnum_str
                    replace citation_base = citation_base + ", " + page ///
                        if page != "" & page != "."
                    replace citation_base = citation_base + ". "

                    if "`md'" != "" {
                        gen strL cite_text = citation_base
                        replace cite_text = cite_text + ///
                            "[Link](" + url_html + ")"
                        replace cite_text = cite_text + ///
                            ", [PDF](" + url_pdf + ")" ///
                            if url_pdf != "" & url_pdf != "."
                        replace cite_text = cite_text + ///
                            ", [Google](<" + url_google + ">)"
                    }
                    else if "`latex'" != "" {
                        tempvar citation_base_tex url_html_tex url_pdf_tex ///
                            url_google_tex
                        findsj_tex_escape citation_base, ///
                            generate(`citation_base_tex')
                        findsj_tex_escape url_html, ///
                            generate(`url_html_tex') url
                        findsj_tex_escape url_pdf, ///
                            generate(`url_pdf_tex') url
                        findsj_tex_escape url_google, ///
                            generate(`url_google_tex') url

                        gen strL cite_text = `citation_base_tex'
                        replace cite_text = cite_text + ///
                            char(92) + "href{" + `url_html_tex' + "}{Link}"
                        replace cite_text = cite_text + ///
                            ", " + char(92) + "href{" + `url_pdf_tex' + ///
                            "}{PDF}" ///
                            if url_pdf != "" & url_pdf != "."
                        replace cite_text = cite_text + ///
                            ", " + char(92) + "href{" + ///
                            `url_google_tex' + "}{Google}"
                    }
                    else if "`plain'" != "" {
                        gen strL cite_text = citation_base
                        replace cite_text = cite_text + "Link: " + url_html
                        replace cite_text = cite_text + ", PDF: " + url_pdf ///
                            if url_pdf != "" & url_pdf != "."
                        replace cite_text = cite_text + ///
                            ", Google: " + url_google
                    }

                    * Prefer richer local citation metadata record by record.
                    * Records without citation_apa retain the website fallback.
                    cap confirm variable citation_apa
                    if _rc == 0 {
                        tempvar has_local_citation
                        gen byte `has_local_citation' = ///
                            citation_apa != "" & citation_apa != "."

                        if "`latex'" != "" {
                            tempvar citation_apa_tex
                            findsj_tex_escape citation_apa, ///
                                generate(`citation_apa_tex')
                        }

                        if "`md'" != "" {
                            replace cite_text = citation_apa + ///
                                " [Link](" + url_html + ")" ///
                                if `has_local_citation'
                            replace cite_text = cite_text + ///
                                ", [PDF](" + url_pdf + ")" ///
                                if `has_local_citation' & ///
                                   url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ///
                                ", [Google](<" + url_google + ">)" ///
                                if `has_local_citation'
                        }
                        else if "`latex'" != "" {
                            replace cite_text = `citation_apa_tex' + " " + ///
                                char(92) + "href{" + `url_html_tex' + ///
                                "}{Link}" ///
                                if `has_local_citation'
                            replace cite_text = cite_text + ///
                                ", " + char(92) + "href{" + ///
                                `url_pdf_tex' + "}{PDF}" ///
                                if `has_local_citation' & ///
                                   url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ///
                                ", " + char(92) + "href{" + ///
                                `url_google_tex' + "}{Google}" ///
                                if `has_local_citation'
                        }
                        else if "`plain'" != "" {
                            replace cite_text = citation_apa + ///
                                " Link: " + url_html ///
                                if `has_local_citation'
                            replace cite_text = cite_text + ///
                                ", PDF: " + url_pdf ///
                                if `has_local_citation' & ///
                                   url_pdf != "" & url_pdf != "."
                            replace cite_text = cite_text + ///
                                ", Google: " + url_google ///
                                if `has_local_citation'
                        }

                        drop `has_local_citation'
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
                    else if "`latex'" != "" local fn_suffix ".tex"
                    else if "`plain'" != "" local fn_suffix ".txt"
                    
                    local saving "_findsj_temp_out_`fn_suffix'"
                    
                    * Get save path (use current working directory)
                    local save_path "`c(pwd)'"
                    local save_path = subinstr("`save_path'", "\", "/", .)

                    capture confirm file "`save_path'/`saving'"
                    if _rc == 0 {
                        noi dis as text ///
                            "Note: replacing existing export file: `saving'"
                    }

                    * Write one citation per line without CSV quoting.
                    tempname export_fh
                    file open `export_fh' using "`save_path'/`saving'", ///
                        write text replace
                    forvalues j = 1/`=_N' {
                        file write `export_fh' (cite_text[`j']) _n
                    }
                    file close `export_fh'
                    
                    * Save file location info to global (will be cleaned up later)
                    global findsj_export_path "`save_path'"
                    global findsj_export_file "`saving'"
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

* Reassert after export helpers so callers can always verify the path and count.
return local search_source = "`search_source'"
return scalar n_results = `n_results'
if "`export_doi_1'" != "" & "`export_doi_1'" != "." {
    return local doi_1 = "`export_doi_1'"
}

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
        dis as text `"{stata "findsj, update":Update database}"'
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
      local begin   `"<b><a href="/sj"'
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
  local begin `"<b><a href="/sj"'
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
        local version_file "`ado_dir'\findsj_version.dta"
        * Normalize for display
        local dta_file = subinstr("`dta_file'", "/", "\", .)
        local version_file = subinstr("`version_file'", "/", "\", .)
    }
    else {
        local dta_file "`ado_dir'/findsj.dta"
        local version_file "`ado_dir'/findsj_version.dta"
    }
    
    dis as text "Database location: " as result "`dta_file'"
    dis ""
    
    * Download both runtime files to temporary paths.  The installed files are
    * not touched until both downloads have passed validation.
    local github_dta_url "https://raw.githubusercontent.com/BlueDayDreeaming/findsj/main/findsj.dta"
    local github_version_url "https://raw.githubusercontent.com/BlueDayDreeaming/findsj/main/findsj_version.dta"
    tempfile downloaded_dta downloaded_version backup_dta backup_version
    tempname validation_data validation_version

    local update_rc = 0
    local failure_reason ""
    local n_records = .

    dis as text "Downloading from GitHub..." _c

    capture copy "`github_dta_url'" "`downloaded_dta'", replace
    if _rc {
        local update_rc = _rc
        local failure_reason "Could not download findsj.dta from GitHub"
    }

    if `update_rc' == 0 {
        capture copy "`github_version_url'" "`downloaded_version'", replace
        if _rc {
            local update_rc = _rc
            local failure_reason "Could not download findsj_version.dta from GitHub"
        }
    }

    * Validate the article database in a separate frame so that the caller's
    * active dataset, including unsaved changes, remains untouched.
    if `update_rc' == 0 {
        frame create `validation_data'
        capture frame `validation_data': use "`downloaded_dta'", clear
        local validation_rc = _rc

        if `validation_rc' == 0 {
            foreach required_var in art_id title authors year doi url citation_apa {
                capture frame `validation_data': confirm variable `required_var'
                if _rc & `validation_rc' == 0 local validation_rc = _rc
            }
        }

        if `validation_rc' == 0 {
            capture frame `validation_data': isid art_id
            if _rc local validation_rc = _rc
        }

        if `validation_rc' == 0 {
            frame `validation_data': quietly count
            local n_records = r(N)
            if `n_records' < 1 local validation_rc = 2000
        }

        capture frame drop `validation_data'

        if `validation_rc' != 0 {
            local update_rc = 610
            local failure_reason "Downloaded findsj.dta failed validation"
        }
    }

    * Validate the companion version metadata and require its record count to
    * agree with the downloaded article database.
    if `update_rc' == 0 {
        frame create `validation_version'
        capture frame `validation_version': use "`downloaded_version'", clear
        local validation_rc = _rc

        if `validation_rc' == 0 {
            foreach required_var in update_date total_articles {
                capture frame `validation_version': confirm variable `required_var'
                if _rc & `validation_rc' == 0 local validation_rc = _rc
            }
        }

        if `validation_rc' == 0 {
            capture frame `validation_version': confirm numeric variable total_articles
            if _rc local validation_rc = _rc
        }

        if `validation_rc' == 0 {
            frame `validation_version': quietly count
            if r(N) != 1 local validation_rc = 459
        }

        if `validation_rc' == 0 {
            frame `validation_version': quietly summarize total_articles, meanonly
            if r(min) != `n_records' local validation_rc = 459
        }

        capture frame drop `validation_version'

        if `validation_rc' != 0 {
            local update_rc = 610
            local failure_reason "Downloaded findsj_version.dta failed validation"
        }
    }

    * Back up both installed runtime files before replacing either one.
    local had_dta = 0
    local had_version = 0

    if `update_rc' == 0 {
        capture confirm file "`dta_file'"
        if !_rc {
            capture copy "`dta_file'" "`backup_dta'", replace
            if _rc {
                local update_rc = _rc
                local failure_reason "Could not back up the installed findsj.dta"
            }
            else local had_dta = 1
        }
    }

    if `update_rc' == 0 {
        capture confirm file "`version_file'"
        if !_rc {
            capture copy "`version_file'" "`backup_version'", replace
            if _rc {
                local update_rc = _rc
                local failure_reason "Could not back up the installed findsj_version.dta"
            }
            else local had_version = 1
        }
    }

    * Install both validated files.  If either copy fails, restore the prior
    * pair so that the package never retains a half-completed update.
    if `update_rc' == 0 {
        capture copy "`downloaded_dta'" "`dta_file'", replace
        if _rc {
            local update_rc = _rc
            local failure_reason "Could not install the downloaded findsj.dta"
            if `had_dta' capture copy "`backup_dta'" "`dta_file'", replace
            else capture erase "`dta_file'"
        }
    }

    if `update_rc' == 0 {
        capture copy "`downloaded_version'" "`version_file'", replace
        if _rc {
            local update_rc = _rc
            local failure_reason "Could not install the downloaded findsj_version.dta"
            if `had_dta' capture copy "`backup_dta'" "`dta_file'", replace
            else capture erase "`dta_file'"
            if `had_version' capture copy "`backup_version'" "`version_file'", replace
            else capture erase "`version_file'"
        }
    }

    if `update_rc' != 0 {
        dis as error " Failed."

        * Normalize ado_dir for display
        local display_dir = "`ado_dir'"
        if c(os) == "Windows" {
            local display_dir = subinstr("`display_dir'", "/", "\", .)
        }

        dis ""
        dis as text "{hline 70}"
        dis as error "  Update Failed"
        dis as text "{hline 70}"
        dis as error "`failure_reason'"
        dis as text "The existing database and version metadata were left unchanged."
        dis as text "Possible reasons:"
        dis as text "  - No internet connection"
        dis as text "  - Firewall blocking access"
        dis as text "  - Repository temporarily unavailable"
        dis ""
        dis as text "Manual download instructions:"
        dis as text "  1. Visit: " as result "https://github.com/BlueDayDreeaming/findsj"
        dis as text "  2. Download findsj.dta and findsj_version.dta"
        dis as text "  3. Copy both files to: " as result "`display_dir'"
        dis as text "{hline 70}"
        exit `update_rc'
    }

    dis as result " Success!"

    * Normalize path for display
    local display_path = "`dta_file'"
    if c(os) == "Windows" {
        local display_path = subinstr("`display_path'", "/", "\", .)
    }
    dis ""
    dis as text "{hline 70}"
    dis as result "  Update Complete!"
    dis as text "{hline 70}"
    dis as text "Database and version metadata updated successfully from GitHub"
    dis as text "Total articles: " as result "`n_records'"
    dis as text "Location: " as result "`display_path'"
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
        
        * Check update_date from version file
        preserve
        quietly use "`version_file_path'", clear
        
        * Get update_date variable (format: YYYY-MM-DD or similar)
        capture confirm variable update_date
        if _rc {
            restore
            exit
        }
        
        local update_date_str = update_date[1]
        restore
        
        * Parse update_date and compare with today
        * Format expected: "2025-12-08" or similar
        if strlen("`update_date_str'") >= 10 {
            local update_year = substr("`update_date_str'", 1, 4)
            local update_month = substr("`update_date_str'", 6, 2)
            local update_day = substr("`update_date_str'", 9, 2)
            
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
                noi dis as text "Last updated: " as result "`update_date_str'" as text " (" as result "`days_diff'" as text " days ago)"
                noi dis as text "Update: " `"{stata "findsj, update":findsj, update}"'
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
