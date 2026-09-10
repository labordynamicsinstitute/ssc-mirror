*! finegray Version 1.3.2  2026/09/08
*! Fine-Gray competing risks regression
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: eclass (returns results in e())

/*
Basic syntax:
  finegray varlist [if] [in] [pweight fweight], compete(varname) cause(#) [options]

Description:
  Fits Fine-Gray subdistribution hazard model for competing risks.
  Uses native Mata forward-backward scan algorithm (Kawaguchi et al. 2021).

  Data must be stset.  Without id() each record is one subject; id() is
  needed only when a subject contributes more than one record.

Required options:
  compete(varname)  - Event type variable (0=cens, 1=cause1, 2=cause2, ...)
  cause(#)          - Which event value is cause of interest

Optional options:
  censvalue(#)      - Censoring value (default: 0)
  noshr             - Display log-SHR instead of SHR
  level(cilevel)    - Confidence level
  strata(varlist)   - Stratify censoring distribution
  bstrata(varname)  - Stratify the BASELINE subdistribution hazard (shared beta)
  cluster(varname)  - Clustered standard errors
  norobust          - Model-based SEs instead of default sandwich
  nolog             - Suppress iteration log
  iterate(#)        - Max iterations (default: 200)
  tolerance(#)      - Convergence tolerance (default: 1e-8)

Weights:
  pweight  - design/sampling weights: every subject's risk-set contribution and
             event term is multiplied by w_i (Wogu, Zhao, Nichols & Cai 2021,
             eq. 3 score form only); analysis-sample censoring KM stays
             unweighted; fixed-weight sandwich meat sum_i (w_i s_i)^2.
             Not a general case-cohort estimator (see methods scope).
  fweight  - frequency weights: replication semantics, including in the
             censoring KM and in N.

See help finegray for complete documentation
*/

