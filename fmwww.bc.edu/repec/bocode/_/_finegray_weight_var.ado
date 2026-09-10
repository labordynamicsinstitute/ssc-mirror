*! _finegray_weight_var Version 1.3.2  2026/09/08
*! Rebuild the fit's design-weight column from e(wexp) for post-estimation
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: rclass (internal)

* Fills `wname' -- a tempvar name the caller has already reserved -- with the
* fit's weight expression e(wexp) evaluated over `touse', and returns the
* engine's weight-type code in r(wtype): 1 pweight, 2 fweight.  Refuses any
* other e(wtype), and refuses a weight that is missing or non-positive on a
* row of the estimation sample.
*
* THE REBUILT COLUMN IS RECONCILED AGAINST THE FIT, NOT ONLY SIGNED.
* e(datasignature) covers the VARIABLES the expression names, and _n/_N are
* refused at fit time; but a scalar, an e() or c() value, a subscript such as
* w[1] or a random draw inside the expression is not a variable, so a change
* to it -- or, for the subscript, a re-sort -- re-evaluates e(wexp) into a
* DIFFERENT column at rc 0.  Measured 2026-08-29 (independent review): the
* CIF moved 4.6e-4 for a changed scalar and 2.4e-4 for a re-sorted w[1],
* both at rc 0.  So the column is first rebuilt over e(sample) and its total
* compared with e(sum_w), the total the fit recorded over the same rows; a
* mismatch is refused r(459).  The total is order-invariant, so a plain
* re-sort of a variable weight passes, and it moves for every member of the
* class above short of a change that leaves the sum untouched to 1e-10.
*
* One place, so that finegray_cif, finegray_predict, finegray_phtest and
* _finegray_resolve_baseline agree on what the weight column IS.

