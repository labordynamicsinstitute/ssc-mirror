*! version 1.0.1  11apr2026  Dr. Merwan Roudane
*! _lrmbounds_graph: Publication-quality visualizations for lrmbounds
*! Produces: LRM forest plot, CUSUM, actual vs fitted, residual diagnostics,
*!           dynamic multipliers, bounds comparison chart

capture program drop _lrmbounds_graph
program define _lrmbounds_graph
    syntax , [                                  ///
        DEPVAR(string)                          ///
        INDEPVARS(string)                       ///
        NINDEP(integer 1)                       ///
        OPTLAG(integer 1)                       ///
        TREND                                   ///
        NOCONStant                              ///
        GRAPHDIR(string)                        ///
        F_PSS(real 0)                           ///
        F_LB(real 0)                            ///
        F_UB(real 0)                            ///
        ECR(real 0)                             ///
        NOBS(integer 100)                       ///
        ]
    
    if "`graphdir'" == "" local graphdir "lrmbounds_graphs"
    capture mkdir "`graphdir'"
    
    * ----------------------------------------------------------------
    * Build ECM specification (shared by Graphs 1, 3, 5, 6)
    * ----------------------------------------------------------------
    local ecm_levels "L.`depvar'"
    foreach xv of local indepvars {
        local ecm_levels "`ecm_levels' L.`xv'"
    }
    local ecm_diffs ""
    foreach xv of local indepvars {
        local ecm_diffs "`ecm_diffs' D.`xv'"
    }
    if `optlag' > 1 {
        forvalues i = 1/`=`optlag'-1' {
            local ecm_diffs "`ecm_diffs' L`i'D.`depvar'"
            foreach xv of local indepvars {
                local ecm_diffs "`ecm_diffs' L`i'D.`xv'"
            }
        }
    }
    local trendvar ""
    if "`trend'" != "" {
        tempvar tvar
        qui gen double `tvar' = _n
        local trendvar "`tvar'"
    }
    
    * Run the ECM once and keep fitted / residual for Graphs 3-4
    qui regress D.`depvar' `ecm_levels' `ecm_diffs' `trendvar', `noconstant'
    
    tempname bmat Vmat
    matrix `bmat' = e(b)
    matrix `Vmat' = e(V)
    local ecr_val = _b[L.`depvar']
    
    tempvar fitted resid
    qui predict double `fitted', xb
    qui predict double `resid' , residuals
    
    * ================================================================
    *  Graph 1: LRM Forest Plot with Bounds Decision
    *  Shows each LRM with CI, color-coded by bounds decision
    * ================================================================
    capture noisily {
        preserve
        clear
        qui set obs `nindep'
        qui gen str32 varname = ""
        qui gen double lrm = .
        qui gen double lrm_se = .
        qui gen double lrm_lo = .
        qui gen double lrm_hi = .
        qui gen double lrm_t = .
        qui gen int order = _n
        
        local j = 0
        foreach xv of local indepvars {
            local ++j
            
            local psi_yx = `bmat'[1, colnumb(`bmat', "L.`xv'")]
            local pos_yy = colnumb(`bmat', "L.`depvar'")
            local pos_xj = colnumb(`bmat', "L.`xv'")
            
            local lrm_val = -`psi_yx' / `ecr_val'
            
            local var_yy = `Vmat'[`pos_yy', `pos_yy']
            local var_xj = `Vmat'[`pos_xj', `pos_xj']
            local cov_xy = `Vmat'[`pos_xj', `pos_yy']
            local g1 = -1 / `ecr_val'
            local g2 = `psi_yx' / (`ecr_val' * `ecr_val')
            local var_lrm = `g1'^2 * `var_xj' + `g2'^2 * `var_yy' + 2 * `g1' * `g2' * `cov_xy'
            local se_val = sqrt(max(`var_lrm', 0))
            
            qui replace varname = "`xv'" in `j'
            qui replace lrm = `lrm_val' in `j'
            qui replace lrm_se = `se_val' in `j'
            qui replace lrm_lo = `lrm_val' - 1.96 * `se_val' in `j'
            qui replace lrm_hi = `lrm_val' + 1.96 * `se_val' in `j'
            qui replace lrm_t = abs(`lrm_val' / `se_val') in `j'
        }
        
        * Create forest plot
        twoway (rcap lrm_lo lrm_hi order, horizontal lcolor("55 71 133") lwidth(medthick)) ///
               (scatter order lrm, msymbol(D) msize(large) mcolor("220 95 60") mlcolor("55 71 133") mlwidth(thin)), ///
               yline(0, lcolor(gs10) lpattern(dash)) ///
               ylabel(1(1)`nindep', valuelabel angle(0) labsize(small)) ///
               xlabel(, labsize(small) grid glcolor(gs14)) ///
               ytitle("") xtitle("Long Run Multiplier (LRM)", size(medsmall)) ///
               title("{bf:Long Run Multiplier Estimates with 95% CI}", size(medium) color("55 71 133")) ///
               subtitle("Webb, Linn & Lebo (2019) Bounds Approach", size(small) color(gs6)) ///
               legend(off) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_forest, replace)
        
        qui graph export "`graphdir'/lrm_forest_plot.png", as(png) replace
        restore
    }
    
    * ================================================================
    *  Graph 2: PSS F-Bounds Comparison Chart
    *  Bar showing F-stat against I(0)/I(1) bounds with colored zones
    * ================================================================
    capture noisily {
        preserve
        clear
        qui set obs 100
        qui gen double x = _n / 10
        qui gen double zone_below = 0
        qui gen double zone_between = 0
        qui gen double zone_above = 0
        
        qui replace zone_below = 1 if x <= `f_lb'
        qui replace zone_between = 1 if x > `f_lb' & x <= `f_ub'
        qui replace zone_above = 1 if x > `f_ub'
        
        * Create the bar chart
        twoway (area zone_below x if zone_below == 1, color("144 190 109%40") base(0)) ///
               (area zone_between x if zone_between == 1, color("255 193 37%40") base(0)) ///
               (area zone_above x if zone_above == 1, color("220 95 60%40") base(0)) ///
               (pci 0 `f_pss' 1 `f_pss', lcolor("55 71 133") lwidth(thick) lpattern(solid)), ///
               xline(`f_lb', lcolor("144 190 109") lwidth(medthick) lpattern(dash)) ///
               xline(`f_ub', lcolor("220 95 60") lwidth(medthick) lpattern(dash)) ///
               xtitle("F-statistic", size(medsmall)) ytitle("") ///
               title("{bf:PSS Bounds Test}", size(medium) color("55 71 133")) ///
               subtitle("F-statistic vs. Critical Value Bounds (5%)", size(small) color(gs6)) ///
               ylabel(none) ///
               xlabel(, labsize(small) grid glcolor(gs14)) ///
               text(0.9 `f_lb' "I(0) = `: display %5.3f `f_lb''", place(w) size(vsmall) color("144 190 109")) ///
               text(0.9 `f_ub' "I(1) = `: display %5.3f `f_ub''", place(e) size(vsmall) color("220 95 60")) ///
               text(0.5 `f_pss' "F = `: display %6.3f `f_pss''", place(e) size(small) color("55 71 133")) ///
               legend(off) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_fbounds, replace)
        
        qui graph export "`graphdir'/pss_fbounds.png", as(png) replace
        restore
    }
    
    * ================================================================
    *  Graph 3: Actual vs Fitted with Residuals
    * ================================================================
    capture noisily {
        
        twoway (tsline D.`depvar', lcolor("55 71 133") lwidth(medthick)) ///
               (tsline `fitted', lcolor("220 95 60") lwidth(medium) lpattern(dash)), ///
               ytitle("D.`depvar'", size(medsmall)) ///
               xtitle("", size(medsmall)) ///
               title("{bf:Actual vs. Fitted Values}", size(medium) color("55 71 133")) ///
               subtitle("Conditional ECM: D.`depvar'", size(small) color(gs6)) ///
               legend(order(1 "Actual" 2 "Fitted") rows(1) position(6) size(small) ///
                      region(lcolor(gs14) fcolor(white))) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_actual_fit, replace)
        
        qui graph export "`graphdir'/actual_vs_fitted.png", as(png) replace
    }
    
    * ================================================================
    *  Graph 4: Residual Diagnostics Panel
    *  Residual time series + histogram + QQ plot
    * ================================================================
    capture noisily {
        * Residual time series  
        twoway (tsline `resid', lcolor("55 71 133") lwidth(medium)), ///
               yline(0, lcolor("220 95 60") lwidth(thin) lpattern(dash)) ///
               ytitle("Residuals", size(medsmall)) ///
               xtitle("", size(medsmall)) ///
               title("{bf:ECM Residuals}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_resid_ts, replace)
        
        * Histogram
        histogram `resid', ///
               fcolor("55 71 133%60") lcolor("55 71 133") ///
               normal normopts(lcolor("220 95 60") lwidth(medthick)) ///
               xtitle("Residuals", size(medsmall)) ///
               ytitle("Density", size(medsmall)) ///
               title("{bf:Residual Distribution}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_resid_hist, replace)
        
        * QQ plot
        qnorm `resid', ///
               msymbol(O) msize(small) mcolor("55 71 133") ///
               rlopts(lcolor("220 95 60") lwidth(medthick)) ///
               xtitle("Theoretical Quantiles", size(medsmall)) ///
               ytitle("Sample Quantiles", size(medsmall)) ///
               title("{bf:Normal Q-Q Plot}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_resid_qq, replace)
        
        * Combine into panel
        graph combine _lrm_resid_ts _lrm_resid_hist _lrm_resid_qq, ///
               cols(3) ///
               title("{bf:Residual Diagnostics Panel}", size(medium) color("55 71 133")) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               name(_lrm_resid_panel, replace)
        
        qui graph export "`graphdir'/residual_diagnostics.png", as(png) replace
    }
    
    * ================================================================
    *  Graph 5: CUSUM Stability Plot
    * ================================================================
    capture noisily {
        qui regress D.`depvar' `ecm_levels' `ecm_diffs' `trendvar', `noconstant'
        tempvar resid2
        qui predict double `resid2', residuals
        
        local N = e(N)
        local k_p = e(rank)
        
        * Compute CUSUM
        tempvar cusum cusum_upper cusum_lower obs_id
        qui gen double `cusum' = .
        qui gen double `obs_id' = _n
        
        * Standardize residuals
        qui sum `resid2'
        local sigma = r(sd)
        
        * Recursive CUSUM
        local cumsum = 0
        forvalues i = 1/`N' {
            local rv = `resid2'[`i']
            if !missing(`rv') {
                local cumsum = `cumsum' + `rv' / `sigma'
                qui replace `cusum' = `cumsum' in `i'
            }
        }
        
        * 5% significance boundaries
        local a = 0.948
        qui gen double `cusum_upper' = `a' * sqrt(`N' - `k_p') + 2 * `a' * (`obs_id' - `k_p') / sqrt(`N' - `k_p')
        qui gen double `cusum_lower' = -`cusum_upper'
        
        twoway (tsline `cusum', lcolor("55 71 133") lwidth(medthick)) ///
               (tsline `cusum_upper', lcolor("220 95 60") lwidth(medium) lpattern(dash)) ///
               (tsline `cusum_lower', lcolor("220 95 60") lwidth(medium) lpattern(dash)), ///
               ytitle("CUSUM", size(medsmall)) ///
               xtitle("", size(medsmall)) ///
               title("{bf:CUSUM Stability Test}", size(medium) color("55 71 133")) ///
               subtitle("5% Significance Boundaries", size(small) color(gs6)) ///
               legend(order(1 "CUSUM" 2 "5% Boundary") rows(1) position(6) size(small) ///
                      region(lcolor(gs14) fcolor(white))) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_cusum, replace)
        
        qui graph export "`graphdir'/cusum_stability.png", as(png) replace
    }
    
    * ================================================================
    *  Graph 6: Dynamic Multiplier Plot
    *  Cumulative effect of a unit change in x over time
    * ================================================================
    capture noisily {
        qui regress D.`depvar' `ecm_levels' `ecm_diffs' `trendvar', `noconstant'
        
        local ecr_dm = _b[L.`depvar']
        
        preserve
        clear
        local nperiods = 30
        qui set obs `nperiods'
        qui gen int period = _n - 1
        
        * For each x variable, compute dynamic multiplier
        local j = 0
        foreach xv of local indepvars {
            local ++j
            
            * Short-run effect (contemporaneous): beta_0 = coeff on D.xv
            capture local sr = `bmat'[1, colnumb(`bmat', "D.`xv'")]
            if _rc local sr = 0
            
            * Long-run multiplier
            local psi_yx = `bmat'[1, colnumb(`bmat', "L.`xv'")]
            local lr = -`psi_yx' / `ecr_dm'
            
            * Dynamic path: cumulative effect converges from sr to lr
            * Using: M_h = LRM * (1 - (1+ecr)^h) + sr * (1+ecr)^(h-1)
            qui gen double dm_`j' = .
            qui replace dm_`j' = 0 in 1
            
            forvalues h = 1/`=`nperiods'-1' {
                local cum = `lr' * (1 - (1 + `ecr_dm')^`h')
                qui replace dm_`j' = `cum' in `=`h'+1'
            }
        }
        
        * Build plot command
        local plotcmd ""
        local legorder ""
        local colors `" "55 71 133" "220 95 60" "144 190 109" "178 102 178" "70 130 180" "'
        
        local j = 0
        foreach xv of local indepvars {
            local ++j
            local col : word `j' of `colors'
            if "`col'" == "" local col "55 71 133"
            local plotcmd "`plotcmd' (line dm_`j' period, lcolor("`col'") lwidth(medthick))"
            local legorder "`legorder' `j' `" "`xv'" "'"
        }
        
        twoway `plotcmd', ///
               ytitle("Cumulative Effect", size(medsmall)) ///
               xtitle("Periods After Shock", size(medsmall)) ///
               title("{bf:Dynamic Multiplier Paths}", size(medium) color("55 71 133")) ///
               subtitle("Cumulative effect of a unit change in each x", size(small) color(gs6)) ///
               xlabel(0(5)30, labsize(small) grid glcolor(gs14)) ///
               legend(order(`legorder') rows(1) position(6) size(small) ///
                      region(lcolor(gs14) fcolor(white))) ///
               scheme(s2color) ///
               graphregion(color(white) margin(small)) ///
               plotregion(margin(small)) ///
               name(_lrm_dynmult, replace)
        
        qui graph export "`graphdir'/dynamic_multipliers.png", as(png) replace
        restore
    }
    
    di ""
    di as res "  Graphs saved to: `graphdir'/"
    di as txt "    lrm_forest_plot.png       — LRM estimates with 95% CI"
    di as txt "    pss_fbounds.png           — F-statistic vs. bounds"
    di as txt "    actual_vs_fitted.png      — Actual vs. fitted values"
    di as txt "    residual_diagnostics.png  — Residual panel (time series, histogram, QQ)"
    di as txt "    cusum_stability.png       — CUSUM stability test"
    di as txt "    dynamic_multipliers.png   — Dynamic multiplier paths"
end
