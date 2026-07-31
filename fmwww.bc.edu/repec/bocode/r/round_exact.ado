*! version 4.0.0  2026-07-30
*! Author: Anne Fengyan Shi
*! Revision:
*!    - Added support for `replace` option with `fromstring` on string variables
*!    - Fixed function call error by using native Stata string padding
*!    - Fixed literal mode handling for quoted string input and scalar evaluation syntax

program define round_exact, rclass
    version 14.0
    syntax anything(name=input) [if] [in], D(integer) ///
        [Generate(name) Replace FROMString]

    // ---------------------------------------------------------
    // Syntax Trap for Parentheses
    // ---------------------------------------------------------
    if substr(trim("`input'"), 1, 1) == "(" {
        di as error "Syntax Error: Do not use parentheses around varname."
        di as error "Correct usage: {bf:round_exact varname, d(2) replace}"
        exit 198
    }

    local multiplier = 10^`d'
    local tol = 1e-12

    // Helper padding string (supports up to 50 decimal places)
    local max_zeros = "00000000000000000000000000000000000000000000000000"

    // ---------------------------------------------------------
    // CASE 1: Variable Mode
    // ---------------------------------------------------------
    capture confirm variable `input'
    if !_rc {
        marksample touse

        if "`generate'" == "" & "`replace'" == "" {
            di as error "You must specify {bf:generate(newvar)} or {bf:replace}."
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

            tempvar target_var
            local is_replace = ("`replace'" != "")

            if `is_replace' {
                local target "`target_var'"
            }
            else {
                confirm new variable `generate'
                local target "`generate'"
            }

            quietly gen double `target' = . if `touse'

            tempvar s neg dot ip fp fp2 keep next rest istie roundup scaled out

            quietly gen strL `s' = trim(`input') if `touse'

            quietly gen byte `neg' = (substr(`s',1,1)=="-") if `touse'
            quietly replace `s' = substr(`s',2,.) if `touse' & `neg'
            quietly replace `s' = substr(`s',2,.) if `touse' & substr(`s',1,1)=="+"

            quietly gen int `dot' = strpos(`s', ".") if `touse'
            quietly gen strL `ip' = cond(`dot'>0, substr(`s',1,`dot'-1), `s') if `touse'
            quietly gen strL `fp' = cond(`dot'>0, substr(`s',`dot'+1,.), "") if `touse'

            quietly replace `ip' = "0" if `touse' & (`ip'=="")

            local pad_len = `d' + 1
            local pad_zeros = substr("`max_zeros'", 1, `pad_len')
            quietly replace `fp' = `fp' + "`pad_zeros'" if `touse'

            quietly gen strL `fp2' = substr(`fp',1,`d'+1) if `touse'
            quietly gen strL `keep' = cond(`d'==0, "", substr(`fp2',1,`d')) if `touse'
            quietly gen strL `next' = substr(`fp2',`d'+1,1) if `touse'
            quietly gen strL `rest' = substr(`fp',`d'+2,.) if `touse'

            quietly gen byte `istie' = (`next'=="5") & ///
                (`rest'=="" | regexm(`rest',"^0*$")) if `touse'

            quietly gen byte `roundup' = (`next'>"5") | `istie' if `touse'

            quietly gen double `scaled' = real(`ip') * `multiplier' + ///
                cond(`d'==0, 0, real(`keep')) if `touse'

            quietly replace `scaled' = . if `touse' & missing(real(`ip'))
            quietly replace `scaled' = `scaled' + `roundup' if `touse' & !missing(`scaled')

            quietly gen double `out' = cond(`neg', -`scaled', `scaled') / `multiplier' if `touse'
            quietly replace `target' = `out' if `touse'

            quietly count if `touse' & !missing(`target')
            local n_gen = r(N)

            if `is_replace' {
                quietly drop `input'
                rename `target' `input'
                di as text "Variable " as result "`input'" as text ///
                   " converted from string to double." ///
                   " (" as result "`n_gen'" as text " non-missing observation(s) updated)"
                return scalar N_changed = `n_gen'
            }
            else {
                di as text "Variable " as result "`generate'" as text ///
                   " created (type double)." ///
                   " (" as result "`n_gen'" as text " non-missing observation(s) generated)"
                return scalar N_generated = `n_gen'
            }

            exit
        }

        // =========================
        // numeric mode
        // =========================
        tempvar x z f tolz iround newval
        quietly gen double `x' = `input' if `touse'
        quietly gen double `z' = abs(`x') * `multiplier' if `touse'
        quietly gen double `f' = `z' - floor(`z') if `touse'

        local vtype : type `input'
        local eps = cond("`vtype'"=="float", c(epsfloat), c(epsdouble))

        quietly gen double `tolz' = 4*`eps'*`z' + 1e-12 if `touse'

        quietly gen double `iround' = cond(abs(`f' - 0.5) < `tolz', ///
            floor(`z') + 1, round(`z')) if `touse'
        quietly gen double `newval' = sign(`x') * (`iround' / `multiplier') ///
            if `touse'

        if "`generate'" != "" {
            confirm new variable `generate'
            quietly gen double `generate' = `newval' if `touse'
            
            quietly count if `touse' & !missing(`generate')
            local n_gen = r(N)
            
            di as text "Variable " as result "`generate'" as text ///
               " created (type double)." ///
               " (" as result "`n_gen'" ///
               as text " non-missing observation(s) generated)"
            
            return scalar N_generated = `n_gen'
        }
        else if "`replace'" != "" {
            quietly recast double `input'
            quietly count if `touse' & (`input' != `newval') & ///
                !missing(`input') & !missing(`newval')
            local n_changed = r(N)
            quietly replace `input' = `newval' if `touse'
            di as text "Variable " as result "`input'" as text ///
                " updated and promoted to double." ///
                " (" as result "`n_changed'" as text " real change(s) made)"
            return scalar N_changed = `n_changed'
        }

        exit
    }

    // ---------------------------------------------------------
    // CASE 2: Scalar/Literal Mode
    // ---------------------------------------------------------
    else {
        if "`fromstring'" != "" {
            // Clean out external double quotes if present
            local s = trim(`"`input'"')
            local s = subinstr(`"`s'"', `"""', "", .)

            if (`"`s'"'=="" | `"`s'"'==".") {
                di as result .
                return scalar val = .
                exit
            }

            local neg = 0
            if substr(`"`s'"',1,1)=="-" {
                local neg = 1
                local s = substr(`"`s'"',2,.)
            }
            else if substr(`"`s'"',1,1)=="+" {
                local s = substr(`"`s'"',2,.)
            }

            local dot = strpos(`"`s'"', ".")
            local ip = `"`s'"'
            local fp = ""
            if `dot' > 0 {
                local ip = substr(`"`s'"', 1, `dot'-1)
                local fp = substr(`"`s'"', `dot'+1, .)
            }
            if `"`ip'"'=="" local ip = "0"

            local pad_zeros = substr("`max_zeros'", 1, `d'+1)
            local fp = `"`fp'`pad_zeros'"'
            local fp2 = substr(`"`fp'"', 1, `d'+1)

            local keep = ""
            if `d' > 0 local keep = substr(`"`fp2'"', 1, `d')
            local next = substr(`"`fp2'"', `d'+1, 1)
            local rest = substr(`"`fp'"', `d'+2, .)

            local istie = (`"`next'"'=="5" & ///
                (`"`rest'"'=="" | regexm(`"`rest'"', "^0*$")))
            local roundup = (`"`next'"'>"5") | `istie'

            scalar __scaled = real(`"`ip'"')*`multiplier' + ///
                cond(`d'==0,0,real(`"`keep'"'))
            if missing(__scaled) {
                di as result .
                return scalar val = .
                exit
            }
            scalar __scaled = __scaled + `roundup'
            
            // Evaluates clean scalar output using native cond()
            scalar __res = (__scaled/`multiplier') * cond(`neg', -1, 1)

            di as result __res
            return scalar val = __res
            exit
        }

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
