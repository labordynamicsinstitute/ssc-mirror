*! _finegray_mata Version 1.3.2  2026/09/08
*! Mata forward-backward scan engine for Fine-Gray regression
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: internal (stores results in Stata matrices)

/*
Internal command: Fits Fine-Gray subdistribution hazard model using
the forward-backward scan algorithm (Kawaguchi et al. 2021).
Called by finegray. Not intended for direct user invocation.

Algorithm: O(np) per Newton-Raphson iteration
  1. KM censoring distribution G(t) (supports left truncation)
  2. Incremental risk-set tracking with entry-time pointer
  3. Backward scan: weighted sums for competing-event subjects
  4. Combine at cause-event times for score/Hessian
  5. Newton-Raphson with step halving

Key detail: processes observations in time-point groups to correctly
handle tied events (Breslow method) and prevent double-counting of
competing events at tied cause-event times.

Left truncation: subjects enter the risk set at _t0 and exit at _t.
The entry-time pointer advances through subjects sorted by _t0,
adding them to the active risk set as event times are processed.
When all _t0 == 0, this degenerates to the original full-cumsum
algorithm.
*/

* Loading guard.
*
* The sentinel MUST be a Mata function, not this Stata program.  `mata clear'
* (and `mata: mata clear') drops every Mata function while leaving Stata programs
* untouched -- so a Stata-program sentinel still answers "loaded" when the engine
* is in fact gone, the reload never fires, and the next Mata call dies with
* r(3499) "function not found".  Every caller therefore probes
* _finegray_mata_ok() (defined in the Mata block below) and reloads this file if
* the probe errors.  The program below is kept only as a human-facing marker.
capture program drop _finegray_mata_loaded
program define _finegray_mata_loaded
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    capture noisily {
        display as text "_finegray_mata is loaded"
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end

mata:
mata set matastrict on

/* The real load sentinel: a Mata function, so that `mata clear' -- which wipes
   Mata but not Stata programs -- makes the probe fail and the caller reload. */
void _finegray_mata_ok() {}

/* The non-base coefficient vector of the fit in e(), as a column.

   finegray posts the full fit-time expansion as its stripe on a factor-variable
   fit -- base terms (`0b.pelnode') included, with a zero coefficient -- because
   that is the stripe margins enumerates a factor's levels from.  The estimate
   is in the DESIGN frame: every routine here pairs beta[k] with design column k
   (the k-th name in e(designvars)), so the base columns must come out again
   before any such pairing.  Read the LIVE e(b) and drop by stripe, never a
   stored narrow copy: margins builds its delta-method Jacobian by reposting a
   perturbed e(b) and calling predict, and a private copy would leave that
   derivative at zero.  `Nb.' is the base marker; `Nbn.' (ibn.) carries a real
   coefficient and stays.  Same rule as _finegray_bnb on the Stata side and the
   kept-term filter in finegray.ado; a tvc() or non-factor fit is the identity. */
real colvector _finegray_beta()
{
    real rowvector b
    string matrix s
    real colvector keep

    b = st_matrix("e(b)")
    if (cols(b) == 0) return(J(0, 1, .))
    s = st_matrixcolstripe("e(b)")
    keep = selectindex(!regexm(s[., 2], "[0-9]+b\."))
    if (length(keep) == cols(b)) return(b')
    return(b[1, keep]')
}

/* Single-stratum KM of censoring distribution (with left truncation).
   Returns the POST-JUMP survivor at each observation time, i.e. the ordinary
   right-continuous KM step values.  Consumers that need the IPCW weight take
   the left limit G(t-) via _finegray_G_at_times/_finegray_G_minus; keeping the
   raw step values here is what lets that lookup be exact at, between, and
   beyond observation times. */
real colvector _finegray_km_censor_single(
    real colvector t,
    real colvector delta,
    real scalar censval,
    real colvector event_type,
    real colvector t0,
    | real scalar n_trunc_out,
    real colvector w)
{
    real colvector row_id
    real scalar n, i, j, surv, n_risk_at_t, n_cens_at_t, cur_time, ep
    real colvector G, ord, entry_ord

    n = rows(t)
    G = J(n, 1, 1)
    /* fweight replication: an observation carrying w copies counts w times
       in the at-risk and censored totals.  pweights never reach here -- the
       censoring KM is UNWEIGHTED under pweights, as in survival::finegray.
       This is the analysis-sample G, not Wogu et al.'s full-cohort G;
       population interpretation requires a valid sample censoring estimate. With
       w == 1 every sum below is the integer count it was. */
    if (args() < 7) w = J(n, 1, 1)
    /* Deterministic tie-break by row index.  Mata's order() resolves ties
       using Stata's sort seed, which ADVANCES on every sort, so a tied key
       (every t0 == 0 when there is no delayed entry) yields a different
       permutation on each call -- and the risk-set scan then accumulates in
       a different floating-point order.  Without this the same command on
       the same data is not bit-reproducible. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))

    surv = 1
    ep = 1  /* entry pointer */
    n_risk_at_t = 0

    /* For LT-KM we need to count the risk set dynamically.
       Stata survival intervals are (t0, t], so the risk set at time t is the
       subjects with t0 < t AND _t >= t: a subject entering at exactly t is not
       yet at risk for an event at t.
       Process entry events (sorted by t0) and exit events (sorted by _t)
       simultaneously via a two-pointer merge. */

    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]

        /* Add entries: subjects with t0 < cur_time */
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            /* Only count if subject is still alive (t >= cur_time) */
            if (t[entry_ord[ep]] >= cur_time) {
                n_risk_at_t = n_risk_at_t + w[entry_ord[ep]]
            }
            ep++
        }

        /* Count censoring events in this time group */
        n_cens_at_t = 0
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            if (event_type[ord[j]] == censval & delta[ord[j]] == 0) {
                n_cens_at_t = n_cens_at_t + w[ord[j]]
            }
            j++
        }

        if (n_cens_at_t > 0 & n_risk_at_t > 0) {
            surv = surv * (1 - n_cens_at_t / n_risk_at_t)
        }

        /* Assign G to all obs at this time, then remove them from risk set */
        while (i < j) {
            G[ord[i]] = surv
            n_risk_at_t = n_risk_at_t - w[ord[i]]
            i++
        }
    }

    real scalar n_trunc
    n_trunc = 0
    for (i = 1; i <= n; i++) {
        if (G[i] < 1e-10) {
            G[i] = 1e-10
            n_trunc++
        }
    }
    /* This function never prints.  A stratified sweep calls it once per
       stratum, so a note emitted here would fire once PER STRATUM; the
       decision to print, and the aggregation across strata, belong to
       _finegray_km_censor.  Report the count back by reference instead. */
    if (args() >= 6) n_trunc_out = n_trunc

    return(G)
}

/* KM of censoring distribution, optionally stratified by byg */
real colvector _finegray_km_censor(
    real colvector t,
    real colvector delta,
    real scalar censval,
    real colvector event_type,
    real colvector byg_id,
    real colvector t0,
    | real scalar quiet,
    real colvector w)
{
    real scalar n, g, nlev, n_trunc, n_trunc_tot
    real colvector G, levels, sel

    /* quiet suppresses the G-truncation note.  The fit REPORTS it once (the
       data characteristic is the user's to act on); post-estimation commands
       recompute G for the influence function and must NOT reprint it, or a
       fit-time warning appears attributed to predict/cif.  Omitted => 0. */
    if (args() < 7) quiet = 0
    if (args() < 8) w = J(rows(t), 1, 1)
    n_trunc_tot = 0

    n = rows(t)
    G = J(n, 1, 1)

    levels = uniqrows(byg_id)
    nlev = rows(levels)
    if (nlev > 1) {
        for (g = 1; g <= nlev; g++) {
            sel = selectindex(byg_id :== levels[g])
            G[sel] = _finegray_km_censor_single(t[sel], delta[sel],
                censval, event_type[sel], t0[sel], n_trunc, w[sel])
            n_trunc_tot = n_trunc_tot + n_trunc
        }
    }
    else {
        G = _finegray_km_censor_single(t, delta, censval, event_type, t0,
            n_trunc, w)
        n_trunc_tot = n_trunc
    }

    /* One count per sweep, over every stratum.  Truncation is a property of
       the censoring KM as a whole; the per-stratum breakdown is not something
       the user acts on differently, and printing it per stratum buried the
       message under its own repeats.

       Handed BACK rather than printed.  This function runs while the weights
       are being built, i.e. before the caller has displayed anything, so a
       printf here made an unexplained line of jargon ("G(t)") the first thing
       a first-time user saw -- above even the command's own title.  The count
       now rides out in a local, the fit posts it as e(N_G_trunc), and
       _finegray_display prints it inside the header where the reader already
       has the context to read it (and with the right singular/plural). */
    if (!quiet) {
        st_local("_fg_ntrunc", strofreal(n_trunc_tot, "%18.0g"))
    }

    return(G)
}

/* Map each observation to its censoring-distribution group. */
real colvector _finegray_group_index(
    real colvector byg_id,
    real colvector levels)
{
    real scalar g
    real colvector gidx, sel

    gidx = J(rows(byg_id), 1, .)
    for (g = 1; g <= rows(levels); g++) {
        sel = selectindex(byg_id :== levels[g])
        /* length(), not rows().  Mata reads a 1 x 1 result as a ROW vector, so
           selectindex() with no match on a one-row input returns 1 x 0 and
           rows() answers 1 -- which then asks for a J(1,1,.) assignment into
           nothing.  length() is rows*cols and is right either way. */
        if (length(sel) == 0) continue
        gidx[sel] = J(length(sel), 1, g)
    }
    return(gidx)
}

/* ------------------------------------------------------------------------
   Baseline strata -- bstrata().

   A DIFFERENT axis from strata()/truncstrata().  strata() stratifies the
   Kaplan-Meier censoring distribution G, truncstrata() the entry distribution
   H; bstrata() leaves both alone and frees the BASELINE subdistribution hazard
   per stratum, with beta shared -- Zhou, Latouche, Rocha & Fine (2011),
   Biometrics 67(2):661-670.  The log pseudo-likelihood is then a sum of
   independent within-stratum terms, so score and information are sums too and
   the scan runs once per stratum over that stratum's rows.

   Strata are identified by the bstrata() variable's VALUES, never by an
   `egen group()' code.  A code depends on which levels are present in the
   sample it was built over, so a post-estimation call restricted to a subset
   of the fit's rows would renumber the strata and read another stratum's
   baseline at rc 0.  uniqrows() on the values is stable under subsetting.
   ------------------------------------------------------------------------ */
void _finegray_bs_setup(
    real colvector bsraw,
    real colvector bslev,
    real colvector bscode,
    real scalar K)
{
    if (rows(bsraw) == 0) {
        bslev  = J(0, 1, .)
        bscode = J(0, 1, .)
        K = 0
        return
    }
    bslev = uniqrows(bsraw)
    K = rows(bslev)
    /* K == 1 is the unstratified fit.  Short-circuit so that every scan below
       walks exactly the row order it walked before bstrata() existed: the
       stratum loop runs once, over the untouched ord/entry_ord, and the
       floating-point accumulation order -- hence the last bit of every
       estimate -- is unchanged.  Guarded by the K = 1 identity test. */
    if (K == 1) {
        bscode = J(rows(bsraw), 1, 1)
        return
    }
    bscode = _finegray_group_index(bsraw, bslev)
}

/* Row indices of one baseline stratum, in the scan's own order.  Selecting
   FROM the global permutation (rather than re-sorting the stratum's rows)
   keeps the within-stratum order identical to the pooled scan's, which is what
   makes the K = 1 case bit-identical. */
real colvector _finegray_bs_rows(
    real colvector ord,
    real colvector bscode,
    real scalar kk,
    real scalar K)
{
    if (K <= 1) return(ord)
    return(select(ord, bscode[ord] :== kk))
}

/* Evaluate every stratum-specific censoring KM at arbitrary target times, as
   the LEFT LIMIT G_g(target_t-).  G carries the post-jump survivor at each
   observation time, so accumulating only the jumps at times strictly BELOW the
   target yields the left limit -- for a target that is itself an observation
   time as well as for one between (or beyond) observation times.

   The left limit is the convention both reference implementations use:
   cmprsk::crr evaluates the censoring KM at ftime*(1 - 100*eps) and stcrreg
   does the same.  A subject whose time coincides with a censoring event must
   NOT absorb that time's KM jump.

   Fine-Gray IPCW weights for a retained competing-event subject use the
   numerator from THAT SUBJECT'S censoring stratum, not the stratum of the
   cause event currently being processed. */
real matrix _finegray_G_at_times(
    real colvector t,
    real colvector G,
    real colvector byg_id,
    real colvector target_t)
{
    real scalar g, i, p, lastg
    real colvector levels, sel, gord, tord
    real matrix out

    levels = uniqrows(byg_id)
    out = J(rows(target_t), rows(levels), 1)
    tord = order(target_t, 1)

    for (g = 1; g <= rows(levels); g++) {
        sel = selectindex(byg_id :== levels[g])
        gord = sel[order(t[sel], 1)]
        p = 1
        lastg = 1
        for (i = 1; i <= rows(tord); i++) {
            while (p <= rows(gord)) {
                if (t[gord[p]] < target_t[tord[i]]) {
                    lastg = G[gord[p]]
                    p++
                }
                else break
            }
            out[tord[i], g] = lastg
        }
    }
    return(out)
}

/* Left-limit censoring survivor G(T_i-) for each observation, read from that
   observation's OWN censoring stratum.  This is the IPCW denominator used to
   weight a competing-event subject back into the subdistribution risk set. */
real colvector _finegray_G_minus(
    real colvector gidx,
    real matrix Gt)
{
    real scalar i, n
    real colvector out

    n = rows(gidx)
    out = J(n, 1, 1)
    for (i = 1; i <= n; i++) out[i] = Gt[i, gidx[i]]
    return(out)
}

/* ------------------------------------------------------------------------
   DELAYED ENTRY: the entry distribution H, and the combined weight A = G*H.

   Stabilized Zhang-Zhang-Fine Weight 1 is  w_i(t) = A(t-) / A(X_i-)  with

       A(t) = b(t) / S(t-)                  ZZF (2011) eq. (5)   [canonical]
            = H(t-) * G(t-)                 Geskus (2011) eq. (11)

   The product-limit identity holds without requiring L and C to be independent.
   Under independence, H and G additionally admit separate marginal-probability
   interpretations (H as P(L < t)); otherwise they remain the two product-limit
   factors of A. Gate Z-ties established that the two computational forms agree
   to machine precision on every tie-collision class.

   The product form is not merely convenient -- it is what makes the no-LT
   path BIT-IDENTICAL.  With no delayed entry every l_j = 0, so for any t > 0
   the product below is empty and H == 1, giving A == G exactly.  Computing
   the canonical b/S instead would reach the same limit by a different
   floating-point route and would perturb every released right-censoring
   result in its last digits.

   Sourced formulas (Geskus 2011, sec. 2.1, p.41):

       H(t)  = prod_{l_(j) >  t}  ( 1 - w_j / r(l_(j)) )        eq. (6)
       H(t-) = prod_{l_(j) >= t}  ( 1 - w_j / r(l_(j)) )        left limit
       r(u)  = #{ i : x_i >= u  &  l_i <= u }                   p.40

   H is a REVERSE-time product limit: "L is right truncated by X, this
   statistic is obtained by reversal of time, such that -L is left truncated
   by -X" (p.41).  So H is a product over entry times ABOVE t, and it rises
   to 1 at the right edge.

   TIE CONVENTION.  r(l_(j)) counts the entering subjects themselves (l_i <= u,
   not l_i < u): they are the "events" of the reverse-time process and must be
   in their own risk set.  This differs from the (t0, t] convention used for
   the at-risk set and for G, where an entry at exactly t is NOT yet at risk --
   which is the "events, then censorings, then entries" ordering (Geskus p.40).
   The two conventions are both correct and they are not the same; this is
   verified against the direct b/S oracle in qa/crossval_finegray_zzf.do rather
   than argued.
   ------------------------------------------------------------------------ */

/* Left limit H_g(target-) of the entry distribution, one column per level of
   tg_id, evaluated at arbitrary target times.

   H jumps at ENTRY times, which need not be observation (exit) times.  So --
   unlike G -- H cannot be represented by step values stored at the exit times
   and read back with _finegray_G_at_times: that lookup would attribute an
   entry jump to the last exit time below it.  H is therefore built on its own
   grid of distinct entry times and evaluated directly. */
real matrix _finegray_H_at_times(
    real colvector t,
    real colvector t0,
    real colvector tg_id,
    real colvector target_t)
{
    real scalar g, i, j, k, nlev, nl, u, w_j, r_j, acc
    real colvector levels, sel, l_g, t_g, lt, lord, tord
    real matrix out

    levels = uniqrows(tg_id)
    nlev = rows(levels)
    out = J(rows(target_t), nlev, 1)

    for (g = 1; g <= nlev; g++) {
        sel = selectindex(tg_id :== levels[g])
        l_g = t0[sel]
        t_g = t[sel]

        /* distinct entry times, ascending; entries at 0 never bind because
           H(u-) products run over l_j >= u and every target u is > 0 */
        lt = uniqrows(select(l_g, l_g :> 0))
        nl = rows(lt)
        if (nl == 0) continue          /* no delayed entry in this stratum: H == 1 */

        /* w_j and r_j for EVERY distinct entry time in one ascending pass.
           A nested subject-by-entry-time loop is O(n^2) and would destroy the
           linear-scan property this package exists for.  Two pointers instead:

               r(u) = #{ l_i <= u }  -  #{ x_i <= u }

           both of which are monotone in u.  O(n log n) for the sorts, O(n) here.

           NOTE THE `<=' ON THE EXIT SIDE.  Geskus (2011) fixes the tie ordering as
           t_(i) < c_(j) < l_(j) -- events, then censorings, then ENTRIES (p.40) --
           and states the consequence for the at-risk count directly: "Because we
           assume events to come first, individuals with an event at c_(j) are not
           considered to be at risk in the calculation of r(c_(j))" (p.41).  At an
           ENTRY time u the ordering puts BOTH the events and the censorings at u
           ahead of the entries at u, so every subject exiting at exactly u has
           already left and must NOT be counted in r(u).

           This was `x_i < u', which kept those subjects in the risk set and made
           the estimator depend on whether an entry time exactly COINCIDED with an
           exit time.  Nudging 80 tied entries from 5 to 5+1e-7 -- a change that
           cannot move any risk set -- then moved the coefficient by 5.4e-04.
           The continuous-time crossval fixtures cannot see this (tied entry/exit
           times have probability zero there); test_finegray_ties FG-C03 can, and
           did. */
        real colvector ls, ts_, wv, rv, Hleft
        real scalar pl, pt

        ls = sort(l_g, 1)
        ts_ = sort(t_g, 1)
        wv = J(nl, 1, 0)
        rv = J(nl, 1, 0)
        pl = 1
        pt = 1
        for (j = 1; j <= nl; j++) {
            u = lt[j]
            /* entries with l_i <= u */
            while (pl <= rows(ls)) {
                if (ls[pl] <= u) pl++
                else break
            }
            /* exits with x_i <= u (events and censorings at u precede entries) */
            while (pt <= rows(ts_)) {
                if (ts_[pt] <= u) pt++
                else break
            }
            rv[j] = (pl - 1) - (pt - 1)
            wv[j] = 0
        }
        /* w_j = multiplicity of each distinct entry time */
        pl = 1
        for (j = 1; j <= nl; j++) {
            u = lt[j]
            w_j = 0
            while (pl <= rows(ls)) {
                if (ls[pl] == u) {
                    w_j++
                    pl++
                }
                else if (ls[pl] < u) pl++
                else break
            }
            wv[j] = w_j
        }

        /* Reverse-time accumulation: walk entry times DOWNWARD, so that after
           absorbing all l_j >= u we hold H(u-).  Store the running product
           keyed to each entry time. */
        Hleft = J(nl, 1, 1)
        acc = 1
        for (j = nl; j >= 1; j--) {
            r_j = rv[j]
            w_j = wv[j]
            if (r_j > 0 & w_j > 0) acc = acc * (1 - w_j / r_j)
            Hleft[j] = acc        /* = prod over entry times >= lt[j] */
        }

        /* H(target-) = prod over entry times >= target = Hleft[first lt >= target] */
        tord = order(target_t, 1)
        lord = 1
        for (i = 1; i <= rows(tord); i++) {
            /* advance to the first entry time >= this target */
            while (lord <= nl) {
                if (lt[lord] < target_t[tord[i]]) lord++
                else break
            }
            out[tord[i], g] = (lord <= nl ? Hleft[lord] : 1)
        }
    }
    return(out)
}

/* Combined weight A_j(target-) = G_c(target-) * H_u(target-) for each
   CROSS-CLASSIFIED weight stratum j = (c, u), where c indexes the censoring
   strata (strata()) and u the truncation strata (truncstrata()).

   G is estimated within censoring strata and H within truncation strata; a
   subject's weight uses its own cell of each. jc/ju map each joint level to
   its censoring and truncation level. When truncstrata() is absent there is a
   single pooled H level; H == 1 only when there is no delayed entry. */
/* Cross-classified weight strata.  A subject's weight stratum is the pair
   (censoring stratum, truncation stratum) = (strata(), truncstrata()).  Only
   OBSERVED combinations become levels, so the joint count is <= nc*nu and is
   what e(N_weight_strata) reports.

   Outputs (by reference):
     jidx  n x 1   joint weight-stratum index of each subject, 1..nj
     jc    nj x 1  censoring-stratum index of each joint level  (column of Gt)
     ju    nj x 1  truncation-stratum index of each joint level (column of Ht)

   With no truncstrata() there is one pooled truncation level, so jidx/jc reduce
   to the censoring-stratum index and ju is all 1s. */
void _finegray_joint_setup(
    real colvector byg_id,
    real colvector tg_id,
    real colvector jidx,
    real colvector jc,
    real colvector ju)
{
    real scalar i, j, nj, n, lo, hi, mid
    real colvector lc, lu, ci, ui, key, ukey

    lc = uniqrows(byg_id)
    lu = uniqrows(tg_id)
    ci = _finegray_group_index(byg_id, lc)
    ui = _finegray_group_index(tg_id, lu)

    n = rows(byg_id)
    key = (ci :- 1) :* rows(lu) :+ ui          /* observed (c,u) codes */
    ukey = uniqrows(key)
    nj = rows(ukey)

    /* jidx[i] is the rank of key[i] among the OBSERVED joint codes.  uniqrows()
       returns ukey sorted ascending, so that rank is a binary search -- O(n log
       nj) -- and the nested `for j { for i }' scan this replaced was O(nj*n) of
       INTERPRETED Mata.  Measured at n = 20,000: 0.31 s per call with strata()
       at 200 levels against 0.01 s at 2 levels; 0.043 s after this change.  The
       >=100 joint-group cap in finegray.ado applies to DELAYED-ENTRY fits only,
       so nothing bounds nj on the right-censoring path.

       Every key[i] is in ukey by construction, so the search always hits and
       jidx is left with no missing -- identical output to the scan, including
       when byg_id/tg_id carry missing values (uniqrows sorts those last, and
       Mata's comparisons order missing above every number consistently).

       SCOPE, so the next reader does not over-credit this helper in isolation.
       Through 1.2.0 the likelihood and score rebuilt the whole beta-independent
       weight design on every optimizer evaluation.  _finegray_engine now
       prepares that design once and passes it through the Newton/line-search
       calls; standalone Mata callers still use the self-contained fallback. */
    jidx = J(n, 1, .)
    for (i = 1; i <= n; i++) {
        lo = 1
        hi = nj
        while (lo <= hi) {
            mid = floor((lo + hi) / 2)
            if (ukey[mid] < key[i]) lo = mid + 1
            else if (ukey[mid] > key[i]) hi = mid - 1
            else {
                jidx[i] = mid
                break
            }
        }
    }
    jc = J(nj, 1, .)
    ju = J(nj, 1, .)
    for (j = 1; j <= nj; j++) {
        jc[j] = floor((ukey[j] - 1) / rows(lu)) + 1
        ju[j] = ukey[j] - (jc[j] - 1) * rows(lu)
    }
}

real matrix _finegray_A_at_times(
    real colvector t,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    real colvector jc,
    real colvector ju,
    real colvector target_t)
{
    real scalar j, nj
    real matrix Gt, Ht, out

    Gt = _finegray_G_at_times(t, G, byg_id, target_t)
    Ht = _finegray_H_at_times(t, t0, tg_id, target_t)

    nj = rows(jc)
    out = J(rows(target_t), nj, 1)
    for (j = 1; j <= nj; j++) out[., j] = Gt[., jc[j]] :* Ht[., ju[j]]
    return(out)
}

/* ZZF (2011) equation (7) uses a POOLED time-side stabilizer and a
   stratum-specific subject-side denominator.  The same algebra applies to the
   package's factorized censoring-by-entry extension when its two grouping
   variables differ.  This differs from the historical symmetric
   A_g(t)/A_g(X_i) implementation only when delayed entry and multiple weight
   strata are both present.  Keeping the predicate explicit preserves the
   released no-entry path bit for bit. */
real scalar _finegray_use_pooled_stabilizer(
    real colvector t0,
    real colvector byg_id,
    real colvector tg_id)
{
    if (sum(t0 :> 0) == 0) return(0)
    /* More than one observed joint pair exists exactly when either component
       differs from its first value.  The former implementation built the full
       subject-to-joint-stratum mapping merely to answer this yes/no question,
       then the selected CIF/Schoenfeld core built the mapping again. */
    return(sum(byg_id :!= byg_id[1]) > 0 |
        sum(tg_id :!= tg_id[1]) > 0)
}

/* Pooled A(t-) = G_pool(t-) H_pool(t-), evaluated on target_t.  Bellach et
   al. (2020) establish the continuous-time equivalence to ZZF's b(t)/S(t-);
   the package's tie convention is separately regression-tested. */
real colvector _finegray_A_pool_at_times(
    real colvector t,
    real colvector delta,
    real scalar censval,
    real colvector event_type,
    real colvector t0,
    real colvector target_t)
{
    real colvector one, Gp
    real matrix Gpt, Hpt

    one = J(rows(t), 1, 1)
    /* quiet=1 is mandatory, not cosmetic.  The engine prepares this object once
       for all optimizer evaluations, while standalone likelihood/score callers
       may still build it on entry.  A helper-level note would therefore repeat
       a fit-time fact unpredictably.  The pooled A floor is separately surfaced
       -- and escalated to r(459) when a consulted cell is zero -- by
       _finegray_positivity_check, and the censoring KM's own truncation is
       reported once by the engine. */
    Gp = _finegray_km_censor(t, delta, censval, event_type, one, t0, 1)
    Gpt = _finegray_G_at_times(t, Gp, one, target_t)
    Hpt = _finegray_H_at_times(t, t0, one, target_t)
    return(Gpt[., 1] :* Hpt[., 1])
}

/* Build the beta-INDEPENDENT weight design once.

   The optimizer evaluates the score, likelihood, and step-halving candidates
   repeatedly at different beta values, but none of the objects below depends
   on beta.  Rebuilding them inside every evaluation made a 20,000-observation,
   200-stratum fit spend about 2.2 seconds per Newton iteration on identical
   work.  The engine now prepares this bundle once and passes it into the hot
   likelihood/score paths and downstream residual, baseline-hazard, and
   diagnostic calculations.  Standalone callers retain their self-contained
   fallback and build the same bundle on entry.

     use_pooled  whether ZZF equation 7's pooled stabilizer is active
     gidx       subject -> observed joint weight-stratum index
     Gminus     A_g(X_i-) for each subject
     A          A_g(t_i-) for every observation time and joint stratum
     Apool      pooled A(t_i-) (ones when the pooled branch is inactive) */
void _finegray_prepare_weight_design(
    real colvector t,
    real colvector delta,
    real scalar censval,
    real colvector event_type,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix A,
    real colvector Apool)
{
    real colvector jc, ju

    _finegray_joint_setup(byg_id, tg_id, gidx, jc, ju)
    A = _finegray_A_at_times(t, G, byg_id, t0, tg_id, jc, ju, t)
    Gminus = _finegray_G_minus(gidx, A)
    use_pooled = (sum(t0 :> 0) > 0 & rows(jc) > 1)
    if (use_pooled) {
        Apool = _finegray_A_pool_at_times(t, delta, censval, event_type, t0, t)
    }
    else {
        Apool = J(rows(t), 1, 1)
    }
}

/* Combined-weight diagnostics, computed ONCE after convergence.
   Posts the e() contract's weight-sensitivity scalars:

     _finegray_nwstrata   number of OBSERVED joint (censoring x truncation) strata
     _finegray_minprob    smallest A actually consulted by the scan
     _finegray_maxwt      largest RETAINED subject-by-cause-time weight
     _finegray_nprobwarn  count of consulted A cells below A_FLOOR (1e-10)
     _finegray_nwtwarn    count of retained weights above WT_CEIL (1e6)
     _finegray_warnstrata joint-group codes contributing a flagged cell/weight

   "CONSULTED" is the load-bearing word.  A stratum's A(t) may collapse toward
   zero in a tail where that stratum carries no competing-event mass at all; such
   a cell never enters the likelihood, and counting it would raise an alarm about
   a number the estimator never divides by.  The cells the scan actually uses are:

     numerator    A_g(t_k) for each cause-of-interest event time t_k and each stratum
                  g holding at least one competing-event subject with X_i < t_k
     denominator  A_g(X_i-) for each competing-event subject i that is retained,
                  i.e. that some cause event outlives

   max weight is computed WITHOUT expanding the n x K weight matrix.  A_g is a
   step function of time, so for subject i in stratum g

       max_{t_k > X_i} A_g(t_k) / A_g(X_i-)

   needs only a SUFFIX MAXIMUM of A_g over the cause-event times -- O(n + K) per
   stratum, not O(n*K).  (With no delayed entry H == 1, A = G is nonincreasing and
   every weight is <= 1; under left truncation H rises, so A need not be monotone
   and weights above 1 are legitimate.  That is exactly why this diagnostic exists
   only on the ZZF branch.) */
/* HARD POSITIVITY CHECK for the delayed-entry weights.

   A retained competing-event subject i is divided by its own stratum's
   A_g(X_i-): its numerator is A_g(t-) on the one-stratum branch and
   the pooled A(t-) under equation 7.  If A_g(X_i-) is ZERO, that weight is
   undefined -- and Mata returns
   MISSING for x/0 rather than infinity, so the damage surfaces far downstream as
   "the null log pseudo-likelihood is not finite" / r(430) "convergence not
   achieved".  That message blames the optimizer for what is actually a
   positivity violation in the data, and it names no stratum, so the user has
   nothing to act on.

   How it happens: a subject exits from a competing event so early that almost
   nobody in its weight stratum has entered yet, so H_g -- the entry-distribution
   product limit, estimated WITHIN the stratum -- is still 0 there.  Splitting the
   sample into more weight strata makes this MORE likely, because each H_g is then
   estimated from fewer subjects.  Observed live: n = 8,000 with 50 truncation
   strata gave 39 competing subjects with A(X_i-) exactly 0 (bit-exact, not merely
   small) in a stratum holding 168 subjects -- eight times the >=20-subject support
   boundary.  THE SIZE BOUNDARY DOES NOT PROTECT AGAINST THIS: it bounds how many
   subjects a stratum holds, not whether A stays away from zero where the scan
   actually divides by it.

   We refuse rather than drop the offending subjects: silently dropping them would
   change the estimand without saying so, which is the failure class this package
   treats as worst.

   This CANNOT fire on the no-LT branch, so released behaviour stays bit-identical:
   there H == 1, so A == G, and G(X_i-) > 0 necessarily -- subject i is itself at
   risk throughout [0, X_i), so the censoring KM's at-risk count never reaches 0
   before X_i and no factor of the product can vanish. */
