*! version 1.0.0  03mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! xtmispanel: Comprehensive Missing Data Detection, Imputation & Diagnostics
*!             for Panel (Time-Series Cross-Sectional) Data
*! Requires: Stata 15.0 or later, panel data must be xtset

capture program drop xtmispanel
program define xtmispanel, rclass
    version 15.0

    * ─── Parse syntax ─────────────────────────────────────────────────────
    syntax [varlist(default=none ts)] [if] [in] , ///
        [ DETect                    /// Module 1: detection & summary tables
          TEST                      /// Module 2: MCAR/MAR mechanism tests
          IMPute(string)            /// Module 3: imputation method
          GENerate(name)            /// name for imputed variable
          replace                   /// overwrite existing imputed var
          SENSitivity               /// Module 4: sensitivity analysis
          METHods(string)           /// subset of methods for sensitivity
          GRaph                     /// Module 5: visualizations
          IMPVar(varname)           /// imputed var for density overlay
          KNN(integer 5)            /// neighbors for KNN imputation
          MICE(integer 5)           /// number of MI imputations
        ]

    * ─── Verify panel setup ───────────────────────────────────────────────
    capture xtset
    if _rc != 0 {
        di as err "Data must be {bf:xtset} before using {bf:xtmispanel}."
        di as err "Example: {cmd:xtset panelid timevar}"
        exit 459
    }
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"

    * If no varlist, use all numeric variables except panel/time IDs
    if "`varlist'" == "" {
        ds, has(type numeric)
        local varlist `r(varlist)'
        local varlist : list varlist - panelvar
        local varlist : list varlist - timevar
    }

    * ─── Default action: detect if nothing specified ──────────────────────
    if "`detect'" == "" & "`test'" == "" & "`impute'" == "" & ///
       "`sensitivity'" == "" & "`graph'" == "" {
        local detect "detect"
    }

    marksample touse, novarlist

    * ─── Display header ───────────────────────────────────────────────────
    di
    di in smcl in gr "{hline 78}"
    di in gr "{bf:xtmispanel}" _col(20) "Missing Data Diagnostics for Panel Data" ///
        _col(67) "v1.0.0"
    di in gr "{hline 78}"
    di in gr "Panel variable: " in ye "`panelvar'" ///
        _col(40) in gr "Time variable: " in ye "`timevar'"

    * Count panels and time periods
    tempvar pid
    qui egen `pid' = group(`panelvar') if `touse'
    qui su `pid' if `touse', meanonly
    local npanels = r(max)
    qui levelsof `timevar' if `touse', local(timelevels)
    local ntimes : word count `timelevels'
    di in gr "Panels: " in ye "`npanels'" ///
        _col(40) in gr "Time periods: " in ye "`ntimes'"
    di in gr "{hline 78}"

    * ═══════════════════════════════════════════════════════════════════════
    * MODULE 1: DETECTION & SUMMARY TABLES
    * ═══════════════════════════════════════════════════════════════════════
    if "`detect'" != "" {
        _xtmispanel_detect `varlist' if `touse', ///
            panelvar(`panelvar') timevar(`timevar')
    }

    * ═══════════════════════════════════════════════════════════════════════
    * MODULE 2: MECHANISM TESTS
    * ═══════════════════════════════════════════════════════════════════════
    if "`test'" != "" {
        _xtmispanel_test `varlist' if `touse', ///
            panelvar(`panelvar') timevar(`timevar')
    }

    * ═══════════════════════════════════════════════════════════════════════
    * MODULE 3: IMPUTATION
    * ═══════════════════════════════════════════════════════════════════════
    if "`impute'" != "" {
        * Need exactly one variable for imputation
        local nv : word count `varlist'
        if `nv' != 1 {
            di as err "Specify exactly {bf:one variable} for imputation."
            exit 198
        }
        local impvar_src "`varlist'"

        * Determine output variable name
        if "`generate'" == "" {
            local generate "`impvar_src'_imp"
        }
        if "`replace'" != "" {
            capture drop `generate'
        }
        capture confirm new variable `generate'
        if _rc != 0 {
            di as err "Variable {bf:`generate'} already exists. Use {bf:replace} option."
            exit 110
        }

        * Dispatch to imputation engine
        xtmispanel_impute `impvar_src' if `touse', ///
            method(`impute') generate(`generate') ///
            panelvar(`panelvar') timevar(`timevar') ///
            knn(`knn') mice(`mice')

        * Report
        qui count if missing(`impvar_src') & `touse'
        local nmiss = r(N)
        qui count if missing(`generate') & `touse'
        local nstill = r(N)
        local nfilled = `nmiss' - `nstill'

        di
        di in smcl in gr "{hline 78}"
        di in gr "{bf:Imputation Results}"
        di in gr "{hline 78}"
        di in gr "Source variable:   " in ye "`impvar_src'"
        di in gr "Output variable:   " in ye "`generate'"
        di in gr "Method:            " in ye "`impute'"
        di in gr "{hline 40}"
        di in gr "Missing before:    " in ye %9.0fc `nmiss'
        di in gr "Values imputed:    " in ye %9.0fc `nfilled'
        di in gr "Still missing:     " in ye %9.0fc `nstill'
        if `nmiss' > 0 {
            local pctfill = `nfilled' / `nmiss' * 100
            di in gr "Fill rate:         " in ye %9.1f `pctfill' "%"
        }
        di in gr "{hline 78}"

        * ── Before vs After Comparison Table ──
        di
        di in gr "{bf:Before vs After Comparison}"
        di in gr "{hline 78}"
        di in gr "  Statistic" _col(24) "Original" _col(40) "Imputed" _col(56) "Delta" _col(68) "Delta%"
        di in gr "{hline 78}"

        qui su `impvar_src' if `touse' & !missing(`impvar_src')
        local o_mean = r(mean)
        local o_sd = r(sd)
        local o_min = r(min)
        local o_max = r(max)
        local o_n = r(N)

        qui su `generate' if `touse' & !missing(`generate')
        local i_mean = r(mean)
        local i_sd = r(sd)
        local i_min = r(min)
        local i_max = r(max)
        local i_n = r(N)

        local d_mean = `i_mean' - `o_mean'
        local d_sd = `i_sd' - `o_sd'
        local dp_mean = 0
        local dp_sd = 0
        if `o_mean' != 0 {
            local dp_mean = `d_mean' / abs(`o_mean') * 100
        }
        if `o_sd' != 0 {
            local dp_sd = `d_sd' / abs(`o_sd') * 100
        }

        di in gr "  N" _col(22) in ye %10.0fc `o_n' _col(38) in ye %10.0fc `i_n' _col(54) in ye %10.0fc (`i_n' - `o_n')
        di in gr "  Mean" _col(22) in ye %10.3f `o_mean' _col(38) in ye %10.3f `i_mean' _col(54) in ye %10.3f `d_mean' _col(66) in ye %8.2f `dp_mean' "%"
        di in gr "  SD" _col(22) in ye %10.3f `o_sd' _col(38) in ye %10.3f `i_sd' _col(54) in ye %10.3f `d_sd' _col(66) in ye %8.2f `dp_sd' "%"
        di in gr "  Min" _col(22) in ye %10.3f `o_min' _col(38) in ye %10.3f `i_min'
        di in gr "  Max" _col(22) in ye %10.3f `o_max' _col(38) in ye %10.3f `i_max'

        * Correlation between original and imputed (on non-missing pairs)
        qui corr `impvar_src' `generate' if `touse' & !missing(`impvar_src')
        local corr_val = r(rho)
        di in gr "{hline 78}"
        di in gr "  Correlation (obs. pairs):" in ye %8.4f `corr_val'
        di in gr "{hline 78}"

        * ── Auto-generate density graph ──
        di
        di in gr "{bf:Generating density comparison graph...}"
        capture {
            twoway (kdensity `impvar_src' if `touse' & !missing(`impvar_src'), ///
                    lcolor("41 128 185") lwidth(medthick) lpattern(solid)) ///
                   (kdensity `generate' if `touse' & !missing(`generate'), ///
                    lcolor("220 50 47") lwidth(medthick) lpattern(dash)), ///
                title("{bf:Distribution: Original vs Imputed (`impute')}", ///
                    size(medium) color(black)) ///
                subtitle("`impvar_src': observed (blue) vs `generate' (red)", ///
                    size(small) color(gs6)) ///
                ytitle("Density", size(small)) ///
                xtitle("Value", size(small)) ///
                ylabel(, labsize(vsmall) angle(0) nogrid) ///
                xlabel(, labsize(vsmall)) ///
                legend(order(1 "Original (observed)" 2 "Imputed (complete)") ///
                    rows(1) size(vsmall) position(6) ring(1)) ///
                graphregion(color(white) margin(small)) ///
                plotregion(color(white) margin(small)) ///
                name(xtmis_impute_density, replace)
            di in gr "  Graph stored: {bf:xtmis_impute_density}"
            di in gr "  To view:  {cmd:graph display xtmis_impute_density}"
            di in gr "  To export: {cmd:graph export density.png, name(xtmis_impute_density) replace}"
        }
        if _rc != 0 {
            di in ye "  (density graph could not be generated)"
        }
        di in gr "{hline 78}"

        return scalar n_missing  = `nmiss'
        return scalar n_imputed  = `nfilled'
        return scalar n_remain   = `nstill'
        return scalar orig_mean  = `o_mean'
        return scalar orig_sd    = `o_sd'
        return scalar imp_mean   = `i_mean'
        return scalar imp_sd     = `i_sd'
        return scalar correlation = `corr_val'
        return local  method     "`impute'"
        return local  imputed_var "`generate'"
    }

    * ═══════════════════════════════════════════════════════════════════════
    * MODULE 4: SENSITIVITY ANALYSIS
    * ═══════════════════════════════════════════════════════════════════════
    if "`sensitivity'" != "" {
        local nv : word count `varlist'
        if `nv' != 1 {
            di as err "Specify exactly {bf:one variable} for sensitivity analysis."
            exit 198
        }
        _xtmispanel_sensitivity `varlist' if `touse', ///
            panelvar(`panelvar') timevar(`timevar') ///
            methods(`methods') knn(`knn') mice(`mice')
    }

    * ═══════════════════════════════════════════════════════════════════════
    * MODULE 5: VISUALIZATIONS
    * ═══════════════════════════════════════════════════════════════════════
    if "`graph'" != "" {
        xtmispanel_graph `varlist' if `touse', ///
            panelvar(`panelvar') timevar(`timevar') ///
            impvar(`impvar')
    }

    di
    di in gr "{bf:xtmispanel} completed successfully."
    di
end

* ╔═══════════════════════════════════════════════════════════════════════════╗
* ║  SUBPROGRAM: _xtmispanel_detect                                         ║
* ║  Missing data detection and beautiful summary tables                     ║
* ╚═══════════════════════════════════════════════════════════════════════════╝
capture program drop _xtmispanel_detect
program define _xtmispanel_detect, rclass
    syntax varlist [if], panelvar(varname) timevar(varname)
    marksample touse, novarlist

    * ─── TABLE 1: Per-Variable Summary ────────────────────────────────────
    di
    di in smcl in ye "{bf:╔══════════════════════════════════════════════════════════════════════════╗}"
    di in ye        "{bf:║}" in gr "  TABLE 1: Missing Data Summary by Variable" ///
        _col(75) in ye "{bf:║}"
    di in ye        "{bf:╚══════════════════════════════════════════════════════════════════════════╝}"
    di
    di in smcl in gr "  {hline 74}"
    di in gr "  Variable" _col(22) "N_Total" _col(33) "N_Miss" ///
        _col(43) "%Miss" _col(53) "Mean" _col(63) "SD" _col(72) "Status"
    di in gr "  {hline 74}"

    local total_miss = 0
    local total_obs = 0
    local nvars : word count `varlist'

    foreach v of local varlist {
        qui count if `touse'
        local ntot = r(N)
        qui count if missing(`v') & `touse'
        local nmiss = r(N)
        local pct = 0
        if `ntot' > 0 {
            local pct = `nmiss' / `ntot' * 100
        }
        qui su `v' if `touse' & !missing(`v')
        local vmean = r(mean)
        local vsd = r(sd)
        if `vsd' == . local vsd = 0

        * Status indicator
        local status "✓ Complete"
        local statcol "in gr"
        if `pct' > 0 & `pct' <= 5 {
            local status "● Low"
            local statcol "in ye"
        }
        else if `pct' > 5 & `pct' <= 20 {
            local status "▲ Moderate"
            local statcol "in ye"
        }
        else if `pct' > 20 & `pct' <= 50 {
            local status "■ High"
            local statcol "in re"
        }
        else if `pct' > 50 {
            local status "✗ Severe"
            local statcol "in re"
        }

        * Truncate variable name if too long
        local vname = abbrev("`v'", 16)
        di in gr "  `vname'" _col(22) in ye %7.0fc `ntot' ///
            _col(33) in ye %6.0fc `nmiss' ///
            _col(42) in ye %6.1f `pct' "%" ///
            _col(51) in ye %8.2f `vmean' ///
            _col(62) in ye %7.2f `vsd' ///
            _col(72) `statcol' "`status'"

        local total_miss = `total_miss' + `nmiss'
        local total_obs  = `total_obs'  + `ntot'
    }

    di in gr "  {hline 74}"
    local overall_pct = 0
    if `total_obs' > 0 {
        local overall_pct = `total_miss' / `total_obs' * 100
    }
    di in gr "  {bf:Overall}" _col(22) in ye %7.0fc `total_obs' ///
        _col(33) in ye %6.0fc `total_miss' ///
        _col(42) in ye %6.1f `overall_pct' "%"
    di in gr "  {hline 74}"

    * ─── TABLE 2: Per-Panel Summary ───────────────────────────────────────
    di
    di in smcl in ye "{bf:╔══════════════════════════════════════════════════════════════════════════╗}"
    di in ye        "{bf:║}" in gr "  TABLE 2: Missing Data Summary by Panel" ///
        _col(75) in ye "{bf:║}"
    di in ye        "{bf:╚══════════════════════════════════════════════════════════════════════════╝}"
    di
    di in smcl in gr "  {hline 74}"
    di in gr "  Panel" _col(18) "N_Obs" _col(28) "N_Miss" ///
        _col(38) "%Miss" _col(48) "Gaps" _col(56) "Max_Gap" _col(68) "Status"
    di in gr "  {hline 74}"

    qui levelsof `panelvar' if `touse', local(panels)
    foreach p of local panels {
        local pmiss = 0
        local pobs  = 0
        foreach v of local varlist {
            qui count if `panelvar' == `p' & `touse'
            local pobs_v = r(N)
            qui count if `panelvar' == `p' & `touse' & missing(`v')
            local pmiss = `pmiss' + r(N)
            local pobs  = `pobs'  + `pobs_v'
        }
        local ppct = 0
        if `pobs' > 0 {
            local ppct = `pmiss' / `pobs' * 100
        }

        * Count gaps (consecutive missing blocks) for first variable
        local firstvar : word 1 of `varlist'
        local ngaps = 0
        local maxgap = 0
        tempvar _inmiss _gapid _gaplen
        qui gen byte `_inmiss' = missing(`firstvar') & `panelvar' == `p' & `touse'
        qui gen long `_gapid' = .
        qui gen long `_gaplen' = .
        capture {
            qui bysort `panelvar' (`timevar'): ///
                replace `_gapid' = sum(`_inmiss' != `_inmiss'[_n-1] & `_inmiss' == 1) ///
                if `panelvar' == `p' & `touse'
            qui replace `_gapid' = . if `_inmiss' == 0
            qui bysort `panelvar' `_gapid' (`timevar'): ///
                replace `_gaplen' = _N if `_gapid' != . & `panelvar' == `p'
            qui su `_gapid' if `panelvar' == `p' & `_gapid' != ., meanonly
            if r(N) > 0 {
                local ngaps = r(max)
            }
            qui su `_gaplen' if `panelvar' == `p' & `_gapid' != ., meanonly
            if r(N) > 0 {
                local maxgap = r(max)
            }
        }
        drop `_inmiss' `_gapid' `_gaplen'

        * Status
        local pstatus "Complete"
        if `ppct' > 0 & `ppct' <= 10  local pstatus "Low"
        if `ppct' > 10 & `ppct' <= 30 local pstatus "Moderate"
        if `ppct' > 30                local pstatus "High"

        local plabel = abbrev("`p'", 14)
        di in gr "  `plabel'" _col(18) in ye %6.0fc `pobs' ///
            _col(28) in ye %6.0fc `pmiss' ///
            _col(37) in ye %6.1f `ppct' "%" ///
            _col(48) in ye %4.0f `ngaps' ///
            _col(56) in ye %5.0f `maxgap' ///
            _col(68) in ye "`pstatus'"
    }
    di in gr "  {hline 74}"

    * ─── TABLE 3: Per-Time-Period Summary ─────────────────────────────────
    di
    di in smcl in ye "{bf:╔══════════════════════════════════════════════════════════════════════════╗}"
    di in ye        "{bf:║}" in gr "  TABLE 3: Missing Data Summary by Time Period" ///
        _col(75) in ye "{bf:║}"
    di in ye        "{bf:╚══════════════════════════════════════════════════════════════════════════╝}"
    di
    di in smcl in gr "  {hline 50}"
    di in gr "  Period" _col(18) "N_Miss" _col(30) "%Missing" _col(43) "Bar"
    di in gr "  {hline 50}"

    qui levelsof `timevar' if `touse', local(times)
    foreach t of local times {
        local tmiss = 0
        local tobs  = 0
        foreach v of local varlist {
            qui count if `timevar' == `t' & `touse'
            local tobs_v = r(N)
            qui count if `timevar' == `t' & `touse' & missing(`v')
            local tmiss = `tmiss' + r(N)
            local tobs  = `tobs'  + `tobs_v'
        }
        local tpct = 0
        if `tobs' > 0 {
            local tpct = `tmiss' / `tobs' * 100
        }

        * ASCII bar
        local barlen = round(`tpct' / 3)
        if `barlen' > 25 local barlen = 25
        local bar ""
        forv i = 1/`barlen' {
            local bar "`bar'█"
        }
        if `barlen' == 0 & `tpct' > 0 {
            local bar "▏"
        }

        di in gr "  `t'" _col(18) in ye %6.0fc `tmiss' ///
            _col(29) in ye %6.1f `tpct' "%" ///
            _col(43) in re "`bar'"
    }
    di in gr "  {hline 50}"

    * --- TABLE 4: Missing Data Pattern Matrix ---
    di
    di in smcl in gr "  {hline 74}"
    di in gr "  {bf:TABLE 4: Missing Data Pattern (Variable Co-occurrence)}"
    di in gr "  {hline 74}"
    di

    local nvars : word count `varlist'
    tempvar _patt
    qui gen str1 `_patt' = ""
    foreach v of local varlist {
        qui replace `_patt' = `_patt' + cond(missing(`v'), "0", "1") if `touse'
    }

    if `nvars' <= 10 {
        local hdr "  Pattern"
        local cnt = 0
        foreach v of local varlist {
            local cnt = `cnt' + 1
            local vab = abbrev("`v'", 6)
            local hdr "`hdr'  `vab'"
        }
        local hdr "`hdr'    N"
        di in gr "`hdr'"
        di in gr "  {hline 74}"

        qui levelsof `_patt' if `touse', local(patterns)
        local pnum = 0
        foreach pat of local patterns {
            local pnum = `pnum' + 1
            qui count if `_patt' == "`pat'" & `touse'
            local pn = r(N)
            local pline "  #`pnum'     "
            local slen = strlen("`pat'")
            forv c = 1/`slen' {
                local ch = substr("`pat'", `c', 1)
                if "`ch'" == "1" {
                    local pline "`pline'    ."
                }
                else {
                    local pline "`pline'    X"
                }
            }
            di in gr "`pline'" _col(60) in ye %8.0fc `pn'
        }
        di in gr "  {hline 74}"
        di in gr "  {it:Legend: . = observed  X = missing}"
    }
    else {
        di in gr "  (Pattern table skipped: too many variables)"
    }

    di in gr ""

    * Compute return values locally (locals from main program are NOT accessible)
    qui tab `panelvar' if `touse'
    local _npanels = r(r)
    return scalar total_missing = `total_miss'
    return scalar total_obs = `total_obs'
    return scalar overall_pct = `overall_pct'
    return scalar n_panels = `_npanels'
    return scalar n_vars = `nvars'
end

* ╔═══════════════════════════════════════════════════════════════════════════╗
* ║  SUBPROGRAM: _xtmispanel_test                                           ║
* ║  Tests for missing data mechanisms (MCAR, MAR)                           ║
* ╚═══════════════════════════════════════════════════════════════════════════╝
capture program drop _xtmispanel_test
program define _xtmispanel_test, rclass
    syntax varlist [if], panelvar(varname) timevar(varname)
    marksample touse, novarlist

    di
    di in smcl in ye "{bf:╔══════════════════════════════════════════════════════════════════════════╗}"
    di in ye        "{bf:║}" in gr "  MODULE 2: Missing Data Mechanism Tests" ///
        _col(75) in ye "{bf:║}"
    di in ye        "{bf:╚══════════════════════════════════════════════════════════════════════════╝}"

    local nvars : word count `varlist'

    * ─── TEST 1: Little's MCAR Test (simplified) ──────────────────────────
    * We approximate Little's test using a chi-square comparison of means
    * between groups defined by missingness patterns
    di
    di in gr "  {bf:Test 1: Little's MCAR Test (Approximate)}"
    di in gr "  {hline 60}"
    di in gr "  H0: Data are Missing Completely At Random (MCAR)"
    di in gr "  H1: Data are NOT MCAR"
    di

    * Create missingness pattern variable
    tempvar _patt
    qui gen str1 `_patt' = ""
    foreach v of local varlist {
        qui replace `_patt' = `_patt' + cond(missing(`v'), "0", "1") if `touse'
    }

    * Compute test statistic
    * For each variable with missingness, compare means across patterns
    tempname chi2_total df_total
    scalar `chi2_total' = 0
    scalar `df_total' = 0

    foreach v of local varlist {
        qui count if missing(`v') & `touse'
        if r(N) == 0 continue

        * Get overall mean
        qui su `v' if `touse' & !missing(`v')
        local gmean = r(mean)
        local gvar  = r(Var)
        local gn    = r(N)

        if `gvar' == . | `gvar' == 0 continue

        * Compare means across missingness groups of OTHER variables
        foreach w of local varlist {
            if "`w'" == "`v'" continue
            qui count if missing(`w') & `touse'
            if r(N) == 0 | r(N) == `gn' continue

            * Mean of v where w is missing
            qui su `v' if missing(`w') & `touse' & !missing(`v'), meanonly
            if r(N) < 2 continue
            local m1 = r(mean)
            local n1 = r(N)

            * Mean of v where w is observed
            qui su `v' if !missing(`w') & `touse' & !missing(`v'), meanonly
            if r(N) < 2 continue
            local m2 = r(mean)
            local n2 = r(N)

            * Contribution to chi-square
            local se = sqrt(`gvar' * (1/`n1' + 1/`n2'))
            if `se' > 0 {
                local z = (`m1' - `m2') / `se'
                scalar `chi2_total' = `chi2_total' + `z'^2
                scalar `df_total' = `df_total' + 1
            }
        }
    }

    if `df_total' > 0 {
        local chi2val = `chi2_total'
        local dfval   = `df_total'
        local pval    = chi2tail(`dfval', `chi2val')

        di in gr "  Chi-square statistic:  " in ye %10.3f `chi2val'
        di in gr "  Degrees of freedom:    " in ye %10.0f `dfval'
        di in gr "  p-value:               " in ye %10.4f `pval'
        di

        if `pval' < 0.05 {
            di in re "  ► Reject H0: Data are {bf:NOT MCAR} (p < 0.05)"
            di in gr "    → Missingness depends on observed or unobserved data."
            di in gr "    → Simple deletion may produce biased results."
            local mcar_result "REJECT"
        }
        else {
            di in gr "  ► Fail to reject H0: Data {bf:may be MCAR} (p ≥ 0.05)"
            di in gr "    → Complete case analysis may be acceptable."
            local mcar_result "FAIL_TO_REJECT"
        }

        return scalar mcar_chi2 = `chi2val'
        return scalar mcar_df   = `dfval'
        return scalar mcar_pval = `pval'
        return local  mcar_result "`mcar_result'"
    }
    else {
        di in ye "  Test could not be computed (insufficient variation)."
    }

    * ─── TEST 2: MAR Logistic Regression Test ─────────────────────────────
    di
    di in gr "  {bf:Test 2: MAR Logistic Regression Test}"
    di in gr "  {hline 60}"
    di in gr "  For each variable, regress its missingness indicator"
    di in gr "  on all other observed variables."
    di

    di in gr "  {hline 66}"
    di in gr "  Variable" _col(18) "chi2" _col(30) "p-value" ///
        _col(42) "Pseudo-R²" _col(56) "Conclusion"
    di in gr "  {hline 66}"

    local any_mar = 0
    foreach v of local varlist {
        qui count if missing(`v') & `touse'
        local nmv = r(N)
        if `nmv' == 0 {
            local vab = abbrev("`v'", 14)
            di in gr "  `vab'" _col(18) in gr "  ---" ///
                _col(30) "  ---" _col(42) "  ---" _col(56) "No missing"
            continue
        }
        qui count if !missing(`v') & `touse'
        if r(N) < 5 continue

        * Create missingness indicator
        tempvar _mind
        qui gen byte `_mind' = missing(`v') if `touse'

        * Build predictor list (other variables, non-missing obs)
        local preds ""
        foreach w of local varlist {
            if "`w'" == "`v'" continue
            local preds "`preds' `w'"
        }

        * Run logistic regression
        if "`preds'" != "" {
            capture {
                qui logit `_mind' `preds' if `touse', nolog
                local lchi2   = e(chi2)
                local lpval   = chi2tail(e(df_m), e(chi2))
                local lpseudo = e(r2_p)
            }
            if _rc == 0 {
                local vab = abbrev("`v'", 14)
                local lconc "MCAR"
                if `lpval' < 0.05 {
                    local lconc "MAR"
                    local any_mar = 1
                }
                di in gr "  `vab'" ///
                    _col(16) in ye %8.2f `lchi2' ///
                    _col(28) in ye %8.4f `lpval' ///
                    _col(41) in ye %8.4f `lpseudo' ///
                    _col(56) in ye "`lconc'"
            }
            else {
                local vab = abbrev("`v'", 14)
                di in gr "  `vab'" _col(18) in re "Failed" ///
                    _col(30) "---" _col(42) "---" _col(56) "---"
            }
        }
        drop `_mind'
    }
    di in gr "  {hline 66}"

    * ─── TEST 3: Pattern Analysis ─────────────────────────────────────────
    di
    di in gr "  {bf:Test 3: Missingness Pattern Classification}"
    di in gr "  {hline 60}"

    * Check if pattern is monotone
    local is_monotone = 1
    qui levelsof `panelvar' if `touse', local(panels)
    foreach p of local panels {
        foreach v of local varlist {
            * For monotone: once a value is missing, all subsequent should be missing
            tempvar _chk
            qui gen byte `_chk' = 0
            qui bysort `panelvar' (`timevar'): ///
                replace `_chk' = 1 if `panelvar' == `p' & `touse' ///
                & !missing(`v') & missing(`v'[_n-1]) & _n > 1
            qui count if `_chk' == 1
            if r(N) > 0 {
                local is_monotone = 0
            }
            drop `_chk'
            if `is_monotone' == 0 {
                continue, break
            }
        }
        if `is_monotone' == 0 {
            continue, break
        }
    }

    if `is_monotone' {
        di in gr "  Pattern type:  " in ye "{bf:Monotone}"
        di in gr "  → Once missing, the variable stays missing."
        di in gr "  → Sequential imputation methods are optimal."
    }
    else {
        di in gr "  Pattern type:  " in ye "{bf:Arbitrary (Non-monotone)}"
        di in gr "  → Missing values appear in irregular positions."
        di in gr "  → MICE / chained equations recommended."
    }

    * ─── OVERALL RECOMMENDATION ───────────────────────────────────────────
    di
    di in smcl in ye "{bf:╔══════════════════════════════════════════════════════════════════════════╗}"
    di in ye        "{bf:║}" in gr "  OVERALL RECOMMENDATION" ///
        _col(75) in ye "{bf:║}"
    di in ye        "{bf:╚══════════════════════════════════════════════════════════════════════════╝}"
    di

    if "`mcar_result'" == "FAIL_TO_REJECT" & `any_mar' == 0 {
        di in gr "  ► Mechanism: {bf:Likely MCAR}"
        di in gr "  ► Complete case analysis is acceptable."
        di in gr "  ► For efficiency, consider: {it:mean, linear, locf}"
        return local mechanism "MCAR"
    }
    else if `any_mar' == 1 {
        di in gr "  ► Mechanism: {bf:Likely MAR}"
        di in gr "  ► Simple deletion will produce BIASED results."
        di in gr "  ► Recommended: {it:mice, pmm, regress, knn}"
        return local mechanism "MAR"
    }
    else {
        di in gr "  ► Mechanism: {bf:Possibly MNAR}"
        di in gr "  ► Advanced methods needed. Consider:"
        di in gr "    - Selection models (Heckman)"
        di in gr "    - Sensitivity analysis across multiple methods"
        di in gr "  ► Use: {cmd:xtmispanel varname, sensitivity}"
        return local mechanism "MNAR"
    }
    di

    drop `_patt'
