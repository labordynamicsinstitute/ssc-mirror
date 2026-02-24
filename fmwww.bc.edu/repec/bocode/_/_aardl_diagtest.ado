*! _aardl_diagtest — Diagnostic Tests for AARDL
*! Version 1.1.0
*! Pattern follows _fbardl_diagtest.ado (proven working)
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _aardl_diagtest
program define _aardl_diagtest
    version 17

    syntax varname, df_r(integer) nobs(integer)

    local resid "`varlist'"

    // =========================================================================
    // DIAGNOSTIC TESTS
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 4: Diagnostic Tests"
    di as txt "{hline 78}"
    di as txt ""
    di as txt "  {hline 68}"
    di as txt _col(5) "Test" _col(35) "Statistic" _col(50) "p-value" _col(63) "Result"
    di as txt "  {hline 68}"

    // ─── A. JARQUE-BERA (follows fbardl pattern with precedence fix) ───
    capture qui sum `resid', detail
    if _rc == 0 {
        local n = r(N)
        local skew = r(skewness)
        local kurt = r(kurtosis)

        // JB = (n/6) * [ S^2 + (K-3)^2 / 4 ]
        // NOTE: parentheses around (`skew') are critical!
        //   Stata evaluates -0.1^2 as -(0.1^2)=-0.01, NOT (-0.1)^2=0.01
        local jb = (`n' / 6) * ((`skew')^2 + ((`kurt') - 3)^2 / 4)
        local jb_p = chi2tail(2, `jb')

        local jb_result "Normal"
        if `jb_p' < 0.05 local jb_result "Non-Normal"

        di as txt _col(5) "Jarque-Bera" _col(33) as res %10.4f `jb' ///
           _col(48) %8.4f `jb_p' _col(63) "`jb_result'"
    }

    // ─── B. BREUSCH-GODFREY SERIAL CORRELATION ───
    // Manual LM — no dependence on e() (follows fbardl pattern)
    local bg_chi = .
    local bg_p = .
    capture {
        tempvar resid_copy
        qui gen double `resid_copy' = `resid'
        qui regress `resid_copy' L(1/2).`resid_copy'
        local bg_r2 = e(r2)
        local bg_n = e(N)
        local bg_chi = `bg_n' * `bg_r2'
        local bg_p = chi2tail(2, `bg_chi')
    }
    if `bg_p' < . {
        local bg_result "No SC"
        if `bg_p' < 0.05 local bg_result "Serial Corr."
        di as txt _col(5) "BG-LM (2 lags)" _col(33) as res %10.4f `bg_chi' ///
           _col(48) %8.4f `bg_p' _col(63) "`bg_result'"
    }

    // ─── C. ARCH LM ───
    local arch_F = .
    local arch_p = .
    capture {
        tempvar esq
        qui gen double `esq' = `resid'^2
        qui regress `esq' L.`esq'
        local arch_F = e(F)
        local arch_p = Ftail(e(df_m), e(df_r), e(F))
    }
    if `arch_p' < . {
        local arch_result "Homoskedastic"
        if `arch_p' < 0.05 local arch_result "ARCH effects"
        di as txt _col(5) "ARCH LM (1 lag)" _col(33) as res %10.4f `arch_F' ///
           _col(48) %8.4f `arch_p' _col(63) "`arch_result'"
    }

    // ─── D. RAMSEY RESET ───
    // Requires e() from the ARDL regression (restored before calling this)
    local reset_p = .
    capture {
        qui estat ovtest
        local reset_F = r(F)
        local reset_p = r(p)
    }
    if `reset_p' < . {
        local reset_result "Correct spec"
        if `reset_p' < 0.05 local reset_result "Misspecified"
        di as txt _col(5) "Ramsey RESET" _col(33) as res %10.4f `reset_F' ///
           _col(48) %8.4f `reset_p' _col(63) "`reset_result'"
    }
    else {
        di as txt _col(5) "Ramsey RESET" _col(33) as txt "(not available)"
    }

    di as txt "  {hline 68}"
    di as txt _col(5) "*** p<0.01, ** p<0.05, * p<0.10"

end
