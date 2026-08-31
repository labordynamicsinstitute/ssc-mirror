*! version 4.0.6 29aug2026
*! Anne Fengyan Shi (AShi@pewresearch.org)
*
* Changes from v4.0.0 to v4.0.6:
* 1. Scalar String Parsing: Intercept `macro 0` before `syntax` parsing to preserve 
*    literal string representations and avoid binary float noise prior to execution.
* 2. Performance: Replaced `regexm()` with pure character length checks (`strlen`/`strtrim`) 
*    for faster variable-mode execution on large datasets.
* 3. Missing Values: Fixed issue where missing string inputs ("." or "") were treated as 
*    valid numeric zero strings; explicitly flags missing values upfront.
* 4. Memory Optimization: Replaced temporary `strL` allocations with `str2045` to 
*    reduce dataset metadata overhead while preserving high character length.
* 5. Syntax Resilience: Added fallback handling for numeric inputs passed with 
*    `fromstring` in scalar mode to prevent unexpected program termination.

program define round_exact, rclass
    version 14.0

    // Capture raw input macro zero before syntax parses or evaluates numeric tokens
    local raw_0 `"`0'"'

    // Check if scalar fromstring mode is invoked
    local is_fromstring = (strpos(lower(`"`raw_0'"'), "fromstring") > 0)

    // If scalar fromstring mode (input is not a variable name), parse raw text directly
    if `is_fromstring' {
        local comma_pos = strpos(`"`raw_0'"', ",")
        local arg_part = cond(`comma_pos' > 0, substr(`"`raw_0'"', 1, `comma_pos'-1), `"`raw_0'"')
        local arg_part = strtrim(`"`arg_part'"')

        // If arg_part is NOT a single existing variable, process as exact string scalar
        capture confirm variable `arg_part'
        if _rc {
            // Strip outer quotes if present
            if substr(`"`arg_part'"', 1, 1) == `"""' & substr(`"`arg_part'"', -1, 1) == `"""' {
                local arg_part = substr(`"`arg_part'"', 2, length(`"`arg_part'"') - 2)
            }
            local arg_part = strtrim(`"`arg_part'"')

            // Extract d(#) option manually from raw_0 without regex
            local d_pos = strpos(lower(`"`raw_0'"'), "d(")
            if `d_pos' > 0 {
                local d_sub = substr(`"`raw_0'"', `d_pos'+2, .)
                local d_end = strpos(`"`d_sub'"', ")")
                local d = substr(`"`d_sub'"', 1, `d_end'-1)
            }
            else {
                di as error "Option {bf:d()} required."
                exit 198
            }

            local multiplier = 10^`d'

            if (`"`arg_part'"'=="" | `"`arg_part'"'==".") {
                di as result .
                return scalar val = .
                exit
            }

            local s `"`arg_part'"'
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

            local pad_len = `d' + 1
            local pad_zeros : display _dup(`pad_len') "0"
            local fp = `"`fp'`pad_zeros'"'
            local fp2 = substr(`"`fp'"', 1, `d'+1)

            local keep = ""
            if `d' > 0 local keep = substr(`"`fp2'"', 1, `d')
            local next = substr(`"`fp2'"', `d'+1, 1)
            local rest = substr(`"`fp'"', `d'+2, .)

            // Exact tie check using real() zero check
            local rest_is_zero = (real(`"`rest'"') == 0 | `"`rest'"' == "")
            local istie = (`"`next'"' == "5" & `rest_is_zero')
            local roundup = (`"`next'"' > "5") | `istie'

            scalar __scaled = real(`"`ip'"')*`multiplier' + ///
                cond(`d'==0,0,real(`"`keep'"'))
            if missing(__scaled) {
                di as result .
                return scalar val = .
                exit
            }
            scalar __scaled = __scaled + `roundup'
            scalar __res = (__scaled/`multiplier') * cond(`neg', -1, 1)

            di as result __res
            return scalar val = __res
            exit
        }
    }

    // Standard Syntax Parsing (Variables and standard numeric scalars)
    syntax [anything(name=input)] [if] [in], d(integer) ///
        [Generate(name) Replace FROMString]

    local multiplier = 10^`d'
    local pad_len = `d' + 1
    local pad_zeros : display _dup(`pad_len') "0"

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

            tempvar s neg dot ip fp fp2 keep next rest istie roundup scaled out is_miss

            quietly gen str2045 `s' = strtrim(`input') if `touse'

            // Flag missing or unparseable non-numeric values upfront
            quietly gen byte `is_miss' = missing(real(`s')) & (`s' != "0") if `touse'

            quietly gen byte `neg' = (substr(`s',1,1)=="-") if `touse'
            quietly replace `s' = substr(`s',2,.) if `touse' & `neg'
            quietly replace `s' = substr(`s',2,.) if `touse' & substr(`s',1,1)=="+"

            quietly gen int `dot' = strpos(`s', ".") if `touse'
            quietly gen str2045 `ip' = cond(`dot'>0, substr(`s',1,`dot'-1), `s') if `touse'
            quietly gen str2045 `fp' = cond(`dot'>0, substr(`s',`dot'+1,.), "") if `touse'

            quietly replace `ip' = "0" if `touse' & (`ip'=="")

            quietly replace `fp' = `fp' + "`pad_zeros'" if `touse'

            quietly gen str2045 `fp2' = substr(`fp',1,`d'+1) if `touse'
            quietly gen str2045 `keep' = cond(`d'==0, "", substr(`fp2',1,`d')) if `touse'
            quietly gen str2045 `next' = substr(`fp2',`d'+1,1) if `touse'
            quietly gen str2045 `rest' = substr(`fp',`d'+2,.) if `touse'

            quietly gen byte `istie' = (`next'=="5") & ///
                (real(`rest')==0 | `rest'=="") if `touse'

            quietly gen byte `roundup' = (`next'>"5") | `istie' if `touse'

            quietly gen double `scaled' = real(`ip') * `multiplier' + ///
                cond(`d'==0, 0, real(`keep')) if `touse'

            quietly replace `scaled' = `scaled' + `roundup' if `touse' & !missing(`scaled')

            quietly gen double `out' = cond(`neg', -`scaled', `scaled') / `multiplier' if `touse'
            
            // Assign result, enforcing missing for invalid/blank string entries
            quietly replace `out' = . if `touse' & `is_miss'
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

        // Numeric variable mode
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
    // CASE 2: Numeric Scalar Mode
    // ---------------------------------------------------------
    else {
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