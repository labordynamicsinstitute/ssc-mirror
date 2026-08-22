*! _gvar_bconv 1.0.1  21aug2026
*! gvar bconv -- Geweke's convergence diagnostic for the sampled chains.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Inventory section 12.10.  BGVAR R/helpers.R conv.diag(), which delegates to
* coda::geweke.diag (NAMESPACE:63).
*
* coda is a DEPENDENCY of BGVAR, not part of its source, so the diagnostic had to
* be written from the algorithm rather than transcribed -- the same situation as
* GIGrvg for the Normal-Gamma prior.  It is therefore gated on its own test
* (_test47.do): the spectral density at zero against its closed form for an
* AR(1), the size of the test on i.i.d. chains, and the power of it on a drifting
* chain and on a random walk.
*
* Step -> source map
*   Z = (m1 - m2)/sqrt(s1/n1 + s2/n2)   <- coda geweke.diag
*   first 10%, last 50%                 <- geweke.diag frac1, frac2 defaults
*   s = spectral density at ZERO        <- coda spectrum0.ar
*   count |Z| > 1.96, report percent    <- conv.diag, crit.val = 1.96
*   drop coefficients with no Z         <- conv.diag decrements K on failure

program define _gvar_bconv, rclass
    version 14.0

    syntax [,                                   ///
        CRITical(real 1.96)                     ///
        FRAC1(real 0.1)                         ///
        FRAC2(real 0.5)                         ///
        BYunit                                  ///
        GRaph                                   ///
        NAME(string)                            ///
        noSUMmary                               ///
    ]

    * There must be a chain to diagnose.  gvar bayes sets hasbayes; without it
    * m.bA holds nothing and the loop would fail with a subscript error rather
    * than a sentence.
    _gvar_require foreign
    capture mata: st_local("hb", strofreal(gvar_hasbayes()))
    if (_rc | "`hb'" != "1") {
        di as err "there is no sampled chain in memory; run {bf:gvar bayes}"
        di as err "first.  This diagnostic reads the retained draws, so it has"
        di as err "nothing to say about a model fitted by {bf:gvar estimate}."
        exit 301
    }

    if (`critical' <= 0) {
        di as err "critical() is a two-sided normal cutoff and must be positive"
        exit 198
    }
    if (`frac1' <= 0 | `frac2' <= 0 | `frac1' + `frac2' > 1) {
        di as err "frac1() and frac2() are the leading and trailing shares of"
        di as err "the chain and must be positive with frac1 + frac2 <= 1:"
        di as err "overlapping windows would compare a stretch with itself."
        exit 198
    }

    mata: st_local("nd", strofreal(gvar_getbdraws()))
    if (`nd' < 20) {
        di as err "only `nd' retained draw(s): Geweke's Z compares the first"
        di as err "`=round(100*`frac1')'% of the chain with the last"
        di as err " `=round(100*`frac2')'%, and neither window has enough"
        di as err "observations to estimate a spectral density from."
        di as err "Lengthen the chain or thin it less."
        exit 198
    }

    tempname CD
    mata: st_matrix("`CD'", gvar_bconvrun(`critical', `frac1', `frac2'))

    mata: st_local("cn", invtokens(gvar_getcname()'))
    local N = rowsof(`CD')

    local ntot 0
    local nex  0
    local nskip 0
    forvalues i = 1/`N' {
        local ntot  = `ntot'  + `CD'[`i', 2]
        local nex   = `nex'   + `CD'[`i', 3]
        local nskip = `nskip' + `CD'[`i', 4]
    }
    local pex = 0
    if (`ntot' > 0) local pex = 100 * `nex' / `ntot'

    if ("`summary'" != "nosummary") {
        _gvar_title "Convergence: Geweke (1992)"
        di as text "  The first " as result `=round(100*`frac1')' as text ///
           "% of each chain against the last " as result ///
           `=round(100*`frac2')' as text "%."
        di as text "  Under stationarity the two means are equal and Z is"
        di as text "  standard normal.  The standard error comes from the"
        di as text "  {bf:spectral density at zero}, so it accounts for the"
        di as text "  autocorrelation every MCMC chain has -- the sample"
        di as text "  variance would understate it and reject far too often."
        di ""
        di as text "  Retained draws per chain  " as result %8.0f `nd'
        di as text "  Coefficients examined     " as result %8.0f `ntot'
        di as text "  |Z| > " as result %4.2f `critical' as text ///
           "               " as result %8.0f `nex'
        di as text "  Share exceeding           " as result %8.2f `pex' ///
           as text " %"
        if (`nskip' > 0) {
            di as text "  Not examined              " as result %8.0f `nskip'
            di as text "    Coefficients that never moved have no Z.  SSVS and"
            di as text "    the shrinkage priors produce those by design, so"
            di as text "    they are excluded rather than counted as passes."
        }
        di ""
        if (`pex' <= 10) {
            di as text "  " as result "About what a converged chain looks like."
            di as text "  Under the null 5% exceed 1.96 by construction, so a"
            di as text "  share in that neighbourhood is evidence of nothing"
            di as text "  wrong rather than evidence of convergence -- the test"
            di as text "  can only fail to reject."
        }
        else {
            * {err:} markup, NOT "as err".  quietly does not suppress
            * "display as error", so this block leaked through a
            * -qui gvar bconv- in _test47.do and printed a warning in the
            * middle of a quiet run.  Same trap as the six sites already
            * converted in _gvar_report.ado.
            di as text "  {err:More chains fail than chance explains.}"
            di as text "  {err:Lengthen the chain and the burn-in before" ///
                       " reading any}"
            di as text "  {err:posterior from it.  If it persists, look at" ///
                       " which}"
            di as text "  {err:units are responsible} ({bf:byunit}):" ///
                       " {err:a single badly}"
            di as text "  {err:identified country model can account for all" ///
                       " of it.}"
        }
        di ""

        if ("`byunit'" != "") {
            di as text "  {hline 58}"
            di as text "  " %-14s "unit" %10s "examined" %10s "exceed" ///
               %10s "percent" %10s "no Z"
            di as text "  {hline 58}"
            forvalues i = 1/`N' {
                local u : word `i' of `cn'
                local ex = `CD'[`i', 2]
                local xc = `CD'[`i', 3]
                local sk = `CD'[`i', 4]
                local pc = 0
                if (`ex' > 0) local pc = 100 * `xc' / `ex'
                di as text "  " %-14s "`u'" as result %10.0f `ex' ///
                   %10.0f `xc' %10.2f `pc' %10.0f `sk'
            }
            di as text "  {hline 58}"
        }
    }

    if ("`graph'" != "") {
        _gvar_bconv_graph `CD' "`cn'" `critical' "`name'"
    }

    return matrix table = `CD'
    return scalar n        = `ntot'
    return scalar nexceed  = `nex'
    return scalar pexceed  = `pex'
    return scalar nskipped = `nskip'
    return scalar critical = `critical'
    return scalar draws    = `nd'
end

* ---------------------------------------------------------------------------
* One bar per unit: the share of its coefficients whose Z exceeds the cutoff,
* with the 5% the null implies drawn across it.  Without that reference line a
* reader has no way to tell an ordinary chain from a bad one.
* ---------------------------------------------------------------------------
program define _gvar_bconv_graph
    version 14.0
    args CD cn crit name

    preserve
    qui clear
    local N = rowsof(`CD')
    qui set obs `N'
    qui gen int    _u   = .
    qui gen double _pc  = .
    qui gen str32  _lab = ""
    forvalues i = 1/`N' {
        qui replace _u = `i' in `i'
        local ex = `CD'[`i', 2]
        local xc = `CD'[`i', 3]
        local pc = 0
        if (`ex' > 0) local pc = 100 * `xc' / `ex'
        qui replace _pc = `pc' in `i'
        local u : word `i' of `cn'
        qui replace _lab = "`u'" in `i'
    }

    local nm "gvar_bconv"
    if ("`name'" != "") local nm "`name'"

    qui levelsof _u, local(us)
    local xlab ""
    foreach u of local us {
        local l = _lab[`u']
        local xlab `xlab' `u' "`l'"
    }

    * Colours come from _gvar_palette, not from literals: the package documents
    * one palette and every other plot honours it, so a literal here would drift
    * the moment the palette changes.
    _gvar_palette
    local pc1 `"`r(c1)'"'
    local pc2 `"`r(c2)'"'
    twoway (bar _pc _u, barwidth(0.7) color("`pc1'")) ///
           (function y = 5, range(0.5 `=`N'+0.5') lcolor("`pc2'") ///
                lpattern(dash)), ///
        legend(order(1 "share exceeding |Z| > `crit'" ///
                     2 "5%, what the null implies") ///
               rows(1) size(small) region(lstyle(none))) ///
        xtitle("") ytitle("percent of coefficients") ///
        xlabel(`xlab', angle(90) labsize(vsmall)) ///
        title("Geweke convergence diagnostic by unit", size(medium)) ///
        subtitle("first 10% of each chain against the last 50%", size(small)) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name("`nm'", replace)
    restore
end