real scalar _finegray_positivity_check(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Aden,
    real colvector Apool)
{
    real scalar n, nj, i, j, k, g, npos, ep, cur_time, last_cause
    real colvector is_cause, is_compete, flagged
    real colvector row_id, ord, entry_ord, riskn
    string scalar badstr

    n = rows(t)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :&
        (delta :== 1) :& (t :< max(select(t, is_cause)))
    last_cause = max(select(t, is_cause))

    /* The engine already needs this beta-independent bundle for optimization.
       Accept it here so the pre-fit guard does not build the same N-by-strata
       matrix and pooled stabilizer twice.  Standalone callers remain
       self-contained. */
    if (args() < 14) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, use_pooled, gidx, Gminus, Aden, Apool)
    }
    nj = cols(Aden)

    /* Under the equation-7 pooled-stabilizer form, every genuinely at-risk
       subject is divided by its group's A_g(t-), not just retained
       competing-event subjects by A_g(X_i-).  Check exactly those consulted
       denominator cells.  Inactive groups are deliberately ignored: 0/A_g
       never enters the scan. */
    if (use_pooled) {
        row_id = (1::n)
        ord = order((t, row_id), (1, 2))
        entry_ord = order((t0, row_id), (1, 2))
        riskn = J(nj, 1, 0)
        flagged = J(nj, 1, 0)
        npos = 0
        ep = 1
        i = 1
        while (i <= n) {
            cur_time = t[ord[i]]
            while (ep <= n) {
                if (t0[entry_ord[ep]] >= cur_time) break
                k = entry_ord[ep]
                if (t[k] >= cur_time) riskn[gidx[k]] = riskn[gidx[k]] + 1
                ep++
            }
            j = i
            while (j <= n) {
                if (t[ord[j]] != cur_time) break
                j++
            }
            for (k = i; k < j; k++) {
                if (!is_cause[ord[k]]) continue
                if (Apool[ord[k]] <= 0) {
                    npos++
                    for (g = 1; g <= nj; g++) {
                        if (riskn[g] > 0) flagged[g] = 1
                    }
                }
                for (g = 1; g <= nj; g++) {
                    if (riskn[g] <= 0) continue
                    if (Aden[ord[k], g] > 0) continue
                    npos++
                    flagged[g] = 1
                }
            }
            for (k = i; k < j; k++) {
                g = gidx[ord[k]]
                riskn[g] = riskn[g] - 1
            }
            i = j
        }
        for (i = 1; i <= n; i++) {
            if (!is_compete[i] | t[i] >= last_cause) continue
            if (Aden[i, gidx[i]] > 0) continue
            npos++
            flagged[gidx[i]] = 1
        }
        badstr = ""
        for (i = 1; i <= nj; i++) {
            if (!flagged[i]) continue
            if (badstr == "") badstr = strofreal(i)
            else              badstr = badstr + " " + strofreal(i)
        }
        st_local("_fg_posstrata", badstr)
        return(npos)
    }

    /* A_g(X_i-) in subject i's OWN joint group: the weight's denominator. */
    /* EXACTLY zero, not "below A_FLOOR".  Those are different failures and must
       stay different, or one silently eats the other:

         A == 0          the weight is UNDEFINED (Mata gives missing for x/0).
                         Nothing downstream can recover.  Hard r(459).
         0 < A < A_FLOOR the weight is defined but enormous.  The estimate is
                         computable and may be worth inspecting, so this is what
                         e(N_prob_warn)/e(N_weight_warn) are FOR.

       An earlier version of this check errored on `A <= A_FLOOR', which used the
       SAME 1e-10 threshold as the low-A warning -- so the fit aborted before the
       warning could ever fire, and the denominator half of the documented warning
       contract was unreachable dead code.  A warning you cannot reach is not a
       warning; it is a comment. */
    npos = 0
    flagged = J(nj, 1, 0)
    for (i = 1; i <= n; i++) {
        /* Only X_i < t_k subjects are retained at a later cause time. A zero
           denominator after the final cause event is never consulted. */
        if (!is_compete[i] | t[i] >= last_cause) continue
        if (Gminus[i] > 0) continue
        npos++
        flagged[gidx[i]] = 1
    }

    badstr = ""
    for (i = 1; i <= nj; i++) {
        if (!flagged[i]) continue
        if (badstr == "") badstr = strofreal(i)
        else              badstr = badstr + " " + strofreal(i)
    }
    st_local("_fg_posstrata", badstr)

    return(npos)
}

void _finegray_weight_diag_zzf(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real colvector gidx,
    real colvector Gminus,
    real matrix Aden,
    real colvector Apool)
{
    real scalar A_FLOOR, WT_CEIL, n, nj, K, i, j, k, g, ep, cur_time
    real scalar minprob, maxwt, nprobwarn, nwtwarn, a, w, p, _use
    real colvector is_cause, is_compete, row_id, ord, entry_ord
    real colvector et, erow, Pev, Pmax, riskn, flagged
    real matrix Aev, active
    string scalar warnstr

    A_FLOOR = 1e-10
    WT_CEIL = 1e6
    n = rows(t)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :&
        (delta :== 1) :& (t :< max(select(t, is_cause)))
    if (args() < 13) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, _use, gidx, Gminus, Aden, Apool)
    }
    nj = cols(Aden)
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))

    et = erow = J(0, 1, .)
    for (i = 1; i <= n; i++) {
        if (!is_cause[ord[i]]) continue
        if (rows(et) == 0) {
            et = t[ord[i]]
            erow = ord[i]
        }
        else if (t[ord[i]] != et[rows(et)]) {
            et = et \ t[ord[i]]
            erow = erow \ ord[i]
        }
    }
    K = rows(et)
    if (K == 0) {
        st_matrix("_finegray_nwstrata", nj)
        st_matrix("_finegray_minprob", .)
        st_matrix("_finegray_maxwt", .)
        st_matrix("_finegray_nprobwarn", 0)
        st_matrix("_finegray_nwtwarn", 0)
        st_local("_fg_warnstrata", "")
        return
    }

    Aev = Aden[erow, .]
    Pev = Apool[erow]
    active = J(K, nj, 0)
    riskn = J(nj, 1, 0)
    ep = 1
    k = 1
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            j = entry_ord[ep]
            if (t[j] >= cur_time) riskn[gidx[j]] = riskn[gidx[j]] + 1
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        if (k <= K) {
            if (et[k] == cur_time) {
                active[k, .] = riskn'
                k++
            }
        }
        for (g = i; g < j; g++) {
            riskn[gidx[ord[g]]] = riskn[gidx[ord[g]]] - 1
        }
        i = j
    }

    Pmax = J(K, 1, .)
    Pmax[K] = Pev[K]
    for (k = K - 1; k >= 1; k--) Pmax[k] = max((Pev[k], Pmax[k + 1]))
    minprob = .
    maxwt = .
    nprobwarn = 0
    nwtwarn = 0
    flagged = J(nj, 1, 0)
    for (k = 1; k <= K; k++) {
        p = Pev[k]
        if (p < minprob) minprob = p
        if (p < A_FLOOR) {
            nprobwarn++
            for (g = 1; g <= nj; g++) {
                if (active[k, g] > 0) flagged[g] = 1
            }
        }
        for (g = 1; g <= nj; g++) {
            if (active[k, g] <= 0) continue
            a = Aev[k, g]
            if (a < minprob) minprob = a
            if (a < A_FLOOR) {
                nprobwarn++
                flagged[g] = 1
            }
            if (a <= 0) continue
            w = p / a
            if (maxwt >= . | w > maxwt) maxwt = w
            if (w > WT_CEIL) {
                nwtwarn++
                flagged[g] = 1
            }
        }
    }

    k = 1
    for (i = 1; i <= n; i++) {
        j = ord[i]
        while (k <= K) {
            if (et[k] > t[j]) break
            k++
        }
        if (!is_compete[j] | k > K) continue
        g = gidx[j]
        a = Gminus[j]
        if (a < minprob) minprob = a
        if (a < A_FLOOR) {
            nprobwarn++
            flagged[g] = 1
        }
        if (a <= 0) continue
        w = Pmax[k] / a
        if (maxwt >= . | w > maxwt) maxwt = w
        if (w > WT_CEIL) {
            nwtwarn++
            flagged[g] = 1
        }
    }

    warnstr = ""
    for (g = 1; g <= nj; g++) {
        if (!flagged[g]) continue
        warnstr = warnstr + (warnstr == "" ? "" : " ") + strofreal(g)
    }
    st_matrix("_finegray_nwstrata", nj)
    st_matrix("_finegray_minprob", minprob)
    st_matrix("_finegray_maxwt", maxwt)
    st_matrix("_finegray_nprobwarn", nprobwarn)
    st_matrix("_finegray_nwtwarn", nwtwarn)
    st_local("_fg_warnstrata", warnstr)
}

void _finegray_weight_diag(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Aden,
    real colvector Apool)
{
    real scalar A_FLOOR, WT_CEIL
    real scalar n, nj, K, i, k, g, r, minprob, maxwt, nprobwarn, nwtwarn, w, a
    real colvector is_cause, is_compete, et, erow, flagged
    real colvector ord, row_id, cmin
    real matrix Aev, SUF
    string scalar warnstr

    if (args() < 14) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, use_pooled, gidx, Gminus, Aden, Apool)
    }

    if (use_pooled) {
        _finegray_weight_diag_zzf(t, delta, cause, censval, event_type,
            G, byg_id, t0, tg_id, gidx, Gminus, Aden, Apool)
        return
    }

    A_FLOOR = 1e-10
    WT_CEIL = 1e6

    n = rows(t)
    is_cause   = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    nj = cols(Aden)

    /* Cause-event times, ascending and unique. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    et = erow = J(0, 1, .)
    for (i = 1; i <= n; i++) {
        r = ord[i]
        if (!is_cause[r]) continue
        /* Mata's | does NOT short-circuit, so a combined test of the form
           "rows(et) == 0 | t[r] != et[rows(et)]" still evaluates et[0] on the
           first event and aborts with 3301.  Keep the bound test separate. */
        if (rows(et) == 0) {
            et = t[r]
            erow = r
            continue
        }
        if (t[r] != et[rows(et)]) {
            et = et \ t[r]
            erow = erow \ r
        }
    }
    K = rows(et)

    minprob   = .
    maxwt     = .
    nprobwarn = 0
    nwtwarn   = 0
    flagged   = J(nj, 1, 0)

    if (K == 0) {
        st_matrix("_finegray_nwstrata", nj)
        st_matrix("_finegray_minprob", .)
        st_matrix("_finegray_maxwt", .)
        st_matrix("_finegray_nprobwarn", 0)
        st_matrix("_finegray_nwtwarn", 0)
        st_local("_fg_warnstrata", "")
        return
    }

    /* A at the cause-event times (K x nj) and each subject's own denominator. */
    Aev = Aden[erow, .]

    /* cmin[g] = the EARLIEST competing exit in stratum g (missing if g holds no
       competing-event subject at all).  A numerator cell A_g(t_k) is consulted by
       the scan only once some competing subject in g has already exited, because
       until then the backward accumulator for g is exactly zero and Gt[., g] is
       multiplied by nothing.  Scanning every k instead would let a stratum whose A
       collapses in a tail it carries no competing mass into raise an alarm about a
       number the estimator never divides by. */
    cmin = J(nj, 1, .)
    for (i = 1; i <= n; i++) {
        if (!is_compete[i]) continue
        g = gidx[i]
        /* Missing is the LARGEST value in Mata, so the initial . needs no special
           case: the first competing exit in g always compares less than it. */
        if (t[i] < cmin[g]) cmin[g] = t[i]
    }

    /* Suffix maxima, ONCE per stratum: SUF[k, g] = max A_g over et[k..K].
       Each retained subject then reads its largest possible weight in O(1).
       Doing this per subject instead would be O(n*K) -- the very expansion the
       unexpanded scan exists to avoid. */
    SUF = J(K, nj, .)
    for (g = 1; g <= nj; g++) {
        if (cmin[g] >= .) continue          /* no competing mass: nothing consulted */

        SUF[K, g] = Aev[K, g]
        for (k = K - 1; k >= 1; k--) SUF[k, g] = max((Aev[k, g], SUF[k + 1, g]))

        /* Numerator cells consulted in stratum g: event times strictly after the
           earliest competing exit in g.  This restriction is the code, not just
           the comment -- an unrestricted k = 1..K loop counts cells the scan
           never reaches. */
        for (k = 1; k <= K; k++) {
            if (et[k] <= cmin[g]) continue
            a = Aev[k, g]
            if (a >= .) continue
            if (a < minprob) minprob = a
            if (a < A_FLOOR) {
                nprobwarn++
                flagged[g] = 1
            }
        }
    }

    /* Denominators and retained weights.  Walk subjects in ASCENDING time so the
       pointer k -- the first cause-event time strictly after the current exit --
       only ever moves forward: O(n + K), not O(n*K). */
    k = 1
    for (i = 1; i <= n; i++) {
        r = ord[i]

        /* Advance to the first cause-event time strictly after this exit.  Mata's
           & does NOT short-circuit, so the bound test must be its own statement:
           a combined "k <= K & et[k] <= t[r]" evaluates et[K+1] and aborts. */
        while (k <= K) {
            if (et[k] > t[r]) break
            k++
        }

        if (!is_compete[r]) continue

        /* No cause event outlives this subject: it is never weighted into any
           risk set, so its A(X_i-) is not consulted and must not raise an alarm. */
        if (k > K) continue

        g = gidx[r]
        a = Gminus[r]
        if (a >= .) continue

        if (a < minprob) minprob = a
        if (a < A_FLOOR) {
            nprobwarn++
            flagged[g] = 1
        }
        if (a <= 0) continue

        w = SUF[k, g] / a
        if (maxwt >= . | w > maxwt) maxwt = w
        if (w > WT_CEIL) {
            nwtwarn++
            flagged[g] = 1
        }
    }

    warnstr = ""
    for (g = 1; g <= nj; g++) {
        if (!flagged[g]) continue
        warnstr = warnstr + (warnstr == "" ? "" : " ") + strofreal(g)
    }

    st_matrix("_finegray_nwstrata", nj)
    st_matrix("_finegray_minprob", minprob)
    st_matrix("_finegray_maxwt", maxwt)
    st_matrix("_finegray_nprobwarn", nprobwarn)
    st_matrix("_finegray_nwtwarn", nwtwarn)

    /* The flagged group codes are a STRING, so they cannot ride back in a matrix.
       st_local writes into the calling ado's scope.  st_global would not work
       here: a Stata macro of that kind may not begin with an underscore (the
       assignment is rejected with r(198)), and any name that IS accepted could
       collide with one the user already set. */
    st_local("_fg_warnstrata", warnstr)
}

/* Canonical stratified ZZF equation (7): pooled A(t) stabilizer,
   stratum-specific A_g(.) denominators.  Risk-set sums are maintained on the
   denominator scale; the pooled factor cancels from S1/S0 but remains as the
   outer cause-event weight in the estimating equation. */
real scalar _finegray_loglik_zzf_strat(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    real colvector gidx,
    real colvector Gminus,
    real matrix Aden,
    real colvector Apool)
{
    real colvector row_id, eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector riskn
    real scalar n, i, j, k, idx, cur_time, ep, g, ng, coreS0, ew, ll
    real rowvector risk0, bwd0

    n = rows(t)
    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    ng = cols(Aden)

    risk0 = J(1, ng, 0)
    /* Activity is combinatorial, not numerical.  Entry and exit traverse
       different orders, so a weighted sum can retain a tiny positive residue
       after its last subject exits; riskn prevents that empty stratum from
       consulting A_g(t). */
    riskn = J(ng, 1, 0)
    bwd0 = J(1, ng, 0)
    ep = 1
    ll = 0
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                g = gidx[idx]
                risk0[g] = risk0[g] + expeta[idx]
                riskn[g] = riskn[g] + 1
            }
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                coreS0 = bwd0 * J(ng, 1, 1)
                for (g = 1; g <= ng; g++) {
                    if (riskn[g] > 0) coreS0 = coreS0 + risk0[g] / Aden[idx, g]
                }
                ew = Apool[idx] / Aden[idx, gidx[idx]]
                ll = ll + ew * (eta[idx] - log(Apool[idx] * coreS0))
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                g = gidx[idx]
                bwd0[g] = bwd0[g] + expeta[idx] / Gminus[idx]
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            risk0[g] = risk0[g] - expeta[idx]
            riskn[g] = riskn[g] - 1
        }
        i = j
    }
    return(ll)
}

void _finegray_score_info_zzf_strat(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector score,
    real matrix info,
    real colvector t0,
    real colvector tg_id,
    | real colvector gidx,
    real colvector Gminus,
    real matrix Aden,
    real colvector Apool)
{
    real colvector row_id, eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector riskn
    real scalar n, p, i, j, k, idx, cur_time, ep, g, ng, coreS0, ew, _use
    real rowvector risk0, bwd0, coreS1, zbar
    real matrix risk1, bwd1, risk2, bwd2, coreS2

    n = rows(t)
    p = cols(Z)
    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    if (args() < 17) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, _use, gidx, Gminus, Aden, Apool)
    }
    ng = cols(Aden)

    risk0 = J(1, ng, 0)
    riskn = J(ng, 1, 0)
    risk1 = J(ng, p, 0)
    risk2 = J(ng, p * p, 0)
    bwd0 = J(1, ng, 0)
    bwd1 = J(ng, p, 0)
    bwd2 = J(ng, p * p, 0)
    score = J(p, 1, 0)
    info = J(p, p, 0)
    ep = 1
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                g = gidx[idx]
                risk0[g] = risk0[g] + expeta[idx]
                riskn[g] = riskn[g] + 1
                risk1[g, .] = risk1[g, .] + expeta[idx] * Z[idx, .]
                risk2[g, .] = risk2[g, .] +
                    vec(expeta[idx] * (Z[idx, .]' * Z[idx, .]))'
            }
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                coreS0 = 0
                coreS1 = J(1, p, 0)
                coreS2 = J(p, p, 0)
                for (g = 1; g <= ng; g++) {
                    coreS0 = coreS0 + bwd0[g]
                    coreS1 = coreS1 + bwd1[g, .]
                    coreS2 = coreS2 + rowshape(bwd2[g, .], p)
                    if (riskn[g] > 0) {
                        coreS0 = coreS0 + risk0[g] / Aden[idx, g]
                        coreS1 = coreS1 + risk1[g, .] / Aden[idx, g]
                        coreS2 = coreS2 + rowshape(risk2[g, .], p) / Aden[idx, g]
                    }
                }
                zbar = coreS1 / coreS0
                ew = Apool[idx] / Aden[idx, gidx[idx]]
                score = score + ew * (Z[idx, .] - zbar)'
                info = info + ew * (coreS2 / coreS0 - zbar' * zbar)
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                g = gidx[idx]
                bwd0[g] = bwd0[g] + expeta[idx] / Gminus[idx]
                bwd1[g, .] = bwd1[g, .] + expeta[idx] / Gminus[idx] * Z[idx, .]
                bwd2[g, .] = bwd2[g, .] +
                    vec(expeta[idx] / Gminus[idx] * (Z[idx, .]' * Z[idx, .]))'
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            risk0[g] = risk0[g] - expeta[idx]
            riskn[g] = riskn[g] - 1
            risk1[g, .] = risk1[g, .] - expeta[idx] * Z[idx, .]
            risk2[g, .] = risk2[g, .] -
                vec(expeta[idx] * (Z[idx, .]' * Z[idx, .]))'
        }
        i = j
    }
}

real matrix _finegray_scores_zzf_strat(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real colvector gidx,
    real colvector Gminus,
    real matrix Aden,
    real colvector Apool)
{
    real colvector row_id, eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector entry_rinv, exit_rinv, exit_cinv
    real colvector riskn
    real scalar n, p, i, j, k, idx, cur_time, ep, g, ng, coreS0, ew, run_cinv
    real scalar _use
    real rowvector risk0, bwd0, coreS1, zbar, run_cz
    real matrix risk1, bwd1, scores, run_rz, entry_rz, exit_rz, exit_cz
    real rowvector run_rinv

    n = rows(t)
    p = cols(Z)
    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :&
        (delta :== 1) :& (t :< max(select(t, is_cause)))
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    if (args() < 15) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, _use, gidx, Gminus, Aden, Apool)
    }
    ng = cols(Aden)

    risk0 = J(1, ng, 0)
    riskn = J(ng, 1, 0)
    risk1 = J(ng, p, 0)
    bwd0 = J(1, ng, 0)
    bwd1 = J(ng, p, 0)
    scores = J(n, p, 0)
    run_rinv = J(1, ng, 0)
    run_rz = J(ng, p, 0)
    entry_rinv = J(n, 1, 0)
    entry_rz = J(n, p, 0)
    exit_rinv = J(n, 1, 0)
    exit_rz = J(n, p, 0)
    run_cinv = 0
    run_cz = J(1, p, 0)
    exit_cinv = J(n, 1, 0)
    exit_cz = J(n, p, 0)
    ep = 1
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                g = gidx[idx]
                risk0[g] = risk0[g] + expeta[idx]
                riskn[g] = riskn[g] + 1
                risk1[g, .] = risk1[g, .] + expeta[idx] * Z[idx, .]
                entry_rinv[idx] = run_rinv[g]
                entry_rz[idx, .] = run_rz[g, .]
            }
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                coreS0 = 0
                coreS1 = J(1, p, 0)
                for (g = 1; g <= ng; g++) {
                    coreS0 = coreS0 + bwd0[g]
                    coreS1 = coreS1 + bwd1[g, .]
                    if (riskn[g] > 0) {
                        coreS0 = coreS0 + risk0[g] / Aden[idx, g]
                        coreS1 = coreS1 + risk1[g, .] / Aden[idx, g]
                    }
                }
                zbar = coreS1 / coreS0
                ew = Apool[idx] / Aden[idx, gidx[idx]]
                scores[idx, .] = scores[idx, .] + ew * (Z[idx, .] - zbar)
                run_cinv = run_cinv + ew / coreS0
                run_cz = run_cz + ew * zbar / coreS0
                for (g = 1; g <= ng; g++) {
                    /* A stratum with no natural at-risk subject contributes
                       exactly zero here.  Its A_g(t) may also be zero: touching
                       1/A_g(t) would manufacture missing score rows from a cell
                       the estimating equation never consults. */
                    if (riskn[g] <= 0) continue
                    run_rinv[g] = run_rinv[g] + ew / (Aden[idx, g] * coreS0)
                    run_rz[g, .] = run_rz[g, .] +
                        ew * zbar / (Aden[idx, g] * coreS0)
                }
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            exit_rinv[idx] = run_rinv[g]
            exit_rz[idx, .] = run_rz[g, .]
            exit_cinv[idx] = run_cinv
            exit_cz[idx, .] = run_cz
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                g = gidx[idx]
                bwd0[g] = bwd0[g] + expeta[idx] / Gminus[idx]
                bwd1[g, .] = bwd1[g, .] + expeta[idx] / Gminus[idx] * Z[idx, .]
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            risk0[g] = risk0[g] - expeta[idx]
            riskn[g] = riskn[g] - 1
            risk1[g, .] = risk1[g, .] - expeta[idx] * Z[idx, .]
        }
        i = j
    }

    for (i = 1; i <= n; i++) {
        scores[i, .] = scores[i, .] - expeta[i] *
            (Z[i, .] * (exit_rinv[i] - entry_rinv[i]) -
             (exit_rz[i, .] - entry_rz[i, .]))
        if (is_compete[i]) {
            scores[i, .] = scores[i, .] - expeta[i] / Gminus[i] *
                (Z[i, .] * (run_cinv - exit_cinv[i]) -
                 (run_cz - exit_cz[i, .]))
        }
    }
    return(scores)
}

/* Log pseudo-likelihood via incremental risk-set scan with Breslow ties.
   Supports left truncation via entry-time pointer. */
real scalar _finegray_loglik(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector w)
{
    real colvector row_id, ordk, entry_ordk, bslev, bscode
    real scalar n, p, i, j, k, ll, idx, cur_time, g, ng
    real scalar risk_S0, ep, nk, kk, K
    real colvector eta, expeta, wexpeta, is_cause, is_compete, ord, entry_ord
    real rowvector raw_bwd

    if (args() < 17) bsraw = J(rows(t), 1, 1)
    if (args() < 18) w = J(rows(t), 1, 1)

    if (args() < 16) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
    }

    if (use_pooled) {
        return(_finegray_loglik_zzf_strat(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, t0, tg_id, gidx, Gminus, Gt,
            Apool))
    }

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    /* Per-subject design weight (pweight/fweight).  It multiplies every
       risk-set contribution and every event's outer term: Wogu et al. (2021)
       eq. (3), p.167 -- the ordinary Fine-Gray score with rho_i on each
       subject's exp(eta) in S^(d).  w :* expeta with w == 1 is exact, so the
       unweighted fit is bit-identical to the pre-weight scan. */
    wexpeta = w :* expeta
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    /* Deterministic tie-break by row index.  Mata's order() resolves ties
       using Stata's sort seed, which ADVANCES on every sort, so a tied key
       (every t0 == 0 when there is no delayed entry) yields a different
       permutation on each call -- and the risk-set scan then accumulates in
       a different floating-point order.  Without this the same command on
       the same data is not bit-reproducible. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    /* ZZF: Gt is A = G(t-)H(t-) on CROSS-CLASSIFIED strata.  With no delayed
       entry H == 1 and this is bit-identical to the former G-only path. */
    ng = cols(Gt)

    _finegray_bs_setup(bsraw, bslev, bscode, K)

    ll = 0

    /* bstrata(): the log pseudo-likelihood is the SUM of independent
       within-stratum terms (Zhou et al. 2011), so each stratum gets its own
       risk set, its own retained-competing accumulator, and its own entry
       pointer.  With K == 1 the loop runs once over the untouched ord. */
    for (kk = 1; kk <= K; kk++) {
        ordk = _finegray_bs_rows(ord, bscode, kk, K)
        entry_ordk = _finegray_bs_rows(entry_ord, bscode, kk, K)
        nk = length(ordk)
        if (nk == 0) continue

        /* Incremental risk-set tracking */
        risk_S0 = 0
        ep = 1
        raw_bwd = J(1, ng, 0)
        i = 1

        while (i <= nk) {
            cur_time = t[ordk[i]]

            /* Add entries: subjects with t0 < cur_time AND t >= cur_time */
            while (ep <= nk) {
                if (t0[entry_ordk[ep]] >= cur_time) break
                if (t[entry_ordk[ep]] >= cur_time) {
                    risk_S0 = risk_S0 + wexpeta[entry_ordk[ep]]
                }
                ep++
            }

            /* Find end of this time group */
            j = i
            while (j <= nk) {
                if (t[ordk[j]] != cur_time) break
                j++
            }

            /* Process all cause events at this time (Breslow) */
            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_cause[idx]) {
                    ll = ll + w[idx] * eta[idx] -
                        w[idx] * log(risk_S0 + Gt[idx, .] * raw_bwd')
                }
            }

            /* AFTER processing cause events, add competing events to backward */
            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_compete[idx]) {
                    g = gidx[idx]
                    raw_bwd[g] = raw_bwd[g] + wexpeta[idx] / Gminus[idx]
                }
            }

            /* Remove exiting subjects from risk set */
            for (k = i; k < j; k++) {
                risk_S0 = risk_S0 - wexpeta[ordk[k]]
            }

            i = j
        }
    }

    return(ll)
}

/* Score vector and observed information via incremental risk-set scan.
   Supports left truncation. */
void _finegray_score_info(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector score,
    real matrix info,
    real colvector t0,
    real colvector tg_id,
    | real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector w)
{
    real colvector row_id, ordk, entry_ordk, bslev, bscode
    real scalar n, p, i, j, k, idx, S0_total, cur_time
    real scalar risk_S0, ep, g, ng, nk, kk, K
    real colvector eta, expeta, wexpeta, is_cause, is_compete, ord, entry_ord
    real matrix bwd_s1_raw, bwd_s2_raw, S2_total, risk_S2
    real rowvector bwd_s0_raw, S1_total, z_bar, risk_S1

    if (args() < 19) bsraw = J(rows(t), 1, 1)
    if (args() < 20) w = J(rows(t), 1, 1)

    if (args() < 18) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
    }

    if (use_pooled) {
        _finegray_score_info_zzf_strat(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, score, info, t0, tg_id,
            gidx, Gminus, Gt, Apool)
        return
    }

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    wexpeta = w :* expeta
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    /* Deterministic tie-break by row index.  Mata's order() resolves ties
       using Stata's sort seed, which ADVANCES on every sort, so a tied key
       (every t0 == 0 when there is no delayed entry) yields a different
       permutation on each call -- and the risk-set scan then accumulates in
       a different floating-point order.  Without this the same command on
       the same data is not bit-reproducible. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    /* ZZF: Gt is A = G(t-)H(t-) on CROSS-CLASSIFIED strata.  With no delayed
       entry H == 1 and this is bit-identical to the former G-only path. */
    ng = cols(Gt)

    _finegray_bs_setup(bsraw, bslev, bscode, K)

    score = J(p, 1, 0)
    info = J(p, p, 0)

    /* bstrata(): score and information are sums of independent within-stratum
       contributions, so they accumulate ACROSS the loop while every risk-set
       state is rebuilt per stratum. */
    for (kk = 1; kk <= K; kk++) {
        ordk = _finegray_bs_rows(ord, bscode, kk, K)
        entry_ordk = _finegray_bs_rows(entry_ord, bscode, kk, K)
        nk = length(ordk)
        if (nk == 0) continue

        /* Incremental risk-set sums */
        risk_S0 = 0
        risk_S1 = J(1, p, 0)
        risk_S2 = J(p, p, 0)
        ep = 1

        bwd_s0_raw = J(1, ng, 0)
        bwd_s1_raw = J(ng, p, 0)
        bwd_s2_raw = J(ng, p * p, 0)

        i = 1
        while (i <= nk) {
            cur_time = t[ordk[i]]

            /* Add entries: (t0, t] means t0 < cur_time */
            while (ep <= nk) {
                if (t0[entry_ordk[ep]] >= cur_time) break
                idx = entry_ordk[ep]
                if (t[idx] >= cur_time) {
                    risk_S0 = risk_S0 + wexpeta[idx]
                    risk_S1 = risk_S1 + wexpeta[idx] * Z[idx, .]
                    risk_S2 = risk_S2 + wexpeta[idx] * (Z[idx, .]' * Z[idx, .])
                }
                ep++
            }

            j = i
            while (j <= nk) {
                if (t[ordk[j]] != cur_time) break
                j++
            }

            /* Process cause events at this time */
            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_cause[idx]) {
                    S0_total = risk_S0 + Gt[idx, .] * bwd_s0_raw'
                    S1_total = risk_S1 + Gt[idx, .] * bwd_s1_raw
                    S2_total = risk_S2
                    for (g = 1; g <= ng; g++) {
                        S2_total = S2_total + Gt[idx, g] *
                            rowshape(bwd_s2_raw[g, .], p)
                    }

                    z_bar = S1_total / S0_total

                    /* w[idx] on the event's own term; the association
                       (info + w*S2/S0) - w*zbar'zbar keeps the w == 1
                       arithmetic bit-identical to the unweighted line. */
                    score = score + (w[idx] * (Z[idx, .] - z_bar))'
                    info = info + (w[idx] * S2_total) / S0_total -
                        w[idx] * (z_bar' * z_bar)
                }
            }

            /* Add competing events to backward */
            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_compete[idx]) {
                    g = gidx[idx]
                    bwd_s0_raw[g] = bwd_s0_raw[g] + wexpeta[idx] / Gminus[idx]
                    bwd_s1_raw[g, .] = bwd_s1_raw[g, .] +
                        wexpeta[idx] / Gminus[idx] * Z[idx, .]
                    bwd_s2_raw[g, .] = bwd_s2_raw[g, .] +
                        vec(wexpeta[idx] / Gminus[idx] *
                        (Z[idx, .]' * Z[idx, .]))'
                }
            }

            /* Remove exiting subjects */
            for (k = i; k < j; k++) {
                idx = ordk[k]
                risk_S0 = risk_S0 - wexpeta[idx]
                risk_S1 = risk_S1 - wexpeta[idx] * Z[idx, .]
                risk_S2 = risk_S2 - wexpeta[idx] * (Z[idx, .]' * Z[idx, .])
            }

            i = j
        }
    }
}

