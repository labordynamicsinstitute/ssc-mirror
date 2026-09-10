*! _finegray_resolve_baseline Version 1.3.2  2026/09/08
*! Resolve the baseline cumulative subhazard for post-estimation
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: internal (fills a caller-named H0 variable)

* Fills `h0' with H0(t) at each observation's `tvar', over `touse'.
*
* WHY THIS EXISTS.  e(basehaz) is opt-in: it holds one row per distinct
* cause-event time (K ~ n/2), and creating a Stata matrix that tall is O(K^2) --
* Stata builds one dimension name per row, and the cost is per name, not per
* element.  That single matrix was the whole of finegray's superlinearity.
*
* So the curve has to come from somewhere else, and there are exactly three
* places it can come from.  This helper is the one place that knows the order,
* because getting it wrong in one consumer and right in another is how a package
* ends up predicting from the wrong fit's baseline at rc 0.
*
*   1. e(basehaz), when the user asked for it.  Reading an e() matrix is free;
*      it is only CREATING one that is quadratic.
*   2. The Mata cache (_finegray_bh_store).  A Mata matrix has no dimension-name
*      stripe -- it is just numbers -- so the same curve costs nothing there.
*      This is what makes `predict, cif' work on NEW data: the user drops the
*      estimation sample, types a fresh covariate profile, and predicts.  There
*      is then nothing to rebuild FROM, and the old code only survived because it
*      read a Stata matrix out of e(), which outlives `drop _all'.
*      The cache is keyed by e(bh_key) and refuses a mismatch, so a curve from a
*      PREVIOUS fit can never answer for this one.
*   3. Rebuild it in Mata from the estimation data.  Exact, not approximate: it
*      re-runs the fit's own _finegray_basehazard.  Only possible while the
*      estimation sample is still in memory -- and, because it is the only path
*      that READS those data, the only path that verifies them
*      (_finegray_check_data) and rebuilds dropped _fg_* design columns.  Paths 1
*      and 2 must not do either: `predict, cif' on new data travels path 2.
*
* If none of the three is available -- the data are gone AND the cache was wiped
* by `discard' or `mata clear' -- this errors.  It does not guess.
*
* BASELINE STRATA.  Under bstrata() the curve is not one step function but K of
* them, and the caller must say which stratum each evaluation row belongs to:
* bsvar() names a variable holding that row's bstrata() VALUE.  All three paths
* carry it, because all three can be reached on a stratified fit and answering
* from the wrong stratum's baseline is a wrong CIF at rc 0.  A fit made without
* bstrata() passes bsvar("") and every lookup below is unchanged.

