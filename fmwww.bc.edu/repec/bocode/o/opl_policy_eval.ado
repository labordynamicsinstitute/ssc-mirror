*! version 0.1.0 15jul2026
program define opl_policy_eval, rclass
    version 18.0

    syntax varname(numeric)

    /*
    ------------------------------------------------------------
    Minimal post-estimation policy evaluator.

    Usage:

        opl_tb_cba tau, cost(cost) ...
        policy_eval D

    where D is a binary policy variable:
        D = 1 treated
        D = 0 untreated
    ------------------------------------------------------------
    */

    /*
    1. Check previous estimation command
    */

    if "`e(cmd)'" != "opl_tb_cba" {
        di as error ///
            "policy_eval must be run after opl_tb_cba"
        exit 301
    }

    /*
    2. Recover estimation information
    */

    local tau    "`e(tauvar)'"
    local cost   "`e(costvar)'"
    local lambda = e(lambda)

    if "`tau'" == "" {
        di as error ///
            "e(tauvar) not found after opl_tb_cba"
        exit 498
    }

    if "`cost'" == "" {
        di as error ///
            "e(costvar) not found after opl_tb_cba"
        exit 498
    }

    if missing(`lambda') {
        di as error ///
            "e(lambda) not found after opl_tb_cba"
        exit 498
    }

    /*
    3. Verify variables
    */

    confirm numeric variable `varlist'
    confirm numeric variable `tau'
    confirm numeric variable `cost'

    /*
    4. Define evaluation sample
    */

    tempvar touse
    quietly gen byte `touse' = e(sample)

    quietly replace `touse' = 0 if missing(`varlist')
    quietly replace `touse' = 0 if missing(`tau')
    quietly replace `touse' = 0 if missing(`cost')

    quietly count if `touse'
    local N = r(N)

    if `N' == 0 {
        di as error ///
            "no observations available for policy evaluation"
        exit 2000
    }

    /*
    5. Check that policy is binary
    */

    quietly count if `touse' & ///
        !inlist(`varlist', 0, 1)

    if r(N) > 0 {
        di as error ///
            "policy variable `varlist' must contain only 0 and 1"
        exit 459
    }

    /*
    6. Compute basic policy statistics
    */

    quietly count if `touse' & `varlist' == 1
    local Nt = r(N)

    local Nu       = `N' - `Nt'
    local coverage = `Nt' / `N'

    local TB      = 0
    local TC      = 0
    local Q       = 0
    local ATET    = .
    local avgcost = .
    local avgsurp = .

    if `Nt' > 0 {

        quietly summarize `tau' if ///
            `touse' & `varlist' == 1, meanonly

        local TB   = r(sum)
        local ATET = r(mean)

        quietly summarize `cost' if ///
            `touse' & `varlist' == 1, meanonly

        local TC      = r(sum)
        local avgcost = r(mean)

        local Q       = `TB' - `lambda' * `TC'
        local avgsurp = `Q' / `Nt'
    }

    /*
    7. Return results
    */

    return scalar N           = `N'
    return scalar N_treated   = `Nt'
    return scalar N_untreated = `Nu'
    return scalar coverage    = `coverage'
    return scalar total_benefit = `TB'
    return scalar total_cost    = `TC'
    return scalar Q             = `Q'
    return scalar ATET          = `ATET'
    return scalar avg_cost      = `avgcost'
    return scalar avg_surplus   = `avgsurp'

    return local policy "`varlist'"
    return local tauvar "`tau'"
    return local costvar "`cost'"

    /*
    8. Display results
    */

    di as text _newline ///
        "Policy evaluation"

    di as text "{hline 60}"

    di as text ///
        "Policy variable:       " ///
        as result "`varlist'"

    di as text ///
        "Treatment effect:      " ///
        as result "`tau'"

    di as text ///
        "Treatment cost:        " ///
        as result "`cost'"

    di as text ///
        "Lambda:                " ///
        as result %12.4f `lambda'

    di as text "{hline 60}"

    di as text ///
        "Evaluation sample:     " ///
        as result %12.0f `N'

    di as text ///
        "Treated:               " ///
        as result %12.0f `Nt'

    di as text ///
        "Untreated:             " ///
        as result %12.0f `Nu'

    di as text ///
        "Coverage:              " ///
        as result %12.4f `coverage'

    di as text ///
        "Total benefit:         " ///
        as result %12.4f `TB'

    di as text ///
        "Total cost:            " ///
        as result %12.4f `TC'

    di as text ///
        "Total welfare Q:       " ///
        as result %12.4f `Q'

    di as text ///
        "ATET:                  " ///
        as result %12.4f `ATET'

    di as text ///
        "Average cost:          " ///
        as result %12.4f `avgcost'

    di as text ///
        "Average surplus:       " ///
        as result %12.4f `avgsurp'

    di as text "{hline 60}"
end
