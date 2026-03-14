*! dpath_dri: Decision Reliability Index
*! Version 1.0.0  Subir Hait, Michigan State University (2026)

/*
  dpath dri, id(idvar) time(timevar) [by(groupvar)]

  Computes the Decision Reliability Index (DRI):
    DRI = 1 - mean(switching_rate)

  DRI = 1.0 => perfectly consistent decisions (Type I infrastructure)
  DRI = 0.0 => maximum instability

  Interpretation thresholds (adapted from Nunnally, 1978):
    DRI >= 0.90 : High reliability
    DRI  0.70-0.89 : Acceptable
    DRI  0.50-0.69 : Questionable
    DRI < 0.50  : Poor reliability

  Results stored in r():
    r(DRI)               : overall DRI
    r(mean_switch)       : mean switching rate
    r(n_units)           : number of units
*/

program define dpath_dri, rclass
    version 14.0

    syntax , id(varname) time(varname) [BY(varname)]

    // ── Check prerequisites ───────────────────────────────────────────────
    foreach v in _dp_switch {
        capture confirm variable `v'
        if _rc {
            di as error "Variable `v' not found. Run {cmd:dpath build} first."
            exit 111
        }
    }

    preserve

    // Keep one row per unit
    quietly bysort `id' (`time'): keep if _n == _N

    // ── Overall DRI ───────────────────────────────────────────────────────
    quietly summarize _dp_switch
    local mean_switch = r(mean)
    local sd_switch   = r(sd)
    local dri         = 1 - `mean_switch'
    local n_units     = r(N)

    // ── Interpretation ────────────────────────────────────────────────────
    local interp ""
    if `dri' >= 0.90 {
        local interp "High reliability — consistent infrastructure"
    }
    else if `dri' >= 0.70 {
        local interp "Acceptable reliability"
    }
    else if `dri' >= 0.50 {
        local interp "Questionable reliability — moderate path instability"
    }
    else {
        local interp "Poor reliability — high path instability"
    }

    // ── Infrastructure type classification ────────────────────────────────
    local infra_type ""
    if `dri' >= 0.95 {
        local infra_type "Type I (Static)"
    }
    else if `dri' >= 0.75 {
        local infra_type "Type II (Periodically Recalibrated)"
    }
    else if `dri' >= 0.50 {
        local infra_type "Type III (Continuously Adaptive)"
    }
    else {
        local infra_type "Type IV (Human-in-the-Loop)"
    }

    // ── Display ───────────────────────────────────────────────────────────
    di as text  _newline "{hline 55}"
    di as result "  dpath dri — Decision Reliability Index"
    di as text  "{hline 55}"
    di as text  "  Units               : " as result `n_units'
    di as text  "  Mean switching rate : " as result %7.3f `mean_switch'
    di as text  "  SD switching rate   : " as result %7.3f `sd_switch'
    di as text  "{hline 55}"
    di as text  "  DRI                 : " as result %7.3f `dri'
    di as text  "  Interpretation      : " as result "`interp'"
    di as text  "  Suggested type      : " as result "`infra_type'"
    di as text  "{hline 55}"

    // ── By-group DRI ─────────────────────────────────────────────────────
    if "`by'" != "" {
        capture confirm variable `by'
        if _rc {
            di as error "Group variable `by' not found."
        }
        else {
            di as text  _newline "  DRI by group (`by'):"
            di as text  "  {hline 50}"
            di as text  "  Group        N     Mean Switch    DRI"
            di as text  "  {hline 50}"

            quietly levelsof `by', local(grplevels)
            foreach g of local grplevels {
                quietly count if `by' == "`g'"
                local ng = r(N)
                quietly summarize _dp_switch if `by' == "`g'", meanonly
                local ms_g   = r(mean)
                local dri_g  = 1 - `ms_g'
                di as text  "  " %-10s "`g'" "  " as result %5.0f `ng' ///
                    "    " %10.3f `ms_g' "    " %6.3f `dri_g'
            }
            di as text  "  {hline 50}"
        }
    }

    restore

    // ── Return ────────────────────────────────────────────────────────────
    return scalar DRI         = `dri'
    return scalar mean_switch = `mean_switch'
    return scalar n_units     = `n_units'

end
