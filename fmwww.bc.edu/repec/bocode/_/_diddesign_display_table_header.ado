*! _diddesign_display_table_header.ado - Display column headers for estimation results
*!
*! Outputs formatted column headers for the DID estimation summary table,
*! including estimator labels, point estimates, standard errors, confidence
*! intervals, and GMM weights. Part of the display utility module.

version 16.0

// ============================================================================
// _diddesign_display_table_header
// Display column headers for the estimation results table.
//
// Outputs a standardized header row with columns for:
//   - Estimator name (DID, sDID, Double DID)
//   - Point estimate
//   - Standard error
//   - Confidence interval bounds at system-specified level
//   - GMM weight (for component estimators)
//
// Arguments:
//   None
//
// Returns:
//   None (displays output to console)
// ============================================================================
program define _diddesign_display_table_header
    version 16.0
    
    display as text ""
    display as text "{hline 78}"
    display as text %13s "Estimator" " | " %9s "Estimate" %10s "Std.Err." %20s "[95% Conf. Interval]" %9s "Weight"
    display as text "{hline 14}+{hline 64}"
end
