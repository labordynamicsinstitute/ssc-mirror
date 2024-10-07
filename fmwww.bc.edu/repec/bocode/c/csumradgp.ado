*! 1.0.0 Ariel Linden 27Sep2024

program define csumradgp, rclass
        version 11
        syntax [, obs(integer 1000) odds(real 2) riskscore(name)]

		clear
		svmat `riskscore'
		local p0 `riskscore'1
		

		tempvar ysim ws wf w_t c_t
		qui gen `ysim' = rbinomial(1,	`p0')
		qui gen `ws' = log(1/(1 + (`odds'- 1) * `p0'))
		qui gen `wf' = log(`odds' / (1 + (`odds' - 1) * `p0'))
		qui gen `w_t' = cond(`ysim',`wf',`ws')
		
		
				
		qui gen `c_t' = 0
		
		if `odds' > 1 {
			qui replace `c_t' in 1 = max(0, `c_t'[1] + `w_t'[1])
			forvalues ii = 2/`obs' {
				qui replace `c_t' in `ii' = max(0, `c_t'[`ii'-1] + `w_t'[`ii'])
			}
		}
		summarize `c_t', meanonly
		return scalar max = r(max)		
		
		else if `odds' < 1 {
			qui replace `c_t' in 1 = min(0, `c_t'[1] - `w_t'[1])
			forvalues ii = 2/`obs' {
				qui replace `c_t' in `ii' = min(0, `c_t'[`ii'-1] - `w_t'[`ii'])		
			}
		}
		qui summarize `c_t', meanonly
		return scalar min = r(min)		
		
end	