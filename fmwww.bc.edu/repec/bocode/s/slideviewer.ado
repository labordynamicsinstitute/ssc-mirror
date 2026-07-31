*! slideviewer.ado - manage and navigate SMCL slides in the Stata Viewer
*! Eric A. Booth <eric.a.booth@gmail.com>
*! Version 2.0 : Last Updated: May 2026
** Version 1.1 : Feb 2012
** Version 1.0 : Jan 2012

program define slideviewer, rclass
    version 16
    syntax [anything], [Subdir(str asis) Navbar Post Clear]

    *-- Handle Clear
    if "`clear'" != "" {
        global S_slideviewer_subdir ""
        global S_slideviewer_current ""
        exit
    }

    *-- Handle Subdirectory Persistence
    if `"`subdir'"' != "" {
        * Clean up path (ensure no trailing slashes for consistency)
        loc subdir : subinstr local subdir "\\" "/", all
        loc subdir : subinstr local subdir "//" "/", all
        if substr(`"`subdir'"', -1, 1) == "/" {
            loc subdir = substr(`"`subdir'"', 1, length(`"`subdir'"')-1)
        }
        global S_slideviewer_subdir `"`subdir'"'
    }
    
    if "$S_slideviewer_subdir" == "" {
        * Default to "ignore" folder in PWD if nothing specified
        global S_slideviewer_subdir `"`c(pwd)'/ignore"'
    }

    *-- Get File List
    loc files : dir "$S_slideviewer_subdir" files "*.smcl"
    loc files : list sort files
    loc nfiles : word count `files'

    if `nfiles' == 0 {
        di as err "No .smcl files found in $S_slideviewer_subdir"
        exit 601
    }

    *-- Parse Input / Keyword Logic
    loc target ""
    loc cmd = lower(trim(`"`anything'"'))
    loc cmd : subinstr local cmd ".smcl" "", all

    if inlist("`cmd'", "next", "prev", "first", "last", "toc") {
        
        * Find current index
        loc current_idx = 0
        if "$S_slideviewer_current" != "" {
            loc i = 1
            foreach f in `files' {
                if "`f'" == "$S_slideviewer_current" {
                    loc current_idx = `i'
                    continue, break
                }
                loc ++i
            }
        }

        if "`cmd'" == "first" {
            loc target : word 1 of `files'
        }
        else if "`cmd'" == "last" {
            loc target : word `nfiles' of `files'
        }
        else if "`cmd'" == "next" {
            loc next_idx = `current_idx' + 1
            if `next_idx' > `nfiles' loc next_idx = 1
            loc target : word `next_idx' of `files'
        }
        else if "`cmd'" == "prev" {
            loc prev_idx = `current_idx' - 1
            if `prev_idx' < 1 loc prev_idx = `nfiles'
            loc target : word `prev_idx' of `files'
        }
        else if "`cmd'" == "toc" {
            _sv_gen_toc `"`files'"' "`navbar'"
            exit
        }
    }
    else {
        * Treat as filename
        if "`cmd'" == "" {
            * If nothing specified, show current or first
            if "$S_slideviewer_current" != "" loc target "$S_slideviewer_current"
            else loc target : word 1 of `files'
        }
        else {
            loc target "`cmd'.smcl"
        }
    }

    *-- Validate Target
    cap confirm file "$S_slideviewer_subdir/`target'"
    if _rc {
        di as err "File `target' not found in $S_slideviewer_subdir"
        exit 601
    }

    *-- Update State
    global S_slideviewer_current "`target'"

    *-- View File
    if "`navbar'" != "" {
        _sv_view_with_navbar "$S_slideviewer_subdir/`target'" "`navbar'"
    }
    else {
        view "$S_slideviewer_subdir/`target'"
    }

    *-- Post results
    if "`post'" != "" {
        return local lastslide "$S_slideviewer_current"
        return local totalscore "${totalscore}"
    }

end

*-- Helper: Generate TOC
program define _sv_gen_toc
    args files navbar_opt
    
    if "`navbar_opt'" != "" loc navopt ", navbar"
    
    tempfile tocfile
    tempname fh
    file open `fh' using "`tocfile'", write text
    
    file write `fh' "{smcl}" _n
    file write `fh' "{title:Table of Contents}" _n
    file write `fh' "{hline}" _n _n
    
    foreach f in `files' {
        loc fname : subinstr local f ".smcl" "", all
        file write `fh' `"{p 4 8 2}{stata "slideviewer `fname'`navopt'":`fname'}{p_end}"' _n
    }
    
    file write `fh' _n "{hline}" _n
    file write `fh' `"{p 4 8 2}{stata "slideviewer first`navopt'":[Back to Start]}{p_end}"' _n
    
    file close `fh'
    view "`tocfile'"
end

*-- Helper: View with Navigation Bar
program define _sv_view_with_navbar
    args sourcefile navbar_opt
    
    tempfile viewfile
    tempname fh_in fh_out
    
    file open `fh_out' using "`viewfile'", write text
    
    * Header
    file write `fh_out' "{smcl}" _n
    file write `fh_out' "{center:{stata slideviewer first, navbar:[First]}  {stata slideviewer prev, navbar:[Prev]}  {stata slideviewer toc, navbar:[TOC]}  {stata slideviewer next, navbar:[Next]}  {stata slideviewer last, navbar:[Last]}}" _n
    file write `fh_out' "{hline}" _n
    
    * Content
    file open `fh_in' using "`sourcefile'", read text
    file read `fh_in' line
    while r(eof) == 0 {
        * Skip {smcl} tag in source to avoid nested tags if possible, though Stata handles it okay
        if trim(lower("`line'")) != "{smcl}" {
            file write `fh_out' `"`line'"' _n
        }
        file read `fh_in' line
    }
    file close `fh_in'
    
    * Footer
    file write `fh_out' "{hline}" _n
    file write `fh_out' "{center:{stata slideviewer first, navbar:[First]}  {stata slideviewer prev, navbar:[Prev]}  {stata slideviewer toc, navbar:[TOC]}  {stata slideviewer next, navbar:[Next]}  {stata slideviewer last, navbar:[Last]}}" _n
    
    file close `fh_out'
    view "`viewfile'"
end
