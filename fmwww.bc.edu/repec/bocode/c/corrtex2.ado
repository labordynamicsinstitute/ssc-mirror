*! **************************************
*! corrtex2.ado v2.9 (13Aug2025) Adapted from corrtex (by Nicholas Couderc,2006)
*! Export correlation matrix to LaTeX with significance stars	
*! FIXED: Proper by-group handling and casewise deletion

*!    Wu Lianghai
*!    Anhui University of Technology (AHUT)
*!    Email: agd2010@yeah.net

*!    Hu Fangfang
*!    Wanjiang University of Technology (WJUT)
*!    Email: huff470@163.com
*!
*!    Wu Hanyan
*!    Nanjing University of Aeronautics and Astronautics (NUAA)
*!    Email: 2325476320@qq.com

*!    Zhao Xin
*!    Anhui University of Technology (AHUT)
*!    Email: 1980124145@qq.com

*! **************************************

set more off
cap prog drop corrtex2
program corrtex2, byable(recall)
version 9.0

syntax [varlist(default=none)] [if] [in], [LANDscape] [LONGtable] [FILE(string)] ///
[Append] [Replace] [DIGits(integer 3)] [CASEwise] [PLacement(string)] [TITle(string)] ///
[KEY(string)] [NA(string)] [NOscreen] [NBobs] [FONTsize(string)]

// Validate syntax
if "`varlist'"=="" {
    di as error "varlist required"
    exit
}
if "`file'"=="" {
    di as error "Output file required"
    exit
}
if `digits'<0 | `digits' >20 {
    di as error "Digits must be 0-20"
    exit
}
if "`append'"!="" & "`replace'"!="" {
    di as error "Use either APPEND or REPLACE"
    exit
}

tempvar touse
mark `touse' `if' `in'

// Casewise deletion - MUST be before by-group processing
if "`casewise'"~="" {
    marksample touse, novarlist
}

// Calculate total number of by-groups
local bynvals 1
if _by() {
    qui replace `touse'=0 if `_byindex' != _byindex()
    tempname bycount
    qui levelsof `_byindex' if `touse', local(bygroups)
    local bynvals: word count `bygroups'
}

tempname fich

// File handling
if _by() {
    if _byindex() > 1 {
        local replace = ""
        local append = "append"
    }
}
tokenize "`file'", parse(.)
if "`3'"=="" {
    local file = "`1'.tex"
}
file open `fich' using `file', write `append' `replace' text

// LaTeX preamble
if (_byindex() == 1 | !_by()) & "`append'"=="" {
    file write `fich' "\documentclass[UTF8]{article}" _n
    file write `fich' "\usepackage{ctex}" _n
    file write `fich' "\usepackage{amsmath}" _n
    file write `fich' "\usepackage{booktabs}" _n
    file write `fich' "\usepackage{geometry}" _n
    file write `fich' "\usepackage{pdflscape}" _n
    file write `fich' "\usepackage{longtable}" _n
    file write `fich' "\usepackage{array}" _n
    file write `fich' "\usepackage{multirow}" _n
    file write `fich' "\usepackage[utf8]{inputenc}" _n
    file write `fich' "\usepackage{dcolumn}" _n
    file write `fich' "\newcolumntype{d}[1]{D{.}{.}{#1}}" _n
    file write `fich' "\begin{document}" _n
    
    if "`fontsize'"=="" local fontsize "\normalsize"
    file write `fich' "`fontsize'" _n
}

// Table setup
local width = `digits' + 3
local cformat "%`width'.`digits'f"
local n_rows: list sizeof varlist
local n_cols: list sizeof varlist

// Optimized column formatting using dcolumn
local tablelong " l "
forvalues cols = 1/`n_cols' {
    local tablelong "`tablelong' d{-1} "
}
local n_cols_plus1 = `n_cols' + 1

// Table headers
if "`placement'"=="" local placement "htbp"
if "`fontsize'"=="" local fontsize "\normalsize"

if _by() local by = _byindex()

if "`na'"!="" local na2 "na(`na')"
if "`title'"=="" local title "Cross-correlation table"
if "`key'"=="" local key "corrtable"
if _by() {
    local title "`title' `by'"
    local key "`key'`by'"
}

