*! dpath_describe: Per-unit decision path descriptors
*! Version 1.0.0  Subir Hait, Michigan State University (2026)

/*
  dpath describe, id(idvar) time(timevar) [by(groupvar)]

  Requires dpath build to have been run first.
  Displays and returns per-unit summary statistics for:
    dosage, switching_rate, onset, duration, longest_run

  Results stored in r():
    r(mean_dosage)    : mean dosage across units
    r(mean_switch)    : mean switching rate
    r(mean_onset)     : mean onset wave
    r(mean_duration)  : mean duration
    r(n_unique_paths) : number of unique path strings
    r(n_units)        : number of units
*/

program define dpath_describe, rclass
    version 14.0

    syntax , id(varname) time(varname) [BY(varname)]

    // ── Check that dpath build was run ────────────────────────────────────
    foreach v in _dp_dosage _dp_switch _dp_onset _dp_duration _dp_path_str {
        capture confirm variable `v'
        if _rc {
            di as error "Variable `v' not found. Run {cmd:dpath build} first."
            exit 111
        }
    }

    // ── Collapse to unit level ────────────────────────────────────────────
    preserve

    quietly {
        bysort `id' (`time'): keep if _n == _N  // keep last row per unit
    }

    // ── Overall summary ───────────────────────────────────────────────────
    quietly summarize _dp_dosage
    local mean_dosage = r(mean)
    local sd_dosage   = r(sd)

    quietly summarize _dp_switch
    local mean_switch = r(mean)
    local sd_switch   = r(sd)

    quietly summarize _dp_onset
    local mean_onset = r(mean)

    quietly summarize _dp_duration
    local mean_dur = r(mean)

    quietly levelsof _dp_path_str, local(paths)
    local n_unique : word count `paths'

    quietly count
    local n_units = r(N)

    // ── Display overall results ───────────────────────────────────────────
    di as text  _newline "{hline 55}"
    di as result "  dpath describe — Decision Path Descriptors"
    di as text  "{hline 55}"
    di as text  "  Units              : " as result `n_units'
    di as text  "  Unique paths       : " as result `n_unique'
    di as text  "{hline 55}"
    di as text  "  Metric             Mean       SD"
    di as text  "  {hline 43}"
    di as text  "  Dosage          " as result %8.3f `mean_dosage' "   " %8.3f `sd_dosage'
    di as text  "  Switching rate  " as result %8.3f `mean_switch' "   " %8.3f `sd_switch'
    di as text  "  Onset (wave)    " as result %8.3f `mean_onset'  "   "
    di as text  "  Duration        " as result %8.3f `mean_dur'    "   "

    // ── By-group summary ──────────────────────────────────────────────────
    if "`by'" != "" {
        capture confirm variable `by'
        if _rc {
            di as error "Group variable `by' not found."
        }
        else {
            di as text  _newline "  By group (`by'):"
            di as text  "  {hline 55}"
            di as text  "  Group       N     Dosage   Switching  DRI"
            di as text  "  {hline 55}"

            quietly levelsof `by', local(grplevels)
            foreach g of local grplevels {
                quietly count if `by' == "`g'"
                local ng = r(N)
                quietly summarize _dp_dosage if `by' == "`g'", meanonly
                local md = r(mean)
                quietly summarize _dp_switch if `by' == "`g'", meanonly
                local ms = r(mean)
                local dri_g = 1 - `ms'
                di as text  "  " %-8s "`g'" "  " as result %5.0f `ng' "  " ///
                    %7.3f `md' "  " %9.3f `ms' "  " %6.3f `dri_g'
            }
            di as text  "  {hline 55}"
        }
    }

    restore

    // ── Return scalars ────────────────────────────────────────────────────
    return scalar mean_dosage    = `mean_dosage'
    return scalar mean_switch    = `mean_switch'
    return scalar mean_onset     = `mean_onset'
    return scalar mean_duration  = `mean_dur'
    return scalar n_unique_paths = `n_unique'
    return scalar n_units        = `n_units'

end
