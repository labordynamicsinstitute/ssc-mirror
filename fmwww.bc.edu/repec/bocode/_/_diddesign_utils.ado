*! _diddesign_utils.ado - Utility functions module and error/warning code reference
*!
*! Provides module information entry point and defines standardized error/warning
*! codes for the DIDdesign package. Actual utility functions are implemented in
*! independent ado files for modular architecture:
*!   - _diddesign_error.ado
*!   - _diddesign_warning.ado
*!   - _diddesign_display_header.ado
*!   - _diddesign_display_table_header.ado
*!   - _diddesign_display_result.ado
*!   - _diddesign_display_footer.ado
*!
*! Error Codes:
*!   E001 - Missing required variable/option (exit 198)
*!   E002 - Invalid parameter value (exit 198)
*!   E003 - Data structure issue (exit 459)
*!   E004 - Singular VCOV matrix (exit 498)
*!   E005 - No valid SA periods (exit 498)
*!   E006 - Negative variance estimate (exit 498)
*!   E007 - Treatment reversal detected (exit 459)
*!   E008 - Non-consecutive time periods (exit 459)
*!   E009 - Empty bootstrap sample (exit 498)
*!   E010 - Zero variance in control group (exit 498)
*!   E011 - All bootstrap iterations failed (exit 498)
*!   E012 - Invalid formula (LHS) (exit 198)
*!   E013 - Invalid formula (RHS) (exit 198)
*!   E014 - SA design requires panel data (exit 198)
*!   E015 - Mata library not loaded (exit 499)
*!   E016 - Conflicting options (exit 198)
*!   E017 - Invalid variable type (exit 198)
*!
*! Warning Codes:
*!   W001 - No control group in SA period
*!   W002 - Singular VCOV in bootstrap iteration
*!   W003 - Insufficient post-treatment periods for lead
*!   W004 - Single observation per cluster
*!   W005 - Missing outcome values dropped
*!   W006 - Collinear covariates detected
*!   W007 - Unbalanced panel detected
*!   W008 - Single valid period for SA design
*!   W009 - Threshold adjusted to max available
*!   W010 - Placebo lag exceeds pre-treatment periods

version 16.0

// ============================================================================
// MODULE VERIFICATION
// ============================================================================

// ----------------------------------------------------------------------------
// _diddesign_utils
// Display module information and list available utility programs.
// All utility functions are provided by independent ado files for better
// modularity and on-demand loading.
// ----------------------------------------------------------------------------
program define _diddesign_utils
    version 16.0
    
    display as text "{bf:DIDdesign Utility Functions Module}"
    display as text ""
    display as text "Available utility programs (provided by independent ado files):"
    display as text "  _diddesign_error          - Display standardized error message"
    display as text "  _diddesign_warning        - Display standardized warning message"
    display as text "  _diddesign_display_header - Display estimation header"
    display as text "  _diddesign_display_table_header - Display table column headers"
    display as text "  _diddesign_display_result - Display result row"
    display as text "  _diddesign_display_footer - Display estimation footer"
    display as text ""
    display as text "See file header for error codes (E001-E017) and warning codes (W001-W010)."
end
