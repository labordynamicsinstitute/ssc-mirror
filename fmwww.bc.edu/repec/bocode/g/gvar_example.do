*! gvar_example.do  1.0.0  07aug2026
*! A complete worked GVAR session on real data.
*!
*! Reproduces the GVAR Toolbox's own 26-unit demo: 33 countries with the euro
*! area aggregated from its eight members, quarterly 1979Q2-2013Q1, six
*! domestic variables and three commodity prices.  Everything here runs on
*! data shipped with the package.
*!
*! Dr Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane

version 14.0
clear all
set more off

* ---------------------------------------------------------------------------
* Locate the four shipped datasets, wherever they were installed.
* ---------------------------------------------------------------------------
* This file used to open them by bare name, which works only when Stata's
* working directory happens to BE the package directory.  It appeared to work
* for exactly that reason -- an earlier do-file had left the directory set --
* and then failed with r(601) in a fresh session.
*
* findfile searches the adopath, so it resolves them after -ssc install gvar-
* (where they land in PLUS) and equally in a development tree.  It is the idiom
* the package already uses for its critical-value table at
* _gvar_coint.ado:45.  Nothing below depends on the working directory.
foreach f in gvar_demo26 gvar_demospec gvar_flows gvar_demoagg {
    capture findfile `f'.dta
    if (_rc) {
        di as err "cannot find {bf:`f'.dta} on the adopath."
        di as err "It ships with the package.  If you are running from a"
        di as err "source tree rather than an installed copy, either {bf:cd}"
        di as err "into that directory or put it on the adopath:"
        di as err ""
        * Compound double quotes.  A backslash is NOT an escape character in
        * Stata, so "\"...\"" ends the string at the second quote and the rest
        * is parsed as arguments -- which is how this line first failed, with
        * r(198) invalid name instead of the message it was meant to print.
        di as err `"    {bf:adopath + "C:/Users/HP/Documents/xtpmg/GVAR/gvar"}"'
        di as err ""
        di as err "The current directory is on the adopath, so {bf:cd} alone"
        di as err "is enough."
        exit 601
    }
    * compound double quotes, matching _gvar_coint.ado:52 -- a path that itself
    * contains a quote character would otherwise truncate the local
    local `f' `"`r(fn)'"'
}

* ===========================================================================
* 1.  DECLARE THE MODEL
* ===========================================================================
* The specification grid fixes, per unit: which variables are endogenous,
* which have foreign counterparts, the lag orders, the deterministic case and
* the cointegrating rank.  Without it the ranks and lags would come from
* gvar coint and gvar lags, which will not reproduce a published model
* exactly.  See  help gvar_setup.

use "`gvar_demo26'", clear

* The three commodity prices are GLOBAL and get their own dominant-unit block.
* They are weakly exogenous for all 26 countries, and a separate multivariate
* model determines them with feedback from the world economy.
*
* This is the demo's own specification, and using gendog() here instead was a
* real error, caught by comparing against the Toolbox's published output:
* ECMS_VARX shows the usa block with FIVE equations (dy dDp deq dr dlr) and
* poil_1 only as a regressor, while gendog() gave usa eight equations and hence
* a logL of 3248.84 against the published 2758.26.  With dominant() all 26
* country models reproduce the reference to 2.3e-12.  See _test59.do.
gvar setup y Dp eq ep r lr, unit(country) time(quarter)     ///
    global(poil pmat pmetal)                                ///
    dominant(poil pmat pmetal)                              ///
    spec("`gvar_demospec'")

* Read the report above before going on.  A blank where you expected a
* variable usually means a name did not match, not that the unit lacks the
* series.  The USA carries no exchange rate because it is the numeraire.  The
* three commodity prices belong to the dominant unit, not to the USA -- under
* gendog() they would be USA-endogenous instead, which is the DdPS device and
* NOT what this file does.

* ===========================================================================
* 2.  THE LINK WEIGHTS
* ===========================================================================
* Trade flows averaged over 2009-2011, as in the Toolbox demo.  map() is
* mandatory here: the euro area is built from eight members who appear in the
* flow data under their own names, and the aggregate does not appear at all.

gvar weights using "`gvar_flows'",                          ///
    flow(trade) source(partner) destination(home)           ///
    year(year) years(2009 2011) type(1)                     ///
    map("`gvar_demoagg'")

* A quick sanity check on the weights: the United States' largest trade
* partners should be Canada, China and Mexico.
matrix W = r(W)
matrix list W, format(%6.3f) noheader nohalf

* ===========================================================================
* 3.  FOREIGN VARIABLES AND ESTIMATION
* ===========================================================================

gvar foreign

* Reduced-rank ML of every VECMX*.  vce() sets which standard errors are
* reported; the point estimates do not depend on it.
gvar estimate, vce(nwest)

