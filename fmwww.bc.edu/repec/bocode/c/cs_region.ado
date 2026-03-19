*! cs_region.ado  v1.0.1  2026-03-18  Stata 14.1 compatible ASCII only
*! Regional fragility integral over a treatment interval

program define cs_region, rclass
    version 14.0

    syntax , A(real) B(real) [ Type(string) ]

    if "`type'" == "" local type "curvature_ratio"
    if !inlist("`type'", "curvature_ratio", "inverse_slope") {
        di as error "type() must be: curvature_ratio  inverse_slope"
        exit 198
    }

    if "$CSCMD" != "causalspline" {
        di as error "cs_region requires causalspline to be run first"
        exit 301
    }

    local t_min = $CSTMIN
    local t_max = $CSTMAX

    if `a' < `t_min' local a = `t_min'
    if `b' > `t_max' local b = `t_max'
    if `a' >= `b' {
        di as error "a() must be less than b()"
        exit 198
    }

    // Get fragility values from cs_fragility
    qui cs_fragility, type(`type') noplot

    tempname frag ft
    mat `frag' = r(fragility)
    mat `ft'   = r(frag_t)

    local ng    = rowsof(`frag')
    local count = 0
    local integ = 0
    local avg   = 0

    forval j = 1/`ng' {
        local tv = `ft'[`j',1]
        if `tv' >= `a' & `tv' <= `b' {
            local fv = `frag'[`j',1]
            if `fv' != . {
                local integ = `integ' + `fv'
                local count = `count' + 1
            }
        }
    }

    if `count' > 0 {
        local avg = `integ' / `count'
        // Trapezoidal integration
        local width = (`b' - `a') / `count'
        local integ = `integ' * `width'
    }

    di as text " "
    di as text "{hline 55}"
    di as text " Regional Fragility Summary"
    di as text "{hline 55}"
    di as text "  Interval       : [" %6.3f `a' as text ", " %6.3f `b' as text "]"
    di as text "  Type           : " as result "`type'"
    di as text "  Grid points    : " as result `count'
    di as text "{hline 55}"
    di as text "  Integral fragility : " as result %10.5f `integ'
    di as text "  Average fragility  : " as result %10.5f `avg'
    di as text "{hline 55}"

    if "`type'" == "curvature_ratio" {
        di as text " "
        di as text "  Interpretation (curvature_ratio):"
        di as text "  < 0.5  : stable region (low curvature relative to slope)"
        di as text "  0.5-2  : moderate structural change"
        di as text "  > 2    : high fragility (threshold / turning point)"
    }
    else {
        di as text " "
        di as text "  Interpretation (inverse_slope):"
        di as text "  Low    : steep causal effect (structurally strong)"
        di as text "  High   : flat causal effect (structurally weak)"
    }

    return scalar integral_frag = `integ'
    return scalar avg_frag      = `avg'
    return scalar grid_points   = `count'
    return scalar a             = `a'
    return scalar b             = `b'
    return local  type          "`type'"
end
