*! version 0.1.0  copulaendog -- Gaussian copula corrections for endogenous regressors
*!
*! Stata port of the R reference implementation
*!   Haschka, R. E. (2026). Copula-based endogeneity corrections in R.
*!   https://github.com/HashtagHaschka/Copula-based-endogeneity-corrections
*! and of the packaged version of it, Malshe, A., endogCopula.
*!
*! Five cross-sectional estimators:
*!   pg      Park & Gupta (2012)
*!   2scope  Yang, Qian & Xie (2025)
*!   ima     Haschka (2025a)
*!   bmw     Breitung, Mayer & Wied (2024)
*!   jams    Liengaard et al. (2025)

program define copulaendog, eclass sortpreserve
    version 16.0

    if replay() {
        if "`e(cmd)'" != "copulaendog" error 301
        syntax [, Level(cilevel) VALidity ]
        Display, level(`level')
        if "`validity'" != "" Validity
        exit
    }

    syntax varlist(numeric min=2) [if] [in] , ///
        [ EXog(varlist numeric fv)            ///
          Method(string)                      ///
          CDF(string)                         ///
          TIes(string)                        ///
          NBoots(integer 199)                 ///
          SEED(string)                        ///
          CONDitional(varlist numeric)        ///
          FSExclude(varlist numeric)          ///
          DIScrete(varlist numeric)           ///
          GENerate(name)                      ///
          noCONStant                          ///
          Level(cilevel)                      ///
          VALidity ]

    * ---------------------------------------------------------------- method
    if "`method'" == "" local method "pg"
    local method = lower("`method'")
    if !inlist("`method'", "pg", "2scope", "ima", "bmw", "jams") {
        di as err "method() must be one of: pg, 2scope, ima, bmw, jams"
        exit 198
    }

    * ------------------------------------------------------------------- cdf
    local cdf = subinstr(lower("`cdf'"), "_", ".", .)
    if "`cdf'" == "" {
        * defaults follow each estimator's own paper
        if "`method'" == "pg"     local cdf "kde.silverman"
        if "`method'" == "2scope" local cdf "rank.n"
        if "`method'" == "ima"    local cdf "rank.n"
        if "`method'" == "bmw"    local cdf "rank.n1"
        if "`method'" == "jams"   local cdf "ecdf.adj"
    }
    if "`cdf'" == "kde.cv" {
        di as err "cdf(kde.cv) is not available in the Stata port; the "     ///
                  "cross-validated bandwidth"
        di as err "of Li, Li & Racine (2017) needs the R or Python "         ///
                  "implementation."
        exit 198
    }
    if !inlist("`cdf'", "kde.silverman", "kde.plugin", "ecdf.fixed",        ///
                        "ecdf.adj", "rank.n", "rank.n1") {
        di as err "cdf() must be one of: kde.silverman, kde.plugin, "       ///
                  "ecdf.fixed, ecdf.adj, rank.n, rank.n1"
        exit 198
    }
    if "`method'" == "bmw" & "`cdf'" != "rank.n1" {
        di as txt "note: Proposition 3.1 of Breitung, Mayer & Wied (2024) "  ///
                  "is derived for cdf(rank.n1)."
        di as txt "      With cdf(`cdf') the point estimates remain "        ///
                  "sensible but the standard errors"
        di as txt "      are no longer covered by the published theory."
    }

    * ------------------------------------------------------------------ ties
    if "`ties'" == "" local ties "max"
    local ties = lower("`ties'")
    if !inlist("`ties'", "max", "average") {
        di as err "ties() must be max or average"
        exit 198
    }
    if `nboots' < 2 {
        di as err "nboots() must be at least 2"
        exit 198
    }

    * ------------------------------------------------------- sample and data
    gettoken depvar endog : varlist
    _fv_check_depvar `depvar'
    if "`endog'" == "" {
        di as err "at least one endogenous regressor is required"
        exit 198
    }

    marksample touse
    markout `touse' `conditional' `fsexclude' `discrete'
    if "`exog'" != "" {
        fvrevar `exog', list
        markout `touse' `r(varlist)'
    }

    * factor variables in exog() are expanded into temporary indicators, so
    * that the rest of the command sees a plain design matrix.  fvrevar is no
    * help for this: handed a list of specific levels it rebases them and
    * returns an all-zero column for whichever one it decides is the base, so
    * each kept column is built here from what _ms_parse_parts reports.  Note
    * that fvrevar and generate both reset r(), so the parse is copied into
    * locals before anything else is run.
    local wnames
    local wvars
    if "`exog'" != "" {
        fvexpand `exog' if `touse'
        local exexp `r(varlist)'
        foreach v of local exexp {
            _ms_parse_parts `v'
            local ptype  "`r(type)'"
            local pname  "`r(name)'"
            local pomit  = r(omit)
            local pbase  = cond(r(base)    == ., 0, r(base))
            local plevel = r(level)
            local pk     = cond(r(k_names) == ., 0, r(k_names))
            forvalues i = 1/`pk' {
                local pop`i'  "`r(op`i')'"
                local pnm`i'  "`r(name`i')'"
                local plv`i'  = r(level`i')
            }

            if `pomit' continue
            if "`ptype'" == "factor" & `pbase' continue

            if "`ptype'" == "variable" {
                fvrevar `pname' if `touse'
                local wvars `wvars' `r(varlist)'
            }
            else if "`ptype'" == "factor" {
                tempvar fv
                quietly generate byte `fv' = (`pname' == `plevel') if `touse'
                local wvars `wvars' `fv'
            }
            else {
                * an interaction is the product of its parts, each of which is
                * either a continuous variable or a single level indicator
                local expr
                forvalues i = 1/`pk' {
                    if inlist("`pop`i''", "c", "co") {
                        local expr `expr' * `pnm`i''
                    }
                    else {
                        local expr `expr' * (`pnm`i'' == `plv`i'')
                    }
                }
                local expr = substr("`expr'", 3, .)
                tempvar fv
                quietly generate double `fv' = `expr' if `touse'
                local wvars `wvars' `fv'
            }
            local wnames `wnames' `v'
        }
        local n1 : word count `wnames'
        local n2 : word count `wvars'
        if `n1' != `n2' {
            di as err "could not line the expanded exogenous regressors up "  ///
                      "with their names;"
            di as err "create the indicator variables yourself and pass "     ///
                      "them as plain variables."
            exit 498
        }
    }

    * which exogenous columns are held out of the first stage.  In R a term
    * built from an endogenous variable is excluded automatically; here the
    * exogenous list is taken as given and fsexclude() is the override.
    local fskeep
    local i = 0
    foreach v of local wnames {
        local ++i
        local hit = 0
        foreach f of local fsexclude {
            if strpos("`v'", "`f'") local hit = 1
        }
        if !`hit' local fskeep `fskeep' `i'
    }

    * which exogenous columns are discrete and therefore stay out of the
    * copula terms of JAMS (Equation 17 transforms the continuous W only)
    local jcont
    local i = 0
    foreach v of local wnames {
        local ++i
        local hit = 0
        foreach f of local discrete {
            if strpos("`v'", "`f'") local hit = 1
        }
        _ms_parse_parts `v'
        if "`r(type)'" == "factor" local hit = 1
        if !`hit' local jcont `jcont' `i'
    }

    * ------------------------------------------------------------ JAMS cells
    tempvar cell
    local ncells = 1
    if "`method'" == "jams" & "`conditional'" != "" {
        quietly egen long `cell' = group(`conditional') if `touse'
        quietly summarize `cell' if `touse', meanonly
        local ncells = r(max)
    }
    else {
        quietly generate byte `cell' = 1 if `touse'
        if "`method'" == "jams" {
            di as txt "note: conditional() names no variables, so one common " ///
                      "copula structure is"
            di as txt "      estimated (Equation 18). Name the categorical "   ///
                      "controls in conditional()"
            di as txt "      to let it vary across their categories "          ///
                      "(Equations 20-21)."
        }
    }

    tempvar cons
    quietly generate byte `cons' = 1 if `touse'
    if "`seed'" != "" set seed `seed'

    * --------------------------------------------------------------- fit it
    * generate() keeps the copula terms as variables, named after the
    * coefficients they belong to so that predict xba can find them again
    mata: ce_main("`depvar'", "`endog'", "`wvars'", "`cell'", "`touse'",   ///
                  "`method'", "`cdf'", "`ties'", `nboots',                 ///
                  "`constant'" == "", "`fskeep'", "`jcont'", `ncells',     ///
                  "`generate'" != "")

    * -------------------------------------------------------------- post it
    local colnames `endog' `wnames'
    if "`constant'" == "" local colnames `colnames' _cons
    local colnames `colnames' `copnames'

    matrix colnames b_ce = `colnames'
    matrix rownames b_ce = `depvar'
    matrix colnames V_ce = `colnames'
    matrix rownames V_ce = `colnames'

    local xnames `endog' `wnames'
    if "`constant'" == "" local xnames `xnames' _cons
    matrix colnames rho_ce   = `endog'
    matrix colnames rhose_ce = `endog'
    matrix colnames icon_ce  = `xnames'
    matrix rownames icon_ce  = ICON SE_corrected
    matrix colnames bols_ce  = `xnames'
    matrix colnames seols_ce = `xnames'
    matrix colnames diag_ce  = `endog'
    matrix rownames diag_ce  = skewness ex_kurtosis AD CvM KS_p Yang_ok Becker_ok

    ereturn post b_ce V_ce, esample(`touse') depname(`depvar') obs(`e_nobs')

    ereturn local cmd        "copulaendog"
    ereturn local cmdline    `"copulaendog `0'"'
    ereturn local depvar     "`depvar'"
    ereturn local endogenous "`endog'"
    ereturn local exogenous  "`wnames'"
    ereturn local copnames   "`copnames'"
    ereturn local method     "`method'"
    ereturn local methodlab  "`methodlab'"
    ereturn local nonnormof  "`nonnormof'"
    ereturn local cdf        "`cdf'"
    ereturn local ties       "`ties'"
    ereturn local predict    "copulaendog_p"

    ereturn scalar N        = `e_nobs'
    ereturn scalar nboots   = `nboots_used'
    ereturn scalar df_r     = `e_dfr'
    ereturn scalar rmse     = `e_rmse'
    ereturn scalar r2       = `e_r2'
    ereturn scalar r2_a     = `e_r2a'
    ereturn scalar rmse_s   = `e_rmse_s'
    ereturn scalar r2_s     = `e_r2_s'
    ereturn scalar icon_max = `e_iconmax'
    ereturn scalar xi_skew  = `e_xiskew'
    ereturn scalar xi_kurt  = `e_xikurt'
    ereturn scalar xi_ad    = `e_xiad'
    ereturn scalar xi_ksp   = `e_xiksp'
    ereturn scalar th_skew  = `e_thskew'
    ereturn scalar th_ad    = `e_thad'
    ereturn scalar th_cvm   = `e_thcvm'

    ereturn matrix rho         = rho_ce
    ereturn matrix rho_se      = rhose_ce
    ereturn matrix icon        = icon_ce
    ereturn matrix b_ols       = bols_ce
    ereturn matrix se_ols      = seols_ce
    ereturn matrix diagnostics = diag_ce
    if "`method'" == "bmw" {
        matrix colnames dhw_ce = `copnames'
        matrix rownames dhw_ce = coef se
        ereturn matrix dhw = dhw_ce
    }
    if "`method'" == "pg" & "`wnames'" != "" {
        matrix colnames a5_ce = `wnames'
        matrix rownames a5_ce = corr p_holm
        ereturn matrix assumption5 = a5_ce
        ereturn scalar a5_r2 = `e_a5r2'
        ereturn scalar a5_F  = `e_a5F'
        ereturn scalar a5_p  = `e_a5p'
    }

    capture matrix drop b_ce V_ce rho_ce rhose_ce icon_ce bols_ce seols_ce ///
                        diag_ce dhw_ce a5_ce

    Display, level(`level')
    if "`validity'" != "" Validity
end


* ---------------------------------------------------------------------------
program define Display
    syntax [, Level(cilevel) ]

    di
    di as txt "Copula endogeneity correction: " as res "`e(methodlab)'"
    di as txt "Number of obs    = " as res %9.0g e(N)
    di as txt "Bootstrap reps   = " as res %9.0g e(nboots)
    di as txt "Endogenous       = " as res "`e(endogenous)'"
    di as txt "CDF estimator    = " as res "`e(cdf)'" as txt "  ties = "     ///
       as res "`e(ties)'"
    di

    ereturn display, level(`level')

    di as txt "Standard errors are bootstrap standard errors from " as res   ///
       e(nboots) as txt " pairs resamples."
    di as txt "The copula terms are endogeneity controls and are not part "  ///
       "of the causal model."

    * ------------------------------------------------------------------ rho
    tempname r rs
    matrix `r'  = e(rho)
    matrix `rs' = e(rho_se)
    if `r'[1,1] < . {
        di
        di as txt "Endogeneity. rho(P*, xi*) is the correlation between "    ///
           "the normal score of an"
        di as txt "endogenous regressor and that of the structural error, "  ///
           "xi* = xi/sigma."
        di as txt "{hline 66}"
        di as txt %-18s "" %12s "rho" %12s "Std. err." %10s "z" %12s "P>|z|"
        di as txt "{hline 66}"
        local nms : colnames `r'
        local j = 0
        foreach nm of local nms {
            local ++j
            local e  = `r'[1,`j']
            local se = `rs'[1,`j']
            local z  = `e'/`se'
            di as txt %-18s "`nm'" as res %12.4f `e' %12.4f `se'            ///
               %10.2f `z' %12.3f 2*normal(-abs(`z'))
        }
        di as txt "{hline 66}"
    }

    * ----------------------------------------------------- Durbin-Hausman-Wu
    if "`e(method)'" == "bmw" {
        tempname d
        matrix `d' = e(dhw)
        di
        di as txt "Durbin-Hausman-Wu test of rho = 0. Breitung, Mayer & "    ///
           "Wied (2024, Corollary 3.2)"
        di as txt "show the textbook t statistic keeps a standard normal "   ///
           "limit under the null,"
        di as txt "even though these standard errors are wrong for the "     ///
           "structural coefficients."
        di as txt "{hline 66}"
        di as txt %-18s "" %12s "Coef." %12s "Std. err." %10s "t" %12s "P>|t|"
        di as txt "{hline 66}"
        local nms : colnames `d'
        local j = 0
        foreach nm of local nms {
            local ++j
            local e  = `d'[1,`j']
            local se = `d'[2,`j']
            local t  = `e'/`se'
            di as txt %-18s "`nm'" as res %12.4f `e' %12.4f `se'            ///
               %10.2f `t' %12.3f 2*normal(-abs(`t'))
        }
        di as txt "{hline 66}"
    }

    * ------------------------------------------------------------------ fit
    di
    di as txt "Fit, on " as res e(df_r) as txt " residual degrees of freedom:"
    di as txt %-26s "" %14s "augmented" %14s "structural"
    di as txt %-26s "Residual std. error" as res %14.4f e(rmse)             ///
       %14.4f e(rmse_s)
    di as txt %-26s "R-squared" as res %14.4f e(r2) %14.4f e(r2_s)
    di as txt %-26s "Adjusted R-squared" as res %14.4f e(r2_a)              ///
       %14.4f (1 - (1-e(r2_s))*(e(N)-1)/e(df_r))
