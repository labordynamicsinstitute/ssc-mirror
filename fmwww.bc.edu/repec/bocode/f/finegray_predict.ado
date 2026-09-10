*! finegray_predict Version 1.3.2  2026/09/08
*! Post-estimation predictions after finegray
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: rclass (creates variable; returns no results)

/*
Basic syntax:
  finegray_predict newvar [if] [in], [cif xb schoenfeld timevar(varname)]

Description:
  Generate predictions after finegray.

  xb (default) - linear predictor z'beta
  cif          - cumulative incidence function: 1 - exp(-H0(t)*exp(xb))

Required:
  newvar - name for the new variable

Options:
  cif          - predict CIF instead of xb
  xb           - predict linear predictor (default)
  timevar(var) - use specified variable for time (instead of _t)

See help finegray for complete documentation
*/

program define finegray_predict, rclass sortpreserve
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    local _held = 0
    local _bframe = 0
    local _bh_stashed = 0
    local _rngsaved = 0
    local _rngstate ""
    local _created_vars ""

    capture noisily {

    syntax newvarname [if] [in] , ///
        [CIF XB SCHoenfeld BASECSHazard TIMEvar(varname numeric) CI Level(string) ///
         BOOTstrap(integer 0) SEED(string) ATTime(string)]

    * attime() is parsed as a string, not real, so an OMITTED attime() can be
    * told apart from attime(.) -- and attime(.) is a user error worth naming,
    * not a silent "use each row's own time".

    * level() is parsed as a string (not cilevel) so an OMITTED level() leaves
    * the macro empty and can be told apart from an explicit one; cilevel would
    * auto-fill it with c(level) and make "was it given?" undetectable.  It is
    * validated as a confidence level below only when actually supplied.

    if `bootstrap' < 0 {
        display as error "bootstrap() must be a non-negative integer"
        exit 198
    }
    * A bootstrap SE is the sample SD of the replicate estimates; with a handful
    * of replicates that SD is itself almost pure noise.  The floor of 25 is
    * Efron and Tibshirani's (1993, sec. 6.4) minimum for estimating a standard
    * error.  The previous floor was 2 -- an interval could be, and was, built
    * from two replications.
    local _minboot 25
    if `bootstrap' > 0 & `bootstrap' < `_minboot' {
        display as error "bootstrap() must be at least `_minboot'"
        display as error "a standard error estimated from fewer replications is not usable"
        exit 198
    }
    if `bootstrap' > 0 & "`ci'" == "" {
        display as error "bootstrap() requires the ci option"
        exit 198
    }
    * seed() only means something when there is resampling to seed.  Silently
    * ignoring it invites a user to believe a non-bootstrap run is reproducible
    * because they asked for it to be.
    if `"`seed'"' != "" & `bootstrap' == 0 {
        display as error "seed() requires bootstrap()"
        exit 198
    }
    * seed() is documented as seed(#) and is handed straight to `set seed'.  A
    * non-numeric seed used to reach it raw, so seed(abc) cleared both curated
    * guards above and then died inside `set seed' on Stata's own complaint
    * about finding a non-integer where an integer below 2^31 was expected:
    * correct and fail-closed, but not this command's message, and printed long
    * after the guards that exist to speak first.
    *
    * NOTE for future editors: keep the sequence double-quote-then-apostrophe
    * out of these comment lines.  test_finegray_contracts.do reads this file a
    * line at a time inside a compound quote, and that sequence closes it early
    * -- r(132) too few quotes, reported against the test rather than the file.
    if `"`seed'"' != "" {
        capture confirm integer number `seed'
        if _rc | real(`"`seed'"') < 0 | real(`"`seed'"') >= 2^31 {
            display as error "seed() must be an integer between 0 and 2147483647"
            display as error "{bf:`seed'} is not a usable random-number seed"
            exit 198
        }
    }

    * Check finegray was run
    if "`e(cmd)'" != "finegray" {
        * After `mi estimate, cmdok: finegray ...' the results in e() are mi's
        * pooled ones, not a finegray fit, and "you must run finegray" reads as
        * though the user had not -- when they just did.  Name what actually
        * happened, and where post-estimation does live.
        if "`e(cmd)'" == "mi estimate" & "`e(cmd_mi)'" == "finegray" {
            display as error "post-estimation is not available after {bf:mi estimate}"
            display as error "e() holds the pooled estimates, and pooled estimates have no"
            display as error "single baseline hazard for {bf:finegray_predict} to work from"
            display as error "refit on a single dataset -- {bf:mi extract 0, clear} for the"
            display as error "complete-case data, or {bf:mi extract #, clear} for one imputation --"
            display as error "and run {bf:finegray} there; see {help finegray##mi:help finegray}"
            exit 301
        }
        display as error "last estimates not found"
        display as error "you must run {bf:finegray} before using finegray_predict"
        exit 301
    }
    * A fit made on multiple-imputation data left no post-estimation support in
    * the caller's dataset: its design columns and its entry column were
    * tempvars and are gone (see the mi block in finegray.ado).  There is also
    * no single baseline hazard to answer from once estimates are pooled across
    * imputations -- pooling a CIF is a different estimand, not this command.
    * Refuse by name rather than resolve e(designvars), whose tempvar names the
    * next command to ask for a tempvar will happily reuse.
    if `"`e(postest)'"' == "unavailable_mi" {
        display as error "post-estimation is not available after a fit on mi data"
        display as error "{bf:finegray_predict} needs the fit's design columns and its"
        display as error "baseline hazard, neither of which a fit on mi data leaves behind"
        display as error "refit on a single dataset -- {bf:mi extract 0, clear} for the"
        display as error "complete-case data, or {bf:mi extract #, clear} for one imputation --"
        display as error "and run {bf:finegray} there; see {help finegray##mi:help finegray}"
        exit 301
    }
    * Results posted by a finegray that recorded the design columns as
    * e(covariates) carry the narrow stripe and no e(designvars); pairing this
    * version's non-base reader with them would score the right columns by
    * luck only.  Refuse by name.
    if `"`e(designvars)'"' == "" & `"`e(covariates)'"' != "" {
        display as error "estimation results predate this version of finegray"
        display as error "e(designvars) is not set; re-run {bf:finegray} before using finegray_predict"
        exit 301
    }
    * A nonconverged fit posts e(b), and every prediction path reads it. Without
    * this gate xb/cif/schoenfeld are computed from a last iterate that is not a
    * solution -- rc 0, no warning, silently wrong.
    if e(converged) != 1 {
        display as error "last estimates did not converge"
        display as error "finegray_predict requires a converged fit; refit finegray"
        display as error "with a larger iterate() or a different specification"
        exit 430
    }

    * fweight and bootstrap() are incompatible.  `bsample' draws ROWS, and an
    * fweighted fit stores its replication as a weight column rather than as
    * rows: resampling 600 rows carrying w = 1..3 is not a resample of the
    * sum(w) subjects the fit describes, so the replicate SD is the SD of a
    * much smaller design and the reported SE is inflated (measured 2026-09-01:
    * about twice the analytic one).  Refuse rather than report it.  The
    * analytic interval needs no resampling here: under frequency weights the
    * influence-function variance is exact, because an fweighted fit IS the fit
    * of the replicated data (asserted bit for bit in qa/test_finegray_weights.do,
    * WT-03).
    if `bootstrap' > 0 & `"`e(wtype)'"' == "fweight" {
        display as error "bootstrap() is not supported after a fit with fweights"
        display as error "{bf:bsample} resamples rows, not the replicated subjects the"
        display as error "frequency weights stand for, so the replicate SD would describe"
        display as error "a smaller sample than the fit"
        display as error "the analytic interval is exact under fweights -- use {bf:ci} without"
        display as error "{bf:bootstrap()}, or expand the data ({bf:expand} the weight) and"
        display as error "bootstrap the expanded fit"
        exit 198
    }

    * =====================================================================
    * PIECEWISE beta(t) CONTEXT
    * =====================================================================
    * On a tvc() fit e(b) is WIDER than e(designvars): the time-varying design
    * columns carry one coefficient per interval.  Every branch below that pairs
    * a coefficient with a column has to know that, and the two that cannot be
    * answered at all are refused by name.
    local _fg_tvc `"`e(tvc)'"'
    local _fg_cuts `"`e(tsplit)'"'
    local _fg_tvcpos `"`e(tvc_pos)'"'
    local _fg_nint = e(n_intervals)
    if `_fg_nint' >= . local _fg_nint = 1
    local _fg_istvc = ("`_fg_tvc'" != "")
    if `_fg_istvc' & (`_fg_nint' < 2 | "`_fg_cuts'" == "" | "`_fg_tvcpos'" == "") {
        display as error "estimation results predate this version of finegray"
        display as error "re-run {bf:finegray} before using finegray_predict"
        exit 301
    }

    * Default to xb
    local n_types = ("`cif'" != "") + ("`xb'" != "") + ("`schoenfeld'" != "") ///
        + ("`basecshazard'" != "")
    if `n_types' > 1 {
        display as error "specify only one of cif, xb, schoenfeld, or basecshazard"
        exit 198
    }
    if `n_types' == 0 local xb "xb"

    * Schoenfeld residuals under beta(t).  The residual at an interval-j event
    * time is D_j(z) - zbar_j, and in the p' frame every OTHER interval's block
    * is structurally zero there -- the covariate itself is zero in that risk
    * set.  A table of residuals that is zero by construction for (J-1)/J of its
    * entries is not a diagnostic, and finegray_phtest, which consumes exactly
    * these residuals, would test proportionality of a model that no longer
    * assumes it.  tvc() IS the modelled answer to a phtest rejection: run the
    * diagnostic on the proportional fit, then fit this one.
    if "`schoenfeld'" != "" & `_fg_istvc' {
        display as error "schoenfeld is not available after a fit with tvc()"
        display as error "under a piecewise beta(t) each residual is defined inside its own"
        display as error "interval, so every other interval's block is zero by construction"
        display as error "and the table is not a proportional-hazards diagnostic"
        display as error "run {bf:finegray_phtest} on the proportional fit instead; a rejection"
        display as error "there is what {bf:tvc()} answers"
        exit 198
    }

    * ci/bootstrap()/level() are CIF-only.  basecshazard is a baseline quantity
    * with no covariate profile, so a CI option paired with it would be parsed,
    * ignored, and silently produce a bare point estimate -- refuse instead.
    if "`basecshazard'" != "" & ("`ci'" != "" | `bootstrap' > 0) {
        display as error "ci and bootstrap() are not supported with basecshazard"
        exit 198
    }

    if "`ci'" != "" & "`cif'" == "" {
        display as error "ci requires the cif option"
        exit 198
    }

    * The analytic CIF interval is the influence function in
    * _finegray_cif_core, derived for ONE exp(z'beta) multiplying every Breslow
    * increment.  Under beta(t) each increment carries its own interval's linear
    * predictor and its own S0(t), so both the prefix-sum scaffolding and the
    * beta-derivative term change shape; that derivation is not in this release.
    * Reporting the proportional-hazards influence function for a piecewise fit
    * would be a wrong standard error at rc 0.  The bootstrap needs no
    * derivation -- it refits the whole model on each resample -- so it is the
    * supported route and is named here rather than left to be discovered.
    * FENCE LIFTED 2026-08-26 (variance unification).  The CIF influence function has been
    * re-derived for a piecewise beta(t) -- the derivation is written out in the
    * header of _finegray_cif_core_pw in _finegray_mata.ado --
    * and the piecewise variant reuses the SAME accumulators the proportional one
    * uses, differing only in the combination over intervals.  bootstrap(#)
    * remains available and is the arm the analytic route is checked against.

    * ---- attime(): the evaluation time for a piecewise linear predictor -----
    * xb is a pure linear score on a proportional fit and there is nothing to
    * evaluate it AT.  On a tvc() fit it is a function of time, because which
    * interval's coefficients are active depends on the time -- so it needs one,
    * and attime() supplies a single constant one for every row (the default is
    * each row's own _t).
    local _fg_attime ""
    if `"`attime'"' != "" {
        if "`xb'" == "" {
            display as error "attime() requires the xb option"
            display as error "it fixes the time at which the piecewise linear predictor is"
            display as error "evaluated; for cif and basecshazard use {bf:timevar()}"
            exit 198
        }
        if !`_fg_istvc' {
            display as error "attime() requires a fit with tvc()"
            display as error "without tvc() the linear predictor does not depend on time"
            exit 198
        }
        capture confirm number `attime'
        if _rc | missing(real(`"`attime'"')) | real(`"`attime'"') < 0 {
            display as error "attime() must be a non-negative number"
            display as error "{bf:`attime'} is not a usable analysis time"
            exit 198
        }
        local _fg_attime = real(`"`attime'"')
    }

    * FG-07: refuse options that the selected statistic silently ignores, so a
    * misspelled or misplaced analysis option is never accepted as if honored.
    * timevar() sets the evaluation time and is meaningful only for cif and
    * basecshazard; it does nothing for the linear predictor or the residuals.
    if "`timevar'" != "" & ("`xb'" != "" | "`schoenfeld'" != "") {
        display as error "timevar() is not allowed with xb or schoenfeld"
        display as error "it sets the evaluation time for cif and basecshazard only"
        exit 198
    }
    * level() controls a confidence interval, so it means something only for
    * cif WITH ci.  With Level(string) an omitted level() is empty here.
    if "`level'" != "" & !("`cif'" != "" & "`ci'" != "") {
        display as error "level() requires the cif and ci options"
        display as error "it sets the confidence level for the cif interval only"
        exit 198
    }
    if "`level'" == "" {
        local level = c(level)
    }
    else {
        * One bound, one message, in all four places -- Stata's own cilevel
        * rule, delegated so it cannot drift from `finegray, level()' again.
        _finegray_check_level, level(`level')
    }

    * ci derives two more variable names from newvarname by suffix, so the
    * usable budget is 28 characters, not Stata's 32.  These names used to be
    * confirmed only after the point CIF had been computed, and after every
    * guard that could report a DIFFERENT failure first: `finegray_predict
    * <29 chars> if <selects nothing>, cif ci' ended at r(2000) "no
    * observations", never mentioning the name that could not have worked.  When
    * it did surface it was a bare "..._lci invalid name", r(198), with the
    * 28-character ceiling documented nowhere.
    * Check before the work, and say which of the two things went wrong:
    * `confirm new variable' returns 198 for a malformed or over-long name and
    * 110 for a well-formed name that is already taken.
    if "`ci'" != "" {
        foreach _sfx in lci uci {
            capture confirm new variable `varlist'_`_sfx'
            if _rc == 110 {
                display as error "variable `varlist'_`_sfx' already exists"
                display as error "{bf:ci} creates `varlist'_lci and `varlist'_uci alongside `varlist'"
                exit 110
            }
            else if _rc {
                display as error "`varlist'_`_sfx' is not a valid variable name"
                display as error "{bf:ci} appends _lci and _uci to the new variable name, so"
                display as error "with {bf:ci} the name may be at most 28 characters"
                display as error "(`varlist' is `=length("`varlist'")')"
                exit 198
            }
        }
    }

    marksample touse, novarlist

    * NOTE on why plain xb/cif do NOT call _finegray_check_data.
    * xb is a pure linear score, X*b: it does not read _t, _d, compete(), the
    * strata or the cluster variable, so a change in any of those cannot make it
    * wrong, and demanding an intact estimation sample would break the documented
    * ability to score new data.  What xb DOES depend on is that each coefficient
    * is paired with the right column -- which is exactly what FG-H02 broke.  That
    * is enforced below, structurally, by aligning factor terms to the fit-time
    * expansion by LEVEL VALUE and refusing any level the fit never saw.

    * CI uses influence functions that require the original estimation data
    if "`ci'" != "" {
        _finegray_check_data
        capture confirm variable _t
        if _rc {
            display as error "ci requires the original stset estimation data"
            display as error "use {bf:finegray_predict, cif} for the point CIF on new data"
            exit 111
        }
        quietly replace `touse' = 0 if !e(sample)
    }

    * For CI, the influence-function variance needs the full estimation design,
    * so reconstruct covariates over e(sample) (a superset of touse); the CIF
    * itself is still evaluated only at touse.
    * schoenfeld needs the same basis: the residuals are computed over the WHOLE
    * estimation sample (if/in only masks the output -- see the blanking step at
    * the end of that path), and the Mata scan reads the design columns for
    * every e(sample) row.  A design built only over touse leaves missing values
    * on the rows if/in excludes; each such row poisons the risk-set sums S0/S1
    * from its entry onward, and every residual after that point came back
    * MISSING at rc 0 -- `finegray_predict s if x<0, schoenfeld' on a factor fit
    * returned an all-missing variable while the non-factor path was correct.
    * Without ci/schoenfeld the basis is touse (predictions, possibly on new
    * data).
    local _fvbasis "`touse'"
    if "`ci'" != "" | "`schoenfeld'" != "" {
        tempvar _esamp
        quietly gen byte `_esamp' = e(sample)
        local _fvbasis "`_esamp'"
    }

    quietly count if `touse'
    if r(N) == 0 {
        display as error "no observations"
        exit 2000
    }

    if "`schoenfeld'" != "" {
        _finegray_check_data
        * Schoenfeld residuals require the original stset estimation data
        capture confirm variable _t
        if _rc {
            display as error "variable _t not found"
            display as error "schoenfeld residuals require the original stset estimation data"
            display as error "use {bf:finegray_predict, xb} for predictions on new data"
            exit 111
        }
        capture confirm variable _d
        if _rc {
            display as error "variable _d not found"
            display as error "schoenfeld residuals require the original stset estimation data"
            exit 111
        }
        quietly count if e(sample)
        if r(N) == 0 {
            display as error "no observations in estimation sample"
            display as error "schoenfeld residuals require the original stset estimation data"
            display as error "use {bf:finegray_predict, xb} for predictions on new data"
            exit 2000
        }
    }

    * Entry-time source for every path that may rebuild the baseline or score
    * residuals. Point CIF/basecshazard predictions normally use the warm Mata
    * cache too, but after mata clear they rebuild from the estimation data and
    * therefore need the same subject-level entry times as ci/schoenfeld.
    * The characteristic travels with the data, e(entryvar) with the estimates.
    * After `estimates use' over a dataset saved before the fit there is no
    * characteristic, and reading _t0 instead would silently substitute
    * per-record entry times for the subject-level ones the fit used.
    local _t0var "_t0"
    * Entry metadata belongs to the active estimates. An empty e(entryvar)
    * means _t0; a later fit's dataset characteristic cannot override it.
    local _fg_entrysrc `"`e(entryvar)'"'
    if ("`cif'" != "" | "`basecshazard'" != "" | "`schoenfeld'" != "") ///
        & `"`_fg_entrysrc'"' != "" {
        local _t0var `"`_fg_entrysrc'"'
        * Point lookup from a saved/cached baseline reads no entry data.
        * A rebuild verifies the estimation signature inside the resolver.
        if "`ci'" != "" | "`schoenfeld'" != "" {
            capture confirm numeric variable `_t0var'
            if _rc {
                display as error "variable `_t0var' not found"
                display as error "finegray recorded subject entry times in `_t0var' for its"
                display as error "multiple-record reduction; re-run finegray before finegray_predict"
                exit 111
            }
        }
    }

    * Baseline strata.  Under bstrata() there is no single baseline: each
    * stratum has its own step function, and every path that reads a baseline
    * curve (cif, basecshazard) or rebuilds a risk set (schoenfeld, ci) must
    * know which one a row belongs to.  xb is exempt -- it is Z*b and reads no
    * baseline at all -- which is also why an unstratified fit is untouched
    * here: e(bstrata) is empty and every call below passes "".
    local _bsvar `"`e(bstrata)'"'
    if `"`_bsvar'"' != "" & ("`cif'" != "" | "`basecshazard'" != "" ///
        | "`schoenfeld'" != "") {
        capture confirm numeric variable `_bsvar'
        if _rc {
            display as error "baseline strata variable `_bsvar' not found"
            display as error "finegray was fit with {bf:bstrata(`_bsvar')}, so every row's"
            display as error "baseline is the one belonging to its stratum; predict requires"
            display as error "that variable in the data"
            exit 111
        }
        * A row with no stratum value has no baseline.  Leave its prediction
        * MISSING rather than answering it from some other stratum's curve --
        * the same rule the factor-variable path applies to a missing level.
        markout `touse' `_bsvar'
        quietly count if `touse'
        if r(N) == 0 {
            display as error "no observations with non-missing `_bsvar'"
            exit 2000
        }
        * A stratum that carried no cause event has an identically zero Breslow
        * baseline -- a degenerate curve, not an estimate of one -- so a CIF or
        * basecshazard there would be an exact 0 that reads as a real finding.
        * Named at fit time in e(bstrata_noevent); refused here, where the
        * message can say which level and why.  xb and schoenfeld are exempt:
        * neither reads a baseline.
        * Two spellings of the same levels: e(bstrata_noevent) is what the
        * message says, e(bstrata_noevent_x) is %21x and is what the `=='
        * runs against -- the readable form rounds a noninteger stratum and
        * would match no row, letting the degenerate curve through at rc 0.
        local _bsne `"`e(bstrata_noevent)'"'
        local _bsnex `"`e(bstrata_noevent_x)'"'
        * A fit stored before e(bstrata_noevent_x) existed carries only the
        * readable macro; fall back to it rather than matching nothing.
        if `"`_bsnex'"' == "" local _bsnex `"`_bsne'"'
        if `"`_bsne'"' != "" & ("`cif'" != "" | "`basecshazard'" != "") {
            local _bshit ""
            local _nbsne : word count `_bsnex'
            forvalues _b = 1/`_nbsne' {
                local _bsl : word `_b' of `_bsnex'
                local _bsldisp : word `_b' of `_bsne'
                quietly count if `touse' & `_bsvar' == `_bsl'
                if r(N) > 0 local _bshit "`_bshit' `_bsldisp'"
            }
            if "`_bshit'" != "" {
                display as error "baseline stratum(s)`_bshit' carried no cause `=e(cause)' event"
                display as error "their baseline subdistribution hazard is identically zero, which"
                display as error "is a degenerate curve rather than an estimate of one"
                display as error "exclude those rows with {bf:if}, or pool them into a stratum that"
                display as error "has events; see {help finegray##bstrata:help finegray}"
                exit 459
            }
        }
    }

    * basecshazard needs NO covariate design: it reports the baseline
    * cumulative subhazard, which does not depend on z.  Building the design
    * anyway made `predict, basecshazard' on new data that carries only the
    * time variable die with "required covariate ... not found" (r(111)) --
    * on a non-factor fit at the confirm-variable sweep below, on a factor
    * fit inside the per-term rebuild.  Everything the baseline branch reads
    * (_fg_cuts/_fg_tvcpos, `_t0var', `_bsvar' and the no-event refusal) is
    * established above; the piecewise block below is already gated on
    * xb/cif, and _score_varlist/_score_labels are read only by the xb, cif
    * and schoenfeld branches.
    if "`basecshazard'" == "" {
        * Build the covariate columns used for prediction.
        * For FV models we reconstruct the design matrix on demand rather than
        * depending on persistent _fg_* columns remaining in the dataset.
        local _score_varlist "`e(designvars)'"
        local _score_labels "`e(designvars)'"
        if `"`e(fvvarlist)'"' != "" {
            * Rebuild the design from the FIT-TIME expansion, e(fvsemantic), evaluating
            * every factor term against the current data BY LEVEL VALUE.
            *
            * The previous implementation re-ran fvexpand/fvrevar on the current data
            * and paired the resulting columns with e(b) POSITIONALLY.  That is only
            * correct while the level support is unchanged: fit on i.grp over {1,2,3},
            * shift the data to {2,3,4}, and fvexpand yields three terms again -- so
            * the coefficient for level 2 was applied to level 3, and so on, at rc 0.
            * Aligning by value cannot make that mistake.
            local _fv_semantic `"`e(fvsemantic)'"'
            if `"`_fv_semantic'"' == "" {
                display as error "estimation results predate this version of finegray"
                display as error "re-run {bf:finegray} before using finegray_predict"
                exit 301
            }

            * --- the fitted level support, per factor variable (base levels included) ---
            * Also collect every underlying raw covariate (factor and continuous) so
            * rows with a missing constituent are marked OUT of the scoreable sample
            * below.  Without that, a missing factor value fails every `var==level'
            * comparison, all its dummies collapse to zero, and the row silently
            * scores as the fitted base category (FG-01) -- a fabricated, plausible
            * prediction returned at rc 0 instead of an honest missing.
            local _fv_facvars ""
            local _fv_rawvars ""
            foreach _term of local _fv_semantic {
                local _tparts = subinstr(subinstr("`_term'", "##", "#", .), "#", " ", .)
                foreach _tp of local _tparts {
                    * Tolerate any factor operator on the level marker (b base, bn
                    * base-none, o omitted) so bn. levels are counted as supported.
                    if regexm("`_tp'", "^([0-9]+)[a-z]*\.(.+)$") {
                        local _flev = regexs(1)
                        local _fvar = regexs(2)
                        local _fpos : list posof "`_fvar'" in _fv_facvars
                        if `_fpos' == 0 {
                            local _fv_facvars "`_fv_facvars' `_fvar'"
                            local _fpos : list posof "`_fvar'" in _fv_facvars
                            local _fvlevels`_fpos' ""
                        }
                        local _lseen : list posof "`_flev'" in _fvlevels`_fpos'
                        if `_lseen' == 0 {
                            local _fvlevels`_fpos' "`_fvlevels`_fpos'' `_flev'"
                        }
                        local _rseen : list posof "`_fvar'" in _fv_rawvars
                        if `_rseen' == 0 local _fv_rawvars "`_fv_rawvars' `_fvar'"
                    }
                    else {
                        * continuous part (c.x, or a bare interaction covariate)
                        local _cvraw = subinstr("`_tp'", "c.", "", .)
                        local _rseen : list posof "`_cvraw'" in _fv_rawvars
                        if `_rseen' == 0 local _fv_rawvars "`_fv_rawvars' `_cvraw'"
                    }
                }
            }

            * FG-01: exclude any row missing a constituent covariate (system . and
            * extended .a-.z) from the scoreable sample, so xb/CIF are left MISSING
            * there rather than fabricated as the base category.  markout screens all
            * missing kinds.  Applied before the unseen-level check so a missing value
            * is never conflated with an unseen (nonmissing) level.
            foreach _rv of local _fv_rawvars {
                capture confirm numeric variable `_rv'
                if !_rc markout `_fvbasis' `_rv'
            }

            * A level the fit never saw has no coefficient.  Scoring it would silently
            * collapse the observation onto the base category (all its dummies zero),
            * which is a fabricated prediction, not an extrapolation.
            foreach _fvar of local _fv_facvars {
                local _fpos : list posof "`_fvar'" in _fv_facvars
                capture confirm numeric variable `_fvar'
                if _rc {
                    display as error "required factor variable `_fvar' not found"
                    display as error "predict requires the variables used when finegray was estimated"
                    exit 111
                }
                tempvar _lvbad
                quietly gen byte `_lvbad' = 0 if `_fvbasis'
                foreach _flev of local _fvlevels`_fpos' {
                    quietly replace `_lvbad' = `_lvbad' + (`_fvar' == `_flev') if `_fvbasis'
                }
                quietly count if `_lvbad' == 0 & `_fvbasis' & !missing(`_fvar')
                if r(N) > 0 {
                    display as error "`_fvar' contains `r(N)' observation(s) at levels not present when finegray was estimated"
                    display as error "the model has no coefficient for those levels; fitted levels are:`_fvlevels`_fpos''"
                    exit 459
                }
                drop `_lvbad'
            }

            * --- build one column per non-base term, keyed to the level VALUE ---
            local _rebuild_varlist ""
            local _rebuild_labels ""
            local _term_i = 0
            foreach _term of local _fv_semantic {
                local ++_term_i
                * base terms (e.g. 1b.grp) carry no coefficient
                if regexm("`_term'", "[0-9]+b\.") continue

                * Label with the term spelled EXACTLY as e(fvsemantic) has it --
                * `2.grp#c.z', not `2.grp#z'.  finegray_phtest's r(phtest) rownames
                * and r(profile_vars) both carry the verbatim term, so stripping
                * `c.' here made the same design column go by two different names
                * across the three post-estimation commands.
                local _label_term "`_term'"
                local _tparts = subinstr(subinstr("`_term'", "##", "#", .), "#", " ", .)

                tempvar _fgcol
                quietly gen double `_fgcol' = 1 if `_fvbasis'
                foreach _tp of local _tparts {
                    if regexm("`_tp'", "^([0-9]+)[a-z]*\.(.+)$") {
                        quietly replace `_fgcol' = `_fgcol' * ///
                            (`=regexs(2)' == `=regexs(1)') if `_fvbasis'
                    }
                    else {
                        local _cvar = subinstr("`_tp'", "c.", "", .)
                        capture confirm numeric variable `_cvar'
                        if _rc {
                            display as error "required covariate `_cvar' not found"
                            display as error "predict requires the variables used when finegray was estimated"
                            exit 111
                        }
                        quietly replace `_fgcol' = `_fgcol' * `_cvar' if `_fvbasis'
                    }
                }
                local _rebuild_varlist "`_rebuild_varlist' `_fgcol'"
                local _rebuild_labels "`_rebuild_labels' `_label_term'"
            }

            local _score_varlist : list retokenize _rebuild_varlist
            local _score_labels : list retokenize _rebuild_labels

            local _n_score : word count `_score_varlist'
            * Compare against the DESIGN width, not colsof(e(b)).  Under tvc() the
            * coefficient vector is wider than the design -- one coefficient per
            * interval for each time-varying column -- so equality with colsof(e(b))
            * is the wrong contract there and would reject every factor-variable
            * tvc() fit.
            local _n_cov : word count `e(designvars)'
            if `_n_score' != `_n_cov' {
                display as error "reconstructed factor-variable design does not match stored coefficients"
                exit 198
            }
        }
        else {
            local _cov_missing ""
            foreach _cov of local _score_varlist {
                capture confirm variable `_cov'
                if _rc {
                    local _cov_missing "`_cov'"
                    continue, break
                }
            }
            if "`_cov_missing'" != "" {
                display as error "required covariate `_cov_missing' not found"
                display as error "predict requires the variables used when finegray was estimated"
                exit 111
            }
        }
    }

    * =====================================================================
    * PIECEWISE LINEAR PREDICTORS
    * =====================================================================
    * On a tvc() fit the coefficient vector is laid out as
    *   [ non-tvc columns in design order | interval 1 tvc block | ... ]
    * (the stripe finegray.ado posts, equations main / tvc1 / ... / tvcJ).  Both
    * xb and cif need the SAME two pieces from it: the time-constant part of the
    * linear predictor, and one time-varying part per interval.  Build them once
    * here, from the non-base copy of e(b) BY POSITION -- the coefficient names
    * are the user's terms and cannot be scored against, and the design columns
    * may be tempvars rebuilt a moment ago.
    *
    * The per-interval blocks are copied element by element into a freshly
    * created J(1,q,0) rather than sliced out of e(b): a slice of e(b) carries
    * its equation names, and `matrix score' against an eq-striped vector is not
    * the operation wanted here.
    local _fg_xbfix ""
    if `_fg_istvc' & ("`xb'" != "" | "`cif'" != "") {
        local _n_cov : word count `_score_varlist'
        local _fg_q : word count `_fg_tvcpos'
        local _fg_nfix = `_n_cov' - `_fg_q'

        local _fg_fixvars ""
        forvalues _pc = 1/`_n_cov' {
            local _pchit : list posof "`_pc'" in _fg_tvcpos
            if `_pchit' == 0 {
                local _fg_fixvars "`_fg_fixvars' `: word `_pc' of `_score_varlist''"
            }
        }
        local _fg_tvcvars ""
        foreach _pc of local _fg_tvcpos {
            local _fg_tvcvars "`_fg_tvcvars' `: word `_pc' of `_score_varlist''"
        }
        local _fg_fixvars : list retokenize _fg_fixvars
        local _fg_tvcvars : list retokenize _fg_tvcvars

        tempname _pb _pbnb
        tempvar _pxbfix
        _finegray_bnb, b(`_pbnb')
        if `_fg_nfix' > 0 {
            matrix `_pb' = J(1, `_fg_nfix', 0)
            forvalues _pi = 1/`_fg_nfix' {
                matrix `_pb'[1, `_pi'] = `_pbnb'[1, `_pi']
            }
            matrix colnames `_pb' = `_fg_fixvars'
            quietly matrix score double `_pxbfix' = `_pb' if `touse'
        }
        else quietly gen double `_pxbfix' = 0 if `touse'
        local _fg_xbfix "`_pxbfix'"

        forvalues _pj = 1/`_fg_nint' {
            tempvar _pxbtv`_pj'
            matrix `_pb' = J(1, `_fg_q', 0)
            forvalues _pi = 1/`_fg_q' {
                matrix `_pb'[1, `_pi'] = ///
                    `_pbnb'[1, `= `_fg_nfix' + (`_pj' - 1) * `_fg_q' + `_pi'']
            }
            matrix colnames `_pb' = `_fg_tvcvars'
            quietly matrix score double `_pxbtv`_pj'' = `_pb' if `touse'
            local _fg_xbtv`_pj' "`_pxbtv`_pj''"
        }
    }

    if "`xb'" != "" {
        * Linear predictor: matrix score
        if "`typlist'" == "" local typlist "double"
        if !`_fg_istvc' {
            * The non-base vector: on a factor-variable fit e(b) carries the
            * base-level columns margins needs, which have no design column.
            tempname b
            _finegray_bnb, b(`b')
            local _n_scorecols : word count `_score_varlist'
            if colsof(`b') == `_n_scorecols' {
                matrix colnames `b' = `_score_varlist'
                matrix score `typlist' `varlist' = `b' if `touse'
            }
            else {
                * e(b) no longer carries the fitted stripe.  margins does this
                * while it runs: it reposts e(b) renamed onto its own
                * fvrevar'd level indicators (`__00000G __00000H ifp tumsize'
                * for `0b.pelnode 1.pelnode ifp tumsize'), sets THOSE columns
                * to the at() values, and expects predict to score e(b) by
                * name -- the contract every official predict honours because
                * it scores e(b) directly.  Without this branch the non-base
                * filter finds no base marker, keeps every column, and
                * `matrix colnames' given fewer names than columns repeats the
                * last one: margins, at(pelnode=(0 1)) printed -13.78 for both
                * levels at rc 0.  A stripe that names no variable fails here
                * in `matrix score' with r(111), which is the right answer.
                matrix `b' = e(b)
                capture matrix score `typlist' `varlist' = `b' if `touse'
                if _rc {
                    display as error "e(b) does not carry the fitted coefficient stripe"
                    display as error "and its column names cannot be scored as variables;"
                    display as error "re-run {bf:finegray} before using finegray_predict"
                    exit 498
                }
            }
            local _created_vars "`varlist'"
            label variable `varlist' "Linear prediction (xb)"
        }
        else {
            * beta(t): the linear predictor is a function of time, because the
            * active interval is.  Evaluate at attime() when given and at each
            * row's own _t otherwise; a row whose evaluation time is missing gets
            * a missing prediction rather than the first interval's answer.
            tempvar _pxt
            if "`_fg_attime'" != "" {
                quietly gen double `_pxt' = `_fg_attime'
                local _xblbl "at t = `_fg_attime'"
            }
            else {
                capture confirm variable _t
                if _rc {
                    display as error "_t not found"
                    display as error "after a fit with {bf:tvc()} the linear predictor depends on"
                    display as error "time; supply one with {bf:attime(#)}, or restore the stset"
                    display as error "analysis-time variable"
                    exit 111
                }
                quietly gen double `_pxt' = _t
                local _xblbl "at _t"
            }
            markout `touse' `_pxt'
            quietly count if `touse'
            if r(N) == 0 {
                display as error "no observations with a non-missing evaluation time"
                exit 2000
            }
            tempvar _pjv
            quietly gen byte `_pjv' = 1 if `touse'
            foreach _pcut of local _fg_cuts {
                quietly replace `_pjv' = `_pjv' + (`_pxt' > `_pcut') if `touse'
            }
            quietly gen `typlist' `varlist' = `_fg_xbfix' if `touse'
            local _created_vars "`varlist'"
            forvalues _pj = 1/`_fg_nint' {
                quietly replace `varlist' = `varlist' + `_fg_xbtv`_pj'' ///
                    if `touse' & `_pjv' == `_pj'
            }
            label variable `varlist' "Linear prediction (xb) `_xblbl'"
        }
    }
    else if "`basecshazard'" != "" {
        * Baseline cumulative subhazard, as a VARIABLE.  This is stcrreg's own
        * idiom -- stcrreg posts no baseline in e() at all and hands it over
        * through predict (stcrreg_p accepts basecshazard and basecif) -- so it is
        * what a user arriving from stcrreg reaches for.  It is also the cheap
        * representation: n rows in the dataset costs nothing, while the same
        * curve as a K-row Stata matrix costs O(K^2) to create.
        local tvar "_t"
        if "`timevar'" != "" local tvar "`timevar'"

        capture confirm variable `tvar'
        if _rc {
            display as error "time variable `tvar' not found"
            exit 111
        }

        markout `touse' `tvar'
        quietly count if `touse'
        if r(N) == 0 {
            display as error "no observations with non-missing `tvar'"
            exit 2000
        }

        * Load Mata engine for the baseline rebuild / step lookup
        capture mata: _finegray_mata_ok()
        * probe MATA, not a Stata program: `mata clear' drops Mata functions but
        * leaves Stata programs standing, so a program sentinel says "loaded" when
        * the engine is gone and the next Mata call dies with r(3499).
        if _rc {
            capture findfile _finegray_mata.ado
            if _rc == 0 {
                run "`r(fn)'"
            }
            else {
                display as error "_finegray_mata.ado not found; reinstall finegray"
                exit 111
            }
        }

        if "`typlist'" == "" local typlist "double"
        tempvar H0_val
        quietly gen double `H0_val' = 0

        capture confirm matrix e(basehaz)
        local _has_bh = (_rc == 0)
        * There is ONE baseline under tvc() -- the interval structure lives in
        * the linear predictor, not in lambda_0 -- so this quantity keeps its
        * meaning and its shape.  What it must NOT do is rebuild the curve with
        * the proportional scan: tvcpos()/tsplit() make the rebuild path re-run
        * the piecewise scan the fit actually ran.
        _finegray_resolve_baseline, tvar(`tvar') h0(`H0_val') touse(`touse') ///
            hasbh(`_has_bh') t0var(`_t0var') bsvar(`_bsvar') ///
            tsplit(`_fg_cuts') tvcpos(`_fg_tvcpos')

        quietly gen `typlist' `varlist' = `H0_val' if `touse'
        local _created_vars "`varlist'"
        label variable `varlist' "Baseline cumulative subhazard"
    }
    else if "`cif'" != "" {
        * CIF = 1 - exp(-H0(t) * exp(xb))
        * The baseline comes from e(basehaz) when the user asked finegray to post
        * it, and is otherwise rebuilt in Mata from e(sample) + e(b).  Both give
        * the same curve -- the rebuild re-runs the fit's own _finegray_basehazard
        * -- so this branch is about where the numbers come from, not what they
        * are.  e(basehaz) is opt-in because creating a K-row Stata matrix is
        * O(K^2); requiring it here would have made every predict user pay it.
        capture confirm matrix e(basehaz)
        local _has_bh = (_rc == 0)

        * Get time variable
        local tvar "_t"
        if "`timevar'" != "" local tvar "`timevar'"

        capture confirm variable `tvar'
        if _rc {
            display as error "time variable `tvar' not found"
            exit 111
        }

        * Exclude observations with missing time values
        markout `touse' `tvar'
        quietly count if `touse'
        if r(N) == 0 {
            display as error "no observations with non-missing `tvar'"
            exit 2000
        }

        * Compute xb first.  On a tvc() fit there is no single xb -- the linear
        * predictor is interval-specific -- so the CIF is accumulated below from
        * the per-interval predictors built above and this scalar one is unused.
        tempvar xb_val
        if !`_fg_istvc' {
            tempname b
            _finegray_bnb, b(`b')
            * The CIF pairs coefficients with the design columns by position
            * (the baseline rebuild and the influence function read them by
            * name), so a re-striped e(b) -- what margins posts while it runs
            * -- cannot be honoured here the way xb honours it; refuse rather
            * than let `matrix colnames' mislabel by repetition.
            local _n_scorecols : word count `_score_varlist'
            if colsof(`b') != `_n_scorecols' {
                display as error "e(b) does not carry the fitted coefficient stripe"
                display as error "(`=colsof(`b')' non-base coefficients, `_n_scorecols' design columns);"
                display as error "re-run {bf:finegray} before using finegray_predict, cif"
                exit 498
            }
            matrix colnames `b' = `_score_varlist'
            matrix score double `xb_val' = `b' if `touse'
        }

        * The step-lookup helper takes a matrix NAME and reads it with
        * st_matrix(), which reads e() matrices directly and for free.  Copying
        * e(basehaz) into a tempname first is O(K^2) in its row count (6.8 s at
        * K = 40,000) and buys nothing.  See finegray.ado's basehaz post.

        if "`typlist'" == "" local typlist "double"

        * Step function lookup via Mata binary search: O(n log n_bh)
        * H0(t_i) = baseline cumhazard at time t_i
        * CIF(t_i|z) = 1 - exp(-H0(t_i) * exp(z'beta))
        tempvar H0_val
        quietly gen double `H0_val' = 0

        * Load Mata engine for step lookup
        capture mata: _finegray_mata_ok()
        * probe MATA, not a Stata program: `mata clear' drops Mata functions but
        * leaves Stata programs standing, so a program sentinel says "loaded" when
        * the engine is gone and the next Mata call dies with r(3499).
        if _rc {
            capture findfile _finegray_mata.ado
            if _rc == 0 {
                run "`r(fn)'"
            }
            else {
                display as error "_finegray_mata.ado not found; reinstall finegray"
                exit 111
            }
        }
        * Under tvc() the same call also returns Lambda_0 AT each tsplit()
        * boundary, from the SAME curve it just evaluated per observation.
        * Reading those from a second, independently resolved baseline is how a
        * CIF ends up mixing two curves at rc 0.
        tempname _pcut
        if `_fg_istvc' {
            _finegray_resolve_baseline, tvar(`tvar') h0(`H0_val') ///
                touse(`touse') hasbh(`_has_bh') t0var(`_t0var') ///
                bsvar(`_bsvar') tsplit(`_fg_cuts') cutmat(`_pcut') ///
                tvcpos(`_fg_tvcpos')
        }
        else {
            _finegray_resolve_baseline, tvar(`tvar') h0(`H0_val') touse(`touse') ///
                hasbh(`_has_bh') t0var(`_t0var') bsvar(`_bsvar')
        }

        if !`_fg_istvc' {
            * exp(xb), or H0 exp(xb), can exceed double precision at a finite
            * but extreme profile; Stata then returns missing for a CIF whose
            * value is 1 to machine precision (Lambda above maxdouble), or 0
            * when H0 is still 0 (0 * missing is missing).  Evaluate those
            * limits; a missing H0 or xb stays missing.  The finite branch is
            * the shipped arithmetic, unchanged.  Same contract as
            * _finegray_cif_stable in _finegray_mata.ado.
            quietly gen `typlist' `varlist' = /// stata-dev-ignore: unchecked-commit — guarded by the _finegray_assert_cardinality call below, which covers this branch and the piecewise one (both write `varlist')
                cond(!missing(`H0_val' * exp(`xb_val')), ///
                    1 - exp(-`H0_val' * exp(`xb_val')), ///
                    cond(missing(`H0_val') | missing(`xb_val'), ., ///
                        cond(`H0_val' > 0, 1, 0))) if `touse'
        }
        else {
            * CIF(s|z) = 1 - exp(-sum_j m_j(s) exp(eta_j(z))), where m_j(s) is
            * the baseline mass that falls inside interval j up to s:
            *   m_j(s) = max(0, min(H0(s), H0(cut_j)) - H0(cut_{j-1}))
            * with H0(cut_0) = 0 and cut_J = +infinity.  This needs no left
            * limits because interval j is (cut_{j-1}, cut_j]: a baseline jump
            * exactly at a boundary belongs to the interval that closes there,
            * which is the same tie rule the fit used.  min() ignores a missing
            * argument in Stata, so the open last interval is written as min(H0, .).
            * The tsplit() boundary values of Lambda_0.  Without bstrata() there
            * is one baseline, so `_pcut' is 1 x (J-1) and every row shares the
            * same boundaries.  WITH bstrata() the baseline is one curve per
            * stratum and so are the boundaries: `_pcut' comes back K x J with
            * the stratum VALUE in column 1 (the e(basehaz) convention), and the
            * accumulation below has to read each row's own stratum's row.
            * Materialise them as columns rather than macros, because a macro
            * cannot vary by observation and a scalar boundary applied to every
            * stratum is exactly the pooled-baseline answer this composition
            * exists to avoid.
            local _p_bs = ("`_bsvar'" != "" & rowsof(`_pcut') > 1)
            if `_p_bs' {
                forvalues _pj = 1/`= `_fg_nint' - 1' {
                    tempvar _pcv`_pj'
                    quietly gen double `_pcv`_pj'' = . if `touse'
                }
                forvalues _pr = 1/`= rowsof(`_pcut')' {
                    local _plv : display %21x `_pcut'[`_pr', 1]
                    forvalues _pj = 1/`= `_fg_nint' - 1' {
                        quietly replace `_pcv`_pj'' = `_pcut'[`_pr', `= `_pj' + 1'] ///
                            if `touse' & `_bsvar' == `_plv'
                    }
                }
                * A row whose stratum the fit never saw has no baseline to
                * answer from; the H0 lookup above has already refused such a
                * row, so any missing left here would be a routing error.
                forvalues _pj = 1/`= `_fg_nint' - 1' {
                    quietly count if `touse' & missing(`_pcv`_pj'')
                    if r(N) > 0 {
                        display as error "internal error: `r(N)' observation(s) have no"
                        display as error "baseline boundary value for their bstrata() level"
                        exit 498
                    }
                }
            }

            tempvar _plam _ppiece _pterm _pbad _povf
            quietly gen double `_plam' = 0 if `touse'
            quietly gen double `_ppiece' = .
            quietly gen double `_pterm' = .
            * Overflow bookkeeping, one flag per row: `_pbad' marks a missing
            * piece or linear predictor (no prediction); `_povf' marks a term
            * that exceeded double precision at a finite predictor over a
            * positive piece (Lambda above maxdouble, CIF = 1).  A term that
            * overflows over a ZERO piece is exactly 0.  Same contract as
            * _finegray_tvc_lambda in _finegray_mata.ado.
            quietly gen byte `_pbad' = 0 if `touse'
            quietly gen byte `_povf' = 0 if `touse'
            tempvar _plov
            quietly gen double `_plov' = 0 if `touse'
            forvalues _pj = 1/`_fg_nint' {
                if `_pj' == `_fg_nint' {
                    quietly replace `_ppiece' = `H0_val' - `_plov' if `touse'
                }
                else if `_p_bs' {
                    quietly replace `_ppiece' = ///
                        min(`H0_val', `_pcv`_pj'') - `_plov' if `touse'
                }
                else {
                    local _phi = `_pcut'[1, `_pj']
                    quietly replace `_ppiece' = ///
                        min(`H0_val', `_phi') - `_plov' if `touse'
                }
                quietly replace `_ppiece' = 0 if `touse' & `_ppiece' < 0
                quietly replace `_pterm' = ///
                    `_ppiece' * exp(`_fg_xbfix' + `_fg_xbtv`_pj'') if `touse'
                quietly replace `_pbad' = 1 if `touse' & (missing(`_ppiece') ///
                    | missing(`_fg_xbfix' + `_fg_xbtv`_pj''))
                quietly replace `_pterm' = 0 if `touse' & missing(`_pterm') ///
                    & !`_pbad' & `_ppiece' == 0
                quietly replace `_povf' = 1 if `touse' & missing(`_pterm') ///
                    & !`_pbad'
                quietly replace `_plam' = `_plam' + `_pterm' if `touse'
                if `_pj' < `_fg_nint' {
                    if `_p_bs' quietly replace `_plov' = `_pcv`_pj'' if `touse'
                    else       quietly replace `_plov' = `_phi' if `touse'
                }
            }
            * A missing `_plam' with neither flag set is the SUM overflowing,
            * which is the same limit as a term overflowing.
            quietly gen `typlist' `varlist' = cond(`_pbad', ., ///
                cond(`_povf' | missing(`_plam'), 1, 1 - exp(-`_plam'))) if `touse'
        }
        local _created_vars "`varlist'"

        * Commit contract (Critical Rule 15).  `touse' being non-empty is not
        * the same fact as the CIF having a value on any of its rows.  The
        * linear predictor is `matrix score'd from the caller's data, and a
        * scoring covariate that is missing on every prediction row makes every
        * CIF missing -- `finegray_predict cifhat, cif' after `replace ifp = .'
        * returned rc 0 with 0 of 109 non-missing values, a column of pure
        * missings labelled as a cumulative incidence.  Registered in
        * `_created_vars' first, so the refusal drops the variable and leaves
        * the dataset as it was.
        _finegray_assert_cardinality `varlist', touse(`touse') ///
            label("cif prediction")

        * Name the evaluation basis in the label.  `cif' without timevar()
        * evaluates at each subject's own _t and `cif timevar(h5)' at h5; the
        * generic "CIF prediction" left `describe' unable to tell the two apart,
        * and the difference is the whole meaning of the column.
        label variable `varlist' "CIF at `tvar' (cause `=e(cause)')"

        * Confidence interval via influence-function SE of the CIF
        if "`ci'" != "" {
            local lci "`varlist'_lci"
            local uci "`varlist'_uci"
            confirm new variable `lci'
            confirm new variable `uci'

            tempvar se_cif
            quietly gen double `se_cif' = .
            if `bootstrap' > 0 {
                * Full-refit subject-bootstrap SE; resample in a separate frame
                * so the eval data (and accumulators) stay intact, and hold the
                * user's e() across the refits.
                * e(refitcmd), not e(cmdline): the refit runs on data already
                * restricted to e(sample) and then resampled, so the user's
                * `if'/`in' qualifier is meaningless there.  Replaying
                * `in 101/200' against a 100-row resample selected no rows and
                * failed every replication (rc 498, 0/B).
                local _fgcmd `"`e(refitcmd)'"'
                local _fgclust `"`e(clustvar)'"'
                local _fgcovs `"`e(designvars)'"'
                tempvar _bsid _bsclust
                * Repeated draws of the same original cluster need a fresh
                * bootstrap-cluster identity. Rewrite only the private replay;
                * e(refitcmd) remains expressed in the user's variable names.
                local _fgbscmd `"`_fgcmd'"'
                if `"`_fgclust'"' != "" {
                    local _fgbscmd : subinstr local _fgcmd ///
                        "cluster(`_fgclust')" "cluster(`_bsclust')", all
                    if `"`_fgbscmd'"' == `"`_fgcmd'"' {
                        display as error "internal bootstrap error: cluster() is absent from e(refitcmd)"
                        exit 498
                    }
                }
                tempvar _bsum _bss
                quietly gen double `_bsum' = 0 if `touse'
                quietly gen double `_bss' = 0 if `touse'

                * Baseline strata the predictions actually need.  Read from the
                * CALLER's evaluation sample, once, before any resampling: a
                * replication that cannot supply a baseline for one of these
                * cannot contribute to those rows' SE, and is skipped below.
                * Held in %21x: these levels are compared for equality
                * against e(bstrata_noevent_x) and against the resample's own
                * rows, and `levelsof, clean' renders a noninteger level to
                * about the last bit, so a display spelling would match
                * nothing and the skip logic would never fire.
                local _bsneed ""
                if `"`_bsvar'"' != "" {
                    tempname _bsnmat
                    quietly levelsof `_bsvar' if `touse', local(_bsneed) clean ///
                        matrow(`_bsnmat')
                    local _nbsn = rowsof(`_bsnmat')
                    local _bsneed ""
                    forvalues _b = 1/`_nbsn' {
                        local _hx : display %21x `_bsnmat'[`_b', 1]
                        local _hx = strtrim("`_hx'")
                        local _bsneed "`_bsneed' `_hx'"
                    }
                    local _bsneed : list retokenize _bsneed
                }

                tempname _bf
                frame copy `c(frame)' `_bf'
                local _bframe = 1
                frame `_bf': quietly keep if e(sample)
                * Refits must see each subject's true entry time, not the
                * kept record's own interval start (multi-record reduction)
                if "`_t0var'" != "_t0" {
                    frame `_bf': quietly replace _t0 = `_t0var'
                }
                tempfile _bdata
                frame `_bf': quietly save `"`_bdata'"'

                tempname _esth
                _estimates hold `_esth', restore
                local _held = 1
                * Each refit below calls finegray again and overwrites the single
                * slot in the Mata baseline cache, minting a key the held
                * e(bh_key) does not name.  Without this, a later `predict, cif' on
                * new data (estimation sample dropped) finds a key mismatch and
                * errors r(459).  Snapshot the cache now and restore it after the
                * loop.  Each replication reads its own key-matched entry before
                * the next refit overwrites it, so the final restore cannot affect
                * the bootstrap SE.
                mata: _finegray_bh_stash()
                local _bh_stashed = 1
                * seed() must not reposition the CALLER's random-number stream:
                * a user who asks for reproducible replicates gets them, and
                * every rnormal() they draw afterwards is exactly the one they
                * would have drawn had the bootstrap not run.  Snapshot here,
                * restore in the cleanup zone (which also runs on error paths).
                local _rngstate = c(rngstate)
                local _rngsaved = 1
                if "`seed'" != "" set seed `seed'

                local _bok = 0
                forvalues b = 1/`bootstrap' {
                    frame `_bf' {
                        quietly use `"`_bdata'"', clear
                        * Resample whole clusters as units when the fit
                        * declared cluster(); otherwise resample subjects.
                        if `"`_fgclust'"' != "" {
                            bsample, cluster(`_fgclust') idcluster(`_bsclust')
                        }
                        else bsample
                        * e(sample) has one reduced record per subject. Use a
                        * fresh survival id without overwriting any user variable.
                        quietly gen long `_bsid' = _n
                        char _dta[st_id] "`_bsid'"
                        * finegray always leaves this refit's baseline in the
                        * sequence-keyed Mata cache.  Do NOT append basehaz:
                        * posting the K-row e(basehaz) matrix is O(K^2), repeated
                        * once per replication.
                        capture `_fgbscmd'
                        local _reprc = _rc
                        if !`_reprc' & e(converged) != 1 local _reprc = 498
                        * A resample can lose a factor level, so the refit
                        * posts a shorter e(b) that no longer conforms with
                        * the stored design; skip the replication.
                        if !`_reprc' & `"`e(designvars)'"' != `"`_fgcovs'"' ///
                            local _reprc = 459
                        * Every stratum the evaluation rows ask for must still
                        * carry a baseline in this refit.  A resample can drop a
                        * small stratum, or every cause event in it; that
                        * replication is skipped and counted, rather than
                        * aborting the whole bootstrap at the baseline lookup.
                        if !`_reprc' & "`_bsneed'" != "" {
                            local _bsne_r `"`e(bstrata_noevent_x)'"'
                            foreach _bsl_r of local _bsneed {
                                local _bshit_r : list posof "`_bsl_r'" in _bsne_r
                                if `_bshit_r' > 0 {
                                    local _reprc = 459
                                    continue, break
                                }
                                quietly count if `_bsvar' == `_bsl_r'
                                if r(N) == 0 {
                                    local _reprc = 459
                                    continue, break
                                }
                            }
                        }
                        if !`_reprc' local _fg_repkey `"`e(bh_key)'"'
                    }
                    if `_reprc' continue
                    * The refit replays e(refitcmd), which carries tvc() and
                    * tsplit(), so each replication is the SAME estimator as the
                    * point estimate.  Its CIF must therefore be accumulated the
                    * same way -- piecewise -- or the bootstrap SD would describe
                    * a proportional CIF wrapped around a piecewise one.
                    if `_fg_istvc' {
                        quietly mata: _finegray_boot_cif_obs_tvc( ///
                            "`_score_varlist'", "`tvar'", "`touse'", ///
                            "`_bsum'", "`_bss'", "`_fg_repkey'", ///
                            "`_fg_tvcpos'", "`_fg_cuts'", "`_bsvar'")
                    }
                    else {
                        quietly mata: _finegray_boot_cif_obs("`_score_varlist'", ///
                            "`tvar'", "`touse'", "`_bsum'", "`_bss'", ///
                            "`_fg_repkey'", "`_bsvar'")
                    }
                    local ++_bok
                }
                frame drop `_bf'
                local _bframe = 0
                _estimates unhold `_esth'
                local _held = 0
                * Restore the fit's own baseline curve to the cache so a later
                * predict on new data resolves against e(bh_key) instead of the
                * last resample's curve.
                mata: _finegray_bh_unstash()
                local _bh_stashed = 0

                if `_bok' < `_minboot' {
                    display as error "bootstrap failed: only `_bok' of `bootstrap' replications succeeded"
                    display as error "at least `_minboot' are required to estimate a standard error"
                    exit 498
                }
                if `_bok' < `bootstrap' {
                    display as text "(note: `=`bootstrap'-`_bok'' of `bootstrap' bootstrap replications failed and were skipped)"
                }
                * Clamp the variance at 0 BEFORE the sqrt.  This is the
                * computational form, so replicates that agree to machine
                * precision (an evaluation time before the first cause event,
                * where every replication returns CIF = 0) leave a tiny
                * NEGATIVE residual after the cancellation, and sqrt() of it is
                * MISSING -- reporting "we cannot quantify this" where the
                * truth is a bootstrap SD of exactly zero.
                *
                * cond(v < 0, 0, v), NOT max(0, v).  Stata's max() IGNORES
                * missing, so max(0, .) is 0: a replication that genuinely
                * produced a missing CIF would be laundered into an SE of
                * exactly zero and then into a zero-width confidence interval,
                * which is the fabricated-certainty defect this command fixed
                * in v1.1.0.  `. < 0' is FALSE (missing sorts above every
                * number), so cond() passes missing through untouched.
                tempvar _bvar
                quietly gen double `_bvar' = ///
                    (`_bss' - `_bsum'^2/`_bok')/(`_bok'-1) if `touse'
                quietly replace `_bvar' = 0 if `_bvar' < 0 & `touse'
                quietly replace `se_cif' = sqrt(`_bvar') if `touse'
            }
            else {
                * Combine multiple strata variables into a single group
                * variable (the Mata engine expects one column)
                local _byg_mata "`e(strata)'"
                local _byg_nvar : word count `e(strata)'
                if `_byg_nvar' > 1 {
                    tempvar _byg_grp
                    _finegray_weight_groups, strata(`e(strata)') ///
                        bygname(`_byg_grp') touse(`_fvbasis')
                    local _byg_mata "`_byg_grp'"
                }
                local _tg_mata ""
                if `"`e(truncstrata)'"' != "" {
                    tempvar _tg_grp
                    _finegray_weight_groups, truncstrata(`e(truncstrata)') ///
                        tgname(`_tg_grp') touse(`_fvbasis')
                    local _tg_mata "`_tg_grp'"
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
                _finegray_weight_var, wname(`_fg_wv') touse(`_fvbasis')
                local _fg_wmata "`_fg_wv'"
                local _fg_wtype = r(wtype)
            }

                * Belt to the parser brace above: the influence function here
                * is derived for a single exp(z'b) at every baseline increment
                * and is NOT the piecewise one.  Reaching it on a tvc() fit
                * would post a plausible SE with no derivation behind it.
                mata: _finegray_cif_predict( ///
                    "`_score_varlist'", "`e(compete)'", `=e(cause)', ///
                    `=e(censvalue)', "`_byg_mata'", "`_tg_mata'", "`e(clustvar)'", ///
                    "`_fvbasis'", "`touse'", "`tvar'", ///
                    "`se_cif'", "`_t0var'", "`_bsvar'", ///
                    "`_fg_tvcpos'", "`_fg_cuts'", "`_fg_wmata'", `_fg_wtype')
            }

            * Complementary log-log limits keep the interval inside (0,1):
            * g = ln(-ln(1-CIF)), SE(g) = SE(CIF)/((1-CIF)*(-ln(1-CIF)))
            local z = invnormal(1 - (1 - `level'/100)/2)
            tempvar gpt segp
            quietly gen double `gpt' = ln(-ln(1 - `varlist')) ///
                if `touse' & `varlist' > 0 & `varlist' < 1
            quietly gen double `segp' = `se_cif' / ///
                ((1 - `varlist') * (-ln(1 - `varlist'))) ///
                if `touse' & `varlist' > 0 & `varlist' < 1
            quietly gen double `lci' = /// stata-dev-ignore: unchecked-commit — guarded by the _finegray_assert_cardinality call below, after both limits are registered for cleanup
                1 - exp(-exp(`gpt' - `z' * `segp')) if `touse'
            quietly gen double `uci' = /// stata-dev-ignore: unchecked-commit — guarded by the _finegray_assert_cardinality call below, after both limits are registered for cleanup
                1 - exp(-exp(`gpt' + `z' * `segp')) if `touse'
            local _created_vars "`_created_vars' `lci' `uci'"
            * A limit that could not be computed stays MISSING.  Through v1.1.0
            * these two lines collapsed it onto the point estimate, which turns
            * "we cannot quantify the uncertainty here" into "there is none":
            * a degenerate CIF, or an interior CIF whose SE came back nonfinite,
            * was shipped as a zero-width confidence interval.
            *
            * Commit contract (Critical Rule 15).  A row-wise missing limit is
            * deliberate (see above); ALL of them missing is not a confidence
            * interval at all.  It happens whenever the transform is undefined
            * everywhere -- a CIF that is identically 0 at a horizon before the
            * first cause event, or an SE that came back nonfinite on every row.
            * `finegray_predict p, cif ci timevar(t)' with t below the first
            * event time returned rc 0 and shipped p_lci and p_uci with 0 of 109
            * non-missing values.  Both limits are already in `_created_vars',
            * so the refusal removes them and the point estimate with them.
            _finegray_assert_cardinality `lci', touse(`touse') ///
                label("cif confidence limits")

            label variable `lci' "CIF lower `level'% limit"
            label variable `uci' "CIF upper `level'% limit"
        }
    }
    else if "`schoenfeld'" != "" {
        * Schoenfeld residuals: creates stub_1, stub_2, ... for each covariate
        * Only defined at cause-event observations
        local covariates "`_score_labels'"
        local events_var "`e(compete)'"
        local cause_val = e(cause)
        local censvalue_val = e(censvalue)
        local byg_var "`e(strata)'"
        local p : word count `covariates'

        * Pre-check every stub name BEFORE the residuals are computed.  This
        * check used to sit after the Mata pass and the preserve/restore, so a
        * name collision or an over-long stub cost the whole computation first.
        * It also reported every failure as "already exists"; `confirm new
        * variable' returns 110 for a taken name and 198 for one that is
        * malformed or too long, and with p covariates the suffix _`p' eats up
        * to 1 + length("`p'") of the 32-character budget.
        if `p' > 1 {
            local _pre_stub = "`varlist'"
            forvalues _pv = 2/`p' {
                local _pvname "`_pre_stub'_`_pv'"
                capture confirm new variable `_pvname'
                if _rc == 110 {
                    display as error "variable `_pvname' already exists"
                    display as error "{bf:schoenfeld} creates `_pre_stub'_2 ... `_pre_stub'_`p'"
                    display as error "alongside `_pre_stub' (one per covariate)"
                    exit 110
                }
                else if _rc {
                    display as error "`_pvname' is not a valid variable name"
                    display as error "{bf:schoenfeld} appends _2 ... _`p' to the new variable name,"
                    display as error "so with `p' covariates the name may be at most"
                    display as error "`=32 - 1 - length("`p'")' characters (`_pre_stub' is `=length("`_pre_stub'")')"
                    exit 198
                }
            }
        }

        * Load Mata engine
        capture mata: _finegray_mata_ok()
        * probe MATA, not a Stata program: `mata clear' drops Mata functions but
        * leaves Stata programs standing, so a program sentinel says "loaded" when
        * the engine is gone and the next Mata call dies with r(3499).
        if _rc {
            capture findfile _finegray_mata.ado
            if _rc == 0 {
                run "`r(fn)'"
            }
            else {
                display as error "_finegray_mata.ado not found; reinstall finegray"
                exit 111
            }
        }

        * Compute on estimation sample
        preserve
        quietly keep if e(sample)
        tempvar _pre_obs_id
        gen long `_pre_obs_id' = _n
        sort _t `_pre_obs_id'

        local _byg_mata "`byg_var'"
        if "`byg_var'" != "" {
            local _byg_nvar : word count `byg_var'
            if `_byg_nvar' > 1 {
                tempvar _byg_grp
                _finegray_weight_groups, strata(`byg_var') bygname(`_byg_grp')
                local _byg_mata "`_byg_grp'"
            }
        }

        local _tg_mata ""
        if `"`e(truncstrata)'"' != "" {
            tempvar _tg_grp
            _finegray_weight_groups, truncstrata(`e(truncstrata)') tgname(`_tg_grp')
            local _tg_mata "`_tg_grp'"
        }

        * Design weights: the residual is Z_i - zbar_w(T_i), with the weighted
        * risk-set mean the fit used.  Every row here is estimation-sample.
        tempvar _fg_sall
        quietly gen byte `_fg_sall' = 1
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
            _finegray_weight_var, wname(`_fg_wv') touse(`_fg_sall')
            local _fg_wmata "`_fg_wv'"
            local _fg_wtype = r(wtype)
        }

        mata: _finegray_schoenfeld_compute( ///
            "`_score_varlist'", "`events_var'", `cause_val', `censvalue_val', ///
            "`_byg_mata'", "`_tg_mata'", 0, "`_t0var'", "`_bsvar'", ///
            "`_fg_wmata'", `_fg_wtype')

        restore

        tempname sch_mat
        matrix `sch_mat' = _finegray_schoenfeld
        capture matrix drop _finegray_schoenfeld

        local n_fail = rowsof(`sch_mat')

        * Create stub variables for all covariates (names pre-checked above,
        * before the residuals were computed)
        if "`typlist'" == "" local typlist "double"
        quietly gen `typlist' `varlist' = .
        local _created_vars "`varlist'"

        local cov_1 : word 1 of `covariates'
        label variable `varlist' "Schoenfeld residual: `cov_1'"

        local _sch_varnames "`varlist'"
        if `p' > 1 {
            local stub = "`varlist'"
            forvalues v = 2/`p' {
                local vname "`stub'_`v'"
                quietly gen `typlist' `vname' = .
                local _created_vars "`_created_vars' `vname'"
                local cov_v : word `v' of `covariates'
                label variable `vname' "Schoenfeld residual: `cov_v'"
                local _sch_varnames "`_sch_varnames' `vname'"
            }
        }

        * Mark cause events in estimation sample
        quietly count if e(sample) & `events_var' == `cause_val' & _d == 1
        if r(N) != `n_fail' {
            display as text "note: `n_fail' Schoenfeld residuals for " ///
                "`r(N)' cause events"
        }

        * Assign residuals via Mata index lookup (O(N) vs O(N*n_fail))
        * Stable sort by _t with observation ID as tiebreaker to match
        * the preserve-block sort order for tied event times
        tempvar _obs_id
        gen long `_obs_id' = _n
        sort _t `_obs_id'
        tempvar _is_cause_evt _cumcount
        quietly gen byte `_is_cause_evt' = ///
            (e(sample) & `events_var' == `cause_val' & _d == 1)
        quietly gen long `_cumcount' = sum(`_is_cause_evt') ///
            if `_is_cause_evt' == 1

        mata: _finegray_assign_schoenfeld_vars( ///
            "`sch_mat'", "`_cumcount'", ///
            tokens("`_sch_varnames'"), `p')

        * Enforce if/in: blank residuals outside the requested sample
        quietly replace `varlist' = . if !`touse'
        if `p' > 1 {
            local stub = "`varlist'"
            forvalues v = 2/`p' {
                quietly replace `stub'_`v' = . if !`touse'
            }
        }
    }

    } /* end capture noisily */

    local rc = _rc
    if `_bframe' capture frame drop `_bf'
    if `_held' capture _estimates unhold `_esth'
    * Give the caller back the random-number stream the bootstrap borrowed.
    if `_rngsaved' capture set rngstate `_rngstate'
    * A bootstrap that errored mid-loop leaves the cache snapshotted; restore it so
    * the fit's baseline stays resolvable (falls back to prior behaviour if it too
    * fails -- no worse than not stashing).
    if `_bh_stashed' {
        capture mata: _finegray_bh_unstash()
        * Saved on the very next line: the first `display' below would otherwise
        * reset _rc to 0 and the message would report rc = 0.
        local _unstash_rc = _rc
        * Captured on purpose: this runs in the cleanup zone, where raising a new
        * error would mask the one that brought us here.  But it must not fail
        * SILENTLY -- the cache stays snapshotted, and the next command that
        * needs the fit's baseline hits a stale or missing one with no clue why.
        if `_unstash_rc' {
            display as error "note: the baseline-hazard cache could not be restored"
            display as error "(mata: _finegray_bh_unstash failed, rc = `_unstash_rc'); re-run"
            display as error "{bf:finegray} before further post-estimation"
        }
    }
    * All-or-nothing output: drop any permanent variables this call created
    * when it exits with an error, so a failed ci/bootstrap/schoenfeld path
    * does not leave a partial prediction behind.
    if `rc' & "`_created_vars'" != "" {
        foreach _cv of local _created_vars {
            capture drop `_cv'
        }
    }
    set varabbrev `_orig_varabbrev'
    * Isolate helper r() results; this command intentionally returns nothing.
    return clear
    if `rc' exit `rc'
end
