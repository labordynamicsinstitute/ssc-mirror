*! dpath_build: Build decision-path variables from panel data
*! Version 1.0.0  Subir Hait, Michigan State University (2026)

/*
  dpath build varname, id(idvar) time(timevar) [group(groupvar) outcome(outcomevar)]

  Computes the following new variables (stored in dataset):
    _dp_path_str   : decision path string e.g. "0-1-1-0"
    _dp_dosage     : proportion of waves with decision == 1
    _dp_switch     : switching rate (proportion of changes)
    _dp_onset      : first wave where decision == 1
    _dp_duration   : total count of waves with decision == 1
    _dp_longest    : longest consecutive run of decision == 1
    _dp_n_periods  : number of observed waves for the unit

  Results stored in r():
    r(n_units)     : number of units
    r(n_waves)     : max number of waves
    r(balanced)    : 1 if balanced panel, 0 otherwise
    r(has_group)   : 1 if group variable supplied
    r(has_outcome) : 1 if outcome variable supplied
*/

program define dpath_build, rclass
    version 14.0

    syntax varname [if] [in],      ///
        id(varname)                 ///
        time(varname)               ///
        [                           ///
        GROup(varname)              ///
        OUTcome(varname)            ///
        ]

    marksample touse

    local decvar `varlist'

    // ── Validate binary decision variable ─────────────────────────────────
    quietly levelsof `decvar' if `touse', local(declevels)
    foreach lv of local declevels {
        if `lv' != 0 & `lv' != 1 {
            di as error "Variable `decvar' must be binary (0/1). Found value: `lv'"
            exit 198
        }
    }

    // ── Check panel structure ──────────────────────────────────────────────
    quietly xtset `id' `time'

    // Count units and waves
    quietly {
        egen long _dp_n_obs = count(`decvar') if `touse', by(`id')
        summarize _dp_n_obs if `touse', meanonly
        local n_waves_max = r(max)
        local n_waves_min = r(min)
        drop _dp_n_obs
    }

    local balanced = (`n_waves_max' == `n_waves_min')
    if !`balanced' {
        di as text "(note: unbalanced panel detected — wave counts range from " ///
            `n_waves_min' " to " `n_waves_max' ")"
    }

    quietly levelsof `id' if `touse', local(id_levels)
    local n_units : word count `id_levels'

    // ── Drop any existing _dp_ variables from previous runs ──────────────
    capture drop _dp_n_periods _dp_dosage _dp_treat_count _dp_duration
    capture drop _dp_switch _dp_d_lag _dp_changed _dp_switch_sum _dp_n_adj
    capture drop _dp_onset _dp_onset_min
    capture drop _dp_longest _dp_run_id _dp_run_len _dp_max_run
    capture drop _dp_path_str

    // ── Create per-unit path descriptor variables ──────────────────────────
    quietly {

        // Number of observed periods
        capture drop _dp_n_periods
        bysort `id' (`time'): gen long _dp_n_periods = _N if `touse'

        // Dosage: mean of decision within unit
        capture drop _dp_dosage
        bysort `id': egen double _dp_dosage = mean(`decvar') if `touse'

        // Treatment count
        capture drop _dp_treat_count
        bysort `id': egen long _dp_treat_count = total(`decvar') if `touse'

        // Duration = treatment count
        capture drop _dp_duration
        gen long _dp_duration = _dp_treat_count if `touse'

        // Switching rate — drop ALL temp vars first to avoid "already defined"
        capture drop _dp_switch _dp_d_lag _dp_changed _dp_switch_sum _dp_n_adj
        bysort `id' (`time'): gen double _dp_d_lag = `decvar'[_n-1] if `touse'
        gen byte _dp_changed = (`decvar' != _dp_d_lag) ///
            if !missing(`decvar') & !missing(_dp_d_lag) & `touse'
        replace _dp_changed = 0 if missing(_dp_changed) & `touse'
        bysort `id': egen double _dp_switch_sum = total(_dp_changed) if `touse'
        bysort `id' (`time'): gen long _dp_n_adj = _N - 1 if `touse'
        gen double _dp_switch = _dp_switch_sum / _dp_n_adj ///
            if `touse' & !missing(_dp_n_adj) & _dp_n_adj > 0
        replace _dp_switch = 0 if `touse' & _dp_n_adj == 0
        drop _dp_d_lag _dp_changed _dp_switch_sum _dp_n_adj

        // Onset: first wave where decision == 1
        capture drop _dp_onset
        gen double _dp_onset = `time' if `decvar' == 1 & `touse'
        bysort `id': egen double _dp_onset_min = min(_dp_onset) if `touse'
        drop _dp_onset
        rename _dp_onset_min _dp_onset

        // Longest consecutive run of 1s — Stata approach using group runs
        capture drop _dp_longest
        capture drop _dp_run_id _dp_run_len _dp_max_run
        bysort `id' (`time'): gen long _dp_run_id = sum(`decvar' != `decvar'[_n-1]) if `touse'
        bysort `id' _dp_run_id: gen long _dp_run_len = _N if `touse' & `decvar' == 1
        bysort `id' _dp_run_id: replace _dp_run_len = . if `decvar' == 0
        bysort `id': egen long _dp_longest = max(_dp_run_len) if `touse'
        replace _dp_longest = 0 if missing(_dp_longest) & `touse'
        drop _dp_run_id _dp_run_len

        // Path string (decision sequence concatenated with "-")
        capture drop _dp_path_str
        gen str40 _dp_path_str = ""
        // Set wave 1 first, then append subsequent waves
        bysort `id' (`time'): replace _dp_path_str = ///
            string(int(`decvar')) if _n == 1 & `touse'
        bysort `id' (`time'): replace _dp_path_str = ///
            _dp_path_str[_n-1] + "-" + string(int(`decvar')) ///
            if _n > 1 & `touse'
        // Propagate final path string to all rows within unit
        bysort `id' (`time'): replace _dp_path_str = _dp_path_str[_N] if `touse'

    }

    // ── Label new variables ────────────────────────────────────────────────
    label variable _dp_n_periods   "Decision Path: number of observed waves"
    label variable _dp_dosage      "Decision Path: dosage (proportion with decision=1)"
    label variable _dp_treat_count "Decision Path: count of waves with decision=1"
    label variable _dp_duration    "Decision Path: duration (= treatment count)"
    label variable _dp_switch      "Decision Path: switching rate"
    label variable _dp_onset       "Decision Path: onset (first wave with decision=1)"
    label variable _dp_longest     "Decision Path: longest consecutive run of decision=1"
    label variable _dp_path_str    "Decision Path: path string (e.g. 0-1-1-0)"

    // ── Return results ─────────────────────────────────────────────────────
    return scalar n_units     = `n_units'
    return scalar n_waves     = `n_waves_max'
    return scalar balanced    = `balanced'
    return scalar has_group   = ("`group'"   != "")
    return scalar has_outcome = ("`outcome'" != "")

    // ── Summary output ─────────────────────────────────────────────────────
    di as text  _newline "{hline 50}"
    di as result "  dpath build — Decision Path Variables Created"
    di as text  "{hline 50}"
    di as text  "  Decision variable : " as result "`decvar'"
    di as text  "  ID variable       : " as result "`id'"
    di as text  "  Time variable     : " as result "`time'"
    di as text  "  Units             : " as result `n_units'
    di as text  "  Max waves         : " as result `n_waves_max'
    di as text  "  Balanced panel    : " as result cond(`balanced',"Yes","No")
    if "`group'" != "" {
        di as text  "  Group variable    : " as result "`group'"
    }
    if "`outcome'" != "" {
        di as text  "  Outcome variable  : " as result "`outcome'"
    }
    di as text  "{hline 50}"
    di as text  "  New variables created:"
    di as text  "    _dp_path_str  _dp_dosage  _dp_switch"
    di as text  "    _dp_onset     _dp_duration _dp_longest"
    di as text  "    _dp_n_periods _dp_treat_count"
    di as text  "{hline 50}"

end
