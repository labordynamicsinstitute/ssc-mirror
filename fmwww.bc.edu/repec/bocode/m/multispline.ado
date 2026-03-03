capture program drop multispline
program define multispline, rclass
    version 14.1

    // =========================================================================
    // multispline — Nonlinear multilevel spline modeling
    // Author : Subir Hait, Michigan State University
    // Version: 1.0.4  01mar2026
    //
    // Syntax:
    //   multispline y x [if] [in], cluster(varname)
    //       [ nknots(#) autoknots at(numlist) plot ]
    //
    // Notes:
    //   - Stata 14 mixed does not support weights
    //   - nknots() must be >= 3 for cubic spline
    //   - interior knots = nknots - 2
    //   - spline terms  = nknots - 1
    //   - at() grid is automatically expanded to 50 points
    //     spanning min to max of requested values
    // =========================================================================

    // -------------------------------------------------------------------------
    // 1) Parse syntax
    // -------------------------------------------------------------------------
    syntax varlist(min=2 max=2 numeric) [if] [in],  ///
        CLuster(name)                                ///
        [ NKNOTS(integer 4)                          ///
          AUTOKNOTS                                  ///
          AT(numlist)                                ///
          PLOT ]

    // Separate outcome and predictor
    tokenize `varlist'
    local y `1'
    local x `2'

    // -------------------------------------------------------------------------
    // Header
    // -------------------------------------------------------------------------
    di as txt _newline "{hline 52}"
    di as txt "  multispline: Nonlinear Multilevel Modeling"
    di as txt "  Version 1.0.4 | Subir Hait | MSU 2026"
    di as txt "{hline 52}"
    di as txt "  Outcome   : " as res "`y'"
    di as txt "  Predictor : " as res "`x'"
    di as txt "  Cluster   : " as res "`cluster'"
    di as txt "{hline 52}"

    // -------------------------------------------------------------------------
    // 2) Determine nknots
    // -------------------------------------------------------------------------
    if "`autoknots'" != "" {

        quietly levelsof `x' `if' `in', local(xlevs)
        local nx : word count `xlevs'

        local nknots = floor(sqrt(`nx'))
        if `nknots' < 4 local nknots = 4
        if `nknots' > 7 local nknots = 7

        di as txt "  Method    : " as res "Autoknots"
        di as txt "  Knots     : " as res "`nknots' (selected automatically)"
        di as txt "{hline 52}"
    }
    else {
        if `nknots' < 3 {
            di as err "nknots() must be >= 3. Resetting to nknots(3)."
            local nknots = 3
        }
        di as txt "  Method    : " as res "User-specified"
        di as txt "  Knots     : " as res "`nknots'"
        di as txt "{hline 52}"
    }

    // -------------------------------------------------------------------------
    // 3) Compute interior knot locations for reporting
    //    interior = nknots - 2
    //    spline terms = nknots - 1
    // -------------------------------------------------------------------------
    local interior = `nknots' - 2

    if `interior' < 1 {
        di as err "Too few interior knots. Resetting to nknots(3)."
        local nknots   = 3
        local interior = 1
    }

    // Equally spaced percentiles for interior knots
    local pctlist ""
    forvalues j = 1/`interior' {
        local p = 100 * `j' / (`interior' + 1)
        local pctlist "`pctlist' `p'"
    }

    quietly centile `x' `if' `in', centile(`pctlist')

    local knotlist ""
    forvalues j = 1/`interior' {
        local knotlist "`knotlist' `=r(c_`j')'"
    }

    di as txt _newline "Step 1: Interior knots (" as res "`interior'" ///
        as txt "): `knotlist'"

    // -------------------------------------------------------------------------
    // 4) Create spline basis on estimation sample
    // -------------------------------------------------------------------------
    capture drop __ms_sp*
    tempname spbase
    quietly mkspline `spbase' = `x' `if' `in', cubic nknots(`nknots')

    capture unab _spl : `spbase'*
    if _rc != 0 {
        di as err "Error: mkspline failed to create spline variables."
        di as err "Try reducing nknots() or check your data."
        exit 498
    }

    local k = 1
    foreach v of local _spl {
        capture drop __ms_sp`k'
        quietly rename `v' __ms_sp`k'
        local ++k
    }

    local nsplines = `k' - 1
    di as txt "Step 2: Spline basis created (" as res "`nsplines'" ///
        as txt " terms)"

    // -------------------------------------------------------------------------
    // 5) Fit multilevel model
    // -------------------------------------------------------------------------
    di as txt _newline "Step 3: Fitting multilevel model..."
    mixed `y' __ms_sp* `if' `in' || `cluster':

    estimates store _ms_model

    // -------------------------------------------------------------------------
    // 6) ICC
    // -------------------------------------------------------------------------
    di as txt _newline "Step 4: Intraclass Correlation (ICC):"
    estat icc

    // -------------------------------------------------------------------------
    // 7) Predictions
    //    Mode A — at() : expand to 50-point dense grid spanning min-max
    //    Mode B — default : predict on estimation sample
    // -------------------------------------------------------------------------
    if "`at'" != "" {

        preserve

            // Find min and max of requested at() values
            local atlist ""
            foreach val of numlist `at' {
                local atlist "`atlist' `val'"
            }

            // Get min and max
            local atmin = .
            local atmax = .
            foreach val of numlist `at' {
                if `val' < `atmin' | `atmin' == . local atmin = `val'
                if `val' > `atmax' | `atmax' == . local atmax = `val'
            }

            di as txt _newline "Step 5: Predictions over range " ///
                as res "[`atmin', `atmax']" ///
                as txt " (50-point grid)"

            // Create 50-point dense grid
            clear
            set obs 50
            gen double `x' = `atmin' + (`atmax' - `atmin') * (_n - 1) / 49

            // Fake cluster for xb prediction
            gen long `cluster' = 1

            // Rebuild spline basis with same nknots
            // 50 points is always enough for any nknots 3-7
            capture drop __ms_sp*
            tempname spbase2
            quietly mkspline `spbase2' = `x', cubic nknots(`nknots')

            capture unab _spl2 : `spbase2'*
            if _rc != 0 {
                di as err "Error: mkspline failed on prediction grid."
                restore
                exit 498
            }

            local k2 = 1
            foreach v of local _spl2 {
                capture drop __ms_sp`k2'
                quietly rename `v' __ms_sp`k2'
                local ++k2
            }

            // Restore fitted model and predict fixed-effects part (xb)
            quietly estimates restore _ms_model
            capture drop __ms_fit
            predict double __ms_fit, xb

            di as txt _newline "Prediction summary:"
            quietly summarize __ms_fit
            di as txt "  N    : " as res r(N)
            di as txt "  Mean : " as res %9.3f r(mean)
            di as txt "  SD   : " as res %9.3f r(sd)
            di as txt "  Min  : " as res %9.3f r(min)
            di as txt "  Max  : " as res %9.3f r(max)

            if "`plot'" != "" {
                twoway line __ms_fit `x', sort                         ///
                    title("multispline: predicted curve")              ///
                    subtitle("Natural cubic spline | nknots=`nknots'") ///
                    ytitle("Predicted `y'")                            ///
                    xtitle("`x'")                                      ///
                    lcolor(navy) lwidth(medthick)                      ///
                    scheme(s2color)
            }

        restore

    }
    else {

        di as txt _newline "Step 5: Predictions on estimation sample..."
        capture drop __ms_fit
        predict double __ms_fit, xb

        di as txt _newline "Prediction summary:"
        quietly summarize __ms_fit `if' `in'
        di as txt "  N    : " as res r(N)
        di as txt "  Mean : " as res %9.3f r(mean)
        di as txt "  SD   : " as res %9.3f r(sd)
        di as txt "  Min  : " as res %9.3f r(min)
        di as txt "  Max  : " as res %9.3f r(max)

        if "`plot'" != "" {
            twoway line __ms_fit `x' `if' `in', sort                   ///
                title("multispline: fitted values")                    ///
                subtitle("Natural cubic spline | nknots=`nknots'")    ///
                ytitle("Predicted `y'")                                ///
                xtitle("`x'")                                          ///
                lcolor(navy) lwidth(medthick)                          ///
                scheme(s2color)
        }
    }

    // -------------------------------------------------------------------------
    // 8) Return results
    // -------------------------------------------------------------------------
    return local  cmd       "multispline"
    return local  y         "`y'"
    return local  x         "`x'"
    return local  cluster   "`cluster'"
    return local  knots     "`knotlist'"
    return scalar nknots    = `nknots'
    return scalar nsplines  = `nsplines'
    return scalar interior  = `interior'

    // -------------------------------------------------------------------------
    // Footer
    // -------------------------------------------------------------------------
    di as txt _newline "{hline 52}"
    di as txt "  multispline completed successfully"
    di as txt "  Estimates stored : _ms_model"
    di as txt "  Predictions in   : __ms_fit"
    di as txt "  Use -estimates restore _ms_model-"
    di as txt "  to access model results"
    di as txt "{hline 52}" _newline

end
