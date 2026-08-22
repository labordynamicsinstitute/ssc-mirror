*! _gvar_solve 1.0.1  21aug2026
*! gvar solve -- build the link matrices, stack the country models into the
*! global model, invert to the reduced form, and check stability.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   z_it = W_i x_t, link matrices            <- Toolbox create_linkmatrices.m
*   G0 = stack_i A_i W_i, H_l = stack_i B_il W_i,
*   F_l = G0^-1 H_l, eta = G0^-1 zeta        <- Toolbox solve_GVAR.m
*                                               BGVAR gvar_stacking.cpp
*   companion eigenvalues and stability      <- same
*   number of unit eigenvalues vs K - sum r  <- Toolbox gvar.m section 4.3

program define _gvar_solve, rclass
    version 14.0

    syntax [, TOLerance(real 1e-6) ///
              GRaph                ///
              NAME(string)         ///
              NEIGen(integer 20)   ///
              noSUMmary ]

    * "dominant" implies "estimate"; it adds the check that a dominant block
    * DECLARED at setup has actually been fitted, which is what stacking needs.
    _gvar_require dominant

    mata: gvar_solvemodel()

    mata: st_local("N",    strofreal(gvar_getN()))
    mata: st_local("K",    strofreal(gvar_getK()))
    mata: st_local("pmax", strofreal(gvar_getpmax()))

    tempname EIG RK
    mata: st_matrix("`EIG'", gvar_geteig())
    mata: st_matrix("`RK'",  gvar_getrank())

    local ne = rowsof(`EIG')
    local maxmod = `EIG'[1, 1]

    * number of eigenvalues at (numerically) one
    local nunit 0
    forvalues i = 1/`ne' {
        if (abs(`EIG'[`i', 1] - 1) < `tolerance') local ++nunit
    }
    local nexpl 0
    forvalues i = 1/`ne' {
        if (`EIG'[`i', 1] > 1 + `tolerance') local ++nexpl
    }

    * K - sum(r) is the theoretical number of unit roots
    local sumr 0
    forvalues i = 1/`N' {
        local sumr = `sumr' + `RK'[`i', 1]
    }

    * The dominant block is in K but not in RK: RK has one row per COUNTRY
    * model.  Left out, a block that cointegrates internally is counted as gd
    * common trends instead of gd - r_du, and the diagnostic reports a
    * mismatch that is its own arithmetic rather than the model's.
    *
    * Only the VECM branch has a rank to subtract.  For a univariate dominant
    * variable, whether it contributes a unit root depends on where the roots
    * of its own AR polynomial fall -- an estimated property, not an imposed
    * one -- so nothing is subtracted and the report says the count excludes
    * the block.  Assuming 0 or 1 there would trade a visible mismatch for an
    * invisible one.
    local durk 0
    local duk  0
    local dukn 0
    capture mata: st_local("duk", strofreal(gvar_hasdu()))
    if ("`duk'" == "1") {
        mata: st_local("dukn", strofreal(rows(gvar_getduylist())))
        mata: st_local("durk", strofreal(gvar_getdurank()))
        if (`dukn' > 1) local sumr = `sumr' + `durk'
    }
    local expected = `K' - `sumr'

    if ("`summary'" != "nosummary") {
        _gvar_title "Solved GVAR"
        di as text "  Endogenous variables (K)     " as result %8.0f `K'
        di as text "  GVAR lag order               " as result %8.0f `pmax'
        di as text "  Companion eigenvalues        " as result %8.0f `ne'
        di ""
        di as text "  {hline 66}"
        di as text "  Stability"
        di as text "  {hline 66}"
        di as text "  Largest eigenvalue modulus   " as result %12.6f `maxmod'
        di as text "  Eigenvalues > 1 (tol " %6.0e `tolerance' ")     " ///
                   as result %8.0f `nexpl'
        if (`nexpl' == 0) {
            di as text "  " as result "The GVAR is stable: no eigenvalue exceeds unity."
        }
        else {
            * {err:} markup, not "as err".  This is a WARNING inside the summary
            * block, and "as err" prints through -quietly- -- so a loop doing
            * "qui gvar solve" got instability warnings it had asked to suppress.
            * The error paths in this file are different: they exit, so they
            * should print regardless.
            di as text "  {err:The GVAR is UNSTABLE: `nexpl' eigenvalue(s)" ///
                       " exceed unity.}"
            di as text "  {err:Impulse responses will not die out. Re-check" ///
                       " the lag}"
            di as text "  {err:orders, the ranks and the deterministic case.}"
        }
        di ""
        di as text "  {hline 66}"
        di as text "  Unit roots"
        di as text "  {hline 66}"
        di as text "  Eigenvalues at unity         " as result %8.0f `nunit'
        * A Bayesian VARX in levels imposes NO cointegrating rank, so K - sum(r)
        * has nothing to compare against: m.rnk holds whatever gvar coint or an
        * earlier gvar estimate left behind, and printing a "mismatch" against
        * it would be this command's arithmetic rather than the model's.  BGVAR
        * runs no such check either -- the eigenvalue trim in gvar bayes is what
        * takes its place.
        mata: st_local("et", gvar_getesttype())
        if ("`et'" == "bvarx") {
            di as text "  " as result "The model was fit by gvar bayes as a" ///
               " VARX in levels,"
            di as text "  so no cointegrating rank is imposed and there is no"
            di as text "  K - sum(r) to compare this against.  Stability was"
            di as text "  screened draw by draw instead; see the eigenvalue"
            di as text "  trim reported by {bf:gvar bayes}."
        }
        else {
            di as text "  K - sum(r) expected          " ///
               as result %8.0f `expected'
            if ("`duk'" == "1") {
                if (`dukn' > 1) {
                    di as text "  including the dominant block's rank " ///
                       as result %5.0f `durk'
                }
                else {
                    di as text "  {err:The dominant block is univariate, so" ///
                               " no rank is subtracted}"
                    di as text "  {err:for it; the expected count excludes it" ///
                               " and a difference of one}"
                    di as text "  {err:is what a unit root in that block" ///
                               " looks like.}"
                }
            }
            if (`nunit' == `expected') {
                di as text "  " as result ///
                   "Consistent with the imposed cointegrating ranks."
            }
            else {
                di as text "  {err:These differ; the number of common" ///
                           " stochastic}"
                di as text "  {err:trends implied by the solved model is not" ///
                           " the one implied}"
                di as text "  {err:by the country-by-country ranks. This is" ///
                           " common when the}"
                di as text "  {err:ranks are chosen unit by unit} -- see" ///
                           " {help gvar_methods}."
            }
        }
        di ""
        di as text "  {hline 66}"
        di as text "  Largest " as result `neigen' as text " eigenvalue moduli"
        di as text "  {hline 66}"
        local show = min(`neigen', `ne')
        local line "   "
        forvalues i = 1/`show' {
            local piece : display %8.5f `EIG'[`i', 1]
            if (length("`line'`piece'  ") > 76) {
                di as text "`line'"
                local line "   "
            }
            local line "`line'`piece'  "
        }
        if (trim("`line'") != "") di as text "`line'"
        di as text "  {hline 66}"
        di ""
    }

    if ("`graph'" != "") {
        _gvar_solve_graph `EIG' "`name'"
    }

    return matrix eigen = `EIG', copy
    return scalar maxmod   = `maxmod'
    return scalar nunit    = `nunit'
    return scalar nexpl    = `nexpl'
    return scalar expected = `expected'
    return scalar K        = `K'
    return scalar pmax     = `pmax'
    return scalar stable   = (`nexpl' == 0)
