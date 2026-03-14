*! dpath_audit: Five-step Decision Infrastructure Audit
*! Version 1.0.0  Subir Hait, Michigan State University (2026)

/*
  dpath audit varname, id(idvar) time(timevar) [by(groupvar) ref(reflevel)]

  Runs the full five-step Decision Infrastructure Audit (Hait, 2025):
    Step 1: Build decision-path variables
    Step 2: Path descriptors (dosage, switching, onset, duration)
    Step 3: Decision Reliability Index (DRI)
    Step 4: Shannon path entropy
    Step 5: Equity diagnostics (if by() specified)

  Returns all scalars from sub-commands.
*/

program define dpath_audit, rclass
    version 14.0

    syntax varname [if] [in] ,  ///
        id(varname)              ///
        time(varname)            ///
        [                        ///
        BY(varname)              ///
        REF(string)              ///
        OUTcome(varname)         ///
        ]

    marksample touse

    local decvar `varlist'
    capture drop _dp_*
    // ═══════════════════════════════════════════════════════════════════════
    di as text  _newline
    di as result "{hline 60}"
    di as result "  Decision Infrastructure Audit  (Hait, 2025)"
    di as result "  dpath v1.0.0  —  Stata Implementation"
    di as result "{hline 60}"
    di as text  "  Decision var : " as result "`decvar'"
    di as text  "  ID var       : " as result "`id'"
    di as text  "  Time var     : " as result "`time'"
    if "`by'" != "" {
        di as text  "  Group var    : " as result "`by'"
    }
    di as result "{hline 60}"

    // ═══════════════════════════════════════════════════════════════════════
    di as result _newline "  STEP 1 — Build Decision-Path Variables"
    di as text  "{hline 60}"

    if "`by'" != "" & "`outcome'" != "" {
        dpath_build `decvar' if `touse', id(`id') time(`time') ///
            group(`by') outcome(`outcome')
    }
    else if "`by'" != "" {
        dpath_build `decvar' if `touse', id(`id') time(`time') group(`by')
    }
    else if "`outcome'" != "" {
        dpath_build `decvar' if `touse', id(`id') time(`time') outcome(`outcome')
    }
    else {
        dpath_build `decvar' if `touse', id(`id') time(`time')
    }

    local n_units  = r(n_units)
    local n_waves  = r(n_waves)
    local balanced = r(balanced)

    // ═══════════════════════════════════════════════════════════════════════
    di as result _newline "  STEP 2 — Path Descriptors"
    di as text  "{hline 60}"

    if "`by'" != "" {
        dpath_describe, id(`id') time(`time') by(`by')
    }
    else {
        dpath_describe, id(`id') time(`time')
    }

    local mean_dosage    = r(mean_dosage)
    local mean_switch    = r(mean_switch)
    local mean_onset     = r(mean_onset)
    local mean_duration  = r(mean_duration)
    local n_unique_paths = r(n_unique_paths)

    // ═══════════════════════════════════════════════════════════════════════
    di as result _newline "  STEP 3 — Decision Reliability Index (DRI)"
    di as text  "{hline 60}"

    if "`by'" != "" {
        dpath_dri, id(`id') time(`time') by(`by')
    }
    else {
        dpath_dri, id(`id') time(`time')
    }

    local DRI        = r(DRI)
    local mean_sw    = r(mean_switch)

    // ═══════════════════════════════════════════════════════════════════════
    di as result _newline "  STEP 4 — Shannon Path Entropy"
    di as text  "{hline 60}"

    if "`by'" != "" {
        dpath_entropy, id(`id') time(`time') by(`by')
    }
    else {
        dpath_entropy, id(`id') time(`time')
    }

    local H        = r(entropy)
    local H_norm   = r(normalized_entropy)
    local n_unique = r(n_unique_paths)

    // ═══════════════════════════════════════════════════════════════════════
    if "`by'" != "" {
        di as result _newline "  STEP 5 — Equity Diagnostics"
        di as text  "{hline 60}"

        if "`ref'" != "" {
            dpath_equity, id(`id') time(`time') by(`by') ref(`ref')
        }
        else {
            dpath_equity, id(`id') time(`time') by(`by')
        }

        local DRI_ref = r(DRI_ref)
    }

    // ═══════════════════════════════════════════════════════════════════════
    di as result _newline "{hline 60}"
    di as result "  AUDIT SUMMARY"
    di as result "{hline 60}"
    di as text  "  Units              : " as result `n_units'
    di as text  "  Max waves          : " as result `n_waves'
    di as text  "  Balanced panel     : " as result cond(`balanced',"Yes","No")
    di as text  "  Mean dosage        : " as result %7.3f `mean_dosage'
    di as text  "  Mean switching rate: " as result %7.3f `mean_switch'
    di as text  "  DRI                : " as result %7.3f `DRI'
    di as text  "  Entropy H (bits)   : " as result %7.3f `H'
    di as text  "  Normalized H*      : " as result %7.3f `H_norm'
    di as text  "  Unique paths       : " as result `n_unique'
    if "`by'" != "" {
        di as text  "  Equity diagnostics : " as result "Computed (see Step 5)"
    }
    di as result "{hline 60}"

    // ── Infrastructure type classification ────────────────────────────────
    local itype ""
    local idesc ""
    if `DRI' >= 0.95 & `H_norm' < 0.30 {
        local itype "Type I — Static"
        local idesc "Fixed rules; decisions rarely change"
    }
    else if `DRI' >= 0.70 & `H_norm' < 0.70 {
        local itype "Type II — Periodically Recalibrated"
        local idesc "Stable within periods; updates at intervals"
    }
    else if `DRI' >= 0.40 & `H_norm' >= 0.50 {
        local itype "Type III — Continuously Adaptive"
        local idesc "High entropy; decisions update frequently"
    }
    else {
        local itype "Type IV — Human-in-the-Loop"
        local idesc "High variability; human overrides present"
    }

    di as text  _newline "  Suggested infrastructure type:"
    di as result "    " "`itype'"
    di as text  "    " "`idesc'"
    di as result "{hline 60}"
    di as text  "  Reference: Hait, S. (2025). Artificial intelligence as"
    di as text  "  decision infrastructure. Michigan State University."
    di as result "{hline 60}"

    // ── Return all scalars ────────────────────────────────────────────────
    return scalar n_units            = `n_units'
    return scalar n_waves            = `n_waves'
    return scalar balanced           = `balanced'
    return scalar mean_dosage        = `mean_dosage'
    return scalar mean_switch        = `mean_switch'
    return scalar DRI                = `DRI'
    return scalar entropy            = `H'
    return scalar normalized_entropy = `H_norm'
    return scalar n_unique_paths     = `n_unique'

end
