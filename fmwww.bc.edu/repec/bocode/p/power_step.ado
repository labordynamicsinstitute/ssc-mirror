*! 1.1.0 Ariel Linden 09Sep2025	// added onesided and format options; renamed results headings to "effect" and "power"
*! 1.0.0 Ariel Linden 05Feb2025

program define power_step, rclass
        version 11

    syntax , NTime(integer) TRPeriod(integer) phi(real) [ Alpha(real 0.05) ONESIDed FORmat(string) ]
	
		tempname i11 i22 i12 tausq tau p
		scalar `i11' = `ntime' * (1.0 - `phi') * (1.0 - `phi')
		scalar `i22' = (`ntime'-`trperiod') * (1.0 - `phi') * (1.0 - `phi') + 1.0
		scalar `i12' = `i22'-`phi'
		scalar `tausq' = (`i11' * `i22' - `i12' * `i12') / (`i11' * (1 - `phi' * `phi'))
		scalar `tau' = sqrt(`tausq')
		
		if "`onesided'" == "" {
			local norm1 = invnorm(`alpha' / 2)
			local side Two-sided
		}
		else {
			local norm1 = invnorm(`alpha')
			local side One-sided
		}
		local norm2 = abs(`norm1')
		local plevel = `alpha' * 100
		
		local deltaMin = 0
		local deltaMax = 3
		local deltaInc = 0.25
		local numDelta = 1 + ceil((`deltaMax' - `deltaMin') / `deltaInc')

		// format the power values
		if "`format'" != "" { 
			confirm numeric format `format' 
		}
		else local format %6.3f
		
		di _n
		di as txt "Statistical Power Computation"
		di as txt "Step Intervention with AR(1) Error"
		di as txt "`side' test at `plevel'% level"
		di _n
		di as txt "Length of time series = " `ntime'
		di as txt "Observation number corresponding to the start of the Intervention = " `trperiod'
		di as txt "Lag-one autocorrelation coefficient, ø = " %4.2f `phi'		
		
		di _n
		di as txt "{ul:Effect}" "   " "{ul:Power}"
		forvalues i = 0(1)12 {
			local delta = `deltaMin' + `deltaInc' * `i'
			scalar `p'`i' = 1 + normal(`norm1' - `tau' * `delta') - normal(`norm2' - `tau' * `delta')
			return scalar p`i' = `p'`i'
			di _col(0) %3.2f `delta' _skip(4) `format' `p'`i'			
		} 
		
	
end		

