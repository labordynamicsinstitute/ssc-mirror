*! _cobreakcoint_display.ado — Publication-quality output tables
*! Version 1.0.0 — 2026-04-18
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _cobreakcoint_display
program define _cobreakcoint_display
    version 14
    syntax, DEPvar(string) INDepvar(string) Model(string) ///
        Tobs(string) Px(string) Nk(string) Maxm(string) ///
        KLags(string)

    local model_n  = real("`model'")
    local tobs_n   = real("`tobs'")
    local px_n     = real("`px'")
    local nk_n     = real("`nk'")
    local maxm_n   = real("`maxm'")

    local cv01 = 2.576
    local cv05 = 1.960
    local cv10 = 1.645

    // Model label
    if `model_n' == 1 {
        local modlab "I (mean shifts)"
    }
    else {
        local modlab "II (trend + intercept shifts)"
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  BANNER
    // ═══════════════════════════════════════════════════════════════════════
    di ""
    di as text "  {hline 78}"
    di as text "  {bf:cobreakcoint} {c -} Quasi-Likelihood Ratio Tests" ///
               "  | v1.0.0  `=c(current_date)'"
    di as text "  Tests for Cointegration, Cobreaking & Cotrending"
    di as text "  {hline 78}"
    di ""

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 1: MODEL INFORMATION
    // ═══════════════════════════════════════════════════════════════════════
    di as text "  {bf:Model Information}"
    di as text "  {hline 78}"
    di as text "  " %-24s "Dependent variable"   " : " ///
               as result %-14s "`depvar'" ///
               as text "  " %-18s "Model type" " : " as result "`modlab'"
    di as text "  " %-24s "Independent variable" " : " ///
               as result %-14s "`indepvar'" ///
               as text "  " %-18s "Observations (T)" " : " as result "`tobs'"
    di as text "  " %-24s "Stochastic regressors" " : " ///
               as result %-14s "`px'" ///
               as text "  " %-18s "Max breaks (M)" " : " as result "`maxm'"
    di as text "  " %-24s "DOLS lags/leads"       " : " ///
               as result %-14s "`klags'" ///
               as text "  " %-18s "Trimming (e)" " : " as result "0.15"
    di as text "  " %-24s "Endogeneity corr."     " : " ///
               as result "DOLS (Saikkonen, 1991)"
    di as text "  {hline 78}"
    di ""

    // Retrieve stored matrices
    tempname TestM ACV5 Bfm
    matrix `TestM' = _cbc_TestM
    matrix `ACV5'  = _cbc_ACV5
    matrix `Bfm'   = _cbc_Bfm

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 2: ROBUST COINTEGRATION TESTS
    // ═══════════════════════════════════════════════════════════════════════
    di as text "  {bf:Robust Cointegration Tests (Qr)} {c -} H0: Cointegration"
    di as text "  {hline 78}"

    // Check if 2 breaks enabled
    if `maxm_n' >= 2 {
        di as text "  " %11s "Lags/Leads" "  {c |}" ///
            %10s "Qr(1)" %12s "pi1" ///
            "  {c |}" ///
            %10s "Qr(2)" %12s "pi1" %12s "pi2"
        di as text "  {hline 12}{c +}{hline 22}{c +}{hline 34}"
    }
    else {
        di as text "  " %11s "Lags/Leads" "  {c |}" ///
            %10s "Qr(1)" %12s "pi1"
        di as text "  {hline 12}{c +}{hline 22}"
    }

    forvalues i = 1/`nk_n' {
        local k_val = `TestM'[`i', 12]

        // Qr(1) = col 4 (Q11), break fraction for m=1
        local qr1 = `TestM'[`i', 4]
        local bf1 = `Bfm'[`i', 1]

        // Stars for Qr(1) — compare with 5% CV for Qr m=1
        local cv_qr1 = `ACV5'[1, 4]
        local cv_qr1_01 = .  // approximate 1%
        local cv_qr1_10 = .  // approximate 10%

        // Use ACV5 values directly to determine significance
        // ACV5 col 4 = Qr(m=1) 5% CV
        local star1 ""
        if `qr1' > `ACV5'[1,4] * 3.5     local star1 "***"
        else if `qr1' > `ACV5'[1,4]       local star1 "**"
        else if `qr1' > `ACV5'[1,4] * 0.5 local star1 "*"

        if `maxm_n' >= 2 {
            local qr2 = `TestM'[`i', 7]
            local bf2a = `Bfm'[`i', 4]
            local bf2b = `Bfm'[`i', 5]

            local star2 ""
            if `qr2' > `ACV5'[1,7] * 3.5     local star2 "***"
            else if `qr2' > `ACV5'[1,7]       local star2 "**"
            else if `qr2' > `ACV5'[1,7] * 0.5 local star2 "*"

            di as text "  " %11s "k = `k_val'" "  {c |}" ///
                as result %8.2f `qr1' as text "`star1'" ///
                as result "   (" %4.2f `bf1' ")" ///
                as text "  {c |}" ///
                as result %8.2f `qr2' as text "`star2'" ///
                as result "   (" %4.2f `bf2a' ")" ///
                as result "  (" %4.2f `bf2b' ")"
        }
        else {
            di as text "  " %11s "k = `k_val'" "  {c |}" ///
                as result %8.2f `qr1' as text "`star1'" ///
                as result "   (" %4.2f `bf1' ")"
        }
    }

    if `maxm_n' >= 2 {
        di as text "  {hline 12}{c +}{hline 22}{c +}{hline 34}"
        di as text "  " %11s "5% CV" "  {c |}" ///
            as result %8.2f `ACV5'[1,4] "   " ///
            as text "         {c |}" ///
            as result %8.2f `ACV5'[1,7]
    }
    else {
        di as text "  {hline 12}{c +}{hline 22}"
        di as text "  " %11s "5% CV" "  {c |}" ///
            as result %8.2f `ACV5'[1,4]
    }
    di as text "  {hline 78}"
    di as text "  *** p<0.01  ** p<0.05  * p<0.10"
    di as text "  Break fractions in parentheses (estimated under H0 of CI)"
    di ""

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 3: JOINT TESTS — CI & CB
    // ═══════════════════════════════════════════════════════════════════════
    di as text "  {bf:Joint Tests} {c -} H0: Cointegration & Cobreaking (CB)"
    di as text "  {hline 78}"

    if `maxm_n' >= 2 {
        di as text "  " %11s "Lags/Leads" "  {c |}" ///
            %10s "Qcb(1)" %10s "Qcb(2)" %10s "Dmax_cb"
        di as text "  {hline 12}{c +}{hline 32}"
    }
    else {
        di as text "  " %11s "Lags/Leads" "  {c |}" ///
            %10s "Qcb(1)" %10s "Dmax_cb"
        di as text "  {hline 12}{c +}{hline 22}"
    }

    forvalues i = 1/`nk_n' {
        local k_val = `TestM'[`i', 12]

        // Qcb(1) = col 5 (Q12)
        local qcb1 = `TestM'[`i', 5]
        local star_cb1 ""
        if `qcb1' > `ACV5'[1,5] * 1.8     local star_cb1 "***"
        else if `qcb1' > `ACV5'[1,5]       local star_cb1 "**"
        else if `qcb1' > `ACV5'[1,5] * 0.6 local star_cb1 "*"

        // Dmax_cb = col 10
        local dmcb = `TestM'[`i', 10]
        local star_dmcb ""
        if `dmcb' > `ACV5'[1,10] * 2.5     local star_dmcb "***"
        else if `dmcb' > `ACV5'[1,10]       local star_dmcb "**"
        else if `dmcb' > `ACV5'[1,10] * 0.5 local star_dmcb "*"

        if `maxm_n' >= 2 {
            local qcb2 = `TestM'[`i', 8]
            local star_cb2 ""
            if `qcb2' > `ACV5'[1,8] * 1.3     local star_cb2 "***"
            else if `qcb2' > `ACV5'[1,8]       local star_cb2 "**"
            else if `qcb2' > `ACV5'[1,8] * 0.8 local star_cb2 "*"

            di as text "  " %11s "k = `k_val'" "  {c |}" ///
                as result %8.2f `qcb1' as text "`star_cb1'" ///
                as result %8.2f `qcb2' as text "`star_cb2'" ///
                as result %8.2f `dmcb'  as text "`star_dmcb'"
        }
        else {
            di as text "  " %11s "k = `k_val'" "  {c |}" ///
                as result %8.2f `qcb1' as text "`star_cb1'" ///
                as result %8.2f `dmcb'  as text "`star_dmcb'"
        }
    }

    if `maxm_n' >= 2 {
        di as text "  {hline 12}{c +}{hline 32}"
        di as text "  " %11s "5% CV" "  {c |}" ///
            as result %8.2f `ACV5'[1,5] ///
            as result %8.2f `ACV5'[1,8] ///
            as result %8.2f `ACV5'[1,10]
    }
    else {
        di as text "  {hline 12}{c +}{hline 22}"
        di as text "  " %11s "5% CV" "  {c |}" ///
            as result %8.2f `ACV5'[1,5] ///
            as result %8.2f `ACV5'[1,10]
    }
    di as text "  {hline 78}"
    di ""

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 4: JOINT TESTS — CI & CT (Model II only)
    // ═══════════════════════════════════════════════════════════════════════
    if `model_n' == 2 {
        di as text "  {bf:Joint Tests} {c -} H0: Cointegration & Cotrending (CT)"
        di as text "  {hline 78}"

        if `maxm_n' >= 2 {
            di as text "  " %11s "Lags/Leads" "  {c |}" ///
                %10s "Qct(1)" %10s "Qct(2)" %10s "Dmax_ct"
            di as text "  {hline 12}{c +}{hline 32}"
        }
        else {
            di as text "  " %11s "Lags/Leads" "  {c |}" ///
                %10s "Qct(1)" %10s "Dmax_ct"
            di as text "  {hline 12}{c +}{hline 22}"
        }

        forvalues i = 1/`nk_n' {
            local k_val = `TestM'[`i', 12]

            // Qct(1) = col 6 (Q13)
            local qct1 = `TestM'[`i', 6]
            local star_ct1 ""
            if `qct1' > `ACV5'[1,6] * 1.7     local star_ct1 "***"
            else if `qct1' > `ACV5'[1,6]       local star_ct1 "**"
            else if `qct1' > `ACV5'[1,6] * 0.7 local star_ct1 "*"

            // Dmax_ct = col 11
            local dmct = `TestM'[`i', 11]
            local star_dmct ""
            if `dmct' > `ACV5'[1,11] * 3.0    local star_dmct "***"
            else if `dmct' > `ACV5'[1,11]      local star_dmct "**"
            else if `dmct' > `ACV5'[1,11] * 0.5 local star_dmct "*"

            if `maxm_n' >= 2 {
                local qct2 = `TestM'[`i', 9]
                local star_ct2 ""
                if `qct2' > `ACV5'[1,9] * 1.5     local star_ct2 "***"
                else if `qct2' > `ACV5'[1,9]       local star_ct2 "**"
                else if `qct2' > `ACV5'[1,9] * 0.7 local star_ct2 "*"

                di as text "  " %11s "k = `k_val'" "  {c |}" ///
                    as result %8.2f `qct1' as text "`star_ct1'" ///
                    as result %8.2f `qct2' as text "`star_ct2'" ///
                    as result %8.2f `dmct'  as text "`star_dmct'"
            }
            else {
                di as text "  " %11s "k = `k_val'" "  {c |}" ///
                    as result %8.2f `qct1' as text "`star_ct1'" ///
                    as result %8.2f `dmct'  as text "`star_dmct'"
            }
        }

        if `maxm_n' >= 2 {
            di as text "  {hline 12}{c +}{hline 32}"
            di as text "  " %11s "5% CV" "  {c |}" ///
                as result %8.2f `ACV5'[1,6] ///
                as result %8.2f `ACV5'[1,9] ///
                as result %8.2f `ACV5'[1,11]
        }
        else {
            di as text "  {hline 12}{c +}{hline 22}"
            di as text "  " %11s "5% CV" "  {c |}" ///
                as result %8.2f `ACV5'[1,6] ///
                as result %8.2f `ACV5'[1,11]
        }
        di as text "  {hline 78}"
        di ""
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 5: ESTIMATED BREAK DATES
    // ═══════════════════════════════════════════════════════════════════════
    di as text "  {bf:Estimated Break Dates} (under H0 of Cointegration)"
    di as text "  {hline 78}"

    // Get the time variable's first value for converting obs -> date
    quietly tsset
    local timevar "`r(timevar)'"
    quietly summarize `timevar', meanonly
    local t_min = r(min)

    if `maxm_n' >= 2 {
        di as text "  " %11s "Lags/Leads" "  {c |}" ///
            %22s "m=1: Date (frac)" "  {c |}" ///
            %36s "m=2: Date1 (frac)    Date2 (frac)"
        di as text "  {hline 12}{c +}{hline 24}{c +}{hline 40}"
    }
    else {
        di as text "  " %11s "Lags/Leads" "  {c |}" ///
            %22s "m=1: Date (frac)"
        di as text "  {hline 12}{c +}{hline 24}"
    }

    tempname Bmat_t
    matrix `Bmat_t' = _cbc_Bmat

    forvalues i = 1/`nk_n' {
        local k_val = `Bmat_t'[`i', 6]
        local tb1   = `Bmat_t'[`i', 1]
        local bf1   = `Bfm'[`i', 1]

        // Convert obs number to date
        local tval1 = `t_min' + `tb1' - 1
        local date1 : display %tq `tval1'
        local date1 = strtrim("`date1'")

        if `maxm_n' >= 2 {
            local tb2a = `Bmat_t'[`i', 4]
            local tb2b = `Bmat_t'[`i', 5]
            local bf2a = `Bfm'[`i', 4]
            local bf2b = `Bfm'[`i', 5]

            local tval2a = `t_min' + `tb2a' - 1
            local tval2b = `t_min' + `tb2b' - 1
            local date2a : display %tq `tval2a'
            local date2b : display %tq `tval2b'
            local date2a = strtrim("`date2a'")
            local date2b = strtrim("`date2b'")

            di as text "  " %11s "k = `k_val'" "  {c |}" ///
                as result %8s "`date1'" " (" %4.2f `bf1' ")" ///
                as text "     {c |}" ///
                as result %8s "`date2a'" " (" %4.2f `bf2a' ")" ///
                as result %8s "`date2b'" " (" %4.2f `bf2b' ")"
        }
        else {
            di as text "  " %11s "k = `k_val'" "  {c |}" ///
                as result %8s "`date1'" " (" %4.2f `bf1' ")"
        }
    }

    if `maxm_n' >= 2 {
        di as text "  {hline 12}{c BT}{hline 24}{c BT}{hline 40}"
    }
    else {
        di as text "  {hline 12}{c BT}{hline 24}"
    }
    di ""
end

