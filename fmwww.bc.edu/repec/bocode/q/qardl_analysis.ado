*! qardl_analysis v1.0.0 - Advanced post-estimation analysis for QARDL
*! Asymmetry diagnostics, pairwise tests, and professional visualizations
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define qardl_analysis
    version 14.0
    
    syntax [, NOSUMmary NOGraph NOPAIRwise]
    
    * Check estimation results exist
    if "`e(cmd)'" != "qardl" {
        di as error "qardl estimation results not found"
        di as error "run {cmd:qardl} first, then {cmd:qardl_analysis}"
        exit 301
    }
    
    * Extract stored results
    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    local nobs = e(N)
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"
    
    tempname beta beta_cov phi phi_cov gamma gamma_cov tau_vec
    mat `beta' = e(beta)
    mat `beta_cov' = e(beta_cov)
    mat `phi' = e(phi)
    mat `phi_cov' = e(phi_cov)
    mat `gamma' = e(gamma)
    mat `gamma_cov' = e(gamma_cov)
    mat `tau_vec' = e(tau)
    
    * ================================================================
    * Color palette: professional academic palette
    * ================================================================
    * Main palette: ColorBrewer "Set1" style - vivid & distinguishable
    local c_blue    "55 126 184"
    local c_red     "228 26 28"
    local c_green   "77 175 74"
    local c_purple  "152 78 163"
    local c_orange  "255 127 0"
    local c_gold    "255 215 0"
    local c_teal    "0 139 139"
    local c_brown   "166 86 40"
    
    * Derived palette for quantile shading (cool to warm)
    local c_q1   "44 123 182"       // Deep blue  (lower tail)
    local c_q2   "102 194 165"      // Teal       (lower-mid)
    local c_q3   "120 120 120"      // Gray       (median)
    local c_q4   "253 174 97"       // Orange     (upper-mid)
    local c_q5   "215 48 39"        // Red        (upper tail)
    
    * ================================================================
    *  PART 0: Quantile Cointegration Summary
    * ================================================================
    if "`nosummary'" == "" {
        di as txt _n
        di as txt "{hline 78}"
        di as res _col(8) "{bf:QUANTILE COINTEGRATION SUMMARY}"
        di as txt "{hline 78}"
        di as txt "  Dep. var: `depvar'    Model: QARDL(`p',`q')    Obs: `nobs'    Quantiles: `ntau'"
        di as txt "{hline 78}"
        di as txt "  {ralign 10:Variable}" _c
        di as txt "  {ralign 10:W(beta)}" _c
        di as txt "  {ralign 8:p-val}" _c
        di as txt "  {ralign 10:W(gamma)}" _c
        di as txt "  {ralign 8:p-val}" _c
        di as txt "  {ralign 10:rho(med)}" _c
        di as txt "  {ralign 8:Signal}" _c
        di as txt "  {ralign 10:Verdict}"
        di as txt "{hline 78}"
        
        * Median quantile index
        local med_idx = ceil(`ntau' / 2)
        
        * Compute median rho
        local sum_phi_med = 0
        forvalues i = 1/`p' {
            local phi_idx = (`med_idx' - 1) * `p' + `i'
            if `phi_idx' <= rowsof(`phi') {
                local sum_phi_med = `sum_phi_med' + `phi'[`phi_idx', 1]
            }
        }
        local rho_med = `sum_phi_med' - 1
        
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            
            * ------ Per-variable Wald for beta constancy ------
            * H0: beta_v(tau_1) = beta_v(tau_2) = ... = beta_v(tau_T)
            * R is (ntau-1) x ntau: each row tests tau_t - tau_1 = 0
            local wb_stat = .
            local wb_pval = .
            local wb_df = `ntau' - 1
            capture {
                tempname Rv bv RvVRv
                mat `Rv' = J(`wb_df', `ntau', 0)
                forvalues tt = 2/`ntau' {
                    local rr = `tt' - 1
                    * Row rr: coefficient at tau_tt minus coefficient at tau_1
                    local col1 = 1
                    local col_tt = `tt'
                    mat `Rv'[`rr', `col1'] = -1
                    mat `Rv'[`rr', `col_tt'] = 1
                }
                
                * Extract beta_v across quantiles and its covariance
                tempname bvec bvcov
                mat `bvec' = J(`ntau', 1, 0)
                mat `bvcov' = J(`ntau', `ntau', 0)
                forvalues ti = 1/`ntau' {
                    local idx_i = (`ti' - 1) * `k' + `vnum'
                    mat `bvec'[`ti', 1] = `beta'[`idx_i', 1]
                    forvalues tj = 1/`ntau' {
                        local idx_j = (`tj' - 1) * `k' + `vnum'
                        mat `bvcov'[`ti', `tj'] = `beta_cov'[`idx_i', `idx_j']
                    }
                }
                
                * Scale covariance
                tempname bvcov_s
                mat `bvcov_s' = `bvcov' / ((`nobs' - 1)^2)
                
                * Wald = (R*b)' * inv(R*V*R') * (R*b)
                tempname Rb_v RVR_v RVR_inv Wm
                mat `Rb_v' = `Rv' * `bvec'
                mat `RVR_v' = `Rv' * `bvcov_s' * (`Rv'')
                mat `RVR_inv' = syminv(`RVR_v')
                mat `Wm' = (`Rb_v'') * `RVR_inv' * `Rb_v'
                local wb_stat = `Wm'[1,1]
                local wb_pval = chi2tail(`wb_df', `wb_stat')
            }
            
            * ------ Per-variable Wald for gamma constancy ------
            local wg_stat = .
            local wg_pval = .
            local wg_df = `ntau' - 1
            capture {
                tempname Rg gvec gvcov
                mat `Rg' = J(`wg_df', `ntau', 0)
                forvalues tt = 2/`ntau' {
                    local rr = `tt' - 1
                    mat `Rg'[`rr', 1] = -1
                    mat `Rg'[`rr', `tt'] = 1
                }
                
                mat `gvec' = J(`ntau', 1, 0)
                mat `gvcov' = J(`ntau', `ntau', 0)
                forvalues ti = 1/`ntau' {
                    local idx_i = (`ti' - 1) * `k' + `vnum'
                    mat `gvec'[`ti', 1] = `gamma'[`idx_i', 1]
                    forvalues tj = 1/`ntau' {
                        local idx_j = (`tj' - 1) * `k' + `vnum'
                        mat `gvcov'[`ti', `tj'] = `gamma_cov'[`idx_i', `idx_j']
                    }
                }
                
                tempname gvcov_s Rg_b RgVRg RgVRg_inv Wgm
                mat `gvcov_s' = `gvcov' / (`nobs' - 1)
                mat `Rg_b' = `Rg' * `gvec'
                mat `RgVRg' = `Rg' * `gvcov_s' * (`Rg'')
                mat `RgVRg_inv' = syminv(`RgVRg')
                mat `Wgm' = (`Rg_b'') * `RgVRg_inv' * `Rg_b'
                local wg_stat = `Wgm'[1,1]
                local wg_pval = chi2tail(`wg_df', `wg_stat')
            }
            
            * ------ Display row ------
            di as txt "  {ralign 10:`v'}" _c
            
            * Beta Wald
            if `wb_stat' != . {
                di as res "  {ralign 10:" %8.2f `wb_stat' "}" _c
                if `wb_pval' < 0.01 {
                    di as err "  " %5.3f `wb_pval' "***" _c
                }
                else if `wb_pval' < 0.05 {
                    di as err "  " %5.3f `wb_pval' "** " _c
                }
                else if `wb_pval' < 0.10 {
                    di as res "  " %5.3f `wb_pval' "*  " _c
                }
                else {
                    di as txt "  " %5.3f `wb_pval' "   " _c
                }
            }
            else {
                di as txt "  {ralign 10:    .}" _c
                di as txt "  {ralign 8:  .}" _c
            }
            
            * Gamma Wald
            if `wg_stat' != . {
                di as res "  {ralign 10:" %8.2f `wg_stat' "}" _c
                if `wg_pval' < 0.01 {
                    di as err "  " %5.3f `wg_pval' "***" _c
                }
                else if `wg_pval' < 0.05 {
                    di as err "  " %5.3f `wg_pval' "** " _c
                }
                else if `wg_pval' < 0.10 {
                    di as res "  " %5.3f `wg_pval' "*  " _c
                }
                else {
                    di as txt "  " %5.3f `wg_pval' "   " _c
                }
            }
            else {
                di as txt "  {ralign 10:    .}" _c
                di as txt "  {ralign 8:  .}" _c
            }
            
            * ECM rho(median)
            di as res "  {ralign 10:" %8.4f `rho_med' "}" _c
            if `rho_med' < 0 {
                di as txt "  {ralign 8:Conv.}" _c
            }
            else {
                di as err "  {ralign 8:Diverg}" _c
            }
            
            * Verdict: QC exists if beta OR gamma Wald rejects at 5%
            local qc_exists = 0
            if `wb_pval' != . & `wb_pval' < 0.05 {
                local qc_exists = 1
            }
            if `wg_pval' != . & `wg_pval' < 0.05 {
                local qc_exists = 1
            }
            if `qc_exists' == 1 {
                di as err "   {bf:QC Exists}"
            }
            else {
                di as txt "   No QC"
            }
        }
        
        * ------ Joint test: all variables (as in CKS 2015 paper) ------
        di as txt "  {hline 74}"
        local jb_stat = .
        local jb_pval = .
        local jb_df = (`ntau' - 1) * `k'
        capture {
            tempname Rj Rbj RVRj
            local dim = `ntau' * `k'
            mat `Rj' = J(`jb_df', `dim', 0)
            local rr = 0
            forvalues tt = 2/`ntau' {
                forvalues vi = 1/`k' {
                    local ++rr
                    local col1 = (1 - 1) * `k' + `vi'
                    local col_tt = (`tt' - 1) * `k' + `vi'
                    mat `Rj'[`rr', `col1'] = -1
                    mat `Rj'[`rr', `col_tt'] = 1
                }
            }
            
            tempname bcov_s
            mat `bcov_s' = `beta_cov' / ((`nobs' - 1)^2)
            mat `Rbj' = `Rj' * `beta'
            mat `RVRj' = `Rj' * `bcov_s' * (`Rj'')
            tempname RVRj_inv Wjm
            mat `RVRj_inv' = syminv(`RVRj')
            mat `Wjm' = (`Rbj'') * `RVRj_inv' * `Rbj'
            local jb_stat = `Wjm'[1,1]
            local jb_pval = chi2tail(`jb_df', `jb_stat')
        }
        
        local jg_stat = .
        local jg_pval = .
        capture {
            tempname Rjg Rgjb RgVRgj
            mat `Rjg' = J(`jb_df', `dim', 0)
            local rr = 0
            forvalues tt = 2/`ntau' {
                forvalues vi = 1/`k' {
                    local ++rr
                    local col1 = (1 - 1) * `k' + `vi'
                    local col_tt = (`tt' - 1) * `k' + `vi'
                    mat `Rjg'[`rr', `col1'] = -1
                    mat `Rjg'[`rr', `col_tt'] = 1
                }
            }
            
            tempname gcov_s
            mat `gcov_s' = `gamma_cov' / (`nobs' - 1)
            mat `Rgjb' = `Rjg' * `gamma'
            mat `RgVRgj' = `Rjg' * `gcov_s' * (`Rjg'')
            tempname RgVRgj_inv Wgjm
            mat `RgVRgj_inv' = syminv(`RgVRgj')
            mat `Wgjm' = (`Rgjb'') * `RgVRgj_inv' * `Rgjb'
            local jg_stat = `Wgjm'[1,1]
            local jg_pval = chi2tail(`jb_df', `jg_stat')
        }
        
        * Display joint row
        di as res "  {ralign 10:Joint(all)}" _c
        
        if `jb_stat' != . {
            di as res "  {ralign 10:" %8.2f `jb_stat' "}" _c
            if `jb_pval' < 0.01 {
                di as err "  " %5.3f `jb_pval' "***" _c
            }
            else if `jb_pval' < 0.05 {
                di as err "  " %5.3f `jb_pval' "** " _c
            }
            else if `jb_pval' < 0.10 {
                di as res "  " %5.3f `jb_pval' "*  " _c
            }
            else {
                di as txt "  " %5.3f `jb_pval' "   " _c
            }
        }
        else {
            di as txt "  {ralign 10:    .}" _c
            di as txt "  {ralign 8:  .}" _c
        }
        
        if `jg_stat' != . {
            di as res "  {ralign 10:" %8.2f `jg_stat' "}" _c
            if `jg_pval' < 0.01 {
                di as err "  " %5.3f `jg_pval' "***" _c
            }
            else if `jg_pval' < 0.05 {
                di as err "  " %5.3f `jg_pval' "** " _c
            }
            else if `jg_pval' < 0.10 {
                di as res "  " %5.3f `jg_pval' "*  " _c
            }
            else {
                di as txt "  " %5.3f `jg_pval' "   " _c
            }
        }
        else {
            di as txt "  {ralign 10:    .}" _c
            di as txt "  {ralign 8:  .}" _c
        }
        
        * ECM rho(median) same for joint row
        di as res "  {ralign 10:" %8.4f `rho_med' "}" _c
        if `rho_med' < 0 {
            di as txt "  {ralign 8:Conv.}" _c
        }
        else {
            di as err "  {ralign 8:Diverg}" _c
        }
        
        * Joint verdict
        local jqc = 0
        if `jb_pval' != . & `jb_pval' < 0.05 local jqc = 1
        if `jg_pval' != . & `jg_pval' < 0.05 local jqc = 1
        if `jqc' == 1 {
            di as err "   {bf:QC Exists}"
        }
        else {
            di as txt "   No QC"
        }
        
        di as txt "{hline 78}"
        di as txt "  W(beta): Wald H0: beta constant across quantiles"
        di as txt "  W(gamma): Wald H0: gamma constant across quantiles"
        di as txt "  Per-variable: df = `wb_df'  |  Joint(all): df = `jb_df'"
        di as txt "  rho(med): ECM speed of adjustment at median quantile"
        di as txt "  Verdict: QC Exists if W(beta) or W(gamma) rejects at 5%"
        di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
        di as txt "{hline 78}"
    }
    
    * ================================================================
    *  PART 1: Asymmetry Summary Table
    * ================================================================
    if "`nosummary'" == "" {
        di as txt _n
        di as txt "{hline 78}"
        di as res "  QARDL Asymmetry Diagnostics"
        di as txt "{hline 78}"
        di as txt "  Dep. var: `depvar'    Model: QARDL(`p',`q')    Obs: `nobs'    Quantiles: `ntau'"
        di as txt "{hline 78}"
        
        * ============================================================
        * 1a. Beta Asymmetry Table
        * ============================================================
        di as txt _n
        di as res "  {bf:Long-Run Parameters: beta(tau) Asymmetry}"
        di as txt "  {hline 74}"
        di as txt "  {ralign 10:Variable}" _c
        di as txt "  {ralign 9:beta_min}" _c
        di as txt "  {ralign 9:tau_min}" _c
        di as txt "  {ralign 9:beta_max}" _c
        di as txt "  {ralign 9:tau_max}" _c
        di as txt "  {ralign 9:Ratio}" _c
        di as txt "  {ralign 9:AsymIdx}" _c
        di as txt "  {ralign 6:Wald}"
        di as txt "  {hline 74}"
        
        * Per-variable Wald: test beta_v constancy across quantiles
        * Computed separately for each variable v
        
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            
            * --- Per-variable Wald for beta_v constancy ---
            local wpval_beta = .
            local wb_df = `ntau' - 1
            capture {
                tempname Rv bvec bvcov bvcov_s Rb_v RVR_v RVR_inv Wm
                mat `Rv' = J(`wb_df', `ntau', 0)
                forvalues tt = 2/`ntau' {
                    local rr = `tt' - 1
                    mat `Rv'[`rr', 1] = -1
                    mat `Rv'[`rr', `tt'] = 1
                }
                
                * Extract beta_v across quantiles and its sub-covariance
                mat `bvec' = J(`ntau', 1, 0)
                mat `bvcov' = J(`ntau', `ntau', 0)
                forvalues ti = 1/`ntau' {
                    local idx_i = (`ti' - 1) * `k' + `vnum'
                    mat `bvec'[`ti', 1] = `beta'[`idx_i', 1]
                    forvalues tj = 1/`ntau' {
                        local idx_j = (`tj' - 1) * `k' + `vnum'
                        mat `bvcov'[`ti', `tj'] = `beta_cov'[`idx_i', `idx_j']
                    }
                }
                
                mat `bvcov_s' = `bvcov' / ((`nobs' - 1)^2)
                mat `Rb_v' = `Rv' * `bvec'
                mat `RVR_v' = `Rv' * `bvcov_s' * (`Rv'')
                mat `RVR_inv' = syminv(`RVR_v')
                mat `Wm' = (`Rb_v'') * `RVR_inv' * `Rb_v'
                local wstat_b = `Wm'[1,1]
                local wpval_beta = chi2tail(`wb_df', `wstat_b')
            }
            
            * Find min/max beta across quantiles for this variable
            * Initialize with first value
            local idx1 = (1 - 1) * `k' + `vnum'
            local bmin = `beta'[`idx1', 1]
            local bmax = `beta'[`idx1', 1]
            local bmin_tau = `tau_vec'[1, 1]
            local bmax_tau = `tau_vec'[1, 1]
            local bmed = .
            local med_tau = 0.5
            local med_dist = 1
            
            forvalues t = 1/`ntau' {
                local idx = (`t' - 1) * `k' + `vnum'
                local bval = `beta'[`idx', 1]
                local tauval = `tau_vec'[`t', 1]
                
                if `bval' < `bmin' {
                    local bmin = `bval'
                    local bmin_tau = `tauval'
                }
                if `bval' > `bmax' {
                    local bmax = `bval'
                    local bmax_tau = `tauval'
                }
                
                * Find closest to median tau
                local tdist = abs(`tauval' - 0.5)
                if `tdist' < `med_dist' {
                    local med_dist = `tdist'
                    local bmed = `bval'
                }
            }
            
            * Asymmetry ratio
            if `bmin' != 0 {
                local aratio = `bmax' / `bmin'
            }
            else {
                local aratio = .
            }
            
            * Asymmetry index: (max - min) / |median|
            if `bmed' != 0 {
                local aidx = (`bmax' - `bmin') / abs(`bmed')
            }
            else {
                local aidx = .
            }
            
            * Display
            di as txt "  {ralign 10:`v'}" _c
            di as res "  {ralign 9:" %7.3f `bmin' "}" _c
            di as txt "  {ralign 9:" %7.2f `bmin_tau' "}" _c
            di as res "  {ralign 9:" %7.3f `bmax' "}" _c
            di as txt "  {ralign 9:" %7.2f `bmax_tau' "}" _c
            
            * Color the ratio
            if `aratio' != . {
                if abs(`aratio' - 1) > 0.5 {
                    di as err "  {ralign 9:" %7.3f `aratio' "}" _c
                }
                else if abs(`aratio' - 1) > 0.2 {
                    di as res "  {ralign 9:" %7.3f `aratio' "}" _c
                }
                else {
                    di as txt "  {ralign 9:" %7.3f `aratio' "}" _c
                }
            }
            else {
                di as txt "  {ralign 9:    .}" _c
            }
            
            * Asymmetry index
            if `aidx' != . {
                if `aidx' > 0.5 {
                    di as err "  {ralign 9:" %7.3f `aidx' "}" _c
                }
                else if `aidx' > 0.2 {
                    di as res "  {ralign 9:" %7.3f `aidx' "}" _c
                }
                else {
                    di as txt "  {ralign 9:" %7.3f `aidx' "}" _c
                }
            }
            else {
                di as txt "  {ralign 9:    .}" _c
            }
            
            * Wald p-value with stars (per-variable test)
            if `wpval_beta' != . {
                if `wpval_beta' < 0.01 {
                    di as err " " %6.3f `wpval_beta' "***"
                }
                else if `wpval_beta' < 0.05 {
                    di as err " " %6.3f `wpval_beta' "** "
                }
                else if `wpval_beta' < 0.10 {
                    di as res " " %6.3f `wpval_beta' "*  "
                }
                else {
                    di as txt " " %6.3f `wpval_beta' "   "
                }
            }
            else {
                di as txt "     .   "
            }
        }
        di as txt "  {hline 74}"
        di as txt "  Ratio = beta_max/beta_min; AsymIdx = (max-min)/|median|"
        di as txt "  Wald: H0: beta_v constant across quantiles (per variable). *** p<0.01 ** p<0.05 * p<0.10"
        
        * ============================================================
        * 1b. Gamma Asymmetry Table
        * ============================================================
        di as txt _n
        di as res "  {bf:Short-Run Impact: gamma(tau) Asymmetry}"
        di as txt "  {hline 74}"
        di as txt "  {ralign 10:Variable}" _c
        di as txt "  {ralign 9:gam_min}" _c
        di as txt "  {ralign 9:tau_min}" _c
        di as txt "  {ralign 9:gam_max}" _c
        di as txt "  {ralign 9:tau_max}" _c
        di as txt "  {ralign 9:Ratio}" _c
        di as txt "  {ralign 9:AsymIdx}" _c
        di as txt "  {ralign 6:Wald}"
        di as txt "  {hline 74}"
        
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            
            * --- Per-variable Wald for gamma_v constancy ---
            local gwpval_gam = .
            local wg_df = `ntau' - 1
            capture {
                tempname Rg gvec gvcov gvcov_s Rg_b RgVRg RgVRg_inv Wgm
                mat `Rg' = J(`wg_df', `ntau', 0)
                forvalues tt = 2/`ntau' {
                    local rr = `tt' - 1
                    mat `Rg'[`rr', 1] = -1
                    mat `Rg'[`rr', `tt'] = 1
                }
                
                * Extract gamma_v across quantiles and its sub-covariance
                mat `gvec' = J(`ntau', 1, 0)
                mat `gvcov' = J(`ntau', `ntau', 0)
                forvalues ti = 1/`ntau' {
                    local idx_i = (`ti' - 1) * `k' + `vnum'
                    mat `gvec'[`ti', 1] = `gamma'[`idx_i', 1]
                    forvalues tj = 1/`ntau' {
                        local idx_j = (`tj' - 1) * `k' + `vnum'
                        mat `gvcov'[`ti', `tj'] = `gamma_cov'[`idx_i', `idx_j']
                    }
                }
                
                mat `gvcov_s' = `gvcov' / (`nobs' - 1)
                mat `Rg_b' = `Rg' * `gvec'
                mat `RgVRg' = `Rg' * `gvcov_s' * (`Rg'')
                mat `RgVRg_inv' = syminv(`RgVRg')
                mat `Wgm' = (`Rg_b'') * `RgVRg_inv' * `Rg_b'
                local gwstat = `Wgm'[1,1]
                local gwpval_gam = chi2tail(`wg_df', `gwstat')
            }
            
            * Initialize with first value
            local gidx1 = (1 - 1) * `k' + `vnum'
            local gmin = `gamma'[`gidx1', 1]
            local gmax = `gamma'[`gidx1', 1]
            local gmin_tau = `tau_vec'[1, 1]
            local gmax_tau = `tau_vec'[1, 1]
            local gmed = .
            local med_dist = 1
            
            forvalues t = 1/`ntau' {
                local idx = (`t' - 1) * `k' + `vnum'
                local gval = `gamma'[`idx', 1]
                local tauval = `tau_vec'[`t', 1]
                
                if `gval' < `gmin' {
                    local gmin = `gval'
                    local gmin_tau = `tauval'
                }
                if `gval' > `gmax' {
                    local gmax = `gval'
                    local gmax_tau = `tauval'
                }
                local tdist = abs(`tauval' - 0.5)
                if `tdist' < `med_dist' {
                    local med_dist = `tdist'
                    local gmed = `gval'
                }
            }
            
            if `gmin' != 0 {
                local gratio = `gmax' / `gmin'
            }
            else {
                local gratio = .
            }
            if `gmed' != 0 {
                local gidx = (`gmax' - `gmin') / abs(`gmed')
            }
            else {
                local gidx = .
            }
            
            di as txt "  {ralign 10:`v'}" _c
            di as res "  {ralign 9:" %7.3f `gmin' "}" _c
            di as txt "  {ralign 9:" %7.2f `gmin_tau' "}" _c
            di as res "  {ralign 9:" %7.3f `gmax' "}" _c
            di as txt "  {ralign 9:" %7.2f `gmax_tau' "}" _c
            
            if `gratio' != . {
                if abs(`gratio' - 1) > 0.5 {
                    di as err "  {ralign 9:" %7.3f `gratio' "}" _c
                }
                else if abs(`gratio' - 1) > 0.2 {
                    di as res "  {ralign 9:" %7.3f `gratio' "}" _c
                }
                else {
                    di as txt "  {ralign 9:" %7.3f `gratio' "}" _c
                }
            }
            else {
                di as txt "  {ralign 9:    .}" _c
            }
            
            if `gidx' != . {
                if `gidx' > 0.5 {
                    di as err "  {ralign 9:" %7.3f `gidx' "}" _c
                }
                else if `gidx' > 0.2 {
                    di as res "  {ralign 9:" %7.3f `gidx' "}" _c
                }
                else {
                    di as txt "  {ralign 9:" %7.3f `gidx' "}" _c
                }
            }
            else {
                di as txt "  {ralign 9:    .}" _c
            }
            
            * Wald p-value with stars (per-variable test)
            if `gwpval_gam' != . {
                if `gwpval_gam' < 0.01 {
                    di as err " " %6.3f `gwpval_gam' "***"
                }
                else if `gwpval_gam' < 0.05 {
                    di as err " " %6.3f `gwpval_gam' "** "
                }
                else if `gwpval_gam' < 0.10 {
                    di as res " " %6.3f `gwpval_gam' "*  "
                }
                else {
                    di as txt " " %6.3f `gwpval_gam' "   "
                }
            }
            else {
                di as txt "     .   "
            }
        }
        di as txt "  {hline 74}"
        
        * ============================================================
        * 1c. Coefficient Heatmap Table
        * ============================================================
        di as txt _n
        di as res "  {bf:Coefficient Heatmap: beta(tau) across Quantiles}"
        di as txt "  {hline 74}"
        
        * Header row with tau values
        di as txt "  {ralign 12:Variable}" _c
        forvalues t = 1/`ntau' {
            local tauval = `tau_vec'[`t', 1]
            di as txt "  {ralign 9:tau=" %4.2f `tauval' "}" _c
        }
        di ""
        di as txt "  {hline 74}"
        
        * Find global min/max for color coding
        local gmin_all = `beta'[1, 1]
        local gmax_all = `beta'[1, 1]
        forvalues i = 2/`= rowsof(`beta')' {
            local bv = `beta'[`i', 1]
            if `bv' < `gmin_all' local gmin_all = `bv'
            if `bv' > `gmax_all' local gmax_all = `bv'
        }
        local bmid = (`gmin_all' + `gmax_all') / 2
        
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            di as txt "  {ralign 12:`v'}" _c
            
            forvalues t = 1/`ntau' {
                local idx = (`t' - 1) * `k' + `vnum'
                local bval = `beta'[`idx', 1]
                
                * Color code: red for high, blue for low
                if `bval' > `bmid' {
                    di as err "  {ralign 9:" %7.3f `bval' "}" _c
                }
                else {
                    di as res "  {ralign 9:" %7.3f `bval' "}" _c
                }
            }
            di ""
        }
        di as txt "  {hline 74}"
        di as txt "  {it:Red = above median; Yellow = below median across all beta values}"
        
        * ============================================================
        * 1d. Pairwise Quantile Equality Tests (upper triangle)
        * ============================================================
        if "`nopairwise'" == "" & `ntau' >= 2 & `ntau' <= 9 {
            di as txt _n
            di as res "  {bf:Pairwise Equality Tests: H0: beta(tau_i) = beta(tau_j)}"
            di as txt "  {hline 74}"
            
            * Header
            di as txt "  {ralign 7: }" _c
            forvalues j = 2/`ntau' {
                local tauval = `tau_vec'[`j', 1]
                di as txt "  {ralign 7:tau=" %4.2f `tauval' "}" _c
            }
            di ""
            di as txt "  {hline 74}"
            
            forvalues i = 1/`= `ntau' - 1' {
                local tauv_i = `tau_vec'[`i', 1]
                di as txt "  tau=" %4.2f `tauv_i' " " _c
                
                * Blank cells for lower triangle
                forvalues j = 2/`i' {
                    di as txt "  {ralign 7:     }" _c
                }
                
                * Upper triangle: pairwise Wald for each pair (i,j)
                forvalues j = `= `i' + 1'/`ntau' {
                    * Wald test for beta(tau_i) = beta(tau_j)
                    * R selects beta at tau_i and tau_j, tests equality
                    local wstat_pair = 0
                    local wdf_pair = `k'
                    
                    forvalues vi = 1/`k' {
                        local idx_i = (`i' - 1) * `k' + `vi'
                        local idx_j = (`j' - 1) * `k' + `vi'
                        
                        local b_i = `beta'[`idx_i', 1]
                        local b_j = `beta'[`idx_j', 1]
                        local diff = `b_i' - `b_j'
                        
                        * Variance of difference
                        local vii = `beta_cov'[`idx_i', `idx_i']
                        local vjj = `beta_cov'[`idx_j', `idx_j']
                        local vij = `beta_cov'[`idx_i', `idx_j']
                        local var_diff = `vii' + `vjj' - 2 * `vij'
                        
                        if `var_diff' > 0 {
                            local wstat_pair = `wstat_pair' + ///
                                (`nobs' - 1)^2 * (`diff')^2 / `var_diff'
                        }
                    }
                    
                    local pval_pair = chi2tail(`wdf_pair', `wstat_pair')
                    
                    if `pval_pair' < 0.01 {
                        di as err "  {ralign 7:" %5.3f `pval_pair' "}" _c
                    }
                    else if `pval_pair' < 0.05 {
                        di as res "  {ralign 7:" %5.3f `pval_pair' "}" _c
                    }
                    else {
                        di as txt "  {ralign 7:" %5.3f `pval_pair' "}" _c
                    }
                }
                di ""
            }
            di as txt "  {hline 74}"
            di as txt "  p-values: {err:red p<0.01} {res:yellow p<0.05} {txt:white p>=0.05}"
        }
    }
    
    * ================================================================
    *  PART 2: Professional Graphs
    * ================================================================
    if "`nograph'" == "" {
        
        preserve
        clear
        qui set obs `ntau'
        
        * Tau variable
        qui gen double tau = .
        forvalues t = 1/`ntau' {
            qui replace tau = `tau_vec'[`t', 1] in `t'
        }
        
        * ============================================================
        * 2a. Fan Chart: All beta(tau) lines on one plot
        * ============================================================
        local vnum = 0
        local glist_fan ""
        local legend_fan ""
        
        * Define colors per variable
        local colors `" "`c_blue'" "`c_red'" "`c_green'" "`c_purple'" "`c_orange'" "`c_teal'" "`c_brown'" "'
        
        foreach v of local indepvars {
            local ++vnum
            
            * Pick color for this variable
            local cvar : word `vnum' of `colors'
            if "`cvar'" == "" local cvar "`c_blue'"
            
            * Generate data
            qui gen double beta_v`vnum' = .
            qui gen double beta_lo_v`vnum' = .
            qui gen double beta_hi_v`vnum' = .
            
            forvalues t = 1/`ntau' {
                local idx = (`t' - 1) * `k' + `vnum'
                if `idx' <= rowsof(`beta') {
                    local est = `beta'[`idx', 1]
                    qui replace beta_v`vnum' = `est' in `t'
                    
                    if `idx' <= rowsof(`beta_cov') {
                        local var_val = `beta_cov'[`idx', `idx']
                        if `var_val' > 0 {
                            local se = sqrt(`var_val') / (`nobs' - 1)
                            qui replace beta_lo_v`vnum' = `est' - 1.96*`se' in `t'
                            qui replace beta_hi_v`vnum' = `est' + 1.96*`se' in `t'
                        }
                    }
                }
            }
            
            * Confidence band (lighter)
            local glist_fan `glist_fan' (rarea beta_lo_v`vnum' beta_hi_v`vnum' tau, ///
                fcolor("`cvar'%15") lcolor("`cvar'%30") lwidth(vthin))
            
            * Line + markers
            local glist_fan `glist_fan' (connected beta_v`vnum' tau, ///
                lcolor("`cvar'") mcolor("`cvar'") lwidth(medthick) ///
                msymbol(circle) msize(small))
            
            local pnum2 = `vnum' * 2
            local legend_fan `legend_fan' `pnum2' "`v'"
        }
        
        * Zero reference
        local glist_fan `glist_fan' (function y = 0, range(0.05 0.95) ///
            lcolor(gs12) lpattern(dash) lwidth(thin))
        
        twoway `glist_fan', ///
            title("{bf:Long-Run Coefficients Across Quantiles}", ///
                size(medium) color("0 51 102")) ///
            subtitle("beta(tau) with 95% Confidence Bands", ///
                size(small) color(gs5)) ///
            xtitle("Quantile (tau)", size(small)) ///
            ytitle("Long-run coefficient", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(vsmall)) ///
            legend(order(`legend_fan') rows(1) size(vsmall) ///
                region(lcolor(gs14))) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            name(qardl_fan_beta, replace)
        
        * ============================================================
        * 2b. Fan Chart for Gamma
        * ============================================================
        local vnum = 0
        local glist_gfan ""
        local legend_gfan ""
        
        foreach v of local indepvars {
            local ++vnum
            local cvar : word `vnum' of `colors'
            if "`cvar'" == "" local cvar "`c_blue'"
            
            qui gen double gamma_v`vnum' = .
            qui gen double gamma_lo_v`vnum' = .
            qui gen double gamma_hi_v`vnum' = .
            
            forvalues t = 1/`ntau' {
                local idx = (`t' - 1) * `k' + `vnum'
                if `idx' <= rowsof(`gamma') {
                    local est = `gamma'[`idx', 1]
                    qui replace gamma_v`vnum' = `est' in `t'
                    
                    if `idx' <= rowsof(`gamma_cov') {
                        local var_val = `gamma_cov'[`idx', `idx']
                        if `var_val' > 0 {
                            local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                            qui replace gamma_lo_v`vnum' = `est' - 1.96*`se' in `t'
                            qui replace gamma_hi_v`vnum' = `est' + 1.96*`se' in `t'
                        }
                    }
                }
            }
            
            local glist_gfan `glist_gfan' (rarea gamma_lo_v`vnum' gamma_hi_v`vnum' tau, ///
                fcolor("`cvar'%15") lcolor("`cvar'%30") lwidth(vthin))
            local glist_gfan `glist_gfan' (connected gamma_v`vnum' tau, ///
                lcolor("`cvar'") mcolor("`cvar'") lwidth(medthick) ///
                msymbol(triangle) msize(small))
            
            local pnum2 = `vnum' * 2
            local legend_gfan `legend_gfan' `pnum2' "`v'"
        }
        
        local glist_gfan `glist_gfan' (function y = 0, range(0.05 0.95) ///
            lcolor(gs12) lpattern(dash) lwidth(thin))
        
        twoway `glist_gfan', ///
            title("{bf:Short-Run Impact Across Quantiles}", ///
                size(medium) color("0 51 102")) ///
            subtitle("gamma(tau) with 95% Confidence Bands", ///
                size(small) color(gs5)) ///
            xtitle("Quantile (tau)", size(small)) ///
            ytitle("Short-run coefficient", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(vsmall)) ///
            legend(order(`legend_gfan') rows(1) size(vsmall) ///
                region(lcolor(gs14))) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            name(qardl_fan_gamma, replace)
        
        * ============================================================
        * 2c. Asymmetry Ratio Bar Chart
        * ============================================================
        clear
        local nk = `k'
        * Two rows per variable: one for beta ratio, one for gamma ratio
        local nrows = `nk' * 2
        qui set obs `nrows'
        qui gen str20 varname = ""
        qui gen double ratio = .
        qui gen double ypos = .
        qui gen int bartype = .   // 1=beta, 2=gamma
        
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            local row_b = (`vnum' - 1) * 2 + 1
            local row_g = (`vnum' - 1) * 2 + 2
            
            qui replace varname = "`v'" in `row_b'
            qui replace varname = "`v'" in `row_g'
            qui replace ypos = `vnum' - 0.18 in `row_b'
            qui replace ypos = `vnum' + 0.18 in `row_g'
            qui replace bartype = 1 in `row_b'
            qui replace bartype = 2 in `row_g'
            
            * Beta ratio
            local idx1 = (1 - 1) * `k' + `vnum'
            local bmin_v = `beta'[`idx1', 1]
            local bmax_v = `beta'[`idx1', 1]
            forvalues t = 2/`ntau' {
                local idx = (`t' - 1) * `k' + `vnum'
                local bval = `beta'[`idx', 1]
                if `bval' < `bmin_v' local bmin_v = `bval'
                if `bval' > `bmax_v' local bmax_v = `bval'
            }
            if `bmin_v' != 0 {
                qui replace ratio = `bmax_v' / `bmin_v' in `row_b'
            }
            
            * Gamma ratio
            local gidx1 = (1 - 1) * `k' + `vnum'
            local gmin_v = `gamma'[`gidx1', 1]
            local gmax_v = `gamma'[`gidx1', 1]
            forvalues t = 2/`ntau' {
                local idx = (`t' - 1) * `k' + `vnum'
                local gval = `gamma'[`idx', 1]
                if `gval' < `gmin_v' local gmin_v = `gval'
                if `gval' > `gmax_v' local gmax_v = `gval'
            }
            if `gmin_v' != 0 {
                qui replace ratio = `gmax_v' / `gmin_v' in `row_g'
            }
        }
        
        * Build ylabel labels
        local ylabs ""
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            local ylabs `ylabs' `vnum' "`v'"
        }
        
        twoway (bar ratio ypos if bartype == 1, ///
                barwidth(0.3) color("`c_blue'%80") ///
                horizontal) ///
            (bar ratio ypos if bartype == 2, ///
                barwidth(0.3) color("`c_red'%80") ///
                horizontal), ///
            title("{bf:Asymmetry Ratio: max(tau)/min(tau)}", ///
                size(medium) color("0 51 102")) ///
            subtitle("Ratio = 1 implies symmetry", ///
                size(small) color(gs5)) ///
            xtitle("Ratio", size(small)) ///
            ytitle("", size(small)) ///
            ylabel(`ylabs', labsize(small) angle(0)) ///
            xline(1, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
            legend(order(1 "beta ratio" 2 "gamma ratio") ///
                rows(1) size(vsmall) region(lcolor(gs14))) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            name(qardl_asym_ratio, replace)
        
        * ============================================================
        * 2d. Tail Divergence Plot: beta(tau_high) - beta(tau_low)
        * ============================================================
        * Compare each variable's upper vs lower tail effect
        clear
        qui set obs `nk'
        qui gen str20 varname = ""
        qui gen double tail_diff = .
        qui gen double tail_diff_lo = .
        qui gen double tail_diff_hi = .
        qui gen int vorder = _n
        
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            qui replace varname = "`v'" in `vnum'
            
            * Upper and lower tail indices
            local idx_lo = (1 - 1) * `k' + `vnum'
            local idx_hi = (`ntau' - 1) * `k' + `vnum'
            
            local b_lo = `beta'[`idx_lo', 1]
            local b_hi = `beta'[`idx_hi', 1]
            local diff = `b_hi' - `b_lo'
            
            * SE of difference
            local v_lo = `beta_cov'[`idx_lo', `idx_lo']
            local v_hi = `beta_cov'[`idx_hi', `idx_hi']
            local v_lh = `beta_cov'[`idx_lo', `idx_hi']
            local var_diff = `v_lo' + `v_hi' - 2 * `v_lh'
            
            qui replace tail_diff = `diff' in `vnum'
            if `var_diff' > 0 {
                local se_diff = sqrt(`var_diff') / (`nobs' - 1)
                qui replace tail_diff_lo = `diff' - 1.96 * `se_diff' in `vnum'
                qui replace tail_diff_hi = `diff' + 1.96 * `se_diff' in `vnum'
            }
        }
        
        local tau_lo = `tau_vec'[1, 1]
        local tau_hi = `tau_vec'[`ntau', 1]
        
        local tau_lo_str : di %4.2f `tau_lo'
        local tau_hi_str : di %4.2f `tau_hi'
        
        twoway (rcap tail_diff_lo tail_diff_hi vorder, ///
                lcolor("`c_purple'") lwidth(medthick) horizontal) ///
            (scatter vorder tail_diff, ///
                mcolor("`c_purple'") msymbol(diamond) msize(medlarge)), ///
            title("{bf:Tail Divergence: beta(tau_high) - beta(tau_low)}", ///
                size(medium) color("0 51 102")) ///
            subtitle("beta(`tau_hi_str') - beta(`tau_lo_str') with 95% CI", ///
                size(small) color(gs5)) ///
            xtitle("Coefficient difference", size(small)) ///
            ytitle("", size(small)) ///
            ylabel(1/`nk', valuelabel labsize(small) angle(0)) ///
            xline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            note("Difference = 0 implies symmetry between upper and lower quantiles", ///
                size(vsmall) color(gs8)) ///
            name(qardl_tail_div, replace)
        
        * ============================================================
        * 2e. Quantile Gradient Plot: dBeta/dTau
        * ============================================================
        if `ntau' >= 3 {
            clear
            local ngrad = `ntau' - 1
            qui set obs `ngrad'
            qui gen double tau_mid = .
            
            forvalues t = 1/`ngrad' {
                local tau_t = `tau_vec'[`t', 1]
                local tau_t1 = `tau_vec'[`= `t' + 1', 1]
                qui replace tau_mid = (`tau_t' + `tau_t1') / 2 in `t'
            }
            
            local vnum = 0
            local glist_grad ""
            local legend_grad ""
            
            foreach v of local indepvars {
                local ++vnum
                local cvar : word `vnum' of `colors'
                if "`cvar'" == "" local cvar "`c_blue'"
                
                qui gen double grad_v`vnum' = .
                
                forvalues t = 1/`ngrad' {
                    local idx_t = (`t' - 1) * `k' + `vnum'
                    local idx_t1 = `t' * `k' + `vnum'
                    local tau_t = `tau_vec'[`t', 1]
                    local tau_t1 = `tau_vec'[`= `t' + 1', 1]
                    local dtau = `tau_t1' - `tau_t'
                    
                    if `idx_t' <= rowsof(`beta') & `idx_t1' <= rowsof(`beta') & `dtau' > 0 {
                        local b_t = `beta'[`idx_t', 1]
                        local b_t1 = `beta'[`idx_t1', 1]
                        local gradient = (`b_t1' - `b_t') / `dtau'
                        qui replace grad_v`vnum' = `gradient' in `t'
                    }
                }
                
                local glist_grad `glist_grad' (connected grad_v`vnum' tau_mid, ///
                    lcolor("`cvar'") mcolor("`cvar'") lwidth(medthick) ///
                    msymbol(circle) msize(small))
                
                local legend_grad `legend_grad' label(`vnum' "`v'")
            }
            
            local glist_grad `glist_grad' (function y = 0, range(0.05 0.95) ///
                lcolor(gs12) lpattern(dash) lwidth(thin))
            
            twoway `glist_grad', ///
                title("{bf:Quantile Gradient: d{it:beta}/d{it:tau}}", ///
                    size(medium) color("0 51 102")) ///
                subtitle("Rate of change of long-run coefficient across quantiles", ///
                    size(small) color(gs5)) ///
                xtitle("Quantile (tau)", size(small)) ///
                ytitle("d{it:beta}/d{it:tau}", size(small)) ///
                xlabel(0.1(0.1)0.9, labsize(vsmall)) ///
                legend(`legend_grad' rows(1) size(vsmall) ///
                    region(lcolor(gs14))) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(small)) ///
                scheme(s2color) ///
                note("Flat = symmetric; Steep = high local asymmetry", ///
                    size(vsmall) color(gs8)) ///
                name(qardl_gradient, replace)
        }
        
        * ============================================================
        * 2f. ECM Speed-of-Adjustment Plot: rho(tau) Bar Chart
        * ============================================================
        clear
        qui set obs `ntau'
        qui gen double tau = .
        qui gen double rho = .
        qui gen double rho_lo = .
        qui gen double rho_hi = .
        qui gen double rho_abs = .
        
        forvalues t = 1/`ntau' {
            qui replace tau = `tau_vec'[`t', 1] in `t'
            
            * Compute rho = sum(phi) - 1
            local sum_phi = 0
            forvalues i = 1/`p' {
                local phi_idx = (`t' - 1) * `p' + `i'
                if `phi_idx' <= rowsof(`phi') {
                    local sum_phi = `sum_phi' + `phi'[`phi_idx', 1]
                }
            }
            local rho_val = `sum_phi' - 1
            qui replace rho = `rho_val' in `t'
            qui replace rho_abs = abs(`rho_val') in `t'
            
            * SE via delta method
            local var_rho = 0
            forvalues i = 1/`p' {
                forvalues j = 1/`p' {
                    local pi = (`t' - 1) * `p' + `i'
                    local pj = (`t' - 1) * `p' + `j'
                    if `pi' <= rowsof(`phi_cov') & `pj' <= rowsof(`phi_cov') {
                        local var_rho = `var_rho' + `phi_cov'[`pi', `pj']
                    }
                }
            }
            if `var_rho' > 0 {
                local se_rho = sqrt(`var_rho') / sqrt(`nobs' - 1)
                qui replace rho_lo = `rho_val' - 1.96 * `se_rho' in `t'
                qui replace rho_hi = `rho_val' + 1.96 * `se_rho' in `t'
            }
        }
        
        * Gradient color: deep teal for strong convergence
        local c_conv   "0 139 139"      // Teal = convergence
        local c_diverg "215 48 39"      // Red  = divergence
        
        twoway (bar rho tau, ///
                barwidth(0.08) color("`c_conv'%70") lcolor("`c_conv'") lwidth(thin)) ///
            (rcap rho_lo rho_hi tau, ///
                lcolor("0 51 102") lwidth(medthick)) ///
            (scatter rho tau, ///
                mcolor("0 51 102") msymbol(diamond) msize(medlarge)) ///
            (function y = 0, range(0.05 0.95) ///
                lcolor("`c_diverg'") lpattern(dash) lwidth(thin)), ///
            title("{bf:ECM Speed of Adjustment: {it:rho}(tau)}", ///
                size(medium) color("0 51 102")) ///
            subtitle("{it:rho}(tau) = SUM {it:phi}_i(tau) - 1 | rho < 0 = convergence", ///
                size(small) color(gs5)) ///
            xtitle("Quantile (tau)", size(small)) ///
            ytitle("{it:rho}(tau)", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(vsmall)) ///
            yline(0, lcolor("`c_diverg'%50") lpattern(solid) lwidth(thin)) ///
            legend(order(1 "{it:rho}(tau)" 2 "95% CI") ///
                rows(1) size(vsmall) region(lcolor(gs14))) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            note("Bars below zero indicate convergence to long-run equilibrium", ///
                size(vsmall) color(gs8)) ///
            name(qardl_ecm_rho, replace)
        
        * ============================================================
        * 2g. Pairwise Equality p-value Plots (Beta & Gamma)
        * ============================================================
        if `ntau' >= 2 {
            * Compute all pairwise p-values for beta (per variable)
            local npairs = `ntau' * (`ntau' - 1) / 2
            local total_pw = `npairs' * `k'
            
            clear
            qui set obs `total_pw'
            qui gen str20 varname = ""
            qui gen double pval_beta = .
            qui gen double pval_gamma = .
            qui gen int pairid = .
            qui gen str12 pairlbl = ""
            qui gen int varid = .
            
            local obs = 0
            local pid = 0
            local vnum = 0
            foreach v of local indepvars {
                local ++vnum
                local pid = 0
                forvalues i = 1/`ntau' {
                    local ti = `tau_vec'[`i', 1]
                    local ip1 = `i' + 1
                    forvalues j = `ip1'/`ntau' {
                        local tj = `tau_vec'[`j', 1]
                        local ++obs
                        local ++pid
                        
                        local idx_i = (`i' - 1) * `k' + `vnum'
                        local idx_j = (`j' - 1) * `k' + `vnum'
                        
                        qui replace varname = "`v'" in `obs'
                        qui replace varid = `vnum' in `obs'
                        qui replace pairid = `pid' in `obs'
                        
                        local ti_s : di %3.1f `ti'
                        local tj_s : di %3.1f `tj'
                        qui replace pairlbl = "`ti_s'-`tj_s'" in `obs'
                        
                        * Beta pairwise Wald
                        if `idx_i' <= rowsof(`beta') & `idx_j' <= rowsof(`beta') ///
                         & `idx_i' <= rowsof(`beta_cov') & `idx_j' <= rowsof(`beta_cov') {
                            local b_i = `beta'[`idx_i', 1]
                            local b_j = `beta'[`idx_j', 1]
                            local diff = `b_i' - `b_j'
                            local v_ii = `beta_cov'[`idx_i', `idx_i']
                            local v_jj = `beta_cov'[`idx_j', `idx_j']
                            local v_ij = `beta_cov'[`idx_i', `idx_j']
                            local var_d = `v_ii' + `v_jj' - 2 * `v_ij'
                            if `var_d' > 1e-15 {
                                local ws = (`nobs' - 1)^2 * (`diff')^2 / `var_d'
                                local pv = chi2tail(1, abs(`ws'))
                                qui replace pval_beta = `pv' in `obs'
                            }
                        }
                        
                        * Gamma pairwise Wald
                        if `idx_i' <= rowsof(`gamma') & `idx_j' <= rowsof(`gamma') ///
                         & `idx_i' <= rowsof(`gamma_cov') & `idx_j' <= rowsof(`gamma_cov') {
                            local g_i = `gamma'[`idx_i', 1]
                            local g_j = `gamma'[`idx_j', 1]
                            local diff = `g_i' - `g_j'
                            local v_ii = `gamma_cov'[`idx_i', `idx_i']
                            local v_jj = `gamma_cov'[`idx_j', `idx_j']
                            local v_ij = `gamma_cov'[`idx_i', `idx_j']
                            local var_d = `v_ii' + `v_jj' - 2 * `v_ij'
                            if `var_d' > 1e-15 {
                                local ws = (`nobs' - 1) * (`diff')^2 / `var_d'
                                local pv = chi2tail(1, abs(`ws'))
                                qui replace pval_gamma = `pv' in `obs'
                            }
                        }
                    }
                }
            }
            
            * Generate significance markers
            qui gen byte sig_beta = 0
            qui replace sig_beta = 1 if pval_beta < 0.10 & pval_beta != .
            qui replace sig_beta = 2 if pval_beta < 0.05 & pval_beta != .
            qui replace sig_beta = 3 if pval_beta < 0.01 & pval_beta != .
            
            qui gen byte sig_gamma = 0
            qui replace sig_gamma = 1 if pval_gamma < 0.10 & pval_gamma != .
            qui replace sig_gamma = 2 if pval_gamma < 0.05 & pval_gamma != .
            qui replace sig_gamma = 3 if pval_gamma < 0.01 & pval_gamma != .
            
            * Encode varname for the y-axis
            encode varname, gen(varname_n)
            
            * Create x position from pairid + variable offset
            qui gen double xpos = pairid + (varid - 1) * (`npairs' + 1)
            
            * ---- Beta pairwise p-value dot plot ----
            twoway (scatter xpos pval_beta if sig_beta == 0, ///
                    mcolor("102 194 165") msymbol(circle) msize(medium)) ///
                (scatter xpos pval_beta if sig_beta >= 1 & sig_beta <= 2, ///
                    mcolor("253 174 97") msymbol(circle) msize(medlarge)) ///
                (scatter xpos pval_beta if sig_beta == 3, ///
                    mcolor("215 48 39") msymbol(circle) msize(large)) ///
                (function y = 0.05, range(0 1) ///
                    lcolor("215 48 39%60") lpattern(dash) lwidth(thin)) ///
                (function y = 0.10, range(0 1) ///
                    lcolor("253 174 97%60") lpattern(dot) lwidth(thin)), ///
                title("{bf:Pairwise Equality: {it:beta}(tau_i) = {it:beta}(tau_j)}", ///
                    size(medium) color("0 51 102")) ///
                subtitle("p-values by variable and quantile pair", ///
                    size(small) color(gs5)) ///
                xtitle("p-value", size(small)) ///
                ytitle("Quantile pair", size(small)) ///
                ylabel(, labsize(vsmall) angle(0) nogrid) ///
                legend(order(1 "p >= 0.10" 2 "p < 0.10" 3 "p < 0.01" ///
                    4 "5% threshold") ///
                    rows(1) size(vsmall) region(lcolor(gs14))) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(small)) ///
                scheme(s2color) ///
                note("Green = accept equality; Red = reject equality", ///
                    size(vsmall) color(gs8)) ///
                name(qardl_pw_beta, replace)
            
            * ---- Gamma pairwise p-value dot plot ----
            twoway (scatter xpos pval_gamma if sig_gamma == 0, ///
                    mcolor("102 194 165") msymbol(triangle) msize(medium)) ///
                (scatter xpos pval_gamma if sig_gamma >= 1 & sig_gamma <= 2, ///
                    mcolor("253 174 97") msymbol(triangle) msize(medlarge)) ///
                (scatter xpos pval_gamma if sig_gamma == 3, ///
                    mcolor("215 48 39") msymbol(triangle) msize(large)) ///
                (function y = 0.05, range(0 1) ///
                    lcolor("215 48 39%60") lpattern(dash) lwidth(thin)) ///
                (function y = 0.10, range(0 1) ///
                    lcolor("253 174 97%60") lpattern(dot) lwidth(thin)), ///
                title("{bf:Pairwise Equality: {it:gamma}(tau_i) = {it:gamma}(tau_j)}", ///
                    size(medium) color("0 51 102")) ///
                subtitle("p-values by variable and quantile pair", ///
                    size(small) color(gs5)) ///
                xtitle("p-value", size(small)) ///
                ytitle("Quantile pair", size(small)) ///
                ylabel(, labsize(vsmall) angle(0) nogrid) ///
                legend(order(1 "p >= 0.10" 2 "p < 0.10" 3 "p < 0.01" ///
                    4 "5% threshold") ///
                    rows(1) size(vsmall) region(lcolor(gs14))) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(small)) ///
                scheme(s2color) ///
                note("Green = accept equality; Red = reject equality", ///
                    size(vsmall) color(gs8)) ///
                name(qardl_pw_gamma, replace)
        }
        
        * ============================================================
        * 2h. Combined Dashboards (split for clarity)
        * ============================================================
        
        * --- Dashboard 1: Main Analysis (2x2) ---
        graph combine qardl_fan_beta qardl_fan_gamma ///
            qardl_ecm_rho qardl_tail_div, ///
            title("{bf:QARDL Main Analysis Dashboard}", ///
                size(medsmall) color("0 51 102")) ///
            subtitle("Cho, Kim & Shin (2015) | QARDL(`p',`q')", ///
                size(small) color(gs5)) ///
            graphregion(color(white)) ///
            cols(2) ///
            imargin(small) ///
            name(qardl_dashboard_main, replace)
        
        * --- Dashboard 2: Diagnostics (2x2) ---
        local diag_list "qardl_asym_ratio"
        capture confirm graph qardl_gradient
        if _rc == 0 {
            local diag_list "`diag_list' qardl_gradient"
        }
        capture confirm graph qardl_pw_beta
        if _rc == 0 {
            local diag_list "`diag_list' qardl_pw_beta"
        }
        capture confirm graph qardl_pw_gamma
        if _rc == 0 {
            local diag_list "`diag_list' qardl_pw_gamma"
        }
        
        graph combine `diag_list', ///
            title("{bf:QARDL Diagnostics Dashboard}", ///
                size(medsmall) color("0 51 102")) ///
            subtitle("Pairwise Tests & Asymmetry Diagnostics | QARDL(`p',`q')", ///
                size(small) color(gs5)) ///
            graphregion(color(white)) ///
            cols(2) ///
            imargin(small) ///
            name(qardl_dashboard_diag, replace)
        
        restore
        
        di as txt _n
        di as res "  Analysis graphs created:"
        di as txt "    {cmd:qardl_fan_beta}    - All beta(tau) on one plot"
        di as txt "    {cmd:qardl_fan_gamma}   - All gamma(tau) on one plot"
        di as txt "    {cmd:qardl_ecm_rho}     - ECM speed of adjustment rho(tau)"
        di as txt "    {cmd:qardl_asym_ratio}  - Max/Min ratio bar chart"
        di as txt "    {cmd:qardl_tail_div}    - Upper vs lower tail difference"
        if `ntau' >= 3 {
            di as txt "    {cmd:qardl_gradient}    - Quantile gradient d{it:beta}/d{it:tau}"
        }
        if `ntau' >= 2 {
            di as txt "    {cmd:qardl_pw_beta}     - Pairwise equality p-values (beta)"
            di as txt "    {cmd:qardl_pw_gamma}    - Pairwise equality p-values (gamma)"
        }
        di as txt "    {cmd:qardl_dashboard_main} - Main analysis panel (2x2)"
        di as txt "    {cmd:qardl_dashboard_diag} - Diagnostics panel (2x2)"
        di as txt _n "  Use {cmd:graph dir} to list all graphs."
        di as txt "  Use {cmd:graph export filename.png} to save."
    }
    
    * ================================================================
    *  PART 3: Interpretation Guide
    * ================================================================
    di as txt _n
    di as txt "{hline 78}"
    di as res "  How to Interpret These Results"
    di as txt "{hline 78}"
    di as txt _n
    di as res "  {bf:1. Asymmetry Summary Table}"
    di as txt "  - {bf:Ratio} = beta_max / beta_min. If Ratio {ul:=} 1, the effect is"
    di as txt "    symmetric across quantiles. Far from 1 = strong asymmetry."
    di as txt "  - {bf:AsymIdx} = (max - min) / |median|. Larger values indicate"
    di as txt "    greater asymmetry. Values > 0.5 suggest meaningful asymmetry."
    di as txt "  - {bf:Wald} p-value tests H0: parameter is CONSTANT across all quantiles."
    di as txt "    Reject (p<0.05) => quantile cointegration exists."
    di as txt _n
    di as res "  {bf:2. Coefficient Heatmap}"
    di as txt "  - Shows how each variable's coefficient changes across quantiles."
    di as txt "  - Red = above median value; Yellow = below median value."
    di as txt "  - If colors switch across quantiles, the effect is asymmetric."
    di as txt _n
    di as res "  {bf:3. Pairwise Equality Tests}"
    di as txt "  - Tests H0: beta(tau_i) = beta(tau_j) for each pair of quantiles."
    di as txt "  - Red cells (p<0.01) = coefficients differ significantly."
    di as txt "  - Identifies WHICH quantile pairs drive the asymmetry."
    di as txt _n
    di as res "  {bf:4. Fan Charts}"
    di as txt "  - All variables on one plot with 95% confidence bands."
    di as txt "  - Crossing lines indicate reversal of relative importance."
    di as txt "  - Wide bands = imprecise estimates at those quantiles."
    di as txt _n
    di as res "  {bf:5. Asymmetry Ratio Bar Chart}"
    di as txt "  - Blue bars = long-run (beta), Red bars = short-run (gamma)."
    di as txt "  - Dashed line at 1 = perfect symmetry."
    di as txt "  - Longer bars = stronger asymmetry for that variable."
    di as txt _n
    di as res "  {bf:6. Tail Divergence}"
    di as txt "  - Compares upper-tail vs lower-tail coefficients."
    di as txt "  - If CI excludes 0, the tails differ significantly."
    di as txt "  - Positive = stronger effect at upper quantiles (bullish)."
    di as txt "  - Negative = stronger effect at lower quantiles (bearish)."
    di as txt _n
    di as res "  {bf:7. Quantile Gradient}"
    di as txt "  - Shows d(beta)/d(tau): the RATE of change across quantiles."
    di as txt "  - Flat line = symmetric region (no change)."
    di as txt "  - Sharp spikes = asymmetry concentrated at specific quantiles."
    di as txt _n
    di as res "  {bf:8. ECM Speed of Adjustment}"
    di as txt "  - Bar chart of rho(tau) = sum(phi) - 1 with 95% CI."
    di as txt "  - All bars below zero = convergence to equilibrium."
    di as txt "  - Larger |rho| = faster adjustment speed."
    di as txt _n
    di as res "  {bf:9. Pairwise p-value Plots}"
    di as txt "  - Green dots = accept equality (no asymmetry for that pair)."
    di as txt "  - Red dots = reject equality (significant difference)."
    di as txt "  - Identifies WHICH quantile pairs and variables drive asymmetry."
    di as txt "{hline 78}"
    di as txt "  Reference: Cho, Kim & Shin (2015), Journal of Econometrics, 188(2), 281-300."
    di as txt "{hline 78}"
    
end
