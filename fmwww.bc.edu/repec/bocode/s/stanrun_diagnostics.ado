*! stanrun_diagnostics v2.1.0 09mar2026
*! Convergence diagnostics for stanrun
*! Ben A. Dwamena, University of Michigan

capture program drop stanrun_diagnostics
program define stanrun_diagnostics, rclass
    version 15.0
    syntax [, DRAWFile(string) PARAMeters(string) ESSmin(real 100) TRACE(string)]

    // ---------------------------------------------------------
    // 1. Call stanrun_extract to get table with Rhat and ESS
    // ---------------------------------------------------------
    quietly stanrun_extract ///
        , drawfile(`"`drawfile'"') ///
          parameters(`"`parameters'"') ///
          trace(`"`trace'"')

    tempname T
    matrix `T' = r(table)
    local params = r(parameters)
    local nch    = r(nchains)
    local drawf  = r(drawfile)

    local K = rowsof(`T')

    // Column mapping:
    // 1 mean, 2 sd, 3 p2_5, 4 p50, 5 p97_5, 6 Rhat, 7 ESS, 8 N
    local col_Rhat = 6
    local col_ESS  = 7
    local col_N    = 8

    // ---------------------------------------------------------
    // 2. Inspect rows and flag problematic parameters
    // ---------------------------------------------------------
    local bad_rhat ""
    local bad_ess  ""
    local bad_all  ""

    forvalues i = 1/`K' {
        local pname : word `i' of `params'

        scalar rhat_i = `T'[`i', `col_Rhat']
        scalar ess_i  = `T'[`i', `col_ESS']
        scalar N_i    = `T'[`i', `col_N']

        local flag_rhat 0
        local flag_ess  0

        // R-hat flag
        if !missing(rhat_i) & rhat_i > 1.01 {
            local flag_rhat = 1
            local bad_rhat `bad_rhat' `pname'
        }

        // ESS flag (only if ESS and N are non-missing)
        if !missing(ess_i) & !missing(N_i) {
            if ess_i < `essmin' {
                local flag_ess = 1
                local bad_ess `bad_ess' `pname'
            }
        }

        if (`flag_rhat' | `flag_ess') {
            local bad_all `bad_all' `pname'
        }
    }

    // ---------------------------------------------------------
    // 3. Report summary
    // ---------------------------------------------------------
    di as text "{hline}"
    di as text "stanrun_diagnostics for: `drawf'"
    di as text "Chains detected: `nch'"
    di as text "ESS threshold: `essmin'"
    di as text "{hline}"

    if "`bad_all'" == "" {
        di as result "No parameters flagged with Rhat > 1.01 or ESS < `essmin'."
    }
    else {
        di as text "Parameters flagged:"
        if "`bad_rhat'" != "" {
            di as text "  Rhat > 1.01 : " ///
                as result "`bad_rhat'"
        }
        if "`bad_ess'" != "" {
            di as text "  ESS < `essmin' : " ///
                as result "`bad_ess'"
        }
    }

    // ---------------------------------------------------------
    // 4. Return flags in r()
    // ---------------------------------------------------------
    return local bad_rhat "`bad_rhat'"
    return local bad_ess  "`bad_ess'"
    return local bad_all  "`bad_all'"
    return scalar essmin  = `essmin'
    return scalar nchains = `nch'
    return local drawfile "`drawf'"
end
