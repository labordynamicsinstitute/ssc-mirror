*! makicoint v1.0.0  30jan2026
*! Maki (2012) Cointegration Test with Multiple Structural Breaks
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com
*! Independent Researcher
*!
*! Reference: Maki, D. (2012). Tests for cointegration allowing for an 
*!            unknown number of breaks. Economic Modelling, 29, 2011-2015.

program define makicoint, rclass
    version 14.0
    
    syntax varlist(min=2 ts) [if] [in], ///
        Maxbreaks(integer) ///
        [ Model(integer 2) ///
          TRIMming(real 0.10) ///
          MAXLags(integer 12) ///
          LAGMethod(string) ]
    
    marksample touse
    
    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'
    
    if "`panelvar'" != "" {
        di as error "Panel data not supported. Please use single time series."
        exit 198
    }
    
    if "`timevar'" == "" {
        di as error "Time variable not set. Please use -tsset- first."
        exit 198
    }
    
    gettoken depvar indepvars : varlist
    local numindep : word count `indepvars'
    
    if `maxbreaks' < 1 | `maxbreaks' > 5 {
        di as error "Maximum number of breaks must be between 1 and 5."
        exit 198
    }
    
    if `model' < 0 | `model' > 3 {
        di as error "Model must be 0 (level shift), 1 (level shift with trend),"
        di as error "          2 (regime shift), or 3 (regime shift with trend)."
        exit 198
    }
    
    if `numindep' < 1 | `numindep' > 4 {
        di as error "Number of independent variables must be between 1 and 4."
        di as error "Critical values are not available for more than 4 regressors."
        exit 198
    }
    
    if `trimming' <= 0 | `trimming' >= 0.5 {
        di as error "Trimming parameter must be between 0 and 0.5 (exclusive)."
        exit 198
    }
    
    if `maxlags' < 0 {
        di as error "Maximum lags must be non-negative."
        exit 198
    }
    
    if "`lagmethod'" == "" {
        local lagmethod "tsig"
    }
    
    if !inlist("`lagmethod'", "tsig", "fixed", "aic", "bic") {
        di as error "lagmethod must be one of: tsig, fixed, aic, bic"
        exit 198
    }
    
    preserve
    
    qui keep if `touse'
    
    qui count
    local nobs = r(N)
    
    * Minimum sample size check
    if `nobs' < 30 {
        di as error "Sample size too small. Minimum 30 observations required."
        exit 198
    }
    
    * Warning for potentially small samples given breaks and trimming
    local min_recommended = ceil((`maxbreaks' + 1) / `trimming')
    
    if `nobs' < `min_recommended' {
        di as txt "Note: Sample size (`nobs') is small for `maxbreaks' breaks with trimming `trimming'."
        di as txt "      Recommended minimum: `min_recommended' observations."
        di as txt "      Results may be unreliable. Consider reducing maxbreaks or trimming."
    }
    
    foreach var of local varlist {
        qui count if missing(`var')
        if r(N) > 0 {
            di as error "Missing values found in `var'."
            exit 198
        }
    }
    
    qui gen _obsnum = _n
    qui gen _timevals = `timevar'
    
    mata: maki_main("`depvar'", "`indepvars'", `maxbreaks', `model', ///
                    `trimming', `maxlags', "`lagmethod'", `nobs')
    
    tempname test_stat breakpoints cv
    
    scalar `test_stat' = r(test_stat)
    local num_breaks = r(num_breaks)
    
    forvalues i = 1/`maxbreaks' {
        local bp`i' = r(bp`i')
        local bpdate`i' = r(bpdate`i')
        local bpfrac`i' = r(bpfrac`i')
    }
    
    local cv1 = r(cv1)
    local cv5 = r(cv5)
    local cv10 = r(cv10)
    local lags_used = r(lags_used)
    
    restore
    
    local model0 "Level Shift"
    local model1 "Level Shift with Trend"
    local model2 "Regime Shift"
    local model3 "Regime Shift with Trend"
    
    local tsig_name "t-sig"
    local fixed_name "Fixed"
    local aic_name "AIC"
    local bic_name "BIC"
    
    di ""
    di as txt "{hline 78}"
    di as txt _col(10) "{bf:Maki (2012) Cointegration Test with Multiple Structural Breaks}"
    di as txt "{hline 78}"
    di ""
    di as txt "Model: " as res "`model`model''"
    di as txt "Number of observations: " as res `nobs'
    di as txt "Maximum breaks: " as res `maxbreaks'
    di as txt "Trimming: " as res %5.2f `trimming'
    di as txt "Lag selection: " as res "``lagmethod'_name'" _col(45) as txt "Max lags: " as res `maxlags'
    di as txt "Lags used: " as res `lags_used'
    di ""
    di as txt "Dependent variable: " as res "`depvar'"
    di as txt "Independent variable(s): " as res "`indepvars'"
    di ""
    di as txt "{hline 78}"
    di as txt _col(5) "H0: No cointegration"
    di as txt _col(5) "H1: Cointegration with up to `maxbreaks' break(s)"
    di as txt "{hline 78}"
    di ""
    
    di as txt "{hline 48}"
    di as txt "Test Statistic" _col(25) "{c |}" _col(35) "Critical Values"
    di as txt "{hline 24}{c +}{hline 23}"
    di as txt _col(25) "{c |}" _col(30) "1%" _col(38) "5%" _col(46) "10%"
    di as txt "{hline 24}{c +}{hline 23}"
    di as res %12.4f `test_stat' _col(25) as txt "{c |}" ///
       as res _col(27) %8.3f `cv1' _col(35) %8.3f `cv5' _col(43) %8.3f `cv10'
    di as txt "{hline 48}"
    di ""
    
    di as txt "{hline 60}"
    di as txt "Estimated Break Points"
    di as txt "{hline 60}"
    di as txt _col(5) "Break" _col(15) "Observation" _col(32) "Date" _col(50) "Fraction"
    di as txt "{hline 60}"
    
    forvalues i = 1/`maxbreaks' {
        if `bp`i'' > 0 {
            di as txt _col(7) as res `i' _col(17) `bp`i'' _col(30) `bpdate`i'' _col(50) %6.4f `bpfrac`i''
        }
    }
    di as txt "{hline 60}"
    di ""
    
    di as txt "{hline 78}"
    if `test_stat' < `cv1' {
        di as res "Conclusion: Reject H0 at 1% significance level."
        di as res "            Evidence of cointegration with structural break(s)."
        local reject = 1
    }
    else if `test_stat' < `cv5' {
        di as res "Conclusion: Reject H0 at 5% significance level."
        di as res "            Evidence of cointegration with structural break(s)."
        local reject = 1
    }
    else if `test_stat' < `cv10' {
        di as res "Conclusion: Reject H0 at 10% significance level."
        di as res "            Evidence of cointegration with structural break(s)."
        local reject = 1
    }
    else {
        di as res "Conclusion: Fail to reject H0."
        di as res "            No evidence of cointegration."
        local reject = 0
    }
    di as txt "{hline 78}"
    di ""
    
    return scalar test_stat = `test_stat'
    return scalar cv1 = `cv1'
    return scalar cv5 = `cv5'
    return scalar cv10 = `cv10'
    return scalar nobs = `nobs'
    return scalar maxbreaks = `maxbreaks'
    return scalar model = `model'
    return scalar trimming = `trimming'
    return scalar lags = `lags_used'
    return scalar reject = `reject'
    
    forvalues i = 1/`maxbreaks' {
        return scalar bp`i' = `bp`i''
        return scalar bpdate`i' = `bpdate`i''
        return scalar bpfrac`i' = `bpfrac`i''
    }
    
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
    return local model_name "`model`model''"
    return local lagmethod "`lagmethod'"
    
