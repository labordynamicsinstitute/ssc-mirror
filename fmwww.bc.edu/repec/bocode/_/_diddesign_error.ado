*! _diddesign_error.ado - Standardized error handling for DIDdesign package
*!
*! Centralized error handling module for the DIDdesign package. Error messages
*! are formatted with standardized codes (E001-E017) and mapped to appropriate
*! Stata exit codes for proper error propagation through the call stack.
*!
*! Stata Exit Code Mapping:
*!   198 - Invalid syntax   (E001, E002, E012, E013, E014, E016, E017)
*!   459 - Data error       (E003, E007, E008)
*!   498 - Computation error (E004, E005, E006, E009, E010, E011)
*!   499 - Mata not loaded  (E015)

version 16.0

// ============================================================================
// _diddesign_error
// Display a formatted error message and terminate with the appropriate exit code.
//
// Arguments:
//   error_code : integer - Package-specific error code (1-17)
//   message    : string  - Descriptive error message
//
// Behavior:
//   The program displays the error message prefixed with a formatted code
//   (E001-E017) and terminates with the corresponding Stata exit code.
// ============================================================================
program define _diddesign_error
    version 16.0
    
    args error_code message
    
    // -------------------------------------------------------------------------
    // Error Code Validation
    // -------------------------------------------------------------------------
    
    if `error_code' < 1 | `error_code' > 17 {
        display as error "Internal error: Invalid error code `error_code'"
        exit 498
    }
    
    // -------------------------------------------------------------------------
    // Message Formatting and Display
    // -------------------------------------------------------------------------
    
    // Format error code with leading zeros (E001, E002, etc.)
    local code_str = string(`error_code', "%03.0f")
    
    display as error "E`code_str': `message'"
    
    // -------------------------------------------------------------------------
    // Exit Code Mapping
    // -------------------------------------------------------------------------
    
    if inlist(`error_code', 1, 2, 12, 13, 14, 16, 17) {
        exit 198  // Invalid syntax
    }
    else if inlist(`error_code', 3, 7, 8) {
        exit 459  // Data error
    }
    else if `error_code' == 15 {
        exit 499  // Mata not loaded
    }
    else {
        exit 498  // Computation error
    }
end
