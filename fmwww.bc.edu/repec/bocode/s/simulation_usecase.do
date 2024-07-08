*! simulation_usecase.do Version 1.0.0 JRC 2024-07-07

version 18.0

clear *

set seed 722098273

/* "Pooled" logistic regression with cluster-robust standard errors and GEE 
    with time-varying predictor and autoregressive correlation rho = 0.6 */
matrix define M = (0.8, 2/3, 1/2, 1/3, 1/5)
matrix define C = J(5, 5, 0.6) + I(5) * 0.4
forvalues i = 2/5 {
    forvalues j = 1/`=`i'-1' {
        matrix define C[`i',`j'] = C[`i',`j']^abs(`i' - `j')
        matrix define C[`j',`i'] = C[`i',`j']
    }
}
forvalues i = 1/5 {
    matrix define C[`i', `i'] = 1
}
ovbdc , means(M) corr(C) verbose
matrix define A = r(A)
matrix define Z = r(Z)

program define simEm, rclass
    version 18.0
    syntax , a(name) z(name) [n(integer 200)]

    drop _all
    set obs `n'
    forvalue i = 1/5 {
        local varlist `varlist' out`i'
    }
    ovbdr `varlist', a(`a') z(`z')
    generate `c(obs_t)' pid = _n
    reshape long out, i(pid) j(tim)

    tempname true gee
    scalar define `true' = ln((0.2 / 0.8) / (0.8 / 0.2)) / 4
    
    // Method 1
    xtgee out c.tim, i(pid) t(tim) family(binomial) link(logit) corr(ar 1)
    scalar define `gee' = inrange(`true', r(table)["ll", "tim"], ///
        r(table)["ul", "tim"])

    // Method 2
    logit out c.tim, vce(cluster pid)
    return scalar pooled = inrange(`true', r(table)["ll", "out:tim"], ///
        r(table)["ul", "out:tim"])
    return scalar gee = `gee'
end

quietly simulate gee = r(gee) pooled = r(pooled), reps(1000): simEm , a(A) z(Z)
foreach method in gee pooled {
    summarize `method', meanonly
    display in smcl as text "CI coverage with `method' = " ///
        as result %4.1f 100 * r(mean)
}

exit