* The dominant unit needs its own model before the system can be stacked: the
* commodity prices are not any country's domestic variables, so something has to
* determine them.  Multivariate, VAR order 2 by AIC, with feedback from world
* output and inflation -- the settings on the demo's DOMINANT UNIT sheet.
gvar dominant, lags(2) flags(1) case(4) rank(1) feedback(y Dp)

* Stack and solve.  The eigenvalue check is a specification test: a GVAR with
* K variables and sum r_i cointegrating relations must have exactly
* K - sum r_i unit roots.
gvar solve

* ===========================================================================
* 4.  IS THE MODEL ANY GOOD?
* ===========================================================================
* One command that runs the checks a referee would ask for and tells you
* which detailed subcommand to read.

gvar report

* The two that matter most, in full:

* Weak exogeneity is the assumption the whole country-by-country estimation
* rests on.  DdPS report 5-10% rejection for a well-specified GVAR.
*
* select(aic) maxls(2) maxln(2) is the demo's own setting (MAIN row 55): the
* marginal model's lag orders are CHOSEN per unit rather than inherited from the
* country model.  It matters -- 19 of the 26 units end up with orders differing
* from their estimation orders, and chl gets q* = 2 where its estimation q is 1.
* Without this the F statistics are a different test from the published ones.
gvar wetest, select(aic) maxls(2) maxln(2)

* Including the foreign variables should soak up the cross-section
* dependence.  Compare the levels column with the residuals column.
gvar avgcorr, block(levels resid)

* System-wide residual diagnostics with bootstrap p-values.  Read those in
* preference to the asymptotic ones: at these dimensions the adjusted
* portmanteau is three to nine times its nominal size.
gvar diag, multivariate reps(200)

* ===========================================================================
* 5.  IMPULSE RESPONSES
* ===========================================================================
* Generalized responses need no ordering of the variables, which is why the
* GVAR literature reports them: with 136 variables no Cholesky ordering is
* defensible.

* The response of output everywhere to a one standard-error shock to the US
* short rate, with 95% bootstrap bands.  shuffle resamples whole date columns,
* which preserves the cross-section correlation of the residuals and needs no
* Cholesky factor - the right choice when K > T.
set seed 20260807
gvar irf, shock(usa:r) response(y) step(24)                 ///
    reps(200) shuffle horizons(0 1 2 4 8 12 20 24)

* The cumulated effect of an oil price shock on the major economies.
* The oil price lives in the DOMINANT unit, not in usa's block, so the shock is
* dominant:poil.  Under gendog(poil=usa) it would have been usa:poil -- the label
* follows the specification, which is one more reason not to mix the two.
* gvar describe, order prints the global vector if you are unsure.
gvar irf, shock(dominant:poil) response(usa:y euro:y china:y japan:y) ///
    step(24) cumulative horizons(0 1 2 4 8 12 24)

* An orthogonalised response needs a factorable covariance.  Sigma_zeta is
* 136 x 136 with rank 133, so it has none; shrink is the Toolbox's remedy.
gvar irf, shock(usa:r) response(usa:y usa:Dp usa:eq)        ///
    step(12) type(oirf) shrink horizons(0 1 2 4 8 12)

* A structural GIRF orthogonalises only a leading block.  Which units lead IS
* the identifying assumption; the block size follows from it.
* vorder() lists usa's OWN variables, and under dominant() that is five, not
* eight: the commodity prices are no longer in usa's block.  The eight-variable
* ordering here was correct only under gendog(poil=usa), and gvar irf refuses it
* rather than silently orthogonalising the wrong block -- worth having, because a
* Cholesky ordering that quietly loses three variables would change every number
* below without changing their plausibility.
*
* Whether usa should lead at all is now a live question.  The commodity prices
* are determined outside every country, so a case can be made for putting the
* dominant unit ahead of usa in first().  That is an identifying assumption, so
* it is stated rather than defaulted.
gvar irf, shock(usa:r) response(usa:y euro:y china:y)       ///
    step(12) type(sgirf) first(usa)                         ///
    vorder(y Dp eq r lr)                                    ///
    horizons(0 1 2 4 8 12)

* ===========================================================================
* 6.  DECOMPOSITIONS
* ===========================================================================

* What drives euro-area output?  The generalized decomposition does not sum
* to one because the shocks are correlated; the TOTAL column shows by how
* much it overshoots.
gvar fevd, variable(euro:y) step(24) top(8) horizons(0 1 4 8 24)

* Persistence profiles: every long-run relation must decay back to zero.
* One that does not is not a long-run relation, whatever the rank test said.
gvar pp, units(usa euro china japan) step(24) horizons(0 1 2 4 8 12 24)

* Connectedness, aggregated by country.  Positive NET marks a transmitter.
gvar spillover, step(24) by(unit) top(10)

