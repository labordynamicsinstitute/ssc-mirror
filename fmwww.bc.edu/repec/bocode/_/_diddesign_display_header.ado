*! _diddesign_display_header.ado - Display estimation header for Double DID
*!
*! Internal module for the DIDdesign output display system. Renders header
*! information before the results table, including design type (Standard DID
*! or Staggered Adoption), data structure, sample characteristics, and
*! inference settings.

version 16.0

// ============================================================================
// _diddesign_display_header
// Display header section of estimation output
//
// Outputs contextual information about the Double DID estimation, including
// design specification, data structure, sample size, and bootstrap settings.
//
// Arguments:
//   cmd       : string  - Command name
//   design    : string  - Design type ("std" for Standard DID, "sa" for
//                         Staggered Adoption)
//   datatype  : string  - Data structure ("Panel" or "Repeated Cross-Section")
//   n         : integer - Total number of observations
//   n_units   : integer - Number of unique units (panel data only; default: 0)
//   n_periods : integer - Number of time periods (default: 0)
//   n_boot    : integer - Number of bootstrap replications (default: 30)
//   cluster   : string  - Clustering variable name (optional)
//   thres     : integer - Minimum observations per cohort-period cell
//                         (Staggered Adoption only; default: 2)
//
// Returns:
//   None (output displayed to console)
// ============================================================================
program define _diddesign_display_header
    version 16.0
    
    syntax , CMD(string) DESIGN(string) DATATYPE(string) ///
             N(integer) [N_units(integer 0) N_periods(integer 0) ///
             N_boot(integer 30) CLuster(string) THRes(integer 2)]
    
    // -------------------------------------------------------------------------
    // Design Type and Data Structure
    // -------------------------------------------------------------------------
    
    if "`design'" == "std" {
        display as text _n "Double Difference-in-Differences Estimation"
        display as text _dup(44) "="
        display as text "Design:           Standard DID"
    }
    else if "`design'" == "sa" {
        display as text _n "Staggered Adoption Double Difference-in-Differences Estimation"
        display as text _dup(62) "="
        display as text "Design:           Staggered Adoption"
    }
    else {
        display as text _n "DIDdesign Estimation"
        display as text _dup(20) "="
        display as text "Design:           `design'"
    }
    
    display as text "Data type:        `datatype'"
    
    // -------------------------------------------------------------------------
    // Sample Information
    // -------------------------------------------------------------------------
    
    display as text "Observations:     " as result %12.0fc `n'
    
    // Panel data only: display number of unique units
    if `n_units' > 0 {
        display as text "Units:            " as result %12.0fc `n_units'
    }
    
    if `n_periods' > 0 {
        display as text "Time periods:     " as result %12.0fc `n_periods'
    }
    
    // SA-specific valid-period support is displayed by the caller once the
    // estimable period count is available.
    
    // -------------------------------------------------------------------------
    // Inference Settings
    // -------------------------------------------------------------------------
    
    display as text ""
    
    display as text "Bootstrap:        `n_boot' replications"
    
    // Cluster-robust standard errors
    if "`cluster'" != "" {
        display as text "Clustering:       `cluster'"
    }
end