program define _finegray_resolve_baseline
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    capture noisily {

        * All-lowercase option names: no abbreviations, full names required.  A
        * capitalised abbreviation run does not survive a name whose second
        * character is a digit -- `T0VAR' parsed to something that then rejected
        * t0var() as "option not allowed".  This is an internal helper; nobody
        * types these.
        syntax , tvar(name) h0(name) touse(name) hasbh(integer) ///
            [t0var(string) bsvar(string) tsplit(string) cutmat(string) ///
            tvcpos(string)]

        * PIECEWISE beta(t).  Two things change under tvc(), and both have to
        * travel down whichever of the three paths is taken:
        *
        *   tvcpos()/tsplit()  the REBUILD path re-runs the fit's own baseline
        *                      scan, and the piecewise scan is a different scan.
        *                      Rebuilding with the proportional one would return
        *                      a different curve for the same fit, at rc 0.
        *   cutmat()           every piecewise CIF consumer needs Lambda_0 AT the
        *                      boundaries as well as at its own times, and both
        *                      must come from the SAME curve.  Asking a second,
        *                      independently resolved baseline for the boundary
        *                      values is how a CIF mixes two curves.
        if `"`tvcpos'"' != "" & `"`tsplit'"' == "" {
            display as error "internal error: tvcpos() without tsplit()"
            exit 198
        }

        * 1. the posted matrix
        if `hasbh' {
            mata: _finegray_step_lookup("e(basehaz)", "`tvar'", "`h0'", ///
                "`touse'", "`bsvar'", "`tsplit'", "`cutmat'")
        }
        else {
            * 2. the Mata cache, but only if it belongs to THIS fit
            local _key `"`e(bh_key)'"'
            local _have = 0
            if `"`_key'"' != "" {
                mata: _finegray_bh_have("`_key'", "_have")
            }

            if `_have' {
                mata: _finegray_step_lookup_cached("`_key'", "`tvar'", "`h0'", ///
                    "`touse'", "`bsvar'", "`tsplit'", "`cutmat'")
            }
            else {
                * 3. rebuild from the estimation data -- if they are still here
                local _rebuildable = 1
                capture confirm variable _t
                if _rc local _rebuildable = 0
                if `_rebuildable' {
                    quietly count if e(sample)
                    if r(N) == 0 local _rebuildable = 0
                }

                if !`_rebuildable' {
                    display as error "baseline cumulative subhazard not available"
                    display as error "the estimation data are no longer in memory and the cached"
                    display as error "baseline was cleared (by {bf:discard} or {bf:mata clear})"
                    display as error "refit {bf:finegray}, or refit with {bf:basehaz} so the"
                    display as error "baseline is posted in {bf:e(basehaz)} and survives both"
                    exit 459
                }

                * ONLY this branch reads the estimation data, so this is the only
                * branch that has to verify them.  Path 1 reads a posted matrix
                * and path 2 a Mata cache keyed to e(bh_key); both are immune to
                * what the data now hold, and `predict, cif' on NEW data (the
                * documented FG-B04 workflow) travels path 2 -- calling this any
                * higher up would break it.
                *
                * Without the check, a _fg_* design column that is still present
                * but no longer equals what the fit-time expansion implies is
                * read here BY NAME and answers at rc 0: flipping _fg_pelnode_1
                * moved the mean CIF from 0.2324819505 to 0.1150179144, and the
                * mean baseline H0 from 0.2832285959 to 0.1256285380.  Warm-cache
                * calls returned the right number for the same data, so the
                * answer depended on session history.  finegray_cif and
                * finegray_phtest already call this helper unconditionally.
                _finegray_check_data

                tempvar _es
                quietly gen byte `_es' = e(sample)

                * Which columns to hand the engine.  e(designvars) names the
                * package-owned _fg_* design columns, and dropping those is a
                * DOCUMENTED, supported operation (finegray.sthlp: "finegray_predict
                * rebuilds design columns on demand") -- the score path does
                * rebuild them, from e(fvsemantic); this path used to pass the
                * stored names through unverified and died inside st_data() with a
                * raw Mata traceback (r(3598)).  `estimates store' / refit /
                * `estimates restore' is the ordinary workflow that triggers it,
                * because the second fit drops the first fit's _fg_* columns.
                *
                * Rebuild by LEVEL VALUE from the fit-time expansion, never by
                * re-running fvexpand against the current data -- see
                * _finegray_fv_design's header for why the count check cannot
                * catch that.  The rebuilt columns are tempvars over e(sample):
                * this helper is read-only from the caller's point of view, so it
                * must not materialise _fg_* names it would then have to clean up.
                local _zvars "`e(designvars)'"
                local _need_rebuild = 0
                foreach _cv of local _zvars {
                    capture confirm numeric variable `_cv'
                    if _rc {
                        local _need_rebuild = 1
                        continue, break
                    }
                }
                if `_need_rebuild' {
                    if `"`e(fvvarlist)'"' == "" {
                        display as error "covariate(s) from the fitted model are no longer in the data"
                        display as error "the baseline cumulative subhazard is rebuilt from the"
                        display as error "estimation data, which requires every covariate finegray"
                        display as error "was fit on; restore them, refit {bf:finegray}, or refit"
                        display as error "with {bf:basehaz} so the baseline survives in {bf:e(basehaz)}"
                        exit 459
                    }
                    _finegray_fv_design, caller("this post-estimation command")
                    * Copy the whole r() payload out BEFORE anything else touches r().
                    local _fvk = r(k)
                    forvalues _j = 1/`_fvk' {
                        local _fvexpr`_j' `"`r(expr`_j')'"'
                    }
                    local _nz : word count `_zvars'
                    if `_fvk' != `_nz' {
                        display as error "reconstructed FV design does not match the fitted model"
                        display as error "(`_fvk' non-base terms in e(fvsemantic), `_nz' in e(designvars))"
                        exit 198
                    }
                    local _rbvars ""
                    forvalues _j = 1/`_fvk' {
                        tempvar _fgrb`_j'
                        * Built only over e(sample): outside it a `(race == 2)'
                        * indicator reads a missing race as 0 and quietly assigns
                        * the base category.
                        quietly gen double `_fgrb`_j'' = `_fvexpr`_j'' if `_es'
                        local _rbvars "`_rbvars' `_fgrb`_j''"
                    }
                    local _zvars : list retokenize _rbvars
                }

                * Rebuild the weight design from the STORED specification, never
                * from a variable left behind in the data: the fit's design must be
                * reproduced exactly or the baseline is computed under different
                * weights than the model was.
                local _byg_mata "`e(strata)'"
                local _byg_nvar : word count `e(strata)'
                if `_byg_nvar' > 1 {
                    tempvar _byg_grp
                    _finegray_weight_groups, strata(`e(strata)') ///
                        bygname(`_byg_grp') touse(`_es')
                    local _byg_mata "`_byg_grp'"
                }
                local _tg_mata ""
                if `"`e(truncstrata)'"' != "" {
                    tempvar _tg_grp
                    _finegray_weight_groups, truncstrata(`e(truncstrata)') ///
                        tgname(`_tg_grp') touse(`_es')
                    local _tg_mata "`_tg_grp'"
                }

                if "`t0var'" == "" local t0var "_t0"

                * The rebuild re-runs the fit's own _finegray_basehazard, so it
                * needs the fit's baseline strata too -- without them it would
                * return the POOLED curve for a stratified fit, at rc 0.  The
                * fit-time variable is named in e(bstrata) and is covered by
                * e(datasignaturevars), which _finegray_check_data just verified.
                local _bs_est `"`e(bstrata)'"'
                if `"`_bs_est'"' != "" {
                    capture confirm numeric variable `_bs_est'
                    if _rc {
                        display as error "baseline strata variable `_bs_est' not found"
                        display as error "the baseline cumulative subhazard is rebuilt from the"
                        display as error "estimation data, which requires the {bf:bstrata()}"
                        display as error "variable finegray was fit on; restore it, refit"
                        display as error "{bf:finegray}, or refit with {bf:basehaz} so the"
                        display as error "baseline survives in {bf:e(basehaz)}"
                        exit 111
                    }
                }

            * Design weights.  A weighted fit's baseline and influence function are
            * different curves from the unweighted ones, so the weight column is
            * rebuilt from e(wexp) (the variables it names are in the estimation
            * signature, verified above) and handed to every Mata entry point below.
            *   _fg_wmata  the rebuilt column, "" on an unweighted fit
            *   _fg_wtype  0 none, 1 pweight, 2 fweight
            local _fg_wmata ""
            local _fg_wtype = 0
            if `"`e(wtype)'"' != "" {
                tempvar _fg_wv
                _finegray_weight_var, wname(`_fg_wv') touse(`_es')
                local _fg_wmata "`_fg_wv'"
                local _fg_wtype = r(wtype)
            }

                mata: _finegray_step_lookup_direct("`_zvars'", ///
                    "`e(compete)'", `=e(cause)', `=e(censvalue)', ///
                    "`_byg_mata'", "`_tg_mata'", "`_es'", "`t0var'", ///
                    "`tvar'", "`h0'", "`touse'", "`_bs_est'", ///
                    "`tvcpos'", "`tsplit'", "`cutmat'", ///
                    "`_fg_wmata'", `_fg_wtype')
            }
        }
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