end

version 14.0
mata:
mata clear
mata set matastrict on

void maki_main(string scalar depvar, string scalar indepvars, 
               real scalar m, real scalar model, 
               real scalar trimm, real scalar maxlags,
               string scalar lagmethod, real scalar nobs)
{
    real matrix datap, Y, X
    real vector y, breakpoints, breakdates, breakfracs
    real scalar test_stat, tb, i, lag_used
    real rowvector cv
    string rowvector xvars
    
    y = st_data(., depvar)
    xvars = tokens(indepvars)
    X = st_data(., xvars)
    
    datap = y, X
    
    tb = round(trimm * nobs)
    
    breakpoints = J(5, 1, 0)
    breakdates = J(5, 1, 0)
    breakfracs = J(5, 1, 0)
    
    test_stat = maki_test(datap, m, model, tb, maxlags, lagmethod, 
                          breakpoints, lag_used)
    
    real vector timevals
    timevals = st_data(., "_timevals")
    
    for (i = 1; i <= m; i++) {
        if (breakpoints[i] > 0) {
            breakdates[i] = timevals[breakpoints[i]]
            breakfracs[i] = breakpoints[i] / nobs
        }
    }
    
    cv = get_critical_values(cols(X), m, model)
    
    st_numscalar("r(test_stat)", test_stat)
    st_numscalar("r(num_breaks)", m)
    st_numscalar("r(lags_used)", lag_used)
    
    for (i = 1; i <= 5; i++) {
        st_numscalar("r(bp" + strofreal(i) + ")", breakpoints[i])
        st_numscalar("r(bpdate" + strofreal(i) + ")", breakdates[i])
        st_numscalar("r(bpfrac" + strofreal(i) + ")", breakfracs[i])
    }
    
    st_numscalar("r(cv1)", cv[1])
    st_numscalar("r(cv5)", cv[2])
    st_numscalar("r(cv10)", cv[3])
}

