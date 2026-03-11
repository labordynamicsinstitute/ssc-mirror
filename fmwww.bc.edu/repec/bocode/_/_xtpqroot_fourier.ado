*! _xtpqroot_fourier v1.0.1
*! Panel Unit Root Test with Smooth (Fourier) + Sharp (LST) Structural Breaks
*! Implements: Corakci & Omay (2023, Renewable Energy 205, 648-662)
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: March 2026
capture program drop _xtpqroot_fourier
program define _xtpqroot_fourier, rclass sortpreserve
    version 14.0
    syntax varname(numeric ts) [if] [in], ///
        PANELvar(varname) TIMEvar(varname) ///
        Model(string) MAXLag(integer) ///
        BOOTReps(integer) Level(integer) ///
        N(integer) T(integer) NTobs(integer) ///
        [NOGRaph NOTABle]
    
    marksample touse
    
    * syntax creates lowercase locals; code uses uppercase
    local N `n'
    local T `t'
    local NTobs `ntobs'
    
    sort `panelvar' `timevar'
    qui xtset `panelvar' `timevar'
    
    * =========================================================================
    * SETUP
    * =========================================================================
    
    * Determine model type
    if "`model'" == "intercept" {
        local model_code = 1   // Model A: y = a1 + a2*F(t) + e
        local model_label "A (Intercept shift)"
    }
    else if "`model'" == "trendshift" {
        local model_code = 3   // Model C: y = a1 + b1*t + a2*F(t) + b2*F(t)*t + e
        local model_label "C (Intercept + Trend shift)"
    }
    else {
        local model_code = 2   // Model B: y = a1 + b1*t + a2*F(t) + e
        local model_label "B (Intercept shift + Trend)"
    }
    
    * Max ADF lag for Fourier step
    local maxlag_fourier = min(`maxlag', 6)
    
    * Panel identifiers
    qui levelsof `panelvar' if `touse', local(panels)
    
    * Storage
    tempname results_mat boot_cv_mat ind_mat
    mat `results_mat' = J(1, 4, .)     // tfr, boot_pval, N, T
    mat `ind_mat' = J(`N', 7, .)       // ti_fr, kfr, gamma, tau_break, sharp_date, phi, sic_lag
    
    * =========================================================================
    * STEP 1 & 2: For each panel, estimate LST + Fourier ADF
    * =========================================================================
    
    di as text ""
    di as text "  Estimating LST + Fourier ADF for `N' panels..."
    
    * Run entire estimation in Mata for speed (replaces ~4000 Stata reg calls)
    mata: _xtpqroot_fourier_est_mata("`varlist'", "`panelvar'", "`timevar'", ///
        "`touse'", `N', `T', `model_code', `maxlag_fourier', ///
        "`ind_mat'")
    
    * Panel statistic: tfr = (1/N) * sum(ti_fr)
    local sum_tfr = 0
    local count_valid = 0
    forvalues ii = 1/`N' {
        local ti = `ind_mat'[`ii', 1]
        if `ti' != . {
            local sum_tfr = `sum_tfr' + `ti'
            local ++count_valid
        }
    }
    if `count_valid' > 0 {
        local tfr_stat = `sum_tfr' / `count_valid'
    }
    else {
        local tfr_stat = .
    }

    
    * =========================================================================
    * STEP 3: Sieve Bootstrap for p-values (Chang 2004)
    * =========================================================================
    
    di as text "  Running Sieve Bootstrap (`bootreps' replications)..."
    
    * Run bootstrap as pure Stata program (no Mata)
    _xtpqroot_sieve_boot, varname(`varlist') panelvar(`panelvar') ///
        timevar(`timevar') touse(`touse') npanels(`N') tperiods(`T') ///
        maxlag(`maxlag_fourier') modelcode(`model_code') bootreps(`bootreps') ///
        indmat(`ind_mat') tfrobs(`tfr_stat') resultsmat(`results_mat') ///
        bootcvmat(`boot_cv_mat')
    
    local tfr_stat = `results_mat'[1, 1]
    local boot_pval = `results_mat'[1, 2]
    
    * Bootstrap critical values
    local cv01 = `boot_cv_mat'[1, 1]
    local cv05 = `boot_cv_mat'[1, 2]
    local cv10 = `boot_cv_mat'[1, 3]
    
    * =========================================================================
    * DISPLAY OUTPUT
    * =========================================================================
    
    if "`notable'" == "" {
        di ""
        di as text "{hline 78}"
        di as text "{bf: Panel Unit Root Test with Smooth & Sharp Structural Breaks (tFR)}"
        di as text "{hline 78}"
        
        * Data summary
        di ""
        di as text " {bf:Data Summary}"
        di as text "{hline 78}"
        di as text " Variable          : {res:`varlist'}" ///
            _col(45) as text "Panel variable  : {res:`panelvar'}"
        di as text " Time variable     : {res:`timevar'}" ///
            _col(45) as text "Panel structure : {res:Balanced}"
        di as text " N (panels)        : {res:`N'}" ///
            _col(45) as text "T (time periods): {res:`T'}"
        di as text " Total obs         : {res:`NTobs'}" ///
            _col(45) as text "Model           : {res:`model_label'}"
        di as text " CSD correction    : {res:Sieve Bootstrap}" ///
            _col(45) as text "Boot. reps      : {res:`bootreps'}"
        di as text " Max ADF lag       : {res:`maxlag_fourier'}" ///
            _col(45) as text "Lag selection   : {res:SIC}"
        di as text "{hline 78}"
        
        * Main result
        di ""
        di as text " {bf:Panel Test Result}"
        di as text "{hline 78}"
        di as text %30s "Statistic" _col(35) %14s "Value" _col(52) %12s "p-value" _col(66) %12s ""
        di as text "{hline 78}"
        
        * Stars
        local stars ""
        local scol "text"
        if `boot_pval' < 0.01 & `boot_pval' != . {
            local stars "***"
            local scol "err"
        }
        else if `boot_pval' < 0.05 & `boot_pval' != . {
            local stars "**"
            local scol "err"
        }
        else if `boot_pval' < 0.10 & `boot_pval' != . {
            local stars "*"
            local scol "result"
        }
        
        if `boot_pval' < 0.001 & `boot_pval' != . {
            local pstr "<0.001"
        }
        else if `boot_pval' == . {
            local pstr "---"
        }
        else {
            local pstr : di %8.3f `boot_pval'
            local pstr = strtrim("`pstr'")
        }
        
        di as text %30s "tFR" _col(35) as result %14.3f `tfr_stat' ///
            _col(52) as `scol' %12s "`pstr'`stars'"
        di as text "{hline 78}"
        
        * Critical values table
        di ""
        di as text " {bf:Bootstrap Critical Values}"
        di as text "{hline 78}"
        di as text %18s "Signif. Level" _col(22) %14s "Critical Value" ///
            _col(38) %14s "tFR" _col(54) %24s "Decision"
        di as text "{hline 78}"
        
        * 1%
        if `tfr_stat' < `cv01' & `cv01' != . {
            di as text %18s "1%" _col(22) as result %14.3f `cv01' ///
                _col(38) as result %14.3f `tfr_stat' ///
                _col(54) as err %24s "Reject H0 ***"
        }
        else {
            di as text %18s "1%" _col(22) as result %14.3f `cv01' ///
                _col(38) as result %14.3f `tfr_stat' ///
                _col(54) as text %24s "Fail to reject H0"
        }
        
        * 5%
        if `tfr_stat' < `cv05' & `cv05' != . {
            di as text %18s "5%" _col(22) as result %14.3f `cv05' ///
                _col(38) as result %14.3f `tfr_stat' ///
                _col(54) as err %24s "Reject H0 **"
        }
        else {
            di as text %18s "5%" _col(22) as result %14.3f `cv05' ///
                _col(38) as result %14.3f `tfr_stat' ///
                _col(54) as text %24s "Fail to reject H0"
        }
        
        * 10%
        if `tfr_stat' < `cv10' & `cv10' != . {
            di as text %18s "10%" _col(22) as result %14.3f `cv10' ///
                _col(38) as result %14.3f `tfr_stat' ///
                _col(54) as err %24s "Reject H0 *"
        }
        else {
            di as text %18s "10%" _col(22) as result %14.3f `cv10' ///
                _col(38) as result %14.3f `tfr_stat' ///
                _col(54) as text %24s "Fail to reject H0"
        }
        di as text "{hline 78}"
        
        * Individual results table
        di ""
        di as text " {bf:Individual Panel Results}"
        di as text "{hline 78}"
        di as text %14s "Panel" _col(16) %8s "t_i,fr" _col(26) %6s "k^fr" ///
            _col(34) %8s "gamma" _col(44) %6s "tau" ///
            _col(52) %10s "Break Date" _col(64) %6s "SIC p" _col(72) %6s ""
        di as text "{hline 78}"
        
        local i = 0
        foreach pid of local panels {
            local ++i
            
            local ti_fr = `ind_mat'[`i', 1]
            local kfr   = `ind_mat'[`i', 2]
            local gamma = `ind_mat'[`i', 3]
            local tau_b = `ind_mat'[`i', 4]
            local s_date = `ind_mat'[`i', 5]
            local sic_p = `ind_mat'[`i', 7]
            
            * Stars for individual t-stat
            local stars_i ""
            if `ti_fr' < `cv01' & `ti_fr' != . & `cv01' != . {
                local stars_i "***"
            }
            else if `ti_fr' < `cv05' & `ti_fr' != . & `cv05' != . {
                local stars_i "**"
            }
            else if `ti_fr' < `cv10' & `ti_fr' != . & `cv10' != . {
                local stars_i "*"
            }
            
            if `ti_fr' != . {
                di as text %14s "`pid'" ///
                    _col(16) as result %8.3f `ti_fr' ///
                    _col(26) as result %6.1f `kfr' ///
                    _col(34) as result %8.1f `gamma' ///
                    _col(44) as result %6.2f `tau_b' ///
                    _col(52) as result %10.0f `s_date' ///
                    _col(64) as result %6.0f `sic_p' ///
                    _col(72) as text "`stars_i'"
            }
            else {
                di as text %14s "`pid'" _col(16) "  ---"
            }
        }
        di as text "{hline 78}"
        
        * ==========================================================
        * Break Dates Table (Table 6 in Corakci & Omay 2023)
        * ==========================================================
        di ""
        di as text " {bf:Sharp and Smooth Break Dates}"
        di as text "{hline 78}"
        di as text " {ul:Country}" _col(18) "{ul:Sharp Break}" ///
            _col(34) "{ul:Smooth Break Dates}"
        di as text "         " _col(18) "{ul:Dates     }" _col(34) ""
        di as text "{hline 78}"
        
        local i = 0
        foreach pid of local panels {
            local ++i
            
            local gamma_i = `ind_mat'[`i', 3]
            local tau_i   = `ind_mat'[`i', 4]
            local s_date  = `ind_mat'[`i', 5]
            local kfr_i   = `ind_mat'[`i', 2]
            
            if `s_date' == . continue
            
            * Get panel label (country name)
            local pname "`pid'"
            capture {
                local vlbl : value label `panelvar'
                if "`vlbl'" != "" {
                    local pname : label `vlbl' `pid'
                }
            }
            * Truncate to 12 chars
            if length("`pname'") > 12 {
                local pname = substr("`pname'", 1, 12)
            }
            
            * Sharp break date
            local sharp_yr : di %4.0f `s_date'
            
            * Smooth break dates: turning points of a*sin(2*pi*k*t/T) + b*cos(2*pi*k*t/T)
            * Turning points occur at t where derivative = 0
            * d/dt[sin(2*pi*k*t/T)] = 0 => cos(2*pi*k*t/T) = 0 => t = T/(4k) + j*T/(2k)
            * This gives peaks/troughs of the Fourier component
            qui sum `timevar' if `panelvar' == `pid' & `touse', meanonly
            local t_min_i = r(min)
            local t_max_i = r(max)
            local Ti_i    = r(N)
            
            local smooth_str ""
            local nsmooth = 0
            if `kfr_i' > 0 & `kfr_i' < . {
                * Half-period of the Fourier cycle
                local half_p = `Ti_i' / (2 * `kfr_i')
                * First extremum at quarter-period
                local first_ext = `Ti_i' / (4 * `kfr_i')
                
                local j = 0
                local done = 0
                while `done' == 0 {
                    local t_ext = `first_ext' + `j' * `half_p'
                    if `t_ext' > `Ti_i' {
                        local done = 1
                    }
                    else if `t_ext' >= 1 {
                        * Convert to calendar date
                        local date_ext = `t_min_i' + floor(`t_ext')
                        if `date_ext' <= `t_max_i' {
                            local ++nsmooth
                            if `nsmooth' > 1 {
                                local smooth_str "`smooth_str', `date_ext'"
                            }
                            else {
                                local smooth_str "`date_ext'"
                            }
                        }
                        local ++j
                    }
                    else {
                        local ++j
                    }
                    if `j' > 100 local done = 1
                }
            }
            
            if "`smooth_str'" == "" local smooth_str "---"
            
            * Display: if smooth_str fits in one line (< 44 chars), print on one line
            * Otherwise, wrap to next line
            if length("`smooth_str'") <= 44 {
                di as text " " %-12s "`pname'" ///
                    _col(18) as result %12s "`sharp_yr'" ///
                    _col(34) as text "`smooth_str'"
            }
            else {
                * First line
                di as text " " %-12s "`pname'" ///
                    _col(18) as result %12s "`sharp_yr'" ///
                    _col(34) as text substr("`smooth_str'", 1, 44)
                * Continuation lines
                local remain = substr("`smooth_str'", 45, .)
                while "`remain'" != "" {
                    local chunk = substr("`remain'", 1, 44)
                    di as text _col(34) "`chunk'"
                    if length("`remain'") > 44 {
                        local remain = substr("`remain'", 45, .)
                    }
                    else {
                        local remain ""
                    }
                }
            }
        }
        di as text "{hline 78}"
        di ""
        di as text " {it:Notes: Sharp break dates are found using the threshold estimate of the}"
        di as text " {it:logistic function, while smooth breaks are obtained using the estimated}"
        di as text " {it:fractional frequencies of the Fourier function.}"
        di as text "{hline 78}"
        
        * Hypotheses
        di ""
        di as text " {bf:Hypotheses}"
        di as text "{hline 78}"
        di as text " H0: All panels contain a unit root (phi_i = 0 for all i)"
        di as text " H1: At least some panels are stationary (phi_i < 0 for some i)"
        di as text "{hline 78}"
        di as text " *** p<0.01, ** p<0.05, * p<0.10"
        di as text " Source: Corakci & Omay (2023, Renewable Energy)"
        di as text "{hline 78}"
    }
    
    * =========================================================================
    * GRAPHS
    * =========================================================================
    
    if "`nograph'" == "" {
        preserve
        
        * --- Graph 1: Individual panel fitted curves (like pq3 paper) ---
        local npanels : word count `panels'
        local ngraphs = min(`npanels', 16)
        
        local glist ""
        local gcount = 0
        local i = 0
        foreach pid of local panels {
            local ++i
            if `i' > `ngraphs' continue
            
            local ti_fr = `ind_mat'[`i', 1]
            if `ti_fr' == . continue
            
            local kfr_i   = `ind_mat'[`i', 2]
            local gamma_i = `ind_mat'[`i', 3]
            local tau_i   = `ind_mat'[`i', 4]
            
            * Get panel label
            local pname "`pid'"
            capture {
                local vlbl : value label `panelvar'
                if "`vlbl'" != "" {
                    local pname : label `vlbl' `pid'
                }
            }
            if length("`pname'") > 10 {
                local pname = substr("`pname'", 1, 10)
            }
            
            * Compute fitted values via Stata OLS
            tempvar _fit_`i' _lst_`i' _sin_`i' _cos_`i' _tt_`i'
            
            * Time index within panel
            qui gen double `_tt_`i'' = .
            qui bysort `panelvar' (`timevar'): replace `_tt_`i'' = _n if `panelvar' == `pid' & `touse'
            qui sum `_tt_`i'' if `panelvar' == `pid' & `touse', meanonly
            local Ti_g = r(max)
            
            * LST transition function
            qui gen double `_lst_`i'' = 1 / (1 + exp(-`gamma_i' * (`_tt_`i'' - `tau_i' * `Ti_g'))) if `panelvar' == `pid' & `touse'
            
            * Fourier terms
            qui gen double `_sin_`i'' = sin(2 * _pi * `kfr_i' * `_tt_`i'' / `Ti_g') if `panelvar' == `pid' & `touse'
            qui gen double `_cos_`i'' = cos(2 * _pi * `kfr_i' * `_tt_`i'' / `Ti_g') if `panelvar' == `pid' & `touse'
            
            * OLS fit and predict
            if `model_code' == 1 {
                capture qui reg `varlist' `_lst_`i'' `_sin_`i'' `_cos_`i'' if `panelvar' == `pid' & `touse'
            }
            else if `model_code' == 3 {
                tempvar _ltt_`i'
                qui gen double `_ltt_`i'' = `_lst_`i'' * `_tt_`i'' if `panelvar' == `pid' & `touse'
                capture qui reg `varlist' `_tt_`i'' `_lst_`i'' `_ltt_`i'' `_sin_`i'' `_cos_`i'' if `panelvar' == `pid' & `touse'
            }
            else {
                capture qui reg `varlist' `_tt_`i'' `_lst_`i'' `_sin_`i'' `_cos_`i'' if `panelvar' == `pid' & `touse'
            }
            
            if _rc != 0 continue
            
            tempvar _fit_`i'
            capture qui predict double `_fit_`i'' if `panelvar' == `pid' & `touse', xb
            if _rc != 0 continue
            
            local ++gcount
            
            * Create individual panel graph
            capture twoway ///
                (line `varlist' `timevar' if `panelvar' == `pid' & `touse', ///
                    lcolor(gs3) lwidth(medthin)) ///
                (line `_fit_`i'' `timevar' if `panelvar' == `pid' & `touse', ///
                    lcolor("0 90 181") lwidth(medthin)), ///
                title("`pname'", size(small)) ///
                ytitle("", size(tiny)) xtitle("", size(tiny)) ///
                ylabel(, labsize(tiny) grid glcolor(gs14)) ///
                xlabel(, labsize(tiny) angle(45)) ///
                legend(off) ///
                graphregion(color(white) margin(tiny)) ///
                plotregion(margin(tiny) lcolor(gs12)) ///
                name(_xtpq_p`gcount', replace) nodraw
            
            if _rc == 0 {
                local glist "`glist' _xtpq_p`gcount'"
            }
        }
        
        * Combine panels into one figure
        if `gcount' > 0 & "`glist'" != "" {
            if `gcount' <= 4       local gcols = 2
            else if `gcount' <= 9  local gcols = 3
            else                   local gcols = 4
            
            capture graph combine `glist', ///
                cols(`gcols') ///
                title("{bf:Actual vs Fitted (LST + Fourier)}", ///
                    size(small) color("0 51 102")) ///
                subtitle("`varlist'  Model `model_label'", ///
                    size(vsmall) color(gs6)) ///
                note("Black = actual, Blue = LST + Fourier fitted", ///
                    size(vsmall)) ///
                graphregion(color(white)) ///
                name(xtpqroot_fourier_panels, replace)
            
            forvalues gi = 1/`gcount' {
                capture graph drop _xtpq_p`gi'
            }
        }
        
        * --- Graph 2: t-statistics bar chart ---
        capture confirm matrix `boot_cv_mat'
        if _rc == 0 {
            qui clear
            qui set obs `npanels'
            qui gen str20 panel_name = ""
            qui gen double t_stat = .
            
            local i = 0
            foreach pid of local panels {
                local ++i
                qui replace panel_name = "`pid'" in `i'
                qui replace t_stat = `ind_mat'[`i', 1] in `i'
            }
            
            qui gsort t_stat
            qui gen order = _n
            
            qui gen byte sig = 0
            qui replace sig = 3 if t_stat < `cv01' & t_stat != .
            qui replace sig = 2 if t_stat < `cv05' & t_stat >= `cv01' & t_stat != .
            qui replace sig = 1 if t_stat < `cv10' & t_stat >= `cv05' & t_stat != .
            
            twoway (bar t_stat order if sig == 3, barwidth(0.6) ///
                       fcolor("204 0 51") lcolor("153 0 38") lwidth(vthin)) ///
                   (bar t_stat order if sig == 2, barwidth(0.6) ///
                       fcolor("255 153 0") lcolor("204 122 0") lwidth(vthin)) ///
                   (bar t_stat order if sig == 1, barwidth(0.6) ///
                       fcolor("255 204 51") lcolor("204 163 41") lwidth(vthin)) ///
                   (bar t_stat order if sig == 0, barwidth(0.6) ///
                       fcolor("180 200 220") lcolor("150 170 190") lwidth(vthin)) ///
                   (scatteri `cv05' 0.5 `cv05' `=`npanels'+0.5', recast(line) ///
                       lcolor("0 102 204") lwidth(medium) lpattern(dash)), ///
                title("{bf:Individual t(i,FR) Statistics}", ///
                    size(medium) color("0 51 102")) ///
                xtitle("") ytitle("t-statistic", size(small)) ///
                xlabel(1/`npanels', valuelabel angle(45) labsize(tiny)) ///
                ylabel(, labsize(small) grid glcolor(gs14)) ///
                legend(order(1 "Reject at 1%" 2 "Reject at 5%" ///
                    3 "Reject at 10%" 4 "Fail to reject" 5 "5% CV") ///
                    size(vsmall) cols(5) position(6) ///
                    region(lcolor(gs14) color(white))) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(small) lcolor(gs12)) ///
                scheme(s2color) name(xtpqroot_fourier_ind, replace)
        }
        
        restore
    }
    
    * =========================================================================
    * RETURN VALUES
    * =========================================================================
    
    return scalar tfr      = `tfr_stat'
    return scalar pvalue   = `boot_pval'
    return scalar cv01     = `cv01'
    return scalar cv05     = `cv05'
    return scalar cv10     = `cv10'
    return matrix ind_results = `ind_mat'
    return scalar bootreps = `bootreps'
    return local test      "tFR"
    return local model_type "`model_label'"
    
end

* =============================================================================
* MATA: SIEVE BOOTSTRAP (Chang 2004) --" Fast compiled version
* =============================================================================

capture program drop _xtpqroot_sieve_boot
program define _xtpqroot_sieve_boot
    syntax, varname(varname) panelvar(varname) timevar(varname) ///
        touse(varname) npanels(integer) tperiods(integer) ///
        maxlag(integer) modelcode(integer) bootreps(integer) ///
        indmat(string) tfrobs(real) resultsmat(string) bootcvmat(string)
    
    * Pass everything to Mata for fast execution
    mata: _xtpqroot_sieve_boot_mata("`varname'", "`panelvar'", "`touse'", ///
        `npanels', `tperiods', `maxlag', `bootreps', ///
        "`indmat'", `tfrobs', "`resultsmat'", "`bootcvmat'")
end

* Drop any previous Mata definitions
capture mata: mata drop _xtpqroot_sieve_boot_mata()
capture mata: mata drop _xtpqroot_fourier_est_mata()

mata:

void _xtpqroot_sieve_boot_mata(
    string scalar varname,
    string scalar panelvar,
    string scalar tousevar,
    real scalar N,
    real scalar T_,
    real scalar maxlag,
    real scalar bootreps,
    string scalar indmat_name,
    real scalar tfr_obs,
    string scalar resultsmat_name,
    string scalar bootcvmat_name
)
{
    real matrix indmat, Y_panel, delta_coefs, epsilon_mat
    real colvector panel_all, y_all, unique_panels, sel, yi
    real colvector dyi, dep, ylag_v, ei
    real matrix X_h0
    real colvector bh0
    real scalar i, tt, jj, kfr_i, sic_lag_i, t_start, t_eff, ncols_h0
    real scalar n_raw, det_val
    
    // Bootstrap variables
    real matrix eps_star
    real colvector de_star, e_star, dep_b
    real matrix Xb
    real colvector bhat_b, resid_b, boot_tfr, boot_ti
    real scalar rep, doubleT, rand_t, ar_start, start_use
    real scalar t_start2, t_eff2, ncols_b, dof, sigma2_b, se_b
    real scalar sum_bti, cnt_bti, de_idx, elag_idx, dlag_idx
    real scalar kfr_i2, sic_lag_i2, tt2
    real scalar n_valid, cnt_le, boot_pval, cv01, cv05, cv10
    real colvector valid_boot, sorted_boot
    
    // Read data
    st_view(y_all, ., varname, tousevar)
    st_view(panel_all, ., panelvar, tousevar)
    unique_panels = uniqrows(panel_all)
    indmat = st_matrix(indmat_name)
    
    // Storage
    delta_coefs = J(N, maxlag, 0)
    epsilon_mat = J(T_, N, 0)
    
    // =================================================================
    // Step 1: Extract AR coefficients and centered residuals per panel
    // =================================================================
    
    // First, load all panel data into Y_panel (T x N)
    Y_panel = J(T_, N, .)
    
    for (i = 1; i <= N; i++) {
        if (i > rows(unique_panels)) break
        
        sel = (panel_all :== unique_panels[i])
        yi = select(y_all, sel)
        n_raw = rows(yi)
        if (n_raw < T_) continue
        
        // Store panel data
        Y_panel[., i] = yi[1..T_]
        
        kfr_i = indmat[i, 2]
        sic_lag_i = indmat[i, 7]
        if (kfr_i >= .) continue
        
        // First differences
        dyi = yi[2..T_] - yi[1..T_-1]
        
        // Effective sample
        t_start = max((2, sic_lag_i + 2))
        t_eff = T_ - t_start + 1
        if (t_eff < 10) continue
        
        // Build X_h0 = [1, sin, cos, y_{t-1}, lags(Dy)] (unrestricted ADF)
        ncols_h0 = 4 + sic_lag_i
        X_h0 = J(t_eff, ncols_h0, 0)
        dep = J(t_eff, 1, 0)
        ylag_v = J(t_eff, 1, 0)
        
        for (jj = 1; jj <= t_eff; jj++) {
            tt = t_start - 1 + jj
            
            // dep = Dy at time tt
            if (tt-1 >= 1 & tt-1 <= T_-1) dep[jj] = dyi[tt-1]
            
            // y_{t-1}
            if (tt-1 >= 1 & tt-1 <= T_) ylag_v[jj] = yi[tt-1]
            
            // Intercept, Fourier, lagged level
            X_h0[jj, 1] = 1
            X_h0[jj, 2] = sin(2 * pi() * kfr_i * tt / T_)
            X_h0[jj, 3] = cos(2 * pi() * kfr_i * tt / T_)
            X_h0[jj, 4] = ylag_v[jj]
            
            // AR lags
            for (tt2 = 1; tt2 <= sic_lag_i; tt2++) {
                dlag_idx = tt - 1 - tt2
                if (dlag_idx >= 1 & dlag_idx <= T_-1) {
                    X_h0[jj, 4 + tt2] = dyi[dlag_idx]
                }
            }
        }
        
        // OLS
        det_val = det(cross(X_h0, X_h0))
        if (det_val > 1e-15) {
            bh0 = invsym(cross(X_h0, X_h0)) * cross(X_h0, dep)
            ei = dep - X_h0 * bh0
            
            // Store delta coefficients (cols 5+)
            for (jj = 1; jj <= min((sic_lag_i, maxlag)); jj++) {
                if (4 + jj <= rows(bh0)) {
                    delta_coefs[i, jj] = bh0[4 + jj]
                }
            }
            
            // Center residuals
            ei = ei :- mean(ei)
            
            // Store in epsilon_mat
            for (jj = 1; jj <= min((t_eff, T_ - t_start + 1)); jj++) {
                if (t_start - 1 + jj <= T_) {
                    epsilon_mat[t_start - 1 + jj, i] = ei[jj]
                }
            }
        }
    }
    
    // =================================================================
    // Steps 3-5: Bootstrap loop (ALL in Mata = fast)
    // =================================================================
    
    doubleT = 2 * T_
    boot_tfr = J(bootreps, 1, .)
    
    for (rep = 1; rep <= bootreps; rep++) {
        
        // Step 3: Resample full rows (preserves cross-panel covariance)
        eps_star = J(doubleT, N, 0)
        for (tt = 1; tt <= doubleT; tt++) {
            rand_t = ceil(runiform(1, 1) * T_)
            if (rand_t < 1) rand_t = 1
            if (rand_t > T_) rand_t = T_
            eps_star[tt, .] = epsilon_mat[rand_t, .]
        }
        
        // Per-panel bootstrap t-stats
        boot_ti = J(N, 1, .)
        
        for (i = 1; i <= N; i++) {
            kfr_i2 = indmat[i, 2]
            sic_lag_i2 = indmat[i, 7]
            if (kfr_i2 >= .) continue
            
            // Step 4: AR filter -> de_star
            de_star = J(doubleT, 1, 0)
            ar_start = max((sic_lag_i2 + 1, 1))
            
            for (tt = ar_start; tt <= doubleT; tt++) {
                de_star[tt] = eps_star[tt, i]
                for (jj = 1; jj <= min((sic_lag_i2, maxlag)); jj++) {
                    if (tt - jj >= 1) {
                        de_star[tt] = de_star[tt] + delta_coefs[i, jj] * de_star[tt - jj]
                    }
                }
            }
            
            // Step 5: Partial sums -> levels (last T obs)
            start_use = T_ + 1
            e_star = J(T_, 1, 0)
            e_star[1] = de_star[start_use]
            for (tt = 2; tt <= T_; tt++) {
                e_star[tt] = e_star[tt-1] + de_star[start_use + tt - 1]
            }
            
            // Build bootstrap ADF regression
            t_start2 = max((2, sic_lag_i2 + 2))
            t_eff2 = T_ - t_start2 + 1
            if (t_eff2 < 10) continue
            
            ncols_b = 4 + sic_lag_i2
            Xb = J(t_eff2, ncols_b, 0)
            dep_b = J(t_eff2, 1, 0)
            
            for (jj = 1; jj <= t_eff2; jj++) {
                tt2 = t_start2 - 1 + jj
                
                // dep = de_star at (start_use + tt2 - 1)
                de_idx = start_use + tt2 - 1
                if (de_idx >= 1 & de_idx <= doubleT) dep_b[jj] = de_star[de_idx]
                
                // Intercept + Fourier
                Xb[jj, 1] = 1
                Xb[jj, 2] = sin(2 * pi() * kfr_i2 * tt2 / T_)
                Xb[jj, 3] = cos(2 * pi() * kfr_i2 * tt2 / T_)
                
                // e*_{t-1}
                elag_idx = tt2 - 1
                if (elag_idx >= 1 & elag_idx <= T_) Xb[jj, 4] = e_star[elag_idx]
                
                // ADF lags
                for (tt = 1; tt <= sic_lag_i2; tt++) {
                    dlag_idx = start_use + tt2 - 1 - tt
                    if (dlag_idx >= 1 & dlag_idx <= doubleT) {
                        Xb[jj, 4 + tt] = de_star[dlag_idx]
                    }
                }
            }
            
            // OLS t-stat on column 4 (lagged level)
            det_val = det(cross(Xb, Xb))
            if (det_val > 1e-15) {
                bhat_b = invsym(cross(Xb, Xb)) * cross(Xb, dep_b)
                resid_b = dep_b - Xb * bhat_b
                dof = t_eff2 - ncols_b
                if (dof > 0) {
                    sigma2_b = cross(resid_b, resid_b) / dof
                    se_b = sqrt(sigma2_b * invsym(cross(Xb, Xb))[4, 4])
                    if (se_b > 0 & se_b < .) {
                        boot_ti[i] = bhat_b[4] / se_b
                    }
                }
            }
        }
        
        // Panel average
        sum_bti = 0
        cnt_bti = 0
        for (i = 1; i <= N; i++) {
            if (boot_ti[i] < .) {
                sum_bti = sum_bti + boot_ti[i]
                cnt_bti++
            }
        }
        if (cnt_bti > 0) boot_tfr[rep] = sum_bti / cnt_bti
    }
    
    // =================================================================
    // P-value and critical values
    // =================================================================
    
    valid_boot = select(boot_tfr, boot_tfr :< .)
    n_valid = rows(valid_boot)
    
    if (n_valid > 0) {
        // p-value
        cnt_le = sum(valid_boot :<= tfr_obs)
        boot_pval = cnt_le / n_valid
        
        // Sort and extract critical values
        sorted_boot = sort(valid_boot, 1)
        cv01 = sorted_boot[max((1, ceil(n_valid * 0.01)))]
        cv05 = sorted_boot[max((1, ceil(n_valid * 0.05)))]
        cv10 = sorted_boot[max((1, ceil(n_valid * 0.10)))]
    }
    else {
        boot_pval = .
        cv01 = .
        cv05 = .
        cv10 = .
    }
    
    // Store results
    st_matrix(resultsmat_name, (tfr_obs, boot_pval, N, T_))
    st_matrix(bootcvmat_name, (cv01, cv05, cv10))
}

// =========================================================================
// Full Fourier estimation in Mata (LST grid search + Fourier ADF)
// Replaces ~4365 Stata reg calls with compiled cross()/invsym() OLS
// =========================================================================
void _xtpqroot_fourier_est_mata(
    string scalar varname,
    string scalar panelvar,
    string scalar timevar,
    string scalar tousevar,
    real scalar N,
    real scalar T_,
    real scalar model_code,
    real scalar maxlag_fourier,
    string scalar indmat_name
)
{
    real colvector y_all, panel_all, time_all, unique_panels, sel, yi, ti
    real matrix indmat
    real scalar i, n_raw, Ti
    
    // LST grid search variables
    real rowvector gamma_grid
    real scalar g_idx, tau_idx, g_val, tau_frac
    real scalar best_ssr, best_gamma, best_tau
    real colvector F_t, t_trend, Ft_t_int
    real matrix X_lst
    real colvector b_lst, resid_lst
    real scalar ssr_current, det_val
    real scalar tt
    
    // Fourier ADF variables
    real scalar kfr, kfr_val, best_kfr, best_ssr_fourier, best_tfr_i, best_sic_lag
    real colvector sin_k, cos_k, de_resid, de_lag, de_d
    real matrix X_adf
    real colvector dep_adf, b_adf, resid_adf
    real scalar pp, opt_p, best_sic, sic_val, n_adf, k_adf
    real scalar ssr_f, se_phi, t_phi
    real scalar t_start, jj
    real colvector dlag_j
    
    // Break date
    real scalar t_min, t_max, sharp_date
    
    // Read data
    st_view(y_all, ., varname, tousevar)
    st_view(panel_all, ., panelvar, tousevar)
    st_view(time_all, ., timevar, tousevar)
    unique_panels = uniqrows(panel_all)
    indmat = st_matrix(indmat_name)
    
    gamma_grid = (0.1, 0.5, 1, 2, 3, 5, 10, 20, 50)
    
    for (i = 1; i <= N; i++) {
        if (i > rows(unique_panels)) break
        
        sel = (panel_all :== unique_panels[i])
        yi = select(y_all, sel)
        ti = select(time_all, sel)
        n_raw = rows(yi)
        Ti = n_raw
        
        if (Ti < 20) {
            indmat[i, 1] = .
            continue
        }
        
        // =============================================================
        // Step 1: LST grid search --" minimize SSR over (gamma, tau)
        // =============================================================
        best_ssr = 1e30
        best_gamma = 1
        best_tau = 0.5
        
        for (g_idx = 1; g_idx <= cols(gamma_grid); g_idx++) {
            g_val = gamma_grid[g_idx]
            
            for (tau_idx = 15; tau_idx <= 85; tau_idx = tau_idx + 5) {
                tau_frac = tau_idx / 100
                
                // Transition function F(t) = 1/(1+exp(-gamma*(t-tau*T)))
                F_t = J(Ti, 1, 0)
                for (tt = 1; tt <= Ti; tt++) {
                    F_t[tt] = 1 / (1 + exp(-g_val * (tt - tau_frac * Ti)))
                }
                
                // Build X based on model
                if (model_code == 1) {
                    // Model A: y = a1 + a2*F(t)
                    X_lst = J(Ti, 1, 1), F_t
                }
                else if (model_code == 3) {
                    // Model C: y = a1 + b1*t + a2*F(t) + b2*F(t)*t
                    t_trend = (1::Ti)
                    Ft_t_int = F_t :* t_trend
                    X_lst = J(Ti, 1, 1), t_trend, F_t, Ft_t_int
                }
                else {
                    // Model B: y = a1 + b1*t + a2*F(t)
                    t_trend = (1::Ti)
                    X_lst = J(Ti, 1, 1), t_trend, F_t
                }
                
                det_val = det(cross(X_lst, X_lst))
                if (det_val > 1e-15) {
                    b_lst = invsym(cross(X_lst, X_lst)) * cross(X_lst, yi)
                    resid_lst = yi - X_lst * b_lst
                    ssr_current = cross(resid_lst, resid_lst)
                    if (ssr_current < best_ssr) {
                        best_ssr = ssr_current
                        best_gamma = g_val
                        best_tau = tau_frac
                    }
                }
            }
        }
        
        // Get residuals from best LST model
        F_t = J(Ti, 1, 0)
        for (tt = 1; tt <= Ti; tt++) {
            F_t[tt] = 1 / (1 + exp(-best_gamma * (tt - best_tau * Ti)))
        }
        
        if (model_code == 1) {
            X_lst = J(Ti, 1, 1), F_t
        }
        else if (model_code == 3) {
            t_trend = (1::Ti)
            X_lst = J(Ti, 1, 1), t_trend, F_t, F_t :* t_trend
        }
        else {
            t_trend = (1::Ti)
            X_lst = J(Ti, 1, 1), t_trend, F_t
        }
        
        b_lst = invsym(cross(X_lst, X_lst)) * cross(X_lst, yi)
        de_resid = yi - X_lst * b_lst
        
        // =============================================================
        // Step 2: Fourier ADF on residuals
        // Grid: kfr in {0.1, 0.2, ..., 5.0}
        // =============================================================
        best_kfr = 1
        best_ssr_fourier = 1e30
        best_tfr_i = .
        best_sic_lag = 1
        
        // Compute first differences and lags of de_resid once
        de_lag = J(Ti, 1, .)
        de_d = J(Ti, 1, .)
        for (tt = 2; tt <= Ti; tt++) {
            de_lag[tt] = de_resid[tt - 1]
            de_d[tt] = de_resid[tt] - de_resid[tt - 1]
        }
        
        for (kfr = 1; kfr <= 50; kfr++) {
            kfr_val = kfr / 10
            
            // Fourier terms
            sin_k = J(Ti, 1, 0)
            cos_k = J(Ti, 1, 0)
            for (tt = 1; tt <= Ti; tt++) {
                sin_k[tt] = sin(2 * pi() * kfr_val * tt / Ti)
                cos_k[tt] = cos(2 * pi() * kfr_val * tt / Ti)
            }
            
            // SIC lag selection
            best_sic = 1e30
            opt_p = 0
            
            for (pp = 0; pp <= maxlag_fourier; pp++) {
                // Effective sample starts at max(2, pp+2) to accommodate lags
                t_start = max((2, pp + 2))
                n_adf = Ti - t_start + 1
                if (n_adf <= 5) continue
                
                // Build X: [sin, cos, de_lag, lag1(de_d), ..., lagp(de_d)]
                X_adf = sin_k[t_start..Ti], cos_k[t_start..Ti], de_lag[t_start..Ti]
                dep_adf = de_d[t_start..Ti]
                
                for (jj = 1; jj <= pp; jj++) {
                    dlag_j = J(n_adf, 1, 0)
                    for (tt = 1; tt <= n_adf; tt++) {
                        if (t_start + tt - 1 - jj >= 2) {
                            dlag_j[tt] = de_d[t_start + tt - 1 - jj]
                        }
                    }
                    X_adf = X_adf, dlag_j
                }
                
                // Add intercept
                X_adf = J(n_adf, 1, 1), X_adf
                k_adf = cols(X_adf)
                
                det_val = det(cross(X_adf, X_adf))
                if (det_val > 1e-15) {
                    b_adf = invsym(cross(X_adf, X_adf)) * cross(X_adf, dep_adf)
                    resid_adf = dep_adf - X_adf * b_adf
                    ssr_f = cross(resid_adf, resid_adf)
                    sic_val = ln(ssr_f / n_adf) + k_adf * ln(n_adf) / n_adf
                    if (sic_val < best_sic) {
                        best_sic = sic_val
                        opt_p = pp
                    }
                }
            }
            
            // Run final ADF with optimal lag at this kfr
            t_start = max((2, opt_p + 2))
            n_adf = Ti - t_start + 1
            if (n_adf <= 5) continue
            
            X_adf = sin_k[t_start..Ti], cos_k[t_start..Ti], de_lag[t_start..Ti]
            dep_adf = de_d[t_start..Ti]
            
            for (jj = 1; jj <= opt_p; jj++) {
                dlag_j = J(n_adf, 1, 0)
                for (tt = 1; tt <= n_adf; tt++) {
                    if (t_start + tt - 1 - jj >= 2) {
                        dlag_j[tt] = de_d[t_start + tt - 1 - jj]
                    }
                }
                X_adf = X_adf, dlag_j
            }
            
            X_adf = J(n_adf, 1, 1), X_adf
            k_adf = cols(X_adf)
            
            det_val = det(cross(X_adf, X_adf))
            if (det_val > 1e-15 & n_adf > 5) {
                b_adf = invsym(cross(X_adf, X_adf)) * cross(X_adf, dep_adf)
                resid_adf = dep_adf - X_adf * b_adf
                ssr_f = cross(resid_adf, resid_adf)
                
                if (ssr_f < best_ssr_fourier) {
                    best_ssr_fourier = ssr_f
                    best_kfr = kfr_val
                    
                    // t-stat on de_lag (column 4 = intercept, sin, cos, de_lag)
                    // se = sqrt(sigma2 * (X'X)^{-1}[4,4])
                    se_phi = sqrt(ssr_f / (n_adf - k_adf) * invsym(cross(X_adf, X_adf))[4, 4])
                    if (se_phi > 0 & se_phi < .) {
                        best_tfr_i = b_adf[4] / se_phi
                    }
                    best_sic_lag = opt_p
                }
            }
        }
        
        // Store results in indmat
        // Cols: ti_fr, kfr, gamma, tau_break, sharp_date, phi_hat, sic_lag
        indmat[i, 1] = best_tfr_i
        indmat[i, 2] = best_kfr
        indmat[i, 3] = best_gamma
        indmat[i, 4] = best_tau
        
        // Sharp break date
        t_min = min(ti)
        t_max = max(ti)
        sharp_date = t_min + round(best_tau * (t_max - t_min))
        indmat[i, 5] = sharp_date
        indmat[i, 6] = best_tfr_i
        indmat[i, 7] = best_sic_lag
    }
    
    st_matrix(indmat_name, indmat)
}

end


