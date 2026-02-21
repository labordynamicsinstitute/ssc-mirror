*! garchur - GARCH-based Unit Root Test with Trend and Structural Breaks
*! Version 1.0.1, February 2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Reference:
*!   Narayan, P.K., Liu, R. (2015).
*!   A Unit Root Model for Trending Time-Series Energy Variables.
*!   Energy Economics. DOI: 10.1016/j.eneco.2014.11.021
*!
*! Description:
*!   Implements the trend-GARCH(1,1) unit root test with two endogenous
*!   structural breaks proposed by Narayan and Liu (2015).
*!   The model: y_t = a0 + a1*t + rho*y_{t-1} + sum(gamma_j*DU_jt) + eps_t
*!   where eps_t ~ GARCH(1,1): h_t = kappa + alpha*eps_{t-1}^2 + beta*h_{t-1}
*!   H0: rho = 1 (unit root)  vs  H1: rho < 1 (stationary)

program define garchur, rclass sortpreserve
    version 14.0

    syntax varname(ts) [if] [in],   ///
        [                           ///
        BREAKs(integer 2)           /// Number of structural breaks (2 or 3)
        Model(string)               /// Model: "ct" (const+trend, default) or "c"
        TRIM(real 0.15)             /// Trimming proportion for break search
        NOPRint                     /// Suppress text output
        GRaph                       /// Display graphs
        SAVEgraph(string)           /// Save graph to file (e.g., "mygraph.png")
        ]

    *--------------------------------------------------------------------------
    * Load Mata library
    *--------------------------------------------------------------------------
    capture findfile _garchur_mata.ado
    if _rc {
        di as error "Required file _garchur_mata.ado not found."
        di as error "Ensure the garchur package is properly installed."
        exit 601
    }
    qui run `"`r(fn)'"'

    *--------------------------------------------------------------------------
    * Input validation
    *--------------------------------------------------------------------------
    marksample touse
    _ts timevar panelvar if `touse', sort onepanel
    markout `touse' `timevar'

    * Validate model
    if "`model'" == "" {
        local model "ct"
    }
    else {
        local model = lower("`model'")
        if !inlist("`model'", "c", "ct") {
            di as error "model() must be {bf:c} (constant) or {bf:ct} (constant + trend)"
            exit 198
        }
    }

    * Validate breaks
    if `breaks' < 1 | `breaks' > 3 {
        di as error "breaks() must be 1, 2, or 3"
        exit 198
    }

    * Validate trim
    if `trim' < 0.05 | `trim' > 0.30 {
        di as error "trim() must be between 0.05 and 0.30 (default: 0.15)"
        exit 198
    }

    * Check sample size
    qui count if `touse'
    local N = r(N)
    if `N' < 30 {
        di as error "Insufficient observations (need at least 30, have `N')"
        exit 2001
    }

    *--------------------------------------------------------------------------
    * Run GARCH estimation via Mata
    *--------------------------------------------------------------------------
    tempvar y_temp
    qui gen double `y_temp' = `varlist' if `touse'

    * Clean up graph variables if they exist
    capture drop _garchur_ht _garchur_sr

    mata: garchur_compute("`y_temp'", "`touse'", "`model'", `breaks', `trim')

    *--------------------------------------------------------------------------
    * Retrieve results
    *--------------------------------------------------------------------------
    local stat     = r(stat)
    local rho      = r(rho)
    local alpha    = r(alpha)
    local beta_g   = r(beta)
    local kappa    = r(kappa)
    local halflife = r(halflife)
    local loglik   = r(loglik)
    local nobs     = r(nobs)
    local cv1      = r(cv1)
    local cv5      = r(cv5)
    local cv10     = r(cv10)
    local ab       = r(ab)

    * Retrieve TB indices NOW before levelsof clears r()
    * levelsof is rclass — it wipes ALL r() scalars when it runs
    forvalues j = 1/`breaks' {
        local tb`j'_idx = round(r(TB`j'))
    }

    * Get ordered time values (runs AFTER r(TB*) safely saved above)
    qui levelsof `timevar' if `touse', local(tvlist)
    local tfmt : format `timevar'    // e.g. %td, %tq, %ty ...

    * Convert saved TB indices to actual time values
    forvalues j = 1/`breaks' {
        local tb`j'_val = .
        local k = 0
        foreach tv of local tvlist {
            local k = `k' + 1
            if `k' == `tb`j'_idx' {
                local tb`j'_val `tv'
                continue, break
            }
        }
    }

    *--------------------------------------------------------------------------
    * Significance stars and decision
    *--------------------------------------------------------------------------
    local stars ""
    local sig_level "---"
    local decision "Cannot reject H_0: Evidence of unit root"
    local reject   0

    if `stat' < `cv1' {
        local stars "***"
        local sig_level "1%"
        local decision "Reject H_0 at 1%: Strong evidence of stationarity"
        local reject 1
    }
    else if `stat' < `cv5' {
        local stars "**"
        local sig_level "5%"
        local decision "Reject H_0 at 5%: Evidence of stationarity"
        local reject 1
    }
    else if `stat' < `cv10' {
        local stars "*"
        local sig_level "10%"
        local decision "Reject H_0 at 10%: Weak evidence of stationarity"
        local reject 1
    }

    * Half-life display
    if `halflife' == . {
        local hl_disp "N/A (a+b >= 1)"
    }
    else {
        local hl_disp : di %9.2f `halflife'
    }

    * Model label
    if "`model'" == "ct" {
        local model_label "Constant + Linear Trend"
        local spec "y_t = a_0 + a_1*t + rho*y_(t-1) + Sum[g_j*DU_jt] + e_t"
    }
    else {
        local model_label "Constant only"
        local spec "y_t = a_0 + rho*y_(t-1) + Sum[g_j*DU_jt] + e_t"
    }

    *--------------------------------------------------------------------------
    * Format time values for display
    *--------------------------------------------------------------------------
    forvalues j = 1/`breaks' {
        if `tb`j'_val' != . {
            local tb`j'_fmt : di `tfmt' `tb`j'_val'
        }
        else {
            local tb`j'_fmt "(not found)"
        }
    }

    *--------------------------------------------------------------------------
    * Display results table (paper-compatible format)
    *--------------------------------------------------------------------------
    if "`noprint'" == "" {

        di
        di as txt "{hline 78}"
        di as txt "{col 3}{bf:Trend-GARCH Unit Root Test with Structural Breaks}"
        di as txt "{col 3}{it:Narayan, P.K. & Liu, R. (2015). Energy Economics.}"
        di as txt "{col 3}DOI: 10.1016/j.eneco.2014.11.021"
        di as txt "{hline 78}"
        di
        di as txt "{col 3}Variable:{col 25}" as res "`varlist'" ///
           as txt "{col 45}N (mean eq.):{col 64}=" as res %8.0f `nobs'
        di as txt "{col 3}Model:{col 25}" as res "`model_label'" ///
           as txt "{col 55}No. of breaks:{col 71}" as res %4.0f `breaks'
        di as txt "{col 3}Trimming:{col 25}" as res %7.2f `trim'
        di
        di as txt "{hline 78}"
        di as txt "{col 20}{bf:I. Structural Break Dates}"
        di as txt "{hline 78}"
        di
        di as txt "{col 3}{it:Note: Break dates estimated by sequential max |t| of DU dummy}"
        di as txt "{col 3}(Narayan & Liu, 2015, eq. 3-4; Narayan & Popp, 2010)"
        di
        forvalues j = 1/`breaks' {
            di as txt "{col 3}TB_`j':{col 25}" ///
               as res "`tb`j'_fmt'" ///
               as txt "  (obs. index = " as res `tb`j'_idx' as txt ")"
        }
        di
        di as txt "{hline 78}"
        di as txt "{col 20}{bf:II. GARCH(1,1) Variance Equation}"
        di as txt "{hline 78}"
        di
        di as txt "{col 3}Coefficient{col 30}Estimate"
        di as txt "{col 3}{hline 45}"
        di as txt "{col 3}Kappa (k){col 30}" as res %12.6f `kappa'
        di as txt "{col 3}Alpha (a){col 30}" as res %12.6f `alpha'
        di as txt "{col 3}Beta  (b){col 30}" as res %12.6f `beta_g'
        di as txt "{col 3}{hline 45}"
        di as txt "{col 3}a + b (persistence){col 30}" as res %12.6f `ab'
        di as txt "{col 3}Half-life [ln(0.5)/ln(a+b)]{col 30}" as res "`hl_disp'"
        di as txt "{col 3}Log-likelihood{col 30}" as res %12.4f `loglik'
        di
        di as txt "{hline 78}"
        di as txt "{col 20}{bf:III. Unit Root Test Results}"
        di as txt "{hline 78}"
        di as txt "{col 3}{it:H_0: rho = 1 (unit root)   H_1: rho < 1 (stationary)}"
        di
        di as txt "{col 3}Coefficient{col 25}Estimate{col 42}Test Statistic"
        di as txt "{col 3}{hline 60}"
        di as txt "{col 3}rho (AR coeff.){col 25}" as res %10.6f `rho' ///
           as txt "{col 40}" as res %12.4f `stat' " `stars'"
        di as txt "{col 3}{hline 60}"
        di
        di as txt "{col 3}Critical Values (Narayan & Liu, 2015, Table III):"
        di
        di as txt "{col 10}" _col(20) "1%" _col(34) "5%" _col(48) "10%"
        di as txt "{col 10}" ///
           _col(16) as res %10.4f `cv1' ///
           _col(30) as res %10.4f `cv5' ///
           _col(44) as res %10.4f `cv10'
        di
        di as txt "{col 3}{it:(Critical values based on T=`nobs', alpha+beta=}" ///
           as res %5.3f `ab' as txt "{it:, Table III interpolation)}"
        di
        di as txt "{hline 78}"
        di as txt "{col 3}{bf:Decision:}"
        if `reject' {
            di as res "{col 3}`decision'"
        }
        else {
            di as txt "{col 3}`decision'"
        }
        di as txt "{hline 78}"
        di as txt "{col 3}Note: *** p<0.01, ** p<0.05, * p<0.10"
        di as txt "{col 3}CVs interpolated from Table III (50,000 Monte Carlo reps)"
        di as txt "{hline 78}"
        di
    }

    *--------------------------------------------------------------------------
    * Graph
    *--------------------------------------------------------------------------
    if "`graph'" != "" | "`savegraph'" != "" {
        * Check if graph module exists
        capture findfile garchur_graph.ado
        if _rc {
            di as error "garchur_graph.ado not found — cannot produce graph"
        }
        else {
            local tbopts ""
            forvalues j = 1/`breaks' {
                local tbopts `"`tbopts' tb`j'(`tb`j'_val')"'
            }
            if "`savegraph'" != "" {
                local sgopt `"savegraph("`savegraph'")"'
            }
            qui garchur_graph `varlist' if `touse', ///
                model("`model'")    ///
                breaks(`breaks')    ///
                `tbopts'            ///
                `sgopt'
        }
    }

    *--------------------------------------------------------------------------
    * Return results
    *--------------------------------------------------------------------------
    return scalar N        = `nobs'
    return scalar stat     = `stat'
    return scalar rho      = `rho'
    return scalar alpha    = `alpha'
    return scalar beta     = `beta_g'
    return scalar kappa    = `kappa'
    return scalar ab       = `ab'
    return scalar halflife = `halflife'
    return scalar loglik   = `loglik'
    return scalar cv1      = `cv1'
    return scalar cv5      = `cv5'
    return scalar cv10     = `cv10'
    return scalar breaks   = `breaks'

    forvalues j = 1/`breaks' {
        return scalar TB`j' = `tb`j'_val'
    }

    return local varname   "`varlist'"
    return local model     "`model'"
    return local decision  "`decision'"
    return local cmd       "garchur"

    * Significance indicator
    return local stars     "`stars'"
    return local sig_level "`sig_level'"

end
