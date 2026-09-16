*! _tvtie_bootstrap 1.2.0 13sep2026
*! Levent Kutlu
*! Copyright (C) 2026 Levent Kutlu. GNU GPL v3; see tvtie_license.txt.
program define _tvtie_bootstrap, rclass
    version 16.0
    syntax , KIND(string) REPS(integer) SEED(integer) STARTS(integer) [ALTERNATIVE(string)]
    if `reps'<19 | `reps'>99999 | `starts'<1 | `starts'>100 | `seed'<0 | `seed'>2147483647 error 198
    if `reps'>c(max_matsize) {
        di as error "reps() exceeds this Stata edition's matrix limit of " c(max_matsize) ". Use fewer replications."
        exit 198
    }
    if "`e(vce)'"!="oim" {
        di as error "This parametric bootstrap requires vce(oim) and the maintained independent-panel model."
        exit 198
    }
    if "`e(endogenous)'"!="" & ("`e(endof_declared)'"!="" | ("`e(endofunctions)'"!="" & "`e(endof_automatic)'"=="")) {
        di as error "Bootstrap draws must reconstruct endogenous functions. Use continuous factor notation instead of endof() for this calculation."
        exit 198
    }
    local protected "`e(ivar)' `e(tvar)' `e(heterogeneity)'"
    local endogenous "`e(endogenous)'"
    local conflict : list protected & endogenous
    if "`conflict'"!="" {
        di as error "The bootstrap requires fixed panel identifiers, times, and heterogeneity basis variables."
        exit 198
    }
    tempname held drawstate
    estimates store `held'
    local rngstate `"`c(rngstate)'"'
    preserve
    set seed `seed'
    capture noisily _tvtie_bootstrap_work, kind(`kind') reps(`reps') starts(`starts') alternative(`alternative') drawstate(`drawstate')
    local rc=_rc
    if !`rc' return add
    capture mata: mata drop `drawstate'
    restore
    quietly estimates restore `held'
    quietly estimates drop `held'
    quietly set rngstate `rngstate'
    if `rc' exit `rc'
    return scalar seed=`seed'
    return local method "parametric bootstrap with null re-estimation"
end

program define _tvtie_bootstrap_work, rclass
    version 16.0
    syntax , KIND(string) REPS(integer) STARTS(integer) DRAWSTATE(name) [ALTERNATIVE(string)]
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"
    local id "`e(ivar)'"
    local time "`e(tvar)'"
    local uhet "`e(uhet)'"
    local heterogeneity "`e(heterogeneity)'"
    local trend=e(trend)
    local endogenous "`e(endogenous)'"
    local instruments "`e(instruments)'"
    local zvars "`e(zvars)'"
    local nohet "`e(nohet)'"
    local nohetconstant "`e(nohetconstant)'"
    local noconstant "`e(noconstant)'"
    local cost "`e(cost)'"
    local distribution "`e(distribution)'"
    local rfvars "`e(rfvars)'"
    local dropshort ""
    local clustvar ""
    tempvar touse
    quietly generate byte `touse'=e(sample)
    tempname original generator simulated statistic attempted
    matrix `original'=e(b)
    local fitopts "id(`id') `cost' `noconstant' distribution(`distribution') starts(`starts') nolog"
    if "`time'"!="" local fitopts "`fitopts' time(`time')"
    if "`uhet'"!="" local fitopts "`fitopts' uhet(`uhet')"
    if "`nohet'"!="" local fitopts "`fitopts' nohet"
    else if "`heterogeneity'"!="" local fitopts "`fitopts' heterogeneity(`heterogeneity') `nohetconstant'"
    else local fitopts "`fitopts' trend(`trend') `nohetconstant'"
    local endopts ""
    if "`endogenous'"!="" {
        local endopts "endogenous(`endogenous') instruments(`instruments')"
        if "`rfvars'"!="" local endopts "`endopts' rfvars(`rfvars')"
    }
    if "`kind'"=="heterogeneity" {
        quietly estat hettest, asymptotic `alternative'
        scalar `statistic'=r(F)
        local asymptotic=r(p)
    }
    else {
        quietly estat endogeneity
        scalar `statistic'=r(chi2)
        local asymptotic=r(p)
    }
    _tvtie_load
    mata: `drawstate'=_tvtie_setup()
    matrix `generator'=`original'
    if "`kind'"=="endogeneity" {
        tempname exostart
        mata: st_matrix("`exostart'",st_matrix("`original'")[1,1..(`drawstate'.ie[1]-1)])
        quietly tvtie `depvar' `indepvars' if `touse', `fitopts' from(`exostart')
        matrix `exostart'=e(b)
        mata: st_matrix("`generator'",_tvtie_boot_null(`drawstate',st_matrix("`original'"),st_matrix("`exostart'")))
    }
    matrix `attempted'=J(`reps',3,.)
    matrix colnames `attempted'=replication statistic return_code
    local exceed 0
    local failed 0
    forvalues replication=1/`reps' {
        mata: _tvtie_boot_draw(`drawstate',st_matrix("`generator'"))
        capture quietly tvtie `depvar' `indepvars' if `touse', `fitopts' `endopts' from(`generator')
        local rc=_rc
        local value=.
        if !`rc' {
            if "`kind'"=="heterogeneity" capture quietly estat hettest, asymptotic `alternative'
            else capture quietly estat endogeneity
            local rc=_rc
            if !`rc' {
                if "`kind'"=="heterogeneity" local value=r(F)
                else local value=r(chi2)
                if missing(`value') local rc=459
            }
        }
        if `rc' local ++failed
        else if `value'>=scalar(`statistic') local ++exceed
        matrix `attempted'[`replication',1]=`replication',`value',`rc'
    }
    local pcalc=cond(`failed'==0,(1+`exceed')/(`reps'+1),.)
    local mcsecalc=cond(`failed'==0,sqrt(`pcalc'*(1-`pcalc')/(`reps'+1)),.)
    return scalar statistic=scalar(`statistic')
    return scalar p_asymptotic=`asymptotic'
    return scalar reps=`reps'
    return scalar failed=`failed'
    return scalar exceedances=`exceed'
    return scalar p_lower=(1+`exceed')/(`reps'+1)
    return scalar p_upper=(1+`exceed'+`failed')/(`reps'+1)
    return scalar p=`pcalc'
    return scalar mcse=`mcsecalc'
    return matrix draws=`attempted'
    di as txt "Parametric bootstrap `kind' test"
    di as txt "Observed statistic = " as res %10.5f scalar(`statistic') as txt "   Bootstrap p-value = " as res %8.5f `pcalc'
    di as txt "Replications = " as res `reps' as txt "   Failed = " as res `failed' as txt "   Monte Carlo SE = " as res %8.5f `mcsecalc'
    if `failed' di as txt "No single p-value is reported because some replications failed. Bounds: [" as res %8.5f ((1+`exceed')/(`reps'+1)) as txt ", " as res %8.5f ((1+`exceed'+`failed')/(`reps'+1)) as txt "]."
    di as txt "The bootstrap re-estimates nuisance parameters and reconstructs predicted inefficiency in every successful draw."
    di as txt "Inference remains conditional on the maintained parametric model; it is not weak-instrument-robust."
end
