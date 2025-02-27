*! version 1.0  20Feb2025
*! Minh Cong Nguyen - mnguyen3@worldbank.org
*! Hai-Anh Hoang Dang - hdang@worldbank.org
*! Kseniya Abanokova - kabanokova@worldbank.org

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

cap program drop s2s
program define s2s, eclass byable(recall) sortpreserve
                 
	syntax varlist [if] [in] [aweight fweight], by(varname numeric) from(numlist max=1) to(numlist max=1)  pline(varname numeric) cluster(varname numeric) ///
	[method(string) WTstats(varname numeric) strata(varname numeric) Alpha(integer 1) pline2(varname numeric) VLine(varname numeric) rep(integer 50) Brep(integer 10) seed(integer 1234567) bseed(integer 7654321) SAVing(string) REPLACE LNY] 
	
	*NOCONStant INDicators(string) 
	
	version 16, missing
	if c(more)=="on" set more off
    local version : di "version " string(_caller()) ", missing:"

	local cmdline: copy local 0
    *local nocns "`constant'"
	
	//housechecking
	if "`lny'" ~= "" {
		noi dis in yellow _newline `"Warning: When the "lny" option is specified, ensure that the left-hand side variable is expressed in logarithmic terms, while the poverty line variables remain in level terms."'
	}
	
	//method
	if "`method'"=="" local method normal
	else {
		local method `=lower("`method'")'
		if "`method'"~="empirical" & "`method'"~="normal" & "`method'"~="probit" & "`method'"~="logit" {
			noi dis as error "Method `method' is now allowed. Allowed methods: empirical, normal, probit, and logit."
			error 198
		}
	}
	
	preserve
	
	*** Poverty lines	
	if "`pline2'"~="" {
		cap assert `pline' > `pline2'		
		if _rc~=0 {
			noi dis as error "Values of extreme poverty line in pline2() should be smaller than that of poverty line in pline()."
			error 198
		}
	}
	
	if "`vline'"~="" {
		cap assert `vline' > `pline'
		if _rc~=0 {
			noi dis as error "Values of vulnerability line in vline() should be larger than that of poverty line in pline()."
			error 198
		}
	}
	
	/*
	*** area options
	if ("`cluster'"=="") {
		tempvar grv
		qui gen `grv' = 1
		local grvar `grv'
	}
	else {
		if (`:word count `cluster''==1) { // one group variable
			local grvar `cluster'
		}               
		else { // more than one group variable
			tempvar grmv
			qui egen `grmv' = group(`cluster'), label truncate(16)
			local grvar `grmv'
		}
	}	
	*local svar `strata'
	*/
	
	*** Weights
	if ("`weight'"=="") {
		tempvar w
		qui gen `w' = 1
		local wvar "`w'"
	}       
	else {
		local weight "[`weight'`exp']"                          
		local wvar : word 2 of `exp'
	}
	
	*** Indicator weight
	if ("`wtstats'"=="") {
		tempvar w
		qui gen `w' = 1
		local wtstats "`w'"
	}
	
	*** FGT indicators 
	/*
	if ("`alpha'"=="") & ("`all'"=="") {
		local alpha = 1
	}
	if ("`alpha'"=="") & ("`all'"~="") {
       local beta1 = 1
	   local beta2 = 2
	   local beta3 = 3
	   local beta4 = 4
	   local beta5 = 5
    }
	*/
	
	//missing observation check
	marksample touse, novarlist	
	gettoken lhs varlist: varlist
	local flist `"`varlist' `wvar' `by' `cluster' `strata' `pline'"'
	local okvarlist `varlist'
	markout `touse' `flist' 
	
	*** Poverty status in the base survey 
	tempvar pr	
	if "`lny'" ~= "" qui gen `pr'= `lhs'< ln(`pline') if `lhs'<. & `by'==`from' & `touse'
	else qui gen `pr'= `lhs'< `pline' if `lhs'<. & `by'==`from' & `touse'
	local poorbit `pr'
	
	** Check svysetting
	cap svydescribe
	if _rc!=0 {
		noi dis _newline "Waring: svyset was not applied in the data. Apply the basic svysetting:"
		noi dis `"svyset `cluster' [w= `wtstats'], strata(`strata') singleunit(certainty)"'
		svyset `cluster' [w= `wtstats'], strata(`strata') singleunit(certainty)
	}

	** Save original data	
	tempfile dataori datafrm datato dataset datatobs
	qui save `dataori', replace
	
	** from data
	use `dataori' if `touse', clear
	qui keep if `by'==`from'
	qui count
    local nfdata= r(N)
	local fr = r(N)
	if `fr'<=0 {
		dis "Data (`from') has no observation"
		exit 198 
	}
	qui save `datafrm', replace
	
	** to data
	use `dataori' if `touse', clear
	qui keep if `by'==`to'	
	qui count
	local nsdata= r(N)
	local toc = r(N)
	if `toc'<=0 {
		dis "Data (`to') has no observation"
		exit 198 
	}
	qui save `datato', replace
	
	use `dataori' if `touse', clear 	
	tempname all allp poorp gapp pgapp epoorp vpoorp meanp m5p m10p m25p m50p m75p m90p m95p 
	tempname allb poorb seb gapb gapseb pgapb pgapseb epoorb epoorseb vpoorb vpoorseb meanb meanseb m5b m5seb m10b m10seb m25b m25seb m50b m50seb m75b m75seb m90b m90seb m95b m95seb __xb
	
	local regok = 0
	if "`method'"=="empirical" | "`method'"=="normal" {	
		cap xtreg `lhs' `okvarlist' `weight' if `by'==`from', i(`cluster')
		if _rc==0 local regok = 1
	}
	else if "`method'"=="probit"  {
		cap xtprobit `poorbit' `okvarlist' `weight' if `by'==`from', i(`cluster')
		if _rc==0 local regok = 1
	}
	else { //if "`method'"=="logit" {
		cap xtlogit `poorbit' `okvarlist' `weight' if `by'==`from', i(`cluster')
		if _rc==0 local regok = 1
	}
	
	qui if `regok'==1 {
		local nfdata= e(N)
		keep if `by'==`to'
		predict double `__xb', xb
		keep if `__xb'<.
		keep `lhs' `okvarlist' `__xb' `by' `strata' `cluster' `wvar' `pline' `pline2' `wtstats' `vline'
		gen __obid= _n
		su __obid
		local nsdata= r(N)
		sort __obid
		compress
		tempfile datatoxb
		save `datatoxb', replace		
	}
	else {
		noi dis "Unable to run the model (`method') - please check your data and model"
		error 198
	}
	
	// Simulate with empirical distribution of Point estimates
	qui if "`method'"=="empirical" {		
		display _newline " "
		noi _dots 0, title(Point estimates - Running with `rep' reps) reps(`rep')
		use `dataori' if `touse', clear
		xtreg `lhs' `okvarlist' `weight' if `by'==`from', i(`cluster')
		scalar r2_m = e(r2_o)
		scalar n_m = r(N)
		predict double __ut if e(sample), u
		predict double __et if e(sample), e
		keep if __ut<.
		keep __ut __et
		compress
		tempfile euh
		save `euh', replace
		local ratio = ceil(`toc'/`fr')
		
		set seed `seed'
		qui forv i=1/`rep' {			
			tempvar  yh
			//adjust errors of the same cluster later
			use `euh', clear
			expand = `ratio'				
			bsample `nsdata' 
			gen __obid= _n
			sort __obid			
			merge 1:1 __obid using `datatoxb', nogen
			
		    *Get yh 
			if "`lny'" ~= "" gen double `yh' = exp(`__xb' + __ut + __et)
			else gen double `yh' = `__xb' + __ut + __et
		    
			*SAVE SIMULATED DATASET
			gen double yh_s`i' = `yh'
			
			tempfile dataset`i'
			save `dataset`i'', replace
			
			//function on the indicators
			s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') strata(`strata') pline(`pline') pline2(`pline2') vline(`vline') alpha(`alpha') resmat(`allp') method("`method'")
			
			noisily _dots `i' 0
		} //rep
		noisily _dots
		
		clear			
		mat colnames `allp' = poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
		svmat `allp', names(col)
			
		//INDicator list to be fixed
		local vlist1 poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
		foreach var of local vlist1 {
			sum `var'
			local est0_`var' = r(mean)
		}
		   
		*SAVE SIMULATED DATASET //need to add in original hhid 
		if "`saving'"~="" {
			use `dataset1', clear  
			qui forv i=2/`rep' { 
				merge 1:1 __obid using `dataset`i'', nogen
			}
			rename __obid id
			keep id yh_s*
			save "`saving'", `replace'
			noi dis _newline `"file "`saving'" saved"'
		} //save
	} //empirical

	// Simulate with empirical distribution of errors	
	qui if "`method'"=="empirical" {	
		display _newline " "
		noi dis _newline in gr `"Standard errors - Running with `rep' reps and `brep' bootstraps (`rep'*`brep')"'		
		set seed `bseed'
		tempfile data01 data02
		qui forv b = 1/`brep' { 	       
			tempname varu vare V all poor poor_var gap gap_var pgap pgap_var epoor epoor_var vpoor vpoor_var mean mean_var m5 m5_var m10 m10_var m25 m25_var m50 m50_var m75 m75_var m90 m90_var m95 m95_var r2_m n_m tmp1 single
			
			use `dataori' if `touse', clear
			//resample the whole data -- size of data year can be different
			keep if `by'==`from'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			save `data01', replace
			
			use `dataori' if `touse', clear			
			keep if `by'==`to'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			append using `data01'
			
			xtreg `lhs' `okvarlist' `weight' if `by'==`from', i(`cluster')
			local nfdata_bs`b'= e(N)
			
			keep if `by'==`to'
			predict double __xb_bs`b', xb
			keep if __xb_bs`b'<.
			keep `lhs' `okvarlist' __xb_bs`b' `by' `strata' `cluster' `wvar' `pline' `pline2' `wtstats' `vline'
			gen __obid_bs`b'= _n
			qui su __obid_bs`b'
			local nsdata_bs`b'= r(N)
			sort __obid_bs`b'
		
			compress
			tempfile datatoxb_bs`b'
			save `datatoxb_bs`b'', replace			
			local ratio_bs`b' = ceil(`nsdata_bs`b''/`nfdata_bs`b'')
			
			use `dataori' if `touse', clear						
			expand = `ratio_bs`b''			
			save `data02', replace
			
			keep if `by'==`from'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			save `data01', replace
			
			use `data02', clear			
			keep if `by'==`to'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			append using `data01'
						
			xtreg `lhs' `okvarlist' `weight' if `by'==`from', i(`cluster')

			scalar `r2_m' = e(r2_o)
			scalar `n_m' = r(N)
			predict double __ut_bs`b' if e(sample), u
			predict double __et_bs`b' if e(sample), e
			keep if __ut_bs`b'<.
			keep __ut_bs`b' __et_bs`b'
		   
			compress
			tempfile euh_bs`b'
			save `euh_bs`b'', replace
			
			set seed `seed'
			qui forv i = 1/`rep' {				
				tempvar yh
				use `euh_bs`b'', clear

				expand `ratio_bs`b''				
				bsample `nsdata_bs`b'' 

				gen __obid_bs`b'= _n
				sort __obid_bs`b'			
				merge 1:1 __obid_bs`b' using `datatoxb_bs`b'', nogen
				
				*Get yh
				if "`lny'" ~= "" gen double `yh' = exp(__xb_bs`b' + __ut_bs`b' + __et_bs`b')
				else gen double `yh' = __xb_bs`b' + __ut_bs`b' + __et_bs`b'
				
				s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') strata(`strata') pline(`pline') pline2(`pline2') vline(`vline') alpha(`alpha') resmat(`all') std method("`method'")
  
				noisily _dots `i' 0
			}
			
			clear	
			mat colnames `all' = `poor' `poor_var' `gap' `gap_var' `pgap' `pgap_var' `epoor' `epoor_var' `vpoor' `vpoor_var' `mean' `mean_var' `m5' `m5_var' `m10' `m10_var' `m25' `m25_var' `m50' `m50_var' `m75' `m75_var' `m90' `m90_var' `m95' `m95_var'

			svmat `all', names(col)		
		    mat drop `all'
			
			//INDicator list to be fixed, this order	
			cap mat drop `tmp1'
			local vlist1 poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
			foreach var1 of local vlist1 {
				sum ``var1''
				local est_`var1' = r(mean)
				scalar seexp = r(Var)/r(N) 
				su ``var1'_var'
				local se2_`var1' = (r(mean) + seexp)^0.5
				mat `tmp1' = nullmat(`tmp1'), `se2_`var1''
			}
					
			mat `allb' = nullmat(`allb') \ (`tmp1')
			noisily _dots `b' 0	   
	    } //brep
		
		clear
		mat colnames `allb' = poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95		
		svmat `allb', names(col)
				
		//INDicator list to be fixed
		local vlist1 poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
		foreach var of local vlist1 {
			sum `var'
			local se_`var' = r(mean)
		}
	} //empirical

	* Point estimates - normal	
	qui if "`method'"=="normal" {
		display _newline " "
		noi _dots 0, title(Point estimates - Running with `rep' reps) reps(`rep')
		use `dataori' if `touse', clear
		xtreg `lhs' `okvarlist' `weight' if `by'==`from', i(`cluster')
		scalar r2_m = e(r2_o)
		scalar n_m = r(N)
		mat b= e(b)
		mat V= J(2,2,.)
		scalar varu= e(sigma_u)^2
		mat V[1,1]= varu
		scalar vare= e(sigma_e)^2
		mat V[2,2]= vare
		mat V[1,2]= 0
		mat V[2,1]= 0
		
		set seed `seed'
		qui forv i= 1/`rep'  {
			clear			
			tempvar yh
			drawnorm __ut __et, n(`nsdata') cov(V) double			
			gen __obid= _n
			sort __obid			
			merge 1:1 __obid using `datatoxb', nogen
			
			*Get yh
		    if "`lny'"~="" qui gen double `yh' = exp(`__xb' + __ut + __et)
			else qui gen double `yh' = `__xb' + __ut + __et

			*SAVE SIMULATED DATASET
			generate double yh_s`i' = `yh'
			
			tempfile dataset`i'
			save `dataset`i'', replace

			//function on the indicators
			s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') strata(`strata') pline(`pline') pline2(`pline2') vline(`vline') alpha(`alpha') resmat(`allp') method("`method'")
			
			noisily _dots `i' 0
		} //rep
		noisily _dots
		
		clear			
		mat colnames `allp' = poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
		svmat `allp', names(col)
				
		//INDicator list to be fixed
		local vlist1 poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
		foreach var of local vlist1 {
			sum `var'
			local est0_`var' = r(mean)
		}
		      
		*SAVE SIMULATED DATASET
		if "`saving'"~="" {
			use `dataset1', clear  
			qui forv i=2/`rep' { 
				merge 1:1 __obid using `dataset`i'', nogen
			}
			rename __obid id
			keep id yh_s*
			save "`saving'", `replace'
			noi dis _newline `"file "`saving'" saved"'
		} //saving
	} //normal est point
	
	* Standard errors - normal	
	qui if "`method'"=="normal" {
		display _newline  " "
		noi _dots 0, title(Standard errors - Running with `rep' reps and `brep' bootstraps (`rep'*`brep')) reps(`=`rep'*`brep'')
		*noi dis _newline in gr `"Standard errors - Running with `rep' reps and `brep' bootstraps (`rep'*`brep')"'		
		set seed `bseed'
		tempfile data01 data02
		forvalues b = 1/`brep' {
			tempname all poor poor_var gap gap_var pgap pgap_var epoor epoor_var vpoor vpoor_var mean mean_var m5 m5_var m10 m10_var m25 m25_var m50 m50_var m75 m75_var m90 m90_var m95 m95_var r2_m n_m tmp1 single
			
			use `dataori' if `touse', clear 
			keep if `by'==`from'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			save `data01', replace
			
			use `dataori' if `touse', clear			
			keep if `by'==`to'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			append using `data01'
						
			xtreg `lhs' `okvarlist' `weight' if `by'==`from', i(`cluster')
			local nfdata_bs`b'= e(N)
			keep if `by'==`to'
		    
			predict double __xb_bs`b', xb
			keep if __xb_bs`b'<.
			keep `lhs' `okvarlist' __xb_bs`b' `by' `strata' `cluster' `wvar' `pline' `pline2' `wtstats' `vline'
			gen __obid_bs`b'= _n
			qui su __obid_bs`b'
		   
			local nsdata_bs`b'= r(N)
			sort __obid_bs`b'
		
			compress
			tempfile datatoxb_bs`b'
			save `datatoxb_bs`b'', replace

			use `dataori' if `touse', clear
			keep if `by'==`from'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			save `data01', replace
			
			use `dataori' if `touse', clear			
			keep if `by'==`to'
			svydescribe, gen(`single')
			drop if `single'==1
			bsample, strata(`strata') cluster(`cluster')             
			append using `data01'
			
			xtreg `lhs' `okvarlist' `weight' if `by'==`from', i(`cluster')
			
			mat V_bs`b' = J(2,2,.)
			scalar varu_bs`b' = e(sigma_u)^2
			mat V_bs`b'[1,1]= varu_bs`b'
			scalar vare_bs`b'= e(sigma_e)^2
			mat V_bs`b'[2,2]= vare_bs`b'
			mat V_bs`b'[1,2]= 0
			mat V_bs`b'[2,1]= 0
			 
			* Set seed for reproducibility
			set seed `seed'
			qui forv i = 1/`rep'  { // Loop over normal draws
				clear 				
				tempvar yh 
				
				drawnorm __ut __et, n(`nsdata_bs`b'') cov(V_bs`b') double			
				gen __obid_bs`b' = _n
				sort __obid_bs`b'			
				merge 1:1 __obid_bs`b' using `datatoxb_bs`b'', nogen
								
				*Get yh
				if "`lny'"~= "" gen double `yh' = exp(__xb_bs`b' + __ut + __et)
				else gen double `yh' = __xb_bs`b' + __ut + __et

				s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') strata(`strata') pline(`pline') pline2(`pline2') vline(`vline') alpha(`alpha') resmat(`all') std method("`method'")
				
				noisily _dots `i' 0
			} //rep
			
			clear
			mat colnames `all' = `poor' `poor_var' `gap' `gap_var' `pgap' `pgap_var' `epoor' `epoor_var' `vpoor' `vpoor_var' `mean' `mean_var' `m5' `m5_var' `m10' `m10_var' `m25' `m25_var' `m50' `m50_var' `m75' `m75_var' `m90' `m90_var' `m95' `m95_var'
						
			svmat `all', names(col)					
			mat drop `all'
			
			//INDicator list to be fixed, this order	
			cap mat drop `tmp1'
			local vlist1 poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
			foreach var1 of local vlist1 {
				sum ``var1''				
				scalar seexp = r(Var)/r(N) 
				su ``var1'_var'
				local se2_`var1' = (r(mean) + seexp)^0.5
				mat `tmp1' = nullmat(`tmp1'), `se2_`var1''
			}
					
			mat `allb' = nullmat(`allb') \ (`tmp1')			
			noisily _dots `b' 0
		} //brep
		_dots
		
		clear
		mat colnames `allb' = poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95		
		svmat `allb', names(col)
		
		//INDicator list to be fixed
		local vlist1 poor gap pgap epoor vpoor mean m5 m10 m25 m50 m75 m90 m95
		foreach var of local vlist1 {
			sum `var'
			local se_`var' = r(mean)
		}
	} //normal method - std
	
	* Point estimates - probit	
	qui if "`method'"=="probit" {
		display _newline " "
		noi _dots 0, title(Point estimates - Running with `rep' reps) reps(`rep')
		use `dataori' if `touse', clear
		xtprobit `poorbit' `okvarlist' `weight' if `by'==`from', i(`cluster')
		scalar n_m = r(N)
		mat b= e(b)
		mat V= J(1,1,.)
		scalar varu= e(sigma_u)^2
		mat V[1,1]= varu		
		scalar r2_m = .
		
		set seed `seed'
		forv i= 1/`rep'  {
			clear			
			tempvar yh
			drawnorm __ut, n(`nsdata') cov(V) double
			gen __obid= _n
			sort __obid			
			merge 1:1 __obid using `datatoxb', nogen
							
            gen double `yh' = `__xb' + __ut
						
			//function on the indicators
			s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') method("`method'") strata(`strata') pline(`pline') resmat(`allp')
			
			noisily _dots `i' 0
		} //rep
		noisily _dots
		
		clear			
		mat colnames `allp' = poor
		svmat `allp', names(col)
		
		//INDicator list to be fixed
		local vlist1 poor 
		foreach var of local vlist1 {
			sum `var'
			local est0_`var' = r(mean)
		}

		/*SAVE SIMULATED DATASET //need to add in original hhid 
		if "`saving'"~="" {
			use `dataset1', clear  
			qui forv i=2/`rep' { 
				merge 1:1 __obid using `dataset`i'', nogen
			}
			rename __obid id
			keep id yh_s*
			save "`saving'", `replace'
			noi dis `"file "`saving'" saved"'
		} //save
		*/		
	} //probit est point

	* Standard errors - probit
	qui if "`method'"=="probit" {
		display _newline " "
		noi _dots 0, title(Standard errors - Running with `rep' reps) reps(`rep')
		use `dataori' if `touse', clear
		xtprobit `poorbit' `okvarlist' `weight' if `by'==`from', i(`cluster')

		scalar n_m = r(N)
		mat b= e(b)
		mat V= J(1,1,.)
		scalar varu= e(sigma_u)^2
		mat V[1,1]= varu		
		scalar r2_m = .
		
		set seed `seed'
		forv i= 1/`rep' {
			clear
			tempvar yh

			drawnorm __ut, n(`nsdata') cov(V) double
			gen __obid= _n
			sort __obid			
			merge 1:1 __obid using `datatoxb', nogen
					
			gen double `yh' = `__xb' + __ut
			
			//function on the indicators
			s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') method("`method'") strata(`strata') pline(`pline') resmat(`all') std
			
			noisily _dots `i' 0
		} //rep
		
		clear
		mat colnames `all' = poor poor_var 		
		svmat `all', names(col)
		
		//INDicator list to be fixed, this order	
		sum poor
		scalar seexppoor = r(Var)/r(N) 
		su poor_var
		local se_poor = (r(mean) + seexppoor)^0.5			
	} //probit standard error
	
	* Point estimates - logit	
	qui if "`method'"=="logit" {
		display _newline " "
		noi _dots 0, title(Point estimates - Running with `rep' reps) reps(`rep')
		use `dataori' if `touse', clear
		qui xtlogit `poorbit' `okvarlist' `weight' if `by'==`from', i(`cluster')
		scalar n_m = r(N)
		mat b= e(b)
		mat V= J(1,1,.)
		scalar varu= e(sigma_u)^2
		mat V[1,1]= varu
		scalar r2_m = .
		
		set seed `seed'
		qui forv i= 1/`rep'  {
			clear
			tempvar yh
			drawnorm __ut, n(`nsdata') cov(V) double			
			gen __obid= _n
			sort __obid			
			merge 1:1 __obid using `datatoxb', nogen
						
			gen double `yh' = `__xb' + __ut
			
			//function on the indicators
			s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') method("`method'") strata(`strata') pline(`pline') resmat(`allp')

			noisily _dots `i' 0
		} //rep
		noisily _dots
		
		clear			
		mat colnames `allp' = poor
		svmat `allp', names(col)
		
		//INDicator list to be fixed
		local vlist1 poor 
		foreach var of local vlist1 {
			sum `var'
			local est0_`var' = r(mean)
		}
		
		/*SAVE SIMULATED DATASET //need to add in original hhid 
		if "`saving'"~="" {
			use `dataset1', clear  
			qui forv i=2/`rep' { 
				merge 1:1 __obid using `dataset`i'', nogen
			}
			rename __obid id
			keep id yh_s*
			save "`saving'", `replace'
			noi dis `"file "`saving'" saved"'
		} //save
	    */
	} //logit est point
	
	* Standard errors - logit
	qui if "`method'"=="logit" {
		display _newline " "
		noi _dots 0, title(Standard errors - Running with `rep' reps) reps(`rep')
		use `dataori' if `touse', clear
		qui xtlogit `poorbit' `okvarlist' `weight' if `by'==`from', i(`cluster')
		scalar n_m = r(N)
		mat b= e(b)
		mat V= J(1,1,.)
		scalar varu= e(sigma_u)^2
		mat V[1,1]= varu
		scalar r2_m = .
		
		set seed `seed'
		qui forv i= 1/`rep'  {
			clear
			tempvar yh
			drawnorm __ut, n(`nsdata') cov(V) double			
			gen __obid= _n
			sort __obid			
			merge 1:1 __obid using `datatoxb', nogen
			
			gen double `yh' = `__xb' + __ut
			
			//function on the indicators
			s2s_indicators, welfare(`yh') weight(`wtstats') indicators(`indicators') cluster(`cluster') method("`method'") strata(`strata') pline(`pline') resmat(`all') std
			
			noisily _dots `i' 0
		} //rep
		
		clear
		mat colnames `all' = poor poor_var 		
		svmat `all', names(col)
		
		//INDicator list to be fixed, this order	
		sum poor
		scalar seexppoor = r(Var)/r(N) 
		su poor_var
		local se_poor = (r(mean) + seexppoor)^0.5			
	} //logit standard error

	//return to user
	display _newline ""
	display _newline in ye "Method: `method'"	
	di as text "{hline 59}{c TT}{hline 15}{c TT}{hline 15}"
	di as text _col(60) "{c |}" "   Estimate    " "{c |}" "    Std. err.  "
	di as text "{hline 59}{c +}{hline 15}{c +}{hline 15}"
	di as text "Imputed Headcount poverty rate (%)" _col(60) "{c |}" _col(62) %9.2f `=100*`est0_poor'' _col(76) "{c |}" %9.2f `=100*`se_poor''
	
	if "`method'"=="empirical" | "`method'"=="normal" {
		di as text "Imputed FGT(`alpha') %" _col(60) "{c |}" _col(62) %9.2f `=100*`est0_gap'' _col(76) "{c |}" %9.2f `=100*`se_gap''
		di as text "Imputed FGT(`alpha') %, among the poor" _col(60) "{c |}" _col(62) %9.2f `=100*`est0_pgap'' _col(76) "{c |}" %9.2f `=100*`se_pgap''
		if "`pline2'"~="" {
			di as text "Imputed extreme poverty (%)" _col(60) "{c |}" _col(62) %9.2f `=100*`est0_epoor'' _col(76) "{c |}" %9.2f  `=100*`se_epoor''
		}
		if "`vline'"~="" {
			di as text "Imputed near poverty (%)" _col(60) "{c |}" _col(62) %9.2f `=100*`est0_vpoor'' _col(76) "{c |}" %9.2f  `=100*`se_vpoor''
		}
		di as text "Mean consumption" _col(60) "{c |}" _col(62) %9.2f `est0_mean' _col(76) "{c |}" %9.2f `se_mean'
		local vlist1 5 10 25 50 75 90 95
		foreach var1 of local vlist1 {
			di as text "Mean percentile `var1'th" _col(60) "{c |}" _col(62) %9.2f `est0_m`var1'' _col(76) "{c |}" %9.2f `se_m`var1''
		}
	}	
	di as text "{hline 59}{c BT}{hline 15}{c BT}{hline 15}"
	
	ereturn clear
	ereturn local cmdline "`cmdline'"
		
	//return scalar
    ereturn scalar pov_imp = `=100*`est0_poor''
	ereturn scalar pov_var = (`=100*`se_poor'')^2
	
	if "`method'"=="empirical" | "`method'"=="normal" {
		ereturn scalar fgt`alpha'_imp = `=100*`est0_gap''
		ereturn scalar fgt`alpha'_var = (`=100*`se_gap'')^2
		
		ereturn scalar pfgt`alpha'_imp = `=100*`est0_pgap''
		ereturn scalar pfgt`alpha'_var = (`=100*`se_pgap'')^2
		
		if "`pline2'"~="" {
			ereturn scalar exp_imp = `=100*`est0_epoor''
			ereturn scalar exp_var = (`=100*`se_epoor'')^2
		}
		
		if "`vline'"~="" {
			ereturn scalar np_imp = `=100*`est0_vpoor''
			ereturn scalar np_var = (`=100*`se_vpoor'')^2
		}
		
		ereturn scalar mean_imp = `est0_mean' 
		ereturn scalar mean_var = `se_mean'^2
		
		local vlist1 5 10 25 50 75 90 95
		foreach var1 of local vlist1 {
			ereturn scalar p`var1'_imp = `est0_m`var1'' 
			ereturn scalar p`var1'_var = `se_m`var1''^2
		}
	}
	
	ereturn scalar N1 = `nfdata'
	ereturn scalar N2 = `nsdata'			
end