/* Per-subject score (efficient-score) residuals for the Fine-Gray model,
   including the IPCW at-risk correction for competing-event subjects.
   Returns an n x p matrix whose rows are the U_i; sum_i U_i U_i' is the meat
   of the sandwich.  Extracted so both the robust variance and the CIF
   influence-function variance use one definition (coefficient SEs unchanged).

   Left truncation: subject i's natural at-risk window is [t0_i, T_i], so the
   at-risk contribution sums only over cause-event times inside that window.
   The cumulative sums are captured twice per subject: at entry (events with
   T_m < t0_i, recorded when the entry pointer admits the subject) and at exit
   (events with T_m <= T_i); the difference is the window sum. */
real matrix _finegray_score_residuals(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector w)
{
    real colvector row_id, ordk, entry_ordk, bslev, bscode, rowsk
    real scalar n, p, i, j, k, idx, running_invS0
    real scalar S0_t, cur_time, risk_S0, ep, g, ng, nk, nrk, kk, K, r
    real colvector eta, expeta, wexpeta, is_cause, is_compete, ord, entry_ord
    real colvector cum_invS0, cum_ginvS0, entry_invS0
    real matrix scores, cum_zbars, cum_gzbars, entry_zbars
    real matrix bwd_s1_raw, running_gzbars
    real rowvector bwd_s0_raw, running_zbar_sum, z_bar_t, S1_t, risk_S1
    real rowvector running_ginvS0, total_ginvS0, total_gzbars

    if (args() < 17) bsraw = J(rows(t), 1, 1)
    if (args() < 18) w = J(rows(t), 1, 1)

    if (args() < 16) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
    }

    if (use_pooled) {
        return(_finegray_scores_zzf_strat(t, delta, cause,
            censval, event_type, Z, beta, G, byg_id, t0, tg_id, gidx,
            Gminus, Gt, Apool))
    }

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    /* Design weights.  The risk-set sums and the Breslow increments carry
       w (S0, S1 and the per-event d/S0 running sums below); the subject's
       OWN outer factor w_i is NOT applied here.  What is returned is s_i,
       the residual per unit weight; _finegray_robust_var forms the meat
       as sum_i (w_i s_i)^(x)2 for pweights and sum_i w_i s_i^(x)2 for
       fweights, and _finegray_cif_core scales its influence function by
       w_i the same way.  Keeping the outer weight out of this matrix is
       what lets one residual serve both weight types. */
    wexpeta = w :* expeta
    is_cause = (event_type :== cause) :& (delta :== 1)
    /* The last cause-event time is taken over the WHOLE sample, not within the
       baseline stratum.  A competing subject past its own stratum's last cause
       event contributes an exactly zero correction anyway (the reverse sums it
       multiplies are empty), so the pooled bound changes no number -- and
       keeping it pooled is what makes the K = 1 case bit-identical. */
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :&
        (delta :== 1) :& (t :< max(select(t, is_cause)))

    /* Deterministic tie-break by row index.  Mata's order() resolves ties
       using Stata's sort seed, which ADVANCES on every sort, so a tied key
       (every t0 == 0 when there is no delayed entry) yields a different
       permutation on each call -- and the risk-set scan then accumulates in
       a different floating-point order.  Without this the same command on
       the same data is not bit-reproducible. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    /* ZZF: Gt is A = G(t-)H(t-) on CROSS-CLASSIFIED strata.  With no delayed
       entry H == 1 and this is bit-identical to the former G-only path. */
    ng = cols(Gt)

    _finegray_bs_setup(bsraw, bslev, bscode, K)

    scores = J(n, p, 0)
    cum_zbars = J(n, p, 0)
    cum_invS0 = J(n, 1, 0)
    entry_invS0 = J(n, 1, 0)
    entry_zbars = J(n, p, 0)
    cum_ginvS0 = J(n, 1, 0)
    cum_gzbars = J(n, p, 0)

    /* bstrata(): every quantity below is a within-stratum running sum, and the
       two post-scan corrections consume that stratum's own totals -- so they
       run inside the stratum loop rather than once over all rows.  The
       residuals themselves are written back by ORIGINAL row index, which is why
       _finegray_robust_var / _finegray_cluster_sums need no change: the meat is
       still sum over subjects of a per-subject score residual. */
    for (kk = 1; kk <= K; kk++) {
        ordk = _finegray_bs_rows(ord, bscode, kk, K)
        entry_ordk = _finegray_bs_rows(entry_ord, bscode, kk, K)
        nk = length(ordk)
        if (nk == 0) continue
        if (K <= 1) rowsk = row_id
        else        rowsk = selectindex(bscode :== kk)
        nrk = length(rowsk)

        risk_S0 = 0
        risk_S1 = J(1, p, 0)
        ep = 1

        bwd_s0_raw = J(1, ng, 0)
        bwd_s1_raw = J(ng, p, 0)
        running_invS0 = 0
        running_zbar_sum = J(1, p, 0)

        running_ginvS0 = J(1, ng, 0)
        running_gzbars = J(ng, p, 0)

        i = 1
        while (i <= nk) {
            cur_time = t[ordk[i]]

            while (ep <= nk) {
                if (t0[entry_ordk[ep]] >= cur_time) break
                idx = entry_ordk[ep]
                if (t[idx] >= cur_time) {
                    risk_S0 = risk_S0 + wexpeta[idx]
                    risk_S1 = risk_S1 + wexpeta[idx] * Z[idx, .]
                    /* cur_time is the first observation time strictly after
                       t0[idx], so the running sums at admission are exactly the
                       sums over cause-event times T_m <= t0[idx] -- the events the
                       subject's (t0, t] window must EXCLUDE. */
                    entry_invS0[idx] = running_invS0
                    entry_zbars[idx, .] = running_zbar_sum
                }
                ep++
            }

            j = i
            while (j <= nk) {
                if (t[ordk[j]] != cur_time) break
                j++
            }

            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_cause[idx]) {
                    S0_t = risk_S0 + Gt[idx, .] * bwd_s0_raw'
                    S1_t = risk_S1 + Gt[idx, .] * bwd_s1_raw
                    z_bar_t = S1_t / S0_t

                    scores[idx, .] = Z[idx, .] - z_bar_t
                    running_invS0 = running_invS0 + w[idx] / S0_t
                    running_zbar_sum = running_zbar_sum + w[idx] * z_bar_t / S0_t
                    for (g = 1; g <= ng; g++) {
                        running_ginvS0[g] = running_ginvS0[g] +
                            w[idx] * Gt[idx, g] / S0_t
                        running_gzbars[g, .] = running_gzbars[g, .] +
                            w[idx] * Gt[idx, g] * z_bar_t / S0_t
                    }
                }
            }

            for (k = i; k < j; k++) {
                idx = ordk[k]
                cum_invS0[idx] = running_invS0
                cum_zbars[idx, .] = running_zbar_sum
                g = gidx[idx]
                cum_ginvS0[idx] = running_ginvS0[g]
                cum_gzbars[idx, .] = running_gzbars[g, .]
            }

            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_compete[idx]) {
                    g = gidx[idx]
                    bwd_s0_raw[g] = bwd_s0_raw[g] + wexpeta[idx] / Gminus[idx]
                    bwd_s1_raw[g, .] = bwd_s1_raw[g, .] +
                        wexpeta[idx] / Gminus[idx] * Z[idx, .]
                }
            }

            for (k = i; k < j; k++) {
                idx = ordk[k]
                risk_S0 = risk_S0 - wexpeta[idx]
                risk_S1 = risk_S1 - wexpeta[idx] * Z[idx, .]
            }

            i = j
        }

        /* Subtract the at-risk contribution for all subjects, restricted to each
           subject's own risk window (t0_i, T_i] (entry-to-exit difference) */
        for (r = 1; r <= nrk; r++) {
            i = rowsk[r]
            scores[i, .] = scores[i, .] - expeta[i] *
                (Z[i, .] * (cum_invS0[i] - entry_invS0[i]) -
                 (cum_zbars[i, .] - entry_zbars[i, .]))
        }

        /* IPCW at-risk correction for competing-event subjects */
        total_ginvS0 = running_ginvS0
        for (r = 1; r <= nrk; r++) {
            i = rowsk[r]
            if (is_compete[i]) {
                g = gidx[i]
                total_gzbars = running_gzbars[g, .]
                scores[i, .] = scores[i, .] -
                    (expeta[i] / Gminus[i]) *
                    (Z[i, .] * (total_ginvS0[g] - cum_ginvS0[i]) -
                     (total_gzbars - cum_gzbars[i, .]))
            }
        }
    }

    return(scores)
}

/* ------------------------------------------------------------------------
   psi_i -- Fine & Gray (1999) eq. (7)-(8), p.500.

   eta_i (above) is the score's i.i.d. contribution treating the censoring
   survivor G as KNOWN.  psi_i is the SECOND term: the contribution from
   having ESTIMATED G by Kaplan-Meier.  The full sandwich meat is
   sum_i (eta_i + psi_i)^{(x)2}; using eta alone may understate or overstate
   the variance because eta and psi are correlated. See FG 1999 sec. 4,
   pp.500-501.

       psi_i = integral_0^{X_i} { q_g(u) / Y_g(u) } dMc_i(u)
             = 1{eps_i = 0} q_g(X_i)/Y_g(X_i)
               - sum_{u <= X_i} dNc_g(u) q_g(u) / Y_g(u)^2

   with g = i's censoring stratum, Y_g(u) = #{j in g : X_j >= u}, and

       q_g(t) = sum_{s >= t, s an event time FROM GROUP g} d_s^g
                  [ S1_2^g(s,t) - zbar(s) S0_2^g(s,t) ] / S0(s)
       S0_2^g(s,t) = sum_{X_j < t, eps_j = 2, g(j) = g}
                        exp(eta_j) Ghat_g(s-)/Ghat_g(X_j-)

   THREE THINGS THAT ARE EASY TO GET WRONG, each verified against
   cmprsk's Fortran crrvv (written by R.J. Gray, FG's second author) and
   proven by fixtures in qa/:

   1. BOTH sums in q are group-restricted.  crr.f:379 accumulates into
      qu(., icg(j1)) -- the group of the EVENT subject -- so a cause-1 event
      in group A contributes only to q_A.  S0(s) and zbar(s) stay GLOBAL.
      Restricting only the inner competing-event sum passes every
      single-stratum fixture and fails at ~1e-3 with strata().
   2. TIE MULTIPLICITY.  A time carrying d tied cause-1 events contributes
      d times (Breslow); crr.f loops over event SUBJECTS, not distinct event
      times.  Dropping it is invisible without tied events and >100% wrong
      with them.
   3. Ghat is the LEFT limit Ghat(t-) throughout, which is what
      _finegray_G_at_times already returns (it advances on strict <).

   RIGHT CENSORING ONLY.  Li/Scheike/Zhang (2015) and FG (1999) eq. (7)-(8)
   are both derived without entry times; the delayed-entry analogue is the
   ZZF (2011) Appendix B term, which we do not hold.  The caller must not
   reach here with t0 > 0; this function errors rather than returning a
   quantity whose derivation does not cover the data.

   Complexity is O(n * p * ng), not O(n^2): q factorises as
   q_g(t) = B1_g(t) C0_g(t) - B0_g(t) C1_g(t), where B is a forward running
   sum over competing events and C a reverse running sum over event times.

   BASELINE STRATA -- bstrata() -- added 2026-08-26.
   Zhou, Latouche, Rocha & Fine (2011) sec. 4.1: "the details of eta_ki and
   psi_ki for each k are omitted here because they are IDENTICAL to eta_i and
   psi_i in [Fine & Gray 1999], with the added subscript k", and
   Sigma_r = sum_k Sigma_rk.  The authors' own crrSC::crrs implements exactly
   that and nothing more: crrvvs() subsets the data to one stratum, calls
   cmprsk's UNMODIFIED crrvv on it, and sums the two matrices over strata.

   So the whole change is an index.  Every RISK-SET quantity gains a k:

       bwd_s0[g,k]   = sum_{j2 competing, t_j2 < u, g(j2)=g, k(j2)=k}
                          exp(eta_j2) / Ghat_g(t_j2-)
       C0[u,g,k]     = sum_{j1 cause, t_j1 >= u, g(j1)=g, k(j1)=k}
                          Ghat_g(t_j1-) / S0_k(t_j1)
       C1[u,g,k,.]   = same, weighted by zbar_k(t_j1)
       q[g,k,.]      = bwd_s1[g,k,.] C0[u,g,k] - bwd_s0[g,k] C1[u,g,k,.]
       q_g(u)        = sum_k q[g,k,.]

   while every CENSORING-KM quantity stays on the g axis untouched: Y_g and
   dN^c_g are properties of Ghat_g's estimation, not of the score.  S0_k and
   zbar_k are the STRATUM's risk-set totals, which is the only thing that was
   pooled before.

   Two reductions make this checkable rather than merely plausible:

     K == 1  is bit-identical to the pre-bstrata term, not close to it.  Every
             k index is 1, (g-1)*K+k is g, S0_1 IS the pooled S0, and the
             K == 1 branches below are written to keep the floating-point
             ACCUMULATION ORDER identical (colsum for the initial totals; qsum
             aliased to qg with no arithmetic).  Asserted, not assumed.
     g == k  (i.e. bstrata(c) strata(c), crrs ctype=1) collapses q[g,k] to
             k = g, whose j1/j2 sets are exactly stratum g's rows, with S0_g,
             zbar_g, Y_g and Ghat_g -- which is crrvv run on stratum g and
             summed.  That is the EXTERNAL check, crossval_bstrata.do.

   bstrata(c) WITHOUT strata(c) is a stratified baseline with a pooled Ghat.
   crrs has no such cell: its ctype=2 is not this estimator but Zhou sec. 4.2's
   highly-stratified variance, a different derivation (a different C routine,
   crrvvh) whose displays are extraction losses in the corpus.  The pooled-G
   cell here is therefore the PACKAGE'S OWN composition of sourced parts --
   Zhou's additivity over strata, FG's eq. (8) -- and is documented as such in
   Methods and formulas.  It is validated by simulation (SE calibration and CI
   coverage) and by the two reductions above, not by an external oracle.
   ------------------------------------------------------------------------ */
real matrix _finegray_psi_residuals(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    | real colvector bsraw,
    real colvector censtrue)
{
    real scalar n, p, ng, i, j, k, g, idx, it, nt, S0_t, cur_time
    real scalar cS0, dNc_g, K, kk, gk, ngk
    real colvector row_id, ord, gidx, levels, eta, expeta
    real colvector is_cause, is_compete, is_cens, Gminus, Yg
    real colvector bslev, bscode, risk_S0
    real matrix Gt, psi, Zbar, Dg, Gg, C0, C1, cumL, bwd_s0, bwd_s1, qg, qsum
    real matrix S0arr, risk_S1
    real rowvector S1_t, z_bar_t, c1row

    n = rows(t)
    p = cols(Z)

    if (args() < 11) bsraw = J(n, 1, 1)
    _finegray_bs_setup(bsraw, bslev, bscode, K)
    if (K < 1) {
        K = 1
        bscode = J(n, 1, 1)
    }

    if (colmax(t0) > 0) {
        errprintf("finegray: psi (FG 1999 eq. 7-8) is derived for right ")
        errprintf("censoring only;\n")
        errprintf("       it is not defined under delayed entry\n")
        exit(error(198))
    }

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :&
        (delta :== 1)
    /* THE CENSORING SET IS NOT READ OFF event_type WHEN THE CALLER SUPPLIES
       ONE.  Under tvc() the caller hands this function interval j's MASKED
       event vector, in which every cause event outside interval j has been
       relabelled to the censoring CODE.  That relabelling is right for
       is_cause (interval j's pass must see only its own cause events) and
       harmless for is_compete (a cause event is not a competing event either
       way).  It is WRONG for is_cens, because the censoring set here is not a
       modelling device: it is the support of the censoring counting process
       N^c, which is what Ghat was estimated from and what its influence
       function integrates against.  Ghat itself is computed once from the real
       data and passed in, so a pass that invented extra censoring events would
       be differentiating a Ghat that was never estimated that way -- inflating
       dNc_g and handing every out-of-interval cause event a +q/Y term it has
       no claim to.

       Measured before the fix, against cmprsk::crr's own eq. (7)-(8) variance
       on the crossval_tvc fixtures: 2.0e-05 / 4.9e-05 / 1.9e-05 relative, i.e.
       small enough to look like optimizer noise beside the eta-only arm's
       1.4e-04, and three orders worse than the same psi machinery reaches
       without tvc() (3.1e-08 vs crrs).  The gap was the whole tell. */
    if (args() < 12) censtrue = (delta :== 0) :| (event_type :== censval)
    is_cens = censtrue

    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    levels = uniqrows(byg_id)
    ng = rows(levels)
    gidx = _finegray_group_index(byg_id, levels)
    Gt = _finegray_G_at_times(t, G, byg_id, t)
    Gminus = _finegray_G_minus(gidx, Gt)

    /* ---- pass A: per distinct time, collect S0, zbar, event counts, Ghat */
    nt = 0
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        nt++
        i = j
    }

    /* (g, k) pairs are flattened to gk = (g-1)*K + k, so K == 1 leaves every
       index and every matrix block EXACTLY where it was before bstrata(). */
    ngk = ng * K

    S0arr = J(nt, K, 0)
    Zbar = J(nt, K * p, 0)
    Dg = J(nt, ngk, 0)
    Gg = J(nt, ng, 1)

    risk_S0 = J(K, 1, 0)
    risk_S1 = J(K, p, 0)
    if (K == 1) {
        /* colsum, not an accumulation loop: the pre-bstrata code summed this
           way and the last bits of every psi term depend on the order. */
        risk_S0[1] = colsum(expeta)
        risk_S1[1, .] = colsum(expeta :* Z)
    }
    else {
        for (i = 1; i <= n; i++) {
            kk = bscode[i]
            risk_S0[kk] = risk_S0[kk] + expeta[i]
            risk_S1[kk, .] = risk_S1[kk, .] + expeta[i] * Z[i, .]
        }
    }
    bwd_s0 = J(ngk, 1, 0)
    bwd_s1 = J(ngk, p, 0)

    it = 0
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        it++

        for (g = 1; g <= ng; g++) Gg[it, g] = Gt[ord[i], g]

        /* Each stratum's own risk-set totals.  The retained-competing part is
           still summed over the g axis (a stratum can hold subjects from any
           weight group), but only over THIS stratum's competing exits. */
        if (K == 1) {
            /* The pre-bstrata expression, character for character: with
               K == 1 the gk layout is the g layout, so bwd_s0 and bwd_s1 are
               the same ng-row objects they were, and Mata's dot product
               accumulates in the same order it did.  Written out separately
               rather than reached through the general loop because a
               different summation order over g moves the last bits, and a
               nuisance fit with strata() was legal before this change. */
            S0_t = risk_S0[1] + Gg[it, .] * bwd_s0
            S1_t = risk_S1[1, .] + Gg[it, .] * bwd_s1
            if (S0_t > 0) {
                z_bar_t = S1_t / S0_t
                S0arr[it, 1] = S0_t
                Zbar[it, .] = z_bar_t
            }
        }
        else {
            for (kk = 1; kk <= K; kk++) {
                S0_t = risk_S0[kk]
                S1_t = risk_S1[kk, .]
                for (g = 1; g <= ng; g++) {
                    gk = (g - 1) * K + kk
                    S0_t = S0_t + Gg[it, g] * bwd_s0[gk]
                    S1_t = S1_t + Gg[it, g] * bwd_s1[gk, .]
                }
                if (S0_t > 0) {
                    z_bar_t = S1_t / S0_t
                    S0arr[it, kk] = S0_t
                    Zbar[it, ((kk - 1) * p + 1)..(kk * p)] = z_bar_t
                }
            }
        }

        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                gk = (gidx[idx] - 1) * K + bscode[idx]
                Dg[it, gk] = Dg[it, gk] + 1
            }
        }

        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                gk = (gidx[idx] - 1) * K + bscode[idx]
                bwd_s0[gk] = bwd_s0[gk] + expeta[idx] / Gminus[idx]
                bwd_s1[gk, .] = bwd_s1[gk, .] +
                    expeta[idx] / Gminus[idx] * Z[idx, .]
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            kk = bscode[idx]
            risk_S0[kk] = risk_S0[kk] - expeta[idx]
            risk_S1[kk, .] = risk_S1[kk, .] - expeta[idx] * Z[idx, .]
        }
        i = j
    }

    /* ---- pass B: reverse cumulative C0, C1 over (group g, stratum k) event
       times.  The DENOMINATOR is the stratum's S0_k and the numerator carries
       the group's Ghat_g -- that pairing is the whole of the change. */
    C0 = J(nt, ngk, 0)
    C1 = J(nt, ngk * p, 0)
    for (it = nt; it >= 1; it--) {
        if (it < nt) {
            C0[it, .] = C0[it + 1, .]
            C1[it, .] = C1[it + 1, .]
        }
        for (g = 1; g <= ng; g++) {
            for (kk = 1; kk <= K; kk++) {
                gk = (g - 1) * K + kk
                if (Dg[it, gk] == 0) continue
                if (S0arr[it, kk] <= 0) continue
                cS0 = Dg[it, gk] * Gg[it, g] / S0arr[it, kk]
                C0[it, gk] = C0[it, gk] + cS0
                C1[it, ((gk - 1) * p + 1)..(gk * p)] =
                    C1[it, ((gk - 1) * p + 1)..(gk * p)] +
                    cS0 * Zbar[it, ((kk - 1) * p + 1)..(kk * p)]
            }
        }
    }

    /* ---- pass C: forward, form q_g(t) and accumulate psi */
    psi = J(n, p, 0)
    cumL = J(ng, p, 0)
    qg = J(ngk, p, 0)
    qsum = J(ng, p, 0)
    Yg = J(ng, 1, 0)
    for (i = 1; i <= n; i++) Yg[gidx[i]] = Yg[gidx[i]] + 1

    bwd_s0 = J(ngk, 1, 0)
    bwd_s1 = J(ngk, p, 0)

    it = 0
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        it++

        for (gk = 1; gk <= ngk; gk++) {
            c1row = C1[it, ((gk - 1) * p + 1)..(gk * p)]
            qg[gk, .] = bwd_s1[gk, .] * C0[it, gk] - bwd_s0[gk] * c1row
        }

        /* q_g(u) = sum_k q[g,k](u).  Ghat_g's influence reaches EVERY
           stratum's score -- with a pooled Ghat that is the whole point --
           so the strata are summed before the censoring-martingale integral,
           not after.  With K == 1 qsum IS qg: aliased, not recomputed, so no
           arithmetic touches the pre-bstrata numbers. */
        if (K == 1) {
            qsum = qg
        }
        else {
            for (g = 1; g <= ng; g++) {
                qsum[g, .] = J(1, p, 0)
                for (kk = 1; kk <= K; kk++) {
                    qsum[g, .] = qsum[g, .] + qg[(g - 1) * K + kk, .]
                }
            }
        }

        for (g = 1; g <= ng; g++) {
            dNc_g = 0
            for (k = i; k < j; k++) {
                idx = ord[k]
                if (is_cens[idx] & gidx[idx] == g) dNc_g = dNc_g + 1
            }
            if (dNc_g > 0 & Yg[g] > 0)
                cumL[g, .] = cumL[g, .] +
                    dNc_g * qsum[g, .] / (Yg[g] * Yg[g])
        }

        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            psi[idx, .] = -cumL[g, .]
            if (is_cens[idx] & Yg[g] > 0)
                psi[idx, .] = psi[idx, .] + qsum[g, .] / Yg[g]
        }

        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                gk = (gidx[idx] - 1) * K + bscode[idx]
                bwd_s0[gk] = bwd_s0[gk] + expeta[idx] / Gminus[idx]
                bwd_s1[gk, .] = bwd_s1[gk, .] +
                    expeta[idx] / Gminus[idx] * Z[idx, .]
            }
        }
        for (k = i; k < j; k++) Yg[gidx[ord[k]]] = Yg[gidx[ord[k]]] - 1

        i = j
    }

    return(psi)
}

/* Sum score/influence rows by cluster in deterministic cluster/row order.
   The former implementation called selectindex() over all N rows once for
   each of G clusters, making clustered inference O(N*G).  Sorting once and
   using panelsum() makes the aggregation O(N log N) while preserving original
   row order within each cluster (and therefore deterministic floating-point
   accumulation). */
real matrix _finegray_cluster_sums(
    real matrix X,
    real colvector clust_id)
{
    real colvector row_id, ord
    real matrix pinfo

    row_id = (1::rows(clust_id))
    ord = order((clust_id, row_id), (1, 2))
    pinfo = panelsetup(clust_id[ord], 1)
    return(panelsum(X[ord, .], pinfo))
}

/* Robust (sandwich) variance estimator with left truncation support */
real matrix _finegray_robust_var(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real matrix info_inv,
    string scalar clust_var,
    real colvector clust_id,
    real colvector t0,
    real colvector tg_id,
    | real scalar nuisance,
    real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector ivl,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint,
    real colvector w,
    real scalar wtype)
{
    real scalar n, p, use_cluster
    real matrix scores, meat, clust_scores

    if (args() < 15) nuisance = 0
    if (args() < 21) bsraw = J(rows(t), 1, 1)
    if (args() < 25) nint = 1
    if (args() < 26) w = J(rows(t), 1, 1)
    if (args() < 27) wtype = 0

    n = rows(t)
    p = cols(Z)

    if (args() < 20) {
        scores = _finegray_score_residuals(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, t0, tg_id)
    }
    else if (nint <= 1) {
        scores = _finegray_score_residuals(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, t0, tg_id, use_pooled, gidx,
            Gminus, Gt, Apool, bsraw, w)
    }
    else {
        /* Piecewise beta(t): the meat is still sum_i U_i U_i', with U_i the
           subject's residual summed over every interval's cause events. */
        scores = _finegray_score_residuals_pw(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, t0, tg_id, use_pooled, gidx,
            Gminus, Gt, Apool, bsraw, ivl, fixpos, tvcpos, nint, w)
    }

    /* FG (1999) eq. (7)-(8): add the influence contribution from having
       ESTIMATED G.  The caller guarantees right censoring only -- the psi
       derivation does not cover delayed entry -- and _finegray_psi_residuals
       errors rather than silently returning an ungrounded quantity if that
       guarantee is broken.

       bstrata() USED to be refused here as well, because q_g(t) in eq. (8)
       was built from the pooled S0(s) and zbar(s).  Since 2026-08-26
       _finegray_psi_residuals takes bsraw and gives every risk-set quantity a
       stratum index, which is Zhou et al. (2011) sec. 4.1's psi_ki -- FG's psi
       "with the added subscript k" -- and reduces to crrSC's crrvvs() exactly
       when the two axes coincide.  The bsraw column is therefore forwarded,
       not asserted against. */
    if (nuisance) {
        /* The psi term is not derived under design weights in this release
           (finegray.ado refuses nuisance with weights); this is the belt. */
        if (wtype) {
            errprintf("finegray: nuisance is not supported with weights\n")
            exit(error(198))
        }
        if (colmax(t0) > 0) {
            /* Delayed entry: the ZZF (2011) Appendix B terms in place of FG's
               psi, for the pooled weight only.  The Stata layer refuses every
               other delayed-entry nuisance cell (weight strata, bstrata(),
               tvc()) before reaching here; this guard is the belt. */
            if (args() < 20) {
                _finegray_prepare_weight_design(t, delta, censval, event_type,
                    G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
            }
            if (nint > 1 | use_pooled | cols(Gt) != 1 |
                rows(uniqrows(bsraw)) > 1) {
                errprintf("finegray: the delayed-entry psi (ZZF 2011 ")
                errprintf("Appendix B) is implemented for the pooled weight ")
                errprintf("only\n")
                exit(error(198))
            }
            scores = scores + _finegray_psi_residuals_lt(t, delta, cause,
                censval, event_type, Z, beta, t0, Gminus, Gt)
        }
        else {
            scores = scores + _finegray_psi_residuals_pw(t, delta, cause,
                censval, event_type, Z, beta, G, byg_id, t0, bsraw, ivl,
                fixpos, tvcpos, nint)
        }
    }

    /* Sandwich meat under design weights.  scores holds s_i, the residual
       per unit weight (see _finegray_score_residuals).
         pweight  sum_i (w_i s_i)(w_i s_i)'   -- the survey/IPW sandwich, as
                  coxph(weights=, robust=TRUE) forms it on the finegray()
                  expansion, treating estimated censoring weights as fixed.
                  It omits censoring-estimation uncertainty. It is
                  NOT Wogu et al. (2021) Thm 4.1, which estimates a
                  different decomposition for their SRS subcohort (p.169):
                  n^-1 sum_i rho_i (eta_i + psi_i)^2 -- rho ONCE, an HT
                  estimate of the full-cohort model variance -- plus
                  (1-alpha)/alpha n^-1 sum_i rho_i mu_i^2, the subcohort
                  design part. The recovery validation is a finite-DGP
                  check, not proof of general design consistency.
         fweight  sum_i w_i s_i s_i'          -- w_i independent copies.
         cluster  within-cluster sums of w_i s_i, then outer products,
                  for either type.
       wtype == 0 leaves the shipped lines untouched. */
    use_cluster = (clust_var != "" & rows(clust_id) == n)
    if (use_cluster) {
        if (wtype) scores = w :* scores
        clust_scores = _finegray_cluster_sums(scores, clust_id)
        meat = clust_scores' * clust_scores
    }
    else if (wtype == 1) {
        scores = w :* scores
        meat = scores' * scores
    }
    else if (wtype == 2) {
        meat = (w :* scores)' * scores
    }
    else {
        meat = scores' * scores
    }

    return(info_inv * meat * info_inv)
}

/* Canonical stratified ZZF Breslow baseline.  The pooled stabilizer cancels
   between the weighted event count and weighted risk set, leaving one
   stratum-specific event denominator outside the denominator-scale risk sum. */
real matrix _finegray_basehaz_zzf(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real colvector gidx,
    real colvector Gminus,
    real matrix Aden)
{
    real colvector row_id, eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector riskn, _Apool
    real scalar n, i, j, k, idx, cur_time, ep, g, ng, coreS0, _use
    real scalar cum_bh, ev_idx, n_events, has_cause
    real rowvector risk0, bwd0
    real matrix result

    n = rows(t)
    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    if (args() < 14) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, _use, gidx, Gminus, Aden, _Apool)
    }
    ng = cols(Aden)

    risk0 = J(1, ng, 0)
    riskn = J(ng, 1, 0)
    bwd0 = J(1, ng, 0)
    n_events = sum(is_cause)
    result = J(n_events, 2, .)
    cum_bh = 0
    ev_idx = 0
    ep = 1
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                g = gidx[idx]
                risk0[g] = risk0[g] + expeta[idx]
                riskn[g] = riskn[g] + 1
            }
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        has_cause = 0
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                coreS0 = bwd0 * J(ng, 1, 1)
                for (g = 1; g <= ng; g++) {
                    if (riskn[g] > 0) coreS0 = coreS0 + risk0[g] / Aden[idx, g]
                }
                cum_bh = cum_bh +
                    1 / (Aden[idx, gidx[idx]] * coreS0)
                has_cause = 1
            }
        }
        if (has_cause) {
            ev_idx++
            result[ev_idx, 1] = cur_time
            result[ev_idx, 2] = cum_bh
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                g = gidx[idx]
                bwd0[g] = bwd0[g] + expeta[idx] / Gminus[idx]
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            risk0[g] = risk0[g] - expeta[idx]
            riskn[g] = riskn[g] - 1
        }
        i = j
    }
    if (ev_idx < 1) return(J(0, 2, .))
    if (ev_idx < rows(result)) result = result[(1..ev_idx), .]
    return(result)
}

