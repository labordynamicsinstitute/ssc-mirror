*! 1.0.0 Ariel Linden 12Sep2025

program define power_arima_itsa, rclass
    version 11
    syntax , Ntime(integer)		///
		EFFect(numlist)			///
        [ TRperiod(string) 		///
		TYPE(string)			///	
		ACorr(real 0) 			///
		ALPha(real 0.05) 		///
		ONESIDed 				///
		KNOWnmean 				///
		RAW 					///
		FORmat(string) ]


	* set the default treatment period to the halfway point in the time series	
	if "`trperiod'" == "" {
		local trperiod = ceil(`ntime' / 2)
	}
	
	* set default type to "step"
	if "`type'" == "" {
		local type step
	}

	local first = 1   // flag for first effect (to create matrix)

	tempname sigma_stat effect_raw i11 i12 i22 se_effect det lambda zcrit power results
	
	foreach e of local effect {

        * stationary SD (sigma)
        scalar `sigma_stat' = 1/sqrt(1 - `acorr'^2)

        * effect scaling
        if "`raw'" != "" {
            scalar `effect_raw' = `e'
        }
        else {
            scalar `effect_raw' = `e' * `sigma_stat'
        }

        * information matrix entries for AR1 (from Table 1)
        scalar `i11' = `ntime' * (1 - `acorr')^2
        scalar `i12' = 0
        scalar `i22' = 0

        if "`type'" == "step" {
            scalar `i12' = (`ntime' - `trperiod') * (1 - `acorr')^2 + 1 - `acorr'
            scalar `i22' = (`ntime' - `trperiod') * (1 - `acorr')^2 + 1
        }
        else if "`type'" == "pulse" {
            scalar `i12' = 1 - `acorr'^2
            scalar `i22' = 1 - `acorr'^2
        }
        else if "`type'" == "ramp" {
            scalar `i12' = (1 + `ntime' - `trperiod') * (1 - `acorr') * (2 + `ntime' - `trperiod' - (`ntime' - `trperiod')*`acorr') / 2
            scalar `i22' = (1 + `ntime' - `trperiod') * ///
                (6 + 7*`ntime' + 2*`ntime'^2 - 7*`trperiod' - 4*`ntime'*`trperiod' + 2*`trperiod'^2 ///
                 - 8*`ntime'*`acorr' - 4*`ntime'^2*`acorr' + 8*`trperiod'*`acorr' + 8*`ntime'*`trperiod'*`acorr' ///
                 - 4*`trperiod'^2*`acorr' + `ntime'*`acorr'^2 + 2*`ntime'^2*`acorr'^2 - `trperiod'*`acorr'^2 ///
                 - 4*`ntime'*`trperiod'*`acorr'^2 + 2*`trperiod'^2*`acorr'^2) / 6
        }
        else {
            di as err "unknown type: `type' (use step/pulse/ramp)"
            exit 198
        }

        * standard error
        if "`knownmean'" != "" {
            scalar `se_effect' = sqrt(1 / `i22')
        }
        else {
            scalar `det' = `i11' * `i22' - `i12'^2
            if `det' <= 0 {
                di as err "nonpositive determinant in information matrix; check inputs"
                exit 199
            }
            scalar `se_effect' = sqrt(`i11' / `det')
        }

		* noncentrality and `power'
        scalar `lambda' = `effect_raw' / `se_effect'
        if "`onesided'" != "" {
            scalar `zcrit' = invnormal(1 - `alpha')
            scalar `power' = 1 - normal(`zcrit' - `lambda')
        }
        else {
            scalar `zcrit' = invnormal(1 - `alpha'/2)
            scalar `power' = normal(-`zcrit' - `lambda') + (1 - normal(`zcrit' - `lambda'))
        }
		
        * append to `results' matrix
        if `first' {
            matrix `results' = (`e', `=`power'')   // first row
            local first = 0
        }
        else {
            matrix `results' = `results' \ (`e', `=`power'')  // subsequent rows
        }
    } // end foreach effect 
	
	* formatting for titles, headers and values in `results' table
	if "`onesided'" != "" {
		local side One-sided	
	}
	else {
		local side Two-sided
	}
	local plevel = `alpha' * 100		

	if "`format'" != "" { 
		confirm numeric format `format' 
	}
	else local format %-6.3f 
	
	if "`raw'" != "" {
		local std unstandardardized
	}
	else {
		local std standardardized		
	}
	if "`knownmean'" != "" {
		local mean known
	}
	else {
		local mean estimated
	}

    matrix colnames `results' = Effect Power
	
	di _n
	di as txt "Statistical power computation for a {bf:`type'} intervention with AR(1) Error"
	di as txt "`side' test at `plevel'% level"
	di _n
	di as txt "Length of time series = " `ntime'
	di as txt "Observation number corresponding to the start of the intervention = " `trperiod'
	di as txt "Lag-one autocorrelation coefficient = " %4.2f `acorr'
	di as txt "Pre-intervention mean is `mean'
	di as txt "Effect size is `std'	


	* results table	
	matlist `results', border(top bottom) format(`format') tindent(0) aligncolnames(center) twidth(8)	names(columns)

    * return matrix
    return matrix table = `results'

end