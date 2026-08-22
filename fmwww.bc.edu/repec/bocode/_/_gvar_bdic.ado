*! _gvar_bdic 1.0.1  21aug2026
*! gvar bdic -- deviance information criterion for the sampled model.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Inventory section 12.11.  BGVAR R/BGVAR.R dic(), which calls the exported
* globalLik() and helper.cpp dmvnrm_arma_fast.
*
* Note on reading the source: utils.R:1446 has a .globalLik call COMMENTED OUT
* inside .gvar.stacking.wrapper, which looks like the dead joint sampler at
* BVAR_linear.cpp:413.  It is not the same situation -- BGVAR.R:974 and 1051
* call a LIVE exported globalLik() and BGVAR.R:1012 documents dic().  The
* commented line is only a storage shortcut.  Commented code near a live call
* path needs the call path checked before the comment is trusted.
*
* Step -> source map
*   Dbar = -2 mean_s logL(theta_s)      <- BGVAR.R:1056
*   pD   = Dbar + 2 logL(theta_bar)     <- BGVAR.R:1057
*   DIC  = Dbar + pD                    <- BGVAR.R:1058
*   theta_bar: A, S and Ginv averaged
*     SEPARATELY, then combined         <- BGVAR.R:1053-1055

program define _gvar_bdic, rclass
    version 14.0

    syntax [, noSUMmary ]

    _gvar_require solve
    capture mata: st_local("hb", strofreal(gvar_hasbayes()))
    if (_rc | "`hb'" != "1") {
        di as err "there is no sampled chain in memory; run {bf:gvar bayes}"
        di as err "first.  DIC averages the likelihood over the retained draws,"
        di as err "so it has nothing to say about a model fitted by"
        di as err "{bf:gvar estimate} -- use the log likelihood, AIC and SBC"
        di as err "that {bf:gvar estimate} reports per country model."
        exit 301
    }

    mata: st_local("nd", strofreal(gvar_getbdraws()))
    if (`nd' < 2) {
        di as err "DIC needs at least two draws to average over; the chain has"
        di as err "`nd'."
        exit 198
    }

    if ("`summary'" != "nosummary") {
        di as text "  evaluating the global likelihood at " as result `nd' ///
           as text " draw(s) ..."
    }

    tempname D
    mata: st_matrix("`D'", gvar_bdicrun())
    local Db = `D'[1, 1]
    local pD = `D'[1, 2]
    local IC = `D'[1, 3]
    local np = `D'[1, 4]
    local nf = `D'[1, 5]

    if (`Db' >= .) {
        di as err "the global likelihood could not be evaluated at any draw."
        di as err "That happens when the stacked covariance is singular at"
        di as err "every draw, which the sampler should not produce -- check"
        di as err "{bf:gvar bconv} and the eigenvalue trim first."
        exit 498
    }

    if ("`summary'" != "nosummary") {
        _gvar_title "Deviance information criterion"
        di as text "  Draws averaged over    " as result %14.0f `=`nd' - `nf''
        if (`nf' > 0) {
            di as text "  Draws skipped          " as result %14.0f `nf'
            di as text "    A draw is skipped when its stacked covariance is"
            di as text "    singular, so no density exists to evaluate.  It is"
            di as text "    left out rather than counted as a zero."
        }
        di ""
        di as text "  Posterior mean deviance   Dbar " as result %14.4f `Db'
        if (`pD' < .) {
            di as text "  Effective parameters      pD   " as result %14.4f `pD'
            di as text "  {bf:DIC}" _col(35) as result %14.4f `IC'
        }
        else {
            * {err:} markup, not "as err": this is inside the summary block, so
            * "as err" would print through a -qui gvar bdic-.  Third time this
            * trap has appeared today; the error paths above are different --
            * they exit, so they SHOULD print regardless.
            di as text "  {err:pD could not be computed: the likelihood at the}"
            di as text "  {err:posterior mean is undefined.  Dbar is still valid.}"
        }
        di as text "  Actual parameter count         " as result %14.0f `np'
        di ""
        di as text "  pD is the {bf:effective} number of parameters,"
        di as text "  Dbar - D(theta_bar).  Where it is positive, the gap below"
        di as text "  the actual count is what the shrinkage bought.  It can"
        di as text "  also be negative; see below."
        di ""
        di as text "  {bf:Do not read pD as a measure of prior tightness.}  It is"
        di as text "  concentration times curvature: tightening concentrates"
        di as text "  the posterior, which lowers pD, but also pushes it into a"
        di as text "  steeper region of the likelihood, which raises pD.  The"
        di as text "  two oppose, so the direction is not guaranteed either way."
        di as text "  Measured on the shipped demo under the EARLIER"
        di as text "  gendog(poil=usa) specification, prmean(0), 150 draws,"
        di as text "  K = 136 with 2 lags.  The demo now uses dominant(), which"
        di as text "  raises the lag order to 3 and the parameter count to 55624,"
        di as text "  so the levels below will NOT match what this command just"
        di as text "  printed -- only the SHAPE of the relationship carries over:"
        di as text "      lambda1      Dbar         pD       pD/count"
        di as text "        0.5     -89404      1305.2       0.035"
        di as text "        0.2     -88302       698.5       0.019"
        di as text "        0.1     -86444       428.8       0.012   <- default"
        di as text "        0.05    -80996       -73.9      -0.002"
        di as text "        0.01    -42151      -926.0      -0.025"
        di as text "  On this demo pD falls steadily as the prior tightens and"
        di as text "  goes {bf:negative} below about lambda1(0.1), while Dbar"
        di as text "  rises -- the fit deteriorates and DIC stops being usable"
        di as text "  before it warns you in any other way.  That is one dataset"
        di as text "  and five points, not a theorem: check rather than assume."
        di ""

        * Measured on the shipped demo, prmean(0), 150 draws, seed 20260811,
        * by _test53.do:
        *
        *     lambda1     Dbar          pD      pD/37128
        *       0.5    -89403.7      1305.2       0.035
        *       0.2    -88301.6       698.5       0.019
        *       0.1    -86443.5       428.8       0.012   <- the default
        *       0.05   -80996.2       -73.9      -0.002
        *       0.01   -42151.1      -926.0      -0.025
        *
        * THESE NUMBERS REPLACE AN EARLIER SET measured before Sigma was
        * corrected from inv(L) D inv(L)' to L D L'.  Sigma enters the deviance
        * twice -- through log|Sigma| and through the quadratic form -- so the old
        * table was out by up to 147% on Dbar and 103% on pD, and it supported a
        * claim that is now false: the old numbers were U-shaped with a minimum
        * near lambda1(0.2), which is why the text used to assert non-monotonicity
        * in that specific shape.  Under the corrected Sigma pD is monotone
        * decreasing in tightness over these five points and turns negative.
        *
        * The mechanism argument survives -- concentration and curvature really do
        * oppose, so no direction is guaranteed -- but the shape it was used to
        * illustrate does not, and the text now says only what was measured.
        *
        * At lambda1(0.01) the coefficients are pinned near zero while the data
        * sit around 4.8, so the residuals are enormous and theta_bar's SEPARATE
        * averaging drifts far from the draws it represents.  pD goes negative,
        * which is the documented weakness of DIC when the posterior is far from
        * normal -- not something this implementation introduces.  Note the
        * warning below therefore FIRES on the shipped demo at lambda1(0.05) and
        * tighter; it is not a theoretical caveat.
        if (`pD' < .) {
            if (`pD' < 0) {
                di as text "  {err:pD is NEGATIVE.}  That is a known DIC failure"
                di as text "  {err:mode, not an arithmetic error: it means the}"
                di as text "  {err:posterior is far from normal, and DIC should}"
                di as text "  {err:not be used to rank this model.}"
                di ""
            }
            else if (`pD' > 0.5 * `np') {
                di as text "  {err:pD is above half the actual parameter count.}"
                di as text "  {err:A prior is supposed to REMOVE flexibility, so}"
                di as text "  {err:an effective count that high means the}"
                di as text "  {err:posterior is not concentrated and DIC's normal}"
                di as text "  {err:approximation has broken down.  Treat this DIC}"
                di as text "  {err:as uninformative rather than as a large number.}"
                di as text "  {err:Check the fit before comparing it with anything}"
                di as text "  {err:-- a Dbar far from the values a looser prior}"
                di as text "  {err:gives is the usual companion sign.}"
                di ""
            }
        }
        di as text "  {bf:Smaller DIC is better}, and only differences mean"
        di as text "  anything -- the level carries the arbitrary constant of"
        di as text "  the Gaussian density.  Compare models fitted to the"
        di as text "  {bf:same} data, the same lag orders and the same"
        di as text "  variables; a DIC computed on a different sample is not"
        di as text "  comparable, and DIC will not tell you that."
        di ""
        di as text "  theta_bar averages A, S and G0^-1 {bf:separately} and then"
        di as text "  combines them, as {it:BGVAR.R}:1053-1055 does.  That is not"
        di as text "  the mean of Sigma, and not the model {bf:gvar solve}"
        di as text "  holds; it is reproduced because DIC gets compared across"
        di as text "  papers and a different theta_bar gives a different pD."
    }

    return scalar dbar    = `Db'
    return scalar pd      = `pD'
    return scalar dic     = `IC'
    return scalar nparam  = `np'
    return scalar nfailed = `nf'
    return scalar draws   = `nd'
end
