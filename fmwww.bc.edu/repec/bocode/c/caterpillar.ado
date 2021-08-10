* 1.0.0 13 June 2017 Laura Bellows, laura.bellows@duke.edu

/*** Unlicense (abridged):
This is free and unencumbered software released into the public domain.
It is provided "AS IS", without warranty of any kind.

For the full legal text of the Unlicense, see <http://unlicense.org>
*/

program define caterpillar, rclass byable(recall) sortpreserve
	version 13

	qui cap findfile _gwtmean.ado
	if _rc!=0 {
        	di as err "user-written package _GWTMEAN needs to be installed first;"
         	di as err "use -ssc install _gwtmean- to do that"
         	exit 498
	}

	syntax varlist (min=3 max=3) [if] [in]  [, BY(varlist) GRaph CENter]
	
	marksample touse, novarlist
	
	tokenize `varlist'
	local e `1'
	local s `2'
	local i `3'

	if "`by'"!="" & "`graph'"!="" {
		 di as err "Cannot specify both by and graph option"
 		exit 198		
	}

	qui count if `touse'
	if r(N)==0 {
		di as err "No observations specified"
		exit 198
	}
	
	if "`by'"!="" {
		isid `by' `i'
	}
	else {
		isid `i'
	}

	capture confirm numeric variable `e' `s'
	if _rc!=0 {
		di as err "Standard error and/or estimate is not numeric"
		exit 198
	}

	capture confirm new variable CI_lo CI_hi CI_lo_bon CI_hi_bon null_quantile
	if _rc!=0 {
		di as err "Variable CI_lo, CI_hi, CI_lo_bon, CI_hi_bon, and/or null_quantile is previously defined"
		exit 198
	}

	if "`center'"!="" { 
		capture confirm new variable contrast
		if _rc!=0 {
			di as err "Variable contrast is previously defined"
			exit 198
		}
	}

	quietly {
		tempvar precision contrast
		gen `precision' = 1/(`s')^2 if `touse'
		
		tempvar wtmean
		if "`by'"!="" {
			bysort `by': egen `wtmean' = wtmean(`e') if `touse', weight(`precision')
		}
		else {
			egen `wtmean' = wtmean(`e') if `touse', weight(`precision')
		}
		gen `contrast' = `e' - `wtmean' if `touse'
		drop `wtmean' 

		if "`center'"!="" {
			gen contrast = `contrast' if `touse'
			local c "contrast"
			local title "Centered Estimates with CIs and Null Distribution"
		}
		else {
			local c "`e'"
			local title "Estimates with CIs and Null Distribution"
		}

		tempvar count
		if "`by'"!="" {
			egen `count' = count(`i') if `touse', by(`by')
		}
		else {
			egen `count' = count(`i') if `touse'
		}
		gen CI_lo = `c' - `s' * invnormal(1-.05/(2)) if `touse'
		gen CI_hi = `c' + `s' * invnormal(1-.05/(2)) if `touse'
		gen CI_lo_bon = `c' - `s' * invnormal(1-.05/(2*`count')) if `touse'
		gen CI_hi_bon = `c' + `s' * invnormal(1-.05/(2*`count')) if `touse'
		drop `count'

		preserve
		
		keep if `touse'
		
		forvalues j = 1/99 {
 			gen null_quantile`j'=`s'*invnormal(`j'/100) 
		}
		
		if "`by'"!="" {
			reshape long null_quantile, i(`i' `by') j(j)
			sort `by' null_quantile
			keep if mod(_n,99) == 49
			keep `by' null_quantile
		}
		else {
			reshape long null_quantile, i(`i') j(j)
			sort null_quantile
			keep if mod(_n,99) == 49
			keep null_quantile
		}
		
		tempfile null_quantiles 
		save `null_quantiles', replace
		
		restore

		if "`by'"!="" {
			gsort -`touse' `by' `c'
		}
		else {
			gsort -`touse' `c' 
		}
		merge 1:1 _n using `null_quantiles', nogen
		erase `null_quantiles'

		tempvar zero
		egen `zero' = wtmean(`c') if `touse', weight(`precision')
		replace null_quantile = null_quantile + `zero' if `touse'

		cap label variable contrast	"Centered Estimate"
		label variable CI_lo 		"Lower Bound of 95% CI"
		label variable CI_hi 		"Upper Bound of 95% CI"
		label variable CI_lo_bon 	"Lower Bound of Bonferroni-Corrected CI"
		label variable CI_hi_bon 	"Upper Bound of Bonferroni-Corrected CI"
		label variable null_quantile 	"Null Distribution"

		if "`by'"!="" {
			tempvar Q P df_Q p_Q E_s2 sd_est var_est tau2 tau rho_Q 
			bysort `by': egen `Q' = sum(`contrast'^2*`precision') if `touse'
			bysort `by': egen `P' = count(`contrast') if `touse'
			gen `df_Q' = `P' - 1 if `touse'
			gen `p_Q' = 1 - chi2(`df_Q',`Q') if `touse'
			bysort `by': egen `E_s2'=mean(`s'^2) if `touse'
			bysort `by': egen `sd_est'=sd(`contrast') if `touse'
			gen `var_est' = `sd_est'^2 if `touse'
			gen `tau2' = `var_est' - `E_s2' if `touse'
			gen `tau' = sqrt(`tau2') if `touse'
			replace `tau'=0 if `tau2'<0 & `touse'
			gen `rho_Q' = 1 - `df_Q' / `Q' if `touse'
			replace `rho_Q' = 0 if `rho_Q'<0 & `touse'

			preserve

			keep if `touse'
			keep `by' `Q' `df_Q' `p_Q' `tau' `rho_Q'
			duplicates drop
			tempname mat_Q mat_df_Q mat_p_Q mat_tau mat_rho_Q
			mkmat `Q', matrix(`mat_Q')
			mkmat `df_Q', matrix(`mat_df_Q')
			mkmat `p_Q', matrix(`mat_p_Q')
			mkmat `tau', matrix(`mat_tau')
			mkmat `rho_Q', matrix(`mat_rho_Q') 

			return matrix Q = `mat_Q'
			return matrix df = `mat_df_Q'
			return matrix p = `mat_p_Q'
			return matrix tau = `mat_tau'
			return matrix rho = `mat_rho_Q'
			
			tokenize `by'

			local wcount: word count `by'

			count
			local ncount = r(N)

			local val_list ""
			forvalues n=1(1)`ncount' {
				local totalby`n' ""
				forvalues i=1(1)`wcount' {
					cap confirm string variable ``i'' 
					if _rc==0 {
						replace ``i'' = stritrim(``i'')
						replace ``i'' = subinstr(``i''," ","_",.)
					}
					if `i'==1 {
						local totalby`n' "`=``i''[`n']'"
					}
					else {
						local totalby`n' "`totalby`n''_`=``i''[`n']'"
					}
				}
				if `n'==1 {
					local val_list "`totalby`n''"
				}
				else {
					local val_list "`val_list' `totalby`n''"
				}
			}
			return local levels "`val_list'"
			
			restore

		}
		else {
			tempvar Q P df_Q p_Q E_s2 sd_est var_est tau2 tau rho_Q 
			egen `Q' = sum(`contrast'^2*`precision') if `touse'
			egen `P' = count(`contrast') if `touse'
			gen `df_Q' = `P' - 1 if `touse'
			gen `p_Q' = 1 - chi2(`df_Q',`Q') if `touse'
			egen `E_s2'=mean(`s'^2) if `touse'
			egen `sd_est'=sd(`contrast') if `touse'
			gen `var_est' = `sd_est'^2 if `touse'
			gen `tau2' = `var_est' - `E_s2' if `touse'
			gen `tau' = sqrt(`tau2') if `touse'
			replace `tau'=0 if `tau2'<0 & `touse'
			gen `rho_Q' = 1 - `df_Q' / `Q' if `touse'
			replace `rho_Q' = 0 if `rho_Q'<0 & `touse'


			gsort -`touse'
			return scalar Q = `=`Q'[1]'
			return scalar df = `=`df_Q'[1]'
			return scalar p = `=`p_Q'[1]'
			return scalar tau = `=`tau'[1]'
			return scalar rho = `=`rho_Q'[1]'
		}

		if "`graph'"!="" {
			gsort -`touse' `c'
			tempvar est_num 
			gen `est_num' = _n if `touse'

			foreach y in rho_Q tau p_Q {
				qui sum ``y'' if `touse', detail
				local `y' = trim("`: di %9.2f r(p50)'")
			}

			foreach y in df_Q Q {
				qui sum ``y'' if `touse', detail
				local `y' = trim("`: di %9.0f r(p50)'")
			}

			local xaxisstuff "xscale(noline) xlabel(none, nolabels)"
			local estimate "(scatter `c' `est_num' if `touse', mcolor(black) msize(vsmall) msymbol(diamond))"
			local reference "(line `zero' `est_num' if `touse', lcolor(gs6) lwidth(medthin) lpattern(solid))"
			local null "(line null_quantile `est_num' if `touse', lcolor(gs4) lwidth(medthick))"
			local confidence "(rcapsym CI_lo CI_hi `est_num' if `touse', lcolor(gs8) lwidth(medthin) lpattern(solid) mcolor(gs8) msize(vsmall) msymbol(none))"
			local confidence2 "(rcapsym CI_lo_bon CI_lo `est_num' if `touse', lcolor(gs8) lwidth(medthick) lpattern(dot) mcolor(gs8) msize(small) msymbol(none))"
			local confidence3 "(rcapsym CI_hi CI_hi_bon `est_num' if `touse', lcolor(gs8) lwidth(medthick) lpattern(dot) mcolor(gs8) msize(small) msymbol(none))"
			local confidence4 "(scatter CI_hi_bon `est_num' if `touse', mcolor(gs8) msize(small) msymbol(O))"
			local confidence5 "(scatter CI_lo_bon `est_num' if `touse', mcolor(gs8) msize(small) msymbol(O))"
			local note: di "Q(`df_Q')=`Q', p=`p_Q', {&tau}=`tau', {&rho}=`rho_Q'"

			twoway `confidence2' `confidence3' `confidence' `estimate' `null' `reference' `confidence4' `confidence5', `xaxisstuff' title("`title'") xtitle("`i'") legend(order(4 "Contrasts" 5 "Null Distribution" 3 "95% Pointwise Confidence Intervals" 1 "Bonferroni Confidence Intervals") rows(2)) legend(size(small) region(lpattern(blank) lwidth(none))) ylabel(, nogrid labsize(vsmall)) note("`note'", position(6) ring(0) size(small))

			drop `est_num' 
		}

		drop `zero' `precision' `contrast'
	}
	
end 

