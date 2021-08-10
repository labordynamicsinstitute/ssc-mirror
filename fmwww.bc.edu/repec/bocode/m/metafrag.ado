*! 2.0.0 Ariel Linden 15jul2020 // added color to values that were modified on forest plot; added verbiage in results window indicating which studies were modified 
*! 1.1.1 Ariel Linden 03jul2020 // revised description of results when the number of added events does not equal number of iterations (due to ties)
*! 1.1.0 Ariel Linden 25dec2019 // added _dots; fixed ">=" and "<=" on lines 147 and 219; added output for ties
*! 1.0.0 Ariel Linden 18nov2019

program define metafrag, rclass
version 16.0

	syntax  [,	///
		FORest	FORest2(str asis) /// plot forestplot
		EForm	/// exponentiated
	* ]                    

	qui { 
		preserve
	
		/* Ensure that data are meta set */
		cap confirm variable _meta_es _meta_se
		if _rc {
			di as err "data not {bf:meta} set"
			di as err "{p 4 4 2}You must declare your meta-analysis " "data using {helpb meta esize}.{p_end}"
			exit 119
		}
	
		/* Extract chars from -meta esize- */
		local datatype "`_dta[_meta_datatype]'"
		local cmdlne "`_dta[_meta_setcmdline]'"
		local events1  "`_dta[_meta_n11var]'"
		local nonevents1 "`_dta[_meta_n12var]'"
		local events2 "`_dta[_meta_n21var]'"
		local nonevents2 "`_dta[_meta_n22var]'"
		local ifexp "`_dta[_meta_ifexp]'"
		local inexp "`_dta[_meta_inexp]'"
		local estype "`_dta[_meta_estype]'"
		local vars "`_dta[_meta_datavars]'"

		/* Ensure that data are binary */
		if "`datatype'" != "binary" {
			di as err "{p}invalid {bf:meta esize()} specification: specify {bf:lnoratio}, " "{bf:lnrratio}, {bf:rdiff}, or {bf:lnorpeto}{p_end}"
			exit 184
		}

		/* assess model choice and eform */
		if "`estype'" == "rdiff" | "`eform'" == "" {
			local border = 0
		}
		else local border = 1
		
		/* keep observations meeting [if][in] expression used in -meta esize- */
		tempvar touse orig_events1 orig_events2
		gen `touse' = 1 `ifexp' `inexp'
		keep if `touse' == 1
		
		/* clone original event rates for comparison */
		gen `orig_events1' = `events1'
		gen `orig_events2' = `events2'


		/* rerun meta esize using cmdline stripped of [if/in] */
		local right = reverse("`cmdlne'")
		local right = substr("`right'", 1, strpos("`right'", ",") - 1)
		local right = reverse("`right'")

		local cleancmd meta esize `vars', `right'
		`cleancmd'
		
		meta summarize, `eform'
		
		/* Exponentiate stats if eform */
		if "`eform'" != "" {
			local init = exp(r(theta)) // initial pooled esize (exponentiated)
			local ci_up = exp(r(ci_ub)) // initial upper CI
			local ci_low = exp(r(ci_lb)) // initial lower CI
		}
		else {
			local init = r(theta) // initial pooled esize (exponentiated)
			local ci_up = r(ci_ub) // initial upper CI
			local ci_low = r(ci_lb) // initial lower CI
		}
		
		tempvar total1 total2 alt_events1 alt_noevents1 alt_events2 alt_noevents2 add subt
		gen `total1' = `events1' + `nonevents1'
		gen `total2' = `events2' + `nonevents2'
		gen `alt_events1' = `events1'
		gen `alt_noevents1' = `nonevents1'
		gen `alt_events2' = `events2'
		gen `alt_noevents2' = `nonevents2'

		gen double `add' = .
		gen double `subt' = .

		local frag = 0
		local cnt_fi = 0
		count
		local N = r(N)
	} // end qui
		di _n
		di as txt "Computing the fragility index. Please wait..."
	qui {
		
		*******************************************************
		* if the upper CI is less than 1 (eform) or 0 (linear)
		*******************************************************
		if `init' < `border' {

			while `ci_up' <  `border' {

				* Add events to first group of each study
				forval i = 1/`N' {
					replace `events1' in `i' =  `events1'[`i'] + 1 if `events1'[`i'] <= (`total1'[`i']) // add 1 event if events <= N1
					replace `events1' in `i' = 0 if `events1'[`i'] > (`total1'[`i']) // switch events to 0 if they are > N1
					replace `nonevents1' in `i' =  `nonevents1'[`i'] - 1 // subtract 1 from Group 1 non-events to ensure N1 is always the same
					replace `nonevents1' in `i' =  0 if `nonevents1'[`i'] < 0 // switch events to 0 if they equal 0
					`cleancmd'
					meta summarize, `eform'
					if "`eform'" != "" {
						local ucl = exp(r(ci_ub)) // get exponentiated upper CI
					}
					else local ucl = r(ci_ub)
					replace `add' in `i' = `ucl' // post CI to related study ID
					replace `events1' in `i' =  `alt_events1'[`i'] // return test events to original value
					replace `nonevents1' in `i' = `alt_noevents1'[`i'] // return test non-events to original value
				} //  end forval add

				* Subtract events from second group of each study
				forval i = 1/`N' {
					replace `events2' in `i' =  `events2'[`i'] - 1 if `events2'[`i'] > 0 // subtract 1 event if events > 0 
					replace `events2' in `i' =  0 if `events2'[`i'] < 0 // switch events to 0 if they are <= 0
					replace `nonevents2' in `i' =  `nonevents2'[`i'] + 1 // add 1 to Group 2 non-events to ensure N2 is always the same
					replace `nonevents2' in `i' = 0 if `nonevents2'[`i'] > (`total2'[`i']) // switch events to 0 if they are > N2
					`cleancmd'
					meta summarize, `eform'
					if "`eform'" != "" {
						local ucl = exp(r(ci_ub)) // get exponentiated upper CI
					}
					else local ucl = r(ci_ub)
					replace `subt' in `i' = `ucl' // post CI to related study ID
					replace `events2' in `i' =  `alt_events2'[`i'] // return test events to original value
					replace `nonevents2' in `i' =  `alt_noevents2'[`i'] // return test non-events to original value
				} // end subtract
			
				* find max CI values
				sum `add', meanonly
				local add_max =  r(max)
				sum `subt', meanonly
				local subt_max =  r(max)
		 
				* Modify original event and non-event data according to max CI value
				if `subt_max' == 0 | `add_max' > `subt_max' {
					replace `events1' = `events1' + 1 if `add' == `add_max'
					replace `nonevents1' = `nonevents1' - 1 if `add' == `add_max'
					local ci_up = `add_max'
					count if `add' == `add_max'
					local cnt = r(N)
					
				}
				else if `add_max' <= `subt_max' {
					replace `events2' = `events2' - 1 if `subt' == `subt_max'
					replace `nonevents2' = `nonevents2' + 1 if `subt' == `subt_max'
					local ci_up = `subt_max'
					count if `subt' == `subt_max'
					local cnt = r(N)
				}
		
				* set original data to match modified data
				replace `alt_events1' = `events1'
				replace `alt_noevents1' = `nonevents1'
				replace `alt_events2' = `events2'
				replace `alt_noevents2' = `nonevents2'

				noi _dots `frag' 0
				local frag = `frag' + 1
				local cnt_fi = `cnt_fi' + `cnt'
	
			} // end while ci_up < `border'
		
		} // end if init < `border'	
	
		*********************************************************
		* if the lower CI is greater than 1 (eform) or 0 (linear)
		*********************************************************	
		else if `init' > `border' {
		
			while `ci_low' > `border' {
			
				* Add events to second group of each study
				forval i = 1/`N' {
					replace `events2' in `i' =  `events2'[`i'] + 1 if `events2'[`i'] <= (`total2'[`i']) // add 1 event if events <= N2
					replace `events2' in `i' = 0 if `events2'[`i'] > (`total2'[`i']) // switch events to 0 if they are > N1 ... IN R THIS IS "return(Inf)"
					replace `nonevents2' in `i' =  `nonevents2'[`i'] - 1 // subtract 1 from Group 2 non-events to ensure N1 is always the same
					replace `nonevents2' in `i' =  0 if `nonevents2'[`i'] < 0 // switch events to 0 if they equal 0
					`cleancmd'
					meta summarize, `eform'
					if "`eform'" != "" {
						local lcl = exp(r(ci_lb)) // get exponentiated upper CI
					}
					else local lcl = r(ci_lb)
					replace `add' in `i' = `lcl' // post CI to related study ID
					replace `events2' in `i' =  `alt_events2'[`i'] // return test events to original value
					replace `nonevents2' in `i' = `alt_noevents2'[`i'] // return test non-events to original value
				} //  end add
		
				* Subtract events from first group of each study
				forval i = 1/`N' {
					replace `events1' in `i' =  `events1'[`i'] - 1 if `events1'[`i'] > 0 // subtract 1 event if events > 0 
					replace `events1' in `i' =  0 if `events1'[`i'] < 0 // switch events to 0 if they are <= 0  ... IN R THIS IS "return(Inf)"
					replace `nonevents1' in `i' =  `nonevents1'[`i'] + 1 // add 1 to Group 2 non-events to ensure N2 is always the same
					replace `nonevents1' in `i' = 0 if `nonevents1'[`i'] > (`total1'[`i']) // switch events to 0 if they are > N2
					`cleancmd'
					meta summarize, `eform'
					if "`eform'" != "" {
						local lcl = exp(r(ci_lb)) // get exponentiated upper CI
					}
					else local lcl = r(ci_lb)
					replace `subt' in `i' = `lcl' // post CI to related study ID
					replace `events1' in `i' =  `alt_events1'[`i'] // return test events to original value
					replace `nonevents1' in `i' =  `alt_noevents1'[`i'] // return test non-events to original value
				} // end subtract
			
				* find min CI values
				sum `add', meanonly
				local add_min =  r(min)
				sum `subt', meanonly
				local subt_min =  r(min)
		 
				* Modify original event and non-event data according to max CI value
				if `subt_min' == 0 | `add_min' < `subt_min' {
					replace `events2' = `events2' + 1 if `add' == `add_min'
					replace `nonevents2' = `nonevents2' - 1 if `add' == `add_min'
					local ci_low = `add_min'
					count if `add' == `add_min'
					local cnt = r(N)
				}
				else if `add_min' >= `subt_min' {
					replace `events1' = `events1' - 1 if `subt' == `subt_min'
					replace `nonevents1' = `nonevents1' + 1 if `subt' == `subt_min'
					local ci_low = `subt_min'
					count if `subt' == `subt_min'
					local cnt = r(N)
				}
		
				* Set original data to match test data (with modifications)
				replace `alt_events1' = `events1'
				replace `alt_noevents1' = `nonevents1'
				replace `alt_events2' = `events2'
				replace `alt_noevents2' = `nonevents2'

				noi _dots `frag' 0
				local frag = `frag' + 1
				local cnt_fi = `cnt_fi' + `cnt'

			} // end while ci_low > `border'	
		} // end init > `border'

		`cleancmd'
			
		/* Generate forestplot */
		if `"`forest'`forest2'"' != "" { 
			meta forestplot, nullrefline `eform' ///
				columnopts(_data1, supertitle(Group 1)) columnopts(_data2, supertitle(Group 2)) ///
				columnopts(_a _c, title("Events")) columnopts(_b _d, title("Non-events")) `forest2'
		
		* Add red or blue color to event values that were subtracted or added, respectively		
			forval i = 1/`N' {
				if `events1'[`i'] < `orig_events1'[`i'] {
					gr_edit .plotregion1.column2.items[`i'].EditCustomStyle , j(-1) style(color(red))
				}
				else if `events1'[`i'] > `orig_events1'[`i'] {
					gr_edit .plotregion1.column2.items[`i'].EditCustomStyle , j(-1) style(color(blue))
				}
				if `events2'[`i'] < `orig_events2'[`i'] {
					gr_edit .plotregion1.column4.items[`i'].EditCustomStyle , j(-1) style(color(red))
				}
				else if `events2'[`i'] > `orig_events2'[`i'] {
					gr_edit .plotregion1.column4.items[`i'].EditCustomStyle , j(-1) style(color(blue))
				}
			} // end forval
		} // end forest	
		
	} // end qui	
		
		/* Display result */
		di _n
		di as txt "   Fragility Index: " as result %1.0f `frag'
		
		if "`frag'" != "`cnt_fi'" {
			di as txt "   Fragility Index with ties: " as result %1.0f `cnt_fi'
		}
		di _n
		if "`frag'" == "`cnt_fi'" {
			di as txt "   The pooled treatment effect turns statistically non-significant after " %1.0f `frag' " event-status modifications" 
		}
		if "`frag'" != "`cnt_fi'" {
			di as txt "   The pooled treatment effect turns statistically non-significant after " %1.0f `frag' " iterations accounting for " %1.0f `cnt_fi' " event-status modifications"
		}

		/* Display study modification text */
		qui tab _meta_studylabel if `events1' != `orig_events1' | `events2' != `orig_events2'
		local studycnt = r(N)
	
		di _n
		if `studycnt' == 1 {
			di as txt "   `studycnt' trial was modified: " 
		}
		else if `studycnt' > 1 {
			di as txt "   A total of `studycnt' trials were modified: " 
		}

		forval i = 1/ `N' {
			if `events1'[`i'] < `orig_events1'[`i'] {
				local count = (`orig_events1'[`i'] - `events1'[`i'])
				local name = _meta_studylabel[`i']
				if `count' == 1 {
					di as txt "   -  `name': subtracted `count' event from Group 1"
				}
				else if `count' > 1 {
					di as txt "   -  `name': subtracted `count' events from Group 1"
				}
			}
			if `events1'[`i'] > `orig_events1'[`i'] {
				local count = (`events1'[`i'] - `orig_events1'[`i'])
				local name = _meta_studylabel[`i']
				if `count' == 1 {
					di as txt "   - `name': added `count' event to Group 1"
				}
				else if `count' > 1 {
					di as txt "   -  `name': added `count' events to Group 1"
				}
			}	
			if `events2'[`i'] < `orig_events2'[`i'] {
				local count = (`orig_events2'[`i'] - `events2'[`i'])
				local name = _meta_studylabel[`i']
				if `count' == 1 {
					di as txt "   -  `name': subtracted `count' event from Group 2"
				}
				else if `count' > 1 {
					di as txt "   -  `name': subtracted `count' events from Group 2"
				} 
			} 
			if `events2'[`i'] > `orig_events2'[`i'] {
				local count = (`events2'[`i'] - `orig_events2'[`i'])
				local name = _meta_studylabel[`i']
				if `count' == 1 {
					di as txt "   -  `name': added `count' event to Group 2"
				} 
				else if `count' > 1 {
					di as txt "   -  `name': added `count' events to Group 2"
				} 
			}
		} // end forval 

		// return list
		return scalar frag = `frag'
		if "`frag'" != "`cnt_fi'" {
			return scalar frag_ties = `cnt_fi'
		}
end


