*! _gvar_irf 1.0.1  21aug2026
*! gvar irf -- impulse responses of the solved GVAR.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   generalized IRF (Pesaran & Shin 1998)      <- Toolbox irf.m, girf.m
*     GIRF_h(j) = Phi_h G0^{-1} Sigma e_j / sqrt(e_j' Sigma e_j)
*   orthogonalised IRF (Cholesky)              <- Toolbox irf.m, sgirf flag 2
*   structural GIRF, leading block orthogonal  <- Toolbox irf.m, sgirf flag 1
*   Phi_h recursion from the reduced form      <- Toolbox phi.m
*
* The generalized responses are invariant to the ordering of the variables,
* which is why the GVAR literature reports them: with 130-odd variables there
* is no defensible Cholesky ordering.  They are not, however, responses to
* orthogonal shocks, so they do not decompose the forecast error variance
* into shares that sum to one.  See {help gvar_fevd} and {help gvar_methods}.

program define _gvar_irf, rclass
    version 14.0

    syntax [,                                   ///
        SHOCK(string)                           ///
        RESPonse(string)                        ///
        STEP(integer 24)                        ///
        TYPE(string)                            ///
        CUMULative                              ///
        FIRST(string)                           ///
        VORDer(string)                          ///
        VCOV(string)                            ///
        REPS(integer 0)                         ///
        LEVel(cilevel)                          ///
        SHUFFLE                                 ///
        SHRINKDraw                              ///
        LAMDraw(real -1)                        ///
        SHRINK                                  ///
        LAMbda(real -1)                         ///
        NEGative                                ///
        RESTRictions(string)                    ///
        SIGNS(string)                           ///
        DRAWS(integer 500)                      ///
        MAXTries(integer 200)                   ///
        CFHold(string)                          ///
        CFVia(string)                           ///
        CFBase                                  ///
        HORizons(numlist integer >=0 sort)      ///
        TABle                                   ///
        GRaph                                   ///
        NAME(string)                            ///
        BY(string)                              ///
        noSUMmary                               ///
        SAVing(name)                            ///
    ]

    _gvar_require solve

    if ("`shock'" == "") {
        di as err "shock() is required: name the element of the global vector"
        di as err "that is shocked, as {bf:unit:variable}, e.g. {bf:shock(usa:r)}"
        exit 198
    }
    if (`step' < 1) {
        di as err "step() must be at least 1"
        exit 198
    }

    * ---- shock type --------------------------------------------------------
    if ("`type'" == "") local type girf
    local type = lower("`type'")
    if      ("`type'" == "girf")  local sg 0
    else if ("`type'" == "sgirf") local sg 1
    else if ("`type'" == "oirf")  local sg 2
    else if ("`type'" == "sign")  local sg 3
    else {
        di as err "type() must be {bf:girf}, {bf:sgirf}, {bf:oirf} or {bf:sign}"
        exit 198
    }

    if (`sg' == 3 & "`restrictions'" == "" & "`signs'" == "") {
        di as err "type(sign) identifies the shock by restricting the sign or"
        di as err "the value of its responses, so it needs those restrictions:"
        di as err ""
        di as err "    {bf:signs(}{it:list}{bf:)}          restrictions on the" ///
                  " single shock in shock()"
        di as err "    {bf:restrictions(}{it:file}{bf:)}   a dataset, for" ///
                  " several shocks at once"
        di as err ""
        di as err "See {bf:help gvar_irf} for the syntax of both."
        exit 198
    }
    if (`sg' != 3 & ("`restrictions'" != "" | "`signs'" != "")) {
        di as err "signs() and restrictions() require {bf:type(sign)}"
        exit 198
    }
    if (`sg' == 3 & "`negative'" != "") {
        di as err "negative is meaningless under type(sign): the sign of the"
        di as err "shock is what the restrictions fix.  Reverse the" ///
                  " inequalities instead."
        exit 198
    }
    if (`sg' == 3 & `draws' < 1) {
        di as err "draws() must be at least 1"
        exit 198
    }

    * ---- counterfactual ----------------------------------------------------
    local cf 0
    if ("`cfhold'" != "") {
        local cf 1
        if (`sg' == 3) {
            di as err "cfhold() and type(sign) are different identifications"
            di as err "and cannot be combined."
            exit 198
        }
        if (`reps' > 0) {
            di as err "cfhold() cannot be combined with reps(): the" ///
                      " counterfactual is"
            di as err "a what-if under one identification, not an estimate" ///
                      " with sampling"
            di as err "error attached."
            exit 198
        }
    }
    if ("`cfvia'" != "" & `cf' == 0) {
        di as err "cfvia() requires cfhold()"
        exit 198
    }
    if ("`cfbase'" != "" & `cf' == 0) {
        di as err "cfbase requires cfhold()"
        exit 198
    }

    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("xn", invtokens(gvar_getxname()'))
    mata: st_local("xc", invtokens(gvar_getxcname()'))

    * n0 is DERIVED, never supplied: reorder_GVAR.m sets it to sumk0, the
    * total endogenous count of the units placed first.  For a full
    * orthogonalisation the leading block is the whole system.
    local n0 0
    if (`sg' == 2) local n0 = `K'

    * ---- resolve the shock -------------------------------------------------
    _gvar_xsel "`shock'"
    local spos "`r(pos)'"
    local slab "`r(labels)'"
    local ns = r(n)
    if (`ns' != 1) {
        di as err "shock() must select exactly one element, not `ns'"
        di as err "selected: `slab'"
        exit 198
    }

    * ---- resolve the responses ---------------------------------------------
    if ("`response'" == "") {
        * the classic cross-country panel: the shocked variable everywhere
        local sv : word `spos' of `xn'
        local response "`sv'"
    }
    _gvar_xsel "`response'"
    local rpos "`r(pos)'"
    local rlab "`r(labels)'"
    local nr = r(n)

    * ---- compute -----------------------------------------------------------
    tempname E IRF
    matrix `E' = J(`K', 1, 0)
    matrix `E'[`spos', 1] = 1
    if ("`negative'" != "") matrix `E'[`spos', 1] = -1

    local cum 0
    if ("`cumulative'" != "") local cum 1
    * ---- reordering, from which n0 is derived (reorder_GVAR.m) ------------
    tempname ORD
    local nord 0
    if ("`first'" != "") {
        _gvar_reorder "`first'" "`vorder'"
        local ordlist "`r(ord)'"
        local nord : word count `ordlist'
        matrix `ORD' = J(`nord', 1, 0)
        local q 0
        foreach z of local ordlist {
            local ++q
            matrix `ORD'[`q', 1] = `z'
        }
        if (`sg' == 1) local n0 = r(n0)
    }
    else {
        matrix `ORD' = J(1, 1, 0)
    }
    if (`sg' == 1 & "`first'" == "") {
        di as err "type(sgirf) identifies the shocks by orthogonalising the"
        di as err "leading block of x(t), so you must say which units lead:"
        di as err "    {bf:first(}{it:unit}[ {it:unit} ...]{bf:)}"
        di as err "and optionally their internal order with {bf:vorder()}."
        di as err "The block size n0 is then the total number of endogenous"
        di as err "variables in those units, as in reorder_GVAR.m."
        exit 198
    }
    * compound quotes: Stata has no backslash escape inside " "
    local ordarg "J(0, 1, 0)"
    if (`nord' > 0) local ordarg `"st_matrix("`ORD'")"'

    _gvar_shrinkopt `sg' `n0' "`vcov'" "`shrink'" "`lambda'"
    local vmeth "`r(vmeth)'"
    local vexcl "`r(vexcl)'"
    local shr   "`r(shr)'"
    local lam   "`r(lam)'"

    tempname BB
    local haveband 0
    local bandkind "bootstrap"

    if (`sg' == 3) {
        * ---- set identification by rotation --------------------------------
        tempname RES
        _gvar_signspec `spos' `"`signs'"' `"`restrictions'"'
        matrix `RES' = r(res)
        local nrestr = rowsof(`RES')

        * every SHOCKED unit's covariance block has to have a Cholesky
        * factor: gvar_p0g factors each block separately, so the leading-block
        * gate that _gvar_shrinkopt applies to oirf/sgirf is the wrong test
        mata: st_local("badu", strofreal(gvar_signpd(st_matrix("`RES'"), ///
                                          `vmeth', `vexcl', `shr', `lam')))
        if ("`badu'" != "0") {
            mata: st_local("cn", invtokens(gvar_getcname()'))
            local ub : word `badu' of `cn'
            mata: st_local("rk", strofreal(gvar_szetarank()))
            di as err "the covariance block of unit {bf:`ub'} has no" ///
                      " Cholesky factor"
            di as text "  Sigma_zeta is `K' by `K' with rank `rk'." ///
                       "  Sign identification"
            di as text "  factors each shocked unit's own block, so that" ///
                       " block must be"
            di as text "  positive definite.  Shrink it:"
            di as text ""
            di as text "      {bf:. gvar irf, type(sign) ... shrink}"
            di as text "      {bf:. gvar irf, type(sign) ... lambda(0.2)}"
            exit 506
        }

        di as text "  drawing " as result `draws' as text ///
                   " rotations that satisfy " as result `nrestr' ///
                   as text " restriction(s) ..."
        mata: gvar_signwrap(st_matrix("`RES'"), `step', `spos', `draws', ///
                            `maxtries', `vmeth', `vexcl', `shr', `lam', ///
                            `cum', `=(100-`level')/200', 0.5, ///
                            `=1-(100-`level')/200')
        local nacc  = r_nacc
        local nfail = r_nfail
        if (`nacc' == 0) {
            di as err "no rotation satisfying the restrictions was found in" ///
                      " `maxtries' tries"
            di as err "per draw.  Either the restrictions are mutually" ///
                      " inconsistent, or they"
            di as err "are simply tight: raise {bf:maxtries()}, relax a" ///
                      " sign, or drop a"
            di as err "restriction and see which one is binding."
            exit 498
        }
        matrix `BB' = r_sign
        local haveband 1
        local bandkind "identified set"

        * the point estimate under set identification is the pointwise median
        * of the accepted set -- there is no single "the" response
        matrix `IRF' = `BB'[`=`K'+1'..`=2*`K'', 1...]
    }
    else if (`cf' == 1) {
        * ---- counterfactual: hold one variable's response at zero ----------
        _gvar_xsel "`cfhold'"
        if (r(n) != 1) {
            di as err "cfhold() must name exactly one element of x(t)"
            exit 198
        }
        local hpos "`r(pos)'"
        local hlab "`r(labels)'"

        * the instrument defaults to the held variable's own shock, which is
        * the usual case: hold the policy rate fixed with policy shocks
        local vspec "`cfvia'"
        if ("`vspec'" == "") local vspec "`cfhold'"
        _gvar_xsel "`vspec'"
        if (r(n) != 1) {
            di as err "cfvia() must name exactly one element of x(t)"
            exit 198
        }
        local vpos "`r(pos)'"
        local vlab "`r(labels)'"

        local which "gvar_cfrun(`spos', `step', `hpos', `vpos', "
        if ("`cfbase'" != "") {
            local which "gvar_cfbase(`spos', `step', "
        }
        mata: st_matrix("`IRF'", `which' `vmeth', `vexcl', `shr', `lam', `cum'))
        if (rowsof(`IRF') < 2) {
            di as err "the counterfactual could not be computed"
            if (`vpos' > `hpos') {
                di as text "  {bf:`vlab'} comes AFTER {bf:`hlab'} in x(t)." ///
                           "  The impact matrix"
                di as text "  is a lower-triangular Cholesky factor, so a" ///
                           " shock ordered later"
                di as text "  has no impact effect on a variable ordered" ///
                           " earlier -- it cannot"
                di as text "  move {bf:`hlab'} at all, let alone hold it at" ///
                           " zero."
                di as text ""
                di as text "  Choose an instrument ordered BEFORE" ///
                           " {bf:`hlab'}, or reorder x(t)"
                di as text "  with {bf:first()} and {bf:vorder()}.  See" ///
                           " {help gvar_describe:gvar describe, order}"
                di as text "  for the current ordering."
            }
            else {
                di as text "  Sigma_eta has no Cholesky factor.  Add" ///
                           " {bf:shrink}, or {bf:lambda(#)}."
            }
            exit 506
        }
        if ("`negative'" != "") matrix `IRF' = -1 * `IRF'
    }
    else {
        mata: st_matrix("`IRF'", gvar_irfrun(st_matrix("`E'"), `step', ///
                                             `sg', `n0', `cum', ///
                                             `vmeth', `vexcl', `shr', `lam', ///
                                             `ordarg'))
    }

    * ---- bootstrap confidence bands (bootstrap_GVAR.m) --------------------
    * Under type(sign) the band is already the identified set, and the two
    * are not the same object: one is sampling uncertainty about a point, the
    * other is the range of points consistent with the restrictions.  Mixing
    * them into one interval would be meaningless, so reps() is refused.
    if (`sg' == 3 & `reps' > 0) {
        di as err "reps() cannot be combined with type(sign)"
        di as err "The reported band is the identified SET -- the spread of"
        di as err "responses consistent with the restrictions -- not a"
        di as err "confidence interval.  Use {bf:draws()} to control how" ///
                  " finely"
        di as err "that set is sampled."
        exit 198
    }
    if (`reps' > 0) {
        local shf 0
        if ("`shuffle'" != "") local shf 1

        * gvar.m keeps the shrinkage of the DRAW covariance separate from the
        * one used for the point estimate (use_shrinkedvcv_dg), and needs it
        * only when resampling in orthogonalised space.
        local dgs 0
        local dgl .
        if ("`shrinkdraw'" != "") local dgs 1
        if ("`lamdraw'" != "" & "`lamdraw'" != "-1") {
            if (`lamdraw' < 0 | `lamdraw' > 1) {
                di as err "lamdraw() must lie between 0 and 1"
                exit 198
            }
            local dgs 1
            local dgl `lamdraw'
        }

        if (`shf' == 0) {
            mata: st_local("dgok", strofreal(gvar_dgpd(`vmeth', `vexcl', ///
                                                       `dgs', `dgl')))
            if ("`dgok'" != "1") {
                mata: st_local("rk", strofreal(gvar_szetarank()))
                di as err "the bootstrap cannot draw from this covariance:" ///
                          " it is not positive definite"
                di as text "  Resampling in orthogonalised space needs a" ///
                           " Cholesky factor of Sigma_zeta,"
                di as text "  which is " as result "`K'" as text " by " ///
                           as result "`K'" as text " with rank " ///
                           as result "`rk'" as text " and so has none."
                di as text "  gvar.m has a separate switch for exactly this," ///
                           " use_shrinkedvcv_dg."
                di as text "  Two ways forward, both in the source:"
                di as text ""
                di as text "      {bf:. gvar irf, ... reps(#) shrinkdraw}"
                di as text "          shrink the draw covariance" ///
                           " (use_shrinkedvcv_dg = 1)"
                di as text "      {bf:. gvar irf, ... reps(#) shuffle}"
                di as text "          resample whole date columns instead" ///
                           " (shuffleflag = 1),"
                di as text "          which needs no factor and keeps the" ///
                           " cross-section"
                di as text "          correlation of the residuals intact"
                exit 506
            }
        }

        local lo = (100 - `level') / 200
        local hi = 1 - `lo'
        di as text "  bootstrapping " as result `reps' as text ///
                   " replications: regenerating the global vector," _n ///
                   "  re-estimating all country models and re-solving ..."
        mata: gvar_bootwrap(`reps', `shf', 1, st_matrix("`E'"), `step', ///
                            `sg', `n0', `vmeth', `vexcl', `shr', `lam', ///
                            `cum', `lo', 0.5, `hi', `dgs', `dgl')
        local bnok   = r_nok
        local bndisc = r_ndisc
        if (`bnok' == 0) {
            di as err "every bootstrap replication failed or was unstable"
            di as err "(`bndisc' discarded).  Try {bf:shuffle}, or fewer"
            di as err "restrictions on the country models."
            exit 498
        }
        matrix `BB' = r_boot
        local haveband 1
    }

    * rows = horizon 0..step, columns = the selected responses
    tempname R
    matrix `R' = J(`=`step'+1', `nr', .)
    local c 0
    foreach j of local rpos {
        local ++c
        forvalues h = 1/`=`step'+1' {
            matrix `R'[`h', `c'] = `IRF'[`j', `h']
        }
    }
    local rn ""
    forvalues h = 0/`step' {
        local rn "`rn' h`h'"
    }
    matrix rownames `R' = `rn'
    local cn2 ""
    foreach l of local rlab {
        local cn2 "`cn2' `=subinstr("`l'", ":", "_", .)'"
    }
    matrix colnames `R' = `cn2'

    * lower and upper bands, laid out like `R'
    tempname RL RU
    if (`haveband') {
        matrix `RL' = J(`=`step'+1', `nr', .)
        matrix `RU' = J(`=`step'+1', `nr', .)
        local c 0
        foreach j of local rpos {
            local ++c
            forvalues h = 1/`=`step'+1' {
                matrix `RL'[`h', `c'] = `BB'[`j',            `h']
                matrix `RU'[`h', `c'] = `BB'[`=2*`K'+`j'',   `h']
            }
        }
        matrix rownames `RL' = `rn'
        matrix rownames `RU' = `rn'
        matrix colnames `RL' = `cn2'
        matrix colnames `RU' = `cn2'
    }

    * ---- table -------------------------------------------------------------
    if ("`horizons'" == "") {
        local hshow 0 1 2 4 8 12 16 20 24 32 40
        local keep ""
        foreach h of local hshow {
            if (`h' <= `step') local keep "`keep' `h'"
        }
        local pin : list posof "`step'" in keep
        if (`pin' == 0) local keep "`keep' `step'"
    }
    else {
        local keep ""
        foreach h of local horizons {
            if (`h' <= `step') local keep "`keep' `h'"
        }
    }
    local keep = trim("`keep'")

    if ("`summary'" != "nosummary" | "`table'" != "") {
        local tname "Generalized impulse responses"
        if (`sg' == 1) local tname "Structural generalized impulse responses"
        if (`sg' == 2) local tname "Orthogonalised impulse responses"
        if (`sg' == 3) local tname "Sign-restricted impulse responses"
        if (`cf' == 1) {
            local tname "Counterfactual impulse responses"
            if ("`cfbase'" != "") {
                local tname "Baseline impulse responses (counterfactual off)"
            }
        }
        _gvar_title "`tname'"
        local sgn "one standard-error"
        if ("`negative'" != "") local sgn "minus one standard-error"
        if (`sg' == 3)          local sgn "unit structural"
        di as text "  Shock: " as result "`slab'" as text ", `sgn'."
        if (`sg' == 3) {
            di as text "  " as result `nrestr' as text ///
               " restriction(s); " as result `nacc' as text ///
               " of " as result `draws' as text " rotations accepted" _continue
            if (`nfail' > 0) {
                di as text " (" as result `nfail' as text ///
                   " hit maxtries(" as result `maxtries' as text "))."
            }
            else {
                di as text "."
            }
        }
        if ("`cumulative'" != "") {
            di as text "  Responses are accumulated over the horizon."
        }
        if (`sg' == 1) {
            di as text "  Leading block of size " as result `n0' ///
                       as text " orthogonalised by Cholesky."
        }
        if (`cf' == 1 & "`cfbase'" == "") {
            di as text "  " as result "`hlab'" as text ///
               " is held at zero throughout, using shocks to " ///
               as result "`vlab'" as text "."
        }
        di ""
        _gvar_irf_table `R' "`keep'" "`rlab'" `step' `haveband' `RL' `RU'
        di as text "  Read down a column for one responding variable and"
        di as text "  across a row for one horizon."
        if (`haveband' & `sg' == 3) {
            di as text "  The point estimate is the pointwise MEDIAN of the"
            di as text "  accepted rotations, and the brackets are the " ///
               as result `level' as text "% range"
            di as text "  across them.  That range is the identified SET," ///
                       " not a confidence"
            di as text "  interval: every rotation inside it fits the data" ///
                       " equally well,"
            di as text "  and no amount of data would narrow it.  The" ///
                       " restrictions are"
            di as text "  what narrows it."
            di as text "  The median response is itself not attained by any" ///
                       " single"
            di as text "  rotation, so read the set, not the middle line."
        }
        else if (`haveband') {
            di as text "  Brackets give the " as result `level' as text ///
                       "% bootstrap band from " as result `bnok' ///
                       as text " replications" _continue
            if (`bndisc' > 0) {
                di as text " (" as result `bndisc' as text " discarded as unstable)."
            }
            else {
                di as text "."
            }
            if ("`shuffle'" != "") {
                di as text "  Residuals resampled by date column, keeping the"
                di as text "  cross-section correlation intact (shuffleflag=1)."
            }
            else {
                di as text "  Residuals resampled in orthogonalised space" ///
                           " (shuffleflag=0)."
            }
        }
        * the counterfactual is Cholesky-based whatever type() says, so it has
        * to be tested before sg
        if (`cf' == 1) {
            di as text "  Shocks are orthogonalised by a Cholesky factor of"
            di as text "  Sigma_eta, the REDUCED-FORM covariance, so this"
            di as text "  depends on the order of x(t); see" ///
                       " {help gvar_describe:gvar describe}."
            if ("`cfbase'" == "") {
                di as text "  The difference from {bf:cfbase} is the part of" ///
                           " the response"
                di as text "  that travelled through " as result "`hlab'" ///
                   as text ".  Run both and subtract."
            }
        }
        else if (`sg' == 0) {
            di as text "  Generalized responses need no ordering of the"
            di as text "  variables, which is why the GVAR literature reports"
            di as text "  them: with `K' variables no Cholesky ordering is"
            di as text "  defensible.  The shock is correlated with the other"
            di as text "  shocks by construction, so these do not decompose"
            di as text "  into orthogonal contributions.  For that use"
            di as text "  {bf:type(oirf)} or {bf:type(sgirf)}."
        }
        else if (`sg' == 3) {
            di as text "  The impact matrix is G0^-1 P0G Q with Q orthonormal."
            di as text "  Zero restrictions are imposed exactly, column by"
            di as text "  column, by the Arias, Rubio-Ramirez & Waggoner"
            di as text "  nullspace algorithm; signs are imposed by rejection."
            di as text "  Because Q is not unique, the answer is a set."
            if (`shr' == 1) {
                di as text "  The covariance was shrunk towards the identity" ///
                           " before factoring."
            }
        }
        else {
            di as text "  Shocks are orthogonalised by a Cholesky factor, so"
            di as text "  the responses depend on the order of the variables"
            di as text "  in x(t); see {help gvar_describe:gvar describe} for"
            di as text "  that order."
            di as text "  Note that the impact matrix is G0^-1 P, not P: the"
            di as text "  contemporaneous links G0 mean it is not triangular"
            di as text "  even though P is."
            if (`shr' == 1) {
                di as text "  The covariance was shrunk towards the identity" ///
                           " before factoring."
            }
        }
        di ""
    }

    * ---- graph -------------------------------------------------------------
    if ("`graph'" != "") {
        _gvar_irf_graph `R' `step' `nr' "`rlab'" "`slab'" "`name'" ///
                        "`cumulative'" "`by'" `haveband' `RL' `RU' ///
                        "`bandkind'" `level'
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    if (`haveband') {
        return matrix lower = `RL', copy
        return matrix upper = `RU', copy
        return matrix band  = `BB', copy
        return scalar level = `level'
        * bnok/bndisc exist only on the bootstrap path; under type(sign) the
        * band came from rotations, and the counts that describe it are
        * different quantities with different names
        if (`sg' == 3) {
            return matrix restrictions = `RES', copy
            return scalar accepted = `nacc'
            return scalar failed   = `nfail'
            return scalar draws    = `draws'
        }
        else {
            return scalar reps  = `bnok'
            return scalar discarded = `bndisc'
        }
    }
    return matrix irf = `R', copy
    return local  shock  "`slab'"
    return local  responses "`rlab'"
    return local  type   "`type'"
    return scalar step   = `step'
    return scalar cumulative = `cum'
end

* ---------------------------------------------------------------------------
* Horizon x response table, wrapped into blocks that fit the Results window
* ---------------------------------------------------------------------------
program define _gvar_irf_table
    version 14.0
    args R keep rlab step haveband RL RU
    if ("`haveband'" == "") local haveband 0

    local nr : word count `rlab'

    * a band cell is "[-0.0035, -0.0002]", so the columns have to be wider
    * and fewer of them fit across the Results window
    local cw 11
    local per 7
    if (`haveband') {
        local cw 19
        local per 4
    }
    local done 0

    while (`done' < `nr') {
        local lo = `done' + 1
        local hi = min(`done' + `per', `nr')
        local w  = 10 + `cw' * (`hi' - `lo' + 1)

        di as text "{hline `w'}"
        di as text %-9s "  horizon" _continue
        forvalues c = `lo'/`hi' {
            local l : word `c' of `rlab'
            _gvar_ablab "`l'" `=`cw'-1'
            di as text %`cw's "`_ablab'" _continue
        }
        di ""
        di as text "{hline `w'}"

        foreach h of local keep {
            local row = `h' + 1
            di as text "  " %-7.0f `h' _continue
            forvalues c = `lo'/`hi' {
                di as result %`cw'.4f `=`R'[`row', `c']' _continue
            }
            di ""
            if (`haveband') {
                di as text "  " %-7s "" _continue
                forvalues c = `lo'/`hi' {
                    local lb = `RL'[`row', `c']
                    local ub = `RU'[`row', `c']
                    local bs = "[" + string(`lb', "%7.4f") + "," + ///
                                     string(`ub', "%7.4f") + "]"
                    di as text %`cw's "`bs'" _continue
                }
                di ""
            }
        }
        di as text "{hline `w'}"
        di ""
        local done = `hi'
    }
end
* ---------------------------------------------------------------------------
* IRF plot, with the band the command already computed.
*
* plot_irfs.m draws the point response together with its bootstrap band; the
* band is the whole reason bootstrap_GVAR.m exists.  This program used to
* receive only the point matrix, so `gvar irf, reps() graph` computed 1000
* bootstrap replications, printed them in the table, and then drew a bare
* line.  The band is now passed in and drawn as an rarea behind the response.
*
* Two kinds of band reach this program and they are NOT the same object:
*   bootstrap        a sampling interval around a point estimate
*   identified set   the spread of admissible rotations, which does not
*                    shrink with T (Arias, Rubio-Ramirez & Waggoner 2018)
* The note under the plot says which one it is, because reading a set as a
* confidence interval is the standard misreading of sign-restricted IRFs.
*
* Step -> source map
*   line + shaded band, one panel per response   <- plot_irfs.m
*   band label distinguishing set from interval  <- irf.R sign-restriction docs
* ---------------------------------------------------------------------------
program define _gvar_irf_graph
    version 14.0
    args R step nr rlab slab gname cumul byopt haveband RL RU bandkind level

    if ("`gname'" == "") local gname gvar_irf
    if ("`haveband'" == "") local haveband 0

    _gvar_palette
    local reg  "`r(region)'"
    local c1   "`r(c1)'"
    local bnd  "`r(band)'"
    local zero "`r(zero)'"

    * The note has to name the band, otherwise the shaded region is
    * uninterpretable: the same picture means two different things.
    local bnote ""
    if (`haveband') {
        if ("`bandkind'" == "identified set") {
            local bnote "shaded: identified set over admissible rotations -- not a confidence interval"
        }
        else {
            local bnote "shaded: `level'% bootstrap confidence band"
        }
    }

    preserve
    clear
    qui set obs `=`step'+1'
    qui gen int horizon = _n - 1
    forvalues c = 1/`nr' {
        qui gen double y`c' = .
        qui gen double lo`c' = .
        qui gen double hi`c' = .
        forvalues h = 1/`=`step'+1' {
            qui replace y`c' = `R'[`h', `c'] in `h'
            if (`haveband') {
                qui replace lo`c' = `RL'[`h', `c'] in `h'
                qui replace hi`c' = `RU'[`h', `c'] in `h'
            }
        }
        local l : word `c' of `rlab'
        label variable y`c' "`l'"
    }

    local ttl "Response to a shock to `slab'"
    if ("`cumul'" != "") local ttl "Cumulated response to a shock to `slab'"

    if (`nr' == 1) {
        local l1 : word 1 of `rlab'
        local bplot ""
        if (`haveband') {
            local bplot "(rarea lo1 hi1 horizon, fcolor("`bnd'") fintensity(70) lcolor("`bnd'") lwidth(none))"
        }
        twoway `bplot' (line y1 horizon, lcolor("`c1'") lwidth(medthick)) ///
            , `reg' ///
              yline(0, lcolor("`zero'") lpattern(dash) lwidth(thin)) ///
              ylabel(, angle(0) labsize(small) grid glcolor(gs15)) ///
              xlabel(0(4)`step', labsize(small)) ///
              ytitle("`l1'", size(small)) ///
              xtitle("horizon (periods)", size(small)) ///
              title("`ttl'", size(medium) color(black)) ///
              note("`bnote'", size(vsmall)) ///
              name(`gname', replace) legend(off)
    }
    else {
        * reshape long so -by()- gives one small multiple per response.  The
        * band stubs travel with y: reshaping y alone would leave lo/hi as
        * wide columns and silently plot response 1's band on every panel.
        qui gen long _id = _n
        if (`haveband') {
            qui reshape long y lo hi, i(_id) j(_which)
        }
        else {
            qui reshape long y, i(_id) j(_which)
        }
        qui gen str32 _resp = ""
        forvalues c = 1/`nr' {
            local l : word `c' of `rlab'
            qui replace _resp = "`l'" if _which == `c'
        }
        qui encode _resp, gen(_respn)

        local bplot ""
        if (`haveband') {
            local bplot "(rarea lo hi horizon, fcolor("`bnd'") fintensity(70) lcolor("`bnd'") lwidth(none))"
        }
        twoway `bplot' (line y horizon, lcolor("`c1'") lwidth(medthick)) ///
            , `reg' ///
              by(_respn, `byopt' note("`bnote'", size(vsmall)) ///
                 title("`ttl'", size(medium) color(black)) ///
                 graphregion(color(white))) ///
              yline(0, lcolor("`zero'") lpattern(dash) lwidth(thin)) ///
              ylabel(, angle(0) labsize(vsmall) grid glcolor(gs15)) ///
              xlabel(0(8)`step', labsize(vsmall)) ///
              ytitle("response", size(small)) ///
              xtitle("horizon (periods)", size(small)) ///
              subtitle(, size(small) color(black) fcolor(white) ///
                       lcolor(gs12)) ///
              name(`gname', replace) legend(off)
    }
    restore
end


* ---------------------------------------------------------------------------
* Parse sign / zero restrictions into the flat table gvar_signcubes expects.
*
* Two ways in, both producing the same five columns:
*     1 shock position in x(t)
*     2 restricted variable position in x(t)
*     3 +1 for ">", -1 for "<", 0 for a zero restriction
*     4 horizon, 1 = impact
*     5 probability of imposition
*
* signs()        every restriction applies to the single shock in shock():
*                    signs("usa:y< usa:Dp< usa:r> euro:y<@1/4")
*                A trailing @h or @h1/h2 gives the horizon(s); the default is
*                horizon 1, the impact period.  Use =0 for an exact zero, and
*                %p for a probability, as in usa:y<%0.8.
*
* restrictions() a dataset, for identifying several shocks at once.  It must
*                hold shock, restriction and sign; horizon and prob are
*                optional and default to 1.
*
* This mirrors BGVAR's get_shockinfo / add_shockinfo, whose data.frame carries
* exactly these columns.
* ---------------------------------------------------------------------------
program define _gvar_signspec, rclass
    version 14.0
    args spos signs rfile

    tempname R
    local nrow 0
    local rows ""

    * ---- the inline form ---------------------------------------------------
    if (`"`signs'"' != "") {
        foreach tk of local signs {
            _gvar_signtok "`tk'"
            local vp = r(vpos)
            local sn = r(sn)
            local pb = r(prob)
            local h1 = r(h1)
            local h2 = r(h2)
            forvalues h = `h1'/`h2' {
                local rows "`rows' `spos'|`vp'|`sn'|`h'|`pb'"
                local ++nrow
            }
        }
    }

    * ---- the dataset form --------------------------------------------------
    if (`"`rfile'"' != "") {
        preserve
        capture use `"`rfile'"', clear
        if (_rc) {
            restore
            di as err "cannot read the restriction file {bf:`rfile'}"
            exit 601
        }
        foreach v in shock restriction sign {
            capture confirm variable `v'
            if (_rc) {
                restore
                di as err "the restriction file must contain {bf:`v'}"
                di as err "columns: shock restriction sign [horizon] [prob]"
                exit 111
            }
        }
        capture confirm variable horizon
        local hashor = (_rc == 0)
        capture confirm variable prob
        local hasprob = (_rc == 0)

        quietly count
        local nf = r(N)
        if (`nf' == 0) {
            restore
            di as err "the restriction file is empty"
            exit 2000
        }
        forvalues q = 1/`nf' {
            local sk = shock[`q']
            local rv = restriction[`q']
            local op = sign[`q']
            local hh 1
            if (`hashor')  local hh = horizon[`q']
            local pp 1
            if (`hasprob') local pp = prob[`q']

            _gvar_xsel "`sk'"
            if (r(n) != 1) {
                restore
                di as err "row `q': shock {bf:`sk'} must name exactly one element of x(t)"
                exit 198
            }
            local sp "`r(pos)'"
            _gvar_xsel "`rv'"
            if (r(n) != 1) {
                restore
                di as err "row `q': restriction {bf:`rv'} must name exactly one element of x(t)"
                exit 198
            }
            local vp "`r(pos)'"

            local sn .
            if ("`op'" == ">")      local sn 1
            else if ("`op'" == "<") local sn -1
            else if ("`op'" == "0") local sn 0
            else {
                restore
                di as err "row `q': sign must be {bf:>}, {bf:<} or {bf:0}, not {bf:`op'}"
                exit 198
            }
            if (`hh' < 1) {
                restore
                di as err "row `q': horizon must be at least 1 (1 = impact)"
                exit 198
            }
            if (`pp' <= 0 | `pp' > 1) {
                restore
                di as err "row `q': prob must lie in (0, 1]"
                exit 198
            }
            local rows "`rows' `sp'|`vp'|`sn'|`hh'|`pp'"
            local ++nrow
        }
        restore
    }

    if (`nrow' == 0) {
        di as err "no restrictions were parsed"
        exit 198
    }

    * Horizon 1 must be represented.  The own-shock normalisation of irf.R
    * writes a +1 into the impact block, and there is nowhere to write it if
    * no restriction is at horizon 1.
    local has1 0
    foreach rw of local rows {
        local pieces : subinstr local rw "|" " ", all
        local h4 : word 4 of `pieces'
        if (`h4' == 1) local has1 1
    }
    if (`has1' == 0) {
        di as err "at least one restriction must be at horizon 1"
        di as err "The shock is normalised to move its own variable up on"
        di as err "impact, which is itself a horizon-1 restriction; with no"
        di as err "horizon-1 row there is no impact block to normalise in."
        exit 198
    }

    matrix `R' = J(`nrow', 5, .)
    local q 0
    foreach rw of local rows {
        local ++q
        local pieces : subinstr local rw "|" " ", all
        forvalues c = 1/5 {
            local pc : word `c' of `pieces'
            matrix `R'[`q', `c'] = `pc'
        }
    }

    * The restriction cubes are matrices, so two restrictions on the same
    * (shock, variable, horizon) cell overwrite rather than conflict: the last
    * one silently wins.  That is what irf.R does, and it is kept, but a
    * contradiction that vanishes without a word is worth a line of warning.
    local ndup 0
    forvalues a = 1/`nrow' {
        forvalues b = `=`a'+1'/`nrow' {
            if (`R'[`a',1] == `R'[`b',1] & `R'[`a',2] == `R'[`b',2] ///
                & `R'[`a',4] == `R'[`b',4]) {
                local ++ndup
                if (`ndup' == 1) {
                    di as text "  {bf:note}: the same cell is restricted" ///
                               " more than once."
                    di as text "  Later restrictions overwrite earlier ones," ///
                               " so only the last"
                    di as text "  one on each (shock, variable, horizon)" ///
                               " has any effect."
                }
                if (`R'[`a',3] != `R'[`b',3]) {
                    mata: st_local("lb", gvar_getxcname()[`=`R'[`b',2]'] ///
                                   + ":" + gvar_getxname()[`=`R'[`b',2]'])
                    di as text "    {bf:`lb'} at horizon " ///
                       as result `=`R'[`b',4]' as text ": the earlier" ///
                       " restriction is discarded."
                }
            }
        }
    }

    return matrix res = `R'
    return scalar n = `nrow'
    return scalar duplicates = `ndup'
end

* ---------------------------------------------------------------------------
* One inline restriction token: variable, operator, optional @horizon(s) and
* optional %probability.  Order is  var OP [@h|@h1/h2] [%p].
* ---------------------------------------------------------------------------
program define _gvar_signtok, rclass
    version 14.0
    args tk

    local pb 1
    local pc = strpos("`tk'", "%")
    if (`pc' > 0) {
        local ps = substr("`tk'", `pc' + 1, .)
        local tk = substr("`tk'", 1, `pc' - 1)
        local pb = real("`ps'")
        if (`pb' >= . | `pb' <= 0 | `pb' > 1) {
            di as err "bad probability in {bf:%`ps'}: it must lie in (0, 1]"
            exit 198
        }
    }

    local h1 1
    local h2 1
    local at = strpos("`tk'", "@")
    if (`at' > 0) {
        local hs = substr("`tk'", `at' + 1, .)
        local tk = substr("`tk'", 1, `at' - 1)
        local sl = strpos("`hs'", "/")
        if (`sl' > 0) {
            local h1 = real(substr("`hs'", 1, `sl' - 1))
            local h2 = real(substr("`hs'", `sl' + 1, .))
        }
        else {
            local h1 = real("`hs'")
            local h2 = `h1'
        }
        if (`h1' >= . | `h2' >= . | `h1' < 1 | `h2' < `h1') {
            di as err "bad horizon in {bf:@`hs'}: use {bf:@h} or {bf:@h1/h2}"
            di as err "with 1 <= h1 <= h2.  Horizon 1 is the impact period."
            exit 198
        }
    }

    local sn .
    local vv ""
    if (substr("`tk'", -2, 2) == "=0") {
        local sn 0
        local vv = substr("`tk'", 1, length("`tk'") - 2)
    }
    else if (substr("`tk'", -1, 1) == ">") {
        local sn 1
        local vv = substr("`tk'", 1, length("`tk'") - 1)
    }
    else if (substr("`tk'", -1, 1) == "<") {
        local sn -1
        local vv = substr("`tk'", 1, length("`tk'") - 1)
    }
    else {
        di as err "restriction {bf:`tk'} must end in {bf:>}, {bf:<} or {bf:=0}"
        di as err "for example {bf:usa:y<}, {bf:usa:r>@1/4}, {bf:usa:eq=0}"
        exit 198
    }

    _gvar_xsel "`vv'"
    if (r(n) != 1) {
        di as err "{bf:`vv'} must name exactly one element of x(t)"
        exit 198
    }
    return scalar vpos = `r(pos)'
    return scalar sn   = `sn'
    return scalar prob = `pb'
    return scalar h1   = `h1'
    return scalar h2   = `h2'
end
