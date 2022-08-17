*! v1.1 FRA 8/5/2022 Redef not yet treated. 
*! v1   FRA 8/5/2022 Has almost everything we need
program jwdid, eclass
	version 14
	syntax varlist [if] [in] [pw], Ivar(varname) Tvar(varname) Gvar(varname) [never group method(name)]
	marksample  touse
	markout    `touse' `ivar' `tvar' `gvar'
	gettoken y x:varlist 
	
	easter_egg
	** Count gvar
	/*qui:count if `gvar'==0 & `touse'==1 
	if `r(N)'==0 {
		*qui:sum `gvar' if `touse'==1 , meanonly
		
	}*/
	** Take out of sample units that have always been treated.
	tempvar tvar2
	qui:bysort `touse' `ivar': egen long `tvar2'=min(`tvar')
	qui:replace `touse'=0 if `touse'==1 & `tvar2'>=`gvar' & `gvar'!=0 & `tvar'>=`gvar'
	** If no never treated
	qui:count if `gvar'==0 & `touse'==1 
	if `r(N)'==0 {
		qui:sum `gvar' if `touse'==1 , meanonly
		qui:replace `touse'=0 if `touse'==1 & `tvar'>=`r(max)' 
	}
	qui:capture drop __tr__
	qui:gen byte __tr__=0 if `touse'
	qui:replace  __tr__=1 if `tvar'>=`gvar' & `gvar'>0  & `touse'
	qui:replace  __tr__=1 if `touse' & "`never'"!=""
	qui:capture drop __etr__
	qui:gen byte __etr__=0 if `touse'
	qui:replace  __etr__=1 if `touse' & `tvar'>=`gvar' & `gvar'>0
	
	qui:levels `gvar' if `touse' & `gvar'>0, local(glist)
	sum `tvar' if `touse' , meanonly
	qui:levels `tvar' if `touse' & `tvar'>r(min), local(tlist)
	** Center Covariates
	if "`weight'"!="" local wgt aw
	if "`x'"!="" {
			capture drop _x_*
			qui:hdfe `y' `x' if `touse'	[`wgt'`exp'], abs(`gvar') 	keepsingletons  gen(_x_)
			capture drop _x_`y'
			local xxvar _x_*
	}
	***
	foreach i of local glist {
		foreach j of local tlist {
			if "`never'"!="" {
				local xvar `xvar' c.__tr__#i`i'.`gvar'#i`j'.`tvar' ///
							  i`i'.`gvar'#i`j'.`tvar'#c.(`xxvar') 
 			
			}
			else if `j'>=`i' {
				local xvar `xvar' c.__tr__#i`i'.`gvar'#i`j'.`tvar' ///
							 i`i'.`gvar'#i`j'.`tvar'#c.(`xxvar')   
			}

		}
	}
	** for xs
	
	foreach i of local glist {
		local ogxvar `ogxvar' i`i'.`gvar'#c.(`x')
	}
	foreach j of local tlist {
		local otxvar `otxvar' i`j'.`tvar'#c.(`x')
	}
 	
	if "`method'"=="" {
		if "`group'"=="" {
			reghdfe `y' `xvar'   `otxvar'	///
				if `touse' [`weight'`exp'], abs(`ivar' `tvar') cluster(`ivar') keepsingletons	
		}	
		else {		 
			reghdfe `y' `xvar'  `x'  `ogxvar' `otxvar'  ///
			if `touse' [`weight'`exp'], abs(`gvar' `tvar') cluster(`ivar') keepsingletons
		}
	}
	else {
		`method'  `y' `xvar'  `x'  `ogxvar' `otxvar' i.`gvar' i.`tvar' ///
		if `touse' [`weight'`exp'], cluster(`ivar') 
	}
	
	ereturn local cmd jwdid
	ereturn local cmdline jwdid `0'
	ereturn local estat_cmd jwdid_estat
	if "`never'"!="" ereturn local type  never
	else 			 ereturn local type  notyet
	ereturn local ivar `ivar'
	ereturn local tvar `tvar'
	ereturn local gvar `gvar'
	
end


program easter_egg
	
	local date_to = date("`c(current_date)'","DMY")
	local month   = month(`date_to')
	local day     = day(`date_to')
	
	if runiform()<0.001 | (`month'==8 & `day'==6) {
	display in w "{p}Hi there, thank you for using this command. I hope you are finding this 'easter egg' as a surprised, and not because you " ///
	"decided to take a peak on the code. But if you did, shame on me for not making a better easter egg {p_end}"
	display in w "{p}Anyways, This easter egg is for my Daughter! Yes as of August 6th 2022 (Viva Bolivia) my little one was born!. " _n  ///
		"so if you happen to read this, two things happen. Either you were in the 0.1% lucky to see this, or its my little one birthday. If the latter  please send my little one Abby, a Happy Birthday! {p_end}"
	}
end