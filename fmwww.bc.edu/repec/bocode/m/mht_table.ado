*! version 1.0.0 18may2026 Viviano, Wuthrich, Niehaus & Rosas Lopez
*! mht_table -- Display table of optimal test sizes
*! Based on Viviano, Wuthrich, and Niehaus (2026)

/*
    mht_table -- Reproduce Table 1 of Viviano, Wuthrich, and Niehaus (2026)

    Default behavior (no arguments) reproduces Table 1 of v10 of the paper EXACTLY:

      |J|=1..9 plus infinity (rows)
      Columns:
        - At n_bar/m_bar = 100%, four alphabar values: 0.025, 0.05, 0.10, 0.15
        - At n_bar/m_bar = 50%, 150%, 200%, single alphabar = 0.025
        - Two Sidak benchmark columns: alpha_bar = 0.025 and 0.05

    Custom usage: pass alphabar(), jrange(), nmratios() to override defaults.
    When custom args are given, the simpler single-alpha-across-nm-ratios layout
    is used.

    Syntax:
        mht_table [, alphabar(#) jrange(numlist) nmratios(numlist)
                     sidakbars(numlist) nosidak model(string) options]

    Stored results (r()):
        r(alpha_<j>_<nm>_<ab>) : optimal alpha for J=j, n/m, alphabar (default mode)
        r(alpha_<j>_<nm>)      : optimal alpha for J=j, n/m (custom mode)
        r(sidak_<ab>_<j>)      : Sidak level
        r(model)               : cost model used
*/