end

* ╔═══════════════════════════════════════════════════════════════════════════╗
* ║  SUBPROGRAM: _xtmispanel_sensitivity                                     ║
* ║  Sensitivity analysis: compare all imputation methods                     ║
* ╚═══════════════════════════════════════════════════════════════════════════╝
capture program drop _xtmispanel_sensitivity
program define _xtmispanel_sensitivity, rclass
    syntax varlist(max=1) [if], panelvar(varname) timevar(varname) ///
        [methods(string) knn(integer 5) mice(integer 5)]
    marksample touse, novarlist

    local srcvar "`varlist'"

    * Default method list
    if "`methods'" == "" {
        local methods "mean median locf nocb linear spline regress pmm hotdeck knn rf em mice"
    }

    di
    di in smcl in ye "{bf:╔══════════════════════════════════════════════════════════════════════════╗}"
    di in ye        "{bf:║}" in gr "  SENSITIVITY ANALYSIS: Comparing Imputation Methods" ///
        _col(75) in ye "{bf:║}"
    di in ye        "{bf:╚══════════════════════════════════════════════════════════════════════════╝}"
    di
    di in gr "  Target variable: " in ye "`srcvar'"
    qui count if missing(`srcvar') & `touse'
    local nmiss = r(N)
    di in gr "  Missing values:  " in ye "`nmiss'"
    di

    * Get original variable stats (non-missing)
    qui su `srcvar' if `touse' & !missing(`srcvar')
    local orig_mean = r(mean)
    local orig_sd   = r(sd)
    local orig_min  = r(min)
    local orig_max  = r(max)
    local orig_n    = r(N)

    di in gr "  {hline 74}"
    di in gr "  {bf:Original (observed)}: Mean=" in ye %8.3f `orig_mean' ///
        in gr "  SD=" in ye %8.3f `orig_sd' ///
        in gr "  N=" in ye %6.0f `orig_n'
    di in gr "  {hline 74}"
    di
    di in gr "  {hline 74}"
    di in gr "  Method" _col(18) "Mean" _col(28) "SD" _col(38) "Min" ///
        _col(48) "Max" _col(56) "Filled" _col(64) "Δ Mean%"
    di in gr "  {hline 74}"

    * Storage for comparison
    tempname sens_mat
    local nmethods : word count `methods'
    matrix `sens_mat' = J(`nmethods', 5, .)
    local mnames ""

    local mi = 0
    foreach m of local methods {
        local mi = `mi' + 1
        local mnames "`mnames' `m'"

        * Create temporary imputed variable
        tempvar _imp_`mi'
        capture {
            qui xtmispanel_impute `srcvar' if `touse', ///
                method(`m') generate(`_imp_`mi'') ///
                panelvar(`panelvar') timevar(`timevar') ///
                knn(`knn') mice(`mice')
        }
        if _rc != 0 {
            di in gr "  `m'" _col(18) in re "FAILED"
            matrix `sens_mat'[`mi', 1] = .
            continue
        }

        * Compute stats on full imputed series
        qui su `_imp_`mi'' if `touse'
        local imean = r(mean)
        local isd   = r(sd)
        local imin  = r(min)
        local imax  = r(max)

        qui count if !missing(`_imp_`mi'') & `touse'
        local nfill = r(N)

        * Percentage change in mean
        local dmean = 0
        if `orig_mean' != 0 {
            local dmean = (`imean' - `orig_mean') / abs(`orig_mean') * 100
        }

        matrix `sens_mat'[`mi', 1] = `imean'
        matrix `sens_mat'[`mi', 2] = `isd'
        matrix `sens_mat'[`mi', 3] = `imin'
        matrix `sens_mat'[`mi', 4] = `imax'
        matrix `sens_mat'[`mi', 5] = `dmean'

        * Color: green if mean change < 1%, yellow < 5%, red >= 5%
        local mcol "in gr"
        if abs(`dmean') < 1     local mcol "in gr"
        else if abs(`dmean') < 5 local mcol "in ye"
        else                     local mcol "in re"

        local mlab = abbrev("`m'", 12)
        di `mcol' "  `mlab'" _col(16) in ye %8.3f `imean' ///
            _col(26) in ye %8.3f `isd' ///
            _col(36) in ye %8.2f `imin' ///
            _col(46) in ye %8.2f `imax' ///
            _col(56) in ye %5.0f `nfill' ///
            _col(63) `mcol' %7.2f `dmean' "%"

        drop `_imp_`mi''
    }

    di in gr "  {hline 74}"

    * Find best method (smallest absolute mean change)
    local best_idx = 1
    local best_dmean = 999999
    forv i = 1/`nmethods' {
        if `sens_mat'[`i', 5] != . {
            local adm = abs(`sens_mat'[`i', 5])
            if `adm' < `best_dmean' {
                local best_dmean = `adm'
                local best_idx = `i'
            }
        }
    }
    local best_method : word `best_idx' of `methods'

    di
    di in gr "  {bf:Recommendation}"
    di in gr "  ► Best method (lowest distribution distortion): " ///
        in ye "{bf:`best_method'}"
    di in gr "  ► Mean change from original: " in ye %6.2f `best_dmean' "%"
    di
    di in gr "  Note: Consider also the mechanism test results when choosing."
    di in gr "  For MAR data, prefer: {it:mice, pmm, regress, knn}"
    di in gr "  For MCAR data, any method is acceptable."
    di

    * Correlation between methods
    di in gr "  {bf:Cross-Method Correlation Matrix (Pearson)}"
    di in gr "  {hline 74}"
    di in gr "  (Use {cmd:xtmispanel `srcvar', sensitivity graph} for visual)"
    di

    return local best_method "`best_method'"
    return scalar best_dmean_pct = `best_dmean'
    return matrix sensitivity = `sens_mat'
end