real scalar maki_test(real matrix datap, real scalar m, real scalar model,
                      real scalar tb, real scalar maxlags, string scalar lagmethod,
                      real vector breakpoints, real scalar lag_used)
{
    real scalar n, mintau, mintau1, mintau2, mintau3, mintau4, mintau5
    real scalar bp1, bp2, bp3, bp4, bp5
    real vector bp, bp123, bp1234, alltau
    
    n = rows(datap)
    
    if (m == 1) {
        mintau1 = mbreak1(datap, n, model, tb, maxlags, lagmethod, bp1, lag_used)
        mintau = mintau1
        breakpoints[1] = bp1
    }
    else if (m == 2) {
        mintau1 = mbreak1(datap, n, model, tb, maxlags, lagmethod, bp1, lag_used)
        mintau2 = mbreak2(datap, n, model, tb, bp1, maxlags, lagmethod, bp2, lag_used)
        
        alltau = (mintau1 \ mintau2)
        mintau = min(alltau)
        
        bp = sort((bp1 \ bp2), 1)
        breakpoints[1] = bp[1]
        breakpoints[2] = bp[2]
    }
    else if (m == 3) {
        mintau1 = mbreak1(datap, n, model, tb, maxlags, lagmethod, bp1, lag_used)
        mintau2 = mbreak2(datap, n, model, tb, bp1, maxlags, lagmethod, bp2, lag_used)
        
        bp = sort((bp1 \ bp2), 1)
        mintau3 = mbreak3(datap, n, model, tb, bp, maxlags, lagmethod, bp3, lag_used)
        
        alltau = (mintau1 \ mintau2 \ mintau3)
        mintau = min(alltau)
        
        bp = sort((bp1 \ bp2 \ bp3), 1)
        breakpoints[1] = bp[1]
        breakpoints[2] = bp[2]
        breakpoints[3] = bp[3]
    }
    else if (m == 4) {
        mintau1 = mbreak1(datap, n, model, tb, maxlags, lagmethod, bp1, lag_used)
        mintau2 = mbreak2(datap, n, model, tb, bp1, maxlags, lagmethod, bp2, lag_used)
        
        bp = sort((bp1 \ bp2), 1)
        mintau3 = mbreak3(datap, n, model, tb, bp, maxlags, lagmethod, bp3, lag_used)
        
        bp123 = sort((bp1 \ bp2 \ bp3), 1)
        mintau4 = mbreak4(datap, n, model, tb, bp123, maxlags, lagmethod, bp4, lag_used)
        
        alltau = (mintau1 \ mintau2 \ mintau3 \ mintau4)
        mintau = min(alltau)
        
        bp = sort((bp1 \ bp2 \ bp3 \ bp4), 1)
        breakpoints[1] = bp[1]
        breakpoints[2] = bp[2]
        breakpoints[3] = bp[3]
        breakpoints[4] = bp[4]
    }
    else if (m == 5) {
        mintau1 = mbreak1(datap, n, model, tb, maxlags, lagmethod, bp1, lag_used)
        mintau2 = mbreak2(datap, n, model, tb, bp1, maxlags, lagmethod, bp2, lag_used)
        
        bp = sort((bp1 \ bp2), 1)
        mintau3 = mbreak3(datap, n, model, tb, bp, maxlags, lagmethod, bp3, lag_used)
        
        bp123 = sort((bp1 \ bp2 \ bp3), 1)
        mintau4 = mbreak4(datap, n, model, tb, bp123, maxlags, lagmethod, bp4, lag_used)
        
        bp1234 = sort((bp1 \ bp2 \ bp3 \ bp4), 1)
        mintau5 = mbreak5(datap, n, model, tb, bp1234, maxlags, lagmethod, bp5, lag_used)
        
        alltau = (mintau1 \ mintau2 \ mintau3 \ mintau4 \ mintau5)
        mintau = min(alltau)
        
        bp = sort((bp1 \ bp2 \ bp3 \ bp4 \ bp5), 1)
        breakpoints[1] = bp[1]
        breakpoints[2] = bp[2]
        breakpoints[3] = bp[3]
        breakpoints[4] = bp[4]
        breakpoints[5] = bp[5]
    }
    
    return(mintau)
}

real scalar mbreak1(real matrix datap, real scalar n, real scalar model,
                    real scalar tb, real scalar maxlags, string scalar lagmethod,
                    real scalar bp1, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du, e, dy, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx, tr, dtr
    
    y = datap[., 1]
    k = cols(datap)
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = tb + 1; i <= n - tb; i++) {
        u = J(n, 1, 1)
        du = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du
            dx = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx
        }
        else if (model == 3) {
            tr = (1::n)
            dtr = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du, tr, dtr
            dx = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx
        }
        
        e = get_residuals(y, X)
        
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[tb + 1..n - tb])
    
    minssr = .
    minidx = tb + 1
    for (i = tb + 1; i <= n - tb; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp1 = minidx
    
    return(mintau)
}

real scalar mbreak2(real matrix datap, real scalar n, real scalar model,
                    real scalar tb, real scalar bp1_in, real scalar maxlags,
                    string scalar lagmethod, real scalar bp2, real scalar lag_used)
{
    real scalar mintau, tau1, tau2, bp21, bp22
    
    if (bp1_in <= 0.1 * n) {
        tau2 = mbreak22(datap, n, model, tb, bp1_in, maxlags, lagmethod, bp22, lag_used)
        mintau = tau2
        bp2 = bp22
    }
    else if (bp1_in >= 0.9 * n) {
        tau1 = mbreak21(datap, n, model, tb, bp1_in, maxlags, lagmethod, bp21, lag_used)
        mintau = tau1
        bp2 = bp21
    }
    else {
        tau1 = mbreak21(datap, n, model, tb, bp1_in, maxlags, lagmethod, bp21, lag_used)
        tau2 = mbreak22(datap, n, model, tb, bp1_in, maxlags, lagmethod, bp22, lag_used)
        
        if (tau1 < tau2) {
            mintau = tau1
            bp2 = bp21
        }
        else {
            mintau = tau2
            bp2 = bp22
        }
    }
    
    return(mintau)
}

