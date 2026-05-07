*! _xtpc_pme_display v1.1.0 — PME-specific display
*! Author: Dr. Merwan Roudane

program define _xtpc_pme_display
    di
    di as txt "{hline 78}"
    di as txt "{bf:xtpanelcoint -- `e(estimator)'}"
    di as txt "{hline 78}"
    di as txt "  Variables       : " as res "`e(depvar)'"
    di as txt "  N (panels)      : " as res %6.0f e(N_g)
    di as txt "  T (periods)     : " as res %6.0f e(T)
    di as txt "  m (variables)   : " as res %6.0f e(m_vars)
    di as txt "  q (sub-samples) : " as res %6.0f e(subsamples)
    di as txt "  delta           : " as res %6.4f e(delta)
    di as txt "{hline 78}"

    // Eigenvalue table
    if "`e(eigenvalues)'" != "" {
        tempname ev
        mat `ev' = e(eigenvalues)
        local m = rowsof(`ev')
        local r = e(r_hat)
        local thr = e(T)^(-e(delta))

        di
        di as txt "  {bf:Eigenvalue Analysis}"
        di as txt "  Threshold T^(-delta) = " as res %10.6f `thr'
        di
        di as txt "{ralign 6:j}{ralign 16:lambda_j}{ralign 20:Status}"
        di as txt "{hline 42}"
        forvalues j = 1/`m' {
            local status "Non-stationary"
            if `j' <= `r' local status "Long-run relation"
            di as txt %6.0f `j' ///
               as res %16.6f `ev'[`j', 1] ///
               as txt "  `status'"
        }
        di as txt "{hline 42}"
        di as txt "  {bf:Estimated r_0 = `r'}"
    }

    // Coefficient table
    if "`e(Theta)'" != "" & e(r_hat) > 0 {
        tempname Th Tse Tt Tp
        mat `Th'  = e(Theta)
        mat `Tse' = e(Theta_se)
        mat `Tt'  = e(Theta_t)
        mat `Tp'  = e(Theta_p)

        local nr = rowsof(`Th')
        local nc = colsof(`Th')

        di
        di as txt "  {bf:Long-Run Coefficients}"
        di
        di as txt "{ralign 20:Coefficient}" ///
           as txt "{ralign 12:theta}" ///
           as txt "{ralign 12:SE}" ///
           as txt "{ralign 10:t}" ///
           as txt "{ralign 10:P>|t|}"
        di as txt "{hline 64}"

        forvalues c = 1/`nc' {
            forvalues r = 1/`nr' {
                local sig ""
                if `Tp'[`r', `c'] < 0.01      local sig "***"
                else if `Tp'[`r', `c'] < 0.05 local sig "**"
                else if `Tp'[`r', `c'] < 0.10 local sig "*"
                di as txt %20s "theta(`r',`c')" ///
                   as res %12.4f `Th'[`r', `c'] ///
                   as res %12.4f `Tse'[`r', `c'] ///
                   as res %10.4f `Tt'[`r', `c'] ///
                   as res %10.4f `Tp'[`r', `c'] ///
                   as txt "  `sig'"
            }
        }
        di as txt "{hline 64}"
    }
    di as txt "{hline 78}"
end
