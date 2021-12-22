*! version 1.0  2021-10-25 Mark Chatfield

program define tolerancei, rclass
		version 9.0
        syntax anything, percentofpop(numlist max=1 >0 <100) [Confidence(numlist max=1 >0 <100) onesided Method(string asis)] 

		local p = `percentofpop'/100  
				
		tokenize `anything' 
		
		local N `1'
		local mean `2'
		local sd `3'		
		if "`sd'"=="" di as err "Syntax should be tolerance2i #N #Mean #SD, options"
		di " "
		di as txt "You specified: N = `N', mean = `mean', sd = `sd'"	
		
		if "`onesided'" == "onesided" {
		    
			if "`confidence'" == "" {
			*prediction interval  (Meeker eqn 4.7 with m=1, replacing alpha/2 with alpha)
			local k = invt((`N' - 1), 1 - (1 - `p')) * sqrt(1 + 1/`N')				
			di as txt _col(1) "One-sided `percentofpop'%-expectation tolerance intervals, or equivalently, one-sided `percentofpop'% prediction intervals are:"	
			local low = `mean' - `k' * `sd'
			local upp = `mean' + `k' * `sd'
			
			di as res _col(5) %9.0g `low' _c
			di as txt _col(15) "to +infinity  (lower bound = mean -"  _c
			di as res _col(50) %9.0g `k' _c
			di as txt _col(60) %9.0g  "× sd)"

			di as txt _col(5) "-infinity to "  _c			
			di as res _col(15) %9.0g `upp' _c
			di as txt _col(28) " (upper bound = mean +"  _c
			di as res _col(50) %9.0g `k' _c
			di as txt _col(60) %9.0g  "× sd)"
				
			return scalar k_lb = `k'
			return scalar k_ub = `k'
			return scalar upp = `upp'		
			return scalar low = `low' 			
			}
			
			else {
			*Meeker section sections 4.6.3, 4.4
			local zp = invnorm(`p')
			local df = `N'-1
			local np = -`zp'*sqrt(`N')
			local biggamma   = 1 - `confidence'/100
			local smallgamma = 1 - `biggamma'			
			local bigk   =  -invnt(`df',`np',`biggamma')   / sqrt(`N')
			local smallk =  -invnt(`df',`np',`smallgamma') / sqrt(`N')
			
			local low = `mean' + `smallk' * `sd'
			local upp = `mean' + `bigk' * `sd'
			
			di as txt _col(1) "One-sided `percentofpop'% tolerance intervals with `confidence'% confidence are:"  		
			di as res _col(5) %9.0g `low' _c
			di as txt _col(15) "to +infinity  (lower bound = mean +"  _c
			di as res _col(50) %9.0g `smallk' _c
			di as txt _col(60) %9.0g  "× sd)"

			di as txt _col(5) "-infinity to "  _c			
			di as res _col(15) %9.0g `upp' _c
			di as txt _col(28) " (upper bound = mean +"  _c
			di as res _col(50) %9.0g `bigk' _c
			di as txt _col(60) %9.0g  "× sd)"
			
			local twosidedconfidence = 100 - 2*(100-`confidence')
			if `twosidedconfidence' >=0 {
				di as txt _col(1) "[Extra] Two-sided `twosidedconfidence'% CI for the `percentofpop'th percentile: "
				di as res _col(5) %9.0g `low' _c
				di as txt _col(15) "to"  _c
				di as res _col(18) %9.0g `upp' _c
  			}
			
			return scalar k_ub = `bigk'			
			return scalar k_lb = `smallk'
			return scalar upp = `upp'		
			return scalar low = `low' 
			}
		}		
		
	else {	
        if "`confidence'" == "" {        
			*prediction interval  (Meeker eqn 4.7 with m=1)
			local k = invt((`N' - 1), 1 - (1 - `p')/2) * sqrt(1 + 1/`N')				
			di as txt _col(1) "`percentofpop'%-expectation tolerance interval, or equivalently, `percentofpop'% prediction interval:"			
		}
		else {
			*beta-gamma tolerance interval   [Peter Lachenbruch's tolerance.ado describes beta and gamma the wrong way around]		    
			local gamma = `confidence'/100		
			local k = invnorm(1 - (1 - `p')/2) * sqrt(1 + 1/`N') * sqrt((`N' - 1) / invchi2(`N' - 1,1 - `gamma') )  // Howe 1969 lambda_1
			if "`method'" != "howesimpler" local k = `k' * sqrt(1 + (`N' - 3 - invchi2(`N' - 1,1 - `gamma'))/2/(`N' + 1)^2)   //  Howe 1969 lambda_3
			if "`method'" == "howesimpler" local extra " [method(howesimpler)]"			
			di as txt _col(1) "`percentofpop'% tolerance interval with `confidence'% confidence`extra':"
		}
	
	local low = `mean' - `k' * `sd'
	local upp = `mean' + `k' * `sd'
	
	di as res _col(5) %9.0g `low' _c
	di as txt _col(16) "to"  _c
	di as res _col(19) %9.0g `upp'  _c
	di as txt _col(33) %9.0g "(i.e.  mean  ± "  _c
	di as res _col(45) %9.0g `k' _c
	di as txt _col(58) %9.0g  "× sd)" _c
		
	return scalar k = `k'
	return scalar upp = `upp'		
	return scalar low = `low' 
	}
di " "	
end
