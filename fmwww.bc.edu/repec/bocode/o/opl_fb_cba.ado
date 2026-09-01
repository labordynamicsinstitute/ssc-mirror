*! version 1.1.0 16jul2026
program define opl_fb_cba , rclass

    version 18.0

    syntax varname(numeric) [if] [in],                 ///
        COST(varname numeric)                          ///
        [ LAMBDA(real 1)                               ///
          NQUANTILES(integer 20)                       ///
          GENERATE(name)                               ///
          FRAME(name)                                  ///
          SAVING(string asis)                          ///
		  GRSIZE(real 0.7)                             ///
          GRAPH                                        ///
          REPLACE ]

    marksample touse
    markout `touse' `varlist' `cost'

    local tau `varlist'

    *******************************************************
    * Defaults
    *******************************************************

    if "`generate'" == "" {
        local generate policy_fb
    }

    if "`frame'" == "" {
        local frame policy_frontier
    }

    *******************************************************
    * Input checks
    *******************************************************

    if `lambda' < 0 | `lambda' > 1 {

        di as err ///
            "lambda() must be between 0 and 1"

        exit 198
    }

    if `nquantiles' < 2 {

        di as err ///
            "nquantiles() must be at least 2"

        exit 198
    }

    quietly count if `touse'
    local N = r(N)

    if `N' == 0 {

        di as err ///
            "no valid observations"

        exit 2000
    }

    if `nquantiles' > `N' {

        di as err ///
            "nquantiles() cannot exceed the number of observations"

        exit 198
    }

    quietly count if `cost' < 0 & `touse'

    if r(N) > 0 {

        di as err ///
            "cost() must contain nonnegative values"

        exit 459
    }

    *******************************************************
    * Check generated policy variable
    *******************************************************

    capture confirm new variable `generate'

    if _rc {

        if "`replace'" == "" {

            di as err ///
                "variable `generate' already exists; specify replace"

            exit 110
        }

        drop `generate'
    }

    *******************************************************
    * Check frontier frame
    *******************************************************

    capture frame confirm `frame'

    if !_rc {

        if "`replace'" == "" {

            di as err ///
                "frame `frame' already exists; specify replace"

            exit 110
        }

        frame drop `frame'
    }

    *******************************************************
    * Construct policy score
    *
    * score_i = tau_i - lambda*cost_i
    *******************************************************

    tempvar score

    quietly generate double `score' = ///
        `tau' - `lambda'*`cost' if `touse'

    *******************************************************
    * Generate first-best policy
    *
    * policy_i = 1 if score_i > 0
    *******************************************************

    quietly generate byte `generate' = ///
        (`score' > 0) if `touse'

    label variable `generate' ///
        "First-best policy: tau - lambda*cost > 0"

    *******************************************************
    * Evaluate first-best policy
    *******************************************************

    quietly count if `generate' == 1 & `touse'

    local FB_NTREAT = r(N)
    local FB_COVERAGE = 100*`FB_NTREAT'/`N'

    local FB_ATET       = .
    local FB_TTET       = 0
    local FB_ATEPOP     = 0
    local FB_AVG_COST   = .
    local FB_TOTAL_COST = 0
    local FB_NET_BEN    = 0
    local FB_WELFARE    = 0
    local FB_BC         = .

    if `FB_NTREAT' > 0 {

        quietly summarize `tau' ///
            if `generate' == 1 & `touse', ///
            meanonly

        local FB_ATET   = r(mean)
        local FB_TTET   = r(sum)
        local FB_ATEPOP = `FB_TTET'/`N'

        quietly summarize `cost' ///
            if `generate' == 1 & `touse', ///
            meanonly

        local FB_AVG_COST   = r(mean)
        local FB_TOTAL_COST = r(sum)

        /*
            Standard net monetary benefit
        */

        local FB_NET_BEN = ///
            `FB_TTET' - `FB_TOTAL_COST'

        /*
            Objective maximized by the first-best policy
        */

        local FB_WELFARE = ///
            `FB_TTET' - `lambda'*`FB_TOTAL_COST'

        if `FB_TOTAL_COST' > 0 {

            local FB_BC = ///
                `FB_TTET'/`FB_TOTAL_COST'
        }
    }

    *******************************************************
    * Display first-best results
    *******************************************************

    di
    di as txt "{hline 74}"
    di as txt "FIRST-BEST POLICY"
    di as txt "{hline 74}"

    di as txt "Policy score" ///
        _col(44) as res "`tau' - `lambda'*`cost'"

    di as txt "Lambda" ///
        _col(44) as res %14.4f `lambda'

    di as txt "Generated policy" ///
        _col(44) as res "`generate'"

    di as txt "{hline 74}"

    di as txt "Observations" ///
        _col(44) as res %14.0fc `N'

    di as txt "Individuals treated" ///
        _col(44) as res %14.0fc `FB_NTREAT'

    di as txt "Coverage (%)" ///
        _col(44) as res %14.2f `FB_COVERAGE'

    di as txt "ATET: Average CATE on treated" ///
        _col(44) as res %14.4f `FB_ATET'

    di as txt "TTET: Total treatment effect" ///
        _col(44) as res %14.4f `FB_TTET'

    di as txt "Average effect in population" ///
        _col(44) as res %14.4f `FB_ATEPOP'

    di as txt "{hline 74}"

    di as txt "Average treatment cost" ///
        _col(44) as res %14.4f `FB_AVG_COST'

    di as txt "Total treatment cost" ///
        _col(44) as res %14.4f `FB_TOTAL_COST'

    di as txt "Net benefit: TTET - total cost" ///
        _col(44) as res %14.4f `FB_NET_BEN'

    di as txt "Weighted welfare: TTET - lambda*cost" ///
        _col(44) as res %14.4f `FB_WELFARE'

    di as txt "Benefit / Cost ratio" ///
        _col(44) as res %14.4f `FB_BC'

    di as txt "{hline 74}"

    *******************************************************
    * Compute quantiles of the policy score
    *******************************************************

    quietly _pctile `score' if `touse', ///
        nq(`nquantiles')

    /*
        Save all quantiles before another r-class command
        overwrites r(r1), r(r2), ...
    */

    forvalues q = 1/`=`nquantiles' - 1' {

        local cutoff_`q' = r(r`q')
    }

    *******************************************************
    * Create frontier frame
    *
    * Number of rows:
    *
    *   1 first-best point
    *   nquantiles - 1 quantile policies
    *
    * Total = nquantiles
    *******************************************************
	
	*******************************************************
	* Check and remove existing frontier frame
	*******************************************************

	capture frame confirm `frame'
	if !_rc {
		if "`replace'" == "" {
			di as err ///
				"frame `frame' already exists; specify replace"
			exit 110
		}
		quietly frame drop `frame'
	}
	
qui{
    frame create `frame'

    frame `frame': set obs `nquantiles'

    frame `frame': generate double quantile         = .
    frame `frame': generate double cutoff           = .
    frame `frame': generate byte   first_best       = 0
    frame `frame': generate double Ntreat           = .
    frame `frame': generate double coverage         = .
    frame `frame': generate double ATET             = .
    frame `frame': generate double TTET             = .
    frame `frame': generate double ATEPOP           = .
    frame `frame': generate double avg_cost         = .
    frame `frame': generate double total_cost       = .
    frame `frame': generate double net_benefit      = .
    frame `frame': generate double welfare          = .
    frame `frame': generate double bc_ratio         = .

    *******************************************************
    * Store first-best results in row 1
    *******************************************************

    frame `frame': replace quantile = . ///
        in 1

    frame `frame': replace cutoff = 0 ///
        in 1

    frame `frame': replace first_best = 1 ///
        in 1

    frame `frame': replace Ntreat = `FB_NTREAT' ///
        in 1

    frame `frame': replace coverage = `FB_COVERAGE' ///
        in 1

    frame `frame': replace ATET = `FB_ATET' ///
        in 1

    frame `frame': replace TTET = `FB_TTET' ///
        in 1

    frame `frame': replace ATEPOP = `FB_ATEPOP' ///
        in 1

    frame `frame': replace avg_cost = `FB_AVG_COST' ///
        in 1

    frame `frame': replace total_cost = `FB_TOTAL_COST' ///
        in 1

    frame `frame': replace net_benefit = `FB_NET_BEN' ///
        in 1

    frame `frame': replace welfare = `FB_WELFARE' ///
        in 1

    frame `frame': replace bc_ratio = `FB_BC' ///
        in 1
}
    *******************************************************
    * Evaluate quantile-based policies
    *******************************************************

    forvalues q = 1/`=`nquantiles' - 1' {

        local row = `q' + 1

        local cutoff = `cutoff_`q''

        local percentile = ///
            100*`q'/`nquantiles'

        tempvar policy_q

        quietly generate byte `policy_q' = ///
            (`score' > `cutoff') if `touse'

        quietly count if `policy_q' == 1 & `touse'

        local Q_NTREAT = r(N)
        local Q_COVERAGE = 100*`Q_NTREAT'/`N'

        local Q_ATET       = .
        local Q_TTET       = 0
        local Q_ATEPOP     = 0
        local Q_AVG_COST   = .
        local Q_TOTAL_COST = 0
        local Q_NET_BEN    = 0
        local Q_WELFARE    = 0
        local Q_BC         = .

        if `Q_NTREAT' > 0 {

            quietly summarize `tau' ///
                if `policy_q' == 1 & `touse', ///
                meanonly

            local Q_ATET   = r(mean)
            local Q_TTET   = r(sum)
            local Q_ATEPOP = `Q_TTET'/`N'

            quietly summarize `cost' ///
                if `policy_q' == 1 & `touse', ///
                meanonly

            local Q_AVG_COST   = r(mean)
            local Q_TOTAL_COST = r(sum)

            local Q_NET_BEN = ///
                `Q_TTET' - `Q_TOTAL_COST'

            local Q_WELFARE = ///
                `Q_TTET' - `lambda'*`Q_TOTAL_COST'

            if `Q_TOTAL_COST' > 0 {

                local Q_BC = ///
                    `Q_TTET'/`Q_TOTAL_COST'
            }
        }

        ***************************************************
        * Store current policy in frontier frame
        ***************************************************
