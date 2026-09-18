*! ltscoint_example.do  1.0.0  17sep2026
*! Self-test and worked examples for ltscoint
*! Merwan Roudane -- merwanroudane920@gmail.com -- https://github.com/merwanroudane
*
* Part A  Monte Carlo on the paper's own DGP (Berenguer-Rico & Nielsen 2026, eqs 6.1-6.3):
*         known truth, size of the t-test on kappa (their Table 1 design, 5 outlier episodes)
* Part B  Exact enumeration vs FAST-LTS (must agree)
* Part C  Empirical illustration: UK consumption and income (their Section 7), tables + figures
*
* Run:   do ltscoint_example.do      (after net install / adopath, or after: do ltscoint.ado)

version 14.0
clear
set more off
capture program drop _ltsc_mcdgp
capture log close
log using ltscoint_example.log, replace text

* ---------------------------------------------------------------------------
* Part A.  Monte Carlo: DGP (6.1)-(6.2) with outliers in 5 episodes (Table 1)
* ---------------------------------------------------------------------------
*   Dy_t = omega Dz_t + alpha (y_{t-1} - kappa z_{t-1} - nu) + eps_t ,   Dz_t = eta_t
*   omega = 0.5, kappa = 1, nu = 1, alpha = -0.2, sigma_eps = sigma_eta = 1
*   T - h = sqrt(T)/2 outliers in G = 5 equally spaced episodes;
*   outlier errors: eta = sqrt(2 log h) + U(0,1), eps = sqrt(2 log h) + U(0,1) + 10
*   Test H0: kappa = 1 at 5% with OLS (full sample) and LTS (known h).

