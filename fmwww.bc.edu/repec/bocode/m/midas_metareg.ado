*! midas_metareg.ado — Bivariate meta-regression for DTA meta-analysis
*! Version 2.0.0  31mar2026
*! Author: Ben Adarkwa Dwamena, MD
*!
*! Adds study-level covariates to the bivariate model:
*!   logit(Se_i) = mu1 + beta1*X_i + u1i
*!   logit(Sp_i) = mu2 + beta2*X_i + u2i
*!
*! v2.0: For binary covariates, adds comparative SROC plot with
*!       subgroup summary points and confidence regions.

capture program drop midas_metareg
program define midas_metareg, eclass
    version 16
    
    #delimit ;
    syntax varlist(min=4 max=4 numeric) [if] [in],
        ID(varname)
        COVariates(varlist numeric)
        [SENonly
        SPEonly
        LEVEL(cilevel)
        NOGraph
        SAVEtable(string)
        NOIsily
        SUBESTimator(string)
        RPATH(string)
        STANdir(string)
        MODELfile(string)
        OUTPUTfile(string)
        CHains(integer 4)
        WARMup(integer 1000)
        ITER(integer 10000)
        THIN(integer 10)
        SEED(integer 12345)
        SUBCOVariance(string)
        *] ;
    #delimit cr
    
    if "`senonly'" != "" & "`speonly'" != "" {
        di as error "senonly and speonly are mutually exclusive"
        exit 198
    }
    
    * Subgroup estimator for binary SROC (default: mle)
    if "`subestimator'" == "" local subestimator "mle"
    if !inlist("`subestimator'", "mle", "inla", "hmc") {
        di as error "subestimator() must be one of: mle, inla, hmc"
        exit 198
    }
    
    * Build subgroup estimator option strings
    local inla_opts ""
    if "`rpath'" != "" local inla_opts `"rpath("`rpath'")"'
    
    local hmc_opts ""
    if "`standir'" != ""       local hmc_opts `"`hmc_opts' standir("`standir'")"'
    if "`modelfile'" != ""     local hmc_opts `"`hmc_opts' modelfile("`modelfile'")"'
    if "`outputfile'" != ""    local hmc_opts `"`hmc_opts' outputfile("`outputfile'")"'
    if "`subcovariance'" != "" local hmc_opts `"`hmc_opts' covariance(`subcovariance')"'
    local hmc_opts `"`hmc_opts' chains(`chains') warmup(`warmup') iter(`iter') thin(`thin') seed(`seed')"'
    
    tokenize `varlist'
    local tp `1'
    local fp `2'
    local fn `3'
    local tn `4'
    
    marksample touse
    
    * Count covariates
    local ncov: word count `covariates'
    
    di as text _n "{hline 70}"
    di as result "MIDAS Bivariate Meta-Regression"
    di as text "{hline 70}"
    di as text "Covariates: " as result "`covariates' (`ncov')"
    if "`senonly'" != "" di as text "Applied to: " as result "Sensitivity only"
    else if "`speonly'" != "" di as text "Applied to: " as result "Specificity only"
    else di as text "Applied to: " as result "Both Se and Sp"
    di as text "{hline 70}"
    
    * ============================================================
    * Check for binary covariate (for comparative SROC)
    * ============================================================
    
    local is_binary 0
    local bincov ""
    if `ncov' == 1 {
        local bincov: word 1 of `covariates'
        qui tab `bincov' if `touse'
        if r(r) == 2 {
            local is_binary 1
            qui levelsof `bincov' if `touse', local(binlevels)
        }
    }
    
    * ============================================================
    * Data preparation (mirrors midas_mle internals)
    * ============================================================
    
    preserve
    qui keep if `touse'
    qui count
    local nstud = r(N)
    
    * Study labels
    capture confirm string variable `id'
    if _rc {
        qui tostring `id', gen(_midas_studylabel)
    }
    else {
        qui gen _midas_studylabel = `id'
    }
    sort _midas_studylabel
    qui gen _midas_studyid = _n
    
    * Note: binary SROC uses original data directly (restore/re-preserve)
    
    * Create the long-format data for meglm
    qui gen _midas_dis1 = `tp' + `fn'
    qui gen _midas_dis0 = `tn' + `fp'
    
    qui gen _midas_dep1 = `tp'
    qui gen _midas_dep2 = `tn'
    qui gen _midas_denom1 = _midas_dis1
    qui gen _midas_denom2 = _midas_dis0
    
    qui reshape long _midas_dep _midas_denom, i(_midas_studyid) j(_midas_dis_status)
    
    * Interaction terms: covariate * disease status indicator
    qui gen _dis1 = (_midas_dis_status == 1)
    qui gen _dis2 = (_midas_dis_status == 2)
    
    * Build covariate interaction terms
    local cov_se_terms ""
    local cov_sp_terms ""
    
    foreach cv of local covariates {
        if "`speonly'" == "" {
            qui gen _cx_se_`cv' = _dis1 * `cv'
            local cov_se_terms "`cov_se_terms' _cx_se_`cv'"
        }
        if "`senonly'" == "" {
            qui gen _cx_sp_`cv' = _dis2 * `cv'
            local cov_sp_terms "`cov_sp_terms' _cx_sp_`cv'"
        }
    }
    
    local allcov "`cov_se_terms' `cov_sp_terms'"
    
    * ============================================================
    * Fit bivariate meta-regression via meglm
    * ============================================================
    
    di as text ""
    di as text "Fitting bivariate meta-regression model..."
    di as text ""
    
    * Base model: intercepts + covariates, random effects for Se and Sp
    #delimit ;
    capture noisily meglm _midas_dep _dis1 _dis2 `allcov', 
        nocons
        family(binomial _midas_denom) link(logit)
        || _midas_studyid: _dis1 _dis2, nocons cov(unstructured)
        intpoints(7)
        `noisily' ;
    #delimit cr
    
    if _rc {
        di as error "Meta-regression model failed to converge"
        restore
        exit _rc
    }
    
    * ============================================================
    * Extract and display results
    * ============================================================
    
    * Intercepts
    local mu1 = _b[_dis1]
    local mu2 = _b[_dis2]
    local se_mu1 = _se[_dis1]
    local se_mu2 = _se[_dis2]
    
    di as text _n "{hline 70}"
    di as result "Meta-Regression Results"
    di as text "{hline 70}"
    
    di as text ""
    di as text " Intercepts (baseline):"
    di as text "{hline 60}"
    di as text "  Parameter" _col(20) "Coef" _col(32) "SE" _col(42) "z" _col(50) "p" _col(58) "[95% CI]"
    di as text "{hline 60}"
    
    local z1 = `mu1'/`se_mu1'
    local p1 = 2*(1-normal(abs(`z1')))
    local lo1 = `mu1' - 1.96*`se_mu1'
    local hi1 = `mu1' + 1.96*`se_mu1'
    di as text "  logit Se" _col(16) as result %10.4f `mu1' _col(28) %8.4f `se_mu1' ///
        _col(40) %6.2f `z1' _col(48) %6.4f `p1' "  " %6.3f `lo1' " " %6.3f `hi1'
    
    local z2 = `mu2'/`se_mu2'
    local p2 = 2*(1-normal(abs(`z2')))
    local lo2 = `mu2' - 1.96*`se_mu2'
    local hi2 = `mu2' + 1.96*`se_mu2'
    di as text "  logit Sp" _col(16) as result %10.4f `mu2' _col(28) %8.4f `se_mu2' ///
        _col(40) %6.2f `z2' _col(48) %6.4f `p2' "  " %6.3f `lo2' " " %6.3f `hi2'
    
    * Covariate effects
    di as text ""
    di as text " Covariate effects:"
    di as text "{hline 60}"
    
    foreach cv of local covariates {
        if "`speonly'" == "" {
            local b_se_`cv' = _b[_cx_se_`cv']
            local se_bse_`cv' = _se[_cx_se_`cv']
            local z_se = `b_se_`cv''/`se_bse_`cv''
            local p_se = 2*(1-normal(abs(`z_se')))
            local lo_se = `b_se_`cv'' - 1.96*`se_bse_`cv''
            local hi_se = `b_se_`cv'' + 1.96*`se_bse_`cv''
            di as text "  `cv' -> Se" _col(16) as result %10.4f `b_se_`cv'' _col(28) %8.4f `se_bse_`cv'' ///
                _col(40) %6.2f `z_se' _col(48) %6.4f `p_se' "  " %6.3f `lo_se' " " %6.3f `hi_se'
            if `p_se' < 0.05 {
                di as text "    * Significant at 5% level"
            }
        }
        if "`senonly'" == "" {
            local b_sp_`cv' = _b[_cx_sp_`cv']
            local se_bsp_`cv' = _se[_cx_sp_`cv']
            local z_sp = `b_sp_`cv''/`se_bsp_`cv''
            local p_sp = 2*(1-normal(abs(`z_sp')))
            local lo_sp = `b_sp_`cv'' - 1.96*`se_bsp_`cv''
            local hi_sp = `b_sp_`cv'' + 1.96*`se_bsp_`cv''
            di as text "  `cv' -> Sp" _col(16) as result %10.4f `b_sp_`cv'' _col(28) %8.4f `se_bsp_`cv'' ///
                _col(40) %6.2f `z_sp' _col(48) %6.4f `p_sp' "  " %6.3f `lo_sp' " " %6.3f `hi_sp'
            if `p_sp' < 0.05 {
                di as text "    * Significant at 5% level"
            }
        }
    }
    di as text "{hline 60}"
    
    * Random effects — extract variance components from meglm
    * Stata 19.5 meglm stores RE params in e(b) under equation "/" with
    * column names like var(_dis1[...]), var(_dis2[...]), cov(...)
    * Values are already on the variance/covariance scale.
    
    local tau2_1 = .
    local tau2_2 = .
    local cov_re_12 = .
    
    * Method 1: Try /lns style (older Stata versions store log-SD)
    capture local tau2_1 = exp(_b[/lns1_1_1])^2
    capture local tau2_2 = exp(_b[/lns1_1_2])^2
    
    * Method 2: Scan e(b) for eq="/" columns with var()/cov() in the name
    * Stata 19.5 meglm stores these on variance/covariance scale directly
    if `tau2_1' >= . | `tau2_2' >= . {
        tempname eb_full
        mat `eb_full' = e(b)
        local eqnames: coleq `eb_full'
        local cnames: colnames `eb_full'
        local ncols = colsof(`eb_full')
        
        local var_count = 0
        forval j = 1/`ncols' {
            local eq: word `j' of `eqnames'
            local cn: word `j' of `cnames'
            if "`eq'" == "/" {
                if strpos("`cn'", "var(") == 1 {
                    local ++var_count
                    if `var_count' == 1 {
                        local tau2_1 = `eb_full'[1,`j']
                    }
                    else if `var_count' == 2 {
                        local tau2_2 = `eb_full'[1,`j']
                    }
                }
                else if strpos("`cn'", "cov(") == 1 {
                    local cov_re_12 = `eb_full'[1,`j']
                }
            }
        }
    }
    
    di as text ""
    di as text " Random effects (residual heterogeneity after regression):"
    di as text "{hline 60}"
    di as text _col(3) "tau2(logit Se)" _col(25) as result %8.4f `tau2_1'
    di as text _col(3) "tau2(logit Sp)" _col(25) as result %8.4f `tau2_2'
    di as text "{hline 60}"
    
    * Model fit
    local ll = e(ll)
    local aic = -2*`ll' + 2*(2 + `ncov'*2 + 3)
    local bic = -2*`ll' + ln(`nstud')*(2 + `ncov'*2 + 3)
    
    di as text ""
    di as text " Model fit:"
    di as text _col(3) "Log-likelihood" _col(25) as result %10.3f `ll'
    di as text _col(3) "AIC" _col(25) as result %10.3f `aic'
    di as text _col(3) "BIC" _col(25) as result %10.3f `bic'
    di as text _col(3) "N studies" _col(25) as result `nstud'
    di as text "{hline 70}"
    
    * ============================================================
    * Store results
    * ============================================================
    
    ereturn scalar ll = `ll'
    ereturn scalar AIC = `aic'
    ereturn scalar BIC = `bic'
    ereturn scalar N = `nstud'
    ereturn scalar ncov = `ncov'
    ereturn local covariates "`covariates'"
    ereturn local estimator "metareg"
    ereturn local package "midas"
    ereturn local cmd "midas_metareg"
    
    * ============================================================
    * Graphical output
    * ============================================================
    
    if "`nograph'" == "" & `ncov' == 1 {
    
        local cv: word 1 of `covariates'
        
        if `is_binary' {
            * ==========================================================
            * COMPARATIVE SROC PLOT for binary covariate
            * ==========================================================
            
            * We are inside the outer preserve. Restore first to get
            * back to original data, then re-preserve for the plot.
            restore
            preserve
            qui keep if `touse'
            
            * --- Fit separate models per subgroup ---
            local gi = 0
            foreach lev of local binlevels {
                local ++gi
                
                * Subgroup data
                qui count if `bincov' == `lev'
                local k_`gi' = r(N)
                
                * Get value label if available
                local vlname: value label `bincov'
                if "`vlname'" != "" {
                    local lab_`gi': label `vlname' `lev'
                }
                else {
                    local lab_`gi' "`bincov'=`lev'"
                }
                
                * -------------------------------------------
                * Fit bivariate model for this subgroup
                * -------------------------------------------
                * Save current state, subset, fit, extract, restore
                tempfile _sg_save
                qui save `_sg_save', replace
                
                qui keep if `bincov' == `lev'
                qui count
                local nk = r(N)
                
                if "`subestimator'" == "mle" {
                    * Direct meglm fit
                    qui gen _sid = _n
                    qui gen _dep1 = `tp'
                    qui gen _dep2 = `tn'
                    qui gen _den1 = `tp' + `fn'
                    qui gen _den2 = `tn' + `fp'
                    qui reshape long _dep _den, i(_sid) j(_ds)
                    qui gen _d1 = (_ds == 1)
                    qui gen _d2 = (_ds == 2)
                    
                    capture noisily qui meglm _dep _d1 _d2, nocons ///
                        family(binomial _den) link(logit) ///
                        || _sid: _d1 _d2, nocons cov(unstructured) ///
                        intpoints(7)
                    
                    if _rc {
                        di as text "  Note: MLE failed for subgroup `lab_`gi'' — skipping"
                        local mu1_`gi' = .
                        local mu2_`gi' = .
                        local se_mu1_`gi' = .
                        local se_mu2_`gi' = .
                        local cov12_`gi' = 0
                        local summ_se_`gi' = .
                        local summ_sp_`gi' = .
                        local summ_fpr_`gi' = .
                        local k_`gi' = `nk'
                        qui use `_sg_save', clear
                        continue
                    }
                    
                    * Extract summary operating point from meglm
                    local mu1_`gi' = _b[_d1]
                    local mu2_`gi' = _b[_d2]
                    local se_mu1_`gi' = _se[_d1]
                    local se_mu2_`gi' = _se[_d2]
                    
                    tempname vcov
                    mat `vcov' = e(V)
                    local cov12_`gi' = `vcov'[1,2]
                }
                else if "`subestimator'" == "inla" {
                    * Use midas inla for this subgroup
                    capture noisily {
                        midas inla `tp' `fp' `fn' `tn', id(`id') `inla_opts'
                    }
                    if _rc {
                        di as text "  Note: INLA failed for subgroup `lab_`gi'' — skipping"
                        local mu1_`gi' = .
                        local mu2_`gi' = .
                        local se_mu1_`gi' = .
                        local se_mu2_`gi' = .
                        local cov12_`gi' = 0
                        local summ_se_`gi' = .
                        local summ_sp_`gi' = .
                        local summ_fpr_`gi' = .
                        local k_`gi' = `nk'
                        qui use `_sg_save', clear
                        continue
                    }
                    
                    * Extract from midas inla e() results
                    local mu1_`gi' = e(b)[1,1]
                    local mu2_`gi' = e(b)[1,2]
                    local se_mu1_`gi' = sqrt(e(V)[1,1])
                    local se_mu2_`gi' = sqrt(e(V)[2,2])
                    local cov12_`gi' = e(V)[1,2]
                }
                else if "`subestimator'" == "hmc" {
                    * Use midas hmc for this subgroup
                    capture noisily {
                        midas hmc `tp' `fp' `fn' `tn', id(`id') `hmc_opts'
                    }
                    if _rc {
                        di as text "  Note: HMC failed for subgroup `lab_`gi'' — skipping"
                        local mu1_`gi' = .
                        local mu2_`gi' = .
                        local se_mu1_`gi' = .
                        local se_mu2_`gi' = .
                        local cov12_`gi' = 0
                        local summ_se_`gi' = .
                        local summ_sp_`gi' = .
                        local summ_fpr_`gi' = .
                        local k_`gi' = `nk'
                        qui use `_sg_save', clear
                        continue
                    }
                    
                    * Extract from midas hmc e() results
                    local mu1_`gi' = e(b)[1,1]
                    local mu2_`gi' = e(b)[1,2]
                    local se_mu1_`gi' = sqrt(e(V)[1,1])
                    local se_mu2_`gi' = sqrt(e(V)[2,2])
                    local cov12_`gi' = e(V)[1,2]
                }
                
                * Summary Se and Sp on probability scale
                local summ_se_`gi' = invlogit(`mu1_`gi'')
                local summ_sp_`gi' = invlogit(`mu2_`gi'')
                local summ_fpr_`gi' = 1 - `summ_sp_`gi''
                
                * Reload full subgroup data
                qui use `_sg_save', clear
            }
            
            * --- Build confidence and prediction ellipses via Mata ---
            local npts 100
            local ngrp = `gi'
            
            * RE covariance was extracted before restore (tau2_1, tau2_2 already set)
            * Extract cov from the original meglm e(b) — saved as cov_re_12
            * (tau2_1, tau2_2, cov_re_12 were set before the restore+preserve)
            
            * Check if at least one subgroup converged
            local any_converged = 0
            forval g = 1/`ngrp' {
                if `summ_se_`g'' < . {
                    local any_converged = 1
                }
            }
            
            if `any_converged' == 0 {
                di as text "  Note: No subgroups converged — skipping SROC plot"
            }
            else {
            
            mata: _midas_metareg_ellipses()
            
            * --- Construct the SROC plot ---
            
            * Determine colors for groups
            local col1 "blue"
            local col2 "red"
            local mcol1 "blue"
            local mcol2 "red"
            
            * Build summary table text for graph note
            * Format: Group | k | Se (95% CI) | Sp (95% CI) 
            local tabline1 ""
            local tabline2 ""
            
            forval g = 1/`ngrp' {
                if `summ_se_`g'' == . continue
                
                * Delta method CIs for Se and Sp
                local se_lo = invlogit(`mu1_`g'' - 1.96*`se_mu1_`g'')
                local se_hi = invlogit(`mu1_`g'' + 1.96*`se_mu1_`g'')
                local sp_lo = invlogit(`mu2_`g'' - 1.96*`se_mu2_`g'')
                local sp_hi = invlogit(`mu2_`g'' + 1.96*`se_mu2_`g'')
                
                local fse: di %4.2f `summ_se_`g''
                local fsp: di %4.2f `summ_sp_`g''
                local fse_lo: di %4.2f `se_lo'
                local fse_hi: di %4.2f `se_hi'
                local fsp_lo: di %4.2f `sp_lo'
                local fsp_hi: di %4.2f `sp_hi'
                local fk_g: di %3.0f `k_`g''
                
                local tabline`g' "`lab_`g'' (k=`fk_g'): Se=`fse' (`fse_lo'-`fse_hi'), Sp=`fsp' (`fsp_lo'-`fsp_hi')"
            }
            
            * --- Assemble the graph ---
            local plotcmds ""
            local legendord ""
            local li = 0
            
            forval g = 1/`ngrp' {
                if `summ_se_`g'' == . continue
                
                * 1) Prediction ellipse (wider, dashed line)
                local ++li
                local plotcmds "`plotcmds' (line _pell_se_`g' _pell_fpr_`g', lcolor(`col`g''%60) lwidth(medium) lpattern(dash) cmissing(n))"
                local legendord "`legendord' `li' `"`lab_`g'' 95% PR"'"
                
                * 2) Confidence ellipse (tighter, solid line)
                local ++li
                local plotcmds "`plotcmds' (line _cell_se_`g' _cell_fpr_`g', lcolor(`col`g'') lwidth(medthick) lpattern(solid) cmissing(n))"
                local legendord "`legendord' `li' `"`lab_`g'' 95% CR"'"
                
                * 3) Summary operating point
                local ++li
                local plotcmds "`plotcmds' (scatteri `summ_se_`g'' `summ_fpr_`g'', ms(D) msize(vlarge) mcolor(`mcol`g'') mlcolor(black) mlwidth(thin))"
                local legendord "`legendord' `li' `"`lab_`g'' summary"'"
            }
            
            * Build full note text
            local notetxt ""
            forval g = 1/`ngrp' {
                if "`tabline`g''" != "" {
                    if "`notetxt'" == "" {
                        local notetxt "`tabline`g''"
                    }
                    else {
                        local notetxt "`notetxt'" "`tabline`g''"
                    }
                }
            }
            
            #delimit ;
            twoway `plotcmds',
                xti("1 - Specificity (FPR)")
                yti("Sensitivity")
                yla(0(0.2)1, angle(horizontal) format(%3.1f))
                xla(0(0.2)1, format(%3.1f))
                xscale(range(0 1))
                yscale(range(0 1))
                aspectratio(1)
                legend(order(`legendord') pos(5) ring(0)
                    col(1) size(*.55) symxsize(*.7)
                    region(fcolor(white%90) lcolor(gs12)))
                title("Comparative SROC: Effect of `cv'", size(*.85))
                subtitle("Meta-regression, `nstud' studies", size(*.7))
                note(`"`tabline1'"' `"`tabline2'"', 
                    size(*.5) span)
                name(metareg_sroc, replace) ;
            #delimit cr
            
            } // end if any_converged
            
        }
        else {
            * ==========================================================
            * STANDARD BUBBLE PLOT for continuous covariates
            * ==========================================================
            
            * Compute study-level Se and Sp
            tempvar studysen studyspe studyn
            qui gen `studysen' = `tp'/(`tp'+`fn')
            qui gen `studyspe' = `tn'/(`tn'+`fp')
            qui gen `studyn' = `tp'+`fp'+`fn'+`tn'
            
            * Predicted values from regression
            tempvar predse predspe
            
            if "`speonly'" == "" {
                local b_se = _b[_cx_se_`cv']
                qui gen `predse' = invlogit(`mu1' + `b_se'*`cv')
            }
            if "`senonly'" == "" {
                local b_sp = _b[_cx_sp_`cv']
                qui gen `predspe' = invlogit(`mu2' + `b_sp'*`cv')
            }
            
            * Two-panel plot
            if "`speonly'" == "" & "`senonly'" == "" {
                #delimit ;
                twoway (scatter `studysen' `cv' [aw=`studyn'], ms(Oh) mc(blue%60))
                       (line `predse' `cv', sort lc(blue) lw(medthick))
                       (scatter `studyspe' `cv' [aw=`studyn'], ms(Dh) mc(red%60))
                       (line `predspe' `cv', sort lc(red) lw(medthick)),
                    legend(order(1 "Study Se" 2 "Predicted Se" 3 "Study Sp" 4 "Predicted Sp")
                        pos(6) row(2) size(*.65))
                    yti("Sensitivity / Specificity") xti("`cv'")
                    yla(0(0.2)1, angle(horizontal) format(%3.1f))
                    title("Meta-Regression: Effect of `cv'", size(*.85))
                    subtitle("Bivariate model, `nstud' studies", size(*.7))
                    name(metareg_bubble, replace) ;
                #delimit cr
            }
            else if "`speonly'" == "" {
                #delimit ;
                twoway (scatter `studysen' `cv' [aw=`studyn'], ms(Oh) mc(blue%60))
                       (line `predse' `cv', sort lc(blue) lw(medthick)),
                    legend(order(1 "Study Se" 2 "Predicted Se") pos(6) row(1) size(*.65))
                    yti("Sensitivity") xti("`cv'")
                    yla(0(0.2)1, angle(horizontal) format(%3.1f))
                    title("Meta-Regression: Effect of `cv' on Sensitivity", size(*.85))
                    name(metareg_bubble, replace) ;
                #delimit cr
            }
            else {
                #delimit ;
                twoway (scatter `studyspe' `cv' [aw=`studyn'], ms(Dh) mc(red%60))
                       (line `predspe' `cv', sort lc(red) lw(medthick)),
                    legend(order(1 "Study Sp" 2 "Predicted Sp") pos(6) row(1) size(*.65))
                    yti("Specificity") xti("`cv'")
                    yla(0(0.2)1, angle(horizontal) format(%3.1f))
                    title("Meta-Regression: Effect of `cv' on Specificity", size(*.85))
                    name(metareg_bubble, replace) ;
                #delimit cr
            }
        }
    }
    
    * ============================================================
    * Save LaTeX table if requested
    * ============================================================
    
    if "`savetable'" != "" {
        capture file close _mrt
        file open _mrt using "`savetable'", write replace
        file write _mrt "% Auto-generated by midas metareg" _n
        file write _mrt "\begin{table}[htbp]" _n
        file write _mrt "\centering" _n
        file write _mrt "\caption{Bivariate Meta-Regression Results}" _n
        file write _mrt "\label{tab:metareg}" _n
        file write _mrt "\begin{tabular}{lrrrrr}" _n
        file write _mrt "\toprule" _n
        file write _mrt "Parameter & Coef. & SE & $z$ & $p$ & 95\% CI \\" _n
        file write _mrt "\midrule" _n
        
        * Intercepts
        file write _mrt %~20s "logit Se" " & " %8.4f (`mu1') " & " %8.4f (`se_mu1') ///
            " & " %6.2f (`z1') " & " %6.4f (`p1') " & " ///
            %6.3f (`lo1') " to " %6.3f (`hi1') " \\" _n
        file write _mrt %~20s "logit Sp" " & " %8.4f (`mu2') " & " %8.4f (`se_mu2') ///
            " & " %6.2f (`z2') " & " %6.4f (`p2') " & " ///
            %6.3f (`lo2') " to " %6.3f (`hi2') " \\" _n
        file write _mrt "\midrule" _n
        
        foreach cv of local covariates {
            if "`speonly'" == "" {
                local b = `b_se_`cv''
                local s = `se_bse_`cv''
                local z = `b'/`s'
                local p = 2*(1-normal(abs(`z')))
                local lo = `b' - 1.96*`s'
                local hi = `b' + 1.96*`s'
                local star ""
                if `p' < 0.05 local star "*"
                file write _mrt %~20s "`cv' $\to$ Se" " & " %8.4f (`b') " & " %8.4f (`s') ///
                    " & " %6.2f (`z') " & " %6.4f (`p') "`star'" " & " ///
                    %6.3f (`lo') " to " %6.3f (`hi') " \\" _n
            }
            if "`senonly'" == "" {
                local b = `b_sp_`cv''
                local s = `se_bsp_`cv''
                local z = `b'/`s'
                local p = 2*(1-normal(abs(`z')))
                local lo = `b' - 1.96*`s'
                local hi = `b' + 1.96*`s'
                local star ""
                if `p' < 0.05 local star "*"
                file write _mrt %~20s "`cv' $\to$ Sp" " & " %8.4f (`b') " & " %8.4f (`s') ///
                    " & " %6.2f (`z') " & " %6.4f (`p') "`star'" " & " ///
                    %6.3f (`lo') " to " %6.3f (`hi') " \\" _n
            }
        }
        
        file write _mrt "\midrule" _n
        file write _mrt %~20s "$\tau^2$(logit Se)" " & \multicolumn{5}{c}{" %8.4f (`tau2_1') "} \\" _n
        file write _mrt %~20s "$\tau^2$(logit Sp)" " & \multicolumn{5}{c}{" %8.4f (`tau2_2') "} \\" _n
        file write _mrt "\midrule" _n
        file write _mrt %~20s "Log-likelihood" " & \multicolumn{5}{c}{" %10.3f (`ll') "} \\" _n
        file write _mrt %~20s "AIC" " & \multicolumn{5}{c}{" %10.3f (`aic') "} \\" _n
        file write _mrt %~20s "BIC" " & \multicolumn{5}{c}{" %10.3f (`bic') "} \\" _n
        file write _mrt "\bottomrule" _n
        file write _mrt "\end{tabular}" _n
        file write _mrt "\end{table}" _n
        file close _mrt
        di as text "  [TEX] `savetable'"
    }
    
    restore
    
end


* ==============================================================================
* Mata helper: compute confidence ellipses for subgroups
* ==============================================================================

version 16
mata:
void _midas_metareg_ellipses()
{
    real scalar ngrp, npts, g, i, N
    real scalar mu1, mu2, se_mu1, se_mu2, cov12, chi2_crit
    real scalar tau2_1, tau2_2, cov_re_12
    real matrix Sigma_c, Sigma_p, Chol_c, Chol_p, ell_c, ell_p
    real colvector theta
    real rowvector uv
    string scalar vname
    
    npts = 100
    chi2_crit = invchi2(2, 0.95)  // 5.991 for 95% CI
    
    ngrp   = strtoreal(st_local("ngrp"))
    tau2_1 = strtoreal(st_local("tau2_1"))
    tau2_2 = strtoreal(st_local("tau2_2"))
    cov_re_12 = strtoreal(st_local("cov_re_12"))
    
    // Angular grid — closed polygon (101 points)
    theta = rangen(0, 2*pi(), npts+1)
    
    // Ensure enough observations
    N = st_nobs()
    if (N < npts + 1) {
        st_addobs(npts + 1 - N)
        N = npts + 1
    }
    
    for (g=1; g<=ngrp; g++) {
        
        mu1 = strtoreal(st_local("mu1_" + strofreal(g)))
        mu2 = strtoreal(st_local("mu2_" + strofreal(g)))
        
        if (mu1 >= . | mu2 >= .) continue
        
        se_mu1 = strtoreal(st_local("se_mu1_" + strofreal(g)))
        se_mu2 = strtoreal(st_local("se_mu2_" + strofreal(g)))
        cov12  = strtoreal(st_local("cov12_" + strofreal(g)))
        
        // -------------------------------------------------------
        // Confidence ellipse: VCE of (logit_se, logit_sp) means
        // -------------------------------------------------------
        Sigma_c = (se_mu1^2, cov12 \ cov12, se_mu2^2)
        
        if (det(Sigma_c) <= 0 | se_mu1 <= 0 | se_mu2 <= 0) continue
        
        Chol_c = cholesky(Sigma_c)
        
        ell_c = J(npts+1, 2, .)
        for (i=1; i<=npts+1; i++) {
            uv = (cos(theta[i]), sin(theta[i]))
            ell_c[i,1] = mu1 + sqrt(chi2_crit) * (Chol_c[1,1]*uv[1] + Chol_c[1,2]*uv[2])
            ell_c[i,2] = mu2 + sqrt(chi2_crit) * (Chol_c[2,1]*uv[1] + Chol_c[2,2]*uv[2])
        }
        
        ell_c[,1] = invlogit(ell_c[,1])
        ell_c[,2] = 1 :- invlogit(ell_c[,2])
        
        // Store confidence ellipse
        vname = "_cell_se_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_c[,1])
        
        vname = "_cell_fpr_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_c[,2])
        
        // -------------------------------------------------------
        // Prediction ellipse: VCE of means + residual heterogeneity
        // -------------------------------------------------------
        if (tau2_1 >= . | tau2_2 >= . | tau2_1 <= 0 | tau2_2 <= 0) {
            // Create empty variables so twoway doesn't error
            vname = "_pell_se_" + strofreal(g)
            (void) st_addvar("double", vname)
            vname = "_pell_fpr_" + strofreal(g)
            (void) st_addvar("double", vname)
            continue
        }
        
        // Use RE covariance if available, else 0
        if (cov_re_12 >= .) cov_re_12 = 0
        
        Sigma_p = (se_mu1^2 + tau2_1, cov12 + cov_re_12 \
                   cov12 + cov_re_12, se_mu2^2 + tau2_2)
        
        if (det(Sigma_p) <= 0) {
            vname = "_pell_se_" + strofreal(g)
            (void) st_addvar("double", vname)
            vname = "_pell_fpr_" + strofreal(g)
            (void) st_addvar("double", vname)
            continue
        }
        
        Chol_p = cholesky(Sigma_p)
        
        ell_p = J(npts+1, 2, .)
        for (i=1; i<=npts+1; i++) {
            uv = (cos(theta[i]), sin(theta[i]))
            ell_p[i,1] = mu1 + sqrt(chi2_crit) * (Chol_p[1,1]*uv[1] + Chol_p[1,2]*uv[2])
            ell_p[i,2] = mu2 + sqrt(chi2_crit) * (Chol_p[2,1]*uv[1] + Chol_p[2,2]*uv[2])
        }
        
        ell_p[,1] = invlogit(ell_p[,1])
        ell_p[,2] = 1 :- invlogit(ell_p[,2])
        
        // Store prediction ellipse
        vname = "_pell_se_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_p[,1])
        
        vname = "_pell_fpr_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_p[,2])
    }
}
end
