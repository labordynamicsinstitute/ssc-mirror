*! version 2.7.0  2026-04-08
*! Author: Anne Fengyan Shi
program define round_exact, rclass
    version 14.0
    syntax anything(name=input) [if] [in], D(integer) [Generate(name) Replace]
    // ---------------------------------------------------------
    // Syntax Trap for Parentheses
    // ---------------------------------------------------------
    if substr(trim("`input'"), 1, 1) == "(" {
        display as error "Syntax Error: Do not use parentheses around the variable name."
        display as error "Correct usage: {bf:round_exact1 varname, d(2) replace}"
        exit 198
    }
    local multiplier = 10^`d'

    // ---------------------------------------------------------
    // Epsilon rationale:
    //   3.05 is stored as 3.04999999999999982236...
    //   3.05 * 10 = 30.4999999999999982236...
    //   shortfall from 30.5 = ~1.8e-15 * 10 = ~1.8e-14
    //   but for float (single precision) values like gear_ratio,
    //   the shortfall can be as large as ~4.4e-7 * multiplier
    //   We use eps = 1e-6 / multiplier so after multiplying:
    //     abs(x)*multiplier + 0.5 + 1e-6
    //   which comfortably bridges the gap without affecting
    //   values genuinely below the rounding boundary
    //   (those would need to be within 1e-6 of .5, which does
    //   not occur for typical numeric data with d<=4)
    // ---------------------------------------------------------
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
            quietly gen double `generate' = `input' if `touse'
            quietly replace `generate' = ///
                sign(`input') * floor(abs(`input') * `multiplier' + 0.5 + `eps') / `multiplier' ///
                if `touse'
            display as text "Variable " as result "`generate'" as text " created."
        }
        else if "`replace'" != "" {
            quietly count if `touse'
            local n_changed = r(N)
            quietly replace `input' = ///
                sign(`input') * floor(abs(`input') * `multiplier' + 0.5 + `eps') / `multiplier' ///
                if `touse'
            display as text "Variable " as result "`input'" as text " updated." ///
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
