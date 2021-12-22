*! 1.1.0 NJC 9 March 2021 renamed given clash with official Stata help 
*! 1.0.0 NJC 8 January 1999
program define dissim_index  
    version 5.0
    local varlist "req ex min(2)"
    local if "opt"
    local in "opt"
    local options "Matrix(str)"
    parse "`*'"
    parse "`varlist'", parse(" ")

    tempvar diff
    tempname D isum jsum

    qui gen `diff' = .
    local nvars : word count `varlist'
    mat `D' = J(`nvars',`nvars',0)

    local i = 1
    qui while `i' <= `nvars' {
            local j = `i' + 1
            while `j' <= `nvars' {
                    capture assert ``i'' >= 0 & ``j'' >= 0 `if' `in'
                    if _rc == 9 {
                            di in r "``i'' and ``j'': " _c
                            error 411
                    }
                    su ``i'' `if' `in', meanonly
                    scalar `isum' = _result(18)
                    su ``j'' `if' `in', meanonly
                    scalar `jsum' = _result(18)
                    replace `diff' = abs((``i''/`isum')-(``j''/`jsum')) `if' `in'
                    su `diff', meanonly
                    mat `D'[`i',`j'] = _result(18) / 2
                    mat `D'[`j',`i'] = _result(18) / 2
                    local j = `j' + 1
            }
            local i = `i' + 1
    }

    qui count `if' `in'
    local n = _result(1)
    di in g "(obs=`n')"

    mat rownames `D' = `varlist'
    mat colnames `D' = `varlist'
    mat li `D', f(%10.4f) noheader

    if "`matrix'" != "" { mat `matrix' = `D' }
end