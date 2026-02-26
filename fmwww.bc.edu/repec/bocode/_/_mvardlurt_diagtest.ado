*! _mvardlurt_diagtest — Diagnostic tests for mvardlurt
*! Version 1.2.0 — 2026-02-24
*!
*! Performs standard regression diagnostics after ARDL estimation.
*! Requires e() from a prior regress command.
*! Order: BG, RESET, White first (need estat), then ARCH and JB (manual).

capture program drop _mvardlurt_diagtest
program define _mvardlurt_diagtest
    version 14

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Diagnostic Tests"
    di as txt "{hline 78}"
    di as txt ""
    di as txt _col(5) "{ul:Test}" ///
       _col(35) "{ul:Statistic}" ///
       _col(52) "{ul:p-value}" ///
       _col(65) "{ul:Decision}"
    di as txt "{hline 78}"

    // ─── 1. Breusch-Godfrey Serial Correlation LM Test (lag 1) ───
    local bg_ok = 0
    capture {
        qui estat bgodfrey, lags(1)
    }
    if _rc == 0 {
        capture {
            tempname bgchi bgp
            mat `bgchi' = r(chi2)
            mat `bgp'   = r(p)
            local bg1_chi = `bgchi'[1,1]
            local bg1_p   = `bgp'[1,1]
            local bg_ok = 1
        }
    }
    if `bg_ok' {
        local bg_dec "No autocorrelation"
        if `bg1_p' < 0.05 local bg_dec "{err:Autocorrelation}"

        di as txt _col(5) "Breusch-Godfrey(1)" ///
           _col(35) as res %10.4f `bg1_chi' ///
           _col(52) as res %8.4f `bg1_p' ///
           _col(65) as txt "`bg_dec'"
    }
    else {
        di as txt _col(5) "Breusch-Godfrey" _col(35) "—" _col(52) "—" _col(65) "(not available)"
    }

    // ─── 2. Ramsey RESET Test (needs e()) ───
    local reset_ok = 0
    capture {
        qui estat ovtest
    }
    if _rc == 0 {
        capture {
            local reset_f = r(F)
            local reset_p = r(p)
            local reset_ok = 1
        }
    }
    if `reset_ok' {
        local reset_dec "Correct specification"
        if `reset_p' < 0.05 local reset_dec "{err:Misspecification}"

        di as txt _col(5) "Ramsey RESET" ///
           _col(35) as res %10.4f `reset_f' ///
           _col(52) as res %8.4f `reset_p' ///
           _col(65) as txt "`reset_dec'"
    }
    else {
        di as txt _col(5) "Ramsey RESET" _col(35) "—" _col(52) "—" _col(65) "(not available)"
    }

    // ─── 3. White Heteroskedasticity Test (needs e()) ───
    local white_ok = 0
    capture {
        qui estat imtest, white
    }
    if _rc == 0 {
        capture {
            local white_chi = r(chi2_w)
            local white_p   = r(p_w)
            if `white_chi' < . {
                local white_ok = 1
            }
        }
        if `white_ok' == 0 {
            capture {
                local white_chi = r(chi2)
                local white_p   = r(p)
                if `white_chi' < . {
                    local white_ok = 1
                }
            }
        }
    }
    if `white_ok' {
        local white_dec "Homoskedastic"
        if `white_p' < 0.05 local white_dec "{err:Heteroskedasticity}"

        di as txt _col(5) "White" ///
           _col(35) as res %10.4f `white_chi' ///
           _col(52) as res %8.4f `white_p' ///
           _col(65) as txt "`white_dec'"
    }
    else {
        di as txt _col(5) "White" _col(35) "—" _col(52) "—" _col(65) "(not available)"
    }

    // ─── 4. ARCH LM Test (manual — does NOT need estat) ───
    //    Regress e^2 on L.e^2, chi2 = N*R2 ~ Chi2(1)
    //    Done AFTER estat tests since it runs its own regress
    local arch_ok = 0
    capture {
        tempvar resid_arch resid2_arch
        qui predict double `resid_arch', residuals
        qui gen double `resid2_arch' = `resid_arch'^2
        qui regress `resid2_arch' L.`resid2_arch'
        local arch_n = e(N)
        local arch_r2 = e(r2)
        local arch_chi = `arch_n' * `arch_r2'
        local arch_p = chi2tail(1, `arch_chi')
        local arch_ok = 1
    }
    if `arch_ok' {
        local arch_dec "No ARCH effects"
        if `arch_p' < 0.05 local arch_dec "{err:ARCH effects}"

        di as txt _col(5) "ARCH(1)" ///
           _col(35) as res %10.4f `arch_chi' ///
           _col(52) as res %8.4f `arch_p' ///
           _col(65) as txt "`arch_dec'"
    }
    else {
        di as txt _col(5) "ARCH" _col(35) "—" _col(52) "—" _col(65) "(not available)"
    }

    // ─── 5. Jarque-Bera Normality Test (manual) ───
    local jb_ok = 0
    capture {
        tempvar resid_jb
        qui predict double `resid_jb', residuals
        qui su `resid_jb', detail
        local skew = r(skewness)
        local kurt = r(kurtosis)
        local n_jb = r(N)
        local jb_stat = (`n_jb'/6) * (`skew'^2 + (`kurt' - 3)^2 / 4)
        local jb_p    = chi2tail(2, `jb_stat')
        local jb_ok = 1
    }
    if `jb_ok' {
        local jb_dec "Normal residuals"
        if `jb_p' < 0.05 local jb_dec "{err:Non-normal residuals}"

        di as txt _col(5) "Jarque-Bera" ///
           _col(35) as res %10.4f `jb_stat' ///
           _col(52) as res %8.4f `jb_p' ///
           _col(65) as txt "`jb_dec'"
    }
    else {
        di as txt _col(5) "Jarque-Bera" _col(35) "—" _col(52) "—" _col(65) "(not available)"
    }

    di as txt "{hline 78}"
    di as txt _col(5) "Note: Decisions based on 5% significance level."
    di as txt ""

end
