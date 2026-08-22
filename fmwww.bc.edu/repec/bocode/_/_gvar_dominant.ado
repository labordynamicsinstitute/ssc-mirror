*! _gvar_dominant 1.0.1  21aug2026
*! gvar dominant -- the dominant unit / global exogenous model.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Inventory section 7.  Toolbox estimate_VECM_dumodel.m, vec2var_du.m,
* augmentedregression.m, and the dominant-unit branch of solve_GVAR.m.
*
* A global variable -- an oil price, a commodity index -- can be handled two
* ways.  Attach it to a country block with gendog(), which makes it that
* country's endogenous variable and gives it that country's dynamics; or give
* it its own block, which is what this does.  The second is what the Toolbox
* calls the dominant unit, and it is the honest choice when the variable is
* nobody's domestic variable.
*
* Step -> source map
*   univariate AR(p) in levels        <- estimate_VECM_dumodel.m, esttype 0
*   univariate AR(p) in differences   <- estimate_VECM_dumodel.m, esttype 1
*   multivariate VECM                 <- estimate_VECM_dumodel.m -> mlcoint
*   VAR recovery from the VECM        <- vec2var_du.m
*   feedback variables xtilde* = W x  <- augmentedregression.m
*   stacking into the GVAR            <- solve_GVAR.m dominant-unit branch
*
* The block is estimated here and used by gvar solve.  It is NOT a unit: N
* stays the number of country models, because every per-country table in the
* package expects a beta, an alpha and a residual matrix per index.  K does
* grow, so the dominant variables appear as responses and as shocks in irf,
* fevd, spillover and hd -- which is the point of modelling them at all.

