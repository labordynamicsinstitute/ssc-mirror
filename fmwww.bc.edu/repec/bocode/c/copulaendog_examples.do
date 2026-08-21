*! =============================================================================
*!  EXAMPLES.DO
*!
*!  The full reference: every option of every estimator spelled out, defaults
*!  included.  For the short tour, see QUICKSTART.DO.
*!
*!  Download this one file and run it.  It fetches the command straight from
*!  the repository into a temporary directory, so there is nothing else to
*!  download and no working directory to set.
*! =============================================================================
*!
*!  Ported from the R reference implementation
*!    Haschka, R. E. (2026). Copula-based endogeneity corrections in R.
*!    https://github.com/HashtagHaschka/Copula-based-endogeneity-corrections
*!  and from endogCopula by Ashwin Malshe,
*!    https://github.com/ashgreat/endogCopula
*!
*!  GPL-3 or later, with the additional attribution term stated in LICENSE.

clear all
set more off

* -----------------------------------------------------------------------------
*  Fetch the command
* -----------------------------------------------------------------------------
local gh "https://raw.githubusercontent.com/girishm77/copulaendog_stata_python/main/stata"

capture confirm file "copulaendog.ado"
if !_rc {
    adopath ++ "`c(pwd)'"
}
else {
    local dir "`c(tmpdir)'/copulaendog"
    capture mkdir "`dir'"
    local failed = 0
    foreach f in copulaendog.ado copulaendog_p.ado copulaendog.sthlp {
        capture copy "`gh'/`f'" "`dir'/`f'", replace
        if _rc local failed = 1
    }
    if `failed' {
        di as err "Could not download the command from `gh'."
        exit 601
    }
    adopath ++ "`dir'"
}

which copulaendog


* =============================================================================
*  DATASET 1.  Simulated, so the truth is known
* =============================================================================
*      (xi, v) ~ bivariate normal, corr 0.6
*      P       = exp(0.8*v + 0.6*w),   y = 1 + 2*P + 1.5*x - 0.5*w + xi
*  True coefficient on P is 2.  corr(W, P*) is nonzero by construction, so the
*  Park & Gupta uncorrelatedness assumption fails.

set seed 90210
quietly {
    set obs 2000
    generate double w  = rnormal()
    generate double x  = rnormal()
    generate double v  = rnormal()
    generate double xi = 0.6*v + sqrt(1 - 0.6^2)*rnormal()
    generate double P  = exp(0.8*v + 0.6*w)
    generate double y  = 1 + 2*P + 1.5*x - 0.5*w + xi

    * a second endogenous regressor, and two categorical controls
    generate double v2 = rnormal()
    generate double P2 = exp(0.5*v2 + 0.3*w)
    replace  y = y + 0.8*P2 + 0.5*(0.4*v2 + sqrt(1 - 0.4^2)*rnormal())
    generate byte store  = 1 + int(3*runiform())
    generate byte promo  = runiform() < 0.4
    replace  y = y + 0.4*store + 0.2*promo
}


* =============================================================================
*  1.  THE FIVE ESTIMATORS, every argument spelled out at its default
* =============================================================================
*  Syntax:
*      copulaendog depvar endogvars [if] [in] , [options]
*
*  Position decides.  Variables after depvar are endogenous and each gets its
*  own copula term; everything in exog() is exogenous and gets none.

* --- Park & Gupta (2012) -----------------------------------------------------
*  Adds Phi^-1(Fhat(P)) directly.  Assumes corr(W, P*) = 0.
di as txt _n "{hline 78}" _n "1.1  method(pg), all defaults written out" _n "{hline 78}"
copulaendog y P,            ///
    exog(x w)               ///
    method(pg)              ///
    cdf(kde.silverman)      /// the default for pg: Park & Gupta (2012), Eq. 3
    ties(max)               /// the default
    nboots(199)             /// the default
    seed(1)                 /// no seed is set unless you set one
    level(95)                  // the default

