*! dpath_equity: Distributive equity diagnostics for decision paths
*! Version 1.0.0  Subir Hait, Michigan State University (2026)

/*
  dpath equity, id(idvar) time(timevar) by(groupvar) [ref(reflevel)]

  Computes equity diagnostics via standardized mean differences (SMDs)
  across path descriptors (dosage, switching rate, onset, duration, DRI)
  between group levels and a reference group.

  SMD = (mean_g - mean_ref) / SD_pooled
  |SMD| < 0.10 : negligible difference (equity achieved)
  |SMD| 0.10-0.20 : small
  |SMD| > 0.20 : meaningful inequity

  Results stored in r():
    r(smd_dosage)   : SMD for dosage
    r(smd_switch)   : SMD for switching rate
    r(smd_onset)    : SMD for onset
    r(smd_duration) : SMD for duration
    r(DRI_ref)      : DRI for reference group
*/

program define dpath_equity, rclass
    version 14.0

    syntax , id(varname) time(varname) BY(varname) [REF(string)]

    // ── Check prerequisites ───────────────────────────────────────────────
    foreach v in _dp_dosage _dp_switch _dp_onset _dp_duration {
        capture confirm variable `v'
        if _rc {
            di as error "Variable `v' not found. Run {cmd:dpath build} first."
            exit 111
        }
    }

    capture confirm variable `by'
    if _rc {
        di as error "Group variable `by' not found."
        exit 111
    }

    preserve

    // Keep one row per unit
    quietly bysort `id' (`time'): keep if _n == _N

    // ── Get group levels ──────────────────────────────────────────────────
    quietly levelsof `by', local(grplevels)
    local n_groups : word count `grplevels'

    if `n_groups' < 2 {
        di as error "Group variable `by' has fewer than 2 levels."
        exit 198
    }

    // Reference group: use first level if not specified
    if "`ref'" == "" {
        local ref : word 1 of `grplevels'
    }

    // Check ref is valid
    local ref_found 0
    foreach g of local grplevels {
        if "`g'" == "`ref'" local ref_found 1
    }
    if !`ref_found' {
        di as error "Reference level `ref' not found in `by'."
        exit 198
    }

    // ── Compute overall SD for each metric ───────────────────────────────
    foreach metric in _dp_dosage _dp_switch _dp_onset _dp_duration {
        quietly summarize `metric'
        local sd_`metric' = r(sd)
    }

    // ── Reference group stats ─────────────────────────────────────────────
    quietly summarize _dp_dosage   if `by' == "`ref'", meanonly
    local mean_dosage_ref = r(mean)
    quietly summarize _dp_switch   if `by' == "`ref'", meanonly
    local mean_switch_ref = r(mean)
    local dri_ref         = 1 - `mean_switch_ref'
    quietly summarize _dp_onset    if `by' == "`ref'", meanonly
    local mean_onset_ref  = r(mean)
    quietly summarize _dp_duration if `by' == "`ref'", meanonly
    local mean_dur_ref    = r(mean)
    quietly count if `by' == "`ref'"
    local n_ref = r(N)

    // ── Display header ────────────────────────────────────────────────────
    di as text  _newline "{hline 65}"
    di as result "  dpath equity — Equity Diagnostics"
    di as text  "{hline 65}"
    di as text  "  Group variable   : " as result "`by'"
    di as text  "  Reference group  : " as result "`ref'" ///
        " (N=" `n_ref' ")"
    di as text  "{hline 65}"
    di as text  "  Reference group descriptors:"
    di as text  "    Dosage    : " as result %6.3f `mean_dosage_ref'
    di as text  "    Switch    : " as result %6.3f `mean_switch_ref'
    di as text  "    DRI       : " as result %6.3f `dri_ref'
    di as text  "    Onset     : " as result %6.3f `mean_onset_ref'
    di as text  "    Duration  : " as result %6.3f `mean_dur_ref'
    di as text  "{hline 65}"
    di as text  "  Standardized Mean Differences (vs. `ref'):"
    di as text  "  {hline 60}"
    di as text  "  Group       N   Dosage  Switch  Onset   Duration  DRI"
    di as text  "  {hline 60}"

    // ── SMD for each non-reference group ─────────────────────────────────
    foreach g of local grplevels {
        if "`g'" == "`ref'" continue

        quietly count if `by' == "`g'"
        local ng = r(N)

        quietly summarize _dp_dosage   if `by' == "`g'", meanonly
        local smd_dos = (`r(mean)' - `mean_dosage_ref') / max(`sd__dp_dosage', 0.0001)

        quietly summarize _dp_switch   if `by' == "`g'", meanonly
        local ms_g    = r(mean)
        local smd_sw  = (`ms_g' - `mean_switch_ref') / max(`sd__dp_switch', 0.0001)
        local dri_g   = 1 - `ms_g'

        quietly summarize _dp_onset    if `by' == "`g'", meanonly
        local smd_on  = (`r(mean)' - `mean_onset_ref') / max(`sd__dp_onset', 0.0001)

        quietly summarize _dp_duration if `by' == "`g'", meanonly
        local smd_dur = (`r(mean)' - `mean_dur_ref') / max(`sd__dp_duration', 0.0001)

        local dri_smd = `dri_g' - `dri_ref'

        di as text  "  " %-10s "`g'" "  " as result %3.0f `ng' ///
            "  " %6.3f `smd_dos' "  " %6.3f `smd_sw' ///
            "  " %6.3f `smd_on' "  " %8.3f `smd_dur' ///
            "  " %5.3f `dri_smd'
    }

    di as text  "  {hline 60}"
    di as text  "  Note: |SMD| < 0.10 negligible; 0.10-0.20 small; > 0.20 meaningful"

    // ── By-group mean table ───────────────────────────────────────────────
    di as text  _newline "  Group-level means:"
    di as text  "  {hline 60}"
    di as text  "  Group       N    Dosage   Switch   Onset   Duration   DRI"
    di as text  "  {hline 60}"

    foreach g of local grplevels {
        quietly count if `by' == "`g'"
        local ng = r(N)
        quietly summarize _dp_dosage   if `by' == "`g'", meanonly
        local md = r(mean)
        quietly summarize _dp_switch   if `by' == "`g'", meanonly
        local ms = r(mean)
        local dr = 1 - `ms'
        quietly summarize _dp_onset    if `by' == "`g'", meanonly
        local mo = r(mean)
        quietly summarize _dp_duration if `by' == "`g'", meanonly
        local mdu = r(mean)
        di as text  "  " %-10s "`g'" "  " as result %4.0f `ng' ///
            "  " %7.3f `md' "  " %7.3f `ms' "  " %6.3f `mo' ///
            "  " %8.3f `mdu' "  " %5.3f `dr'
    }
    di as text  "  {hline 60}"

    restore

    // ── Return scalars ────────────────────────────────────────────────────
    return scalar DRI_ref = `dri_ref'

end