* Historical decomposition needs orthogonal shocks, so it takes an ordering.
* Five variables for usa, as in the sgirf above -- see the note there.
gvar hd, variables(usa:y) shrink first(usa)                 ///
    vorder(y Dp eq r lr)                                    ///
    periods(40 80 120 134)

* ===========================================================================
* 7.  FORECASTING
* ===========================================================================
* The interest-rate floor is stated in per-annum percent and converted into
* the units the model holds rates in.

gvar forecast, step(8) variables(usa:y euro:y usa:r euro:r) rmin(0.25)

* A conditional forecast: hold the US short rate at its last observed value
* for four quarters and see what the rest of the world does.
mata:
    lab = gvar_getxcname() :+ ":" :+ gvar_getxname()
    X   = gvar_getX()
    j   = gvar_pos(lab, "usa:r")
    st_local("rlast", strofreal(X[j, cols(X)], "%18.15f"))
end
gvar forecast, step(8) variables(usa:r usa:y euro:y china:y) ///
    condition(usa:r = `rlast' `rlast' `rlast' `rlast')

* ===========================================================================
* 8.  TREND AND CYCLE
* ===========================================================================
* Beveridge-Nelson.  The Toolbox's own guidance for this demo is to restrict
* the trend for inflation and the interest rates in every country.

gvar tcdecomp, variables(usa:y euro:y china:y) restrict(Dp r lr)

* ===========================================================================
* 9.  THE BAYESIAN ALTERNATIVE
* ===========================================================================
* gvar bayes replaces gvar estimate: it samples each country VARX* by MCMC
* rather than fitting it by reduced-rank ML, writes the posterior mean into the
* same slots, and then gvar solve and everything after it proceed unchanged.
*
* Three settings below are NOT the defaults, and each one is here for a
* measured reason rather than taste.  Read them before copying this block.
*
*   prmean(0).  The default prmean(1) is a RANDOM-WALK prior on each own first
*   lag -- the standard choice for macro data in levels, and exactly what pushes
*   133 country roots onto the unit circle.  Stacked across 26 countries the
*   system tips over.  Measured on this demo, 60 draws each:
*
*       prmean  lambda1   max |eig|   roots > 1
*            1     0.10     1.02041           8      <- the DEFAULT, unstable
*            0     0.10     0.99751           0
*            0     0.05     0.99817           0
*            0     0.02     0.74102           0      <- over-shrunk
*
*   so prmean(0) with lambda1 at its default 0.1 is what makes this model
*   usable.  A forecast from an explosive system diverges rather than being
*   merely wide, so this is not a cosmetic choice.
*
*   noeigentrim.  BGVAR discards any draw whose largest companion eigenvalue
*   modulus reaches 1.05, and stops outright below 10 survivors.  On this model
*   those moduli run above 1.05 -- a GVAR in levels has many roots near unity
*   and the MAXIMUM of the 408 companion eigenvalues sits above one in almost
*   every draw --
*   so the default cutoff discards everything.  gvar bayes prints the three
*   numbers when that happens; noeigentrim keeps every draw instead.
*
*   a seed.  An MCMC result that cannot be reproduced is not a result.

gvar bayes, prior(mn) prmean(0) noeigentrim                  ///
    draws(1000) burnin(1000) seed(20260811)

* Check the chains BEFORE reading anything from them.  Geweke compares the
* first 10% of each chain with the last 50%; the estimator over-rejects
* slightly by construction, so read 7 or 8% as unremarkable rather than 5%.
gvar bconv

* Which units are responsible, if the share is high.  One badly identified
* country model often accounts for the whole of it.
gvar bconv, byunit

* Stack and solve the posterior mean, exactly as after gvar estimate.
gvar solve

* Score the specification.  Only DIFFERENCES in DIC mean anything -- the level
* carries the arbitrary constant of the Gaussian density -- and only across
* models fitted to the same data, the same lags and the same variables.
*
* This has to come AFTER gvar solve, not before: the deviance is the GLOBAL
* likelihood, so it needs F_l and G0^-1, and theta-bar averages A, S and Ginv
* separately over the draws (BGVAR.R:1053-1055).  gvar bayes invalidates any
* earlier solution, so the solve above is what bdic reads.
gvar bdic

* The predictive density, which is the one thing the Bayesian branch offers
* that gvar forecast cannot: every draw is stacked and solved separately, so
* the interval carries PARAMETER uncertainty as well as shock uncertainty.
* On this demo that roughly doubles it.  Measured at draws(200) burnin(200),
* which is what gvar_bforecast.sthlp tabulates: 90% half-widths for usa:y of
* 0.0117 under gvar forecast against 0.0264 here at h = 1, a ratio of 2.26.
*
* The block below runs 1000 draws with a 1000 burn-in, so it is a DIFFERENT
* chain and prints about 0.0241 rather than 0.0264 -- 9% apart, which is MCMC
* variation and not a discrepancy.  Do not expect a half-width quoted at one
* chain length to reappear at another; only the seed AND the chain settings
* together pin an MCMC number down.
*
* The predictive interval can never be the NARROWER of the two: its variance is
* E[Omega(h)] + Var(mu_h) against gvar forecast's E[Omega(h)] alone.  Note the
* two cannot be compared from this file's output, either -- section 7 forecasts
* the ML fit and this forecasts the Bayesian one.  _test54.do puts both on the
* same model, which is the only way the ratio means anything.
*
* Note these are not sample paths: each horizon is drawn from its own marginal
* predictive, so a row is right for its own horizon and must not be read as a
* trajectory.
gvar bforecast, variables(usa:y euro:y) step(8) bands(68 90)

* The other three priors take the same workflow.  SSVS reports a posterior
* inclusion probability per coefficient; Normal-Gamma and Horseshoe are
* global-local shrinkage, and Horseshoe takes no tuning hyperparameters at all.
*
*   gvar bayes, prior(ssvs) pi(0.8) prmean(0) noeigentrim draws(1000) burnin(1000) seed(1)
*   gvar bayes, prior(ng)   prmean(0) noeigentrim draws(1000) burnin(1000) seed(1)
*   gvar bayes, prior(hs)   prmean(0) noeigentrim draws(1000) burnin(1000) seed(1)
*
* And sv replaces the constant variance with a stochastic-volatility path.  The
* target is BGVAR's; the algorithm is the standard mixture sampler rather than
* the interweaved one, so mixing may be slower -- which is what gvar bconv is
* for.
*
*   gvar bayes, prior(mn) prmean(0) sv noeigentrim draws(2000) burnin(2000) seed(1)

* Restore the ML fit before continuing, so the sections below describe the
* model this file has been building.  gvar bayes has overwritten it.
gvar estimate, vce(nwest) nosummary
gvar solve, nosummary

* ===========================================================================
* 10.  A SPECIFICATION AUDIT
* ===========================================================================
* One command that re-runs the specification checks and reports them together,
* which is the quickest way to see whether a change anywhere broke something
* somewhere else.

gvar report

* ===========================================================================
* 11.  SAVE THE FITTED MODEL
* ===========================================================================
* Estimating, solving and bootstrapping this model takes several minutes.
* The saved file carries its own copies of the data, weights and estimates,
* so it reloads without the panel.

* This one is an OUTPUT, so it is written to the current working directory
* rather than resolved on the adopath.  Give a full path if you want it
* somewhere specific.
gvar save gvar_demo_fitted, replace

* To pick up where you left off in a later session:
*     gvar use gvar_demo_fitted
*     gvar irf, shock(usa:r) response(y) step(24)

* ===========================================================================
* Two routes this file did not take
* ===========================================================================
* BRINGING DATA OVER FROM THE TOOLBOX.  This file starts from a Stata dataset.
* If you have the Toolbox's own workbook instead -- one worksheet per variable,
* countries across the columns, dates down column A -- gvar import turns it
* round without retyping:
*
*   gvar import using "GVAR_Data.xls", domestic(y Dp eq ep r lr) ///
*       global(poil pmat pmetal) frequency(quarterly) clear
*
* It counts and names the gaps the merge leaves, which is the case that
* otherwise estimates and solves without complaint.
*
* THE OIL PRICE INSIDE THE US MODEL.  Section 1 uses dominant(), which is what
* the Toolbox demo does.  The alternative is the Dees-di Mauro-Pesaran-Smith
* device: make the oil price a US ENDOGENOUS variable, so it is determined
* contemporaneously by US dynamics rather than by its own block.
*
*   gvar setup ..., gendog(poil=usa)        // instead of dominant(poil)
*   gvar estimate
*   gvar solve                              // no gvar dominant needed
*
* That gives the usa model three extra equations and a different global system.
* Both are legitimate and they answer the question differently; what you must not
* do is assume one while reading results produced by the other.  Getting this
* wrong is what made this file's usa model disagree with the published demo by
* 490 in log-likelihood while all 25 other countries matched exactly -- the kind
* of error that shifts every global result and looks like nothing.
*
* Do not use both for the same variable.

* ===========================================================================
* Further reading
* ===========================================================================
*   help gvar            the command family and the workflow
*   help gvar_methods    equations, the step-to-source map, the places where
*                        the reference implementations disagree, and a list of
*                        checks that look convincing and are not
*   help gvar_datasets   the shipped data
*   help gvar_bayes      the four priors, the eigenvalue trim, and why the
*                        defaults do not suit this particular model
*   help gvar_dominant   the dominant-unit model, and gendog() versus dominant()
*   help gvar_import     reading a Toolbox workbook