program define _ltsc_mcdgp, rclass
    * creates y z (T obs) with the Table-1 outlier layout; leaves T, h in r()
    syntax , T(integer) [alpha(real -0.2) G(integer 5) seed(integer 1)]
    clear
    set seed `seed'
    local nout = round(sqrt(`t')/2)
    local h = `t' - `nout'
    local per = floor(`nout'/`g')
    local gap = floor(`h'/`g')
    set obs `t'
    gen int time = _n
    tsset time
    gen byte bad = 0
    * episodes: gap good, per outliers, gap good, per outliers, ...
    local pos = `gap'
    forvalues e = 1/`g' {
        forvalues j = 1/`per' {
            local ++pos
            qui replace bad = 1 if time==`pos'
        }
        local pos = `pos' + `gap'
    }
    local c = sqrt(2*ln(`h'))
    gen double eta = rnormal()
    gen double eps = rnormal()
    qui replace eta = `c' + runiform()      if bad
    qui replace eps = `c' + runiform() + 10 if bad
    gen double z = sum(eta)                 // z_0 = 0
    gen double y = .
    * y_0 = nu = 1 ;  Dy = 0.5 Dz + alpha (y_{t-1} - z_{t-1} - 1) + eps
    qui replace y = 1 + 0.5*z[1] + `alpha'*(1 - 0 - 1) + eps[1] in 1
    forvalues i = 2/`t' {
        qui replace y = y[`i'-1] + 0.5*(z[`i']-z[`i'-1]) + `alpha'*(y[`i'-1] - z[`i'-1] - 1) + eps[`i'] in `i'
    }
    return scalar h = `h'
    return scalar nout = `nout'
end

local R = 200                       // repetitions (10^4 in the paper); 200 is enough to see 0.05 vs 0.30
local T = 100
tempname RES
matrix `RES' = J(`R', 6, .)
matrix colnames `RES' = rej_ols rej_lts kap_ols kap_lts nfound alpha_lts
di as txt _n "Part A: Monte Carlo, T = `T', alpha = -0.2, kappa = 1, 5 outlier episodes, `R' reps" _n
forvalues r = 1/`R' {
    qui _ltsc_mcdgp, t(`T') seed(`=1000+`r'')
    local nout = r(nout)
    qui ltscoint y z, nout(`nout') lags(1) seed(`=2000+`r'') notests
    tempname K KO
    matrix `K'  = e(kappa)
    matrix `KO' = e(kappa_ols)
    matrix `RES'[`r',1] = (abs((`KO'[1,1]-1)/`KO'[1,2]) > 1.96)
    matrix `RES'[`r',2] = (abs((`K'[1,1]-1)/`K'[1,2])   > 1.96)
    matrix `RES'[`r',3] = `KO'[1,1]
    matrix `RES'[`r',4] = `K'[1,1]
    * how many of the true outliers were found?
    qui count if bad==1 & e(sample)
    local ntrue = r(N)
    tempvar g
    qui gen byte `g' = 1 if e(sample)
    foreach yr in `e(outyears)' {
        qui replace `g' = 0 if time==`yr'
    }
    qui count if bad==1 & `g'==0
    matrix `RES'[`r',5] = r(N)/`ntrue'
    matrix `RES'[`r',6] = e(alpha)
    if (mod(`r',50)==0) di as txt "  rep `r' done"
}
clear
qui svmat double `RES', name(m)
di as txt _n "Rejection frequency of H0: kappa = 1 at nominal 5% (paper Table 1, alpha = -0.2, sqrt(T)/2 column, T = 100:"
di as txt "   OLS 0.088   LTS 0.067)"
qui sum m1
di as txt "   OLS: " as res %6.3f r(mean)
qui sum m2
di as txt "   LTS: " as res %6.3f r(mean)
qui sum m3
di as txt "Mean kappa-hat  OLS: " as res %7.4f r(mean) as txt "   (truth 1)"
qui sum m4
di as txt "Mean kappa-hat  LTS: " as res %7.4f r(mean)
qui sum m6
di as txt "Mean alpha-hat  LTS: " as res %7.4f r(mean) as txt "   (truth -0.2)"
qui sum m5
di as txt "Share of true outliers recovered by LTS: " as res %6.3f r(mean)

* ---------------------------------------------------------------------------
* Part B.  Exact enumeration vs FAST-LTS on a small sample
* ---------------------------------------------------------------------------
di as txt _n "Part B: exact enumeration vs FAST-LTS (T = 30, T-h = 2) -- rss and outliers must agree" _n
qui _ltsc_mcdgp, t(30) seed(77)
ltscoint y z, nout(2) lags(1) exact notests noheader
local rss_ex = e(rss)
local out_ex "`e(outyears)'"
ltscoint y z, nout(2) lags(1) seed(5) notests noheader
di as txt "exact: rss = " as res %12.8f `rss_ex' as txt "  outliers: " as res "`out_ex'"
di as txt "fast : rss = " as res %12.8f e(rss)  as txt "  outliers: " as res "`e(outyears)'"
assert reldif(`rss_ex', e(rss)) < 1e-8

* ---------------------------------------------------------------------------
* Part C.  Empirical illustration: UK consumption and income (Section 7)
* ---------------------------------------------------------------------------
di as txt _n "Part C: UK consumption function, ADL(2) with trend, 1957-2023" _n
use ltscoint_ukcons.dta, clear
capture mkdir figures
* Figure 2 analogue: data plot
ltscoint dataplot c y if year<=2023, kappa(1) name(fig2)
capture noisily graph export figures/fig2_data.png, name(fig2) replace width(1200)
* Table 7 analogue: profile of T_h over h, with plot
ltscoint hsearch c y if year<=2023, trend lags(2) seed(1) graph name(fig_h)
capture noisily graph export figures/fig_h_profile.png, name(fig_h) replace width(1600)
* Equations (7.1)-(7.3): full-sample OLS vs LTS with T-h = 5, homogeneity test kappa = 1,
* weak-exogeneity regression, mis-specification tests, and the Figure 3/4 graphics
ltscoint c y if year<=2023, nout(5) trend lags(2) seed(1) kappa0(1) wetest graph name(fig4) generate(good_lts)
capture noisily graph export figures/fig4_misspec.png, name(fig4) replace width(1600)
* SLTS standard errors (robust-statistics convention) for comparison
ltscoint c y if year<=2023, nout(5) trend lags(2) seed(1) slts noheader notests
* Data-driven h (argmin T_h) on the current ONS vintage
ltscoint c y if year<=2023, trend lags(2) seed(1)
* postestimation graphics can be regenerated at any time
ltscoint graph, name(fig4b)
log close
