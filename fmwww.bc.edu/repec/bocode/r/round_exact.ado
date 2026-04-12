
*! version 2.7.2  2026-04-10
*! Author: Anne Fengyan Shi
*! Revision: Automatically recasts float variables to double to preserve rounding precision.

program define round_exact, rclass
    version 14.0
    syntax anything(name=input) [if] [in], D(integer) [Generate(name) Replace]

    // ---------------------------------------------------------
    // Syntax Trap for Parentheses
    // ---------------------------------------------------------
    if substr(trim("`input'"), 1, 1) == "(" {
        display as error "Syntax Error: Do not use parentheses around the variable name."
        display as error "Correct usage: {bf:round_exact varname, d(2) replace}"
        exit 198
    }

    local multiplier = 10^`d'
    local eps = 1e-6

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
            // Force the new variable to be double immediately
            quietly gen double `generate' = ///
                sign(`input') * floor(abs(`input') * `multiplier' + 0.5 + `eps') / `multiplier' ///
                if `touse'
            display as text "Variable " as result "`generate'" as text " created (type double)."
        }
        
        else if "`replace'" != "" {
            // CRITICAL STEP: Recast the original variable to double.
            // If it's already double, nothing happens. If it's float, it's promoted.
            quietly recast double `input'
            
            tempvar newval
            quietly gen double `newval' = ///
                sign(`input') * floor(abs(`input') * `multiplier' + 0.5 + `eps') / `multiplier' ///
                if `touse'

            quietly count if `touse' & (`input' != `newval') ///
                & !missing(`input') & !missing(`newval')
            local n_changed = r(N)

            quietly replace `input' = `newval' if `touse'
            
            display as text "Variable " as result "`input'" as text " updated and promoted to double." ///
                " (" as result "`n_changed'" as text " real change(s) made)"
            return scalar N_changed = `n_changed'
        }
    }
    // ---------------------------------------------------------
    // CASE 2: Scalar/Literal Mode
    // ---------------------------------------------------------
    else {
        tempname res
        scalar `res' = sign(`input') * ///
            floor(abs(`input') * `multiplier' + 0.5 + `eps') / `multiplier'
        display as result `res'
        return scalar val = `res'
    }
end