real scalar mbreak21(real matrix datap, real scalar n, real scalar model,
                     real scalar tb, real scalar bp1_in, real scalar maxlags,
                     string scalar lagmethod, real scalar bp21, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du1, du2, e, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx1, dx2, tr, dtr1, dtr2
    
    y = datap[., 1]
    k = cols(datap)
    
    u = J(n, 1, 1)
    du1 = (J(bp1_in, 1, 0) \ J(n - bp1_in, 1, 1))
    dx1 = (J(bp1_in, k - 1, 0) \ datap[bp1_in + 1..n, 2..k])
    dtr1 = (J(bp1_in, 1, 0) \ (bp1_in + 1::n))
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = tb + 1; i <= bp1_in - tb; i++) {
        du2 = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du1, du2
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du1, du2
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du1, du2
            dx2 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2
        }
        else if (model == 3) {
            tr = (1::n)
            dtr2 = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du1, du2, tr, dtr1, dtr2
            dx2 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2
        }
        
        e = get_residuals(y, X)
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[tb + 1..bp1_in - tb])
    
    minssr = .
    minidx = tb + 1
    for (i = tb + 1; i <= bp1_in - tb; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp21 = minidx
    
    return(mintau)
}

real scalar mbreak22(real matrix datap, real scalar n, real scalar model,
                     real scalar tb, real scalar bp1_in, real scalar maxlags,
                     string scalar lagmethod, real scalar bp22, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du1, du2, e, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx1, dx2, tr, dtr1, dtr2
    
    y = datap[., 1]
    k = cols(datap)
    
    u = J(n, 1, 1)
    du1 = (J(bp1_in, 1, 0) \ J(n - bp1_in, 1, 1))
    dx1 = (J(bp1_in, k - 1, 0) \ datap[bp1_in + 1..n, 2..k])
    dtr1 = (J(bp1_in, 1, 0) \ (bp1_in + 1::n))
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = bp1_in + tb + 1; i <= n - tb; i++) {
        du2 = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du1, du2
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du1, du2
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du1, du2
            dx2 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2
        }
        else if (model == 3) {
            tr = (1::n)
            dtr2 = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du1, du2, tr, dtr1, dtr2
            dx2 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2
        }
        
        e = get_residuals(y, X)
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[bp1_in + tb + 1..n - tb])
    
    minssr = .
    minidx = bp1_in + tb + 1
    for (i = bp1_in + tb + 1; i <= n - tb; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp22 = minidx
    
    return(mintau)
}

real scalar mbreak3(real matrix datap, real scalar n, real scalar model,
                    real scalar tb, real vector bp_in, real scalar maxlags,
                    string scalar lagmethod, real scalar bp3, real scalar lag_used)
{
    real scalar bp1, bp2, mintau, tau1, tau2, tau3, bp31, bp32, bp33
    real vector alltau, allbp
    
    bp1 = bp_in[1]
    bp2 = bp_in[2]
    
    if (bp2 - bp1 > 0.1 * n && bp2 <= 0.9 * n) {
        if (bp1 <= 0.1 * n) {
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp32, lag_used)
            tau3 = mbreak33(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp33, lag_used)
            alltau = (tau2 \ tau3)
            allbp = (bp32 \ bp33)
            mintau = min(alltau)
            bp3 = allbp[selectindex(alltau :== min(alltau))[1]]
        }
        else {
            tau1 = mbreak31(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp31, lag_used)
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp32, lag_used)
            tau3 = mbreak33(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp33, lag_used)
            alltau = (tau1 \ tau2 \ tau3)
            allbp = (bp31 \ bp32 \ bp33)
            mintau = min(alltau)
            bp3 = allbp[selectindex(alltau :== min(alltau))[1]]
        }
    }
    else if (bp2 - bp1 > 0.1 * n && bp2 >= 0.9 * n) {
        if (bp1 <= 0.1 * n) {
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp32, lag_used)
            mintau = tau2
            bp3 = bp32
        }
        else {
            tau1 = mbreak31(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp31, lag_used)
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp32, lag_used)
            alltau = (tau1 \ tau2)
            allbp = (bp31 \ bp32)
            mintau = min(alltau)
            bp3 = allbp[selectindex(alltau :== min(alltau))[1]]
        }
    }
    else {
        tau2 = mbreak32(datap, n, model, tb, bp1, bp2, maxlags, lagmethod, bp32, lag_used)
        mintau = tau2
        bp3 = bp32
    }
    
    return(mintau)
}

