*! pocoint v2.0.0  03may2026  Ozan Eruygur
*! Phillips-Ouliaris (1990) residual-based cointegration tests
*! Implements all four tests: Z(alpha), Z(t), P_u, P_z
*! Trends: none / constant / constant+trend / constant+trend+trend^2
*! Critical values and p-values via Hansen-Haug response surface
*!   (sourced from the Python arch package by Kevin Sheppard).
*! Backwards-compatible 'tseries' option reproduces R tseries::po.test exactly.

program define pocoint, rclass
    version 14.0

    syntax varlist(min=2 max=13 numeric ts) [if] [in] [, TEST(string) TRend(string) Lags(integer -1) LSHort LLONG AUTO Kernel(string) RESid(name) TSeries URCA EViews]

    * eviews mode is restrictive: must be checked BEFORE any defaults are set
    if "`eviews'" != "" {
        if "`tseries'" != "" | "`urca'" != "" {
            di as err "eviews mode cannot be combined with tseries or urca"
            exit 198
        }
        local _evbad ""
        if "`test'" != ""    local _evbad "`_evbad' test()"
        if "`trend'" != ""   local _evbad "`_evbad' trend()"
        if "`kernel'" != ""  local _evbad "`_evbad' kernel()"
        if `lags' >= 0       local _evbad "`_evbad' lags()"
        if "`auto'" != ""    local _evbad "`_evbad' auto"
        if "`lshort'" != ""  local _evbad "`_evbad' lshort"
        if "`llong'" != ""   local _evbad "`_evbad' llong"
        if "`resid'" != ""   local _evbad "`_evbad' resid()"
        if "`_evbad'" != "" {
            di as err "eviews mode replicates the EViews default; the following options are not allowed:`_evbad'"
            exit 198
        }
    }

    if "`test'" == "" local test "Zt"
    local test = proper("`test'")
    if !inlist("`test'", "Za", "Zt", "Pu", "Pz") {
        di as err "test() must be one of: Za, Zt, Pu, Pz"
        exit 198
    }
    if "`trend'" == "" local trend "c"
    local trend = lower("`trend'")
    if "`trend'" == "none"     local trend "n"
    if "`trend'" == "constant" local trend "c"
    if !inlist("`trend'", "n", "c", "ct", "ctt") {
        di as err "trend() must be one of: n, c, ct, ctt  (or: none, constant)"
        exit 198
    }
    if "`kernel'" == "" local kernel "bartlett"
    local kernel = lower("`kernel'")
    if "`kernel'" == "qs"                  local kernel "quadratic-spectral"
    if "`kernel'" == "quadratic_spectral"  local kernel "quadratic-spectral"
    if !inlist("`kernel'", "bartlett", "parzen", "quadratic-spectral") {
        di as err "kernel() must be one of: bartlett, parzen, quadratic-spectral (or qs)"
        exit 198
    }
    if "`tseries'" != "" & "`urca'" != "" {
        di as err "options tseries and urca cannot be combined"
        exit 198
    }
    if "`tseries'" != "" {
        if "`trend'" == "" local trend "c"
        if !inlist("`trend'", "n", "c") {
            di as err "tseries mode supports only trend(n) or trend(c)"
            exit 198
        }
        if "`kernel'" != "bartlett" {
            di as err "tseries mode uses Bartlett kernel only"
            exit 198
        }
        if "`auto'" != "" {
            di as err "tseries mode does not support auto bandwidth"
            exit 198
        }
        if "`resid'" != "" {
            di as err "tseries mode does not support the resid() option"
            exit 198
        }
        local test "Za"
    }
    if "`urca'" != "" {
        if "`test'" == "" local test "Pu"
        if "`trend'" == "" local trend "c"
        if !inlist("`test'", "Pu", "Pz") {
            di as err "urca mode supports only test(Pu) or test(Pz)"
            exit 198
        }
        if !inlist("`trend'", "n", "c", "ct") {
            di as err "urca mode supports only trend(n), trend(c), or trend(ct)"
            exit 198
        }
        if "`kernel'" != "bartlett" {
            di as err "urca mode uses Bartlett kernel only"
            exit 198
        }
        if "`auto'" != "" {
            di as err "urca mode does not support auto bandwidth"
            exit 198
        }
        if "`resid'" != "" {
            di as err "urca mode does not support the resid() option"
            exit 198
        }
    }
    local test_id  = cond("`test'"=="Za", 1, cond("`test'"=="Zt", 2, cond("`test'"=="Pu", 3, 4)))
    local trend_id = cond("`trend'"=="n", 1, cond("`trend'"=="c", 2, cond("`trend'"=="ct", 3, 4)))

    marksample touse
    qui tsset, noquery
    local panel `r(panelvar)'
    if "`panel'" != "" {
        di as err "pocoint requires pure time-series data (no panel)."
        exit 459
    }

    local nvars : word count `varlist'
    if `nvars' < 2 {
        di as err "at least two variables are required"
        exit 102
    }
    if `nvars' > 13 {
        di as err "no critical values for more than 13 variables"
        exit 459
    }
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indeps `*'

    qui count if `touse'
    local Tobs = r(N)
    if `Tobs' < 10 {
        di as err "too few observations"
        exit 2001
    }

    * Bandwidth selection precedence: lags(#) > auto > llong > lshort
    if `lags' >= 0 {
        local bw = `lags'
        local bw_method "user"
    }
    else if "`auto'" != "" {
        local bw = -1
        local bw_method "auto (Andrews/Newey-West)"
    }
    else if "`urca'" != "" {
        * urca bandwidth: trunc(4*(n/100)^0.25) short, trunc(12*(n/100)^0.25) long
        * where n = T-1 (after first differencing)
        local n_diff = `Tobs' - 1
        if "`llong'" != "" {
            local bw = floor(12 * (`n_diff'/100)^0.25)
            local bw_method "llong (urca)"
        }
        else {
            local bw = floor(4 * (`n_diff'/100)^0.25)
            local bw_method "lshort (urca)"
        }
    }
    else if "`llong'" != "" {
        local bw = floor((`Tobs'-1) / 30)
        local bw_method "llong: trunc((n-1)/30)"
    }
    else {
        local bw = floor((`Tobs'-1) / 100)
        local bw_method "lshort: trunc((n-1)/100)"
    }
    if `bw' < 0 & "`auto'" == "" local bw = 0

    if "`tseries'" != "" {
        pocoint_tseries `varlist' if `touse', bw(`bw') nvars(`nvars') trend(`trend')
        return add
        return local method "Phillips-Ouliaris (tseries::po.test compatible)"
        return scalar tseries = 1
        exit 0
    }

    if "`urca'" != "" {
        if `nvars' > 6 {
            di as err "urca mode supports up to 6 variables only"
            exit 459
        }
        pocoint_urca `varlist' if `touse', test(`test') trend(`trend') bw(`bw') nvars(`nvars')
        return add
        return local method "Phillips-Ouliaris (urca::ca.po compatible)"
        return scalar urca = 1
        exit 0
    }

    if "`eviews'" != "" {
        pocoint_eviews `varlist' if `touse', nvars(`nvars')
        return add
        return local method "Phillips-Ouliaris (EViews compatible)"
        return scalar eviews = 1
        exit 0
    }

    capture mata: pocoint_cv_table()
    if _rc {
        capture findfile pocoint_tables.mata
        if _rc {
            di as err "pocoint_tables.mata not found in adopath - reinstall the package"
            exit 199
        }
        quietly do "`r(fn)'"
        capture mata: pocoint_cv_table()
        if _rc {
            di as err "pocoint_tables.mata failed to define lookup functions"
            exit 199
        }
    }

    tempname stat pval cv1 cv5 cv10 minN bw_used

    * If user asked for residuals, run the cointegrating regression in Stata
    * (matches what Mata does internally) and save them.
    if "`resid'" != "" {
        capture confirm new variable `resid'
        if _rc {
            di as err "variable `resid' already exists; choose a new name or drop it first"
            exit 110
        }
        tempvar tvar t2var
        if "`trend'" == "n" {
            qui regress `depvar' `indeps' if `touse', noconstant
        }
        else if "`trend'" == "c" {
            qui regress `depvar' `indeps' if `touse'
        }
        else if "`trend'" == "ct" {
            qui gen double `tvar' = _n if `touse'
            qui regress `depvar' `indeps' `tvar' if `touse'
        }
        else {
            qui gen double `tvar' = _n if `touse'
            qui gen double `t2var' = `tvar'^2 if `touse'
            qui regress `depvar' `indeps' `tvar' `t2var' if `touse'
        }
        qui predict double `resid' if e(sample), residuals
    }

    mata: pocoint_run_test("`depvar'", "`indeps'", "`touse'", "`test'", "`trend'", "`kernel'", `bw', `nvars', `Tobs', "`stat'", "`pval'", "`cv1'", "`cv5'", "`cv10'", "`minN'", "`bw_used'")
    local bw_eff = `bw_used'

    local trend_label = cond("`trend'"=="n", "none", cond("`trend'"=="c", "constant", cond("`trend'"=="ct", "constant + trend", "constant + trend + trend^2")))

    local kernel_label = cond("`kernel'"=="bartlett", "Bartlett", cond("`kernel'"=="parzen", "Parzen", "Quadratic Spectral"))

    di _n as txt "Phillips-Ouliaris Cointegration Test"
    di     as txt "{hline 65}"
    di     as txt "Test                    : " as res "`test'"
    di     as txt "Deterministics          : " as res "`trend_label'"
    di     as txt "Cointegrating regression: " as res "`depvar'" as txt " on " as res "`indeps'"
    di     as txt "Effective N             : " as res `Tobs'
    di     as txt "Number of variables     : " as res `nvars'
    di     as txt "Kernel                  : " as res "`kernel_label'"
    if "`auto'" != "" {
        di as txt "Bandwidth               : " as res %9.4f `bw_eff'
        di as txt "                            (auto: Andrews/Newey-West)"
    }
    else {
        di as txt "Bandwidth (truncation l): " as res `bw_eff'
        if `lags' >= 0 di as txt "                            (user-specified)"
        else if "`llong'" != "" di as txt "                            (llong: trunc((n-1)/30))"
        else di as txt "                            (lshort: trunc((n-1)/100))"
    }
    di     as txt "{hline 65}"
    di     as txt "Statistic               : " as res %12.4f `stat'
    di     as txt "Asymptotic p-value      : " as res %12.4f `pval'
    di     as txt "{hline 65}"
    di     as txt "Critical values (Hansen-Haug response surface):"
    di     as txt "      1%" _col(20) "5%" _col(34) "10%"
    di     as res %12.4f `cv1' _col(15) %12.4f `cv5' _col(30) %12.4f `cv10'
    di     as txt "{hline 65}"
    if inlist("`test'", "Za", "Zt") {
        di as txt "H0: no cointegration.  Reject H0 if statistic < critical value."
    }
    else {
        di as txt "H0: no cointegration.  Reject H0 if statistic > critical value."
    }
    if "`resid'" != "" {
        di as txt "Cointegrating-regression residuals saved in: " as res "`resid'"
    }
    if `Tobs' < `minN' {
        di as txt "Note: sample size N=" %4.0f `Tobs' " is below the smallest size"
        di as txt "      used to fit the response surface (N>=" %4.0f `minN' "). Interpret p-value with caution."
    }

    return scalar statistic = `stat'
    return scalar p         = `pval'
    return scalar cv_1pct   = `cv1'
    return scalar cv_5pct   = `cv5'
    return scalar cv_10pct  = `cv10'
    return scalar minN      = `minN'
    return scalar lag       = `bw_eff'
    return scalar n         = `Tobs'
    return scalar nvars     = `nvars'
    return local  bw_method "`bw_method'"
    return local  kernel    "`kernel'"
    return local  test      "`test'"
    return local  trend     "`trend'"
    return local  depvar    "`depvar'"
    return local  indeps    "`indeps'"
    return local  method    "Phillips-Ouliaris (1990) cointegration test"
end


program define pocoint_tseries, rclass
    syntax varlist [if] [in], bw(integer) nvars(integer) [trend(string)]
    if "`trend'" == "" local trend "c"
    marksample touse
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indeps `*'

    tempvar uhat ut ut1 khat
    if "`trend'" == "n" {
        qui regress `depvar' `indeps' if `touse', noconstant
    }
    else {
        qui regress `depvar' `indeps' if `touse'
    }
    qui predict double `uhat' if e(sample), residuals
    qui gen double `ut'  = `uhat'
    qui gen double `ut1' = L.`uhat'
    qui regress `ut' `ut1' if `touse', noconstant
    scalar _alpha = _b[`ut1']
    qui predict double `khat' if e(sample), residuals
    qui count if `khat' < .
    local n = r(N)

    tempvar k2 ut12
    qui gen double `k2' = `khat'^2 if `touse'
    qui summarize `k2' if `touse', meanonly
    scalar ssqrk = r(sum) / `n'
    scalar ssqrtl = ssqrk
    if `bw' >= 1 mata: pocoint_tseries_nw("`khat'", "`touse'", `n', `bw')

    qui gen double `ut12' = `ut1'^2 if `touse'
    qui summarize `ut12' if `touse', meanonly
    scalar sum_ut1sq = r(sum)
    scalar STAT = `n'*(_alpha - 1) - 0.5 * (`n')^2 * (ssqrtl - ssqrk) / sum_ut1sq

    * R tseries::po.test p-value via linear interpolation on its built-in
    * critical-value table; matches po.test's PVAL output exactly.
    local nvars : word count `varlist'
    local demean = cond("`trend'"=="n", 0, 1)
    tempname pval pflag
    mata: pocoint_tseries_pval(st_numscalar("STAT"), `nvars', `demean', "`pval'", "`pflag'")

    local trend_label = cond("`trend'"=="n", "standard (no intercept)", "demeaned (with intercept)")
    di _n as txt "Phillips-Ouliaris Cointegration Test (tseries::po.test compatible)"
    di     as txt "{hline 65}"
    di     as txt "Test                    : " as res "Z(alpha) `trend_label'"
    di     as txt "Cointegrating regression: " as res "`depvar'" as txt " on " as res "`indeps'"
    di     as txt "Effective N             : " as res `n'
    di     as txt "Bartlett bandwidth (l)  : " as res `bw'
    di     as txt "{hline 65}"
    di     as txt "Z(alpha) statistic      : " as res %12.4f STAT
    di     as txt "p-value                 : " as res %12.4f `pval'
    if `pflag' == 1 di as txt "Warning: p-value smaller than printed p-value (statistic below table)."
    if `pflag' == 2 di as txt "Warning: p-value greater than printed p-value (statistic above table)."

    return scalar statistic = STAT
    return scalar p         = `pval'
    return scalar alpha     = _alpha
    return scalar lag       = `bw'
    return scalar n         = `n'
    return local  trend     "`trend'"
end


* ==============================================================================
*  urca::ca.po-compatible mode (Pu and Pz, with urca's exact algorithm)
* ==============================================================================
program define pocoint_urca, rclass
    syntax varlist [if] [in], test(string) trend(string) bw(integer) nvars(integer)
    marksample touse
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indeps `*'

    local test_id  = cond("`test'"=="Pu", 3, 4)
    local trend_id = cond("`trend'"=="n", 1, cond("`trend'"=="c", 2, 3))

    tempname stat cv1 cv5 cv10
    mata: pocoint_urca_run("`depvar'", "`indeps'", "`touse'", "`test'", "`trend'", `bw', `nvars', "`stat'", "`cv1'", "`cv5'", "`cv10'")

    local trend_label = cond("`trend'"=="n", "none", cond("`trend'"=="c", "constant", "constant + trend"))
    di _n as txt "Phillips-Ouliaris Cointegration Test (urca::ca.po compatible)"
    di     as txt "{hline 65}"
    di     as txt "Test                    : " as res "`test'"
    di     as txt "Deterministics          : " as res "`trend_label'"
    di     as txt "Cointegrating regression: " as res "`depvar'" as txt " on " as res "`indeps'"
    qui count if `touse'
    di     as txt "Effective N             : " as res r(N)
    di     as txt "Number of variables     : " as res `nvars'
    di     as txt "Bartlett bandwidth (l)  : " as res `bw'
    di     as txt "{hline 65}"
    di     as txt "Statistic               : " as res %12.4f `stat'
    di     as txt "{hline 65}"
    di     as txt "Critical values (urca::ca.po internal table):"
    di     as txt "    10%" _col(20) "5%" _col(34) "1%"
    di     as res %12.4f `cv10' _col(15) %12.4f `cv5' _col(30) %12.4f `cv1'
    di     as txt "{hline 65}"
    di     as txt "H0: no cointegration.  Reject H0 if statistic > critical value."
    di     as txt "Note: urca does not return a p-value."

    return scalar statistic = `stat'
    return scalar cv_1pct   = `cv1'
    return scalar cv_5pct   = `cv5'
    return scalar cv_10pct  = `cv10'
    return scalar lag       = `bw'
    return scalar n         = r(N)
    return scalar nvars     = `nvars'
    return local  test      "`test'"
    return local  trend     "`trend'"
end


* ==============================================================================
*  EViews-compatible mode (Z_alpha and Z_t, both reported, with EViews
*  default settings: Bartlett kernel, Newey-West fixed bandwidth
*  floor(4*(T/100)^(2/9)), demeaned cointegrating regression, no d.f.
*  adjustment).  Produces statistics that match EViews to machine precision.
* ==============================================================================
program define pocoint_eviews, rclass
    syntax varlist [if] [in], nvars(integer)
    marksample touse
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indeps `*'

    qui count if `touse'
    local Tfull = r(N)
    if `Tfull' < 10 {
        di as err "too few observations"
        exit 2001
    }

    * EViews "Newey-West fixed" bandwidth
    local bw = floor(4 * (`Tfull'/100)^(2/9))
    if `bw' < 0 local bw = 0

    * Step 1: cointegrating regression with constant
    tempvar uhat
    qui regress `depvar' `indeps' if `touse'
    qui predict double `uhat' if e(sample), residuals

    * Step 2: AR(1) on the residuals (no constant), get rho
    tempvar ut ut1 khat
    qui gen double `ut'  = `uhat'  if `touse'
    qui gen double `ut1' = L.`uhat' if `touse'
    qui regress `ut' `ut1' if `touse', noconstant
    scalar _rho = _b[`ut1']
    qui predict double `khat' if e(sample), residuals
    qui count if `khat' < .
    local Teff = r(N)

    * Step 3: long-run variance and one-sided long-run autocovariance of khat
    *  sigma^2 = (1/T) * sum k_t^2  (no d.f. adjustment, matching EViews)
    *  omega^2 = sigma^2 + 2 * sum_{s=1}^{l} w_s * gamma_s
    *  lambda  = (omega^2 - sigma^2) / 2  (one-sided)
    tempvar k2
    qui gen double `k2' = `khat'^2 if `touse'
    qui summarize `k2' if `touse', meanonly
    scalar _sigma2 = r(sum) / `Teff'
    scalar _omega2 = _sigma2
    if `bw' >= 1 {
        scalar ssqrtl = _omega2
        mata: pocoint_tseries_nw("`khat'", "`touse'", `Teff', `bw')
        scalar _omega2 = ssqrtl
    }
    scalar _lambda = (_omega2 - _sigma2) / 2

    * Step 4: bias correction and statistics
    tempvar ut1sq
    qui gen double `ut1sq' = `ut1'^2 if `touse'
    qui summarize `ut1sq' if `touse', meanonly
    scalar _sumu2 = r(sum)
    scalar _rho_star_m1 = (_rho - 1) - `Teff' * _lambda / _sumu2
    scalar _rho_se = sqrt(_omega2 / _sumu2)
    scalar _z   = `Teff' * _rho_star_m1
    scalar _tau = _rho_star_m1 / _rho_se

    * Step 5: p-values from Hansen-Haug response surface (Sheppard simulation).
    * EViews reports MacKinnon (1996) p-values; we use Hansen-Haug here.
    capture mata: pocoint_cv_table()
    if _rc {
        capture findfile pocoint_tables.mata
        if _rc {
            di as err "pocoint_tables.mata not found in adopath - reinstall the package"
            exit 199
        }
        quietly do "`r(fn)'"
    }
    tempname pZa pZt cv1Za cv5Za cv10Za cv1Zt cv5Zt cv10Zt minNZa minNZt
    mata: st_numscalar(st_local("pZa"), pocoint_pval(st_numscalar("_z"),   1, 2, `nvars'))
    mata: st_numscalar(st_local("pZt"), pocoint_pval(st_numscalar("_tau"), 2, 2, `nvars'))
    mata: pocoint_eviews_cv(1, 2, `nvars', `Tfull', "`cv1Za'", "`cv5Za'", "`cv10Za'", "`minNZa'")
    mata: pocoint_eviews_cv(2, 2, `nvars', `Tfull', "`cv1Zt'", "`cv5Zt'", "`cv10Zt'", "`minNZt'")

    di _n as txt "Phillips-Ouliaris Cointegration Test (EViews compatible)"
    di     as txt "{hline 65}"
    di     as txt "Cointegrating regression: " as res "`depvar'" as txt " on " as res "`indeps'"
    di     as txt "Deterministics          : " as res "constant"
    di     as txt "Effective N             : " as res `Tfull' " (residuals: " `Teff' ")"
    di     as txt "Number of variables     : " as res `nvars'
    di     as txt "Kernel                  : " as res "Bartlett"
    di     as txt "Bandwidth (truncation l): " as res `bw'
    di     as txt "                            (Newey-West fixed: trunc(4*(T/100)^(2/9)))"
    di     as txt "{hline 65}"
    di     as txt "Test                       Statistic     p-value"
    di     as txt "{hline 65}"
    di     as txt "Z(alpha)              " as res %12.4f _z   "  " %10.4f `pZa'
    di     as txt "Z(t)                  " as res %12.4f _tau "  " %10.4f `pZt'
    di     as txt "{hline 65}"
    di     as txt "Critical values (Hansen-Haug response surface):"
    di     as txt "                          1%        5%       10%"
    di     as txt "Z(alpha)             " as res %10.4f `cv1Za' " " %10.4f `cv5Za' " " %10.4f `cv10Za'
    di     as txt "Z(t)                 " as res %10.4f `cv1Zt' " " %10.4f `cv5Zt' " " %10.4f `cv10Zt'
    di     as txt "{hline 65}"
    di     as txt "Intermediate Results:"
    di     as txt "  Rho - 1                              : " as res %12.6f (_rho - 1)
    di     as txt "  Bias-corrected Rho - 1 (Rho* - 1)    : " as res %12.6f _rho_star_m1
    di     as txt "  Rho* S.E.                            : " as res %12.6f _rho_se
    di     as txt "  Residual variance (sigma^2)          : " as res %12.6f _sigma2
    di     as txt "  Long-run residual variance (omega^2) : " as res %12.6f _omega2
    di     as txt "  Long-run residual autocov (lambda)   : " as res %12.6f _lambda
    di     as txt "{hline 65}"
    di     as txt "H0: no cointegration.  Reject H0 if statistic < critical value."
    di     as txt "Note: EViews reports MacKinnon (1996) p-values; pocoint uses the"
    di     as txt "      Hansen-Haug response surface.  Test statistics agree to"
    di     as txt "      machine precision; p-values may differ slightly."
    if `Tfull' < `minNZa' {
        di as txt "Note: sample size N=" %4.0f `Tfull' " is below the smallest size"
        di as txt "      used to fit the response surface (N>=" %4.0f `minNZa' "). Interpret p-value with caution."
    }

    return scalar z         = _z
    return scalar tau       = _tau
    return scalar p_z       = `pZa'
    return scalar p_tau     = `pZt'
    return scalar rho       = _rho
    return scalar rho_star  = _rho_star_m1 + 1
    return scalar rho_se    = _rho_se
    return scalar sigma2    = _sigma2
    return scalar omega2    = _omega2
    return scalar lambda    = _lambda
    return scalar lag       = `bw'
    return scalar n         = `Tfull'
    return scalar nvars     = `nvars'
    return local  trend     "c"
    return local  kernel    "bartlett"
end


mata:
mata set matastrict off

void pocoint_run_test(string scalar dvar, string scalar ivars, string scalar touse, string scalar test, string scalar trend, string scalar kernel, real scalar bw_in, real scalar nvars, real scalar Tobs, string scalar sname_stat, string scalar sname_pval, string scalar sname_cv1, string scalar sname_cv5, string scalar sname_cv10, string scalar sname_minN, string scalar sname_bw)
{
    real colvector y
    real matrix    X
    real scalar    test_id, trend_id, stat, pval, bw

    real rowvector cvinfo

    y = st_data(., dvar, touse)
    X = st_data(., ivars, touse)

    test_id  = (test == "Za" ? 1 : (test == "Zt" ? 2 : (test == "Pu" ? 3 : 4)))
    trend_id = (trend == "n" ? 1 : (trend == "c" ? 2 : (trend == "ct" ? 3 : 4)))

    // Resolve bandwidth: if bw_in < 0, compute Andrews/Newey-West auto bw
    if (bw_in < 0) {
        bw = pocoint_compute_optbw(y, X, trend, test, kernel)
    }
    else {
        bw = bw_in
    }

    if (test_id <= 2) {
        stat = pocoint_z_stat(y, X, trend, test, kernel, bw)
    }
    else {
        stat = pocoint_p_stat(y, X, trend, test, kernel, bw)
    }
    pval = pocoint_pval(stat, test_id, trend_id, nvars)
    cvinfo = pocoint_cv_lookup(test_id, trend_id, nvars, Tobs)

    st_numscalar(sname_stat, stat)
    st_numscalar(sname_pval, pval)
    st_numscalar(sname_cv1,  cvinfo[1,1])
    st_numscalar(sname_cv5,  cvinfo[1,2])
    st_numscalar(sname_cv10, cvinfo[1,3])
    st_numscalar(sname_minN, cvinfo[1,4])
    st_numscalar(sname_bw,   bw)
}

real matrix pocoint_make_trend(real scalar nobs, string scalar trend)
{
    real colvector t
    if (trend == "n")   return(J(nobs, 0, .))
    if (trend == "c")   return(J(nobs, 1, 1))
    t = (1::nobs)
    if (trend == "ct")  return((J(nobs,1,1), t))
    if (trend == "ctt") return((J(nobs,1,1), t, t:^2))
    return(J(0,0,.))
}

// Andrews/Newey-West optimal bandwidth (matches arch.covariance.kernel)
// xi may be matrix (T x m); collapses via rowsum (arch's default 1-vector weighting)
real scalar pocoint_optbw(real matrix xi, string scalar kernel)
{
    real scalar    nobs, n, j, q, c, rate, alpha_q, bw, sig_j, scale, f0, fq
    real colvector v

    if (kernel == "bartlett") {
        c    = 1.1447
        q    = 1.0
        rate = 2/9
    }
    else if (kernel == "parzen") {
        c    = 2.6614
        q    = 2.0
        rate = 4/25
    }
    else {
        c    = 1.3221
        q    = 2.0
        rate = 2/25
    }

    if (cols(xi) == 1) {
        v = xi[., 1]
    }
    else {
        v = rowsum(xi)
    }

    nobs = rows(v)
    n = ceil(4 * (nobs/100)^rate)
    f0 = 0
    fq = 0
    for (j = 0; j <= n; j++) {
        sig_j = (v[j+1..nobs])' * v[1..nobs-j] / nobs
        scale = 1 + (j != 0)
        f0 = f0 + scale * sig_j
        fq = fq + scale * (j^q) * sig_j
    }
    alpha_q = (fq / f0)^2
    bw = c * (alpha_q * nobs)^(1 / (2*q + 1))
    if (bw > nobs - 1) bw = nobs - 1
    return(bw)
}

// For Z-tests, optimal bw is computed on the AR(1) residual k of the
// cointegrating regression's residual u. For P-tests, optimal bw is
// computed on the VAR(1) innovations xi of (y, X).
real scalar pocoint_compute_optbw(real colvector y, real matrix X, string scalar trend, string scalar test, string scalar kernel)
{
    real matrix    tr, XX, k, Z, z_lead, z_lag_raw, z_lag, tr_lag, phi, xi
    real colvector u, beta, ulag, ulead
    real scalar    nobs, alpha, nobs_full

    if (test == "Za" | test == "Zt") {
        nobs = rows(y)
        tr = pocoint_make_trend(nobs, trend)
        XX = (cols(tr) > 0 ? (tr, X) : X)
        beta = qrsolve(XX, y)
        u = y - XX * beta
        nobs = rows(u)
        ulag  = u[1..nobs-1]
        ulead = u[2..nobs]
        alpha = qrsolve(ulag, ulead)
        k = ulead - alpha * ulag
        return(pocoint_optbw(k, kernel))
    }
    // P-tests: VAR(1) on (y, X)
    Z = (y, X)
    nobs_full = rows(Z)
    z_lead = Z[2..nobs_full, .]
    z_lag_raw = Z[1..nobs_full-1, .]
    tr_lag = pocoint_make_trend(rows(z_lag_raw), trend)
    z_lag = (cols(tr_lag) > 0 ? (tr_lag, z_lag_raw) : z_lag_raw)
    phi = qrsolve(z_lag, z_lead)
    xi = z_lead - z_lag * phi
    return(pocoint_optbw(xi, kernel))
}

void pocoint_bartlett(real matrix xi, real scalar bw, real matrix long_run, real matrix one_sided_strict)
{
    real scalar Tn, j, w
    real matrix Gj, G0
    Tn = rows(xi)
    G0 = (xi' * xi) / Tn
    one_sided_strict = J(cols(xi), cols(xi), 0)
    for (j = 1; j <= bw; j++) {
        w = 1 - j/(bw + 1)
        Gj = (xi[j+1..Tn, .]' * xi[1..Tn-j, .]) / Tn
        one_sided_strict = one_sided_strict + w * Gj
    }
    long_run = G0 + one_sided_strict + one_sided_strict'
}

// kernel weight vector w[1..(K+1)] for lags 0..K (Bartlett, Parzen, QS)
real rowvector pocoint_kweights(string scalar kernel, real scalar bw, real scalar Tn)
{
    real scalar    K, j, xj, z, pi5
    real rowvector w

    if (kernel == "bartlett") {
        K = floor(bw)
        w = J(1, K + 1, 0)
        for (j = 0; j <= K; j++) {
            w[1, j+1] = (bw + 1 - j) / (bw + 1)
        }
        return(w)
    }
    if (kernel == "parzen") {
        K = floor(bw)
        w = J(1, K + 1, 0)
        for (j = 0; j <= K; j++) {
            xj = j / (bw + 1)
            if (xj <= 0.5) {
                w[1, j+1] = 1 - 6*xj^2*(1 - xj)
            }
            else {
                w[1, j+1] = 2*(1 - xj)^3
            }
        }
        return(w)
    }
    // quadratic-spectral: support is whole sample
    pi5 = 6 * pi() / 5
    w = J(1, Tn, 0)
    w[1, 1] = 1
    if (bw > 0) {
        for (j = 1; j < Tn; j++) {
            xj = j / bw
            z = pi5 * xj
            w[1, j+1] = 3 / z^2 * (sin(z)/z - cos(z))
        }
    }
    return(w)
}

// generic long-run covariance with kernel weights
void pocoint_lrv(real matrix xi, string scalar kernel, real scalar bw, real matrix long_run, real matrix one_sided_strict)
{
    real scalar    Tn, j, K
    real matrix    Gj, G0
    real rowvector w

    Tn = rows(xi)
    G0 = (xi' * xi) / Tn
    one_sided_strict = J(cols(xi), cols(xi), 0)
    w = pocoint_kweights(kernel, bw, Tn)
    K = cols(w) - 1
    for (j = 1; j <= K; j++) {
        if (j > Tn - 1) break
        Gj = (xi[j+1..Tn, .]' * xi[1..Tn-j, .]) / Tn
        one_sided_strict = one_sided_strict + w[1, j+1] * Gj
    }
    long_run = G0 + one_sided_strict + one_sided_strict'
}

real scalar pocoint_z_stat(real colvector y, real matrix X, string scalar trend, string scalar test, string scalar kernel, real scalar bw)
{
    real matrix    tr, XX, k, lr, oss
    real colvector u, beta, ulag, ulead
    real scalar    nobs, ks, alpha, u2, omega1, z, lr_v, se

    nobs = rows(y)
    tr = pocoint_make_trend(nobs, trend)
    XX = (cols(tr) > 0 ? (tr, X) : X)
    beta = qrsolve(XX, y)
    u = y - XX * beta
    nobs = rows(u)
    ks = (nobs - 1) / nobs
    ulag  = u[1..nobs-1]
    ulead = u[2..nobs]
    alpha = qrsolve(ulag, ulead)
    k = ulead - alpha * ulag
    u2 = ulag' * ulag
    if (kernel == "bartlett") {
        pocoint_bartlett(k, bw, lr=., oss=.)
    }
    else {
        pocoint_lrv(k, kernel, bw, lr=., oss=.)
    }
    omega1 = ks * oss[1,1]
    z = (alpha - 1) - nobs * omega1 / u2
    if (test == "Za") return(nobs * z)
    lr_v = ks * lr[1,1]
    se = sqrt(lr_v / u2)
    return(z / se)
}

real scalar pocoint_p_stat(real colvector y, real matrix X, string scalar trend, string scalar test, string scalar kernel, real scalar bw)
{
    real matrix    Z, z_lead, z_lag_raw, z_lag, tr_lag, phi, xi, lr, oss
    real matrix    omega, tr_full, Xc, beta, Mzz, zarr, tr, tcoef
    real colvector u
    real scalar    nobs_full, denom, o112
    real rowvector o21
    real matrix    o22

    Z = (y, X)
    nobs_full = rows(Z)
    z_lead = Z[2..nobs_full, .]
    z_lag_raw = Z[1..nobs_full-1, .]
    tr_lag = pocoint_make_trend(rows(z_lag_raw), trend)
    z_lag = (cols(tr_lag) > 0 ? (tr_lag, z_lag_raw) : z_lag_raw)
    phi = qrsolve(z_lag, z_lead)
    xi = z_lead - z_lag * phi
    if (kernel == "bartlett") {
        pocoint_bartlett(xi, bw, lr=., oss=.)
    }
    else {
        pocoint_lrv(xi, kernel, bw, lr=., oss=.)
    }
    omega = (nobs_full - 1) / nobs_full * lr

    tr_full = pocoint_make_trend(nobs_full, trend)
    Xc = (cols(tr_full) > 0 ? (tr_full, X) : X)
    beta = qrsolve(Xc, y)
    u = y - Xc * beta

    if (test == "Pu") {
        denom = (u' * u) / nobs_full
        o21 = omega[1, 2..cols(omega)]
        o22 = omega[2..rows(omega), 2..cols(omega)]
        o112 = omega[1,1] - o21 * luinv(o22) * o21'
        return(nobs_full * o112 / denom)
    }
    zarr = Z
    if (trend != "n") {
        tr = pocoint_make_trend(nobs_full, trend)
        tcoef = qrsolve(tr, zarr)
        zarr = zarr - tr * tcoef
    }
    else {
        zarr = zarr :- zarr[1, .]
    }
    Mzz = (zarr' * zarr) / nobs_full
    return(nobs_full * trace(omega * luinv(Mzz)))
}

void pocoint_tseries_nw(string scalar khvar, string scalar tvar, real scalar n, real scalar l)
{
    real colvector k
    real scalar    i, j, tmp1, tmp2, w, addn

    k = st_data(., khvar, tvar)
    k = select(k, k :< .)
    tmp1 = 0
    for (i = 1; i <= l; i++) {
        tmp2 = 0
        for (j = i + 1; j <= n; j++) {
            tmp2 = tmp2 + k[j] * k[j - i]
        }
        w = 1 - i / (l + 1)
        tmp1 = tmp1 + w * tmp2
    }
    addn = 2 * tmp1 / n
    st_numscalar("ssqrtl", st_numscalar("ssqrtl") + addn)
}

// EViews-mode helper: write the response-surface critical values (1%, 5%, 10%)
// and the minimum N to four named Stata scalars.
void pocoint_eviews_cv(real scalar test_id, real scalar trend_id, real scalar nvars, real scalar nobs, string scalar sname_cv1, string scalar sname_cv5, string scalar sname_cv10, string scalar sname_minN)
{
    real rowvector cvinfo
    cvinfo = pocoint_cv_lookup(test_id, trend_id, nvars, nobs)
    st_numscalar(sname_cv1,  cvinfo[1, 1])
    st_numscalar(sname_cv5,  cvinfo[1, 2])
    st_numscalar(sname_cv10, cvinfo[1, 3])
    st_numscalar(sname_minN, cvinfo[1, 4])
}


// R tseries::po.test p-value: linear interpolation on the built-in
// critical-value table.  Tables and probabilities reproduced verbatim
// from R's tseries::po.test source code.  Returns:
//   pval  = interpolated p-value
//   pflag = 0 (in range), 1 (smaller than printed), 2 (greater than printed)
void pocoint_tseries_pval(real scalar stat, real scalar nvars, real scalar demean, string scalar sname_pval, string scalar sname_pflag)
{
    real matrix    tab
    real rowvector tablep, row
    real scalar    idx, smin, smax, pv, pf, j

    tablep = (0.01, 0.025, 0.05, 0.075, 0.10, 0.125, 0.15)

    if (demean == 1) {
        tab = (28.32, 23.81, 20.49, 18.48, 17.04, 15.93, 14.91 \
               34.17, 29.74, 26.09, 23.87, 22.19, 21.04, 19.95 \
               41.13, 35.71, 32.06, 29.51, 27.58, 26.23, 25.05 \
               47.51, 41.64, 37.15, 34.71, 32.74, 31.15, 29.88 \
               52.17, 46.53, 41.94, 39.11, 37.01, 35.48, 34.20)
    }
    else {
        tab = (22.83, 18.89, 15.64, 13.81, 12.54, 11.57, 10.74 \
               29.27, 25.21, 21.48, 19.61, 18.18, 17.01, 16.02 \
               36.16, 31.54, 27.85, 25.52, 23.92, 22.62, 21.53 \
               42.87, 37.48, 33.48, 30.93, 28.85, 27.40, 26.17 \
               48.52, 42.55, 38.09, 35.51, 33.80, 32.27, 30.90)
    }
    tab = -tab

    idx = nvars - 1
    if (idx < 1) idx = 1
    if (idx > rows(tab)) idx = rows(tab)
    row = tab[idx, .]

    // table values increase with p-value (less negative as p grows)
    smin = row[1]                  // most negative -> smallest p (0.01)
    smax = row[length(row)]        // least negative -> largest p (0.15)

    pf = 0
    if (stat <= smin) {
        pv = tablep[1]
        pf = 1
    }
    else if (stat >= smax) {
        pv = tablep[length(tablep)]
        pf = 2
    }
    else {
        for (j = 1; j < length(row); j = j + 1) {
            if (stat >= row[j] & stat <= row[j+1]) {
                pv = tablep[j] + (tablep[j+1] - tablep[j]) * (stat - row[j]) / (row[j+1] - row[j])
                break
            }
        }
    }

    st_numscalar(sname_pval,  pv)
    st_numscalar(sname_pflag, pf)
}


// ----- urca::ca.po-compatible runner -----
void pocoint_urca_run(string scalar dvar, string scalar ivars, string scalar touse, string scalar test, string scalar trend, real scalar bw, real scalar nvars, string scalar sname_stat, string scalar sname_cv1, string scalar sname_cv5, string scalar sname_cv10)
{
    real colvector y
    real matrix    X, Z, zl, zr, Xc, Xc_full, res, smat, omega, block, Mzz
    real colvector beta_lag_col, beta_co, resu, trd, trd_full, ones_n, ones_full
    real matrix    beta_lag
    real scalar    nobs_full, nobs, m, i, w, sigma_u, omega112, stat
    real rowvector omega21, cv
    real matrix    omega22

    y = st_data(., dvar, touse)
    X = st_data(., ivars, touse)
    Z = (y, X)
    nobs_full = rows(Z)
    m = cols(Z)
    zl = Z[2..nobs_full, .]
    zr = Z[1..nobs_full-1, .]
    nobs = nobs_full - 1

    if (trend == "n") {
        beta_lag = qrsolve(zr, zl)
        res = zl - zr * beta_lag
        if (test == "Pu") {
            beta_co = qrsolve(X, y)
            resu = y - X * beta_co
        }
    }
    else if (trend == "c") {
        ones_n = J(nobs, 1, 1)
        Xc = (ones_n, zr)
        beta_lag = qrsolve(Xc, zl)
        res = zl - Xc * beta_lag
        if (test == "Pu") {
            ones_full = J(nobs_full, 1, 1)
            Xc_full = (ones_full, X)
            beta_co = qrsolve(Xc_full, y)
            resu = y - Xc_full * beta_co
        }
    }
    else {
        // "ct"
        ones_n = J(nobs, 1, 1)
        trd = (1::nobs)
        Xc = (ones_n, zr, trd)
        beta_lag = qrsolve(Xc, zl)
        res = zl - Xc * beta_lag
        if (test == "Pu") {
            ones_full = J(nobs_full, 1, 1)
            trd_full = (1::nobs_full)
            Xc_full = (ones_full, X, trd_full)
            beta_co = qrsolve(Xc_full, y)
            resu = y - Xc_full * beta_co
        }
    }

    // Long-run covariance (urca formulation):
    // omega = (1/nobs) * res'res + (1/nobs) * sum_{i=1..bw} w_i * (Gamma_i + Gamma_i')
    smat = J(m, m, 0)
    for (i = 1; i <= bw; i++) {
        w = 1 - i/(bw + 1)
        block = res[i+1..nobs, .]' * res[1..nobs-i, .] + res[1..nobs-i, .]' * res[i+1..nobs, .]
        smat = smat + w * block
    }
    omega = (res' * res) / nobs + smat / nobs

    if (test == "Pz") {
        Mzz = (zl' * zl) / nobs
        stat = nobs * trace(omega * luinv(Mzz))
    }
    else {
        sigma_u = (resu' * resu) / nobs
        omega21 = omega[2..m, 1]'
        omega22 = omega[2..m, 2..m]
        omega112 = omega[1,1] - omega21 * luinv(omega22) * omega21'
        stat = nobs * omega112 / sigma_u
    }

    cv = pocoint_urca_cv(test, trend, nvars)

    st_numscalar(sname_stat, stat)
    st_numscalar(sname_cv10, cv[1,1])
    st_numscalar(sname_cv5,  cv[1,2])
    st_numscalar(sname_cv1,  cv[1,3])
}


// ----- urca critical-value table (from urca/R/ca-po.R) -----
// Table is indexed by (test, trend, m) where m = nvars - 1 in {1..5}
// and stores (cv10, cv5, cv1).
real rowvector pocoint_urca_cv(string scalar test, string scalar trend, real scalar nvars)
{
    real matrix    Tcv
    real scalar    test_id, trend_id, m, i
    real rowvector miss

    miss = (., ., .)
    if (test == "Pu") test_id = 3
    else              test_id = 4
    if      (trend == "n")  trend_id = 1
    else if (trend == "c")  trend_id = 2
    else                    trend_id = 3
    m = nvars - 1
    if (m < 1 | m > 5) return(miss)

    Tcv = (
        3, 1, 1, 20.3933, 25.9711, 38.3413 \
        3, 1, 2, 26.7022, 32.9392, 46.4097 \
        3, 1, 3, 33.5359, 40.1220, 55.7341 \
        3, 1, 4, 39.2826, 46.2691, 63.2149 \
        3, 1, 5, 44.3725, 51.8614, 69.4939 \
        3, 2, 1, 27.8536, 33.7130, 48.0021 \
        3, 2, 2, 33.6955, 40.5252, 53.8731 \
        3, 2, 3, 39.6949, 46.7281, 63.4128 \
        3, 2, 4, 45.3308, 53.2502, 71.5214 \
        3, 2, 5, 50.3537, 57.7855, 76.7705 \
        3, 3, 1, 41.2488, 48.8439, 65.1714 \
        3, 3, 2, 46.1061, 53.8300, 69.2629 \
        3, 3, 3, 52.0015, 60.2384, 78.3470 \
        3, 3, 4, 57.3667, 65.8706, 84.5480 \
        3, 3, 5, 61.6155, 70.7416, 91.0392 \
        4, 1, 1, 33.9267, 40.8217, 55.1911 \
        4, 1, 2, 62.1436, 71.2751, 89.6679 \
        4, 1, 3, 99.2664, 109.7426, 131.5716 \
        4, 1, 4, 143.0775, 155.8019, 180.4845 \
        4, 1, 5, 195.6202, 210.2910, 237.7723 \
        4, 2, 1, 47.5877, 55.2202, 71.9273 \
        4, 2, 2, 80.2034, 89.7619, 109.4525 \
        4, 2, 3, 120.3035, 132.2207, 153.4504 \
        4, 2, 4, 168.8572, 182.0749, 209.8054 \
        4, 2, 5, 225.2303, 241.3316, 270.5018 \
        4, 3, 1, 71.9586, 81.3812, 102.0167 \
        4, 3, 2, 113.4929, 124.3933, 145.8644 \
        4, 3, 3, 163.1050, 175.9902, 201.0905 \
        4, 3, 4, 219.5098, 234.2865, 264.4988 \
        4, 3, 5, 284.0100, 301.0949, 335.9054
    )
    for (i = 1; i <= rows(Tcv); i++) {
        if (Tcv[i,1] == test_id & Tcv[i,2] == trend_id & Tcv[i,3] == m) {
            return((Tcv[i,4], Tcv[i,5], Tcv[i,6]))
        }
    }
    return(miss)
}

end
