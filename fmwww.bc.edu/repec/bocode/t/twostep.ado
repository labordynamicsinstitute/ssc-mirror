! version 1.0.6 Juni 17, 2021 @ 15:23:42 UK
*! Multilevel Analysis With 2 Step Approach

// History
// twostep 1.0.6: Option -method()- not used for edv in prefix. -> fixed (thanks Ben Jann) 
// twostep 1.0.5: Check if clustervars are constant
// twostep 1.0.4: Add -unitregby- plot added (Bowers/Drake's fig 3)
// twostep 1.0.2: Again new syntax, mkdata -> mk2nd, 2ndlevl->edv, coefplot -> dot
// twostep 1.0.1: New syntax -> prefix style; 2ndlevel depname prefixed with _b_ , version 16
// twostep 1.0.0: New command design 
// Initial version: -edvreg_joe- added Factor Variable Notation
// Predecessor: -edvreg- by Lewis/Linzer

// Syntax: twostep varlist [, stats(string)]: model depvar indepvars [options] || secondlevelcmd 

* Caller for subprogramms

program twostep, eclass
version 16
	
	// Check if Prefix 
	capture _on_colon_parse `0'
	if _rc == 198 {
		twostep_edv  `0'
		exit
	}

	// All the prefixed commands
	local bystring `s(before)'
	local 0 `s(after)'
	gettoken firstlevelstring secondlevelstring: 0, parse("||")
	local secondlevelstring: subinstr local secondlevelstring "||" "", all

	ParseFirst `firstlevelstring'
	local firstcmd `r(subcmd)'
	
 	ParseSecond `secondlevelstring'
	local clear `r(clear)'
	local secondcmd `r(subcmd)'

	// Call Subprograms
	if "`r(subcmd)'" == "mk2nd" {
		quietly d, s
		if r(changed) == 1 & "`clear'" == "" {
			display "{err}no; data in memory would be lost"
			exit 4
		}
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring' 
		
		exit
	}

	// Run the Models and Perform Lewis Linzer
	else if "`secondcmd'" == "edv"  {
		ParseFirst `firstlevelstring'
		local model `r(subcmd)'

		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring'

		ParseSecond `secondlevelstring'
		twostep_edv `r(secondlevelvars)' `r(if)' `r(in)', method(`r(method)') `r(options)'

		if substr("`model'",1,3) != "reg" display `"{txt}Warning: First level model not -regress-. Use on own risk"'
		ereturn repost
		exit
	}
	

	// Component-plus-Residual Plot for all the 1st Level models
	else if "`firstcmd'" == "unitcpr" {
		gettoken litter firstlevelstring: firstlevelstring
		
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'

		twostep_unitcpr `bystring': `firstlevelstring' || `secondlevelstring'
		exit
	}

	// Component-plus-Residual Plot for the 2nd level linear regression
	if "`secondcmd'" == "clustercpr" {

		ParseFirst `firstlevelstring'
		local model `r(subcmd)'

		preserve
		tempvar touse wgt
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring'

		ParseSecond `secondlevelstring'
		quietly twostep_edv `r(secondlevelvars)' `r(if)' `r(in)', `r(options)' keepweights(`wgt') method(`r(method)')

		if substr("`model'",1,3) != "reg" display `"{txt}Warning: First level model not -regress-. Use on own risk"'
		ereturn repost

		gettoken litter allsecondlevelopts : secondlevelstring, parse(",")
		twostep_clustercpr `wgt' `allsecondlevelopts' 
		
	}

	// The -unitregby- Plots (i.e. Bowers/Drakes figure 3)
	else if "`secondcmd'" == "unitregby" {
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'

		ParseSecond `secondlevelstring'
		local secondlevelvars `r(secondlevelvars)'
		gettoken seconddepvar secondindepvar: secondlevelvars
		local unitby `r(unitby)'
		
		local secondlevelstring = subinstr("`secondlevelstring'","`seconddepvar'","_all",.)

		summarize `=subinstr("`seconddepvar'","_b_","",.)', meanonly
		local min = r(min)
		local max = r(max)
		
		twostep_mk2nd `unitby' `bystring': `firstlevelstring' ||  `secondlevelstring'
		ParseByString `bystring'
		local byvars  `r(byvar)' 

		gettoken secondlevelstring allsecondlevelopts : secondlevelstring, parse(",")
		local allsecondlevelopts = subinstr("`allsecondlevelopts'",",","",1)

		twostep_unitregby `secondlevelvars' ///
		  , min(`min') max(`max') `allsecondlevelopts' _byvars(`byvars') unitby(`unitby') 
	}


	// Dot chart for the requested 1st level coeficient
	else if "`secondcmd'" == "dot" {
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring'
		ParseByString `bystring'
		local byvar  `r(byvar)'

		gettoken secondlevelstring allsecondlevelopts : secondlevelstring, parse(",")
		local allsecondlevelopts = subinstr("`allsecondlevelopts'",",","",1)
		
		twostep_dot `secondlevelstring', over(`byvar') `allsecondlevelopts'
	}

	// An arbitrary Fallback command for the 2nd level
	else {
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring'
		twostep_fallback `secondlevelstring'
		
	}
end
	
* Create 2nd Level Data

program define twostep_mk2nd
	
	capture _on_colon_parse `0'
	local bystring `s(before)'
	local 0 `s(after)'
	
	// Parse By-String
   ParseByString `bystring'
	local byvar  `r(byvar)'
	local addstats `r(addstats)'
	
	// Parse First Level Information
	gettoken 0 secondlevel: 0, parse("||")
	local secondlevel: subinstr local secondlevel "||" "", all
	gettoken model 0:0
	
	syntax varlist(fv)  ///
	  [fweight aweight pweight]    ///
	  [if] [in] ///
	  [, vce(string) NOCONStant Hascons tsscons eform(string) clear]
	gettoken firstdepvar firstindepvar: varlist
	
	// Parse Second Level Information
	ParseSecond `secondlevel'
	local iflist `r(iflist)'
	local secondif `r(if)'
	local secondin `r(in)'
	local using `r(using)'
	local secondlevelvars `r(secondlevelvars)'
	gettoken seconddepvar secondindepvar: secondlevelvars

	tempfile 1stlevelcoefs 2ndlevelvars thisdata 
	tempvar ifuse
	
	quietly {
		
		// Swap 2nd level data 
		if `"`using'"' == `""' {
			fvexpand `secondindepvar'
			if "`r(fvops)'" != "" {
				RemoveFvBits `secondindepvar'
				local secondindepvar `r(cleanlist)' 
			}
			save `thisdata'
			keep `byvar' `secondindepvar' `iflist'

			// Check cluster variables to be constant
			gen byte `ifuse' = 0 
			replace `ifuse' = 1 `secondif' `secondin'
			foreach var of local secondindepvar {
				capture bys `ifuse' `byvar' (`var'): assert `var'[1]==`var'[_N] `secondif' `secondin'
				if _rc {
					noi display `"{err}`var' is not constant within `byvar'"'
					exit _rc
				}
			}
			
			bys `byvar': keep if _n==1
			save `2ndlevelvars'
			use `thisdata'
		}
		
		// Statsby does not allow pweights. I simulate them with aweights and vce(robust)
		if "`weight'" == "pweight" {
			local weight "aweight"
			if "`vce'" == "" {
				local vce vce(robust)
			}
			
			else {
				local vce `vce' robust
				local vce vce(`: list uniq vce')
			}
			
		}	
		
		// Do we use factor-variable notation?
		fvexpand `firstindepvar'
		local fvops = "`r(fvops)'"=="true"

		// Run Within First Level Models
		statsby _b _se _n_model = e(N) `addstats', `clear' by(`byvar') saving(`1stlevelcoefs', double):  ///
		  `model' `firstdepvar' `firstindepvar' [`weight'`exp'] `if' `in',  `vce' `noconstant' `hasconstant' `tsconstant'
		use `1stlevelcoefs', clear
		if `"`using'"' == `""' {
			merge 1:1 `byvar' using `2ndlevelvars', keep(3) nogen
		}
		else merge 1:1 `byvar' `using', keep(3) nogen
		
		// Harmonize variable names in case of factor variable notation
		if `fvops' {
			foreach var of varlist _stat_* {
				local newname: variable label `var'
				local newname: subinstr local newname "[" "_", all
				local newname: subinstr local newname "." "_", all
				local newname: subinstr local newname "]" "", all
				local newname: subinstr local newname "#" "X", all
				rename `var' `newname'
			}
		}

		// I Harmonize the variable names a bit further, if possible
		foreach var of varlist *_b_* {
			capture ren `var' `=regexr("`var'","_*[0-9a-z]+_b_","_b_")'
		}
		foreach var of varlist *_se_* {
			capture ren `var' `=regexr("`var'","_*[0-9a-z]+_se_","_se_")'
		}
		foreach var of varlist _eq* {
			capture ren `var' `=regexr("`var'","_eq[0-9]+_","_")'
		}
		
		// Keep what is requested only
		if "`seconddepvar'" != "_all" {
			local seofdepvar = subinstr("`seconddepvar'","_b_","_se_",1)
			keep `byvar' `seconddepvar' `seofdepvar' _n_model  `secondindepvar' `iflist'
		}
		
		if "`secondin'" != "" | "`secondif'" != "" keep `secondin' `secondif' 
	}
