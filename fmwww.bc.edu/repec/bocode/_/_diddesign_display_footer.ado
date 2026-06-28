*! _diddesign_display_footer.ado - Display estimation footer with methodological notes
*!
*! Part of the DIDdesign output display system. Displays footer information
*! after the results table, including GMM weight normalization notes,
*! confidence interval method, and confidence level.

version 16.0

// ============================================================================
// _diddesign_display_footer - Display methodological notes after results table
//
// Arguments:
//   n_boot    : integer - Number of bootstrap replications (default: 30)
//   level     : real    - Confidence level in percent (default: 95)
//   ci_method : string  - CI method: "asymptotic" or "bootstrap"
//   notes     : string  - User-specified notes (optional)
//
// Returns:
//   None (output displayed to console)
// ============================================================================
program define _diddesign_display_footer
    version 16.0
    
    syntax , [N_boot(integer 30) LEVEL(real 95) ///
              CI_method(string) NOTES(string)]
    
    display as text "{hline 75}"
    
    // -------------------------------------------------------------------------
    // GMM Weight Normalization
    // -------------------------------------------------------------------------
    
    display as text ""
    display as text "Note: Weights sum to 1."
    
    // -------------------------------------------------------------------------
    // Inference Method
    // -------------------------------------------------------------------------
    
    if "`ci_method'" == "asymptotic" {
        display as text "      CI computed using asymptotic formula."
    }
    else if "`ci_method'" == "bootstrap" {
        display as text "      CI computed using bootstrap quantiles (`n_boot' replications)."
    }
    
    display as text "      Confidence level: `level'%"
    
    // -------------------------------------------------------------------------
    // User Notes
    // -------------------------------------------------------------------------
    
    if "`notes'" != "" {
        display as text "      `notes'"
    }
end
