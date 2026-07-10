/*──────────────────────────────────────────────────────────────────────────────
  trop_validation.mata

  Pre-estimation data validation for the TROP estimator.

  The unit distance metric requires a non-empty set of jointly observed
  control periods for each pair of units entering the weighted regression.
  Specifically, the denominator  sum_{u!=t} (1 - W_{iu})(1 - W_{ju})  must
  be positive for at least one donor j per treated unit i; otherwise the
  distance is undefined and estimation cannot proceed.

  This module verifies that condition prior to calling the estimation
  backend.

  Contents
    _trop_chk_common_ctrl_periods()   minimum pairwise control-period overlap
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  _trop_chk_common_ctrl_periods()

  For each ever-treated unit i, find the donor j != i that shares the most
  control periods with i, then return the minimum of those maxima across all
  ever-treated units.

  Define  C_{it} = (1 - W_{it}) * 1{Y_{it} observed}.  The pairwise overlap
  between units i and j is

      overlap(i,j) = sum_t  C_{it} * C_{jt}.

  The statistic returned is

      min_{i : ever-treated}  max_{j != i}  overlap(i,j).

  A return value >= 2 guarantees that every ever-treated unit has at least
  one donor with a non-degenerate set of joint control periods, so the
  leave-one-out unit distance (which excludes one period at a time) retains
  a positive denominator.

  Arguments
    panelid_var   variable name: integer panel identifier (1..N)
    timeid_var    variable name: integer time  identifier (1..T)
    treatvar      variable name: binary treatment indicator W_{it}
    depvar        variable name: outcome Y_{it}
    tousevar      variable name: estimation-sample marker
    N_panel       number of panel units
    T_panel       number of time periods

  Returns
    real scalar   minimum best-pairwise overlap defined above
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_chk_common_ctrl_periods(
    string scalar panelid_var,
    string scalar timeid_var,
    string scalar treatvar,
    string scalar depvar,
    string scalar tousevar,
    real scalar N_panel,
    real scalar T_panel)
{
    real colvector _pid, _tid, _treat, _yvals
    real scalar _kk, _ii, _jj

    st_view(_pid,   ., panelid_var, tousevar)
    st_view(_tid,   ., timeid_var,  tousevar)
    st_view(_treat, ., treatvar,    tousevar)
    st_view(_yvals, ., depvar,      tousevar)

    /* ── Build indicator matrices ──────────────────────────────────────────
       C[i,t] = 1  iff  W_{it} = 0  and  Y_{it} non-missing   (control)
       D[i,t] = 1  iff  W_{it} = 1                             (treated)
    ────────────────────────────────────────────────────────────────────── */
    real matrix _C, _D
    _C = J(N_panel, T_panel, 0)
    _D = J(N_panel, T_panel, 0)

    for (_kk = 1; _kk <= rows(_pid); _kk++) {
        _ii = _pid[_kk]
        _jj = _tid[_kk]
        if (_treat[_kk] == 1) {
            _D[_ii, _jj] = 1
        }
        if (_treat[_kk] == 0 & _yvals[_kk] < .) {
            _C[_ii, _jj] = 1
        }
    }

    /* ── Ever-treated indicator: unit i with sum_t D[i,t] > 0 ─────────── */
    real colvector _ever
    _ever = (rowsum(_D) :> 0)

    /* ── Pairwise overlap: overlap[i,j] = C_i' * C_j  (Gram matrix) ──── */
    real matrix _overlap
    _overlap = _C * _C'

    /* ── min_{i: ever-treated}  max_{j != i}  overlap[i,j] ───────────── */
    real scalar _mvp, _maxov
    _mvp = .

    for (_ii = 1; _ii <= N_panel; _ii++) {
        if (_ever[_ii]) {
            _maxov = 0
            for (_jj = 1; _jj <= N_panel; _jj++) {
                if (_jj != _ii & _overlap[_ii, _jj] > _maxov) {
                    _maxov = _overlap[_ii, _jj]
                }
            }
            if (_mvp == . | _maxov < _mvp) {
                _mvp = _maxov
            }
        }
    }

    /* If no ever-treated unit exists, default to 1 (degenerate panel). */
    if (_mvp == .) _mvp = 1

    return(_mvp)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_panel_health_check()

  Pre-estimation panel health diagnostics.  Emits warnings for panels
  that are technically valid but may produce unreliable estimates, and
  aborts with an error for panels that cannot be estimated at all.

  Arguments
    n_units       number of cross-sectional units
    n_periods     number of time periods
    n_obs         total in-sample observations
    pct_missing   percentage of outcome cells that are missing (0-100)

  Side effects
    - Prints warnings for small panels or high missingness
    - Calls exit(498) if n_periods < 2 (fatal: estimation impossible)
──────────────────────────────────────────────────────────────────────────────*/

void _trop_panel_health_check(real scalar n_units, real scalar n_periods,
                              real scalar n_obs, real scalar pct_missing)
{
    if (n_periods < 2) {
        errprintf("Error: At least 2 time periods required (got %g).\n", n_periods)
        exit(498)
    }
    if (n_units < 3) {
        printf("{txt}Warning: Only %g units detected. Estimates may be unreliable.\n", n_units)
    }
    if (pct_missing > 30) {
        printf("{txt}Warning: %.1f%% missing outcomes detected. Consider data quality.\n", pct_missing)
    }
    if (n_obs < n_units * n_periods * 0.5) {
        printf("{txt}Warning: Panel is less than 50%% balanced (%g obs of %g possible).\n",
               n_obs, n_units * n_periods)
    }
}

end