* --- 2sCOPE (Yang, Qian & Xie 2025) ------------------------------------------
*  Transforms W too, regresses each P* on W*, uses the residual.  First stage
*  carries an intercept.
di as txt _n "{hline 78}" _n "1.2  method(2scope)" _n "{hline 78}"
copulaendog y P, exog(x w) method(2scope) cdf(rank.n) ties(max) nboots(199) seed(1)

* --- IMA (Haschka 2025a) -----------------------------------------------------
*  The same without an intercept in the first stage, which is what the paper's
*  derivation of rho requires.
di as txt _n "{hline 78}" _n "1.3  method(ima)" _n "{hline 78}"
copulaendog y P, exog(x w) method(ima) cdf(rank.n) ties(max) nboots(199) seed(1)

* --- BMW (Breitung, Mayer & Wied 2024) ---------------------------------------
*  Residualise first, then rank-transform the residual.  Reports a
*  Durbin-Hausman-Wu test alongside the bootstrap one (their Corollary 3.2).
di as txt _n "{hline 78}" _n "1.4  method(bmw)" _n "{hline 78}"
copulaendog y P, exog(x w) method(bmw) cdf(rank.n1) ties(max) nboots(199) seed(1)

* --- JAMS (Liengaard et al. 2025) --------------------------------------------
di as txt _n "{hline 78}" _n "1.5  method(jams), one common structure" _n "{hline 78}"
copulaendog y P, exog(x w) method(jams) cdf(ecdf.adj) ties(max) nboots(199) seed(1)


* =============================================================================
*  2.  cdf() -- how the marginal CDF is estimated
* =============================================================================
*  The literature disagrees, so every proposal is implemented and the choice is
*  free -- except in BMW, whose Proposition 3.1 is derived for rank.n1 and
*  which therefore warns if you ask for anything else.
*
*    kde.silverman  integrated Epanechnikov density, Silverman bandwidth
*                     Park & Gupta (2012)                    [default for pg]
*    kde.plugin     Gaussian kernel CDF, plug-in bandwidth
*                     Polansky & Baker (2000)
*    ecdf.fixed     ECDF with replaced boundary
*                     Becker, Proksch & Ringle (2022)
*    ecdf.adj       adjusted ECDF
*                     Liengaard et al. (2025)                [default for jams]
*    rank.n         rank/n with a top correction
*                     Qian, Koschmann & Xie (2025)   [default for 2scope, ima]
*    rank.n1        rank/(n+1)
*                     Breitung, Mayer & Wied (2024)          [default for bmw]
*
*  kde.cv, the cross-validated bandwidth of Li, Li & Racine (2017), is
*  available in the Python version only; the Stata command rejects it rather
*  than silently substituting another.
*
*  Underscores are accepted in place of dots: cdf(kde_plugin) works too.

