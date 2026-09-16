*! tvtie_p 1.2.0 13sep2026
*! Levent Kutlu
*! Copyright (C) 2026 Levent Kutlu. GNU GPL v3; see tvtie_license.txt.
program define tvtie_p
    version 16.0
    if "`e(cmd)'" != "tvtie" error 301
    syntax newvarname [if] [in] [, XB INEFFiciency EFFiciency MEANTE FE CF ///
        FITTED RESiduals USCale U0 U0SD UQuantile(string) TEQuantile(string)]
    local statistic ""
    local count 0
    foreach s in xb inefficiency efficiency meante fe cf fitted residuals uscale u0 u0sd {
        if "``s''" != "" {
            local statistic "`s'"
            local ++count
        }
    }
    local probability .5
    if "`uquantile'" != "" {
        local statistic "uquantile"
        local probability = real("`uquantile'")
        local ++count
    }
    if "`tequantile'" != "" {
        local statistic "tequantile"
        local probability = real("`tequantile'")
        local ++count
    }
    if `count' > 1 {
        di as error "Specify only one prediction statistic."
        exit 198
    }
    if `count' == 0 local statistic "xb"
    if `probability' <= 0 | `probability' >= 1 {
        di as error "Quantile probabilities must lie strictly between zero and one."
        exit 198
    }
    marksample targetuse, novarlist
    tempvar touse
    quietly generate byte `touse' = e(sample)
    quietly count if `touse'
    if r(N) != e(N) {
        di as error "The estimation sample is unavailable. Restore the estimation data and sample first."
        exit 459
    }
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
    _tvtie_load
    quietly generate `typlist' `varlist' = .
    capture noisily mata: _tvtie_predict("`varlist'","`targetuse'","`statistic'",`probability')
    if _rc {
        local rc = _rc
        quietly drop `varlist'
        exit `rc'
    }
    label variable `varlist' "tvtie: `statistic'"
end
