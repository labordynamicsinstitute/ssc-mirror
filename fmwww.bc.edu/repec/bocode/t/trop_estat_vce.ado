/*
    trop_estat_vce: Display Variance-Covariance Matrix

    Displays the variance-covariance matrix (VCE) after trop estimation.

    Syntax:
        estat vce [, correlation]

    Options:
        correlation    Display as a correlation matrix (reserved for interface
                       compatibility; has no effect on a scalar variance).
*/
program define trop_estat_vce
    version 17
    syntax [, correlation]

    // Verify that trop estimation results are available.
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }

    // Display the variance-covariance matrix.
    di as txt ""
    di as txt "{hline 65}"
    di as txt "Variance-Covariance Matrix (1×1)"
    di as txt "{hline 65}"

    // Check if e(V) exists (available only when bootstrap is performed).
    // If absent, report the point-estimate standard error instead.
    capture confirm matrix e(V)
    if _rc {
        di as txt "(e(V) not available — bootstrap() was not specified)"
        di as txt "(run trop with bootstrap() option to obtain variance estimates)"
        di as txt "{hline 65}"
        di as txt ""
        di as txt "Standard Error: " as res %9.3f e(se) as txt " (from e(se))"
    }
    else {
        tempname V
        matrix `V' = e(V)

        // Display the VCE matrix.
        matlist `V', border(rows) rowtitle("         ") ///
            cspec(& %12s | %12.6f &) rspec(&-&)

        di as txt "{hline 65}"

        // Display standard error.
        di as txt ""
        di as txt "Standard Error: " as res %9.3f e(se) as txt " (from e(se))"
    }

    // Determine the variance estimation method.
    // Prioritize e(vcetype); otherwise, infer from bootstrap replication count.
    local vce_method "`e(vcetype)'"
    local bsvariance "`e(bsvariance)'"
    if "`vce_method'" == "" {
        capture confirm scalar e(bootstrap_reps)
        if !_rc & e(bootstrap_reps) > 0 {
            local vce_method "Bootstrap"
        }
        else {
            local vce_method "None (bootstrap required)"
        }
    }
    di as txt "Variance estimation method: " as res "`vce_method'"

    // Display bootstrap configuration details if applicable.
    if "`vce_method'" == "Bootstrap" {
        capture confirm scalar e(bootstrap_reps)
        if !_rc {
            di as txt "  Replications: " as res %8.0f e(bootstrap_reps)
        }
        if "`bsvariance'" == "paper" {
            di as txt "  SE denom:     " as res "paper (1/B)"
        }
        else if "`bsvariance'" != "" {
            di as txt "  SE denom:     " as res "sample (1/(B-1))"
        }
        capture confirm scalar e(n_bootstrap_valid)
        if !_rc {
            if e(n_bootstrap_valid) < e(bootstrap_reps) {
                di as txt "  Valid reps:   " as res %8.0f e(n_bootstrap_valid)
            }
        }
    }

    di as txt "{hline 65}"
end