end

* ---------------------------------------------------------------------------
* Eigenvalue moduli against the unit circle
* ---------------------------------------------------------------------------
program define _gvar_solve_graph
    version 14.0
    args EIG gname
    if ("`gname'" == "") local gname gvar_eigen

    _gvar_palette
    local reg  "`r(region)'"
    local c1   "`r(c1)'"
    local zero "`r(zero)'"

    preserve
    clear
    local ne = rowsof(`EIG')
    qui set obs `ne'
    qui gen double modulus = .
    forvalues i = 1/`ne' {
        qui replace modulus = `EIG'[`i', 1] in `i'
    }
    qui gen int idx = _n

    twoway ///
        (scatter modulus idx, msymbol(circle) msize(small) ///
             mcolor("`c1'%70") mlcolor("`c1'") mlwidth(vthin)) ///
        , `reg' ///
          yline(1, lcolor("`zero'") lpattern(dash) lwidth(medthin)) ///
          ylabel(, angle(0) labsize(small) grid glcolor(gs15)) ///
          xlabel(, labsize(small)) ///
          ytitle("modulus", size(small)) ///
          xtitle("eigenvalue (sorted)", size(small)) ///
          title("Eigenvalues of the GVAR companion matrix", ///
                size(medium) color(black)) ///
          subtitle("moduli must not exceed the unit circle", ///
                   size(vsmall) color(gs7)) ///
          name(`gname', replace)
    restore
end
