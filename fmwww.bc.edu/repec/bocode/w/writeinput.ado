*! writeinput - advanced dataset-to-input command generator
*! Eric A. Booth <eric.a.booth@gmail.com>
*! Version 3.0.1 : Jul 2026
** Version 3.0.0 : May 2026
** Version 2.0.0 : May 2026
** Version 1.0.1 : Mar 2011

program define writeinput, rclass
    version 16
    syntax varlist [if] [in] [using/] [, ///
        Replace noCLEAR Append ///
        Note(str asis) Header(str asis) ///
        Labels Dates Dryrun Markdown ///
        Precision(str) Maxobs(integer 500) ///
        Sort(varlist) Sample(integer 0) Seed(integer 0) ///
        Varlab Generic Frame(name) ]

    *-- Handle Frame
    if "`frame'" != "" {
        loc original_frame "`c(frame)'"
        cap frame change `frame'
        if _rc {
            di as err "Frame `frame' not found"
            exit 111
        }
    }

    *-- Handle 'using' and 'dryrun'
    if "`using'" == "" & "`dryrun'" == "" & "`markdown'" == "" {
        di as err "must specify 'using filename', 'dryrun', or 'markdown'"
        exit 198
    }

    if "`using'" != "" {
        loc check : subinstr local using ".do" "", count(loc howmany)
        if "`howmany'" == "0" loc using "`using'.do"

        cap confirm file `"`using'"'
        if !_rc & "`replace'" == "" & "`append'" == "" {
            di as err "File `using' exists; specify 'replace' or 'append' option"
            exit 198
        }
    }

    *-- Validate precision() early so Mata never sees a bad format
    if "`precision'" != "" & "`precision'" != "hex" {
        cap loc pchk = string(1, "`precision'")
        if _rc | "`pchk'" == "" {
            di as err "invalid precision() format: `precision'"
            exit 120
        }
    }

    *-- Filter data (novarlist: rows with missing values must be kept,
    *-- else they silently vanish from the serialized dataset)
    marksample touse, strok novarlist

    qui {
        preserve
        keep if `touse'

        *-- Handle Sample/Seed
        if `sample' > 0 {
            if `seed' > 0 set seed `seed'
            sample `sample', count
        }

        *-- Handle Sort
        if "`sort'" != "" sort `sort'

        *-- Handle Maxobs
        loc truncated = 0
        if `maxobs' > 0 & _N > `maxobs' {
            keep in 1/`maxobs'
            loc truncated = 1
        }

        if _N == 0 {
            noi di as err "no observations"
            restore
            if "`original_frame'" != "" frame change `original_frame'
            exit 2000
        }

        *-- Handle Generic (Anonymize)
        if "`generic'" != "" {
            loc i = 1
            foreach v in `varlist' {
                rename `v' v`i'
                loc new_varlist "`new_varlist' v`i'"
                loc ++i
            }
            loc varlist "`new_varlist'"
        }

        *-- Handle Labels option
        if "`labels'" != "" {
            foreach v in `varlist' {
                loc lblname : value label `v'
                if "`lblname'" != "" {
                    decode `v', gen(`v'_lab)
                    drop `v'
                    rename `v'_lab `v'
                }
            }
        }

        *-- Handle Dates option
        if "`dates'" != "" {
            foreach v in `varlist' {
                loc fmt : format `v'
                if strpos("`fmt'", "t") | strpos("`fmt'", "d") {
                    tempvar `v'_str
                    gen str ``v'_str' = string(`v', "`fmt'")
                    drop `v'
                    rename ``v'_str' `v'
                }
            }
        }

        *-- Input Statement
        loc inp_line "input"
        foreach v in `varlist' {
            loc type : type `v'
            loc inp_line "`inp_line' `type' `v'"
        }

        *-- Emit everything (file and/or screen) in Mata.  Data values,
        *-- header(), and note() text reach the output via st_local()/
        *-- st_sdata(), which the macro processor never re-expands, so
        *-- $, `, and embedded quotes in the data survive verbatim.
        *-- (Values containing the sequence  "'  still cannot be quoted;
        *-- that is a limitation of Stata's input syntax itself.)
        loc file_mode = cond("`append'" != "", "a", "w")
        noi mata: _writeinput_emit()

        if "`using'" != "" {
            noi di as smcl _n "Output file written to: {browse `using'}"
        }

        *-- Post results
        return local filename "`using'"
        return scalar nobs = _N
        return scalar nvars = `: word count `varlist''
        return local varlist "`varlist'"
        return scalar truncated = `truncated'

        restore
        if "`original_frame'" != "" frame change `original_frame'
    }
