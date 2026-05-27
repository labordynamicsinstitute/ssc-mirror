*! asycaus v1.0.1  24may2026
*! Asymmetric Causality Suite — main dispatcher
*! Implements: Hatemi-J (2012, 2021, 2024), Hacker & Hatemi-J (2006, 2012),
*!             Nazlioglu, Gormus & Soytas (2016), Bahmani-Oskooee, Chang & Ranjbar (2016),
*!             Fang, Wang, Shieh & Chung (2026), Pata (2020)
*! Author:  Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Syntax: asycaus subcmd depvar causvar [if] [in] [, options]
*!   subcmd : static | dynamic | fourier | spectral | quantile | efficient | all

program define asycaus, rclass
    version 14.0
    gettoken sub 0 : 0
    if "`sub'" == "" {
        di as err "no subcommand specified"
        di as txt "Use one of: {bf:static} {bf:dynamic} {bf:fourier} {bf:spectral} {bf:quantile} {bf:efficient} {bf:all}"
        exit 198
    }
    local valid static dynamic fourier spectral quantile efficient all components
    if !`: list sub in valid' {
        di as err "unknown subcommand `sub'"
        di as txt "Use one of: `valid'"
        exit 198
    }

    // Load Mata engine (always re-run; ensures any new helper functions are available)
    qui findfile asycaus_engine.mata
    qui run "`r(fn)'"

    asycaus_`sub' `0'
    // Propagate r() of the subcommand to our caller.
    return add
end


// ============================================================
//  COMPONENTS — utility: generate cumulative pos/neg components
// ============================================================
program define asycaus_components, rclass
    syntax varlist(min=1 numeric) [if] [in] , ///
        [ POS(name) NEG(name) replace ]

    marksample touse
    qui count if `touse'
    if r(N) < 3 {
        di as err "too few observations"
        exit 2001
    }

    if "`pos'" == "" local pos pos_
    if "`neg'" == "" local neg neg_

    foreach v of varlist `varlist' {
        local pname `pos'`v'
        local nname `neg'`v'
        if "`replace'" != "" {
            capture drop `pname'
            capture drop `nname'
        }
        tempvar dx
        qui gen double `dx' = D.`v' if `touse'
        tempvar p_ n_
        qui gen double `p_' = cond(`dx' > 0, `dx', 0) if `touse'
        qui gen double `n_' = cond(`dx' < 0, `dx', 0) if `touse'
        qui replace `p_' = 0 if `p_' >= .
        qui replace `n_' = 0 if `n_' >= .
        qui gen double `pname' = sum(`p_') if `touse'
        qui gen double `nname' = sum(`n_') if `touse'
        label var `pname' "Cumulative positive shocks of `v'"
        label var `nname' "Cumulative negative shocks of `v'"
    }
    di as txt "Generated cumulative positive and negative components for: " as res "`varlist'"
end
