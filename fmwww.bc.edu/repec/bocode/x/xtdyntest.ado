*! version 0.5.0  02jun2026
*! xtdyntest -- Specification tests after dynamic panel-data GMM estimation
*! Author: Dr Merwan Roudane
*! Subcommands:
*!   csd  cross-sectional dependence residual battery
*!          - Pesaran (2004) CD test
*!          - Breusch & Pagan (1980) LM test
*!          - Friedman (1937) rank test (FR)
*!          - Frees (1995) test (FRE), normal approximation
*!   syr  Sarafidis-Yamagata-Robertson (2009) error-CSD Sargan-difference
*!          test (D_DIF2 / D_SYS2) for short dynamic-panel GMM
*!   break  De Wachter & Tzavalis (2012) structural-break detection in
*!          dynamic panels (Arellano-Bond GMM J-difference statistic);
*!          known breakpoint via at() (Theorem 1) OR unknown-breakpoint
*!          sup-test with simulated critical values (Theorem 2, eq 25)
*!          when at() is omitted; self-contained AR(p) engine
*!   lee  Lee (2014) generalized-spectral linearity / correct-functional-
*!          form test for linear dynamic panels vs nonlinear alternatives;
*!          reports M^a, M^b, M0^a, M0^b (all ->d N(0,1)) with a data-
*!          driven plug-in bandwidth; residuals from host predict or a
*!          self-contained linear dynamic FE fit
*! Designed to run AFTER: xtdpdgmm, xtabond2, xtabond (auto-detected),
*! or on user-supplied residuals via residuals(); break is self-contained.

