*! kypshift v1.3.23 - July 2026 - H. Ozan Eruygur
*! Bootstrap detection of multiple persistence shifts (Kejriwal, Yu & Perron, 2020, JTSA)
*! Port of the authors' MATLAB code (detnumbreak.m), validated against a deterministic Octave reference

program define kypshift, rclass
    version 16.0
    syntax varname(numeric ts) [if] [in], [ MAXBreaks(integer 5) TRIM(real 0.15) ETA(real 0.10) BICmaxlag(integer 8) REPs(integer 400) SEED(string) PMSEED(real 0) noDOTS VALlog ASYMPCV ]

    * ------------------------------------------------------------------
    * checks
    * ------------------------------------------------------------------
    if `maxbreaks' < 2 | `maxbreaks' > 5 {
        di as error "maxbreaks() must be between 2 and 5"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as error "trim() must be strictly between 0 and 0.5"
        exit 198
    }
    if `eta' <= 0 | `eta' >= 1 {
        di as error "eta() must be strictly between 0 and 1"
        exit 198
    }
    if `bicmaxlag' < 0 {
        di as error "bicmaxlag() must be a nonnegative integer"
        exit 198
    }
    if `reps' < 10 {
        di as error "reps() must be at least 10"
        exit 198
    }

    quietly tsset
    local timevar "`r(timevar)'"
    local tfmt : format `timevar'

    marksample touse
    quietly tsreport if `touse'
    if r(N_gaps) > 0 {
        di as error "sample contains gaps in `timevar'; kypshift requires consecutive observations"
        exit 498
    }
    quietly count if `touse'
    local N = r(N)
    local Tm1 = `N' - 1
    local h0 = round(`trim' * `Tm1')
    if (`maxbreaks' + 1) * `h0' >= `Tm1' - `bicmaxlag' {
        di as error "sample too short for maxbreaks(`maxbreaks') with trim(`trim') and bicmaxlag(`bicmaxlag')"
        exit 498
    }

    if "`seed'" != "" {
        set seed `seed'
    }

    local usepm = 0
    if `pmseed' > 0 {
        local usepm = 1
    }
    capture quietly tsset
    if _rc == 0 {
        local tvar = r(timevar)
        if "`tvar'" != "" {
            sort `tvar'
        }
    }
    local usedots = cond("`dots'" == "nodots", 0, 1)
    local usevallog = cond("`vallog'" == "vallog", 1, 0)
    if "`asympcv'" != "" & abs(`trim' - 0.15) > 1e-8 {
        di as error "asympcv requires trim(0.15): the Kejriwal-Perron-Zhou (2013) critical values are tabulated for 15 percent trimming only"
        exit 198
    }

    tempvar obsord
    quietly gen double `obsord' = `timevar' if `touse'

    * ------------------------------------------------------------------
    * run the Mata core
    * ------------------------------------------------------------------
    di as text ""
    di as text "Kejriwal-Yu-Perron (2020) tests for shifts between I(1) and I(0) regimes"
    di as text "{hline 78}"
    di as text "Series          : " as result "`varlist'"
    di as text "Sample size (T) : " as result `N'
    di as text "Max breaks      : " as result `maxbreaks' as text "   Trimming: " as result %5.3f `trim' as text "   Significance eta: " as result %5.3f `eta'
    di as text "BIC max lag     : " as result `bicmaxlag' as text "   Bootstrap replications: " as result `reps'
    if `usepm' {
        di as text "RNG             : " as result "Park-Miller validation stream (pmseed = " %12.0f `pmseed' ")"
    }
    else {
        di as text "RNG             : " as result "Stata wild bootstrap draws"
    }
    di as text "{hline 78}"
    di as text "Note: computations use dynamic programming plus wild bootstrap and may take"
    if `usedots' {
        di as text "several minutes for long series with reps() large. Progress dots are shown."
    }
    else {
        di as text "several minutes for long series with reps() large."
    }

    mata: kypshift_run("`varlist'", "`obsord'", "`touse'", `maxbreaks', `trim', `eta', `bicmaxlag', `reps', `usepm', `pmseed', `usedots', `usevallog')

    * ------------------------------------------------------------------
    * capture all results BEFORE any r()-clearing command
    * ------------------------------------------------------------------
    local realb = r(nb)
    local rwmax = r(wmax)
    local rudmax = r(udmax)
    local rpv = r(pv)
    local rpvw = r(pvw)
    local rpvbp = r(pvbp)
    local rcvw = r(cvw)
    local rcvbp = r(cvbp)
    local rhstat = r(hstat)
    local roptlag0 = r(optlag0)
    local rmw = r(meanwald)
    local rmwcv = r(meanwaldcv)
    local rmshift = r(meanshift)
    local rarsum = r(arsum)
    local rarsumlag = r(arsumlag)
    local raglow = r(aglow)
    local ragup = r(agup)
    local radfp = r(adfp)
    local radfpt = r(adfptrend)
    local rmodel7 = r(model7)
    local rctk1 = r(ctk1)
    local rctk1p = r(ctk1p)
    local rctk4 = r(ctk4)
    local rctpv1 = r(ctpv1)
    local rctpv2 = r(ctpv2)
    local rctpv3 = r(ctpv3)
    tempname RM T2 FA FB
    matrix `FA' = r(f1a)
    matrix `FB' = r(f1b)
    capture matrix `RM' = r(regmodel)
    local hasrm = (_rc == 0)
    if `hasrm' {
        capture local hasrm = (colsof(`RM') == `= r(nb) + 1')
        if _rc != 0 {
            local hasrm = 0
        }
    }
    capture matrix `T2' = r(table2)
    local hast2 = (_rc == 0)
    if `hast2' {
        capture local hast2 = (colsof(`T2') == 5)
        if _rc != 0 {
            local hast2 = 0
        }
    }
    tempname WV BPV PV TM
    matrix `WV' = r(wstats)
    matrix `BPV' = r(bpstats)
    matrix `PV' = r(pvall)
    matrix `TM' = r(tmpnt)
    quietly summarize `obsord' if `touse'
    local tmin = r(min)

    di as text ""
    di as text "[1] Full-sample hybrid tests of H0: the process is stable I(1) or stable I(0)"
    di as text "{hline 62}"
    di as text "  k    sup F1a(k)    sup F1b(k)         W1(k)    G1(k) [BP]"
    di as text "{hline 62}"
    forvalues k = 1/`maxbreaks' {
        di as text "  `k'  " as result %12.4f `FA'[1,`k'] as text "  " as result %12.4f `FB'[1,`k'] as text "  " as result %12.4f `WV'[1,`k'] as text "  " as result %12.4f `BPV'[1,`k']
    }
    di as text "{hline 62}"
    di as text "  Wmax = " as result %10.4f `rwmax' as text "   UDmax = " as result %10.4f `rudmax'
    di as text "  Bootstrap p-values: p(Wmax) = " as result %6.4f `rpvw' as text "   p(UDmax) = " as result %6.4f `rpvbp'
    di as text "  Joint p-value p* = max(p(Wmax), p(UDmax)) = " as result %6.4f `rpv'
    di as text "{hline 58}"
    if `rpv' <= `eta' {
        di as text "  Decision: p* = " as result %6.4f `rpv' as text " <= eta = " as result %5.3f `eta' as text " -> the null of a stable"
        di as text "  I(1) or stable I(0) process is rejected at the " as result %5.3f `eta' as text " level; the"
        di as text "  sequential procedure below estimates how many breaks and when."
    }
    else {
        di as text "  Decision: p* = " as result %6.4f `rpv' as text " > eta = " as result %5.3f `eta' as text " -> the null of a stable"
        di as text "  I(1) or stable I(0) process is not rejected at the " as result %5.3f `eta' as text " level;"
        di as text "  no persistence break is detected."
    }
    di as text "{hline 58}"

    if `realb' == 0 {
        di as text ""
        di as text "[2] Sequential procedure: p* = " as result %6.4f `rpv' as text " > eta = " as result %5.3f `eta'
        di as text "No persistence break is detected. Selected number of breaks: " as result "0"
    }
    else {
        di as text ""
        di as text "[2] Sequential procedure (regime-specific bootstrap p-values):"
        di as text "{hline 78}"
        local i = 1
        local go = 1
        while `go' & `i' <= 5 {
            local rowfilled = 0
            capture local chk = `PV'[`i' + 1, 1]
            if _rc == 0 {
                if `PV'[`i' + 1, 1] < . {
                    local rowfilled = 1
                }
            }
            if `rowfilled' {
                local dl ""
                forvalues j = 1/`i' {
                    local dobs = `TM'[`i', `j']
                    local tv = `tmin' + `dobs' - 1
                    local dl "`dl' `: display `tfmt' `tv''"
                }
                local pl ""
                local jj = `i' + 1
                forvalues j = 1/`jj' {
                    local pl "`pl' `: display %6.4f `PV'[`i' + 1, `j']'"
                }
                local thr = 1 - (1 - `eta')^(1/`i')
                di as text "  `i' break(s): dates =" as result "`dl'"
                di as text "     regime p-values =" as result "`pl'" as text "   threshold = " as result %6.4f `thr'
            }
            else {
                local go = 0
            }
            local i = `i' + 1
        }
        di as text "{hline 78}"
        di as text "Selected number of persistence breaks: " as result "`realb'"
        local dl ""
        forvalues j = 1/`realb' {
            local dobs = `TM'[`realb', `j']
            local tv = `tmin' + `dobs' - 1
            local dl "`dl' `: display `tfmt' `tv''"
        }
        di as text "Estimated break dates:" as result "`dl'"
    }
    di as text ""
    di as text "[3] Article Table I diagnostics"
    di as text "{hline 78}"
    if `realb' > 0 {
        local msyn = cond(`rmshift' == 1, "Yes", "No")
        di as text "  (4) Pure mean shifts (robust Wald): W = " as result %8.4f `rmw' as text "   chi2(`realb') 10% cv = " as result %6.4f `rmwcv' as text "  -> " as result "`msyn'"
    }
    else {
        di as text "  (4) Pure mean shifts: not applicable (no breaks selected)"
    }
    di as text "  (5) Largest AR coefficient sum = " as result %6.2f `rarsum' as text "   (BIC lags = " as result `rarsumlag' as text ")"
    di as text "  (6) AG (2014) 90% band = [" as result %6.2f `raglow' as text ", " as result %6.2f `ragup' as text "]"
    local m7 ""
    if `realb' == 0 {
        local m7 = cond(`rmodel7' == 1, "I(1)", "I(0)")
    }
    else if `rmshift' == 1 {
        local m7 "I(0) with `realb' mean shift(s)"
    }
    else {
        forvalues j = 1/`= `realb' + 1' {
            local m7 = "`m7'" + cond(`RM'[1, `j'] == 1, "I(1)", "I(0)") + cond(`j' <= `realb', "-", "")
        }
    }
    di as text "  (7) Selected model: " as result "`m7'"
    local ct8 ""
    if `rctpv1' == 0 & `rctpv2' == 0 & `rctpv3' == 0 {
        local ct8 "I(0)-I(1)/I(1)-I(0)"
    }
    else {
        local ctmin = min(`rctpv1', `rctpv2', `rctpv3')
        if `ctmin' >= 0.1 {
            local ct8 "I(0)"
        }
        else if `rctpv1' == `ctmin' {
            local ct8 "I(0)-I(1)"
        }
        else if `rctpv2' == `ctmin' {
            local ct8 "I(1)-I(0)"
        }
        else {
            local ct8 "I(0)-I(1)/I(1)-I(0)"
        }
    }
    di as text "  (8) CT ratio tests: K1 = " as result %10.4f `rctk1' as text "  K1' = " as result %10.4f `rctk1p' as text "  K4 = " as result %10.4f `rctk4'
    di as text "      bootstrap p-values: " as result %6.4f `rctpv1' as text ", " as result %6.4f `rctpv2' as text ", " as result %6.4f `rctpv3' as text "  -> CT selection: " as result "`ct8'"
    di as text "  (9) CT-ADF bootstrap p-value (demeaned) = " as result %6.2f `radfp' as text "   (detrended = " as result %6.2f `radfpt' as text ")"
    di as text "{hline 78}"
    if !`hast2' {
        di as text "[4] Article Table II: not applicable (no regime-wise persistence breaks selected)"
    }
    if `hast2' {
        di as text ""
        di as text "[4] Article Table II regime-wise persistence estimates"
        di as text "{hline 66}"
        di as text "  Regime      AR sum      AG 90% band          ADF p    BIC lags"
        di as text "{hline 66}"
        local nreg = rowsof(`T2')
        forvalues j = 1/`nreg' {
            di as text "    " %2.0f `j' as result "    " %8.2f `T2'[`j', 1] as text "    [" as result %6.2f `T2'[`j', 2] as text "," as result %7.2f `T2'[`j', 3] as text " ]    " as result %6.2f `T2'[`j', 4] as text "    " as result %4.0f `T2'[`j', 5]
        }
        di as text "{hline 66}"
    }
    di as text ""

    * ------------------------------------------------------------------
    * stored results
    * ------------------------------------------------------------------
    if "`asympcv'" != "" {
        tempname CVA CVB CVW CVM
        matrix `CVA' = (7.94, 9.47, 7.08, 7.04, 5.11 \ 8.88, 10.62, 7.73, 7.67, 5.56 \ 9.93, 11.64, 8.33, 8.30, 5.95 \ 11.11, 12.72, 9.19, 9.05, 6.46)
        matrix `CVB' = (5.41, 5.64, 6.05, 5.33, 4.84 \ 6.39, 6.33, 6.68, 5.84, 5.29 \ 7.28, 6.84, 7.35, 6.31, 5.70 \ 8.28, 7.42, 8.04, 6.87, 6.17)
        matrix `CVW' = (8.08, 9.51, 7.28, 7.10, 5.40 \ 8.99, 10.62, 7.91, 7.71, 5.79 \ 10.00, 11.64, 8.49, 8.32, 6.21 \ 11.21, 12.72, 9.44, 9.05, 6.63)
        matrix `CVM' = (9.86 \ 10.90 \ 11.95 \ 13.02)
        tempname CVG CVU
        matrix `CVG' = (9.81, 8.63, 7.54, 6.51, 5.27 \ 11.47, 9.75, 8.36, 7.19, 5.85 \ 12.96, 10.75, 9.15, 7.81, 6.38 \ 15.37, 12.15, 10.27, 8.65, 7.00)
        matrix `CVU' = (10.16 \ 11.70 \ 13.18 \ 15.41)
        di as text ""
        di as text "[5] Kejriwal-Perron-Zhou (2013) asymptotic critical values (Table 1, Panel A)"
        di as text "{hline 68}"
        di as text "  Statistic         Value           10%       5%     2.5%       1%"
        di as text "{hline 68}"
        forvalues k = 1/`maxbreaks' {
            di as text "  k = `k'"
            foreach pair in "F1a `FA' `CVA'" "F1b `FB' `CVB'" "W1 `WV' `CVW'" "G1 `BPV' `CVG'" {
                tokenize `pair'
                local nm `1'
                local vv = `2'[1, `k']
                local s ""
                if `vv' > `3'[4, `k'] {
                    local s "****"
                }
                else if `vv' > `3'[3, `k'] {
                    local s "***"
                }
                else if `vv' > `3'[2, `k'] {
                    local s "**"
                }
                else if `vv' > `3'[1, `k'] {
                    local s "*"
                }
                if "`nm'" == "W1" {
                    local lbl "W1"
                }
                else if "`nm'" == "G1" {
                    local lbl "G1 [BP]"
                }
                else {
                    local lbl "sup `nm'"
                }
                di as text "    " %-10s "`lbl'" as result %10.4f `vv' as result %-5s "`s'" as text " " as result %8.2f `3'[1,`k'] as text " " as result %8.2f `3'[2,`k'] as text " " as result %8.2f `3'[3,`k'] as text " " as result %8.2f `3'[4,`k']
            }
        }
        di as text "{hline 68}"
        local s ""
        if `rwmax' > `CVM'[4,1] {
            local s "****"
        }
        else if `rwmax' > `CVM'[3,1] {
            local s "***"
        }
        else if `rwmax' > `CVM'[2,1] {
            local s "**"
        }
        else if `rwmax' > `CVM'[1,1] {
            local s "*"
        }
        di as text "  " %-12s "Wmax" as result %10.4f `rwmax' as result %-5s "`s'" as text " " as result %8.2f `CVM'[1,1] as text " " as result %8.2f `CVM'[2,1] as text " " as result %8.2f `CVM'[3,1] as text " " as result %8.2f `CVM'[4,1]
        local swm "`s'"
        local s ""
        if `rudmax' > `CVU'[4,1] {
            local s "****"
        }
        else if `rudmax' > `CVU'[3,1] {
            local s "***"
        }
        else if `rudmax' > `CVU'[2,1] {
            local s "**"
        }
        else if `rudmax' > `CVU'[1,1] {
            local s "*"
        }
        di as text "  " %-12s "UDmax [BP]" as result %10.4f `rudmax' as result %-5s "`s'" as text " " as result %8.2f `CVU'[1,1] as text " " as result %8.2f `CVU'[2,1] as text " " as result %8.2f `CVU'[3,1] as text " " as result %8.2f `CVU'[4,1]
        local nh = min(strlen("`swm'"), strlen("`s'"))
        if `nh' == 4 {
            local hlev "1%"
        }
        else if `nh' == 3 {
            local hlev "2.5%"
        }
        else if `nh' == 2 {
            local hlev "5%"
        }
        else {
            local hlev "10%"
        }
        if `nh' >= 1 {
            di as text "  {bf:Hybrid decision} (KPZ 2013, Section 4): Wmax and UDmax both"
            di as text "  reject at the `hlev' level (smallest tabulated level at which"
            di as text "  both reject) -> the null of a stable I(1) or stable I(0)"
            di as text "  process is rejected (asymptotic)."
        }
        else {
            di as text "  {bf:Hybrid decision} (KPZ 2013, Section 4): Wmax and UDmax do not"
            di as text "  both reject at the 10% level -> the null of a stable I(1) or"
            di as text "  stable I(0) process is not rejected (asymptotic)."
        }
        di as text "{hline 68}"
        di as text "  Stars: * rejects at 10%, ** at 5%, *** at 2.5%, **** at 1%."
        di as text "  G1(k) and UDmax critical values: Bai and Perron (1998, 2003),"
        di as text "  trimming 0.15, two changing coefficients (q = 2)."
        di as text "  - These values are valid under homoskedastic errors only. However, the"
        di as text "    wild bootstrap p-values in [1] are valid with or without"
        di as text "    heteroskedasticity (KYP 2020). Use this table as a fast"
        di as text "    complement when homoskedastic errors are plausible."
    }

    return scalar nb = `realb'
    return scalar T = `N'
    return scalar reps = `reps'
    return scalar eta = `eta'
    return scalar trim = `trim'
    return scalar maxlag = `bicmaxlag'
    return scalar maxbreaks = `maxbreaks'
    return scalar wmax = `rwmax'
    return scalar udmax = `rudmax'
    return scalar pv = `rpv'
    return scalar pvw = `rpvw'
    return scalar pvbp = `rpvbp'
    return scalar cvw = `rcvw'
    return scalar cvbp = `rcvbp'
    return scalar hstat = `rhstat'
    return scalar optlag0 = `roptlag0'
    return scalar meanwald = `rmw'
    return scalar meanwaldcv = `rmwcv'
    return scalar meanshift = `rmshift'
    return scalar arsum = `rarsum'
    return scalar aglow = `raglow'
    return scalar agup = `ragup'
    return scalar adfp = `radfp'
    return scalar adfptrend = `radfpt'
    return scalar ctk1 = `rctk1'
    return scalar ctk1p = `rctk1p'
    return scalar ctk4 = `rctk4'
    return scalar ctpv1 = `rctpv1'
    return scalar ctpv2 = `rctpv2'
    return scalar ctpv3 = `rctpv3'
    return local selmodel "`m7'"
    return local ctmodel "`ct8'"
    if `hast2' {
        return matrix table2 = `T2'
    }
    if `hasrm' {
        return matrix regmodel = `RM'
    }
    return matrix f1a = `FA'
    return matrix f1b = `FB'
    if "`asympcv'" != "" {
        local cn ""
        forvalues k = 1/`maxbreaks' {
            local cn "`cn' k`k'"
        }
        matrix `CVA' = `CVA'[1..4, 1..`maxbreaks']
        matrix `CVB' = `CVB'[1..4, 1..`maxbreaks']
        matrix `CVW' = `CVW'[1..4, 1..`maxbreaks']
        matrix rownames `CVA' = p10 p5 p2_5 p1
        matrix rownames `CVB' = p10 p5 p2_5 p1
        matrix rownames `CVW' = p10 p5 p2_5 p1
        matrix rownames `CVM' = p10 p5 p2_5 p1
        matrix colnames `CVA' = `cn'
        matrix colnames `CVB' = `cn'
        matrix colnames `CVW' = `cn'
        matrix colnames `CVM' = wmax
        return matrix cvf1a = `CVA'
        return matrix cvf1b = `CVB'
        return matrix cvw1 = `CVW'
        matrix `CVG' = `CVG'[1..4, 1..`maxbreaks']
        matrix rownames `CVG' = p10 p5 p2_5 p1
        matrix rownames `CVU' = p10 p5 p2_5 p1
        matrix colnames `CVG' = `cn'
        matrix colnames `CVU' = udmax
        return matrix cvg1 = `CVG'
        return matrix cvudmax = `CVU'
        return matrix cvwmax = `CVM'
    }
    return matrix wstats = `WV'

    return matrix bpstats = `BPV'
    return matrix pvall = `PV'
    return matrix tmpnt = `TM'
