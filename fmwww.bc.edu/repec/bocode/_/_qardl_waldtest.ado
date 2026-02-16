*! _qardl_waldtest v1.0.0 - Wald tests for QARDL parameters
*! Translates wtestlrb, wtestsrp, wtestsrg, wtestphi, wtesttheta
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _qardl_waldtest, rclass
    version 14.0
    
    syntax, TYpe(string) TAU(numlist >0 <1 sort) ///
        [R(string) r(string)]
    
    * Types: beta, phi, gamma, phi_ecm, theta
    
    if "`e(cmd)'" != "qardl" {
        di as error "qardl estimation results not found"
        exit 301
    }
    
    local nobs = e(N)
    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    
    if "`type'" == "beta" {
        tempname param cov
        mat `param' = e(beta)
        mat `cov' = e(beta_cov)
        
        * Build restriction matrix
        if "`R'" != "" {
            tempname Rmat rmat
            mat `Rmat' = `R'
            mat `rmat' = `r'
        }
        else {
            * Default: constancy across quantiles
            mata: _qardl_build_constancy_R(`k', `ntau', "__tmpR", "__tmpr")
            tempname Rmat rmat
            mat `Rmat' = __tmpR
            mat `rmat' = __tmpr
        }
        
        * Compute Wald statistic
        mata: _qardl_wald_stat("`param'", "`cov'", "`Rmat'", ///
            "`rmat'", `nobs', "lr", "__tmpW")
        
        local wstat = __tmpW[1,1]
        local df = rowsof(`Rmat')
        local pval = chi2tail(`df', `wstat')
        
        di as txt _n
        di as txt "{hline 50}"
        di as res "  Wald Test: Long-Run Parameter beta"
        di as txt "{hline 50}"
        di as txt "  W(beta)   = " as res %12.4f `wstat'
        di as txt "  df        = " as res `df'
        di as txt "  p-value   = " _c
        if `pval' < 0.05 {
            di as err %12.4f `pval'
        }
        else {
            di as res %12.4f `pval'
        }
        di as txt "{hline 50}"
        
        return scalar wald = `wstat'
        return scalar df = `df'
        return scalar pval = `pval'
    }
    else if "`type'" == "phi" {
        tempname param cov
        mat `param' = e(phi)
        mat `cov' = e(phi_cov)
        
        if "`R'" != "" {
            tempname Rmat rmat
            mat `Rmat' = `R'
            mat `rmat' = `r'
        }
        else {
            mata: _qardl_build_constancy_R(`p', `ntau', "__tmpR", "__tmpr")
            tempname Rmat rmat
            mat `Rmat' = __tmpR
            mat `rmat' = __tmpr
        }
        
        mata: _qardl_wald_stat("`param'", "`cov'", "`Rmat'", ///
            "`rmat'", `nobs', "sr", "__tmpW")
        
        local wstat = __tmpW[1,1]
        local df = rowsof(`Rmat')
        local pval = chi2tail(`df', `wstat')
        
        di as txt _n
        di as txt "{hline 50}"
        di as res "  Wald Test: Short-Run Parameter phi"
        di as txt "{hline 50}"
        di as txt "  W(phi)    = " as res %12.4f `wstat'
        di as txt "  df        = " as res `df'
        di as txt "  p-value   = " _c
        if `pval' < 0.05 {
            di as err %12.4f `pval'
        }
        else {
            di as res %12.4f `pval'
        }
        di as txt "{hline 50}"
        
        return scalar wald = `wstat'
        return scalar df = `df'
        return scalar pval = `pval'
    }
    else if "`type'" == "gamma" {
        tempname param cov
        mat `param' = e(gamma)
        mat `cov' = e(gamma_cov)
        
        if "`R'" != "" {
            tempname Rmat rmat
            mat `Rmat' = `R'
            mat `rmat' = `r'
        }
        else {
            mata: _qardl_build_constancy_R(`k', `ntau', "__tmpR", "__tmpr")
            tempname Rmat rmat
            mat `Rmat' = __tmpR
            mat `rmat' = __tmpr
        }
        
        mata: _qardl_wald_stat("`param'", "`cov'", "`Rmat'", ///
            "`rmat'", `nobs', "sr", "__tmpW")
        
        local wstat = __tmpW[1,1]
        local df = rowsof(`Rmat')
        local pval = chi2tail(`df', `wstat')
        
        di as txt _n
        di as txt "{hline 50}"
        di as res "  Wald Test: Short-Run Parameter gamma"
        di as txt "{hline 50}"
        di as txt "  W(gamma)  = " as res %12.4f `wstat'
        di as txt "  df        = " as res `df'
        di as txt "  p-value   = " _c
        if `pval' < 0.05 {
            di as err %12.4f `pval'
        }
        else {
            di as res %12.4f `pval'
        }
        di as txt "{hline 50}"
        
        return scalar wald = `wstat'
        return scalar df = `df'
        return scalar pval = `pval'
    }
    else if "`type'" == "phi_ecm" {
        if "`e(model)'" != "qardl-ecm" {
            di as error "ECM results not available. Use ecm option."
            exit 198
        }
        
        tempname param cov
        mat `param' = e(phi_ecm)
        mat `cov' = e(phi_ecm_cov)
        local pp1 = `p' - 1
        if `pp1' < 1 local pp1 = 1
        
        if "`R'" != "" {
            tempname Rmat rmat
            mat `Rmat' = `R'
            mat `rmat' = `r'
        }
        else {
            mata: _qardl_build_constancy_R(`pp1', `ntau', "__tmpR", "__tmpr")
            tempname Rmat rmat
            mat `Rmat' = __tmpR
            mat `rmat' = __tmpr
        }
        
        mata: _qardl_wald_stat("`param'", "`cov'", "`Rmat'", ///
            "`rmat'", `nobs', "sr", "__tmpW")
        
        local wstat = __tmpW[1,1]
        local df = rowsof(`Rmat')
        local pval = chi2tail(`df', `wstat')
        
        di as txt _n
        di as txt "{hline 50}"
        di as res "  Wald Test: ECM Parameter phi*"
        di as txt "{hline 50}"
        di as txt "  W(phi*)   = " as res %12.4f `wstat'
        di as txt "  df        = " as res `df'
        di as txt "  p-value   = " _c
        if `pval' < 0.05 {
            di as err %12.4f `pval'
        }
        else {
            di as res %12.4f `pval'
        }
        di as txt "{hline 50}"
        
        return scalar wald = `wstat'
        return scalar df = `df'
        return scalar pval = `pval'
    }
    else if "`type'" == "theta" {
        if "`e(model)'" != "qardl-ecm" {
            di as error "ECM results not available. Use ecm option."
            exit 198
        }
        
        tempname param cov
        mat `param' = e(theta)
        mat `cov' = e(theta_cov)
        local tdim = `q' * `k'
        
        if "`R'" != "" {
            tempname Rmat rmat
            mat `Rmat' = `R'
            mat `rmat' = `r'
        }
        else {
            mata: _qardl_build_constancy_R(`tdim', `ntau', "__tmpR", "__tmpr")
            tempname Rmat rmat
            mat `Rmat' = __tmpR
            mat `rmat' = __tmpr
        }
        
        mata: _qardl_wald_stat("`param'", "`cov'", "`Rmat'", ///
            "`rmat'", `nobs', "sr2", "__tmpW")
        
        local wstat = __tmpW[1,1]
        local df = rowsof(`Rmat')
        local pval = chi2tail(`df', `wstat')
        
        di as txt _n
        di as txt "{hline 50}"
        di as res "  Wald Test: ECM Parameter theta"
        di as txt "{hline 50}"
        di as txt "  W(theta)  = " as res %12.4f `wstat'
        di as txt "  df        = " as res `df'
        di as txt "  p-value   = " _c
        if `pval' < 0.05 {
            di as err %12.4f `pval'
        }
        else {
            di as res %12.4f `pval'
        }
        di as txt "{hline 50}"
        
        return scalar wald = `wstat'
        return scalar df = `df'
        return scalar pval = `pval'
    }
    else {
        di as error "invalid test type: `type'"
        di as error "valid types: beta, phi, gamma, phi_ecm, theta"
        exit 198
    }
end
