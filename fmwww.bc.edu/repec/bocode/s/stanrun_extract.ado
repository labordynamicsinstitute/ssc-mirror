*! stanrun_extract v2.1.0 09mar2026
*! Posterior summary extraction for stanrun
*! Ben A. Dwamena, University of Michigan

capture program drop stanrun_extract
program define stanrun_extract, rclass
    version 15.0
    syntax [, DRAWFile(string) PARAMeters(string) TRACE(string)]

    // -------------------------------------------------------------
    // 1. Resolve draws file
    // -------------------------------------------------------------
    if "`drawfile'" == "" {
        local drawfile "`r(drawsfile)'"
        if "`drawfile'" == "" {
            di as error "stanrun_extract: no drawfile() specified and r(drawsfile) not found."
            di as error "Run stanrun first or specify drawfile(path_to_draws.dta)."
            exit 198
        }
    }

    capture confirm file "`drawfile'"
    if _rc {
        di as error "stanrun_extract: cannot find draws dataset: `drawfile'"
        exit 601
    }

    // -------------------------------------------------------------
    // 2. Preserve current data and load draws
    // -------------------------------------------------------------
    preserve
    quietly use "`drawfile'", clear

    // chain variable?
    capture confirm variable chain
    local has_chain = !_rc

    // -------------------------------------------------------------
    // 3. Identify parameter variables
    //    (drop typical sampler columns and chain)
    // -------------------------------------------------------------
    local sampler_cols lp__ accept_stat__ stepsize__ treedepth__ ///
        n_leapfrog__ divergent__ energy__ chain

    unab allvars : *
    local paramvars ""

    foreach v of local allvars {
        if strpos(" `sampler_cols' ", " `v' ") {
            continue
        }
        capture confirm numeric variable `v'
        if !_rc {
            local paramvars `paramvars' `v'
        }
    }

    if "`parameters'" != "" {
        // user-specified subset (assume numeric parameters)
        local paramvars "`parameters'"
    }

    if "`paramvars'" == "" {
        di as error "stanrun_extract: no numeric parameter variables detected."
        di as error "Draws dataset: `drawfile'"
        restore
        exit 198
    }

    // -------------------------------------------------------------
    // 4. Chain structure and counts
    // -------------------------------------------------------------
    if `has_chain' == 0 {
        local n_chains = 1
        local chains ""
    }
    else {
        quietly levelsof chain, local(chains)
        local n_chains : word count `chains'
    }

    // -------------------------------------------------------------
    // 5. Prepare results matrix
    //    Columns: mean sd p2_5 p50 p97_5 Rhat ESS N
    // -------------------------------------------------------------
    local K : word count `paramvars'
    tempname T
    matrix `T' = J(`K', 8, .)
    matrix colnames `T' = mean sd p2_5 p50 p97_5 Rhat ESS N

    local i = 0

    // -------------------------------------------------------------
    // 6. Loop over parameters, compute summaries, R-hat, ESS
    // -------------------------------------------------------------
    foreach p of local paramvars {
        local ++i

        // overall summary
        quietly summarize `p'
        local mean   = r(mean)
        local sd     = r(sd)
        local N      = r(N)
        local var    = r(Var)

        // quantiles
        quietly centile `p', centile(2.5 50 97.5)
        local q2_5  = r(c_1)
        local q50   = r(c_2)
        local q97_5 = r(c_3)

        // Default R-hat and ESS to missing
        local Rhat = .
        local ESS  = .

        // ---------------------------------------------------------
        // R-hat: only if multiple chains with equal lengths
        // ---------------------------------------------------------
        if (`n_chains' > 1 & `has_chain') {
            tempname W B Nperchain grandmean m

            preserve
            keep chain `p'
            drop if missing(chain) | missing(`p')

            quietly collapse (mean) mean_p = `p' ///
                               (sd)   sd_p   = `p' ///
                               (count) Nchain = `p', by(chain)

            quietly summarize Nchain
            scalar `Nperchain' = r(min)
            if r(min) != r(max) {
                di as text "Warning: chains for parameter `p' have unequal lengths; R-hat set to missing."
                restore
            }
            else if `Nperchain' > 1 {
                quietly count
                scalar `m' = r(N)

                gen double var_p = sd_p^2
                quietly summarize var_p
                scalar `W' = r(mean)

                quietly summarize mean_p
                scalar `grandmean' = r(mean)

                gen double mean_diff2 = (mean_p - `grandmean')^2
                quietly summarize mean_diff2
                scalar `B' = `Nperchain' * r(sum) / (`m' - 1)

                scalar var_hat    = ((`Nperchain' - 1)/`Nperchain')*`W' + `B'/`Nperchain'
                scalar Rhat_local = sqrt(var_hat / `W')

                local Rhat = Rhat_local

                restore
            }
            else {
                restore
            }
        }

        // ---------------------------------------------------------
        // ESS: simple autocorrelation-based estimate for combined chain
        //
        // ESS = N / (1 + 2 * sum_{k=1}^K rho_k)
        //     where rho_k is lag-k autocorrelation.
        // We stop when rho_k < 0 or when k reaches a max lag.
        // ---------------------------------------------------------
        if `N' > 3 & `var' > 0 {
            local maxlag = 100
            if `maxlag' >= `N' {
                local maxlag = `N' - 1
            }

            preserve
            keep `p'
            drop if missing(`p')

            quietly summarize `p'
            local N_eff = r(N)
            local mu    = r(mean)
            local varp  = r(Var)

            if `N_eff' > 3 & `varp' > 0 {
                local sumrho = 0
                forvalues k = 1/`maxlag' {
                    tempvar prod
                    gen double `prod' = (`p' - `mu') * ( `p'[_n+`k'] - `mu' ) if _n <= _N-`k'
                    quietly summarize `prod', meanonly
                    local gamma_k = r(mean)
                    drop `prod'
                    if missing(`gamma_k') {
                        continue
                    }
                    local rho_k = `gamma_k'/`varp'
                    if `rho_k' < 0 {
                        continue, break
                    }
                    local sumrho = `sumrho' + `rho_k'
                }

                if (1 + 2*`sumrho') > 0 {
                    local ESS = `N_eff' / (1 + 2*`sumrho')
                    if `ESS' > `N_eff' {
                        local ESS = `N_eff'
                    }
                }
            }

            restore
        }

        // Store into results matrix
        matrix `T'[`i',1] = `mean'
        matrix `T'[`i',2] = `sd'
        matrix `T'[`i',3] = `q2_5'
        matrix `T'[`i',4] = `q50'
        matrix `T'[`i',5] = `q97_5'
        matrix `T'[`i',6] = `Rhat'
        matrix `T'[`i',7] = `ESS'
        matrix `T'[`i',8] = `N'
    }

    // -------------------------------------------------------------
    // 7. Label rows and display table
    // -------------------------------------------------------------
    matrix rownames `T' = `paramvars'

    di as text "{hline}"
    di as text "Stanrun summaries for draws in: `drawfile'"
    if `n_chains' > 1 {
        di as text "Number of chains: `n_chains'  (R-hat computed where possible)"
    }
    else {
        di as text "Single chain or no chain variable; R-hat may be missing."
    }
    di as text "ESS is an approximate autocorrelation-based estimate for the combined series."
    di as text "{hline}"

    matrix list `T', format(%9.4f)

    // -------------------------------------------------------------
    // 8. Optional TRACE() plots
    // -------------------------------------------------------------
    if "`trace'" != "" {

        local tracevars "`trace'"
        local toplot ""

        foreach p of local tracevars {
            capture confirm variable `p'
            if _rc {
                di as error "stanrun_extract: trace() variable `p' not found in draws dataset; skipping."
            }
            else {
                local toplot `toplot' `p'
            }
        }

        if "`toplot'" != "" {
            di as text "{hline}"
            di as text "Generating trace and density plots for: `toplot'"
            di as text "{hline}"

            foreach p of local toplot {

                tempvar iter
                if `has_chain' {
                    bysort chain: gen long `iter' = _n
                }
                else {
                    gen long `iter' = _n
                }

                // ---- TRACE PLOT ----
                if (`n_chains' > 1 & `has_chain') {

                    local graphcmd "twoway"
                    local first 1
                    foreach c of local chains {
                        if `first' {
                            local graphcmd "`graphcmd' line `p' `iter' if chain==`c', sort"
                            local first = 0
                        }
                        else {
                            local graphcmd "`graphcmd' || line `p' `iter' if chain==`c', sort"
                        }
                    }
                    local graphcmd "`graphcmd' , title(""Trace: `p'"")"

                    quietly `graphcmd'
                }
                else {
                    quietly twoway line `p' `iter', sort ///
                        title("Trace: `p'")
                }

                // ---- DENSITY PLOT ----
                if (`n_chains' > 1 & `has_chain') {
                    quietly kdensity `p', by(chain) ///
                        title("Density: `p'")
                }
                else {
                    quietly kdensity `p', ///
                        title("Density: `p'")
                }

                drop `iter'
            }
        }
    }

    // -------------------------------------------------------------
    // 9. Return results in r()
    // -------------------------------------------------------------
    return matrix table    = `T'
    return local parameters "`paramvars'"
    return scalar nchains  = `n_chains'
    return local drawfile  "`drawfile'"

    restore
end
