
*! version 2.3.0  2026-04-03
*! Author: Anne Fengyan Shi
program define round_exact, rclass
    version 14.0
    syntax anything(name=input) [if] [in], D(integer) [Generate(name) Replace]

    // ---------------------------------------------------------
    // NEW: Syntax Trap for Parentheses
    // ---------------------------------------------------------
    if substr(trim("`input'"), 1, 1) == "(" {
        display as error "Syntax Error: Do not use parentheses around the variable name."
        display as error "Correct usage: {bf:round_exact varname, d(2) replace}"
        exit 198
    }

    local multiplier = 10^`d'

    // ---------------------------------------------------------
    // CASE 1: Variable Mode
    // ---------------------------------------------------------
    capture confirm variable `input'
    if !_rc {
        marksample touse
        
        if "`generate'" == "" & "`replace'" == "" {
            display as error "You must specify either {bf:generate(newvar)} or {bf:replace}."
            exit 198
        }

        if "`generate'" != "" {
            confirm new variable `generate'
            quietly gen double `generate' = `input' if `touse'
            quietly replace `generate' = round(`input' * `multiplier') / `multiplier' ///
                if abs(`input' - round(`input', 1)) > 1e-15 & `touse'
            display as text "Variable " as result "`generate'" as text " created."
        }
        else if "`replace'" != "" {
            quietly replace `input' = round(`input' * `multiplier') / `multiplier' ///
                if abs(`input' - round(`input', 1)) > 1e-15 & `touse'
            display as text "Variable " as result "`input'" as text " updated."
        }
    }
    
    // ---------------------------------------------------------
    // CASE 2: Scalar/Literal Mode
    // ---------------------------------------------------------
    else {
        tempname res
        scalar `res' = round((`input') * `multiplier') / `multiplier'
        display as result `res'
        return scalar val = `res'
    }
end
