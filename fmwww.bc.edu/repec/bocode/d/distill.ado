*! 1.00 Ariel Linden 02Oct2023

capture program drop distill
program distill, rclass byable(recall)

version 13 

	syntax varname(numeric) [if] [in] , ///
		TReat(varname numeric)			/// treatment is required
		PScore(varname numeric)			/// propensity score is required
		[								///
		NQuantiles(integer 5)			/// number of quantiles 
		LEvel(cilevel)					/// CIs
		FIG FIG2(str asis)				/// generate forest-plot
		* 								/// all glm and twoway options
		]

	quietly {
		marksample touse 
		count if `touse' 
		if r(N) == 0 error 2000
		local N = r(N) 
		replace `touse' = -`touse'

		tokenize `varlist'
		local outcome `1'

		
		// ensure treatment variable is binary with values of 0 and 1
		quietly tabulate `treat' if `touse' 
		if r(r) != 2 { 
			di as err "With a binary treatment, `treat' must have exactly two values (coded 0 or 1)."
			exit 420  
			} 
		else if r(r) == 2 { 
			capture assert inlist(`treat', 0, 1) if `touse' 
			if _rc { 
				di as err "With a binary treatment, `treat' must be coded as either 0 or 1."
				exit 450 
			}
		}
	
		// generate quantiles (strata) by treatment group
		capture drop _xtile
		tempvar _xtile1 _xtile2
		xtile `_xtile1' = `pscore' if `treat'==0 & `touse', nq(`nquantiles')
		xtile `_xtile2' = `pscore' if `treat'==1 & `touse', nq(`nquantiles')
		gen _xtile = cond(`_xtile1' !=.,`_xtile1',`_xtile2')
		drop `_xtile1' `_xtile2'

		levelsof _xtile if `touse'
		local maxlev = r(r)
		label var _xtile "`maxlev' quantiles of `pscore'"
	
		// estimate the outcome for each strata and save results to a matrix
		forvalue i = 1/`maxlev' {
			glm `outcome' `treat' if _xtile == `i' & `touse', /*level(`level')*/ `options'
			mat A`i' = r(table)
			mat A`i' = A`i'[1...,"`outcome':`treat'"]
			mat colnames A`i' = Strata`i'
		}

		matrix ALL = A1
		foreach i of numlist 2/`maxlev'{
			mat ALL = ALL,A`i'
			mat drop A`i'
		}
		mat drop A1
	
		// display "exp(b)" when specifying "eform"
		local exp = ALL[9,1] 
		if `exp' == 1 {
			mat rowname ALL = "exp(b)" "std. err." "z" "P>|z|" "[`level'% conf." "interval]"
			mat roweq ALL = "exp(b)" "std. err." "z" "P>|z|" "[`level'% conf." "interval]"
		}
		else {
			mat rowname ALL = "Coefficient" "std. err." "z" "P>|z|" "[`level'% conf." "interval]"
		}	

	} // end quietly


	// keep pertinent data and present it in a nice table
	mat ALL = ALL[1..6,1...]'
	
	
	// formatting the matrix table 
	local cnt = `maxlev' - 1
	local ands = `cnt'*"&"
	local rs --`ands'-


	if `exp' == 1 {
		di _n
		di "family(`e(varfunct)') link(`e(linkt)') vce(`e(vcetype)')"
		matlist ALL, cspec(& %12s | %9.0g & %9.0g & %5.2f & %7.3f & w10 %9.0g & %9.0g &) ///
			rspec(`rs') title(Number of obs = `N') coleqonly showcoleq(combined)
	}
	else {
		di _n
		di "family(`e(varfunct)') link(`e(linkt)') vce(`e(vcetype)')"
		matlist ALL, cspec(& %12s | w11 %9.0g & C %9.0g & %5.2f & %7.3f & w10 %9.0g & %9.0g &) ///
		rspec(`rs') title(Number of obs = `N')
	}	
 
	if `"`fig'`fig2'"' != "" {	
		preserve
		svmat ALL
		quietly {
			gen name = .
			forvalues i = 1/`maxlev' {
				replace name = `i' in `i'
			}
		} // end quietly
		if `exp' == 1 {
			local xline = 1
			local xtitle "`outcome' (exponentiated)"
		} 
		else {
			local xline = 0
			local xtitle "`outcome'"
		}
		local note "family(`e(varfunct)') link(`e(linkt)') vce(`e(vcetype)')"

		twoway(rcap ALL5 ALL6 name, hor) ///
			(scatter name ALL1), ///
			ytitle("Strata") ///
			ylabel(1(1)`maxlev', angle(hor)) ///
			ysc(reverse) ///
			xtitle(`xtitle') ///
			xscale(titlegap(3)) ///
			xline(`xline') xlabel(, nogrid ) `favopt' ///
			legend(off) `fig2' ///
			note(`note')

		restore

	}	// end fig
	
		/* saved results */ 
		return scalar N = `N'
		return scalar nq = `nquantiles'
		return matrix table = ALL

end


