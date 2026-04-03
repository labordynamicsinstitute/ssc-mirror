*! midas_subgroup.ado — Stratified subgroup analysis for DTA meta-analysis
*! Version 2.0.0  31mar2026
*! Author: Ben Adarkwa Dwamena, MD
*!
*! v2.0: Comparative SROC plot shows summary operating points with
*!       confidence regions and prediction regions (no study-level points).
*!       Summary comparison table embedded in graph.

capture program drop midas_subgroup
program define midas_subgroup, rclass
    version 16
    
    #delimit ;
    syntax varlist(min=4 max=4 numeric) [if] [in],
        ID(varname)
        BY(varname)
        [ESTimator(string)
        LEVEL(cilevel)
        HETstats
        HSROC
        NOGraph
        SAVEtable(string)
        PLOTtype(string)
        RPATH(string)
        STANdir(string)
        MODELfile(string)
        OUTPUTfile(string)
        CHains(integer 4)
        WARMup(integer 1000)
        ITER(integer 10000)
        THIN(integer 10)
        SEED(integer 12345)
        COVariance(string)
        *] ;
    #delimit cr
    
    if "`estimator'" == "" local estimator "mle"
    if !inlist("`estimator'", "mle", "qrsim", "hmc", "inla") {
        di as error "estimator() must be one of: mle, qrsim, hmc, inla"
        exit 198
    }
    if "`plottype'" == "" local plottype "sroc"
    
    * Build estimator-specific option strings
    local inla_opts ""
    if "`rpath'" != "" local inla_opts `"rpath("`rpath'")"'
    
    local hmc_opts ""
    if "`standir'" != ""    local hmc_opts `"`hmc_opts' standir("`standir'")"'
    if "`modelfile'" != ""  local hmc_opts `"`hmc_opts' modelfile("`modelfile'")"'
    if "`outputfile'" != "" local hmc_opts `"`hmc_opts' outputfile("`outputfile'")"'
    if "`covariance'" != "" local hmc_opts `"`hmc_opts' covariance(`covariance')"'
    local hmc_opts `"`hmc_opts' chains(`chains') warmup(`warmup') iter(`iter') thin(`thin') seed(`seed')"'
    
    tokenize `varlist'
    local tp `1'
    local fp `2'
    local fn `3'
    local tn `4'
    
    marksample touse
    
    * Get subgroup levels
    qui levelsof `by' if `touse', local(groups)
    local ngroups: word count `groups'
    
    if `ngroups' < 2 {
        di as error "by() variable must have at least 2 levels"
        exit 198
    }
    if `ngroups' > 10 {
        di as error "by() variable has `ngroups' levels — maximum is 10"
        exit 198
    }
    
    * ============================================================
    * Run estimation for each subgroup
    * ============================================================
    
    di as text _n "{hline 70}"
    di as result "MIDAS Subgroup Analysis"
    di as text "{hline 70}"
    di as text "Estimator:  " as result "`estimator'"
    di as text "Subgroups:  " as result "`ngroups' levels of `by'"
    di as text "{hline 70}"
    
    local grpnames ""
    local gi = 0
    
    foreach g of local groups {
        local ++gi
        
        * Determine group label
        local glabel "`g'"
        capture label list `: value label `by''
        if !_rc {
            local glabel: label (`by') `g'
        }
        local grpnames "`grpnames' `glabel'"
        
        di as text _n "{hline 50}"
        di as result "  Subgroup `gi': `by' = `glabel' (`g')"
        di as text "{hline 50}"
        
        preserve
        qui keep if `touse' & `by' == `g'
        qui count
        local ng = r(N)
        
        if `ng' < 4 {
            di as error "  Subgroup `glabel' has only `ng' studies — skipping (need >= 4)"
            scalar _sen_`gi' = .
            scalar _spe_`gi' = .
            scalar _lrp_`gi' = .
            scalar _lrn_`gi' = .
            scalar _dor_`gi' = .
            scalar _senlo_`gi' = .
            scalar _senhi_`gi' = .
            scalar _spelo_`gi' = .
            scalar _spehi_`gi' = .
            scalar _v1_`gi' = .
            scalar _v2_`gi' = .
            scalar _corr_`gi' = .
            scalar _nstud_`gi' = `ng'
            * Fixed-effects VCE for ellipses
            scalar _se_mu1_`gi' = .
            scalar _se_mu2_`gi' = .
            scalar _cov_mu12_`gi' = .
            restore
            continue
        }
        
        * Run the estimator
        capture noisily {
            if "`estimator'" == "mle" {
                midas mle `tp' `fp' `fn' `tn', id(`id') `hetstats' `hsroc'
            }
            else if "`estimator'" == "qrsim" {
                midas qrsim `tp' `fp' `fn' `tn', id(`id') simulation(halton) draws(200) burn(50)
            }
            else if "`estimator'" == "hmc" {
                midas hmc `tp' `fp' `fn' `tn', id(`id') `hmc_opts' `options'
            }
            else if "`estimator'" == "inla" {
                midas inla `tp' `fp' `fn' `tn', id(`id') `inla_opts' `options'
            }
        }
        
        if _rc == 0 {
            * Extract summary results from e()
            scalar _sen_`gi'   = e(bsum)[1,1]
            scalar _spe_`gi'   = e(bsum)[1,2]
            scalar _dor_`gi'   = e(bsum)[1,3]
            scalar _lrp_`gi'   = e(bsum)[1,4]
            scalar _lrn_`gi'   = e(bsum)[1,5]
            scalar _senlo_`gi' = e(Vsum)[1,5]
            scalar _senhi_`gi' = e(Vsum)[1,6]
            scalar _spelo_`gi' = e(Vsum)[2,5]
            scalar _spehi_`gi' = e(Vsum)[2,6]
            
            * Random effects: between-study variance components
            scalar _v1_`gi'    = e(b)[1,3]   // varlogitsen
            scalar _v2_`gi'    = e(b)[1,4]   // varlogitspe
            scalar _corr_`gi'  = e(b)[1,6]   // corrlogits
            scalar _nstud_`gi' = e(N)
            
            * Fixed effects: logit means and their VCE (for confidence ellipses)
            * logitsen = e(b)[1,1], logitspe = e(b)[1,2]
            scalar _mu1_`gi'   = e(b)[1,1]   // logit(Se)
            scalar _mu2_`gi'   = e(b)[1,2]   // logit(Sp)
            
            * Standard errors of logit means from e(V)
            * e(V) is the full 6x6 matrix; positions 1,2 are logitsen, logitspe
            tempname _Vfull_`gi'
            mat `_Vfull_`gi'' = e(V)
            scalar _se_mu1_`gi'  = sqrt(`_Vfull_`gi''[1,1])
            scalar _se_mu2_`gi'  = sqrt(`_Vfull_`gi''[2,2])
            scalar _cov_mu12_`gi' = `_Vfull_`gi''[1,2]
            
            * Store estimates
            estimates store _midas_sg`gi'
        }
        else {
            di as error "  Estimation failed for subgroup `glabel'"
            scalar _sen_`gi' = .
            scalar _spe_`gi' = .
            scalar _lrp_`gi' = .
            scalar _lrn_`gi' = .
            scalar _dor_`gi' = .
            scalar _senlo_`gi' = .
            scalar _senhi_`gi' = .
            scalar _spelo_`gi' = .
            scalar _spehi_`gi' = .
            scalar _v1_`gi' = .
            scalar _v2_`gi' = .
            scalar _corr_`gi' = .
            scalar _nstud_`gi' = `ng'
            scalar _se_mu1_`gi' = .
            scalar _se_mu2_`gi' = .
            scalar _cov_mu12_`gi' = .
        }
        
        restore
    }
    
    * ============================================================
    * Summary comparison table (console)
    * ============================================================
    
    di as text _n(2) "{hline 70}"
    di as result "SUBGROUP COMPARISON"
    di as text "{hline 70}"
    di as text ""
    di as text _col(3) "Subgroup" _col(18) "k" _col(25) "Se" _col(37) ///
        "Sp" _col(49) "LR+" _col(58) "LR-" _col(67) "DOR"
    di as text "{hline 70}"
    
    tempname sgmat
    mat `sgmat' = J(`ngroups', 7, .)
    
    forvalues gi = 1/`ngroups' {
        local gname: word `gi' of `grpnames'
        local nk: di %3.0f _nstud_`gi'
        local se: di %6.4f _sen_`gi'
        local sp: di %6.4f _spe_`gi'
        local lr: di %6.2f _lrp_`gi'
        local ln: di %6.4f _lrn_`gi'
        local dr: di %6.2f _dor_`gi'
        
        di as text _col(3) "`gname'" _col(18) as result "`nk'" _col(23) "`se'" ///
            _col(35) "`sp'" _col(47) "`lr'" _col(56) "`ln'" _col(65) "`dr'"
        
        mat `sgmat'[`gi',1] = _nstud_`gi'
        mat `sgmat'[`gi',2] = _sen_`gi'
        mat `sgmat'[`gi',3] = _spe_`gi'
        mat `sgmat'[`gi',4] = _lrp_`gi'
        mat `sgmat'[`gi',5] = _lrn_`gi'
        mat `sgmat'[`gi',6] = _dor_`gi'
    }
    di as text "{hline 70}"
    
    * Store return results
    return matrix subgroup = `sgmat'
    return scalar ngroups = `ngroups'
    return local groups "`groups'"
    return local grpnames "`grpnames'"
    return local by "`by'"
    return local estimator "`estimator'"
    
    * ============================================================
    * Comparative SROC Plot
    * ============================================================
    
    if "`nograph'" == "" & "`plottype'" == "sroc" {
        
        * Pass parameters to Mata for ellipse construction
        * Mata needs: ngroups, and per group: mu1, mu2, se_mu1, se_mu2, cov_mu12,
        *             v1 (tau2_se), v2 (tau2_sp), corr (rho_re)
        
        preserve
        qui keep if `touse'
        
        local ngrp = `ngroups'
        
        * Collect parameters into locals for Mata
        forvalues gi = 1/`ngrp' {
            local mu1_`gi'      = _mu1_`gi'
            local mu2_`gi'      = _mu2_`gi'
            local se_mu1_`gi'   = _se_mu1_`gi'
            local se_mu2_`gi'   = _se_mu2_`gi'
            local cov_mu12_`gi' = _cov_mu12_`gi'
            local tau2se_`gi'   = _v1_`gi'
            local tau2sp_`gi'   = _v2_`gi'
            local rho_re_`gi'   = _corr_`gi'
            local summ_se_`gi'  = _sen_`gi'
            local summ_sp_`gi'  = _spe_`gi'
            local k_`gi'        = _nstud_`gi'
        }
        
        * Build ellipses via Mata
        mata: _midas_subgroup_ellipses()
        
        * --- Colors ---
        local colors   "blue red dkgreen orange purple cranberry"
        
        * --- Build plot commands ---
        local plotcmds ""
        local legendord ""
        local li = 0
        
        forvalues gi = 1/`ngrp' {
            local gname: word `gi' of `grpnames'
            local col: word `gi' of `colors'
            
            if `summ_se_`gi'' >= . continue
            
            local summ_fpr = 1 - `summ_sp_`gi''
            
            * 1) Prediction ellipse (wider, dashed line, no fill)
            local ++li
            local plotcmds "`plotcmds' (line _pell_se_`gi' _pell_fpr_`gi', lcolor(`col'%60) lwidth(medium) lpattern(dash) cmissing(n))"
            local legendord "`legendord' `li' `"`gname' 95% PR"'"
            
            * 2) Confidence ellipse (tighter, solid line, no fill)
            local ++li
            local plotcmds "`plotcmds' (line _cell_se_`gi' _cell_fpr_`gi', lcolor(`col') lwidth(medthick) lpattern(solid) cmissing(n))"
            local legendord "`legendord' `li' `"`gname' 95% CR"'"
            
            * 3) Summary operating point
            local ++li
            local plotcmds "`plotcmds' (scatteri `summ_se_`gi'' `summ_fpr', ms(D) msize(vlarge) mcolor(`col') mlcolor(black) mlwidth(thin))"
            local legendord "`legendord' `li' `"`gname' summary"'"
            
            * Build note line — compute CIs from logit means + SEs
            local se_lo = invlogit(`mu1_`gi'' - 1.96*`se_mu1_`gi'')
            local se_hi = invlogit(`mu1_`gi'' + 1.96*`se_mu1_`gi'')
            local sp_lo = invlogit(`mu2_`gi'' - 1.96*`se_mu2_`gi'')
            local sp_hi = invlogit(`mu2_`gi'' + 1.96*`se_mu2_`gi'')
            
            local fse: di %4.2f `summ_se_`gi''
            local fsp: di %4.2f `summ_sp_`gi''
            local fse_lo: di %4.2f `se_lo'
            local fse_hi: di %4.2f `se_hi'
            local fsp_lo: di %4.2f `sp_lo'
            local fsp_hi: di %4.2f `sp_hi'
            local fk: di %3.0f `k_`gi''
            local flrp: di %5.1f scalar(_lrp_`gi')
            local flrn: di %5.3f scalar(_lrn_`gi')
            local fdor: di %5.2f scalar(_dor_`gi')
            
            local tabline`gi' "`gname' (k=`fk'): Se=`fse' (`fse_lo',`fse_hi') Sp=`fsp' (`fsp_lo',`fsp_hi') LR+=`flrp' LR-=`flrn' DOR=`fdor'"
        }
        
        * Assemble note lines
        local notelines ""
        forvalues gi = 1/`ngrp' {
            if "`tabline`gi''" != "" {
                local notelines `"`notelines' `"`tabline`gi''"'"'
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
            title("Comparative SROC: Subgroup Analysis by `by'", size(*.85))
            subtitle("Estimator: `estimator', `ngroups' subgroups", size(*.7))
            note(`notelines', size(*.5) span)
            name(subgroup_sroc, replace) ;
        #delimit cr
        
        restore
    }
    
    * ============================================================
    * Save LaTeX table if requested
    * ============================================================
    
    if "`savetable'" != "" {
        file open _sgt using "`savetable'", write replace
        file write _sgt "% Auto-generated by midas subgroup" _n
        file write _sgt "\begin{table}[htbp]" _n
        file write _sgt "\centering" _n
        file write _sgt "\caption{Subgroup Analysis by `by' (`estimator')}" _n
        file write _sgt "\label{tab:subgroup_`by'}" _n
        file write _sgt "\begin{tabular}{lrrrrrr}" _n
        file write _sgt "\toprule" _n
        file write _sgt "Subgroup & $k$ & Se & Sp & LR+ & LR$-$ & DOR \\" _n
        file write _sgt "\midrule" _n
        
        forvalues gi = 1/`ngroups' {
            local gname: word `gi' of `grpnames'
            local nk: di %3.0f _nstud_`gi'
            local se: di %6.4f _sen_`gi'
            local sp: di %6.4f _spe_`gi'
            local lr: di %6.2f _lrp_`gi'
            local ln: di %6.4f _lrn_`gi'
            local dr: di %6.2f _dor_`gi'
            file write _sgt "`gname' & `nk' & `se' & `sp' & `lr' & `ln' & `dr' \\" _n
        }
        
        file write _sgt "\bottomrule" _n
        file write _sgt "\end{tabular}" _n
        file write _sgt "\end{table}" _n
        file close _sgt
        di as text "  [TEX] `savetable'"
    }
    
    * Clean up stored estimates and scalars
    forvalues gi = 1/`ngroups' {
        capture estimates drop _midas_sg`gi'
        capture scalar drop _sen_`gi' _spe_`gi' _lrp_`gi' _lrn_`gi' _dor_`gi'
        capture scalar drop _senlo_`gi' _senhi_`gi' _spelo_`gi' _spehi_`gi'
        capture scalar drop _v1_`gi' _v2_`gi' _corr_`gi' _nstud_`gi'
        capture scalar drop _mu1_`gi' _mu2_`gi'
        capture scalar drop _se_mu1_`gi' _se_mu2_`gi' _cov_mu12_`gi'
    }
end


* ==============================================================================
* Mata helper: compute confidence and prediction ellipses for each subgroup
* ==============================================================================

version 16
mata:
void _midas_subgroup_ellipses()
{
    real scalar ngrp, npts, g, i, N
    real scalar mu1, mu2, se_mu1, se_mu2, cov_mu12
    real scalar tau2se, tau2sp, rho_re, cov_re
    real scalar chi2_crit
    real matrix Sigma_c, Sigma_p, Chol_c, Chol_p
    real matrix ell_c, ell_p
    real colvector theta
    real rowvector uv
    string scalar vname
    
    npts = 100
    chi2_crit = invchi2(2, 0.95)  // 5.991 for 95% confidence
    
    ngrp = strtoreal(st_local("ngrp"))
    
    // Angular grid — closed polygon (npts+1 points)
    theta = rangen(0, 2*pi(), npts+1)
    
    // Ensure dataset has enough rows
    N = st_nobs()
    if (N < npts + 1) {
        st_addobs(npts + 1 - N)
        N = npts + 1
    }
    
    for (g=1; g<=ngrp; g++) {
        
        mu1 = strtoreal(st_local("mu1_" + strofreal(g)))
        mu2 = strtoreal(st_local("mu2_" + strofreal(g)))
        
        if (mu1 >= . | mu2 >= .) continue
        
        se_mu1   = strtoreal(st_local("se_mu1_" + strofreal(g)))
        se_mu2   = strtoreal(st_local("se_mu2_" + strofreal(g)))
        cov_mu12 = strtoreal(st_local("cov_mu12_" + strofreal(g)))
        tau2se   = strtoreal(st_local("tau2se_" + strofreal(g)))
        tau2sp   = strtoreal(st_local("tau2sp_" + strofreal(g)))
        rho_re   = strtoreal(st_local("rho_re_" + strofreal(g)))
        
        // -------------------------------------------------------
        // Confidence ellipse: VCE of (logit_se, logit_sp) means
        // -------------------------------------------------------
        Sigma_c = (se_mu1^2, cov_mu12 \ cov_mu12, se_mu2^2)
        
        // Guard against non-positive-definite
        if (det(Sigma_c) <= 0 | se_mu1 <= 0 | se_mu2 <= 0) {
            printf("{txt}  Note: confidence ellipse not available for group %g\n", g)
            continue
        }
        
        Chol_c = cholesky(Sigma_c)
        
        ell_c = J(npts+1, 2, .)
        for (i=1; i<=npts+1; i++) {
            uv = (cos(theta[i]), sin(theta[i]))
            ell_c[i,1] = mu1 + sqrt(chi2_crit) * (Chol_c[1,1]*uv[1] + Chol_c[1,2]*uv[2])
            ell_c[i,2] = mu2 + sqrt(chi2_crit) * (Chol_c[2,1]*uv[1] + Chol_c[2,2]*uv[2])
        }
        
        // Transform to probability scale: Se = invlogit, FPR = 1 - invlogit
        ell_c[,1] = invlogit(ell_c[,1])
        ell_c[,2] = 1 :- invlogit(ell_c[,2])
        
        // Store confidence ellipse variables
        vname = "_cell_se_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_c[,1])
        
        vname = "_cell_fpr_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_c[,2])
        
        // -------------------------------------------------------
        // Prediction ellipse: VCE of means + between-study variance
        // -------------------------------------------------------
        if (tau2se >= . | tau2sp >= . | tau2se <= 0 | tau2sp <= 0) {
            printf("{txt}  Note: prediction ellipse not available for group %g\n", g)
            // Still create empty variables so twoway doesn't error
            vname = "_pell_se_" + strofreal(g)
            (void) st_addvar("double", vname)
            vname = "_pell_fpr_" + strofreal(g)
            (void) st_addvar("double", vname)
            continue
        }
        
        cov_re = rho_re * sqrt(tau2se * tau2sp)
        
        // Prediction variance = sampling var of mean + between-study var
        Sigma_p = (se_mu1^2 + tau2se, cov_mu12 + cov_re \ 
                   cov_mu12 + cov_re, se_mu2^2 + tau2sp)
        
        if (det(Sigma_p) <= 0) {
            printf("{txt}  Note: prediction ellipse not positive definite for group %g\n", g)
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
        
        // Transform to probability scale
        ell_p[,1] = invlogit(ell_p[,1])
        ell_p[,2] = 1 :- invlogit(ell_p[,2])
        
        // Store prediction ellipse variables
        vname = "_pell_se_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_p[,1])
        
        vname = "_pell_fpr_" + strofreal(g)
        (void) st_addvar("double", vname)
        st_store((1::npts+1), vname, ell_p[,2])
    }
}
end