qui{
        frame `frame': replace quantile = ///
            `percentile' in `row'

        frame `frame': replace cutoff = ///
            `cutoff' in `row'

        frame `frame': replace first_best = ///
            0 in `row'

        frame `frame': replace Ntreat = ///
            `Q_NTREAT' in `row'

        frame `frame': replace coverage = ///
            `Q_COVERAGE' in `row'

        frame `frame': replace ATET = ///
            `Q_ATET' in `row'

        frame `frame': replace TTET = ///
            `Q_TTET' in `row'

        frame `frame': replace ATEPOP = ///
            `Q_ATEPOP' in `row'

        frame `frame': replace avg_cost = ///
            `Q_AVG_COST' in `row'

        frame `frame': replace total_cost = ///
            `Q_TOTAL_COST' in `row'

        frame `frame': replace net_benefit = ///
            `Q_NET_BEN' in `row'

        frame `frame': replace welfare = ///
            `Q_WELFARE' in `row'

        frame `frame': replace bc_ratio = ///
            `Q_BC' in `row'

        drop `policy_q'
    }

}
    *******************************************************
    * Format frontier frame
    *******************************************************

    frame `frame': sort coverage

    frame `frame': format quantile %9.2f
    frame `frame': format cutoff %12.2f
    frame `frame': format Ntreat %12.0fc
    frame `frame': format coverage %9.2f
	

    frame `frame': format ///
        ATET TTET ATEPOP avg_cost total_cost ///
        net_benefit welfare bc_ratio %14.4f

    frame `frame': label variable quantile ///
        "Score percentile cutoff"

    frame `frame': label variable cutoff ///
        "Policy-score cutoff"

    frame `frame': label variable first_best ///
        "First-best policy"

    frame `frame': label variable Ntreat ///
        "Individuals treated"

    frame `frame': label variable coverage ///
        "Coverage (%)"

    frame `frame': label variable ATET ///
        "Average CATE on treated"

    frame `frame': label variable TTET ///
        "Total treatment benefit"

    frame `frame': label variable ATEPOP ///
        "Average population effect"

    frame `frame': label variable avg_cost ///
        "Average treatment cost"

    frame `frame': label variable total_cost ///
        "Total treatment cost"

    frame `frame': label variable net_benefit ///
        "TTET - total cost"

    frame `frame': label variable welfare ///
        "TTET - lambda*total cost"

    frame `frame': label variable bc_ratio ///
        "Benefit-cost ratio"

    *******************************************************
    * Save frontier frame
    *******************************************************

    if "`saving'" != "" {

        if "`replace'" != "" {

            frame `frame': ///
                save `saving', replace
        }
        else {

            frame `frame': ///
                save `saving'
        }
    }

    *******************************************************
    * Graphs
    *******************************************************

    if "`graph'" != "" {

        frame `frame': twoway                       ///
            (line TTET coverage,                    ///
                sort)                               ///
            (scatter TTET coverage                  ///
                if first_best == 1,                 ///
                msymbol(D)                          ///
                msize(medium)),                     ///
            xtitle("Coverage (%)")                  ///
            ytitle("Total treatment benefit")       ///
			ylabel(,format(%9.0fc))                  ///
            title("Benefit-Coverage Frontier")      ///
            subtitle("lambda = `lambda'")           ///
            legend(order(1 "Score frontier"         ///
                         2 "First-best"))            ///
            name(psf_benefit, replace)

			
		frame `frame': twoway                       ///
			(line ATET coverage,                    ///
				sort)                               ///
			(scatter ATET coverage                  ///
				if first_best == 1,                 ///
				msymbol(D)                          ///
				msize(medium)),                     ///
			xtitle("Coverage (%)")                  ///
			ytitle("Average treatment effect")      ///
			ylabel(, format(%9.2f))                 ///
			title("ATET-Coverage Frontier")         ///
			subtitle("lambda = `lambda'")           ///
			legend(order(1 "Score frontier"         ///
						 2 "First-best"))           ///
			name(psf_atet, replace)			
			
			
        frame `frame': twoway                       ///
            (line total_cost coverage,              ///
                sort)                               ///
            (scatter total_cost coverage            ///
                if first_best == 1,                 ///
                msymbol(D)                          ///
                msize(medium)),                     ///
            xtitle("Coverage (%)")                  ///
            ytitle("Total treatment cost")          ///
			ylabel(,format(%9.0fc))                  ///
            title("Cost-Coverage Frontier")         ///
            subtitle("lambda = `lambda'")           ///
            legend(order(1 "Score frontier"         ///
                         2 "First-best"))            ///
            name(psf_cost, replace)

        frame `frame': twoway                       ///
            (line welfare coverage,                 ///
                sort)                               ///
            (scatter welfare coverage               ///
                if first_best == 1,                 ///
                msymbol(D)                          ///
                msize(medium)),                     ///
            xline(`FB_COVERAGE',                    ///
                lpattern(dash))                     ///
            xtitle("Coverage (%)")                  ///
			ylabel(,format(%9.0fc))                 ///
            ytitle("TTET - lambda x total cost")    ///
            title("Welfare-Coverage Frontier")      ///
            subtitle("lambda = `lambda'")           ///
            legend(order(1 "Score frontier"         ///
                         2 "First-best"))            ///
            name(psf_welfare, replace)

        frame `frame': twoway                       ///
            (line net_benefit coverage,             ///
                sort)                               ///
            (scatter net_benefit coverage           ///
                if first_best == 1,                 ///
                msymbol(D)                          ///
                msize(medium)),                     ///
            xtitle("Coverage (%)")                  ///
            ytitle("TTET - total cost")             ///
			ylabel(,format(%9.0fc))                  ///
            title("Net Benefit-Coverage Frontier")  ///
            subtitle("lambda = `lambda'")           ///
            legend(order(1 "Score frontier"         ///
                         2 "First-best"))            ///
            name(psf_net, replace)

        graph combine                               ///
            psf_benefit                             ///
			psf_atet                                ///
            psf_cost                                ///
            psf_welfare                             ///
            psf_net,                                ///
            cols(2)                                 ///
			iscale(*`grsize')                       ///
            title("Policy Score Frontier")
    }

    *******************************************************
    * Returned first-best results
    *******************************************************

    return scalar N = `N'
    return scalar Ntreat = `FB_NTREAT'
    return scalar coverage = `FB_COVERAGE'

    return scalar ATET = `FB_ATET'
    return scalar TTET = `FB_TTET'
    return scalar ATEPOP = `FB_ATEPOP'

    return scalar avg_cost = `FB_AVG_COST'
    return scalar total_cost = `FB_TOTAL_COST'

    return scalar net_benefit = `FB_NET_BEN'
    return scalar welfare = `FB_WELFARE'
    return scalar bc_ratio = `FB_BC'

    return scalar lambda = `lambda'
    return scalar nquantiles = `nquantiles'

    return local policy "`generate'"
    return local frame "`frame'"

end