program define _gvar_dominant, rclass
    version 14.0

    syntax [,                                   ///
        LAGs(integer 2)                         ///
        FLAGs(integer 1)                        ///
        CASe(integer 4)                         ///
        RANK(integer 1)                         ///
        DIFF                                    ///
        FEEDback(string)                        ///
        WEIGHTs(string)                         ///
        TREND                                   ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require foreign

    mata: st_local("hasm", strofreal(gvar_hasdumark()))
    if ("`hasm'" != "1") {
        di as err "no global variable is assigned to the dominant unit."
        di as err "Name them when the model is set up:"
        di as err "    {bf:gvar setup ..., global(poil pmat) dominant(poil pmat)}"
        di as err "A global named in {bf:dominant()} is endogenous in no"
        di as err "country; its own block supplies it."
        exit 459
    }

    mata: st_local("gd", strofreal(rows(gvar_getduylist())))
    mata: st_local("dul", invtokens(gvar_getduylist()'))
    * duylist is only filled once the block has been estimated; before that,
    * count the marked globals from the data matrix instead
    mata: st_local("gd", strofreal(cols(gvar_getduX())))
    mata: st_local("N",  strofreal(gvar_getN()))

    if (`lags' < 1) {
        di as err "lags() must be at least 1"
        exit 198
    }

    * ---- which estimator ----------------------------------------------------
    * estimate_VECM_dumodel.m branches on the number of dominant variables:
    * one gives an AR(p) in levels or in first differences, more than one a
    * VECM.  diff is meaningless for the VECM branch and is refused rather
    * than ignored.
    local etype 0
    if ("`diff'" != "") local etype 1
    if (`gd' > 1 & `etype' == 1) {
        di as err "diff applies to a single dominant variable."
        di as err "With " as res `gd' as err " of them the block is a VECM," ///
                  " where the differencing is"
        di as err "already in the error-correction form."
        exit 198
    }

    * ducase: for the levels AR it is 0 (intercept) or 1 (intercept and
    * trend); for the VECM it is the usual 2, 3 or 4.  Keeping one option
    * name for both means translating here rather than asking the user to
    * know which branch they are in.
    local ducase = `case'
    if (`gd' == 1 & `etype' == 0) {
        local ducase 0
        if ("`trend'" != "") local ducase 1
    }
    if (`gd' == 1 & `etype' == 1) {
        local ducase 0
    }
    if (`gd' > 1) {
        if (`case' < 2 | `case' > 4) {
            di as err "case() must be 2, 3 or 4 for a VECM dominant unit"
            exit 198
        }
        if (`rank' < 0 | `rank' >= `gd') {
            di as err "rank() must be between 0 and " as res `=`gd'-1'
            exit 198
        }
    }

    * ---- estimate ------------------------------------------------------------
    * The GVAR lag order can RISE here: amaxlag = max(maxlag, ptilde,
    * qtilde), with ptilde = lags for a univariate model in levels and
    * lags + 1 otherwise.  Record pmax before and after so the change can be
    * reported rather than discovered later in gvar solve.
    * ---- the entity's own weights (BGVAR OE.weights$weights) --------------
    * A vector over units, in the model's unit order, or a variable holding
    * one value per unit.  Empty keeps the aggregation weights, which is the
    * default rather than the definition.
    if ("`weights'" != "") {
        capture confirm matrix `weights'
        if (_rc) {
            di as err "weights() must name a Stata matrix with one row per"
            di as err "unit, in the order {bf:gvar describe} lists them."
            exit 198
        }
        if (rowsof(`weights') != `N') {
            di as err "weights() has " as res rowsof(`weights') as err ///
                      " rows; the model has " as res `N' as err " units."
            exit 198
        }
        mata: gvar_setduw(st_matrix("`weights'")[., 1])
    }
    else {
        mata: gvar_setduw(J(0, 1, .))
    }

    mata: st_local("pm0", strofreal(gvar_getpmax()))
    mata: gvar_durun(`lags', `flags', `ducase', `etype', `rank', "`feedback'")
    mata: st_local("pm1", strofreal(gvar_getpmax()))

    mata: st_local("dul",  invtokens(gvar_getduylist()'))
    mata: st_local("fbl",  invtokens(gvar_getdufblist()'))
    local nfb : word count `fbl'

    tempname TH OM EP A0
    mata: st_matrix("`TH'", gvar_getduTh())
    mata: st_matrix("`OM'", gvar_getduOm())
    mata: st_matrix("`EP'", gvar_getdueps())
    mata: st_matrix("`A0'", gvar_getdua0())

    * ---- report ---------------------------------------------------------------
    if ("`summary'" != "nosummary") {
        _gvar_title "Dominant unit model"
        di as text "  Variables in the block: " as result "`dul'"
        if (`gd' == 1) {
            if (`etype' == 1) {
                di as text "  Univariate AR(" as result `lags' as text ///
                   ") in {bf:first differences}, mapped back to levels."
                di as text "  estimate_VECM_dumodel.m returns the level" ///
                           " coefficients as"
                di as text "  Theta_1 = 1 + b_2, Theta_i = b_(i+1) - b_i," ///
                           " Theta_p = -b_p."
            }
            else {
                di as text "  Univariate AR(" as result `lags' as text ///
                   ") in {bf:levels}" _continue
                if (`ducase' == 1) di as text ", with a linear trend."
                else               di as text ", intercept only."
            }
        }
        else {
            di as text "  VECM with " as result `gd' as text ///
               " variables, rank " as result `rank' as text ///
               ", case " as result `ducase' as text "."
            di as text "  VAR coefficients recovered as in {it:vec2var_du.m}."
        }
        di as text "  Both stages are the Toolbox's: stage I is" ///
                   " {it:estimate_VECM_dumodel.m},"
        di as text "  stage II the augmented regression of" ///
                   " {it:augmentedregression.m}, which is"
        di as text "  where every reported coefficient comes from.  It runs" ///
                   " with or without"
        di as text "  feedbacks, so these are not the first-stage numbers."
        if (`pm1' > `pm0') {
            di as text "  {err:GVAR lag order raised} from " as result `pm0' ///
               as text " to " as result `pm1' as text ": the dominant block"
            di as text "  needs more lags than the country models, and" ///
                       " amaxlag = max(maxlag,"
            di as text "  ptilde, qtilde).  Every country block was" ///
                       " zero-padded to match."
        }
        if (`nfb' > 0) {
            local wsrc "aggregation weights"
            if ("`weights'" != "") local wsrc "weights(`weights')"
            di as text "  Feedback variables: " as result "`fbl'" as text ///
               "  aggregated with " as result "`wsrc'" as text ///
               ", lag order " as result `flags'
            di as text "  These enter at {bf:lags only}.  solve_GVAR.m's" ///
                       " H0 = [G0 -J0 ; 0 I] has a"
            di as text "  zero in its second row, so the block cannot" ///
                       " respond within the period."
        }
        else {
            di as text "  No feedback: the block is strictly exogenous to" ///
                       " the country models."
        }
        di ""

        * ---- the level coefficients --------------------------------------
        di as text "{hline 74}"
        di as text "  Lag coefficients (levels representation)"
        di as text "{hline 74}"
        local ml = colsof(`TH') / `gd'
        di as text "  equation" _col(16) _continue
        forvalues j = 1/`ml' {
            di as text %10s "lag `j'" _continue
        }
        di ""
        di as text "{hline 74}"
        forvalues q = 1/`gd' {
            local nm : word `q' of `dul'
            di as text "  " %-13s abbrev("`nm'", 13) _continue
            forvalues j = 1/`ml' {
                local c = (`j' - 1) * `gd' + `q'
                di as result %10.4f `TH'[`q', `c'] _continue
            }
            di ""
        }
        di as text "{hline 74}"
        di as text "  Columns beyond the estimated order are exactly zero:" ///
                   " the block is"
        di as text "  padded to the GVAR lag order so it stacks with the" ///
                   " country models."
        di ""

        * ---- residual scale ------------------------------------------------
        di as text "{hline 74}"
        di as text "  Residuals"
        di as text "{hline 74}"
        di as text "  equation" _col(20) "s.d." _col(34) "observations"
        forvalues q = 1/`gd' {
            local nm : word `q' of `dul'
            di as text "  " %-16s abbrev("`nm'", 16) ///
               as result %10.6f sqrt(`OM'[`q', `q']) ///
               as result %14.0f rowsof(`EP')
        }
        di as text "{hline 74}"
        di ""
        di as text "  Run {bf:gvar solve} to stack this block into the" ///
                   " system.  Its variables"
        di as text "  are already in x(t), so {bf:gvar irf} and" ///
                   " {bf:gvar fevd} will report them."
        di ""
    }

    if ("`saving'" != "") {
        matrix `saving' = `TH'
    }

    tempname A1V
    mata: st_matrix("`A1V'", gvar_getdua1())
    return matrix a0    = `A0', copy
    return matrix a1    = `A1V', copy
    return matrix theta = `TH', copy
    return matrix omega = `OM', copy
    return local  variables "`dul'"
    return local  feedback  "`fbl'"
    return scalar nvars    = `gd'
    return scalar nfeedback = `nfb'
    return scalar lags     = `lags'
    return scalar flags    = `flags'
    return scalar pmax     = `pm1'
    return scalar case     = `ducase'
    return scalar rank     = `rank'
    return scalar diff     = `etype'
end
