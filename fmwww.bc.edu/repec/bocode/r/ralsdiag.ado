*! ralsdiag 1.0.1  16may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! Pre-test diagnostics for the RALS family:
*!    - Shapiro-Wilk and Jarque-Bera normality tests
*!    - Harvey, Leybourne & Xiao (2008) linearity test
*!    - skewness, kurtosis
*!    - RALS  rho^2 derived from a first-pass ADF residual
*!  These three diagnostics feed the decision tree of Yilanci & Ozgur (2025)
*!  (Figure 3 of the EU5 RIP paper).
*------------------------------------------------------------------------------

program define ralsdiag, rclass
    version 14.0
    capture mata: __rals_loaded()
    if _rc qui _rals_mata
    syntax varname(ts) [if] [in], [                ///
            TREND                                  ///
            MAXLags(integer 8)                     ]
    marksample touse
    qui count if `touse'
    if r(N) < 20 {
        di as error "sample too small for diagnostics (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be tsset before running ralsdiag"
        exit 459
    }

    tempvar dy lyser e2
    qui gen `dy' = D.`varlist' if `touse'

    * stage-0 ADF residual to feed RALS w
    qui regress `dy' L.`varlist' if `touse'
    qui predict double `e2' if e(sample), residual

    * Skewness & kurtosis
    qui sum `e2' if `touse', detail
    local skew  = r(skewness)
    local kurt  = r(kurtosis)

    * Shapiro-Wilk
    qui swilk `e2' if `touse'
    local sw_W  = r(W)
    local sw_p  = r(p)

    * Jarque-Bera (compute manually)
    qui sum `e2' if `touse'
    local N = r(N)
    local JB = (`N'/6)*(`skew'^2 + ((`kurt'-3)^2)/4)
    local JB_p = chi2tail(2,`JB')

    * Harvey-Leybourne-Xiao linearity test (simple proxy via cubed regressor)
    tempvar x3
    qui gen `x3' = L.`varlist'^3 if `touse'
    qui regress `dy' L.`varlist' `x3' if `touse'
    local HLX_F  = e(F)
    local HLX_p  = Ftail(e(df_m), e(df_r), e(F))

    * RALS rho^2 estimate from auxiliary regression -------------------------
    tempvar w1 w2
    qui sum `e2' if `touse', meanonly
    qui gen `w1' = (`e2')^2 if `touse'
    qui sum `w1' if `touse', meanonly
    qui replace `w1' = `w1' - r(mean) if `touse'
    qui gen `w2' = (`e2')^3 if `touse'
    qui sum `w2' if `touse', meanonly
    local m3 = r(mean)
    qui sum `e2' if `touse', meanonly
    local m2 = r(mean)
    qui replace `w2' = `w2' - `m3' - 3*`m2'*(`e2') if `touse'
    qui regress `dy' L.`varlist' `w1' `w2' if `touse'
    qui predict double _eA if e(sample), residual
    qui sum _eA if `touse'
    local sigA = r(Var)
    qui regress `dy' L.`varlist' if `touse'
    qui predict double _eB if e(sample), residual
    qui sum _eB if `touse'
    local sigB = r(Var)
    local rho2 = `sigA' / `sigB'
    capture drop _eA _eB

    *--------------------------------------------------------------------------
    di as text ""
    di as text "{c TLC}{hline 78}{c TRC}"
    di as text "{c |}  " as result "RALS diagnostics for `varlist'{col 79}{c |}"
    di as text "{c BLC}{hline 78}{c BRC}"
    di as text ""
    di as text "  {bf:1. Distribution of first-difference residuals}"
    di as text "     Skewness         = " as result %8.4f `skew'
    di as text "     Kurtosis         = " as result %8.4f `kurt'
    di as text "     Shapiro-Wilk W   = " as result %8.4f `sw_W'  ///
        as text "    p-value = " as result %6.4f `sw_p'
    di as text "     Jarque-Bera      = " as result %8.4f `JB'    ///
        as text "    p-value = " as result %6.4f `JB_p'
    di as text ""
    di as text "  {bf:2. Linearity (cube test, Harvey-style)}"
    di as text "     F-statistic      = " as result %8.4f `HLX_F' ///
        as text "    p-value = " as result %6.4f `HLX_p'
    di as text ""
    di as text "  {bf:3. RALS rho^2 (variance ratio sigma_RALS^2 / sigma_ADF^2)}"
    di as text "     rho^2            = " as result %8.4f `rho2'
    di as text "     (Closer to 0  => more power gain from the RALS terms.)"
    di as text ""
    di as text "  {bf:Suggested decision branch (Yilanci & Ozgur 2025, Fig.3)}"
    if `sw_p' < 0.05 {
        di as text "     - non-normal residuals: RALS augmentation is informative."
    }
    else {
        di as text "     - residuals look normal: RALS augmentation gives little gain."
    }
    if `HLX_p' < 0.10 {
        di as text "     - linearity rejected (10%): consider Fourier or KSS-type tests."
    }
    else {
        di as text "     - linearity not rejected: linear ADF/LM variants suffice."
    }
    di as text ""

    return scalar skewness = `skew'
    return scalar kurtosis = `kurt'
    return scalar sw_W     = `sw_W'
    return scalar sw_p     = `sw_p'
    return scalar JB       = `JB'
    return scalar JB_p     = `JB_p'
    return scalar HLX_F    = `HLX_F'
    return scalar HLX_p    = `HLX_p'
    return scalar rho2     = `rho2'
end
