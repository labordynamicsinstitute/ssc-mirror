*! opl_frontier_tb, v. 0.01, G.Cerulli
program define opl_frontier_tb , rclass
    version 18.0

    syntax [, FRAME(name) REPLACE SAVING(string asis) GRAPH BANDS(integer 15) SPLINEPOINTS(integer 100) GRSIZE(real 0.8) ]

    if "`e(cmd)'" != "opl_tb_cba" {
        di as error "opl_frontier_tb must be run after opl_tb_cba"
        exit 301
    }

    if `bands' < 2 {
        di as error "bands() must be at least 2"
        exit 198
    }

    if `splinepoints' < 2 {
        di as error "splinepoints() must be at least 2"
        exit 198
    }

    if "`frame'" == "" local frame "opl_frontier"

    capture frame `frame': describe
    if !_rc {
        if "`replace'" == "" {
            di as error "frame `frame' already exists; specify replace"
            exit 110
        }
        frame drop `frame'
    }

    tempname G
    matrix `G' = e(grid)

    local nselect = e(nselect)
    local lambda  = e(lambda)
    local th1opt  = e(threshold1)
	
	* Optimal constrained-policy outcomes

	local covopt  = 100 * e(coverage_opt)
	local Qopt    = e(Q_opt)
	local TBopt   = e(total_benefit_opt)
	local TCopt   = e(total_cost_opt)
	local ATETopt = e(ATET_opt)
	local covlabel : display %5.1f `covopt'	
	
    local th2opt  = .
    if `nselect' == 2 local th2opt = e(threshold2)

    frame create `frame'
    frame `frame' {
        quietly svmat double `G', names(col)

        * Policy identifier
        gen long policy_id = _n
        label variable policy_id "Candidate policy identifier"

        * Percentage coverage, convenient for graphs
        gen double coverage_pct = 100*coverage
        label variable coverage_pct "Coverage (%)"

        * Mark the policy selected by opl_tb_cba
        if `nselect' == 1 {
            gen byte optimal = abs(threshold1-`th1opt') < 1e-10
        }
        else {
            gen byte optimal = abs(threshold1-`th1opt') < 1e-10 & ///
                               abs(threshold2-`th2opt') < 1e-10
        }
        label variable optimal "Optimal constrained policy"

        *------------------------------------------------------------*
        * Cost-benefit Pareto frontier
        *
        * A policy is cost-benefit efficient if no policy with an
        * equal or lower total cost produces a strictly larger total
        * benefit.
        *------------------------------------------------------------*
        gsort total_cost -total_benefit
        gen double runmax_benefit = total_benefit
        replace runmax_benefit = max(runmax_benefit[_n-1], total_benefit) ///
            in 2/L
        gen byte efficient_cb = total_benefit >= runmax_benefit - 1e-10
        label variable efficient_cb "Efficient on cost-benefit frontier"

        * Surplus frontier as cost rises
        gsort total_cost -Q
        gen double runmax_Q = Q
        replace runmax_Q = max(runmax_Q[_n-1], Q) in 2/L
        gen byte efficient_Q = Q >= runmax_Q - 1e-10
        label variable efficient_Q "Efficient on cost-surplus frontier"

        *------------------------------------------------------------*
        * Coverage frontier
        *
        * With two selection variables, many threshold pairs may produce
        * the same treatment coverage. For each exact coverage level,
        * retain the policy with the largest social surplus Q.
        *
        * The threshold pair remains available as policy metadata, but
        * it is not used as a graph axis.
        *------------------------------------------------------------*
        gsort coverage -Q
        by coverage: gen byte frontier_coverage = (_n == 1)
        label variable frontier_coverage ///
            "Maximum-surplus policy at each coverage level"

        * Restore a convenient order
        sort total_cost total_benefit

        * Save frontier dataset, if requested
        if `"`saving'"' != "" {
            save `"`saving'"', replace
        }

        *------------------------------------------------------------*
        * Graphs: median-spline representations of policy frontiers
        *------------------------------------------------------------*
        if "`graph'" != "" {

			* 1. Cost-benefit efficient frontier
			twoway                                                   ///
				(mspline total_benefit total_cost if efficient_cb,  ///
					bands(`bands')                                  ///
					n(`splinepoints'))                              ///
				(scatteri `TBopt' `TCopt',                          ///
					msymbol(D)                                      ///
					msize(medium)),                                 ///
				xtitle("Total treatment cost")                      ///
				ytitle("Total treatment benefit")                   ///
				title("Cost-benefit policy frontier")               ///
				legend(order(1 "Efficient frontier"                 ///
							 2 "Optimal policy"))                   ///
				name(opl_frontier_cb, replace)

			* 2. Surplus-coverage frontier
			twoway                                                   ///
				(mspline Q coverage_pct if frontier_coverage,       ///
					bands(`bands')                                  ///
					n(`splinepoints'))                              ///
				(scatteri `Qopt' `covopt',                          ///
					msymbol(D)                                      ///
					msize(medium)),                                 ///
				xline(`covopt', lpattern(dash))                     ///
				text(`Qopt' `covopt'                                ///
					" Optimal coverage = `covlabel'%",              ///
					placement(ne))                                  ///
				xtitle("Coverage (%)")                              ///
				ytitle("Weighted social surplus Q")                 ///
				title("Surplus-coverage frontier")                  ///
				legend(order(1 "Policy frontier"                    ///
							 2 "Optimal policy"))                   ///
				name(opl_frontier_qcov, replace)
				
			* 3. ATET-coverage frontier
			twoway                                                   ///
				(mspline ATET coverage_pct if frontier_coverage,    ///
					bands(`bands')                                  ///
					n(`splinepoints'))                              ///
				(scatteri `ATETopt' `covopt',                       ///
					msymbol(D)                                      ///
					msize(medium)),                                 ///
				xline(`covopt', lpattern(dash))                     ///
				text(`ATETopt' `covopt'                             ///
					" Optimal coverage = `covlabel'%",              ///
					placement(ne))                                  ///
				xtitle("Coverage (%)")                              ///
				ytitle("ATET")                                      ///
				title("ATET-coverage frontier")                     ///
				legend(order(1 "Policy frontier"                    ///
							 2 "Optimal policy"))                   ///
				name(opl_frontier_atet, replace)
	
			* 4. Benefit, cost, and surplus by coverage
			twoway                                                     ///
				(mspline total_benefit coverage_pct                   ///
					if frontier_coverage,                             ///
					bands(`bands') n(`splinepoints'))                 ///
				(mspline total_cost coverage_pct                      ///
					if frontier_coverage,                             ///
					bands(`bands') n(`splinepoints'))                 ///
				(mspline Q coverage_pct                               ///
					if frontier_coverage,                             ///
					bands(`bands') n(`splinepoints')),                ///
				xline(`covopt', lpattern(dash))                       ///
				text(`Qopt' `covopt'                                  ///
					" Optimal coverage = `covlabel'%",                ///
					placement(ne))                                    ///
				xtitle("Coverage (%)")                                ///
				ytitle("Total outcome")                               ///
				title("Policy outcomes by coverage")                  ///
				legend(order(1 "Total benefit"                        ///
							 2 "Total cost"                           ///
							 3 "Social surplus"))                     ///
				name(opl_frontier_path, replace)

            graph combine                                             ///
                opl_frontier_cb                                       ///
                opl_frontier_qcov                                     ///
                opl_frontier_atet                                     ///
                opl_frontier_path,                                    ///
                cols(2)                                               ///
                title("Welfare policy analysis")                      ///
                name(opl_frontier_tbs, replace) iscale(*`grsize')
        }

        quietly count
        return scalar N_policies = r(N)

        quietly count if efficient_cb
        return scalar N_efficient_cb = r(N)

        quietly count if efficient_Q
        return scalar N_efficient_Q = r(N)
    }

    return local frame "`frame'"
    return scalar lambda = `lambda'
    return scalar nselect = `nselect'
    return scalar bands = `bands'
    return scalar splinepoints = `splinepoints'

    di as text _newline "Policy frontier dataset created in frame " ///
        as result "`frame'"
    di as text "Use: " as result "frame change `frame'"
    di as text "Cost-benefit efficient policies: " ///
        as result r(N_efficient_cb)
end