program define mht_table, rclass
    version 15.0
    syntax [,                              ///
            ALPHAbar(real -1)              ///  benchmark alpha (-1 sentinel for default)
            Jrange(numlist integer >0)     ///  J values for rows
            NMratios(numlist >0)           ///  n/m values for columns
            SIDAKbars(numlist >0 <=1)      ///  alpha_bar values for Sidak columns
            NOSidak                        ///  suppress Sidak columns
            NOInf                          ///  suppress J=infinity row
            MODel(string)                  ///  linear or cobbdouglas
            CFshare(real 0.46)             ///  Linear: fixed cost share
            Jbar(real 3)                   ///  Linear: avg subgroups
            BETA(real 0.13)                ///  Cobb-Douglas: arms elasticity
            IOTA(real 0.075)               ///  Cobb-Douglas: size elasticity
            ]

    if "`model'" == "" local model "linear"
    if "`model'" != "linear" & "`model'" != "cobbdouglas" {
        display as error `"model() must be "linear" or "cobbdouglas""'
        exit 198
    }

    // Decide whether we are in DEFAULT mode (paper Table 1) or CUSTOM mode
    local default_mode = 0
    if `alphabar' == -1 & "`jrange'" == "" & "`nmratios'" == "" & "`sidakbars'" == "" {
        local default_mode = 1
    }

    if `default_mode' {
        _mht_table_paper, model(`model') cfshare(`cfshare') jbar(`jbar') ///
            beta(`beta') iota(`iota') `noinf'
        return add
    }
    else {
        if `alphabar' == -1 local alphabar 0.05
        if `alphabar' <= 0 | `alphabar' >= 1 {
            display as error "alphabar() must be strictly between 0 and 1"
            exit 198
        }
        if "`jrange'"   == "" local jrange   1 2 3 4 5 6 7 8 9
        if "`nmratios'" == "" local nmratios 0.5 1.0 1.5 2.0
        if "`nosidak'" == "" & "`sidakbars'" == "" local sidakbars 0.025 0.05
        if "`nosidak'" != "" local sidakbars ""

        _mht_table_custom, alphabar(`alphabar') jrange(`jrange') ///
            nmratios(`nmratios') sidakbars(`sidakbars') ///
            model(`model') cfshare(`cfshare') jbar(`jbar') ///
            beta(`beta') iota(`iota') `noinf'
        return add
    }

    return local model = "`model'"
end


// =============================================================================
// _mht_table_paper -- Reproduces paper Table 1 exactly
// =============================================================================

program define _mht_table_paper, rclass
    syntax [, MODel(string) CFshare(real 0.46) Jbar(real 3) ///
              BETA(real 0.13) IOTA(real 0.075) NOInf ]

    if "`model'" == "" local model "linear"
    local model_str = cond("`model'" == "linear", "Linear (Eq. 26)", "Cobb-Douglas (App. A)")

    local jrange "1 2 3 4 5 6 7 8 9"
    local alphas_100 "0.025 0.05 0.10 0.15"
    local nm_other   "0.5 1.5 2.0"
    local alpha_other 0.025
    local sidakbars "0.025 0.05"

    // Header
    display ""
    display as text "{hline 90}"
    display as result "  Table 1: Critical values as functions of hypothesis count and sample size"
    display as text   "  Viviano, Wuthrich, and Niehaus (2026)"
    display as text   "  Model: " as result "`model_str'"
    if "`model'" == "linear" {
        display as text "  Calibration: cf_share=" as result %4.2f `cfshare' ///
                as text ", jbar=" as result %3.0f `jbar'
    }
    else {
        display as text "  Calibration: beta=" as result %5.3f `beta' ///
                as text ", iota=" as result %5.3f `iota'
    }
    display as text "{hline 90}"
    display ""

    // Top-row group labels
    display as text "         |        n_bar/m_bar = 100%             |  50%   | 150%   | 200%   |  Sidak"
    display as text "    |J|  | a=.025  a=.050  a=.100  a=.150   | a=.025 | a=.025 | a=.025 | .025   .050"
    display as text "  " "{hline 86}"

    // Finite J rows
    foreach j of numlist `jrange' {
        // n/m=100%, four alphas
        local cells_100 ""
        foreach a of numlist `alphas_100' {
            quietly mht_critical, jhypotheses(`j') alphabar(`a') ///
                model(`model') cfshare(`cfshare') jbar(`jbar') ///
                nmratio(1.0) beta(`beta') iota(`iota')
            local aopt = r(alpha_opt)
            local ab_key = "0" + subinstr(string(`a'), ".", "p", .)
            return scalar alpha_`j'_100_`ab_key' = `aopt'
            local cells_100 = "`cells_100'" + " " + string(`aopt', "%7.4f")
        }
        // Other n/m at alpha=0.025
        local cells_other ""
        foreach nm of numlist `nm_other' {
            quietly mht_critical, jhypotheses(`j') alphabar(`alpha_other') ///
                model(`model') cfshare(`cfshare') jbar(`jbar') ///
                nmratio(`nm') beta(`beta') iota(`iota')
            local aopt = r(alpha_opt)
            local nm_key = subinstr("`nm'", ".", "p", .)
            return scalar alpha_`j'_`nm_key'_0p025 = `aopt'
            local cells_other = "`cells_other'" + " " + string(`aopt', "%7.4f")
        }
        // Sidak
        local cells_sid ""
        foreach a of numlist `sidakbars' {
            local sid = 1 - (1 - `a')^(1/`j')
            local ab_key = "0" + subinstr(string(`a'), ".", "p", .)
            return scalar sidak_`ab_key'_`j' = `sid'
            local cells_sid = "`cells_sid'" + " " + string(`sid', "%6.4f")
        }

        display as result "    " %3.0f `j' "  | " "`cells_100'" "  | " "`cells_other'" "  | " "`cells_sid'"
    }

    // J = infinity row
    if "`noinf'" == "" {
        local cells_100 ""
        foreach a of numlist `alphas_100' {
            quietly mht_critical, jhypotheses(999999) alphabar(`a') ///
                model(`model') cfshare(`cfshare') jbar(`jbar') ///
                nmratio(1.0) beta(`beta') iota(`iota')
            local cells_100 = "`cells_100'" + " " + string(r(alpha_opt), "%7.4f")
        }
        local cells_other ""
        foreach nm of numlist `nm_other' {
            quietly mht_critical, jhypotheses(999999) alphabar(`alpha_other') ///
                model(`model') cfshare(`cfshare') jbar(`jbar') ///
                nmratio(`nm') beta(`beta') iota(`iota')
            local cells_other = "`cells_other'" + " " + string(r(alpha_opt), "%7.4f")
        }
        local cells_sid ""
        foreach a of numlist `sidakbars' {
            local cells_sid = "`cells_sid'" + " " + string(0, "%6.4f")
        }
        display as result "    Inf  | " "`cells_100'" "  | " "`cells_other'" "  | " "`cells_sid'"
    }

    display as text "  " "{hline 86}"
    display ""
    display as text "  Notes: Optimal critical values for different |J| and n_bar/m_bar."
    display as text "         alpha_Sidak = 1 - (1 - alpha_bar)^(1/|J|), exact for FWER with independent tests."
    if "`model'" == "cobbdouglas" {
        display as text ""
        display as text "  Caveat (Cobb-Douglas): Paper Table 3 uses alphabar=0.05 in the 50%, 150%, 200%"
        display as text "  columns (vs 0.025 here, matching Table 1 layout). The paper does not explicitly"
        display as text "  justify the switch; it is the economics-RCT convention rather than the FDA"
        display as text "  convention used in Table 1. To reproduce Table 3 exactly, call:"
        display as text "    mht_table, alphabar(0.05) jrange(1 2 3 4 5 6 7 8 9) nmratios(0.5 1.0 1.5 2.0) model(cobbdouglas)"
    }
    display as text "{hline 90}"
    display ""
end


// =============================================================================
// _mht_table_custom -- Legacy single-alpha layout for custom user calls
// =============================================================================

program define _mht_table_custom, rclass
    syntax , ALPHAbar(real) JRange(numlist integer >0) ///
             NMratios(numlist >0) ///
             [ SIDAKbars(numlist >0 <=1) ///
               MODel(string) CFshare(real 0.46) Jbar(real 3) ///
               BETA(real 0.13) IOTA(real 0.075) NOInf ]

    if "`model'" == "" local model "linear"
    local model_str = cond("`model'" == "linear", "Linear (Eq. 26)", "Cobb-Douglas (App. A)")
    local n_nm  : word count `nmratios'
    local n_sid : word count `sidakbars'

    display ""
    display as text "{hline 72}"
    display as result "  Optimal Test Sizes  [Viviano, Wuthrich & Niehaus 2026]"
    display as text "  Model: " as result "`model_str'"
    display as text "  Benchmark alpha: " as result %6.4f `alphabar'
    display as text "{hline 72}"
    display ""

    local header "  |J|"
    forvalues k = 1/`n_nm' {
        local nm_k : word `k' of `nmratios'
        local nm_pct = string(round(`nm_k' * 100), "%3.0f") + "%"
        local header = "`header'" + "    n/m=" + "`nm_pct'"
    }
    if `n_sid' > 0 {
        forvalues k = 1/`n_sid' {
            local ab_k : word `k' of `sidakbars'
            local header = "`header'" + "  Sid(a=" + string(`ab_k') + ")"
        }
    }
    display as text "`header'"
    local hlen = 4 + 10*`n_nm' + 12*`n_sid'
    display as text "  {hline `hlen'}"

    foreach j of numlist `jrange' {
        local row = "  " + string(`j', "%3.0f")
        forvalues k = 1/`n_nm' {
            local nm_k : word `k' of `nmratios'
            quietly mht_critical, jhypotheses(`j') alphabar(`alphabar') ///
                model(`model') cfshare(`cfshare') jbar(`jbar') ///
                nmratio(`nm_k') beta(`beta') iota(`iota')
            local aopt = r(alpha_opt)
            local nm_key = subinstr("`nm_k'", ".", "p", .)
            return scalar alpha_`j'_`nm_key' = `aopt'
            local row = "`row'" + "    " + string(`aopt', "%8.4f")
        }
        if `n_sid' > 0 {
            forvalues k = 1/`n_sid' {
                local ab_k : word `k' of `sidakbars'
                local sid  = 1 - (1 - `ab_k')^(1/`j')
                local ab_key = "0" + subinstr(string(`ab_k'), ".", "p", .)
                return scalar sidak_`ab_key'_`j' = `sid'
                local row = "`row'" + "  " + string(`sid', "%10.4f")
            }
        }
        display as result "`row'"
    }

    if "`noinf'" == "" {
        local row = "  Inf"
        forvalues k = 1/`n_nm' {
            local nm_k : word `k' of `nmratios'
            quietly mht_critical, jhypotheses(999999) alphabar(`alphabar') ///
                model(`model') cfshare(`cfshare') jbar(`jbar') ///
                nmratio(`nm_k') beta(`beta') iota(`iota')
            local aopt = r(alpha_opt)
            local nm_key = subinstr("`nm_k'", ".", "p", .)
            return scalar alpha_inf_`nm_key' = `aopt'
            local row = "`row'" + "    " + string(`aopt', "%8.4f")
        }
        if `n_sid' > 0 {
            forvalues k = 1/`n_sid' {
                local row = "`row'" + "  " + string(0, "%10.4f")
            }
        }
        display as result "`row'"
    }

    display as text "  {hline `hlen'}"
    display ""

    return scalar alpha_bar = `alphabar'
end
