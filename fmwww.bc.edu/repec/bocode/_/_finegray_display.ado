*! _finegray_display Version 1.3.2  2026/09/08
*! Render the finegray header, coefficient table and fit-time notes from e()
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: internal (nclass)

/*
Syntax:
  _finegray_display [, level(#) noshr coeflegend]

WHY THIS EXISTS.  finegray's output is produced in exactly one place so that
`finegray' typed with no varlist -- the replay every Stata e-class estimator
supports -- reproduces the fit-time display rather than a second, drifting
copy of it.  Everything below is read from e(); nothing is read from the data
except the value labels used to spell the `Reference:' lines, and those are
guarded so a dropped factor variable degrades to the bare level number instead
of erroring on a redisplay.

That constraint is what forced e(N_delayed), e(compete_values) and
e(N_G_trunc) into the return list: each is a fit-time quantity the header
reports and no consumer could recompute after the fact.
*/

capture program drop _finegray_display
program define _finegray_display
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off

    capture noisily {

    * level() is parsed as a string, not cilevel: cilevel auto-fills an omitted
    * option with c(level), which would make a replay silently redisplay at the
    * SESSION level rather than at the level the fit was reported with.
    syntax [, Level(string) noSHR COEFLegend]

    * coeflegend replaces the statistics with the _b[] names that index them,
    * so neither a confidence level nor the SHR/log-SHR scale has anything to
    * apply to.  Stata's own estimators refuse level() with coeflegend; noshr
    * is refused for the same reason rather than accepted with no effect.
    * (Through the 1.3.0 pre-release builds `finegray, coeflegend' was refused r(198), so the
    * name of a tvc or factor design column could not be read off the table.)
    if "`coeflegend'" != "" {
        if `"`level'"' != "" {
            display as error "level() may not be combined with coeflegend"
            exit 198
        }
        if "`shr'" == "noshr" {
            display as error "noshr may not be combined with coeflegend"
            display as error "the legend table reports coefficient names, not a coefficient scale"
            exit 198
        }
    }

    if `"`e(cmd)'"' != "finegray" {
        display as error "last estimates not found"
        display as error "you must run {bf:finegray} before displaying its results"
        exit 301
    }

    if `"`level'"' == "" {
        local level = e(level)
        if `level' >= . local level = c(level)
    }
    else {
        * One bound, one message, in all four places -- Stata's own cilevel
        * rule, delegated so it cannot drift from `finegray, level()' again.
        _finegray_check_level, level(`level')
    }

    * A fit from an older release has no lt_weight; treat it as right censoring.
    local _lt `"`e(lt_weight)'"'
    local _has_lt = (`"`_lt'"' != "" & `"`_lt'"' != "right_censoring")

    * =====================================================================
    * HEADER
    * =====================================================================
    display as text "Fine-Gray competing risks regression"
    display as text ""

    * Name the competing VALUES, not just the compete() variable.  Without them
    * a miscoded event code -- 2, 3 and a stray 9 all pooled together -- is
    * invisible in the output and the reader cannot check what was pooled.
    local _cvals `"`e(compete_values)'"'
    if `"`_cvals'"' != "" {
        * A compete() variable is an event code, so this list is normally one or
        * two values.  Cap it anyway: a miscoded variable with dozens of distinct
        * codes is precisely what this line exists to surface, and printing all
        * of them would bury the header under one unreadable row.
        local _ncv : word count `_cvals'
        if `_ncv' > 8 {
            local _cvshort ""
            forvalues _i = 1/8 {
                local _cvshort `"`_cvshort' `: word `_i' of `_cvals''"'
            }
            local _cvshort : list retokenize _cvshort
            local _cvals `"`_cvshort' ... (`_ncv' values)"'
        }
        display as text "Competing events:" _col(24) as result ///
            "`e(compete)' (values: `_cvals')"
    }
    else {
        display as text "Competing events:" _col(24) as result "`e(compete)'"
    }
    display as text "Cause of interest:" _col(24) as result e(cause)
    display as text "Censoring value:" _col(24) as result e(censvalue)
    if `"`e(strata)'"' != "" {
        display as text "Censoring strata:" _col(24) as result "`e(strata)'"
    }

    * Baseline strata.  Same reason the delayed-entry line below exists: a fit
    * with a free baseline per stratum and a pooled-baseline fit are different
    * estimators, and before this they printed identical headers.  The label
    * says "baseline" because two other options in this command are also called
    * strata and stratify something else entirely (see help finegray).
    if `"`e(bstrata)'"' != "" {
        display as text "Baseline strata:" _col(24) as result "`e(bstrata)'"
    }

    * Time-varying effects.  A proportional fit and a piecewise beta(t) fit are
    * different models, and the coefficient table alone shows only that some
    * rows sit under equation names -- which a reader who did not type the
    * command has no way to decode.  Name the covariates and the boundaries.
    if `"`e(tvc)'"' != "" {
        display as text "Time-varying effects:" _col(24) as result "`e(tvc)'"
        display as text "Interval boundaries:" _col(24) as result "`e(tsplit)'"
    }

    * Delayed entry.  A ZZF Weight-1 fit and an ordinary right-censored fit used
    * to print identical headers, so two materially different estimators were
    * distinguishable only by running `ereturn list'.
    if `_has_lt' {
        local _ltxt "`_lt'"
        if "`_lt'" == "zzf1_geskus"     local _ltxt "ZZF Weight 1 (Geskus product-limit form)"
        if "`_lt'" == "zzf1_stratified" local _ltxt "ZZF Weight 1 (stratified)"
        if "`_lt'" == "zzf1_factorized" local _ltxt "ZZF Weight 1 (factorized A=G*H extension)"
        display as text "Delayed entry:" _col(24) as result "`_ltxt'"
        if `"`e(truncstrata)'"' != "" {
            display as text "Entry strata:" _col(24) as result "`e(truncstrata)'"
        }
    }

    * Which variance is in e(V).  nuisance and norobust change the inference and
    * nothing else in the printed output said so.
    *
    * The `oim' test comes first, which is truthful only because
    * `nuisance' + `norobust' is refused r(198) at fit time (finegray.ado,
    * "nuisance is not allowed with norobust"): there is no fit whose
    * e(vce) is oim and whose e(vce_meat) is nuisance_adjusted, so the order
    * cannot hide a nuisance-adjusted variance behind the model-based label.
    * If that refusal is ever relaxed, this branch order must be revisited.
    local _vmeat `"`e(vce_meat)'"'
    local _vtxt ""
    if `"`e(vce)'"' == "oim"                   local _vtxt "model-based (inverse information)"
    else if `"`_vmeat'"' == "nuisance_adjusted" {
        * cluster() and nuisance are independent: the meat is nuisance-adjusted
        * AND summed within cluster, so naming only one of them understated the
        * inference actually in e(V).
        if `"`e(vce)'"' == "cluster" local _vtxt "cluster-robust, nuisance-adjusted sandwich"
        else                         local _vtxt "nuisance-adjusted sandwich"
    }
    else if `"`e(vce)'"' == "cluster"           local _vtxt "cluster-robust sandwich"
    else if `"`e(vce)'"' == "robust"            local _vtxt "robust sandwich (fixed weights)"
    if `"`_vtxt'"' != "" {
        display as text "Variance:" _col(24) as result "`_vtxt'"
    }

    * Design weights.  A weighted and an unweighted fit print the same table
    * otherwise, and e(N) under fweights is the REPLICATED count, so the
    * reader has to be told which they are looking at.
    if `"`e(wtype)'"' != "" {
        display as text "Weights:" _col(24) as result "`e(wtype)' `e(wexp)'"
    }

    display as text ""
    * e(N) is the number of risk-set units the engine actually fitted, which is
    * the SUBJECT count: finegray.ado recomputes N after the multiple-record
    * reduction and prints "(note: R records reduced to N subjects)" a screen
    * earlier.  Labelling it "No. of obs" directly under that note contradicted
    * the note.  stcrreg prints "No. of subjects" for the same quantity.
    display as text "No. of subjects" _col(24) "= " as result %10.0fc e(N)
    display as text "No. of cause events" _col(24) "= " as result %10.0fc e(N_fail)
    display as text "No. competing events" _col(24) "= " as result %10.0fc e(N_compete)
    display as text "No. censored" _col(24) "= " as result %10.0fc e(N_cens)
    if `_has_lt' & e(N_delayed) < . {
        display as text "No. delayed entry" _col(24) "= " ///
            as result %10.0fc e(N_delayed)
    }
    * How many baselines were actually fitted.  "bstrata(centre)" and "four
    * centres" are different facts, and only the second one tells the reader
    * how much data each baseline rests on -- which is the whole small-stratum
    * caveat in help finegray.
    if `"`e(bstrata)'"' != "" & e(k_bstrata) < . {
        display as text "No. baseline strata" _col(24) "= " ///
            as result %10.0fc e(k_bstrata)
    }
    if `"`e(tvc)'"' != "" & e(n_intervals) < . {
        display as text "No. of intervals" _col(24) "= " ///
            as result %10.0fc e(n_intervals)
    }
    if `"`e(clustvar)'"' != "" {
        display as text "No. of clusters" _col(24) "= " ///
            as result %10.0fc e(N_clust)
    }
    display as text ""

    if e(ll) < . {
        display as text "Log pseudo-likelihood" _col(24) "= " ///
            as result %12.4f e(ll)
    }
    if e(chi2) < . {
        display as text "Wald chi2(" as result e(df_m) ///
            as text ")" _col(24) "= " as result %10.2f e(chi2)
        display as text "Prob > chi2" _col(24) "= " as result %10.4f e(p)
    }
    display as text ""

    * The censoring-survivor floor.  Reported HERE, not from inside the Mata KM
    * sweep, where it was the first line of output -- unexplained jargon above
    * even the command's own title.  Singular and plural are both spelled out:
    * "1 observations" was the printf's own wording.
    local _ntr = e(N_G_trunc)
    if `_ntr' > 0 & `_ntr' < . {
        local _obsword "observations"
        if `_ntr' == 1 local _obsword "observation"
        * Kept short deliberately.  Stata wraps display output at linesize, and
        * test Z27 parses the count out of this line -- a message that wrapped
        * between "for" and the number would make that guard unfalsifiable.
        display as text "note: censoring survivor G(t) hit its 1e-10 floor for " ///
            "`_ntr' `_obsword'"
        display as text "(the inverse-probability weights there rest on almost no"
        display as text "censoring information)"
        display as text ""
    }

    * Warn BEFORE the table, as stcrreg does. Printed after the coefficients it
    * discredits, this is trivially scrolled past -- and the coefficients are
    * the thing the reader takes away.
    if e(converged) == 0 {
        display as error "convergence not achieved"
        display as text "(the coefficients below are the last iterate, not a " ///
            "solution; post-estimation commands will refuse them)"
        display as text ""
    }

    * Weight-sensitivity warnings, for the same reason: before the coefficients
    * they discredit, not after.  These are not errors -- the fit is reported --
    * but a near-zero A or an enormous weight means a handful of subjects carry
    * the estimate, and the reader must see that next to the numbers.
    if `_has_lt' {
        local _fg_npw = e(N_prob_warn)
        local _fg_nww = e(N_weight_warn)
        local _fg_mxw : display %9.3e e(max_lt_weight)
        local _fg_mxw = trim("`_fg_mxw'")

        if `_fg_npw' > 0 & `_fg_npw' < . {
            display as error "warning: the combined weight A(t) falls below 1e-10 in `_fg_npw' consulted cells"
            display as text "(near-zero censoring or entry probability: the weights there are" ///
                " not estimable and the fit leans on very few subjects)"
        }
        if `_fg_nww' > 0 & `_fg_nww' < . {
            display as error "warning: `_fg_nww' retained weights exceed 1e6 (largest `_fg_mxw')"
            display as text "(a few subjects dominate the risk sets; treat these coefficients" ///
                " as unstable)"
        }
        local _fg_ws "`e(weight_warn_strata)'"
        if "`_fg_ws'" != "" {
            display as text "(affected joint weight strata: `_fg_ws')"
            display as text ""
        }
    }

    * Factorized-extension note.  When strata() and truncstrata() name different
    * groupings the weight is the package's factorized A=G*H extension, not the
    * ZZF stratified construction.  The help file documents this, but the fit
    * itself otherwise reports only e(lt_weight)=zzf1_factorized; say at fit time
    * that the estimator differs from ZZF and what extra structure it requires.
    if "`_lt'" == "zzf1_factorized" {
        display as text ""
        display as text "note: the censoring weight G and entry weight H use different groupings,"
        display as text "so finegray uses the factorized A=G*H extension -- a package extension,"
        display as text "requiring the censoring mechanism to be homogeneous across omitted entry"
        display as text "groups and vice versa. See Left truncation in {help finegray}."
        display as text "e(lt_weight)=zzf1_factorized."
    }

    * mi note.  A fit on mi data leaves no post-estimation support behind (its
    * design columns and entry column were tempvars), so finegray_predict,
    * finegray_cif and finegray_phtest refuse it.  Say so at fit time AND on
    * replay -- e() is all this program reads, so both print the same line --
    * rather than leaving the user to discover it from a later refusal.
    * Under `mi estimate, cmdok:' the per-imputation fits run quietly, so this
    * surfaces only where it is actionable: a finegray typed on mi data.
    if `"`e(postest)'"' == "unavailable_mi" {
        display as text ""
        display as text "note: fitted on multiple-imputation data; the coefficients and variance"
        display as text "are ordinary M-estimator output and pool under Rubin's rules, but"
        display as text "finegray_predict, finegray_cif and finegray_phtest are unavailable"
        display as text "on this fit. See Multiple imputation in {help finegray##mi:help finegray}."
        display as text "e(postest)=unavailable_mi."
    }

    * =====================================================================
    * COEFFICIENT TABLE
    * =====================================================================
    if "`coeflegend'" != "" {
        ereturn display, coeflegend
    }
    else if "`shr'" == "noshr" {
        ereturn display, level(`level')
    }
    else {
        ereturn display, eform(SHR) level(`level')
    }

    * =====================================================================
    * INTERVAL LEGEND
    * =====================================================================
    * The equation names in the table are tvc1, tvc2, ... because `<' and `='
    * break [eqname] parsing and would make `test [tvc1]x = [tvc2]x' -- the Wald
    * test of "is this effect constant?" -- fail r(132).  The bounds they stand
    * for therefore have to be printed, or the table is undecodable from its own
    * output.  Half-open at the LEFT: an event exactly at a boundary belongs to
    * the earlier interval, matching the (t0, t] risk sets the fit is built on.
    if `"`e(tsplit)'"' != "" {
        local _tvcuts `"`e(tsplit)'"'
        local _tvJ = e(n_intervals)
        if `_tvJ' >= . local _tvJ = `: word count `_tvcuts'' + 1
        * Cause events per interval, posted at fit time.  An interval resting on
        * a handful of events is where a piecewise fit reaches a monotone
        * likelihood and prints an enormous but finite subhazard ratio at rc 0;
        * the count is the only thing in the output that shows it.
        local _tvnf `"`e(tsplit_nfail)'"'
        local _tvcz = e(cause)
        display as text ""
        display as text "beta(t) is constant on each interval below; " ///
            "intervals are (lower, upper]:"
        local _tvlo ""
        forvalues _tvj = 1/`_tvJ' {
            if `_tvj' == `_tvJ' local _tvlbl "_t > `_tvlo'"
            else {
                local _tvhi : word `_tvj' of `_tvcuts'
                if `_tvj' == 1 local _tvlbl "_t <= `_tvhi'"
                else           local _tvlbl "`_tvlo' < _t <= `_tvhi'"
            }
            local _tvn : word `_tvj' of `_tvnf'
            if "`_tvn'" != "" {
                local _tvewd "events"
                if `_tvn' == 1 local _tvewd "event"
                display as text "    tvc`_tvj':" _col(14) as result ///
                    "`_tvlbl'" _col(38) as text "(`_tvn' cause `_tvcz' `_tvewd')"
            }
            else {
                display as text "    tvc`_tvj':" _col(14) as result "`_tvlbl'"
            }
            if `_tvj' < `_tvJ' local _tvlo : word `_tvj' of `_tvcuts'
        }
        * The `main' equation exists only when something was left proportional.
        * Explaining an equation the table does not contain reads as a bug in
        * the table rather than a note about it.
        local _tvncov : word count `e(designvars)'
        local _tvntv = e(k_tvc)
        if `_tvntv' >= . local _tvntv = 0
        if `_tvncov' > `_tvntv' {
            display as text "    (main:" _col(14) as result ///
                "covariates whose effect is held proportional)"
        }
        * The warning belongs beside the numbers it discredits, not in the help
        * file.  Five is a round figure, not a theoretical threshold.
        local _tvmin = .
        foreach _tvn of local _tvnf {
            if `_tvn' < `_tvmin' local _tvmin = `_tvn'
        }
        if `_tvmin' < 5 {
            display as error "warning: an interval carries only `_tvmin' cause `_tvcz' event(s)"
            display as text "(its coefficients rest on those events alone; a piecewise fit can"
            display as text "reach a monotone likelihood there and still converge, printing an"
            display as text "enormous but finite subhazard ratio -- use fewer, wider intervals)"
        }
    }

    * The Fine-Gray objective is a PSEUDO-likelihood: its weighted score need not
    * obey the ordinary likelihood information identity, so inverse information
    * does not generally estimate the sampling variance of beta-hat.  norobust
    * is a diagnostic, not a routine inference option -- say so every time.
    if `"`e(vce)'"' == "oim" {
        display as text ""
        display as error "Warning: norobust reports model-based (inverse-information) standard errors."
        display as error "The Fine-Gray weighted score is a pseudo-likelihood score, so the ordinary"
        display as error "likelihood information identity need not hold.  Inverse information omits"
        display as error "the empirical score variability and any estimated-weight contribution."
        display as error "These standard errors are generally too small and their confidence"
        display as error "intervals do not have nominal coverage.  Use the default robust"
        display as error "(sandwich) variance for inference; norobust is provided for comparison"
        display as error "with the naive likelihood only."

        * Under delayed entry this is not a caution, it is a MEASURED defect, and
        * it is far larger than the right-censoring case above.  The weights A(t)
        * are estimated, and their uncertainty is absent from the information
        * matrix; the damage grows with the truncation fraction.
        *
        * qa/validation_finegray_zzf_coverage.do, 1000 replications per arm,
        * known truth, 95% nominal:
        *
        *   truncation    norobust coverage   default (sandwich) coverage
        *        0%          0.956 / 0.949        0.954 / 0.943
        *       37%          0.897 / 0.901        0.941 / 0.951
        *       69%          0.850 / 0.850        0.955 / 0.953
        *
        * The model-based SE runs up to 38% below the true sampling SD at 69%
        * truncation.  Quote the numbers: a user who is told "generally too small"
        * cannot tell whether that means 1% or 30%.
        if `_has_lt' {
            display as error ""
            display as error "This fit has DELAYED ENTRY, where the defect above is measured and severe."
            display as error "The truncation weights are themselves estimated and the information matrix"
            display as error "does not carry their uncertainty.  In this package's coverage study (1000"
            display as error "replications, known truth, nominal 95%) norobust intervals covered only"
            display as error "89% at 37% truncation and 85% at 69% truncation, and the model-based"
            display as error "standard errors ran up to 38% below the true sampling variability.  The"
            display as error "failure gets WORSE as the truncation fraction rises."
            display as error "Do not use norobust for inference on left-truncated data."
        }
    }

    * =====================================================================
    * REFERENCE CATEGORIES
    * =====================================================================
    * Derived from e(fvsemantic), the FIT-TIME expansion, so a replay names the
    * levels the fit actually used even if fvset base has changed since.  The
    * coefficient rows now carry the user's own term names, so these lines say
    * only what the table cannot: which level each factor is measured against.
    local _fvsem `"`e(fvsemantic)'"'
    local _nrefs = 0
    if `"`_fvsem'"' != "" {
        foreach _term of local _fvsem {
            if regexm("`_term'", "^([0-9]+)b\.(.+)$") & !strpos("`_term'", "#") {
                local _rlev = regexs(1)
                local _rvar = regexs(2)
                local _rtxt ""
                * The variable may have been dropped since the fit; a redisplay
                * must not error over a cosmetic label lookup.
                capture confirm variable `_rvar'
                if !_rc {
                    local _rvl : value label `_rvar'
                    if "`_rvl'" != "" {
                        local _rtxt : label `_rvl' `_rlev'
                    }
                }
                if `"`_rtxt'"' == "" local _rtxt "`_rlev'"
                local ++_nrefs
                local _refline`_nrefs' `"i.`_rvar': `_rtxt' (`_rvar'==`_rlev')"'
            }
        }
    }
    if `_nrefs' > 0 {
        display as text ""
        forvalues _i = 1/`_nrefs' {
            display as text `"Reference: `_refline`_i''"'
        }
    }

    } /* end capture noisily */

    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
