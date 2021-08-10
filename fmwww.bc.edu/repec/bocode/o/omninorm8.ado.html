*! 2.0.0 30 August 2007 NJC 
*! 1.0.3 2328 cfb 
* omnibus normality test, Doornik and Hansen 1994
* http://ideas.uqam.ca/ideas/data/Papers/wuknucowp9604.html
* from normtest.ox
* 1.0.3: correct df to 2*k
program omninorm8, rclass
	version 8
	syntax varlist(ts) [if] [in] 

	quietly { 
		marksample touse
		count if `touse' 
		if r(N) == 0 error 2000 

		local N = r(N)
		local Nm1 = r(N) - 1
		local oneN = 1.0/`N'
		tempname corr evec eval norm std iota skew kurt vy vy2 vys ///
		kurt2 lvy vz newskew newkurt omni omnia
		local count: word count `varlist'
	// N01
		mat accum `corr' = `varlist' if `touse', noc d
		mat `corr' = `corr'/`Nm1'
		mat `corr' = corr(`corr') 
		mat symeigen `evec' `eval' = `corr'

		local C = colsof(`eval')
		forval j = 1/`C' {
			mat `eval'[1, `j'] =  cond(`eval'[1, `j'] > 1e-12, /// 
			1/sqrt(`eval'[1, `j']), 0)
		}
		
		foreach var of varlist `varlist' {
			tempvar sv
                	su `var' if `touse'
	                local den = sqrt(r(Var) * (r(N) - 1)/r(N)) 
                	gen `sv' = (`var' - r(mean))/`den'  
			local svl `svl' `sv'
		}
		mkmat `svl' if `touse', mat(`norm')
		mat `std' = `norm' * `evec' * diag(`eval') * `evec''
	// skew, kurt
		mat `skew' = `std' 
		mat `kurt' = `std' 
		local I = rowsof(`std') 
		local J = colsof(`std') 
		forval i = 1/`I' { 
			forval j = 1/`J' { 
				mat `skew'[`i', `j'] = `skew'[`i', `j']^3
				mat `kurt'[`i', `j'] = `kurt'[`i', `j']^4
			}
		}
		mat `iota' = J(1, `N', `oneN')
		mat `skew' = `iota' * `skew'
		mat `kurt' = `iota' * `kurt'
		mat `iota' = J(1, `C', 1)
	// skewsu
		local nsk = cond(`N' < 8, 8, `N')
		local nsk2 = `nsk'^2
		local beta = 3 * (`nsk2' + 27 * `nsk' - 70)/ ///
		((`nsk' - 2) * (`nsk' + 5)) * ((`nsk' + 1)/(`nsk' + 7)) * ///
		((`nsk' + 3)/(`nsk' + 9))
		local w2 = -1 + sqrt(2 * (`beta' - 1))
		local delta = 1 / sqrt(log(sqrt(`w2')))
		local alfa = sqrt(2/(`w2' - 1))
		mat `vy' = `skew' * ///
		sqrt((`nsk' + 1) * (`nsk' + 3)/(6 * (`nsk' - 2)))/`alfa'	
		mat `vy2' = `vy' 
		mat `vys' = `vy' 
		mat `lvy' = `vy' 
		forval j = 1/`J' { 
			mat `vy2'[1, `j'] = `vy2'[1, `j']^2
		}
		mat `vy2' = `vy2' + `iota'
		forval j = 1/`J' { 
			mat `vys'[1, `j'] = sqrt(`vy2'[1, `j']) 
		}
		mat `vys' = `vy' + `vys'
		forval j = 1/`J' { 
			mat `lvy'[1, `j'] = log(`vys'[1, `j']) 
		}
		mat `newskew' = `lvy' * `delta'
	// kurtgam
		local delta = ((`nsk' + 5)/(`nsk' - 3)) * ///
		((`nsk' + 7)/(`nsk' + 1))/(6 * (`nsk2' + 15 * `nsk' - 4))
		local a = (`nsk' - 2) * (`nsk2' + 27 * `nsk' - 70) * `delta'
	    	local c = (`nsk' - 7) * (`nsk2' + 2 * `nsk' - 5) * `delta'
		local k = (`nsk' * `nsk2' + 37 * `nsk2' + 11 * `nsk' - 313) * `delta'/2
		forval j = 1/`J' { 
			mat `vy2'[1, `j'] = (`skew'[1, `j'])^2  
		}
		mat `vz' = `c' * `vy2' + `a' * `iota'
		mat `kurt2' = (`kurt' - `iota' - `vy2') * `k' * 2
		mat `newkurt' = `kurt'
		forval j = 1/`C' { 
			mat `newkurt'[1, `j'] = (((`kurt2'[1, `j']/(2 * `vz'[1, `j']))^(1/3)) - ///
			1 + 1/(9 * `vz'[1, `j'])) * sqrt(9 * `vz'[1, `j'])
    		}
		mat `omni' = `newskew' * `newskew'' + `newkurt' * `newkurt''
   		mat `kurt' = `kurt' - 3 * `iota'
		mat `omnia' = `N'/6 * `skew' * `skew'' + `N'/24 * `kurt' * `kurt''
	}

	return scalar stat = `omni'[1, 1]
	return scalar statasy = `omnia'[1, 1]
	return scalar N = `N'
	return scalar k = `C'
	return scalar df = 2 * return(k)
	return scalar p = chiprob(return(df), return(stat))
	return scalar pasy = chiprob(return(df), return(statasy))

	di _n as txt "Omnibus normality statistic: " ///
	"{col 36}" as res %10.4f return(stat) ///
	as txt " Prob > chi2(" as res return(df) as txt ") = " as res %6.4f return(p)
	di as txt "Asymptotic statistic: "  ///
	"{col 36}" as res %10.4f return(statasy) as txt " Prob > chi2(" as res return(df) ///
	as txt ") = " as res %6.4f return(pasy)
end
