* Epidemic Volatility Index version 1.0 - 11 October 2021
* Authors: Luis Furuya-Kanamori (l.furuya@uq.edu.au) & Polychronis Kostoulas


program define evi, rclass
version 14

syntax varlist(min=2 max=2 numeric) [if] [in] ///
, [Lag(numlist min=2 max=2)] [C(numlist min=2 max=2)] [R(numlist max=1)] ///
[MOV(numlist max=1)] [CUMulative] ///
[SEnsitivity(numlist max=1)] [SPecificity(numlist max=1)] [Youden]  ///
[NORSample] [noGraph] [LOGarithmic]  
*[CONTINUE/UPDATE] 


tokenize `varlist'

*Dummy ID + preserve
	cap quietly gen __dummy_id = _n
	preserve
	
marksample touse, novarlist 
quietly keep if `touse'


*Check required packages
foreach package in rangestat diagt {
capture which `package'
if _rc==111 ssc install `package'
}

*Error specification
	*Combine Youden's J, Sens, Spec (Error)
	if "`youden'"!="" & ("`sensitivity'"!="" | "`specificity'"!="")  {
	di as error "Select only one: Youden's J, Sens, or Spec"
		restore
		drop __dummy_id
	exit 198
	}
				
	if "`sensitivity'"!="" & ("`youden'"!="" | "`specificity'"!="")  {
	di as error "Select only one: Youden's J, Sens, or Spec"
		restore
		drop __dummy_id
	exit 198
	}
	
	if "`specificity'"!="" & ("`sensitivity'"!="" | "`youden'"!="")  {
	di as error "Select only one: Youden's J, Sens, or Spec"
		restore
		drop __dummy_id
	exit 198
	}
	
	if "`specificity'"!="" & "`sensitivity'"!="" & "`youden'"!=""  {
	di as error "Select only one: Youden's J, Sens, or Spec"
		restore
		drop __dummy_id
	exit 198
	}
	
	*Range Se and Sp
	if "`sensitivity'"!="" {
		local sens = `sensitivity'
		cap assert `sens'>=0 & `sens'<=1
		if _rc!=0{
			display as error ""
			di as error "Sens should be between 0 and 1" 
				restore
				drop __dummy_id
			exit 198
		}	
	}
	
	if "`specificity'"!="" {
		local spec = `specificity'
		cap assert `spec'>=0 & `spec'<=1
		if _rc!=0{
			display as error ""
			di as error "Spec should be between 0 and 1" 
				restore
				drop __dummy_id
			exit 198
		}	
	}
	
	
*Data input for analysis + error/warning messages
if "`1'" != "" & "`2'" != "" {
	quietly {
	
	*Days
		gen __day = `2'
		gen __day_label = "`2'"
	
			*Repeated days (Error)
			gen __n_day = __day[_n] - __day[_n-1]
			cap assert __n_day != 0
			if _rc!=0{
			display as error ""
			di as error "Variable {bf:`2'} contains repeated values" 
				restore
				drop __*
			exit _rc
			}
			
			*Sort days (Error)
			cap assert __n_day > 0
			if _rc!=0{
			display as error ""
			di as error "Variable {bf:`2'} not sorted: {bf:`2'}[_n-1] > {bf:`2'}[_n]" 
				restore
				drop __*
			exit _rc
			}
						
			*Missing values days (Error)
			cap assert `2' != .
			if _rc!=0{
			display as error ""
			di as error "Variable {bf:`2'} contains missing values"
				restore
				drop __*
			exit _rc
			}
			
		sort __day
		drop if __day==.
			local day_min = __day[1]
			gen __day_max = [_N]
			local day_max = __day_max[1]
			
			
	*Cases	
		*Mova
			if "`mov'"=="" {
				local mova1 = 7
				local mova2 = `mova1'-1
			}
		
			if "`mov'"!="" {
				local mova1 = `mov'
				local mova2 = `mova1'-1
					
					*MOVA >=14 (Warning)
					if `mova1' >= 14 {
					display as error ""
					display as error "Warning: Rolling window size ≥ 14 is not recommended"
					}
			}
			
		*Cumulative 
			if "`cumulative'"=="" {
			gen __n_case = `1'
			gen __cases_label = "`1'"
			}
				
			if "`cumulative'"!="" {
			gen __cases = `1'
			gen __cases_label = "`1'"
			gen __n_case = __cases[_n] - __cases[_n-1]
			replace __n_case = __cases in 1
				
				*Cases[_n-1] > Cases[_n] (Error)
				cap assert __n_case >= 0
				if _rc!=0{
				display as error ""
				di as error "Warning: variable {bf:`1'} not in ascending order: {bf:`1'}[_n-1] > {bf:`1'}[_n]" 
				}
			}				
			
			*Non-integers cases (Warning)
			cap assert int(`1')==`1'
			if _rc!=0{
			display as error ""
			di as error "Warning: variable {bf:`1'} contains non-integers"
			}
			
			*Missing values cases (Warning)
			cap assert `1'!=.
			if _rc!=0{
			display as error ""
			di as error "Warning: variable {bf:`1'} contains missing values"
			}

			
	*Lag
		if "`lag'"=="" {
			local lag_min = 7
			local lag_max = 10
		}
		
		if "`lag'"!="" {
			tokenize `lag'
				local lag_min = `1'
				local lag_max = `2'
				
					*Lag <=6 (Warning)
					if `lag_min' <= 6 {
					display as error ""
					display as error "Warning: Lag ≤ 6 is not recommended"
					}
		}
	
	
	*C
		if "`c'"=="" {
			local c_min = 0.01
			local c_max = 0.05
		}
		
		if "`c'"!="" {
			tokenize `c'
				local c_min = `1'
				local c_max = `2'
		}
	
	
	*R
		if "`r'"=="" {
			local r1 = 1.2
			local r2 = 1/`r1'
		}
		
		if "`r'"!="" {
			local r1 = `r'
			local r2 = 1/`r1'
		}	

		
