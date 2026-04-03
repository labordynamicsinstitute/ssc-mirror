*! version 1.0.0 24jan2020

cap program drop midas_simdata
program define midas_simdata
	version 11.2
	#delimit;
	syntax [varlist(default=none)], N(integer) LOGits(numlist min=2 max=2) VARlogits(numlist min=2 max=2)
	[STudies(integer 10) P(real 0) R(real 0.5) CORR(real 0.5)					
	PATH(string)];
	#delimit cr
	//==========================================================================//
	// Error checks and defaults 
	

		/* Count number of estimates specified in numlist variables */
		local nes : word count `logits'
		if `nes' > 1 { 
			local logit_sens : word 1 of `logits'
			local logit_spec : word 2 of `logits'
		}

		local nse : word count `varlogits'
		
		local var_logit_sens : word 1 of `varlogits'
		local var_logit_spec : word 2 of `varlogits'
		if (`var_logit_sens'<0 | `var_logit_spec'<0) {
		di as err "Cannot specify a negative variance"
			}
		

		if  `nse'<2 {
			di as err "Must specify an variance value for both sensitivity and specificity"
			exit 198
		}

		

		
		if "`corr'"=="0" {
			di in green "Warning: correlation between logit(sensitivity) and logit(specificity) has been set to 0"
		}
		
	//===========================================================================//
	/*** Postfile declares the filename of a new Stata dataset "temppow". ***/
	/*** "Samp" will contain new study results from each simulation.      ***/
		if "`path'"=="" {
			local dir `c(pwd)'
		}
		else {
			local dir `path'
		}		
	tempname samp								
	postfile `samp' tp fp fn tn using "`dir'/midastemp", replace

		
	/*** Simulate  studies ***/


	forvalues i = 1/`studies' {

	*** Clear the data memory *** 
	drop _all


	*** Specify the matrix for estimates of sens and spec. ***
	matrix m = (`logit_sens', `logit_spec')


	*** Specify the variance-covariance matrix for sens and spec. ***

	
	local sd1 = sqrt(`var_logit_sens')
	local sd2 = sqrt(`var_logit_spec')
	matrix sd = (`sd1', `sd2')

	*** Sample from the multivariate normal distribution. ***
	qui drawnorm logsens logspec, n(`n') means(m) corr(1,`corr',1) sd(sd) cstorage(lower) 
	local sens=invlogit(logsens)
	local spec=invlogit(logspec)

				
	*** Set the number of obs to be the number of diseased patients (n). ***	

	qui set obs `n'

	*** Randomly sample from the binomial distribution N=n, Prob=sens. ***
	*** If xb=1 then TP result, if xb=0 then FN result.                ***
	tempvar xb
	qui gen byte `xb' = rbinomial(1,`sens')

	*** Create a local macro called rtp counting the number of TP. ***

	qui count if `xb'==1
	local rtp=r(N)

	drop `xb'

	*** Calculate the number of healthy patients. ***

	local m=int((`n'*(1-`r'))/`r')

	qui drop _all

	*** Set the number of obs to be the number of healthy patients (m). ***

	qui set obs `m'

	*** Randomly sample from the binomial distribution N=m, Prob=spec. ***
	*** If xb=1 then TN result, if xb=0 then FP result.                ***
	tempvar xb
	qui gen byte `xb' = rbinomial(1,`spec')

	*** Create a local macro called rtn counting the number of TN. ***

	qui count if `xb'==1	
	local rtn=r(N)

	*** Create local macros containing number of FN and FP test results. ***

	local rfn=`n'-`rtp'									
	local rfp=`m'-`rtn'		
				
					
	qui post `samp' (`rtp') (`rfp') (`rfn') (`rtn')  
			}	
		
	/* Close postfile temppow */
	qui postclose `samp'
	quietly use "`dir'/midastemp", clear
	di as txt _n "Simulated DTA data: " as res `studies' as txt " studies, N = " as res `n' as txt " per study"
	di as txt "Data loaded in memory (" as res _N as txt " observations)"
	list tp fp fn tn in 1/5, noobs separator(0)

end
