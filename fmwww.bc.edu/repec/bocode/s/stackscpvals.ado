*! version 1.2  Justin Wiltshire 11/11/2024 - Implement synthetic control placebo sampling for averaging and calculating p-values

* Program stackscpvals: automates the stacking and averaging of (generally, modified) 
* synthetic control estimated gaps for multiple treated units and the donor pool units, 
* the creation of the sample empirical ditribution of placebo 
* average treatment effects, and the calculation of specified p-values. 
program stackscpvals, rclass
	version 15.1
	#delimit ;
		syntax , 
		gap(string)
		time(string)
		unit(string)
		pvalues(string)
		filepath(string)
		[
		filepath_2(string)
		filepath_3(string)
		filepath_4(string)
		filepath_5(string)
		filepath_6(string)
		filepath_7(string)
		filepath_8(string)
		filepath_9(string)
		savepath(string)
		savename(string)
		keeptrunits(numlist min=2)
		numavg(numlist min=1 max=1 >0 integer) 
		emin(numlist min=1 max=1 <0 integer) 
		emax(numlist min=1 max=1 >0 integer) 
		avgwts(string)
		balance
		* 
		]
		;
	#delimit cr
	
	* Rename locals
	local tvar "`time'"
	local pvar "`unit'"
	local avgs "`numavg'"
	if "`uW'" != "" {
		local unique_W "unique_W"
	}
	
	* If keeptrunits() is specified
	if "`keeptrunits'" != "" {
		local _trunits=subinstr("`keeptrunits'", " ", ",", .)
	}
	if "`keeptrunits'" == "" {
		local keeptrunits ""
		local _trunits "."
	}
	
	* Initialize pvalues specification locals
	local pvaluesvariance = 0
	local pvaluesrmspe = 0
		
	* Parse the pvalues() string
	foreach s of local pvalues {
		capture assert "`s'" == "variance" | "`s'" == "rmspe"
		if _rc != 0 {
			di as err "pvalues() contains an invalid specification. Only -variance-, -rmspe-, or both are allowed. Specifying pvalues() without any options will be treated as if pvalues() is not specified"
			exit 198
		}
		local pvalues`s' = 1
	}
	if "`avgs'" == "" {
		local avgs = 100
	}

	if `pvaluesrmspe' == 1 & `avgs' < 30 {
		local avgs = 30
	}
	if `pvaluesvariance' == 1 {
		local avgs = 1000
	}
	
	* Tempfiles
	tempfile core
	tempfile core2
	tempfile core3

	* Get filelist
	local filelist: dir "`filepath'" files "*.dta"
	
	* Append the estimates and adjust as appropriate
	local counter = 0
	foreach f of local filelist {
		if strpos("`f'", "_ate") == 0 {
			local g = subinstr("`f'", "tr_", "", .)
			local g = subinstr("`g'", ".dta", "", .)
			if "`keeptrunits'" == "" | ("`keeptrunits'" != "" & inlist(`g', `_trunits')) {
				qui use "`filepath'/`f'", clear
				
				* Ensure specified variables exist
				foreach y in gap time unit {
					capture confirm variable ``y''
					if _rc != 0 {
						di as err "`y'() was defined as ``y'', but variable ``y'' is not found in the data"
						exit 198
					}
				}
				if "`avgwts'" != "" {
					capture confirm variable `avgwts'
					if _rc != 0 {
						di as err "avgwts() was defined as `avgwts', but variable `avgwts' is not found in the data"
						exit 198
					}
				}

				
				* Confirm local macros
				qui rename _time `tvar'
				if `counter' == 0 {
					capture assert `pvar'
					if _rc != 0 {
						local pvar ""
					}
				}
        				
				* Clean up
				qui keep `pvar' `tvar' `gap' `unique_W' trunit trperiod `avgwts'
				qui keep if !mi(`gap')
				qui gen _tm = `tvar'
				qui format _tm `tvarformat'
				if "`emin'" != "" | "`emax'" != ""  {
					capture assert "`emin'" != ""
					if _rc != 0 {
						local emin = -5
					}
					capture assert "`emax'" != ""
					if _rc != 0 {
						local emax = 5
					}
					qui replace _tm = `tvar' - trperiod
					qui keep if inrange(_tm, `emin', `emax')
				}
				if `counter' > 0 {
					qui append using "`core'"
				}
				qui save "`core'", replace
				local counter = `counter' + 1
			}
		}
	}
	
	* If additional filepaths are specified
	forval m = 2/9 {
		if "`filepath_`m''" != "" {
		
			* Get filelist
			local filelist: dir "`filepath_`m''" files "*.dta"
			
			* Append the estimates and adjust as appropriate
			foreach f of local filelist {
				if strpos("`f'", "_ate") == 0 {
					local g = subinstr("`f'", "tr_", "", .)
					local g = subinstr("`g'", ".dta", "", .)
					if "`keeptrunits'" == "" | ("`keeptrunits'" != "" & inlist(`g', `_trunits')) {
						qui use "`filepath_`m''/`f'", clear
						
						* Ensure specified variables exist
						foreach y in gap time unit {
							capture confirm variable ``y''
							if _rc != 0 {
								di as err "`y'() was defined as ``y'', but ``y'' is not found in the data"
								exit 198
							}
						}
						
						* Confirm local macros
						qui rename _time `tvar'
						if `counter' == 0 {
							capture assert `avgwts'
							if _rc != 0 {
								local avgwts ""
							}
							capture assert `pvar'
							if _rc != 0 {
								local pvar ""
							}
						}
						
						* Clean up
						qui keep `pvar' `tvar' `gap' `unique_W' trunit trperiod `avgwts'
						qui keep if !mi(`gap')
						qui gen _tm = `tvar'
						qui format _tm `tvarformat'
						if "`emin'" != "" {
							qui replace _tm = `tvar' - trperiod
							qui keep if inrange(_tm, `emin', `emax')
						}
						qui append using "`core'"
						qui save "`core'", replace
					}
				}
			}
		}
	}
	
	* Update save filepath if specified
	if "`savepath'" != "" {
		local filepath "`savepath'"
	}
	
	* Update save filename if specified
	local keepname "stackedsc_att"
	if "`savename'" != "" {
		local keepname "`savename'"
	}

	* Calculate the estimated average treatment effect for treated units
	di "Calculating the estimated average treatment effect for treated units"
	di
	qui use "`core'", clear
	if "`uW'" != "" {
		qui levelsof trunit if unique_W == 0, local(droptrunits)
		if "`droptrunits'" != "" {
			di
			di as txt "Treated units `droptrunits' do not have unique W matrices and are being dropped as -unique_w- is specified in the allsynth option stacked()"
			di
		}
		qui levelsof trunit if unique_W == 1, local(keeptrunits)
		if "`keeptrunits'" == "" {
			di
			di as err "No treated units are left after dropping units without unique W matrics. Try a different specification"
			exit 198
		}
		if "`droptrunits'" == "" {
			di
			di as txt"All treated units have unique W matrices"
			di
		}
		qui keep if unique_W == 1
	}
	qui sum trperiod
	local trperiod = r(mean)
	capture assert trperiod == `trperiod' if !mi(trperiod)
	if _rc != 0 & "`emin'" == "" {
		local emin = -5
		local emax = 5
		qui replace _tm = `tvar' - trperiod
		qui keep if inrange(_tm, `emin', `emax')
	}
	if "`emin'" != "" {
		local trperiod = 0
		qui sum `tvar'
		local eperiods = r(max) - r(min)
		format _tm %9.0g
	}
	qui save "`core'", replace
	qui keep if `pvar' == trunit
	if "`balance'" != "" {
		quietly {
			qui levelsof `pvar', local(_Units)
			local nunits : list sizeof _Units
			bysort _tm: gen _tmCount = _N
			qui keep if _tmCount == `nunits'
		}
	}
	if "`avgwts'" != "" {
		local awts "[aw=`avgwts']"
	}
	collapse (mean) `gap' `awts', by(_tm)
	qui drop if mi(_tm)
	qui compress
	qui save "`filepath'/`keepname'.dta", replace
	list 
	di
	di as txt "Estimated average treatment effects saved in `filepath'/`keepname'.dta"
	di

	* Set seed
	set seed 12345
		
	di
	di "Randomly sampling `avgs' placebo average treatment effects"
	di
	qui use "`core'", clear
	qui levelsof trunit, local(trunits)
	qui drop if `pvar' == trunit
	qui save "`core2'", replace		
	forval n = 1/`avgs' {
		if mod(`n',20) == 0 {	
			display "`n'" _continue
		}
		if mod(`n',20) != 0 {
			if mod(`n',5)== 0 {
				display "." _continue
			}
		}
			
		* Randomly select a placebo treated unit from each actually treated unit
		qui use "`core2'", clear
		qui gen p = runiform() if `tvar' == trperiod
		qui sort trunit p
		bysort trunit: gen px = (_n == 1)
		bysort `pvar' trunit: egen keepdonor = max(px)
		qui keep if keepdonor == 1
		qui sort `pvar' `tvar'
		
		* Calculate the sample average treatment effect
		if "`balance'" != "" {
			qui levelsof trunit, local(_Units)
			local nunits : list sizeof _Units
			bysort _tm: gen _tmCount = _N
			qui keep if _tmCount == `nunits'
		}
		collapse (mean) `gap' `awts', by(_tm)
		qui compress
		qui gen _placeboID = `n'
		if `n' > 1 {
			qui append using "`core3'"
		}
		qui save "`core3'", replace
		}
		qui append using "`filepath'/`keepname'.dta"
	qui replace _placeboID = 0 if mi(_placeboID)
	qui save "`core3'", replace
	
	quietly {
	
		* Placebo RMSPE and p-val estimation
		if `pvaluesrmspe' == 1 {
			*** Calculate the RMSPEs and RMSPE p-values
			local pvar _placeboID
			local tvar _tm
			qui sum `tvar'
			local T0 = `trperiod' - r(min)
			local T1 = r(max) - `trperiod' + 1
			qui levelsof `tvar' if `tvar' >= `trperiod', local(trtvars)
			qui gen rmspe = .
			qui levelsof(`pvar'), local(id)
			bysort `tvar': gen N = _N
			foreach i of local id {
				qui egen xpre = total(`gap'^2) if `tvar' < `trperiod' & `pvar' == `i'
				qui gen xpre2 = xpre/`T0'
				qui egen mspe_pre = max(xpre2) if `pvar' == `i'
				qui drop x*
					
				* Treated period
				foreach tt of local trtvars {
					qui egen xpost2 = mean(`gap'^2) if inrange(`tvar', `trperiod', `tt') & `pvar' == `i'
					qui egen mspe_post_`tt' = max(xpost2) if `pvar' == `i'
					qui replace rmspe = mspe_post_`tt'/mspe_pre if `pvar' == `i' & `tvar' == `tt'
					qui drop x* mspe_post_`tt'
				}
				qui drop mspe*
			}
					
			* Generate RMSPE-ranked p-values
			qui gsort `tvar' -rmspe
			bysort `tvar': gen rmspe_rank = _n  if `tvar' >= `trperiod'
			qui gen p = rmspe_rank/N if `tvar' >= `trperiod'
			qui order `pvar' `tvar' `gap' rmspe* p N
			local pvalrmspevars "rmspe* p N"
		}
		qui save "`core3'", replace

		* Placebo variance estimation
		if `pvaluesvariance' == 1 {
			
			local pvar _placeboID
			local tvar _tm
			
			* Set seed
			set seed 12345
					
			* Re-sample 1000 times
			tempfile _Plvar_S
			qui use "`core3'", clear
			qui drop if `pvar' == 0

			* Get the estimated variance and standard eror
			qui collapse (mean) _Avg_plgap=`gap', by(`tvar')
			qui merge 1:m `tvar' using "`core3'", nogen norep
			qui gen _Sq_demean = (`gap' - _Avg_plgap)^2
			qui collapse (mean) _Pl_var=_Sq_demean `_plvarbc', by(`tvar')
			qui gen _Se = sqrt(_Pl_var)
			qui save "`_Plvar_S'", replace

			* Merge in and estimate 95% CIs
			qui merge 1:m `tvar' using "`core3'", nogen norep
			qui keep if `pvar' == 0
			qui keep `tvar' `pvar' `gap' _Se
			qui gen _Tstat = abs(`gap')/_Se
			qui gen _Pval = 2*ttail(`avgs',(_Tstat))
			qui gen LB_95 = `gap' - 1.96*_Se
			qui gen UB_95 = `gap' + 1.96*_Se
			qui drop `gap'
			qui merge 1:1 `tvar' `pvar' using "`core3'", nogen norep
			qui sort `tvar' `pvar' `gap' `pvalrmspevars' _Se* _Pval*
			local pvalvariancevars "_Se* _Tstat* _Pval* LB* UB*"
			qui compress
		}
	}
		
	qui save "`filepath'/`keepname'_distn.dta", replace
	qui sort _placeboID _tm
	qui rename `gap' corrected_gap
	di ""
	di
	di as txt "Sample distribution saved in `filepath'/`keepname'_distn.dta"
	di
	
end