di as txt _n "{hline 78}" _n "2.  every cdf() in turn, coefficient on P" _n "{hline 78}"
foreach c in kde.silverman kde.plugin ecdf.fixed ecdf.adj rank.n rank.n1 {
    quietly copulaendog y P, exog(x w) method(pg) cdf(`c') nboots(49) seed(1)
    di as txt %-16s "`c'" as res %9.4f _b[P] as txt "  (se " as res %6.4f _se[P] as txt ")"
}

* --- ties() ------------------------------------------------------------------
*  max      reproduces F(x) = (1/n) sum I(P_i <= x) literally, which is how
*           every one of the papers writes it                       [default]
*  average  midranks, the convention of the wider copula literature
*
*  Two things have to hold before the choice can matter at all: the CDF has to
*  be a rank-based one, and the variable has to have tied values.  The
*  kernel estimators never look at ranks, so under the pg default of
*  kde.silverman ties() does nothing whatever you pass it.  Rounding P coarsely
*  and asking for rank.n1 makes the difference visible.
di as txt _n "2b.  ties(), with a rank-based cdf and a variable that has ties"
quietly generate double Pr = round(P, 0.5)
quietly count if Pr == Pr[_n-1]
di as txt "  Pr has " as res r(N) as txt " repeated values out of " as res _N

foreach t in max average {
    quietly copulaendog y Pr, exog(x w) method(pg) cdf(rank.n1) ties(`t') ///
        nboots(49) seed(1)
    di as txt "  cdf(rank.n1) ties(" %-7s "`t')" as txt " b = " ///
       as res %9.4f _b[Pr]
}
foreach t in max average {
    quietly copulaendog y Pr, exog(x w) method(pg) cdf(kde.silverman) ///
        ties(`t') nboots(49) seed(1)
    di as txt "  kde.silverman ties(" %-7s "`t')" as txt " b = " ///
       as res %9.4f _b[Pr] as txt "   <- unaffected, as it should be"
}


* =============================================================================
*  3.  validity -- the identification checks
* =============================================================================
*  [1] non-normality of P, on both the Yang (KS p < .05) and the Becker
*      (skewness / AD / CvM, sample-size dependent) criteria.  For bmw the
*      requirement falls on the first-stage residuals instead, and the report
*      says so.
*  [2] the uncorrelatedness assumption -- printed only for pg, since the other
*      estimators project that correlation out in their first stage.
*  [4] the shape of the structural error.
*  [5] ICON, the standard error inflation relative to uncorrected OLS.  Above
*      6 flags weak identification or a misspecified dependence model.

di as txt _n "{hline 78}" _n "3.1  validity after pg: the assumption should fail here" _n "{hline 78}"
copulaendog y P, exog(x w) method(pg) nboots(199) seed(1) validity

di as txt _n "{hline 78}" _n "3.2  validity after bmw: note it tests the first-stage residuals" _n "{hline 78}"
copulaendog y P, exog(x w) method(bmw) nboots(199) seed(1) validity

*  validity also works as a replay, without refitting
di as txt _n "3.3  replay: the same report without re-running the bootstrap"
copulaendog, validity


* =============================================================================
*  4.  Two endogenous regressors
* =============================================================================
*  Each gets its own copula term and its own rho.  Each P*_k is regressed on
*  W* alone in the first stage, never on the other endogenous regressor.

di as txt _n "{hline 78}" _n "4.  two endogenous regressors" _n "{hline 78}"
copulaendog y P P2, exog(x w) method(2scope) nboots(199) seed(1)


* =============================================================================
*  5.  Factor variables and interactions in exog()
* =============================================================================
*  exog() takes factor-variable notation.  Endogenous regressors may not: a
*  factor expands into several columns and has no single copula term, so
*  categorical controls belong in exog().

di as txt _n "{hline 78}" _n "5.1  i.store in exog()" _n "{hline 78}"
copulaendog y P, exog(x w i.store) method(2scope) nboots(199) seed(1)

di as txt _n "{hline 78}" _n "5.2  an interaction among the controls" _n "{hline 78}"
copulaendog y P, exog(x w c.x#c.w) method(pg) nboots(199) seed(1)

di as txt _n "{hline 78}" _n "5.3  a factor interaction" _n "{hline 78}"
copulaendog y P, exog(x w i.store#i.promo) method(pg) nboots(99) seed(1)


* =============================================================================
*  6.  JAMS: conditional() and discrete()
* =============================================================================
*  conditional(varlist)  the copula structure is estimated separately within
*                        each joint category of the named variables
*                        (Equations 20 and 21).  Two binary variables give four
*                        cells, not two.  Each copula column is zero outside
*                        its own cell.  Left empty, one common structure is
*                        estimated instead (Equation 18).
*  discrete(varlist)     exogenous regressors to treat as discrete and keep out
*                        of the copula terms: W in Equation 17 is the
*                        continuous exogenous vector.  Indicators produced from
*                        factor variables are detected and excluded already.

di as txt _n "{hline 78}" _n "6.1  structure varying over store" _n "{hline 78}"
copulaendog y P, exog(x w i.store) method(jams) conditional(store) ///
    nboots(199) seed(1)

di as txt _n "{hline 78}" _n "6.2  over the joint categories of store and promo" _n "{hline 78}"
copulaendog y P, exog(x w i.store i.promo) method(jams) ///
    conditional(store promo) nboots(199) seed(1)

di as txt _n "{hline 78}" _n "6.3  one common structure" _n "{hline 78}"
copulaendog y P, exog(x w i.store) method(jams) nboots(199) seed(1)


* =============================================================================
*  7.  fsexclude() -- holding a regressor out of the first stage
* =============================================================================
*  Everything in exog() enters both the structural model and the first stage.
*  A term built from an endogenous variable is not exogenous information,
*  whichever list it was written in, so name it here to keep it out of the
*  first stage while leaving it in the model.

quietly generate double Pw = P*w
di as txt _n "{hline 78}" _n "7.  P*w kept out of the first stage" _n "{hline 78}"
copulaendog y P, exog(x w Pw) method(2scope) fsexclude(Pw) nboots(99) seed(1)


* =============================================================================
*  8.  generate() and predict
* =============================================================================
*  The copula terms are endogeneity controls, not part of the causal model, so
*  they never enter the default prediction.
*
*    predict newvar              structural linear prediction        [default]
*    predict newvar, residuals   structural residual xi = y - xb
*    predict newvar, xba         augmented prediction xb + C*gamma
*    predict newvar, resida      augmented residual u
*
*  xba and resida need the copula terms in the data, which is what generate()
*  leaves behind.

di as txt _n "{hline 78}" _n "8.  generate() and the four predict statistics" _n "{hline 78}"
capture drop P_cop
copulaendog y P, exog(x w) method(pg) nboots(99) seed(1) generate(cop)
predict double xb_s
predict double xi_s,  residuals
predict double xb_a,  xba
predict double u_a,   resida
summarize P_cop xb_s xi_s xb_a u_a
capture drop P_cop xb_s xi_s xb_a u_a


* =============================================================================
*  9.  noconstant, if/in, level()
* =============================================================================
di as txt _n "{hline 78}" _n "9.1  noconstant" _n "{hline 78}"
copulaendog y P, exog(x w) method(pg) nboots(99) seed(1) noconstant

di as txt _n "{hline 78}" _n "9.2  a subsample, and a 90% interval" _n "{hline 78}"
copulaendog y P if store != 3, exog(x w) method(2scope) nboots(99) seed(1) level(90)

di as txt _n "9.3  replay at a different level, without refitting"
copulaendog, level(99)


* =============================================================================
*  10.  What is left behind in e()
* =============================================================================
di as txt _n "{hline 78}" _n "10.  stored results" _n "{hline 78}"
quietly copulaendog y P, exog(x w) method(pg) nboots(199) seed(1)
ereturn list

di as txt _n "the endogeneity measure and its bootstrap standard error:"
matrix list e(rho)
matrix list e(rho_se)

di as txt _n "uncorrected OLS on the same resamples, and the resulting ICON:"
matrix list e(b_ols)
matrix list e(icon)

di as txt _n "the diagnostics behind the validity report:"
matrix list e(diagnostics)


* =============================================================================
*  DATASET 2.  A real one: auto.dta
* =============================================================================
*  Treat price as endogenous with respect to mileage.  Nothing here is a causal
*  claim; the point is that the command runs on data you already have, and that
*  validity tells you whether the correction is identified on it.
*
*  It should report that price is non-normal enough to work with -- it is
*  strongly right-skewed -- while the small sample size (74) puts it below
*  every Becker, Proksch & Ringle boundary, which is exactly the sort of thing
*  the report exists to say out loud.

sysuse auto, clear

di as txt _n "{hline 78}" _n "auto.dta: mpg on price, price treated as endogenous" _n "{hline 78}"
copulaendog mpg price, exog(weight length) method(2scope) nboots(199) seed(1) ///
    validity

di as txt _n "{hline 78}" _n "auto.dta: with a factor control, JAMS over foreign" _n "{hline 78}"
copulaendog mpg price, exog(weight i.foreign) method(jams) conditional(foreign) ///
    nboots(199) seed(1)


* =============================================================================
di as txt _n "{hline 78}"
di as txt "Done.  help copulaendog for the full syntax."
di as txt "{hline 78}"
