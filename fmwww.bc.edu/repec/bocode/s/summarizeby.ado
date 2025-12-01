*! version 1.2.0  20nov2025  I I Bolotov
program def summarizeby
    version 8.0
    /*
        This program allows to perform statsby with summarize on all variables.

        Author: Ilya Bolotov, MBA Ph.D.
        Date: 15 November 2020
    */
    // syntax
    syntax ///
    [anything(name=exp_list equalok)] [fw iw pw aw] [if] [in] ///
    [, CLEAR SAving(string) Detail MEANonly Format *]
    tempfile tmpf

    // accumulate summarize results for each variable into `tmpf'
    foreach var of varlist * {
        preserve
        qui statsby `exp_list' `if' `in' `weight', clear `options': ///
            sum `var', `detail' `meanonly' `format'
        gen variable = "`var'"
        cap append using `tmpf'
        qui save `tmpf', replace
        restore
    }

    // work with `tmpf'
    if "`clear'" != "" & "`saving'" != "" {
        di as err "clear and saving() are mutually exclusive options"
        exit 198
    }

    if trim("`clear'`saving'") != "" {
        if trim("`saving'") != "" {
            preserve
        }

        cap confirm file `tmpf'
        if _rc {
            di as err "no results generated; nothing to load"
            exit 498
        }

        use `tmpf', clear
        tempvar id
        gen `id' = _n
        gsort -`id'
        drop `id'
        order variable
        label var variable "variable name"

        if trim("`saving'") != "" {
            save "`saving'", replace
        }
    }
    else {
        di as err "specify either clear or saving()"
        exit 198
    }
end
