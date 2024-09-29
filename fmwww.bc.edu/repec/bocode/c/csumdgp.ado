*! 1.0.0 Ariel Linden 16Sep2024

program define csumdgp, rclass byable(recall) 
        version 11
        syntax [, obs(integer 1000) mult(real 2) p0(real 0.05) ]
        drop _all
        set obs `obs'
        count
		local n = r(N)
		local o0 = `p0' / (1 - `p0')
		local o1 = `o0' * `mult'
		local p1 = `o1' / (1 + `o1')
		
		tempvar ysim w_t c_t
		gen `ysim' = rbinomial(1,	`p0')
		gen `w_t' = `ysim' * log(`p1' / `p0') + (1 - `ysim') * log((1 - `p1') / (1 - `p0'))
		gen `c_t' = 0
		
		if `mult' > 1 {
			replace `c_t' in 1 = max(0, `c_t'[1] + `w_t'[1])
			forvalues ii = 2/`n' {
				replace `c_t' in `ii' = max(0, `c_t'[`ii'-1] + `w_t'[`ii'])
			}	
		}
		summarize `c_t', meanonly
		return scalar max = r(max)
		
		else if `mult' < 1 {
			replace `c_t' in 1 = min(0, `c_t'[1] - `w_t'[1])
			forvalues ii = 2/`n' {
				qui replace `c_t' in `ii' = min(0, `c_t'[`ii'-1] - `w_t'[`ii'])		
			}
		}	
		summarize `c_t', meanonly
		return scalar min = r(min)

    end
	