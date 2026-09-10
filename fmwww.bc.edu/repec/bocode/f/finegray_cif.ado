*! finegray_cif Version 1.3.2  2026/09/08
*! Cumulative incidence curves and fixed-horizon CIF after finegray
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: rclass (returns results in r())

/*
Basic syntax:
  finegray_cif [, at(var=# ...) over(varname) attime(numlist)
                  timepoints(numlist) ci level(#) saving(filename)
                  nograph twoway_options]

Description:
  Predicted cumulative incidence function (CIF) after finegray, for a chosen
  covariate profile, with optional pointwise confidence band (an analogue of
  stcurve, cif that can also plot the CI).

  Default            plots a step-function CIF from the exact origin over the
                     event-time grid.
  attime(numlist)    reports a table of CIF (and CI) at the listed horizons.
  at(var=# ...)      sets the covariate profile (default: estimation-sample means).
  over(varname)      one curve per level of a model variable (or per fitted
                     baseline stratum), overlaid in one call; results stacked.
  ci                 adds influence-function confidence limits (cloglog scale).
  saving(filename)   writes the numeric estimates (time cif se lci uci) to a
                     dataset (the outfile analogue).

See help finegray_cif for complete documentation.
*/

program define finegray_cif, rclass sortpreserve
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    local _preserved = 0
    local _held = 0
    local _bh_stashed = 0
    local _rngsaved = 0
    local _rngstate ""
    local _side_rc = 0
    local _fgrebuilt ""

    capture noisily {

    syntax [, AT(string) OVER(varname numeric) ATTime(string) ///
        TImepoints(string) CI Level(string) ///
        BSTRATum(string) ///
        SAVing(string) BOOTstrap(integer 0) SEED(string) noGRAPH *]

    * level() is parsed as a string (not cilevel) so an OMITTED level() is empty
    * and distinguishable from an explicit one -- cilevel would auto-fill it with
    * c(level), making the "level() requires ci" guard misfire on every plain
    * finegray_cif call.  Validated as a confidence level below when supplied.

    * bstratum() is parsed as a string, not numlist, and the LITERAL token is
    * kept -- exactly as at() keeps its values.  numlist normalises what it
    * reads to about ten significant digits, so bstratum(.1000000000000001)
    * arrived here as `.1': a noninteger baseline stratum was unaddressable,
    * and the request silently resolved to a different stratum or to none.
    if `"`bstratum'"' != "" {
        capture confirm number `bstratum'
        if _rc {
            display as error "bstratum(): `bstratum' is not a number"
            exit 198
        }
        if real(`"`bstratum'"') >= . {
            display as error "bstratum() must be a finite number"
            exit 198
        }
    }

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
    * FG-07: bootstrap() and level() shape a confidence interval, so both require
    * ci.  Before this guard, bootstrap() without ci performed every refit and
    * changed the SE but returned missing interval limits, and level() without ci
    * was parsed and ignored -- either one silently accepted an analysis option
    * that had no effect.  This mirrors finegray_predict.
    if `bootstrap' > 0 & "`ci'" == "" {
        display as error "bootstrap() requires the ci option"
        exit 198
    }
    if "`level'" != "" & "`ci'" == "" {
        display as error "level() requires the ci option"
        exit 198
    }
    * FG-07 again: attime() and timepoints() are two ways of naming the same
    * thing -- the times the CIF is evaluated at -- and the grid builder below
    * takes attime() first, so the pair used to run at rc 0 with timepoints()
    * parsed, dropped, and never mentioned.  `finegray_cif, attime(4)
    * timepoints(1 2 3)' returned a one-row table at t = 4.  Neither is a
    * modifier of the other (attime() also selects table mode over curve mode),
    * so there is no defensible winner to pick silently.
    if "`attime'" != "" & "`timepoints'" != "" {
        display as error "attime() and timepoints() may not be combined"
        display as error "both set the times the CIF is evaluated at: use {bf:attime()}"
        display as error "for a table at specific times, {bf:timepoints()} for a curve"
        display as error "evaluated on a grid you supply"
        exit 198
    }

    * attime() and timepoints() are declared as strings and validated here so
    * that a bad list gets this command's message.  Declared as
    * `numlist sort >=0', `finegray_cif, attime(-1)' died inside `syntax' on
    * Stata's raw "invalid numlist has elements outside of allowed range"
    * (r(125)), which names neither the option nor the rule -- out of step with
    * every neighbouring guard.  The validated list is written back in the same
    * expanded, sorted form `syntax' produced, so nothing downstream changes.
    * The horizons are USED AS TYPED.  numlist validates the list (a bad element
    * gets this command's message, not `syntax''s), but its r(numlist) is text
    * rounded to nine significant digits, and writing that back replaced the
    * request: attime(.1000000000000001) became .1, which precedes a cause
    * event at .1000000000000001, so the CIF there was reported as exactly 0
    * with a note that the time precedes the first event, at rc 0.  The step
    * function moves at the event, and 1e-16 is enough to miss it; the same
    * rounding merged attime(.1 .1000000000000001) into one row.  So the
    * user's own tokens are kept whenever every token is a plain number, and
    * the list is sorted and de-duplicated BY VALUE (a string comparison would
    * keep .1 and 0.1 as two rows).  Range syntax (0(1)10, 1/5, `to') is
    * expanded by numlist as before: those values come from arithmetic and
    * carry no typed precision to lose.
    foreach _fgopt in attime timepoints {
        if `"``_fgopt''"' == "" continue
        capture numlist `"``_fgopt''"', sort range(>=0)
        if _rc {
            display as error "`_fgopt'(): {bf:``_fgopt''} is not a usable list of analysis times"
            if "`_fgopt'" == "attime" {
                display as error "supply one or more numbers >= 0, e.g. {bf:attime(1 3 5)}"
            }
            else display as error "supply one or more numbers >= 0, e.g. {bf:timepoints(0(1)10)}"
            exit 198
        }
        local _fg_expanded `"`r(numlist)'"'
        local _fg_raw : list retokenize `_fgopt'
        * Token by token: a plain number is kept as typed, a one-token range
        * (0(1)10, 1/5, 1[1]5) is expanded on its own.  The multi-token forms
        * `1 2 to 5' and `1 2 : 5' read their step from the tokens before
        * them, so a list containing `to' or `:' is taken from numlist whole.
        local _fg_multi : list posof "to" in _fg_raw
        if `_fg_multi' == 0 local _fg_multi : list posof ":" in _fg_raw
        if `_fg_multi' == 0 {
            local _fg_kept ""
            foreach _v of local _fg_raw {
                capture confirm number `_v'
                if _rc == 0 local _fg_kept "`_fg_kept' `_v'"
                else {
                    * The whole list passed numlist above, so a token that
                    * fails on its own is one that reads its neighbours;
                    * hand the whole list to numlist's expansion instead.
                    capture numlist "`_v'"
                    if _rc {
                        local _fg_multi = 1
                        continue, break
                    }
                    local _fg_kept "`_fg_kept' `r(numlist)'"
                }
            }
        }
        if `_fg_multi' == 0 {
            * Sort permutation by value.  Built-in Mata only: the package
            * engine is loaded further down, after the parse.
            mata: st_local("_fg_ord", invtokens(strofreal(order(strtoreal(tokens(st_local("_fg_kept")))', 1)')))
            local _fg_sorted ""
            foreach _i of local _fg_ord {
                local _fg_sorted "`_fg_sorted' `: word `_i' of `_fg_kept''"
            }
        }
        else local _fg_sorted `"`_fg_expanded'"'
        * Collapse repeats: numlist's `sort' keeps duplicates, and every
        * duplicate became a duplicate ROW of the table (and a repeated marker
        * on the curve): attime(1 1 2) printed t = 1 twice at rc 0 with
        * r(table) one row longer than the horizons asked for, so a caller
        * assembling several profiles double-counted it.  A repeated horizon
        * carries no information a single one does not, so collapse the list
        * rather than refuse it.  The comparison is numeric on the sorted
        * list, so equal values adjacent in it collapse whatever their text.
        local _fg_uniq ""
        local _fg_prev ""
        foreach _v of local _fg_sorted {
            if "`_fg_prev'" != "" {
                if `_v' == `_fg_prev' continue
            }
            local _fg_uniq "`_fg_uniq' `_v'"
            local _fg_prev "`_v'"
        }
        local `_fgopt' : list retokenize _fg_uniq
    }

    * =====================================================================
    * VALIDATE STATE
    * =====================================================================
    if "`e(cmd)'" != "finegray" {
        * After `mi estimate, cmdok: finegray ...' the results in e() are mi's
        * pooled ones, not a finegray fit, and "you must run finegray" reads as
        * though the user had not -- when they just did.  Name what actually
        * happened, and where post-estimation does live.
        if "`e(cmd)'" == "mi estimate" & "`e(cmd_mi)'" == "finegray" {
            display as error "post-estimation is not available after {bf:mi estimate}"
            display as error "e() holds the pooled estimates, and pooled estimates have no"
            display as error "single baseline hazard for {bf:finegray_cif} to work from"
            display as error "refit on a single dataset -- {bf:mi extract 0, clear} for the"
            display as error "complete-case data, or {bf:mi extract #, clear} for one imputation --"
            display as error "and run {bf:finegray} there; see {help finegray##mi:help finegray}"
            exit 301
        }
        display as error "last estimates not found"
        display as error "you must run {bf:finegray} before using finegray_cif"
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
        display as error "{bf:finegray_cif} needs the fit's design columns and its"
        display as error "baseline hazard, neither of which a fit on mi data leaves behind"
        display as error "refit on a single dataset -- {bf:mi extract 0, clear} for the"
        display as error "complete-case data, or {bf:mi extract #, clear} for one imputation --"
        display as error "and run {bf:finegray} there; see {help finegray##mi:help finegray}"
        exit 301
    }
    * A nonconverged fit posts e(b), and e(b) is all this command reads. Without
    * this gate a CIF and its confidence band are built from a last iterate that
    * is not a solution -- rc 0, no warning, silently wrong.
    if e(converged) != 1 {
        display as error "last estimates did not converge"
        display as error "finegray_cif requires a converged fit; refit finegray"
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
    _finegray_check_data

    * =====================================================================
    * PIECEWISE beta(t)
    * =====================================================================
    * The point estimate is defined and computed: CIF(s|z) accumulates the
    * baseline over each interval with that interval's own linear predictor.
    * The ANALYTIC interval is not.  Its influence function (see
    * _finegray_cif_core) is derived for a single exp(z'b) multiplying every
    * Breslow increment; under beta(t) each increment carries its own interval's
    * predictor and its own risk-set total, and the prefix-sum scaffolding and
    * the beta-derivative term both change shape.  Reporting the proportional
    * one for a piecewise fit would be a wrong band at rc 0, so the bootstrap --
    * which refits the whole model on each resample and needs no derivation --
    * is the supported route and is named here rather than left to be found.
    local _fg_tvc `"`e(tvc)'"'
    local _fg_cuts `"`e(tsplit)'"'
    local _fg_tvcpos `"`e(tvc_pos)'"'
    local _fg_nint = e(n_intervals)
    if `_fg_nint' >= . local _fg_nint = 1
    local _fg_istvc = ("`_fg_tvc'" != "")
    if `_fg_istvc' & (`_fg_nint' < 2 | "`_fg_cuts'" == "" | "`_fg_tvcpos'" == "") {
        display as error "estimation results predate this version of finegray"
        display as error "re-run {bf:finegray} before using finegray_cif"
        exit 301
    }
    * FENCE LIFTED 2026-08-26 (variance unification).  Development builds refused an analytic ci after a
    * tvc() fit because the CIF influence function was derived for a single
    * exp(z'b) at every baseline increment, and under a piecewise beta(t) each
    * increment carries its own interval's linear predictor and its own
    * risk-set total.  It has now been re-derived -- the derivation is written
    * out in the header of _finegray_cif_core_pw in _finegray_mata.ado
    * -- and the piecewise variant reuses
    * the SAME accumulators the proportional one uses (_finegray_cif_accum),
    * differing only in the combination over intervals.  bootstrap(#) remains
    * available and is the arm the analytic route is checked against.

    * =====================================================================
    * BASELINE STRATA
    * =====================================================================
    * Under bstrata() the baseline subdistribution hazard is free in each
    * stratum, so at() no longer identifies a curve: the same covariate profile
    * has K different CIFs, one per stratum.  Requiring bstratum() is the only
    * honest option -- picking a stratum silently would report one of K answers
    * with nothing on screen to say which, and averaging them is a different
    * estimand (it needs declared stratum weights) that this version does not
    * implement.
    local _bsvar `"`e(bstrata)'"'
    local _kbs = 1
    if "`e(k_bstrata)'" != "" local _kbs = e(k_bstrata)
    if `"`_bsvar'"' != "" & `_kbs' > 1 {
        * over(bstrata variable) draws every stratum, so it stands in for
        * bstratum(); the pair is refused further down.
        if "`bstratum'" == "" & "`over'" != "`_bsvar'" {
            display as error "bstratum() is required after a fit with bstrata(`_bsvar')"
            display as error "each baseline stratum has its own baseline subdistribution"
            display as error "hazard, so a covariate profile alone does not identify a CIF"
            display as error "name the stratum, as in {bf:finegray_cif, bstratum(#)}, where # is"
            display as error "a value of `_bsvar'; see {help finegray_cif##bstratum:help finegray_cif}"
            exit 198
        }
        capture confirm numeric variable `_bsvar'
        if _rc {
            display as error "baseline strata variable `_bsvar' not found"
            display as error "finegray was fit with {bf:bstrata(`_bsvar')}; finegray_cif needs"
            display as error "that variable to identify the requested stratum's baseline"
            exit 111
        }
        * The two checks below judge the ONE stratum bstratum() named; under
        * over(`_bsvar') there is none yet, and the overlay block applies the
        * no-event rule to every fitted level itself.
        if "`bstratum'" != "" {
            * Refuse a stratum the fit never saw, by name and with the fitted levels
            * listed.  Left to the baseline lookup this surfaces as a bare r(459)
            * from Mata, several hundred lines of work later.
            quietly count if e(sample) & `_bsvar' == `bstratum'
            if r(N) == 0 {
                quietly levelsof `_bsvar' if e(sample), local(_bslevels) clean
                display as error "bstratum(`bstratum') is not a fitted baseline stratum"
                display as error "the estimation sample holds `_bsvar' levels: `_bslevels'"
                exit 459
            }
            * A stratum with no cause event has an identically zero Breslow
            * baseline.  That is a degenerate curve, not an estimate of one, and a
            * CIF drawn from it is a flat line at exactly 0 that reads as a finding.
            * The levels are named at fit time in e(bstrata_noevent_x),
            * which serializes them in %21x.  The readable e(bstrata_noevent)
            * rounds a noninteger stratum, so `list posof' against it misses
            * the very level this block exists to refuse.
            local _bsne `"`e(bstrata_noevent_x)'"'
            local _usex = `"`_bsne'"' != ""
            local _bsx : display %21x `bstratum'
            local _bsx = strtrim("`_bsx'")
            * A fit stored before e(bstrata_noevent_x) existed carries only the
            * readable macro; compare in that vocabulary rather than matching
            * nothing and letting the degenerate stratum through.
            if !`_usex' local _bsne `"`e(bstrata_noevent)'"'
            if `"`_bsne'"' != "" {
                local _bshit = 0
                if `_usex' {
                    local _bshit : list posof "`_bsx'" in _bsne
                }
                else {
                    * On the fallback both sides are NUMBERS written as text,
                    * and bstratum() keeps the literal token the user typed:
                    * `bstratum(2.0)' and `bstratum(+2)' name the stratum
                    * e(bstrata_noevent) spells "2".  A string `list posof'
                    * missed them and drew the degenerate stratum as a flat
                    * zero at rc 0.  Compare on the values.
                    local _nbsw : word count `_bsne'
                    local _bstgt = real("`bstratum'")
                    forvalues _bw = 1/`_nbsw' {
                        local _bsw : word `_bw' of `_bsne'
                        if !missing(real("`_bsw'"), `_bstgt') & ///
                            real("`_bsw'") == `_bstgt' local _bshit = `_bw'
                    }
                }
                if `_bshit' > 0 {
                    display as error "baseline stratum `bstratum' carried no cause `=e(cause)' event"
                    display as error "its baseline subdistribution hazard is identically zero, which is"
                    display as error "a degenerate curve rather than an estimate of one; there is no"
                    display as error "cumulative incidence to report for it"
                    display as error "see {help finegray##bstrata:help finegray}"
                    exit 459
                }
            }
        }
    }
    else if "`bstratum'" != "" {
        display as error "bstratum() requires a fit with more than one baseline stratum"
        if `"`_bsvar'"' == "" {
            display as error "these estimates were fit without {bf:bstrata()}, so there is a"
            display as error "single pooled baseline subdistribution hazard and no stratum"
            display as error "to select"
        }
        else {
            display as error "{bf:bstrata(`_bsvar')} took one value in the estimation sample,"
            display as error "so the fit has a single baseline and nothing to select from"
        }
        exit 198
    }
    * The stratum handed to Mata: a real value, or missing on an unstratified
    * fit, where every baseline call falls through to the pooled curve.
    * The selected baseline stratum, carried as a %21x string (or "." for
    * "no stratum selected").  %21x round-trips exactly through Stata's
    * numeric parser, so the same local drives the `==' restrictions, the
    * e(bstrata_noevent_x) membership test and -- through strtoreal() -- the
    * Mata baseline lookups, with no rounding step anywhere between.
    local _bslev = "."
    if "`bstratum'" != "" {
        local _bslev : display %21x `bstratum'
        local _bslev = strtrim("`_bslev'")
    }

    * No e(basehaz) requirement: the baseline is rebuilt in Mata from e(sample)
    * and e(b) (exactly, not approximately -- it re-runs the fit's own
    * _finegray_basehazard).  e(basehaz) is opt-in precisely because materialising
    * it as a Stata matrix is O(K^2); requiring it here would have forced every
    * finegray_cif user to pay that cost at fit time.
    capture confirm variable _t
    if _rc {
        display as error "finegray_cif requires the original stset estimation data"
        exit 111
    }
    quietly count if e(sample)
    if r(N) == 0 {
        display as error "no observations in estimation sample"
        exit 2000
    }
    if "`level'" == "" {
        local level = c(level)
    }
    else {
        * One bound, one message, in all four places -- Stata's own cilevel
        * rule, delegated so it cannot drift from `finegray, level()' again.
        _finegray_check_level, level(`level')
    }

    * Entry-time source: multi-record fits persist each subject's earliest
    * entry in a finegray-created variable; single-record fits use _t0.
    * The characteristic travels with the data, e(entryvar) with the estimates.
    * After `estimates use' over a dataset saved before the fit there is no
    * characteristic, and reading _t0 instead would silently substitute
    * per-record entry times for the subject-level ones the fit used.
    local _t0var "_t0"
    * Entry metadata belongs to the active estimates. An empty e(entryvar)
    * means _t0; a later fit's dataset characteristic cannot override it.
    local _fg_entrysrc `"`e(entryvar)'"'
    if `"`_fg_entrysrc'"' != "" {
        local _t0var `"`_fg_entrysrc'"'
        capture confirm numeric variable `_t0var'
        if _rc {
            display as error "variable `_t0var' not found"
            display as error "finegray recorded subject entry times in `_t0var' for its"
            display as error "multiple-record reduction; re-run finegray before finegray_cif"
            exit 111
        }
    }

    * Parse saving(filename[, replace]); reject shell metacharacters
    local savefile ""
    local savereplace ""
    if `"`saving'"' != "" {
        gettoken savefile _svrest : saving, parse(",") bind
        local savefile = strtrim(`"`savefile'"')
        local _svrest = lower(strtrim(`"`_svrest'"'))
        * Accept ",replace" and ", replace" alike: strip the leading comma,
        * then compare the bare suboption.
        if substr(`"`_svrest'"', 1, 1) == "," {
            local _svrest = strtrim(substr(`"`_svrest'"', 2, .))
        }
        if `"`savefile'"' == "" | !inlist(`"`_svrest'"', "", "replace") {
            display as error "saving() must be filename[, replace]"
            exit 198
        }
        if `"`_svrest'"' == "replace" local savereplace "replace"
        if strpos(`"`savefile'"', ";") | strpos(`"`savefile'"', "|") | ///
           strpos(`"`savefile'"', "&") | strpos(`"`savefile'"', "<") | ///
           strpos(`"`savefile'"', ">") | strpos(`"`savefile'"', "$") | ///
           strpos(`"`savefile'"', char(96)) | ///
           strpos(`"`savefile'"', char(34)) | ///
           strpos(`"`savefile'"', char(39)) {
            display as error "invalid characters in saving() filename"
            exit 198
        }
    }

    local covs "`e(designvars)'"
    local p : word count `covs'

    * =====================================================================
    * REBUILD DROPPED _fg_* DESIGN COLUMNS (contract: dropping them is supported)
    * =====================================================================
    * The package-owned _fg_* columns are DERIVED from the raw factor variables,
    * so _finegray_check_data treats dropping them as supported and expects each
    * consumer to rebuild on demand.  finegray_predict rebuilds from the fit-time
    * expansion e(fvsemantic) by level VALUE; do the same here.  The influence-
    * function SE path reads these columns from the data BY NAME (st_data over
    * e(designvars)), so they must be materialized as the real _fg_* names, not
    * tempvars -- but only the ones we create are dropped again in the cleanup
    * zone, so a read-only finegray_cif never leaks columns into the caller's
    * data.  A dropped RAW covariate (the user's own variable) cannot be rebuilt
    * and earns a curated refusal rather than a raw "variable not found" r(111).
    local _fvsem_r `"`e(fvsemantic)'"'
    local _nbterms ""
    if `"`_fvsem_r'"' != "" & `"`_fvsem_r'"' != "." {
        * Non-base semantic terms align 1:1, in order, with e(designvars).
        foreach _t of local _fvsem_r {
            if regexm("`_t'", "[0-9]+b\.") continue
            local _nbterms `"`_nbterms' `_t'"'
        }
    }
    local _cj = 0
    foreach _cv of local covs {
        local ++_cj
        capture confirm numeric variable `_cv'
        if !_rc continue
        * Missing column.  Only a package-owned _fg_* column may be rebuilt.
        if substr("`_cv'", 1, 4) != "_fg_" | `"`_nbterms'"' == "" {
            display as error "covariate `_cv' is missing and cannot be rebuilt"
            display as error "re-run {bf:finegray} before {bf:finegray_cif}, or restore the dropped variable"
            exit 459
        }
        local _term : word `_cj' of `_nbterms'
        local _tparts = subinstr(subinstr("`_term'", "##", "#", .), "#", " ", .)
        quietly gen double `_cv' = 1 if e(sample)
        * A rebuilt column IS package-owned: carry the dataset's current
        * ownership token onto it.  finegray refuses an existing _fg_* column
        * that does not carry that token (a user's own variable under the same
        * name), and `generate' does not copy characteristics -- so without
        * this stamp the rebuilt column looked like a user variable to the
        * bootstrap's own refits, and every replication was skipped with
        * "variable `_cv' exists and was not created by finegray" at rc 0
        * (finegray_cif then reported "0 of B replications succeeded").
        local _fgowntok `"`: char _dta[_finegray_owner]'"'
        if `"`_fgowntok'"' != "" char `_cv'[_finegray_owner] `"`_fgowntok'"'
        local _fgrebuilt "`_fgrebuilt' `_cv'"
        foreach _tp of local _tparts {
            if regexm("`_tp'", "^([0-9]+)[a-z]*\.(.+)$") {
                local _flev = regexs(1)
                local _fvar = regexs(2)
                capture confirm numeric variable `_fvar'
                if _rc {
                    display as error "factor variable `_fvar' is missing; cannot rebuild `_cv'"
                    display as error "re-run {bf:finegray} before {bf:finegray_cif}"
                    exit 459
                }
                quietly replace `_cv' = `_cv' * (`_fvar' == `_flev') if e(sample)
            }
            else {
                local _cvar = subinstr("`_tp'", "c.", "", .)
                capture confirm numeric variable `_cvar'
                if _rc {
                    display as error "covariate `_cvar' is missing; cannot rebuild `_cv'"
                    display as error "re-run {bf:finegray} before {bf:finegray_cif}"
                    exit 459
                }
                quietly replace `_cv' = `_cv' * `_cvar' if e(sample)
            }
        }
    }

    * =====================================================================
    * OVERLAY: over(varname) draws one curve per level in a single call
    * =====================================================================
    * A factor-level margin after this estimator is, nearly always, a request
    * for group CIFs -- the curves finegray_cif already draws, one profile per
    * call.  over() runs that same one-profile path once per level and stacks
    * the results, so each overlaid curve is BIT-IDENTICAL to its standalone
    * at()/bstratum() call (pinned in qa/test_finegray_cif_over.do).  Two
    * shapes: over(model variable) varies that variable across its observed
    * estimation-sample values with every other covariate held as at() says,
    * and over(bstrata variable) draws the fitted baseline strata.
    local _overmode ""
    local _ovlevs ""
    local _ncurve = 1
    if "`over'" != "" {
        if "`over'" == "`_bsvar'" & `_kbs' > 1 {
            if "`bstratum'" != "" {
                display as error "over(`over') and bstratum() may not be combined"
                display as error "over() draws every fitted baseline stratum; bstratum() selects one"
                exit 198
            }
            local _overmode "bstrata"
            * matrow() carries the levels as MACHINE DOUBLES.  The `clean'
            * macro is the display rendering and rounds a noninteger level at
            * about the last bit, so it cannot be subtracted against, compared
            * with, or fed back into a computation; it is kept for labels and
            * row names only.  `_ovlevsx' is the %21x form, which round-trips
            * exactly through Stata's numeric parser and drives everything
            * downstream.
            tempname _ovmat
            quietly levelsof `_bsvar' if e(sample), local(_ovall) clean matrow(`_ovmat')
            local _bsne `"`e(bstrata_noevent_x)'"'
            * A fit stored before e(bstrata_noevent_x) existed carries only
            * the readable macro; probe in that vocabulary rather than
            * matching nothing and overlaying a flat zero curve.
            local _usex = `"`_bsne'"' != ""
            if !`_usex' local _bsne `"`e(bstrata_noevent)'"'
            local _ovlevs ""
            local _ovlevsx ""
            local _ovskip ""
            local _novall = rowsof(`_ovmat')
            forvalues _r = 1/`_novall' {
                local _hx : display %21x `_ovmat'[`_r', 1]
                local _hx = strtrim("`_hx'")
                local _wd : word `_r' of `_ovall'
                local _hit = 0
                if `_usex' {
                    local _hit : list posof "`_hx'" in _bsne
                }
                else {
                    * Same fallback, same rule as the bstratum() branch above:
                    * on the readable macro both sides are numbers written as
                    * text and two renderings of one level need not match
                    * character for character, so compare on the values.
                    local _nbsw : word count `_bsne'
                    local _wdv = real("`_wd'")
                    forvalues _bw = 1/`_nbsw' {
                        local _bsw : word `_bw' of `_bsne'
                        if !missing(real("`_bsw'"), `_wdv') & ///
                            real("`_bsw'") == `_wdv' local _hit = `_bw'
                    }
                }
                if `_hit' > 0 {
                    local _ovskip "`_ovskip' `_wd'"
                }
                else {
                    local _ovlevs "`_ovlevs' `_wd'"
                    local _ovlevsx "`_ovlevsx' `_hx'"
                }
            }
            local _ovlevs : list retokenize _ovlevs
            local _ovlevsx : list retokenize _ovlevsx
            local _ovskip : list retokenize _ovskip
            if "`_ovlevs'" == "" {
                display as error "no baseline stratum of `_bsvar' carried a cause `=e(cause)' event"
                display as error "there is no cumulative incidence curve to draw"
                exit 459
            }
            * A stratum with no cause event has an identically zero baseline
            * and is refused by name under bstratum(); the overlay omits it and
            * says so, rather than drawing a flat line at 0 that reads as a
            * finding.
            if "`_ovskip'" != "" {
                display as text "note: baseline stratum/strata `_ovskip' of `_bsvar' carried no"
                display as text "cause `=e(cause)' event and are omitted from the overlay"
            }
        }
        else {
            * Membership is checked once the fit-time design is resolved below.
            local _overmode "cov"
        }
        local _ncurve : word count `_ovlevs'
        if "`_overmode'" == "cov" local _ncurve = 0
    }

    * =====================================================================
    * FIT-TIME DESIGN  (needed by at() and by over() on a covariate)
    * =====================================================================
    * Resolve the fit-time design FIRST and copy every r() out before any
    * other command runs.  r() is one shared queue: the `summarize' and
    * `count' calls below wipe r(pieces#)/r(rawvars) on their first use.
    * Verified 2026-08-18: r(expr1) = "(grp == 2)" before `summarize x',
    * empty after.
    local _fvk = 0
    local _rawvars ""
    local _fvars   ""
    if (`"`at'"' != "" | "`_overmode'" == "cov") & ///
       `"`e(fvsemantic)'"' != "" & `"`e(fvsemantic)'"' != "." {
        _finegray_fv_design, caller(finegray_cif)
        local _fvk = r(k)
        local _rawvars `"`r(rawvars)'"'
        local _fvars   `"`r(fvars)'"'
        forvalues _c = 1/`_fvk' {
            local _pieces`_c' `"`r(pieces`_c')'"'
        }
        * The helper already checks _k against colsof(e(b)); covs is built
        * from e(designvars).  A disagreement here would mispair a column
        * with a term silently, so refuse rather than index into it.
        if `_fvk' != `p' {
            display as error "fitted design columns do not match e(designvars)"
            display as error "(`_fvk' non-base terms, `p' design columns); re-run {bf:finegray}"
            exit 198
        }
        * Belt for the r()-clobbering failure mode above: an empty pieces
        * list would silently leave that column at its mean.
        forvalues _c = 1/`_fvk' {
            if `"`_pieces`_c''"' == "" {
                display as error "the fitted design for column `_c' could not be resolved"
                display as error "re-run {bf:finegray} before {bf:finegray_cif}"
                exit 198
            }
        }
    }

    * Design weights.  A weighted fit's baseline and influence function are
    * different curves from the unweighted ones, so the weight column is
    * rebuilt from e(wexp) (the variables it names are in the estimation
    * signature, verified above) and handed to every Mata entry point below.
    *   _fg_wmata  the rebuilt column, "" on an unweighted fit
    *   _fg_wtype  0 none, 1 pweight, 2 fweight
    * REBUILT HERE, above the profile construction, not at the Mata call:
    * the default profile is the estimation-sample mean, and on a weighted
    * fit that mean is the WEIGHTED one.  Through v1.3.0 the column was not
    * yet available when the profile was built, so a [fw=w] fit reported a
    * default CIF at the unweighted means -- a profile the fit never saw,
    * at rc 0 (measured against the expanded-data fit: mreldif 2.1e-3).
    * Rebuilt after the _finegray_fv_design block above, because
    * _finegray_weight_var runs `count' and `summarize' and so wipes r().
    tempvar es
    quietly gen byte `es' = e(sample)
    local _fg_wmata ""
    local _fg_wtype = 0
    local _fg_aw ""
    if `"`e(wtype)'"' != "" {
        tempvar _fg_wv
        _finegray_weight_var, wname(`_fg_wv') touse(`es')
        local _fg_wmata "`_fg_wv'"
        local _fg_wtype = r(wtype)
        * Weight qualifier for every default-profile mean below.  aweight is
        * the right kind for a MEAN whatever e(wtype) is: an fweight mean and
        * an aweight mean over the same column agree exactly, and an aweight
        * qualifier does not change N in a way `summarize, meanonly' reads.
        * An unweighted fit leaves this empty, so its code path is the one
        * that shipped, character for character.
        local _fg_aw "[aweight=`_fg_wv']"
    }

    * Denominator for the proportion of an unset factor indicator: the count
    * of estimation-sample rows, or their weight total on a weighted fit.
    * Taken once, here, because r(N) is as volatile as everything else in r().
    * Held in a scalar, not a local: `local x = r(sum)' renders at about 8
    * significant digits, and the weighted default profile has to reproduce
    * the expanded-data fit to 1e-12.
    tempname _nes
    if "`_fg_wmata'" != "" {
        quietly summarize `_fg_wmata' if e(sample), meanonly
        scalar `_nes' = r(sum)
    }
    else {
        quietly count if e(sample)
        scalar `_nes' = r(N)
    }

    * over() on a covariate: it must be a model variable (raw or design
    * column), must not also be fixed by at(), and must have few enough
    * distinct values to be a grouping.  Twenty is a display limit, not a
    * statistical one: an overlay of more step functions than that is
    * unreadable, and a continuous covariate typed here by mistake would
    * otherwise draw hundreds of curves and a legend to match.
    local _ovcols ""
    if "`_overmode'" == "cov" {
        local _israw : list posof "`over'" in _rawvars
        local _isdir : list posof "`over'" in covs
        if !`_israw' & !`_isdir' {
            display as error "over(): `over' is not a model covariate"
            if `"`_rawvars'"' != "" {
                display as error "model variables are: `_rawvars'"
            }
            display as error "design columns are: `covs'"
            if `"`_bsvar'"' != "" {
                display as error "(the baseline strata variable is `_bsvar')"
            }
            exit 198
        }
        local _rest `"`at'"'
        while `"`_rest'"' != "" {
            gettoken _pair _rest : _rest, parse(" ")
            local _eqp = strpos(`"`_pair'"', "=")
            if `_eqp' == 0 continue
            local _avar = strtrim(substr(`"`_pair'"', 1, `_eqp' - 1))
            if "`_avar'" == "`over'" {
                display as error "over(`over') and at(`over'=#) may not be combined"
                display as error "over() varies `over' across its levels; at() would fix it"
                exit 198
            }
        }
        * See the bstrata branch above: matrow() is the exact form, the
        * `clean' macro is the display form.
        tempname _ovmatc
        quietly levelsof `over' if e(sample), local(_ovlevs) clean matrow(`_ovmatc')
        local _ncurve : word count `_ovlevs'
        local _ovlevsx ""
        forvalues _r = 1/`_ncurve' {
            local _hx : display %21x `_ovmatc'[`_r', 1]
            local _hx = strtrim("`_hx'")
            local _ovlevsx "`_ovlevsx' `_hx'"
        }
        local _ovlevsx : list retokenize _ovlevsx
        if `_ncurve' > 20 {
            display as error "over(`over') would draw `_ncurve' curves"
            display as error "over() is for a grouping variable with at most 20 distinct values;"
            display as error "use {bf:at(`over'=#)} to draw the profiles you want"
            exit 198
        }
        * Design columns the over() variable enters -- excluded from the
        * shared profile line, since they take a different value on every
        * curve.
        if `_fvk' > 0 {
            forvalues _c = 1/`_fvk' {
                foreach _pc of local _pieces`_c' {
                    local _cp = strpos("`_pc'", ":")
                    local _pvar = cond(`_cp', substr("`_pc'", 1, `_cp' - 1), "`_pc'")
                    if "`_pvar'" == "`over'" local _ovcols "`_ovcols' `_c'"
                }
            }
        }
        * A name that IS a design column is varied directly, whether or not
        * the fit carries a factor design.  This used to sit in an `else' to
        * the block above, so on a factor fit over(<design column>) printed
        * the varied column on the shared "at:" line at rc 0.
        if `_isdir' local _ovcols "`_ovcols' `_isdir'"
        local _ovcols : list uniq _ovcols
    }

    * Curve labels, read while the source variable is still in memory (the
    * graph block runs on a preserved, cleared dataset).
    local _ovvar "`over'"
    if "`_overmode'" == "bstrata" local _ovvar "`_bsvar'"
    tempname _LEVM
    if "`_overmode'" != "" {
        forvalues g = 1/`_ncurve' {
            * `_lev`g'' is the DISPLAY spelling (labels, notes, row names);
            * `_levx`g'' is the same value in %21x and is the one that reaches
            * at(), the baseline-stratum selector, the `over' column of
            * r(table) and every `==' comparison.
            local _lev`g' : word `g' of `_ovlevs'
            local _levx`g' : word `g' of `_ovlevsx'
            local _lbl`g' : label (`_ovvar') `_lev`g''
        }
        * The levels as machine doubles, returned so a caller can feed a level
        * straight back into at()/bstratum() and land on the same curve.
        * r(levels) is the display spelling and cannot do that for a
        * noninteger level.
        matrix `_LEVM' = J(`_ncurve', 1, .)
        forvalues g = 1/`_ncurve' {
            matrix `_LEVM'[`g', 1] = `_levx`g''
        }
        matrix colnames `_LEVM' = level
        matrix rownames `_LEVM' = `_ovlevs'
    }

    * =====================================================================
    * BUILD COVARIATE PROFILE(S)  (default: estimation-sample means)
    * =====================================================================
    * Every column starts at its own estimation-sample mean -- unchanged from
    * v1.2.0, and unchanged for any column at() does not reach.  This matters:
    * for an interaction column the mean of the PRODUCT is not the product of
    * the means (i.grp##c.x, live: _fg_grp_2Xx mean 1.6344536 against
    * 0.33333 * 4.97502 = 1.6583), so recomputing untouched columns from a raw
    * profile would silently move the default curve of every factor fit.
    tempname zmeans
    matrix `zmeans' = J(1, `p', 0)
    local j 0
    foreach v of local covs {
        local ++j
        quietly summarize `v' if e(sample) `_fg_aw', meanonly
        matrix `zmeans'[1, `j'] = r(mean)
    }

    * One profile per curve.  Without over() the loop runs once with the
    * user's at() and the fit's own stratum selection; with over() on a
    * covariate each pass appends `over'=level to at(), and with over() on
    * the bstrata() variable each pass selects that stratum.  The parser is
    * exactly the one-profile parser, so a level reached through over() and
    * the same level typed into at() build the same row.
    forvalues g = 1/`_ncurve' {
        local _at_cur `"`at'"'
        local _bslev`g' "`_bslev'"
        if "`_overmode'" == "cov"     local _at_cur `"`at' `over'=`_levx`g''"'
        if "`_overmode'" == "bstrata" local _bslev`g' "`_levx`g''"
        tempname _zr
        local zrow`g' "`_zr'"
        matrix `_zr' = `zmeans'

    * Override means with user-specified at(var=#).  A name may be either a
    * RAW model variable (`grp', `x') or a package-owned design column
    * (`_fg_grp_2Xx').  A raw setting is carried into every design column the
    * variable enters, which is what makes at() usable on an interaction fit:
    * through v1.2.0 at(grp=1) after `i.grp##c.x' was refused outright, and
    * at(x=0) was ACCEPTED while _fg_grp_2Xx stayed at its mean 1.63 -- a
    * profile no subject can have, reported at rc 0.
    if `"`_at_cur'"' != "" {
        * -----------------------------------------------------------------
        * Parse at() into raw-variable settings and direct column settings.
        * A name that is a raw model variable is treated as raw even when a
        * design column shares its spelling (a continuous main effect keeps
        * its own name in e(designvars)); that is what lets a setting reach
        * the interaction columns the variable also enters.
        * -----------------------------------------------------------------
        local _rvars ""
        local _rvals ""
        local _dcols ""
        local _dvals ""
        local _rest `"`_at_cur'"'
        while `"`_rest'"' != "" {
            gettoken _pair _rest : _rest, parse(" ")
            if `"`_pair'"' == "" continue
            local _eqp = strpos(`"`_pair'"', "=")
            if `_eqp' == 0 {
                display as error "at() must be specified as var=# [var=# ...]"
                exit 198
            }
            local _avar = strtrim(substr(`"`_pair'"', 1, `_eqp' - 1))
            local _aval = strtrim(substr(`"`_pair'"', `_eqp' + 1, .))
            capture confirm number `_aval'
            if _rc {
                display as error "at(): `_aval' is not a number"
                exit 198
            }
            if real(`"`_aval'"') >= . {
                display as error "at(): values must be finite numbers"
                exit 198
            }
            * Keep the LITERAL token, not real(): `local x = real("...")'
            * renders at about 8 significant digits, and the contract that
            * at(grp=1), at(grp=1.0) and at(grp=1e0) agree exactly (FG-M04)
            * rests on the value reaching a numeric context unrounded.

            local _israw : list posof "`_avar'" in _rawvars
            local _isdir : list posof "`_avar'" in covs

            if `_israw' {
                local _dup : list posof "`_avar'" in _rvars
                if `_dup' {
                    display as error "at(): `_avar' is set more than once"
                    exit 198
                }
                local _isf : list posof "`_avar'" in _fvars
                if `_isf' {
                    quietly count if e(sample) & `_avar' == `_aval'
                    if r(N) == 0 {
                        display as error "at(): `_aval' is not an observed level of `_avar'"
                        exit 198
                    }
                }
                local _rvars "`_rvars' `_avar'"
                local _rvals "`_rvals' `_aval'"
            }
            else if `_isdir' {
                local _dup : list posof "`_avar'" in _dcols
                if `_dup' {
                    display as error "at(): `_avar' is set more than once"
                    exit 198
                }
                local _dcols "`_dcols' `_avar'"
                local _dvals "`_dvals' `_aval'"
            }
            else {
                display as error "at(): `_avar' is not a model covariate"
                if `"`_rawvars'"' != "" {
                    display as error "model variables are: `_rawvars'"
                }
                display as error "design columns are: `covs'"
                exit 198
            }
        }

        * -----------------------------------------------------------------
        * Propagate raw settings into every design column they enter.
        * A column no set variable appears in keeps its mean; a piece the user
        * did not set is held at its own estimation-sample mean (the sample
        * PROPORTION for a factor indicator), so the untouched part of a mixed
        * term reads exactly as it would have without at().
        * -----------------------------------------------------------------
        tempname _cval _wsub
        if `"`_rvars'"' != "" {
            forvalues _c = 1/`_fvk' {
                local _touched = 0
                foreach _pc of local _pieces`_c' {
                    local _cp = strpos("`_pc'", ":")
                    local _pvar = cond(`_cp', substr("`_pc'", 1, `_cp' - 1), "`_pc'")
                    local _sp : list posof "`_pvar'" in _rvars
                    if `_sp' local _touched = 1
                }
                if !`_touched' continue

                scalar `_cval' = 1
                foreach _pc of local _pieces`_c' {
                    local _cp = strpos("`_pc'", ":")
                    if `_cp' {
                        local _pvar = substr("`_pc'", 1, `_cp' - 1)
                        local _plev = substr("`_pc'", `_cp' + 1, .)
                    }
                    else {
                        local _pvar "`_pc'"
                        local _plev ""
                    }
                    local _sp : list posof "`_pvar'" in _rvars
                    if `_sp' {
                        local _uval : word `_sp' of `_rvals'
                        if "`_plev'" != "" scalar `_cval' = `_cval' * (`_uval' == `_plev')
                        else               scalar `_cval' = `_cval' * (`_uval')
                    }
                    else if "`_plev'" != "" {
                        * Unset factor part: its estimation-sample proportion,
                        * i.e. the mean of the indicator, which is exactly what
                        * the untouched column would have carried.  On a
                        * weighted fit that proportion is sum(w | level) over
                        * sum(w), matching the weighted column mean above.
                        if "`_fg_wmata'" != "" {
                            quietly summarize `_fg_wmata' ///
                                if e(sample) & `_pvar' == `_plev', meanonly
                            scalar `_wsub' = cond(r(N) == 0, 0, r(sum))
                            scalar `_cval' = `_cval' * (`_wsub' / `_nes')
                        }
                        else {
                            quietly count if e(sample) & `_pvar' == `_plev'
                            scalar `_cval' = `_cval' * (r(N) / `_nes')
                        }
                    }
                    else {
                        quietly summarize `_pvar' if e(sample) `_fg_aw', meanonly
                        scalar `_cval' = `_cval' * r(mean)
                    }
                }
                matrix `_zr'[1, `_c'] = `_cval'
            }
        }

        * -----------------------------------------------------------------
        * Direct design-column settings last, so an explicit _fg_* value wins
        * over anything the propagation computed for the same column.
        * -----------------------------------------------------------------
        local _nd : word count `_dcols'
        forvalues _d = 1/`_nd' {
            local _dc : word `_d' of `_dcols'
            local _dv : word `_d' of `_dvals'
            local _pos : list posof "`_dc'" in covs
            matrix `_zr'[1, `_pos'] = `_dv'
        }
    }
    } /* end per-curve profile loop */

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

    * Combine multiple strata variables into a single group variable
    * (the Mata engine expects one column)
    local _byg_mata "`e(strata)'"
    local _byg_nvar : word count `e(strata)'
    if `_byg_nvar' > 1 {
        tempvar _byg_grp
        _finegray_weight_groups, strata(`e(strata)') ///
            bygname(`_byg_grp') touse(`es')
        local _byg_mata "`_byg_grp'"
    }

    * Rebuild the truncation strata from the STORED specification, never from a
    * variable left behind in the data: the fit's weight design must be reproduced
    * exactly or the CIF is computed under different weights than the model was.
    local _tg_mata ""
    if `"`e(truncstrata)'"' != "" {
        tempvar _tg_grp
        _finegray_weight_groups, truncstrata(`e(truncstrata)') ///
            tgname(`_tg_grp') touse(`es')
        local _tg_mata "`_tg_grp'"
    }

    * =====================================================================
    * BUILD TIME GRID  (per curve: under over(bstrata) each stratum has its
    * own event times, so the default grid differs by curve)
    * =====================================================================
    * Curve mode plots the distinct baseline event times, thinned to <= 400.  It
    * used to read them out of e(basehaz), which no longer exists unless the user
    * asked for it -- and which cost O(K^2) to create even when it did.  Get the
    * thinned grid straight from Mata instead: _finegray_bh_grid rebuilds the
    * baseline (one linear pass) and posts only the <= 401 grid times, so the
    * Stata matrix it does create is small enough for the quadratic to vanish.
    * attime() and timepoints() are mutually exclusive (refused at parse time),
    * so this order expresses a preference over nothing.
    if "`attime'" != "" {
        local mode "table"
        * attime() draws no graph, so any leftover twoway options cannot apply.
        if `"`options'"' != "" {
            display as text "note: graph (twoway) options are ignored with attime()"
        }
    }
    else local mode "curve"
    forvalues g = 1/`_ncurve' {
        if "`attime'" != "" {
            local grid`g' "`attime'"
        }
        else if "`timepoints'" != "" {
            local grid`g' "`timepoints'"
        }
        else if `g' > 1 & "`_overmode'" != "bstrata" {
            * Same baseline for every curve: one grid, computed once.
            local grid`g' "`grid1'"
        }
        else {
            * Use distinct baseline-hazard times; thin to <= 400 for the matrix/plot.
            * The thinning (stride, then always close on the last row) happens inside
            * _finegray_bh_grid, which reproduces the former Stata-side loop exactly.
            * A stride > 1 steps OVER the final row whenever nbh is not congruent to
            * 1 mod step: with nbh = 402 and step = 2 the last grid point is row 401
            * and the terminal event time is silently dropped -- while nbh = 481
            * happens to land on it. The CIF's terminal value is its plateau, i.e.
            * the number most readers take off the curve, so it must never depend on
            * the parity of the event count. Always close the grid on the last row.
            tempname BHG

            * Prefer the Mata cache (free) over rebuilding (one linear pass).  Both
            * give the same curve; the cache refuses a key from a different fit, so a
            * stale baseline cannot leak in.  finegray_cif always runs on the
            * estimation data (_finegray_check_data enforces it), so the rebuild is
            * always available as the fallback after `discard' / `mata clear'.
            local _key `"`e(bh_key)'"'
            local _have = 0
            if `"`_key'"' != "" {
                mata: _finegray_bh_have("`_key'", "_have")
            }
            if `_have' {
                mata: _finegray_bh_grid_cached("`_key'", 400, "`BHG'", strtoreal("`_bslev`g''"))
            }
            else {
                mata: _finegray_bh_grid("`covs'", "`e(compete)'", `=e(cause)', ///
                    `=e(censvalue)', "`_byg_mata'", "`_tg_mata'", "`es'", ///
                    "`_t0var'", 400, "`BHG'", "`_bsvar'", strtoreal("`_bslev`g''"), ///
                    "`_fg_tvcpos'", "`_fg_cuts'", "`_fg_wmata'", `_fg_wtype')
            }
            local nbh = `_fg_nbh'
            local grid`g' ""
            if `nbh' > 0 {
                local _ngb = rowsof(`BHG')
                forvalues r = 1/`_ngb' {
                    local grid`g' "`grid`g'' `=`BHG'[`r',1]'"
                }
            }
        }
        local ngrid`g' : word count `grid`g''
        if `ngrid`g'' == 0 {
            display as error "no time points to evaluate"
            exit 198
        }
    }

    * =====================================================================
    * EVALUATION MATRIX  (k x (1+p): time, profile) and CIF, per curve
    * =====================================================================
    forvalues g = 1/`_ncurve' {
        tempname _E _O
        local OUT`g' "`_O'"
        matrix `_E' = J(`ngrid`g'', `=`p'+1', 0)
        local r 0
        foreach tt of local grid`g' {
            local ++r
            matrix `_E'[`r', 1] = `tt'
            forvalues c = 1/`p' {
                matrix `_E'[`r', `=`c'+1'] = `zrow`g''[1, `c']
            }
        }
        * One call either way since the unification: _finegray_cif_var_st dispatches to the
        * piecewise influence function when it is told the interval structure, and
        * both routes reach the same accumulators.  bstrata() needs the stratum
        * column (to rebuild the fit's one-curve-per-stratum baseline) and the
        * requested stratum (to answer from the right one); passing neither rebuilt
        * a pooled baseline and returned the same CIF for every stratum at rc 0.
        if `_fg_istvc' {
            mata: _finegray_cif_var_st("`covs'", "`e(compete)'", `=e(cause)', ///
                `=e(censvalue)', "`_byg_mata'", "`_tg_mata'", "`e(clustvar)'", ///
                "`es'", "`_E'", "`_O'", "`_t0var'", "`_bsvar'", strtoreal("`_bslev`g''"), ///
                "`_fg_tvcpos'", "`_fg_cuts'", "`_fg_wmata'", `_fg_wtype')
        }
        else {
            * The two empty strings are the tvc()/tsplit() slots (positional):
            * the weight column and its type code follow them.
            mata: _finegray_cif_var_st("`covs'", "`e(compete)'", `=e(cause)', ///
                `=e(censvalue)', "`_byg_mata'", "`_tg_mata'", "`e(clustvar)'", "`es'", "`_E'", ///
                "`_O'", "`_t0var'", "`_bsvar'", strtoreal("`_bslev`g''"), "", "", ///
                "`_fg_wmata'", `_fg_wtype')
        }
        * A nonfinite CIF is not a result.  The engine returns a missing CIF
        * only when the profile's linear predictor is itself nonfinite (an
        * at() value or a coefficient that is missing); exp() overflow at an
        * extreme but finite profile is evaluated in the engine as CIF = 1
        * (see _finegray_cif_core in _finegray_mata.ado).  Through 1.3.0 an
        * overflowing row was posted as (cif = ., se = 0) at rc 0: the
        * influence contributions were missing and the variance sum treated
        * them as zeros, so an unusable point estimate carried a fabricated
        * zero SE.  Refuse here, before bootstrap replications are spent on
        * it and before anything reaches r().
        mata: st_local("_fg_nmis", strofreal(sum(st_matrix("`_O'")[., 1] :>= .)))
        if `_fg_nmis' > 0 {
            display as error "the CIF could not be evaluated at `_fg_nmis' of `ngrid`g'' requested time(s)"
            if "`_overmode'" != "" display as error `"(curve `_ovvar' = `_lbl`g'')"'
            display as error "the covariate profile gives a nonfinite linear predictor; check the at() values"
            exit 498
        }
    }

    * =====================================================================
    * BOOTSTRAP STANDARD ERRORS (optional; refits censoring/entry weights)
    * =====================================================================
    * One replication loop serves every curve: each refit is scored at every
    * profile, so an overlay costs the same B refits as a single curve, and
    * with the same seed() each curve sees exactly the resamples its
    * standalone call would (bsample is the only consumer of the RNG).
    * Replications are counted PER CURVE, because under over(bstrata) a
    * resample can lose one stratum's cause events without touching another.
    if `bootstrap' > 0 {
        * e(refitcmd), not e(cmdline): the refit runs on data already restricted
        * to e(sample) and then resampled, so the user's `if'/`in' qualifier is
        * meaningless there.  Replaying `in 101/200' against a 100-row resample
        * selected no rows and failed every replication (rc 498, 0/B).
        local _fgcmd `"`e(refitcmd)'"'
        local _fgclust `"`e(clustvar)'"'
        tempvar _bsid _bsclust
        * Repeated draws of the same original cluster must be distinct
        * bootstrap clusters. idcluster() supplies that draw identity; keep
        * e(refitcmd) unchanged and rewrite only the private bootstrap replay.
        local _fgbscmd `"`_fgcmd'"'
        if `"`_fgclust'"' != "" {
            local _fgbscmd : subinstr local _fgcmd ///
                "cluster(`_fgclust')" "cluster(`_bsclust')", all
            if `"`_fgbscmd'"' == `"`_fgcmd'"' {
                display as error "internal bootstrap error: cluster() is absent from e(refitcmd)"
                exit 498
            }
        }
        forvalues g = 1/`_ncurve' {
            tempname _G _S1 _S2
            local Gmat`g' "`_G'"
            local BSUM`g' "`_S1'"
            local BSS`g'  "`_S2'"
            matrix `_G' = J(`ngrid`g'', 1, 0)
            local r 0
            foreach tt of local grid`g' {
                local ++r
                matrix `_G'[`r', 1] = `tt'
            }
            matrix `_S1' = J(`ngrid`g'', 1, 0)
            matrix `_S2' = J(`ngrid`g'', 1, 0)
            local _bok`g' = 0
        }
        * Protect the user's estimation results across the refits. Hold
        * BEFORE preserve: hold records e(sample) in a hidden variable, and
        * only a hold placed before preserve puts that variable into the
        * preserved snapshot so that restore + unhold can bring e(sample)
        * back. (e(sample) itself was already captured in `es' above, and
        * e(cmdline) in `_fgcmd', since hold clears the active e().)
        tempname _esth
        _estimates hold `_esth', restore
        local _held = 1
        * Each refit below calls finegray again and overwrites the single slot in
        * the Mata baseline cache, minting a key the held
        * e(bh_key) does not name.  _estimates hold protects e(), but the cache is a
        * Mata global and is invisible to it.  Without this snapshot, a later
        * `finegray_predict, cif' on new data (estimation sample dropped) finds
        * a key mismatch, cannot rebuild, and errors r(459).  Each
        * replication reads its own key-matched cache entry
        * before the next refit overwrites it; restoring the held fit's cache
        * afterward cannot affect the bootstrap SE. Same defect and same fix as
        * finegray_predict.ado.
        mata: _finegray_bh_stash()
        local _bh_stashed = 1

        preserve
        local _preserved = 1
        quietly keep if `es'
        * Refits must see each subject's true entry time, not the kept
        * record's own interval start (multi-record reduction)
        if "`_t0var'" != "_t0" quietly replace _t0 = `_t0var'
        tempfile _bdata
        quietly save `"`_bdata'"'

        * seed() must not reposition the CALLER's random-number stream: a user
        * who asks for reproducible replicates gets them, and every rnormal()
        * they draw afterwards is exactly the one they would have drawn had the
        * bootstrap not run.  Snapshot the state here and restore it in the
        * cleanup zone (which also runs on the error paths inside the loop).
        local _rngstate = c(rngstate)
        local _rngsaved = 1
        if "`seed'" != "" set seed `seed'

        tempname bcif
        forvalues b = 1/`bootstrap' {
            quietly {
                use `"`_bdata'"', clear
                * Resample whole clusters as units when the fit declared
                * cluster(); otherwise resample subjects.
                if `"`_fgclust'"' != "" {
                    bsample, cluster(`_fgclust') idcluster(`_bsclust')
                }
                else bsample
                * e(sample) contains one reduced record per subject. Give every
                * copied row a fresh survival id without overwriting a user
                * variable that may also appear in the model or weight strata.
                gen long `_bsid' = _n
                char _dta[st_id] "`_bsid'"
                * The refit always caches its baseline in Mata.  Do NOT append
                * basehaz here: posting the K-row e(basehaz) matrix is O(K^2) and
                * repeating it B times can dominate the bootstrap.
                capture `_fgbscmd'
                if _rc continue
                if e(converged) != 1 continue
                * A resample can lose a factor level, so the refit posts a
                * shorter e(b) whose columns no longer align with the stored
                * profile; using it would silently mispair coefficients.
                if `"`e(designvars)'"' != `"`covs'"' continue
                local _bsne_r `"`e(bstrata_noevent_x)'"'
                local _fg_repkey `"`e(bh_key)'"'
                forvalues g = 1/`_ncurve' {
                    * A resample can lose every cause event in the requested
                    * baseline stratum, or the stratum itself.  That replication
                    * has no curve to contribute; skip it, and let the _bok
                    * accounting below report how many were skipped.  Reaching the
                    * baseline lookup instead would abort the whole bootstrap on a
                    * resample that is merely unlucky.
                    if `"`_bsvar'"' != "" & "`_bslev`g''" != "." {
                        local _bshit_r : list posof "`_bslev`g''" in _bsne_r
                        if `_bshit_r' > 0 continue
                        quietly count if `_bsvar' == `_bslev`g''
                        if r(N) == 0 continue
                    }
                    * The refit replays e(refitcmd), which carries tvc()/tsplit(),
                    * so each replication is the same estimator as the point
                    * estimate and its CIF must be accumulated the same way.
                    if `_fg_istvc' {
                        mata: _finegray_boot_cif_tvc("`zrow`g''", "`Gmat`g''", "`bcif'", ///
                            "`_fg_repkey'", "`_fg_tvcpos'", "`_fg_cuts'", ///
                            strtoreal("`_bslev`g''"))
                    }
                    else {
                        mata: _finegray_boot_cif("`zrow`g''", "`Gmat`g''", "`bcif'", ///
                            "`_fg_repkey'", strtoreal("`_bslev`g''"))
                    }
                    forvalues r = 1/`ngrid`g'' {
                        matrix `BSUM`g''[`r',1] = `BSUM`g''[`r',1] + `bcif'[`r',1]
                        matrix `BSS`g''[`r',1]  = `BSS`g''[`r',1] + `bcif'[`r',1]^2
                    }
                    local ++_bok`g'
                }
            }
        }
        restore
        local _preserved = 0
        _estimates unhold `_esth'
        local _held = 0
        * Restore the fit's own baseline curve to the cache so a later predict on
        * new data resolves against e(bh_key) instead of the last resample's
        * curve.  Before the `exit 498' below on purpose: a bootstrap that fell
        * short of _minboot must still leave the user's fit usable.
        mata: _finegray_bh_unstash()
        local _bh_stashed = 0

        local _bokmin = `bootstrap'
        local _bokvary = 0
        forvalues g = 1/`_ncurve' {
            if `_bok`g'' < `_minboot' {
                display as error "bootstrap failed: only `_bok`g'' of `bootstrap' replications succeeded"
                if "`_overmode'" != "" {
                    display as error `"(curve `_ovvar' = `_lbl`g'')"'
                }
                display as error "at least `_minboot' are required to estimate a standard error"
                exit 498
            }
            if `_bok`g'' < `_bokmin' local _bokmin = `_bok`g''
            if `_bok`g'' != `_bok1' local _bokvary = 1
        }
        if `_bokvary' {
            * Different curves used different numbers of replications: say
            * which, because r(bootstrap_success) reports only the minimum.
            local _bokline ""
            forvalues g = 1/`_ncurve' {
                local _bokline "`_bokline' `_ovvar'=`_lev`g'': `_bok`g''"
            }
            display as text "(note: replications used per curve --`_bokline')"
        }
        if `_bokmin' < `bootstrap' {
            display as text "(note: `=`bootstrap'-`_bokmin'' of `bootstrap' bootstrap replications failed and were skipped)"
        }
        * Replace the analytic SE column with the bootstrap SD
        forvalues g = 1/`_ncurve' {
            forvalues r = 1/`ngrid`g'' {
                local _m = `BSUM`g''[`r',1]/`_bok`g''
                local _v = (`BSS`g''[`r',1] - `_bok`g''*`_m'^2)/(`_bok`g''-1)
                * Clamp at 0.  This is the computational form of the variance, so
                * replicates that agree to machine precision (a grid point before
                * the first cause event, where every replication returns CIF = 0)
                * leave a tiny NEGATIVE residual after the cancellation, and
                * sqrt() of it is MISSING.  A missing SE then suppresses the
                * confidence limits below, reporting "we cannot quantify this"
                * where the truth is a bootstrap SD of exactly zero.
                if `_v' < 0 local _v = 0
                matrix `OUT`g''[`r',2] = sqrt(`_v')
            }
        }
    }

    * =====================================================================
    * ASSEMBLE RESULTS  (time cif se lci uci [over]), per curve then stacked
    * =====================================================================
    local z = invnormal(1 - (1 - `level'/100)/2)
    forvalues g = 1/`_ncurve' {
        tempname _R
        local R`g' "`_R'"
        matrix `_R' = J(`ngrid`g'', 5, .)
        forvalues r = 1/`ngrid`g'' {
            local tt : word `r' of `grid`g''
            local cifv = `OUT`g''[`r', 1]
            local sev  = `OUT`g''[`r', 2]
            matrix `_R'[`r', 1] = `tt'
            matrix `_R'[`r', 2] = `cifv'
            matrix `_R'[`r', 3] = `sev'
            * Confidence limits, or NOTHING.  `R' is initialised to missing, and a
            * limit we cannot compute must stay missing.  Writing the point estimate
            * into lci/uci instead -- which is what this did through v1.1.0 --
            * manufactures a zero-width interval and presents it as a real one: an
            * interior CIF whose SE came back nonfinite was reported as an exact,
            * uncertainty-free estimate. It also meant r(table) carried
            * lci = uci = cif whenever ci was NOT requested, so a caller reading
            * those columns got a fabricated interval it never asked for.
            if "`ci'" != "" & `cifv' > 0 & `cifv' < 1 & `sev' < . & `sev' > 0 {
                local g_ = ln(-ln(1 - `cifv'))
                local seg = `sev' / ((1 - `cifv') * (-ln(1 - `cifv')))
                matrix `_R'[`r', 4] = 1 - exp(-exp(`g_' - `z' * `seg'))
                matrix `_R'[`r', 5] = 1 - exp(-exp(`g_' + `z' * `seg'))
            }
        }
        matrix colnames `_R' = time cif se lci uci
    }
    * The stacked result.  Without over() it IS the single curve's table, so
    * r(table) keeps its five documented columns; with over() a sixth column
    * carries the level (or baseline stratum) each row belongs to, appended so
    * that positional readers of columns 1-5 are unaffected.  A seventh,
    * private column indexes the curve for the graph builder and is never
    * returned.
    tempname R RALL ZR
    if "`_overmode'" == "" {
        matrix `R' = `R1'
        matrix `ZR' = `zrow1'
    }
    else {
        forvalues g = 1/`_ncurve' {
            tempname _Rg
            matrix `_Rg' = `R`g'', J(`ngrid`g'', 1, `_levx`g''), J(`ngrid`g'', 1, `g')
            if `g' == 1 {
                matrix `RALL' = `_Rg'
                matrix `ZR' = `zrow1'
            }
            else {
                matrix `RALL' = `RALL' \ `_Rg'
                matrix `ZR' = `ZR' \ `zrow`g''
            }
        }
        matrix colnames `RALL' = time cif se lci uci over _curve
        matrix rownames `ZR' = `_ovlevs'
        matrix `R' = `RALL'[1..., 1..6]
    }

    * =====================================================================
    * PROFILE LINE  (the covariate values the numbers belong to)
    * =====================================================================
    * The table and the graph used to report a CIF with no statement of WHICH
    * covariate profile it was evaluated at, so several at() tables scrolled
    * back through in one session were indistinguishable -- and a default run
    * never said it had used estimation-sample means either.  `stcurve'/`stci'
    * print an `at:' line above the table; do the same.
    *
    * Spelled in the user's vocabulary (`grp=1'), not the package-owned design
    * columns, using exactly the term list r(profile_vars) reports.  With
    * over() on a covariate the columns that variable enters are left off the
    * shared line -- they take a different value on every curve, and the
    * curve's own label says which.
    local _pv_disp : list retokenize _nbterms
    local _pv_dn : word count `_pv_disp'
    if `"`_pv_disp'"' == "" | `_pv_dn' != `p' local _pv_disp "`covs'"
    local _atline ""
    local _ai = 0
    foreach _pvn of local _pv_disp {
        local ++_ai
        local _skip : list posof "`_ai'" in _ovcols
        if `_skip' continue
        local _pvv = `zrow1'[1, `_ai']
        local _pvs : display %9.3g `_pvv'
        local _pvs = trim("`_pvs'")
        local _atline `"`_atline' `_pvn'=`_pvs'"'
    }
    local _atline : list retokenize _atline
    * Under bstrata() the profile alone does not identify the curve; the stratum
    * is half of the answer, so it is printed on the same line as the rest of it.
    if "`bstratum'" != "" {
        local _atline `"`_atline' `_bsvar'=`bstratum' (baseline stratum)"'
    }
    local _atsrc "at"
    if `"`at'"' == "" local _atsrc "at (estimation-sample means)"
    local _overline ""
    if "`_overmode'" == "cov"     local _overline "over: `over'"
    if "`_overmode'" == "bstrata" local _overline "over: `_bsvar' (baseline strata)"

    * =====================================================================
    * OUTPUT: table (attime) and/or graph (curve)
    * =====================================================================
    if "`mode'" == "table" {
        display as text ""
        if "`ci'" != "" {
            display as text "Cumulative incidence (cause " as result e(cause) ///
                as text "), `level'% CI"
        }
        else {
            display as text "Cumulative incidence (cause " as result e(cause) ///
                as text ")"
        }
        display as text "`_atsrc': " as result `"`_atline'"'
        if "`_overline'" != "" display as text "`_overline'"
        * Rule width tracks the widest data line, which depends on whether the
        * CI pair is printed: the last field ends at column 56 with `ci' and at
        * column 34 without it.  A fixed 40 left the CI table's rules two
        * columns short of the upper limit and hung 20 columns past the SE in
        * the no-CI table.  Stem is 13 + 1 (the {c TT}/{c +}/{c BT} glyph).
        local _rulew = cond("`ci'" != "", 42, 20)
        forvalues g = 1/`_ncurve' {
            if "`_overmode'" != "" {
                display as text ""
                display as text "-> `_ovvar' = " as result `"`_lbl`g''"'
            }
            display as text "{hline 13}{c TT}{hline `_rulew'}"
            if "`ci'" != "" {
                display as text %12s "time" " {c |}" ///
                    _col(18) "CIF" _col(30) "SE" _col(42) "[`level'% CI]"
            }
            else {
                display as text %12s "time" " {c |}" _col(18) "CIF" _col(30) "SE"
            }
            display as text "{hline 13}{c +}{hline `_rulew'}"
            forvalues r = 1/`ngrid`g'' {
                local tt = `R`g''[`r', 1]
                local cf = `R`g''[`r', 2]
                local se = `R`g''[`r', 3]
                if "`ci'" != "" {
                    display as text %12.0g `tt' " {c |}" as result ///
                        _col(16) %7.4f `cf' _col(28) %7.4f `se' ///
                        _col(40) %7.4f `R`g''[`r',4] _col(50) %7.4f `R`g''[`r',5]
                }
                else {
                    display as text %12.0g `tt' " {c |}" as result ///
                        _col(16) %7.4f `cf' _col(28) %7.4f `se'
                }
            }
            display as text "{hline 13}{c BT}{hline `_rulew'}"
        }
    }

    * =====================================================================
    * OUT-OF-SUPPORT NOTES (user-supplied grids only)
    * =====================================================================
    * The CIF is a step function, so it returns a defensible answer at any time:
    * exactly 0 before the first cause event and the terminal plateau after the
    * last one.  Both were silent, which let `attime(999)' print 0.3010 with
    * nothing on screen to say that 999 is 992 years past the last observed
    * event -- and a reader can then quote "the CIF at year 999".
    *
    * Within the requested baseline stratum: the curve steps on THAT
    * stratum's cause-event times, so a note about "the last cause-event
    * time" that quoted the pooled maximum would describe a curve nobody
    * asked for.  Under over(bstrata) the boundary differs by curve, so the
    * note is per curve; otherwise every curve shares one baseline and the
    * note is printed once.
    if "`attime'" != "" | "`timepoints'" != "" {
        tempname _tfirst _tlast
        local _nnote = cond("`_overmode'" == "bstrata", `_ncurve', 1)
        forvalues g = 1/`_nnote' {
            local _bsrestrict ""
            if "`_bslev`g''" != "." local _bsrestrict "& `_bsvar' == `_bslev`g''"
            quietly summarize _t if `es' & `e(compete)' == `=e(cause)' `_bsrestrict', meanonly
            scalar `_tfirst' = r(min)
            scalar `_tlast'  = r(max)
            if !missing(`_tfirst') {
                local _nafter = 0
                local _nbefore = 0
                foreach _tt of local grid`g' {
                    if `_tt' > `_tlast'  local ++_nafter
                    if `_tt' < `_tfirst' local ++_nbefore
                }
                local _tl : display %9.0g `_tlast'
                local _tl = trim("`_tl'")
                local _tf : display %9.0g `_tfirst'
                local _tf = trim("`_tf'")
                local _which ""
                if "`_overmode'" == "bstrata" local _which `" (`_bsvar' = `_lbl`g'')"'
                if `_nafter' > 0 {
                    display as text "note: `_nafter' requested time(s) exceed the last cause-event time (`_tl')`_which';"
                    display as text "the CIF is flat beyond it, so those rows repeat the terminal estimate"
                }
                if `_nbefore' > 0 {
                    display as text "note: `_nbefore' requested time(s) precede the first cause-event time (`_tf')`_which';"
                    display as text "the CIF is exactly 0 there and has no confidence limits"
                }
            }
        }
    }

    * exp(xb) overflowed double precision at a finite profile (the engine
    * raised `_fg_cifovf'): the CIF there is 1 and its SE 0 to machine
    * precision, which is the limit of the estimator at that profile, not
    * evidence that the data reach it.  Say so.
    if "`_fg_cifovf'" != "" {
        display as text "note: exp(xb) exceeds double precision at one or more requested time(s)/profile(s);"
        display as text "the CIF is 1 and its SE 0 to machine precision there, with no confidence limits"
    }

    * Last observed analysis time in the estimation sample, per curve.  Read
    * HERE, before the preserve below clears the data: the graph draws the
    * CIF's flat tail out to this time (see the terminal-row block), as sts
    * graph and stcurve do.
    forvalues g = 1/`_ncurve' {
        local _bsrestrict2 ""
        if "`_bslev`g''" != "." local _bsrestrict2 "& `_bsvar' == `_bslev`g''"
        quietly summarize _t if `es' `_bsrestrict2', meanonly
        local _maxfu`g' = r(max)
    }
    * The over() variable's value label, carried into the saving() dataset so
    * its `over' column reads as the source variable does.  Read now: the
    * preserved dataset below is cleared, and value labels go with it.
    local _ovvl ""
    if "`_overmode'" != "" {
        local _ovvl : value label `_ovvar'
        if "`_ovvl'" != "" {
            tempfile _ovvlfile
            quietly label save `_ovvl' using `"`_ovvlfile'"', replace
        }
    }

    * Build curve dataset for graph and/or saving
    if "`mode'" == "curve" & "`graph'" != "nograph" | `"`savefile'"' != "" {
        preserve
        local _preserved = 1
        quietly {
            clear
            if "`_overmode'" == "" svmat double `R', names(col)
            else svmat double `RALL', names(col)
            if "`_ovvl'" != "" {
                run `"`_ovvlfile'"'
                label values over `_ovvl'
            }
        }
        if "`mode'" == "curve" & "`graph'" != "nograph" {
            * A cumulative incidence curve is a right-continuous step function.
            * The analytical grid begins at the first baseline event time, so
            * add the known (0,0) boundary only to the live graph dataset.  The
            * display-only row and band variables are removed before saving(),
            * leaving r(table) and the exported numeric estimates unchanged.
            tempvar _graph_origin _graph_lci _graph_uci _graph_g
            local _graph_origin_made = 0
            local _graph_lci_made = 0
            local _graph_uci_made = 0
            local _graph_origin_added = 0
            capture noisily {
                quietly {
                    gen byte `_graph_origin' = 0
                    local _graph_origin_made = 1
                    gen double `_graph_lci' = lci
                    local _graph_lci_made = 1
                    gen double `_graph_uci' = uci
                    local _graph_uci_made = 1
                    * The curve index: the private 7th column with over(), or
                    * a constant 1 -- so the per-curve block below is one code
                    * path.  Selection is by index, not by level value, so a
                    * level that does not round-trip through a macro cannot
                    * misfile a row.
                    if "`_overmode'" != "" gen byte `_graph_g' = _curve
                    else gen byte `_graph_g' = 1
                }
                forvalues g = 1/`_ncurve' {
                    * Read the terminal grid row NOW, before any display-only
                    * row is appended: the origin row is appended at the end
                    * of the data, so a later `cif[_N-1]' would read the
                    * origin, not the last estimate.
                    quietly summarize time if `_graph_g' == `g' & !`_graph_origin', meanonly
                    local _graph_tmax = r(max)
                    local _graph_tmin = r(min)
                    quietly summarize cif if `_graph_g' == `g' & time == `_graph_tmax', meanonly
                    local _graph_lastcif = r(mean)
                    quietly summarize `_graph_lci' if `_graph_g' == `g' & time == `_graph_tmax', meanonly
                    local _graph_lastlci = r(mean)
                    quietly summarize `_graph_uci' if `_graph_g' == `g' & time == `_graph_tmax', meanonly
                    local _graph_lastuci = r(mean)
                    if `_graph_tmin' > 0 {
                        local _graph_newobs = _N + 1
                        quietly set obs `_graph_newobs'
                        quietly replace `_graph_origin' = 1 in `_graph_newobs'
                        local _graph_origin_added = 1
                        quietly replace `_graph_g' = `g' in `_graph_newobs'
                        quietly replace time = 0 in `_graph_newobs'
                        quietly replace cif = 0 in `_graph_newobs'
                    }
                    * ...and the same treatment at the right edge.  The analytical
                    * grid ends at the LAST CAUSE-EVENT time, but follow-up runs on
                    * past it, and the CIF is flat over that stretch.  Drawn without
                    * this row the curve stops short of the plot's right edge and
                    * reads as "no information here", which is not what a flat tail
                    * means -- sts graph and stcurve both extend it.  Display-only,
                    * like the origin: removed before saving(), so r(table) and the
                    * exported numeric estimates are unchanged.
                    if `_maxfu`g'' < . & `_graph_tmax' < . & ///
                       `_maxfu`g'' > `_graph_tmax' + 1e-12 {
                        local _graph_newobs = _N + 1
                        quietly set obs `_graph_newobs'
                        quietly replace `_graph_origin' = 1 in `_graph_newobs'
                        local _graph_origin_added = 1
                        quietly replace `_graph_g' = `g' in `_graph_newobs'
                        quietly replace time = `_maxfu`g'' in `_graph_newobs'
                        quietly replace cif = `_graph_lastcif' in `_graph_newobs'
                        quietly replace `_graph_lci' = `_graph_lastlci' ///
                            in `_graph_newobs'
                        quietly replace `_graph_uci' = `_graph_lastuci' ///
                            in `_graph_newobs'
                    }
                }
                * The complementary-log-log interval is undefined at a boundary
                * CIF, but its graphical band has the exact zero-width limit.
                quietly replace `_graph_lci' = cif ///
                    if missing(`_graph_lci') & inlist(cif, 0, 1)
                quietly replace `_graph_uci' = cif ///
                    if missing(`_graph_uci') & inlist(cif, 0, 1)
                quietly sort `_graph_g' time

                * Default legend is a single row; because repeated legend()
                * options merge, anything in `options' (e.g. legend(off),
                * legend(rows(2)), legend(pos(6))) overrides these defaults.
                *
                * The default note() states the covariate profile, for the same
                * reason the table now prints an `at:' line: a saved .png of a
                * CIF curve otherwise carries no record of which profile it is.
                * `options' is expanded last, so a user's own note() wins.
                if "`_overmode'" == "" {
                    if "`ci'" != "" {
                        twoway ///
                            (rarea `_graph_lci' `_graph_uci' time, ///
                                color(%30) lwidth(none) connect(stairstep)) ///
                            (line cif time, lwidth(medthick) connect(stairstep)), ///
                            ytitle("Cumulative incidence") ///
                            xtitle("Analysis time") ///
                            legend(order(2 "CIF" 1 "`level'% CI") rows(1)) ///
                            note(`"`_atsrc': `_atline'"') ///
                            xscale(range(0 .)) plotregion(margin(zero)) `options'
                    }
                    else {
                        twoway ///
                            (line cif time, lwidth(medthick) connect(stairstep)), ///
                            ytitle("Cumulative incidence") ///
                            xtitle("Analysis time") legend(rows(1)) ///
                            note(`"`_atsrc': `_atline'"') ///
                            xscale(range(0 .)) plotregion(margin(zero)) `options'
                    }
                }
                else {
                    * One band per curve first (so every line is drawn on top
                    * of every band), then one line per curve.  Band and line
                    * g share pstyle p<g>, so a band is its own curve's colour
                    * at 30% opacity; pstyles cycle after the scheme's 15.
                    * The legend names the lines; the bands are named once in
                    * the note.
                    local _plots ""
                    local _legord ""
                    forvalues g = 1/`_ncurve' {
                        local _ps = mod(`g' - 1, 15) + 1
                        if "`ci'" != "" {
                            local _plots `"`_plots' (rarea `_graph_lci' `_graph_uci' time if `_graph_g' == `g', pstyle(p`_ps') color(%30) lwidth(none) connect(stairstep))"'
                        }
                    }
                    local _nband = cond("`ci'" != "", `_ncurve', 0)
                    forvalues g = 1/`_ncurve' {
                        local _ps = mod(`g' - 1, 15) + 1
                        local _plots `"`_plots' (line cif time if `_graph_g' == `g', pstyle(p`_ps') lwidth(medthick) connect(stairstep))"'
                        local _legord `"`_legord' `=`_nband' + `g'' `"`_ovvar' = `_lbl`g''"'"'
                    }
                    * Two note lines: the shared profile, then the overlay
                    * and the band -- one line ran past the plot width.
                    local _gnote2 `"`_overline'"'
                    if "`ci'" != "" local _gnote2 `"`_overline'; shaded: `level'% CI"'
                    if `"`_atline'"' != "" local _gnote1 `"`_atsrc': `_atline'"'
                    else local _gnote1 `"`_gnote2'"'
                    if `"`_atline'"' == "" local _gnote2 ""
                    twoway `_plots', ///
                        ytitle("Cumulative incidence") ///
                        xtitle("Analysis time") ///
                        legend(order(`_legord') rows(1)) ///
                        note(`"`_gnote1'"' `"`_gnote2'"') ///
                        xscale(range(0 .)) plotregion(margin(zero)) `options'
                }
            }
            local _graph_rc = _rc
            * Cleanup is required even after a graph-side failure so saving()
            * still receives only the documented analytical variables.
            if `_graph_origin_added' quietly drop if `_graph_origin' == 1
            if `_graph_origin_made' drop `_graph_origin'
            if `_graph_lci_made' drop `_graph_lci'
            if `_graph_uci_made' drop `_graph_uci'
            capture drop `_graph_g'
            if `_graph_rc' {
                if !`_side_rc' local _side_rc = `_graph_rc'
                display as error "failed to draw cumulative-incidence graph"
            }
        }
        if `"`savefile'"' != "" {
            * Label the exported columns.  This file is meant to be shared, and
            * finegray_predict labels every variable it creates ("CIF lower 90%
            * limit"); five unlabelled columns in the same package was an
            * inconsistency a recipient pays for, not the author.
            quietly {
                capture drop _curve
                label variable time "Analysis time"
                label variable cif  "Cumulative incidence (cause `=e(cause)')"
                label variable se   "Standard error of CIF"
                label variable lci  "CIF lower `level'% limit"
                label variable uci  "CIF upper `level'% limit"
                if "`_overmode'" != "" {
                    label variable over "`_ovvar' (curve)"
                    sort over time
                }
            }
            * The profile goes in a dataset NOTE, not the dataset label: a label
            * is capped at 80 characters and a wide at() profile would be cut
            * mid-token there, while a note has no such limit.
            quietly label data ///
                "finegray_cif: cumulative incidence (cause `=e(cause)')"
            local _dnote `"finegray_cif `_atsrc': `_atline'"'
            if "`_overline'" != "" local _dnote `"`_dnote'; `_overline'"'
            if "`_overline'" != "" & `"`_atline'"' == "" local _dnote `"finegray_cif `_overline'"'
            quietly notes _dta : `_dnote'
            * -quietly-: Stata's own "file X saved" and the package's
            * "(estimates saved to X)" said the same thing twice.  The package
            * note stays because it also resolves the .dta extension actually
            * written, which Stata's message does not.
            capture noisily quietly save `"`savefile'"', `savereplace'
            local _save_rc = _rc
            local _saved_path `"`savefile'"'
            if !`_save_rc' {
                capture confirm file `"`_saved_path'"'
                if _rc & !regexm(lower(`"`_saved_path'"'), "\.dta$") {
                    local _saved_path `"`_saved_path'.dta"'
                    capture confirm file `"`_saved_path'"'
                }
                if _rc local _save_rc = 601
            }
            if `_save_rc' {
                if !`_side_rc' local _side_rc = `_save_rc'
                display as error `"failed to save estimates to `savefile'"'
            }
            else display as text `"(estimates saved to `_saved_path')"'
        }
        restore
        local _preserved = 0
    }

    } /* end capture noisily */

    local rc = _rc
    if `_preserved' capture restore
    if `_held' capture _estimates unhold `_esth'
    * Give the caller back the random-number stream the bootstrap borrowed.
    if `_rngsaved' capture set rngstate `_rngstate'
    * A bootstrap that errored mid-loop leaves the cache snapshotted; restore it
    * so the fit's baseline stays resolvable (falls back to prior behaviour if it
    * too fails -- no worse than not stashing).
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
    * Drop only the _fg_* columns this command rebuilt (see the rebuild block):
    * finegray_cif is read-only and must not leave design columns behind.  After
    * any restore above these are back in the data, so the drop is unconditional.
    foreach _v of local _fgrebuilt {
        capture drop `_v'
    }
    set varabbrev `_orig_varabbrev'

    * Post the complete analytical payload even when graph/save side work
    * failed; callers can inspect r() while still receiving the side-effect rc.
    if `rc' == 0 {
        return matrix table = `R'
        return matrix at = `ZR'
        return scalar level = `level'
        return scalar cause = e(cause)
        * The baseline stratum these numbers belong to.  Returned so a caller
        * assembling several strata into one table never has to re-derive it
        * from the command line it issued.
        if "`bstratum'" != "" {
            return local bstrata "`_bsvar'"
            return scalar bstratum = `bstratum'
        }
        * The overlay: which variable, and which of its values, row by row of
        * r(at) and in the `over' column of r(table).
        if "`_overmode'" != "" {
            return local over "`_ovvar'"
            return local levels "`_ovlevs'"
            return matrix levels_mat = `_LEVM'
            if "`_overmode'" == "bstrata" return local bstrata "`_bsvar'"
        }
        * Report the profile in the vocabulary the USER typed.  e(designvars)
        * holds the package-owned design columns (`_fg_grp_2'), which the user
        * never wrote, need not have in their data, and cannot pass to at() --
        * at() itself takes `grp=1', so reporting internal names made the input
        * and output vocabularies disagree.  `_nbterms' is the fit-time
        * expansion's non-base terms (`2.grp'), built above and already relied
        * on for 1:1 alignment with e(designvars) by the rebuild loop.  Same
        * defect class fixed in finegray_phtest on 2026-07-21; the sweep had
        * stopped one command short.  Fall back to e(designvars) for non-factor
        * fits (where the two are identical) and, defensively, whenever the
        * counts disagree -- a short list silently mispairs with r(at).
        * retokenize: `_nbterms' is built by appending, so it carries a leading
        * space.  e(designvars) does not, and r(profile_vars) is a documented
        * return that callers string-compare -- a stray space would make the
        * factor and non-factor forms unequal for no reason a user could see.
        local _pv : list retokenize _nbterms
        local _pv_n : word count `_pv'
        if `"`_pv'"' != "" & `_pv_n' == `p' {
            return local profile_vars `"`_pv'"'
        }
        else {
            return local profile_vars "`covs'"
        }
        if `bootstrap' > 0 {
            return scalar bootstrap_requested = `bootstrap'
            return scalar bootstrap_success = `_bokmin'
            return scalar bootstrap_failed = `bootstrap' - `_bokmin'
        }
        * WHICH standard error filled column 3 of r(table).  Until this existed
        * the answer was only inferable -- from whether the caller had typed
        * bootstrap(), or from r(bootstrap_requested) being absent, which is
        * also what an analytic SE looks like, or from the SE column being a
        * run of dots, which is also what a degenerate curve looks like.  That
        * inference is exactly what the honest-disclosure contract must not
        * require: the package discloses in PROSE which option combination gets
        * which variance, and every such disclosure owes a machine counterpart.
        * e(vce_meat) is the fit-level one; this is the CIF-level one.
        *   "bootstrap"  resampled SD over the replications
        *   "analytic"   the delta-method CIF influence function
        * The note printed under the table says the same thing in words, so the
        * two must agree -- pinned in qa/test_finegray_fences.do.
        if `bootstrap' > 0 {
            return local se_method "bootstrap"
        }
        else {
            return local se_method "analytic"
        }
        * The fit's finite-sample factor (e(vce_adjust)) applies to the
        * COEFFICIENT variance only.  Neither the analytic CIF influence
        * sandwich nor the bootstrap SD carries it, so noadjust moves e(V) and
        * leaves column 3 of r(table) alone.  Said here so the caller need not
        * infer it from the fit's option list.
        return local vce_adjust "none"
        if `_side_rc' local rc = `_side_rc'
    }
    if `rc' exit `rc'
end
