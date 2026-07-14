/*──────────────────────────────────────────────────────────────────────────────
  trop_rust_interface.mata

  Plugin interface layer for the TROP estimator.

  Mata wrappers for the compiled native plugin.  This module handles
  platform detection, plugin discovery and loading, and thin call-through
  functions for every plugin entry point.  No estimation logic resides
  here; all numerical computation is delegated to the plugin binary.

  Contents
  ────────
  1. Platform detection and plugin loading
       _trop_get_plugin_name()        canonical plugin filename (trop.plugin)
       _trop_get_plugin_name_platform()  platform-specific fallback filename
       _trop_get_plugin_path()        locate plugin binary on disk
       _trop_ensure_plugin()           load plugin into Stata
       _trop_call_plugin()            issue a plugin call with varlist
       _trop_call_plugin_simple()     issue a plugin call without varlist
       trop_rust_available()          query plugin availability

  2. LOOCV interface
       trop_loocv_twostep()               two-step LOOCV cycling search
       trop_loocv_twostep_exhaustive()    two-step LOOCV Cartesian grid search
       trop_loocv_joint()                 joint LOOCV coordinate-descent search
       trop_loocv_joint_exhaustive()      joint LOOCV Cartesian grid search

  3. Estimation interface
       trop_estimate_twostep()        two-step point estimation
       trop_estimate_joint()          joint point estimation

  4. Bootstrap interface
       trop_bootstrap_twostep()       two-step bootstrap variance
       trop_bootstrap_joint()         joint bootstrap variance

  5. Distance matrix
       trop_compute_unit_distance()   inter-unit RMSE distance matrix

  6. LOOCV diagnostics
       store_loocv_diagnostics()      post LOOCV diagnostics to e()
       check_loocv_fail_rate()        abort or warn on high failure rate
       display_loocv_verbose()        print LOOCV summary to console

  7. Orchestration
       _trop_main()                   LOOCV -> estimation -> bootstrap
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:
mata set matastrict on

/* ═══════════════════════════════════════════════════════════════════════════
   1. Platform detection and plugin loading
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  _trop_get_plugin_name()

  Returns the canonical plugin filename.  When installed via `net install`
  (SSC or GitHub) the platform-specific binary is already mapped to the
  generic name "trop.plugin" by the g/h directives in trop.pkg.

  For development builds where the platform-specific name still lives
  under plugin/, fall back to the old per-OS names.
──────────────────────────────────────────────────────────────────────────────*/

string scalar _trop_get_plugin_name()
{
    return("trop.plugin")
}

string scalar _trop_get_plugin_name_platform()
{
    string scalar os, machine

    os      = c("os")
    machine = c("machine_type")

    /* macOS: c(os) may report "MacOSX" or "Unix" across Stata versions */
    if (os == "MacOSX" | (os == "Unix" & strpos(machine, "Mac") > 0)) {
        if (strpos(machine, "Apple Silicon") > 0 |
            strpos(machine, "arm64") > 0) {
            return("trop_macos_arm64.plugin")
        }
        return("trop_macos_x64.plugin")
    }

    /* Linux: Unix that is not macOS */
    if (os == "Unix" & strpos(machine, "Mac") == 0) {
        return("trop_linux_x64.plugin")
    }

    /* Windows */
    if (os == "Windows") {
        return("trop_windows_x64.plugin")
    }

    return("")
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_get_plugin_path()

  Searches for the plugin binary with a two-tier fallback:
    1) SSC install: g/h directives rename to "trop.plugin" — found first.
    2) GitHub install: g/h not effective, files keep platform-specific names
       (trop_macos_arm64.plugin, trop_macos_x64.plugin, etc.).
  Also checks development build paths under plugin/ subdirectories.

  Returns the full path if found, "" otherwise.
──────────────────────────────────────────────────────────────────────────────*/

