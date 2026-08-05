*! importr - Dual-bridge (R/Python) importer for R data files
*! Eric A. Booth <eric.a.booth@gmail.com>
*! Version 2.0.2 : Aug 2026
*!   - the R and Python bridge subroutines are now rclass, so a successful
*!     import no longer exits with r(151) "non r-class program may not set r()".
*!   - bridge selection no longer probes with -shell Rscript --version-: -shell-
*!     reports success whenever the shell ran, so R was always chosen and the
*!     Python fallback was unreachable.  Each bridge is attempted in turn.
*!   - the Python bridge writes a .py temp file; -python script- rejects the
*!     extensionless name -tempfile- returns.
*!   - paths are normalised to forward slashes before going into R string
*!     literals, so Windows paths parse.
*! Version 2.0.1 : Aug 2026
*!   - check the file exists before trying either bridge, so a mistyped path
*!     reports the path rather than a bridge/library failure.
** Version 2.0.0 : May 2026
** Version 1.0.0 : May 2026

program define importr, rclass
    version 16
    * -replace- used to be accepted here and then never referenced anywhere in
    * the program: it was a silent no-op, so -importr using x, replace- looked
    * like it did something and did not.  Removed rather than left as a trap.
    syntax using/ [, CLEAR RDS]

    *-- 0. Does the file actually exist?
    * Without this, a typo in the filename falls all the way through to a
    * bridge, which then fails for its own reasons and reports something like
    * "Ensure 'pyreadstat' is functioning correctly" -- sending the user off to
    * debug a Python install when the real problem is the path.
    cap confirm file `"`using'"'
    if _rc {
        di as err `"importr: file not found -- `using'"'
        exit 601
    }

    *-- Extension Check
    loc ext = lower(substr(`"`using'"', -6, .))
    loc is_rds = 0
    if strpos("`ext'", ".rds") | "`rds'" != "" loc is_rds = 1

    *-- 1. Try the R bridge.
    * Detection used to be -qui cap shell Rscript --version-, testing _rc.  That
    * does not work: -shell- reports success whenever the shell itself ran, so a
    * machine with no R still came back _rc==0.  importr therefore always claimed
    * the R bridge and exited 198, and the Python fallback below was unreachable.
    * Rather than probe, just attempt each bridge and judge it by whether a
    * dataset actually arrived -- which is the thing we care about anyway, and
    * needs no per-platform knowledge of how to locate an executable.
    * The attempt is -capture-d so a missing R stays silent and we can fall
    * through; that also hides the success report, so importr prints it here.
    cap _sv_run_r `"`using'"' `is_rds' `"`clear'"'
    if _rc == 0 {
        return add
        di as txt "Method: R bridge (Rscript)"
        _sv_report `"`using'"'
        exit
    }

    *-- 2. Fall back to Stata's Python integration.
    cap _sv_run_python `"`using'"' `is_rds' `"`clear'"'
    if _rc == 0 {
        return add
        di as txt "Method: Python bridge (pyreadr)"
        _sv_report `"`using'"'
        exit
    }

    *-- 3. Neither bridge worked.
    di as err "importr: could not read `using'."
    di as txt "  importr needs one of:"
    di as txt "  - R on the system path, with the 'haven' package, or"
    di as txt "  - Stata's Python integration, with pyreadr and pyreadstat."
    di as txt _n "  For the Python route, in Stata:"
    di as smcl "  {stata python pip install pyreadr pyreadstat}"
    di as txt "  If R is installed but not found, check that Rscript is on the"
    di as txt "  path Stata sees ({stata di c(os)}: see {help shell})."
    exit 198
end

program define _sv_run_r, rclass
    args using is_rds clear
    tempfile dtafile rscript

    * Both paths are pasted into R string literals below, and R treats a
    * backslash as an escape: 'C:\data\x.Rdata' fails to parse on Windows.  R
    * accepts forward slashes on every platform, so normalise both.  (The old
    * -subinstr local dtafile "\\" "/"- looked for two adjacent backslashes,
    * which is not what a Windows path contains, and left -using- untouched.)
    local using   = subinstr(`"`macval(using)'"',   char(92), "/", .)
    local dtafile = subinstr(`"`macval(dtafile)'"', char(92), "/", .)

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
    
    return local filename "`using'"
    return scalar nobs = _N
    return scalar nvars = c(k)
end

program define _sv_run_python, rclass
    args using is_rds clear
    tempfile dtafile pystub
    loc dtafile : subinstr local dtafile "\\" "/", all

    * -python script- refuses any file whose name does not end in .py, and
    * -tempfile- hands back an extensionless name, so borrow the temp name and
    * add the suffix.  (Rscript has no such rule, hence only Python needs it.)
    local pyscript `"`pystub'.py"'

    * The Python is written to a temp .py and run with -python script-, the
    * same shape as the R bridge above.  It used to be an inline -python: ...
    * end- block, which cannot live inside a program: that terminating -end-
    * is read as the end of -program define-, so the rest of this file was
    * never parsed and _sv_run_r, _sv_run_python and _sv_report were left
    * undefined.  importr could not run at all.
    *
    * Reading R files is pyreadr's job, not pyreadstat's; the old block called
    * pyreadstat.read_rds()/read_rport(), neither of which reads .Rdata --
    * read_rport is the SAS XPORT reader.  pyreadstat still writes the .dta.
    tempname fh
    qui file open `fh' using "`pyscript'", write text replace
    file write `fh' "import sys" _n
    file write `fh' "try:" _n
    file write `fh' "    import pyreadr, pyreadstat" _n
    file write `fh' "except ImportError as e:" _n
    file write `fh' "    print('importr: missing library -- ' + str(e))" _n
    file write `fh' "    sys.exit(0)" _n
    file write `fh' "src = r'''`using''''" _n
    file write `fh' "out = r'''`dtafile''''" _n
    file write `fh' "try:" _n
    if `is_rds' {
        file write `fh' "    df = pyreadr.read_r(src)[None]" _n
    }
    else {
        file write `fh' "    res = pyreadr.read_r(src)" _n
        file write `fh' "    df = res[list(res.keys())[0]]" _n
    }
    file write `fh' "    pyreadstat.write_dta(df, out)" _n
    file write `fh' "except Exception as e:" _n
    file write `fh' "    print('importr: conversion failed -- ' + str(e))" _n
    file close `fh'

    cap noisily python script "`pyscript'"

    cap confirm file "`dtafile'"
    if _rc {
        di as err "importr: the Python bridge did not produce a dataset."
        di as txt "  It needs both pyreadr (to read the R file) and pyreadstat"
        di as txt "  (to write the .dta):"
        di as smcl "{stata python pip install pyreadr pyreadstat}"
        exit 198
    }

    use "`dtafile'", `clear'
    
    return local filename "`using'"
    return scalar nobs = _N
    return scalar nvars = c(k)
end

program define _sv_report
    args file
    di as smcl _n "{text}Successfully imported {res}`file'{text}."
    di as txt "Obs: " as res _N "  Vars: " as res c(k)
end
