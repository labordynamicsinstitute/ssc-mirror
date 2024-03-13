*===================================================================================*
* Ado-file: 	EconSig Version 1.0 
* Author: 		Shutter Zor(左祥太)
* Affiliation: 	Accounting Department, Xiamen University
* E-mail: 		Shutter_Z@outlook.com 
* Date: 		2024/3/3                                          
*===================================================================================*



capture program drop econsig
program define econsig
	version 13
	
	syntax, Model(string) [Keep(string) REGression REFerence]
	
	*-display begin time
	/*dis _n in g "Begin Time: " in y "`c(current_date)' `c(current_time)'"
	qui timer clear 99
	qui timer on    99*/
	
	*-check the model() option	
	local condition_if = subinword("`model'", "if", "S-Z-if", .)
	local condition_in = subinword("`model'", "in", "S-Z-in", .)
	if strpos("`condition_if'","S-Z-if")>0 | strpos("`condition_in'","S-Z-in")>0{
	   dis as error "[if] or [in] can not specified in model() option"
	   exit 198	   	    
	}
	
	*- calculate economic significance
	preserve
		
		*- get dependent and independent variable
		local model_text = subinstr("`model'", ",", "++", .)
		tokenize "`model_text'", parse("++")
		local cmdvlist "`1'"
		
		if strpos("`model_text'","++") != 0 {
			local opts ", `4'"  // options 
		}
		else{
			local opts ""
		}
		
		gettoken cmd vlist: cmdvlist  // before ,
		gettoken depvar indepvar: vlist
		
		*dis "`depvar'"
		*dis "`indepvar'"
		*dis "`cmd'"
		*dis "`cmdvlist'"
		*dis "`opts'"
		
		if "`regression'" == "" {
			qui `model'
		}
		else {
			`model'
		}
		
		qui keep if e(sample)

		foreach variable in `indepvar' {
			local `variable'_coef = _b[`variable']
		}
		
		qui sum `depvar'
		local y_mean = r(mean)
		local y_sd   = r(sd)
		
		foreach variable in `indepvar' {
			qui sum `variable', d
			local `variable'_mean	= r(mean)
			local `variable'_sd		= r(sd)
			local `variable'_iqr	= r(p75) - r(p25)
			local smith_2016_`variable'		= abs(``variable'_coef'*``variable'_sd'/`y_mean')
			local guiso_2015_`variable'   	= abs(``variable'_coef'*``variable'_sd'/`y_sd')
			local mueller_2017_`variable'  	= abs(``variable'_coef'*``variable'_iqr'/`y_mean')
			local mitton_2024_`variable'   	= abs(``variable'_coef'*``variable'_iqr'/`y_sd')
			local custodio_2014_`variable' 	= abs(``variable'_coef'/`y_mean')
			local li_2011_`variable'  		= abs(``variable'_coef'/`y_sd')
		}

		*- display results
		di in w _n "{bf:Economic Significance Index:}"
		di in smcl in gr _n "Variable" _skip(3) "{c |}" _skip(5) /*
		*/ "ES1      ES2      ES3      ES4      ES5      ES6    " /*
		*/ _n "{hline 11}{c +}{hline 60}"
		
		if "`keep'" == "" {
			local indepvar_num = wordcount("`indepvar'")
			local num_count = 1
			tokenize "`indepvar'"
			forvalues i = 1/`indepvar_num' {
				di in smcl in gr abbrev("``i''",8) _col(12) "{c |}" in ye ///
					"   " %6.3f `li_2011_``i'''			///
					"   " %6.3f `custodio_2014_``i'''	///
					"   " %6.3f `guiso_2015_``i'''		///
					"   " %6.3f `smith_2016_``i'''		///
					"   " %6.3f `mueller_2017_``i'''	///
					"   " %6.3f `mitton_2024_``i'''
			}
		}
		else {
			local indepvar_num = wordcount("`keep'")
			local num_count = 1
			tokenize "`keep'"
			forvalues i = 1/`indepvar_num' {
				di in smcl in gr abbrev("``i''",8) _col(12) "{c |}" in ye ///
					"   " %6.3f `li_2011_``i'''			///
					"   " %6.3f `custodio_2014_``i'''	///
					"   " %6.3f `guiso_2015_``i'''		///
					"   " %6.3f `smith_2016_``i'''		///
					"   " %6.3f `mueller_2017_``i'''	///
					"   " %6.3f `mitton_2024_``i'''
			}
		}

	restore
	
	* dis over time
	/*timer off  99
	qui timer list 99
	dis _n in g " Over Time:" in y "`c(current_date)' `c(current_time)'" _c
	dis  in g "   Time used: " in y "`r(t99)'s"	*/
	
	*- display references
	if "`reference'" != "" {
		di in w _n "{bf:References:}"
		di in w _n "    ES1: Li F, Srinivasan S. Corporate governance when founders are directors[J]. Journal of financial economics, 2011, 102(2): 454-469."
		di in w _n "    ES2: Custódio C, Metzger D. Financial expert CEOs: CEO's work experience and firm's financial policies[J]. Journal of financial economics, 2014, 114(1): 125-154."
		di in w _n "    ES3: Guiso L, Sapienza P, Zingales L. The value of corporate culture[J]. Journal of Financial Economics, 2015, 117(1): 60-76."
		di in w _n "    ES4: Smith J D. US political corruption and firm financial policies[J]. Journal of Financial Economics, 2016, 121(2): 350-367."
		di in w _n "    ES5: Mueller H M, Ouimet P P, Simintzi E. Within-firm pay inequality[J]. The Review of Financial Studies, 2017, 30(10): 3605-3635."
		di in w _n "    ES4: Mitton T. Economic significance in corporate finance[J]. The Review of Corporate Finance Studies, 2024, 13(1): 38-79."
	}
	
	
end


