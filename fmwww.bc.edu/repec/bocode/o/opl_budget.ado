********************************************************************************
*! "opl_budget", v.2, GCerulli, 11/12/2025
********************************************************************************

program define opl_budget, rclass
    version 17.0
    /*
        Optimal Policy Learning with Budget Constraint
        Binary treatment assignment (0/1), selecting individuals to treat
        under two constraints:
            (i)  total treatment cost <= budget C
            (ii) number of treated individuals >= N*

        Syntax:
            opl_budget tauvar costvar, budget(#) nmin(#) em0(#)
                [ policy(name) replace custom_pol(varname) ]
        
        Inputs:
            tauvar   = estimated individual treatment effects (τ̂_i)
            costvar  = individual treatment costs (c_i)
        
        Required options:
            budget(#)  = total available budget C
            nmin(#)    = minimum number of treated individuals N*
            em0(#)     = baseline welfare E[m0(X)]

        Optional:
            policy(name)    = name of generated optimal policy variable (default: opl_policy)
            replace         = allow overwriting existing policy variable
            custom_pol(var) = name of an existing 0/1 policy variable defined by the user,
                              which will be evaluated in terms of welfare and coverage
    */

    //----------------------------------------------------------------------
    // 1. Parse arguments
    //----------------------------------------------------------------------
    syntax varlist(min=2 max=2 numeric) , ///
        BUDget(real) ///
        NMin(integer) ///
        EM0(real) ///
        [ POLicy(name) REPLACE CUSTOM_pol(varname) ]
	
    tokenize `varlist'
    local tauvar  `1'     // variable storing τ̂_i
    local costvar `2'     // variable storing c_i

	tempvar mysample
	gen `mysample' = !missing(`tauvar' , `costvar')
	qui count if `mysample'==1
	local N_used = r(N) 

    // Default name for policy variable if not provided
    if ("`policy'" == "") local policy "opl_policy"

    //----------------------------------------------------------------------
    // 2. Basic dataset checks
    //----------------------------------------------------------------------
    quietly count
    local N = r(N)

    if `N' == 0 {
        di as err "dataset is empty"
        exit 200
    }

    if `nmin' < 1 {
        di as err "nmin() must be >= 1"
        exit 198
    }

    if `nmin' > `N' {
        di as err "nmin() exceeds the number of observations"
        exit 198
    }

    if `budget' <= 0 {
        di as err "budget() must be strictly positive"
        exit 198
    }

    // Costs must be positive and nonmissing
    capture assert `costvar' > 0 & !missing(`costvar')
    if _rc {
        di as err "cost variable must be strictly positive and non-missing"
        exit 459
    }

    //----------------------------------------------------------------------
    // 3. Handling existing policy variable (optimal policy)
    //----------------------------------------------------------------------
    capture confirm variable `policy'
    if !_rc {
        if ("`replace'" == "") {
            di as err "variable `policy' already exists. Use option replace."
            exit 110
        }
        else {
            drop `policy'
        }
    }

    //----------------------------------------------------------------------
    // 4. Store original order
    //----------------------------------------------------------------------
    tempvar origorder
    gen long `origorder' = _n     // preserve dataset order for final sorting

    //----------------------------------------------------------------------
    // 5. Compute cost-effectiveness score s_i = τ̂_i / c_i
    //----------------------------------------------------------------------
    tempvar score
    gen double `score' = `tauvar' / `costvar'

    //----------------------------------------------------------------------
    // 6. Sort by score in descending order
    //----------------------------------------------------------------------
    gsort - `score'

    //----------------------------------------------------------------------
    // 7. Ranking and cumulative sums
    //----------------------------------------------------------------------
    tempvar rank cumtau cumcost feas

    gen long   `rank'    = _n                     // ranking index after sorting
    gen double `cumtau'  = sum(`tauvar')          // cumulative τ̂
    gen double `cumcost' = sum(`costvar')         // cumulative cost

    // feasible solutions: must meet both constraints:
    // (i) rank >= nmin   -> at least N* units selected
    // (ii) cumcost <= budget
    gen byte `feas' = (`rank' >= `nmin' & `cumcost' <= `budget')

    //----------------------------------------------------------------------
    // 8. Check feasibility
    //----------------------------------------------------------------------
    quietly count if `feas'
    if r(N) == 0 {
        di as err "no feasible solution: budget too small to treat at least N* individuals"
        sort `origorder'
        drop `origorder' `rank' `cumtau' `cumcost' `feas' `score'
        exit 498
    }

    //----------------------------------------------------------------------
    // 9. Identify k* maximizing cumulative tau among feasible k
    //----------------------------------------------------------------------
    quietly summarize `cumtau' if `feas', meanonly
    scalar besttau = r(max)

    quietly summarize `rank' if `feas' & `cumtau' == besttau, meanonly
    local kstar = r(min)      // choose smallest rank achieving max welfare

    //----------------------------------------------------------------------
    // 10. Generate optimal policy: treat if rank <= k*
    //----------------------------------------------------------------------
    gen byte `policy' = (`rank' <= `kstar')

    //----------------------------------------------------------------------
    // 11. Compute total welfare and total cost of selected (optimal) policy
    //----------------------------------------------------------------------
	
	quietly count
    local N = r(N)
	
	quietly count if `policy'
    local Ntreated = r(N)
	
	quietly sum `tauvar' if `policy'
	local ATET = r(mean)
	
	local TTET = `ATET'*`Ntreated'
	
	local averageWelfare = `em0' + `ATET' * `Ntreated'/`N'
	
	local totalWelfare = `averageWelfare' * `N'

    quietly summarize `costvar' if `policy', meanonly
    local totalCost = r(sum)
	
	local averageCost = `totalCost'/`Ntreated'
	
	local pnr = `TTET' - `totalCost' // policy net return
	
	local pnr_per_treat = `pnr'/`Ntreated' // policy net return per treated
	
    //----------------------------------------------------------------------
    // 12. Restore original dataset order
    //----------------------------------------------------------------------
    sort `origorder'
    drop `origorder' `rank' `cumtau' `cumcost' `feas' `score'

    //----------------------------------------------------------------------
    // 13. Return results for optimal policy to r()
    //----------------------------------------------------------------------
    return scalar budget        = `budget'
    return scalar kstar         = `kstar'
    return scalar AW            = `averageWelfare'
    return scalar TW            = `totalWelfare'
    return scalar AC            = `averageCost'
    return scalar TC            = `totalCost'
	return scalar AI            = `ATET' // average impact
	return scalar TI            = `TTET' // total impact
	return scalar PNR           = `pnr' // policy net return
	return scalar PNRT          = `pnr_per_treat' // policy net return per treated
    return scalar Ntreated      = `Ntreated'
    return scalar Ptreated      = `Ntreated' / `N' * 100

    //----------------------------------------------------------------------
    // 14. Evaluate custom policy (if requested)
    //----------------------------------------------------------------------
    if ("`custom_pol'" != "") {
		
        // Check that custom_pol variable exists
        capture confirm variable `custom_pol'
        if _rc {
            di as err "custom_pol(`custom_pol') not found in the dataset"
            exit 111
        }

        // Check custom_pol is 0/1 and non-missing
        capture assert inlist(`custom_pol',0,1) & !missing(`custom_pol')
        if _rc {
            di as err "custom_pol() must be a 0/1, non-missing variable"
            exit 459
        }
		

        // Number treated under custom policy
        quietly count if `custom_pol' == 1
        local Ntreated_c = r(N)
		
		quietly sum `tauvar' if `custom_pol' == 1
		local ATET_c = r(mean)
	
		local TTET_c = `ATET_c'*`Ntreated_c'
	
		local averageWelfare_c = `em0' + `ATET_c' * `Ntreated_c'/`N'
	
		local totalWelfare_c = `averageWelfare_c' * `N'

		quietly summarize `costvar' if `custom_pol' == 1, meanonly
		local totalCost_c = r(sum)
	
		local averageCost_c = `totalCost_c'/`Ntreated_c'
		
		local pnr_c = `TTET_c' - `totalCost_c' // policy net return
	
		local pnr_per_treat_c = `pnr_c'/`Ntreated_c' // policy net return per treated
		
        // Return in r()
		
		return scalar N               = `N'
		return scalar N_used          = `N_used'
		return scalar AW_c            = `averageWelfare_c'
		return scalar TW_c            = `totalWelfare_c'
		return scalar AC_c            = `averageCost_c'
		return scalar TC_c            = `totalCost_c'
		return scalar AI_c            = `ATET_c' // average impact
		return scalar TI_c            = `TTET_c' // total impact	
		return scalar PNR_c           = `pnr_c'  // policy net return
	    return scalar PNRT_c          = `pnr_per_treat_c' // policy net return per treated
		return scalar Ntreated_c      = `Ntreated_c'
		return scalar Ptreated_c      = `Ntreated_c' / `N' * 100
		return scalar NMin            = `nmin'
    }

    //----------------------------------------------------------------------
    // 15. Summary tables
    //----------------------------------------------------------------------
                di ""
		di "{hline 60}"
		di "                  - TABLE OF RESULTS -                 "
		di "              {it:OPL WITH BUDGET CONSTRAIN} "
		di "             {it:AND MINIMUM NUMBER OF TREATED} "
		di "{hline 60}"
		di "                    - General Info -   "
		di "{hline 60}"
		di "  Number of obs                     " %12.0f return(N)
		di "  Number of used obs                " %12.0f return(N_used)
		di "  Budget                            " %12.0f return(budget)	
		di "  Minimum N. of requested treated   " %12.0f return(NMin)		
		di "{hline 60}"
		di "                   - Optimal Policy - "
		di "{hline 60}"
		di "  Parameter                               Value"
		di "{hline 60}"
		di "  Optimal number of treated         " %12.0f return(Ntreated)
		di "  Percentage of treated             " %12.0f return(Ptreated)	
		di "  Total cost (TC)                   " %12.4f return(TC)
		di "  Average cost per treated (AC)     " %12.4f return(AC)		
		di "  Total welfare (TW)                " %12.4f return(TW)
		di "  Average welfare (AW)              " %12.4f return(AW)		
		di "  Average impact (ATET)             " %12.4f return(AI)		
		di "  Total impact (TTET)               " %12.4f return(TI)	
		di "  Policy net return (PNR)           " %12.4f return(PNR)	
		di "  PNR per treated (PNRT)            " %12.4f return(PNRT)	
		di "  Policy variable created           " %12s   "`policy'"
		di "{hline 60}"
		di "  Note: PNR = TTET-TC; PNRT = PNR/N1"
		di "{hline 60}"
		

	if ("`custom_pol'" != "") {
		di " "
		di "{hline 60}"
		di "                   - Custom Policy - " 
		di "{hline 60}"
		di "  Parameter                               Value"
		di "{hline 60}"
		di "  Number of treated                  " %12.0f return(Ntreated_c)
		di "  Percentage of treated              " %12.0f return(Ptreated_c)	
		di "  Total cost (TC_c)                  " %12.4f return(TC_c)
		di "  Average cost per treated (AC_c)    " %12.4f return(AC_c)		
		di "  Total welfare (TW_c)               " %12.4f return(TW_c)
		di "  Average welfare (AW_c)             " %12.4f return(AW_c)		
		di "  Average impact (ATET_c)            " %12.4f return(AI_c)		
		di "  Total impact (TTET_c)              " %12.4f return(TI_c)			
		di "  Policy net return (PNR_c)          " %12.4f return(PNR_c)	
		di "  PNR_c per treated (PNRT_c)         " %12.4f return(PNRT_c)		
		di "  Policy variable created            " %12s   "`policy'"
		di "{hline 60}"
		di "{hline 60}"
		di "  Note: PNR_c = TTET_c-TC_c; PNRTc= PNR_c/N1_c"
		di "{hline 60}"
	}	
    di " "
end
********************************************************************************			
