*! cs_gradient.ado  v1.0.1  2026-03-18  Stata 14.1 compatible ASCII only
*! First and second derivatives of the dose-response curve

program define cs_gradient, rclass
    version 14.0

    syntax [anything]

    if "$CSCMD" != "causalspline" {
        di as error "cs_gradient requires causalspline to be run first"
        exit 301
    }

    tempname ct ce cse d1 d2
    mat `ct'  = CSCT
    mat `ce'  = CSCE
    mat `cse' = CSCSE

    local ng = $CSNGRID

    mat `d1' = J(`ng', 1, .)
    mat `d2' = J(`ng', 1, .)

    // Finite difference derivatives
    forval j = 2/`ng' {
        local jm1 = `j' - 1
        local dt = `ct'[`j',1] - `ct'[`jm1',1]
        if `dt' > 0 {
            mat `d1'[`j',1] = (`ce'[`j',1] - `ce'[`jm1',1]) / `dt'
        }
    }
    // Backfill first row
    mat `d1'[1,1] = `d1'[2,1]

    // Second derivative
    forval j = 2/`= `ng' - 1' {
        local jp1 = `j' + 1
        local jm1 = `j' - 1
        local dt1 = `ct'[`jp1',1] - `ct'[`j',1]
        local dt2 = `ct'[`j',1] - `ct'[`jm1',1]
        if `dt1' > 0 & `dt2' > 0 {
            mat `d2'[`j',1] = (`d1'[`jp1',1] - `d1'[`jm1',1]) / (`dt1' + `dt2')
        }
    }

    // Display
    di as text " "
    di as text "{hline 75}"
    di as text " Gradient Curve (Derivatives of Dose-Response Function)"
    di as text "{hline 75}"
    di as text %10s "t" %13s "E[Y(t)]" %11s "SE" %13s "dE/dt" %13s "d2E/dt2"
    di as text "{hline 75}"

    foreach j in 1 `= round(`ng'*0.15)' `= round(`ng'*0.40)' ///
                   `= round(`ng'*0.65)' `= round(`ng'*0.85)' `ng' {
        if `j' >= 1 & `j' <= `ng' {
            local d2v = `d2'[`j',1]
            if `d2v' == . {
                di as result %10.3f `ct'[`j',1] ///
                             %13.4f `ce'[`j',1] ///
                             %11.4f `cse'[`j',1] ///
                             %13.4f `d1'[`j',1] ///
                             %13s "."
            }
            else {
                di as result %10.3f `ct'[`j',1] ///
                             %13.4f `ce'[`j',1] ///
                             %11.4f `cse'[`j',1] ///
                             %13.4f `d1'[`j',1] ///
                             %13.6f `d2v'
            }
        }
    }
    di as text "{hline 75}"
    di as text "First derivative  = marginal causal effect dE[Y(t)]/dt"
    di as text "Second derivative = curvature (acceleration of effect)"

    return matrix grad_t  = `ct'
    return matrix grad_mu = `ce'
    return matrix grad_se = `cse'
    return matrix grad_d1 = `d1'
    return matrix grad_d2 = `d2'
end