/* Compute baseline cumulative subhazard (with left truncation) */
real matrix _finegray_basehazard(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    | real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector w)
{
    real colvector row_id, ordk, entry_ordk, bslev, bscode
    real scalar n, p, i, j, k, idx, cum_bh, g, ng, nk, kk, K, ncol
    real scalar n_events, ev_idx, S0_t, cur_time, risk_S0, ep, has_cause
    real colvector eta, expeta, wexpeta, is_cause, is_compete, ord, entry_ord
    real rowvector bwd_s0_raw
    real matrix result
    external real scalar _finegray_bh_calls

    /* Scan counter.  This routine is a FULL pass over the risk set, and under
       bstrata() it returns every stratum's rows in one call, so calling it once
       per stratum is K redundant scans.  The counter is what lets
       qa/test_finegray_tvc_bstrata_perf.do assert that the tvc() x bstrata()
       assembly makes one call per INTERVAL and none per stratum -- a scaling
       claim no timing measurement can make deterministically.  One external
       scalar increment against an O(n log n) scan is not measurable. */
    if (_finegray_bh_calls == J(1, 1, .) | _finegray_bh_calls >= .) {
        _finegray_bh_calls = 0
    }
    _finegray_bh_calls = _finegray_bh_calls + 1

    if (args() < 17) bsraw = J(rows(t), 1, 1)
    if (args() < 18) w = J(rows(t), 1, 1)

    if (args() < 16) {
        _finegray_prepare_weight_design(t, delta, censval, event_type, G,
            byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
    }

    if (use_pooled) {
        return(_finegray_basehaz_zzf(t, delta, cause, censval, event_type,
            Z, beta, G, byg_id, t0, tg_id, gidx, Gminus, Gt))
    }

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    /* Weighted Breslow baseline (Wogu et al. 2021 eq. 4, p.167): the
       increment at a cause event is w_i / S0_w(t), with S0_w the
       w-weighted risk-set sum. */
    wexpeta = w :* expeta
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    /* Deterministic tie-break by row index.  Mata's order() resolves ties
       using Stata's sort seed, which ADVANCES on every sort, so a tied key
       (every t0 == 0 when there is no delayed entry) yields a different
       permutation on each call -- and the risk-set scan then accumulates in
       a different floating-point order.  Without this the same command on
       the same data is not bit-reproducible. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    /* ZZF: Gt is A = G(t-)H(t-) on CROSS-CLASSIFIED strata.  With no delayed
       entry H == 1 and this is bit-identical to the former G-only path. */
    ng = cols(Gt)

    _finegray_bs_setup(bsraw, bslev, bscode, K)

    /* bstrata(): each stratum carries its OWN unconstrained baseline, so the
       curve is a set of K step functions.  The returned matrix is
       (time, cumhaz) when K == 1 -- the shape every existing consumer knows --
       and (bstratum, time, cumhaz) when K > 1, with the stratum blocks in
       ascending LEVEL VALUE order and ascending time within each block.  Column
       1 carries the bstrata() VALUE, not a 1..K code, so a lookup on a subset
       of the fit's rows still resolves the right block. */
    ncol = (K > 1 ? 3 : 2)
    n_events = sum(is_cause)
    result = J(n_events, ncol, .)
    ev_idx = 0

    for (kk = 1; kk <= K; kk++) {
        ordk = _finegray_bs_rows(ord, bscode, kk, K)
        entry_ordk = _finegray_bs_rows(entry_ord, bscode, kk, K)
        nk = length(ordk)
        if (nk == 0) continue

        risk_S0 = 0
        ep = 1
        bwd_s0_raw = J(1, ng, 0)
        cum_bh = 0

        i = 1
        while (i <= nk) {
            cur_time = t[ordk[i]]

            /* Add entries: (t0, t] means t0 < cur_time */
            while (ep <= nk) {
                if (t0[entry_ordk[ep]] >= cur_time) break
                idx = entry_ordk[ep]
                if (t[idx] >= cur_time) {
                    risk_S0 = risk_S0 + wexpeta[idx]
                }
                ep++
            }

            j = i
            while (j <= nk) {
                if (t[ordk[j]] != cur_time) break
                j++
            }

            /* Process cause events - accumulate baseline hazard.
               The cumulative subhazard is a step function of TIME, so it must have
               one row per unique cause-event time, not one per event.  Tied events
               all see the same risk set and hence the same S0, so Breslow adds
               d/S0(t) once for the d events at t -- but emitting a row per event
               left e(basehaz) multi-valued at t (50 tied events -> 50 rows, 1
               unique time), which every step-function lookup downstream then had to
               tolerate. Accumulate across the tie group, then emit a single row. */
            has_cause = 0
            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_cause[idx]) {
                    S0_t = risk_S0 + Gt[idx, .] * bwd_s0_raw'
                    cum_bh = cum_bh + w[idx] / S0_t
                    has_cause = 1
                }
            }
            if (has_cause) {
                ev_idx++
                if (ncol == 3) {
                    result[ev_idx, 1] = bslev[kk]
                    result[ev_idx, 2] = cur_time
                    result[ev_idx, 3] = cum_bh
                }
                else {
                    result[ev_idx, 1] = cur_time
                    result[ev_idx, 2] = cum_bh
                }
            }

            /* Add competing events to backward */
            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_compete[idx]) {
                    g = gidx[idx]
                    bwd_s0_raw[g] = bwd_s0_raw[g] + wexpeta[idx] / Gminus[idx]
                }
            }

            /* Remove exiting subjects */
            for (k = i; k < j; k++) {
                risk_S0 = risk_S0 - wexpeta[ordk[k]]
            }

            i = j
        }
    }

    /* result was sized for the worst case (every cause event at its own time);
       with ties it holds fewer rows.  Trim, or the trailing rows stay missing
       and every consumer sees a step function with a missing tail. */
    if (ev_idx < 1) return(J(0, ncol, .))
    if (ev_idx < rows(result)) result = result[(1..ev_idx), .]

    return(result)
}

/* Invert a post-estimation information matrix without silently changing the
   estimand.  Mata's invsym() returns a generalized inverse for a rank-deficient
   matrix, so checking only for missing output accepts an unidentified direction
   at rc 0.  Earlier post-estimation code also attempted a 1e-6 ridge only when
   invsym() returned missing; that branch did not catch rank deficiency and, if
   reached, substituted an arbitrary variance.  Estimation itself rejects the
   same condition, and every dependent post-estimation path must fail closed. */
real matrix _finegray_information_inverse(
    real matrix info_mat,
    string scalar context)
{
    real scalar p
    real matrix info_inv

    p = rows(info_mat)
    if (p == 0 | cols(info_mat) != p | hasmissing(info_mat) |
        rank(info_mat) < p) {
        errprintf("finegray: %s information matrix is not full rank\n", context)
        exit(error(459))
    }
    info_inv = invsym(info_mat)
    if (hasmissing(info_inv)) {
        errprintf("finegray: %s information matrix could not be inverted\n",
            context)
        exit(error(498))
    }
    return(info_inv)
}

/* Canonical stratified ZZF Schoenfeld contributions. */
real matrix _finegray_schoenfeld_zzf(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real scalar do_scale,
    real colvector t0,
    real colvector tg_id)
{
    real colvector row_id, eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector gidx, Gminus, Apool, score_vec, riskn
    real scalar n, p, i, j, k, idx, cur_time, ep, g, ng, coreS0, ew, ev
    real scalar use_pooled
    real rowvector risk0, bwd0, coreS1, zbar
    real matrix risk1, bwd1, Aden, result, info_mat, info_inv

    n = rows(t)
    p = cols(Z)
    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    _finegray_prepare_weight_design(t, delta, censval, event_type, G,
        byg_id, t0, tg_id, use_pooled, gidx, Gminus, Aden, Apool)
    ng = cols(Aden)

    risk0 = J(1, ng, 0)
    riskn = J(ng, 1, 0)
    risk1 = J(ng, p, 0)
    bwd0 = J(1, ng, 0)
    bwd1 = J(ng, p, 0)
    result = J(sum(is_cause), p + 1, .)
    ev = 0
    ep = 1
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                g = gidx[idx]
                risk0[g] = risk0[g] + expeta[idx]
                riskn[g] = riskn[g] + 1
                risk1[g, .] = risk1[g, .] + expeta[idx] * Z[idx, .]
            }
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                coreS0 = 0
                coreS1 = J(1, p, 0)
                for (g = 1; g <= ng; g++) {
                    coreS0 = coreS0 + bwd0[g]
                    coreS1 = coreS1 + bwd1[g, .]
                    if (riskn[g] > 0) {
                        coreS0 = coreS0 + risk0[g] / Aden[idx, g]
                        coreS1 = coreS1 + risk1[g, .] / Aden[idx, g]
                    }
                }
                zbar = coreS1 / coreS0
                ew = Apool[idx] / Aden[idx, gidx[idx]]
                ev++
                result[ev, 1] = t[idx]
                result[ev, 2..p+1] = ew * (Z[idx, .] - zbar)
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                g = gidx[idx]
                bwd0[g] = bwd0[g] + expeta[idx] / Gminus[idx]
                bwd1[g, .] = bwd1[g, .] +
                    expeta[idx] / Gminus[idx] * Z[idx, .]
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            risk0[g] = risk0[g] - expeta[idx]
            riskn[g] = riskn[g] - 1
            risk1[g, .] = risk1[g, .] - expeta[idx] * Z[idx, .]
        }
        i = j
    }
    if (do_scale & ev > 0) {
        _finegray_score_info_zzf_strat(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, score_vec, info_mat, t0, tg_id,
            gidx, Gminus, Aden, Apool)
        info_inv = _finegray_information_inverse(info_mat,
            "Schoenfeld-residual")
        for (k = 1; k <= p; k++) {
            result[., k + 1] = result[., k + 1] * info_inv[k, k]
        }
    }
    return(result)
}

/* Schoenfeld residuals at each cause-event time (with left truncation).
   Returns n_fail x (p+1) matrix: [time, resid_1, ..., resid_p]
   An internal legacy switch can apply a per-column diagonal rescaling; public
   callers request raw residuals. */
real matrix _finegray_schoenfeld(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real scalar do_scale,
    real colvector t0,
    real colvector tg_id,
    | real colvector bsraw,
    real colvector w)
{
    real scalar n, p, i, j, k, idx, S0_total, cur_time
    real scalar ev_idx, n_events, risk_S0, ep, g, ng, use_pooled
    real scalar nk, kk, K, ecount
    real colvector eta, expeta, wexpeta, is_cause, is_compete, ord, entry_ord
    real colvector score_vec
    real colvector row_id, gidx, Gminus, Apool, crank
    real colvector ordk, entry_ordk, bslev, bscode
    real matrix result, info_mat, bwd_s1_raw, Gt
    real rowvector bwd_s0_raw, S1_total, z_bar, risk_S1

    if (args() < 13) bsraw = J(rows(t), 1, 1)
    if (args() < 14) w = J(rows(t), 1, 1)

    if (_finegray_use_pooled_stabilizer(t0, byg_id, tg_id)) {
        return(_finegray_schoenfeld_zzf(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, do_scale, t0, tg_id))
    }

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    /* Weighted zbar(t): the residual is Z_i - S1_w(t)/S0_w(t). */
    wexpeta = w :* expeta
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    /* Stable sort by t, breaking ties by row index.  Mata's order() is not
       stable -- it resolves ties from Stata's sort seed, which ADVANCES on
       every sort -- so tied event times otherwise get an arbitrary ordering
       that may not match finegray_predict's assignment sort (_t _obs_id).
       NOTE the key spec is (1, 2): "column 1, then column 2".  (1, 1) means
       "column 1, then column 1", which never consults row_id and leaves the
       ties randomized. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))
    /* ZZF: the weight is now A = G(t-)H(t-) on CROSS-CLASSIFIED strata.  With no
       delayed entry H == 1 and this is bit-identical to the former G-only path. */
    _finegray_prepare_weight_design(t, delta, censval, event_type, G,
        byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
    ng = cols(Gt)

    _finegray_bs_setup(bsraw, bslev, bscode, K)

    n_events = sum(is_cause)
    result = J(n_events, p + 1, .)

    /* Each residual is written to its GLOBAL cause-event rank, not to a
       per-stratum counter.  finegray_predict and finegray_phtest assign these
       rows by cumulative cause-event index over the whole sample in time order
       (_finegray_assign_schoenfeld_vars), so emitting stratum blocks in
       sequence would hand every residual to the wrong observation at rc 0.
       With K == 1 the rank IS the sequential counter, so nothing moves. */
    crank = J(n, 1, .)
    ecount = 0
    for (i = 1; i <= n; i++) {
        idx = ord[i]
        if (is_cause[idx]) {
            ecount++
            crank[idx] = ecount
        }
    }

    for (kk = 1; kk <= K; kk++) {
        ordk = _finegray_bs_rows(ord, bscode, kk, K)
        entry_ordk = _finegray_bs_rows(entry_ord, bscode, kk, K)
        nk = length(ordk)
        if (nk == 0) continue

        risk_S0 = 0
        risk_S1 = J(1, p, 0)
        ep = 1

        bwd_s0_raw = J(1, ng, 0)
        bwd_s1_raw = J(ng, p, 0)

        i = 1
        while (i <= nk) {
            cur_time = t[ordk[i]]

            /* Add entries: (t0, t] means t0 < cur_time */
            while (ep <= nk) {
                if (t0[entry_ordk[ep]] >= cur_time) break
                idx = entry_ordk[ep]
                if (t[idx] >= cur_time) {
                    risk_S0 = risk_S0 + wexpeta[idx]
                    risk_S1 = risk_S1 + wexpeta[idx] * Z[idx, .]
                }
                ep++
            }

            j = i
            while (j <= nk) {
                if (t[ordk[j]] != cur_time) break
                j++
            }

            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_cause[idx]) {
                    S0_total = risk_S0 + Gt[idx, .] * bwd_s0_raw'
                    S1_total = risk_S1 + Gt[idx, .] * bwd_s1_raw
                    z_bar = S1_total / S0_total

                    ev_idx = crank[idx]
                    result[ev_idx, 1] = t[idx]
                    result[ev_idx, 2..p+1] = Z[idx, .] - z_bar
                }
            }

            for (k = i; k < j; k++) {
                idx = ordk[k]
                if (is_compete[idx]) {
                    g = gidx[idx]
                    bwd_s0_raw[g] = bwd_s0_raw[g] + wexpeta[idx] / Gminus[idx]
                    bwd_s1_raw[g, .] = bwd_s1_raw[g, .] +
                        wexpeta[idx] / Gminus[idx] * Z[idx, .]
                }
            }

            /* Remove exiting subjects */
            for (k = i; k < j; k++) {
                idx = ordk[k]
                risk_S0 = risk_S0 - wexpeta[idx]
                risk_S1 = risk_S1 - wexpeta[idx] * Z[idx, .]
            }

            i = j
        }
    }

    /* Legacy internal diagonal rescaling; no public caller requests it.
       Do NOT re-enable this as "Grambsch-Therneau scaling": GT scale by the FULL
       V^-1(beta,t_k) (eq. 5-6, p.517) or by the average variance Vbar = J/d
       (p.518-519).  GT sec. 5, p.523 attributes DIAGONAL-only standardization to
       Pettitt & Bin Daud (1990) and rejects it -- valid "only if the covariates
       are uncorrelated at each time point", otherwise it leaks one covariate's
       time-dependence into another's plot and "precludes equivalence ... to
       existing tests of proportional hazards".  Three discrepancies, not one:
       diagonal vs full matrix, no factor d, no +beta recentring.  And GT's null
       covariance identity is a partial-likelihood result; the IPCW-weighted
       Fine-Gray score is an estimating function, so it would not transport
       even in full-matrix form.  See Grambsch, P. M. and T. M. Therneau.
       1994.  Proportional hazards tests and diagnostics based on weighted
       residuals.  Biometrika 81: 515-526, sections 3-5, pp.517-523.  */
    if (do_scale & n_events > 0) {
        _finegray_score_info(t, delta, cause, censval, event_type,
            Z, beta, G, byg_id, score_vec, info_mat, t0, tg_id,
            use_pooled, gidx, Gminus, Gt, Apool, bsraw, w)
        real matrix info_inv
        info_inv = _finegray_information_inverse(info_mat,
            "Schoenfeld-residual")
        for (k = 1; k <= p; k++) {
            result[., k+1] = result[., k+1] * info_inv[k, k]
        }
    }

    return(result)
}

/* Compute Schoenfeld residuals from stored e() results and post to Stata.
   t0var names the entry-time variable ("_t0", or the persisted subject entry
   variable when the fit reduced multiple records per subject). */
void _finegray_schoenfeld_compute(
    string scalar varlist_str,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar tg_str,
    real scalar do_scale,
    string scalar t0var,
    | string scalar bs_str,
    string scalar w_str,
    real scalar wtype)
{
    real colvector t, delta, event_type, G, byg_id, beta, t0, tg_id, bsraw, w
    real matrix Z, sch
    string rowvector vars
    real scalar p

    if (args() < 9) bs_str = ""
    if (args() < 10) w_str = ""
    if (args() < 11) wtype = 0

    vars = tokens(varlist_str)
    p = length(vars)

    Z = st_data(., vars)
    t = st_data(., "_t")
    delta = st_data(., "_d")
    event_type = st_data(., events_str)
    t0 = st_data(., t0var)

    beta = _finegray_beta()

    if (byg_str != "") {
        byg_id = st_data(., byg_str)
    }
    else {
        byg_id = J(rows(t), 1, 1)
    }
    /* truncstrata(): the entry-distribution H is estimated within these groups.
       Absent => a single pooled H group; H == 1 only without delayed entry. */
    if (tg_str != "") {
        tg_id = st_data(., tg_str)
    }
    else {
        tg_id = J(rows(t), 1, 1)
    }

    if (w_str != "") w = st_data(., w_str)
    else             w = J(rows(t), 1, 1)

    /* post-estimation recompute: quiet=1, the fit already printed any note */
    if (wtype == 2) {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1, w)
    }
    else {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1)
    }

    /* bstrata(): residuals are formed against the row's OWN stratum risk set
       and pooled for the test, which is the same shape the fit's scan takes. */
    if (bs_str != "") bsraw = st_data(., bs_str)
    else              bsraw = J(rows(t), 1, 1)

    sch = _finegray_schoenfeld(t, delta, cause, censval, event_type,
        Z, beta, G, byg_id, do_scale, t0, tg_id, bsraw, w)

    st_matrix("_finegray_schoenfeld", sch)
}

/* Abort on a rank-deficient information matrix, naming the offending terms.

   invsym() returns a GENERALIZED inverse for a rank-deficient matrix, with no
   missing values anywhere -- invsym((1,1\1,1))[1,1] is not missing.  So a
   missing() test cannot detect rank deficiency, and without this guard the
   optimizer chases floating-point noise along a flat direction and fabricates
   a coefficient (with SE 0 and converged=1) for a parameter the subdistribution
   likelihood cannot identify at all.

   _rmcoll in finegray.ado already rejects columns that are collinear in the
   FULL sample.  This catches the weaker condition that actually matters: a
   column can be globally full rank yet enter no cause-event risk set (e.g. it
   is nonzero only for subjects censored before the first cause event), leaving
   its direction flat in the likelihood. */
/* ========================================================================
   PIECEWISE-CONSTANT TIME-VARYING EFFECTS  --  tvc() / tsplit()

   The model is lambda(t | Z) = lambda_0(t) exp(Z'beta(t)) with beta(t)
   constant on the intervals tsplit() defines: the covariates named in tvc()
   carry one coefficient per interval, everything else carries one.

   WHY THIS IS NOT A DESIGN-MATRIX CHANGE.  The scan in _finegray_loglik is
   O(n log n) because of two invariants (see its header): exp(Z'beta) is
   computed ONCE before the loop, and a competing-event subject's retained
   contribution factorises into a subject part and a time part, so it is added
   once and never revisited.  Both hold because the linear predictor does not
   depend on t.  Under beta(t) neither holds.

   What DOES still hold is that the linear predictor is constant WITHIN an
   interval.  At a cause-event time T_m every member of the subdistribution
   risk set -- at-risk subject and retained competing exit alike -- is weighted
   by exp(Z'beta_{j(m)}) for the SAME j(m), because beta(t) is evaluated at the
   event time, not at the subject's own time.  So interval j's contribution to
   the log pseudo-likelihood, score, information, score residuals and Breslow
   baseline is exactly what the ordinary scan returns when it is run with

     (a) the design D_j -- the full p' frame with interval j's tvc block filled
         and every other tvc block zero, and
     (b) the cause events outside interval j masked away,

   and the total is the sum over j.  Each pass still starts at time 0 and still
   walks the whole risk set, so the accumulators are rebuilt at every boundary,
   which is the O(J n p) price of dropping the two invariants; the sorting is
   the only O(n log n) part and it happens once per pass.  Nothing below
   re-derives the scan: the five right-censoring scan functions are called
   unmodified, which is also what keeps a fit WITHOUT tvc() bit-identical --
   nint <= 1 delegates to exactly the call the engine made before.

   SCOPE.  Refused in the parser and again in the engine: delayed entry (the
   ZZF branch is the package's own extension and no source covers beta(t)
   there), bstrata(), and nuisance.  So K == 1 and use_pooled == 0 everywhere
   below.
   ======================================================================== */

/* Interval index of each analysis time.  Interval j is (cuts[j-1], cuts[j]],
   with cuts[0] = 0 and cuts[nint] = +infinity: an event exactly AT a boundary
   belongs to the EARLIER interval.  That is the (t0, t] convention every risk
   set in this package is built on, and it is what lets every baseline lookup
   downstream use the ordinary "largest event time <= s" step search instead of
   a left limit. */
real colvector _finegray_tvc_interval(real colvector t, real colvector cuts)
{
    real colvector iv
    real scalar j, ncut

    ncut = rows(cuts)
    iv = J(rows(t), 1, 1)
    for (j = 1; j <= ncut; j++) iv = iv :+ (t :> cuts[j])
    return(iv)
}

/* Split 1..p into the tvc design columns and the rest, both ASCENDING.
   tvc_str holds 1-based column indices into the fit's design, not names: the
   names are package-owned _fg_* columns that post-estimation is allowed to
   drop and rebuild as tempvars, and a position survives that. */
void _finegray_tvc_positions(
    string scalar tvc_str,
    real scalar p,
    real colvector fixpos,
    real colvector tvcpos)
{
    real colvector mark
    real scalar i, q, v, nt, nf
    string rowvector tok

    tok = tokens(tvc_str)
    q = length(tok)
    mark = J(p, 1, 0)
    for (i = 1; i <= q; i++) {
        v = strtoreal(tok[i])
        if (v >= . | v < 1 | v > p | v != trunc(v)) {
            errprintf("finegray: internal tvc() column index %s is not a ", tok[i])
            errprintf("column of the fitted design\n")
            exit(error(198))
        }
        if (mark[v]) {
            errprintf("finegray: internal tvc() column index %g is repeated\n", v)
            exit(error(198))
        }
        mark[v] = 1
    }

    /* Filled by an explicit loop, not by selectindex().  A 1 x 1 vector is
       orientation-AMBIGUOUS in Mata, so selectindex() on a one-column design
       returns a ROW vector, and an empty result comes back 1 x 0 rather than
       0 x 1 -- which then fails the `real colvector' declaration of every
       function these are handed to (r(3203), seen on
       `finegray x1, tvc(x1) tsplit(...)': one covariate, all of it
       time-varying, so both p == 1 and rows(fixpos) == 0 at once).  Building
       them by hand fixes the shape for every p, including p == 1 and the
       all-tvc case where fixpos is legitimately empty. */
    nt = 0
    for (i = 1; i <= p; i++) if (mark[i]) nt++
    nf = p - nt
    tvcpos = J(nt, 1, .)
    fixpos = J(nf, 1, .)
    nt = 0
    nf = 0
    for (i = 1; i <= p; i++) {
        if (mark[i]) {
            nt++
            tvcpos[nt] = i
        }
        else {
            nf++
            fixpos[nf] = i
        }
    }
}

/* Coefficient count of the piecewise frame. */
real scalar _finegray_tvc_ncoef(
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint)
{
    return(rows(fixpos) + nint * rows(tvcpos))
}

/* The interval-j design in the full p' frame:
     columns 1 .. nfix                     covariates with a single coefficient
     columns nfix + (k-1)*q + 1 .. + q     the tvc covariates for interval k
   Every block but interval j's is exactly zero, so a risk set scanned at an
   interval-j event time sees the inactive blocks as identically-zero
   covariates: they contribute nothing to S0, S1 or S2 and their score and
   information entries stay untouched, which is why the per-interval passes can
   simply be added. */
real matrix _finegray_tvc_design(
    real matrix Z,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint,
    real scalar j)
{
    real matrix D
    real scalar n, nfix, q, c0

    n = rows(Z)
    nfix = rows(fixpos)
    q = rows(tvcpos)
    D = J(n, nfix + nint * q, 0)
    if (nfix > 0) D[., (1..nfix)] = Z[., fixpos]
    if (q > 0) {
        c0 = nfix + (j - 1) * q
        D[., ((c0 + 1)..(c0 + q))] = Z[., tvcpos]
    }
    return(D)
}

/* event_type with every cause event OUTSIDE interval j relabelled as censored.
   Such a subject stays in the risk set until its own exit and contributes to
   neither the likelihood terms nor the retained-competing accumulator --
   exactly its role in interval j's contribution.  The weight design (G, Gminus,
   Gt, gidx) is built ONCE by the caller from the TRUE event types and passed
   in, so this mask never reaches the censoring Kaplan-Meier. */
real colvector _finegray_tvc_mask(
    real colvector event_type,
    real scalar cause,
    real scalar censval,
    real colvector ivl,
    real scalar j)
{
    real colvector m

    m = ((event_type :== cause) :& (ivl :!= j))
    return(event_type :* (1 :- m) :+ censval :* m)
}

/* Coefficient labels in the piecewise frame, for the rank-failure message.
   The Stata side builds the user-facing coefficient stripe independently; this
   is only what _finegray_rank_fail prints. */
string rowvector _finegray_tvc_labels(
    string rowvector vars,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint)
{
    string rowvector lab
    real scalar i, j, nfix, q

    nfix = rows(fixpos)
    q = rows(tvcpos)
    lab = J(1, nfix + nint * q, "")
    for (i = 1; i <= nfix; i++) lab[i] = vars[fixpos[i]]
    for (j = 1; j <= nint; j++) {
        for (i = 1; i <= q; i++) {
            lab[nfix + (j - 1) * q + i] =
                vars[tvcpos[i]] + ":tvc" + strofreal(j)
        }
    }
    return(lab)
}

/* ---- the four piecewise scans ------------------------------------------
   Each delegates verbatim when nint <= 1, so a fit without tvc() runs the
   identical call the engine made before this feature existed. */

real scalar _finegray_loglik_pw(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector ivl,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint,
    | real colvector w)
{
    real scalar ll, j
    real colvector etj
    real matrix Dj

    if (args() < 22) w = J(rows(t), 1, 1)

    if (nint <= 1) {
        return(_finegray_loglik(t, delta, cause, censval, event_type, Z,
            beta, G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt,
            Apool, bsraw, w))
    }

    ll = 0
    for (j = 1; j <= nint; j++) {
        etj = _finegray_tvc_mask(event_type, cause, censval, ivl, j)
        Dj = _finegray_tvc_design(Z, fixpos, tvcpos, nint, j)
        ll = ll + _finegray_loglik(t, delta, cause, censval, etj, Dj,
            beta, G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt,
            Apool, bsraw, w)
    }
    return(ll)
}

void _finegray_score_info_pw(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector score,
    real matrix info,
    real colvector t0,
    real colvector tg_id,
    real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector ivl,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint,
    | real colvector w)
{
    real scalar j, pt
    real colvector etj, score_j
    real matrix Dj, info_j

    if (args() < 24) w = J(rows(t), 1, 1)

    if (nint <= 1) {
        _finegray_score_info(t, delta, cause, censval, event_type, Z, beta,
            G, byg_id, score, info, t0, tg_id, use_pooled, gidx, Gminus,
            Gt, Apool, bsraw, w)
        return
    }

    pt = rows(beta)
    score = J(pt, 1, 0)
    info = J(pt, pt, 0)
    for (j = 1; j <= nint; j++) {
        etj = _finegray_tvc_mask(event_type, cause, censval, ivl, j)
        Dj = _finegray_tvc_design(Z, fixpos, tvcpos, nint, j)
        _finegray_score_info(t, delta, cause, censval, etj, Dj, beta,
            G, byg_id, score_j, info_j, t0, tg_id, use_pooled, gidx,
            Gminus, Gt, Apool, bsraw, w)
        score = score + score_j
        info = info + info_j
    }
}

real matrix _finegray_score_residuals_pw(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector ivl,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint,
    | real colvector w)
{
    real scalar j
    real colvector etj
    real matrix Dj, S

    if (args() < 22) w = J(rows(t), 1, 1)

    if (nint <= 1) {
        return(_finegray_score_residuals(t, delta, cause, censval,
            event_type, Z, beta, G, byg_id, t0, tg_id, use_pooled, gidx,
            Gminus, Gt, Apool, bsraw, w))
    }

    /* The score residual is a sum over cause-event times, so a subject's
       residual is the sum of its per-interval residuals.  Every quantity the
       per-interval pass accumulates -- the at-risk correction, the IPCW
       correction for a retained competing exit -- is restricted to that
       interval's events by the mask, and the pieces are disjoint. */
    S = J(rows(t), rows(beta), 0)
    for (j = 1; j <= nint; j++) {
        etj = _finegray_tvc_mask(event_type, cause, censval, ivl, j)
        Dj = _finegray_tvc_design(Z, fixpos, tvcpos, nint, j)
        S = S + _finegray_score_residuals(t, delta, cause, censval, etj,
            Dj, beta, G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt,
            Apool, bsraw, w)
    }
    return(S)
}

/* The psi (Fine & Gray 1999 eq. 7-8) term under a piecewise beta(t).

   DERIVATION, with the term-by-term check against cmprsk's crrvv below.  In
   one paragraph:

   The tvc scan is an IDENTITY, not an approximation.  Interval j's contribution
   to the score is the unmodified right-censoring score evaluated on design D_j
   (every other interval's block zeroed) with event set E_j (cause events
   outside interval j relabelled to the censoring code), and U = sum_j U^(j).
   psi is the functional-delta term (dU/dGhat)[IF_i(Ghat)].  Differentiation is
   linear, so psi_i = sum_j (dU^(j)/dGhat)[IF_i(Ghat)] = sum_j psi_i^(j), and
   psi_i^(j) is eq. (8) computed on (D_j, E_j) -- exactly the substitution the
   other four _pw wrappers make.  No new formula is involved; this is the fifth
   member of that family.

   THE TWO PLACES IT COULD HAVE GONE WRONG, both checked:

   1. The INNER sum of eq. (8) runs over competing exits before u.  The mask
      relabels CAUSE events only, never competing ones, so every pass sees every
      earlier competing exit -- which is right: at a cause event in interval j
      such a subject IS retained and IS weighted by interval j's coefficients
      through D_j.  This is the raw_bwd subtlety (a competing subject's
      retention is beta-dependent forever) and the mask does not touch it.
   2. The third line of eq. (8), -sum_{u<=t_i} dNc_g(u) q_g(u)/Y_g(u)^2, mixes
      pass-INVARIANT quantities (dNc_g, Y_g) with a pass-varying q.  It is
      linear in q, so summing it over passes gives the term for the summed q --
      the censoring counts are not counted J times.  Ghat itself is likewise
      pass-invariant: it is computed once, before the interval loop, from
      (X, 1-Delta) and passed in, so relabelling cause events to the censoring
      CODE inside a pass cannot move it.

   The evidence, not the argument, is the equivalence oracle: a tvc() fit and a
   hand-split fit with explicit interval x covariate interactions are the same
   model with the same design, so under `nuisance' they must agree in e(V) as
   well as e(b).  qa/test_finegray_tvc.do TVCPSI-01. */
