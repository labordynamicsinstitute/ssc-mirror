*! _diddesign_warning.ado - Warning message display utility
*!
*! Displays formatted warning messages during estimation. Warnings indicate
*! non-fatal conditions that do not prevent computation but may affect results.
*! Warning codes range from W001 to W010.

version 16.0

// ============================================================================
// _diddesign_warning
// Display a formatted warning message; program execution continues.
//
// Arguments:
//   warning_code : integer - DIDdesign warning code (1-10)
//   message      : string  - Descriptive warning message to display
//
// Returns:
//   None (message displayed to console)
// ============================================================================
program define _diddesign_warning
    version 16.0
    
    args warning_code message
    
    // -------------------------------------------------------------------------
    // Warning Code Validation
    // -------------------------------------------------------------------------
    
    if `warning_code' < 1 | `warning_code' > 10 {
        display as text "{bf:Warning:} Invalid warning code `warning_code'"
        display as text "         `message'"
        exit
    }
    
    // -------------------------------------------------------------------------
    // Message Formatting and Display
    // -------------------------------------------------------------------------
    
    // Warning code is formatted with leading zeros (W001, W002, etc.)
    local code_str = string(`warning_code', "%03.0f")
    
    display as text "{bf:Warning W`code_str':} `message'"
end