*Moving average
	tsset __day
	tssmooth ma __mova_case = __n_case, window(`mova2' 1 0)

	
*Status	
	tssmooth ma __avg_mova1 = __mova_case, window(`mova2' 1 0)
	tssmooth ma __avg_mova2 = __mova_case, window(0 0 `mova1')
	gen __status = __avg_mova1/__avg_mova2 if day >= `mova1' 
		cap gen __status_cat = 0 if __status > `r2' 
		replace __status_cat = 1 if __status <= `r2'
		replace __status_cat = . if __day < `mova1'
	
	
*Empty cells
	gen __evi = .
	gen __evi_cat = .
	gen __se = .
	gen __sp = .
	gen __y = .
		
	gen __d = .
	gen __l = .
	gen __c = .
		
	cap gen __l_max = .
	cap gen __c_max = .
	cap gen __se_max = 0
	cap gen __sp_max = 0
	cap gen __y_max = 0

	gen __fixed_val = 0
		
	gen __evi_max = .
	cap gen __evi_cat_max = .
			
	
*Loop by days
	forvalues d_i = `day_min' (1) `day_max' {
		
	*Loops lag and c
		forvalues lag_i = `lag_min' (1) `lag_max' {
		forvalues c_i = `c_min' (0.01) `c_max' {				
	
		*Lag and C
			replace __d = `d_i'
			replace __l = `lag_i'
			replace __c = `c_i'
	
		*Roll SD
			local lag2 = 1-`lag_i'
			rangestat (sd)__mova_case, interval(day `lag2' 0) 
			rename __mova_case_sd __roll_sd
	
		*EVI
			replace __evi = (__roll_sd[_n] - __roll_sd[_n-1]) / __roll_sd[_n-1] 
				replace __evi=0 if __roll_sd==.
				replace __evi=0 if (__roll_sd[_n-1]==0 | __roll_sd[_n-1]==.) & (__roll_sd[_n]==0)
				replace __evi=999 if __roll_sd[_n-1]==0 & __roll_sd[_n]!=0 
				drop __roll_sd
			
		*EVI_cat
			replace __evi_cat = 0
				replace __evi_cat = 1 if __evi >= `c_i' //& __evi!=999 
				replace __evi_cat = 0 if (__mova_case[_n] < __mova_case[_n-`mova1'])
	
		*Sens/Spec/Y
			if `d_i' > 7 {
			local w = `d_i'-7
			cap diagt __status_cat __evi_cat in 1/`w' 
				replace __se=r(sens)/100 in `d_i'
				replace __sp=r(spec)/100 in `d_i'
				replace __y = __se+__sp-1 in `d_i'
			}
					
		*Select Lag/C based on the best
			*Youden's J
				if ("`specificity'"=="" & "`sensitivity'"=="" & "`youden'"=="") | ("`youden'"!="") {
					if __y[`d_i'] > __y_max[`d_i'] {
						replace __y_max in `d_i' = __y[`d_i']
						replace __se_max in `d_i' = __se[`d_i']
						replace __sp_max in `d_i' = __sp[`d_i']
						replace __l_max in `d_i' = __l[`d_i']
						replace __c_max in `d_i' = __c[`d_i']
						replace __evi_max in `d_i' = __evi[`d_i']
						replace __evi_cat_max in `d_i' = __evi_cat[`d_i']
					}
				}
			
			*Sens
				if "`sensitivity'"!="" {
					if (__se[`d_i'] <= `sens') & (__se[`d_i'] > __se_max[`d_i']) {
					 	replace __y_max in `d_i' = __y[`d_i']
						replace __se_max in `d_i' = __se[`d_i']
						replace __sp_max in `d_i' = __sp[`d_i']
						replace __l_max in `d_i' = __l[`d_i']
						replace __c_max in `d_i' = __c[`d_i']
						replace __evi_max in `d_i' = __evi[`d_i']
						replace __evi_cat_max in `d_i' = __evi_cat[`d_i']
						replace __fixed_val in `d_i' = 1
					}
					else if (__se[`d_i'] > `sens') & (__y[`d_i'] > __y_max[`d_i']) & (__fixed_val[`d_i'] != 1) {
						replace __y_max in `d_i' = __y[`d_i']
						replace __se_max in `d_i' = __se[`d_i']
						replace __sp_max in `d_i' = __sp[`d_i']
						replace __l_max in `d_i' = __l[`d_i']
						replace __c_max in `d_i' = __c[`d_i']
						replace __evi_max in `d_i' = __evi[`d_i']
						replace __evi_cat_max in `d_i' = __evi_cat[`d_i']
						replace __fixed_val in `d_i' = 0
					}
				}
				
			*Spec
				if "`specificity'"!="" {
					if (__sp[`d_i'] <= `spec') & (__sp[`d_i'] > __sp_max[`d_i']) {
						replace __y_max in `d_i' = __y[`d_i']
						replace __se_max in `d_i' = __se[`d_i']
						replace __sp_max in `d_i' = __sp[`d_i']
						replace __l_max in `d_i' = __l[`d_i']
						replace __c_max in `d_i' = __c[`d_i']
						replace __evi_max in `d_i' = __evi[`d_i']
						replace __evi_cat_max in `d_i' = __evi_cat[`d_i']
						replace __fixed_val in `d_i' = 1
					}
					else if (__sp[`d_i'] > `spec') & (__y[`d_i'] > __y_max[`d_i']) & (__fixed_val[`d_i'] != 1) {
						replace __y_max in `d_i' = __y[`d_i']
						replace __se_max in `d_i' = __se[`d_i']
						replace __sp_max in `d_i' = __sp[`d_i']
						replace __l_max in `d_i' = __l[`d_i']
						replace __c_max in `d_i' = __c[`d_i']
						replace __evi_max in `d_i' = __evi[`d_i']
						replace __evi_cat_max in `d_i' = __evi_cat[`d_i']
						replace __fixed_val in `d_i' = 0
					}				
				}
				
								
		} // loop c
		} // loop lag
	} // loop day				
	
	
*Burn-in 14
	replace __l_max = `lag_min' in 1/14
	replace __c_max = `c_min' in 1/14
	replace __se_max =. in 1/14
	replace __sp_max =. in 1/14
	replace __y_max =. in 1/14	
	replace __evi_cat_max=. in 1/2
	

		
*Graph
	local y_label = __cases_label[1]
	local x_label = __day_label[1]
	
	if "`graph'" != "nograph" {
		if "`logarithmic'"!="" {
			replace __mova_case = 1 if __mova_case <=1
			gen __log_mova_case = log10(__mova_case)
				twoway (scatter __log_mova_case __day, sort mcolor(gs10) msymbol(smcircle)) ///
				(scatter __log_mova_case __day if __evi_cat_max==1, sort mcolor(maroon) msymbol(smcircle)) ///
				, ytitle(log(`y_label')) ytitle(, margin(small)) ylabel(, angle(horizontal)) ///
				xtitle(`x_label') xtitle(, margin(small)) ///
				legend(off) scale(1.3) graphregion(fcolor(white))		
		}
		if "`logarithmic'"=="" {
			twoway (scatter __mova_case __day, sort mcolor(gs10) msymbol(smcircle)) ///
			(scatter __mova_case __day if __evi_cat_max==1, sort mcolor(maroon) msymbol(smcircle)) ///
			, ytitle(`y_label') ytitle(, margin(small)) ylabel(, angle(horizontal)) ///
			xtitle(`x_label') xtitle(, margin(small)) ///
			legend(off) scale(1.3) graphregion(fcolor(white))
		}
	}	
	
	
*Restore + Keep variables
	if "`norsample'"!="" {
		restore
		drop __dummy_id
	}	
	
	if "`norsample'"=="" {
		keep __dummy_id __status_cat __evi_cat_max __l_max __c_max __se_max __sp_max __y_max
		tempfile formerge
			save `formerge', replace
			restore
			cap merge 1:m __dummy_id using `formerge',  nogenerate
				drop __dummy_id	
				cap drop _status _lag _c _sens _spec _youden _evi
					cap rename __status_cat _status
					cap rename __evi_cat_max _evi
					cap rename __l_max _lag
					cap rename __c_max _c
					cap rename __se_max _sens
					cap rename __sp_max _spec
					cap rename __y_max _youden
						cap drop __status_cat __evi_cat_max __l_max __c_max __se_max __sp_max __y_max
	}
	
	
	} // quietly
} // data input


*Exit
end
exit


