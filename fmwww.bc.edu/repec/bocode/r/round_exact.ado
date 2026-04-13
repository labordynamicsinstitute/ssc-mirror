*! version 3.0.0  2026-04-12
*! Author: Anne Fengyan Shi
*! Revision:
*!   - Adds fromstring mode (string variable or quoted literal)
*!   - Numeric mode: removes unconditional eps; uses conditional half-case handling
*!   - Fix: half-case tolerance now adapts to float vs double storage (prevents 3.05->3.0 in float vars)

program define round_exact, rclass
    version 14.0
    syntax anything(name=input) [if] [in], D(integer) ///
        [Generate(name) Replace FROMString]

    // ---------------------------------------------------------
    // Syntax Trap for Parentheses
    // ---------------------------------------------------------
    if substr(trim("`input'"), 1, 1) == "(" {
        di as error "Syntax Error: Do not use parentheses around the variable name."
        di as error "Correct usage: {bf:round_exact varname, d(2) replace}"
        exit 198
    }

    local multiplier = 10^`d'
    local tol = 1e-12   // retained for scalar-mode fallback / fromstring logic

    // ---------------------------------------------------------
    // CASE 1: Variable Mode
    // ---------------------------------------------------------
    capture confirm variable `input'
    if !_rc {
        marksample touse

        if "`generate'" == "" & "`replace'" == "" {
            di as error "You must specify either {bf:generate(newvar)} or {bf:replace}."
            exit 198
        }

        // =========================
        // fromstring mode (string var only)
        // =========================
        if "`fromstring'" != "" {
            capture confirm string variable `input'
            if _rc {
                di as error "Option {bf:fromstring} requires a string variable."
                di as error "If your input is numeric, omit {bf:fromstring}."
                exit 198
            }

            if "`replace'" != "" {
                di as error "{bf:fromstring} does not support {bf:replace} on a string variable."
                di as error "Use {bf:generate(newvar)} to create the rounded numeric variable."
                exit 198
            }

            confirm new variable `generate'
            quietly gen double `generate' = . if `touse'

            // temp vars for parsing
            tempvar s neg dot ip fp fp2 keep next rest istie roundup scaled out

            quietly gen strL `s' = trim(`input') if `touse'

            // missing/blank -> missing
            quietly replace `generate' = . if `touse' & (`s'=="" | `s'==".")

            // sign
            quietly gen byte `neg' = (substr(`s',1,1)=="-") if `touse'
            quietly replace `s' = substr(`s',2,.) if `touse' & `neg'
            quietly replace `s' = substr(`s',2,.) if `touse' & substr(`s',1,1)=="+"

            // split int/frac
            quietly gen int `dot' = strpos(`s', ".") if `touse'
            quietly gen strL `ip' = cond(`dot'>0, substr(`s',1,`dot'-1), `s') if `touse'
            quietly gen strL `fp' = cond(`dot'>0, substr(`s',`dot'+1,.), "") if `touse'

            quietly replace `ip' = "0" if `touse' & (`ip'=="")

            // pad fractional part to at least d+1 digits (for next digit)
            quietly replace `fp' = `fp' + strrepeat("0", `d'+1) if `touse'

            // first d+1 digits of fraction
            quietly gen strL `fp2' = substr(`fp',1,`d'+1) if `touse'

            // keep first d digits; next is digit d+1
            quietly gen strL `keep' = cond(`d'==0, "", substr(`fp2',1,`d')) if `touse'
            quietly gen strL `next' = substr(`fp2',`d'+1,1) if `touse'
            quietly gen strL `rest' = substr(`fp',`d'+2,.) if `touse'

            // tie: next=="5" and rest all zeros/empty
            quietly gen byte `istie' = (`next'=="5") & (`rest'=="" | regexm(`rest',"^0*$")) if `touse'

            // round up: next>5 OR tie-at-5
            quietly gen byte `roundup' = (`next'>"5") | `istie' if `touse'

            // scaled integer = ip*10^d + keep (keep may be "")
            quietly gen double `scaled' = real(`ip') * `multiplier' + cond(`d'==0, 0, real(`keep')) if `touse'

            // if ip not numeric -> missing
            quietly replace `scaled' = . if `touse' & missing(real(`ip'))

            quietly replace `scaled' = `scaled' + `roundup' if `touse' & !missing(`scaled')

            quietly gen double `out' = cond(`neg', -`scaled', `scaled') / `multiplier' if `touse'
            quietly replace `generate' = `out' if `touse'

            di as text "Variable " as result "`generate'" as text " created (type double)."
            exit
        }

        // =========================
        // numeric mode (FIXED)
        // =========================
        tempvar x z f tolz iround newval
        quietly gen double `x' = `input' if `touse'
        quietly gen double `z' = abs(`x') * `multiplier' if `touse'
        quietly gen double `f' = `z' - floor(`z') if `touse'

        // Storage-aware tolerance (float needs wider half-window than double)
        local vtype : type `input'
        local eps = cond("`vtype'"=="float", c(epsfloat), c(epsdouble))

        // scaled-space tolerance around the 0.5 boundary
        quietly gen double `tolz' = 4*`eps'*`z' + 1e-12 if `touse'

        // if near-half (within tolz), force round-up; otherwise use round(z)
        quietly gen double `iround' = cond(abs(`f' - 0.5) < `tolz', floor(`z') + 1, round(`z')) if `touse'
        quietly gen double `newval' = sign(`x') * (`iround' / `multiplier') if `touse'

        if "`generate'" != "" {
            confirm new variable `generate'
            quietly gen double `generate' = `newval' if `touse'
            di as text "Variable " as result "`generate'" as text " created (type double)."
        }
        else if "`replace'" != "" {
            quietly recast double `input'
            quietly count if `touse' & (`input' != `newval') & !missing(`input') & !missing(`newval')
            local n_changed = r(N)
            quietly replace `input' = `newval' if `touse'
            di as text "Variable " as result "`input'" as text " updated and promoted to double." ///
                " (" as result "`n_changed'" as text " real change(s) made)"
            return scalar N_changed = `n_changed'
        }

        exit
    }

    // ---------------------------------------------------------
    // CASE 2: Scalar/Literal Mode
    // ---------------------------------------------------------
    else {

        // fromstring scalar: treat input as literal text token
        if "`fromstring'" != "" {
            local s = trim("`input'")
            if ("`s'"=="" | "`s'"==".") {
                di as result .
                return scalar val = .
                exit
            }

            local neg = 0
            if substr("`s'",1,1)=="-" {
                local neg = 1
                local s = substr("`s'",2,.)
            }
            else if substr("`s'",1,1)=="+" {
                local s = substr("`s'",2,.)
            }

            local dot = strpos("`s'", ".")
            local ip = "`s'"
            local fp = ""
            if `dot' > 0 {
                local ip = substr("`s'", 1, `dot'-1)
                local fp = substr("`s'", `dot'+1, .)
            }
            if "`ip'"=="" local ip = "0"

            // pad fp
            local fp = "`fp'" + strrepeat("0", `d'+1)
            local fp2 = substr("`fp'", 1, `d'+1)

            local keep = ""
            if `d' > 0 local keep = substr("`fp2'", 1, `d')
            local next = substr("`fp2'", `d'+1, 1)
            local rest = substr("`fp'", `d'+2, .)

            local istie = (`"`next'"'=="5" & (`"`rest'"'=="" | regexm(`"`rest'"', "^0*$")))
            local roundup = (`"`next'"'>"5") | `istie'

            scalar __scaled = real("`ip'")*`multiplier' + cond(`d'==0,0,real("`keep'"))
            if missing(__scaled) {
                di as result .
                return scalar val = .
                exit
            }
            scalar __scaled = __scaled + `roundup'
            scalar __res = (__scaled/`multiplier') * ( `neg' ? -1 : 1 )

            di as result __res
            return scalar val = __res
            exit
        }

        // numeric scalar (keep conditional half logic; use double eps)
        tempname z f tolz iround res
        scalar `z' = abs(`input') * `multiplier'
        scalar `f' = `z' - floor(`z')
        scalar `tolz' = 4*c(epsdouble)*`z' + 1e-12
        scalar `iround' = cond(abs(`f' - 0.5) < `tolz', floor(`z') + 1, round(`z'))
        scalar `res' = sign(`input') * (`iround' / `multiplier')
        di as result `res'
        return scalar val = `res'
        exit
    }
end
