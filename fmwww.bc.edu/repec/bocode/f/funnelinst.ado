*! 1.0.0 Ariel Linden 23jan2024 // added exact stats for smr (cross-sectional)
*! 1.0.0 Ariel Linden 21dec2023

capture program drop funnelinst
program define funnelinst, rclass
version 11.0

		syntax anything [if][in]  [,		///
				TARget(numlist max=2 sort)	/// target with max of two values
				CHType(string)				/// change type for prop/rate subcommands. 4 vars in the syntax indicates "change"
				WINsor(real 0)				/// percent winsored, default 0 winsoring
				OVERdisp(string)			/// additive (add) or multiplicative (mult) overdispersion
				NPOints(real 200)			/// number of points in the funnel plot denominator
				XRangehigh(numlist max=1)	/// highest value in the funnel plot denominator
				YPERcent					/// multiply Y by 100 for proportion
				RATEdenom(numlist max=1)	/// multiply Y by specified amount and X by specified amount for rate
				LOGtrans					/// log tranformation for prop/rate and SMR
				ARCsintrans					/// arc sin transformation for prop/rate and SMR
				SQRttrans					/// square root tranformation for SMR 
				EXact						/// offers exact estimation (works currently for prop/rate for cross-sectional and smr for change data)
				PVal(numlist max=2 sort)	/// p-values used as basis to generate CIs
				BONferroni					/// adjust p-value to account for multiple testing
				YMIn(numlist max=1)			/// truncate values below specified min on Y axis
				YMAx(numlist max=1)			/// truncate values above specified mqax on Y axis
				SAVing(string asis)			/// save CIs to a new file 
				FIGure(str asis) 			///	allows figure options			
				]          
				
		quietly {
			gettoken estype anything : anything, parse(" ")
			local lcmd = length("`estype'")
			if !inlist("`estype'", substr("smr", 1, max(3,`lcmd')), substr("prop", 1, max(4,`lcmd')), substr("rate", 1, max(4,`lcmd')), substr("mean", 1, max(4,`lcmd'))) {
				di as err `"unknown subcommand of {bf:funnelinst}: `estype'"'
				exit 198
			}
			
			tokenize `anything'
			local varcnt : word count `anything'

			if !inlist(`varcnt', 2, 4) {	
				noi di as err "either two or four variables must be specified"
				exit 198
			}
			
			if `varcnt' == 2 {						
				local num `1'
				local den `2'
				confirm numeric variable `num'
				confirm numeric variable `den'
			}
			if `varcnt' == 4 {						
				local num1 `1'
				local den1 `2'
				local num2 `3'
				local den2 `4'				
				
				confirm numeric variable `num1'
				confirm numeric variable `den1'
				confirm numeric variable `num2'
				confirm numeric variable `den2'				
			}			
			
			preserve
			marksample touse
			keep if `touse'
			
			// return _N to the original _N in case funnelinst has been run previously 
			count
			local cnt = r(N)
			sum `num'
			local nobs = r(N)
			
			if `nobs' < `cnt' {
				local nobs = `nobs' + 1
				drop in `nobs' / `cnt'
			}
			
			if ("`ypercent'" != "") & ("`ratedenom'" != "") {
				noi di as err "ypercent and ratedenom cannot be specified together"
				exit 198
			}
			if ("`logtrans'" != "") & ("`arcsintrans'" != "") {
				noi di as err "logtrans and arcsintrans cannot be specified together"
				exit 198
			}	
			if ("`logtrans'" != "") & ("`sqrttrans'" != "") {
				noi di as err "logtrans and sqrttrans cannot be specified together"
				exit 198
			}	

			// Bonferroni adjustment
			if ("`bonferroni'" != "") { 
				local pval = (0.05 / `nobs')
				local pval `pval' 0.025
			}

			// default p-values			
			if ("`pval'" == "") & ("`bonferroni'" == "") {
				local pval 0.001 0.025
			}
			local pcnt : word count `pval'				
			
			************
			// tempvars 
			************
			* variables used in every case
			tempvar rho y varY z zwins rhopoints rhopoints2 varplot msum b1a1 b2a2  ///
				y1 y2 se se1 se2 y_SE2 one_se2 w w2 n1 n2 pibar o1 e1 o2 e2 ///
				meanSMR g qbinom qpois c x

			forval i = 1/`pcnt' { 
				tempvar ll`i' ul`i' 
			} 
			
			*********************
			// Setting targets 
			*********************
			// If target(s) are specified
			if ("`target'" != "") {
				local tarcnt: word count `target'
				// when a range is specified
				if `tarcnt' > 1 {
					// extract lower and upper range values
					local range1: word 1 of `target'
					local range2: word 2 of `target'
				} //  end range specified
			} // end target specified
					
			if inlist("`estype'", substr("prop", 1, max(4,`lcmd')), substr("rate", 1, max(4,`lcmd'))) {
				if (`varcnt' == 2) {	
					if ("`target'" == "") | ("`range1'" != "") {
						sum `num', meanonly
						local maxnum = r(sum)
						sum `den', meanonly
						local maxden = r(sum)
						local target = (`maxnum' / `maxden')
					} // end no target
				}
				if (`varcnt' == 4) {					
					if inlist("`estype'", substr("prop", 1, max(4,`lcmd')), substr("rate", 1, max(4,`lcmd'))) {
						// diff
						if ("`chtype'" == "diff") | ("`chtype'" == "") {
							if ("`target'" == "") | ("`range1'" != "") {							
								sum `num1', meanonly
								local maxnum1 = r(sum)
								sum `den1', meanonly
								local maxden1 = r(sum)
								sum `num2', meanonly
								local maxnum2 = r(sum)
								sum `den2', meanonly
								local maxden2 = r(sum)									
								local target = (`maxnum2' / `maxden2') - (`maxnum1' / `maxden1')
							} // end no target
						}
						// ratio
						if ("`chtype'" == "ratio") {
							if ("`target'" == "") | ("`range1'" != "") {
								sum `num1', meanonly
								local maxnum1 = r(sum)
								sum `den1', meanonly
								local maxden1 = r(sum)
								sum `num2', meanonly
								local maxnum2 = r(sum)
								sum `den2', meanonly
								local maxden2 = r(sum)														
								local target = (`maxnum2' / `maxden2') / (`maxnum1' / `maxden1')				
							} // end no target
						}
						// or
						if ("`chtype'" == "or") {
							if ("`target'" == "") | ("`range1'" != "") {							
								gen `b1a1' = `den1' - `num1'
								sum `b1a1', meanonly
								local maxb1a1 = r(sum)
								gen `b2a2' = `den2' - `num2'									
								sum `b2a2', meanonly
								local maxb2a2 = r(sum)
								sum `num1', meanonly
								local maxnum1 = r(sum)
								sum `num2', meanonly
								local maxnum2 = r(sum)									
								local target = (`maxnum2' / `maxb2a2') / (`maxnum1' / `maxb1a1')
							} // end no target
						} // end chtype = or
					} // end inlist prop/rate
				} // end change prop/rate	
			} // end target prop/rate

			if inlist("`estype'", substr("smr", 1, max(3,`lcmd'))) {
				if (`varcnt' == 2) {	
					if ("`target'" == "") | ("`range1'" != "") {						
						sum `num', meanonly
						local maxnum = r(sum)
						sum `den', meanonly
						local maxden = r(sum)
						local target = (`maxnum' / `maxden')
					} // end no target
				} // end no change for smr
				if (`varcnt' == 4) {						
					if ("`target'" == "") | ("`range1'" != "") {						
						sum `num1', meanonly
						local maxnum1 = r(sum)
						sum `den1', meanonly
						local maxden1 = r(sum)
						sum `num2', meanonly
						local maxnum2 = r(sum)
						sum `den2', meanonly
						local maxden2 = r(sum)														
						local target = (`maxnum2' / `maxden2') / (`maxnum1' / `maxden1')				
					} // end no target
				} // end change for smr
			} // end target smr 
			
			if inlist("`estype'", substr("mean", 1, max(4,`lcmd'))) {
				if (`varcnt' == 2) {	
					gen `rho' = 1 / `den'^2
					gen `y' = `num' 				
					if ("`target'" == "") | ("`range1'" != "") {						
						sum `rho', meanonly	
						local rhosum = r(sum)
						gen `msum' = `y' / `den'^2
						sum `msum', meanonly
						local maxsum = r(sum)
						local target = (`maxsum' / `rhosum')
					} // end no target
				} // end mean no change

				if (`varcnt' == 4) {					
					gen `y1' = `num1'
					gen `y2' = `num2'
					gen `se1' = `den1'
					gen `se2' = `den2'
					gen `y' = `y2' - `y1'
					gen `se' = sqrt(`se1'^2 + `se2'^2)
					gen `rho' = 1 / `se'^2					
					
					if ("`target'" == "") | ("`range1'" != "") {						
						gen `y_SE2' = `y' / `se'^2
						sum `y_SE2', meanonly
						local y_SE2sum = r(sum)
						gen `one_se2' = 1 / `se'^2
						sum `one_se2', meanonly
						local one_se2sum = r(sum)
						local target = (`y_SE2sum' / `one_se2sum')
					} // end no target	
				} // end mean with change
			} // end target mean	
	
			*****************************************************************
			// generate Y and varY depending on datatype and transformation
			*****************************************************************
			if inlist("`estype'", substr("prop", 1, max(4,`lcmd')), substr("rate", 1, max(4,`lcmd'))) {
				if (`varcnt' == 2) {	
					gen `rho' = `den'
					if "`logtrans'" != "" {
						gen `y' = log((`num' + 0.5)/(`den' - `num' + 0.5)) // empirical logit
						gen `varY' = 1/(`target' * (1 - `target') * `rho')
					}
					if "`arcsintrans'" != "" {				
						gen `y' = asin(sqrt(`num'/`den'))
						gen `varY' = 1/(4 * `rho')
					}
					else if ("`logtrans'" == "") & ("`arcsintrans'" == "") {
						gen `y' = `num' / `den'
						gen `varY' = `target' * (1 - `target')/ `rho'
					} // end no logtrans or arcsintrans
				} // end no change 
				if (`varcnt' == 4) {					
					gen `y1' = `num1' / `den1'
					gen `y2' = `num2' / `den2'
					gen `n1' = `den1'
					gen `n2' = `den2'
					if ("`chtype'" == "diff") | ("`chtype'" == "") {
						gen `y' = `y2' -`y1'
						gen `pibar' = (`y1' + `y2') / 2
						gen `varY' = ((`pibar' + `target' / 2) * (1 - `pibar' - `target' / 2))/ `n1' + ((`pibar' - `target' / 2) * (1 - `pibar' + `target' / 2)) / `n2'
						* set `rho' as rough sample size per group
						sum `pibar', meanonly
						local mu_pibar = r(mean)
						gen `rho' = 2 * `mu_pibar' * (1 - `mu_pibar') / `varY'
					} // end chtype "diff"	
					if ("`chtype'" == "ratio") {
						* work on log scale
						local logtrans logtrans
						gen `y' = log(((`num2' + 0.5) / (`n2' + 0.5)) / ((`num1' + 0.5) / (`n1' + 0.5)))
						gen `pibar' = sqrt(`y1' * `y2')
						gen `varY' = (sqrt(`target') - `pibar') / (`pibar' * `n1') + (sqrt(1 / `target') - `pibar') / (`pibar' * `n2')
						* set `rho' as rough sample size per group
						sum `pibar', meanonly
						local mu_pibar = r(mean)
						local g = (sqrt(`target') + sqrt(1 / `target') - 2 * `mu_pibar') / `mu_pibar'
						gen `rho' = `g' / `varY'
						local target = log(`target')						
					} // end chtype "ratio"
					
					if ("`chtype'" == "or") {	
						* work on log scale
						local logtrans logtrans
						local target = log(`target')
						gen `y' = log(((`num2' + 0.5) / (`n2' - `num2' + 0.5)) / ((`num1' + 0.5) / (`n1' - `num1' + 0.5)))
						gen `pibar' = (`y1' + `y2') / 2
						gen `varY' = 1 / (`num1' + 0.5) + 1 / (`n1' - `num1' + 0.5) + 1 / (`num2' + 0.5) + 1 / (`n2' - `num2' + 0.5)
						* set `rho' as rough sample size per group
						sum `pibar', meanonly
						local mu_pibar = r(mean)
						gen `rho' = 2 / (`varY' * `mu_pibar' * (1 - `mu_pibar'))
					} // end chtype "or"
				} // end change
			} // end `y' and `varY' for prop/rate
		
			if inlist("`estype'", substr("smr", 1, max(3,`lcmd'))) {
				if (`varcnt' == 2) {					
					gen `rho' = `den'				
					if "`logtrans'" != "" {
						gen `c' = min(0.5, `den'/2)
						gen `y' = log((`num' + `c')/`den')
						gen `varY' = `target' / `rho' 				
					}
					if "`sqrttrans'" != "" {
						gen `y' = sqrt(`num' / `den')
						gen `varY' = `target'/(4 * `rho')
					}	
					else if ("`logtrans'" == "") & ("`sqrttrans'" == "") {	
						gen `y' = `num' / `den'
						gen `varY' = `target' / `rho'
					} // end no logtrans or sqrttrans
				} // end no change
				if (`varcnt' == 4) {					
					* work on log scale
					local logtrans logtrans
					gen `o1' = `num1'
					gen `e1' = `den1'
					gen `o2' = `num2'
					gen `e2' = `den2'
					replace `o1' = (`o2' / 10) if `o1' == 0
					replace `o2' = (`o1' / 10) if `o2' == 0
					gen `y' = log((`o2' / `e2') / (`o1' / `e1'))
					gen `meanSMR' = (`o1' + `o2') / (sqrt(`target') * `e2' + `e1' / sqrt(`target'))
					sum `meanSMR', meanonly
					local mu_meanSMR = r(mean)
					gen `varY' = (1 / (sqrt(`target') * `e2') + 1 / (`e1' / sqrt(`target'))) / `meanSMR'
					gen `g' = (sqrt(`target') + 1 / sqrt(`target')) / `mu_meanSMR'
					local target = log(`target')					
					gen `rho' = `g' / `varY'
				} // end change smr	
			} // end smr					
				
			if inlist("`estype'", substr("mean", 1, max(4,`lcmd'))) {
				// All other variables are created under "target" block above
				gen `varY' = 1 / `rho'
			} // end "mean"
			
		
			********************
			// naive Z scores
			********************
			gen `z' = (`y' - `target')/sqrt(`varY')

			****************************************************************************
			// compute phi (the dispersion %) and tau (when overdispersion is additive)
			****************************************************************************
			if ("`overdisp'" != "") {
				
				*********************
				// Winsorize Z scores
				*********************
				if `winsor' >= 50 {
					noi di as err "winsor(#) must be a value less that 50"
					exit 198					
				}
				
				gen `zwins' = .
				
				_winsor , z(`z') zwins(`zwins') winsor(`winsor') nobs(`nobs')
				
				sum `zwins'
				local phi = r(Var)
				* "phisig" 
				if `phi' < 1 + 2 * sqrt(2/`nobs') {
					local phi = 1
				}
				local phipct = round(100*(sqrt(`phi')-1),1)
			} // end phi
			
			if ("`overdisp'" == "add") {	
				local q = `phi' * `nobs'
				gen `w' = 1/`varY'
				sum `w'
				local wsum = r(sum)
				gen `w2' = `w'^2
				sum `w2'
				local wsum2 = r(sum)
				local a = `wsum2' / `wsum'
				local denom = `wsum' - `a'
				local tau = sqrt((`q'-(`nobs'- 1)) / `denom')
				local tau2 = `tau'^2
			} // end add
			
			**********************************************
			// generate CI variables (rhopoints, varplot)
			**********************************************
			* check that Npoints are <= than current obs before setting obs larger
			if `nobs' < `npoints' {
				set obs `npoints'
			}	

			if ("`xrangehigh'" == "") {
				sum `rho', meanonly
				local xrangehigh = ceil(r(max) * 1.01)				
			}
			
			local xrangelow = 0
			gen double `rhopoints' = 0
			forvalues i = 1/`npoints' {
				replace `rhopoints' = round(`xrangelow' + (`i' * (`xrangehigh' - `xrangelow')) /  `npoints', .1) in `i'
			}
			replace `rhopoints' = . if `rhopoints'==0
			
			// prop and rate
			if inlist("`estype'", substr("prop", 1, max(4,`lcmd')), substr("rate", 1, max(4,`lcmd'))) {
				if (`varcnt' == 2) {					
					if ("`logtrans'" != "") {
						gen `varplot' = 1/(`rhopoints' * `target' * (1 - `target'))
						local target = log(`target'/(1 - `target'))
					} // end logtrans
					if "`arcsintrans'" != "" {	
						gen `varplot' = 1/(4 * `rhopoints')
						local target = asin(sqrt(`target'))
					}
					else if ("`logtrans'" == "") & ("`arcsintrans'" == "") {
						gen `varplot' = `target' * (1 - `target')/ `rhopoints'
					} // end not logtrans or arcsintrans
				} // end no change prop/rate
				if (`varcnt' == 4) {					
					if ("`chtype'" == "diff") | ("`chtype'" == "") {					
						gen `varplot' =	2 * `mu_pibar' * (1 - `mu_pibar') / `rhopoints'
					} // end diff
					if ("`chtype'" == "ratio") {
						local logtrans logtrans
						gen `varplot' = `g' / `rhopoints'
					} // end ratio
					if ("`chtype'" == "or") {
						local logtrans logtrans
						gen `varplot' = 2 / (`rhopoints' * `mu_pibar' * (1 - `mu_pibar'))
					} // end or
				} // end change prop/rate
			} // prop/rate
			
			// smr
			if inlist("`estype'", substr("smr", 1, max(3,`lcmd'))) {
				if (`varcnt' == 2) {					
					if ("`logtrans'" != "") {
						gen `varplot' = `target' / `rhopoints'
						local target = log(`target')
					}
					if ("`sqrttrans'" != "") {						
						gen `varplot' = `target' / (4 * `rhopoints') // ok for target == 1!!!
						local target = sqrt(`target')
					}
					else if ("`logtrans'" == "") & ("`sqrttrans'" == "") {
						gen `varplot' = `target' / `rhopoints'
					}
				} // end no change
				if (`varcnt' == 4) {					
					local logtrans logtrans				
					gen `varplot' = `g' / `rhopoints'
				} // end change
			} // end smr
			
			// mean
			if inlist("`estype'", substr("mean", 1, max(4,`lcmd'))) {
				gen `varplot' = 1 / `rhopoints'
			} // end mean	

			****************************************************
			// if overdisp is null or additive (random-effects)
			****************************************************
			if ("`overdisp'" != "add") {				
				local tau2 = 0 
			}
			local i = 1
			foreach p in `pval' {
				gen `ll`i'' = `target' + invnormal(`p') * sqrt(`varplot' + `tau2')
				gen `ul`i'' = `target' + invnormal(1-`p') * sqrt(`varplot' + `tau2')
				local i = `i' + 1
			}
			
			**********************************
			// if target is a range
			**********************************			
			if ("`range1'" != "")  {
				local i = 1
				foreach p in `pval' {
					replace `ll`i'' = `range1' + invnormal(`p') * sqrt(`varplot')
					replace `ul`i'' = `range2' + invnormal(1-`p') * sqrt(`varplot')
					local i = `i' + 1
				}
				if ("`logtrans'" != "") {			
					forvalue i = 1/`pcnt' {				
						replace `ll`i'' = log(`ll`i'')
						replace `ul`i'' = log(`ul`i'')				
					}				
				}
			}	

			*********************************
			// if overdisp is multiplicative
			*********************************
			if ("`overdisp'" == "mult") {
				forvalue i = 1/`pcnt' {
					replace `ll`i'' = `target' + (`ll`i'' - `target') * sqrt(`phi')				
					replace `ul`i'' = `target' + (`ul`i'' - `target') * sqrt(`phi')				
				}
			}
				
			************************************
			// Back transform to original scale
			************************************
			if ("`logtrans'" != "") {
				replace `y' = exp(`y') if `y' !=.
				local target = exp(`target')
				forvalue i = 1/`pcnt' {				
					replace `ll`i'' = exp(`ll`i'')
					replace `ul`i'' = exp(`ul`i'')				
				}
			}
		
			if ("`arcsintrans'" != "") {
				replace `y' = sin(`y')^2
				local target = sin(`target')^2
				forvalue i = 1/`pcnt' {
					replace `ll`i'' = sin(max(-_pi/2,`ll`i''))^2					
					replace `ul`i'' = sin(min(_pi/2,`ul`i''))^2					
				}	
			}
			if ("`sqrttrans'" != "") {
				replace `y' = `y'^2
				local target = `target'^2
				forvalue i = 1/`pcnt' {
					replace `ll`i'' = max(0, `ll`i'')^2
					replace `ul`i'' = `ul`i''^2
				}
			}
			
			************************************************
			// Exact CIs for prop, rate and smr subcommands
			************************************************
			if !inlist("`estype'", substr("prop", 1, max(4,`lcmd')), substr("rate", 1, max(4,`lcmd')), substr("smr", 1, max(3,`lcmd'))) & (`varcnt' == 2) {
				if ("`exact'" != "") {
					noi di as err " 'exact' may only be specified with 'prop', 'rate' or 'smr' subcommands for cross-sectional analysis"
					exit 198
				}
			}
			
			if !inlist("`estype'", substr("smr", 1, max(3,`lcmd'))) & (`varcnt' == 4) {
				if ("`exact'" != "") {
					noi di as err " 'exact' may only be specified with the 'smr' subcommand for longitudinal (change over two periods) analysis"
					exit 198
				}
			}
			
			// Exact for "prop" and "rate" for cross-sectional analysis
			if inlist("`estype'", substr("prop", 1, max(4,`lcmd')), substr("rate", 1, max(4,`lcmd'))) {
				if ("`exact'" != "") & (`varcnt' == 2) {
					replace `rhopoints' = `rhopoints' + 1
					levelsof `rhopoints', local(points)

					// first loop is for LCLs
					local i = 1
					foreach p in `pval' {
						gen `qbinom' = .	
						foreach ii of local points {
							mata : st_numscalar("k", invcdfbinomial(`ii', `p', `target'))
							replace `qbinom' = scalar(k) if `rhopoints' == `ii'							
						}
						gen `c' = (`p' - binomial(`rhopoints', `qbinom'-1, `target')) / binomialp(`rhopoints', `qbinom', `target') 
						gen `x' = `qbinom' - 0.5 + `c'
						replace `x' = `rhopoints' if `x' > `rhopoints'
						replace `ll`i'' = `x' / `rhopoints'
						drop `qbinom' `c' `x'
						local i = `i' + 1
					} // end pval
					
					// second loop is for UCLs
					local i = 1
					foreach p in `pval' {
						gen `qbinom' = .	
						foreach ii of local points {
							mata : st_numscalar("k", invcdfbinomial(`ii', 1-`p', `target'))
							replace `qbinom' = scalar(k) if `rhopoints' == `ii'							
						}
						gen `c' = ((1-`p') - binomial(`rhopoints', `qbinom'-1, `target')) / binomialp(`rhopoints', `qbinom', `target') 
						gen `x' = `qbinom' - 0.5 + `c'
						replace `x' = `rhopoints' if `x' > `rhopoints'
						replace `ul`i'' = `x' / `rhopoints'
						drop `qbinom' `c' `x'
						local i = `i' + 1
					} // end pval					
				} // end exact
			} // end prop/rate
			
			// Exact for "smr" cross-sectional
			if inlist("`estype'", substr("smr", 1, max(3,`lcmd'))) {
				if ("`exact'" != "") & (`varcnt' == 2) {	
					
					// first loop is for LCLs
					local i = 1
					foreach p in `pval' {
						gen `qpois' = .	
						forvalues ii = 1/`npoints' {
							local r = `rhopoints'[`ii']
							mata : st_numscalar("k", invcdfpoisson(`r' * `target', `p'))
							replace `qpois' = scalar(k) in `ii'
						}
						// Hayley's method
						gen `c' = (`p' - poisson(`rhopoints' * `target', `qpois' - 1))  / poissonp(`rhopoints' * `target', `qpois') if `qpois' != 0 						
						replace `c' = (`p' - 0)  / poissonp(`rhopoints' * `target', `qpois') if `qpois' == 0
						gen `x' = `qpois' - 0.5 + `c'
						replace `ll`i'' = `x' / `rhopoints'
						drop `qpois' `c' `x'
						local i = `i' + 1
					} // end pval
					
					// second loop is for UCLs	
					local i = 1
					foreach p in `pval' {
						gen `qpois' = .	
						forvalues ii = 1/`npoints' {
							local r = `rhopoints'[`ii']
							mata : st_numscalar("k", invcdfpoisson(`r' * `target', 1 - `p'))
							replace `qpois' = scalar(k) in `ii'
						}
						// Hayley's method
						gen `c' = ((1 - `p') - poisson(`rhopoints' * `target', `qpois' - 1))  / poissonp(`rhopoints' * `target', `qpois') if `qpois' != 0 						
						replace `c' = ((1 - `p') - 0)  / poissonp(`rhopoints' * `target', `qpois') if `qpois' == 0
						gen `x' = `qpois' - 0.5 + `c'
						replace `ul`i'' = `x' / `rhopoints'
						drop `qpois' `c' `x'
						local i = `i' + 1
					} // end pval	
				}	// end if
			} // // end smr cross-sectional					
			
			// *** Exact SMR ratio (for change) *** //
			if inlist("`estype'", substr("smr", 1, max(3,`lcmd'))) {
				if ("`exact'" != "") & (`varcnt' == 4) {
					* work out conditional limits and then transform back
					local target2 = `target' / (1 + `target')
					* half the sample size of Binomial (O1+O2)/2
					replace `rhopoints' = round(2 * `rhopoints') / 2
					gen `rhopoints2' = 2 * `rhopoints'
					levelsof `rhopoints2', local(points)
					
					// first loop is for LCLs
					local i = 1
					foreach p in `pval' {
						gen `qbinom' = .	
						foreach ii of local points {
							mata : st_numscalar("k", invcdfbinomial(`ii', `p', `target2'))
							replace `qbinom' = scalar(k) if `rhopoints2' == `ii'							
						}
						gen `c' = (`p' - binomial(`rhopoints2', `qbinom'-1, `target2')) / binomialp(`rhopoints2', `qbinom', `target2') 			
						gen `x' = `qbinom' - 0.5 + `c'
						replace `x' = `rhopoints2' if `x' > `rhopoints2'
						replace `ll`i'' = `x' / (`rhopoints2' - `x')	
						drop `qbinom' `c' `x'
						local i = `i' + 1
					} // end pval
					
					// second loop is for UCLs
					local i = 1
					foreach p in `pval' {
						gen `qbinom' = .	
						foreach ii of local points {
							mata : st_numscalar("k", invcdfbinomial(`ii', 1-`p', `target2'))
							replace `qbinom' = scalar(k) if `rhopoints2' == `ii'							
						}
						gen `c' = (1-`p' - binomial(`rhopoints2', `qbinom'-1, `target2')) / binomialp(`rhopoints2', `qbinom', `target2') 			
						gen `x' = `qbinom' - 0.5 + `c'
						replace `x' = `rhopoints2' if `x' > `rhopoints2'
						replace `ul`i'' = `x' / (`rhopoints2' - `x')	
						drop `qbinom' `c' `x'
						local i = `i' + 1
					} // end pval					
				} // end exact for change
			} // end SMR 
			
			******************************
			//			figure			//	 
			******************************
			if ("`overdisp'" == "mult") {
					local note1 "Overdispersion: `phipct'%"
					local note2 "Winsorized: `winsor'%"
			}

			if ("`overdisp'" == "add") {
					if ("`ypercent'" != "") {				
						local tau = `tau' * 100
					}
					if ("`ratedenom'" != "") {				
						local tau = `tau' * `ratedenom'
					}
					
					local rtau: display %-06.4f `tau'
					local note1 "Random Effects SD: `rtau'"
					local note2 "Winsorized: `winsor'%"
			}
				
			if ("`ypercent'" != "") {
				if !inlist("`estype'", substr("prop", 1, max(4,`lcmd')), substr("smr", 1, max(3,`lcmd'))) {
					noi di as err " 'ypercent' may only be specified with 'prop' or 'smr' subcommands"
					exit 198
				}					
				else {
					forvalue i = 1/`pcnt' {
						replace `ll`i'' = `ll`i'' * 100
						replace `ul`i'' = `ul`i'' * 100	
					}
				local target = `target' * 100
				replace `y' = `y' * 100
				}
			} // end ypercent 
			
			if ("`ratedenom'" != "") {
				if !inlist("`estype'", substr("rate", 1, max(4,`lcmd'))) {
					noi di as err " 'ratedenom()' may only be specified with the 'rate' subcommand"
					exit 198
				}	
				else {
					forvalue i = 1/`pcnt' {
						replace `ll`i'' = `ll`i'' * `ratedenom'
						replace `ul`i'' = `ul`i'' * `ratedenom'	
					}
				}	
				local target = `target' * `ratedenom'
				replace `rhopoints' = `rhopoints' / `ratedenom'
				replace `rho' = `rho' / `ratedenom' 
				replace `y' = `y' * `ratedenom'				
			} // end ratedenom	
		
			// display range values
			if ("`range1'" != "")  {
				if ("`ypercent'" != "") {
					local range1 = `range1' * 100
					local range2 = `range2' * 100
				}
				if ("`ratedenom'" != "") {
					local range1 = `range1' * `ratedenom'
					local range2 = `range2' * `ratedenom'
				}
				local target `range1' `range2'
			} // end ranges
			
			// truncate values at specified min on Y axis
			if ("`ymin'" !="") {
				forvalue i = 1/`pcnt' {
					replace `ll`i'' = . if `ll`i'' < `ymin'
				}	
				replace `y' = . if `y' < `ymin'
			}
			// truncate values at specified max on Y axis
			if ("`ymax'" !="") {
				forvalue i = 1/`pcnt' {
					replace `ul`i'' = . if `ul`i'' > `ymax'
				}	
				replace `y' = . if `y' > `ymax'
			}
			
			// default titles
			if inlist("`estype'", substr("smr", 1, max(3,`lcmd'))) {
				local ytitle ytitle(SMR)
				local xtitle xtitle(Expected)
			}
			if inlist("`estype'", substr("prop", 1, max(4,`lcmd'))) {
				local ytitle ytitle(Proportion)
				local xtitle xtitle(N)
			}
			if inlist("`estype'", substr("rate", 1, max(4,`lcmd'))) {
				local ytitle ytitle(Rate)
				local xtitle xtitle(N)
			}
			if inlist("`estype'", substr("mean", 1, max(4,`lcmd'))) {
				local ytitle ytitle(Mean)
				local xtitle xtitle(Precision)
			}
			
			// legend values 
			local i = 1
			foreach p in `pval' {
				local legci`i' = (1 - 2 * `p') * 100
				local i = `i' + 1
			}
			if ("`bonferroni'" == "") { 
				local legci1: display %2.1f `legci1'
				local legci2: display %2.1f `legci2'
			}
			else {
				local legci1: display %2.0f 95
				local legci2: display %2.0f 95
				local bon " (Bonf. Adj)"
			}
			
		} // end quietly
	
			// generate figure if 2 p-values are specified, else generate figure if 1 p-value is specified
			if (`pcnt' == 2) {
				twoway(line `ll1' `ul1' `rhopoints', sort lcolor(blue blue)) ///
					(line `ll2' `ul2' `rhopoints', sort lcolor(green green)) ///
					(scatter `y' `rho', mcolor(red) yline(`target', lpattern(shortdash) lcolor(black) lwidth(medthick)) ///
					note("`note1'" "`note2'") legend(order(1 "`legci1'% CI `bon'" 3 "`legci2'% CI") pos(2) col(1) ring(0)) `ytitle' `xtitle' `figure')
			}		
			else {
				twoway(line `ll1' `ul1' `rhopoints' , sort lcolor(blue blue)) ///
					(scatter `y' `rho', mcolor(red) yline(`target', lpattern(shortdash) lcolor(black) lwidth(medthick)) ///
					note("`note1'" "`note2'") legend(order(1 "`legci1'% CI") pos(2) col(1) ring(0)) `ytitle' `xtitle' `figure')
			}
	
			******************
			// saved results
			******************
			return scalar N = `nobs'
			if ("`range1'" != "")  {
				return scalar target1 = `range1'
				return scalar target2 = `range2'
			}
			else if ("`range1'" == "")  {
				return scalar target = `target'
			}	
			if ("`overdisp'" != "") {
				return scalar phi = `phi'
			}
			if ("`overdisp'" == "add") {
				return scalar tau = `rtau'
			}
			return scalar winsor = `winsor'
			
			********************
			// save CIs to file
			********************
			if `"`saving'"' != "" {
				forvalue i = 1/`pcnt' {
					qui gen ll`i' = `ll`i'' 
					qui gen ul`i' = `ul`i''
				
				local ci "`ci' ll`i' ul`i'"
				}
				qui keep `ci' 
				qui keep in 1 / `npoints'
				save `saving'
			} // end saving				

end			
	

capture program drop _winsor
program _winsor, rclass
version 11.0
		
	syntax [varlist(default=none)] [, z(varname) zwins(varname) WINsor(numlist max=1) nobs(numlist max=1)]

		local p = (`winsor' / 100)
		local h = int(`p' * `nobs')
		sort `z'

		* upper range
		local up = `nobs' - `h'
		local uz = `z'[`up']

		* lower range
		local low = `h' + 1
		local lz = `z'[`low']
				
		qui replace `zwins' = cond(`z' < `lz', `lz', cond(`z' > `uz', `uz', `z'))
	