program define finegray, eclass sortpreserve
    version 16.0

    * Replay.  `finegray' typed with no varlist (or with display options only)
    * redisplays the last finegray results, as every Stata e-class estimator
    * does; `finegray, level(90)' redisplays at another confidence level and
    * `finegray, noshr' on the log-SHR scale.  Before this the command answered
    * `varlist required' r(100) and the only way back to the table was to refit
    * -- the expensive thing this package exists to avoid.
    *
    * Handled HERE, ahead of the varabbrev wrapper and the capture block below,
    * so that the `exit' costs no cleanup: nothing has been set, opened, or
    * preserved yet.  _finegray_display runs its own wrapper.
    if replay() {
        if `"`e(cmd)'"' != "finegray" {
            * `mi estimate, cmdok: finegray ...' leaves mi's POOLED results in
            * e(), which finegray cannot replay and mi can.  Say that rather
            * than "you must run finegray", which reads as though they had not.
            if `"`e(cmd)'"' == "mi estimate" & `"`e(cmd_mi)'"' == "finegray" {
                display as error "last estimates are pooled {bf:mi estimate} results, not a finegray fit"
                display as error "replay them with {bf:mi estimate} (with no command), or refit on a"
                display as error "single dataset with {bf:mi extract 0, clear} and run {bf:finegray} there;"
                display as error "see {help finegray##mi:help finegray}"
                exit 301
            }
            display as error "last estimates not found"
            display as error "you must run {bf:finegray} before replaying its results"
            exit 301
        }
        _finegray_display `0'
        exit
    }

    local _orig_varabbrev = c(varabbrev)
    set varabbrev off

    local _cmdline `"finegray `0'"'

    capture noisily {

    * =========================================================================
    * SYNTAX PARSING
    * =========================================================================
    syntax varlist(numeric fv) [if] [in] [pweight fweight] , ///
        COMPete(varname numeric) CAUse(integer) ///
        [CENSvalue(integer 0) noSHR Level(cilevel) ///
         STRata(varlist numeric) TRUNCstrata(varlist numeric) ///
         BSTRata(varname numeric) ///
         TVC(varlist numeric) TSPLIT(numlist ascending) ///
         CLuster(varname numeric) noROBust ///
         noADJust noLOG BASEHaz NUISance ///
         ITERate(integer 200) TOLerance(real 1e-8)]

    * noadjust suppresses the finite-sample correction applied to the sandwich
    * variance; the model-based (norobust) variance has no such correction, so
    * the combination is a contradiction rather than a no-op.
    if "`adjust'" == "noadjust" & "`robust'" == "norobust" {
        display as error "noadjust is not allowed with norobust"
        display as error "the finite-sample adjustment applies to the robust " ///
            "(sandwich) variance only"
        exit 198
    }

    * cluster() requests a cluster-robust sandwich while norobust requests the
    * model-based inverse information. Accepting both used the clustered
    * sandwich in the engine but posted and displayed parts of the norobust
    * contract, yielding a contradictory rc=0 result.
    if "`cluster'" != "" & "`robust'" == "norobust" {
        display as error "cluster() is not allowed with norobust"
        display as error "cluster() requests a cluster-robust sandwich variance; " ///
            "norobust requests the model-based inverse information"
        exit 198
    }

    * nuisance adds the Fine-Gray (1999) eq. 7-8 psi term to the sandwich meat.
    * It is a property of the SANDWICH, so it is meaningless without one.
    if "`nuisance'" != "" & "`robust'" == "norobust" {
        display as error "nuisance is not allowed with norobust"
        display as error "the nuisance (psi) correction applies to the " ///
            "robust (sandwich) variance only"
        exit 198
    }

    * =========================================================================
    * DESIGN WEIGHTS: SCOPE FENCES
    * =========================================================================
    * [pweight=] and [fweight=] are accepted for the RIGHT-CENSORING core --
    * the Fine-Gray score with a per-subject weight on every risk-set sum and
    * every event term. Wogu, Zhao, Nichols & Cai 2021, eq. 3 p.167
    * grounds the score form, not full case-cohort equivalence: our G is
    * estimated on sampled rows. See methods scope. Computational oracle:
    * survival::finegray(weights=) + coxph(weights=, robust=TRUE). Every other
    * cell is refused rather than composed:
    *   pweight x norobust  the inverse information is not a variance under
    *                       informative sampling; fweight x norobust is fine
    *                       (replicated subjects, model-based information)
    *   weight x nuisance   the estimated-G psi term is not held under weights
    *                       (Wogu sec. 4 writes psi with a weighted at-risk
    *                       count that differs from the sec. 3 estimator; not
    *                       adjudicated in this release)
    *   weight x strata()   conservatism, not the absence of an oracle.  R's
    *                       survival::finegray DOES stratify the censoring
    *                       Kaplan-Meier: a strata() term in the formula
    *                       becomes istrat and Gsurv is
    *                       survfit(Surv(...) ~ istrat, se.fit = FALSE)
    *                       (source read, survival 3.8.6, 2026-08-29), and the
    *                       same call takes weights, so the pair CAN be
    *                       cross-validated.  What is missing is the crossval
    *                       arm, not the reference implementation.  Wogu et
    *                       al. p. 167 likewise allow a stratified Ghat.
    *   weight x truncstrata()  no weighted source for the delayed-entry H
    *                       side; cmprsk::crr(cengroup=) has no weights and
    *                       Kim et al. (2020) is not held
    *   weight x bstrata()  Zhou et al. (2011) derive the stratified PSH model
    *                       unweighted; no crossval arm
    *   weight x tvc()      no crossval arm
    *   weight x delayed entry  refused below, once the entry times are known:
    *                       the ZZF branch is already this package's own
    *                       extension and no source weights it
    * aweight and iweight are refused by `syntax' itself (r(101)).
    if "`weight'" == "pweight" & "`robust'" == "norobust" {
        display as error "pweight is not allowed with norobust"
        display as error "the model-based (inverse information) variance is not a " ///
            "variance under sampling weights; use the default sandwich, " ///
            "or cluster()"
        exit 198
    }
    if "`weight'" != "" & "`nuisance'" != "" {
        display as error "nuisance is not allowed with `weight's"
        display as error "the estimated-G (psi) term of the sandwich is not derived " ///
            "under design weights in this release; omit {bf:nuisance}, or " ///
            "use bootstrap inference"
        exit 198
    }
    if "`weight'" != "" & "`strata'" != "" {
        display as error "strata() is not allowed with `weight's"
        display as error "the pair has no cross-validation arm in this release " ///
            "(an oracle exists -- survival::finegray stratifies its censoring " ///
            "KM -- but the arm is not written); fit without strata(), " ///
            "or without weights"
        exit 198
    }
    if "`weight'" != "" & "`truncstrata'" != "" {
        display as error "truncstrata() is not allowed with `weight's"
        display as error "weights are supported for right-censored data only"
        exit 198
    }
    if "`weight'" != "" & "`bstrata'" != "" {
        display as error "bstrata() is not allowed with `weight's"
        display as error "the stratified subdistribution hazard of Zhou et al. " ///
            "(2011) is derived without design weights and the pair has no " ///
            "cross-validation arm; see {help finegray##weights:help finegray}"
        exit 198
    }
    if "`weight'" != "" & "`tvc'" != "" {
        display as error "tvc() is not allowed with `weight's"
        display as error "a weighted piecewise beta(t) fit has no cross-validation " ///
            "arm; see {help finegray##weights:help finegray}"
        exit 198
    }

    * =========================================================================
    * A WEIGHT CARRIED BY stset IS NOT INHERITED -- IT IS REFUSED
    * =========================================================================
    * stcox and streg read the weight the data were `stset' with.  finegray
    * does not: its weight comes from the command line only.  Before this
    * guard, `stset t [pw=w], failure(...) id(id)' followed by an unweighted
    * `finegray' fitted the UNWEIGHTED estimator at rc 0 -- e(wtype) empty,
    * e(b) bit-identical to the never-weighted fit (mreldif 0) and 0.106 away
    * from the explicitly weighted one (webuse hypoxia, verified 2026-08-29).
    * Nothing in the output said so, and a user arriving from weighted st data
    * had no way to see it.
    *
    * Inheriting the weight instead is the other repair, and it is the wrong
    * one here.  The weighted cell is deliberately narrow -- norobust,
    * strata(), truncstrata(), bstrata(), tvc(), nuisance and delayed entry
    * are all refused with weights -- so adopting a stset weight silently
    * would turn working unweighted fits into refusals, and would change the
    * numbers of everyone who ever stset a weight for some other command
    * without their asking for a weighted Fine-Gray fit.  Refusing names the
    * choice and hands it back: retype the weight, or re-stset without it.
    *
    * The refusal is on the stset CHARACTERISTIC, not on any variable: _dta[st_w]
    * holds the literal weight specification (for example "[pweight=wv]"), and
    * it is empty on data stset without a weight.  aweight/iweight stset data
    * reach here too; `syntax' would refuse them with r(101) if retyped, which
    * is why the message also offers the re-stset repair.
    local _fg_stset_w : char _dta[st_w]
    if `"`_fg_stset_w'"' != "" & "`weight'" == "" {
        display as error `"the data are stset with `_fg_stset_w' and no weight was typed on finegray"'
        display as error "finegray does not read weights from stset; a fit here would be " ///
            "silently unweighted"
        display as error `"type the weight on the command -- finegray ... `_fg_stset_w', compete() cause()"'
        display as error "-- or re-stset without it for a deliberately unweighted fit"
        display as error "see {help finegray##weights:help finegray}"
        exit 198
    }

    * FENCE LIFTED 2026-08-26 (variance unification).  bstrata() frees the baseline per
    * stratum, so S0(s) and zbar(s) become stratum-specific; before the unification
    * _finegray_psi_residuals built q_g(t) from the POOLED S0(s) and zbar(s),
    * so accepting nuisance with bstrata() would have added an unstratified
    * correction to a stratified sandwich -- neither Zhou's variance nor this
    * package's.  The refusal was about the implementation, never about the
    * quantity: Zhou et al. (2011) sec. 4.1 states it exactly, as Fine & Gray
    * (1999) eq. 7-8 "with the added subscript k", and the authors' own
    * crrSC::crrs computes it by running cmprsk's unmodified per-stratum
    * variance and summing (crrvvs()).
    *
    * _finegray_psi_residuals now takes the baseline-stratum column and gives
    * every RISK-SET quantity a k index while leaving every CENSORING-KM
    * quantity on the strata() axis, which reduces to crrvvs() exactly when the
    * two axes coincide (bstrata(c) strata(c) = crrs ctype=1, the crossval) and
    * to the pre-unification term bit-identically at K = 1.  The pooled-Ghat cell --
    * bstrata() without strata() -- has no crrs counterpart and is documented
    * in Methods and formulas as this package's own composition of Zhou's
    * additivity over strata with FG's eq. (8).  The derivation is written out
    * in the header of _finegray_psi_residuals in _finegray_mata.ado.

    * =========================================================================
    * PIECEWISE-CONSTANT beta(t): tvc() / tsplit() OPTION GRAMMAR
    * =========================================================================
    * tvc() names the covariates whose effect varies with analysis time and
    * tsplit() the interior boundaries of the intervals it is constant on.
    * Neither means anything without the other: tvc() alone does not say WHERE
    * the effect changes, and tsplit() alone splits nothing.  Refuse both ways
    * rather than silently ignoring one of them.
    if "`tvc'" != "" & "`tsplit'" == "" {
        display as error "tvc() requires tsplit()"
        display as error "tsplit() gives the interior interval boundaries on " ///
            "the analysis-time scale"
        display as error "as in {bf:tvc(x) tsplit(5 10)}; " ///
            "see {help finegray##tvc:help finegray}"
        exit 198
    }
    if "`tsplit'" != "" & "`tvc'" == "" {
        display as error "tsplit() requires tvc()"
        display as error "tvc() names the covariates whose coefficient is " ///
            "allowed to differ across the intervals"
        display as error "as in {bf:tvc(x) tsplit(5 10)}; " ///
            "see {help finegray##tvc:help finegray}"
        exit 198
    }

    local _fg_ntv = 0
    local _fg_nint = 1
    if "`tvc'" != "" {
        * `numlist ascending' already refuses a repeated or out-of-order
        * boundary at the syntax statement (r(124); pinned by T14 in
        * qa/test_finegray_tvc.do).  What it does NOT enforce is positivity:
        * tsplit(0) parses, and a boundary at or below zero would define an
        * empty leading interval (0, 0] carrying its own unidentified
        * coefficient.
        local _fg_ncut : word count `tsplit'
        local _fg_nint = `_fg_ncut' + 1
        foreach _fg_c of local tsplit {
            if `_fg_c' <= 0 {
                display as error "tsplit() boundaries must be positive"
                display as error "`_fg_c' is not a time inside the follow-up"
                exit 198
            }
        }

        * FENCE LIFTED 2026-08-26 (variance unification).  The earlier refusal said the pair
        * "has no reference implementation to validate against".  That was
        * wrong, and it was checked rather than re-asserted: crrSC::crrs takes
        * cov2/tf together with its strata argument, so the pair has exactly the
        * same external oracle each half has separately.
        *
        * The two features reshape the scan on orthogonal axes -- bstrata()
        * partitions ROWS into per-stratum risk sets, tvc() partitions TIME into
        * per-interval passes over a zeroed design -- and the piecewise wrappers
        * already forwarded the stratum column into the stratified scans, so the
        * fit needed no new scan code.  What did need writing is the baseline
        * stacking: each interval pass restarts its cumulative hazard at zero,
        * so the carry-forward that stitches the intervals into one curve is now
        * per stratum (_finegray_basehazard_pw).  A pooled carry would have
        * given every stratum the sum of all the others' mass at rc 0.
        * FENCE LIFTED 2026-08-26 (variance unification).  Until the unification nuisance was
        * refused here because the psi term is Fine & Gray (1999) eq. 7-8 built
        * from ONE S0(s) and zbar(s) per event time, and under beta(t) both are
        * interval-specific.  The re-derivation is short and is written out in
        * the header of _finegray_psi_residuals_pw in _finegray_mata.ado: the
        * tvc scan is an identity (the score IS the sum over
        * intervals of the unmodified score on a zeroed design with the other
        * intervals' cause events relabelled), psi is a linear functional of the
        * score, so psi decomposes over intervals with it.
        * _finegray_psi_residuals_pw is the fifth member of the existing _pw
        * wrapper family and adds no new formula.  The evidence is the
        * hand-split equivalence oracle: a tvc() fit and an explicit
        * interval x covariate interaction fit are the same model, so under
        * nuisance they must agree in e(V) as well as e(b).
    }

    * =========================================================================
    * VALIDATE STSET (must come before marksample references _st)
    * =========================================================================
    capture st_is 2 analysis
    if _rc {
        display as error "data not st; see {helpb stset}"
        exit 119
    }

    * =========================================================================
    * MULTIPLE-IMPUTATION DATA DETECTION
    * =========================================================================
    * finegray writes package-owned PERMANENT columns into the caller's data --
    * _fg_entry for a multiple-record fit and one _fg_<term> column per factor
    * term -- so that post-estimation can rebuild the fit's design.  In mi data
    * those columns are unregistered variables: `mi describe' reports them, and
    * under mlong/flong they carry values on some m and not others.  Fitting
    * `finegray i.grp x' directly on `mi set wide' data left _fg_grp_2 and
    * _fg_grp_3 behind exactly that way.
    *
    * The fix is not new machinery: the fit itself already runs on tempvars
    * inside `preserve', and only the post-estimation SUPPORT is permanent.  On
    * mi data that support is routed through tempvars instead, which means it
    * does not survive the command -- so post-estimation is refused rather than
    * silently answering from columns that are gone (see e(postest) below and
    * the guards in finegray_predict / finegray_cif / finegray_phtest).
    *
    * The detection has to work in three contexts.  All twelve style x context
    * cells below were enumerated by running them on 2026-08-25 (hypoxia, two
    * imputations) and dumping `: char _dta[]' from inside the fitted command:
    *
    *   context               mlong     wide      flong        flongsep
    *   1 typed directly      mlong     wide      flong        flongsep
    *   2 mi estimate,cmdok:  bad       bad       ABSENT       flongsep
    *   3 mi xeq #:           flongsep_sub (all four styles)
    *
    * so _dta[_mi_style] alone misses exactly one cell: flong inside
    * `mi estimate'.  That cell is not char-free, however -- it carries
    * _dta[_mi_substyle] == "bad", the only _mi_* characteristic mi leaves on
    * the completed dataset it hands the command.  Every other cell carries
    * _mi_style plus several more (_mi_M, _mi_ivars, _mi_update, ...).
    *
    * Detection is therefore "does the DATASET carry any _mi_* characteristic",
    * which is true in all twelve cells and false on ordinary data.
    *
    * It must NOT be "does a variable named _mi_m / _mi_id / _mi_miss exist".
    * Those are legal names in an ordinary dataset, and the earlier probe on
    * them was a false positive: `generate long _mi_id = _n' on plain webuse
    * hypoxia produced e(mi_data)=1, e(postest)=unavailable_mi, and r(301) from
    * every post-estimation command, on data that had never been near mi.
    * Reproduced 2026-08-25; regression tests 14-16 in qa/test_finegray_mi.do.
    local _fg_is_mi = 0
    local _fg_dtachars : char _dta[]
    foreach _fg_dtachar of local _fg_dtachars {
        if substr("`_fg_dtachar'", 1, 4) == "_mi_" {
            local _fg_is_mi = 1
            continue, break
        }
    }

    * =========================================================================
    * MARK SAMPLE
    * =========================================================================
    marksample touse
    * NOTE: compete() is deliberately NOT passed to `markout'.  It is the
    * outcome classification, not a covariate, and an unknown event type is
    * refused below rather than dropped.  See "compete() MUST BE OBSERVED".

    * Stamp the caller's row order NOW, before any egen/gsort/sort in this
    * command can permute it.  Stata (and Mata) break sort ties using a seed
    * that ADVANCES on every sort, so a bare `sort _t' -- _t is heavily tied --
    * hands the engine a different row order on each fit, and the risk-set scan
    * then accumulates in a different floating-point order.  This key makes the
    * pre-engine sort total, so the same data always yields the same estimates.
    tempvar _fg_row0
    quietly gen long `_fg_row0' = _n

    * =========================================================================
    * DESIGN WEIGHTS: MATERIALISE
    * =========================================================================
    * `marksample' has already dropped zero and missing weights from `touse'
    * and refused a negative one (r(402)).  The expression is evaluated ONCE,
    * here, into a package-owned column the engine reads; post-estimation
    * re-evaluates e(wexp) on the data it sees, and the variables the
    * expression names are put into the estimation-data signature below so a
    * changed weight makes every post-estimation command fail rather than
    * answer under different weights.
    *   _fg_wtype  0 none, 1 pweight, 2 fweight -- the engine's code
    local _fg_w ""
    local _fg_wtype = 0
    if "`weight'" != "" {
        tempvar _fg_w
        quietly generate double `_fg_w' `exp' if `touse'
        if "`weight'" == "fweight" {
            local _fg_wtype = 2
            * Stata's own contract for frequency weights; `syntax' does not
            * enforce it, and a fractional replication count has no meaning.
            capture assert `_fg_w' == int(`_fg_w') if `touse'
            if _rc {
                display as error "may not use noninteger frequency weights"
                exit 401
            }
        }
        else local _fg_wtype = 1
    }

    * Save original varlist before FV expansion (for e(fvvarlist))
    local _orig_varlist "`varlist'"

    * Variables whose estimation-sample values define the post-estimation
    * contract. Factor/interactions are reduced to their underlying variables.
    local _fg_sigvars "_t _t0 _d `compete'"
    foreach _sig_tok of local _orig_varlist {
        local _sig_parts = subinstr(subinstr("`_sig_tok'", "##", "#", .), "#", " ", .)
        foreach _sig_part of local _sig_parts {
            if regexm("`_sig_part'", "\.(.+)$") local _sig_part = regexs(1)
            capture confirm numeric variable `_sig_part'
            if !_rc {
                local _sig_seen : list posof "`_sig_part'" in _fg_sigvars
                if `_sig_seen' == 0 local _fg_sigvars "`_fg_sigvars' `_sig_part'"
            }
        }
    }
    foreach _sig_var of local strata {
        local _sig_seen : list posof "`_sig_var'" in _fg_sigvars
        if `_sig_seen' == 0 local _fg_sigvars "`_fg_sigvars' `_sig_var'"
    }
    * truncstrata() variables define the weight design, so they belong in the
    * estimation-data signature: changing them after the fit must make every
    * postestimation command FAIL rather than silently rebuild different groups.
    foreach _sig_var of local truncstrata {
        local _sig_seen : list posof "`_sig_var'" in _fg_sigvars
        if `_sig_seen' == 0 local _fg_sigvars "`_fg_sigvars' `_sig_var'"
    }
    * bstrata() assigns every subject to a baseline.  Changing it after the fit
    * must make post-estimation FAIL, not silently answer a row from another
    * stratum's baseline curve.
    if "`bstrata'" != "" {
        local _sig_seen : list posof "`bstrata'" in _fg_sigvars
        if `_sig_seen' == 0 local _fg_sigvars "`_fg_sigvars' `bstrata'"
    }
    if "`cluster'" != "" {
        local _sig_seen : list posof "`cluster'" in _fg_sigvars
        if `_sig_seen' == 0 local _fg_sigvars "`_fg_sigvars' `cluster'"
    }
    * Every variable the weight expression names.  The expression is not itself
    * signable, but its inputs are; a function name or a numeric literal
    * fragment that happens to be a variable name is over-inclusion, never
    * under-inclusion.
    * `confirm variable', NOT `confirm numeric variable': a STRING variable can
    * feed the weight through a function -- [pw = real(strvar)] -- and a numeric
    * test drops it from the signature, after which post-estimation re-evaluates
    * e(wexp) live and rebuilds a DIFFERENT weight column at rc 0.
    * _datasignature signs string variables and detects changes in them.
    * _n and _N are the one class of token that is BOTH unsignable and
    * order/size dependent: [pw = (_n > 100)] names no variable, so nothing
    * about it enters e(datasignature), and post-estimation re-evaluates
    * e(wexp) live -- on data the user may since have sorted, subset or
    * appended -- rebuilding a DIFFERENT weight column at rc 0.  There is no
    * signature that can catch it, so the expression itself is refused; the
    * repair is one `generate'.  Scalars, e()/c() values and subscripted
    * references (w[1]) are unsignable for the same reason and are NOT refused
    * here: _finegray_weight_var reconciles the rebuilt column's total over
    * e(sample) against e(sum_w) at every post-estimation entry and refuses
    * r(459) when it has moved, which catches every member of that class
    * (see the Weights section of the help).
    if "`weight'" != "" {
        local _fg_wrest `"`exp'"'
        while regexm(`"`_fg_wrest'"', "[A-Za-z_][A-Za-z0-9_]*") {
            local _fg_wtok = regexs(0)
            local _fg_wrest = regexr(`"`_fg_wrest'"', "[A-Za-z_][A-Za-z0-9_]*", " ")
            if "`_fg_wtok'" == "_n" | "`_fg_wtok'" == "_N" {
                display as error "the weight expression may not use `_fg_wtok'"
                display as error "`_fg_wtok' names no variable, so it cannot enter e(datasignature), and"
                display as error "post-estimation re-evaluates e(wexp) on whatever row order and"
                display as error "sample size it then sees -- silently, at rc 0"
                display as error "generate the weight into a variable first, then use that variable"
                exit 198
            }
            capture confirm variable `_fg_wtok'
            if !_rc {
                local _sig_seen : list posof "`_fg_wtok'" in _fg_sigvars
                if `_sig_seen' == 0 local _fg_sigvars "`_fg_sigvars' `_fg_wtok'"
            }
        }
    }

    * Mark out missing values in variables referenced by FV specifications
    foreach _fv_tok of local varlist {
        if strpos("`_fv_tok'", ".") > 0 {
            local _mk_tok = subinstr(subinstr("`_fv_tok'", "##", "#", .), "#", " ", .)
            foreach _mk_part of local _mk_tok {
                if regexm("`_mk_part'", "\.(.+)$") {
                    local _mk_var = regexs(1)
                    capture confirm numeric variable `_mk_var'
                    if !_rc markout `touse' `_mk_var'
                }
            }
        }
    }
    if "`strata'" != "" markout `touse' `strata'
    if "`truncstrata'" != "" markout `touse' `truncstrata'
    if "`bstrata'" != "" markout `touse' `bstrata'
    if "`cluster'" != "" markout `touse' `cluster'

    quietly replace `touse' = 0 if _st != 1

    * =========================================================================
    * compete() MUST BE OBSERVED ON EVERY ESTIMATION-SAMPLE RECORD
    * =========================================================================
    * This used to be `markout `touse' `compete'' beside `marksample'.  markout
    * is the right tool for a covariate and the wrong one for the outcome
    * classification: it dropped every record whose event type was UNKNOWN
    * with no message, no e() count and no note -- including failure records
    * (_d==1), where the drop removes an event from the estimand and moves the
    * coefficients.  Live on webuse hypoxia, blanking compete() on five records
    * of which three were cause-1 failures returned rc 0 with N 109 -> 104,
    * N_fail 33 -> 30 and b(ifp) .0326664 -> .04609379, a 41% change.
    *
    * It was also strictly inconsistent with the consistency checks further
    * below, which fail closed at r(198) on a record whose event type merely
    * DISAGREES with _d -- and those counts are restricted to `touse', so the
    * stricter case was the one that survived.  Refuse the unknown case too.
    *
    * Placed AFTER the covariate/strata/cluster markouts and the _st filter, so
    * a record already excluded for a missing covariate or an out-of-sample _st
    * cannot raise this error: only a record that would otherwise have been fit
    * counts.
    *
    * The common way in is stsetting the failure indicator ON the event-type
    * variable and then splitting: `stset t, failure(status) id(id)' followed by
    * `stsplit' sets `status' to missing on every non-terminal episode.  The
    * EXPRESSION form does it too -- verified 2026-08-19, `failure(ev == 1 2)'
    * then `stsplit sp, at(2 6)' blanked 765 of 1365 records -- so what makes
    * the ordinary fixtures safe is not the form but that they stset a SEPARATE
    * indicator, `failure(dfcens == 1)' with `compete(status)'.  Before this
    * guard that configuration reached r(459) "positivity violation in the
    * delayed-entry weights ... use coarser strata()", a message about a cause
    * that was not the cause: the blanked episodes were dropped, every surviving
    * record started at the last split boundary, and the reverse-time product
    * limit for H hit zero there.
    quietly count if `touse' & missing(`compete')
    if r(N) > 0 {
        local _fg_nmiss = r(N)
        quietly count if `touse' & missing(`compete') & _d == 1
        local _fg_nmissfail = r(N)
        display as error "compete() is missing on `_fg_nmiss' record(s) of the estimation sample"
        display as error "`_fg_nmissfail' of them are stset failures (_d==1)"
        display as error "finegray cannot classify a record whose event type is unknown, and"
        display as error "dropping such records would remove events from the estimand silently"
        display as error "if these data were {help stsplit:stsplit} after an {cmd:stset} whose {cmd:failure()}"
        display as error "was built on `compete', {cmd:stsplit} set `compete' to missing on every"
        display as error "non-terminal episode; carry the subject's event type onto every episode,"
        display as error "or exclude those records with {cmd:if}"
        exit 198
    }

    quietly count if `touse'
    if r(N) == 0 {
        display as error "no observations"
        exit 2000
    }
    local N = r(N)

    * No id() in stset: each record is its own subject.  That is what stset
    * itself means by an id()-less declaration, and stsplit and (start,stop]
    * data require id(), so this is the single-record case by construction
    * (stcrreg accepts it the same way).  Key the subject-level machinery by
    * row so the reduction below sees one record per subject and skips
    * itself.  The key is a tempvar and cannot be posted as e(idvar): the
    * weight digest is keyed by e(idvar) at fit time and at post-estimation
    * reconciliation alike, so an id()-less fit uses its value-only form on
    * both sides.  `_fg_idvar' is the name posted to e(); `_fg_id' the key
    * the subject-level passes below actually sort and group on.
    local _fg_idvar `"`_dta[st_id]'"'
    local _fg_id `"`_fg_idvar'"'
    if `"`_fg_id'"' == "" {
        tempvar _fg_rowid
        quietly generate long `_fg_rowid' = _n
        local _fg_id `_fg_rowid'
    }

    * =========================================================================
    * MULTIPLE-RECORD REDUCTION
    * =========================================================================
    * Subjects may contribute multiple in-sample records (delayed entry /
    * (start,stop] intervals / stsplit).  When covariates are constant within
    * subject this is purely a data-shape issue: reduce each subject to a
    * single risk-set unit (earliest entry, latest exit, final status) and let
    * the engine's left-truncation handle the rest.
    *
    * What is NOT supported here is time-varying COVARIATES: a covariate that
    * changes value within subject cannot survive the reduction, and internal
    * time-varying covariates generally lack the model's direct CIF
    * interpretation after a competing event anyway.  The constancy check below
    * is what enforces that.
    *
    * Time-varying COEFFICIENTS are a different thing and ARE supported here.
    * tvc()/tsplit() vary beta(t), not x, so the reduction does not touch them:
    * the subject's one risk-set unit still spans the whole tsplit() grid.  Only
    * DELAYED ENTRY is refused with tvc() (see the _fg_has_lt guard below), and
    * on multiple-record data with earliest entry zero that guard does not fire.
    * Verified 2026-08-25: a 1200-subject fixture split into 2280 zero-entry
    * (start,stop] episodes and fitted with tvc(x1) tsplit(0.7) returns e(b),
    * e(V) and e(ll) BIT-IDENTICAL to the single-record fit of the same data.
    * Pinned by test T26 in qa/test_finegray_tvc.do.
    local _fg_nrecords = `N'

    tempvar _fg_nrec
    quietly egen long `_fg_nrec' = total(`touse'), by(`_fg_id')
    quietly summarize `_fg_nrec' if `touse', meanonly
    local _fg_maxrec = r(max)

    local _fg_reduced = 0
    local _fg_entryvar ""
    local _fg_entry_pending = 0
    if `_fg_maxrec' > 1 {
        * --- covariate constancy check (raw vars, strata, cluster) ---
        local _fg_checkvars ""
        foreach _cv of local _orig_varlist {
            local _cvtok = subinstr(subinstr("`_cv'", "##", "#", .), "#", " ", .)
            foreach _cp of local _cvtok {
                if regexm("`_cp'", "\.(.+)$") local _cp = regexs(1)
                capture confirm numeric variable `_cp'
                if !_rc {
                    local _seen : list posof "`_cp'" in _fg_checkvars
                    if `_seen' == 0 local _fg_checkvars "`_fg_checkvars' `_cp'"
                }
            }
        }
        foreach _cv of local strata {
            local _seen : list posof "`_cv'" in _fg_checkvars
            if `_seen' == 0 local _fg_checkvars "`_fg_checkvars' `_cv'"
        }
        foreach _cv of local truncstrata {
            local _seen : list posof "`_cv'" in _fg_checkvars
            if `_seen' == 0 local _fg_checkvars "`_fg_checkvars' `_cv'"
        }
        * A subject cannot move baselines part-way through follow-up: bstrata()
        * must be constant within id().  The constancy loop below reports it in
        * the same words as a time-varying covariate, which is what it is.
        if "`bstrata'" != "" {
            local _seen : list posof "`bstrata'" in _fg_checkvars
            if `_seen' == 0 local _fg_checkvars "`_fg_checkvars' `bstrata'"
        }
        if "`cluster'" != "" {
            local _seen : list posof "`cluster'" in _fg_checkvars
            if `_seen' == 0 local _fg_checkvars "`_fg_checkvars' `cluster'"
        }

        * Put selected records first once.  The former `egen sd(), by(id)'
        * loop re-ran grouped aggregation (and its sort machinery) for every
        * covariate.  Direct comparison with the first selected record has the
        * same O(N*p) information requirement without p grouped egen passes;
        * this ordering is also the one needed by the interval check below.
        quietly gsort `_fg_id' -`touse' _t0 _t `_fg_row0'
        tempvar _fg_vary
        foreach _cv of local _fg_checkvars {
            capture drop `_fg_vary'
            * EXACT inequality, not a 1e-9 band.  These fields are documented
            * as constant within subject, so any difference at all is a
            * violation, and an absolute 1e-9 was scale-dependent: on data
            * measured in units where a real change is 1e-10 the check passed
            * silently, and the reduction then kept one record's value for a
            * covariate that had moved.  Every row reaching this expression is
            * a `touse' row, and `touse' has been marked out on every variable
            * in `_fg_checkvars' above, so both operands are non-missing here
            * and `. != .' cannot arise.
            quietly by `_fg_id': gen byte `_fg_vary' = ///
                (`touse' & `_cv' != `_cv'[1])
            quietly count if `_fg_vary'
            if r(N) > 0 {
                display as error "finegray requires covariates constant within id()"
                display as error "covariate `_cv' varies within subject"
                display as error "this implementation does not support time-varying covariates"
                display as error "for internal time-varying covariates, consider a cause-specific"
                display as error "model with {help stcox}; see {help finegray##lt:finegray}"
                exit 198
            }
        }

        * A weight is a property of the SUBJECT: the same subject cannot carry
        * one sampling probability on its first episode and another on its
        * last.  Same test as the covariates above, its own words.
        if "`weight'" != "" {
            capture drop `_fg_vary'
            * Exact, for the reason given at the covariate loop above;
            * `marksample' has already dropped missing and zero weights from
            * `touse', so both operands are non-missing.
            quietly by `_fg_id': gen byte `_fg_vary' = ///
                (`touse' & `_fg_w' != `_fg_w'[1])
            quietly count if `_fg_vary'
            if r(N) > 0 {
                display as error "finegray requires the `weight' constant within id()"
                display as error "the weight varies within subject for `r(N)' record(s)"
                display as error "a design weight belongs to the subject, not to the episode;"
                display as error "carry one value onto every record, or collapse to one"
                display as error "record per subject before fitting"
                exit 198
            }
        }

        * --- gap / overlap check: intervals must be contiguous within id ---
        * Check every adjacent boundary.  Comparing total covered time with the
        * overall span is insufficient: an overlap and an equal-sized gap cancel
        * arithmetically, after which the reduction silently invents continuous
        * follow-up across the gap.  Put selected records first, order them by
        * start/stop time with a total row-order key, and compare each start with
        * the preceding stop.  This one grouped pass also supplies the subject's
        * earliest entry time used below, replacing three egen passes.
        tempvar _fg_seq _fg_badspan _fg_mint0
        quietly by `_fg_id': gen long `_fg_seq' = sum(`touse')
        * RELATIVE tolerance, sized to floating-point representation error.
        * Adjacency compares two times that are meant to be the SAME number,
        * so the only difference to forgive is accumulated double-precision
        * rounding: 1e-12 of the larger boundary, roughly four decimal digits
        * of headroom above one ulp.  An absolute 1e-9 answered a different
        * question at every time scale: on times of order 1e-10 it accepted a
        * gap five times the whole follow-up.  A plain 1e-9 RELATIVE band has
        * the opposite fault -- at a time origin of 1e9 it forgives a full
        * unit, and a genuine 0.01 boundary error (pinned in
        * qa/test_finegray_v110.do) would pass.  A few ulp is too tight to be
        * a rule about DATA: two boundaries built by different arithmetic
        * routes -- (d2 - o)/365.25 against d2/365.25 - o/365.25 -- differ by
        * several ulp and describe the same instant, and refusing those would
        * be a refusal about rounding rather than about follow-up.  1e-12
        * relative is exact when both boundaries are 0 and means the same
        * thing at every scale.
        quietly by `_fg_id': gen byte `_fg_badspan' = ///
            (`touse' & `_fg_seq' > 1 & ///
            abs(_t0 - _t[_n - 1]) > ///
            1e-12 * max(abs(_t0), abs(_t[_n - 1])))
        quietly count if `_fg_badspan'
        if r(N) > 0 {
            display as error "finegray: subject records have gaps or overlaps"
            display as error "each subject's intervals must be contiguous"
            display as error "(no gaps or overlapping time spans); collapse to one"
            display as error "record per subject before fitting"
            exit 198
        }
        quietly by `_fg_id': gen double `_fg_mint0' = _t0[1] if `touse'

        * --- one failure per subject, and it must be the last record --------
        * The reduction below keeps ONE record per subject -- the one at
        * max(_t) -- and drops the rest from `touse'.  Under `stset ...,
        * exit(time .)' a subject may carry a _d==1 record that is NOT its
        * last: a second failure after the first (recurrent events), or
        * censored follow-up continued past the failure.  Either way the
        * reduction silently discards the failure: a subject whose cause-1
        * event at t1 is followed by a competing event at t2 enters the
        * estimation as a cause-2 subject, one followed by a censored record
        * enters as censored -- at rc 0, with the cause-of-interest failure
        * gone from the numerator and from e(N_fail).  finegray models the
        * SUBDISTRIBUTION of a single first event per subject, so there is no
        * defensible record to pick silently.  Count first, refuse by name.
        *
        * The rows are sorted (id, -touse, _t0, _t) here and the intervals are
        * contiguous, so within a subject the in-sample rows come first in
        * time order and the last of them is the record the reduction keeps.
        * A failure on any earlier in-sample row is the defect.  Counting
        * `_d == 1' rows alone is not enough: a failure followed by ONE
        * censored record is a single failure record and still vanishes.
        tempvar _fg_earlyfail _fg_efsub
        quietly by `_fg_id': gen byte `_fg_earlyfail' = ///
            (`touse' & _d == 1 & _n < _N & `touse'[_n + 1] == 1)
        quietly by `_fg_id': gen byte `_fg_efsub' = ///
            (_n == _N & sum(`_fg_earlyfail') > 0)
        quietly count if `_fg_efsub'
        if r(N) > 0 {
            display as error "finegray: `r(N)' subject(s) have a failure record that is not their last record"
            display as error "finegray models a single first event per subject; the multiple-record"
            display as error "reduction keeps only the record at the latest exit time, so a failure"
            display as error "followed by further records -- a second failure, or follow-up continued"
            display as error "past it, as {bf:stset, exit(time .)} permits -- would be dropped silently"
            display as error "keep each subject's FIRST event (re-{bf:stset} without {bf:exit(time .)})"
            display as error "or recode the outcome"
            exit 198
        }
        capture drop `_fg_earlyfail'
        capture drop `_fg_efsub'

        * --- claim the entry-time name, but do not write it yet ---
        * Post-estimation (finegray_cif, finegray_predict ci/schoenfeld,
        * finegray_phtest, bootstrap refits) recomputes risk sets from the
        * data; the kept record's own _t0 is its last interval start, so the
        * true entry must survive outside this program's preserve block.
        * Creating _fg_entry here would mutate the dataset BEFORE the input
        * validation below: a validation failure then drops the column in the
        * cleanup zone while a prior fit's e() still refers to it.  Check the
        * name is available now (a pure error path), and materialise the
        * column only once validation has passed.
        * On mi data the entry column is a TEMPVAR (see the mi block above), so
        * it claims no name in the caller's dataset and this check has nothing
        * to adjudicate: an existing user variable called _fg_entry is not in
        * its way and must not be refused over a name finegray will not take.
        * The recorded NAME is not ownership: a user who drops _fg_entry and
        * regenerates their own variable under that name keeps it (the column
        * carries no current ownership marker), and this fit is refused rather
        * than deleting it.  Same adjudication as the deferred write below.
        if !`_fg_is_mi' {
            capture confirm variable _fg_entry
            if !_rc {
                local _own_e0 : char _fg_entry[_finegray_owner]
                if `"`_dta[_finegray_entryvar]'"' != "_fg_entry" | ///
                    `"`_own_e0'"' == "" | ///
                    `"`_own_e0'"' != `"`_dta[_finegray_owner]'"' {
                    display as error "variable _fg_entry exists and was not created by finegray; rename or drop it"
                    display as error "finegray uses this name to record subject entry times"
                    display as error "for multiple-record data"
                    exit 198
                }
            }
        }
        local _fg_entry_pending = 1

        * --- reduce: keep the record at max(_t) per subject ---
        tempvar _fg_obs _fg_seen _fg_surv
        gen long `_fg_obs' = _n
        gsort `_fg_id' -_t -_d -`_fg_obs'
        by `_fg_id': gen long `_fg_seen' = sum(`touse')
        gen byte `_fg_surv' = (`touse' & `_fg_seen' == 1)

        * Commit contract (Critical Rule 15).  The reduction REWRITES the
        * estimation sample, so the subjects it keeps are counted before
        * `touse' is narrowed rather than after: the count is the same number
        * either way (`_fg_surv' implies `touse', and every subject with a
        * marked record keeps exactly one), but taken here it can refuse an
        * empty result instead of describing one.  Unreachable today -- the
        * emptiness guard above this block has already required at least one
        * marked record, and a reduction of a non-empty sample cannot produce
        * none -- and kept so that a future change to `_fg_seen'/`_fg_surv'
        * fails closed rather than fitting on nothing.
        quietly count if `_fg_surv'
        local N = r(N)
        if `N' == 0 {
            display as error "no observations left after reducing to one record per subject"
            exit 2000
        }
        quietly replace `touse' = 0 if !`_fg_surv'

        local _fg_reduced = 1
        display as text "(note: `_fg_nrecords' records reduced to `N' subjects)"
    }

    * Delayed entry is a property of the SUBJECT, not of the record: with
    * (start, stop] intervals every record after the first has _t0 > 0 without any
    * left truncation at all.  A subject has delayed entry only if its EARLIEST
    * entry is positive.  This flag selects the weight (A = G*H vs A = G) and is
    * reported in e(lt_weight), so getting it wrong silently switches estimators.
    *
    * Derived from quantities the reduction already computed.  An `egen ... by()`
    * here would RE-SORT the data, permuting records tied on _t and changing the
    * scan's floating-point accumulation order -- which perturbs every no-delayed-
    * entry result in its last digits.  Gate Z-perf #3 caught exactly that.
    if `_fg_reduced' {
        quietly count if `touse' & `_fg_mint0' > 0 & !missing(`_fg_mint0')
    }
    else {
        quietly count if `touse' & _t0 > 0
    }
    * Kept as well as tested: the header reports HOW MANY subjects entered late,
    * because "this fit has delayed entry" and "three of 4,000 subjects entered
    * late" are different facts and only the second one tells the reader how
    * much of the estimate rides on the entry weights.
    local _fg_n_lt = r(N)
    local _fg_has_lt = (r(N) > 0)

    * The psi term is Fine & Gray (1999) eq. 7-8, derived for right censoring
    * with no entry times.  Its delayed-entry analogue is the ZZF (2011)
    * Appendix B influence function, implemented since 2026-08-28 for the
    * POOLED Weight 1 (_finegray_psi_residuals_lt).  With weight strata --
    * strata() or truncstrata() -- ZZF (Appendix E, p.1949) themselves
    * estimate the variance "treating the weight function known", which is
    * the default fixed_weight_sandwich; a nuisance term for that cell would
    * be a package invention, so it is refused rather than approximated.
    if "`nuisance'" != "" & `_fg_has_lt' & ///
       ("`strata'" != "" | "`truncstrata'" != "") {
        display as error "nuisance is not allowed with delayed entry and weight strata"
        display as error "the delayed-entry psi term (Zhang, Zhang and Fine 2011, " ///
            "Appendix B) is derived for the pooled weight; for a stratified"
        display as error "weight their Appendix E treats the weight as known, " ///
            "which is the default (fixed-weight) sandwich"
        display as error "omit {bf:nuisance}, or use bootstrap coefficient inference; " ///
            "see {help finegray##variance:help finegray}"
        exit 198
    }

    * Zhou, Latouche, Rocha & Fine (2011) derive the stratified proportional
    * subdistribution hazards model for RIGHT-CENSORED data; neither that paper
    * nor Zhang/Zhang/Fine (2011) treats left truncation, so a stratified
    * baseline on the delayed-entry branch would be a package invention with no
    * derivation behind it.  This is also what keeps bstrata() a five-scan-
    * function change instead of a ten: the ZZF branch is untouched.
    if "`bstrata'" != "" & `_fg_has_lt' {
        display as error "bstrata() with delayed entry is an unsourced composition, not implemented"
        display as error "`_fg_n_lt' subject(s) in the estimation sample enter after time 0"
        display as error "the stratified subdistribution hazard of Zhou et al. (2011) is"
        display as error "derived for right censoring only; combining it with the left-truncated"
        display as error "branch has no published derivation"
        display as error "fit within stratum, or drop the delayed entry;"
        display as error "see {help finegray##bstrata:help finegray}"
        exit 198
    }

    * The piecewise scans rebuild the risk set and the retained-competing
    * accumulator at every interval boundary, and they do it by re-running the
    * RIGHT-CENSORING scan once per interval.  The delayed-entry (ZZF) branch is
    * a separate family of five scan functions with no piecewise form, and it is
    * already this package's own extension of Zhang/Zhang/Fine (2011) rather
    * than a published estimator, so a beta(t) built on top of it would be
    * unsourced twice over.  Refuse instead of quietly fitting the proportional
    * estimator under a piecewise coefficient stripe.
    if "`tvc'" != "" & `_fg_has_lt' {
        display as error "tvc() is not supported with delayed entry"
        display as error "`_fg_n_lt' subject(s) in the estimation sample enter after time 0"
        display as error "the piecewise-constant beta(t) scan is derived for right censoring;"
        display as error "the delayed-entry weights have no published piecewise analogue"
        display as error "drop the delayed entry, or model the effect as proportional;"
        display as error "see {help finegray##tvc:help finegray}"
        exit 198
    }

    * Weights are supported for right censoring only.  The delayed-entry
    * branch (ZZF Weight 1) is already this package's own extension of Zhang,
    * Zhang and Fine (2011), and no source derives a design-weighted version
    * of it; weighting it would be unsourced twice over -- the same argument
    * that fences tvc() and bstrata() off that branch.
    if "`weight'" != "" & `_fg_has_lt' {
        display as error "`weight's are not supported with delayed entry"
        display as error "`_fg_n_lt' subject(s) in the estimation sample enter after time 0"
        display as error "the weighted subdistribution score is derived for right censoring"
        display as error "(Wogu et al. 2021); the delayed-entry weights have no published"
        display as error "design-weighted analogue"
        display as error "drop the delayed entry, or fit without weights;"
        display as error "see {help finegray##weights:help finegray}"
        exit 198
    }

    if "`truncstrata'" != "" & !`_fg_has_lt' {
        display as error "truncstrata() requires delayed entry"
        display as error "no subject in the estimation sample enters after time 0, " ///
            "so there is no entry distribution to stratify"
        display as error "stset with enter() to specify delayed entry"
        exit 198
    }

    * =========================================================================
    * VALIDATE INPUTS
    * =========================================================================
    if `cause' == `censvalue' {
        display as error "cause() and censvalue() must differ"
        exit 198
    }

    if `iterate' < 1 {
        display as error "iterate() must be a positive integer"
        exit 198
    }
    * syntax's real type ACCEPTS a missing value, and `. <= 0' is false in
    * Stata (missing sorts above any number), so a bare `<= 0' test lets
    * tolerance(.) through -- and every convergence comparison against a
    * missing tolerance is then vacuously true.  iterate(.) is already rejected
    * by syntax's integer type; mirror that here.
    if missing(`tolerance') | `tolerance' <= 0 {
        display as error "tolerance() must be a positive number"
        exit 198
    }

    * Check compete variable has cause value
    quietly count if `compete' == `cause' & `touse'
    local N_fail = r(N)
    if `N_fail' == 0 {
        display as error "no observations with compete() == `cause'"
        exit 198
    }

    * Count competing events
    quietly count if `compete' != `censvalue' & `compete' != `cause' & `touse'
    local N_compete = r(N)

    * Count censored
    quietly count if `compete' == `censvalue' & `touse'
    local N_cens = r(N)

    * Frequency weights replicate subjects, so every count the header reports
    * -- and e(N), the N of the finite-sample adjustment -- is the replicated
    * one, as it would be on the expanded data.  Probability weights leave the
    * counts alone: e(N) is the number of subjects, as in every official
    * pweight estimator.  e(sum_w) carries the weight total either way.
    local _fg_Nrep = `N'
    local _fg_sumw = .
    local _fg_wsig ""
    local _fg_wsig_n = 0
    if "`weight'" != "" {
        quietly summarize `_fg_w' if `touse', meanonly
        local _fg_sumw = r(sum)
        if "`weight'" == "fweight" {
            local _fg_Nrep = r(sum)
            quietly summarize `_fg_w' if `compete' == `cause' & `touse', meanonly
            local N_fail = r(sum)
            quietly summarize `_fg_w' if `compete' != `censvalue' ///
                & `compete' != `cause' & `touse', meanonly
            local N_compete = r(sum)
            quietly summarize `_fg_w' if `compete' == `censvalue' & `touse', meanonly
            local N_cens = r(sum)
        }
    }

    * FG-M06: the "no competing events" and "no censored observations" guards that
    * used to sit here are GONE.  Both are legitimate limiting cases of the model,
    * not user errors, and the combined-weight path handles each exactly:
    *
    *   no competing events -> no subject is ever retained in a risk set past its
    *     own exit, so the subdistribution risk set IS the ordinary risk set and the
    *     estimator collapses to Cox on cause `cause'.  (Verified against stcox.)
    *   no censoring -> G(t) == 1 everywhere, so A == H (== 1 too without delayed
    *     entry) and every weight is 1.  Complete follow-up is not a defect.
    *
    * They were refused before only because the old G-only weight path had not been
    * shown to degrade gracefully.  Refusing to fit a model that is perfectly well
    * defined is its own kind of wrong answer.  Both cases are gated in
    * qa/test_finegray_zzf.do.

    * Validate compete/stset consistency (both directions)
    quietly count if _d == 0 & `compete' != `censvalue' & `touse'
    if r(N) > 0 {
        display as error "compete() and stset failure indicator do not match"
        display as error "_d==0 but compete() != `censvalue' for `r(N)' observations"
        exit 198
    }

    quietly count if _d == 1 & `compete' == `censvalue' & `touse'
    if r(N) > 0 {
        display as error "compete() and stset failure indicator do not match"
        display as error "_d==1 but compete() == `censvalue' for `r(N)' observations"
        exit 198
    }

    if "`level'" == "" local level = c(level)

    * =========================================================================
    * MATERIALISE THE ENTRY-TIME COLUMN (multi-record fits only)
    * =========================================================================
    * OWNERSHIP MARKER for the columns this run is about to write.
    *
    * The cleanup and adopt paths below used to recognise a package column by its
    * NAME alone: any variable called _fg_grp_2 that a prior fit had recorded was
    * dropped, whatever it now contained.  A user who dropped _fg_grp_2 and
    * regenerated it as their own variable lost it silently on the next fit.  A
    * per-run token written as a characteristic on each generated column makes
    * ownership checkable: a column that does not carry the PRIOR run's token is
    * not ours to drop, and the fit is refused r(198) instead.
    *
    * Characteristics survive sort, preserve/restore and save/use, and are NOT
    * copied by `generate' -- which is what makes the marker discriminating.
    * `clonevar' does copy them; a clone of a package column therefore inherits
    * the marker and is treated as ours.  That is accepted: it is the same
    * ambiguity `clonevar' creates for every other characteristic.
    local _prev_owner `"`_dta[_finegray_owner]'"'
    local _fg_owner_tok ""
    if !`_fg_is_mi' {
        capture confirm number $finegray_bh_ctr
        if _rc global finegray_bh_ctr = 0
        global finegray_bh_ctr = $finegray_bh_ctr + 1
        local _fg_owner_tok = "fg" + string(clock("`c(current_date)' `c(current_time)'", ///
            "DMYhms"), "%21x") + "." + "$finegray_bh_ctr"
    }

    local _prev_estimated `"`_dta[_finegray_estimated]'"'
    local _prev_fv_created `"`_dta[_finegray_fvvars]'"'
    local _prev_entryvar `"`_dta[_finegray_entryvar]'"'

    * =========================================================================
    * FACTOR-VARIABLE NAME DERIVATION -- BEFORE ANY MUTATION
    * =========================================================================
    * The _fg_<term> names this run will write are derived HERE so that the
    * ownership adjudication below can probe them, and so that the refusals the
    * derivation itself raises -- an unsupported factor-variable operator and a
    * 32-character truncation collision -- happen before the entry column is
    * rewritten, before the _dta[_finegray_*] characteristics are blanked and
    * before a prior run's columns are dropped.  Deriving them inside the
    * creation loop further down meant those refusals fired mid-mutation: the
    * fit was correctly refused, and the dataset was left with no ownership
    * chain and no usable prior fit.  The creation loop consumes `_fv_namemap'
    * (one token per semantic term, `.' for a skipped base level) rather than
    * re-deriving anything.
    local _has_fv = 0
    foreach _fv_tok of local varlist {
        if strpos("`_fv_tok'", ".") > 0 {
            local _has_fv = 1
            continue, break
        }
    }

    local _fv_namemap ""
    local _fv_newnames ""
    if `_has_fv' {
        * Get semantic expansion (includes base markers like 1b.race)
        fvexpand `varlist' if `touse'
        local _fv_semantic `r(varlist)'

        * Get actual variable columns (one per term, including base)
        fvrevar `varlist' if `touse'
        local _fv_actual `r(varlist)'

        * Verify counts match (both include base terms)
        local _n_sem : word count `_fv_semantic'
        local _n_act : word count `_fv_actual'
        if `_n_sem' != `_n_act' {
            display as error "internal error: fvexpand/fvrevar term count mismatch"
            display as error "(`_n_sem' semantic terms vs `_n_act' fvrevar variables)"
            exit 198
        }

        * _fv_names holds every name claimed by this specification (a
        * passthrough original variable included), which is what the truncation
        * collision test compares against.  _fv_newnames holds only the
        * _fg_<term> columns this run would WRITE into the caller's data; on mi
        * data those are tempvars, so nothing is claimed and the list stays
        * empty while the collision test still adjudicates the specification.
        local _fv_names ""
        forvalues _i = 1/`_n_sem' {
            local _term : word `_i' of `_fv_semantic'
            local _var : word `_i' of `_fv_actual'

            * Skip base categories (marked with Nb. in fvexpand output)
            if regexm("`_term'", "[0-9]+b\.") {
                local _fv_namemap "`_fv_namemap' ."
                continue
            }

            * If fvrevar returned original variable (not tempvar), use directly
            if substr("`_var'", 1, 2) != "__" {
                local _fv_namemap "`_fv_namemap' `_var'"
                local _fv_names "`_fv_names' `_var'"
                continue
            }

            * Generate _fg_ variable name from FV term
            * Parse parts separated by # : N.var -> var_N, c.var -> var
            local _fg_parts ""
            local _remaining "`_term'"
            while "`_remaining'" != "" {
                local _hashpos = strpos("`_remaining'", "#")
                if `_hashpos' > 0 {
                    local _part = substr("`_remaining'", 1, `_hashpos' - 1)
                    local _remaining = substr("`_remaining'", `_hashpos' + 1, .)
                }
                else {
                    local _part "`_remaining'"
                    local _remaining ""
                }

                * A kept factor level part is `N.var' or `Nbn.var' (base-none:
                * ibn. omits no reference, so its first level 1bn.var carries a
                * REAL coefficient and must produce a legal name, not the raw
                * token _fg_1bn.varXx that r(198)'d before).  Base parts (Nb.var)
                * never reach here -- the whole term is skipped above.
                if regexm("`_part'", "^([0-9]+)(bn)?\.(.+)$") {
                    if "`_fg_parts'" != "" local _fg_parts "`_fg_parts'X"
                    local _fg_parts "`_fg_parts'`=regexs(3)'_`=regexs(1)'"
                }
                else if regexm("`_part'", "^c\.(.+)$") {
                    if "`_fg_parts'" != "" local _fg_parts "`_fg_parts'X"
                    local _fg_parts "`_fg_parts'`=regexs(1)'"
                }
                else if strpos("`_part'", ".") {
                    * A dotted operator the shared grammar does not model (o., a
                    * future marker).  Copying it verbatim into a variable name
                    * produced an illegal name; refuse explicitly instead.
                    display as error "factor-variable operator in `_part' is not supported"
                    display as error "finegray supports i., ib#., ibn., c., #, and ## terms"
                    exit 198
                }
                else {
                    if "`_fg_parts'" != "" local _fg_parts "`_fg_parts'X"
                    local _fg_parts "`_fg_parts'`_part'"
                }
            }

            local _fg_name "_fg_`_fg_parts'"
            if length("`_fg_name'") > 32 {
                local _fg_name = substr("`_fg_name'", 1, 32)
            }

            * Detect name collision from truncation within this run
            local _collision : list posof "`_fg_name'" in _fv_names
            if `_collision' > 0 {
                display as error "factor variable names too similar"
                display as error "`_fg_name' collides after truncation to 32 characters"
                display as error "use shorter variable names or fewer interaction levels"
                exit 198
            }

            local _fv_names "`_fv_names' `_fg_name'"
            local _fv_namemap "`_fv_namemap' `_fg_name'"
            if !`_fg_is_mi' local _fv_newnames "`_fv_newnames' `_fg_name'"
        }
    }

    * =========================================================================
    * OWNERSHIP ADJUDICATION -- REFUSE BEFORE ANY MUTATION
    * =========================================================================
    * Every package-owned column this run would drop or replace is adjudicated
    * HERE, before the entry column is rewritten and before the
    * _dta[_finegray_*] characteristics are blanked below.  The per-site checks
    * further down are kept as defence in depth, but they used to be the ONLY
    * checks -- and they fired after `_fg_entry' had been dropped and recreated
    * and after _dta[_finegray_owner] had been blanked, so a refusal destroyed
    * the ownership chain for every column it had not yet reached: the fit was
    * correctly refused, and every later fit was then refused too, naming a
    * column finegray itself had created, until the user dropped it by hand.
    * Adjudicating first means a refusal leaves the dataset exactly as it was.
    if !`_fg_is_mi' {
        * The entry column this run will (re)create, which decides whether a
        * prior run's entry column is a different name that needs cleaning up.
        local _entrynext "`_fg_entryvar'"
        if `_fg_entry_pending' local _entrynext "_fg_entry"

        local _own_probe ""
        if `_fg_entry_pending' local _own_probe "_fg_entry"
        if `"`_prev_estimated'"' == "1" & `"`_prev_entryvar'"' != "" & ///
            "`_prev_entryvar'" != "`_entrynext'" {
            local _own_probe "`_own_probe' `_prev_entryvar'"
        }
        if `"`_prev_estimated'"' == "1" & `"`_prev_fv_created'"' != "" {
            local _own_probe "`_own_probe' `_prev_fv_created'"
        }
        local _own_probe : list uniq _own_probe
        foreach _op of local _own_probe {
            capture confirm variable `_op'
            if _rc continue
            local _own_c : char `_op'[_finegray_owner]
            if `"`_own_c'"' == "" | `"`_own_c'"' != `"`_prev_owner'"' | ///
                `"`_prev_owner'"' == "" {
                display as error "variable `_op' exists and was not created by finegray; rename or drop it"
                if "`_op'" == "_fg_entry" | "`_op'" == "`_prev_entryvar'" {
                    display as error "finegray uses this name to record subject entry times for multiple-record data"
                }
                else {
                    display as error "finegray writes this name for a factor term of the fitted model"
                }
                exit 198
            }
        }

        * The _fg_<term> names THIS run will write.  The creation loop below
        * adjudicates them again as defence in depth, but that loop runs after
        * the characteristics have been blanked and after the prior run's entry
        * and design columns have been dropped, so its refusal used to leave the
        * dataset mutated.  A name the prior run recorded AND still owns is ours
        * to replace; anything else -- a user's own column under a name this
        * specification newly claims included -- is refused here, untouched.
        local _own_new : list uniq _fv_newnames
        local _own_new : list _own_new - _own_probe
        foreach _op of local _own_new {
            capture confirm variable `_op'
            if _rc continue
            local _own_c : char `_op'[_finegray_owner]
            local _own_m : list posof "`_op'" in _prev_fv_created
            if `_own_m' == 0 | `"`_own_c'"' == "" | ///
                `"`_own_c'"' != `"`_prev_owner'"' | `"`_prev_owner'"' == "" {
                display as error "variable `_op' exists and was not created by finegray; rename or drop it"
                display as error "finegray writes this name for a factor term of the fitted model"
                exit 198
            }
        }
    }

    * Deferred from the reduction step above: every check that can reject this
    * fit has now run, so writing the package-owned column here cannot strand a
    * prior fit's e() behind a dropped variable.
    if `_fg_entry_pending' {
        if `_fg_is_mi' {
            * mi data: a tempvar, dropped when this command returns.  The fit
            * itself is unaffected -- the engine consumes this column inside
            * `preserve' either way -- and nothing is written to the caller's
            * mi dataset.  Post-estimation is refused on this fit (e(postest)).
            tempvar _fg_entry_tv
            quietly gen double `_fg_entry_tv' = `_fg_mint0'
            local _fg_entryvar "`_fg_entry_tv'"
        }
        else {
            capture confirm variable _fg_entry
            if !_rc {
                * Ours to replace only if it still carries the PRIOR run's token.
                local _own_e : char _fg_entry[_finegray_owner]
                if `"`_own_e'"' == "" | `"`_own_e'"' != `"`_prev_owner'"' | ///
                    `"`_prev_owner'"' == "" {
                    display as error "variable _fg_entry exists and was not created by finegray; rename or drop it"
                    display as error "finegray uses this name to record subject entry times for multiple-record data"
                    exit 198
                }
                display as text "(note: replacing existing variable _fg_entry)"
                quietly drop _fg_entry
            }
            quietly gen double _fg_entry = `_fg_mint0'
            char _fg_entry[_finegray_owner] "`_fg_owner_tok'"
            label variable _fg_entry ///
                "finegray: earliest subject entry time (multi-record reduction)"
            local _fg_entryvar "_fg_entry"
        }
    }

    * =========================================================================
    * EXPAND FACTOR VARIABLES (fvrevar-based: supports i., ib#., ##, #, c.)
    * =========================================================================
    local _fv_created ""

    * Input validation above leaves a prior successful fit intact. Once this
    * new fit begins mutating package-owned columns, invalidate the old state
    * first so a failed re-fit cannot masquerade as the previous success.
    *
    * The mark is "0", not "": it has to be TELLABLE from a dataset that never
    * carried the characteristic at all.  Post-estimation now recognises a
    * finegray fit restored by `estimates use' over a dataset saved before the
    * fit -- which has no characteristic -- and both states used to spell
    * themselves the same way, so writing "" here would have let a re-fit that
    * failed mid-mutation fall through to the prior fit's e() and answer from
    * it.  "0" means INVALIDATED and is refused; absent means UNKNOWN and is
    * adjudicated against e().  Guarded by test_finegray_v110.do.
    *
    * On mi data NONE of this happens.  A mi-mode fit mutates nothing permanent
    * -- the entry column and every _fg_<term> design column are tempvars (see
    * the mi block near the top and the two branches below) -- so there is no
    * package-owned state for a failed re-fit to masquerade as, and the mark has
    * nothing to invalidate.  Writing it anyway put seven _dta[_finegray_*]
    * characteristics into the caller's mi dataset, which is exactly the
    * contract this version's mi branch exists to keep ("nothing is written to
    * the caller's mi dataset").  Worse, blanking _dta[_finegray_fvvars] while
    * the cleanup below dropped the columns it named left a PRIOR ordinary fit's
    * e() pointing at design columns that no longer existed and no
    * characteristic recording that finegray had ever owned them.  The whole
    * block, cleanup included, is therefore off-mi-data only: a prior fit's
    * state stays internally consistent and the mi fit adds nothing to it.
    * Post-estimation on the mi fit is refused on e(postest) before any
    * characteristic is consulted, so the stale marks cannot be mistaken for
    * this fit's.  Guarded by FGML-01..03 in qa/test_finegray_mi_lattice.do.
    if !`_fg_is_mi' {
        char _dta[_finegray_estimated] "0"
        char _dta[_finegray_compete] ""
        char _dta[_finegray_cause] ""
        char _dta[_finegray_covars] ""
        char _dta[_finegray_fvvars] ""
        char _dta[_finegray_fvvarlist] ""
        char _dta[_finegray_entryvar] ""
        char _dta[_finegray_owner] ""
    }

    * Clean up the entry-time variable from any prior finegray run when this
    * run did not just (re)create it in the reduction step above.
    if !`_fg_is_mi' & `"`_prev_estimated'"' == "1" & `"`_prev_entryvar'"' != "" ///
        & "`_prev_entryvar'" != "`_fg_entryvar'" {
        capture confirm variable `_prev_entryvar'
        if !_rc {
            * Name recorded is not name owned: the user may have dropped the
            * column and regenerated their own under the same name.
            local _own_p : char `_prev_entryvar'[_finegray_owner]
            if `"`_own_p'"' == "" | `"`_own_p'"' != `"`_prev_owner'"' | ///
                `"`_prev_owner'"' == "" {
                display as error "variable `_prev_entryvar' exists and was not created by finegray; rename or drop it"
                exit 198
            }
            quietly drop `_prev_entryvar'
        }
    }

    * Clean up FV variables from any prior finegray run, unconditionally.
    * This ensures stale _fg_* columns are dropped even when the new run
    * does not use factor variables.
    if !`_fg_is_mi' & `"`_prev_estimated'"' == "1" & `"`_prev_fv_created'"' != "" {
        local _drop_prev ""
        foreach _old_fg of local _prev_fv_created {
            capture confirm variable `_old_fg'
            if !_rc {
                local _own_f : char `_old_fg'[_finegray_owner]
                if `"`_own_f'"' == "" | `"`_own_f'"' != `"`_prev_owner'"' | ///
                    `"`_prev_owner'"' == "" {
                    display as error "variable `_old_fg' exists and was not created by finegray; rename or drop it"
                    exit 198
                }
                local _drop_prev "`_drop_prev' `_old_fg'"
            }
        }
        if "`_drop_prev'" != "" {
            display as text "(note: dropping prior finegray FV variables)"
            quietly drop `_drop_prev'
        }
    }

    if `_has_fv' {
        * Build final varlist and create the design columns.
        *
        * _fv_final holds the columns the engine will read.  The NAMES those
        * columns take in the caller's data were derived before any mutation
        * and reach this loop through `_fv_namemap' (one token per semantic
        * term, `.' for a skipped base level), so every refusal the derivation
        * can raise has already happened with the dataset untouched.  Off mi
        * data a design column takes its derived name; on mi data it is a
        * tempvar and claims no name in the caller's dataset, while the derived
        * names still adjudicated the specification above -- a fit that errors
        * on complete-case data must not succeed under `mi estimate'.
        local _fv_final ""

        forvalues _i = 1/`_n_sem' {
            local _term : word `_i' of `_fv_semantic'
            local _var : word `_i' of `_fv_actual'
            local _fg_name : word `_i' of `_fv_namemap'

            * Skip base categories (marked with Nb. in fvexpand output)
            if "`_fg_name'" == "." continue

            * If fvrevar returned original variable (not tempvar), use directly
            if substr("`_var'", 1, 2) != "__" {
                local _fv_final "`_fv_final' `_var'"
                continue
            }

            * mi data: the design column is a tempvar.  It claims no name in the
            * caller's dataset, so the existing-variable check has nothing to
            * adjudicate and the column does not outlive this command -- which
            * is the point: an unregistered _fg_<term> column in mi data is what
            * this branch exists to avoid.  Post-estimation is refused on this
            * fit (e(postest)), so nothing later reads the column back.
            if `_fg_is_mi' {
                tempvar _fg_col
                quietly generate double `_fg_col' = `_var'
                local _fv_final "`_fv_final' `_fg_col'"
                continue
            }

            * Check for existing _fg_ variable in dataset
            capture confirm variable `_fg_name'
            if !_rc {
                local _prev_match : list posof "`_fg_name'" in _prev_fv_created
                local _own_n : char `_fg_name'[_finegray_owner]
                * Recorded by a prior fit AND still carrying that fit's token.
                * The name alone is not ownership: a user who drops the column
                * and regenerates their own under the same name keeps it.
                if `_prev_match' > 0 & `"`_own_n'"' != "" & ///
                    `"`_own_n'"' == `"`_prev_owner'"' & `"`_prev_owner'"' != "" {
                    * Prior finegray-created variable — safe to replace
                    display as text "(note: replacing existing variable `_fg_name')"
                    quietly drop `_fg_name'
                }
                else {
                    display as error "variable `_fg_name' exists and was not created by finegray; rename or drop it"
                    display as error "finegray writes this name for the factor term `_term'"
                    exit 198
                }
            }

            * Create persistent copy
            quietly generate double `_fg_name' = `_var'
            char `_fg_name'[_finegray_owner] "`_fg_owner_tok'"
            local _fv_created "`_fv_created' `_fg_name'"

            * Label: build from value labels (factors) and variable labels (continuous)
            * Parse each part of the term to build a descriptive label
            local _lbl_full ""
            local _lbl_remaining "`_term'"
            while "`_lbl_remaining'" != "" {
                local _lbl_hashpos = strpos("`_lbl_remaining'", "#")
                if `_lbl_hashpos' > 0 {
                    local _lbl_part = substr("`_lbl_remaining'", 1, `_lbl_hashpos' - 1)
                    local _lbl_remaining = substr("`_lbl_remaining'", `_lbl_hashpos' + 1, .)
                }
                else {
                    local _lbl_part "`_lbl_remaining'"
                    local _lbl_remaining ""
                }

                if regexm("`_lbl_part'", "^([0-9]+)(bn)?\.(.+)$") {
                    * Factor part: use value label if available (Nbn. base-none
                    * levels label like ordinary levels; they have no reference)
                    local _lp_lev = regexs(1)
                    local _lp_var = regexs(3)
                    local _lp_vallbl : value label `_lp_var'
                    local _lp_txt ""
                    if "`_lp_vallbl'" != "" {
                        local _lp_txt : label `_lp_vallbl' `_lp_lev'
                    }
                    if `"`_lp_txt'"' == "" local _lp_txt "`_lp_lev'"
                    * Find reference category for (vs. ref) suffix
                    local _lp_ref ""
                    foreach _bterm of local _fv_semantic {
                        if regexm("`_bterm'", "^([0-9]+)b\.`_lp_var'$") {
                            local _lp_ref = regexs(1)
                        }
                    }
                    if "`_lp_ref'" != "" {
                        local _lp_reftxt ""
                        if "`_lp_vallbl'" != "" {
                            local _lp_reftxt : label `_lp_vallbl' `_lp_ref'
                        }
                        if `"`_lp_reftxt'"' == "" local _lp_reftxt "`_lp_ref'"
                        local _lp_txt `"`_lp_txt' (vs. `_lp_reftxt')"'
                    }
                    if `"`_lbl_full'"' != "" local _lbl_full `"`_lbl_full' # "'
                    local _lbl_full `"`_lbl_full'`_lp_txt'"'
                }
                else if regexm("`_lbl_part'", "^c\.(.+)$") {
                    * Continuous part: use variable label if available
                    local _lp_var = regexs(1)
                    local _lp_txt : variable label `_lp_var'
                    if `"`_lp_txt'"' == "" local _lp_txt "`_lp_var'"
                    if `"`_lbl_full'"' != "" local _lbl_full `"`_lbl_full' # "'
                    local _lbl_full `"`_lbl_full'`_lp_txt'"'
                }
                else {
                    if `"`_lbl_full'"' != "" local _lbl_full `"`_lbl_full' # "'
                    local _lbl_full `"`_lbl_full'`_lbl_part'"'
                }
            }
            label variable `_fg_name' `"`_lbl_full'"'

            local _fv_final "`_fv_final' `_fg_name'"
        }

        local varlist : list retokenize _fv_final

        * The `Reference:' lines used to be built here, from locals the display
        * block then read.  They are now derived from e(fvsemantic) inside
        * _finegray_display, so that a replay prints the same lines as the fit.
    }

    * The unpenalized Fine-Gray likelihood cannot identify constant or exactly
    * collinear columns.  Do not silently substitute arbitrary ridge estimates:
    * reject the specification with the offending expanded columns named.
    quietly _rmcoll `varlist' if `touse', forcedrop
    if r(k_omitted) > 0 {
        local _fg_identified `r(varlist)'
        local _fg_omitted : list varlist - _fg_identified

        * Name the offending terms the way the USER wrote them.  `varlist' is
        * the design columns here, and the non-base fit-time terms pair 1:1 and
        * in order with them (the same pairing e(designvars)/e(fvsemantic) is
        * built on), so an omitted column maps back by position.  Reporting
        * `_fg_grp_2' left the reader to work out which level that was, for a
        * name they never typed.
        local _rk_report "`_fg_omitted'"
        if `_has_fv' {
            local _rk_nb ""
            foreach _rk_t of local _fv_semantic {
                if regexm("`_rk_t'", "[0-9]+b\.") continue
                local _rk_nb "`_rk_nb' `_rk_t'"
            }
            local _rk_nnb : word count `_rk_nb'
            local _rk_nvl : word count `varlist'
            if `_rk_nnb' == `_rk_nvl' {
                local _rk_report ""
                foreach _rk_c of local _fg_omitted {
                    local _rk_p : list posof "`_rk_c'" in varlist
                    if `_rk_p' > 0 {
                        local _rk_report "`_rk_report' `: word `_rk_p' of `_rk_nb''"
                    }
                    else local _rk_report "`_rk_report' `_rk_c'"
                }
                local _rk_report : list retokenize _rk_report
            }
        }

        * A bare `ibn.' main effect is the one rank failure that is a property
        * of the MODEL rather than of the data, so it earns its own note: the
        * Fine-Gray partial likelihood has no intercept, adding a constant to
        * every level's coefficient leaves the likelihood unchanged, and the
        * level indicators sum to 1.  Without this the user reads "constant or
        * collinear" about a variable that is neither, and reaches for a data
        * fix that cannot work.  Detected on a bare `Nbn.var' term -- inside an
        * interaction (`c.x#ibn.grp') the columns do not sum to a constant and
        * ibn. is perfectly estimable, so the note must not fire there.
        local _rk_bn = 0
        local _rk_bnvar ""
        if `_has_fv' {
            foreach _rk_t of local _fv_semantic {
                if strpos("`_rk_t'", "#") continue
                if regexm("`_rk_t'", "^[0-9]+bn\.(.+)$") {
                    local _rk_bn = 1
                    local _rk_bnvar = regexs(1)
                }
            }
        }

        if "`_fv_created'" != "" quietly drop `_fv_created'
        display as error "finegray covariates are not full rank"
        display as error "constant or collinear term(s): `_rk_report'"
        if `_rk_bn' {
            display as error "an ibn. main effect names every level, and the Fine-Gray partial"
            display as error "likelihood has no intercept to absorb the redundancy: the level"
            display as error "indicators sum to 1, so one of them is not identified"
            display as error "use i.`_rk_bnvar' or ib#.`_rk_bnvar' for a main effect; ibn. is estimable"
            display as error "inside an interaction, as in c.x#ibn.`_rk_bnvar'"
        }
        else {
            display as error "remove or recode these terms and fit the model again"
        }
        exit 459
    }

    * =========================================================================
    * MAP tvc() ONTO THE FITTED DESIGN COLUMNS
    * =========================================================================
    * tvc() names VARIABLES; the engine works in design columns.  Off factor
    * variables the two coincide.  With factor variables one variable can supply
    * several columns (i.grp -> two indicators; c.x#i.grp -> one column per
    * level), and the rule is stated rather than guessed at: every coefficient
    * whose TERM involves a tvc() variable becomes interval-specific.  So
    * tvc(grp) frees all of i.grp's level effects together, and tvc(x) in a model
    * containing x and c.x#i.grp frees the interaction columns too.
    *
    * What travels to the engine is POSITIONS, not names.  The design columns are
    * package-owned _fg_* variables that post-estimation is allowed to drop and
    * rebuild as tempvars (see finegray_predict), and a position survives that
    * where a name does not.
    local _fg_tvcpos ""
    local _fg_tvccols ""
    if "`tvc'" != "" {
        local _fg_ncols : word count `varlist'

        * One "source variables" list per design column, in column order.
        forvalues _tv_c = 1/`_fg_ncols' {
            local _tv_src`_tv_c' ""
        }
        if `_has_fv' {
            local _tv_c = 0
            foreach _tv_term of local _fv_semantic {
                if regexm("`_tv_term'", "[0-9]+b\.") continue
                local ++_tv_c
                local _tv_parts = subinstr(subinstr("`_tv_term'", "##", "#", .), "#", " ", .)
                foreach _tv_p of local _tv_parts {
                    if regexm("`_tv_p'", "\.(.+)$") local _tv_p = regexs(1)
                    local _tv_seen : list posof "`_tv_p'" in _tv_src`_tv_c'
                    if `_tv_seen' == 0 local _tv_src`_tv_c' "`_tv_src`_tv_c'' `_tv_p'"
                }
            }
            if `_tv_c' != `_fg_ncols' {
                display as error "internal error: factor expansion and design columns disagree"
                display as error "(`_tv_c' non-base terms, `_fg_ncols' design columns)"
                exit 198
            }
        }
        else {
            forvalues _tv_c = 1/`_fg_ncols' {
                local _tv_src`_tv_c' "`: word `_tv_c' of `varlist''"
            }
        }

        * Match, in ASCENDING design-column order: that is the order the engine
        * assigns the piecewise blocks in, and the coefficient stripe built below
        * has to agree with it column for column.
        forvalues _tv_c = 1/`_fg_ncols' {
            local _tv_hit = 0
            foreach _tv_v of local tvc {
                local _tv_in : list posof "`_tv_v'" in _tv_src`_tv_c'
                if `_tv_in' > 0 {
                    local _tv_hit = 1
                    continue, break
                }
            }
            if `_tv_hit' {
                local _fg_tvcpos "`_fg_tvcpos' `_tv_c'"
                local _fg_tvccols "`_fg_tvccols' `: word `_tv_c' of `varlist''"
            }
        }
        local _fg_tvcpos : list retokenize _fg_tvcpos
        local _fg_tvccols : list retokenize _fg_tvccols

        * A tvc() variable that names no coefficient is a specification error,
        * not a no-op: the user asked for a time-varying effect and would have
        * been handed a fit without one.
        foreach _tv_v of local tvc {
            local _tv_any = 0
            forvalues _tv_c = 1/`_fg_ncols' {
                local _tv_in : list posof "`_tv_v'" in _tv_src`_tv_c'
                if `_tv_in' > 0 {
                    local _tv_any = 1
                    continue, break
                }
            }
            if !`_tv_any' {
                display as error "tvc(`_tv_v') is not in the model"
                display as error "tvc() names covariates the model already fits; add `_tv_v' to"
                display as error "the varlist, or remove it from tvc()"
                exit 198
            }
        }

        local _fg_ntv : word count `_fg_tvcpos'

        * ---- every interval must carry a cause event ------------------------
        * Interval j is (cut[j-1], cut[j]], so a boundary at or beyond the last
        * cause-event time leaves the final interval with no events at all and
        * its coefficients unidentified.  The information matrix would catch it,
        * but as "not full rank" naming a design column -- which sends the reader
        * looking for collinearity.  Name the interval instead.
        local _fg_lo = 0
        local _fg_tvnfail ""
        forvalues _tv_j = 1/`_fg_nint' {
            if `_tv_j' == `_fg_nint' {
                local _tv_cond "_t > `_fg_lo'"
                local _tv_lbl "_t > `_fg_lo'"
            }
            else {
                local _tv_hi : word `_tv_j' of `tsplit'
                local _tv_cond "_t > `_fg_lo' & _t <= `_tv_hi'"
                if `_tv_j' == 1 local _tv_lbl "_t <= `_tv_hi'"
                else            local _tv_lbl "`_fg_lo' < _t <= `_tv_hi'"
            }
            quietly count if `touse' & `compete' == `cause' & `_tv_cond'
            * Kept, not just tested.  An interval is identified as soon as it
            * carries one cause event, but a coefficient estimated from two or
            * three of them is a monotone-likelihood accident waiting to happen
            * -- and the fit converges and prints a finite (enormous) subhazard
            * ratio when it does.  The count belongs next to the interval in the
            * output, where the reader can see what each estimate rests on.
            local _fg_tvnfail "`_fg_tvnfail' `r(N)'"
            if r(N) == 0 {
                display as error "tsplit() interval `_tv_j' (`_tv_lbl') contains no cause `cause' event"
                display as error "its coefficients are not identified by the subdistribution"
                display as error "likelihood, so the interval cannot be estimated"
                display as error "move or drop that boundary; the last cause event is the upper"
                display as error "limit of any usable tsplit() value"
                exit 459
            }
            if `_tv_j' < `_fg_nint' local _fg_lo : word `_tv_j' of `tsplit'
        }
        local _fg_tvnfail : list retokenize _fg_tvnfail
    }

    * =========================================================================
    * LOAD MATA ENGINE
    * =========================================================================
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

    * The weight digest.  The TOTAL is not the weights: a weight expression built
    * on an unsignable input can be changed so that e(sum_w) is invariant while
    * every per-observation weight moves -- [pw = cond(odd == 0, k, 4 - k)] is
    * exactly compensated in k -- and post-estimation then rebuilt a DIFFERENT
    * column at rc 0.  This digest is value-sensitive and order-invariant, and
    * _finegray_weight_var recomputes it on the rebuilt column and refuses a
    * mismatch.  It sits HERE, after the engine load, because it is a Mata call:
    * beside the e(sum_w) computation it would run before the engine exists.
    * Keyed by the stset id() variable: without it the digest is invariant to
    * EXCHANGING two subjects' weights, which leaves e(sum_w) and the multiset
    * of weight values untouched and rebuilt a different column at rc 0.
    if "`weight'" != "" {
        mata: _finegray_wsig("`_fg_w'", "`touse'", "`_fg_idvar'")
    }

    * =========================================================================
    * FIT MODEL (Mata forward-backward scan engine)
    * =========================================================================
    local vce_type "robust"
    if "`cluster'" != "" local vce_type "cluster"
    else if "`robust'" == "norobust" local vce_type "model"

    preserve
    local _rc_fit = 0

    capture noisily {
        quietly keep if `touse'

        * Use each subject's earliest entry time after multi-record reduction
        * (engine left-truncation consumes _t0). Non-destructive: inside preserve.
        if `_fg_reduced' quietly replace _t0 = `_fg_entryvar'

        * Combine multiple strata variables into a single group variable
        local _byg_mata "`strata'"
        if "`strata'" != "" {
            local _byg_nvar : word count `strata'
            if `_byg_nvar' > 1 {
                tempvar _byg_grp
                _finegray_weight_groups, strata(`strata') bygname(`_byg_grp')
                local _byg_mata "`_byg_grp'"
            }
        }

        * Truncation strata: the entry distribution H is estimated within these
        * groups. Empty means one pooled H group; H == 1 only when there is no
        * delayed entry, so the no-delayed-entry path remains bit-identical.
        local _tg_mata ""
        if "`truncstrata'" != "" {
            tempvar _tg_grp
            _finegray_weight_groups, truncstrata(`truncstrata') ///
                tgname(`_tg_grp') touse(`touse')
            local _tg_mata "`_tg_grp'"
        }

        * ---- Support boundary for the combined-weight design.
        *
        * The factorized weights are EVALUATED for each observed joint (censoring x
        * truncation) stratum: G is estimated within censoring strata and H within
        * truncation strata.  Every observed combination must still carry enough
        * support to make its configured weight usable.  Both limits are hard
        * failures: silently pooling groups the user asked to keep separate would
        * change the estimand without saying so, which is the failure class this
        * package treats as worst.
        *
        * Enforced only on the ZZF (delayed-entry) branch.  A right-censoring fit
        * with many strata() levels is unchanged released behaviour, and turning
        * that into an error would break existing analyses -- the no-LT path is
        * required to stay bit-identical, and an error is not bit-identical.
        *
        * BREAKING CHANGE, stated so nobody rediscovers it as a bug: a delayed-entry
        * fit with more than 100 strata() levels used to run and now hard-errors,
        * EVEN WITHOUT truncstrata().  Under delayed entry the weights are A = G*H,
        * and A is evaluated for every observed joint group, so 150 censoring strata
        * are 150 weight strata whether or not the user asked for entry strata.
        * Guarded by Z21/Z22.
        if `_fg_has_lt' {
            tempvar _fg_jgrp _fg_jn
            if "`_byg_mata'" == "" & "`_tg_mata'" == "" {
                quietly gen byte `_fg_jgrp' = 1
            }
            else {
                quietly egen long `_fg_jgrp' = group(`_byg_mata' `_tg_mata')
            }
            quietly summarize `_fg_jgrp', meanonly
            local _fg_njgrp = r(max)

            * Name only the options that actually formed the groups.  Blaming a
            * cross-classification with truncstrata() when the user never typed
            * truncstrata() sends them looking for an option they did not use.
            *
            * Keep each line short.  Stata wraps display output at linesize, and
            * test Z22 greps this text -- a message that wraps mid-token would make
            * the guard's own regression test unfalsifiable.
            if `_fg_njgrp' > 100 {
                display as error "too many weight strata: `_fg_njgrp' observed joint groups (limit 100)"
                if "`_byg_mata'" != "" & "`_tg_mata'" != "" {
                    display as error "strata() and truncstrata() are cross-classified:"
                    display as error "the weight strata are their observed combinations"
                }
                else if "`_tg_mata'" != "" {
                    display as error "the weight strata are the observed levels of truncstrata()"
                }
                else {
                    display as error "the weight strata are the observed levels of strata()"
                    display as error "under delayed entry G is stratum-specific, H is pooled,"
                    display as error "and A is evaluated separately for every strata() level"
                }
                display as error "this limit applies to delayed-entry fits only"
                display as error "use coarser grouping variables"
                exit 459
            }

            quietly bysort `_fg_jgrp': gen long `_fg_jn' = _N
            quietly summarize `_fg_jn', meanonly
            local _fg_minjn = r(min)

            if `_fg_minjn' < 20 {
                display as error "a weight stratum has only `_fg_minjn' subjects (minimum 20)"
                display as error "the factorized weight is evaluated within each observed joint"
                display as error "stratum; too few subjects makes that configured weight unusable"
                display as error "use coarser grouping variables"
                exit 459
            }
        }

        sort _t `_fg_row0'

        if "`log'" != "nolog" {
            display as text "Fitting Fine-Gray model..."
        }

        * Baseline strata travel to the engine as the RAW variable.  The scans
        * map its values to 1..K themselves (uniqrows), so the fit and every
        * post-estimation rebuild agree about which stratum is which even when
        * the later call sees only some of the fit's rows.
        mata: _finegray_engine( ///
            "`varlist'", "`compete'", `cause', `censvalue', ///
            "`_byg_mata'", "`_tg_mata'", "`vce_type'", "`cluster'", ///
            `iterate', `tolerance', ("`log'" != "nolog"), ///
            ("`adjust'" != "noadjust"), ("`basehaz'" != ""), ///
            ("`nuisance'" != ""), "`bstrata'", ///
            "`_fg_tvcpos'", "`tsplit'", "`_fg_w'", `_fg_wtype')
    }

    local _rc_fit = _rc
    restore

    if `_rc_fit' {
        exit `_rc_fit'
    }

    * Baseline strata that contributed no cause event.  `_fg_bs_noevent' is set
    * in this scope by _finegray_engine via st_local; it is "" (or unset) when
    * every stratum has at least one.  These strata are not a fit error -- their
    * likelihood terms are empty -- but they have no baseline curve, so a later
    * CIF or basecshazard request for one of them fails closed at r(459).
    if "`_fg_bs_noevent'" != "" {
        display as text "(note: bstrata() level(s) `_fg_bs_noevent' contain no cause `cause' event;"
        display as text " they contribute no likelihood terms and have no baseline to predict from)"
    }

    * =========================================================================
    * RETRIEVE AND POST E() RESULTS
    * =========================================================================

    tempname b V
    matrix `b' = _finegray_b
    matrix `V' = _finegray_V

    * Column names.  For a factor-variable fit these are the terms the USER
    * typed (`1.pelnode', `1.pelnode#c.ifp'), taken from the fit-time expansion,
    * NOT the package-owned design-column names.  The internal names stay in
    * e(designvars), which is what the post-estimation rebuild machinery reads
    * and what finegray_predict re-stripes onto its own scoring copy of e(b);
    * the coefficient stripe is what the READER sees -- and with it `test',
    * `testparm', `estimates table' and every estout-style exporter.
    *
    * Before this, an interaction row printed as `_fg_pelnod~p' (the 12-char
    * abbreviation of _fg_pelnode_1Xifp) and was undecodable from the printed
    * output alone, `estimates table' exported the same names, and
    * `test 1.pelnode' failed r(111) -- the user had to discover and type
    * `test _fg_pelnode_1'.
    *
    * The count guard is not optional: `matrix colnames' given FEWER names than
    * columns silently repeats the last one across the remainder, which would
    * mislabel every coefficient at rc 0.  The capture guards a term the matrix
    * stripe parser will not take; a fit must never be lost over its labels.
    * One base name per DESIGN COLUMN.  Under tvc() the coefficient vector is
    * wider than the design (one coefficient per interval for each time-varying
    * column), so the stripe is built from these in a second step below rather
    * than being the stripe itself.
    local _fg_ncol : word count `varlist'
    local _fg_bnames "`varlist'"
    if `_has_fv' {
        local _cn_fv ""
        foreach _cn_t of local _fv_semantic {
            if regexm("`_cn_t'", "[0-9]+b\.") continue
            local _cn_fv "`_cn_fv' `_cn_t'"
        }
        local _cn_n : word count `_cn_fv'
        if `_cn_n' == `_fg_ncol' {
            local _cn_try : list retokenize _cn_fv
            capture matrix colnames `b' = `_cn_try'
            if _rc == 0 local _fg_bnames "`_cn_try'"
        }
    }

    * Piecewise beta(t) stripe.  The fixed-effect columns come first, in design
    * order, under equation `main'; then one equation per interval carrying the
    * time-varying columns.  Equation names are plain `tvcN' on purpose: the
    * interval bounds read better (`5 < _t <= 10') but `<' and `=' break
    * [eqname] parsing, so `test [tvc1]x = [tvc2]x' -- the Wald test of "is this
    * effect constant?", which is most of the reason to fit the model -- would
    * fail r(132).  _finegray_display prints the bounds under the table.
    local cnames ""
    local ceqs ""
    if "`tvc'" == "" {
        local cnames "`_fg_bnames'"
    }
    else {
        forvalues _cn_c = 1/`_fg_ncol' {
            local _cn_hit : list posof "`_cn_c'" in _fg_tvcpos
            if `_cn_hit' == 0 {
                local cnames "`cnames' `: word `_cn_c' of `_fg_bnames''"
                local ceqs "`ceqs' main"
            }
        }
        forvalues _cn_j = 1/`_fg_nint' {
            foreach _cn_c of local _fg_tvcpos {
                local cnames "`cnames' `: word `_cn_c' of `_fg_bnames''"
                local ceqs "`ceqs' tvc`_cn_j'"
            }
        }
        local cnames : list retokenize cnames
        local ceqs : list retokenize ceqs
    }

    * `matrix colnames' given FEWER names than columns silently repeats the LAST
    * one across the remainder, which mislabels every coefficient after the first
    * shortfall at rc 0.  Never let that happen by construction alone.
    local _cn_have : word count `cnames'
    if `_cn_have' != colsof(`b') {
        display as error "internal error: `_cn_have' coefficient name(s) for " ///
            "`=colsof(`b')' coefficients"
        exit 498
    }

    matrix colnames `b' = `cnames'
    matrix colnames `V' = `cnames'
    matrix rownames `V' = `cnames'
    if "`ceqs'" != "" {
        matrix coleq `b' = `ceqs'
        matrix coleq `V' = `ceqs'
        matrix roweq `V' = `ceqs'
    }

    * Base-level columns.  Official estimators post a factor's base level as a
    * `0b.pelnode' column holding a zero coefficient and a zero row/column of
    * e(V); `margins', `contrast' and `pwcompare' enumerate a factor's levels
    * from that stripe, so without it `margins, at(pelnode=(0 1))' stops with
    * "at level for factor pelnode not present during estimation".  Widen the
    * posted stripe to the full fit-time expansion in e(fvsemantic), base terms
    * included, in the order fvexpand produced them.
    *
    * The ESTIMATE stays in the design frame.  Everything inside this package
    * that pairs a coefficient with a design column -- the CIF, the linear
    * predictor, the Schoenfeld residuals, the bootstrap refits, the baseline
    * rebuild -- reads the non-base vector through _finegray_bnb (Stata) or
    * _finegray_beta() (Mata), which drop the `Nb.' columns again by stripe.
    * They read the LIVE e(b) rather than a stored narrow copy because margins
    * computes its delta-method Jacobian by reposting a perturbed e(b) and
    * calling predict; a private copy would leave that derivative at zero.
    *
    * Not under tvc(): the tvc stripe is one equation per interval, margins is
    * withdrawn there (no single linear predictor), and a base column has no
    * natural equation in that layout.  Not when the fitted-term naming above
    * fell back to design-column names: the base terms would then be the only
    * factor-operator names in the stripe and margins would misread the rest.
    local _fg_wide = 0
    if `_has_fv' & "`tvc'" == "" & "`_fg_bnames'" != "`varlist'" {
        local _wn_names : list retokenize _fv_semantic
        local _wn_k : word count `_wn_names'
        tempname _wS
        matrix `_wS' = J(`_wn_k', `_fg_ncol', 0)
        local _wn_j = 0
        forvalues _wn_i = 1/`_wn_k' {
            local _wn_t : word `_wn_i' of `_wn_names'
            if regexm("`_wn_t'", "[0-9]+b\.") continue
            local ++_wn_j
            if `_wn_j' <= `_fg_ncol' matrix `_wS'[`_wn_i', `_wn_j'] = 1
        }
        if `_wn_j' == `_fg_ncol' & `_wn_k' > `_fg_ncol' {
            tempname _wb _wV
            matrix `_wb' = `b' * `_wS''
            matrix `_wV' = `_wS' * `V' * `_wS''
            capture matrix colnames `_wb' = `_wn_names'
            if _rc == 0 {
                matrix colnames `_wV' = `_wn_names'
                matrix rownames `_wV' = `_wn_names'
                matrix `b' = `_wb'
                matrix `V' = `_wV'
                local _fg_wide = 1
            }
        }
    }

    local _fg_ll       = _finegray_ll[1,1]
    local _fg_ll_0     = _finegray_ll_0[1,1]
    local _fg_chi2     = _finegray_chi2[1,1]
    local _fg_df_m     = _finegray_df_m[1,1]
    local _fg_conv     = _finegray_conv[1,1]
    local _fg_rank     = _finegray_rank[1,1]
    local _fg_nclust   = .
    capture local _fg_nclust = _finegray_nclust[1,1]
    local _fg_nclust_rc = _rc
    if "`cluster'" != "" & `_fg_nclust_rc' {
        display as error "internal cluster-count result is unavailable"
        exit 498
    }

    * `_fg_warnstrata' is set directly in this scope by _finegray_weight_diag via
    * st_local (a string cannot ride back in a matrix). _finegray_weight_diag runs
    * on every fit (including the ordinary no-delayed-entry branch, where it scores
    * the A=G weights); the local is "" whenever nothing tripped a threshold.

    * Compute p-value from chi2
    if `_fg_chi2' != . & `_fg_df_m' > 0 {
        local _fg_p = chi2tail(`_fg_df_m', `_fg_chi2')
    }
    else {
        local _fg_p = .
    }

    * The values pooled as COMPETING, for the header.  "Competing events: status"
    * names the variable; a miscoded event code (a stray 9 alongside 2 and 3) is
    * then invisible in the output and the reader cannot verify what was pooled.
    * Computed here, after `restore', so the levelsof sort cannot perturb the row
    * order the engine consumed, and stored in e() so replay reports the same
    * list without re-reading data that may since have changed.
    local _fg_cvals ""
    if `N_compete' > 0 {
        quietly levelsof `compete' if `touse' & `compete' != `censvalue' ///
            & `compete' != `cause', local(_fg_cvals) clean
    }

    * Post results.  depname("_t") matches stcrreg: the modelled outcome is
    * time-to-cause on the stset clock, not the event-type variable, and a
    * `status |' stub said otherwise.  The event-type variable is e(compete).
    * buildfvinfo: with it, ereturn display treats a base-level column as a
    * base (hidden by default, "(base)" under showbaselevels) as every
    * official estimator does; without it the same zero coefficient with zero
    * variance prints as "(empty)", which reads as a level with no
    * observations.  addcons, and the hidden marginsprop below, are what
    * stcox posts for the same no-intercept situation: margins' estimability
    * check builds its H matrix from this fv info, and without an implicit
    * constant it declares every factor-level margin "not estimable" (the
    * base indicator is 1 - 1.pelnode only when a constant exists).
    * The weight specification rides on the post: `ereturn post' sets
    * e(wtype) and e(wexp) from it, which is the contract every consumer
    * (post-estimation here, `estimates table', user code) reads.
    ereturn post `b' `V' [`weight'`exp'], obs(`_fg_Nrep') esample(`touse') ///
        depname("_t") properties(b V)
    * ADDCONS is accepted by repost only, and only spelled so (stcox.ado does
    * exactly this).
    ereturn repost, buildfvinfo ADDCONS
    ereturn hidden local marginsprop "addcons allcons"

    ereturn scalar N = `_fg_Nrep'
    if "`weight'" != "" {
        ereturn scalar sum_w = `_fg_sumw'
        ereturn scalar wsig_n = `_fg_wsig_n'
        ereturn local wsig "`_fg_wsig'"
    }
    ereturn scalar N_fail = `N_fail'
    ereturn scalar N_compete = `N_compete'
    ereturn scalar N_cens = `N_cens'
    ereturn scalar ll = `_fg_ll'
    ereturn scalar ll_0 = `_fg_ll_0'
    ereturn scalar chi2 = `_fg_chi2'
    ereturn scalar p = `_fg_p'
    ereturn scalar df_m = `_fg_df_m'
    ereturn scalar rank = `_fg_rank'
    if "`cluster'" != "" ereturn scalar N_clust = `_fg_nclust'
    ereturn scalar converged = `_fg_conv'
    * Subjects whose earliest entry time is positive.  Reported in the header:
    * a delayed-entry fit and an ordinary one were display-indistinguishable,
    * and the ZZF weight construction is a materially different estimator.
    ereturn scalar N_delayed = `_fg_n_lt'
    * Baseline strata actually fitted.  1 on an unstratified fit, so a consumer
    * never has to test e(bstrata) for emptiness to know the baseline's shape:
    * e(k_bstrata) > 1 means e(basehaz) is K x 3 and every baseline lookup needs
    * a stratum.
    ereturn scalar k_bstrata = _finegray_kbstrata[1,1]
    * Piecewise beta(t) shape.  A consumer must be able to tell from e() alone
    * that e(b) is wider than e(designvars) and why: n_intervals is 1 on an
    * ordinary fit, so `e(n_intervals) > 1' is the single test for "this fit has
    * interval-specific coefficients".
    ereturn scalar n_intervals = `_fg_nint'
    ereturn scalar k_tvc = `_fg_ntv'
    ereturn scalar level = `level'
    ereturn scalar cause = `cause'
    ereturn scalar censvalue = `censvalue'
    ereturn scalar iterate = `iterate'
    ereturn scalar tolerance = `tolerance'

    ereturn local cmd "finegray"
    ereturn local cmdline `"`_cmdline'"'

    * Refit command line for the bootstrap paths in finegray_cif /
    * finegray_predict.  e(cmdline) is the user's command AS TYPED and must stay
    * that way, but a refit runs on data already restricted to e(sample) and
    * then resampled, so replaying an `if'/`in' qualifier there is at best
    * redundant and, for `in' (or any _n-dependent `if'), plainly wrong: after
    * `finegray x in 101/200' the resampled dataset has 100 rows, `in 101/200'
    * selects nothing, and every replication fails with rc 498.  Rebuild the
    * line from the parsed options with no sample qualifier.
    * Every option that changes e(b) MUST be replayed here.  e(refitcmd) is what
    * finegray_cif's bootstrap re-issues on each resample, and a dropped fit option
    * does not error there: the refit converges, its covariates still match, so the
    * replication is ACCEPTED and the bootstrap silently describes a DIFFERENT
    * estimator than the point estimate it is wrapped around.
    *
    * truncstrata() was missing here, which meant a bootstrapped ZZF fit resampled
    * the POOLED-weight estimator.  Guarded by Z24, which does not check for the
    * option by name -- it asserts that running e(refitcmd) reproduces e(b), so any
    * future fit option dropped from this list fails the test on its own.
    *
    * noshr and level() are deliberately absent: both are display-only and cannot
    * move e(b).  nuisance is absent for the same reason one level up: it changes
    * only the sandwich meat in e(V), never e(b), and the bootstrap consumers of
    * e(refitcmd) read only each replicate's e(b) -- replaying it would pay the
    * psi-term cost once per replication for a variance nobody reads.
    * The weight travels too: a resample keeps each subject's weight column,
    * and a bootstrap refit that dropped it would describe the UNWEIGHTED
    * estimator around a weighted point estimate.  The weight clause is built
    * as its own fragment rather than the command line twice: two copies of a
    * string this long drift the moment an option is added to one of them, and
    * the unweighted branch is the one a reader would forget.  Empty for an
    * unweighted fit, so the line below reduces to what it always was.
    local _fg_wspec ""
    if "`weight'" != "" local _fg_wspec `" [`weight'`exp']"'
    local _refitcmd `"finegray `_orig_varlist'`_fg_wspec', compete(`compete') cause(`cause') censvalue(`censvalue') iterate(`iterate') tolerance(`tolerance') nolog"'
    if "`strata'" != ""          local _refitcmd `"`_refitcmd' strata(`strata')"'
    if "`truncstrata'" != ""     local _refitcmd `"`_refitcmd' truncstrata(`truncstrata')"'
    if "`bstrata'" != ""         local _refitcmd `"`_refitcmd' bstrata(`bstrata')"'
    if "`tvc'" != ""             local _refitcmd `"`_refitcmd' tvc(`tvc') tsplit(`tsplit')"'
    if "`cluster'" != ""         local _refitcmd `"`_refitcmd' cluster(`cluster')"'
    if "`robust'" == "norobust"  local _refitcmd `"`_refitcmd' norobust"'
    if "`adjust'" == "noadjust"  local _refitcmd `"`_refitcmd' noadjust"'
    ereturn local refitcmd `"`_refitcmd'"'

    ereturn local predict "finegray_predict"

    * Multiple-imputation contract.  A consumer must never have to infer from
    * the data in memory whether this fit left post-estimation support behind.
    *   e(mi_data)  "1" when the fit ran on mi data (typed directly on an mi
    *               dataset, or executed by `mi estimate, cmdok:' / `mi xeq');
    *               absent otherwise
    *   e(postest)  "unavailable_mi" on such a fit; absent otherwise.  This is
    *               the flag finegray_predict, finegray_cif, finegray_phtest and
    *               _finegray_check_data refuse on.
    * The coefficients and variance are ordinary M-estimator output and pool
    * under Rubin's rules exactly as they do off mi data; it is only the
    * row-level post-estimation, which needs the fit's design columns and its
    * single baseline hazard, that has nothing to run on.
    if `_fg_is_mi' {
        ereturn local mi_data "1"
        ereturn local postest "unavailable_mi"
    }

    ereturn local compete "`compete'"
    * The values `compete' takes in the estimation sample that are neither the
    * cause of interest nor the censoring value -- i.e. what was pooled as a
    * competing event.  Empty when there are none.
    ereturn local compete_values "`_fg_cvals'"
    * The package-owned design columns, in coefficient order.  NOT e(covariates):
    * margins reads that name as the fit's covariate list when it is present
    * and resolves factor terms against it instead of against the e(b) stripe,
    * which is why `margins pelnode' used to stop with r(322) "factor pelnode
    * not found in list of covariates" (the list held _fg_pelnode_1).
    ereturn local designvars "`varlist'"
    * The package-owned entry-time column of a multiple-record fit, empty for a
    * single-record fit.  It is also written to _dta[_finegray_entryvar], but a
    * dataset characteristic travels with the DATA and e() travels with the
    * ESTIMATES: after `estimates use' over a dataset saved BEFORE the fit, only
    * e() is left. Post-estimation uses this fit's metadata exclusively;
    * empty means _t0, even if a later fit left a different data characteristic.
    * A path rebuilding risk sets must resolve the recorded column exactly.
    ereturn local entryvar "`_fg_entryvar'"
    * The stset id() variable, posted so post-estimation can key the weight
    * digest the same way this fit did.  The characteristic _dta[st_id] travels
    * with the DATA; e() travels with the estimates, and `estimates use' over
    * another dataset is a documented workflow.  Empty when stset carried no
    * id(): the row key used in that case is a tempvar of this run.
    ereturn local idvar "`_fg_idvar'"
    if `_has_fv' ereturn local fvvarlist "`_orig_varlist'"
    * The fit-time factor expansion, INCLUDING base terms (1b.grp).  This is the
    * semantic record of which level each coefficient belongs to.  Post-estimation
    * must align factor terms against this by LEVEL VALUE; re-expanding the
    * current data and matching positionally silently applies the fitted
    * coefficients to whatever levels happen to be present now.
    if `_has_fv' ereturn local fvsemantic "`_fv_semantic'"
    if "`strata'" != "" ereturn local strata "`strata'"
    if "`truncstrata'" != "" ereturn local truncstrata "`truncstrata'"
    * The BASELINE stratification variable.  A different axis from strata()
    * (censoring KM) and truncstrata() (entry distribution); see the option
    * table in help finegray.
    if "`bstrata'" != "" ereturn local bstrata "`bstrata'"
    * bstrata() levels that carried no cause event.  Their Breslow baseline is
    * identically zero -- a degenerate curve, not an estimate -- so every
    * baseline consumer refuses them by name.  Posted rather than recomputed
    * because `predict, cif' on NEW data is a documented workflow: the
    * estimation sample may be gone by the time the question is asked.
    if "`_fg_bs_noevent'" != "" ereturn local bstrata_noevent "`_fg_bs_noevent'"
    * The same levels in %21x, which round-trips exactly through Stata's
    * numeric parser.  e(bstrata_noevent) is the readable form and rounds a
    * noninteger stratum value, so a consumer that string-compares it against
    * a level obtained any other way misses at rc 0; every internal consumer
    * compares this one.
    if "`_fg_bs_noeventx'" != "" ereturn local bstrata_noevent_x "`_fg_bs_noeventx'"
    * Piecewise beta(t).
    *   e(tvc)            the variables the user named
    *   e(tsplit)         the interior boundaries, ascending
    *   e(tvc_covariates) the DESIGN COLUMNS those variables resolved to
    *   e(tvc_pos)        those columns' positions in e(designvars)
    * Post-estimation reads e(tvc_pos), not e(tvc_covariates): the design
    * columns are package-owned _fg_* variables that a supported `drop _fg_*'
    * removes and every rebuild path recreates as tempvars, so a NAME does not
    * survive the round trip and a position does.  The names are posted anyway
    * because they are what a reader needs to check the mapping tvc(x) made.
    if "`tvc'" != "" {
        ereturn local tvc "`tvc'"
        ereturn local tsplit "`tsplit'"
        ereturn local tvc_covariates "`_fg_tvccols'"
        ereturn local tvc_pos "`_fg_tvcpos'"
        * Cause events per interval, in interval order.  Reported in the
        * interval legend; a small count is the visible face of the monotone-
        * likelihood risk that a piecewise fit runs and a proportional one
        * does not.
        ereturn local tsplit_nfail "`_fg_tvnfail'"
    }
    if "`cluster'" != "" ereturn local clustvar "`cluster'"

    * Combined-weight contract.  lt_weight names the weight actually computed:
    *   right_censoring : no delayed entry; A == G; identical to prior releases
    *   zzf1_geskus       : one weight stratum; Geskus product-limit form
    *   zzf1_stratified   : ZZF eq. 7 pooled-stabilizer form; strata() and
    *                       truncstrata() name the SAME grouping -- the paper's
    *                       stratified nonparametric construction
    *   zzf1_factorized   : ZZF eq. 7 machinery, but strata() and truncstrata()
    *                       name DIFFERENT groupings (including one side left
    *                       unspecified): G is estimated within strata(), H
    *                       within truncstrata(), and the components multiply.
    *                       This is a package extension, NOT attributed to Zhang
    *                       et al.; it requires factor-specific separability:
    *                       G may not vary across omitted truncation groups and H
    *                       may not vary across omitted censoring groups. It is
    *                       named apart from zzf1_stratified because its validity
    *                       conditions differ, so a consumer can branch on it.
    * "Same grouping" compares the sorted variable lists: order does not change
    * the partition egen group() forms, so a re-ordered strata() is still ZZF.
    * _fg_njgrp is defined only on the delayed-entry branch, so every reference
    * to it stays inside `if _fg_has_lt'; _fg_factorized is initialized here so
    * the fit-time note below can test it unconditionally.
    local _fg_factorized = 0
    if `_fg_has_lt' {
        if `_fg_njgrp' > 1 {
            local _fg_strata_sorted : list sort strata
            local _fg_trunc_sorted  : list sort truncstrata
            if `"`_fg_strata_sorted'"' != `"`_fg_trunc_sorted'"' ///
                local _fg_factorized = 1
            if `_fg_factorized' ereturn local lt_weight "zzf1_factorized"
            else                ereturn local lt_weight "zzf1_stratified"
        }
        else ereturn local lt_weight "zzf1_geskus"
    }
    else ereturn local lt_weight "right_censoring"

    * LT variance contract.  lt_vce names the variance actually computed on the
    * delayed-entry branch, so a consumer never has to infer it from the option
    * list.  Adjudicated by Gate Z-inference (qa/validation_finegray_zzf_coverage.do),
    * which measures 95% coverage against a known truth across two truncation
    * intensities and two sample sizes:
    *   model_based          inverse information, no sandwich (Geskus 2011 p.44)
    *   fixed_weight_sandwich  score-residual sandwich that treats the estimated
    *                  censoring distribution G -- and, under delayed entry, the
    *                  entry distribution H, carried as A = G(t-)H(t-) -- as
    *                  FIXED.  It is cluster-robust when cluster() is given.  This
    *                  is NOT the full Fine-Gray (1999) eq. 7-8 / ZZF (2011)
    *                  nuisance-adjusted variance: the two-part influence term for
    *                  having ESTIMATED G (and H) is not added.  Its omission
    *                  is documented and empirically small: Gate Z-inference
    *                  puts fixed_weight_sandwich inside [0.925, 0.975] in
    *                  every arm up to 69% truncation (finegray_methods.sthlp,
    *                  Variance).
    *   nuisance_adjusted  the sandwich with the ZZF (2011) Appendix B
    *                  influence terms added (_finegray_psi_residuals_lt): the
    *                  contribution of the estimated all-cause survival S and
    *                  at-risk fraction b behind the Weight-1 stabilizer.
    *                  Reached by `nuisance' on a delayed-entry fit with the
    *                  pooled weight (no strata()/truncstrata()); the
    *                  stratified cell is refused (ZZF Appendix E treat the
    *                  weight as known there).  Without delayed entry the same
    *                  terms reduce to FG's psi, asserted in QA.
    *   not_applicable no delayed entry -- the right-censoring branch is unchanged
    *                  from prior releases and its variance is not at issue here
    if !`_fg_has_lt'                      ereturn local lt_vce "not_applicable"
    else if "`robust'" == "norobust"      ereturn local lt_vce "model_based"
    else if "`nuisance'" != ""            ereturn local lt_vce "nuisance_adjusted"
    else                                  ereturn local lt_vce "fixed_weight_sandwich"

    * Weight-sensitivity diagnostics, computed once by _finegray_weight_diag over
    * the cells the scan ACTUALLY consults (a stratum's A may collapse in a tail
    * it carries no competing mass into; that cell is never divided by).
    *   N_weight_strata : observed joint (censoring x truncation) strata
    *   min_weight_prob : smallest consulted A
    *   max_lt_weight   : largest retained subject-by-cause-time weight
    *   N_prob_warn     : consulted A cells below 1e-10
    *   N_weight_warn   : retained weights above 1e6
    *   weight_warn_strata : joint-group codes contributing a flagged cell/weight
    * NOT wrapped in -capture-.  The engine posts these unconditionally, so a
    * missing matrix means the weight diagnostics did not run -- and a silent
    * e(min_weight_prob) == . would be indistinguishable from "no weight was ever
    * near zero", which is the reassuring reading of a broken contract.  Fail loudly.
    ereturn scalar N_weight_strata = _finegray_nwstrata[1,1]
    ereturn scalar min_weight_prob = _finegray_minprob[1,1]
    ereturn scalar max_lt_weight   = _finegray_maxwt[1,1]
    ereturn scalar N_prob_warn     = _finegray_nprobwarn[1,1]
    ereturn scalar N_weight_warn   = _finegray_nwtwarn[1,1]
    ereturn local weight_warn_strata "`_fg_warnstrata'"
    * Observations whose censoring survivor G(t) was floored at 1e-10 during the
    * fit's own KM sweep.  `_fg_ntrunc' is set directly in this scope by
    * _finegray_km_censor via st_local (see its header for why it reports rather
    * than prints).  Missing would be indistinguishable from "none", so treat an
    * unset local as a broken contract rather than as a reassuring zero.
    if "`_fg_ntrunc'" == "" {
        display as error "internal error: the G(t) truncation count was not returned"
        exit 498
    }
    ereturn scalar N_G_trunc = `_fg_ntrunc'
    * VCE type: cluster > robust (default) > oim (norobust)
    if "`cluster'" != "" {
        ereturn local vce "cluster"
    }
    else if "`robust'" != "norobust" {
        ereturn local vce "robust"
    }
    else {
        ereturn local vce "oim"
    }
    * Which sandwich meat was used.  A consumer must never have to infer from
    * the option list whether the FG (1999) eq. 7-8 psi term is in e(V).
    *   fixed_weight   sum_i eta_i^(x)2        -- G treated as known (default)
    *   nuisance_adjusted  sum_i (eta_i+psi_i)^(x)2 -- G estimated (nuisance)
    *   not_applicable model-based variance; no sandwich meat exists
    if "`robust'" == "norobust"      ereturn local vce_meat "not_applicable"
    else if "`nuisance'" != ""       ereturn local vce_meat "nuisance_adjusted"
    else                             ereturn local vce_meat "fixed_weight"
    * Whether the finite-sample factor was applied, and to WHAT.  It multiplies
    * the COEFFICIENT variance e(V) only: N/(N-1), or g/(g-1) under cluster().
    * The analytic cumulative-incidence variance finegray_cif and
    * finegray_predict report is the asymptotic influence-function sandwich and
    * carries no such factor, so noadjust moves e(V) and leaves every CIF
    * standard error unchanged.  Stated in prose under noadjust in help
    * finegray; this is its machine counterpart, in the same spirit as
    * e(vce_meat) above.
    *   finite_sample  e(V) carries N/(N-1) or g/(g-1)   (the default)
    *   none           noadjust, or norobust (no sandwich to adjust)
    if "`robust'" == "norobust"      ereturn local vce_adjust "none"
    else if "`adjust'" == "noadjust" ereturn local vce_adjust "none"
    else                             ereturn local vce_adjust "finite_sample"
    ereturn local title "Fine-Gray competing risks regression"
    * margins consumes xb as a single linear predictor.  e(marginsok) lists the
    * predict() statistics margins may ADD to that default; emptying it does NOT
    * withdraw margins -- verified 2026-08-29: after `finegray c.ifp##c.tumsize'
    * (empty here, no base level to widen on) `margins, dydx(ifp)' and
    * `margins, dydx(ifp) predict(xb)' both run, because predict(xb) names the
    * default rather than adding to it.  What this macro says is narrower: xb is
    * the only statistic margins may be pointed at.
    *
    * Under tvc() there is no single xb -- the linear predictor depends on which
    * interval the evaluation time falls in -- so there is no statistic to
    * offer.  margins refuses such a fit on its own, at r(498) ("default
    * prediction is a function of possibly stochastic quantities other than
    * e(b)"), which is the actual fence; this macro records the same fact for a
    * reader of e().  A factor-variable fit is offered xb only when the stripe
    * was widened above: the fallback stripe has no base-level columns for
    * margins to enumerate, so `margins grp' there stops at r(322).
    if "`tvc'" != "" | (`_has_fv' & !`_fg_wide') {
        ereturn local marginsok ""
    }
    else {
        ereturn local marginsok "xb"
    }

    local _sig_entry_seen = 0
    if "`_fg_entryvar'" != "" {
        local _sig_entry_seen : list posof "`_fg_entryvar'" in _fg_sigvars
        if `_sig_entry_seen' == 0 local _fg_sigvars "`_fg_sigvars' `_fg_entryvar'"
    }
    * Package-owned _fg_* design columns are deliberately NOT in this signature.
    * They are derived from the raw factor variables, and post-estimation is
    * allowed to rebuild them when they have been dropped -- putting them here
    * would turn a supported `drop _fg_*' into a hard error.  A _fg_ column that
    * is PRESENT but no longer matches what the fit-time expansion implies is a
    * different matter, and _finegray_check_data verifies that separately
    * (flipping _fg_grp_2 moved the CIF from 0.18367237 to 0.18251435 at rc 0).
    quietly _datasignature `_fg_sigvars' if e(sample), nodefault nonames
    ereturn local datasignature `"`r(datasignature)'"'
    ereturn local datasignaturevars "`_fg_sigvars'"

    * e(basehaz) carries one row per distinct cause-event time, so K is roughly
    * n/2.  Creating ANY K-row Stata matrix is O(K^2) -- Stata builds the
    * dimension-name stripe quadratically, and it hits every route (st_matrix,
    * mkmat, plain copy, transpose, submatrix) alike: 38.6 s of the 95.0 s fit at
    * n = 200,000.  That round trip was the package's ENTIRE superlinearity
    * (slope 1.65 with it, 1.05 without), so it is now opt-in via basehaz.
    * Postestimation never needs it -- finegray_cif and finegray_predict rebuild
    * the same curve in Mata -- and `predict, basecshazard' gives the baseline as
    * a VARIABLE, which is O(n) and is the form stcrreg users already know.
    * ereturn MOVES a named matrix rather than copying it (free: 0.02 s at
    * K = 40,000), so post the Mata-built matrix directly.  The cleanup loop below
    * is a `capture matrix drop', so the moved-away name is not an error.
    if "`basehaz'" != "" {
        capture confirm matrix _finegray_basehaz
        if _rc == 0 {
            ereturn matrix basehaz = _finegray_basehaz
        }
    }

    * The key to the Mata baseline cache (see _finegray_bh_store).  The curve
    * itself lives in Mata, where it costs nothing; this is only its receipt.  A
    * consumer must present this key to get the cache back, so a stale curve from
    * a PREVIOUS fit can never be used to answer for this one -- that would be a
    * wrong CIF at rc 0, which is the failure class that matters.
    *
    * The key is a per-fit STRING token, not the old integer counter.  The
    * counter lived in Mata, so `mata clear' reset it and the next fit was handed
    * key 1 again; an `estimates restore' of an earlier fit that also held key 1
    * then scored its betas on the new fit's baseline at rc 0.  The salt below is
    * a Stata global counter -- which `mata clear' does not touch -- plus the wall
    * clock, and _finegray_bh_setkey folds a digest of e(b) and the fit scalars
    * into it, so a re-minted key is not reachable.  It runs AFTER `ereturn post'
    * because the digest reads e().  e(bh_seq) is kept as the human-readable
    * receipt; nothing gates on it any more.
    ereturn local bh_seq "`_fg_bh_seq'"
    if `"`_fg_bh_seq'"' != "" {
        * A GLOBAL, not a Mata scalar: `mata clear' is the event this key exists
        * to survive.  (A global macro name may not begin with an underscore.)
        capture confirm number $finegray_bh_ctr
        if _rc global finegray_bh_ctr = 0
        global finegray_bh_ctr = $finegray_bh_ctr + 1
        local _fg_bh_salt = string(clock("`c(current_date)' `c(current_time)'", ///
            "DMYhms"), "%21x") + "." + "$finegray_bh_ctr"
        mata: _finegray_bh_setkey("`_fg_bh_salt'")
        ereturn local bh_key "`_fg_bh_key'"
    }

    * Store dataset chars for predict.
    *
    * NOT on mi data.  These characteristics are the receipt for the permanent
    * support columns, and on mi data there are none: the entry column and every
    * _fg_<term> design column were tempvars and are about to be dropped.  A
    * receipt naming columns that no longer exist is the rc=0-but-wrong shape
    * this package spends most of its comments avoiding -- worse here than
    * elsewhere, because a tempvar NAME is reused by the next command that asks
    * for one, so a stale e(designvars)/char pair could resolve to somebody
    * else's column rather than failing to resolve at all.
    *
    * What is left standing instead is the "0" (INVALIDATED) mark written before
    * the fit began mutating anything, so _finegray_check_data refuses this
    * dataset outright.  The explicit e(postest) guards in finegray_predict,
    * finegray_cif and finegray_phtest fire first and name the actual reason.
    if !`_fg_is_mi' {
        char _dta[_finegray_estimated] "1"
        char _dta[_finegray_compete]   "`compete'"
        char _dta[_finegray_cause]     "`cause'"
        char _dta[_finegray_covars]    "`varlist'"
        char _dta[_finegray_fvvars]    "`_fv_created'"
        char _dta[_finegray_entryvar]  "`_fg_entryvar'"
        char _dta[_finegray_owner]     "`_fg_owner_tok'"
        if `_has_fv' {
            char _dta[_finegray_fvvarlist] "`_orig_varlist'"
        }
        else {
            char _dta[_finegray_fvvarlist] ""
        }
    }

    * =========================================================================
    * DISPLAY RESULTS
    * =========================================================================
    * The whole display lives in _finegray_display and reads e() only, so a
    * replay (`finegray' with no varlist) reproduces the fit-time output exactly
    * rather than a second, drifting copy of it.  Every quantity it needs is
    * posted above -- including e(N_delayed) and e(compete_values), which exist
    * for no other reason.
    _finegray_display, level(`level') `shr'

    } /* end capture noisily */

    local rc = _rc

    * Clean up temporary matrices (runs on both success and error paths)
    foreach m in _finegray_b _finegray_V _finegray_ll _finegray_ll_0 ///
        _finegray_chi2 _finegray_df_m _finegray_conv ///
        _finegray_rank _finegray_nclust _finegray_basehaz ///
        _finegray_kbstrata ///
        _finegray_nwstrata _finegray_minprob _finegray_maxwt ///
        _finegray_nprobwarn _finegray_nwtwarn {
        capture matrix drop `m'
    }

    * Drop FV indicators on error (they persist on success for predict)
    if `rc' & "`_fv_created'" != "" {
        foreach v of local _fv_created {
            capture drop `v'
        }
    }

    * Drop the entry-time variable on error (persists on success for
    * post-estimation on reduced multi-record fits)
    if `rc' & "`_fg_entryvar'" != "" {
        capture drop `_fg_entryvar'
    }

    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