end


* ---------------------------------------------------------------------------
program define Validity
    tempname D I S

    di
    di as txt "{hline 78}"
    di as txt "Validity check for " as res "`e(methodlab)'"
    di as txt "Sources: Becker, Proksch & Ringle (2022); Yang, Qian & Xie "  ///
       "(2025);"
    di as txt "         Qian, Koschmann & Xie (2025)"
    di as txt "{hline 78}"

    matrix `D' = e(diagnostics)
    local nms : colnames `D'

    di
    di as txt "[1] Non-normality of the " as res "`e(nonnormof)'" as txt "."
    di as txt "    Yang ok: KS p < .05.  Becker ok: |skew| >= " as res       ///
       %5.3f e(th_skew) as txt ", AD > " as res %6.3f e(th_ad) as txt       ///
       " or CvM > " as res %5.3f e(th_cvm) as txt "."
    di as txt "{hline 76}"
    di as txt %-14s "" %10s "skewness" %10s "ex.kurt" %10s "AD" %10s "CvM"  ///
       %10s "KS p" %6s "Yang" %6s "Beck"
    di as txt "{hline 76}"
    local j = 0
    foreach nm of local nms {
        local ++j
        local yes = cond(`D'[6,`j'] == 1, "yes", "no")
        local bec = cond(`D'[7,`j'] == 1, "yes", "no")
        di as txt %-14s abbrev("`nm'",13) as res %10.3f `D'[1,`j']          ///
           %10.3f `D'[2,`j'] %10.3f `D'[3,`j'] %10.3f `D'[4,`j']            ///
           %10.4f `D'[5,`j'] as txt %6s "`yes'" %6s "`bec'"
    }
    di as txt "{hline 76}"

    capture matrix `S' = e(assumption5)
    if _rc == 0 {
        di
        di as txt "[2] Uncorrelatedness of the exogenous regressors with "   ///
           "the copula term"
        di as txt "    (Assumption 5 of Park & Gupta 2012; Yang, Qian & "    ///
           "Xie 2025, Fig. 2, Step 1)."
        di as txt "{hline 58}"
        di as txt %-26s "" %14s "corr(W, CTT)" %14s "p (Holm)"
        di as txt "{hline 58}"
        local anms : colnames `S'
        local j = 0
        foreach nm of local anms {
            local ++j
            di as txt %-26s abbrev("`nm'",25) as res %14.4f `S'[1,`j']      ///
               %14.4f `S'[2,`j']
        }
        di as txt "{hline 58}"
        di as txt "    Joint: R2 = " as res %6.4f e(a5_r2) as txt ", F = "   ///
           as res %8.3f e(a5_F) as txt ", p = " as res %8.4f e(a5_p)
        if e(a5_p) < 0.05 {
            di as txt "    " as err "! The assumption is rejected. Park & "  ///
               "Gupta is then biased; use"
            di as err "      method(2scope), method(ima) or method(bmw), "   ///
               "which project this"
            di as err "      correlation out in a first stage (Haschka 2025a)."
        }
    }
    else {
        di
        di as txt "[2] Not applicable: this estimator projects the "         ///
           "correlation with the"
        di as txt "    exogenous regressors out in its first stage."
    }

    di
    di as txt "[4] Structural error xi: skewness " as res %7.3f e(xi_skew)   ///
       as txt ", excess kurtosis " as res %7.3f e(xi_kurt)
    di as txt "    AD " as res %7.3f e(xi_ad) as txt ", KS p " as res        ///
       %7.4f e(xi_ksp)
    di as txt "    Becker et al. require a normal error; Yang et al. and "   ///
       "Qian et al. permit a"
    di as txt "    non-normal one under xi = U + V."

    di
    di as txt "[5] ICON, the standard error inflation relative to "          ///
       "uncorrected OLS."
    di as txt "    Above 6 flags weak identification or a misspecified "     ///
       "dependence model."
    matrix `I' = e(icon)
    tempname so
    matrix `so' = e(se_ols)
    local inms : colnames `I'
    di as txt "{hline 62}"
    di as txt %-24s "" %12s "SE (corr.)" %12s "SE (OLS)" %12s "ICON"
    di as txt "{hline 62}"
    local j = 0
    foreach nm of local inms {
        local ++j
        di as txt %-24s abbrev("`nm'",23) as res %12.4f `I'[2,`j']          ///
           %12.4f `so'[1,`j'] %12.4f `I'[1,`j']
    }
    di as txt "{hline 62}"
    di as txt "    max ICON = " as res %7.3f e(icon_max) as txt             ///
       cond(e(icon_max) > 6, "   !", "")
    di
end


* ===========================================================================
*  Mata
* ===========================================================================
version 16.0
mata:
mata set matastrict on

// ----------------------------------------------------------------- ranks ---
// ties = "max" reproduces F(x) = (1/n) sum I(X_i <= x) literally, which is how
// every one of the papers writes it.  "average" uses midranks, the convention
// of the wider copula literature; it only matters for tied values.
real colvector ce_rank(real colvector x, string scalar ties)
{
    real scalar n, i, j
    real colvector o, xs, r, res

    n  = rows(x)
    o  = order(x, 1)
    xs = x[o]
    r  = J(n, 1, .)

    i = 1
    while (i <= n) {
        j = i
        while (j < n) {
            if (xs[j+1] != xs[i]) break
            j++
        }
        if (ties == "max") r[|i \ j|] = J(j-i+1, 1, j)
        else               r[|i \ j|] = J(j-i+1, 1, (i+j)/2)
        i = j + 1
    }
    res = J(n, 1, .)
    res[o] = r
    return(res)
}

real scalar ce_sd(real colvector x)
{
    real scalar n, m
    n = rows(x)
    m = sum(x) / n
    return(sqrt(sum((x :- m):^2) / (n - 1)))
}

// type-7 quantile of a sorted vector, the default of R's quantile()
real scalar ce_quantile(real colvector xs, real scalar p)
{
    real scalar n, h, lo
    n  = rows(xs)
    h  = (n - 1) * p + 1
    lo = floor(h)
    if (lo >= n) return(xs[n])
    return(xs[lo] + (h - lo) * (xs[lo+1] - xs[lo]))
}

// Silverman's rule as used by Park & Gupta (2012, p. 571):
//   b = 0.9 n^(-1/5) min(s, IQR/1.34)
real scalar ce_bw_silverman(real colvector x)
{
    real scalar s, iq, sc
    real colvector xs

    s  = ce_sd(x)
    xs = sort(x, 1)
    iq = (ce_quantile(xs, 0.75) - ce_quantile(xs, 0.25)) / 1.34
    sc = min((s, iq))
    if (sc <= 0 | sc >= .) sc = (s > 0 & s < .) ? s : 1
    return(0.9 * rows(x)^(-1/5) * sc)
}

// ------------------------------------------------------------ kernel CDFs ---
// F(x_j) = (1/n) sum_i G((x_j - x_i)/b) with G the Epanechnikov CDF.
//
// Park & Gupta integrate the density numerically; the Epanechnikov kernel
// integrates in closed form, so the exact antiderivative is used instead --
// the same estimator without quadrature error.  G is a cubic on its support,
// so the window sums come from prefix sums of z, z^2 and z^3, which makes this
// O(n log n) rather than O(n^2).
real colvector ce_cdf_epan(real colvector x, real scalar b)
{
    real scalar n, m, s, bb, i, p, q
    real colvector o, z, zs, lo, hi, S1, S2, S3
    real colvector m0, m1, m2, m3, sd1, sd3, out, res

    n = rows(x)
    if (b <= 0 | b >= .) _error("non-positive bandwidth in kernel CDF")

    // affine equivariance: F_x(x_j; b) = F_z(z_j; b/s)
    m = sum(x) / n
    s = ce_sd(x)
    if (s <= 0 | s >= .) s = 1
    z  = (x :- m) / s
    bb = b / s

    o  = order(z, 1)
    zs = z[o]

    lo = J(n, 1, 0)
    hi = J(n, 1, 0)
    p = 0
    for (i = 1; i <= n; i++) {
        while (p < n) {
            if (zs[p+1] > zs[i] - bb) break
            p++
        }
        lo[i] = p
    }
    q = 0
    for (i = 1; i <= n; i++) {
        while (q < n) {
            if (zs[q+1] > zs[i] + bb) break
            q++
        }
        hi[i] = q
    }

    S1 = 0 \ runningsum(zs)
    S2 = 0 \ runningsum(zs:^2)
    S3 = 0 \ runningsum(zs:^3)

    m0 = hi - lo
    m1 = S1[hi :+ 1] - S1[lo :+ 1]
    m2 = S2[hi :+ 1] - S2[lo :+ 1]
    m3 = S3[hi :+ 1] - S3[lo :+ 1]

    sd1 = (m0 :* zs - m1) / bb
    sd3 = (m0 :* zs:^3 - 3 * zs:^2 :* m1 + 3 * zs :* m2 - m3) / bb^3

    out = (lo + 0.75 * sd1 - 0.25 * sd3 + 0.5 * m0) / n
    out = rowmax((J(n,1,0), rowmin((J(n,1,1), out))))

    res = J(n, 1, .)
    res[o] = out
    return(res)
}

real scalar ce_exactmax()
{
    return(1500)
}

real matrix ce_dnorm_deriv(real matrix x, real scalar sigma, real scalar r)
{
    real matrix z, He
    z = x / sigma
    if (r == 2)      He = z:^2 :- 1
    else if (r == 4) He = z:^4 - 6*z:^2 :+ 3
    else if (r == 6) He = z:^6 - 15*z:^4 + 45*z:^2 :- 15
    else             _error("Hermite polynomial of that order is not needed here")
    return((-1)^r * He :* normalden(z) / sigma^(r+1))
}

real scalar ce_dnd0(real scalar sigma, real scalar r)
{
    real matrix v
    v = ce_dnorm_deriv(0, sigma, r)
    return(v[1,1])
}

// Gaussian kernel CDF, F(x_j) = n^-1 sum_i Phi((x_j - X_i)/h).  Exact in
// chunks for moderate n; above ce_exactmax() the sample is binned on a grid and
// the result interpolated back, the way ks::kcde works.  The binned path is an
// approximation, of an order far below anything a bandwidth choice would notice.
real colvector ce_cdf_gauss(real colvector x, real scalar h)
{
    real scalar n, a, b, M, lo0, hi0, delta, i, j
    real colvector out, gr, cnt, idx, lo, w, Fg, xb

    n = rows(x)
    if (h <= 0 | h >= .) _error("non-positive bandwidth in kernel CDF")

    if (n <= ce_exactmax()) {
        out = J(n, 1, .)
        for (a = 1; a <= n; a = a + 500) {
            b  = min((a + 499, n))
            // a k x 1 and a 1 x n are not c-conformable in Mata, so the row
            // of evaluation points is expanded to k x n before subtracting
            xb = x[|a \ b|]
            out[|a \ b|] =
                rowsum(normal((xb :- J(rows(xb), 1, 1) * x') / h)) / n
        }
        return(out)
    }

    M     = 2048
    lo0   = min(x) - 8 * h
    hi0   = max(x) + 8 * h
    delta = (hi0 - lo0) / (M - 1)
    gr    = lo0 :+ (0::M-1) * delta

    cnt = J(M, 1, 0)
    idx = (x :- lo0) / delta
    lo  = floor(idx) :+ 1
    w   = idx - (lo :- 1)
    for (i = 1; i <= n; i++) {
        j = min((max((lo[i], 1)), M))
        cnt[j] = cnt[j] + (1 - w[i])
        j = min((j + 1, M))
        cnt[j] = cnt[j] + w[i]
    }

    Fg = J(M, 1, 0)
    for (i = 1; i <= M; i++)
        Fg[i] = sum(cnt :* normal((gr[i] :- gr) / h)) / n
    for (i = 2; i <= M; i++) if (Fg[i] < Fg[i-1]) Fg[i] = Fg[i-1]
    Fg = rowmax((J(M,1,0), rowmin((J(M,1,1), Fg))))

    out = J(n, 1, .)
    for (i = 1; i <= n; i++) {
        j = min((max((floor((x[i] - lo0) / delta) + 1, 1)), M - 1))
        out[i] = Fg[j] + (x[i] - gr[j]) / delta * (Fg[j+1] - Fg[j])
    }
    return(out)
}

// Polansky & Baker (2000) plug-in bandwidth for the distribution function,
// the two-stage normal-scale cascade psi_6 -> g_4 -> psi_4 -> g_2 -> psi_2 -> h
real scalar ce_psins(real scalar r, real scalar sigma)
{
    return((-1)^(r/2) * exp(lnfactorial(r)) /
           ((2*sigma)^(r+1) * exp(lnfactorial(r/2)) * sqrt(pi())))
}

real scalar ce_kfe(real colvector x, real scalar g, real scalar r)
{
    real scalar n, a, b, s, M, lo0, hi0, delta, i, j, tot
    real colvector cnt, idx, lo, w, k, sl, xb

    n = rows(x)
    if (n <= ce_exactmax()) {
        s = 0
        for (a = 1; a <= n; a = a + 500) {
            b  = min((a + 499, n))
            // see ce_cdf_gauss(): the k x 1 block has to be widened to k x n
            xb = x[|a \ b|]
            s  = s + sum(ce_dnorm_deriv(xb :- J(rows(xb), 1, 1) * x', g, r))
        }
        return(s / n^2)
    }

    lo0 = min(x); hi0 = max(x)
    if (hi0 <= lo0) return(ce_dnd0(g, r))
    M     = 1024
    delta = (hi0 - lo0) / (M - 1)

    cnt = J(M, 1, 0)
    idx = (x :- lo0) / delta
    lo  = floor(idx) :+ 1
    w   = idx - (lo :- 1)
    for (i = 1; i <= n; i++) {
        j = min((max((lo[i], 1)), M))
        cnt[j] = cnt[j] + (1 - w[i])
        j = min((j + 1, M))
        cnt[j] = cnt[j] + w[i]
    }

    // sum over lags of k(lag) times the autocorrelation of the bin counts;
    // phi^(r) is even for even r, so lags +l and -l contribute alike
    k  = ce_dnorm_deriv((0::M-1) * delta, g, r)
    sl = J(M, 1, 0)
    for (i = 1; i <= M; i++) {
        if (cnt[i] == 0) continue
        for (j = 1; j <= M; j++) {
            if (cnt[j] == 0) continue
            sl[abs(i - j) + 1] = sl[abs(i - j) + 1] + cnt[i] * cnt[j]
        }
    }
    tot = k[1] * sl[1]
    for (i = 2; i <= M; i++) tot = tot + k[i] * sl[i]
    return(tot / n^2)
}

real scalar ce_bw_plugin(real colvector x)
{
    real scalar n, K2, K4, m1, sx, psi6, g4, psi4, g2, psi2
    n  = rows(x)
    K2 = ce_dnd0(1, 2)
    K4 = ce_dnd0(1, 4)
    m1 = (4 * pi())^(-0.5)
    sx = ce_sd(x)
    if (sx <= 0 | sx >= .)
        _error("cannot choose a bandwidth for a constant variable")
    psi6 = ce_psins(6, sx)
    g4   = (2 * K4 / (-psi6 * n))^(1/7)
    psi4 = ce_kfe(x, g4, 4)
    g2   = (2 * K2 / (-psi4 * n))^(1/5)
    psi2 = ce_kfe(x, g2, 2)
    return((2 * m1 / (-psi2 * n))^(1/3))
}

// ------------------------------------------------------------- dispatcher ---
real colvector ce_cdf(real colvector x, string scalar cdf, string scalar ties)
{
    real scalar n, mx
    real colvector u

    n = rows(x)

    if (cdf == "rank.n") {              // Qian, Koschmann & Xie (2025), Eq. 9
        u  = ce_rank(x, ties) / n
        mx = max(x)
        return(u :* (x :!= mx) + J(n,1,n/(n+1)) :* (x :== mx))
    }
    if (cdf == "rank.n1")               // BMW (2024), Eq. 2.3
        return(ce_rank(x, ties) / (n + 1))
    if (cdf == "ecdf.fixed") {          // Becker, Proksch & Ringle (2022)
        u = ce_rank(x, ties) / n
        u = u :* (u :< 1) + J(n,1,1-1e-7) :* (u :>= 1)
        return(u :* (u :> 0) + J(n,1,1e-7) :* (u :<= 0))
    }
    if (cdf == "ecdf.adj")              // Liengaard et al. (2025), Eq. 9
        return(1/(2*n) :+ (n-1)/n^2 :* ce_rank(x, ties))
    if (cdf == "kde.silverman")         // Park & Gupta (2012), Eq. 3
        return(ce_cdf_epan(x, ce_bw_silverman(x)))
    if (cdf == "kde.plugin")            // Polansky & Baker (2000)
        return(ce_cdf_gauss(x, ce_bw_plugin(x)))

    _error("unknown cdf")
    return(J(0,1,.))
}

// C(x) = Phi^-1(Fhat(x))
real colvector ce_ctrans(real colvector x, string scalar cdf, string scalar ties)
{
    real colvector c
    c = invnormal(ce_cdf(x, cdf, ties))
    if (hasmissing(c))
        _error("the copula transformation produced non-finite values: the " +
               "estimated CDF hit 0 or 1. Try a different cdf().")
    return(c)
}

real matrix ce_ctrans_m(real matrix M, string scalar cdf, string scalar ties)
{
    real scalar j
    real matrix out
    out = J(rows(M), cols(M), .)
    for (j = 1; j <= cols(M); j++) out[., j] = ce_ctrans(M[., j], cdf, ties)
    return(out)
}

// ------------------------------------------------------------------- OLS ---
real colvector ce_ols(real matrix A, real colvector y)
{
    return(invsym(quadcross(A, A)) * quadcross(A, y))
}

real colvector ce_resid(real matrix D, real colvector v)
{
    return(v - D * ce_ols(D, v))
}

real scalar ce_corr(real colvector a, real colvector b)
{
    real scalar n, ma, mb, sa, sb
    n  = rows(a)
    ma = sum(a)/n; mb = sum(b)/n
    sa = sqrt(sum((a:-ma):^2)); sb = sqrt(sum((b:-mb):^2))
    if (sa == 0 | sb == 0) return(.)
    return(sum((a:-ma) :* (b:-mb)) / (sa * sb))
}

// -------------------------------------------------- copula control functions
// C      the terms entering the regression
// Cstar  the plain copula data Phi^-1(Fhat(P)), used for rho = corr(xi, P*)
// resid1 first-stage residuals (BMW)
// For Park & Gupta, C and Cstar coincide.
struct ce_terms {
    real matrix C, Cstar, resid1
    string colvector names
}

struct ce_terms scalar ce_build(real matrix P, real matrix W,
                                real colvector cell, real scalar ncells,
                                real rowvector fskeep, real rowvector jcont,
                                string scalar method, string scalar cdf,
                                string scalar ties, string colvector enames)
{
    struct ce_terms scalar t
    real scalar n, dP, k, j, jj, col
    real matrix Wf, Wj, D, Ws, M, S, Si, Ck, cp, cw
    real colvector r, sel

    n  = rows(P)
    dP = cols(P)
    Wf = (cols(W) > 0 & length(fskeep) > 0) ? W[., fskeep] : J(n, 0, .)
    Wj = (cols(W) > 0 & length(jcont)  > 0) ? W[., jcont]  : J(n, 0, .)

    t.resid1 = J(n, 0, .)

    // ------------------------------------------------- Park & Gupta (2012) --
    // y = mu + P alpha + W beta + sum_k gamma_k Phi^-1(Fhat(P_k)) + u
    if (method == "pg") {
        t.Cstar  = ce_ctrans_m(P, cdf, ties)
        t.C      = t.Cstar
        t.names  = enames :+ "_cop"
        return(t)
    }

    // ------------------------- 2sCOPE (intercept) / IMA (no intercept) ------
    // C_k = P*_k - delta_k' W*, each P*_k regressed on W* alone
    if (method == "2scope" | method == "ima") {
        t.Cstar = ce_ctrans_m(P, cdf, ties)
        t.names = enames :+ "_cop"
        if (cols(Wf) == 0) {              // collapses to Park & Gupta
            t.C = t.Cstar
            return(t)
        }
        Ws  = ce_ctrans_m(Wf, cdf, ties)
        D   = (method == "2scope") ? (J(n,1,1), Ws) : Ws
        t.C = J(n, dP, .)
        for (k = 1; k <= dP; k++) t.C[., k] = ce_resid(D, t.Cstar[., k])
        return(t)
    }

    // ------------------------------------------------------------ BMW (2024)
    // The rank transform is applied to the first-stage residuals, not to P.
    // The first stage always carries an intercept: A4 requires E[e] = 0.
    if (method == "bmw") {
        if (cols(Wf) == 0) {
            t.resid1 = P :- (colsum(P) / n)
        }
        else {
            D = (J(n,1,1), Wf)
            t.resid1 = J(n, dP, .)
            for (k = 1; k <= dP; k++) t.resid1[., k] = ce_resid(D, P[., k])
        }
        t.C     = ce_ctrans_m(t.resid1, cdf, ties)
        t.Cstar = t.C
        t.names = enames :+ "_cop"
        return(t)
    }

    // ------------------------------------------ JAMS (Liengaard et al. 2025)
    // C(P, W) = ( C(P)' C(W)' ) Sigma^-1 [ I_dP ; 0 ] with Sigma the
    // covariance matrix -- not the correlation matrix -- of (C(P), C(W)).
    // With cells, everything is estimated inside the cell and each copula
    // column is zero outside its own cell (Equations 20 and 21).
    t.Cstar = J(n, dP, .)
    t.C     = J(n, dP * ncells, 0)
    t.names = J(dP * ncells, 1, "")
    col = 0
    for (jj = 1; jj <= ncells; jj++) {
        r = selectindex(cell :== jj)
        if (rows(r) < dP + cols(Wj) + 2)
            _error("too few observations in a category to estimate the " +
                   "copula structure separately there; name fewer variables " +
                   "in conditional() or merge categories")
        cp = ce_ctrans_m(P[r, .], cdf, ties)
        t.Cstar[r, .] = cp

        M = cp
        if (cols(Wj) > 0) {
            // a regressor constant inside a cell would make Sigma singular
            sel = J(0, 1, .)
            for (j = 1; j <= cols(Wj); j++)
                if (max(Wj[r, j]) > min(Wj[r, j])) sel = sel \ j
            if (rows(sel) > 0) {
                cw = ce_ctrans_m(Wj[r, sel], cdf, ties)
                M  = (cp, cw)
            }
        }

        S  = quadvariance(M)
        Si = invsym(S)
        if (diag0cnt(Si) > 0)
            _error("the covariance matrix of the copula data is singular in " +
                   "a category: two of the regressors are collinear there")
        Ck = M * Si[., 1::dP]
        for (k = 1; k <= dP; k++) {
            col++
            t.C[r, col] = Ck[., k]
            if (ncells == 1) t.names[col] = enames[k] + "_cop"
            else             t.names[col] = enames[k] + "_cop" + strofreal(jj)
        }
    }
    return(t)
}

// ------------------------------------------------------------ diagnostics ---
// Anderson-Darling test for composite normality (D'Agostino & Stephens 1986)
real rowvector ce_ad(real colvector x)
{
    real scalar n, i, A, AA, pv, m, s
    real colvector xs, p, h

    xs = sort(x, 1)
    n  = rows(xs)
    if (n < 8) return((., .))
    m = sum(xs)/n
    s = ce_sd(xs)
    p = normal((xs :- m) / s)
    p = rowmax((J(n,1,1e-15), rowmin((J(n,1,1-1e-15), p))))
    h = J(n, 1, 0)
    for (i = 1; i <= n; i++)
        h[i] = (2*i - 1) * (ln(p[i]) + ln(1 - p[n-i+1]))
    A  = -n - sum(h)/n
    AA = A * (1 + 0.75/n + 2.25/n^2)
    if      (AA < 0.2)  pv = 1 - exp(-13.436 + 101.14*AA - 223.73*AA^2)
    else if (AA < 0.34) pv = 1 - exp(-8.318 + 42.796*AA - 59.938*AA^2)
    else if (AA < 0.6)  pv = exp(0.9177 - 4.279*AA - 1.38*AA^2)
    else if (AA < 10)   pv = exp(1.2937 - 5.709*AA + 0.0186*AA^2)
    else                pv = 3.7e-24
    return((A, pv))
}

// Cramer-von Mises test for composite normality (Stephens 1986)
real rowvector ce_cvm(real colvector x)
{
    real scalar n, i, W, WW, pv, m, s
    real colvector xs, p

    xs = sort(x, 1)
    n  = rows(xs)
    if (n < 8) return((., .))
    m = sum(xs)/n
    s = ce_sd(xs)
    p = normal((xs :- m) / s)
    W = 1/(12*n)
    for (i = 1; i <= n; i++) W = W + (p[i] - (2*i - 1)/(2*n))^2
    WW = W * (1 + 0.5/n)
    if      (WW < 0.0275) pv = 1 - exp(-13.953 + 775.5*WW - 12542.61*WW^2)
    else if (WW < 0.051)  pv = 1 - exp(-5.903 + 179.546*WW - 1515.29*WW^2)
    else if (WW < 0.092)  pv = exp(0.886 - 31.62*WW + 10.897*WW^2)
    else if (WW < 1.1)    pv = exp(1.111 - 34.242*WW + 12.832*WW^2)
    else                  pv = 7.37e-10
    return((W, pv))
}

// Kolmogorov-Smirnov against a fitted normal, with the asymptotic p value
real scalar ce_ksp(real colvector x)
{
    real scalar n, i, D, m, s, t, lam, j, S
    real colvector xs, F

    xs = sort(x, 1)
    n  = rows(xs)
    m  = sum(xs)/n
    s  = ce_sd(xs)
    F  = normal((xs :- m)/s)
    D  = 0
    for (i = 1; i <= n; i++) {
        t = max((abs(F[i] - i/n), abs(F[i] - (i-1)/n)))
        if (t > D) D = t
    }
    lam = (sqrt(n) + 0.12 + 0.11/sqrt(n)) * D
    S = 0
    for (j = 1; j <= 100; j++) S = S + (-1)^(j-1) * exp(-2 * j^2 * lam^2)
    return(max((0, min((1, 2*S)))))
}

real scalar ce_skew(real colvector x)
{
    real scalar n, m
    n = rows(x); m = sum(x)/n
    return((sum((x:-m):^3)/n) / (sum((x:-m):^2)/n)^1.5)
}

real scalar ce_kurt(real colvector x)
{
    real scalar n, m
    n = rows(x); m = sum(x)/n
    return((sum((x:-m):^4)/n) / (sum((x:-m):^2)/n)^2 - 3)
}

// Becker, Proksch & Ringle (2022, Fig. 8) boundary conditions, 80% power
real rowvector ce_becker(real scalar n)
{
    real scalar sk
    if      (n <=  200) sk = .
    else if (n <= 1000) sk = 1.932
    else if (n <= 2000) sk = 0.774
    else                sk = 0
    return((sk, 18.964, 3.488))
}

// Holm step-down adjustment
real colvector ce_holm(real colvector p)
{
    real scalar n, i, run
    real colvector o, ps, adj, out
    n   = rows(p)
    o   = order(p, 1)
    ps  = p[o]
    adj = J(n, 1, .)
    run = 0
    for (i = 1; i <= n; i++) {
        run = max((run, (n - i + 1) * ps[i]))
        adj[i] = min((run, 1))
    }
    out = J(n, 1, .)
    out[o] = adj
    return(out)
}

// ===========================================================================
//  driver
// ===========================================================================
void ce_main(string scalar depvar, string scalar endog, string scalar wvars,
             string scalar cellv,  string scalar touse,
             string scalar method, string scalar cdf, string scalar ties,
             real scalar nboots,   real scalar hascons,
             string scalar fskeeps, string scalar jconts, real scalar ncells,
             real scalar savec)
{
    struct ce_terms scalar t, tb
    real colvector y, cell, cellb, xi, resid_a, rho, rhose, iconv, se, seols
    real colvector cf, cfb, olsb, b, sel, pv, ra5, ctt
    real matrix P, W, X, A, Ab, Xb, Pb, Wb, B, V, Vc, D
    real matrix dg, a5, dhw
    real scalar n, dP, dW, kx, kA, i, k, j, a, ok, fail, nrep
    real scalar ss, r2, r2s, rmse, rmses, s2, F, r2j, pj
    real rowvector fskeep, jcont, th, ad, cvm
    string colvector enames
    string scalar lab

    y    = st_data(., depvar, touse)
    P    = st_data(., endog,  touse)
    W    = (wvars != "") ? st_data(., wvars, touse) : J(rows(y), 0, .)
    cell = st_data(., cellv, touse)
    n    = rows(y)
    dP   = cols(P)
    dW   = cols(W)

    enames = tokens(endog)'
    fskeep = (fskeeps != "") ? strtoreal(tokens(fskeeps)) : J(1, 0, .)
    jcont  = (jconts  != "") ? strtoreal(tokens(jconts))  : J(1, 0, .)

    // design matrix: endogenous, exogenous, constant last (Stata convention)
    X = P
    if (dW > 0) X = X, W
    if (hascons) X = X, J(n, 1, 1)
    kx = cols(X)

    if (n <= kx + dP)
        _error("not enough complete observations for the number of regressors")

    // -------------------------------------------------------- point estimate
    t  = ce_build(P, W, cell, ncells, fskeep, jcont, method, cdf, ties, enames)
    A  = X, t.C
    kA = cols(A)
    if (rank(A) < kA) {
        if (rank(X) < cols(X))
            _error("the design matrix is rank deficient before any copula " +
                   "term is added: the regressors themselves are collinear")
        _error("the copula terms are perfectly collinear with the regressors, " +
               "so the model is not identified. That is what happens when an " +
               "endogenous regressor is normally distributed: its copula " +
               "transform is then a linear function of itself")
    }

    cf      = ce_ols(A, y)
    resid_a = y - A * cf
    xi      = y - X * cf[1::kx]

    rho = J(dP, 1, .)
    for (k = 1; k <= dP; k++) rho[k] = ce_corr(xi, t.Cstar[., k])

    // classical OLS covariance of the augmented regression.  Wrong for the
    // structural coefficients -- the copula terms are generated regressors --
    // but BMW (2024, Corollary 3.2) show the textbook t statistic stays valid
    // for testing rho = 0.
    s2 = quadcross(resid_a, resid_a) / (n - kA)
    Vc = s2 * invsym(quadcross(A, A))

    // ------------------------------------------------------------- bootstrap
    // Plain pairs bootstrap: draw row indices with replacement, recompute the
    // copula terms on the resample, refit.  This is the procedure used in every
    // one of the underlying papers.  Degenerate draws are rejected and redrawn.
    B    = J(0, kA + dP + kx, .)
    fail = 0
    for (i = 1; i <= nboots; i++) {
        ok = 0
        for (a = 1; a <= 200; a++) {
            sel   = ceil(runiform(n, 1) * n)
            Xb    = X[sel, .]
            Pb    = P[sel, .]
            Wb    = (dW > 0) ? W[sel, .] : J(n, 0, .)
            cellb = cell[sel]

            if (ncells > 1) {
                j = 1
                for (k = 1; k <= ncells; k++)
                    if (sum(cellb :== k) < dP + dW + 2) j = 0
                if (j == 0) continue
            }
            if (rank(Xb) < cols(Xb)) continue

            tb = ce_build(Pb, Wb, cellb, ncells, fskeep, jcont, method, cdf,
                          ties, enames)
            Ab = Xb, tb.C
            if (rank(Ab) < cols(Ab)) continue

            cfb  = ce_ols(Ab, y[sel])
            olsb = ce_ols(Xb, y[sel])
            b    = cfb
            for (k = 1; k <= dP; k++)
                b = b \ ce_corr(y[sel] - Xb * cfb[1::kx], tb.Cstar[., k])
            b = b \ olsb
            if (hasmissing(b)) continue
            B  = B \ b'
            ok = 1
            break
        }
        if (!ok) fail++
    }
    nrep = rows(B)
    if (nrep < 2)
        _error("every bootstrap resample was degenerate; a factor level or a " +
               "cell of the discrete regressors is probably too rare")
    if (fail > 0)
        printf("{txt}note: %f of %f bootstrap replicates could not be computed and were dropped.\n",
               fail, nboots)

    V     = quadvariance(B[., 1::kA])
    se    = sqrt(diagonal(V))
    rhose = sqrt(diagonal(quadvariance(B[., (kA+1)::(kA+dP)])))
    seols = sqrt(diagonal(quadvariance(B[., (kA+dP+1)::cols(B)])))

    // ICON (Qian, Koschmann & Xie 2025, Boundary Condition 1): the inflation of
    // the standard errors caused by adding the copula terms.  Above 6 flags
    // weak identification or a misspecified dependence model.
    iconv = se[1::kx] :/ seols

    // ------------------------------------------------------------- fit stats
    ss    = hascons ? sum((y :- sum(y)/n):^2) : sum(y:^2)
    r2    = 1 - quadcross(resid_a, resid_a) / ss
    r2s   = 1 - quadcross(xi, xi) / ss
    rmse  = sqrt(quadcross(resid_a, resid_a) / (n - kA))
    rmses = sqrt(quadcross(xi, xi) / (n - kA))

    // ----------------------------------------------------------- diagnostics
    // Non-normality of whatever identifies the model: the endogenous regressor,
    // or for BMW the first-stage residuals (their Theorem 2.1).
    dg = J(7, dP, .)
    th = ce_becker(n)
    for (k = 1; k <= dP; k++) {
        if (method == "bmw" & cols(t.resid1) > 0) sel = t.resid1[., k]
        else                                      sel = P[., k]
        ad  = ce_ad(sel)
        cvm = ce_cvm(sel)
        dg[1, k] = ce_skew(sel)
        dg[2, k] = ce_kurt(sel)
        dg[3, k] = ad[1]
        dg[4, k] = cvm[1]
        dg[5, k] = ce_ksp(sel)
        dg[6, k] = (dg[5, k] < 0.05)
        dg[7, k] = ((abs(dg[1,k]) >= th[1]) | (dg[3,k] > th[2]) | (dg[4,k] > th[3]))
    }

    // Assumption 5 of Park & Gupta: corr(W, copula term) = 0.  Reported are the
    // Holm-adjusted single correlations and a joint test, which is what the
    // assumption is actually about.
    if (method == "pg" & dW > 0) {
        ra5 = J(dW, 1, .)
        pv  = J(dW, 1, .)
        cfb = ce_ols((X, t.Cstar), y)
        ctt = t.Cstar * cfb[(kx+1)::(kx+dP)]
        for (j = 1; j <= dW; j++) {
            ra5[j] = ce_corr(W[., j], ctt)
            pv[j]  = 2 * normal(-abs(atanh(ra5[j]) * sqrt(n - 3)))
        }
        a5  = (ra5, ce_holm(pv))'
        sel = ce_resid((J(n,1,1), W), ctt)
        r2j = 1 - quadcross(sel, sel) / sum((ctt :- sum(ctt)/n):^2)
        F   = (r2j / dW) / ((1 - r2j) / (n - dW - 1))
        pj  = Ftail(dW, n - dW - 1, F)
        st_matrix("a5_ce", a5)
        st_local("e_a5r2", strofreal(r2j))
        st_local("e_a5F",  strofreal(F))
        st_local("e_a5p",  strofreal(pj))
    }

    // --------------------------------------------------------------- return
    st_matrix("b_ce",     cf')
    st_matrix("V_ce",     V)
    st_matrix("rho_ce",   rho')
    st_matrix("rhose_ce", rhose')
    st_matrix("icon_ce",  (iconv, se[1::kx])')
    st_matrix("bols_ce",  ce_ols(X, y)')
    st_matrix("seols_ce", seols')
    st_matrix("diag_ce",  dg)
    if (method == "bmw") {
        dhw = (cf[(kx+1)::kA], sqrt(diagonal(Vc)[(kx+1)::kA]))'
        st_matrix("dhw_ce", dhw)
    }

    if (savec) {
        for (k = 1; k <= rows(t.names); k++) {
            if (strlen(t.names[k]) > 32)
                _error("generate(): the copula term name " + t.names[k] +
                       " is too long for a Stata variable")
            if (_st_varindex(t.names[k]) != .)
                _error("generate(): the variable " + t.names[k] +
                       " already exists")
        }
        st_store(., st_addvar("double", t.names'), touse, t.C)
    }

    st_local("copnames",    invtokens(t.names'))
    st_local("nboots_used", strofreal(nrep))
    st_local("e_nobs",      strofreal(n))
    st_local("e_dfr",       strofreal(n - kA))
    st_local("e_rmse",      strofreal(rmse))
    st_local("e_r2",        strofreal(r2))
    st_local("e_r2a",       strofreal(1 - (1 - r2) * (n - hascons) / (n - kA)))
    st_local("e_rmse_s",    strofreal(rmses))
    st_local("e_r2_s",      strofreal(r2s))
    st_local("e_iconmax",   strofreal(max(iconv)))

    ad = ce_ad(xi)
    st_local("e_xiskew", strofreal(ce_skew(xi)))
    st_local("e_xikurt", strofreal(ce_kurt(xi)))
    st_local("e_xiad",   strofreal(ad[1]))
    st_local("e_xiksp",  strofreal(ce_ksp(xi)))
    st_local("e_thskew", strofreal(th[1]))
    st_local("e_thad",   strofreal(th[2]))
    st_local("e_thcvm",  strofreal(th[3]))

    if      (method == "pg")     lab = "PG (Park & Gupta 2012)"
    else if (method == "2scope") lab = "2sCOPE (Yang, Qian & Xie 2025)"
    else if (method == "ima")    lab = "IMA (Haschka 2025a)"
    else if (method == "bmw")    lab = "BMW (Breitung, Mayer & Wied 2024)"
    else                         lab = "JAMS (Liengaard et al. 2025)"
    st_local("methodlab", lab)
    st_local("nonnormof", (method == "bmw") ? "first-stage residuals"
                                            : "endogenous regressors")
}

end
