*! importr - Dual-bridge (R/Python) importer for R data files
*! Eric A. Booth <eric.a.booth@gmail.com>
*! Version 2.0.0 : May 2026
** Version 1.0.0 : May 2026

program define importr, rclass
    version 16
    syntax using/ [, Replace CLEAR RDS]

    *-- Extension Check
    loc ext = lower(substr(`"`using'"', -6, .))
    loc is_rds = 0
    if strpos("`ext'", ".rds") | "`rds'" != "" loc is_rds = 1

    *-- 1. Try to find R
    qui cap shell Rscript --version
    if _rc == 0 {
        di as txt "Method: R Bridge (using Rscript)"
        _sv_run_r `"`using'"' `is_rds' `"`clear'"'
        exit
    }

    *-- 2. Fallback: Try Stata's Python Integration
    cap python which pyreadstat
    if _rc == 0 {
        di as txt "Method: Python Bridge (using pyreadstat)"
        _sv_run_python `"`using'"' `is_rds' `"`clear'"'
        exit
    }

    *-- 3. Both failed
    di as err "Import failed: Neither R (Rscript) nor the Python 'pyreadstat' library were found."
    di as txt _n "To use the Python fallback, run the following in Stata:"
    di as smcl "{stata python pip install pyreadstat}"
    exit 198
end

program define _sv_run_r
    args using is_rds clear
    tempfile dtafile rscript
    loc dtafile : subinstr local dtafile "\\" "/", all
    
    tempname fh
    qui file open `fh' using "`rscript'", write text replace
    file write `fh' "if (!require('haven')) install.packages('haven', repos='https://cloud.r-project.org/')" _n
    if `is_rds' file write `fh' "df <- readRDS('`using'')" _n
    else {
        file write `fh' "load('`using'')" _n
        file write `fh' "df <- get(ls()[1])" _n
    }
    file write `fh' "if (!is.data.frame(df)) df <- as.data.frame(df)" _n
    file write `fh' "haven::write_dta(df, '`dtafile'', version = 14)" _n
    file close `fh'

    qui shell Rscript "`rscript'"
    
    cap confirm file "`dtafile'"
    if _rc {
        di as err "R conversion failed. Check that 'haven' is installed in R."
        exit 198
    }
    
    use "`dtafile'", `clear'
    _sv_report "`using'"
    
    return local filename "`using'"
    return scalar nobs = _N
    return scalar nvars = c(k)
end

program define _sv_run_python
    args using is_rds clear
    tempfile dtafile
    loc dtafile : subinstr local dtafile "\\" "/", all
    
    python:
import pyreadstat
import os

try:
    using = r"`using'"
    is_rds = int("`is_rds'")
    temp_dta = r"`dtafile'"
    
    if is_rds:
        df, meta = pyreadstat.read_rds(using)
    else:
        df, meta = pyreadstat.read_rport(using)
    
    pyreadstat.write_dta(df, temp_dta)
except Exception as e:
    print(f"\nPython Error: {e}")
end

    cap confirm file "`dtafile'"
    if _rc {
        di as err "Python conversion failed. Ensure 'pyreadstat' is functioning correctly."
        exit 198
    }

    use "`dtafile'", `clear'
    _sv_report "`using'"
    
    return local filename "`using'"
    return scalar nobs = _N
    return scalar nvars = c(k)
end

program define _sv_report
    args file
    di as smcl _n "{text}Successfully imported {res}`file'{text}."
    di as txt "Obs: " as res _N "  Vars: " as res c(k)
end