real scalar mbreak31(real matrix datap, real scalar n, real scalar model,
                     real scalar tb, real scalar bp1, real scalar bp2,
                     real scalar maxlags, string scalar lagmethod,
                     real scalar bp31, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du1, du2, du3, e, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx1, dx2, dx3, tr, dtr1, dtr2, dtr3
    
    y = datap[., 1]
    k = cols(datap)
    
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    dx1 = (J(bp1, k - 1, 0) \ datap[bp1 + 1..n, 2..k])
    dx2 = (J(bp2, k - 1, 0) \ datap[bp2 + 1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1 + 1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2 + 1::n))
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = tb + 1; i <= bp1 - tb; i++) {
        du3 = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du1, du2, du3
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du1, du2, du3
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du1, du2, du3
            dx3 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3
        }
        else if (model == 3) {
            tr = (1::n)
            dtr3 = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du1, du2, du3, tr, dtr1, dtr2, dtr3
            dx3 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3
        }
        
        e = get_residuals(y, X)
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[tb + 1..bp1 - tb])
    
    minssr = .
    minidx = tb + 1
    for (i = tb + 1; i <= bp1 - tb; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp31 = minidx
    
    return(mintau)
}

real scalar mbreak32(real matrix datap, real scalar n, real scalar model,
                     real scalar tb, real scalar bp1, real scalar bp2,
                     real scalar maxlags, string scalar lagmethod,
                     real scalar bp32, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du1, du2, du3, e, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx1, dx2, dx3, tr, dtr1, dtr2, dtr3
    
    y = datap[., 1]
    k = cols(datap)
    
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    dx1 = (J(bp1, k - 1, 0) \ datap[bp1 + 1..n, 2..k])
    dx2 = (J(bp2, k - 1, 0) \ datap[bp2 + 1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1 + 1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2 + 1::n))
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = bp1 + tb + 1; i <= bp2 - tb; i++) {
        du3 = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du1, du2, du3
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du1, du2, du3
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du1, du2, du3
            dx3 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3
        }
        else if (model == 3) {
            tr = (1::n)
            dtr3 = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du1, du2, du3, tr, dtr1, dtr2, dtr3
            dx3 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3
        }
        
        e = get_residuals(y, X)
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[bp1 + tb + 1..bp2 - tb])
    
    minssr = .
    minidx = bp1 + tb + 1
    for (i = bp1 + tb + 1; i <= bp2 - tb; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp32 = minidx
    
    return(mintau)
}

real scalar mbreak33(real matrix datap, real scalar n, real scalar model,
                     real scalar tb, real scalar bp1, real scalar bp2,
                     real scalar maxlags, string scalar lagmethod,
                     real scalar bp33, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du1, du2, du3, e, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx1, dx2, dx3, tr, dtr1, dtr2, dtr3
    
    y = datap[., 1]
    k = cols(datap)
    
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    dx1 = (J(bp1, k - 1, 0) \ datap[bp1 + 1..n, 2..k])
    dx2 = (J(bp2, k - 1, 0) \ datap[bp2 + 1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1 + 1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2 + 1::n))
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = bp2 + tb + 1; i <= n - tb; i++) {
        du3 = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du1, du2, du3
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du1, du2, du3
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du1, du2, du3
            dx3 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3
        }
        else if (model == 3) {
            tr = (1::n)
            dtr3 = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du1, du2, du3, tr, dtr1, dtr2, dtr3
            dx3 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3
        }
        
        e = get_residuals(y, X)
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[bp2 + tb + 1..n - tb])
    
    minssr = .
    minidx = bp2 + tb + 1
    for (i = bp2 + tb + 1; i <= n - tb; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp33 = minidx
    
    return(mintau)
}