// Table start
if "`landscape'"!="" file write `fich' "\begin{landscape}" _n

if "`longtable'"=="" {
    file write `fich' "\begin{table}[`placement']" _n
    file write `fich' "\centering" _n
    file write `fich' "\caption{`title'\label{`key'}}" _n
    file write `fich' "\begin{tabular}{`tablelong'}\toprule" _n
}
else {
    file write `fich' "\begin{center}"_n
    file write `fich' "\begin{longtable}{`tablelong'}" _n
    file write `fich' "\caption{`title'\label{`key'}} \\ \toprule" _n
    file write `fich' "\endfirsthead" _n
    file write `fich' "\multicolumn{`n_cols_plus1'}{l}{\emph{... table \thetable{} continued}} \\ \midrule " _n
    file write `fich' "\endhead" _n
    file write `fich' "\midrule" _n
    file write `fich' "\multicolumn{`n_cols_plus1'}{r}{\emph{Continued...}}\\" _n
    file write `fich' "\endfoot" _n
    file write `fich' "\bottomrule"  _n
    file write `fich' "\endlastfoot" _n
}

// Column headers
file write `fich' "Variables " 
foreach var of local varlist {
    local lab: variable label `var'
    if `"`lab'"'=="" local lab "`var'"
    file write `fich' " & \multicolumn{1}{c}{`lab'}"
}
file write `fich' " \\ \midrule" _n

// Calculate correlations - CRITICAL FIX: Use `touse' instead of `if' `in'
forvalues row = 1/`n_rows' {
    forvalues col = 1/`row' {
        local var1: word `row' of `varlist'
        local var2: word `col' of `varlist'
        qui corr `var1' `var2' if `touse'  // FIX: Use touse marker
        local val_`row'`col' = r(rho)
        local n_`row'`col' = r(N)
        local n_temp = r(N)
        local rho_temp = r(rho)
        local df = `n_temp' - 2

        // Handle cases where we cannot compute p-value
        if `df' <= 0 {
            local p_`row'`col' = 1
        }
        else if abs(`rho_temp') == 1 {
            local p_`row'`col' = 0
        }
        else {
            local t = abs(`rho_temp') * sqrt(`df') / sqrt(1 - `rho_temp'^2)
            local p_`row'`col' = 2 * ttail(`df', `t')
        }
    } 
}

// Table body
forvalues row = 1/`n_rows' {
    local var: word `row' of `varlist'
    local lab: variable label `var'
    if `"`lab'"'=="" local lab "`var'"
    file write `fich' "`lab'"
    
    forvalues col = 1/`row' {
        file write `fich' " & "
        if `row' == `col' {
            file write `fich' "1.000"
        }
        else {
            local star = ""
            if `p_`row'`col'' < 0.01 local star "***"
            else if `p_`row'`col'' < 0.05 local star "**"
            else if `p_`row'`col'' < 0.10 local star "*"
            
            // Format number with proper decimal alignment
            local num = `val_`row'`col''
            local num_str = string(`num', "%`width'.`digits'f")
            
            // Write number with star
            file write `fich' "`num_str'"
            if "`star'" != "" {
                file write `fich' "^{\mathrm{`star'}}"
            }
        }
    }
    file write `fich' " \\" _n
    
    // Observation counts - fixed alignment
    if "`nbobs'"~="" {
        file write `fich' "Observations"
        forvalues col = 1/`row' {
            if `row' == `col' {
                file write `fich' " & "
            }
            else {
                // Format number with commas
                local obs_num = `n_`row'`col''
                local obs_str : di %12.0fc `obs_num'
                file write `fich' " & `obs_str' "
            }
        }
        file write `fich' " \\" _n
    }
}

// Significance note
file write `fich' "\midrule" _n
file write `fich' "\multicolumn{`n_cols_plus1'}{l}{\footnotesize \textit{Notes: *** p $< 0.01$, ** p $< 0.05$, * p $< 0.10$}} \\" _n

// Table footer
if "`longtable'"=="" {
    file write `fich' "\bottomrule" _n
    file write `fich' "\end{tabular}" _n
    file write `fich' "\end{table}" _n
}
else {
    file write `fich' "\end{longtable}"_n
    file write `fich' "\end{center}" _n
}

if "`landscape'"!="" file write `fich' "\end{landscape}" _n

// Document footer
if "`append'"=="" {
    if _by() {
        if _byindex() == `bynvals' {
            file write `fich' "\end{document}" _n
        }
    }
    else {
        file write `fich' "\end{document}" _n
    }
}	
file close `fich'

capture confirm file "`file'"
if _rc {
    di as error "File "`file'" not found!"
    exit
}

tempfile tempout
file open out using "`tempout'", write text replace

tempname in
file open `in' using "`file'", read text

local found 0
local lastLine ""

file read `in' line
while r(eof)==0 {
    if strpos(`"`line'"', "\end{document}") > 0 {
        local found 1
        local lastLine `"`line'"'
    }
    else {
        file write out `"`line'"' _n
    }
    file read `in' line
}
file close `in'

if `found' {
    file write out `"`lastLine'"' _n
    file close out
    
    copy "`tempout'" "`file'", replace
    di "Success: Moved '\end{document}' to the end of file"
}
else {
    file close out
    di "Note: '\end{document}' not found. You need to manually append it at the end of the tex file."
}

if "`noscreen'"=="" type `file'
di as result "Output written to: " as txt "`file'"
end