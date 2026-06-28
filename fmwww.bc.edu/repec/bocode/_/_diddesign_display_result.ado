*! _diddesign_display_result.ado - Display a single row of estimation results
*!
*! Internal utility for the output display module. Each result row shows the
*! point estimate, standard error, confidence interval, and GMM weight for
*! one of the component estimators (Standard DID, Sequential DID) or the
*! combined Double DID estimator.

version 16.0

// ============================================================================
// _diddesign_display_result
// Output a single row of the estimation results table
//
// Each row corresponds to one estimator: Standard DID, Sequential DID, or
// Double DID. Fixed-width formatting is applied to ensure column alignment.
// The GMM weight column shows the optimal weight assigned to each component
// estimator under the GMM framework.
//
// Arguments:
//   label    : string - Row label identifying the estimator
//   estimate : real   - Point estimate of the treatment effect
//   se       : real   - Standard error of the estimate
//   ci_low   : real   - Lower bound of confidence interval
//   ci_high  : real   - Upper bound of confidence interval
//   weight   : real   - GMM weight (-1 if not applicable)
//
// Returns:
//   None (displays formatted output to console)
// ============================================================================
program define _diddesign_display_result
    
    syntax , LABEL(string) ESTIMATE(real) SE(real) ///
             CI_low(real) CI_high(real) [WEIGHT(real -1)]
    
    // -------------------------------------------------------------------------
    // Format numeric values with fixed widths
    // -------------------------------------------------------------------------
    // Fixed-width formatting applied for column alignment
    // All values use %9.4f = total 9 chars with leading spaces
    local est_fmt = string(`estimate', "%9.4f")
    local se_fmt = string(`se', "%9.4f")
    local ci_low_fmt = string(`ci_low', "%9.4f")
    local ci_high_fmt = string(`ci_high', "%9.4f")

    // -------------------------------------------------------------------------
    // Format GMM weight
    // -------------------------------------------------------------------------
    // A value of -1 denotes the combined estimator (Double DID), for which no
    // single weight is applicable; missing values are treated equivalently
    if `weight' == -1 | `weight' == . {
        local wt_display = "        ."
    }
    else {
        local wt_display = string(`weight', "%9.3f")
    }

    // -------------------------------------------------------------------------
    // Display formatted result row with fixed column widths
    // Columns: Estimator(13) + sep(3) + Estimate(9) + Std.Err(10) + CI_low(10) + CI_high(10) + Weight(9)
    // Total: 13 + 3 + 9 + 10 + 10 + 10 + 9 = 64 chars for data
    // -------------------------------------------------------------------------
    display as text %13s "`label'" " | " ///
            as result %9s "`est_fmt'" %10s "`se_fmt'" %10s "`ci_low_fmt'" %10s "`ci_high_fmt'" %9s "`wt_display'"
end