real scalar mbreak4(real matrix datap, real scalar n, real scalar model,
                    real scalar tb, real vector bp_in, real scalar maxlags,
                    string scalar lagmethod, real scalar bp4, real scalar lag_used)
{
    real scalar bp1, bp2, bp3, mintau, tau, bp_temp
    real vector alltau, allbp
    real scalar i, nregions
    
    bp1 = bp_in[1]
    bp2 = bp_in[2]
    bp3 = bp_in[3]
    
    alltau = J(4, 1, .)
    allbp = J(4, 1, 0)
    nregions = 0
    
    if (bp1 > 2 * tb) {
        nregions++
        tau = mbreak4_region(datap, n, model, tb, bp1, bp2, bp3, 
                             tb + 1, bp1 - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    if (bp2 - bp1 > 2 * tb) {
        nregions++
        tau = mbreak4_region(datap, n, model, tb, bp1, bp2, bp3,
                             bp1 + tb + 1, bp2 - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    if (bp3 - bp2 > 2 * tb) {
        nregions++
        tau = mbreak4_region(datap, n, model, tb, bp1, bp2, bp3,
                             bp2 + tb + 1, bp3 - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    if (n - bp3 > 2 * tb) {
        nregions++
        tau = mbreak4_region(datap, n, model, tb, bp1, bp2, bp3,
                             bp3 + tb + 1, n - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    mintau = min(alltau[1..nregions])
    bp4 = allbp[selectindex(alltau[1..nregions] :== min(alltau[1..nregions]))[1]]
    
    return(mintau)
}

real scalar mbreak4_region(real matrix datap, real scalar n, real scalar model,
                           real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3,
                           real scalar start_i, real scalar end_i,
                           real scalar maxlags, string scalar lagmethod,
                           real scalar bp4_out, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du1, du2, du3, du4, e, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx1, dx2, dx3, dx4, tr, dtr1, dtr2, dtr3, dtr4
    
    y = datap[., 1]
    k = cols(datap)
    
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
    dx1 = (J(bp1, k - 1, 0) \ datap[bp1 + 1..n, 2..k])
    dx2 = (J(bp2, k - 1, 0) \ datap[bp2 + 1..n, 2..k])
    dx3 = (J(bp3, k - 1, 0) \ datap[bp3 + 1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1 + 1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2 + 1::n))
    dtr3 = (J(bp3, 1, 0) \ (bp3 + 1::n))
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = start_i; i <= end_i; i++) {
        du4 = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du1, du2, du3, du4
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du1, du2, du3, du4
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du1, du2, du3, du4
            dx4 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3, dx4
        }
        else if (model == 3) {
            tr = (1::n)
            dtr4 = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du1, du2, du3, du4, tr, dtr1, dtr2, dtr3, dtr4
            dx4 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3, dx4
        }
        
        e = get_residuals(y, X)
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[start_i..end_i])
    
    minssr = .
    minidx = start_i
    for (i = start_i; i <= end_i; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp4_out = minidx
    
    return(mintau)
}

real scalar mbreak5(real matrix datap, real scalar n, real scalar model,
                    real scalar tb, real vector bp_in, real scalar maxlags,
                    string scalar lagmethod, real scalar bp5, real scalar lag_used)
{
    real scalar bp1, bp2, bp3, bp4, mintau, tau, bp_temp
    real vector alltau, allbp
    real scalar i, nregions
    
    bp1 = bp_in[1]
    bp2 = bp_in[2]
    bp3 = bp_in[3]
    bp4 = bp_in[4]
    
    alltau = J(5, 1, .)
    allbp = J(5, 1, 0)
    nregions = 0
    
    if (bp1 > 2 * tb) {
        nregions++
        tau = mbreak5_region(datap, n, model, tb, bp1, bp2, bp3, bp4,
                             tb + 1, bp1 - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    if (bp2 - bp1 > 2 * tb) {
        nregions++
        tau = mbreak5_region(datap, n, model, tb, bp1, bp2, bp3, bp4,
                             bp1 + tb + 1, bp2 - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    if (bp3 - bp2 > 2 * tb) {
        nregions++
        tau = mbreak5_region(datap, n, model, tb, bp1, bp2, bp3, bp4,
                             bp2 + tb + 1, bp3 - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    if (bp4 - bp3 > 2 * tb) {
        nregions++
        tau = mbreak5_region(datap, n, model, tb, bp1, bp2, bp3, bp4,
                             bp3 + tb + 1, bp4 - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    if (n - bp4 > 2 * tb) {
        nregions++
        tau = mbreak5_region(datap, n, model, tb, bp1, bp2, bp3, bp4,
                             bp4 + tb + 1, n - tb, maxlags, lagmethod, bp_temp, lag_used)
        alltau[nregions] = tau
        allbp[nregions] = bp_temp
    }
    
    mintau = min(alltau[1..nregions])
    bp5 = allbp[selectindex(alltau[1..nregions] :== min(alltau[1..nregions]))[1]]
    
    return(mintau)
}

real scalar mbreak5_region(real matrix datap, real scalar n, real scalar model,
                           real scalar tb, real scalar bp1, real scalar bp2, 
                           real scalar bp3, real scalar bp4,
                           real scalar start_i, real scalar end_i,
                           real scalar maxlags, string scalar lagmethod,
                           real scalar bp5_out, real scalar lag_used)
{
    real matrix X, cmat
    real vector y, u, du1, du2, du3, du4, du5, e, vectau, vecssr
    real scalar i, k, tau, ssr, mintau, minssr, minidx
    real vector dx1, dx2, dx3, dx4, dx5, tr, dtr1, dtr2, dtr3, dtr4, dtr5
    
    y = datap[., 1]
    k = cols(datap)
    
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
    du4 = (J(bp4, 1, 0) \ J(n - bp4, 1, 1))
    dx1 = (J(bp1, k - 1, 0) \ datap[bp1 + 1..n, 2..k])
    dx2 = (J(bp2, k - 1, 0) \ datap[bp2 + 1..n, 2..k])
    dx3 = (J(bp3, k - 1, 0) \ datap[bp3 + 1..n, 2..k])
    dx4 = (J(bp4, k - 1, 0) \ datap[bp4 + 1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1 + 1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2 + 1::n))
    dtr3 = (J(bp3, 1, 0) \ (bp3 + 1::n))
    dtr4 = (J(bp4, 1, 0) \ (bp4 + 1::n))
    
    vectau = J(n, 1, .)
    vecssr = J(n, 1, .)
    
    for (i = start_i; i <= end_i; i++) {
        du5 = (J(i, 1, 0) \ J(n - i, 1, 1))
        
        if (model == 0) {
            cmat = u, du1, du2, du3, du4, du5
            X = cmat, datap[., 2..k]
        }
        else if (model == 1) {
            cmat = u, du1, du2, du3, du4, du5
            tr = (1::n)
            X = cmat, tr, datap[., 2..k]
        }
        else if (model == 2) {
            cmat = u, du1, du2, du3, du4, du5
            dx5 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
        }
        else if (model == 3) {
            tr = (1::n)
            dtr5 = (J(i, 1, 0) \ (i + 1::n))
            cmat = u, du1, du2, du3, du4, du5, tr, dtr1, dtr2, dtr3, dtr4, dtr5
            dx5 = (J(i, k - 1, 0) \ datap[i + 1..n, 2..k])
            X = cmat, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
        }
        
        e = get_residuals(y, X)
        tau = adf_test(e, maxlags, lagmethod, lag_used)
        ssr = sum(e:^2)
        
        vectau[i] = tau
        vecssr[i] = ssr
    }
    
    mintau = min(vectau[start_i..end_i])
    
    minssr = .
    minidx = start_i
    for (i = start_i; i <= end_i; i++) {
        if (vecssr[i] < minssr) {
            minssr = vecssr[i]
            minidx = i
        }
    }
    bp5_out = minidx
    
    return(mintau)
}

real vector get_residuals(real vector y, real matrix X)
{
    real matrix XtX_inv
    real vector b, e
    
    XtX_inv = invsym(cross(X, X))
    b = XtX_inv * cross(X, y)
    e = y - X * b
    
    return(e)
}

real scalar adf_test(real vector e, real scalar maxlags, string scalar lagmethod,
                     real scalar lag_used)
{
    real scalar n, lag, tau
    real vector dy
    real matrix X
    
    n = rows(e)
    dy = e[2..n] - e[1..n-1]
    
    if (lagmethod == "fixed") {
        lag = maxlags
    }
    else if (lagmethod == "tsig") {
        lag = optimal_lag_tsig(e, maxlags)
    }
    else if (lagmethod == "aic") {
        lag = optimal_lag_ic(e, maxlags, "aic")
    }
    else if (lagmethod == "bic") {
        lag = optimal_lag_ic(e, maxlags, "bic")
    }
    else {
        lag = optimal_lag_tsig(e, maxlags)
    }
    
    lag_used = lag
    
    tau = compute_adf_tau(e, lag)
    
    return(tau)
}

real scalar optimal_lag_tsig(real vector e, real scalar maxlags)
{
    real scalar n, p, i, s2hat, tstat
    real vector dy, ly, b, se, resid
    real matrix X, XtX_inv
    
    n = rows(e)
    dy = e[2..n] - e[1..n-1]
    
    for (p = maxlags; p >= 1; p--) {
        if (n - 1 - p < 3) continue
        
        X = e[p + 1..n - 1]
        for (i = 1; i <= p; i++) {
            X = X, dy[p + 1 - i..n - 1 - i]
        }
        
        ly = dy[p + 1..n - 1]
        
        XtX_inv = invsym(cross(X, X))
        b = XtX_inv * cross(X, ly)
        
        resid = ly - X * b
        s2hat = cross(resid, resid) / (rows(X) - cols(X))
        se = sqrt(diagonal(s2hat * XtX_inv))
        
        tstat = b[p + 1] / se[p + 1]
        
        if (abs(tstat) > 1.654) {
            return(p)
        }
    }
    
    return(0)
}

real scalar optimal_lag_ic(real vector e, real scalar maxlags, string scalar criterion)
{
    real scalar n, p, i, best_lag, best_ic, ic, s2, nobs, npar
    real vector dy, ly, b, resid
    real matrix X, XtX_inv
    
    n = rows(e)
    dy = e[2..n] - e[1..n-1]
    
    best_lag = 0
    best_ic = .
    
    for (p = 0; p <= maxlags; p++) {
        if (n - 1 - p < 3) continue
        
        X = e[p + 1..n - 1]
        if (p > 0) {
            for (i = 1; i <= p; i++) {
                X = X, dy[p + 1 - i..n - 1 - i]
            }
        }
        
        ly = dy[p + 1..n - 1]
        
        XtX_inv = invsym(cross(X, X))
        b = XtX_inv * cross(X, ly)
        resid = ly - X * b
        
        nobs = rows(X)
        npar = cols(X)
        s2 = cross(resid, resid) / nobs
        
        if (criterion == "aic") {
            ic = ln(s2) + 2 * npar / nobs
        }
        else {
            ic = ln(s2) + ln(nobs) * npar / nobs
        }
        
        if (ic < best_ic) {
            best_ic = ic
            best_lag = p
        }
    }
    
    return(best_lag)
}

real scalar compute_adf_tau(real vector e, real scalar lag)
{
    real scalar n, r, q, tau, s2hat
    real vector dy, ly, b, se, resid
    real matrix X, XtX_inv
    
    n = rows(e)
    dy = e[2..n] - e[1..n-1]
    
    r = 2 + lag
    
    X = e[r - 1..n - 1]
    
    if (lag > 0) {
        for (q = 1; q <= lag; q++) {
            X = X, dy[r - 1 - q..n - 1 - q]
        }
    }
    
    ly = dy[r - 1..n - 1]
    
    XtX_inv = invsym(cross(X, X))
    b = XtX_inv * cross(X, ly)
    resid = ly - X * b
    
    s2hat = cross(resid, resid) / (rows(X) - cols(X))
    se = sqrt(diagonal(s2hat * XtX_inv))
    
    tau = b[1] / se[1]
    
    return(tau)
}

// Critical values from Maki (2012) Table 1 - EXACTLY matching GAUSS code
real rowvector get_critical_values(real scalar k, real scalar m, real scalar model)
{
    real matrix cv_mat
    real rowvector cv
    
    // Model 0: Level shift (from GAUSS lines 2109-2137)
    if (model == 0) {
        if (k == 1) {
            cv_mat = (-5.709, -4.602, -4.354 \
                      -5.416, -4.892, -4.610 \
                      -5.563, -5.083, -4.784 \
                      -5.776, -5.230, -4.982 \
                      -5.959, -5.426, -5.131)
        }
        else if (k == 2) {
            cv_mat = (-5.541, -5.004, -4.733 \
                      -5.717, -5.211, -4.957 \
                      -5.943, -5.392, -5.125 \
                      -6.075, -5.550, -5.297 \
                      -6.296, -5.760, -5.491)
        }
        else if (k == 3) {
            cv_mat = (-5.820, -5.341, -5.101 \
                      -5.984, -5.517, -5.272 \
                      -6.229, -5.704, -5.427 \
                      -6.406, -5.871, -5.603 \
                      -6.555, -6.038, -5.773)
        }
        else if (k == 4) {
            cv_mat = (-6.139, -5.650, -5.386 \
                      -6.303, -5.839, -5.575 \
                      -6.501, -5.992, -5.714 \
                      -6.640, -6.132, -5.892 \
                      -6.856, -6.306, -6.039)
        }
    }
    // Model 1: Level shift with trend (from GAUSS lines 2138-2166)
    else if (model == 1) {
        if (k == 1) {
            cv_mat = (-5.524, -5.038, -4.784 \
                      -5.708, -5.196, -4.938 \
                      -5.833, -5.373, -5.106 \
                      -6.059, -5.508, -5.245 \
                      -6.193, -5.699, -5.449)
        }
        else if (k == 2) {
            cv_mat = (-5.840, -5.359, -5.117 \
                      -6.011, -5.518, -5.247 \
                      -6.169, -5.691, -5.408 \
                      -6.329, -5.831, -5.558 \
                      -6.530, -5.993, -5.722)
        }
        else if (k == 3) {
            cv_mat = (-6.144, -5.645, -5.398 \
                      -6.271, -5.796, -5.538 \
                      -6.472, -5.957, -5.682 \
                      -6.575, -6.086, -5.820 \
                      -6.784, -6.250, -5.976)
        }
        else if (k == 4) {
            cv_mat = (-6.361, -5.913, -5.686 \
                      -6.556, -6.055, -5.805 \
                      -6.741, -6.214, -5.974 \
                      -6.845, -6.373, -6.096 \
                      -7.053, -6.494, -6.220)
        }
    }
    // Model 2: Regime shift (from GAUSS lines 2167-2195)
    else if (model == 2) {
        if (k == 1) {
            cv_mat = (-5.457, -4.895, -4.626 \
                      -5.863, -5.363, -5.070 \
                      -6.251, -5.703, -5.402 \
                      -6.596, -6.011, -5.723 \
                      -6.915, -6.357, -6.057)
        }
        else if (k == 2) {
            cv_mat = (-6.020, -5.558, -5.287 \
                      -6.628, -6.093, -5.833 \
                      -7.031, -6.516, -6.210 \
                      -7.470, -6.872, -6.563 \
                      -7.839, -7.288, -6.976)
        }
        else if (k == 3) {
            cv_mat = (-6.565, -6.035, -5.773 \
                      -7.232, -6.702, -6.411 \
                      -7.767, -7.155, -6.868 \
                      -8.236, -7.625, -7.329 \
                      -8.673, -8.110, -7.796)
        }
        else if (k == 4) {
            cv_mat = (-7.021, -6.520, -6.242 \
                      -7.756, -7.244, -6.964 \
                      -8.336, -7.803, -7.481 \
                      -8.895, -8.292, -8.004 \
                      -9.441, -8.869, -8.541)
        }
    }
    // Model 3: Regime shift with trend (from GAUSS lines 2196-2225)
    else if (model == 3) {
        if (k == 1) {
            cv_mat = (-6.048, -5.541, -5.281 \
                      -6.620, -6.100, -5.845 \
                      -7.082, -6.524, -6.267 \
                      -7.553, -7.009, -6.712 \
                      -8.004, -7.414, -7.110)
        }
        else if (k == 2) {
            cv_mat = (-6.523, -6.055, -5.795 \
                      -7.153, -6.657, -6.397 \
                      -7.673, -7.145, -6.873 \
                      -8.217, -7.636, -7.341 \
                      -8.713, -8.129, -7.811)
        }
        else if (k == 3) {
            cv_mat = (-6.964, -6.464, -6.220 \
                      -7.737, -7.201, -6.926 \
                      -8.331, -7.743, -7.449 \
                      -8.851, -8.269, -7.960 \
                      -9.428, -8.800, -8.508)
        }
        else if (k == 4) {
            cv_mat = (-7.400, -6.911, -6.649 \
                      -8.167, -7.638, -7.381 \
                      -8.865, -8.254, -7.977 \
                      -9.433, -8.871, -8.574 \
                      -10.08, -9.482, -9.151)
        }
    }
    
    cv = cv_mat[m, .]
    
    return(cv)
}

end
