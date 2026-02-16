*! qardl_graph v1.0.0 - Visualizations for QARDL
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define qardl_graph
    version 14.0
    
    syntax, TAU(numlist >0 <1 sort) P(integer) Q(integer) K(integer) ///
        DEPvar(string) INDEPvars(string) [ECM]
    
    * Check if estimation results exist
    if "`e(cmd)'" != "qardl" {
        di as error "qardl estimation results not found"
        di as error "run qardl first, then qardl_graph"
        exit 301
    }
    
    local ntau : word count `tau'
    
    * ============================================================
    * Color palette: modern, beautiful
    * ============================================================
    local c1 "27 158 119"          // Deep teal
    local c2 "217 95 2"            // Rich orange 
    local c3 "117 112 179"         // Purple
    local c4 "231 41 138"          // Vivid pink
    local c5 "102 166 30"          // Lime green
    local c6 "230 171 2"           // Gold
    local c7 "166 118 29"          // Brown
    local c8 "102 102 102"         // Gray
    
    * ============================================================
    * 1. Quantile Process Plots for Beta (Long-Run)
    * ============================================================
    tempname beta beta_cov tau_mat
    mat `beta' = e(beta)
    mat `beta_cov' = e(beta_cov)
    mat `tau_mat' = e(tau)
    
    local nobs = e(N)
    
    * Create temporary data for plotting
    preserve
    clear
    qui set obs `ntau'
    
    * Tau variable
    qui gen double tau = .
    forvalues i = 1/`ntau' {
        qui replace tau = `tau_mat'[`i', 1] in `i'
    }
    
    * Beta variables with confidence bands
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        qui gen double beta_`vnum' = .
        qui gen double beta_lo_`vnum' = .
        qui gen double beta_hi_`vnum' = .
        
        forvalues t = 1/`ntau' {
            local idx = (`t' - 1) * `k' + `vnum'
            if `idx' <= rowsof(`beta') {
                local est = `beta'[`idx', 1]
                qui replace beta_`vnum' = `est' in `t'
                
                if `idx' <= rowsof(`beta_cov') & `idx' <= colsof(`beta_cov') {
                    local var = `beta_cov'[`idx', `idx']
                    if `var' > 0 {
                        local se = sqrt(`var') / (`nobs' - 1)
                        qui replace beta_lo_`vnum' = `est' - 1.96*`se' in `t'
                        qui replace beta_hi_`vnum' = `est' + 1.96*`se' in `t'
                    }
                }
            }
        }
        
        * Create graph
        local glist ""
        
        * Confidence band (shaded area)
        local glist `glist' (rarea beta_lo_`vnum' beta_hi_`vnum' tau, ///
            fcolor("`c1'%20") lcolor("`c1'%40") lwidth(vthin))
        
        * Point estimate line
        local glist `glist' (connected beta_`vnum' tau, ///
            lcolor("`c1'") mcolor("`c1'") lwidth(medthick) ///
            msymbol(circle) msize(small))
        
        * Zero reference line
        local glist `glist' (function y = 0, range(0.05 0.95) ///
            lcolor(gs10) lpattern(dash))
        
        twoway `glist', ///
            title("{bf:Long-Run: {it:beta}_{`vnum'}(tau)}", ///
                size(medium) color("0 51 102")) ///
            subtitle("`v'", size(small) color(gs5)) ///
            xtitle("Quantile (tau)", size(small)) ///
            ytitle("Coefficient", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(small)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            note("95% Confidence Bands | QARDL(`p',`q')", ///
                 size(vsmall) color(gs8)) ///
            name(qardl_beta_`vnum', replace)
    }
    
    * ============================================================
    * 2. Quantile Process Plots for Phi (Short-Run AR)
    * ============================================================
    tempname phi phi_cov
    mat `phi' = e(phi)
    mat `phi_cov' = e(phi_cov)
    
    forvalues j = 1/`p' {
        qui gen double phi_`j' = .
        qui gen double phi_lo_`j' = .
        qui gen double phi_hi_`j' = .
        
        forvalues t = 1/`ntau' {
            local idx = (`t' - 1) * `p' + `j'
            if `idx' <= rowsof(`phi') {
                local est = `phi'[`idx', 1]
                qui replace phi_`j' = `est' in `t'
                
                if `idx' <= rowsof(`phi_cov') & `idx' <= colsof(`phi_cov') {
                    local var = `phi_cov'[`idx', `idx']
                    if `var' > 0 {
                        local se = sqrt(`var') / sqrt(`nobs' - 1)
                        qui replace phi_lo_`j' = `est' - 1.96*`se' in `t'
                        qui replace phi_hi_`j' = `est' + 1.96*`se' in `t'
                    }
                }
            }
        }
        
        twoway (rarea phi_lo_`j' phi_hi_`j' tau, ///
                fcolor("`c2'%20") lcolor("`c2'%40") lwidth(vthin)) ///
            (connected phi_`j' tau, ///
                lcolor("`c2'") mcolor("`c2'") lwidth(medthick) ///
                msymbol(diamond) msize(small)) ///
            (function y = 0, range(0.05 0.95) ///
                lcolor(gs10) lpattern(dash)), ///
            title("{bf:Short-Run AR: {it:phi}_{t-`j'}(tau)}", ///
                size(medium) color("0 51 102")) ///
            xtitle("Quantile (tau)", size(small)) ///
            ytitle("Coefficient", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(small)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            note("95% Confidence Bands | QARDL(`p',`q')", ///
                 size(vsmall) color(gs8)) ///
            name(qardl_phi_`j', replace)
    }
    
    * ============================================================
    * 3. Quantile Process Plots for Gamma (Short-Run Impact)
    * ============================================================
    tempname gamma gamma_cov
    mat `gamma' = e(gamma)
    mat `gamma_cov' = e(gamma_cov)
    
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        qui gen double gamma_`vnum' = .
        qui gen double gamma_lo_`vnum' = .
        qui gen double gamma_hi_`vnum' = .
        
        forvalues t = 1/`ntau' {
            local idx = (`t' - 1) * `k' + `vnum'
            if `idx' <= rowsof(`gamma') {
                local est = `gamma'[`idx', 1]
                qui replace gamma_`vnum' = `est' in `t'
                
                if `idx' <= rowsof(`gamma_cov') & `idx' <= colsof(`gamma_cov') {
                    local var = `gamma_cov'[`idx', `idx']
                    if `var' > 0 {
                        local se = sqrt(`var') / sqrt(`nobs' - 1)
                        qui replace gamma_lo_`vnum' = `est' - 1.96*`se' in `t'
                        qui replace gamma_hi_`vnum' = `est' + 1.96*`se' in `t'
                    }
                }
            }
        }
        
        twoway (rarea gamma_lo_`vnum' gamma_hi_`vnum' tau, ///
                fcolor("`c3'%20") lcolor("`c3'%40") lwidth(vthin)) ///
            (connected gamma_`vnum' tau, ///
                lcolor("`c3'") mcolor("`c3'") lwidth(medthick) ///
                msymbol(triangle) msize(small)) ///
            (function y = 0, range(0.05 0.95) ///
                lcolor(gs10) lpattern(dash)), ///
            title("{bf:Short-Run Impact: {it:gamma}_{`vnum'}(tau)}", ///
                size(medium) color("0 51 102")) ///
            subtitle("`v'", size(small) color(gs5)) ///
            xtitle("Quantile (tau)", size(small)) ///
            ytitle("Coefficient", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(small)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            note("95% Confidence Bands | QARDL(`p',`q')", ///
                 size(vsmall) color(gs8)) ///
            name(qardl_gamma_`vnum', replace)
    }
    
    * ============================================================
    * 4. Combined panel graph
    * ============================================================
    local combine_list ""
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        local combine_list `combine_list' qardl_beta_`vnum'
    }
    forvalues j = 1/`p' {
        local combine_list `combine_list' qardl_phi_`j'
    }
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        local combine_list `combine_list' qardl_gamma_`vnum'
    }
    
    local ncombine : word count `combine_list'
    if `ncombine' > 1 {
        local ncols = min(`k', 3)
        graph combine `combine_list', ///
            rows(3) ///
            title("{bf:QARDL Quantile Process}", ///
                size(medium) color("0 51 102")) ///
            subtitle("Cho, Kim & Shin (2015) | QARDL(`p',`q')", ///
                size(small) color(gs5)) ///
            graphregion(color(white)) ///
            note("Cho, Kim & Shin (2015) | qardl package", ///
                size(vsmall) color(gs8)) ///
            name(qardl_combined, replace)
    }
    
    * ============================================================
    * 5. Rolling QARDL plots (if available)
    * ============================================================
    capture confirm matrix e(rolling_beta)
    if _rc == 0 {
        tempname rbeta
        mat `rbeta' = e(rolling_beta)
        local nwin = rowsof(`rbeta')
        local ncols_rb = colsof(`rbeta')
        
        clear
        qui set obs `nwin'
        qui gen int window = _n
        
        * Plot rolling beta for each variable at median quantile
        local med_idx = ceil(`ntau' / 2)
        
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            local col_idx = (`med_idx' - 1) * `k' + `vnum'
            if `col_idx' <= `ncols_rb' {
                qui gen double rbeta_`vnum' = .
                forvalues i = 1/`nwin' {
                    qui replace rbeta_`vnum' = `rbeta'[`i', `col_idx'] in `i'
                }
                
                twoway (line rbeta_`vnum' window, ///
                        lcolor("`c1'") lwidth(medium)), ///
                    title("{bf:Rolling beta_{`vnum'}(0.5)}", ///
                        size(medium) color("0 51 102")) ///
                    subtitle("`v'", size(small) color(gs5)) ///
                    xtitle("Window", size(small)) ///
                    ytitle("Coefficient", size(small)) ///
                    graphregion(color(white) margin(small)) ///
                    plotregion(margin(small)) ///
                    scheme(s2color) ///
                    note("Rolling window QARDL(`p',`q')", ///
                        size(vsmall) color(gs8)) ///
                    name(qardl_rolling_beta_`vnum', replace)
            }
        }
        
        * Rolling Wald statistics
        capture confirm matrix e(rolling_wald_beta)
        if _rc == 0 {
            tempname rwald
            mat `rwald' = e(rolling_wald_beta)
            qui gen double rwald_beta = .
            forvalues i = 1/`nwin' {
                qui replace rwald_beta = `rwald'[`i', 1] in `i'
            }
            
            * Critical value lines
            local chi2_5 = invchi2tail((`ntau'-1)*`k', 0.05)
            
            twoway (line rwald_beta window, ///
                    lcolor("`c4'") lwidth(medium)) ///
                (function y = `chi2_5', range(1 `nwin') ///
                    lcolor("217 95 2") lpattern(dash) lwidth(thin)), ///
                title("{bf:Rolling Wald Statistic (Beta Constancy)}", ///
                    size(medium) color("0 51 102")) ///
                xtitle("Window", size(small)) ///
                ytitle("Wald Statistic", size(small)) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(small)) ///
                scheme(s2color) ///
                legend(label(1 "Wald stat") label(2 "5% critical value") ///
                    size(vsmall) rows(1)) ///
                note("Rolling window QARDL(`p',`q')", ///
                    size(vsmall) color(gs8)) ///
                name(qardl_rolling_wald, replace)
        }
    }
    
    restore
    
    di as txt _n
    di as res "  Graphs created successfully."
    di as txt "  Use {cmd:graph dir} to see all available graphs."
end