program define _finegray_weight_var, rclass
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    capture noisily {
        syntax , wname(name) touse(name)

        local _wt `"`e(wtype)'"'
        if "`_wt'" == "pweight"      local _code = 1
        else if "`_wt'" == "fweight" local _code = 2
        else {
            display as error "internal error: e(wtype) is `_wt', not pweight or fweight"
            exit 498
        }

        * Reconciliation over the estimation sample, whatever `touse' the
        * caller passed (finegray_predict without ci/schoenfeld predicts over
        * the user's if/in, a subset).
        tempvar _es _chk
        quietly gen byte `_es' = e(sample)
        quietly generate double `_chk' `e(wexp)' if `_es'
        quietly count if `_es' & (missing(`_chk') | `_chk' <= 0)
        if r(N) > 0 {
            display as error "the fit's weights cannot be rebuilt from e(wexp)"
            display as error "`r(N)' estimation-sample observation(s) now carry a missing or"
            display as error "non-positive weight; re-run {bf:finegray} before this post-estimation command"
            exit 459
        }
        quietly summarize `_chk' if `_es', meanonly
        if missing(e(sum_w)) | reldif(r(sum), e(sum_w)) > 1e-10 {
            display as error "the weights rebuilt from e(wexp) do not reproduce the fit's weights"
            display as error "their total over e(sample) is " %12.0g r(sum) ///
                " where the fit recorded e(sum_w) = " %12.0g e(sum_w)
            display as error "something the weight expression reads -- a scalar, an e() or c() value,"
            display as error "a subscript such as w[1] -- has changed since the fit (or the data were"
            display as error "re-sorted under a subscript); re-run {bf:finegray} before this post-estimation command"
            exit 459
        }

        * The total is not the weights.  A compensated change of an unsignable
        * input -- [pw = cond(odd == 0, k, 4 - k)] after `scalar k = 2' -- leaves
        * e(sum_w) exactly where it was and moves every per-observation weight,
        * and the sum check above passes it at rc 0.  e(wsig) is a
        * value-sensitive, order-invariant digest of the fit's own weight
        * column, so it moves for that change and does NOT move for a plain
        * re-sort of a variable weight.
        * DEGRADATION, and it is now AUDIBLE rather than silent: when e(wsig) is
        * absent the reconciliation above is by TOTAL only, and a compensated
        * change of an unsignable weight input passes at rc 0.  The else branch
        * below says so, in the user's face, on every such call.
        *
        * WARNING, NOT REFUSAL, and the reason is a fact about what can reach
        * here rather than a preference.  Two states leave e(wsig) empty:
        *
        *   1  Estimates from a build that predates the digest.  Weighted fits
        *      shipped WITHOUT e(wsig) in released commits d2cb1bda and
        *      789e2635, so `estimates use' of a legitimate weighted fit made by
        *      the current release lands here.  Those results are correct; a
        *      hard exit would break a working, previously supported path for
        *      users who cannot re-fit without the original data.
        *   2  An e() assembled by `mi estimate'.  That state never arrives:
        *      every post-estimation entry point refuses it first and by name --
        *      finegray_cif.ado, finegray_predict.ado and finegray_phtest.ado
        *      each exit 301 on e(cmd) == "mi estimate" & e(cmd_mi) ==
        *      "finegray" BEFORE any weight is rebuilt.  So a refusal here would
        *      buy nothing on the mi path and cost the legacy one.
        *
        * The message is `display as error' inside the `capture noisily' block,
        * so it survives a caller's `quietly' and prints in the error colour.
        if `"`e(wsig)'"' == "" {
            display as error "warning: this fit's e() carries no weight digest e(wsig)"
            display as error "the rebuilt weights were reconciled against e(sum_w) ONLY, which is their"
            display as error "TOTAL: a change to something the weight expression reads -- a scalar, an"
            display as error "e() or c() value, a subscript such as w[1] -- that leaves the total unmoved,"
            display as error "or an exchange of two subjects' weights, is NOT detected here, and this"
            display as error "result may then be computed from a different weight column than the fit used"
            display as error "estimates saved before this build carry no e(wsig); re-run {bf:finegray} on"
            display as error "the current data for the per-observation check"
        }
        if `"`e(wsig)'"' != "" {
            * Keyed by the fit's own id() variable (e(idvar)), so exchanging
            * two subjects' weights is caught; without it the digest sees only
            * the multiset of weight values.
            local _wsigid `"`e(idvar)'"'
            if `"`_wsigid'"' != "" {
                * The digest the fit stored is KEYED by this variable.  Blanking
                * the key when the variable is gone rebuilds a value-only digest
                * and compares it against a subject-keyed one: a guaranteed
                * mismatch, reported as "a scalar has changed since the fit",
                * which is the wrong diagnosis and sends the user looking in the
                * wrong place.  Refuse over the missing key by name instead.
                capture confirm variable `_wsigid'
                if _rc {
                    display as error "the id variable `_wsigid' used by the fit is not in the data"
                    display as error "postestimation weight reconciliation needs it: the fit's weight"
                    display as error "digest is keyed by subject, so it cannot be rebuilt without it"
                    display as error "restore the variable, or re-run {bf:finegray} before this post-estimation command"
                    exit 459
                }
            }
            mata: _finegray_wsig("`_chk'", "`_es'", "`_wsigid'")
            if `"`_fg_wsig'"' != `"`e(wsig)'"' | `_fg_wsig_n' != e(wsig_n) {
                display as error "the weights rebuilt from e(wexp) do not reproduce the fit's weights"
                display as error "the per-observation weights differ from the fit's although their total matches"
                display as error "something the weight expression reads -- a scalar, an e() or c() value,"
                display as error "a subscript such as w[1] -- has changed since the fit in a way that leaves"
                display as error "e(sum_w) unmoved; re-run {bf:finegray} before this post-estimation command"
                exit 459
            }
        }

        quietly generate double `wname' `e(wexp)' if `touse'
        quietly count if `touse' & (missing(`wname') | `wname' <= 0)
        if r(N) > 0 {
            display as error "the fit's weights cannot be rebuilt from e(wexp)"
            display as error "`r(N)' observation(s) in the prediction sample carry a missing or"
            display as error "non-positive weight; re-run {bf:finegray} before this post-estimation command"
            exit 459
        }
        return scalar wtype = `_code'
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