real matrix _finegray_psi_residuals_pw(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector bsraw,
    real colvector ivl,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint)
{
    real scalar j
    real colvector etj, censtrue
    real matrix Dj, P

    if (nint <= 1) {
        return(_finegray_psi_residuals(t, delta, cause, censval, event_type,
            Z, beta, G, byg_id, t0, bsraw))
    }

    /* The REAL censoring set, taken from the unmasked event vector once and
       handed to every pass.  See the long note at the head of
       _finegray_psi_residuals: the mask relabels out-of-interval cause events
       to the censoring code, and that must not reach N^c. */
    censtrue = (delta :== 0) :| (event_type :== censval)

    P = J(rows(t), rows(beta), 0)
    for (j = 1; j <= nint; j++) {
        etj = _finegray_tvc_mask(event_type, cause, censval, ivl, j)
        Dj = _finegray_tvc_design(Z, fixpos, tvcpos, nint, j)
        P = P + _finegray_psi_residuals(t, delta, cause, censval, etj, Dj,
            beta, G, byg_id, t0, bsraw, censtrue)
    }
    return(P)
}

/* ------------------------------------------------------------------------
   psi_i under DELAYED ENTRY -- Zhang, X., M. Zhang and J. Fine.  2011.  A
   proportional hazards regression model for the subdistribution with
   right-censored and left-truncated competing risks data.  Statistics in
   Medicine 30: 1933-1951; Appendix B, pp.1944-1945.

   ZZF write the i.i.d. representation of the Weight-1 score as

       W_i = l_i + v_i + w_i

   where l_i is the fixed-weight score residual (_finegray_score_residuals;
   "the main term") and the other two are the influence of having ESTIMATED
   the weight A(t) = b(t)/S(t-): v_i from the left-truncated all-cause
   Kaplan-Meier S, w_i from the empirical at-risk fraction b.  This function
   returns v_i + w_i, the delayed-entry analogue of FG (1999) eq. (8)'s psi,
   which _finegray_psi_residuals computes for right censoring only.

   WHY THE PACKAGE'S OWN WEIGHTS MAY BE USED.  ZZF's appendix is written in
   the b/S representation; the engine holds the Geskus product A = G(t-)H(t-).
   Bellach et al. (2020) prove the two equal for continuous times, and Gate
   Z-ties (qa/crossval_finegray_zzf_r.R) established that with the package's
   event < censoring < entry tie ordering the product reproduces b/S(t-) on
   every collision class -- which is why e(lt_weight) is zzf1_geskus.  So
   Gt (A(t-) at each row's time) and Gminus (A(X_i-)) below ARE b/S, and the
   all-cause risk-set count Y(u) = #{t0_j < u <= t_j} IS n * b(u) in the same
   convention.

   THE THREE TERMS IN COMPUTABLE FORM.  Every dM^{L,1}_j(s) integrated over
   s > X_j is compensator-only (the jump is at X_j), and Y^{L,1}_j(s) = 1
   there only for a retained competing-event subject, whose weight is
   A(s-)/A(X_j-).  Writing n^{-1}/b(u) = 1/Y(u), with dLam(s) = d_1(s)/S0(s)
   the Breslow increment, zbar(s) = S1(s)/S0(s), and

       B0(u) = sum_{j competing, X_j < u} e^{eta_j} / A(X_j-)
       B1(u) = sum_{j competing, X_j < u} e^{eta_j} / A(X_j-) Z_j
       C0(u) = sum_{s > u, cause-1 times} A(s-) dLam(s)
       C1(u) = sum_{s > u, cause-1 times} A(s-) zbar(s) dLam(s)
       Q(u)  = -[ B1(u) C0(u) - B0(u) C1(u) ]          (= n qhat(u))

   the appendix's terms are

       v_i = 1{i failed, any cause} Q(X_i)/Y(X_i)
             - sum_{u in (t0_i, X_i], all-cause failure times} Q(u) dN.(u)/Y(u)^2

       w_i = - sum_{s in (t0_i, X_i], cause-1 times}
                   A(s-) dLam(s)/Y(s) [ B1(s) - zbar(s) B0(s) ]
             + sum_{j competing, X_j in (t0_i, X_i]}
                   e^{eta_j} / (A(X_j-) Y(X_j)) [ Z_j C0(X_j) - C1(X_j) ]

   Both are prefix sums of per-time quantities over subject i's own at-risk
   window, so the whole term is three passes over the distinct times: one
   forward for the risk-set totals, one reverse for C0/C1, one forward for
   Q and the window sums.  O(n log n) from the sorts; no expansion.

   THE CHECK THAT MAKES THIS MORE THAN A TRANSCRIPTION.  Without delayed entry
   b(u)/S(u-) is exactly G(u-), so the influence of the estimated weight is
   the influence of the censoring Kaplan-Meier -- FG (1999) eq. (8) -- and
   v_i + w_i CONVERGES to _finegray_psi_residuals's psi_i as n grows.
   Converges, not coincides: the appendix's w_i is the exact influence of an
   empirical average where eq. (8) uses the martingale linearization, so the
   two agree only asymptotically (meat distance 2.5e-3 -> 3.5e-5 over
   n = 500 -> 32000, per-subject correlation 0.89 -> 0.9999 on continuous
   data).  That convergence is what qa/test_finegray_nuisance_lt.do NLT-01
   asserts (distance halves per 2.5x n, correlation > 0.99 at n = 8000); it
   is the transcription's oracle, and it holds because the appendix's two
   correction terms are the failure-martingale and at-risk pieces of one
   censoring influence function, not because either vanishes.  Neither term
   vanishes at L = 0.

   SCOPE.  One weight stratum only (no strata()/truncstrata()): with
   stratified weights ZZF (Appendix E, p.1949) themselves treat the weight as
   known, and the package keeps that cell on fixed_weight_sandwich.  No
   bstrata() and no tvc(), both already refused under delayed entry.
   ------------------------------------------------------------------------ */
real matrix _finegray_psi_residuals_lt(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector t0,
    real colvector Gminus,
    real matrix Gt)
{
    real scalar n, p, i, j, k, idx, it, nt, ep, cur_time
    real scalar riskS0, Ycnt, B0, S0_t, d1, dall, Aum
    real rowvector riskS1, B1, zbar, qrow, dWb
    real colvector row_id, ord, entry_ord, eta, expeta
    real colvector is_cause, is_fail, is_comp
    real colvector tA, tY, tD1, tDall, tDlam, tB0, C0
    real colvector ent_it, exit_it
    real matrix tZbar, tB1, C1, cumV, cumWa, cumWb, W

    n = rows(t)
    p = cols(Z)
    if (cols(Gt) != 1) {
        errprintf("finegray: the delayed-entry psi (ZZF 2011 Appendix B) ")
        errprintf("is derived for one weight stratum\n")
        exit(error(198))
    }

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_fail = (delta :== 1) :& (event_type :!= censval)
    is_comp = is_fail :& !is_cause

    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))

    /* ---- pass 1: per distinct observation time u (ascending) ---- */
    nt = 0
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        nt++
        i = j
    }
    tA = J(nt, 1, 1)
    tY = J(nt, 1, 0)
    tD1 = J(nt, 1, 0)
    tDall = J(nt, 1, 0)
    tDlam = J(nt, 1, 0)
    tB0 = J(nt, 1, 0)
    tB1 = J(nt, p, 0)
    tZbar = J(nt, p, 0)
    ent_it = J(n, 1, 0)
    exit_it = J(n, 1, 0)

    riskS0 = 0
    riskS1 = J(1, p, 0)
    Ycnt = 0
    B0 = 0
    B1 = J(1, p, 0)
    ep = 1
    it = 0
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        it++
        /* admit entries: the at-risk window is (t0, t], so t0 < cur_time.
           cur_time is the first observation time strictly after t0_i, so
           it - 1 indexes the last distinct time <= t0_i: the prefix the
           window sums must EXCLUDE. */
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                riskS0 = riskS0 + expeta[idx]
                riskS1 = riskS1 + expeta[idx] * Z[idx, .]
                Ycnt = Ycnt + 1
                ent_it[idx] = it - 1
            }
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        Aum = Gt[ord[i], 1]
        tA[it] = Aum
        tY[it] = Ycnt
        tB0[it] = B0
        tB1[it, .] = B1
        d1 = 0
        dall = 0
        for (k = i; k < j; k++) {
            idx = ord[k]
            exit_it[idx] = it
            if (is_cause[idx]) d1++
            if (is_fail[idx]) dall++
        }
        tD1[it] = d1
        tDall[it] = dall
        if (d1 > 0) {
            S0_t = riskS0 + Aum * B0
            if (S0_t > 0) {
                tDlam[it] = d1 / S0_t
                tZbar[it, .] = (riskS1 + Aum * B1) / S0_t
            }
        }
        /* competing exits at u join the retained set for later times (X_j < s) */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_comp[idx]) {
                B0 = B0 + expeta[idx] / Gminus[idx]
                B1 = B1 + expeta[idx] / Gminus[idx] * Z[idx, .]
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            riskS0 = riskS0 - expeta[idx]
            riskS1 = riskS1 - expeta[idx] * Z[idx, .]
            Ycnt = Ycnt - 1
        }
        i = j
    }

    /* ---- pass 2: reverse sums over cause-1 times STRICTLY later than u ---- */
    C0 = J(nt, 1, 0)
    C1 = J(nt, p, 0)
    for (it = nt - 1; it >= 1; it--) {
        C0[it] = C0[it + 1] + tA[it + 1] * tDlam[it + 1]
        C1[it, .] = C1[it + 1, .] + tA[it + 1] * tDlam[it + 1] * tZbar[it + 1, .]
    }

    /* ---- pass 3: Q(u), the per-time increments, their prefix sums ---- */
    cumV = J(nt + 1, p, 0)
    cumWa = J(nt + 1, p, 0)
    cumWb = J(nt + 1, p, 0)
    W = J(n, p, 0)
    it = 0
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        it++
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        qrow = -(tB1[it, .] * C0[it] - tB0[it] * C1[it, .])
        cumV[it + 1, .] = cumV[it, .]
        cumWa[it + 1, .] = cumWa[it, .]
        cumWb[it + 1, .] = cumWb[it, .]
        if (tY[it] > 0) {
            if (tDall[it] > 0) {
                cumV[it + 1, .] = cumV[it + 1, .] +
                    qrow * tDall[it] / (tY[it] * tY[it])
            }
            if (tD1[it] > 0) {
                cumWa[it + 1, .] = cumWa[it + 1, .] +
                    tA[it] * tDlam[it] / tY[it] *
                    (tB1[it, .] - tZbar[it, .] * tB0[it])
            }
            dWb = J(1, p, 0)
            for (k = i; k < j; k++) {
                idx = ord[k]
                if (is_comp[idx]) {
                    dWb = dWb + expeta[idx] / (Gminus[idx] * tY[it]) *
                        (Z[idx, .] * C0[it] - C1[it, .])
                }
            }
            cumWb[it + 1, .] = cumWb[it + 1, .] + dWb
            /* the jump term of v_i: the subject's own all-cause failure */
            for (k = i; k < j; k++) {
                idx = ord[k]
                if (is_fail[idx]) W[idx, .] = qrow / tY[it]
            }
        }
        i = j
    }

    /* ---- per subject: the window (t0_i, X_i] is rows ent_it+1 .. exit_it ---- */
    for (i = 1; i <= n; i++) {
        W[i, .] = W[i, .] -
            (cumV[exit_it[i] + 1, .] - cumV[ent_it[i] + 1, .]) -
            (cumWa[exit_it[i] + 1, .] - cumWa[ent_it[i] + 1, .]) +
            (cumWb[exit_it[i] + 1, .] - cumWb[ent_it[i] + 1, .])
    }
    return(W)
}

/* Breslow baseline under beta(t).  There is ONE baseline: the interval
   structure lives in the linear predictor, not in lambda_0.  Each pass returns
   that interval's own event times with a cumulative sum that restarts at zero,
   so the blocks are carried forward and stacked.  Interval j's event times all
   exceed interval j-1's, so the stack is ascending in time with no duplicate
   times -- the shape (time, cumhaz) every consumer already knows. */
real matrix _finegray_basehazard_pw(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector byg_id,
    real colvector t0,
    real colvector tg_id,
    real scalar use_pooled,
    real colvector gidx,
    real colvector Gminus,
    real matrix Gt,
    real colvector Apool,
    real colvector bsraw,
    real colvector ivl,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint,
    | real colvector w)
{
    real scalar j, carry, kb, nlev
    real colvector etj, lev, carryv
    real matrix Dj, bhj, out, blk
    pointer(real matrix) colvector acc

    if (args() < 22) w = J(rows(t), 1, 1)

    if (nint <= 1) {
        return(_finegray_basehazard(t, delta, cause, censval, event_type, Z,
            beta, G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt,
            Apool, bsraw, w))
    }

    lev = uniqrows(bsraw)
    nlev = rows(lev)

    if (nlev <= 1) {
        /* One baseline: the shipped K x 2 stacking, unchanged. */
        out = J(0, 2, .)
        carry = 0
        for (j = 1; j <= nint; j++) {
            etj = _finegray_tvc_mask(event_type, cause, censval, ivl, j)
            Dj = _finegray_tvc_design(Z, fixpos, tvcpos, nint, j)
            bhj = _finegray_basehazard(t, delta, cause, censval, etj, Dj, beta,
                G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool,
                bsraw, w)
            if (rows(bhj) == 0) continue
            if (cols(bhj) != 2) {
                errprintf("finegray: internal error -- a stratified baseline ")
                errprintf("reached the unstratified tvc() baseline scan\n")
                exit(error(498))
            }
            bhj[., 2] = bhj[., 2] :+ carry
            carry = bhj[rows(bhj), 2]
            out = out \ bhj
        }
        return(out)
    }

    /* bstrata() x tvc().  Each interval pass returns a (bstratum, time,
       cumhaz) block per stratum, each restarting at zero, so the carry-forward
       that stitches the intervals into one curve has to be PER STRATUM: adding
       one pooled running total would hand every stratum the sum of all the
       others' mass before it.

       The output is assembled stratum-major -- all of stratum 1's intervals in
       time order, then stratum 2's -- because that is the layout every K x 3
       consumer already assumes (_finegray_bh_stratum selects a block by its
       stratum VALUE in column 1 and then does an ordinary ascending-time
       search inside it).  Interval j's event times all exceed interval j-1's
       within a stratum, so each block stays strictly ascending. */
    /* ONE scan per interval, not one per (stratum, interval) pair.  Each
       _finegray_basehazard() call already returns EVERY stratum's rows -- the
       stratum is column 1 -- so the stratum loop outside the interval loop ran
       the same K x J full risk-set scans to keep J of them and throw K - 1
       away each time.  The interval loop now runs once, each stratum's block is
       selected out of that one result, and the per-stratum carry is kept in a
       vector.  The assembly order is unchanged: blocks are accumulated per
       stratum and concatenated stratum-major at the end, so the returned matrix
       is bit-identical to the old K x J version. */
    acc = J(nlev, 1, NULL)
    for (kb = 1; kb <= nlev; kb++) acc[kb] = &(J(0, 3, .))
    carryv = J(nlev, 1, 0)

    for (j = 1; j <= nint; j++) {
        etj = _finegray_tvc_mask(event_type, cause, censval, ivl, j)
        Dj = _finegray_tvc_design(Z, fixpos, tvcpos, nint, j)
        bhj = _finegray_basehazard(t, delta, cause, censval, etj, Dj, beta,
            G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool,
            bsraw, w)
        if (rows(bhj) == 0) continue
        if (cols(bhj) != 3) {
            errprintf("finegray: internal error -- an unstratified ")
            errprintf("baseline reached the stratified tvc() scan\n")
            exit(error(498))
        }
        for (kb = 1; kb <= nlev; kb++) {
            /* select(), not selectindex(): Mata's 1x1 orientation ambiguity
               makes selectindex() return a 1 x 0 ROW vector for a one-row
               match, which then subscripts the wrong way.  Same trap already
               recorded against _finegray_fv_design. */
            blk = select(bhj, bhj[., 1] :== lev[kb])
            if (rows(blk) == 0) continue
            blk[., 3] = blk[., 3] :+ carryv[kb]
            carryv[kb] = blk[rows(blk), 3]
            *acc[kb] = (*acc[kb]) \ blk
        }
    }

    out = J(0, 3, .)
    for (kb = 1; kb <= nlev; kb++) out = out \ (*acc[kb])
    return(out)
}

/* QA accessors for the scan counter set in _finegray_basehazard().  They exist
   so the tvc() x bstrata() assembly's "one scan per interval, none per stratum"
   claim is asserted rather than timed. */
void _finegray_bh_calls_reset()
{
    external real scalar _finegray_bh_calls
    _finegray_bh_calls = 0
}
void _finegray_bh_calls_get()
{
    external real scalar _finegray_bh_calls
    if (_finegray_bh_calls == J(1, 1, .) | _finegray_bh_calls >= .) {
        _finegray_bh_calls = 0
    }
    st_local("_fg_bh_calls", strofreal(_finegray_bh_calls, "%18.0g"))
}

/* Baseline mass accumulated inside each interval up to each horizon.
   D[i, j] is the part of Lambda_0(times[i]) that falls in interval j, i.e.
     max(0, min(Lambda_0(times[i]), Lambda_0(cuts[j])) - Lambda_0(cuts[j-1]))
   with Lambda_0(cuts[0]) = 0 and cuts[nint] = +infinity.  Because interval j
   is (cuts[j-1], cuts[j]] this needs only the ordinary "largest event time <= s"
   step value -- no left limits.  H0cut must be the step values AT the cuts,
   which every baseline source can supply with the same lookup it already runs.

   Lambda(times[i] | z) = sum_j D[i, j] exp(eta_j(z)), and CIF = 1 - exp(-Lambda). */
real matrix _finegray_tvc_bhpieces(
    real colvector H0,
    real rowvector H0cut,
    real scalar nint)
{
    real matrix D
    real colvector hi
    real scalar j, lo

    D = J(rows(H0), nint, 0)
    for (j = 1; j <= nint; j++) {
        lo = (j == 1 ? 0 : H0cut[j - 1])
        if (j == nint) hi = H0
        else           hi = (H0 :< H0cut[j]) :* H0 :+ (H0 :>= H0cut[j]) :* H0cut[j]
        D[., j] = (hi :> lo) :* (hi :- lo)
    }
    return(D)
}

void _finegray_rank_fail(
    real matrix info_mat,
    string rowvector vars,
    real scalar p)
{
    real scalar k, dmax
    real colvector d
    string scalar bad

    d = diagonal(info_mat)
    dmax = colmax(d)
    bad = ""
    for (k = 1; k <= p; k++) {
        if (dmax <= 0 | d[k] <= 1e-9 * dmax) bad = bad + " " + vars[k]
    }

    errprintf("finegray: the information matrix is not full rank\n")
    if (bad != "") {
        errprintf("term(s) contributing no information at any cause-event ")
        errprintf("risk set:%s\n", bad)
        errprintf("their coefficients are not identified by the ")
        errprintf("subdistribution likelihood\n")
    }
    else {
        errprintf("the covariates are collinear within the cause-event ")
        errprintf("risk sets\n")
    }
    errprintf("remove or recode the offending term(s) and fit the model again\n")
    exit(error(459))
}

/* Main engine: Newton-Raphson with step halving */
void _finegray_engine(
    string scalar varlist_str,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar tg_str,
    string scalar vce_type,
    string scalar clust_str,
    real scalar max_iter,
    real scalar tol,
    real scalar show_log,
    real scalar adjust,
    real scalar want_bh,
    real scalar nuisance,
    string scalar bs_str,
    string scalar tvc_str,
    string scalar tsplit_str,
    | string scalar w_str,
    real scalar wtype)
{
    real colvector t, delta, event_type, G, byg_id, t0, tg_id, w
    real scalar nadj
    real matrix Z, V, bh, weight_A
    real colvector beta, beta_new, score_vec, step, clust_id
    real colvector weight_gidx, weight_Gminus, weight_Apool
    real colvector bsraw
    real matrix info_mat, info_inv
    real scalar n, p, ll, ll_new, ll_0, converged, iter
    real scalar step_scale, halving, max_halvings, chi2, df_m
    real scalar decrement, accepted, n_clust, rank_V, npos, weight_pooled
    real scalar K_bs, kb
    real colvector bslev_e
    string scalar bs_noev, bs_noevx
    string rowvector vars, coefnames
    real colvector cuts, ivl, fixpos, tvcpos
    real scalar nint, ptot

    if (args() < 18) w_str = ""
    if (args() < 19) wtype = 0

    /* Read data */
    vars = tokens(varlist_str)
    p = length(vars)

    Z = st_data(., vars)
    t = st_data(., "_t")
    delta = st_data(., "_d")
    event_type = st_data(., events_str)
    t0 = st_data(., "_t0")
    n = rows(t)

    /* Design weights.  wtype 0 = none, 1 = pweight, 2 = fweight; the column
       is a per-subject constant (finegray.ado checks it within id()). */
    if (w_str != "") w = st_data(., w_str)
    else              w = J(n, 1, 1)

    /* Read byg variable if specified */
    if (byg_str != "") {
        byg_id = st_data(., byg_str)
    }
    else {
        byg_id = J(n, 1, 1)
    }
    if (tg_str != "") {
        tg_id = st_data(., tg_str)
    }
    else {
        tg_id = J(n, 1, 1)
    }

    /* Baseline strata (bstrata()).  The RAW values travel into every scan; the
       scans map them to 1..K themselves via uniqrows, so estimation and
       post-estimation cannot disagree about which stratum is which. */
    if (bs_str != "") {
        bsraw = st_data(., bs_str)
    }
    else {
        bsraw = J(n, 1, 1)
    }
    K_bs = rows(uniqrows(bsraw))

    /* Piecewise-constant beta(t).  tsplit_str holds the interior boundaries and
       tvc_str the 1-based positions of the time-varying design columns; both
       empty means an ordinary fit, and nint == 1 makes every scan below
       delegate to the exact call the engine made before this feature existed. */
    if (tsplit_str != "") cuts = strtoreal(tokens(tsplit_str))'
    else                  cuts = J(0, 1, .)
    if (tvc_str != "") {
        _finegray_tvc_positions(tvc_str, p, fixpos, tvcpos)
        nint = rows(cuts) + 1
    }
    else {
        fixpos = (1::p)
        tvcpos = J(0, 1, .)
        nint = 1
    }
    if (nint > 1) {
        ivl = _finegray_tvc_interval(t, cuts)
        coefnames = _finegray_tvc_labels(vars, fixpos, tvcpos, nint)
    }
    else {
        ivl = J(n, 1, 1)
        coefnames = vars
    }
    ptot = _finegray_tvc_ncoef(fixpos, tvcpos, nint)

    /* FENCE LIFTED 2026-08-26 (variance unification).  tvc() x bstrata() used to be refused
       here as well as in the parser.  Nothing about the two features conflicts:
       they reshape the scan on orthogonal axes -- bstrata() partitions ROWS
       into per-stratum risk sets, tvc() partitions TIME into per-interval
       passes over a zeroed design -- and the piecewise wrappers already forward
       bsraw into the stratified scans, so the composition needed no new scan
       code at all.  What did need writing is the BASELINE stacking, which now
       carries a per-stratum running total (see _finegray_basehazard_pw); a
       pooled carry would have handed each stratum the sum of all the others'
       mass before it, at rc 0.

       The refusal's stated reason was that the pair "has no reference
       implementation to validate against".  That turned out to be false and was
       checked rather than assumed: crrSC::crrs takes cov2/tf TOGETHER with its
       strata argument (crrs.r's signature and its ctype=1 branch both handle
       nc2 > 0 per stratum), so crrs IS the external oracle for the pair. */

    /* A stratum with no cause event is legitimate -- its terms simply drop out
       of the pseudo-likelihood -- but it has NO baseline, so `predict, cif' or
       finegray_cif for that stratum has nothing to answer from and fails
       closed later.  Say so at fit time, where the user can still act on it. */
    if (K_bs > 1) {
        bslev_e = uniqrows(bsraw)
        bs_noev = ""
        bs_noevx = ""
        for (kb = 1; kb <= K_bs; kb++) {
            if (sum(((event_type :== cause) :& (delta :== 1)) :&
                (bsraw :== bslev_e[kb])) == 0) {
                /* Two serializations of the SAME levels.  The %18.0g form
                   is what the user reads in e(bstrata_noevent); it still
                   ROUNDS a noninteger stratum value, so a consumer that
                   string-compares it against a level obtained any other way
                   silently misses.  (strofreal's default %10.0g rendered
                   0.1 and 0.1 + 5 ulp identically, which named the WRONG
                   stratum in the message.)  The %21x form round-trips
                   exactly through Stata's numeric parser and is what every
                   internal consumer compares. */
                bs_noev = bs_noev + " " + strofreal(bslev_e[kb], "%18.0g")
                bs_noevx = bs_noevx + " " + strofreal(bslev_e[kb], "%21x")
            }
        }
        st_local("_fg_bs_noevent", strtrim(bs_noev))
        st_local("_fg_bs_noeventx", strtrim(bs_noevx))
    }

    /* Compute censoring distribution. UNWEIGHTED on the analysis sample
       under pweights (survival::finegray's Gsurv), not Wogu's full cohort;
       see the sampling restriction in the methods help. Replicated under
       fweights, where a subject carrying w copies IS w subjects. */
    if (wtype == 2) {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 0, w)
    }
    else {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0)
    }

    /* The weight design is a function of the data, never of beta.  Prepare one
       copy for both the pre-fit positivity guard and every Newton/line-search
       evaluation instead of constructing the same N-by-strata arrays twice
       before optimization and then again inside each optimizer call. */
    _finegray_prepare_weight_design(t, delta, censval, event_type, G, byg_id,
        t0, tg_id, weight_pooled, weight_gidx, weight_Gminus, weight_A,
        weight_Apool)

    /* bstrata() is refused with delayed entry in the parser (Zhou et al. 2011
       does not cover left truncation, so a stratified ZZF baseline would be an
       unsourced extension).  This is the belt to that brace: the ZZF branch's
       five scan functions have no stratum axis, so reaching them with K > 1
       would silently fit the POOLED-baseline estimator at rc 0. */
    if (weight_pooled & K_bs > 1) {
        errprintf("finegray: bstrata() is not supported with delayed entry\n")
        exit(error(198))
    }

    /* Same reasoning for beta(t): the delayed-entry scans have no piecewise
       form, so a tvc() fit that reached them would report the ordinary
       proportional estimator under a piecewise coefficient stripe. */
    if (weight_pooled & nint > 1) {
        errprintf("finegray: tvc() is not supported with delayed entry\n")
        exit(error(198))
    }

    /* Design-weight scope, belt to finegray.ado's braces.  The weighted
       scan is the right-censoring one (Wogu et al. 2021 eq. 3); the ZZF
       delayed-entry family, the censoring-strata cell, the stratified
       baseline and the piecewise scans have no weighted derivation held,
       and the model-based variance is meaningless under pweights. */
    if (wtype) {
        if (weight_pooled | cols(weight_A) > 1 | K_bs > 1 | nint > 1 |
            nuisance | (wtype == 1 & vce_type == "model")) {
            errprintf("finegray: internal error -- a weighted fit reached ")
            errprintf("a scan cell the parser refuses\n")
            exit(error(498))
        }
    }

    /* Positivity BEFORE the fit.  A degenerate weight is knowable before a
       single Newton step; reporting it as nonconvergence 200 iterations later
       diagnoses the wrong mechanism. */
    npos = _finegray_positivity_check(t, delta, cause, censval, event_type,
        G, byg_id, t0, tg_id, weight_pooled, weight_gidx, weight_Gminus,
        weight_A, weight_Apool)
    if (npos > 0) {
        errprintf("finegray: positivity violation in the delayed-entry weights\n")
        errprintf("  %g consulted joint-stratum denominator cell(s) are zero\n", npos)
        errprintf("  a configured ZZF Weight-1 risk contribution is therefore undefined\n")
        errprintf("  this can occur at an event time or at a retained competing exit\n")
        errprintf("  before enough subjects in that stratum have entered\n")
        errprintf("  affected weight strata: %s\n", st_local("_fg_posstrata"))
        errprintf("  use coarser strata()/truncstrata(), or a later time origin\n")
        exit(error(459))
    }

    /* Starting values: zeros.  ptot == p unless tvc() widened the frame. */
    beta = J(ptot, 1, 0)

    /* Null log-likelihood (beta = 0).  The Fine-Gray partial likelihood has no
       identifiable intercept, so this is the beta=0 null, not a constant-only
       fit. */
    ll_0 = _finegray_loglik_pw(t, delta, cause, censval, event_type, Z,
        J(ptot, 1, 0), G, byg_id, t0, tg_id, weight_pooled, weight_gidx,
        weight_Gminus, weight_A, weight_Apool, bsraw, ivl, fixpos, tvcpos,
        nint, w)
    if (ll_0 >= .) {
        errprintf("finegray: the null log pseudo-likelihood is not finite\n")
        exit(error(430))
    }
    ll = ll_0

    if (show_log) {
        printf("{txt}Iteration 0: log pseudo-likelihood = {res}%12.6f\n", ll)
    }

    converged = 0
    max_halvings = 20

    for (iter = 1; iter <= max_iter; iter++) {
        /* Score and information */
        _finegray_score_info_pw(t, delta, cause, censval, event_type,
            Z, beta, G, byg_id, score_vec, info_mat, t0, tg_id,
            weight_pooled, weight_gidx, weight_Gminus, weight_A,
            weight_Apool, bsraw, ivl, fixpos, tvcpos, nint, w)

        if (hasmissing(info_mat) | hasmissing(score_vec)) {
            errprintf("finegray: the score or information matrix is not ")
            errprintf("finite at iteration %g\n", iter)
            exit(error(430))
        }
        if (rank(info_mat) < ptot)
            _finegray_rank_fail(info_mat, coefnames, ptot)

        info_inv = invsym(info_mat)
        if (missing(info_inv[1,1])) {
            errprintf("finegray: the information matrix is singular\n")
            exit(error(498))
        }

        step = info_inv * score_vec

        /* Convergence on the NEWTON DECREMENT, score' inv(I) score.  This is
           invariant under any linear reparameterization of Z -- in particular
           under rescaling a covariate -- so x and 1e6*x converge at the same
           point and to the same likelihood.  A raw step-size test (|step| <
           sqrt(tol)) is NOT scale free: it is stated on the coefficient scale,
           so rescaling x by 1e6 shrinks beta by 1e6 and the test fires
           immediately, stranding the fit at a worse optimum while still
           reporting converged=1.

           Near the optimum the decrement is ~2*(ll_max - ll), so a decrement
           below tol means the likelihood is within tol/2 of its maximum. */
        decrement = score_vec' * step
        if (decrement < 0) decrement = 0    /* info is PSD; absorb fp noise */

        if (decrement < tol) {
            beta = beta + step
            converged = 1
            break
        }

        /* Step halving.  `accepted' records whether the loop exited with an
           improving beta_new, so the step actually taken is always the one the
           likelihood was evaluated at (testing step_scale after the loop reads
           the NEXT halving, not the accepted one). */
        step_scale = 1
        accepted = 0
        for (halving = 1; halving <= max_halvings; halving++) {
            beta_new = beta + step_scale * step
            ll_new = _finegray_loglik_pw(t, delta, cause, censval,
                event_type, Z, beta_new, G, byg_id, t0, tg_id,
                weight_pooled, weight_gidx, weight_Gminus, weight_A,
                weight_Apool, bsraw, ivl, fixpos, tvcpos, nint, w)

            /* Mata returns exp(overflow) as missing, and (. > x) is TRUE, so a
               bare `ll_new > ll' would accept a missing likelihood as an
               improvement.  Require finiteness explicitly. */
            if (ll_new < . & ll_new > ll) {
                accepted = 1
                break
            }
            step_scale = step_scale / 2
        }

        if (!accepted) {
            /* No improving step at any scale down to 2^-max_halvings, while the
               decrement still predicts an improvement of decrement/2 >= tol/2.
               The line search is stuck; this is not convergence. */
            if (show_log) {
                printf("{txt}Iteration %g: step halving failed;" +
                    " no improving step found\n", iter)
            }
            break
        }

        beta = beta_new
        ll = ll_new

        if (show_log) {
            printf("{txt}Iteration %g: log pseudo-likelihood = {res}%12.6f\n",
                iter, ll)
        }
    }

    /* Nonconvergence is NOT an error here: results are posted with
       converged = 0, matching stcrreg, so a partial fit can still be inspected.
       finegray.ado prints the warning ABOVE the coefficient table (where it
       cannot be scrolled past), and every post-estimation command refuses to
       consume a fit with e(converged) != 1 -- which is where the real hazard
       lived, since finegray_cif/finegray_predict/finegray_phtest read e(b)
       without ever asking whether it converged. */

    /* Recompute the log-likelihood at the ACCEPTED beta.  Every break path
       above must leave e(ll) paired with e(b): the decrement path takes a final
       step after its last likelihood evaluation, so reporting the pre-step ll
       there would post a stale value (with tolerance(1) it posted e(ll) ==
       e(ll_0) exactly while beta was nonzero). */
    ll = _finegray_loglik_pw(t, delta, cause, censval, event_type, Z, beta, G,
        byg_id, t0, tg_id, weight_pooled, weight_gidx, weight_Gminus,
        weight_A, weight_Apool, bsraw, ivl, fixpos, tvcpos, nint, w)
    if (ll >= .) {
        errprintf("finegray: the log pseudo-likelihood is not finite at the ")
        errprintf("solution\n")
        exit(error(430))
    }

    /* Final information for variance */
    _finegray_score_info_pw(t, delta, cause, censval, event_type,
        Z, beta, G, byg_id, score_vec, info_mat, t0, tg_id, weight_pooled,
        weight_gidx, weight_Gminus, weight_A, weight_Apool, bsraw,
        ivl, fixpos, tvcpos, nint, w)
    if (hasmissing(info_mat)) {
        errprintf("finegray: the information matrix is not finite at the ")
        errprintf("solution\n")
        exit(error(430))
    }
    if (rank(info_mat) < ptot) _finegray_rank_fail(info_mat, coefnames, ptot)
    info_inv = invsym(info_mat)
    if (missing(info_inv[1,1])) {
        errprintf("finegray: the information matrix is singular at the ")
        errprintf("solution\n")
        exit(error(498))
    }

    /* Variance estimation */
    n_clust = .
    if (vce_type == "robust" | vce_type == "cluster") {
        if (vce_type == "cluster") {
            clust_id = st_data(., clust_str)
            n_clust = rows(uniqrows(clust_id))

            /* The cluster-robust meat is a sum of g outer products of cluster
               score totals which themselves sum to (approximately) zero at the
               solution, so its rank is at most g-1.  With g <= p the sandwich
               is singular in at least p-g+1 directions and any SE printed for
               those directions is an artefact of invsym()'s g-inverse, not an
               estimate: g=1 previously reported SE = 1.4e-11, and g=2 with p=3
               reported three SEs from a rank-1 variance.  The finite-sample
               factor g/(g-1) is undefined at g=1 as well.  Refuse rather than
               post fabricated precision. */
            if (n_clust < 2) {
                errprintf("finegray: cluster(%s) identifies %g cluster in the ",
                    clust_str, n_clust)
                errprintf("estimation sample\n")
                errprintf("clustered standard errors require at least 2 ")
                errprintf("clusters\n")
                exit(error(459))
            }
            if (n_clust <= ptot) {
                errprintf("finegray: cluster(%s) identifies %g clusters for ",
                    clust_str, n_clust)
                errprintf("%g coefficients\n", ptot)
                errprintf("the clustered variance matrix has rank at most %g, ",
                    n_clust - 1)
                errprintf("so it cannot support %g standard errors\n", ptot)
                errprintf("use more clusters, or fit fewer covariates\n")
                exit(error(459))
            }
        }
        else {
            clust_id = J(n, 1, .)
        }
        V = _finegray_robust_var(t, delta, cause, censval, event_type,
            Z, beta, G, byg_id, info_inv, clust_str, clust_id, t0, tg_id,
            nuisance, weight_pooled, weight_gidx, weight_Gminus, weight_A,
            weight_Apool, bsraw, ivl, fixpos, tvcpos, nint, w, wtype)

        /* Finite-sample adjustment, on by default and suppressed by noadjust.
           This is StataCorp's stcrreg contract exactly: g/(g-1) when clustered,
           N/(N-1) otherwise.  Without it finegray reproduced stcrreg's
           `noadjust' variance while presenting it as the default. */
        /* Under fweights N is the replicated count, sum(w); under pweights
           it is the number of subjects, as in every official estimator. */
        nadj = (wtype == 2 ? sum(w) : n)
        if (adjust) {
            if (vce_type == "cluster") V = V * (n_clust / (n_clust - 1))
            else                       V = V * (nadj / (nadj - 1))
        }
    }
    else {
        V = info_inv
    }

    if (hasmissing(V)) {
        errprintf("finegray: the variance matrix is not finite\n")
        errprintf("the estimated weights or score contributions are numerically unstable\n")
        errprintf("inspect the weight warnings and use coarser strata()/truncstrata()\n")
        exit(error(430))
    }

    /* Compute the baseline hazard ALWAYS -- the scan and Mata cache copy are
       linear.  What is expensive is handing its K ~ n/2 rows to Stata as a
       matrix: that is O(K^2) and was the package's whole superlinearity (see
       the note above _finegray_bh_rebuild), so the Stata matrix stays opt-in.
       Postestimation reads the cache, which is what lets `predict, cif' work on
       NEW data after the estimation sample has been dropped. */
    bh = _finegray_basehazard_pw(t, delta, cause, censval, event_type,
        Z, beta, G, byg_id, t0, tg_id, weight_pooled, weight_gidx,
        weight_Gminus, weight_A, weight_Apool, bsraw, ivl, fixpos, tvcpos,
        nint, w)
    _finegray_bh_store(bh)

    /* Model chi2 degrees of freedom.  Counting positive diagonal entries is
       not the rank: a cluster-robust V can have p positive variances and still
       be singular (2 clusters / 3 coefficients gave df_m = 3 against a rank-1
       V, so the Wald test was referred to a chi2(3) it does not follow).  Use
       the numerical rank, and report it as e(rank) -- the stcrreg contract. */
    rank_V = rank(V)
    df_m = rank_V
    chi2 = beta' * invsym(V) * beta

    /* Combined-weight sensitivity diagnostics (the e() weight contract). */
    _finegray_weight_diag(t, delta, cause, censval, event_type,
        G, byg_id, t0, tg_id, weight_pooled, weight_gidx, weight_Gminus,
        weight_A, weight_Apool)

    /* Post results to Stata matrices */
    st_matrix("_finegray_b", beta')
    st_matrix("_finegray_V", V)
    st_matrix("_finegray_rank", rank_V)
    if (n_clust < .) st_matrix("_finegray_nclust", n_clust)
    if (want_bh) {
        st_matrix("_finegray_basehaz", bh)
        /* K x 2 unstratified -- the shape every released consumer knows -- and
           K x 3 under bstrata(), whose first column is the stratum VALUE. */
        if (cols(bh) == 3) {
            st_matrixcolstripe("_finegray_basehaz",
                (J(3,1,""), ("bstratum" \ "time" \ "cumhazard")))
        }
        else {
            st_matrixcolstripe("_finegray_basehaz",
                (J(2,1,""), ("time" \ "cumhazard")))
        }
    }
    st_matrix("_finegray_ll", ll)
    st_matrix("_finegray_ll_0", ll_0)
    st_matrix("_finegray_chi2", chi2)
    st_matrix("_finegray_df_m", df_m)
    st_matrix("_finegray_conv", converged)
    st_matrix("_finegray_kbstrata", K_bs)
}