string scalar _trop_get_plugin_path()
{
    string scalar plugin_name, plugin_path
    string scalar sysdir_plus, sysdir_personal, pwd
    string scalar ado_path, pkg_dir, platform_name

    plugin_name = _trop_get_plugin_name()
    if (plugin_name == "") return("")
    platform_name = _trop_get_plugin_name_platform()

    /* --- 1. findfile on adopath (covers SSC where g/h maps to trop.plugin) --- */
    (void) _stata("capture findfile " + plugin_name, 1)
    plugin_path = st_global("r(fn)")
    if (plugin_path != "" & fileexists(plugin_path)) return(plugin_path)

    /* --- 1b. findfile platform name (GitHub: g/h not effective, original names) --- */
    if (platform_name != "") {
        (void) _stata("capture findfile " + platform_name, 1)
        plugin_path = st_global("r(fn)")
        if (plugin_path != "" & fileexists(plugin_path)) return(plugin_path)
    }

    /* --- 2. Same dir as trop.ado (adopath-relative) --- */
    (void) _stata("capture findfile trop.ado", 1)
    ado_path = st_global("r(fn)")
    if (ado_path != "") {
        /* net install puts plugin alongside ado */
        pkg_dir = subinstr(ado_path, "trop.ado", "", 1)
        plugin_path = pkg_dir + plugin_name
        if (fileexists(plugin_path)) return(plugin_path)

        /* GitHub install: platform-specific name alongside ado */
        if (platform_name != "") {
            plugin_path = pkg_dir + platform_name
            if (fileexists(plugin_path)) return(plugin_path)
        }

        /* dev layout: ado/ -> ../plugin/ */
        pkg_dir = subinstr(ado_path, "/ado/trop.ado", "", 1)
        if (pkg_dir != ado_path) {
            if (platform_name != "") {
                plugin_path = pkg_dir + "/plugin/" + platform_name
                if (fileexists(plugin_path)) return(plugin_path)
            }
        }
    }

    /* --- 3. CWD-relative dev paths with platform-specific name --- */
    pwd = st_global("c(pwd)")
    if (platform_name != "") {
        plugin_path = pwd + "/trop_stata/plugin/" + platform_name
        if (fileexists(plugin_path)) return(plugin_path)

        plugin_path = pwd + "/plugin/" + platform_name
        if (fileexists(plugin_path)) return(plugin_path)

        plugin_path = pwd + "/../plugin/" + platform_name
        if (fileexists(plugin_path)) return(plugin_path)
    }

    /* --- 4. System directories (try both canonical and platform names) --- */
    sysdir_plus = st_global("c(sysdir_plus)")
    plugin_path = sysdir_plus + "t/" + plugin_name
    if (fileexists(plugin_path)) return(plugin_path)
    if (platform_name != "") {
        plugin_path = sysdir_plus + "t/" + platform_name
        if (fileexists(plugin_path)) return(plugin_path)
    }

    sysdir_personal = st_global("c(sysdir_personal)")
    plugin_path = sysdir_personal + plugin_name
    if (fileexists(plugin_path)) return(plugin_path)
    if (platform_name != "") {
        plugin_path = sysdir_personal + platform_name
        if (fileexists(plugin_path)) return(plugin_path)
    }

    plugin_path = pwd + "/" + plugin_name
    if (fileexists(plugin_path)) return(plugin_path)
    if (platform_name != "") {
        plugin_path = pwd + "/" + platform_name
        if (fileexists(plugin_path)) return(plugin_path)
    }

    return("")
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_ensure_plugin()

  Loads the plugin into Stata via `program ... plugin using()`.
  If the plugin is already loaded (rc 110), the error is silently
  absorbed.  The plugin need only be loaded once per session.

  Returns 0 on success, 601 if the binary cannot be found.
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_ensure_plugin()
{
    string scalar plugin_path, cmd

    plugin_path = _trop_get_plugin_path()
    if (plugin_path == "") {
        errprintf("plugin not found; check installation\n")
        return(601)
    }

    cmd = `"capture program _trop_plugin, plugin using(""' ///
        + plugin_path + `"")"'
    (void) _stata(cmd, 1)

    return(0)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_call_plugin()

  Dispatches a command to the plugin with an optional variable list.

  Arguments
    command   name forwarded to the plugin dispatcher
    varlist   space-separated variable names (optional; defaults to
              the global macro __trop_varlist)

  The plugin receives variables indexed relative to the supplied varlist,
  not by their absolute dataset position.  When the global
  __trop_touse_var is set, an `if` qualifier is appended so that
  SF_ifobs() filters observations accordingly.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_call_plugin(string scalar command, | string scalar varlist)
{
    string scalar cmd, vars, touse_var
    real scalar rc

    rc = _trop_ensure_plugin()
    if (rc != 0) return(rc)

    if (args() < 2 | varlist == "") {
        vars = st_global("__trop_varlist")
        if (vars == "") {
            errprintf("no variable list specified\n")
            return(198)
        }
    }
    else {
        vars = varlist
    }

    touse_var = st_global("__trop_touse_var")
    if (touse_var != "") {
        cmd = "plugin call _trop_plugin " + vars ///
            + " if " + touse_var + " , " + command
    }
    else {
        cmd = "plugin call _trop_plugin " + vars + " , " + command
    }
    rc = _stata(cmd, 1)

    return(rc)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_call_plugin_simple()

  Dispatches a command to the plugin without a variable list.

  Arguments
    command   name forwarded to the plugin dispatcher

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_call_plugin_simple(string scalar command)
{
    string scalar cmd
    real scalar rc

    rc = _trop_ensure_plugin()
    if (rc != 0) return(rc)

    cmd = "plugin call _trop_plugin , " + command
    rc = _stata(cmd, 1)

    return(rc)
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_rust_available()

  Tests whether the plugin binary exists and can be loaded.

  Returns 1 if available, 0 otherwise.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_rust_available()
{
    if (_trop_get_plugin_path() == "") return(0)
    return(_trop_ensure_plugin() == 0)
}

/* ═══════════════════════════════════════════════════════════════════════════
   2. LOOCV interface

   Leave-one-out cross-validation selects the regularization triplet
   (lambda_time, lambda_unit, lambda_nn) by minimising the criterion

       Q(lambda) = sum_{i,t: W_{it}=0} (tau_hat_{it}(lambda))^2

   over a grid of candidate values.
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  trop_loocv_twostep()

  Two-step LOOCV grid search.  For each control observation (i,t) and
  each candidate lambda, solves the leave-one-out penalised regression
  to obtain tau_hat_{it}(lambda), then evaluates Q(lambda).

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_loocv_twostep()
{
    return(_trop_call_plugin("loocv_twostep"))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_loocv_twostep_exhaustive()

  Two-step LOOCV exhaustive (Cartesian) grid search.

  Evaluates every (lambda_time, lambda_unit, lambda_nn) combination in
  parallel; complexity is O(|Lambda_time| * |Lambda_unit| * |Lambda_nn|).
  Guarantees the global grid minimum under the tie-breaker rules, at the
  cost of higher computation for large grids.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_loocv_twostep_exhaustive()
{
    return(_trop_call_plugin("loocv_twostep_exhaustive"))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_loocv_joint()

  Joint LOOCV coordinate-descent search (default).

  Two-stage strategy adapted from Footnote 2 of Athey et al. (2025):
    Stage 1 — univariate sweeps with extreme fixed values;
    Stage 2 — cyclic coordinate descent until convergence.
  Complexity O(|grid| * max_cycles); favoured for large grids.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_loocv_joint()
{
    return(_trop_call_plugin("loocv_joint"))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_loocv_joint_exhaustive()

  Joint LOOCV exhaustive (Cartesian) grid search.

  Evaluates every (lambda_time, lambda_unit, lambda_nn) combination in
  parallel; complexity is O(|Lambda_time| * |Lambda_unit| * |Lambda_nn|).
  Guarantees the exact grid argmin of Q(lambda) over the supplied grids.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_loocv_joint_exhaustive()
{
    return(_trop_call_plugin("loocv_joint_exhaustive"))
}

/* ═══════════════════════════════════════════════════════════════════════════
   3. Estimation interface

   Given the selected lambda_hat, estimate the treatment effect(s).
   The two-step method yields observation-level tau_{i,t}; the joint
   method yields a single scalar tau.
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  trop_estimate_twostep()

  Two-step point estimation of observation-level treatment effects.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_estimate_twostep()
{
    return(_trop_call_plugin("estimate_twostep"))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_estimate_joint()

  Joint point estimation of the average treatment effect on the treated.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_estimate_joint()
{
    return(_trop_call_plugin("estimate_joint"))
}

/* ═══════════════════════════════════════════════════════════════════════════
   4. Bootstrap interface

   Variance estimation via unit-level resampling.  Each replicate
   re-draws N units with replacement and re-estimates tau, yielding
   an empirical distribution from which standard errors and percentile
   confidence intervals are computed.
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  trop_bootstrap_twostep()

  Two-step bootstrap variance estimation.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_bootstrap_twostep()
{
    return(_trop_call_plugin("bootstrap_twostep"))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_bootstrap_joint()

  Joint bootstrap variance estimation.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_bootstrap_joint()
{
    return(_trop_call_plugin("bootstrap_joint"))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_bootstrap_rao_wu_twostep()

  Two-step Rao-Wu bootstrap variance estimation for survey data.
  Uses the survey design matrices (__trop_strata, __trop_psu, __trop_fpc)
  prepared by trop_prepare_survey_design().

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_bootstrap_rao_wu_twostep()
{
    return(_trop_call_plugin("bootstrap_rao_wu_twostep"))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_bootstrap_rao_wu_joint()

  Joint Rao-Wu bootstrap variance estimation for survey data.
  Uses the survey design matrices (__trop_strata, __trop_psu, __trop_fpc)
  prepared by trop_prepare_survey_design().

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_bootstrap_rao_wu_joint()
{
    return(_trop_call_plugin("bootstrap_rao_wu_joint"))
}

/* ═══════════════════════════════════════════════════════════════════════════
   5. Distance matrix

   The unit distance metric is

       dist_{-t}(j,i) = sqrt( sum_{u!=t} (1-W_{iu})(1-W_{ju})
                               (Y_{iu}-Y_{ju})^2
                             / sum_{u!=t} (1-W_{iu})(1-W_{ju}) )

   which measures the root-mean-square outcome difference over jointly
   observed control periods, excluding the target period t.
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  trop_compute_unit_distance()

  Computes the N x N inter-unit distance matrix and stores it in the
  Stata matrix __trop_unit_dist.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_compute_unit_distance()
{
    return(_trop_call_plugin("distance_matrix"))
}

/* ═══════════════════════════════════════════════════════════════════════════
   6. LOOCV diagnostics
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  store_loocv_diagnostics()

  Collects LOOCV diagnostic scalars written by the plugin, derives the
  failure rate, and posts everything to e():

    e(loocv_score)        optimal cross-validation score  Q(lambda_hat)
    e(loocv_n_valid)      successful leave-one-out fits
    e(loocv_n_attempted)  attempted leave-one-out fits (=total D=0 cells)
    e(loocv_fail_rate)    fraction of failed fits
    e(seed)               RNG seed (used for bootstrap)

  Arguments
    method  "twostep" or "joint"
    seed    RNG seed (recorded only; LOOCV itself is deterministic)
──────────────────────────────────────────────────────────────────────────────*/

void store_loocv_diagnostics(
    string scalar method,
    real scalar seed)
{
    real scalar loocv_score, n_valid, n_attempted, fail_rate
    real matrix temp

    temp = st_numscalar("__trop_loocv_score")
    if (rows(temp) > 0) loocv_score = temp
    else loocv_score = .

    temp = st_numscalar("__trop_loocv_n_valid")
    if (rows(temp) > 0) n_valid = temp
    else n_valid = .

    temp = st_numscalar("__trop_loocv_n_attempted")
    if (rows(temp) > 0) n_attempted = temp
    else n_attempted = .

    if (n_attempted == . | n_attempted == 0) {
        fail_rate = .
    }
    else {
        fail_rate = (n_attempted - n_valid) / n_attempted
    }

    st_numscalar("e(loocv_score)",       loocv_score)
    st_numscalar("e(loocv_n_valid)",     n_valid)
    st_numscalar("e(loocv_n_attempted)", n_attempted)
    st_numscalar("e(loocv_fail_rate)",   fail_rate)
    st_numscalar("e(seed)",              seed)
}

/*──────────────────────────────────────────────────────────────────────────────
  check_loocv_fail_rate()

  Inspects e(loocv_fail_rate) and acts accordingly:
    > 50%    abort with rc 498 (results unreliable)
    >  5%    issue a warning, continue
    <= 5%    silent

  The 5 % warning threshold mirrors `_trop_display_bootstrap_warnings()`
  so LOOCV and bootstrap surface failures at the same sensitivity.  On a
  panel with ~1,000 D=0 cells a 5 % LOOCV failure rate means ~50 leave-
  one-out fits did not converge, which is enough to bias the selected
  λ triple off of Q(λ)'s true argmin (paper Eq. 5).  The 50 % abort
  threshold is retained as a stronger user protection.

  Returns 0 to continue, 498 to abort.
──────────────────────────────────────────────────────────────────────────────*/

real scalar check_loocv_fail_rate()
{
    real scalar fail_rate, first_t, first_i, n_valid, n_attempted
    real scalar lt, lu, ln
    real matrix temp
    string scalar ln_str

    temp = st_numscalar("e(loocv_fail_rate)")
    if (rows(temp) == 0) return(0)
    fail_rate = temp

    n_valid = .
    n_attempted = .
    temp = st_numscalar("e(loocv_n_valid)")
    if (rows(temp) > 0) n_valid = temp
    temp = st_numscalar("e(loocv_n_attempted)")
    if (rows(temp) > 0) n_attempted = temp

    first_t = .
    first_i = .
    temp = st_numscalar("e(loocv_first_failed_t)")
    if (rows(temp) > 0) first_t = temp
    temp = st_numscalar("e(loocv_first_failed_i)")
    if (rows(temp) > 0) first_i = temp

    /* Selected lambda triple.  e(lambda_nn) is the user-face scalar
       (+Inf shows as Stata missing); render it as "+Inf" to avoid an
       ambiguous ".".  All three scalars may be missing when LOOCV was
       skipped via fixedlambda(), in which case the helper lines below
       are omitted entirely. */
    lt = .
    lu = .
    ln = .
    temp = st_numscalar("e(lambda_time)")
    if (rows(temp) > 0) lt = temp
    temp = st_numscalar("e(lambda_unit)")
    if (rows(temp) > 0) lu = temp
    temp = st_numscalar("e(lambda_nn)")
    if (rows(temp) > 0) ln = temp
    ln_str = (ln >= . ? "+Inf" : strofreal(ln, "%10.4g"))

    if (fail_rate > 0.50) {
        errprintf("Error: LOOCV failure rate exceeds 50%% (%5.1f%%)\n",
                  fail_rate * 100)
        if (n_valid < . & n_attempted < .) {
            errprintf("       %g of %g leave-one-out fits failed.\n",
                      n_attempted - n_valid, n_attempted)
        }
        if (lt < . & lu < .) {
            errprintf(
                "       Selected lambda: (time=%10.4g, unit=%10.4g, nn=%s).\n",
                lt, lu, ln_str)
        }
        errprintf("       Results would be unreliable; check data quality.\n")
        if (first_t != . & first_i != . & first_t >= 0 & first_i >= 0) {
            /* Rust indices are 0-based; display 1-based to match Stata. */
            errprintf(
                "       First failing LOO fit: period %g, unit %g (1-based);\n",
                first_t + 1, first_i + 1)
            errprintf(
                "       cross-reference e(panelvar), e(timevar), and the estimation sample.\n")
        }
        return(498)
    }
    if (fail_rate > 0.05) {
        if (n_valid < . & n_attempted < .) {
            printf("{res}Warning: LOOCV failure rate is %5.1f%% (%g/%g successful){txt}\n",
                   fail_rate * 100, n_valid, n_attempted)
        }
        else {
            printf("{res}Warning: LOOCV failure rate is %5.1f%%{txt}\n",
                   fail_rate * 100)
        }
        if (lt < . & lu < .) {
            printf(
                "{txt}         Selected lambda: (time={res}%10.4g{txt}, unit={res}%10.4g{txt}, nn={res}%s{txt}).\n",
                lt, lu, ln_str)
        }
        printf("{res}         Selected lambda may be off the true Q(lambda) argmin.{txt}\n")
        if (first_t != . & first_i != . & first_t >= 0 & first_i >= 0) {
            printf(
                "{txt}         First failing LOO fit: period %g, unit %g (1-based);\n",
                first_t + 1, first_i + 1)
            printf(
                "{txt}         see e(loocv_first_failed_t), e(loocv_first_failed_i).\n")
        }
    }

    return(0)
}

/*──────────────────────────────────────────────────────────────────────────────
  display_loocv_verbose()

  Prints a one-line summary of LOOCV activity to the Results window:
  number of control observations evaluated and the success/failure
  breakdown.  LOOCV always sums over every D=0 cell (paper Eq. 5).
──────────────────────────────────────────────────────────────────────────────*/

void display_loocv_verbose()
{
    real scalar n_attempted, n_valid, fail_pct
    real matrix temp

    temp = st_numscalar("e(loocv_n_attempted)")
    if (rows(temp) > 0) n_attempted = temp
    else n_attempted = .

    temp = st_numscalar("e(loocv_n_valid)")
    if (rows(temp) > 0) n_valid = temp
    else n_valid = .

    if (n_attempted == . | n_attempted == 0) return

    printf("LOOCV: %g control obs evaluated\n", n_attempted)

    if (n_valid == .) n_valid = n_attempted
    fail_pct = (n_attempted - n_valid) / n_attempted * 100
    printf("LOOCV: %g/%g fits successful (%5.1f%% failure rate)\n",
           n_valid, n_attempted, fail_pct)
}

/* ═══════════════════════════════════════════════════════════════════════════
   7. Orchestration
   ═══════════════════════════════════════════════════════════════════════════ */

/*──────────────────────────────────────────────────────────────────────────────
  _trop_main()

  Executes the full estimation pipeline:
    1. Verify plugin availability
    2. LOOCV hyperparameter search   (if requested)
    3. Point estimation
    4. Bootstrap variance estimation (if requested)

  The e() result storage is handled by the calling ado-file after
  ereturn post.

  Arguments
    method           "twostep" or "joint"
    do_loocv         1 to run LOOCV, 0 to skip
    do_bootstrap     1 to run bootstrap, 0 to skip
    bootstrap_reps   number of bootstrap replications

  Optional argument
    ddof             variance denominator selector forwarded to the
                     bootstrap plugin: 1 = sample variance 1/(B-1)
                     (default); 0 = paper Algorithm 3 population
                     variance 1/B.  Any other value collapses to 1.

  Returns 0 on success.
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_main(
    string scalar method,
    real scalar do_loocv,
    real scalar do_bootstrap,
    real scalar bootstrap_reps,
    | real scalar ddof)
{
    real scalar rc
    real scalar lambda_time, lambda_unit, lambda_nn
    real scalar max_iter, tol, seed, alpha_level, ddof_eff
    real scalar has_survey
    real scalar n_cov
    string scalar joint_mode, twostep_mode

    /* ── plugin check ────────────────────────────────────────────────── */
    if (!trop_rust_available()) {
        errprintf("plugin not available; reinstall the package\n")
        return(198)
    }

    /* ── covariate guard ─────────────────────────────────────────────
       Ensure __trop_n_covariates is always defined before any plugin
       call.  trop_prepare_covariates() sets this when covariates are
       present; when it was never called (no covariates), default to 0
       so the C bridge reads a deterministic scalar. */
    {
        real matrix _tmp_ncov
        _tmp_ncov = st_numscalar("__trop_n_covariates")
        if (rows(_tmp_ncov) == 0) {
            st_numscalar("__trop_n_covariates", 0)
        }
    }

    /* ── LOOCV ───────────────────────────────────────────────────────── */
    if (do_loocv) {
        /* Progress reporting: display grid size before LOOCV starts */
        real scalar _loocv_verbose, _n_lt, _n_lu, _n_ln, _n_grid_total
        string scalar _loocv_mode_str
        _loocv_verbose = st_numscalar("__trop_verbose")
        if (_loocv_verbose >= .) _loocv_verbose = 0
        if (_loocv_verbose) {
            _n_lt = st_numscalar("__trop_n_lambda_time")
            _n_lu = st_numscalar("__trop_n_lambda_unit")
            _n_ln = st_numscalar("__trop_n_lambda_nn")
            if (_n_lt >= . | _n_lt == 0) _n_lt = 1
            if (_n_lu >= . | _n_lu == 0) _n_lu = 1
            if (_n_ln >= . | _n_ln == 0) _n_ln = 1
            _n_grid_total = _n_lt * _n_lu * _n_ln
            if (method == "twostep") {
                _loocv_mode_str = st_global("__trop_twostep_loocv_mode")
            }
            else {
                _loocv_mode_str = st_global("__trop_joint_loocv_mode")
            }
            displayas("txt")
            printf("{txt}\n")
            if (_loocv_mode_str == "exhaustive") {
                printf("{txt}LOOCV grid search (%g points, exhaustive):\n",
                       _n_grid_total)
            }
            else {
                printf("{txt}LOOCV grid search (%g+%g+%g = %g grid values, coordinate-descent):\n",
                       _n_lt, _n_lu, _n_ln, _n_lt + _n_lu + _n_ln)
            }
            printf("{txt}  lambda_time: %g values, lambda_unit: %g values, lambda_nn: %g values\n",
                   _n_lt, _n_lu, _n_ln)
            printf("{txt}  Computing")
            displayflush()
        }

        if (method == "twostep") {
            /* twostep: dispatch on __trop_twostep_loocv_mode.
               "exhaustive" -> full Cartesian search (guaranteed global
               minimum, O(|grid|^3));
               anything else (including missing) -> coordinate-descent
               cycling search (faster, may hit local minima). */
            twostep_mode = st_global("__trop_twostep_loocv_mode")
            if (twostep_mode == "exhaustive") rc = trop_loocv_twostep_exhaustive()
            else rc = trop_loocv_twostep()
        }
        else {
            /* joint: dispatch on __trop_joint_loocv_mode.
               "exhaustive" -> full Cartesian search;
               anything else (including missing) -> coordinate descent. */
            joint_mode = st_global("__trop_joint_loocv_mode")
            if (joint_mode == "exhaustive") rc = trop_loocv_joint_exhaustive()
            else rc = trop_loocv_joint()
        }

        /* Progress reporting: display completion */
        if (_loocv_verbose) {
            printf(" done\n")
            displayflush()
        }

        if (rc != 0) return(rc)
    }

    /* ── point estimation ────────────────────────────────────────────── */
    if (method == "twostep") rc = trop_estimate_twostep()
    else rc = trop_estimate_joint()
    if (rc != 0) return(rc)

    /* ── bootstrap variance estimation ───────────────────────────────── */
    if (do_bootstrap & bootstrap_reps > 0) {
        lambda_time = st_numscalar("__trop_lambda_time")
        lambda_unit = st_numscalar("__trop_lambda_unit")
        lambda_nn   = st_numscalar("__trop_lambda_nn")
        max_iter    = st_numscalar("__trop_max_iter")
        tol         = st_numscalar("__trop_tol")
        seed        = st_numscalar("__trop_seed")
        alpha_level = st_numscalar("__trop_alpha_level")

        /* ddof is forwarded only when the caller supplied a finite value;
           otherwise trop_prepare_bootstrap leaves __trop_bs_ddof unset and
           the plugin applies its default (sample variance, 1/(B-1)). */
        if (args() >= 5 & ddof < .) {
            ddof_eff = (ddof == 0) ? 0 : 1
            trop_prepare_bootstrap(
                bootstrap_reps, alpha_level, seed,
                lambda_time, lambda_unit, lambda_nn,
                max_iter, tol, ddof_eff)
        }
        else {
            trop_prepare_bootstrap(
                bootstrap_reps, alpha_level, seed,
                lambda_time, lambda_unit, lambda_nn,
                max_iter, tol)
        }

        /* Survey design branch: use Rao-Wu bootstrap when active */
        has_survey = st_numscalar("__trop_has_survey_design")
        if (has_survey >= .) has_survey = 0

        if (has_survey == 1) {
            if (method == "twostep") rc = trop_bootstrap_rao_wu_twostep()
            else rc = trop_bootstrap_rao_wu_joint()
        }
        else {
            if (method == "twostep") rc = trop_bootstrap_twostep()
            else rc = trop_bootstrap_joint()
        }
        if (rc != 0) return(rc)
    }

    return(0)
}

end