end


version 16
mata:

// write one generated line to the file and/or the screen
void _writeinput_put(real scalar fh, real scalar scrn, string scalar s)
{
    if (fh >= 0) fput(fh, s)
    if (scrn) printf("{txt}%s\n", s)
}

// serialize one numeric value; strofreal() maps ., .a, ... correctly
string scalar _writeinput_num(real scalar x, string scalar type,
    string scalar prec)
{
    if (prec == "hex") return(strofreal(x, "%21x"))
    if (prec != "")    return(strofreal(x, prec))
    // defaults are round-trip exact: %12.0g covers byte/int/long/float,
    // doubles need up to 17 significant digits
    if (type == "double") return(strofreal(x, "%21.0g"))
    return(strofreal(x, "%12.0g"))
}

void _writeinput_emit()
{
    string scalar    fn, dry, md, prec, s, line, cqo, cqc
    string rowvector vars
    real rowvector   idx
    real scalar      fh, scrn, i, j, nv, N

    fn   = st_local("using")
    dry  = st_local("dryrun")
    md   = st_local("markdown")
    prec = st_local("precision")
    vars = tokens(st_local("varlist"))
    idx  = st_varindex(vars)
    nv   = cols(vars)
    N    = st_nobs()
    scrn = (dry != "" | md != "")
    cqo  = char(96) + char(34)      // `"
    cqc  = char(34) + char(39)      // "'

    fh = -1
    if (fn != "") {
        if (st_local("file_mode") == "w") _unlink(fn)
        fh = _fopen(fn, st_local("file_mode"))
        if (fh < 0) {
            errprintf("file %s could not be opened\n", fn)
            exit(error(603))
        }
    }

    // screen-only decorations
    if (md != "") _writeinput_put(-1, scrn, "```stata")
    else if (dry != "") {
        printf("{txt}{hline}\n")
        printf("{txt}{title:Generated Input Command}\n")
        if (st_local("truncated") == "1") {
            printf("{res}** Truncated to %s observations **\n",
                st_local("maxobs"))
        }
        printf("{txt}{hline}\n")
    }

    // header block
    if (st_local("header") != "") _writeinput_put(fh, scrn, st_local("header"))
    if (st_local("clear") != "noclear") _writeinput_put(fh, scrn, "clear")

    // variable labels as comments
    if (st_local("varlab") != "") {
        for (j=1; j<=nv; j++) {
            s = st_varlabel(idx[j])
            if (s != "") {
                _writeinput_put(fh, scrn,
                    "** var: " + vars[j] + "  label: " + s)
            }
        }
    }

    // input statement
    _writeinput_put(fh, scrn, st_local("inp_line"))

    // data rows
    for (i=1; i<=N; i++) {
        line = ""
        for (j=1; j<=nv; j++) {
            if (st_isstrvar(idx[j])) {
                s = cqo + st_sdata(i, idx[j]) + cqc
            }
            else {
                s = _writeinput_num(st_data(i, idx[j]),
                    st_vartype(idx[j]), prec)
            }
            line = line + (j > 1 ? " " : "") + s
        }
        _writeinput_put(fh, scrn, line)
    }

    // footer
    _writeinput_put(fh, scrn, "end")
    if (st_local("note") != "") {
        _writeinput_put(fh, scrn, "** " + st_local("note"))
    }
    if (st_local("truncated") == "1") {
        _writeinput_put(fh, scrn,
            "** Truncated to " + st_local("maxobs") + " observations")
    }

    if (md != "") _writeinput_put(-1, scrn, "```")
    else if (dry != "") printf("{txt}{hline}\n")

    if (fh >= 0) fclose(fh)
}

end