/* Influence-function variance of the predicted CIF.

   For each evaluation point (t*, z*) returns CIF(t*|z*) and its standard error
   via per-subject influence functions:

     CIF = 1 - exp(-L0(t*) r),   r = exp(z*'b)
     psi_i(CIF) = factor * ( q_i(t*) + PSIb_i' (b(t*) + L0(t*) z*) )
     factor = r exp(-L0 r),  PSIb_i = info_inv U_i  (U_i = score residual)

   with the Breslow baseline cumulative subhazard L0 and its influence pieces:
     q_i(t*)  = [1/S0(T_i) if i is a cause event <= t*]
                - expeta_i * sum_{cause T_m<=t*} Y^FG_i(T_m)/S0(T_m)^2
     b(t*)    = - sum_{cause T_m<=t*} zbar(T_m)/S0(T_m)
   Y^FG_i(T_m) is i's IPCW weight in the subdistribution risk set at T_m
   (1 if genuinely at risk; G(T_m)/G(T_i) if a past competing event; else 0),
   matching the weights the engine uses to build S0.

   Var(CIF) = sum_i psi_i^2 (cluster-summed when clust_str given). This is the
   influence-function (sandwich) variance treating the IPCW censoring weights as
   known; it is accurate under light-to-moderate censoring but mildly
   anti-conservative under heavy censoring, where the bootstrap option of
   finegray_cif / finegray_predict incorporates refit and weight-estimation
   variation.

   Core routine: given the estimation design (Z, t, t0, delta, event_type, beta,
   byg_id, clust_id) and a k x (1+p) matrix of evaluation points E (col 1 = time,
   cols 2.. = covariate profile), returns a k x 2 matrix (CIF, SE). The two
   public entry points (_st for a Stata matrix of points, _predict for one point
   per observation) both delegate here so the influence-function logic lives in
   one place. */
/* Influence-function CIF for the stratified ZZF equation-7 form.  This is the
   denominator-scale analogue of _finegray_cif_core(): each event contributes
   dL = 1/(A_event*C), an at-risk subject in group g contributes
   1/(A_event*A_g*C^2), and a retained competing subject contributes
   1/(A_event*A_i*C^2).  The IPCW product-limit weights are treated as known,
   matching the package's documented analytic variance contract. */
real matrix _finegray_cif_core_zzf(
    real matrix Z,
    real colvector t,
    real colvector t0,
    real colvector delta,
    real colvector event_type,
    real colvector beta,
    real colvector byg_id,
    real colvector tg_id,
    real colvector clust_id,
    real scalar has_clust,
    real scalar cause,
    real scalar censval,
    real matrix E)
{
    real colvector row_id, G, eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector gidx, Gminus, Apool, score_vec, riskn
    real colvector Tm, dLm, obsm, cumL, Aevent, Ccomp, mstars
    real colvector own, sub, q, psi, cle, clt0, hi, lo, Ccs
    real colvector clust_ord, clust_sum
    real matrix info_mat, info_inv, scores, PSIb, Aden, zbarm, Rm, Rcs, out
    real matrix bvecCS
    real matrix clust_info
    real matrix risk1, bwd1
    real rowvector risk0, bwd0, coreS1, zbar, zstar, bvec
    real scalar n, p, ng, M, ev, i, j, k, idx, ep, g, cur_time, coreS0
    real scalar ii, mp, ne, e, tstar, mstar, m, L0, rstar, cif, factor, V
    real scalar lp, lam
    real scalar use_pooled

    n = rows(Z)
    p = cols(Z)
    /* post-estimation recompute: quiet=1, the fit already printed any note */
    G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1)
    _finegray_prepare_weight_design(t, delta, censval, event_type, G,
        byg_id, t0, tg_id, use_pooled, gidx, Gminus, Aden, Apool)
    ng = cols(Aden)

    _finegray_score_info_zzf_strat(t, delta, cause, censval, event_type,
        Z, beta, G, byg_id, score_vec, info_mat, t0, tg_id, gidx,
        Gminus, Aden, Apool)
    info_inv = _finegray_information_inverse(info_mat, "CIF")
    scores = _finegray_scores_zzf_strat(t, delta, cause, censval,
        event_type, Z, beta, G, byg_id, t0, tg_id, gidx, Gminus, Aden,
        Apool)
    PSIb = scores * info_inv

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))

    M = sum(is_cause)
    Tm = J(M, 1, .)
    dLm = J(M, 1, .)
    obsm = J(M, 1, .)
    Aevent = J(M, 1, .)
    Ccomp = J(M, 1, .)
    zbarm = J(M, p, .)
    Rm = J(M, ng, 0)
    risk0 = J(1, ng, 0)
    riskn = J(ng, 1, 0)
    risk1 = J(ng, p, 0)
    bwd0 = J(1, ng, 0)
    bwd1 = J(ng, p, 0)
    ev = 0
    ep = 1
    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]
        while (ep <= n) {
            if (t0[entry_ord[ep]] >= cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                g = gidx[idx]
                risk0[g] = risk0[g] + expeta[idx]
                riskn[g] = riskn[g] + 1
                risk1[g, .] = risk1[g, .] + expeta[idx] * Z[idx, .]
            }
            ep++
        }
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                coreS0 = 0
                coreS1 = J(1, p, 0)
                for (g = 1; g <= ng; g++) {
                    coreS0 = coreS0 + bwd0[g]
                    coreS1 = coreS1 + bwd1[g, .]
                    if (riskn[g] > 0) {
                        coreS0 = coreS0 + risk0[g] / Aden[idx, g]
                        coreS1 = coreS1 + risk1[g, .] / Aden[idx, g]
                    }
                }
                zbar = coreS1 / coreS0
                ev++
                Tm[ev] = t[idx]
                obsm[ev] = idx
                Aevent[ev] = Aden[idx, gidx[idx]]
                dLm[ev] = 1 / (Aevent[ev] * coreS0)
                Ccomp[ev] = 1 / (Aevent[ev] * coreS0 ^ 2)
                zbarm[ev, .] = zbar
                for (g = 1; g <= ng; g++) {
                    if (riskn[g] > 0) {
                        Rm[ev, g] = 1 /
                            (Aevent[ev] * Aden[idx, g] * coreS0 ^ 2)
                    }
                }
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                g = gidx[idx]
                bwd0[g] = bwd0[g] + expeta[idx] / Gminus[idx]
                bwd1[g, .] = bwd1[g, .] +
                    expeta[idx] / Gminus[idx] * Z[idx, .]
            }
        }
        for (k = i; k < j; k++) {
            idx = ord[k]
            g = gidx[idx]
            risk0[g] = risk0[g] - expeta[idx]
            riskn[g] = riskn[g] - 1
            risk1[g, .] = risk1[g, .] - expeta[idx] * Z[idx, .]
        }
        i = j
    }

    cumL = runningsum(dLm)
    bvecCS = J(M, p, 0)
    for (j = 1; j <= p; j++) {
        bvecCS[., j] = runningsum(zbarm[., j] :* dLm)
    }
    Ccs = 0 \ runningsum(Ccomp)
    Rcs = J(M + 1, ng, 0)
    for (g = 1; g <= ng; g++) {
        Rcs[|2, g \ M + 1, g|] = runningsum(Rm[., g])
    }

    cle = J(n, 1, 0)
    clt0 = J(n, 1, 0)
    mp = 0
    for (ii = 1; ii <= n; ii++) {
        idx = ord[ii]
        while (mp < M) {
            if (Tm[mp + 1] <= t[idx]) mp++
            else break
        }
        cle[idx] = mp
    }
    mp = 0
    for (ii = 1; ii <= n; ii++) {
        idx = entry_ord[ii]
        while (mp < M) {
            if (Tm[mp + 1] <= t0[idx]) mp++
            else break
        }
        clt0[idx] = mp
    }

    if (has_clust) {
        clust_ord = order((clust_id, row_id), (1, 2))
        clust_info = panelsetup(clust_id[clust_ord], 1)
    }

    ne = rows(E)
    /* Return the last cause-event index at/before every evaluation time.
       This avoids a full Tm scan for every requested horizon. */
    mstars = _finegray_step_core((Tm, (1::M)), E[., 1])
    out = J(ne, 2, 0)
    for (e = 1; e <= ne; e++) {
        tstar = E[e, 1]
        zstar = E[e, (2..p + 1)]
        mstar = mstars[e]
        if (mstar == 0) {
            out[e, 1] = 0
            out[e, 2] = 0
            continue
        }
        L0 = cumL[mstar]
        bvec = -bvecCS[mstar, .]
        lp = zstar * beta
        if (lp >= .) {
            /* A missing at() value or coefficient: there is no prediction.
               The reporting layer refuses a missing CIF. */
            out[e, 1] = .; out[e, 2] = .
            continue
        }
        rstar = exp(lp)
        lam = L0 * rstar
        if (lam >= .) {
            /* Overflow at a FINITE profile: same contract as
               _finegray_cif_core below. */
            out[e, 1] = 1; out[e, 2] = 0
            st_local("_fg_cifovf", "1")
            continue
        }
        cif = 1 - exp(-lam)
        factor = rstar * exp(-lam)

        own = J(n, 1, 0)
        for (m = 1; m <= mstar; m++) {
            own[obsm[m]] = own[obsm[m]] + dLm[m]
        }
        hi = (cle :> mstar) :* mstar :+ (cle :<= mstar) :* cle
        lo = (clt0 :> hi) :* hi :+ (clt0 :<= hi) :* clt0
        sub = J(n, 1, 0)
        for (i = 1; i <= n; i++) {
            g = gidx[i]
            sub[i] = Rcs[hi[i] + 1, g] - Rcs[lo[i] + 1, g]
            if (is_compete[i]) {
                sub[i] = sub[i] +
                    (Ccs[mstar + 1] - Ccs[hi[i] + 1]) / Gminus[i]
            }
        }
        q = own - expeta :* sub
        psi = factor :* (q + PSIb * (bvec + L0 * zstar)')

        /* colsum() drops missing entries, so a missing influence contribution
           would silently shrink the variance.  A missing SE is the honest
           report. */
        if (hasmissing(psi)) V = .
        else if (has_clust) {
            clust_sum = panelsum(psi[clust_ord], clust_info)
            V = colsum(clust_sum :^ 2)
        }
        else V = colsum(psi :^ 2)
        out[e, 1] = cif
        out[e, 2] = sqrt(V)
    }
    return(out)
}

/* ------------------------------------------------------------------------
   The CIF influence function's per-baseline accumulators, extracted VERBATIM
   from _finegray_cif_core so that the piecewise variant can reuse them rather
   than copy them.

   WHY EXTRACTED RATHER THAN COPIED.  Under tvc() the analytic CIF variance is
   the SAME construction run once per interval on that interval's masked event
   set and zeroed design, then summed -- the fifth application of the pattern
   the four _pw scan wrappers already use.  A copied accumulator drifts from its
   original in BOTH directions, which is a defect class this repo has already
   paid for, so the unstratified, un-piecewise path calls exactly these lines in
   exactly this order and every shipped analytic CIF standard error is
   bit-identical to what it was before.

   Everything here is a function of (data, beta) and of the row subset ordk --
   never of the evaluation point -- which is what makes it hoistable out of the
   per-horizon loop, and now out of the per-interval loop as well.

   OUT-ARGUMENTS (by reference):
     M           number of cause events in this subset
     Tm, obsm    their times (ascending) and row indices
     invS0       1/S0 at each; cum_invS0 its running sum, i.e. Lambda_0
     bvecCS      running sum of zbar/S0 -- d Lambda_0 / d beta, cumulated
     Acs, Bcs    the two prefix-sum families the `sub' term collapses to
     cle, clt0   per-row counts of cause events at/below exit and entry
   Returns 0 when the subset carried no cause event (nothing else is set and the
   caller must skip), 1 otherwise. */
real scalar _finegray_cif_accum(
    real colvector t,
    real colvector t0,
    real matrix Z,
    real colvector expeta,
    real colvector is_cause,
    real colvector is_compete,
    real matrix Gt,
    real colvector Gminus,
    real colvector gidx,
    real scalar ng,
    real colvector ordk,
    real colvector inkk,
    real colvector entry_ordk,
    real scalar n,
    real scalar p,
    real scalar M,
    real colvector Tm,
    real colvector obsm,
    real colvector invS0,
    real colvector cum_invS0,
    real matrix bvecCS,
    real matrix Acs,
    real matrix Bcs,
    real colvector cle,
    real colvector clt0,
    | real colvector w)
{
    real scalar i, j, k, g, ev, ep, ii, idx, mp, nk, cur_time, risk_S0, S0_t
    real rowvector risk_S1, S1_t, bwd_s0_raw
    real colvector S0m, invS0sq, wexpeta, wm, dLm
    real matrix Gm, zbarm, bwd_s1_raw, GmInvS0sq

    if (args() < 26) w = J(rows(t), 1, 1)
    wexpeta = w :* expeta
    nk = length(ordk)
    /* Event scan: per cause-event arrays in ascending time */
    M = sum(select(is_cause, inkk))
    if (M == 0) return(0)
    Tm = J(M, 1, .); S0m = J(M, 1, .); Gm = J(M, ng, .); obsm = J(M, 1, .)
    zbarm = J(M, p, .)
    risk_S0 = 0; risk_S1 = J(1, p, 0); ep = 1
    bwd_s0_raw = J(1, ng, 0); bwd_s1_raw = J(ng, p, 0); ev = 0; i = 1
    while (i <= nk) {
        cur_time = t[ordk[i]]
        /* Add entries: (t0, t] means t0 < cur_time */
        while (ep <= nk) {
            if (t0[entry_ordk[ep]] >= cur_time) break
            idx = entry_ordk[ep]
            if (t[idx] >= cur_time) {
                risk_S0 = risk_S0 + wexpeta[idx]
                risk_S1 = risk_S1 + wexpeta[idx] * Z[idx, .]
            }
            ep++
        }
        j = i
        while (j <= nk) {
            if (t[ordk[j]] != cur_time) break
            j++
        }
        for (k = i; k < j; k++) {
            idx = ordk[k]
            if (is_cause[idx]) {
                S0_t = risk_S0 + Gt[idx, .] * bwd_s0_raw'
                S1_t = risk_S1 + Gt[idx, .] * bwd_s1_raw
                ev++
                Tm[ev] = t[idx]; S0m[ev] = S0_t
                Gm[ev, .] = Gt[idx, .]; obsm[ev] = idx
                zbarm[ev, .] = S1_t / S0_t
            }
        }
        for (k = i; k < j; k++) {
            idx = ordk[k]
            if (is_compete[idx]) {
                g = gidx[idx]
                bwd_s0_raw[g] = bwd_s0_raw[g] + wexpeta[idx] / Gminus[idx]
                bwd_s1_raw[g, .] = bwd_s1_raw[g, .] +
                    wexpeta[idx] / Gminus[idx] * Z[idx, .]
            }
        }
        for (k = i; k < j; k++) {
            idx = ordk[k]
            risk_S0 = risk_S0 - wexpeta[idx]
            risk_S1 = risk_S1 - wexpeta[idx] * Z[idx, .]
        }
        i = j
    }
    /* Weighted Breslow increments dL_m = w_m / S0_w(T_m).  invS0 stays the
       per-unit-weight 1/S0 because it feeds the subject's OWN-event term,
       whose outer w_i _finegray_cif_core applies once to the whole
       influence function; every sum over OTHER events carries w_m here.
       With w == 1, wm :/ S0m is 1 :/ S0m element for element. */
    wm = w[obsm]
    dLm = wm :/ S0m
    cum_invS0 = runningsum(dLm)

    /* --- Prefix-sum scaffolding for the influence-function `sub' term ------
       The original per-eval-point loop over the cause events accumulated, for
       each observation i,
         sub_i = sum_{m<=mstar} [ 1{t0_i<Tm[m]<=t_i}                        (at-risk)
                                  + is_compete_i * 1{t_i<Tm[m]} * Gm[m]/G_i ] (fictitious)
                                 / S0m[m]^2,
       an O(M*n) inner loop per point. The two indicator families are step
       functions of the sorted cause-event times (Tm ascending), so cumulative
       sums over m collapse each observation's contribution to O(1):
         at-risk term    = A[hi_i] - A[lo_i],       A[k] = sum_{m<=k} 1/S0m^2
         fictitious term = (B[mstar]-B[hi_i])/G_i,  B[k] = sum_{m<=k} Gm/S0m^2
       with hi_i = #{m<=mstar : Tm[m]<=t_i}  and  lo_i = #{m<=mstar : Tm[m]<=t0_i}.
       The risk window is (t0_i, T_i] -- half-open at entry -- so lo_i counts
       events AT t0_i as excluded, matching the engine's (t0, t] risk sets.
       cle/clt0 (counts of cause events at/below each observation's exit/entry)
       are eval-point independent, so they are built once via two-pointer merges
       over the ascending Tm array.  Preprocessing is O(n log n); after that,
       each requested horizon needs one O(n) influence-function assembly.
       Under bstrata() they are built over THIS stratum's rows only, and a row
       outside the stratum keeps cle = clt0 = 0, so its at-risk term is exactly
       zero -- it was never in this baseline's risk sets. */
    invS0     = 1 :/ S0m
    invS0sq   = wm :/ (S0m :^ 2)
    GmInvS0sq = (Gm :* (wm * J(1, ng, 1))) :/ ((S0m :^ 2) * J(1, ng, 1))
    Acs = 0 \ runningsum(invS0sq)          /* Acs[k+1] = sum_{m<=k} 1/S0m^2 */
    /* One censoring-KM column per group.  runningsum() takes a vector only, so
       accumulate column by column -- Gm is M x ng whenever bygroup() strata are
       in play (ng > 1) and a whole-matrix call would exit 3201. */
    Bcs = J(M + 1, ng, 0)
    for (g = 1; g <= ng; g++) {
        Bcs[|2, g \ M + 1, g|] = runningsum(GmInvS0sq[., g])
    }
    bvecCS = J(M, p, 0)
    for (j = 1; j <= p; j++) {
        bvecCS[., j] = runningsum(zbarm[., j] :* dLm)
    }

    cle  = J(n, 1, 0)                       /* #{cause events with Tm <= t_i}  */
    clt0 = J(n, 1, 0)                       /* #{cause events with Tm <= t0_i} */
    mp = 0
    for (ii = 1; ii <= nk; ii++) {
        idx = ordk[ii]
        /* Mata & is not short-circuit: guard Tm[mp+1] with a nested test */
        while (mp < M) {
            if (Tm[mp + 1] <= t[idx]) mp++
            else break
        }
        cle[idx] = mp
    }
    mp = 0
    for (ii = 1; ii <= nk; ii++) {
        idx = entry_ordk[ii]
        while (mp < M) {
            if (Tm[mp + 1] <= t0[idx]) mp++
            else break
        }
        clt0[idx] = mp
    }
    return(1)
}

