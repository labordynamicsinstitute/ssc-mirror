*! tvtie_estat 1.2.0 13sep2026
*! Levent Kutlu
*! Copyright (C) 2026 Levent Kutlu. GNU GPL v3; see tvtie_license.txt.
program define tvtie_estat, rclass
    version 16.0
    if "`e(cmd)'" != "tvtie" error 301
    gettoken subcmd rest : 0, parse(" ,")
    local subcmd = lower("`subcmd'")
    if "`subcmd'" == "hettest" {
        local 0 `"`rest'"'
        syntax [, TREND(integer 2) HETerogeneity(varlist numeric) TIME(varname numeric) TIMEVarying ASymptotic BOOTstrap REPS(integer 199) SEED(integer 873921) STARTS(integer 2)]
        if "`bootstrap'"!="" & "`asymptotic'"!="" {
            di as error "Choose bootstrap or asymptotic, not both."
            exit 198
        }
        if "`asymptotic'"=="" {
            local alternative "trend(`trend') `timevarying'"
            if "`heterogeneity'"!="" local alternative "heterogeneity(`heterogeneity') `timevarying'"
            if "`time'"!="" local alternative "`alternative' time(`time')"
            _tvtie_bootstrap, kind(heterogeneity) reps(`reps') seed(`seed') starts(`starts') alternative(`alternative')
            return add
            exit
        }
        if "`timevarying'" == "" & (e(k_het)!=0 | e(frontier_constant)!=1) {
            di as error "Fit the null model with nohet and a common intercept before estat hettest."
            exit 198
        }
        if "`timevarying'" != "" & (e(k_het)!=1 | e(absorbs_constant)!=1) {
            di as error "Fit the time-invariant null model with trend(0) before estat hettest, timevarying."
            exit 198
        }
        if `trend'<0 | `trend'>8 | ("`timevarying'"!="" & `trend'==0 & "`heterogeneity'"=="") error 198
        if "`time'"=="" local time "`e(tvar)'"
        if "`heterogeneity'"=="" & `trend'>0 & "`time'"=="" {
            di as error "Specify time() or fit the model with a declared time variable."
            exit 198
        }
        tempvar touse xb u v
        quietly generate byte `touse'=e(sample)
        quietly predict double `xb', xb
        quietly predict double `u', inefficiency
        quietly generate double `v'=`e(depvar)'-`xb'+e(sign)*`u' if `touse'
        local id "`e(ivar)'"
        local response "`v'"
        tempname statistics
        _tvtie_load
        mata: _tvtie_hettest("`statistics'")
        return scalar F = el(`statistics',1,1)
        return scalar df = el(`statistics',1,2)
        return scalar df_r = el(`statistics',1,3)
        return scalar p = el(`statistics',1,4)
        return scalar N = el(`statistics',1,5)
        return scalar N_g = el(`statistics',1,6)
        return scalar rss_null = el(`statistics',1,7)
        return scalar rss_alternative = el(`statistics',1,8)
        return local method "asymptotic F reference"
        di as txt "Residual-regression heterogeneity diagnostic"
        if "`timevarying'"=="" di as txt "H0: no individual heterogeneity beyond a common intercept."
        else di as txt "H0: individual heterogeneity is time-invariant."
        di as txt "F(" as res el(`statistics',1,2) as txt ", " as res el(`statistics',1,3) as txt ") = " as res %10.4f el(`statistics',1,1) as txt "   Prob > F = " as res %7.5f el(`statistics',1,4)
        di as txt "Uses predicted noise; the approximate F reference can be conservative. Consider estat hettest, bootstrap."
        di as txt "This diagnostic does not provide cluster-robust or weak-identification-robust inference."
        exit
    }
    if "`subcmd'" == "endogeneity" {
        if "`e(endogenous)'" == "" {
            di as error "No endogenous variables were fitted."
            exit 198
        }
        local 0 `"`rest'"'
        syntax [, BOOTstrap REPS(integer 199) SEED(integer 873921) STARTS(integer 2)]
        if "`bootstrap'"!="" {
            _tvtie_bootstrap, kind(endogeneity) reps(`reps') seed(`seed') starts(`starts')
            return add
            exit
        }
        local restrictions ""
        foreach x in `e(endogenous)' {
            local restrictions `"`restrictions' ([eta]`x'=0)"'
        }
        test `restrictions'
        return scalar chi2 = r(chi2)
        return scalar df = r(df)
        return scalar p = r(p)
        exit
    }
    if "`subcmd'" == "diagnostics" {
        if strtrim(`"`rest'"') != "" error 198
        di as txt "Scaled score infinity norm: " as res %12.4e e(score_scaled)
        di as txt "Equilibrated information condition number: " as res %12.4e e(information_condition)
        di as txt "Fraction of squared scaling retained by projection: " as res %12.6f e(scale_survival)
        di as txt "Multiple-start results (accepted = stationarity threshold met):"
        matlist e(starts), names(columns) format(%12.6g)
        return scalar score_scaled = e(score_scaled)
        return scalar information_condition = e(information_condition)
        return scalar scale_survival = e(scale_survival)
        tempname starts diagnostics
        matrix `starts' = e(starts)
        matrix `diagnostics' = e(diagnostics)
        return matrix starts = `starts'
        return matrix diagnostics = `diagnostics'
        exit
    }
    if "`subcmd'" == "firststage" {
        if "`e(endogenous)'" == "" {
            di as error "No reduced-form equations were fitted."
            exit 198
        }
        local 0 `"`rest'"'
        syntax [, DETAIL]
        di as txt "OLS first-stage diagnostics in the projected sample:"
        matlist e(firststage), format(%12.6g)
        di as txt "These classical F statistics are descriptive strength diagnostics, not weak-IV-robust tests."
        if "`detail'" != "" {
            di as txt "Joint maximum-likelihood reduced-form coefficients:"
            matlist e(delta), format(%12.6g)
            di as txt "Reduced-form residual covariance:"
            matlist e(Omega), format(%12.6g)
        }
        tempname firststage delta omega
        matrix `firststage' = e(firststage)
        matrix `delta' = e(delta)
        matrix `omega' = e(Omega)
        return matrix firststage = `firststage'
        return matrix delta = `delta'
        return matrix Omega = `omega'
        exit
    }
    if "`subcmd'" == "components" {
        if strtrim(`"`rest'"') != "" error 198
        di as txt "Conditional noise SD (sigma_r): " as res %12.6g sqrt(e(sigma_r2))
        di as txt "Unconditional noise SD (sigma_v): " as res %12.6g sqrt(e(sigma_v2))
        di as txt "Untruncated latent scale (sigma_u): " as res %12.6g sqrt(e(sigma_u2))
        di as txt "Untruncated latent location (mu): " as res %12.6g e(mu)
        return scalar sigma_r = sqrt(e(sigma_r2))
        return scalar sigma_v = sqrt(e(sigma_v2))
        return scalar sigma_u = sqrt(e(sigma_u2))
        return scalar mu = e(mu)
        exit
    }
    if "`subcmd'" == "heterogeneity" {
        if strtrim(`"`rest'"') != "" error 198
        if e(k_het) == 0 {
            di as error "No individual effects were fitted."
            exit 198
        }
        tempvar touse
        quietly generate byte `touse' = e(sample)
        local depvar "`e(depvar)'"
        local indepvars "`e(indepvars)'"
        local id "`e(ivar)'"
        local time "`e(tvar)'"
        local uhet "`e(uhet)'"
        local heterogeneity "`e(heterogeneity)'"
        local trend = e(trend)
        local endogenous "`e(endogenous)'"
        local instruments "`e(instruments)'"
        local zvars "`e(zvars)'"
        local nohet "`e(nohet)'"
        local nohetconstant "`e(nohetconstant)'"
        local noconstant "`e(noconstant)'"
        local cost "`e(cost)'"
        local distribution "`e(distribution)'"
        local dropshort ""
        local clustvar ""
        local bases ""
        if "`indepvars'`zvars'"!="" {
            quietly fvrevar `indepvars' `zvars', list
            local bases "`r(varlist)'"
        }
        markout `touse' `depvar' `bases' `id' `time' `uhet' `heterogeneity' `endogenous'
        quietly count if `touse'
        if r(N) != e(N) error 459
        _tvtie_load
        tempname alpha ids
        mata: _tvtie_heterogeneity("`alpha'","`ids'")
        return matrix alpha = `alpha'
        return matrix panel_id = `ids'
        return scalar time_center = e(time_center)
        return scalar time_scale = e(time_scale)
        di as txt "Recovered coefficients are in r(alpha); matching panel identifiers are in r(panel_id)."
        di as txt "These are the paper's plug-in individual-effect estimates, not a formal heterogeneity test."
        exit
    }
    estat_default `0'
end