end

* edv (Re-Implentation of Lewis/Linzer's edvreg)
program define twostep_edv

	syntax varlist(fv) [if] [in] [, Method(string) level(passthru) vce(passthru) NOCONStant Hascons keepweights(string) *]
	gettoken depvar indepvars: varlist
	local sename = subinstr("`depvar'", "_b","_se",.)

	tempvar omegavar sumomegavar weight

	if "`method'" == "" local method fgls1
  local creator = cond("`method'"=="fgls2","(1/_n_model)^2","`sename'^2")  // DEBUG line
*	local creator = cond("`method'"=="fgls2","(1/_n_model)^2","`sename'^2 * _n_model") // DEBUG line
	
	quietly {
		gen double `omegavar'  = `creator' `if' `in'
		sum `omegavar', meanonly
		local sumomegavar = r(sum)
		
		regress `depvar' `indepvars' `if' `in'
		local dof = e(df_r) // DEBUG line
		local rss = e(rss)
		
		// Remove base-categories from varlist
		fvexpand `indepvars'
		local list=r(varlist)
		if "`r(fvops)'" == "true" {
			foreach varname of local list {
				local x `x' `= regexr(`"`varname'"',`".+b\..+"',`""')'
			}
			local indepvars `x'
		}
		
		// Create the weighting variable using one of the methods.
		gen double `weight' = . 
		twostep_`method' `indepvars' `if' `in' ///
		  , omega(`omegavar') rss(`rss') sumomegavar(`sumomegavar') dof(`dof') weight(`weight')
		local sigma2 = r(sigma2)
		local omega2 = r(omega2)
	}	
	regress `depvar' `indepvars' [aw=`weight'] `if' `in', `level' `vce' `noconstant' `hascons' `options'
	disp "{txt}Sampling Variance Proportion = {res}" %4.0g `omega2'/(`omega2' + `sigma2')

	if "`keepweights'" != "" gen double `keepweights' = `weight' if e(sample)
end
	
* cprplot for first level regressions
program define twostep_unitcpr

	capture _on_colon_parse `0'
	local bystring `s(before)'
	local 0 `s(after)'
	
	// Parse First Level Information
	gettoken 0 secondlevel: 0, parse("||")
	local secondlevel: subinstr local secondlevel "||" "", all
	
	syntax varlist(fv)  ///
	  [fweight aweight pweight]    ///
	  [if] [in] ///
	  [using]  ///
	  [ , vce(string) NOCONStant Hascons tsscons eform(string) ]
	gettoken firstdepvar firstindepvar: varlist

	// Parse Second Level Information
	ParseSecond `secondlevel'
	local iflist `r(iflist)'
	local using `r(using)'
	local secondif `r(if)'
	local secondin `r(in)'
	local seconddepvar `r(subcmd)' 
	local secondindepvar  `r(secondlevelvars)'
	local scopts `r(scopts)'
	local allopts `r(allopts)'
	local regopts `r(regopts)'
	local lowessopts `r(lowessopts)'
	local byopts `r(byopts)'
	local options `r(options)'
	local title `r(title)'
   local ytitle `r(ytitle)'
   local legend  `r(legend)'
   local note  `r(note)'

	gettoken order: secondindepvar
	local seconddepvar = subinstr("`seconddepvar'","_b_","",.)

	ParseByString `bystring'
	local byvar `r(byvar)'
	local statlist `r(statlist)'

	
	quietly {

		tempvar totalresid totalcpr totalcprhat ///
		  withincpr withinb withinresid  ///
		  rank	
		
		// Overall regression
		regress `firstdepvar' `firstindepvar' [`weight'`exp'] `firstin' `firstif', `vce' `noconstant' `hasconstant' `tsconstant' 
		predict double  `totalresid', resid
		gen `totalcpr' = _b[`seconddepvar']*`seconddepvar' + `totalresid'
		regress `totalcpr' `seconddepvar' 
		predict double  `totalcprhat' 
		drop `totalresid' `totalcpr' 
		
		// Within Regressions
		levelsof `byvar', local(K)
		gen `withincpr' = .
		gen `withinb' = .
		if "`statlist'" != "" {
			foreach stat in `statlist' {
				gen _stat_`stat' = .
			}
		}
		
			
		foreach k of local K {
			regress `firstdepvar' `firstindepvar' if `byvar' == `k' [`weight'`exp'],  `vce' `noconstant' `hasconstant' `tsconstant'
			predict double  `withinresid', resid
			replace `withincpr' = _b[`seconddepvar']*`seconddepvar' + `withinresid' if `byvar' == `k'
			replace `withinb' = _b[`seconddepvar'] if `byvar' == `k'
			if "`statlist'" != "" {
				foreach stat in `statlist' {
					replace _stat_`stat' = e(`stat') if `byvar' == `k'
				}
			}
			drop `withinresid' 
		}
		
		if "`order'" == "" {
			local order `withinb'
			local x = "b_" + "`seconddepvar'"
			local byname `seconddepvar'
		}
		else {
			local x =regexr("`order'","_[0-9A-Za-z]+_","")
			local byname `order'
		}
		
		egen `rank' = rank(-`order') `secondif' `secondin', field  // UK: We should remove this with lower levels
		tempvar label
		decode `byvar', gen(`label')
		replace `label' = `label' + ", `x' = " +  strofreal(`order',"%8.0g")
		labmask `rank' `secondif' `secondin', value(`label')   // UK: We should remove this with lower levels
		local order `withinb'
	}


	// Default options
	if "`scopts'"== "" local scopts ms(oh) mcolor(gs8)
   if "`allopts'"== "" local allopts lcolor(gs12) sort 
   if "`regopts'"== "" local regopts lcolor(black) lpattern(dash) 
   if "`lowessopts'"== "" local lowessopts lcolor(black) lpattern(solid)
	if "`title'"== "" local title Within Clusters Component-Plus-Residual Plots
   if "`ytitle'"== "" local ytitle Component plus residual
   if "`legend'"== "" local legend order(2 "Linear Fit (All)" 3 "Linear Fit (Within)" 4 "LOWESS (Within)")
	if "`note'" == "" local note Plots ordered by field rank of `byname'
	if "`byopts'"== "" local byopts compact title(`title') note(`note')

	label variable `withincpr' "Residual + Component"
	label variable `totalcprhat' "Overall Regression"
	
	graph twoway ///
	  || scatter `withincpr' `seconddepvar', `scopts'  ///
	  || line `totalcprhat' `seconddepvar', `allopts' ///
	  || lfit `withincpr' `seconddepvar', `regopts'  ///
	  || lowess `withincpr' `seconddepvar', `lowessopts' ///
	  || , by(`rank', `byopts') ///
	  ytitle(`ytitle')  ///
	  legend(`legend') ///
	  `options' 
end

* cprplot for second level regression
program define twostep_clustercpr
	local cmdline `e(cmdline)'
	gettoken cmd varlist: cmdline
	gettoken depvar indepvars: varlist
	gettoken interestvar rest: indepvars

	ParseSecond `0'
	local scopts `r(scopts)'
	local regopts `r(regopts)'
	local lowessopts `r(lowessopts)'
	local options `r(options)'
	local title `r(title)'
   local ytitle `r(ytitle)'
   local legend  `r(legend)'
	local method `r(method)'

	tempname resid cpr
	predict double  `resid', resid
	gen `cpr' = `resid' + _b[`interestvar'] * `interestvar'

	// Default options
	if "`scopts'"== "" local scopts ms(Oh) mcolor(gs8)
   if "`regopts'"== "" local regopts lcolor(black) sort lpattern(dash) 
   if "`lowessopts'"== "" local lowessopts lcolor(black) lpattern(solid)
	if "`title'"== "" local title Cluster Level Component Plus Residual Plot
   if "`ytitle'"== "" local ytitle Component plus residual
   if "`legend'"== "" local legend order(2 "Linear Fit" 3 "Within LOWESS")

	graph twoway ///
	  || scatter `cpr' `interestvar' [aweight=`1'], `scopts' ///
	  || lfit `cpr' `interestvar'  [aweight=`1'], `regopts' ///
	  || lowess `cpr' `interestvar', `lowessopts' ///
	  || if e(sample),  ///
	  title(`title')  ///
	  ytitle(`ytitle')  ///
	  legend(`legend') ///
	  `options' 

end

* Unitregby-plot
program define twostep_unitregby
	syntax varlist [if] [in]   ///
	  [ , min(real 0) max(real 1)  ///
	  _byvars(varlist) Unitby(varlist) NQuantiles(int 2)  ///
      DIscrete(varlist) *]

	gettoken depvar indepvars: varlist
	gettoken order: indepvars

	local levelby: list _byvars - unitby

	// Graph defaults
	ParseSecond, `options'
   local byopts `r(byopts)'
	local options `r(options)'
	local title `r(title)'
   local xtitle `r(xtitle)'
   local ytitle `r(ytitle)'
   local regopts `r(regopts)'
	local allopts `r(allopts)'
	
	if "`byopts'" == "" local byopts legend(off)
	else local byopts legend(off) `byopts'
	if "`title'" != "" local byopts `byopts' title(`title')

	if "`regopts'" == "" local regopts c(L)
	else local regopts c(L) `regopts' 

	if "`allopts'" == "" local allopts c(L) lcolor(gs14)
	else local allopts c(L) `allopts'

	if "`xtitle'" == "" local xtitle `=subinstr("`depvar'","_b_","",.)'
	if "`ytitle'" == "" local ytitle Predicted values (all other covariates to zero) 
	
	tempname x phat

	forv i = 1/`=`nquantiles'-1'{
		local cutpoints `cutpoints' , r(r`i')
	}
	
	forv i = 1/`=`nquantiles'' {
		if `i'==1 local grouplab `"`i' "1{super:st}""'
		else if `i'== 2 local grouplab `"`grouplab' `i' "2{super:nd}""'
		else if `i'== 3 local grouplab `"`grouplab' `i' "3{super:rd}""'
		else local grouplab `"`grouplab' `i' "`i'{super:th}""'
	}
	label define grouplab `grouplab'
		
	quietly {
		foreach var of local indepvars {
			tempvar `var'

			if strpos("`discrete'","`var'") == 0 {
				_pctile `var', nquantile(`nquantiles')
				gen int ``var'' = irecode(`var' `cutpoints') + 1
				label var ``var'' " `var' (`nquantiles' quantiles)"
				label val ``var'' grouplab
			}
			else {
				clonevar ``var''=`var'
			}
			local groupvars `groupvars' ``var''
		}
		
		fillin `_byvars' `unitby' `groupvars'
		sort  `_byvars' `unitby' `depvar'
		replace `depvar' = `depvar'[_n-1] if _fillin 
		replace _b_cons = _b_cons[_n-1] if _fillin 
		
		expand 2
		bys `_byvars' `unitby' `groupvars': gen `x' = cond(_n==1,`min',`max')
		gen `phat' = _b_cons + `depvar' * `x'
	}
	
	graph twoway ///
	  || line `phat' `x' if _fillin, `allopts'  ///
	  || line `phat' `x' if !_fillin, `regopts'  /// 
	  || , by(`groupvars' `unitby', `byopts') ///
	  ytitle(`"`ytitle'"')  ///
	  xtitle(`xtitle')  ///
	  `options'
	
end


* dot of Coefs with C.I.
program define twostep_dot
	syntax anything [if] [in] [, over(varname) level(int 95) *]
	gettoken cmd varlist: anything
	gettoken depvar indepvars: varlist
	gettoken order: indepvars

	ParseSecond , `options'
	local scopts `r(scopts)'
	local ciopts `r(ciopts)'
	local options `r(options)'
	local title `r(title)'
   local xtitle `r(xtitle)'

	local tix = cond(strpos("`depvar'","_b_"),"Coefficient","Statistic")
	
	if "`ciopts'" == "" local ciopts lcolor(black)
	if "`scopts'" == "" local scopts ms(O) mcolor(black)
	if "`xtitle'" == "" local xtitle `depvar'
	if "`title'" == "" local title `tix' of unit level models

	tempvar lb ub rank

	quietly {
		local cif = invnorm((100-`level')/200)

		if strpos("`depvar'","_b_") {

			local sename = subinstr("`depvar'","_b","_se",.)

			gen `lb' = `depvar' - `cif'*`sename' `if' `in'
			gen `ub' = `depvar' + `cif'*`sename' `if' `in'

			local rcap 	 || rcap `lb' `ub' `rank', horizontal `ciopts'  

		}
		
		summarize `depvar' `if' `in', meanonly
		local mean = r(mean)
		
		if "`order'" == "" {
			local order `depvar'
			local note Groups ordered by size of within regression coefficients
		}
		else {
			local note Groups ordered by rank of `order'
		}
		
		egen `rank' = rank(-`order') `if' `in', unique
		labmask `rank' `if' `in', value(`over')  decode

		
		levelsof `rank', local(K)
		graph twoway ///
		  `rcap'   ///
		  || scatter `rank' `depvar', `scopts'  ///
		  || `if' `in', ylab(`K', valuelabel angle(0) grid gstyle(dot))  ///
		  ytitle(`"`ytitle'"')  ///
		  xtitle(`xtitle')  ///
		  xline(`mean', lcolor(gs12)) legend(off)  ///
		  title(`title') ///
		  `options'
	}
end

* Fallback mode
program define twostep_fallback
	syntax anything [if] [in] [, *]
	gettoken cmd varlist: anything
	`cmd' `varlist' `if' `in', `options'
end


* edv_OLS
program define twostep_ols, rclass
	syntax varlist(fv) [if] [in] ///
	  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]
	replace `weight' = 1
	return local sigma2 1
	return local omega2 0
end

* edv_WLS
program define twostep_wls, rclass
syntax varlist(fv)  [if] [in]  ///
  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	replace `weight' = 1/`omega' `if' `in'
	return local sigma2 0
	return local omega2 1
end

* edv_borjas
program define twostep_borjas, rclass
syntax varlist(fv)  [if] [in]  ///
  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	tempname XpX

	matrix accum `XpX' = `varlist' `if' `in' 

	local sigma2 = cond((`rss'-`sumomegavar')/`dof'<0, 0,  (`rss'-`sumomegavar')/`dof')

	replace `weight' = 1/(`sigma2' + `omega') `if' `in'

	return local sigma2 `sigma2'
	return local omega2 `sumomegavar'
end

* edv_FGLS-1
program define twostep_fgls1, rclass
	syntax varlist(fv) [if] [in] ///
	  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	tempname XpX XpGX tr

	matrix accum `XpX' = `varlist' `if' `in' 
	matrix accum `XpGX' = `varlist' [iw = `omega'] `if' `in'
	matrix `tr' = trace(invsym(`XpX') * `XpGX')

	local sigma2 =  cond( ///
	  ((`rss'-`sumomegavar' + `tr'[1,1]) / `dof') < 0, ///
	  0,  ///
	  (`rss'-`sumomegavar' + `tr'[1,1]) / `dof')

	
	replace `weight' = 1/(`sigma2' + `omega')

	sum `weight', meanonly

	// noi display "{txt} Sum of squared residual is {res}" %16.0g `rss'
	// noi display "{txt} Sum of omegasquared is  {res}" %16.0g `sumomegavar'
	// noi display "{txt} DF is {res}" `dof'
	// noi display "{txt} trace of inverse is {res}" %16.0g `tr'[1,1]
	// noi display "{txt} nominator of sigmasq-equation is {res}" %16.0g (`rss'-`sumomegavar' + `tr'[1,1])
	// noi display "{txt} sigmasq is {res}" %16.0g (`rss'-`sumomegavar' + `tr'[1,1]) / `dof'

	// noi display "{txt} Sum of weights shouch be 3788651.304 and is {res}" %16.0g `=r(sum)'

	return local sigma2 `sigma2'
	return local omega2 `sumomegavar'
end

* edv_FGLS-2
program define twostep_fgls2, rclass
	syntax varlist [if] [in] ///
	  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	tempvar e v omegahat

	predict double `e' if e(sample), resid
	replace `e' = `e'^2
	reg `e' `omega' `if' `in'
	if _b[_cons] < 0 {
		reg `e' `omega' `if' `in', nocons
		local sigma2 = 0
	}
	else {
		local sigma2 = _b[_cons]
	}
	
	predict double `v' if e(sample)
	replace `weight' = 1/(`v') if e(sample)

	gen double `omegahat' = sum((_b[`omega']*`omega')^2)

	return local sigma2 `sigma2'
	return local omega2 `=`omegahat'[_N]'
	
end


* Parse Firstlevelcommand
program define ParseFirst, rclass 
	syntax anything [if] [in] [aweight fweight pweight] [, *]
	gettoken subcmd firstlevelvars: anything

	return local subcmd `subcmd'
	return local firstlevelvars `firstlevelvars'
	return local if `if'
	return local in `in'
	return local weight `weight'`exp'
	return local options `options'
	
end

* Parse Secondlevelcommand
program define ParseSecond, rclass 
	syntax [anything] [if] [in] [using] [aweight] [, clear  ///
	  BYopts(string) ///
	  LOWESSopts(string)  ///
	  REGopts(string)  ///
	  SCopts(string)  ///
	  TItle(string) ///
	  XTItle(string) ///
	  YTItle(string) ///
	  ALLopts(string)  ///
	  CIopts(string) ///
	  legend(string) ///
	  unitby(string) ///
	  Method(string) ///
	  * ] 

	gettoken subcmd secondlevelvars: anything
	
	if "`if'" != "" {
		GrepIfVarnames `if'
		return local iflist `r(iflist)'
	}
	
	return local allopts `allopts'
	return local byopts `byopts'
	return local ciopts `ciopts' 
	return local clear `clear'
	return local if `if'
	return local in `in'
	return local legend `legend'
	return local lowessopts `lowessopts'
	return local note `note'
	return local options `options'
	return local regopts `regopts'
	return local scopts `scopts'
	return local secondlevelvars `secondlevelvars'
	return local subcmd `subcmd'
	return local title `title'
	return local using `using'
	return local xtitle `xtitle'
	return local ytitle `ytitle'
	return local unitby `unitby'
	return local method `method'
	
end

* Parse By-String
program define ParseByString, rclass
	syntax anything [, stats(string)]
	foreach name of local stats {
		local addstats `addstats' _stat_`name' = e(`name')
	}
	
   return local byvar `anything'
   return local addstats `addstats'
	return local statlist `stats'
end

* Grep variable names from if Option
program define GrepIfVarnames, rclass
	syntax if/

	local maybe 1
	while `maybe' == 1 {
		local maybe = regexm("`if'","[A-Za-z0-9_]+")
		if `maybe' != 0 {
			local candidate = regexs(0) 
			capture confirm variable `candidate'
			if !_rc {
				local iflist `iflist' `candidate'
			}
			local if: subinstr local if "`candidate'" "", all
		}
	}

	return local iflist `iflist'
end

* Remove FV notation to have the unique varnames

program define RemoveFvBits, rclass
	syntax anything(name=secondindepvar) 
		
	local cleansecondindepvars: subinstr local secondindepvar "#" " ", all
	foreach var of local cleansecondindepvars {
		local cleanlist `cleanlist' `=regexr("`var'","[bcio0-9()#]+\."," ")'
	}
		return local cleanlist `: list uniq cleanlist'
end