real matrix _finegray_cif_core(
    real matrix Z,
    real colvector t,
    real colvector t0,
    real colvector delta,
    real colvector event_type,
    real colvector beta,
    real colvector byg_id,
    real colvector tg_id,
    real colvector clust_id,
    real scalar has_clust,
    real scalar cause,
    real scalar censval,
    real matrix E,
    | real colvector bsraw,
    real colvector Etarget,
    real colvector w,
    real scalar wtype)
{
    real colvector row_id
    real colvector G, eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector Tm, S0m, obsm, cum_invS0, own, sub, q, psi, score_vec
    real colvector mstars
    real colvector gidx, Gminus, Apool, clust_ord, clust_sum
    real colvector cle, clt0, Acs, invS0, invS0sq, hi, lo
    real colvector bslev, bscode, ordk, entry_ordk, evsel, inkk
    real matrix info_mat, info_inv, scores, PSIb, zbarm, out, Gt, Gm
    real matrix bwd_s1_raw, Bcs, GmInvS0sq, clust_info, bvecCS
    real rowvector risk_S1, bwd_s0_raw, zstar, bvec, S1_t, Bmstar
    real scalar n, p, i, j, k, idx, ep, cur_time, risk_S0, S0_t
    real scalar M, ev, ne, e, tstar, mstar, m, L0, rstar, cif, factor, V
    real scalar lp, lam
    real scalar mp, ii, g, ng, use_pooled, nk, kk, K, nev, ee

    if (args() < 14) bsraw = J(rows(t), 1, 1)

    if (_finegray_use_pooled_stabilizer(t0, byg_id, tg_id)) {
        return(_finegray_cif_core_zzf(Z, t, t0, delta, event_type, beta,
            byg_id, tg_id, clust_id, has_clust, cause, censval, E))
    }

    n = rows(Z)
    p = cols(Z)
    ne = rows(E)

    if (args() < 15) Etarget = J(ne, 1, 1)
    if (args() < 16) w = J(n, 1, 1)
    if (args() < 17) wtype = 0

    /* post-estimation recompute: quiet=1, the fit already printed any note */
    if (wtype == 2) {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1, w)
    }
    else {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1)
    }
    /* ZZF: the weight is now A = G(t-)H(t-) on CROSS-CLASSIFIED strata.  With no
       delayed entry H == 1 and this is bit-identical to the former G-only path. */
    _finegray_prepare_weight_design(t, delta, censval, event_type, G,
        byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
    ng = cols(Gt)

    _finegray_score_info(t, delta, cause, censval, event_type, Z, beta, G,
        byg_id, score_vec, info_mat, t0, tg_id, use_pooled, gidx,
        Gminus, Gt, Apool, bsraw, w)
    info_inv = _finegray_information_inverse(info_mat, "CIF")

    scores = _finegray_score_residuals(t, delta, cause, censval, event_type,
        Z, beta, G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt,
        Apool, bsraw, w)
    PSIb = scores * info_inv

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)
    /* Deterministic tie-break by row index.  Mata's order() resolves ties
       using Stata's sort seed, which ADVANCES on every sort, so a tied key
       (every t0 == 0 when there is no delayed entry) yields a different
       permutation on each call -- and the risk-set scan then accumulates in
       a different floating-point order.  Without this the same command on
       the same data is not bit-reproducible. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))

    if (has_clust) {
        clust_ord = order((clust_id, row_id), (1, 2))
        clust_info = panelsetup(clust_id[clust_ord], 1)
    }

    _finegray_bs_setup(bsraw, bslev, bscode, K)

    out = J(ne, 2, 0)

    /* bstrata(): each stratum has its OWN baseline, so CIF(t*|z*) is a
       stratum-specific quantity.  The event scan, its prefix sums and the
       influence-function assembly all run within the stratum an evaluation
       point asks for; beta -- and hence PSIb, computed once above -- is shared,
       which is exactly the model's structure (shared beta, free baselines).
       Every quantity a subject outside the stratum contributes to that
       stratum's baseline is identically zero, so its influence enters only
       through the shared-beta term. */
    for (kk = 1; kk <= K; kk++) {
        if (K <= 1) {
            evsel = (1::ne)
            inkk = J(n, 1, 1)
        }
        else {
            evsel = selectindex(Etarget :== bslev[kk])
            inkk = (bscode :== kk)
        }
        nev = length(evsel)
        if (nev == 0) continue

        ordk = _finegray_bs_rows(ord, bscode, kk, K)
        entry_ordk = _finegray_bs_rows(entry_ord, bscode, kk, K)
        nk = length(ordk)
        if (nk == 0) continue

        /* Per-baseline accumulators.  Extracted to _finegray_cif_accum so the
           piecewise variant reuses these lines rather than copying them; the
           call below passes exactly what the inlined code used, in the same
           order, so the arithmetic here is unchanged. */
        if (!_finegray_cif_accum(t, t0, Z, expeta, is_cause, is_compete, Gt,
            Gminus, gidx, ng, ordk, inkk, entry_ordk, n, p, M, Tm, obsm,
            invS0, cum_invS0, bvecCS, Acs, Bcs, cle, clt0, w)) continue

        /* Binary lookup replaces an O(M) cause-time scan at every horizon. */
        mstars = _finegray_step_core((Tm, (1::M)), E[evsel, 1])
        for (ee = 1; ee <= nev; ee++) {
            e = evsel[ee]
            tstar = E[e, 1]
            zstar = E[e, (2..p + 1)]
            mstar = mstars[ee]
            if (mstar == 0) {
                out[e, 1] = 0; out[e, 2] = 0
                continue
            }
            L0 = cum_invS0[mstar]
            bvec = -bvecCS[mstar, .]
            lp = zstar * beta
            if (lp >= .) {
                /* A missing at() value or coefficient: there is no
                   prediction.  The reporting layer refuses a missing CIF. */
                out[e, 1] = .; out[e, 2] = .
                continue
            }
            rstar = exp(lp)
            lam = L0 * rstar
            if (lam >= .) {
                /* exp(lp), or L0 exp(lp), exceeds maxdouble at a FINITE
                   profile (at(x=-20000) on a fit with beta < 0).  Lambda is
                   then above 8.9e307, exp(-Lambda) is 0 and the CIF is 1 to
                   double precision; the influence factor exp(lp - Lambda)
                   underflows to 0, so the delta-method SE is 0 -- the answer
                   the arithmetic below gives one step short of the overflow
                   (x=-800 on the same fit: (1, 0)).  Through 1.3.0 the
                   missing rstar propagated into the CIF and the influence
                   vector, and colsum() treated the missing contributions as
                   zeros: (cif, se) = (., 0) at rc 0.  L0 > 0 whenever
                   mstar > 0, so the product cannot be a 0 * missing.  The
                   local tells finegray_cif to print a note. */
                out[e, 1] = 1; out[e, 2] = 0
                st_local("_fg_cifovf", "1")
                continue
            }
            cif = 1 - exp(-lam)
            factor = rstar * exp(-lam)

            own = J(n, 1, 0)
            for (m = 1; m <= mstar; m++) own[obsm[m]] = invS0[m]

            /* hi_i = #{m<=mstar : Tm[m]<=t_i}; lo_i = #{m<=mstar : Tm[m]<=t0_i} */
            hi = (cle :> mstar) :* mstar :+ (cle :<= mstar) :* cle
            lo = (clt0 :> hi) :* hi :+ (clt0 :<= hi) :* clt0
            Bmstar = Bcs[mstar + 1, .]
            sub = Acs[hi :+ 1] - Acs[lo :+ 1]
            for (i = 1; i <= n; i++) {
                if (is_compete[i] & inkk[i]) {
                    g = gidx[i]
                    sub[i] = sub[i] +
                        (Bmstar[g] - Bcs[hi[i] + 1, g]) / Gminus[i]
                }
            }
            q = own - expeta :* sub
            psi = factor :* (q + PSIb * (bvec + L0 * zstar)')

            /* Design weights enter the influence function once, as the
               subject's outer factor: pweight meat sum_i (w_i psi_i)^2,
               fweight meat sum_i w_i psi_i^2 (w_i independent copies), and
               under cluster() the w_i psi_i are summed within cluster first
               for either type.  wtype == 0 leaves the shipped lines. */
            /* colsum() drops missing entries, so a missing influence
               contribution would silently shrink the variance.  A missing SE
               is the honest report. */
            if (hasmissing(psi)) V = .
            else if (has_clust) {
                if (wtype) psi = w :* psi
                clust_sum = panelsum(psi[clust_ord], clust_info)
                V = colsum(clust_sum :^ 2)
            }
            else if (wtype == 1) V = colsum((w :* psi) :^ 2)
            else if (wtype == 2) V = colsum(w :* (psi :^ 2))
            else V = colsum(psi :^ 2)

            out[e, 1] = cif
            out[e, 2] = sqrt(V)
        }
    }
    return(out)
}

/* ------------------------------------------------------------------------
   ANALYTIC CIF VARIANCE UNDER A PIECEWISE beta(t).

   v1.3.0 refused this: the shipped influence function assumes ONE exp(z'b)
   multiplies every Breslow increment, and under beta(t) each increment carries
   its own interval's linear predictor.  Re-derived 2026-08-26; the derivation
   is written out below.

   THE ESTIMAND.  With interval j = (tau_{j-1}, tau_j] and m_j(s) the baseline
   mass falling inside interval j up to s,

       Lambda(s|z) = sum_j m_j(s) exp(eta_j(z)),   CIF = 1 - exp(-Lambda)

   which is already what the POINT estimate computes (v1.3.0).

   THE INFLUENCE FUNCTION.  Differentiate, and note that the interval
   decomposition is an IDENTITY (interval j's baseline mass is exactly what the
   unmodified scan returns on interval j's masked event set and zeroed design):

       dLambda = sum_j exp(eta_j) dm_j  +  sum_j m_j exp(eta_j) d eta_j

   dm_j has the same two parts the unstratified case has -- a direct part q_j
   (subject i's influence on interval j's Breslow increments at fixed beta) and
   a part through beta-hat -- and d eta_j = z*_j' d beta where z*_j is the
   profile written in the p' frame with only the fixed block and interval j's
   own block nonzero.  So

     psi_i = exp(-Lambda) [ sum_j e^{eta_j} q_{j,i}
                            + PSIb_i ( sum_j e^{eta_j} bvec_j
                                       + sum_j m_j e^{eta_j} z*_j )' ]

   THE CHECK THAT MATTERS.  At J = 1 this must collapse to the shipped formula,
   and it does, term for term: m_1 = L0, e^{eta_1} = rstar, bvec_1 = bvec,
   z*_1 = z*, so psi = rstar exp(-L0 rstar) [ q + PSIb (bvec + L0 z*)' ], which
   is `factor :* (q + PSIb * (bvec + L0 * zstar)')' in _finegray_cif_core.  That
   collapse is asserted numerically, not just algebraically, by the J = 1
   agreement arm in qa/test_finegray_tvc.do.

   EVERY per-interval quantity comes from _finegray_cif_accum -- the SAME lines
   _finegray_cif_core calls -- so no accumulator is duplicated and none can
   drift.  Only the combination above is new. */
real matrix _finegray_cif_core_pw(
    real matrix Z,
    real colvector t,
    real colvector t0,
    real colvector delta,
    real colvector event_type,
    real colvector beta,
    real colvector byg_id,
    real colvector tg_id,
    real colvector clust_id,
    real scalar has_clust,
    real scalar cause,
    real scalar censval,
    real matrix E,
    real colvector bsraw,
    real colvector Etarget,
    real colvector ivl,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint)
{
    real colvector row_id, G, gidx, Gminus, Apool, is_compete, ord, entry_ord
    real colvector score_vec, clust_ord, clust_sum, bslev, bscode
    real colvector ordk, entry_ordk, evsel, inkk, etj, is_cause_j, expeta_j
    real colvector own, sub, q, psi, hi, lo, mstarv, chunk
    real colvector Tml, obsml, invS0l, cuml, clel, clt0l, LAM, OVF
    real matrix info_mat, info_inv, scores, PSIb, Gt, clust_info, Dj
    real matrix out, bvecl, Acsl, Bcsl, DPSI, BACC
    real rowvector zstar, zj, Bmstar
    real scalar n, p, pt, ne, ng, use_pooled, K, kk, nev, ee, e, i, j, g
    real scalar M_j, mstar, m, V, mj, ej, tstar, expo, c0, c1, nc, cs, ok
    real scalar lpj

    /* Chunk width for the per-evaluation-point influence columns.  The
       accumulators below are rebuilt once per chunk per interval (O(n log n)),
       and DPSI holds n x nc doubles, so this trades a handful of rebuilds for a
       bounded footprint: curve mode asks for up to 400 horizons, and a
       400-column n x ne matrix at n = 50,000 is 160 MB. */
    cs = 64

    if (_finegray_use_pooled_stabilizer(t0, byg_id, tg_id)) {
        errprintf("finegray: the analytic CIF variance under tvc() is derived ")
        errprintf("for right censoring only\n")
        exit(error(198))
    }

    n = rows(Z)
    p = cols(Z)
    pt = rows(beta)
    ne = rows(E)

    G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1)
    _finegray_prepare_weight_design(t, delta, censval, event_type, G,
        byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)
    ng = cols(Gt)

    /* beta-hat's own influence, in the FULL p' frame: the piecewise score and
       information, exactly as the fit formed them. */
    _finegray_score_info_pw(t, delta, cause, censval, event_type, Z, beta, G,
        byg_id, score_vec, info_mat, t0, tg_id, use_pooled, gidx, Gminus, Gt,
        Apool, bsraw, ivl, fixpos, tvcpos, nint)
    info_inv = _finegray_information_inverse(info_mat, "CIF")
    scores = _finegray_score_residuals_pw(t, delta, cause, censval, event_type,
        Z, beta, G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool,
        bsraw, ivl, fixpos, tvcpos, nint)
    PSIb = scores * info_inv

    is_compete = (event_type :!= cause) :& (event_type :!= censval) :&
        (delta :== 1)
    row_id = (1::n)
    ord = order((t, row_id), (1, 2))
    entry_ord = order((t0, row_id), (1, 2))

    if (has_clust) {
        clust_ord = order((clust_id, row_id), (1, 2))
        clust_info = panelsetup(clust_id[clust_ord], 1)
    }

    _finegray_bs_setup(bsraw, bslev, bscode, K)

    out = J(ne, 2, 0)

    for (kk = 1; kk <= K; kk++) {
        if (K <= 1) {
            evsel = (1::ne)
            inkk = J(n, 1, 1)
        }
        else {
            /* select(), not selectindex(): a single matching evaluation point
               would come back as a 1 x 0 ROW vector. */
            evsel = select((1::ne), Etarget :== bslev[kk])
            inkk = (bscode :== kk)
        }
        nev = rows(evsel)
        if (nev == 0) continue

        ordk = _finegray_bs_rows(ord, bscode, kk, K)
        entry_ordk = _finegray_bs_rows(entry_ord, bscode, kk, K)
        if (length(ordk) == 0) continue

        for (c0 = 1; c0 <= nev; c0 = c0 + cs) {
            c1 = min((c0 + cs - 1, nev))
            nc = c1 - c0 + 1
            chunk = evsel[|c0 \ c1|]

            LAM  = J(nc, 1, 0)
            OVF  = J(nc, 1, 0)
            DPSI = J(n, nc, 0)
            BACC = J(nc, pt, 0)

            /* INTERVAL OUTER, evaluation points inner: each interval's
               accumulators are built once and consumed by every horizon in the
               chunk.  They come from _finegray_cif_accum -- the same lines
               _finegray_cif_core calls -- so nothing is duplicated. */
            for (j = 1; j <= nint; j++) {
                etj = _finegray_tvc_mask(event_type, cause, censval, ivl, j)
                Dj = _finegray_tvc_design(Z, fixpos, tvcpos, nint, j)
                is_cause_j = (etj :== cause) :& (delta :== 1)
                expeta_j = exp(Dj * beta)

                M_j = 0
                ok = _finegray_cif_accum(t, t0, Dj, expeta_j, is_cause_j,
                    is_compete, Gt, Gminus, gidx, ng, ordk, inkk, entry_ordk,
                    n, pt, M_j, Tml, obsml, invS0l, cuml, bvecl, Acsl, Bcsl,
                    clel, clt0l)
                if (!ok) continue

                mstarv = _finegray_step_core((Tml, (1::M_j)), E[chunk, 1])

                for (ee = 1; ee <= nc; ee++) {
                    mstar = mstarv[ee]
                    if (mstar == 0) continue
                    e = chunk[ee]
                    zstar = E[e, (2..p + 1)]
                    zj = _finegray_tvc_design(zstar, fixpos, tvcpos, nint, j)
                    lpj = zj * beta
                    mj = cuml[mstar]
                    if (lpj >= .) {
                        /* Nonfinite linear predictor: no prediction.  A
                           missing LAM stays missing through every later
                           interval and is refused below. */
                        LAM[ee] = .
                        continue
                    }
                    ej = exp(lpj)
                    if (ej >= . | mj * ej >= .) {
                        /* Overflow at a FINITE profile: same contract as
                           _finegray_cif_core.  mj > 0 whenever mstar > 0, so
                           Lambda is above maxdouble, the CIF is 1 to double
                           precision and every influence term carries
                           exp(-Lambda) = 0. */
                        OVF[ee] = 1
                        continue
                    }
                    LAM[ee] = LAM[ee] + mj * ej

                    own = J(n, 1, 0)
                    for (m = 1; m <= mstar; m++) own[obsml[m]] = invS0l[m]
                    hi = (clel :> mstar) :* mstar :+ (clel :<= mstar) :* clel
                    lo = (clt0l :> hi) :* hi :+ (clt0l :<= hi) :* clt0l
                    Bmstar = Bcsl[mstar + 1, .]
                    sub = Acsl[hi :+ 1] - Acsl[lo :+ 1]
                    for (i = 1; i <= n; i++) {
                        if (is_compete[i] & inkk[i]) {
                            g = gidx[i]
                            sub[i] = sub[i] +
                                (Bmstar[g] - Bcsl[hi[i] + 1, g]) / Gminus[i]
                        }
                    }
                    q = own - expeta_j :* sub
                    DPSI[., ee] = DPSI[., ee] + ej :* q
                    BACC[ee, .] = BACC[ee, .] + ej * (-bvecl[mstar, .]) +
                        (mj * ej) * zj
                }
            }

            for (ee = 1; ee <= nc; ee++) {
                e = chunk[ee]
                if (LAM[ee] >= .) {
                    out[e, 1] = .; out[e, 2] = .
                    continue
                }
                if (OVF[ee]) {
                    out[e, 1] = 1; out[e, 2] = 0
                    st_local("_fg_cifovf", "1")
                    continue
                }
                expo = exp(-LAM[ee])
                psi = expo :* (DPSI[., ee] + PSIb * BACC[ee, .]')
                /* colsum() drops missing entries; see _finegray_cif_core. */
                if (hasmissing(psi)) V = .
                else if (has_clust) {
                    clust_sum = panelsum(psi[clust_ord], clust_info)
                    V = colsum(clust_sum :^ 2)
                }
                else V = colsum(psi :^ 2)
                out[e, 1] = 1 - expo
                out[e, 2] = sqrt(V)
            }
        }
    }
    return(out)
}

/* Read estimation design + a Stata matrix of evaluation points; post CIF/SE. */
void _finegray_cif_var_st(
    string scalar zvars,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar tg_str,
    string scalar clust_str,
    string scalar tousevar,
    string scalar evalmat,
    string scalar outmat,
    string scalar t0var,
    | string scalar bsvar,
    real scalar lev,
    string scalar tvc_str,
    string scalar tsplit_str,
    string scalar w_str,
    real scalar wtype)
{
    real matrix Z, E, out
    real colvector t, t0, delta, event_type, beta, byg_id, tg_id, clust_id
    real colvector bsraw, cuts, ivl, fixpos, tvcpos, w
    real scalar n, has_clust, nint

    if (args() < 12) bsvar = ""
    if (args() < 13) lev = .
    if (args() < 14) tvc_str = ""
    if (args() < 15) tsplit_str = ""
    if (args() < 16) w_str = ""
    if (args() < 17) wtype = 0

    Z = st_data(., tokens(zvars), tousevar)
    t = st_data(., "_t", tousevar)
    t0 = st_data(., t0var, tousevar)
    delta = st_data(., "_d", tousevar)
    event_type = st_data(., events_str, tousevar)
    n = rows(Z)
    beta = _finegray_beta()
    if (byg_str != "") byg_id = st_data(., byg_str, tousevar)
    else byg_id = J(n, 1, 1)
    if (tg_str != "") tg_id = st_data(., tg_str, tousevar)
    else tg_id = J(n, 1, 1)
    has_clust = (clust_str != "")
    if (has_clust) clust_id = st_data(., clust_str, tousevar)
    else clust_id = J(n, 1, .)

    /* bstrata(): every point in this call belongs to ONE stratum -- the one
       finegray_cif's bstratum() named -- because at() no longer identifies a
       curve once the baselines are free. */
    if (bsvar != "") bsraw = st_data(., bsvar, tousevar)
    else             bsraw = J(n, 1, 1)
    if (w_str != "") w = st_data(., w_str, tousevar)
    else             w = J(n, 1, 1)

    E = st_matrix(evalmat)
    /* tvc(): the analytic variance is the piecewise one (2026-08-26).  Both routes
       reach the SAME accumulators through _finegray_cif_accum; only the
       combination over intervals differs. */
    if (tvc_str != "" & tsplit_str != "") {
        /* tvc() x weights is refused at the fit; the piecewise influence
           function has no weight argument and must never be handed one. */
        if (wtype) {
            errprintf("finegray: internal error -- weighted tvc() CIF\n")
            exit(error(498))
        }
        cuts = strtoreal(tokens(tsplit_str))'
        nint = rows(cuts) + 1
        _finegray_tvc_positions(tvc_str, cols(Z), fixpos, tvcpos)
        ivl = _finegray_tvc_interval(t, cuts)
        out = _finegray_cif_core_pw(Z, t, t0, delta, event_type, beta, byg_id,
            tg_id, clust_id, has_clust, cause, censval, E, bsraw,
            J(rows(E), 1, (bsvar != "" ? lev : 1)), ivl, fixpos, tvcpos, nint)
    }
    else {
        out = _finegray_cif_core(Z, t, t0, delta, event_type, beta, byg_id,
            tg_id, clust_id, has_clust, cause, censval, E, bsraw,
            J(rows(E), 1, (bsvar != "" ? lev : 1)), w, wtype)
    }
    st_matrix(outmat, out)
}

/* Per-observation CIF + SE: evaluate at each eval-sample observation's own time
   (tvar) and covariate profile, storing into cifvar and sevar. The estimation
   design is read from est_touse (e(sample)); the evaluation points from
   eval_touse (predict's if/in sample). */
void _finegray_cif_predict(
    string scalar zvars,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar tg_str,
    string scalar clust_str,
    string scalar est_touse,
    string scalar eval_touse,
    string scalar tvar,
    string scalar sevar,
    string scalar t0var,
    | string scalar bsvar,
    string scalar tvc_str,
    string scalar tsplit_str,
    string scalar w_str,
    real scalar wtype)
{
    real matrix Z, Zev, E, out
    real colvector t, t0, delta, event_type, beta, byg_id, tg_id, clust_id
    real colvector etouse, sel, tev, bsraw, bstarget, w
    real colvector cuts, ivl, fixpos, tvcpos
    real scalar n, has_clust, nint

    /* bsvar is argument 13, tvc_str 14, tsplit_str 15 -- count them.  The
       pre-existing guard here read `args() < 12', an off-by-one that was
       harmless only because bsvar was always supplied; carrying the same
       mistake forward blanked tsplit_str on every call and silently routed a
       tvc() fit into the PROPORTIONAL influence function, where it died on a
       conformability error (e(b) is p' wide, Z is p). */
    if (args() < 13) bsvar = ""
    if (args() < 14) tvc_str = ""
    if (args() < 15) tsplit_str = ""
    if (args() < 16) w_str = ""
    if (args() < 17) wtype = 0

    Z = st_data(., tokens(zvars), est_touse)
    t = st_data(., "_t", est_touse)
    t0 = st_data(., t0var, est_touse)
    delta = st_data(., "_d", est_touse)
    event_type = st_data(., events_str, est_touse)
    n = rows(Z)
    beta = _finegray_beta()
    if (byg_str != "") byg_id = st_data(., byg_str, est_touse)
    else byg_id = J(n, 1, 1)
    if (tg_str != "") tg_id = st_data(., tg_str, est_touse)
    else tg_id = J(n, 1, 1)
    has_clust = (clust_str != "")
    if (has_clust) clust_id = st_data(., clust_str, est_touse)
    else clust_id = J(n, 1, .)

    etouse = st_data(., eval_touse)
    sel = selectindex(etouse :!= 0)
    tev = st_data(sel, tvar)
    Zev = st_data(sel, tokens(zvars))
    E = (tev, Zev)

    /* bstrata(): each evaluation row is answered from the baseline of ITS OWN
       stratum, so the target vector is that row's bstrata() value. */
    if (bsvar != "") {
        bsraw = st_data(., bsvar, est_touse)
        bstarget = st_data(sel, bsvar)
    }
    else {
        bsraw = J(n, 1, 1)
        bstarget = J(length(sel), 1, 1)
    }
    if (w_str != "") w = st_data(., w_str, est_touse)
    else             w = J(n, 1, 1)

    /* tvc(): the piecewise influence function (2026-08-26).  Both routes reach the
       same accumulators through _finegray_cif_accum. */
    if (tvc_str != "" & tsplit_str != "") {
        if (wtype) {
            errprintf("finegray: internal error -- weighted tvc() CIF\n")
            exit(error(498))
        }
        cuts = strtoreal(tokens(tsplit_str))'
        nint = rows(cuts) + 1
        _finegray_tvc_positions(tvc_str, cols(Z), fixpos, tvcpos)
        ivl = _finegray_tvc_interval(t, cuts)
        out = _finegray_cif_core_pw(Z, t, t0, delta, event_type, beta, byg_id,
            tg_id, clust_id, has_clust, cause, censval, E, bsraw, bstarget,
            ivl, fixpos, tvcpos, nint)
    }
    else {
        out = _finegray_cif_core(Z, t, t0, delta, event_type, beta, byg_id,
            tg_id, clust_id, has_clust, cause, censval, E, bsraw, bstarget,
            w, wtype)
    }
    /* out[.,1] is the CIF; the analytic point CIF is taken from the step-lookup
       path in finegray_predict, so only the influence-function SE is stored. */
    st_store(sel, sevar, out[., 2])
}

/* Bootstrap helper: CIF at a grid of times for one covariate profile, from the
   current refit's e(b) and fit-keyed Mata baseline cache.  The baseline remains
   in Mata: asking every refit to post e(basehaz) would recreate a K-row Stata
   matrix at O(K^2) cost.  Step lookup is binary-search O(ng*log K), not the
   former nested O(ng*K) scan. Returns an ng x 1 matrix. */
void _finegray_boot_cif(string scalar zmat, string scalar gmat, string scalar omat,
    string scalar key, | real scalar lev)
{
    external real matrix _finegray_bh_cache
    external string scalar _finegray_bh_key
    real rowvector zr
    real colvector beta, gg, cif, H0
    real scalar p, k, xb

    if (args() < 5) lev = .

    if (_finegray_bh_key == "" | _finegray_bh_key != key |
        rows(_finegray_bh_cache) == 0) {
        errprintf("finegray: bootstrap baseline cache does not belong to the refit\n")
        exit(error(459))
    }
    zr = st_matrix(zmat)
    beta = _finegray_beta()
    p = rows(beta)
    xb = 0
    for (k = 1; k <= p; k++) xb = xb + zr[k] * beta[k]
    gg = st_matrix(gmat)
    /* Under bstrata() the replication's cache holds one curve per stratum; the
       requested stratum is the one the point estimate was built on. */
    H0 = _finegray_step_core(_finegray_bh_stratum(_finegray_bh_cache, lev), gg)
    cif = _finegray_cif_stable(H0, J(rows(H0), 1, xb))
    st_matrix(omat, cif)
}

/* Bootstrap helper: per-observation CIF at each eval observation's own time
   (tvar) from the current refit's e(b) and fit-keyed Mata baseline cache,
   accumulated into the
   running sum (sumv) and sum-of-squares (ssv) variables. Used by
   finegray_predict's bootstrap CI (one call per replication). */
void _finegray_boot_cif_obs(
    string scalar zvars,
    string scalar tvar,
    string scalar touse,
    string scalar sumv,
    string scalar ssv,
    string scalar key,
    | string scalar bsvar)
{
    external real matrix _finegray_bh_cache
    external string scalar _finegray_bh_key
    real matrix Z
    real colvector beta, tt, xb, cif, sumc, ssc, tousev, sel, H0, bsvals

    if (args() < 7) bsvar = ""

    if (_finegray_bh_key == "" | _finegray_bh_key != key |
        rows(_finegray_bh_cache) == 0) {
        errprintf("finegray: bootstrap baseline cache does not belong to the refit\n")
        exit(error(459))
    }
    beta = _finegray_beta()
    tousev = st_data(., touse)
    sel = selectindex(tousev :!= 0)
    Z = st_data(sel, tokens(zvars))
    tt = st_data(sel, tvar)
    xb = Z * beta
    if (bsvar != "") bsvals = st_data(sel, bsvar)
    else             bsvals = J(length(sel), 1, 1)
    H0 = _finegray_step_core_bs(_finegray_bh_cache, tt, bsvals)
    cif = _finegray_cif_stable(H0, xb)
    sumc = st_data(sel, sumv)
    ssc = st_data(sel, ssv)
    st_store(sel, sumv, sumc :+ cif)
    st_store(sel, ssv, ssc :+ cif :^ 2)
}

/* ------------------------------------------------------------------------
   CIF under piecewise-constant beta(t).

     Lambda(s | z) = sum_{m: T_m <= s} exp(z' theta_{j(m)}) / S0_{j(m)}(T_m)
                   = sum_j exp(eta_j(z)) * (baseline mass in interval j up to s)
     CIF(s | z)    = 1 - exp(-Lambda(s | z))

   There is one baseline: the interval structure lives in the linear predictor.
   So the point estimate needs only the ordinary Breslow curve (built by the
   piecewise scan) plus its value AT each boundary, which _finegray_tvc_bhpieces
   turns into the per-interval masses.

   NO ANALYTIC STANDARD ERROR IS RETURNED.  The influence function in
   _finegray_cif_core is derived for a single exp(z'beta) multiplying every
   Breslow increment; under beta(t) each increment carries its own interval's
   linear predictor and its own S0, so both the prefix-sum scaffolding and the
   beta-derivative term change shape.  That derivation is not in this release,
   and returning the proportional-hazards influence function for a piecewise fit
   would be a wrong standard error at rc 0.  Column 2 is therefore missing, and
   finegray_cif / finegray_predict refuse an analytic CI on a tvc() fit and
   offer the bootstrap, which resamples the whole fit and needs no derivation.
   ------------------------------------------------------------------------ */

/* eta_j(z) for every evaluation profile: an ne x nint matrix of linear
   predictors, one column per interval. */
real matrix _finegray_tvc_eta(
    real matrix Zstar,
    real colvector beta,
    real colvector fixpos,
    real colvector tvcpos,
    real scalar nint)
{
    real matrix eta
    real scalar j

    eta = J(rows(Zstar), nint, 0)
    for (j = 1; j <= nint; j++) {
        eta[., j] = _finegray_tvc_design(Zstar, fixpos, tvcpos, nint, j) * beta
    }
    return(eta)
}

/* The per-interval baseline masses for a set of times, EACH READ FROM ITS OWN
   STRATUM'S CURVE.

   Added 2026-08-26 with the tvc() x bstrata() composition.  Every piecewise CIF
   consumer needs two things from the baseline: Lambda_0 at the evaluation time,
   and Lambda_0 at each tsplit() boundary.  Under bstrata() BOTH are
   stratum-specific, and the shipped code took both from the whole K x 3 curve
   as though its first column were a time -- which returned the same CIF for
   every stratum at rc 0.  Measured on a K = 3 fit before the fix: strata 1, 2
   and 3 all reported 0.2191 at t = 0.3 against hand values of 0.1511, 0.2311
   and 0.2755.

   Routing every consumer through this one function is deliberate: the boundary
   values and the per-observation values then provably come from the SAME curve,
   which is the invariant _finegray_bh_cutvals's header already states for the
   unstratified case. */