end	

version 11.0
mata :

function invcdfbinomial(real scalar n, real scalar x, real scalar p)

{
    real scalar mu
    real scalar sigma
    real scalar gamma
    real scalar z
    real scalar k
	
    if ( hasmissing((n,x,p)) )
        return(.)
    
    if (n < 0)
        _error(3300)
    
    if ( (x<0)|(x>1) )
        _error(3300)
    
    if ( (p<0)|(p>1) )
        _error(3300)
    
    mu    = n*p
    sigma = sqrt(n*p*(1-p))
    gamma = ((1-p)-p)/sigma
    
    z = invnormal(x)
    k  = floor(mu + sigma * (z + gamma*(z*z-1)/6) + 0.5)
    k  = min((k,n))
    
    if (binomial(n,k,p) >= x)
        while (binomial(n,k-1,p) > x)
            k--
    else
        while (binomial(n,k,p) <= x)
            k++
	
    return(k)
}

end

version 11.0

mata :

real scalar invcdfpoisson(real scalar m, real scalar x)

{
    real scalar mu
    real scalar sigma
    real scalar gamma
    real scalar z
    real scalar k
    
    
    if ( hasmissing((m,x)) )
        return(.)
        
    if (m < 0)
        _error(3300)
    
    if ( (x<0)|(x>1) )
        _error(3300)
    
    if (m == 0)
        return(0)
    
    if (x == 0)
        return(0)
    
    if (x == 1)
        return(.)
    
    mu    = m
    sigma = sqrt(m)
    gamma = 1/sigma
    
    z = invnormal(x)
    k  = round(mu + sigma * (z + gamma*(z*z-1)/6) + 0.5)
    
    if (poisson(m,k) >= x)
        while ( k & (poisson(m,k-1)>x) )
            k--
    else
        while (poisson(m,k) <= x)
            k++

    return(k)
}

end