end

* ======================================================================
* Mata core
* ======================================================================
version 16.0
mata:
mata set matastrict off

// ---------------------------------------------------------------
// Park-Miller / Stata Rademacher draws
// ---------------------------------------------------------------
real colvector kypshift_rnd(real scalar T)
{
    external real scalar kypshift_pm_on
    external real scalar kypshift_pm_state
    real colvector w, u
    real scalar i
    w = J(T, 1, 0)
    if (kypshift_pm_on == 1) {
        for (i = 1; i <= T; i++) {
            kypshift_pm_state = mod(16807 * kypshift_pm_state, 2147483647)
            if (kypshift_pm_state / 2147483647 >= 0.5) w[i] = -1
            else w[i] = 1
        }
    }
    else {
        u = runiform(T, 1)
        for (i = 1; i <= T; i++) {
            if (u[i] >= 0.5) w[i] = -1
            else w[i] = 1
        }
    }
    return(w)
}

// ---------------------------------------------------------------
// recursive SSR matrix (port of Ssr)
// ---------------------------------------------------------------
real matrix kypshift_ssrmat(real colvector y, real matrix z, real scalar h, real scalar T)
{
    external real scalar kypshift_singwarn
    real matrix ms, inv1, zi
    real colvector d1, yi, res, invz
    real scalar i, r, v, f
    if (h < cols(z) & kypshift_singwarn == 0) {
        printf("{txt}warning: minimum segment length h=%g is smaller than the number of regressors (%g);\n", h, cols(z))
        printf("{txt}         estimates in short regimes rely on nearly singular designs (as in the\n")
        printf("{txt}         original MATLAB code); consider reducing bicmaxlag() or trimming\n")
        kypshift_singwarn = 1
    }
    ms = J(T, T, 0)
    for (i = 1; i <= T - h + 1; i++) {
        zi = z[|i, 1 \ i + h - 1, .|]
        yi = y[|i \ i + h - 1|]
        inv1 = luinv(zi' * zi)
        d1 = inv1 * (zi' * yi)
        res = yi - zi * d1
        ms[i, i + h - 1] = res' * res
        for (r = i + h; r <= T; r++) {
            v = y[r] - z[r, .] * d1
            invz = inv1 * z[r, .]'
            f = 1 + z[r, .] * invz
            d1 = d1 + invz * (v / f)
            inv1 = inv1 - (invz * invz') / f
            ms[i, r] = ms[i, r - 1] + v * v / f
        }
    }
    return(ms)
}

// ---------------------------------------------------------------
// Bai-Perron dynamic programming (port of Ldate); MATLAB: T = length(y)
// ---------------------------------------------------------------
void kypshift_ldate(real colvector y, real matrix z, real scalar h, real scalar m, real colvector glb, real matrix datevec)
{
    real matrix ms, optssr, optdt
    real colvector dvec, ix
    real scalar T, j, b1, b2, ib, i
    T = rows(y)
    datevec = J(m, m, 0)
    glb = J(m, 1, 0)
    ms = kypshift_ssrmat(y, z, h, T)
    optssr = J(m, T, 0)
    optdt = J(m, T, 0)
    for (j = 2 * h; j <= T; j++) {
        b1 = h
        b2 = j - h
        dvec = ms[|1, b1 \ 1, b2|]' + ms[|b1 + 1, j \ b2 + 1, j|]
        minindex(dvec, 1, ix = ., .)
        optssr[1, j] = dvec[ix[1]]
        optdt[1, j] = b1 + ix[1] - 1
    }
    glb[1] = optssr[1, T]
    datevec[1, 1] = optdt[1, T]
    for (ib = 2; ib <= m; ib++) {
        for (j = (ib + 1) * h; j <= T; j++) {
            b1 = ib * h
            b2 = j - h
            dvec = optssr[|ib - 1, b1 \ ib - 1, b2|]' + ms[|b1 + 1, j \ b2 + 1, j|]
            minindex(dvec, 1, ix = ., .)
            optssr[ib, j] = dvec[ix[1]]
            optdt[ib, j] = b1 + ix[1] - 1
        }
        glb[ib] = optssr[ib, T]
        datevec[ib, ib] = optdt[ib, T]
        for (i = 1; i <= ib - 1; i++) {
            datevec[ib, ib - i] = optdt[ib - i, datevec[ib, ib - i + 1]]
        }
    }
}

// ---------------------------------------------------------------
// diagonal partition (port of pzbar); bb is 1-based m-vector of dates
// ---------------------------------------------------------------
real matrix kypshift_pzbar(real matrix zz, real scalar m, real colvector bb)
{
    real matrix zb
    real scalar nt, q1, i, a, b
    nt = rows(zz)
    q1 = cols(zz)
    zb = J(nt, (m + 1) * q1, 0)
    zb[|1, 1 \ bb[1], q1|] = zz[|1, 1 \ bb[1], .|]
    for (i = 2; i <= m; i++) {
        a = bb[i - 1]
        b = bb[i]
        zb[|a + 1, (i - 1) * q1 + 1 \ b, i * q1|] = zz[|a + 1, 1 \ b, .|]
    }
    zb[|bb[m] + 1, m * q1 + 1 \ nt, (m + 1) * q1|] = zz[|bb[m] + 1, 1 \ nt, .|]
    return(zb)
}

// ---------------------------------------------------------------
// restriction matrices (port of ResM); returns R for (k, model)
// model: 1 = a (unit root in odd regimes), 2 = b (even regimes)
// ---------------------------------------------------------------
real matrix kypshift_resm(real scalar p, real scalar k, real scalar model)
{
    real matrix R1a, R2a, R3a, R4a, R5a, R1b, R2b, R3b, R4b, R5b
    if (p != 0) {
        R1a = (I(2), J(2, 2 * p + 2, 0)) \ (J(p, 2, 0), I(p), J(p, 2, 0), -I(p))
        R2a = (R1a, J(rows(R1a), 2 + p, 0)) \ (J(p, 4 + p, 0), I(p), J(p, 2, 0), -I(p)) \ (J(2, 4 + 2 * p, 0), I(2), J(2, p, 0))
        R3a = (R2a, J(rows(R2a), 2 + p, 0)) \ (J(p, 6 + 2 * p, 0), I(p), J(p, 2, 0), -I(p))
        R4a = (R3a, J(rows(R3a), 2 + p, 0)) \ (J(p, 8 + 3 * p, 0), I(p), J(p, 2, 0), -I(p)) \ (J(2, 8 + 4 * p, 0), I(2), J(2, p, 0))
        R5a = (R4a, J(rows(R4a), 2 + p, 0)) \ (J(p, 10 + 4 * p, 0), I(p), J(p, 2, 0), -I(p))
        R1b = (J(p, 2, 0), I(p), J(p, 2, 0), -I(p)) \ (J(2, 2 + p, 0), I(2), J(2, p, 0))
        R2b = (R1b, J(rows(R1b), 2 + p, 0)) \ (J(p, 4 + p, 0), I(p), J(p, 2, 0), -I(p))
        R3b = (R2b, J(rows(R2b), 2 + p, 0)) \ (J(2, 6 + 3 * p, 0), I(2), J(2, p, 0)) \ (J(p, 6 + 2 * p, 0), I(p), J(p, 2, 0), -I(p))
        R4b = (R3b, J(rows(R3b), 2 + p, 0)) \ (J(p, 8 + 3 * p, 0), I(p), J(p, 2, 0), -I(p))
        R5b = (R4b, J(rows(R4b), 2 + p, 0)) \ (J(2, 10 + 5 * p, 0), I(2), J(2, p, 0)) \ (J(p, 10 + 4 * p, 0), I(p), J(p, 2, 0), -I(p))
    }
    else {
        R1a = (I(2), J(2, 2, 0))
        R2a = (R1a, J(rows(R1a), 2, 0)) \ (J(2, 4, 0), I(2))
        R3a = (R2a, J(rows(R2a), 2, 0))
        R4a = (R3a, J(rows(R3a), 2, 0)) \ (J(2, 8, 0), I(2))
        R5a = (R4a, J(rows(R4a), 2, 0))
        R1b = (J(2, 2, 0), I(2))
        R2b = (R1b, J(rows(R1b), 2, 0))
        R3b = (R2b, J(rows(R2b), 2, 0)) \ (J(2, 6, 0), I(2))
        R4b = (R3b, J(rows(R3b), 2, 0))
        R5b = (R4b, J(rows(R4b), 2, 0)) \ (J(2, 10, 0), I(2))
    }
    if (model == 1) {
        if (k == 1) return(R1a)
        if (k == 2) return(R2a)
        if (k == 3) return(R3a)
        if (k == 4) return(R4a)
        return(R5a)
    }
    else {
        if (k == 1) return(R1b)
        if (k == 2) return(R2b)
        if (k == 3) return(R3b)
        if (k == 4) return(R4b)
        return(R5b)
    }
}

// ---------------------------------------------------------------
// fixed-coefficient DP (port of Rssrmin); MATLAB: T = length(y)
// ---------------------------------------------------------------
void kypshift_rssrmin(real colvector y, real matrix z, real matrix x, real scalar h, real colvector btild, real scalar m, real scalar optrssr, real rowvector optrdt)
{
    real matrix zx, optssr, optdt, datevec, css
    real colvector glb, rb, dvec, ix
    real scalar T, s, j, b1, b2, ib, i, b, u, acc
    T = rows(y)
    if (cols(x) > 0) zx = (z, x)
    else zx = z
    s = cols(zx)
    datevec = J(m, m, 0)
    glb = J(m, 1, 0)
    optssr = J(m, T, 0)
    optdt = J(m, T, 0)
    css = J(T + 1, m + 1, 0)
    for (b = 0; b <= m; b++) {
        rb = y - zx * btild[|b * s + 1 \ (b + 1) * s|]
        acc = 0
        for (u = 1; u <= T; u++) {
            acc = acc + rb[u] * rb[u]
            css[u + 1, b + 1] = acc
        }
    }
    for (j = 2 * h; j <= T; j++) {
        b1 = h
        b2 = j - h
        dvec = css[|b1 + 1, 1 \ b2 + 1, 1|] + (J(b2 - b1 + 1, 1, css[j + 1, 2]) - css[|b1 + 1, 2 \ b2 + 1, 2|])
        minindex(dvec, 1, ix = ., .)
        optssr[1, j] = dvec[ix[1]]
        optdt[1, j] = b1 + ix[1] - 1
    }
    glb[1] = optssr[1, T]
    datevec[1, 1] = optdt[1, T]
    if (m != 1) {
        for (ib = 2; ib <= m; ib++) {
            for (j = (ib + 1) * h; j <= T; j++) {
                b1 = ib * h
                b2 = j - h
                dvec = optssr[|ib - 1, b1 \ ib - 1, b2|]' + (J(b2 - b1 + 1, 1, css[j + 1, ib + 1]) - css[|b1 + 1, ib + 1 \ b2 + 1, ib + 1|])
                minindex(dvec, 1, ix = ., .)
                optssr[ib, j] = dvec[ix[1]]
                optdt[ib, j] = b1 + ix[1] - 1
            }
            glb[ib] = optssr[ib, T]
            datevec[ib, ib] = optdt[ib, T]
            for (i = 1; i <= ib - 1; i++) {
                datevec[ib, ib - i] = optdt[ib - i, datevec[ib, ib - i + 1]]
            }
        }
    }
    optrssr = glb[m]
    optrdt = datevec[|m, 1 \ m, m|]
}

// ---------------------------------------------------------------
// restricted dating iteration (port of RLdate); returns minimum SSR
// ---------------------------------------------------------------
real scalar kypshift_rldate(real colvector y, real matrix z, real matrix x, real scalar h, real matrix R, real rowvector datevec0, real scalar m)
{
    real matrix zx, zxd, XtXi
    real colvector bhat, btild, r0
    real rowvector datevec, optrdt
    real scalar maxi, i1, optrssr
    if (cols(x) > 0) zx = (z, x)
    else zx = z
    datevec = datevec0
    maxi = 100
    i1 = 0
    optrssr = .
    optrdt = J(1, m, 0)
    while (1) {
        zxd = kypshift_pzbar(zx, m, datevec')
        XtXi = luinv(zxd' * zxd)
        bhat = XtXi * (zxd' * y)
        r0 = J(rows(R), 1, 0)
        btild = XtXi * R' * luinv(R * XtXi * R') * (r0 - R * bhat) + bhat
        kypshift_rssrmin(y, z, x, h, btild, m, optrssr, optrdt)
        if (i1 >= maxi) {
            return(optrssr)
        }
        i1 = i1 + 1
        if (optrdt == datevec) {
            return(optrssr)
        }
        datevec = optrdt
    }
}

// ---------------------------------------------------------------
// KPZ W statistics (port of W_compute)
// ---------------------------------------------------------------
void kypshift_wcompute(real colvector y, real scalar m, real scalar optlag, real scalar eps, real scalar maxlag, real colvector W, real colvector Fa, real colvector Fb)
{
    real colvector dy, depvar, glb
    real matrix regs_consy, regs_lag, zx, datevec, xw
    real scalar T, h, n, k, i, j, SSR0, mina, minb, fa, fb, nlen
    real rowvector dv0
    T = rows(y) - 1
    h = round(eps * T)
    dy = y[|2 \ T + 1|] - y[|1 \ T|]
    n = T - maxlag
    depvar = dy[|maxlag + 1 \ T|]
    regs_consy = (J(n, 1, 1), y[|maxlag + 1 \ T|])
    W = J(m, 1, 0)
    nlen = n
    if (optlag != 0) {
        k = optlag
        regs_lag = J(n, k, 0)
        for (i = 1; i <= k; i++) {
            regs_lag[., i] = dy[|maxlag - i + 1 \ T - i|]
        }
        SSR0 = kypshift_projssr(depvar, regs_lag)
        zx = (regs_consy, regs_lag)
        glb = J(m, 1, 0)
        datevec = J(m, m, 0)
        kypshift_ldate(depvar, zx, h, m, glb, datevec)
        for (j = 1; j <= m; j++) {
            dv0 = datevec[|j, 1 \ j, j|]
            mina = kypshift_rldate(depvar, regs_consy, regs_lag, h, kypshift_resm(k, j, 1), dv0, j)
            minb = kypshift_rldate(depvar, regs_consy, regs_lag, h, kypshift_resm(k, j, 2), dv0, j)
            if (mod(j, 2) == 1) {
                fa = (nlen - j - 1 - k) * (SSR0 - mina) / ((j + 1) * mina)
                fb = (nlen - j - 1 - k) * (SSR0 - minb) / ((j + 1) * minb)
            }
            else {
                fa = (nlen - j - k) * (SSR0 - mina) / (j * mina)
                fb = (nlen - j - 2 - k) * (SSR0 - minb) / ((j + 2) * minb)
            }
            W[j] = max((fa, fb))
            Fa[j] = fa
            Fb[j] = fb
        }
    }
    else {
        SSR0 = depvar' * depvar
        glb = J(m, 1, 0)
        datevec = J(m, m, 0)
        kypshift_ldate(depvar, regs_consy, h, m, glb, datevec)
        xw = J(rows(depvar), 0, 0)
        for (j = 1; j <= m; j++) {
            dv0 = datevec[|j, 1 \ j, j|]
            mina = kypshift_rldate(depvar, regs_consy, xw, h, kypshift_resm(0, j, 1), dv0, j)
            minb = kypshift_rldate(depvar, regs_consy, xw, h, kypshift_resm(0, j, 2), dv0, j)
            if (mod(j, 2) == 1) {
                fa = (nlen - j - 1) * (SSR0 - mina) / ((j + 1) * mina)
                fb = (nlen - j - 1) * (SSR0 - minb) / ((j + 1) * minb)
            }
            else {
                fa = (nlen - j) * (SSR0 - mina) / (j * mina)
                fb = (nlen - j - 2) * (SSR0 - minb) / ((j + 2) * minb)
            }
            W[j] = max((fa, fb))
            Fa[j] = fa
            Fb[j] = fb
        }
    }
}

// helper: SSR from projection of y on X
real scalar kypshift_projssr(real colvector y, real matrix X)
{
    real matrix M
    real colvector e
    M = X * luinv(X' * X) * X'
    e = y - M * y
    return(e' * e)
}

// ---------------------------------------------------------------
// iterative partial-change dating (port of Nldate); returns glb
// ---------------------------------------------------------------
void kypshift_nldate(real colvector y, real matrix z, real matrix x, real scalar h, real scalar m, real colvector glb)
{
    real matrix zx, xbar, zbar, regs, gdt, dtnl
    real colvector teta, delta1, beta1, depv, res, gl0, glnl, resn, yres
    real rowvector bb
    real scalar p, q, mi, ssr1, ssrn, dlen, i, maxi, curglb
    p = cols(x)
    q = cols(z)
    glb = J(m, 1, 0)
    for (mi = 1; mi <= m; mi++) {
        zx = (x, z)
        gl0 = J(m, 1, 0)
        gdt = J(m, m, 0)
        kypshift_ldate(y, zx, h, m, gl0, gdt)
        bb = gdt[|mi, 1 \ mi, mi|]
        xbar = kypshift_pzbar(x, mi, bb')
        zbar = kypshift_pzbar(z, mi, bb')
        regs = (zbar, xbar)
        teta = luinv(regs' * regs) * (regs' * y)
        delta1 = teta[|1 \ q * (mi + 1)|]
        depv = y - zbar * delta1
        beta1 = luinv(x' * x) * (x' * depv)
        res = y - x * beta1 - zbar * delta1
        ssr1 = res' * res
        dlen = 99999999
        i = 1
        maxi = 100
        curglb = .
        while (dlen > 0.0001) {
            yres = y - x * beta1
            glnl = J(mi, 1, 0)
            dtnl = J(mi, mi, 0)
            kypshift_ldate(yres, z, h, mi, glnl, dtnl)
            bb = dtnl[|mi, 1 \ mi, mi|]
            zbar = kypshift_pzbar(z, mi, bb')
            regs = (x, zbar)
            teta = luinv(regs' * regs) * (regs' * y)
            beta1 = teta[|1 \ p|]
            delta1 = teta[|p + 1 \ p + q * (mi + 1)|]
            resn = y - regs * teta
            ssrn = resn' * resn
            dlen = abs(ssrn - ssr1)
            if (i >= maxi) {
                printf("{txt}note: Nldate iteration limit reached\n")
            }
            else {
                i = i + 1
                ssr1 = ssrn
                curglb = ssrn
            }
        }
        glb[mi] = curglb
    }
}

// ---------------------------------------------------------------
// BP G statistics (port of BP_compute)
// ---------------------------------------------------------------
void kypshift_bpcompute(real colvector y, real scalar m, real scalar optlag, real scalar eps, real scalar maxlag, real colvector BP)
{
    real colvector dy, depvar, glb
    real matrix regs_consy, regs_lag, regs, datevec
    real scalar T, h, n, k, i, SSR0, nlen
    T = rows(y) - 1
    h = round(eps * T)
    dy = y[|2 \ T + 1|] - y[|1 \ T|]
    n = T - maxlag
    depvar = dy[|maxlag + 1 \ T|]
    regs_consy = (J(n, 1, 1), y[|maxlag + 1 \ T|])
    BP = J(m, 1, 0)
    nlen = n
    if (optlag != 0) {
        k = optlag
        regs_lag = J(n, k, 0)
        for (i = 1; i <= k; i++) {
            regs_lag[., i] = dy[|maxlag - i + 1 \ T - i|]
        }
        glb = J(m, 1, 0)
        kypshift_nldate(depvar, regs_consy, regs_lag, h, m, glb)
        regs = (regs_consy, regs_lag)
        SSR0 = kypshift_projssr(depvar, regs)
        for (i = 1; i <= m; i++) {
            BP[i] = (nlen - (i + 1) * 2 - k) / (i * 2) * (SSR0 - glb[i]) / glb[i]
        }
    }
    else {
        SSR0 = kypshift_projssr(depvar, regs_consy)
        glb = J(m, 1, 0)
        datevec = J(m, m, 0)
        kypshift_ldate(depvar, regs_consy, h, m, glb, datevec)
        for (i = 1; i <= m; i++) {
            BP[i] = (nlen - (i + 1) * 2) / (i * 2) * (SSR0 - glb[i]) / glb[i]
        }
    }
}

// ---------------------------------------------------------------
// BIC lag and date selection (port of LagDatesel)
// ---------------------------------------------------------------
void kypshift_lagdatesel(real colvector y, real scalar m, real scalar maxlag, real scalar eps, real scalar type, real scalar optlag, real matrix datevec)
{
    real colvector dy, depvar, glb, bic0, bic1, bicv
    real matrix regs, rl, dt, savedate
    real scalar T, h, n, k, i, s, ol0, ol1, lag, best, bestk
    T = rows(y) - 1
    h = round(eps * T)
    dy = y[|2 \ T + 1|] - y[|1 \ T|]
    n = T - maxlag
    depvar = dy[|maxlag + 1 \ T|]
    if (type == 0) {
        bic0 = J(maxlag + 1, 1, 0)
        bic1 = J(maxlag + 1, 1, 0)
        regs = (J(n, 1, 1), y[|maxlag + 1 \ T|])
        s = kypshift_projssr(depvar, regs)
        bic0[1] = ln(s / n)
        for (k = 1; k <= maxlag; k++) {
            rl = J(n, k, 0)
            for (i = 1; i <= k; i++) {
                rl[., i] = dy[|maxlag - i + 1 \ T - i|]
            }
            regs = (J(n, 1, 1), y[|maxlag + 1 \ T|], rl)
            s = kypshift_projssr(depvar, regs)
            bic0[k + 1] = ln(s / n) + k * ln(n) / n
        }
        best = .
        bestk = 0
        for (k = 1; k <= maxlag + 1; k++) {
            if (bic0[k] < best) {
                best = bic0[k]
                bestk = k
            }
        }
        ol0 = bestk - 1
        s = depvar' * depvar
        bic1[1] = ln(s / n)
        for (k = 1; k <= maxlag; k++) {
            rl = J(n, k, 0)
            for (i = 1; i <= k; i++) {
                rl[., i] = dy[|maxlag - i + 1 \ T - i|]
            }
            regs = (J(n, 1, 1), rl)
            s = kypshift_projssr(depvar, regs)
            bic1[k + 1] = ln(s / n) + k * ln(n) / n
        }
        best = .
        bestk = 0
        for (k = 1; k <= maxlag + 1; k++) {
            if (bic1[k] < best) {
                best = bic1[k]
                bestk = k
            }
        }
        ol1 = bestk - 1
        optlag = max((ol0, ol1))
        datevec = J(0, 0, 0)
    }
    else {
        bicv = J(maxlag + 1, 1, 0)
        regs = (J(n, 1, 1), y[|maxlag + 1 \ T|])
        glb = J(m, 1, 0)
        dt = J(m, m, 0)
        kypshift_ldate(depvar, regs, h, m, glb, dt)
        bicv[1] = ln(glb[m] / n)
        savedate = dt
        for (lag = 1; lag <= maxlag; lag++) {
            rl = J(n, lag, 0)
            for (i = 1; i <= lag; i++) {
                rl[., i] = dy[|maxlag - i + 1 \ T - i|]
            }
            regs = (J(n, 1, 1), y[|maxlag + 1 \ T|], rl)
            kypshift_ldate(depvar, regs, h, m, glb, dt)
            savedate = savedate \ dt
            bicv[lag + 1] = ln(glb[m] / n) + lag * ln(n) / n
        }
        best = .
        bestk = 0
        for (k = 1; k <= maxlag + 1; k++) {
            if (bicv[k] < best) {
                best = bicv[k]
                bestk = k
            }
        }
        optlag = bestk - 1
        datevec = savedate[|(bestk - 1) * m + 1, 1 \ bestk * m, m|]
    }
}

// ---------------------------------------------------------------
// bootstrap sample construction (port of Bootconstruc)
// ---------------------------------------------------------------
real colvector kypshift_bootcon(string scalar type, real colvector y, real scalar optlag, real scalar btype, real colvector w)
{
    real colvector dy, err, eb, Bsmp, depvar
    real matrix regs, rl
    real scalar T, k, i, mn
    T = rows(y) - 1
    dy = y[|2 \ T + 1|] - y[|1 \ T|]
    if (btype == 1) {
        if (type == "BP") {
            mn = sum(y[|2 \ T + 1|]) / T
            err = y[|2 \ T + 1|] :- mn
            Bsmp = err :* w[|1 \ T|]
            return(0 \ Bsmp)
        }
        else {
            err = dy[|1 \ T|]
            eb = err :* w[|1 \ T|]
            Bsmp = J(T, 1, 0)
            Bsmp[1] = eb[1]
            for (i = 2; i <= T; i++) {
                Bsmp[i] = Bsmp[i - 1] + eb[i]
            }
            return(0 \ Bsmp)
        }
    }
    else if (btype == 2) {
        if (type == "BP") {
            depvar = dy[|1 \ T|]
            regs = (J(T, 1, 1), y[|1 \ T|])
            err = depvar - regs * (luinv(regs' * regs) * (regs' * depvar))
            Bsmp = err :* w[|1 \ T|]
            return(0 \ Bsmp)
        }
        else {
            err = dy[|1 \ T|]
            eb = err :* w[|1 \ T|]
            Bsmp = J(T, 1, 0)
            Bsmp[1] = eb[1]
            for (i = 2; i <= T; i++) {
                Bsmp[i] = Bsmp[i - 1] + eb[i]
            }
            return(0 \ Bsmp)
        }
    }
    else {
        k = optlag
        if (type == "BP") {
            depvar = dy[|k + 1 \ T|]
            rl = J(T - k, k, 0)
            for (i = 1; i <= k; i++) {
                rl[., i] = dy[|k - i + 1 \ T - i|]
            }
            regs = (J(T - k, 1, 1), y[|k + 1 \ T|], rl)
            err = depvar - regs * (luinv(regs' * regs) * (regs' * depvar))
            eb = err :* w[|k + 1 \ T|]
            return(J(k + 1, 1, 0) \ eb)
        }
        else {
            depvar = dy[|k + 1 \ T|]
            rl = J(T - k, k, 0)
            for (i = 1; i <= k; i++) {
                rl[., i] = dy[|k - i + 1 \ T - i|]
            }
            err = depvar - rl * (luinv(rl' * rl) * (rl' * depvar))
            eb = err :* w[|k + 1 \ T|]
            Bsmp = J(T + 1, 1, 0)
            for (i = k + 2; i <= T + 1; i++) {
                Bsmp[i] = Bsmp[i - 1] + eb[i - k - 1]
            }
            return(Bsmp)
        }
    }
}

// ---------------------------------------------------------------
// hybrid bootstrap test (port of H)
// ---------------------------------------------------------------
void kypshift_hfunc(real colvector y, real scalar mb, real scalar eps, real scalar eta, real scalar optlag, real scalar maxlag, real scalar brep, string scalar option, real scalar usedots, real scalar vallog, real scalar pvh, real colvector Wout, real colvector BPout, real scalar wmaxo, real scalar bpmaxo, real scalar cvwo, real scalar cvbpo, real scalar pvhwo, real scalar pvhbpo, real scalar hio, real colvector F1ao, real colvector F1bo)
{
    real matrix bstat, sb
    real colvector w1, w2, ybw, ybb, Wb, Bb
    real scalar T, n, j, idx, cvW, cvBP, cw, cb
    T = rows(y) - 1
    if (option == "m") {
        Wout = J(mb, 1, 0)
        BPout = J(mb, 1, 0)
        F1ao = J(mb, 1, 0)
        F1bo = J(mb, 1, 0)
        kypshift_wcompute(y, mb, optlag, eps, maxlag, Wout, F1ao, F1bo)
        kypshift_bpcompute(y, mb, optlag, eps, maxlag, BPout)
        wmaxo = max(Wout)
        bpmaxo = max(BPout)
        if (vallog) {
            printf("H(m): T=%g optlag=%g\n", T, optlag)
            printf("H(m) W(k):")
            for (j = 1; j <= mb; j++) printf(" %s", strofreal(Wout[j], "%21.0g"))
            printf("\n")
            printf("H(m) BP(k):")
            for (j = 1; j <= mb; j++) printf(" %s", strofreal(BPout[j], "%21.0g"))
            printf("\n")
        if (vallog) {
            printf("H(m) F1a(k):")
            for (j = 1; j <= mb; j++) printf(" %s", strofreal(F1ao[j], "%21.0g"))
            printf("\n")
            printf("H(m) F1b(k):")
            for (j = 1; j <= mb; j++) printf(" %s", strofreal(F1bo[j], "%21.0g"))
            printf("\n")
        }
        }
        bstat = J(brep, 6, 0)
        for (n = 1; n <= brep; n++) {
            w1 = kypshift_rnd(T)
            w2 = kypshift_rnd(T)
            if (optlag == 0) {
                ybw = kypshift_bootcon("W", y, optlag, 1, w1)
                ybb = kypshift_bootcon("BP", y, optlag, 2, w2)
            }
            else {
                ybw = kypshift_bootcon("W", y, optlag, 3, w1)
                ybb = kypshift_bootcon("BP", y, optlag, 3, w2)
            }
            Wb = J(mb, 1, 0)
            Bb = J(mb, 1, 0)
            bfa = J(mb, 1, 0)
            bfb = J(mb, 1, 0)
            kypshift_wcompute(ybw, mb, 0, eps, maxlag, Wb, bfa, bfb)
            kypshift_bpcompute(ybb, mb, 0, eps, maxlag, Bb)
            bstat[n, .] = (Wb[1], Bb[1], Wb[2], Bb[2], max(Wb), max(Bb))
            if (vallog) {
                printf("H(m) bstat %g:", n)
                for (j = 1; j <= 6; j++) printf(" %s", strofreal(bstat[n, j], "%21.0g"))
                printf("\n")
            }
            if (usedots) {
                printf(".")
                displayflush()

            }
        }
        if (usedots) printf("\n")
        sb = bstat
        for (j = 1; j <= 6; j++) {
            sb[., j] = sort(bstat[., j], 1)
        }
        idx = round(brep * (1 - eta))
        cvW = sb[idx, 5]
        cvBP = sb[idx, 6]
        hio = min((wmaxo, cvW / cvBP * bpmaxo))
        cvwo = cvW
        cvbpo = cvBP
        cw = 0
        cb = 0
        for (n = 1; n <= brep; n++) {
            if (sb[n, 5] > wmaxo) cw = cw + 1
            if (sb[n, 6] > bpmaxo) cb = cb + 1
        }
        pvhwo = cw / brep
        pvhbpo = cb / brep
        pvh = max((pvhwo, pvhbpo))
        if (vallog) {
            printf("H(m) cv: %s %s  hi=%s  pvhw=%s pvhbp=%s pvh=%s\n", strofreal(cvW, "%21.0g"), strofreal(cvBP, "%21.0g"), strofreal(hio, "%21.0g"), strofreal(pvhwo, "%21.0g"), strofreal(pvhbpo, "%21.0g"), strofreal(pvh, "%21.0g"))
        }
    }
    else {
        Wout = J(1, 1, 0)
        BPout = J(1, 1, 0)
        F1ao = J(1, 1, 0)
        F1bo = J(1, 1, 0)
        kypshift_wcompute(y, 1, optlag, eps, maxlag, Wout, F1ao, F1bo)
        kypshift_bpcompute(y, 1, optlag, eps, maxlag, BPout)
        if (vallog) {
            printf("H(1): T=%g optlag=%g  W1=%s BP1=%s\n", T, optlag, strofreal(Wout[1], "%21.0g"), strofreal(BPout[1], "%21.0g"))
        }
        bstat = J(brep, 2, 0)
        for (n = 1; n <= brep; n++) {
            w1 = kypshift_rnd(T)
            w2 = kypshift_rnd(T)
            if (optlag == 0) {
                ybw = kypshift_bootcon("W", y, optlag, 1, w1)
                ybb = kypshift_bootcon("BP", y, optlag, 2, w2)
            }
            else {
                ybw = kypshift_bootcon("W", y, optlag, 3, w1)
                ybb = kypshift_bootcon("BP", y, optlag, 3, w2)
            }
            Wb = J(1, 1, 0)
            Bb = J(1, 1, 0)
            bfa = J(1, 1, 0)
            bfb = J(1, 1, 0)
            kypshift_wcompute(ybw, 1, 0, eps, maxlag, Wb, bfa, bfb)
            kypshift_bpcompute(ybb, 1, 0, eps, maxlag, Bb)
            bstat[n, .] = (Wb[1], Bb[1])
            if (vallog) {
                printf("H(1) bstat %g: %s %s\n", n, strofreal(bstat[n, 1], "%21.0g"), strofreal(bstat[n, 2], "%21.0g"))
            }
            if (usedots) {
                printf(".")
                displayflush()
            }
        }
        if (usedots) printf("\n")
        sb = bstat
        for (j = 1; j <= 2; j++) {
            sb[., j] = sort(bstat[., j], 1)
        }
        idx = round(brep * (1 - eta))
        cvW = sb[idx, 1]
        cvBP = sb[idx, 2]
        hio = min((Wout[1], cvW / cvBP * BPout[1]))
        cvwo = cvW
        cvbpo = cvBP
        cw = 0
        cb = 0
        for (n = 1; n <= brep; n++) {
            if (sb[n, 1] > Wout[1]) cw = cw + 1
            if (sb[n, 2] > BPout[1]) cb = cb + 1
        }
        pvhwo = cw / brep
        pvhbpo = cb / brep
        pvh = max((pvhwo, pvhbpo))
        wmaxo = Wout[1]
        bpmaxo = BPout[1]
        if (vallog) {
            printf("H(1) cv: %s %s  hi=%s  pvhw=%s pvhbp=%s pvh=%s\n", strofreal(cvW, "%21.0g"), strofreal(cvBP, "%21.0g"), strofreal(hio, "%21.0g"), strofreal(pvhwo, "%21.0g"), strofreal(pvhbpo, "%21.0g"), strofreal(pvh, "%21.0g"))
        }
    }
}


// ===============================================================
// PHASE 2: article Table I columns 4-9 and Table II quantities
// ===============================================================

real colvector kypshift_gauss(real scalar n)
{
    external real scalar kypshift_pm_on
    external real scalar kypshift_pm_state
    real colvector r
    real scalar i, u1, u2
    r = J(n, 1, 0)
    if (kypshift_pm_on == 1) {
        for (i = 1; i <= n; i++) {
            kypshift_pm_state = mod(16807 * kypshift_pm_state, 2147483647)
            u1 = kypshift_pm_state / 2147483647
            kypshift_pm_state = mod(16807 * kypshift_pm_state, 2147483647)
            u2 = kypshift_pm_state / 2147483647
            r[i] = sqrt(-2 * ln(u1)) * cos(2 * pi() * u2)
        }
    }
    else {
        r = rnormal(n, 1, 0, 1)
    }
    return(r)
}

void kypshift_ols(real colvector y, real matrix x, real colvector beta, real colvector resid, real matrix varcov, real matrix rob0, real matrix rob5)
{
    real matrix invxx
    real colvector p, pstar, residnew
    real scalar T, k, sigsq, cap5, ii5
    T = rows(x)
    k = cols(x)
    invxx = luinv(x' * x)
    beta = invxx * (x' * y)
    resid = y - x * beta
    sigsq = (resid' * resid) / (T - k)
    varcov = sigsq * invxx
    p = diagonal(x * (invxx * x'))
    cap5 = 1 / sqrt(T)
    pstar = J(T, 1, 0)
    for (ii5 = 1; ii5 <= T; ii5++) {
        if (p[ii5] < cap5) pstar[ii5] = p[ii5]
        else pstar[ii5] = cap5
    }
    residnew = J(T, 1, 0)
    for (ii5 = 1; ii5 <= T; ii5++) {
        residnew[ii5] = resid[ii5] / (1 - pstar[ii5])
    }
    rob0 = invxx * x' * diag(resid :^ 2) * x * invxx
    rob5 = invxx * x' * diag(residnew :^ 2) * x * invxx
}

real matrix kypshift_wbar(real colvector yyb, real matrix zbar, real scalar lags, real scalar trimrow, real scalar bigt, real scalar withy)
{
    real matrix dl, w
    real scalar f
    if (lags == 0) {
        if (withy) w = (zbar, yyb[|trimrow + 1 \ bigt|])
        else w = zbar
    }
    else {
        dl = J(bigt - trimrow, lags, 0)
        for (f = 1; f <= lags; f++) {
            dl[., f] = yyb[|trimrow - f + 2 \ bigt - f + 1|] - yyb[|trimrow - f + 1 \ bigt - f|]
        }
        if (withy) w = (zbar, yyb[|trimrow + 1 \ bigt|], dl)
        else w = (zbar, dl)
    }
    return(w)
}

void kypshift_robtest(real colvector y, real scalar brnum, real colvector estdate, real rowvector result, real scalar waldresult, real scalar lagpure, real scalar CV)
{
    real colvector c, yyf, yyb, dves, a0, a1, yv, err, bic0
    real matrix zbar0, zbar1, wbar0, wbar1, iw, varb, robvarb, tmp1, R
    real scalar bigt, n, m, lagsmax, lags, s0, s1, wald0, wald0alt, robwald0, i, best, bestk
    bigt = rows(y) - 1
    if (brnum == 0) {
        result = J(1, 5, .)
        waldresult = .
        lagpure = .
        CV = .
        return
    }
    m = brnum
    dves = estdate :- 1
    n = bigt + 1
    c = J(bigt, 1, 1)
    yyf = y[|2 \ n|]
    yyb = y[|1 \ n - 1|]
    lagsmax = 12
    bic0 = J(lagsmax + 1, 1, 0)
    for (lags = 0; lags <= lagsmax; lags++) {
        zbar0 = kypshift_pzbar(c, m, dves)
        zbar0 = zbar0[|lagsmax + 1, 1 \ bigt, .|]
        wbar0 = kypshift_wbar(yyb, zbar0, lags, lagsmax, bigt, 1)
        yv = yyf[|lagsmax + 1 \ bigt|]
        a0 = luinv(wbar0' * wbar0) * (wbar0' * yv)
        s0 = (yv - wbar0 * a0)' * (yv - wbar0 * a0)
        bic0[lags + 1] = ln(s0 / (bigt - lagsmax)) + lags * ln(bigt - lagsmax) / (bigt - lagsmax)
    }
    best = .
    bestk = 0
    for (i = 1; i <= lagsmax + 1; i++) {
        if (bic0[i] < best) {
            best = bic0[i]
            bestk = i
        }
    }
    lags = bestk - 1
    lagpure = lags
    zbar0 = kypshift_pzbar(c, m, dves)
    zbar0 = zbar0[|lags + 1, 1 \ bigt, .|]
    zbar1 = kypshift_pzbar((c, yyb), m, dves)
    zbar1 = zbar1[|lags + 1, 1 \ bigt, .|]
    wbar0 = kypshift_wbar(yyb, zbar0, lags, lags, bigt, 1)
    wbar1 = kypshift_wbar(yyb, zbar1, lags, lags, bigt, 0)
    yv = yyf[|lags + 1 \ bigt|]
    a0 = luinv(wbar0' * wbar0) * (wbar0' * yv)
    a1 = luinv(wbar1' * wbar1) * (wbar1' * yv)
    s0 = (yv - wbar0 * a0)' * (yv - wbar0 * a0)
    s1 = (yv - wbar1 * a1)' * (yv - wbar1 * a1)
    wald0 = (bigt - 2 * (m + 1) - lags) * (s0 - s1) / s1
    err = yv - wbar1 * a1
    iw = luinv(wbar1' * wbar1)
    varb = iw * ((err' * err) / (bigt - 2 * (m + 1) - lags))
    robvarb = iw * wbar1' * diag(err :* err) * wbar1 * iw
    tmp1 = J(m, 2 * m, 0)
    for (i = 1; i <= m; i++) {
        tmp1[i, 2 * i] = 1
    }
    R = (tmp1, J(m, 1, 0), -J(m, 1, 1), J(m, lags, 0))
    wald0alt = (R * a1)' * luinv(R * varb * R') * (R * a1)
    robwald0 = (R * a1)' * luinv(R * robvarb * R') * (R * a1)
    result = (robwald0, wald0, wald0alt, a0[m + 2], lags)
    CV = invchi2(m, 0.9)
    waldresult = (robwald0 >= CV ? 1 : 0)
}

real colvector kypshift_aginterp(real colvector h, real colvector qt, real colvector d)
{
    real colvector re
    real scalar T, i, p, loc, found, j
    T = rows(h)
    re = J(rows(d), 1, 0)
    for (i = 1; i <= rows(d); i++) {
        p = d[i]
        found = 0
        for (j = 1; j <= T; j++) {
            if (h[j] > p) {
                found = j
                break
            }
        }
        if (found > 0) {
            if (found > 1) {
                loc = found - 1
                re[i] = (p - h[loc]) * (qt[loc + 1] - qt[loc]) / (h[loc + 1] - h[loc]) + qt[loc]
            }
            else {
                re[i] = qt[1]
            }
        }
        else {
            re[i] = qt[T]
        }
    }
    return(re)
}

void kypshift_agcross(real colvector a, real colvector x, real colvector yv, real colvector g1, real colvector g2)
{
    real colvector r, d, li, al, au, bl, bu
    real scalar rn, i, cnt
    rn = rows(a)
    r = (x :< yv)
    d = 0 \ (r[|2 \ rn|] - r[|1 \ rn - 1|])
    cnt = 0
    li = J(0, 1, 0)
    for (i = 1; i <= rn; i++) {
        if (d[i] == 1) li = li \ i
    }
    if (rows(li) == 0) {
        g1 = J(1, 1, .)
    }
    else {
        al = a[li :- 1]
        au = a[li]
        bl = x[li :- 1] - yv[li :- 1]
        bu = yv[li] - x[li]
        g1 = (bu :* al + bl :* au) :/ (bl + bu)
    }
    li = J(0, 1, 0)
    for (i = 1; i <= rn; i++) {
        if (d[i] == -1) li = li \ i
    }
    if (rows(li) == 0) {
        g2 = J(1, 1, .)
    }
    else {
        al = a[li :- 1]
        au = a[li]
        bl = yv[li :- 1] - x[li :- 1]
        bu = x[li] - yv[li]
        g2 = (bu :* al + bl :* au) :/ (bl + bu)
    }
}

void kypshift_andrews(real scalar rhohat, real scalar robvarcov, real scalar T, real scalar lo, real scalar up)
{
    real colvector cvl, cvu, hspace, rhogrid, hgrid, ql, qu, ta, g1l, g2l, g1u, g2u, allv, s
    real scalar rhostd, step, i, gridp, rng
    gridp = 200
    rng = 5
    cvl = (-2.87 \ -2.83 \ -2.79 \ -2.76 \ -2.73 \ -2.7 \ -2.65 \ -2.61 \ -2.57 \ -2.54 \ -2.51 \ -2.48 \ -2.46 \ -2.44 \ -2.42 \ -2.39 \ -2.35 \ -2.32 \ -2.29 \ -2.26 \ -2.23 \ -2.21 \ -2.19 \ -2.18 \ -2.16 \ -2.14 \ -2.09 \ -2.05 \ -2.01 \ -1.97 \ -1.93 \ -1.91 \ -1.89 \ -1.87 \ -1.86 \ -1.85 \ -1.79 \ -1.76 \ -1.74)
    cvu = (-0.07 \ -0.02 \ 0.04 \ 0.08 \ 0.13 \ 0.17 \ 0.25 \ 0.31 \ 0.37 \ 0.43 \ 0.48 \ 0.52 \ 0.57 \ 0.61 \ 0.64 \ 0.68 \ 0.75 \ 0.81 \ 0.87 \ 0.91 \ 0.95 \ 0.98 \ 1.01 \ 1.03 \ 1.05 \ 1.08 \ 1.15 \ 1.2 \ 1.24 \ 1.3 \ 1.34 \ 1.36 \ 1.39 \ 1.4 \ 1.42 \ 1.43 \ 1.49 \ 1.52 \ 1.55)
    hspace = (0 \ .2 \ .4 \ .6 \ .8 \ 1 \ 1.4 \ 1.8 \ 2.2 \ 2.6 \ 3 \ 3.4 \ 3.8 \ 4.2 \ 4.6 \ 5 \ 6 \ 7 \ 8 \ 9 \ 10 \ 11 \ 12 \ 13 \ 14 \ 15 \ 20 \ 25 \ 30 \ 40 \ 50 \ 60 \ 70 \ 80 \ 90 \ 100 \ 200 \ 300 \ 500)
    rhostd = sqrt(robvarcov)
    step = 2 * rng * rhostd / (gridp - 1)
    rhogrid = J(gridp, 1, 0)
    for (i = 1; i <= gridp; i++) {
        rhogrid[i] = rhohat - rng * rhostd + (i - 1) * step
    }
    hgrid = T * (J(gridp, 1, 1) - rhogrid)
    ql = kypshift_aginterp(hspace, cvl, hgrid)
    qu = kypshift_aginterp(hspace, cvu, hgrid)
    ta = (J(gridp, 1, rhohat) - rhogrid) / rhostd
    kypshift_agcross(rhogrid, ta, ql, g1l = ., g2l = .)
    kypshift_agcross(rhogrid, ta, qu, g1u = ., g2u = .)
    allv = g1l \ g2l \ g1u \ g2u
    s = select(allv, allv :< .)
    lo = min(s)
    up = max(s)
    if (lo == min(g2u)) lo = min(rhogrid)
    if (lo == min(g1l)) lo = min(rhogrid)
    if (up == max(g2l)) up = max(rhogrid)
    if (up == max(g1u)) up = max(rhogrid)
}

real colvector kypshift_lagn(real colvector x, real scalar n)
{
    return(J(n, 1, 0) \ x[|1 \ rows(x) - n|])
}

real scalar kypshift_s2ar(real colvector yts, real scalar penalty, real scalar kmax, real scalar kmin)
{
    real colvector dyts, dyts0, tau, s2e, mic, b, e, kk
    real matrix reg, reg0, X
    real scalar nt, i, k, sumy, nef, best, bestk
    nt = rows(yts)
    tau = J(kmax + 1, 1, 0)
    s2e = J(kmax + 1, 1, 999)
    dyts = 0 \ (yts[|2 \ nt|] - yts[|1 \ nt - 1|])
    reg = kypshift_lagn(yts, 1)
    for (i = 1; i <= kmax; i++) {
        reg = (reg, kypshift_lagn(dyts, i))
    }
    dyts0 = dyts[|kmax + 2 \ nt|]
    reg0 = reg[|kmax + 2, 1 \ nt, .|]
    sumy = reg0[., 1]' * reg0[., 1]
    nef = nt - kmax - 1
    for (k = kmin; k <= kmax; k++) {
        X = reg0[|1, 1 \ ., k + 1|]
        b = luinv(X' * X) * (X' * dyts0)
        e = dyts0 - X * b
        s2e[k + 1] = (e' * e) / nef
        tau[k + 1] = (b[1] * b[1]) * sumy / s2e[k + 1]
    }
    kk = J(kmax + 1, 1, 0)
    for (i = 1; i <= kmax + 1; i++) {
        kk[i] = i - 1
    }
    if (penalty == 0) mic = ln(s2e) + 2 :* (kk + tau) / nef
    else mic = ln(s2e) + ln(nef) :* kk / nef
    best = .
    bestk = 1
    for (i = 1; i <= kmax + 1; i++) {
        if (-mic[i] > best | best == .) {
            if (best == . | -mic[i] > best) {
                best = -mic[i]
                bestk = i
            }
        }
    }
    return(bestk - 1)
}

real scalar kypshift_adft(real colvector Y, real scalar type)
{
    real colvector y, dy, depvar, beta, err
    real matrix tr, rl, regs, invx, varcov
    real scalar T, kmax, k, i
    T = rows(Y) - 1
    if (type == 1) {
        y = Y :- (sum(Y) / rows(Y))
    }
    else {
        tr = J(T + 1, 2, 1)
        for (i = 1; i <= T + 1; i++) {
            tr[i, 2] = i
        }
        y = Y - tr * (luinv(tr' * tr) * (tr' * Y))
    }
    kmax = floor(12 * (T / 100)^0.25 + 0.5)
    k = kypshift_s2ar(y, 0, kmax, 0)
    dy = y[|2 \ T + 1|] - y[|1 \ T|]
    depvar = dy[|k + 1 \ T|]
    if (k != 0) {
        rl = J(T - k, k, 0)
        for (i = 1; i <= k; i++) {
            rl[., i] = dy[|k - i + 1 \ T - i|]
        }
        regs = (y[|k + 1 \ T|], rl)
    }
    else {
        regs = y[|k + 1 \ T|]
    }
    invx = luinv(regs' * regs)
    beta = invx * (regs' * depvar)
    err = depvar - regs * beta
    varcov = ((err' * err) / (T - k)) * invx
    return(beta[1] / sqrt(varcov[1, 1]))
}

void kypshift_urtest(real colvector Y, real scalar lag, real scalar type, real scalar t, real scalar re, real scalar kout, real scalar betaar, real scalar sebeta)
{
    real colvector y, dy, depvar, beta, err, betab, errb, err_new, eps_boot, Bsmp, Bs, tball, stb, seg, dseg
    real matrix tr, rl, regs, invx, varcov, regsb, invxb
    real scalar T, k, i, b, cnt
    T = rows(Y) - 1
    if (type == 1) {
        y = Y :- (sum(Y) / rows(Y))
    }
    else {
        tr = J(T + 1, 2, 1)
        for (i = 1; i <= T + 1; i++) {
            tr[i, 2] = i
        }
        y = Y - tr * (luinv(tr' * tr) * (tr' * Y))
    }
    k = lag
    kout = k
    dy = y[|2 \ T + 1|] - y[|1 \ T|]
    depvar = dy[|k + 1 \ T|]
    if (k != 0) {
        rl = J(T - k, k, 0)
        for (i = 1; i <= k; i++) {
            rl[., i] = dy[|k - i + 1 \ T - i|]
        }
        regs = (y[|k + 1 \ T|], rl)
    }
    else {
        regs = y[|k + 1 \ T|]
    }
    invx = luinv(regs' * regs)
    beta = invx * (regs' * depvar)
    betaar = 1 + beta[1]
    err = depvar - regs * beta
    varcov = ((err' * err) / (T - k)) * invx
    sebeta = sqrt(varcov[1, 1])
    t = beta[1] / sebeta
    tball = J(499, 1, 0)
    for (b = 1; b <= 499; b++) {
        if (k != 0) {
            rl = J(T - k, k, 0)
            for (i = 1; i <= k; i++) {
                rl[., i] = dy[|k - i + 1 \ T - i|]
            }
            regsb = rl
            invxb = luinv(regsb' * regsb)
            betab = invxb * (regsb' * depvar)
            errb = depvar - regsb * betab
            err_new = errb :* kypshift_gauss(rows(errb))
            Bsmp = J(T + 1, 1, 0)
            for (i = k + 2; i <= T + 1; i++) {
                seg = Bsmp[|i - k - 1 \ i - 1|]
                dseg = seg[|2 \ k + 1|] - seg[|1 \ k|]
                Bsmp[i] = Bsmp[i - 1] + betab' * dseg[k::1] + err_new[i - k - 1]
            }
        }
        else {
            eps_boot = dy[|1 \ T|] :* kypshift_gauss(T)
            Bs = J(T, 1, 0)
            Bs[1] = eps_boot[1]
            for (i = 2; i <= T; i++) {
                Bs[i] = Bs[i - 1] + eps_boot[i]
            }
            Bsmp = 0 \ Bs
        }
        tball[b] = kypshift_adft(Bsmp, type)
    }
    stb = sort(tball, 1)
    cnt = 0
    for (b = 1; b <= 499; b++) {
        if (t >= stb[b]) cnt = cnt + 1
    }
    re = cnt / 499
}

void kypshift_regblock(real colvector yreg, real scalar mdof, real rowvector out)
{
    real colvector yyf, yyb, yv, a, err, bic0, beta, resid
    real matrix w, iw, robvar, var, varcov, rob0, rob5
    real scalar bigt, lagsmax, lags, s, i, best, bestk, arsum, std, robstd, l5, u5, l0, u0, Tn
    bigt = rows(yreg) - 1
    yyf = yreg[|2 \ bigt + 1|]
    yyb = yreg[|1 \ bigt|]
    lagsmax = 12
    bic0 = J(lagsmax + 1, 1, 0)
    for (lags = 0; lags <= lagsmax; lags++) {
        w = kypshift_wbar(yyb, J(bigt - lagsmax, 1, 1), lags, lagsmax, bigt, 1)
        yv = yyf[|lagsmax + 1 \ bigt|]
        a = luinv(w' * w) * (w' * yv)
        s = (yv - w * a)' * (yv - w * a)
        bic0[lags + 1] = ln(s / (bigt - lagsmax)) + lags * ln(bigt - lagsmax) / (bigt - lagsmax)
    }
    best = .
    bestk = 0
    for (i = 1; i <= lagsmax + 1; i++) {
        if (bic0[i] < best) {
            best = bic0[i]
            bestk = i
        }
    }
    lags = bestk - 1
    w = kypshift_wbar(yyb, J(bigt - lags, 1, 1), lags, lags, bigt, 1)
    yv = yyf[|lags + 1 \ bigt|]
    a = luinv(w' * w) * (w' * yv)
    arsum = a[2]
    err = yv - w * a
    iw = luinv(w' * w)
    var = iw * ((err' * err) / (bigt - mdof - 2 - lags))
    std = sqrt(var[2, 2])
    robvar = iw * w' * diag(err :* err) * w * iw
    robstd = sqrt(robvar[2, 2])
    beta = J(0, 1, 0)
    resid = J(0, 1, 0)
    varcov = J(0, 0, 0)
    rob0 = J(0, 0, 0)
    rob5 = J(0, 0, 0)
    kypshift_ols(yv, w, beta, resid, varcov, rob0, rob5)
    Tn = rows(yv)
    l5 = .
    u5 = .
    l0 = .
    u0 = .
    kypshift_andrews(beta[2], rob5[2, 2], Tn, l5, u5)
    kypshift_andrews(beta[2], rob0[2, 2], Tn, l0, u0)
    out = (arsum, std, robstd, sqrt(rob5[2, 2]), sqrt(rob0[2, 2]), lags, l5, u5, l0, u0)
}

void kypshift_robesti(real colvector y, real colvector estdate, real scalar optlag, real scalar waldresult, real rowvector re1, real rowvector re2, real rowvector re3, real rowvector re4, real scalar model, real colvector regimemodel, real matrix eachrows)
{
    real colvector ydm, yyf, yyb, yv, a, err, dv, yreg
    real matrix w, iw, robvar, var, varcov, rob0, rob5
    real colvector beta, resid
    real scalar m, bigt, lags, arsum, std, robstd, l5, u5, l0, u0, Tn, i, ur1, kur1, beta1, se1, ur2, kur2, beta2, se2, t1, t2, maxv, maxloc
    real rowvector blk
    m = rows(estdate)
    model = .
    regimemodel = J(0, 1, 0)
    eachrows = J(0, 22, 0)
    if (waldresult == 0) {
        dv = 0 \ estdate \ rows(y)
        ydm = J(rows(y), 1, 0)
        for (i = 1; i <= m + 1; i++) {
            yreg = y[|dv[i] + 1 \ dv[i + 1]|]
            ydm[|dv[i] + 1 \ dv[i + 1]|] = yreg :- (sum(yreg) / rows(yreg))
        }
        bigt = rows(y) - 1
        yyf = ydm[|2 \ bigt + 1|]
        yyb = ydm[|1 \ bigt|]
        lags = optlag
        w = kypshift_wbar(yyb, J(bigt - lags, 1, 1), lags, lags, bigt, 1)
        yv = yyf[|lags + 1 \ bigt|]
        a = luinv(w' * w) * (w' * yv)
        arsum = a[2]
        err = yv - w * a
        iw = luinv(w' * w)
        var = iw * ((err' * err) / (bigt - 2 - lags))
        std = sqrt(var[2, 2])
        robvar = iw * w' * diag(err :* err) * w * iw
        robstd = sqrt(robvar[2, 2])
        beta = J(0, 1, 0)
        resid = J(0, 1, 0)
        varcov = J(0, 0, 0)
        rob0 = J(0, 0, 0)
        rob5 = J(0, 0, 0)
        kypshift_ols(yv, w, beta, resid, varcov, rob0, rob5)
        Tn = rows(yv)
        l5 = .
        u5 = .
        l0 = .
        u0 = .
        kypshift_andrews(beta[2], rob5[2, 2], Tn, l5, u5)
        kypshift_andrews(beta[2], rob0[2, 2], Tn, l0, u0)
        t1 = .
        ur1 = .
        kur1 = .
        beta1 = .
        se1 = .
        kypshift_urtest(ydm, lags, 1, t1, ur1, kur1, beta1, se1)
        t2 = .
        ur2 = .
        kur2 = .
        beta2 = .
        se2 = .
        kypshift_urtest(ydm, lags, 2, t2, ur2, kur2, beta2, se2)
        re1 = (arsum, std, robstd, sqrt(rob5[2, 2]), sqrt(rob0[2, 2]), lags)
        re2 = (arsum - 1.646 * std, arsum + 1.646 * std, arsum - 1.646 * robstd, arsum + 1.646 * robstd)
        re3 = (l5, u5, l0, u0)
        re4 = (ur1, kur1, beta1, se1, ur2, kur2, beta2, se2)
    }
    else if (waldresult == .) {
        blk = J(1, 10, 0)
        kypshift_regblock(y, 0, blk)
        lags = blk[6]
        t1 = .
        ur1 = .
        kur1 = .
        beta1 = .
        se1 = .
        kypshift_urtest(y, lags, 1, t1, ur1, kur1, beta1, se1)
        t2 = .
        ur2 = .
        kur2 = .
        beta2 = .
        se2 = .
        kypshift_urtest(y, lags, 2, t2, ur2, kur2, beta2, se2)
        re1 = (blk[1], blk[2], blk[3], blk[4], blk[5], blk[6])
        re2 = (blk[1] - 1.646 * blk[2], blk[1] + 1.646 * blk[2], blk[1] - 1.646 * blk[3], blk[1] + 1.646 * blk[3])
        re3 = (blk[7], blk[8], blk[9], blk[10])
        re4 = (ur1, kur1, beta1, se1, ur2, kur2, beta2, se2)
        model = (blk[7] <= 1 & blk[8] >= 1 ? 1 : 0)
    }
    else {
        dv = 0 \ estdate \ rows(y)
        eachrows = J(m + 1, 22, 0)
        for (i = 1; i <= m + 1; i++) {
            yreg = y[|dv[i] + 1 \ dv[i + 1]|]
            blk = J(1, 10, 0)
            kypshift_regblock(yreg, m, blk)
            lags = blk[6]
            t1 = .
            ur1 = .
            kur1 = .
            beta1 = .
            se1 = .
            kypshift_urtest(yreg, lags, 1, t1, ur1, kur1, beta1, se1)
            t2 = .
            ur2 = .
            kur2 = .
            beta2 = .
            se2 = .
            kypshift_urtest(yreg, lags, 2, t2, ur2, kur2, beta2, se2)
            eachrows[i, .] = (blk[1], blk[2], blk[3], blk[4], blk[5], blk[6], blk[1] - 1.646 * blk[2], blk[1] + 1.646 * blk[2], blk[1] - 1.646 * blk[3], blk[1] + 1.646 * blk[3], blk[7], blk[8], blk[9], blk[10], ur1, kur1, beta1, se1, ur2, kur2, beta2, se2)
            regimemodel = regimemodel \ (blk[7] <= 1 & blk[8] >= 1 ? 1 : 0)
        }
        maxv = .
        maxloc = 1
        for (i = 1; i <= m + 1; i++) {
            if (maxv == . | eachrows[i, 1] > maxv) {
                maxv = eachrows[i, 1]
                maxloc = i
            }
        }
        re1 = eachrows[|maxloc, 1 \ maxloc, 6|]
        re2 = eachrows[|maxloc, 7 \ maxloc, 10|]
        re3 = eachrows[|maxloc, 11 \ maxloc, 14|]
        re4 = eachrows[|maxloc, 15 \ maxloc, 22|]
    }
}

void kypshift_each(real colvector y, real colvector estdate, real matrix eachrows)
{
    real colvector dv, yreg
    real rowvector blk
    real scalar m, i, lags, t1, ur1, kur1, beta1, se1, t2, ur2, kur2, beta2, se2
    m = rows(estdate)
    dv = 0 \ estdate \ rows(y)
    eachrows = J(m + 1, 22, 0)
    for (i = 1; i <= m + 1; i++) {
        yreg = y[|dv[i] + 1 \ dv[i + 1]|]
        blk = J(1, 10, 0)
        kypshift_regblock(yreg, m, blk)
        lags = blk[6]
        t1 = .
        ur1 = .
        kur1 = .
        beta1 = .
        se1 = .
        kypshift_urtest(yreg, lags, 1, t1, ur1, kur1, beta1, se1)
        t2 = .
        ur2 = .
        kur2 = .
        beta2 = .
        se2 = .
        kypshift_urtest(yreg, lags, 2, t2, ur2, kur2, beta2, se2)
        eachrows[i, .] = (blk[1], blk[2], blk[3], blk[4], blk[5], blk[6], blk[1] - 1.646 * blk[2], blk[1] + 1.646 * blk[2], blk[1] - 1.646 * blk[3], blk[1] + 1.646 * blk[3], blk[7], blk[8], blk[9], blk[10], ur1, kur1, beta1, se1, ur2, kur2, beta2, se2)
    }
}

void kypshift_cttest(real colvector y, real rowvector stat, real rowvector pv, real matrix boot)
{
    real colvector e1, e2, cs1, cs2, kt, err, yb, sv
    real scalar T, brep, n, j, tauT, k1, k1p, k4, cnt, i, slo, shi, si
    T = rows(y)
    brep = 400
    slo = floor(0.15 * T)
    shi = floor(0.85 * T)
    kt = J(shi - slo + 1, 1, 0)
    for (si = slo; si <= shi; si++) {
        tauT = floor((si / T) * T)
        e1 = y[|1 \ tauT|]
        e1 = e1 :- (sum(e1) / tauT)
        e2 = y[|tauT + 1 \ T|]
        e2 = e2 :- (sum(e2) / (T - tauT))
        cs1 = J(tauT, 1, 0)
        cs1[1] = e1[1]
        for (i = 2; i <= tauT; i++) {
            cs1[i] = cs1[i - 1] + e1[i]
        }
        cs2 = J(T - tauT, 1, 0)
        cs2[1] = e2[1]
        for (i = 2; i <= T - tauT; i++) {
            cs2[i] = cs2[i - 1] + e2[i]
        }
        kt[si - slo + 1] = (((T - tauT)^-2) * (cs2' * cs2)) / ((tauT^-2) * (cs1' * cs1))
    }
    k1 = max(kt)
    k1p = max(J(rows(kt), 1, 1) :/ kt)
    k4 = max((k1, k1p))
    stat = (k1, k1p, k4)
    boot = J(brep, 3, 0)
    err = y :- (sum(y) / T)
    for (n = 1; n <= brep; n++) {
        yb = err :* kypshift_gauss(T)
        for (si = slo; si <= shi; si++) {
            tauT = floor((si / T) * T)
            e1 = yb[|1 \ tauT|]
            e1 = e1 :- (sum(e1) / tauT)
            e2 = yb[|tauT + 1 \ T|]
            e2 = e2 :- (sum(e2) / (T - tauT))
            cs1 = J(tauT, 1, 0)
            cs1[1] = e1[1]
            for (i = 2; i <= tauT; i++) {
                cs1[i] = cs1[i - 1] + e1[i]
            }
            cs2 = J(T - tauT, 1, 0)
            cs2[1] = e2[1]
            for (i = 2; i <= T - tauT; i++) {
                cs2[i] = cs2[i - 1] + e2[i]
            }
            kt[si - slo + 1] = (((T - tauT)^-2) * (cs2' * cs2)) / ((tauT^-2) * (cs1' * cs1))
        }
        k1 = max(kt)
        k1p = max(J(rows(kt), 1, 1) :/ kt)
        boot[n, .] = (k1, k1p, max((k1, k1p)))
    }
    pv = J(1, 3, 0)
    for (j = 1; j <= 3; j++) {
        sv = sort(boot[., j], 1)
        cnt = 0
        for (n = 1; n <= brep; n++) {
            if (sv[n] >= stat[j]) cnt = cnt + 1
        }
        pv[j] = cnt / brep
    }
}

// ---------------------------------------------------------------
// main sequencer (port of detnumbreak)
// ---------------------------------------------------------------
void kypshift_run(string scalar yname, string scalar tname, string scalar tousename, real scalar mb, real scalar eps, real scalar eta, real scalar maxlag, real scalar brep, real scalar usepm, real scalar pmseed, real scalar usedots, real scalar usevallog)
{
    external real scalar kypshift_pm_on
    external real scalar kypshift_pm_state
    real colvector y, etaall, W0, BP0, Ws, BPs, seg
    real matrix pvall, tmpnt, datevec
    real rowvector thisdate, ext
    real scalar T, i, j, optlag, pvh, realb, wmax0, bpmax0, cvw0, cvbp0, pvw0, pvbp0, hi0, a, b, vallog
    real scalar dw, db, dc, dv, dp, dh, dh2
    external real scalar kypshift_singwarn
    kypshift_singwarn = 0
    kypshift_pm_on = usepm
    if (usepm) kypshift_pm_state = pmseed
    vallog = usevallog
    y = st_data(., yname, tousename)
    T = rows(y) - 1
    etaall = J(5, 1, 0)
    for (i = 1; i <= 5; i++) {
        etaall[i] = 1 - (1 - eta)^(1 / i)
    }
    tmpnt = J(5, 5, .)
    pvall = J(6, 6, .)
    optlag = 0
    datevec = J(0, 0, 0)
    kypshift_lagdatesel(y, mb, maxlag, eps, 0, optlag, datevec)
    W0 = J(mb, 1, 0)
    BP0 = J(mb, 1, 0)
    pvh = .
    wmax0 = .
    bpmax0 = .
    cvw0 = .
    cvbp0 = .
    pvw0 = .
    pvbp0 = .
    hi0 = .
    printf("{txt}Full-sample bootstrap (reps = %g):\n", brep)
    displayflush()
    F1a0 = J(mb, 1, 0)
    F1b0 = J(mb, 1, 0)
    dfa = J(1, 1, 0)
    dfb = J(1, 1, 0)
    kypshift_hfunc(y, mb, eps, eta, optlag, maxlag, brep, "m", usedots, vallog, pvh, W0, BP0, wmax0, bpmax0, cvw0, cvbp0, pvw0, pvbp0, hi0, F1a0, F1b0)
    pvall[1, 1] = pvh
    st_numscalar("r(optlag0)", optlag)
    st_numscalar("r(wmax)", wmax0)
    st_numscalar("r(udmax)", bpmax0)
    st_numscalar("r(cvw)", cvw0)
    st_numscalar("r(cvbp)", cvbp0)
    st_numscalar("r(pvw)", pvw0)
    st_numscalar("r(pvbp)", pvbp0)
    st_numscalar("r(pv)", pvh)
    st_numscalar("r(hstat)", hi0)
    st_matrix("r(wstats)", W0')
    st_matrix("r(bpstats)", BP0')
    st_matrix("r(f1a)", F1a0')
    st_matrix("r(f1b)", F1b0')
    if (pvh > etaall[1]) {
        realb = 0
    }
    else {
        realb = 5
        for (i = 1; i <= 5; i++) {
            kypshift_lagdatesel(y, i, maxlag, eps, 1, optlag, datevec)
            thisdate = datevec[|i, 1 \ i, i|] :+ maxlag :+ 1
            tmpnt[|i, 1 \ i, i|] = thisdate
            if (vallog) {
                printf("CAND i=%g optlag=%g dates:", i, optlag)
                for (j = 1; j <= i; j++) printf(" %g", thisdate[j])
                printf("\n")
            }
            ext = (0, thisdate, T + 1)
            for (j = 1; j <= i + 1; j++) {
                a = ext[j]
                b = ext[j + 1]
                seg = y[|a + 1 \ b|]
                printf("{txt}Candidate %g break(s), regime %g of %g bootstrap:\n", i, j, i + 1)
                displayflush()
                dw = .
                db = .
                dc = .
                dv = .
                dp = .
                dh = .
                dh2 = .
                Ws = J(1, 1, 0)
                BPs = J(1, 1, 0)
                pvh = .
                kypshift_hfunc(seg, mb, eps, eta, optlag, maxlag, brep, "1", usedots, vallog, pvh, Ws, BPs, dw, db, dc, dv, dp, dh, dh2, dfa, dfb)
                pvall[i + 1, j] = pvh
            }
            if (min(pvall[|i + 1, 1 \ i + 1, i + 1|]) > etaall[i]) {
                realb = i
                break
            }
        }
    }
    if (vallog) {
        printf("FINAL realb=%g\n", realb)
    }
    st_numscalar("r(nb)", realb)
    st_matrix("r(pvall)", pvall)
    st_matrix("r(tmpnt)", tmpnt)
    kypshift_phase2(y, realb, tmpnt, vallog, usedots)
}

void kypshift_phase2(real colvector y, real scalar realb, real matrix tmpnt, real scalar vallog, real scalar usedots)
{
    real colvector estdate, regimemodel
    real rowvector rtres, re1, re2, re3, re4, ctstat, ctpv
    real matrix eachrows, ctboot
    real scalar waldres, lagpure, CV, model, j, i
    if (realb != 0) estdate = tmpnt[|realb, 1 \ realb, realb|]'
    else estdate = J(0, 1, 0)
    printf("{txt}Article Table I and II diagnostics (mean-shift test, AR sums, CT tests):\n")
    displayflush()
    rtres = J(1, 5, .)
    waldres = .
    lagpure = .
    CV = .
    kypshift_robtest(y, realb, estdate, rtres, waldres, lagpure, CV)
    if (vallog) {
        if (realb != 0) {
            printf("F robtest:")
            for (j = 1; j <= 5; j++) printf(" %s", strofreal(rtres[j], "%21.0g"))
            printf(" CV=%s wald=%g\n", strofreal(CV, "%21.0g"), waldres)
        }
        else printf("F robtest: wald=%g\n", waldres)
    }
    re1 = J(1, 6, .)
    re2 = J(1, 4, .)
    re3 = J(1, 4, .)
    re4 = J(1, 8, .)
    model = .
    regimemodel = J(0, 1, 0)
    eachrows = J(0, 22, 0)
    kypshift_robesti(y, estdate, lagpure, waldres, re1, re2, re3, re4, model, regimemodel, eachrows)
    if (waldres == 1) {
        eachrows = J(0, 22, 0)
        kypshift_each(y, estdate, eachrows)
    }
    if (vallog) {
        printf("F re1:")
        for (j = 1; j <= 6; j++) printf(" %s", strofreal(re1[j], "%21.0g"))
        printf("\n")
        printf("F re2:")
        for (j = 1; j <= 4; j++) printf(" %s", strofreal(re2[j], "%21.0g"))
        printf("\n")
        printf("F re3:")
        for (j = 1; j <= 4; j++) printf(" %s", strofreal(re3[j], "%21.0g"))
        printf("\n")
        printf("F re4:")
        for (j = 1; j <= 8; j++) printf(" %s", strofreal(re4[j], "%21.0g"))
        printf("\n")
        printf("F model:")
        if (model < .) printf(" %g", model)
        printf(" rm:")
        for (j = 1; j <= rows(regimemodel); j++) printf(" %g", regimemodel[j])
        printf("\n")
        for (i = 1; i <= rows(eachrows); i++) {
            printf("F each %g:", i)
            for (j = 1; j <= 22; j++) printf(" %s", strofreal(eachrows[i, j], "%21.0g"))
            printf("\n")
        }
    }
    ctstat = J(1, 3, .)
    ctpv = J(1, 3, .)
    ctboot = J(0, 3, 0)
    kypshift_cttest(y, ctstat, ctpv, ctboot)
    if (vallog) {
        printf("F ctstat:")
        for (j = 1; j <= 3; j++) printf(" %s", strofreal(ctstat[j], "%21.0g"))
        printf("\n")
        printf("F ctpv:")
        for (j = 1; j <= 3; j++) printf(" %s", strofreal(ctpv[j], "%21.0g"))
        printf("\n")
        for (i = 1; i <= 10; i++) {
            printf("F ctboot %g:", i)
            for (j = 1; j <= 3; j++) printf(" %s", strofreal(ctboot[i, j], "%21.0g"))
            printf("\n")
        }
    }
    st_numscalar("r(meanwald)", rtres[1])
    st_numscalar("r(meanwaldcv)", CV)
    st_numscalar("r(meanshift)", (waldres == 0 ? 1 : (waldres == 1 ? 0 : .)))
    st_numscalar("r(arsum)", re1[1])
    st_numscalar("r(arsumlag)", re1[6])
    st_numscalar("r(aglow)", re3[1])
    st_numscalar("r(agup)", re3[2])
    st_numscalar("r(adfp)", re4[1])
    st_numscalar("r(adfptrend)", re4[5])
    st_numscalar("r(model7)", model)
    st_numscalar("r(ctk1)", ctstat[1])
    st_numscalar("r(ctk1p)", ctstat[2])
    st_numscalar("r(ctk4)", ctstat[3])
    st_numscalar("r(ctpv1)", ctpv[1])
    st_numscalar("r(ctpv2)", ctpv[2])
    st_numscalar("r(ctpv3)", ctpv[3])
    if (rows(regimemodel) > 0) st_matrix("r(regmodel)", regimemodel')
    if (rows(eachrows) > 0) st_matrix("r(table2)", (eachrows[., 1], eachrows[., 11], eachrows[., 12], eachrows[., 15], eachrows[., 6]))
}

end