real matrix _finegray_tvc_bhpieces_bs(
    real matrix bh,
    real colvector times,
    real colvector lev,
    real colvector cuts,
    real scalar nint)
{
    real matrix D, blk
    real colvector ulev, sel, rid
    real scalar k

    if (cols(bh) < 3) {
        return(_finegray_tvc_bhpieces(_finegray_step_core(bh, times),
            _finegray_step_core(bh, cuts)', nint))
    }

    D = J(rows(times), nint, 0)
    if (rows(times) == 0) return(D)
    ulev = uniqrows(lev)
    rid = (1::rows(lev))
    for (k = 1; k <= rows(ulev); k++) {
        /* select(), not selectindex(): with one matching row selectindex()
           returns a 1 x 0 ROW vector (Mata's 1x1 orientation ambiguity) and the
           subscript below then reads the wrong way. */
        sel = select(rid, lev :== ulev[k])
        if (rows(sel) == 0) continue
        blk = _finegray_bh_stratum(bh, ulev[k])
        D[sel, .] = _finegray_tvc_bhpieces(
            _finegray_step_core(blk, times[sel]),
            _finegray_step_core(blk, cuts)', nint)
    }
    return(D)
}

/* CIF = 1 - exp(-H0 exp(xb)), evaluated so that exp() overflow at a FINITE
   linear predictor gives the limit the arithmetic is approaching rather than a
   missing value.  Lambda above maxdouble means exp(-Lambda) = 0 and CIF = 1;
   H0 = 0 (no baseline mass yet) is CIF = 0 however large xb is, where Stata's
   0 * missing would be missing.  A missing H0 or xb stays missing: there is
   no prediction.  Same contract as _finegray_cif_core's overflow branch. */
real colvector _finegray_cif_stable(real colvector H0, real colvector xb)
{
    real colvector lam, cif
    real scalar i

    lam = H0 :* exp(xb)
    cif = 1 :- exp(-lam)
    if (!hasmissing(cif)) return(cif)
    for (i = 1; i <= rows(cif); i++) {
        if (cif[i] < .) continue
        if (H0[i] >= . | xb[i] >= .) continue
        cif[i] = (H0[i] > 0)
    }
    return(cif)
}

/* Lambda(s|z) from the per-interval baseline masses and per-interval linear
   predictors.

   rowsum() DROPS missing entries, so through 1.3.0 an interval whose
   exp(eta_j) overflowed contributed 0 to Lambda: the CIF then came from the
   remaining intervals alone, too small, at rc 0.  A row is now summed with
   missing propagated; a row that comes back missing is re-walked: a missing
   piece or eta is a missing Lambda (no prediction), an overflowed term over a
   positive piece puts Lambda above maxdouble (returned as maxdouble(), whose
   exp(-Lambda) is 0 and CIF is 1 as for any finite Lambda beyond ~745), and an
   overflowed term over a zero piece is exactly 0.  Same contract as
   _finegray_cif_core_pw. */
real colvector _finegray_tvc_lambda(
    real matrix pieces,
    real matrix eta)
{
    real matrix term
    real colvector lam
    real scalar i, j, bad, ovf, acc

    term = pieces :* exp(eta)
    lam = rowsum(term, 1)
    if (!hasmissing(lam)) return(lam)
    for (i = 1; i <= rows(lam); i++) {
        if (lam[i] < .) continue
        bad = 0
        ovf = 0
        acc = 0
        for (j = 1; j <= cols(term); j++) {
            if (pieces[i, j] >= . | eta[i, j] >= .) {
                bad = 1
                break
            }
            if (term[i, j] < .) acc = acc + term[i, j]
            else if (pieces[i, j] > 0) ovf = 1
        }
        if (bad) lam[i] = .
        else if (ovf | acc >= .) lam[i] = maxdouble()   /* a term, or the sum */
        else lam[i] = acc
    }
    return(lam)
}

/* Bootstrap helper (curve mode): piecewise CIF at a grid of times for one
   covariate profile, from the current refit's e(b) and fit-keyed cache. */
void _finegray_boot_cif_tvc(
    string scalar zmat,
    string scalar gmat,
    string scalar omat,
    string scalar key,
    string scalar tvc_str,
    string scalar tsplit_str,
    | real scalar lev)
{
    external real matrix _finegray_bh_cache
    external string scalar _finegray_bh_key
    real matrix eta, pieces
    real colvector beta, gg, cuts, fixpos, tvcpos
    real scalar nint

    if (args() < 7) lev = .

    if (_finegray_bh_key == "" | _finegray_bh_key != key |
        rows(_finegray_bh_cache) == 0) {
        errprintf("finegray: bootstrap baseline cache does not belong to the refit\n")
        exit(error(459))
    }
    beta = _finegray_beta()
    cuts = (tsplit_str != "" ? strtoreal(tokens(tsplit_str))' : J(0, 1, .))
    nint = rows(cuts) + 1
    _finegray_tvc_positions(tvc_str, cols(st_matrix(zmat)), fixpos, tvcpos)
    gg = st_matrix(gmat)
    /* Under bstrata() the replication's cache holds one curve per stratum; the
       requested stratum is the one the point estimate was built on.  Same
       contract as _finegray_boot_cif. */
    pieces = _finegray_tvc_bhpieces_bs(_finegray_bh_cache, gg,
        J(rows(gg), 1, lev), cuts, nint)
    eta = _finegray_tvc_eta(J(rows(gg), 1, 1) # st_matrix(zmat), beta,
        fixpos, tvcpos, nint)
    st_matrix(omat, 1 :- exp(-_finegray_tvc_lambda(pieces, eta)))
}

/* Bootstrap helper (per-observation mode): piecewise CIF at each evaluation
   observation's own time, accumulated into the running sum / sum-of-squares. */
void _finegray_boot_cif_obs_tvc(
    string scalar zvars,
    string scalar tvar,
    string scalar touse,
    string scalar sumv,
    string scalar ssv,
    string scalar key,
    string scalar tvc_str,
    string scalar tsplit_str,
    | string scalar bsvar)
{
    external real matrix _finegray_bh_cache
    external string scalar _finegray_bh_key
    real matrix Z, eta, pieces
    real colvector beta, tt, cif, sumc, ssc, tousev, sel, bsvals
    real colvector cuts, fixpos, tvcpos
    real scalar nint

    if (args() < 9) bsvar = ""

    if (_finegray_bh_key == "" | _finegray_bh_key != key |
        rows(_finegray_bh_cache) == 0) {
        errprintf("finegray: bootstrap baseline cache does not belong to the refit\n")
        exit(error(459))
    }
    beta = _finegray_beta()
    tousev = st_data(., touse)
    sel = selectindex(tousev :!= 0)
    if (length(sel) == 0) return
    Z = st_data(sel, tokens(zvars))
    tt = st_data(sel, tvar)

    cuts = (tsplit_str != "" ? strtoreal(tokens(tsplit_str))' : J(0, 1, .))
    nint = rows(cuts) + 1
    _finegray_tvc_positions(tvc_str, cols(Z), fixpos, tvcpos)

    if (bsvar != "") bsvals = st_data(sel, bsvar)
    else             bsvals = J(length(sel), 1, .)
    pieces = _finegray_tvc_bhpieces_bs(_finegray_bh_cache, tt, bsvals,
        cuts, nint)
    eta = _finegray_tvc_eta(Z, beta, fixpos, tvcpos, nint)
    cif = 1 :- exp(-_finegray_tvc_lambda(pieces, eta))

    sumc = st_data(sel, sumv)
    ssc = st_data(sel, ssv)
    st_store(sel, sumv, sumc :+ cif)
    st_store(sel, ssv, ssc :+ cif :^ 2)
}

/* ------------------------------------------------------------------------
   Baseline cumulative subhazard WITHOUT a K-row Stata matrix.

   The baseline has one row per distinct cause-event time, so K ~ n/2.  Creating
   a Stata matrix with K rows is O(K^2) -- Stata builds one dimension name per
   row, and the cost is per NAME, not per element, so it hits st_matrix(), mkmat,
   a plain copy and a transpose alike (6.5 s at K = 40,000, 38.6 s at K = 95,600).
   That round trip, not the forward-backward scan, was this package's entire
   superlinearity: ablating it moved the runtime slope from 1.65 to 1.05.

   Postestimation needs the baseline's VALUES, not a Stata matrix.  So rebuild it
   in Mata in one linear pass from the estimation sample and e(b).  It re-runs the
   same _finegray_basehazard() the fit ran, so it recovers the SAME curve.

   Caveat, documented deliberately: the rebuild is not BIT-identical to the cached
   curve -- ~1 ulp (measured 3.8e-15 on a CIF).  _finegray_basehazard breaks tied
   event times by row index, and the rebuild reads rows in current data order while
   the fit read them in its own sorted order, so tied contributions accumulate in a
   different rounding order.  Both paths are individually deterministic and 1 ulp is
   far below any reported precision, so this is a reproducibility footnote, not a
   bug -- but it is why a CIF can change in its last bit if another fit in the
   same session replaces the cache and forces a rebuild.  To get the fit-time
   curve exactly, fit with basehaz: e(basehaz) is
   read directly and no rebuild happens.
   ------------------------------------------------------------------------ */
real matrix _finegray_bh_rebuild(
    string scalar zvars,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar tg_str,
    string scalar tousevar,
    string scalar t0var,
    | string scalar bs_str,
    string scalar tvc_str,
    string scalar tsplit_str,
    string scalar w_str,
    real scalar wtype)
{
    real matrix Z
    real colvector t, t0, delta, event_type, beta, byg_id, tg_id, G, bsraw, w
    real scalar n, use_pooled, nint
    real colvector gidx, Gminus, Apool
    real colvector cuts, ivl, fixpos, tvcpos
    real matrix Gt

    if (args() < 9) bs_str = ""
    if (args() < 10) tvc_str = ""
    if (args() < 11) tsplit_str = ""
    if (args() < 12) w_str = ""
    if (args() < 13) wtype = 0

    Z = st_data(., tokens(zvars), tousevar)
    t = st_data(., "_t", tousevar)
    t0 = st_data(., t0var, tousevar)
    delta = st_data(., "_d", tousevar)
    event_type = st_data(., events_str, tousevar)
    n = rows(Z)
    beta = _finegray_beta()
    if (byg_str != "") byg_id = st_data(., byg_str, tousevar)
    else               byg_id = J(n, 1, 1)
    if (tg_str != "")  tg_id = st_data(., tg_str, tousevar)
    else               tg_id = J(n, 1, 1)
    /* bstrata(): the fit's own stratum column, read from the estimation sample.
       Rebuilding without it would return the POOLED baseline for a stratified
       fit -- a different curve, at rc 0. */
    if (bs_str != "")  bsraw = st_data(., bs_str, tousevar)
    else               bsraw = J(n, 1, 1)
    /* Design weights, rebuilt by the caller from e(wexp): the weighted
       Breslow baseline is a different curve from the unweighted one. */
    if (w_str != "")   w = st_data(., w_str, tousevar)
    else               w = J(n, 1, 1)

    /* post-estimation recompute: quiet=1, the fit already printed any note */
    if (wtype == 2) {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1, w)
    }
    else {
        G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0, 1)
    }
    _finegray_prepare_weight_design(t, delta, censval, event_type, G,
        byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool)

    /* Piecewise beta(t): the rebuild must run the SAME baseline scan the fit
       ran.  Rebuilding with the ordinary scan would return the proportional
       fit's baseline for a piecewise fit -- a different curve, at rc 0 -- so
       the interval structure travels with the call.  tvc_str carries POSITIONS
       into zvars, not names, because post-estimation is allowed to rebuild the
       design columns as tempvars. */
    if (tvc_str != "") {
        cuts = (tsplit_str != "" ? strtoreal(tokens(tsplit_str))' : J(0, 1, .))
        _finegray_tvc_positions(tvc_str, cols(Z), fixpos, tvcpos)
        nint = rows(cuts) + 1
        ivl = _finegray_tvc_interval(t, cuts)
        return(_finegray_basehazard_pw(t, delta, cause, censval, event_type,
            Z, beta, G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt,
            Apool, bsraw, ivl, fixpos, tvcpos, nint, w))
    }

    return(_finegray_basehazard(t, delta, cause, censval, event_type, Z, beta,
        G, byg_id, t0, tg_id, use_pooled, gidx, Gminus, Gt, Apool, bsraw, w))
}

/* ------------------------------------------------------------------------
   The baseline cache: the curve kept in Mata without Stata's naming overhead.

   A Stata matrix costs O(K^2) to create because of its dimension-name stripe.
   A Mata matrix has no stripe -- it is just numbers -- so holding the same K x 2
   curve costs O(K) time and memory.  That is the whole trick: the baseline lives in
   Mata across commands, and only becomes a Stata matrix if the user asks for
   e(basehaz).

   This cache exists because postestimation cannot always rebuild.  `predict, cif'
   on NEW data is a documented workflow: the user drops the estimation data, types
   a fresh covariate profile, and predicts.  The estimation sample is then gone,
   so there is nothing to rebuild the baseline FROM -- and the old code only
   worked because it read a Stata matrix out of e(), which survives `drop _all'.

   The cache is keyed by a per-fit STRING token, posted as e(bh_key).  A stale
   cache is the silent-wrong-answer failure mode here (predicting from the
   PREVIOUS fit's baseline at rc 0), so a consumer must present the key it expects
   and gets nothing back unless it matches.  `mata clear' / `discard' wipe the
   cache, which is safe: the consumer then falls back to rebuilding, or errors.

   The key used to be an integer counter.  That counter lived in Mata, so
   `mata clear' reset it: the first fit afterwards was handed key 1 again, and an
   `estimates restore' of an EARLIER fit that also held key 1 then scored its
   betas on the new fit's baseline at rc 0.  A token that cannot be re-minted
   closes that: it carries a per-invocation salt (a Stata global counter, which
   `mata clear' does not touch, plus the wall clock) and a digest of the fit
   itself, so no two fits can present the same key and a cleared cache simply
   has no key at all.
   ------------------------------------------------------------------------ */
void _finegray_bh_store(real matrix bh)
{
    external real matrix    _finegray_bh_cache
    external real scalar    _finegray_bh_seq
    external string scalar  _finegray_bh_key

    if (_finegray_bh_seq == J(1,1,.) | _finegray_bh_seq >= .) _finegray_bh_seq = 0
    _finegray_bh_cache = bh
    _finegray_bh_seq   = _finegray_bh_seq + 1
    /* The key is minted only AFTER `ereturn post', by _finegray_bh_setkey,
       because the digest reads e().  Between the store and the mint the cache
       is unclaimed and no consumer can match it. */
    _finegray_bh_key = ""
    st_local("_fg_bh_seq", strofreal(_finegray_bh_seq, "%18.0g"))
}

/* Mint the token for the curve just stored, and hand it back for e(bh_key).
   Called from finegray.ado AFTER `ereturn post', so e(b) and the fit scalars are
   readable here.  The digest is built in MATA, not in a Stata macro: a
   serialized e(b) overruns the 244-character macro limit long before a
   moderately sized model does. */
/* ---------------------------------------------------------------------------
   Value-sensitive digest of the fit's design-weight column.

   e(sum_w) alone reconciles only the TOTAL.  A weight expression built on an
   unsignable input -- a scalar, [pw = cond(odd == 0, kk, 4 - kk)] -- can be
   changed in a way that leaves the total invariant and every per-observation
   weight different, and post-estimation then rebuilt a different column at
   rc 0.  This digest sees the values.

   ORDER-INVARIANT on purpose: the accumulator is a sum, so a plain re-sort of a
   variable weight still reconciles (the weights suite asserts exactly that).
   The sum is taken modulo 2^40 so that every partial sum stays exactly
   representable -- an ordinary floating sum of n hashes stops being
   order-invariant once it passes 2^53.

   SUBJECT-KEYED.  Each row contributes hash1(id | w), not hash1(w), so the
   digest is invariant to a re-sort but SENSITIVE to which subject carries
   which weight: exchanging the weights of two subjects leaves the multiset of
   weight values (and e(sum_w)) untouched and would otherwise reconcile at
   rc 0.  `idvar' is the stset id() variable (e(idvar)); it is read as a
   string when the id is a string variable.  Called without it -- a fit whose
   stset carried no id() -- the digest degrades to the value-only form.
   --------------------------------------------------------------------------- */
void _finegray_wsig(string scalar wvar, string scalar tousevar,
    | string scalar idvar)
{
    real colvector tv, sel, w
    real scalar i, n, a1, a2, m, haveid
    string colvector ids
    string scalar h

    if (args() < 3) idvar = ""
    m = 1099511627776             /* 2^40 */
    tv = st_data(., tousevar)
    sel = selectindex(tv :!= 0)
    n = length(sel)
    a1 = 0
    a2 = 0
    haveid = (idvar != "")
    if (n > 0) {
        w = st_data(sel, wvar)
        if (haveid) {
            if (st_isnumvar(idvar)) {
                ids = strofreal(st_data(sel, idvar), "%21x")
            }
            else {
                ids = st_sdata(sel, idvar)
            }
        }
        for (i = 1; i <= n; i++) {
            h = strofreal(w[i], "%21x")
            if (haveid) h = ids[i] + "|" + h
            a1 = mod(a1 + hash1(h), m)
            a2 = mod(a2 + hash1(strreverse(h)), m)
        }
    }
    st_local("_fg_wsig", strofreal(a1, "%21x") + "|" + strofreal(a2, "%21x"))
    st_local("_fg_wsig_n", strofreal(n, "%18.0g"))
}

/* strofreal() of an e() scalar that may not have been posted at all.
   st_numscalar() answers 0 x 0 for a name that does not exist, and strofreal()
   of a void matrix is a conformability error, not a missing value. */
string scalar _finegray_bh_escal(string scalar nm)
{
    real matrix v

    v = st_numscalar(nm)
    if (length(v) != 1) return(".")
    return(strofreal(v, "%21x"))
}

void _finegray_bh_setkey(string scalar salt)
{
    external string scalar _finegray_bh_key
    real matrix b
    real scalar j
    string scalar content, tok

    content = salt
    b = st_matrix("e(b)")
    for (j = 1; j <= cols(b); j++) content = content + "|" + strofreal(b[1, j], "%21x")
    content = content + "|" + _finegray_bh_escal("e(N)")
    content = content + "|" + _finegray_bh_escal("e(sum_w)")
    content = content + "|" + _finegray_bh_escal("e(ll)")
    content = content + "|" + _finegray_bh_escal("e(N_fail)")
    content = content + "|" + st_global("e(datasignature)")
    content = content + "|" + st_global("e(compete)")
    content = content + "|" + st_global("e(cause)")
    content = content + "|" + st_global("e(bstrata)")
    content = content + "|" + st_global("e(tvc)")

    /* Two hashes over the string and its reverse: one hash1() is a 32-bit
       value (measured maximum 4,294,961,279), and the pair keeps the token
       short enough for a Stata macro.  The mod-2^40 fold and the partial sums
       in _finegray_wsig stay below 2^41 either way, so that arithmetic is
       unaffected by the width. */
    tok = strofreal(hash1(content), "%21x") + "|" +
          strofreal(hash1(strreverse(content)), "%21x") + "|" + salt
    _finegray_bh_key = tok
    st_local("_fg_bh_key", tok)
}

/* Does the cache hold the curve for THIS fit?  Sets the caller's local to 1/0. */
void _finegray_bh_have(string scalar key, string scalar lname)
{
    external real matrix _finegray_bh_cache
    external string scalar _finegray_bh_key
    real scalar ok

    ok = 0
    if (_finegray_bh_key != "" & _finegray_bh_key == key) {
        if (rows(_finegray_bh_cache) > 0) ok = 1
    }
    st_local(lname, strofreal(ok))
}

/* Snapshot / restore the single-slot baseline cache around a side computation.
   The cache holds ONE fit's curve, keyed by _finegray_bh_key.  finegray_predict's
   bootstrap refits each call finegray again -- every refit overwrites the cache
   with its own baseline and mints its own key -- so after the bootstrap the global
   cache belongs to the LAST resample while the restored e(bh_key) still names the
   ORIGINAL fit.  A subsequent `predict, cif' on NEW data then finds a key
   mismatch, tries to rebuild from an estimation sample the user has since
   dropped, and errors r(459).  Each bootstrap replication consumes its own
   key-matched cache entry before the next refit overwrites it.  Stashing the
   held fit's entry before the loop and restoring it afterward therefore leaves
   that fit resolvable without changing any replication result.  Copying the
   external is O(K); it does NOT build a Stata matrix (which would reintroduce
   the O(K^2) cost the cache exists to avoid). */
void _finegray_bh_stash()
{
    external real matrix _finegray_bh_cache, _finegray_bh_cache_stash
    external real scalar _finegray_bh_seq,   _finegray_bh_seq_stash
    external string scalar _finegray_bh_key, _finegray_bh_key_stash

    _finegray_bh_cache_stash = _finegray_bh_cache
    _finegray_bh_seq_stash   = _finegray_bh_seq
    /* The key travels WITH the matrix.  Restoring the curve without its token
       leaves the held fit's e(bh_key) naming a cache that answers to the last
       resample's token, which is r(459) on the next predict-on-new-data. */
    _finegray_bh_key_stash   = _finegray_bh_key
}
void _finegray_bh_unstash()
{
    external real matrix _finegray_bh_cache, _finegray_bh_cache_stash
    external real scalar _finegray_bh_seq,   _finegray_bh_seq_stash
    external string scalar _finegray_bh_key, _finegray_bh_key_stash

    _finegray_bh_cache = _finegray_bh_cache_stash
    _finegray_bh_seq   = _finegray_bh_seq_stash
    _finegray_bh_key   = _finegray_bh_key_stash
}

/* Lambda_0 AT each tsplit() boundary, posted as a 1 x (nint-1) Stata matrix.
   Every baseline consumer under tvc() needs these and only these extra values:
   with interval j = (cuts[j-1], cuts[j]] the mass falling in interval j up to
   time s is min(Lambda_0(s), Lambda_0(cuts[j])) - Lambda_0(cuts[j-1]), so the
   ordinary step search answers it and no left limit is required.

   It lives HERE, beside the three lookup paths, so that whichever source a
   caller resolved -- the posted e(basehaz), the Mata cache, or a rebuild -- the
   boundary values come from the SAME curve as the per-observation values.
   Reading them from a second, independently resolved curve is how a CIF ends up
   mixing two baselines at rc 0.  A no-op unless the caller asked. */
void _finegray_bh_cutvals(
    real matrix bh,
    string scalar tsplit_str,
    string scalar cutmat)
{
    real colvector cuts, lev
    real matrix out
    real scalar k

    if (cutmat == "" | tsplit_str == "") return
    cuts = strtoreal(tokens(tsplit_str))'
    if (rows(cuts) == 0) return
    if (cols(bh) < 3) {
        st_matrix(cutmat, _finegray_step_core(bh, cuts)')
        return
    }

    /* bstrata() x tvc(): Lambda_0 at the boundaries is stratum-specific, so the
       posted matrix gains a row per stratum with the stratum VALUE in column 1
       -- the same shape convention e(basehaz) uses, so a consumer that already
       knows how to read a K x 3 curve needs no new rule.
         row k = (stratum value, Lambda_0k(cut_1), ..., Lambda_0k(cut_{J-1}))
       Through v1.3.0 this errored, because the pair was refused at the parser
       and the branch was unreachable. */
    lev = uniqrows(bh[., 1])
    out = J(rows(lev), 1 + rows(cuts), .)
    for (k = 1; k <= rows(lev); k++) {
        out[k, 1] = lev[k]
        out[k, 2..(1 + rows(cuts))] =
            _finegray_step_core(_finegray_bh_stratum(bh, lev[k]), cuts)'
    }
    st_matrix(cutmat, out)
}

/* Step lookup against the cached curve.  Refuses a mismatched seq rather than
   answering from another fit's baseline. */
void _finegray_step_lookup_cached(
    string scalar key,
    string scalar tvar,
    string scalar H0var,
    string scalar tousevar,
    | string scalar bsvar,
    string scalar tsplit_str,
    string scalar cutmat)
{
    external real matrix _finegray_bh_cache
    external string scalar _finegray_bh_key
    real colvector touse_vec, sel, times, H0, bsvals

    if (args() < 5) bsvar = ""
    if (args() < 6) tsplit_str = ""
    if (args() < 7) cutmat = ""

    if (_finegray_bh_key == "" | _finegray_bh_key != key |
        rows(_finegray_bh_cache) == 0) {
        errprintf("finegray: cached baseline does not belong to the active fit\n")
        exit(error(459))
    }
    _finegray_bh_cutvals(_finegray_bh_cache, tsplit_str, cutmat)
    touse_vec = st_data(., tousevar)
    sel = selectindex(touse_vec)
    if (length(sel) == 0) return
    times = st_data(sel, tvar)
    if (bsvar != "") bsvals = st_data(sel, bsvar)
    else             bsvals = J(length(sel), 1, 1)
    H0 = _finegray_step_core_bs(_finegray_bh_cache, times, bsvals)
    st_store(sel, H0var, H0)
}

/* The thinned grid, taken from the cached curve (finegray_cif's curve mode). */
void _finegray_bh_grid_cached(string scalar key, real scalar maxpts,
    string scalar outmat, | real scalar lev)
{
    external real matrix _finegray_bh_cache
    external string scalar _finegray_bh_key
    real colvector idx
    real matrix bh
    real scalar nbh, step, r, last

    if (args() < 4) lev = .

    if (_finegray_bh_key == "" | _finegray_bh_key != key |
        rows(_finegray_bh_cache) == 0) {
        errprintf("finegray: cached baseline does not belong to the active fit\n")
        exit(error(459))
    }
    /* Under bstrata() the curve is one step function per stratum, so the plot
       grid is the requested stratum's event times -- not every stratum's times
       pooled, which is a grid no single curve steps on. */
    bh = _finegray_bh_stratum(_finegray_bh_cache, lev)
    nbh = rows(bh)
    st_local("_fg_nbh", strofreal(nbh))
    if (nbh == 0) return

    step = ceil(nbh / maxpts)
    idx = J(0, 1, .)
    last = 0
    for (r = 1; r <= nbh; r = r + step) {
        idx = idx \ r
        last = r
    }
    if (last < nbh) idx = idx \ nbh
    st_matrix(outmat, bh[idx, 1])
}

/* Shared binary-search step lookup: largest baseline time <= each element of
   times, returning its cumulative subhazard (0 before the first event time). */
real colvector _finegray_step_core(real matrix bh, real colvector times)
{
    real colvector H0
    real scalar i, lo, hi, mid, n_bh, n

    n_bh = rows(bh)
    n = rows(times)
    H0 = J(n, 1, 0)
    for (i = 1; i <= n; i++) {
        if (times[i] >= .) continue
        lo = 1
        hi = n_bh
        while (lo <= hi) {
            mid = trunc((lo + hi) / 2)
            if (bh[mid, 1] <= times[i]) lo = mid + 1
            else hi = mid - 1
        }
        if (hi >= 1) H0[i] = bh[hi, 2]
    }
    return(H0)
}

/* Baseline-strata step lookup.  A K x 3 curve (bstratum, time, cumhaz) holds
   one step function per stratum, so each evaluation row is looked up in the
   block belonging to ITS stratum value.  A K x 2 curve is unstratified and
   falls through to the pooled lookup, unchanged to the last bit.

   A row whose stratum never appeared in the fit has no baseline at all.  It is
   refused by name rather than answered with 0 (which is a real cumulative
   subhazard -- "no events yet" -- and would be read as a CIF of exactly 0) or
   with missing (which every arithmetic consumer propagates silently). */
real colvector _finegray_step_core_bs(
    real matrix bh,
    real colvector times,
    real colvector bsvals)
{
    real colvector H0, lev, sel, seen, unmatched
    real scalar g, nlev

    if (cols(bh) < 3) return(_finegray_step_core(bh, times))

    H0 = J(rows(times), 1, .)
    seen = J(rows(times), 1, 0)
    lev = uniqrows(bh[., 1])
    nlev = rows(lev)
    for (g = 1; g <= nlev; g++) {
        sel = selectindex(bsvals :== lev[g])
        if (length(sel) == 0) continue
        H0[sel] = _finegray_step_core(
            select(bh[., (2, 3)], bh[., 1] :== lev[g]), times[sel])
        seen[sel] = J(length(sel), 1, 1)
    }
    unmatched = selectindex(seen :== 0)
    if (length(unmatched) > 0) {
        errprintf("finegray: baseline stratum %g has no fitted baseline\n",
            bsvals[unmatched[1]])
        errprintf("%g observation(s) lie in bstrata() level(s) the fit never saw\n",
            length(unmatched))
        errprintf("each stratum carries its own baseline, so there is nothing ")
        errprintf("to predict from\n")
        exit(error(459))
    }
    return(H0)
}

/* The rows of one baseline stratum, as a (time, cumhaz) curve.  lev is missing
   for an unstratified fit, where the whole curve is the answer. */
real matrix _finegray_bh_stratum(real matrix bh, real scalar lev)
{
    real matrix sub

    if (cols(bh) < 3) return(bh)
    if (lev >= .) {
        errprintf("finegray: this fit has baseline strata; a stratum must be ")
        errprintf("named\n")
        exit(error(198))
    }
    sub = select(bh[., (2, 3)], bh[., 1] :== lev)
    if (rows(sub) == 0) {
        errprintf("finegray: baseline stratum %g was not present in the fit\n",
            lev)
        exit(error(459))
    }
    return(sub)
}

/* Step lookup with the baseline rebuilt in Mata -- the path taken when the user
   did not ask for e(basehaz).  Same values as _finegray_step_lookup(); it just
   never routes the curve through a Stata matrix. */
void _finegray_step_lookup_direct(
    string scalar zvars,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar tg_str,
    string scalar est_touse,
    string scalar t0var,
    string scalar tvar,
    string scalar H0var,
    string scalar eval_touse,
    | string scalar bs_str,
    string scalar tvc_str,
    string scalar tsplit_str,
    string scalar cutmat,
    string scalar w_str,
    real scalar wtype)
{
    real matrix bh
    real colvector touse_vec, sel, times, H0, bsvals

    if (args() < 12) bs_str = ""
    if (args() < 13) tvc_str = ""
    if (args() < 14) tsplit_str = ""
    if (args() < 15) cutmat = ""
    if (args() < 16) w_str = ""
    if (args() < 17) wtype = 0

    bh = _finegray_bh_rebuild(zvars, events_str, cause, censval, byg_str,
        tg_str, est_touse, t0var, bs_str, tvc_str, tsplit_str, w_str, wtype)
    _finegray_bh_cutvals(bh, tsplit_str, cutmat)
    touse_vec = st_data(., eval_touse)
    sel = selectindex(touse_vec)
    if (length(sel) == 0) return
    times = st_data(sel, tvar)
    if (bs_str != "") bsvals = st_data(sel, bs_str)
    else              bsvals = J(length(sel), 1, 1)
    H0 = _finegray_step_core_bs(bh, times, bsvals)
    st_store(sel, H0var, H0)
}

/* The THINNED baseline time grid for finegray_cif's curve mode.  Posts at most
   maxpts+1 rows, so the Stata matrix it creates is small and its O(rows^2) cost
   is nil -- the point of the exercise is never to hand Stata the full K rows.
   The thinning indices reproduce the former Stata-side loop exactly (stride, then
   always close on the last row), so the grid is unchanged to the last bit. */
void _finegray_bh_grid(
    string scalar zvars,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar tg_str,
    string scalar est_touse,
    string scalar t0var,
    real scalar maxpts,
    string scalar outmat,
    | string scalar bs_str,
    real scalar lev,
    string scalar tvc_str,
    string scalar tsplit_str,
    string scalar w_str,
    real scalar wtype)
{
    real matrix bh
    real colvector idx
    real scalar nbh, step, r, last

    if (args() < 11) bs_str = ""
    if (args() < 12) lev = .
    if (args() < 13) tvc_str = ""
    if (args() < 14) tsplit_str = ""
    if (args() < 15) w_str = ""
    if (args() < 16) wtype = 0

    bh = _finegray_bh_rebuild(zvars, events_str, cause, censval, byg_str,
        tg_str, est_touse, t0var, bs_str, tvc_str, tsplit_str, w_str, wtype)
    bh = _finegray_bh_stratum(bh, lev)
    nbh = rows(bh)
    st_local("_fg_nbh", strofreal(nbh))
    if (nbh == 0) return

    step = ceil(nbh / maxpts)
    idx = J(0, 1, .)
    last = 0
    for (r = 1; r <= nbh; r = r + step) {
        idx = idx \ r
        last = r
    }
    if (last < nbh) idx = idx \ nbh
    st_matrix(outmat, bh[idx, 1])
}

/* Step function lookup via binary search: O(n log n_bh) instead of O(n * n_bh).
   For each observation in the touse sample, finds the largest basehaz time <= t
   and assigns the corresponding cumulative hazard to H0var.  Used when the user
   asked for e(basehaz) and the matrix therefore exists; st_matrix() READS an e()
   matrix for free, it is only CREATING one that is quadratic. */
void _finegray_step_lookup(
    string scalar bh_matname,
    string scalar tvar,
    string scalar H0var,
    string scalar tousevar,
    | string scalar bsvar,
    string scalar tsplit_str,
    string scalar cutmat)
{
    real matrix bh
    real colvector times, H0, touse_vec, sel, bsvals

    if (args() < 5) bsvar = ""
    if (args() < 6) tsplit_str = ""
    if (args() < 7) cutmat = ""

    bh = st_matrix(bh_matname)
    _finegray_bh_cutvals(bh, tsplit_str, cutmat)
    touse_vec = st_data(., tousevar)
    sel = selectindex(touse_vec)
    if (length(sel) == 0) return
    times = st_data(sel, tvar)
    if (bsvar != "") bsvals = st_data(sel, bsvar)
    else             bsvals = J(length(sel), 1, 1)
    H0 = _finegray_step_core_bs(bh, times, bsvals)
    st_store(sel, H0var, H0)
}

/* Assign Schoenfeld residuals from matrix to variables via index lookup.
   O(N) instead of O(N * n_fail) from forvalues replace-if loops.
   ccvar holds cumulative cause-event index (1..n_fail) for cause events,
   missing for non-events. varnames are the target variable names. */
void _finegray_assign_schoenfeld_vars(
    string scalar matname,
    string scalar ccvar,
    string rowvector varnames,
    real scalar p)
{
    real matrix sch
    real colvector cc, vals
    real scalar i, n, col

    sch = st_matrix(matname)
    cc = st_data(., ccvar)
    n = rows(cc)

    for (col = 1; col <= p; col++) {
        vals = J(n, 1, .)
        for (i = 1; i <= n; i++) {
            if (cc[i] < . & cc[i] >= 1) {
                vals[i] = sch[cc[i], col + 1]
            }
        }
        st_store(., varnames[col], vals)
    }
}


end
