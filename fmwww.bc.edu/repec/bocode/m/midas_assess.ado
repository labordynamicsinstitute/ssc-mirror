*! version 1.0.1 26mar2026  Ben A. Dwamena (University of Michigan)
*! midas_assess: pre-model diagnostic battery for DTA meta-analysis
*! Runs bivbox + chiplot + kendall and synthesises a traffic-light report
*! v1.0.1: fix nested brackets in syntax statement causing r(197)

cap program drop midas_assess
program define midas_assess, rclass
    version 17

    syntax [varlist(min=4 max=4 numeric)] [if] [in] [, ///
        ID(varname)                    ///
        CC(real 0.5)                   ///
        CUTOff(real 7)                 ///
        BACONtest                      ///
        SAVEgraph(string)              ///
        * ]

    * --- Postestimation mode: recover counts from e(varlist) ---
    if ("`varlist'" == "") {
        capture confirm matrix e(varlist)
        if (_rc) {
            di as err "specify tp fp fn tn, or run after midas inla / midas qrsim"
            exit 198
        }
        local ecmd = e(cmd)
        local valid_cmds "midas_mle midas_inla midas_qrsim midas_mh midas_hmc"
        if (!regexm("`valid_cmds'", "`ecmd'")) {
            di as err "postestimation mode requires one of: `valid_cmds'"
            exit 198
        }
        tempvar _tp _fp _fn _tn
        qui svmat double e(varlist), names(col)
        qui rename tp `_tp'
        qui rename fp `_fp'
        qui rename fn `_fn'
        qui rename tn `_tn'
        local varlist "`_tp' `_fp' `_fn' `_tn'"
        di as txt "(midas assess: counts recovered from e(varlist) after " as res "`ecmd'" as txt ")"
    }

    marksample touse

    quietly count if `touse'
    if (r(N) == 0) error 2000
    local N = r(N)

    tokenize `varlist'
    local tp `1'
    local fp `2'
    local fn `3'
    local tn `4'

    * -------------------------------------------------------
    * COMPONENT 1: Bivariate boxplot + robnormtest
    * -------------------------------------------------------
    local idopt
    if ("`id'" != "") local idopt "id(`id') labeloutliers"

    local saveopt
    if (`"`savegraph'"' != "") local saveopt `"name(assess_bvb, replace)"'

    quietly midas_bivbox `varlist' if `touse', ///
        robust robnormtest cc(`cc') cutoff(`cutoff') `idopt' `saveopt' `options'

    local rqq        = r(robnorm_rqq)
    local maxdev     = r(robnorm_maxdev)
    local n_out      = r(n_out)
    local corr       = r(corr)
    local bvb_color  = "`r(diag_color)'"
    local bvb_text   = "`r(diag_text)'"

    return scalar robnorm_rqq    = `rqq'
    return scalar robnorm_maxdev = `maxdev'
    return scalar n_out          = `n_out'
    return scalar corr           = `corr'

    * -------------------------------------------------------
    * QQ Plot: squared Mahalanobis distances vs chi2(2)
    * -------------------------------------------------------
    tempvar lse lsp md2 chi2q qqrank
    qui gen double `lse' = logit((`tp' + `cc') / (`tp' + `fn' + 2*`cc')) if `touse'
    qui gen double `lsp' = logit((`tn' + `cc') / (`tn' + `fp' + 2*`cc')) if `touse'
    
    * Robust center and scatter via median/MAD
    qui sum `lse' if `touse', detail
    local med_se = r(p50)
    local mad_se = r(sd)
    qui sum `lsp' if `touse', detail
    local med_sp = r(p50)
    local mad_sp = r(sd)
    qui corr `lse' `lsp' if `touse'
    local rr = r(rho)
    
    * Squared Mahalanobis distance (using sample moments)
    local det = `mad_se'^2 * `mad_sp'^2 * (1 - `rr'^2)
    if `det' > 0 {
        qui gen double `md2' = (1/(1-`rr'^2)) * ( ///
            ((`lse' - `med_se')/`mad_se')^2 + ///
            ((`lsp' - `med_sp')/`mad_sp')^2 - ///
            2*`rr'*((`lse' - `med_se')/`mad_se')*((`lsp' - `med_sp')/`mad_sp') ///
            ) if `touse'
        
        * Chi-squared(2) quantiles
        qui egen `qqrank' = rank(`md2') if `touse'
        qui gen double `chi2q' = invchi2(2, (`qqrank' - 0.5) / `N') if `touse'
        
        * QQ plot
        #delimit ;
        qui twoway (scatter `md2' `chi2q' if `touse', 
                ms(Oh) mc(blue) msize(*0.9))
            (function y=x, range(0 20) lc(red) lp(dash)),
            ytitle("Observed Mahalanobis D{sup:2}", size(*0.85))
            xtitle("Expected {&chi}{sup:2}(2) quantiles", size(*0.85))
            legend(off)
            title("QQ Plot: Bivariate Normality Assessment", size(*0.8))
            subtitle("N = `N'   QQ corr = `: di %5.3f `rqq''", size(*0.7))
            aspect(1) name(assess_qq, replace) ;
        #delimit cr
        
        return scalar N       = `N'
        return scalar qq_corr = `rqq'
        return scalar max_abs_dev  = `maxdev'
        return scalar n_outliers   = `n_out'
        return scalar corr_logit   = `corr'
        return scalar signal       = `rqq' >= 0.97
    }
    else {
        di as txt "(QQ plot skipped: degenerate covariance)"
        return scalar N       = `N'
        return scalar qq_corr = `rqq'
        return scalar max_abs_dev  = `maxdev'
        return scalar n_outliers   = `n_out'
        return scalar corr_logit   = `corr'
        return scalar signal       = `rqq' >= 0.97
    }

    * -------------------------------------------------------
    * COMPONENT 2: Chi-plot (dependence structure)
    * -------------------------------------------------------
    quietly capture midas_chiplot `varlist' if `touse', cc(`cc')
    local chiplot_rc = _rc

    * -------------------------------------------------------
    * COMPONENT 3: Kendall concordance
    * -------------------------------------------------------
    quietly capture midas_kendall `varlist' if `touse', cc(`cc')
    local kendall_rc  = _rc
    local kendall_tau = .
    local kendall_p   = .
    if (`kendall_rc' == 0) {
        capture local kendall_tau = r(tau)
        capture local kendall_p   = r(p)
    }
    return scalar kendall_tau = `kendall_tau'
    return scalar kendall_p   = `kendall_p'

    * -------------------------------------------------------
    * COMPONENT 4: BACON (if requested)
    * -------------------------------------------------------
    local bacon_color ""
    local bacon_n     = .
    local bacon_prop  = .
    if ("`bacontest'" != "") {
        capture which bacon
        if (_rc) {
            di as txt "(bacontest skipped: {bf:bacon} not installed)"
        }
        else {
            quietly capture midas_bivbox `varlist' if `touse', ///
                robust bacontest cc(`cc') cutoff(`cutoff') `idopt'
            if (_rc == 0) {
                local bacon_n    = r(bacon_outliers)
                local bacon_prop = r(bacon_prop)
                local bacon_color = "`r(diag_color)'"
            }
        }
    }
    return scalar bacon_n    = `bacon_n'
    return scalar bacon_prop = `bacon_prop'

    * -------------------------------------------------------
    * Synthesise overall traffic-light
    * -------------------------------------------------------
    local overall_color "GREEN"
    local overall_text  "No evidence against bivariate normality"

    * Downgrade based on QQ correlation
    if (`rqq' < 0.93) {
        local overall_color "RED"
        local overall_text  "Strong evidence of non-ellipticity"
    }
    else if (`rqq' < 0.97 | `maxdev' >= 1) {
        local overall_color "YELLOW"
        local overall_text  "Moderate departure from ellipticity"
    }

    * Downgrade based on outlier proportion
    if (`n_out' > 0) {
        local outpct = 100 * `n_out' / `N'
        if (`outpct' > 25 & "`overall_color'" == "GREEN") {
            local overall_color "YELLOW"
            local overall_text  "Elevated outlier proportion"
        }
        if (`outpct' > 40) {
            local overall_color "RED"
            local overall_text  "High outlier proportion -- model assumptions suspect"
        }
    }

    * Factor in BACON if available
    if ("`bacon_color'" == "RED" & "`overall_color'" == "GREEN") {
        local overall_color "YELLOW"
        local overall_text  "BACON flags substantial contamination"
    }
    if ("`bacon_color'" == "RED" & "`overall_color'" == "YELLOW") {
        local overall_color "RED"
        local overall_text  "Convergent evidence of non-ellipticity"
    }

    return local overall_color "`overall_color'"
    return local overall_text  "`overall_text'"

    * -------------------------------------------------------
    * Print structured report
    * -------------------------------------------------------
    di as txt _n "{hline 60}"
    di as txt "  MIDAS Pre-Model Diagnostic Assessment"
    di as txt "  N studies = " as res `N' as txt "   Corr(logit sens, logit spec) = " as res %6.3f `corr'
    di as txt "{hline 60}"

    di as txt _n "  1. Bivariate ellipticity (robnormtest)"
    di as txt "     QQ correlation : " as res %8.4f `rqq'
    di as txt "     Max abs dev    : " as res %8.4f `maxdev'
    di as txt "     Outliers (n)   : " as res `n_out' as txt " / " as res `N'
    if ("`bvb_color'" != "") {
        di as txt "     Status         : " as res "`bvb_color' -- `bvb_text'"
    }

    if (`kendall_tau' < .) {
        di as txt _n "  2. Kendall tau (threshold effect)"
        di as txt "     tau = " as res %7.4f `kendall_tau' ///
                  as txt "   p = " as res %7.4f `kendall_p'
        if (`kendall_p' < 0.05) {
            di as txt "     " as result "Threshold effect likely present"
        }
        else {
            di as txt "     No significant threshold effect detected"
        }
    }

    if (`bacon_n' < .) {
        di as txt _n "  3. BACON multivariate outliers"
        di as txt "     Flagged: " as res `bacon_n' ///
                  as txt " (" as res %5.1f 100*`bacon_prop' as txt "%)"
        if ("`bacon_color'" != "") {
            di as txt "     Status : " as res "`bacon_color' -- (`bvb_text')"
        }
    }

    di as txt _n "{hline 60}"
    di as txt "  OVERALL ASSESSMENT"
    di as txt "{hline 60}"
    di as txt "  Status : " as result "`overall_color' -- `overall_text'"
    di as txt "{hline 60}"
    di as txt _n "  Recommended action:"
    if ("`overall_color'" == "GREEN") {
        di as txt "  Proceed with bivariate / HSROC pooling."
        di as txt "  midas mle / midas mh / midas hmc"
    }
    else if ("`overall_color'" == "YELLOW") {
        di as txt "  Proceed with caution."
        di as txt "  Inspect outliers: midas bivbox ... , id() labeloutliers"
        di as txt "  Run sensitivity analysis excluding flagged studies."
        di as txt "  Consider: midas mle with heterogeneity terms."
    }
    else {
        di as txt "  Bivariate normal assumption is questionable."
        di as txt "  Investigate subgroups, threshold effects, outliers."
        di as txt "  Consider non-parametric or robust pooling methods."
        di as txt "  midas mle with full covariance; midas hmc"
    }
    di as txt "{hline 60}"

end