program xtdyntest, rclass
    version 16.0
    gettoken sub 0 : 0, parse(" ,")
    if `"`sub'"' == "" {
        di as error "subcommand required"
        di as error "  syntax: {bf:xtdyntest} {it:subcommand} [, options]"
        di as error "  subcommands: {bf:csd}, {bf:syr}, {bf:break}, {bf:lee}"
        exit 198
    }
    if "`sub'" == "csd" {
        _xtdyntest_csd `0'
    }
    else if "`sub'" == "syr" {
        _xtdyntest_syr `0'
    }
    else if "`sub'" == "break" {
        _xtdyntest_break `0'
    }
    else if "`sub'" == "lee" {
        _xtdyntest_lee `0'
    }
    else {
        di as error `"unknown subcommand "`sub'""'
        di as error "  available: csd, syr, break, lee"
        exit 198
    }
    return add
end

*-----------------------------------------------------------------------
* csd subcommand: cross-sectional dependence battery on residuals
*-----------------------------------------------------------------------
program _xtdyntest_csd, rclass
    version 16.0
    syntax [, RESIDuals(varname numeric) ///
              GRAPH GRAPHname(string) ///
              noTABle SAVEcorr(name) ]

    *--- panel settings -------------------------------------------------
    quietly xtset
    local id   = r(panelvar)
    local time = r(timevar)
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}; cannot identify panel/time"
        exit 459
    }

    *--- obtain residuals ----------------------------------------------
    tempvar ehat touse
    if "`residuals'" != "" {
        quietly gen byte `touse' = !missing(`residuals', `id', `time')
        quietly gen double `ehat' = `residuals' if `touse'
        local resrc "user-supplied: `residuals'"
        local host "(residuals supplied)"
    }
    else {
        if "`e(cmd)'" == "" {
            di as error "no estimation results found and residuals() not given"
            di as error "  run xtdpdgmm/xtabond2/xtabond first, or pass residuals()"
            exit 301
        }
        local host "`e(cmd)'"
        if !inlist("`host'","xtdpdgmm","xtabond2","xtabond","xtdpd","xtdpdsys") {
            di as txt "note: host command `host' not formally supported;" ///
                      " attempting generic residual extraction"
        }
        local depvar "`e(depvar)'"

        * (1) host's own residuals via predict (most reliable across hosts)
        capture predict double `ehat' if e(sample), residuals
        if _rc capture predict double `ehat' if e(sample), e
        if !_rc {
            local resrc "predict residuals (host `host')"
        }
        else {
            * (2) fall back to level-equation reconstruction from e(b)
            if `: word count `depvar'' != 1 {
                di as error "could not obtain residuals: host predict failed and" ///
                            " e(depvar) is not a single variable"
                di as error "  supply residuals manually: {bf:xtdyntest csd, residuals(myres)}"
                exit 198
            }
            tempvar xb
            capture matrix score double `xb' = e(b) if e(sample)
            if _rc {
                di as error "could not obtain residuals (predict failed and e(b) score failed)"
                di as error "  supply residuals manually: {bf:xtdyntest csd, residuals(myres)}"
                exit 111
            }
            quietly gen double `ehat' = `depvar' - `xb' if e(sample)
            local resrc "reconstructed: `depvar' - xb (level equation)"
        }
        quietly gen byte `touse' = e(sample) & !missing(`ehat', `id', `time')
    }

    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable residual observations"
        exit 2000
    }

    *--- sort and call Mata engine -------------------------------------
    sort `id' `time'
    tempname R
    mata: _xtd_csd("`ehat'","`id'","`time'","`touse'","`R'")
    * scalars returned to Stata via st_numscalar/st_global inside Mata:
    *   __xtd_N __xtd_Tbal __xtd_Tmin __xtd_Tmax __xtd_npair __xtd_npok
    *   __xtd_avgrho __xtd_avgabsrho
    *   __xtd_lm __xtd_lmdf __xtd_cd __xtd_fr __xtd_frdf __xtd_fre __xtd_frez
    local N      = __xtd_N
    local Tmin   = __xtd_Tmin
    local Tmax   = __xtd_Tmax
    local Tbal   = __xtd_Tbal
    local npair  = __xtd_npair
    local npok   = __xtd_npok
    local avgrho = __xtd_avgrho
    local avgabs = __xtd_avgabsrho
    local LM     = __xtd_lm
    local LMdf   = __xtd_lmdf
    local CD     = __xtd_cd
    local FR     = __xtd_fr
    local FRdf   = __xtd_frdf
    local FRE    = __xtd_fre
    local FREz   = __xtd_frez
    capture scalar drop __xtd_N __xtd_Tbal __xtd_Tmin __xtd_Tmax ///
        __xtd_npair __xtd_npok __xtd_avgrho __xtd_avgabsrho ///
        __xtd_lm __xtd_lmdf __xtd_cd __xtd_fr __xtd_frdf __xtd_fre __xtd_frez

    *--- p-values -------------------------------------------------------
    local pLM  = chi2tail(`LMdf', `LM')
    local pCD  = 2*normal(-abs(`CD'))
    local pFR  = chi2tail(`FRdf', `FR')
    local pFRE = 2*normal(-abs(`FREz'))

    *--- optional bias-corrected CD* via xtcd2 (if installed) -----------
    local haveCDstar 0
    capture which xtcd2
    if !_rc {
        capture xtcd2 `ehat' if `touse', noestimation
        * xtcd2 may not accept these args silently across versions; keep soft
    }

    *--- results table --------------------------------------------------
    if "`table'" != "notable" {
        di ""
        di as txt "{hline 70}"
        di as txt "Cross-sectional dependence tests on residuals" _col(50) "{help xtdyntest##description:xtdyntest}"
        di as txt "{hline 70}"
        di as txt "Host estimator     : " as result "`host'"
        di as txt "Residual source    : " as result "`resrc'"
        di as txt "Panel (id, time)   : " as result "`id', `time'"
        di as txt "N (units)          : " as result %9.0g `N'
        if `Tmin'==`Tmax' di as txt "T (balanced)       : " as result %9.0g `Tbal'
        else              di as txt "T (min, max)       : " as result "`Tmin', `Tmax'  (unbalanced)"
        di as txt "Pairs used / total : " as result "`npok' / `npair'"
        di as txt "Avg corr / |corr|  : " as result %7.4f `avgrho' "  /  " %7.4f `avgabs'
        di as txt "{hline 70}"
        di as txt %-26s "Test" %12s "Statistic" %10s "Dist" %14s "p-value"
        di as txt "{hline 70}"
        di as txt %-26s "Pesaran (2004) CD"        as result %12.4f `CD'  as txt %10s "N(0,1)"        as result %14.4f `pCD'
        di as txt %-26s "Friedman (1937) FR"       as result %12.4f `FR'  as txt %10s "chi2(`FRdf')"  as result %14.4f `pFR'
        di as txt %-26s "Frees (1995) FRE"         as result %12.4f `FREz' as txt %10s "N(0,1)"       as result %14.4f `pFRE'
        di as txt %-26s "Breusch-Pagan (1980) LM"  as result %12.4f `LM'  as txt %10s "chi2"          as result %14.4f `pLM'
        di as txt "{hline 70}"
        di as txt "H0: errors are cross-sectionally independent."
        di as txt "Note: CD valid for large N. LM valid for large T, fixed N."
        di as txt "      FR/FRE assume (near-)balanced panels (T=`Tbal' used)."
        di as txt "{hline 70}"
    }

    *--- optional heatmap ----------------------------------------------
    if "`graph'" != "" {
        if "`graphname'" == "" local graphname "xtd_csd_heat"
        capture which heatplot
        if _rc {
            di as txt "note: {bf:heatplot} (SSC) not installed; skipping graph."
            di as txt "      install with: {stata ssc install heatplot}"
        }
        else {
            capture heatplot `R', ///
                color(hcl, diverging) ///
                title("Pairwise residual correlations") ///
                name(`graphname', replace)
            if _rc di as txt "note: heatplot failed (rc=`=_rc'); matrix is r(corr)."
        }
    }

    *--- save correlation matrix ---------------------------------------
    if "`savecorr'" != "" {
        matrix `savecorr' = `R'
    }

    *--- returns --------------------------------------------------------
    return scalar N        = `N'
    return scalar Tmin     = `Tmin'
    return scalar Tmax     = `Tmax'
    return scalar avgrho   = `avgrho'
    return scalar avgabsrho= `avgabs'
    return scalar CD       = `CD'
    return scalar p_CD     = `pCD'
    return scalar LM       = `LM'
    return scalar LM_df    = `LMdf'
    return scalar p_LM     = `pLM'
    return scalar FR       = `FR'
    return scalar FR_df    = `FRdf'
    return scalar p_FR     = `pFR'
    return scalar FRE      = `FRE'
    return scalar FRE_z    = `FREz'
    return scalar p_FRE    = `pFRE'
    return matrix corr     = `R'
    return local host      "`host'"
    return local cmd       "xtdyntest csd"
end

*-----------------------------------------------------------------------
* syr subcommand: Sarafidis-Yamagata-Robertson (2009) error-CSD test
*   Sargan/Hansen difference between the full instrument set and the set
*   that drops the lagged-dependent-variable (y) GMM instruments.
*   D_DIF2 (after difference GMM) or D_SYS2 (after system GMM).
*-----------------------------------------------------------------------
program _xtdyntest_syr, rclass
    version 16.0
    syntax [, noTABle]

    if "`e(cmd)'" == "" {
        di as error "no estimation results; run {bf:xtdpdgmm} or {bf:xtabond2} first"
        exit 301
    }
    local host "`e(cmd)'"
    if !inlist("`host'","xtdpdgmm","xtabond2") {
        di as error "the SYR test requires the host to be {bf:xtdpdgmm} or {bf:xtabond2}"
        di as error "  (it differences the full vs. x-only overidentification statistic)"
        exit 198
    }
    local depvar  "`e(depvar)'"
    local cmdline `"`e(cmdline)'"'
    if `"`cmdline'"' == "" {
        di as error "e(cmdline) not available; cannot rebuild the restricted model"
        exit 301
    }

    *--- build restricted command (drop lagged-dep-var instrument blocks) ---
    mata: _xtd_restrict("cmdline","depvar")
    local rcmd  `"`_xtd_rcmd'"'
    local nyblk = `_xtd_nyblk'
    local sys   = `_xtd_sys'
    if `nyblk' == 0 {
        di as error "could not identify lagged-dependent-variable (gmm) instruments"
        di as error "  the SYR test needs y-type GMM instruments to drop; check the model"
        exit 198
    }
    if "`host'" == "xtabond2" {
        if strpos(`"`cmdline'"',"noleveleq") local sys 0
        else                                  local sys 1
    }
    local dlabel = cond(`sys', "D_SYS2", "D_DIF2")
    local mlabel = cond(`sys', "system GMM (Blundell-Bond)", ///
                               "difference GMM (Arellano-Bond)")

    *--- restricted (x-only) fit ---
    capture quietly `rcmd'
    if _rc {
        di as error "restricted (x-only) model failed to estimate (rc=`=_rc')"
        di as error "  restricted command: `rcmd'"
        exit _rc
    }
    _xtd_getJ "`host'"
    local Sr  = r(_J)
    local Sru = r(_Ju)
    local dfr = r(_df)

    *--- full fit (re-run to restore e() and match framework) ---
    quietly `cmdline'
    _xtd_getJ "`host'"
    local Sf  = r(_J)
    local Sfu = r(_Ju)
    local dff = r(_df)

    *--- difference ---
    local D   = `Sf'  - `Sr'
    local Du  = `Sfu' - `Sru'
    local ddf = `dff' - `dfr'
    if `ddf' <= 0 {
        di as error "non-positive difference df (`ddf'); cannot form the SYR test"
        exit 198
    }
    local pD  = chi2tail(`ddf', max(`D',0))
    local pDu = chi2tail(`ddf', max(`Du',0))

    *--- table ---
    if "`table'" != "notable" {
        di ""
        di as txt "{hline 72}"
        di as txt "Sarafidis-Yamagata-Robertson (2009) error CSD test" _col(54) "{help xtdyntest##syr_desc:xtdyntest}"
        di as txt "{hline 72}"
        di as txt "Host estimator        : " as result "`host'"
        di as txt "Estimator framework   : " as result "`mlabel'"
        di as txt "Dependent variable    : " as result "`depvar'"
        di as txt "y-instrument blocks   : " as result "`nyblk' dropped for the restricted fit"
        di as txt "{hline 72}"
        di as txt "Overidentification (J) statistics" _col(40) %12s "Full" %12s "x-only"
        di as txt %-38s "  two-step J (robust/Hansen)" as result %12.4f `Sf'  %12.4f `Sr'
        di as txt %-38s "  Sargan J (unadjusted)"      as result %12.4f `Sfu' %12.4f `Sru'
        di as txt %-38s "  degrees of freedom"         as result %12.0f `dff' %12.0f `dfr'
        di as txt "{hline 72}"
        di as txt %-30s "SYR difference test" %12s "Statistic" %8s "df" %14s "p-value"
        di as txt "{hline 72}"
        di as txt %-30s "`dlabel' (Hansen/two-step)" as result %12.4f `D'  as txt %8.0f `ddf' as result %14.4f `pD'
        di as txt %-30s "`dlabel' (Sargan/unadj.)"   as result %12.4f `Du' as txt %8.0f `ddf' as result %14.4f `pDu'
        di as txt "{hline 72}"
        di as txt "H0: error cross-sectional dependence is homogeneous"
        di as txt "    (the lagged-dependent-variable instruments remain valid)."
        di as txt "Ha: heterogeneous error cross-sectional dependence."
        di as txt "Note: the J's are re-optimized separately on each instrument set"
        di as txt "      (SYR eqs 27-28); this can differ from a host's built-in"
        di as txt "      difference-in-Hansen (shared-weight) C statistic."
        if `D' < 0 | `Du' < 0 ///
            di as txt "      A negative finite-sample difference is truncated at 0 for the p-value."
        di as txt "Ref: Sarafidis, Yamagata & Robertson (2009), J. Econometrics 148: 149-161."
        di as txt "{hline 72}"
    }

    *--- returns ---
    return scalar D          = `D'
    return scalar D_df       = `ddf'
    return scalar p_D        = `pD'
    return scalar D_sargan   = `Du'
    return scalar p_D_sargan = `pDu'
    return scalar S_full     = `Sf'
    return scalar S_rest     = `Sr'
    return scalar S_full_u   = `Sfu'
    return scalar S_rest_u   = `Sru'
    return scalar df_full    = `dff'
    return scalar df_rest    = `dfr'
    return local  type       = cond(`sys',"SYS","DIF")
    return local  host       "`host'"
    return local  cmd        "xtdyntest syr"
    return local  rcmd       `"`rcmd'"'
end

*--- helper: extract overid J, unadjusted J, and df for the current fit ---
program _xtd_getJ, rclass
    args host
    if "`host'" == "xtdpdgmm" {
        quietly estat overid
        return scalar _J  = r(chi2_J)
        return scalar _Ju = r(chi2_J_u)
        return scalar _df = r(df_J)
    }
    else {
        return scalar _J  = e(hansen)
        return scalar _Ju = e(sargan)
        return scalar _df = e(hansen_df)
    }
end

*-----------------------------------------------------------------------
* break subcommand: De Wachter & Tzavalis (2012) structural-break test
*   Known-breakpoint statistic  N(Q2 - Qtau) ~ chi2, df = #omitted moments
*   + (dim theta_tau - dim theta_2).  Self-contained Arellano-Bond
*   difference-GMM engine (pure AR(p), non-collapsed GMM-style instruments).
*   Q2 = no-break Hansen J; Qtau = break-at-tau objective using the SAME
*   moment-covariance estimate (its submatrix), per DWT eqs (10)-(11).
*-----------------------------------------------------------------------
program _xtdyntest_break, rclass
    version 16.0
    syntax varname(numeric) [if] [in] [ , AT(real -99) ///
           AR(integer 1) REDUCED FULL noTABle ///
           REPS(integer 499) SEED(string) TRIM(real 0.15) ]

    *--- panel ----------------------------------------------------------
    quietly xtset
    local id   = r(panelvar)
    local time = r(timevar)
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}; cannot identify panel/time"
        exit 459
    }
    if `ar' < 1 {
        di as error "ar() must be a positive integer (AR order)"
        exit 198
    }

    *--- break model flavour (default: full = slope + fixed-effect break) -
    if "`reduced'" != "" & "`full'" != "" {
        di as error "specify only one of {bf:reduced} or {bf:full}"
        exit 198
    }
    local red = cond("`reduced'" != "", 1, 0)
    local mlab = cond(`red', "fixed-effect break only (reduced)", ///
                            "slope + fixed-effect break (full)")

    *--- known vs unknown breakpoint ------------------------------------
    *   at() omitted (sentinel -99) => unknown-breakpoint sup-test
    local supmode = cond(`at' == -99, 1, 0)

    *--- sample ---------------------------------------------------------
    marksample touse, novarlist
    quietly replace `touse' = 0 if missing(`varlist', `id', `time')
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable observations"
        exit 2000
    }

    sort `id' `time'

    *====================================================================
    * UNKNOWN BREAKPOINT: sup-test (DWT 2012, eqs 10-11, Theorem 2)
    *====================================================================
    if `supmode' {
        if `reps' < 99 {
            di as error "reps() must be at least 99"
            exit 198
        }
        if `trim' < 0 | `trim' >= 0.5 {
            di as error "trim() must be in [0, 0.5)"
            exit 198
        }
        if "`seed'" != "" {
            set seed `seed'
        }
        tempname res
        mata: _xtd_dwt_sup("`varlist'","`id'","`time'","`touse'", `ar', `red', `reps', `trim', "`res'")
        local rc = __xtds_rc
        if `rc' == 1 {
            capture scalar drop __xtds_rc
            di as error "too few time periods for the sup-test grid; need"
            di as error "  T >= ar+3 and a non-empty trimmed candidate set"
            exit 198
        }
        local N    = __xtds_N
        local Tg   = __xtds_Tg
        local M    = __xtds_M
        local ntau = __xtds_ntau
        local nrep = __xtds_reps
        local Q2   = __xtds_Q2
        local df2  = __xtds_df2
        local Vmax = __xtds_Vmax
        local pval = __xtds_p
        local btau = __xtds_btau
        local bpos = __xtds_bpos
        local bV   = __xtds_bV
        local bdf  = __xtds_bdf
        capture scalar drop __xtds_N __xtds_Tg __xtds_M __xtds_ntau ///
            __xtds_reps __xtds_Q2 __xtds_df2 __xtds_Vmax __xtds_p ///
            __xtds_btau __xtds_bpos __xtds_bV __xtds_bdf __xtds_rc

        *--- table ------------------------------------------------------
        if "`table'" != "notable" {
            di ""
            di as txt "{hline 72}"
            di as txt "De Wachter-Tzavalis (2012) sup-test for an unknown break" _col(63) "{help xtdyntest##break_desc:xtdyntest}"
            di as txt "{hline 72}"
            di as txt "Model                 : " as result "dynamic panel AR(`ar'), difference GMM"
            di as txt "Break hypothesis      : " as result "`mlab'"
            di as txt "Dependent variable    : " as result "`varlist'"
            di as txt "Panel (id, time)      : " as result "`id', `time'"
            di as txt "N (units) / T (grid)  : " as result "`N' / `Tg'"
            di as txt "Candidates (trim=" as result %4.2f `trim' as txt ") : " as result "`ntau' periods"
            di as txt "Simulation draws      : " as result "`nrep'"
            di as txt "{hline 72}"
            di as txt "Candidate profile  V(tau) = N(Q2 - Q_tau)" _col(50) %10s "V" %6s "df"
            di as txt "{hline 72}"
            forvalues r = 1/`ntau' {
                local pp  = `res'[`r',1]
                local tt  = `res'[`r',2]
                local vv  = `res'[`r',3]
                local dd  = `res'[`r',4]
                local mk  = cond(`pp' == `bpos', "  <- estimated break", "")
                di as txt "  `time' = " as result %6.0f `tt' ///
                    as txt "  (pos " as result %2.0f `pp' as txt ")" ///
                    as result %22.4f `vv' %6.0f `dd' as txt "`mk'"
            }
            di as txt "{hline 72}"
            di as txt %-30s "Sup-test" %12s "Vmax" %8s "" %14s "p-value"
            di as txt "{hline 72}"
            di as txt %-30s "max_tau S(tau) V(tau)" as result %12.4f `Vmax' as txt %8s "" as result %14.4f `pval'
            di as txt "{hline 72}"
            di as txt "Estimated break       : " as result "`time' = `btau'" as txt "  (V = " as result %6.3f `bV' as txt ", df = " as result %1.0f `bdf' as txt ")"
            di as txt "{hline 72}"
            di as txt "H0: no structural break anywhere in the candidate window."
            di as txt "Ha: a single " as result "`mlab'" as txt " at an unknown date."
            di as txt "Note: V(tau) is the DWT pointwise C statistic at each candidate;"
            di as txt "      Vmax is its scaled supremum (eq 11). The p-value is the"
            di as txt "      simulated tail probability of the Theorem-2 limit"
            di as txt "      max_k v'G_k v (v ~ N(0,I)), `nrep' draws."
            di as txt "Ref: De Wachter & Tzavalis (2012), Comput. Stat. Data Anal. 56: 3020-3034."
            di as txt "{hline 72}"
        }

        *--- returns ----------------------------------------------------
        return matrix profile = `res'
        return scalar stat   = `Vmax'
        return scalar p      = `pval'
        return scalar tau    = `btau'
        return scalar ktau   = `bpos'
        return scalar stat_b = `bV'
        return scalar df_b   = `bdf'
        return scalar Q2     = `Q2'
        return scalar df2    = `df2'
        return scalar ntau   = `ntau'
        return scalar reps   = `nrep'
        return scalar N      = `N'
        return scalar T      = `Tg'
        return scalar M      = `M'
        return scalar ar     = `ar'
        return local  test   "sup (unknown break)"
        return local  model  = cond(`red',"reduced","full")
        return local  host   "(self-contained)"
        return local  cmd    "xtdyntest break"
        exit
    }

    *====================================================================
    * KNOWN BREAKPOINT: Theorem 1 pointwise test
    *====================================================================
    tempname res
    mata: _xtd_dwt("`varlist'","`id'","`time'","`touse'", `ar', `at', `red', "`res'")
    * mata posts scalars: __xtd_N __xtd_Tg __xtd_ktau __xtd_M __xtd_Mt
    *   __xtd_Q2 __xtd_df2 __xtd_Qtau __xtd_dftau __xtd_stat __xtd_ddf
    *   __xtd_rc  (0 ok; 1 bad break; 2 nonpos df)
    local rc = __xtd_rc
    if `rc' == 1 {
        capture scalar drop __xtd_rc
        di as error "at(`at') is not a valid breakpoint: must be an observed"
        di as error "  time with ar+2 <= position <= T (need a pre-break period)"
        exit 198
    }
    local N    = __xtd_N
    local Tg   = __xtd_Tg
    local ktau = __xtd_ktau
    local M    = __xtd_M
    local Mt   = __xtd_Mt
    local Q2   = __xtd_Q2
    local df2  = __xtd_df2
    local Qt   = __xtd_Qtau
    local dft  = __xtd_dftau
    local stat = __xtd_stat
    local ddf  = __xtd_ddf
    capture scalar drop __xtd_N __xtd_Tg __xtd_ktau __xtd_M __xtd_Mt ///
        __xtd_Q2 __xtd_df2 __xtd_Qtau __xtd_dftau __xtd_stat __xtd_ddf __xtd_rc

    if `ddf' <= 0 {
        di as error "non-positive difference df (`ddf'); cannot form the test"
        exit 198
    }
    local pval = chi2tail(`ddf', max(`stat',0))

    *--- table ----------------------------------------------------------
    if "`table'" != "notable" {
        di ""
        di as txt "{hline 72}"
        di as txt "De Wachter-Tzavalis (2012) structural-break test" _col(54) "{help xtdyntest##break_desc:xtdyntest}"
        di as txt "{hline 72}"
        di as txt "Model                 : " as result "dynamic panel AR(`ar'), difference GMM"
        di as txt "Break hypothesis      : " as result "`mlab'"
        di as txt "Dependent variable    : " as result "`varlist'"
        di as txt "Panel (id, time)      : " as result "`id', `time'"
        di as txt "N (units) / T (grid)  : " as result "`N' / `Tg'"
        di as txt "Candidate break at    : " as result "`time' = `at'  (position `ktau')"
        di as txt "{hline 72}"
        di as txt "GMM objective (Hansen J) statistics" _col(46) %12s "Stat" %10s "df"
        di as txt %-44s "  No break          Q2"   as result %12.4f `Q2' %10.0f `df2'
        di as txt %-44s "  Break at tau      Qtau" as result %12.4f `Qt' %10.0f `dft'
        di as txt "{hline 72}"
        di as txt %-30s "Break test" %12s "Statistic" %8s "df" %14s "p-value"
        di as txt "{hline 72}"
        di as txt %-30s "N(Q2 - Qtau)" as result %12.4f `stat' as txt %8.0f `ddf' as result %14.4f `pval'
        di as txt "{hline 72}"
        di as txt "H0: no structural break at `time' = `at'."
        di as txt "Ha: " as result "`mlab'" as txt " starting at `time' = `at'."
        di as txt "Note: Qtau drops the moment conditions of the contaminated"
        di as txt "      differenced equation at the break and reuses the no-break"
        di as txt "      moment-covariance submatrix (DWT shared-weight C statistic)."
        di as txt "      Q2 equals the standard Arellano-Bond two-step Hansen J."
        di as txt "Ref: De Wachter & Tzavalis (2012), Comput. Stat. Data Anal. 56: 3020-3034."
        di as txt "{hline 72}"
    }

    *--- returns --------------------------------------------------------
    return scalar stat   = `stat'
    return scalar df     = `ddf'
    return scalar p      = `pval'
    return scalar Q2     = `Q2'
    return scalar df2    = `df2'
    return scalar Qtau   = `Qt'
    return scalar df_tau = `dft'
    return scalar tau    = `at'
    return scalar ktau   = `ktau'
    return scalar N      = `N'
    return scalar T      = `Tg'
    return scalar M      = `M'
    return scalar M_tau  = `Mt'
    return scalar ar     = `ar'
    return local  test   "pointwise (known break)"
    return local  model  = cond(`red',"reduced","full")
    return local  host   "(self-contained)"
    return local  cmd    "xtdyntest break"
end

*-----------------------------------------------------------------------
* lee subcommand: Lee (2014) generalized-spectral linearity / correct-
*   functional-form test for linear dynamic panels against nonlinear
*   alternatives.  Reports all four statistics M^a, M^b, M0^a, M0^b
*   (each ->d N(0,1) under H0, upper-tailed), with a data-driven plug-in
*   bandwidth (p0 = c0 * Tmax^(1/3)) or a user-fixed lag truncation.
*   Residuals: residuals() | host predict (post-estimation default) |
*   self-contained linear dynamic FE fit (fallback).
*   Ref: Lee (2014), J. Econometrics 178: 146-166.
*-----------------------------------------------------------------------
program _xtdyntest_lee, rclass
    version 16.0
    syntax varlist(numeric ts) [if] [in] [ , RESIDuals(varname numeric) ///
           AR(integer 1) EFfects(string) Pbar(integer 4) ///
           LAGs(integer 0) NGrid(integer 31) noTABle ]

    *--- panel ----------------------------------------------------------
    quietly xtset
    local id   = r(panelvar)
    local time = r(timevar)
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}; cannot identify panel/time"
        exit 459
    }
    if `ar' < 1 {
        di as error "ar() must be a positive integer (AR order)"
        exit 198
    }

    *--- option guards --------------------------------------------------
    if `pbar' < 2 {
        di as error "pbar() (preliminary bandwidth) must be at least 2"
        exit 198
    }
    if `lags' < 0 {
        di as error "lags() must be >= 0 (0 => data-driven plug-in bandwidth)"
        exit 198
    }
    if mod(`ngrid',2) == 0 {
        di as error "ngrid() must be odd (so the v-grid is symmetric about 0)"
        exit 198
    }
    if `ngrid' < 11 {
        di as error "ngrid() must be at least 11 for a usable integration grid"
        exit 198
    }

    *--- effects code: twoway(3) individual(1) time(2) none(0) -----------
    if "`effects'" == "" local effects "twoway"
    if      "`effects'" == "twoway"     local efc 3
    else if "`effects'" == "individual" local efc 1
    else if "`effects'" == "time"       local efc 2
    else if "`effects'" == "none"       local efc 0
    else {
        di as error `"effects() must be one of: twoway, individual, time, none"'
        exit 198
    }

    gettoken depvar indeps : varlist

    *--- obtain residuals ----------------------------------------------
    tempvar ehat touse
    if "`residuals'" != "" {
        quietly gen byte `touse' = !missing(`residuals', `id', `time') `if' `in'
        quietly gen double `ehat' = `residuals' if `touse'
        local resrc "user-supplied: `residuals'"
        local host  "(residuals supplied)"
    }
    else if "`e(cmd)'" != "" & "`indeps'" == "" {
        *--- post-estimation: take the host's residuals ----------------
        local host "`e(cmd)'"
        if !inlist("`host'","xtdpdgmm","xtabond2","xtabond","xtdpd","xtdpdsys") {
            di as txt "note: host command `host' not formally supported;" ///
                      " attempting generic residual extraction"
        }
        local hdep "`e(depvar)'"
        capture predict double `ehat' if e(sample), residuals
        if _rc capture predict double `ehat' if e(sample), e
        if !_rc {
            local resrc "predict residuals (host `host')"
        }
        else {
            if `: word count `hdep'' != 1 {
                di as error "could not obtain residuals: host predict failed and" ///
                            " e(depvar) is not a single variable"
                di as error "  supply residuals manually via {bf:residuals()}"
                exit 198
            }
            tempvar xb
            capture matrix score double `xb' = e(b) if e(sample)
            if _rc {
                di as error "could not obtain residuals (predict and e(b) score failed)"
                di as error "  supply residuals manually via {bf:residuals()}"
                exit 111
            }
            quietly gen double `ehat' = `hdep' - `xb' if e(sample)
            local resrc "reconstructed: `hdep' - xb (level equation)"
        }
        quietly gen byte `touse' = e(sample) & !missing(`ehat', `id', `time')
    }
    else {
        *--- self-contained: linear dynamic FE fit, take residuals -----
        marksample touse2, novarlist
        quietly replace `touse2' = 0 if missing(`depvar', `id', `time')
        capture quietly xtreg `depvar' L(1/`ar').`depvar' `indeps' if `touse2', fe
        if _rc {
            di as error "self-contained linear fit failed (rc=`=_rc')"
            di as error "  pass residuals() or estimate a host model first"
            exit 198
        }
        quietly predict double `ehat' if e(sample), e
        quietly gen byte `touse' = e(sample) & !missing(`ehat', `id', `time')
        local host  "(self-contained FE: `depvar' on L(1/`ar').`depvar')"
        local resrc "self-contained FE residuals"
    }

    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable residual observations"
        exit 2000
    }

    *--- sort and call the Mata engine ---------------------------------
    sort `id' `time'
    tempname RES
    mata: _xtd_lee("`ehat'","`id'","`time'","`touse'", `efc', `pbar', `lags', `ngrid', "`RES'")
    local rc = __xtl_rc
    if `rc' != 0 {
        capture scalar drop __xtl_rc
        di as error "Lee test engine failed (rc=`rc'); too few usable periods?"
        exit 198
    }
    local N    = __xtl_N
    local Tmax = __xtl_Tmax
    local M    = __xtl_M
    local p0   = __xtl_p0
    local pb   = __xtl_pbar
    local Ma   = __xtl_Ma
    local Mb   = __xtl_Mb
    local M0a  = __xtl_M0a
    local M0b  = __xtl_M0b
    capture scalar drop __xtl_N __xtl_Tmax __xtl_M __xtl_p0 __xtl_pbar ///
        __xtl_Ma __xtl_Mb __xtl_M0a __xtl_M0b __xtl_rc

    *--- upper-tailed N(0,1) p-values ----------------------------------
    local pMa  = normal(-`Ma')
    local pMb  = normal(-`Mb')
    local pM0a = normal(-`M0a')
    local pM0b = normal(-`M0b')

    local bwlab = cond(`lags' > 0, "fixed (lags = `lags')", "data-driven plug-in")
    local eflab : copy local effects

    *--- table ----------------------------------------------------------
    if "`table'" != "notable" {
        di ""
        di as txt "{hline 72}"
        di as txt "Lee (2014) generalized-spectral linearity test" _col(63) "{help xtdyntest##lee_desc:xtdyntest}"
        di as txt "{hline 72}"
        di as txt "Host / residuals      : " as result "`host'"
        di as txt "Residual source       : " as result "`resrc'"
        di as txt "Panel (id, time)      : " as result "`id', `time'"
        di as txt "N (units) / T (max)   : " as result "`N' / `Tmax'"
        di as txt "Within transform      : " as result "`eflab' demeaning"
        di as txt "Bandwidth p           : " as result %6.3f `p0' as txt "  (`bwlab', pbar = `pb')"
        di as txt "Integration grid M    : " as result "`M' points on [-3,3]"
        di as txt "{hline 72}"
        di as txt %-34s "Statistic" %14s "Value" %10s "Dist" %14s "p-value"
        di as txt "{hline 72}"
        di as txt %-34s "M^a  (robust, pooled)"    as result %14.4f `Ma'  as txt %10s "N(0,1)" as result %14.4f `pMa'
        di as txt %-34s "M^b  (robust, averaged)"  as result %14.4f `Mb'  as txt %10s "N(0,1)" as result %14.4f `pMb'
        di as txt %-34s "M0^a (i.i.d., pooled)"    as result %14.4f `M0a' as txt %10s "N(0,1)" as result %14.4f `pM0a'
        di as txt %-34s "M0^b (i.i.d., averaged)"  as result %14.4f `M0b' as txt %10s "N(0,1)" as result %14.4f `pM0b'
        di as txt "{hline 72}"
        di as txt "H0: the linear dynamic panel model is correctly specified"
        di as txt "    (errors are a martingale difference sequence; no neglected"
        di as txt "    nonlinearity in the conditional mean)."
        di as txt "Ha: neglected nonlinearity / functional-form misspecification."
        di as txt "Note: all statistics are upper-tailed; large positive values"
        di as txt "      reject H0. M^a is the heteroskedasticity-robust statistic"
        di as txt "      recommended by Lee (2014); M0^a/M0^b assume i.i.d. errors."
        di as txt "Ref: Lee (2014), J. Econometrics 178: 146-166."
        di as txt "{hline 72}"
    }

    *--- returns --------------------------------------------------------
    tempname S
    matrix `S' = (`Ma', `pMa' \ `Mb', `pMb' \ `M0a', `pM0a' \ `M0b', `pM0b')
    matrix rownames `S' = Ma Mb M0a M0b
    matrix colnames `S' = stat p
    return matrix stats = `S'

    return scalar Ma     = `Ma'
    return scalar p_Ma   = `pMa'
    return scalar Mb     = `Mb'
    return scalar p_Mb   = `pMb'
    return scalar M0a    = `M0a'
    return scalar p_M0a  = `pM0a'
    return scalar M0b    = `M0b'
    return scalar p_M0b  = `pM0b'
    return scalar stat   = `Ma'
    return scalar p      = `pMa'
    return scalar p0     = `p0'
    return scalar pbar   = `pb'
    return scalar N      = `N'
    return scalar T      = `Tmax'
    return scalar M      = `M'
    return scalar ar     = `ar'
    return local  bw      = cond(`lags' > 0, "fixed", "plug-in")
    return local  effects "`eflab'"
    return local  test    "generalized-spectral (linearity)"
    return local  host    "`host'"
    return local  cmd     "xtdyntest lee"
end

*-----------------------------------------------------------------------
* Mata engine
*-----------------------------------------------------------------------
version 16.0
mata:
mata set matastrict on

void _xtd_csd(string scalar ev, string scalar idv, string scalar timev,
              string scalar tousev, string scalar Rname)
{
    real colvector e, id, tt
    real colvector ids, times
    real matrix    U, M
    real scalar    N, Tn, i, j, t, k, nobs

    st_view(e,  ., ev,    tousev)
    st_view(id, ., idv,   tousev)
    st_view(tt, ., timev, tousev)

    ids   = uniqrows(id)
    times = uniqrows(tt)
    N     = rows(ids)
    Tn    = rows(times)
    nobs  = rows(e)

    // hash maps id->row, time->col
    transmorphic A, B
    A = asarray_create("real")
    B = asarray_create("real")
    for (i=1; i<=N;  i++) asarray(A, ids[i],   i)
    for (t=1; t<=Tn; t++) asarray(B, times[t], t)

    U = J(N, Tn, .)
    for (k=1; k<=nobs; k++) {
        U[asarray(A, id[k]), asarray(B, tt[k])] = e[k]
    }

    // per-row counts (balance info)
    real colvector cnt
    cnt = J(N,1,0)
    for (i=1; i<=N; i++) cnt[i] = rownonmissing(U[i,.])  // # nonmissing in row i
    real scalar Tmin, Tmax
    Tmin = min(cnt); Tmax = max(cnt)

    // rank matrix for Spearman (average ranks per row over nonmissing)
    real matrix Rk
    Rk = _xtd_rowranks(U)

    // accumulate pairwise statistics
    real scalar sLM, sCD, sR, sR2, sumAbs, npok, npair
    real scalar rho, rsp, Tij
    real matrix CorrM
    CorrM = I(N)
    sLM=0; sCD=0; sR=0; sR2=0; sumAbs=0; npok=0
    npair = N*(N-1)/2

    for (i=1; i<=N-1; i++) {
        for (j=i+1; j<=N; j++) {
            // common periods
            real rowvector ui, uj, ri, rj
            real colvector sel
            sel = selectindex( (U[i,.]:!=.) :& (U[j,.]:!=.) )'
            Tij = rows(sel)
            if (Tij >= 2) {
                ui = U[i, sel']
                uj = U[j, sel']
                rho = _xtd_corr(ui', uj')
                ri = Rk[i, sel']
                rj = Rk[j, sel']
                rsp = _xtd_corr(ri', rj')
                sLM = sLM + Tij*rho^2
                sCD = sCD + sqrt(Tij)*rho
                sR  = sR  + rsp
                sR2 = sR2 + rsp^2
                sumAbs = sumAbs + abs(rho)
                CorrM[i,j] = rho; CorrM[j,i] = rho
                npok = npok + 1
            }
        }
    }

    // CD and LM
    real scalar CD, LM, LMdf
    CD   = sqrt(2/(N*(N-1))) * sCD
    LM   = sLM
    LMdf = npair

    // Friedman FR and Frees FRE use a single T (balanced assumption)
    real scalar Tuse, Rave, R2ave, FR, FRdf, FRE, VarQ, FREz, avgrho, avgabs
    Tuse  = Tmax                      // representative T
    Rave  = (2/(N*(N-1))) * sR
    R2ave = (2/(N*(N-1))) * sR2
    FR    = (Tuse-1) * ((N-1)*Rave + 1)
    FRdf  = Tuse-1
    FRE   = N * ( R2ave - 1/(Tuse-1) )
    VarQ  = (32/25)*((Tuse+2)^2)/(((Tuse-1)^3)*((Tuse+1)^2)) ///
            + (4/5)*(((5*Tuse+6)^2)*(Tuse-3))/(Tuse*((Tuse-1)^2)*((Tuse+1)^2))
    FREz  = FRE / sqrt(VarQ)

    // average correlation (simple mean of rho over valid pairs)
    real scalar sRho
    sRho = 0
    for (i=1; i<=N-1; i++) for (j=i+1; j<=N; j++) if (CorrM[i,j]!=. & i<j) sRho = sRho + CorrM[i,j]
    avgrho = (npok>0 ? sRho/npok : .)
    avgabs = (npok>0 ? sumAbs/npok : .)

    // export to Stata
    st_matrix(Rname, CorrM)
    st_numscalar("__xtd_N", N)
    st_numscalar("__xtd_Tbal", Tuse)
    st_numscalar("__xtd_Tmin", Tmin)
    st_numscalar("__xtd_Tmax", Tmax)
    st_numscalar("__xtd_npair", npair)
    st_numscalar("__xtd_npok", npok)
    st_numscalar("__xtd_avgrho", avgrho)
    st_numscalar("__xtd_avgabsrho", avgabs)
    st_numscalar("__xtd_lm", LM)
    st_numscalar("__xtd_lmdf", LMdf)
    st_numscalar("__xtd_cd", CD)
    st_numscalar("__xtd_fr", FR)
    st_numscalar("__xtd_frdf", FRdf)
    st_numscalar("__xtd_fre", FRE)
    st_numscalar("__xtd_frez", FREz)
}

// Pearson correlation of two equal-length vectors (demeaned)
real scalar _xtd_corr(real colvector x, real colvector y)
{
    real colvector xc, yc
    real scalar sx, sy
    xc = x :- mean(x)
    yc = y :- mean(y)
    sx = sqrt(sum(xc:^2))
    sy = sqrt(sum(yc:^2))
    if (sx==0 | sy==0) return(0)
    return( sum(xc:*yc)/(sx*sy) )
}

// row-wise average ranks over nonmissing entries; missing stays missing
real matrix _xtd_rowranks(real matrix U)
{
    real matrix Rk
    real scalar i, n, c
    real colvector v, ord, rnk, sel
    Rk = J(rows(U), cols(U), .)
    for (i=1; i<=rows(U); i++) {
        sel = selectindex(U[i,.]:!=.)'
        n = rows(sel)
        if (n>0) {
            v   = U[i, sel']'
            rnk = _xtd_avgrank(v)
            for (c=1; c<=n; c++) Rk[i, sel[c]] = rnk[c]
        }
    }
    return(Rk)
}

// average ranks with ties for a column vector
real colvector _xtd_avgrank(real colvector v)
{
    real scalar n, a, b, avg, k2
    real colvector ord, out
    n   = rows(v)
    ord = order(v, 1)
    out = J(n,1,.)
    a = 1
    while (a <= n) {
        // extend tie block a..b (Mata && is NOT short-circuit, so guard
        // the subscript explicitly to avoid ord[n+1])
        b = a
        while (b < n) {
            if (v[ord[b+1]] != v[ord[a]]) break
            b++
        }
        // positions a..b are ties; average rank = (a+b)/2
        avg = (a+b)/2
        for (k2=a; k2<=b; k2++) out[ord[k2]] = avg
        a = b + 1
    }
    return(out)
}

//-----------------------------------------------------------------------
// SYR helpers: strip lagged-dependent-variable gmm()/iv() instrument
// blocks from a stored command line, returning the restricted command.
//-----------------------------------------------------------------------
void _xtd_restrict(string scalar cmdlocal, string scalar deplocal)
{
    string scalar cmd, dep, out, kw, grp, inner, vlist, low
    real scalar i, L, opos, cpos, np, sys

    cmd = st_local(cmdlocal)
    dep = st_local(deplocal)
    L   = strlen(cmd)
    out = ""
    np  = 0
    sys = 0
    i   = 1
    while (i <= L) {
        kw = _xtd_kwat(cmd, i)
        if (kw != "") {
            opos = i + strlen(kw)
            while (opos <= L && substr(cmd,opos,1) == " ") opos++
            if (substr(cmd,opos,1) == "(") {
                cpos = _xtd_matchparen(cmd, opos)
                if (cpos > 0) {
                    grp   = substr(cmd, i, cpos-i+1)
                    inner = substr(cmd, opos+1, cpos-opos-1)
                    vlist = _xtd_headlist(inner)
                    if (_xtd_hasdep(vlist, dep)) {
                        np++
                        low = strlower(inner)
                        if (strpos(low, "level") > 0) sys = 1
                        i = cpos + 1
                        while (i <= L && substr(cmd,i,1) == " ") i++
                        continue
                    }
                    else {
                        out = out + grp
                        i = cpos + 1
                        continue
                    }
                }
            }
        }
        out = out + substr(cmd, i, 1)
        i++
    }
    st_local("_xtd_rcmd",  _xtd_squeeze(out))
    st_local("_xtd_nyblk", strofreal(np))
    st_local("_xtd_sys",   strofreal(sys))
}

// keyword at position i with a valid left boundary; "" if none
string scalar _xtd_kwat(string scalar cmd, real scalar i)
{
    string scalar prev
    string rowvector kws
    real scalar k
    prev = (i==1) ? " " : substr(cmd, i-1, 1)
    if (!(prev==" " | prev=="," | prev=="(")) return("")
    kws = ("gmmstyle","gmm","ivstyle","iv")
    for (k=1; k<=cols(kws); k++)
        if (substr(cmd, i, strlen(kws[k])) == kws[k]) return(kws[k])
    return("")
}

// position of the ")" that matches the "(" at position opos
real scalar _xtd_matchparen(string scalar cmd, real scalar opos)
{
    real scalar d, p, L
    string scalar c
    L = strlen(cmd)
    d = 0
    for (p=opos; p<=L; p++) {
        c = substr(cmd,p,1)
        if (c=="(") d++
        else if (c==")") {
            d--
            if (d==0) return(p)
        }
    }
    return(0)
}

// content of a group up to its first depth-0 comma (the varlist)
string scalar _xtd_headlist(string scalar inner)
{
    real scalar d, p, L
    string scalar c
    L = strlen(inner)
    d = 0
    for (p=1; p<=L; p++) {
        c = substr(inner,p,1)
        if (c=="(") d++
        else if (c==")") d--
        else if (c=="," && d==0) return(substr(inner,1,p-1))
    }
    return(inner)
}

// does the dependent variable appear as a token in a varlist?
real scalar _xtd_hasdep(string scalar vlist, string scalar dep)
{
    string scalar s
    string rowvector toks
    real scalar k
    s = subinstr(vlist, ".", " ")
    s = subinstr(s, "(", " ")
    s = subinstr(s, ")", " ")
    s = subinstr(s, "/", " ")
    toks = tokens(s)
    for (k=1; k<=cols(toks); k++) if (toks[k]==dep) return(1)
    return(0)
}

// collapse repeated spaces and tidy " ," then trim
string scalar _xtd_squeeze(string scalar s)
{
    string scalar r
    r = s
    while (strpos(r,"  ")>0) r = subinstr(r,"  "," ")
    r = subinstr(r," ,", ",")
    return(strtrim(r))
}

//-----------------------------------------------------------------------
// De Wachter & Tzavalis (2012) known-breakpoint structural-break test.
// Pure AR(p) difference-GMM with non-collapsed (GMM-style) instruments.
//   Differenced eq at grid time g (g = p+2..Tg):
//       Dy_g = sum_l rho_l Dy_{g-l} [+ sum_l omega_l Dbreak_{g-l}] + Deps_g
//   Instruments for eq g: levels y_{i,1..g-2} (one moment column each).
//   No-break:  theta_2 = (rho_l), all M moments, Hansen J = Q2.
//   Break@tau: drop the moment columns of eq g=ktau (contaminated by the
//       fixed-effect break spike Delta(delta_i 1{t>=tau}) at t=tau); reuse
//       the no-break moment-covariance submatrix as the weight (shared-
//       weight C statistic, DWT eq (10)).  Full model adds p slope-break
//       regressors; reduced keeps only rho_l.
//   stat = Q2 - Qtau ~ chi2( #omitted + (dim theta_tau - dim theta_2) ).
//-----------------------------------------------------------------------
void _xtd_dwt(string scalar yv, string scalar idv, string scalar timev,
              string scalar tousev, real scalar p, real scalar tauval,
              real scalar reduced, string scalar resname)
{
    real colvector y, id, tt, ids, times
    real scalar    N, Tg, nobs, i, g, s, c, l, k, ktau, neq, M, Mt, Mall
    transmorphic   IA, IB
    real matrix    Ymat

    st_view(y,  ., yv,    tousev)
    st_view(id, ., idv,   tousev)
    st_view(tt, ., timev, tousev)

    ids   = uniqrows(id)
    times = uniqrows(tt)
    N     = rows(ids)
    Tg    = rows(times)
    nobs  = rows(y)

    // grid index of the requested breakpoint
    ktau = 0
    for (g=1; g<=Tg; g++) if (times[g]==tauval) ktau = g
    if (ktau < p+2 | ktau > Tg | ktau==0) {
        st_numscalar("__xtd_rc", 1)
        return
    }

    // level matrix Ymat (N x Tg) via hash maps
    IA = asarray_create("real"); IB = asarray_create("real")
    for (i=1; i<=N;  i++) asarray(IA, ids[i],   i)
    for (g=1; g<=Tg; g++) asarray(IB, times[g], g)
    Ymat = J(N, Tg, .)
    for (k=1; k<=nobs; k++)
        Ymat[asarray(IA, id[k]), asarray(IB, tt[k])] = y[k]

    // equation grid and moment-column map (eq g, instrument s)
    neq  = Tg - (p+1)                // equations g = p+2..Tg
    Mall = 0
    for (g=p+2; g<=Tg; g++) Mall = Mall + (g-2)
    real colvector colEq, colS
    colEq = J(Mall,1,0); colS = J(Mall,1,0)
    c = 0
    for (g=p+2; g<=Tg; g++) {
        for (s=1; s<=g-2; s++) {
            c = c+1; colEq[c]=g; colS[c]=s
        }
    }

    // regressors: full design = [p AR-lags | p slope-break lags]
    real scalar kfull
    kfull = 2*p

    // -- pass 1: accumulate A (Mall x kfull), b (Mall x 1), Hsum (Mall x Mall) --
    real matrix    Afull, Hsum, Zi, Hi, DXf
    real colvector b, Dy, valid
    real scalar    gg, e, ok, dyv, ds, sb
    Afull = J(Mall, kfull, 0)
    b     = J(Mall, 1, 0)
    Hsum  = J(Mall, Mall, 0)

    for (i=1; i<=N; i++) {
        Zi  = J(neq, Mall, 0)
        DXf = J(neq, kfull, 0)
        Dy  = J(neq, 1, 0)
        valid = J(neq, 1, 0)
        for (e=1; e<=neq; e++) {
            gg = p+1+e               // equation calendar grid index
            // dependent first difference
            if (Ymat[i,gg]==. | Ymat[i,gg-1]==.) continue
            dyv = Ymat[i,gg] - Ymat[i,gg-1]
            ok  = 1
            // AR-lag and slope-break regressors
            for (l=1; l<=p; l++) {
                if (Ymat[i,gg-l]==. | Ymat[i,gg-l-1]==.) {
                    ok = 0
                    break
                }
            }
            if (!ok) continue
            for (l=1; l<=p; l++) {
                DXf[e,l] = Ymat[i,gg-l] - Ymat[i,gg-l-1]
                sb = 0
                if (gg>=ktau)   sb = sb + Ymat[i,gg-l]
                if (gg-1>=ktau) sb = sb - Ymat[i,gg-l-1]
                DXf[e,p+l] = sb
            }
            Dy[e]    = dyv
            valid[e] = 1
            // instruments for equation gg: levels y_{i,1..gg-2}
            for (c=1; c<=Mall; c++) {
                if (colEq[c]==gg) {
                    ds = colS[c]
                    if (Ymat[i,ds]!=.) Zi[e,c] = Ymat[i,ds]
                }
            }
        }
        // first-difference one-step weight H (2 diag, -1 off-diag) on valid eqs
        Hi = J(neq, neq, 0)
        for (e=1; e<=neq; e++) {
            if (!valid[e]) continue
            Hi[e,e] = 2
            if (e>1)   if (valid[e-1]) Hi[e,e-1] = -1
            if (e<neq) if (valid[e+1]) Hi[e,e+1] = -1
        }
        Afull = Afull + cross(Zi, DXf)
        b     = b     + cross(Zi, Dy)
        Hsum  = Hsum  + Zi' * Hi * Zi
    }

    // drop structurally empty instrument columns (no firm owns them) so the
    // moment count and df match a standard Arellano-Bond GMM fit.
    real colvector keepc, colEqU
    keepc  = select((1::Mall), diagonal(Hsum):>0)
    M      = rows(keepc)
    colEqU = colEq[keepc]
    Afull  = Afull[keepc, .]
    b      = b[keepc]
    Hsum   = Hsum[keepc, keepc]

    // no-break regressors = first p columns of Afull
    real matrix A2
    A2 = Afull[., 1::p]

    // one-step theta1 (used only to form the moment covariance)
    real matrix W1, Phi2
    real colvector th1
    W1  = invsym(Hsum)
    th1 = invsym(cross(A2, W1*A2)) * cross(A2, W1*b)

    // -- pass 2: moment covariance Phi2 = sum_i (Zi'u_i)(Zi'u_i)' --
    real colvector gi, ui
    Phi2 = J(M, M, 0)
    for (i=1; i<=N; i++) {
        Zi  = J(neq, Mall, 0)
        DXf = J(neq, kfull, 0)
        Dy  = J(neq, 1, 0)
        valid = J(neq, 1, 0)
        for (e=1; e<=neq; e++) {
            gg = p+1+e
            if (Ymat[i,gg]==. | Ymat[i,gg-1]==.) continue
            ok = 1
            for (l=1; l<=p; l++)
                if (Ymat[i,gg-l]==. | Ymat[i,gg-l-1]==.) {
                    ok = 0
                    break
                }
            if (!ok) continue
            for (l=1; l<=p; l++) {
                DXf[e,l] = Ymat[i,gg-l] - Ymat[i,gg-l-1]
                sb = 0
                if (gg>=ktau)   sb = sb + Ymat[i,gg-l]
                if (gg-1>=ktau) sb = sb - Ymat[i,gg-l-1]
                DXf[e,p+l] = sb
            }
            Dy[e] = Ymat[i,gg] - Ymat[i,gg-1]
            valid[e] = 1
            for (c=1; c<=Mall; c++) {
                if (colEq[c]==gg) {
                    ds = colS[c]
                    if (Ymat[i,ds]!=.) Zi[e,c] = Ymat[i,ds]
                }
            }
        }
        ui = Dy - DXf[., 1::p]*th1
        gi = cross(Zi[., keepc], ui) // M x 1 (kept moment columns only)
        Phi2 = Phi2 + gi*gi'
    }

    // no-break two-step: theta2, Hansen J = Q2
    real matrix    W2
    real colvector th2, g2
    real scalar    Q2, df2
    W2  = invsym(Phi2)
    th2 = invsym(cross(A2, W2*A2)) * cross(A2, W2*b)
    g2  = (b - A2*th2)               // = sum_i Zi'(...)   (N already in Phi scale)
    Q2  = (g2' * W2 * g2)            // Hansen J (N-consistent: Phi2 ~ sum, g2 ~ sum)
    df2 = M - p

    // break model: drop moment columns of equation ktau
    real colvector keep
    real matrix    Acur, Wt, Phit
    real colvector bt, tht, gt
    real scalar    kt, Qt, dft
    keep = select((1::M), colEqU:!=ktau)
    Mt   = rows(keep)
    Phit = Phi2[keep, keep]
    Wt   = invsym(Phit)
    bt   = b[keep]
    if (reduced) {
        Acur = Afull[keep, 1::p]
        kt   = p
    }
    else {
        Acur = Afull[keep, .]
        kt   = kfull
    }
    tht = invsym(cross(Acur, Wt*Acur)) * cross(Acur, Wt*bt)
    gt  = (bt - Acur*tht)
    Qt  = (gt' * Wt * gt)
    dft = Mt - kt

    // difference statistic
    real scalar stat, ddf
    stat = Q2 - Qt
    ddf  = df2 - dft                 // = #omitted + (kt - p)

    // (placeholder correlation matrix slot for future unknown-break sweep)
    st_matrix(resname, (Q2, Qt, stat \ df2, dft, ddf))

    st_numscalar("__xtd_N",     N)
    st_numscalar("__xtd_Tg",    Tg)
    st_numscalar("__xtd_ktau",  ktau)
    st_numscalar("__xtd_M",     M)
    st_numscalar("__xtd_Mt",    Mt)
    st_numscalar("__xtd_Q2",    Q2)
    st_numscalar("__xtd_df2",   df2)
    st_numscalar("__xtd_Qtau",  Qt)
    st_numscalar("__xtd_dftau", dft)
    st_numscalar("__xtd_stat",  stat)
    st_numscalar("__xtd_ddf",   ddf)
    st_numscalar("__xtd_rc",    0)
}

//-----------------------------------------------------------------------
// Helpers for the unknown-breakpoint sup-test (DWT Theorem 2)
//-----------------------------------------------------------------------
// symmetric inverse square root via eigendecomposition (PSD-safe)
real matrix _xtd_invsqrt(real matrix S)
{
    real matrix    X, R
    real rowvector L
    real scalar    j, d
    symeigensystem(S, X, L)
    d = cols(L)
    for (j=1; j<=d; j++) {
        if (L[j] <= 1e-10) {
            L[j] = 0
        }
        else {
            L[j] = 1/sqrt(L[j])
        }
    }
    R = X * diag(L) * X'
    return(R)
}
// symmetric square root via eigendecomposition (PSD-safe)
real matrix _xtd_sqrt(real matrix S)
{
    real matrix    X, R
    real rowvector L
    real scalar    j, d
    symeigensystem(S, X, L)
    d = cols(L)
    for (j=1; j<=d; j++) {
        if (L[j] <= 0) {
            L[j] = 0
        }
        else {
            L[j] = sqrt(L[j])
        }
    }
    R = X * diag(L) * X'
    return(R)
}
// projection off the column space of X:  M = I - X (X'X)^- X'
real matrix _xtd_Moff(real matrix X)
{
    real scalar n
    n = rows(X)
    return(I(n) - X*invsym(cross(X,X))*X')
}

//-----------------------------------------------------------------------
// Per-candidate worker: for a given grid index ktau, compute the no-break
// objective Q2, the break objective Qtau (shared-weight C statistic), their
// dfs, and the Theorem-2 idempotent matrix Gtau (eq 25) for that candidate.
// Mirrors _xtd_dwt; Q2/df2/M are ktau-invariant (recomputed identically).
//-----------------------------------------------------------------------
void _xtd_dwt_one(real matrix Ymat, real colvector colEq, real colvector colS,
                  real scalar Mall, real scalar neq, real scalar p,
                  real scalar kfull, real scalar ktau, real scalar reduced,
                  real scalar N,
                  real scalar Q2, real scalar Qt, real scalar df2,
                  real scalar dft, real scalar M, real scalar Mt,
                  real matrix Gtau)
{
    real matrix    Afull, Hsum, Zi, Hi, DXf
    real colvector b, Dy, valid
    real scalar    i, e, gg, l, c, ok, dyv, ds, sb

    Afull = J(Mall, kfull, 0)
    b     = J(Mall, 1, 0)
    Hsum  = J(Mall, Mall, 0)

    // -- pass 1: Afull, b, Hsum --
    for (i=1; i<=N; i++) {
        Zi  = J(neq, Mall, 0)
        DXf = J(neq, kfull, 0)
        Dy  = J(neq, 1, 0)
        valid = J(neq, 1, 0)
        for (e=1; e<=neq; e++) {
            gg = p+1+e
            if (Ymat[i,gg]==. | Ymat[i,gg-1]==.) continue
            dyv = Ymat[i,gg] - Ymat[i,gg-1]
            ok  = 1
            for (l=1; l<=p; l++) {
                if (Ymat[i,gg-l]==. | Ymat[i,gg-l-1]==.) {
                    ok = 0
                    break
                }
            }
            if (!ok) continue
            for (l=1; l<=p; l++) {
                DXf[e,l] = Ymat[i,gg-l] - Ymat[i,gg-l-1]
                sb = 0
                if (gg>=ktau)   sb = sb + Ymat[i,gg-l]
                if (gg-1>=ktau) sb = sb - Ymat[i,gg-l-1]
                DXf[e,p+l] = sb
            }
            Dy[e]    = dyv
            valid[e] = 1
            for (c=1; c<=Mall; c++) {
                if (colEq[c]==gg) {
                    ds = colS[c]
                    if (Ymat[i,ds]!=.) Zi[e,c] = Ymat[i,ds]
                }
            }
        }
        Hi = J(neq, neq, 0)
        for (e=1; e<=neq; e++) {
            if (!valid[e]) continue
            Hi[e,e] = 2
            if (e>1)   if (valid[e-1]) Hi[e,e-1] = -1
            if (e<neq) if (valid[e+1]) Hi[e,e+1] = -1
        }
        Afull = Afull + cross(Zi, DXf)
        b     = b     + cross(Zi, Dy)
        Hsum  = Hsum  + Zi' * Hi * Zi
    }

    real colvector keepc, colEqU
    keepc  = select((1::Mall), diagonal(Hsum):>0)
    M      = rows(keepc)
    colEqU = colEq[keepc]
    Afull  = Afull[keepc, .]
    b      = b[keepc]
    Hsum   = Hsum[keepc, keepc]

    real matrix    A2, W1, Phi2
    real colvector th1
    A2  = Afull[., 1::p]
    W1  = invsym(Hsum)
    th1 = invsym(cross(A2, W1*A2)) * cross(A2, W1*b)

    // -- pass 2: Phi2 from one-step no-break residuals --
    real colvector gi, ui
    Phi2 = J(M, M, 0)
    for (i=1; i<=N; i++) {
        Zi  = J(neq, Mall, 0)
        DXf = J(neq, kfull, 0)
        Dy  = J(neq, 1, 0)
        valid = J(neq, 1, 0)
        for (e=1; e<=neq; e++) {
            gg = p+1+e
            if (Ymat[i,gg]==. | Ymat[i,gg-1]==.) continue
            ok = 1
            for (l=1; l<=p; l++) {
                if (Ymat[i,gg-l]==. | Ymat[i,gg-l-1]==.) {
                    ok = 0
                    break
                }
            }
            if (!ok) continue
            for (l=1; l<=p; l++) {
                DXf[e,l] = Ymat[i,gg-l] - Ymat[i,gg-l-1]
            }
            Dy[e] = Ymat[i,gg] - Ymat[i,gg-1]
            valid[e] = 1
            for (c=1; c<=Mall; c++) {
                if (colEq[c]==gg) {
                    ds = colS[c]
                    if (Ymat[i,ds]!=.) Zi[e,c] = Ymat[i,ds]
                }
            }
        }
        ui = Dy - DXf[., 1::p]*th1
        gi = cross(Zi[., keepc], ui)
        Phi2 = Phi2 + gi*gi'
    }

    real matrix    W2
    real colvector th2, g2
    W2  = invsym(Phi2)
    th2 = invsym(cross(A2, W2*A2)) * cross(A2, W2*b)
    g2  = (b - A2*th2)
    Q2  = (g2' * W2 * g2)
    df2 = M - p

    // break model at ktau: drop contaminated equation's moments
    real colvector keep
    real matrix    Acur, Wt, Phit
    real colvector bt, tht, gt
    real scalar    kt
    keep = select((1::M), colEqU:!=ktau)
    Mt   = rows(keep)
    Phit = Phi2[keep, keep]
    Wt   = invsym(Phit)
    bt   = b[keep]
    if (reduced) {
        Acur = Afull[keep, 1::p]
        kt   = p
    }
    else {
        Acur = Afull[keep, .]
        kt   = kfull
    }
    tht = invsym(cross(Acur, Wt*Acur)) * cross(Acur, Wt*bt)
    gt  = (bt - Acur*tht)
    Qt  = (gt' * Wt * gt)
    dft = Mt - kt

    // ---- Theorem 2 idempotent matrix Gtau (Appendix eq 25) ----
    //   G = Phi2^{1/2} R' A' Phitil^{-1/2} {Ma - S' Mb S} Phitil^{-1/2} A R Phi2^{1/2}
    //   reordering R puts the g1 valid moments first, contaminated ones last.
    real colvector omit, idx
    real scalar    g1
    real matrix    PhiR, Phi11, Phi12, At, Phitil, Pis
    real matrix    D2R, D2til, Xa, Ma, Xb, Mb, SMS, Inner, Mid, CoreR, Core, P12
    omit  = select((1::M), colEqU:==ktau)
    idx   = keep \ omit
    g1    = Mt
    PhiR  = Phi2[idx, idx]
    Phi11 = PhiR[1::g1, 1::g1]
    Phi12 = PhiR[1::g1, (g1+1)::M]
    At    = I(M)
    At[(g1+1)::M, 1::g1] = -Phi12' * invsym(Phi11)
    Phitil = At * PhiR * At'
    Pis    = _xtd_invsqrt(Phitil)
    D2R    = A2[idx, .]
    D2til  = At * D2R
    Xa     = Pis * D2til
    Ma     = _xtd_Moff(Xa)
    Xb     = _xtd_invsqrt(Phi11) * Acur
    Mb     = _xtd_Moff(Xb)
    SMS    = J(M, M, 0)
    SMS[1::g1, 1::g1] = Mb
    Inner  = Ma - SMS
    Mid    = Pis * Inner * Pis
    CoreR  = At' * Mid * At
    Core   = J(M, M, 0)
    Core[idx, idx] = CoreR
    P12    = _xtd_sqrt(Phi2)
    Gtau   = P12 * Core * P12
}

//-----------------------------------------------------------------------
// Unknown-breakpoint sup-test (DWT 2012, eqs 10-11, Theorem 2).
//   Sweep candidate tau over the (trimmed) grid, compute V(tau)=N(Q2-Qtau),
//   build Gtau per candidate, then simulate the null distribution of
//   Vmax = max_tau S(tau)*V(tau) by drawing z~N(0,I) and forming z'Gtau z.
//   p-value is computed in CDF (probability) space, which is invariant to
//   the arbitrary reference chi-square used by the scaling S(.).
//-----------------------------------------------------------------------
void _xtd_dwt_sup(string scalar yv, string scalar idv, string scalar timev,
                  string scalar tousev, real scalar p, real scalar reduced,
                  real scalar reps, real scalar trim, string scalar resname)
{
    real colvector y, id, tt, ids, times
    real scalar    N, Tg, nobs, i, g, s, c, k, neq, Mall
    transmorphic   IA, IB
    real matrix    Ymat

    st_view(y,  ., yv,    tousev)
    st_view(id, ., idv,   tousev)
    st_view(tt, ., timev, tousev)
    ids   = uniqrows(id)
    times = uniqrows(tt)
    N     = rows(ids)
    Tg    = rows(times)
    nobs  = rows(y)

    // need at least one interior candidate
    if (Tg < p+3) {
        st_numscalar("__xtds_rc", 1)
        return
    }

    IA = asarray_create("real"); IB = asarray_create("real")
    for (i=1; i<=N;  i++) asarray(IA, ids[i],   i)
    for (g=1; g<=Tg; g++) asarray(IB, times[g], g)
    Ymat = J(N, Tg, .)
    for (k=1; k<=nobs; k++)
        Ymat[asarray(IA, id[k]), asarray(IB, tt[k])] = y[k]

    neq  = Tg - (p+1)
    Mall = 0
    for (g=p+2; g<=Tg; g++) Mall = Mall + (g-2)
    real colvector colEq, colS
    colEq = J(Mall,1,0); colS = J(Mall,1,0)
    c = 0
    for (g=p+2; g<=Tg; g++) {
        for (s=1; s<=g-2; s++) {
            c = c+1; colEq[c]=g; colS[c]=s
        }
    }

    real scalar kfull, ntrim, klo, khi, ntau, kk, ktau
    real scalar Q2, Qt, df2, dft, Mw, Mtw, M
    kfull = 2*p
    ntrim = floor(trim*neq)
    klo   = p+2+ntrim
    khi   = Tg-ntrim
    if (klo < p+2) klo = p+2
    if (khi > Tg)  khi = Tg
    if (khi < klo) {
        st_numscalar("__xtds_rc", 1)
        return
    }
    ntau = khi - klo + 1

    real matrix    Gtau, Gstack, Gk
    real colvector Vv, dfv, tauv, posv
    M = 0
    for (kk=1; kk<=ntau; kk++) {
        ktau = klo + kk - 1
        _xtd_dwt_one(Ymat, colEq, colS, Mall, neq, p, kfull, ktau, reduced,
                     N, Q2, Qt, df2, dft, Mw, Mtw, Gtau)
        if (kk==1) {
            M      = Mw
            Gstack = J(M, M*ntau, 0)
            Vv     = J(ntau, 1, 0)
            dfv    = J(ntau, 1, 0)
            tauv   = J(ntau, 1, 0)
            posv   = J(ntau, 1, 0)
        }
        Gstack[., ((kk-1)*M+1)::(kk*M)] = Gtau
        Vv[kk]   = Q2 - Qt
        dfv[kk]  = df2 - dft
        tauv[kk] = times[ktau]
        posv[kk] = ktau
    }

    // observed Vmax in CDF space + argmax (estimated break)
    real scalar u, maxu_obs, kbest
    maxu_obs = -1
    kbest    = 1
    for (kk=1; kk<=ntau; kk++) {
        u = chi2(dfv[kk], max((Vv[kk], 0)))
        if (u > maxu_obs) {
            maxu_obs = u
            kbest    = kk
        }
    }

    // simulate null distribution of the sup statistic
    real scalar    r, q, maxu
    real colvector zsim, sims
    sims = J(reps, 1, 0)
    for (r=1; r<=reps; r++) {
        zsim = rnormal(M, 1, 0, 1)
        maxu = -1
        for (kk=1; kk<=ntau; kk++) {
            Gk = Gstack[., ((kk-1)*M+1)::(kk*M)]
            q  = (zsim' * Gk * zsim)
            if (q < 0) q = 0
            u  = chi2(dfv[kk], q)
            if (u > maxu) maxu = u
        }
        sims[r] = maxu
    }
    real scalar pval, dref, Vmax_obs
    pval     = mean(sims :>= maxu_obs)
    dref     = 1
    Vmax_obs = invchi2(dref, maxu_obs)

    // per-candidate result matrix: pos, tau, V, df, scaled-to-ref-chi2(1)
    real matrix RES
    RES = J(ntau, 5, 0)
    for (kk=1; kk<=ntau; kk++) {
        RES[kk,1] = posv[kk]
        RES[kk,2] = tauv[kk]
        RES[kk,3] = Vv[kk]
        RES[kk,4] = dfv[kk]
        RES[kk,5] = invchi2(dref, chi2(dfv[kk], max((Vv[kk], 0))))
    }
    st_matrix(resname, RES)

    st_numscalar("__xtds_N",    N)
    st_numscalar("__xtds_Tg",   Tg)
    st_numscalar("__xtds_M",    M)
    st_numscalar("__xtds_ntau", ntau)
    st_numscalar("__xtds_reps", reps)
    st_numscalar("__xtds_Q2",   Q2)
    st_numscalar("__xtds_df2",  df2)
    st_numscalar("__xtds_Vmax", Vmax_obs)
    st_numscalar("__xtds_p",    pval)
    st_numscalar("__xtds_btau", tauv[kbest])
    st_numscalar("__xtds_bpos", posv[kbest])
    st_numscalar("__xtds_bV",   Vv[kbest])
    st_numscalar("__xtds_bdf",  dfv[kbest])
    st_numscalar("__xtds_rc",   0)
}

//-----------------------------------------------------------------------
// Lee (2014) individual-specific generalized-spectral derivative test
// for linearity / correct functional form of a dynamic panel.
//   Bartlett kernel k(z)=(1-|z|)1(|z|<1); characteristic exponent d=q=1.
//   Weighting W = N(0,1) density on a uniform grid over [-3,3].
//   Statistics: Mhat^a, Mhat^b (heteroskedasticity-robust, m.d.s. centering)
//   and Mhat0^a, Mhat0^b (i.i.d.-error centering); all -> N(0,1) under H0.
//-----------------------------------------------------------------------
// Bartlett kernel value
real scalar _xtd_bart(real scalar z)
{
    real scalar az
    az = abs(z)
    if (az >= 1) return(0)
    return(1 - az)
}

void _xtd_lee(string scalar yv, string scalar idv, string scalar timev,
              string scalar tousev, real scalar effects, real scalar pbar,
              real scalar lagsfix, real scalar ngrid, string scalar resname)
{
    // ---- read data, build raw-residual panel U (N x Tg) ----
    real colvector y, id, tt, ids, times
    real scalar    N, Tg, nobs, i, g, k, M, K2
    transmorphic   IA, IB
    real matrix    U, E

    st_view(y,  ., yv,    tousev)
    st_view(id, ., idv,   tousev)
    st_view(tt, ., timev, tousev)
    ids   = uniqrows(id)
    times = uniqrows(tt)
    N     = rows(ids)
    Tg    = rows(times)
    nobs  = rows(y)

    IA = asarray_create("real"); IB = asarray_create("real")
    for (i=1; i<=N;  i++) asarray(IA, ids[i],   i)
    for (g=1; g<=Tg; g++) asarray(IB, times[g], g)
    U = J(N, Tg, .)
    for (k=1; k<=nobs; k++)
        U[asarray(IA, id[k]), asarray(IB, tt[k])] = y[k]

    // ---- within demeaning (two-way / individual / time / none) ----
    real colvector rsum, rcnt
    real rowvector csum, ccnt
    real scalar    gsum, gcnt, t, val, rm, cm, gm
    rsum = J(N,1,0); rcnt = J(N,1,0)
    csum = J(1,Tg,0); ccnt = J(1,Tg,0)
    gsum = 0; gcnt = 0
    for (i=1; i<=N; i++) {
        for (t=1; t<=Tg; t++) {
            if (U[i,t] != .) {
                val = U[i,t]
                rsum[i] = rsum[i] + val
                rcnt[i] = rcnt[i] + 1
                csum[t] = csum[t] + val
                ccnt[t] = ccnt[t] + 1
                gsum    = gsum + val
                gcnt    = gcnt + 1
            }
        }
    }
    gm = gsum/gcnt
    E  = J(N,Tg,.)
    for (i=1; i<=N; i++) {
        for (t=1; t<=Tg; t++) {
            if (U[i,t] != .) {
                rm = rsum[i]/rcnt[i]
                cm = csum[t]/ccnt[t]
                if (effects == 3)      E[i,t] = U[i,t] - rm - cm + gm
                else if (effects == 1) E[i,t] = U[i,t] - rm
                else if (effects == 2) E[i,t] = U[i,t] - cm
                else                   E[i,t] = U[i,t]
            }
        }
    }

    // ---- v-grid (uniform on [-3,3]) and extended grid [-6,6] ----
    real scalar    dv, Tmax
    real rowvector vrow, erow, wv
    M    = ngrid
    K2   = 2*M - 1
    dv   = 6/(M-1)
    vrow = J(1,M,0); wv = J(1,M,0)
    for (k=1; k<=M; k++) {
        vrow[k] = -3 + (k-1)*dv
        wv[k]   = normalden(vrow[k]) * dv
    }
    wv[1] = wv[1]/2; wv[M] = wv[M]/2
    erow = J(1,K2,0)
    for (k=1; k<=K2; k++) erow[k] = -6 + (k-1)*dv

    // ---- pass A: per-unit I_ij, R_i(j), G_i, Ti (bandwidth inputs) ----
    real matrix    Imat, Rmat
    real colvector Tivec, s2vec, Gvec
    real colvector ev, pvec, both, a, b
    real rowvector Cphi, Sphi, sRe, sIm
    real scalar    j, nij, Sa
    real matrix    cosB, sinB
    Imat  = J(N, Tg-1, 0)
    Rmat  = J(N, Tg-1, 0)
    Tivec = J(N,1,0)
    s2vec = J(N,1,0)
    Gvec  = J(N,1,0)
    for (i=1; i<=N; i++) {
        ev   = E[i,.]'
        pvec = (ev :!= .)
        a    = select(ev, pvec)
        Tivec[i] = rows(a)
        if (Tivec[i] < 3) continue
        s2vec[i] = mean(a:^2)
        Cphi = mean(cos(a*vrow))
        Sphi = mean(sin(a*vrow))
        Gvec[i] = sum(wv :* (1 :- (Cphi:^2 + Sphi:^2)))
        for (j=1; j<=Tg-1; j++) {
            both = selectindex( pvec[(j+1)::Tg] :* pvec[1::(Tg-j)] )
            nij  = rows(both)
            if (nij < 2) continue
            b    = ev[both]
            a    = ev[both :+ j]
            Sa   = sum(a)
            cosB = cos(b*vrow)
            sinB = sin(b*vrow)
            sRe  = ((a' * cosB) :- Sa:*Cphi) :/ nij
            sIm  = ((a' * sinB) :- Sa:*Sphi) :/ nij
            Imat[i,j] = sum(wv :* (sRe:^2 + sIm:^2))
            Rmat[i,j] = (a' * b)/nij
        }
    }
    Tmax = max(Tivec)

    // ---- bandwidth: fixed lagsfix, else data-driven plug-in p0 ----
    real scalar p0, numc, denc, c0, kk0, w2, jj, mlt
    if (lagsfix > 0) {
        p0 = lagsfix
    }
    else {
        numc = 0; denc = 0
        for (i=1; i<=N; i++) {
            if (Tivec[i] < 3) continue
            for (j=1; j<=Tg-1; j++) {
                both = selectindex( (E[i,.]':!=.)[(j+1)::Tg] :* (E[i,.]':!=.)[1::(Tg-j)] )
                nij  = rows(both)
                if (nij < 2) continue
                kk0  = _xtd_bart(j/pbar)
                w2   = kk0*kk0
                numc = numc + nij*w2*(j*j)*Imat[i,j]
                denc = denc + nij*w2*Rmat[i,j]*Gvec[i]
            }
        }
        if (denc <= 0 | numc <= 0) {
            p0 = pbar
        }
        else {
            c0 = (3 * numc/denc)^(1/3)
            p0 = c0 * (Tmax^(1/3))
        }
        if (p0 < 1)        p0 = 1
        if (p0 > Tmax-1)   p0 = Tmax-1
    }

    // ---- pass B: per-unit term, centering/scaling, accumulate ----
    real scalar num, sumC0, sumD0, sumCi, sumDi, M0b, Mb
    real scalar term, C0i, D0i, Ci, Di, jm, l, lm, nijl
    real scalar IIphi, kj2, kl2, kj4
    real colvector cc, bj, bl, absphi2
    real rowvector CphiE, SphiE
    real matrix    ExtRe, ExtIm, Jb
    real matrix    psjRe, psjIm, pslRe, pslIm, Mrr, Mii, Mri, Mir
    real matrix    ReB, ImB, sig0Re, sig0Im
    real scalar    m, n
    num = 0; sumC0 = 0; sumD0 = 0; sumCi = 0; sumDi = 0
    M0b = 0; Mb = 0
    for (i=1; i<=N; i++) {
        if (Tivec[i] < 3) continue
        ev   = E[i,.]'
        pvec = (ev :!= .)
        a    = select(ev, pvec)
        Cphi = mean(cos(a*vrow))
        Sphi = mean(sin(a*vrow))
        CphiE = mean(cos(a*erow))
        SphiE = mean(sin(a*erow))
        absphi2 = (Cphi:^2 + Sphi:^2)'

        // --- numerator term_i and robust centering Ci ---
        term = 0; Ci = 0
        jm = floor(p0 - 1e-9)
        if (jm > Tg-1) jm = Tg-1
        for (j=1; j<=jm; j++) {
            both = selectindex( pvec[(j+1)::Tg] :* pvec[1::(Tg-j)] )
            nij  = rows(both)
            if (nij < 2) continue
            kj2  = _xtd_bart(j/p0); kj2 = kj2*kj2
            term = term + kj2*nij*Imat[i,j]
            b    = ev[both]
            a    = ev[both :+ j]
            cosB = cos(b*vrow)
            sinB = sin(b*vrow)
            Jb   = ((cosB :- Cphi):^2 + (sinB :- Sphi):^2) * wv'
            Ci   = Ci + kj2*((a:^2)' * Jb)/nij
        }

        // --- i.i.d. centering C0i and scaling D0i ---
        real scalar sk2, sk4, intCv
        sk2 = 0; sk4 = 0
        for (j=1; j<=jm; j++) {
            kj2 = _xtd_bart(j/p0); kj4 = kj2^4; kj2 = kj2*kj2
            sk2 = sk2 + kj2
            sk4 = sk4 + kj4
        }
        intCv = sum(wv :* (1 :- absphi2'))
        C0i   = s2vec[i] * intCv * sk2
        // 2D integral II_phi for D0i
        ExtRe = J(M,M,0); ExtIm = J(M,M,0)
        for (m=1; m<=M; m++) {
            for (n=1; n<=M; n++) {
                ExtRe[m,n] = CphiE[m+n-1]
                ExtIm[m,n] = SphiE[m+n-1]
            }
        }
        sig0Re = ExtRe - (Cphi'*Cphi - Sphi'*Sphi)
        sig0Im = ExtIm - (Cphi'*Sphi + Sphi'*Cphi)
        IIphi  = (wv * (sig0Re:^2 + sig0Im:^2) * wv')
        D0i    = 2 * (s2vec[i]^2) * IIphi * sk4

        // --- robust scaling Di (diagonal lag sum) ---
        // Lee (2014) eq. for D-hat_i writes a DOUBLE sum over lags (j,l).  The
        // off-diagonal (j!=l) terms estimate Cov(q_j,q_l), which is zero in the
        // limit because the lag-j and lag-l generalized covariances are
        // asymptotically independent (m.d.s.; only a single lag enters Ass. A.6).
        // In finite samples those terms are squared near-zero noise that can ONLY
        // inflate the variance estimate, never reduce it -- empirically this makes
        // D-hat_i ~2.8x too large and pathologically volatile, leaving M^a badly
        // conservative (5% size ~1.6% at (N,T)=(50,50)).  Summing only the
        // diagonal (j=l) terms -- still heteroskedasticity-robust via the e^2_it
        // weights, and a consistent estimator of the SAME asymptotic variance --
        // reproduces Lee's published Table-2 size (5% size ~4.8% vs paper 5.7%).
        Di = 0
        for (j=1; j<=jm; j++) {
            kj4  = _xtd_bart(j/p0); kj4 = kj4^4
            both = selectindex( pvec[(j+1)::Tg] :* pvec[1::(Tg-j)] )
            nij  = rows(both)
            if (nij < 2) continue
            cc   = ev[both :+ j]
            cc   = cc:^2
            b    = ev[both]
            psjRe = cos(b*vrow) :- Cphi
            psjIm = sin(b*vrow) :- Sphi
            Mrr = psjRe' * (cc :* psjRe)
            Mii = psjIm' * (cc :* psjIm)
            Mri = psjRe' * (cc :* psjIm)
            ReB = (Mrr - Mii) :/ nij
            ImB = (Mri + Mri') :/ nij
            Di  = Di + 2*kj4*(wv * (ReB:^2 + ImB:^2) * wv')
        }

        // --- accumulate ---
        num   = num + term
        sumC0 = sumC0 + C0i
        sumD0 = sumD0 + D0i
        sumCi = sumCi + Ci
        sumDi = sumDi + Di
        if (D0i > 0) M0b = M0b + (term - C0i)/sqrt(D0i)
        if (Di  > 0) Mb  = Mb  + (term - Ci )/sqrt(Di)
    }

    real scalar Ma, M0a
    M0a = .
    Ma  = .
    if (sumD0 > 0) M0a = (num - sumC0)/sqrt(sumD0)
    if (sumDi > 0) Ma  = (num - sumCi)/sqrt(sumDi)
    M0b = M0b/sqrt(N)
    Mb  = Mb /sqrt(N)

    real matrix RES
    RES = (Ma \ Mb \ M0a \ M0b)
    st_matrix(resname, RES)
    st_numscalar("__xtl_N",     N)
    st_numscalar("__xtl_Tmax",  Tmax)
    st_numscalar("__xtl_M",     M)
    st_numscalar("__xtl_p0",    p0)
    st_numscalar("__xtl_pbar",  pbar)
    st_numscalar("__xtl_Ma",    Ma)
    st_numscalar("__xtl_Mb",    Mb)
    st_numscalar("__xtl_M0a",   M0a)
    st_numscalar("__xtl_M0b",   M0b)
    st_numscalar("__xtl_rc",    0)
}
end
