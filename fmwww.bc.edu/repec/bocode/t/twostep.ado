*! version 2.3 Juli 9, 2024 @ 17:38:22 UK
*! Multilevel Analysis With 2 Step Approach
  
// History
// twostep 2.3: Remove titles for graphs with defualt titeling did not work. -> fixed
// twostep 2.2: 2nd R&R SJ
// - Removed default titles for all plots
// - Constant only edv-regress allowed
// - Bug in the use of overopts() in microdfb -> fixed
// twostep 2.1: SJ revise and resubmitt version
//  - unit renamed to micro, cluster renamed to macro everywhere
//  - Option -robust- and -vce- returned an error in some situations -> fixed
//  - Standalone twostep is now undocumented. New command -edv- is used as a wrapper.
//  - xline(mean) removed from twostep-dot
//  - edv with option ols no longer defaults to -vce(robust)-; option -vce()- allowed instead.
//  - message about constraints added
//  - New micro-level command microdfb added
//  - Error in variance proportion: sigma2 + omega2 -> J*sigma2 + omega2
// twostep 2: SJ version
//  - cluster level command avplot added
//  - using not allowed for cluster level command dot -> fixed
//  - unitcpr returned an error if sort order is not unique -> fixed
//  - Some twoway options ended in edvreg. -> fixed
//  - default options respect selected scheme
//  - help-file reworked

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
	local firstin `r(in)'
	local firstif `r(if)'


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
	else if "`firstcmd'" == "microcpr" {
		gettoken litter firstlevelstring: firstlevelstring
		
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'

		twostep_microcpr `bystring': `firstlevelstring' || `secondlevelstring'
		exit
	}

	// Box plot of df-betas for all the 1st Level models
	else if "`firstcmd'" == "microdfb" {
		gettoken litter firstlevelstring: firstlevelstring
		
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'

		twostep_microdfb `bystring': `firstlevelstring' || `secondlevelstring'
	}

	
	// Component-plus-Residual Plot for the cluster level linear regression
	else if "`secondcmd'" == "cprplot" {
		
		ParseFirst `firstlevelstring'
		local model `r(subcmd)'
		
		preserve
		tempvar touse wgt
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring'
		local macroid `r(macroid)' 
		
		ParseSecond `secondlevelstring'
		if strpos(`"`r(options)'"',"hascons") local hascons hascons
		if strpos(`"`r(options)'"',"nocons") local nocons nocons
		if strpos(`"`r(options)'"',"tsscons") local tsscons tsscons
		
		quietly twostep_edv `r(secondlevelvars)' `r(if)' `r(in)', `hascons' `nocons' `tsscons' keepweights(`wgt') method(`r(method)')

		if substr("`model'",1,3) != "reg" display `"{txt}Warning: First level model not -regress-. Use on own risk"'
		ereturn repost

		gettoken litter allsecondlevelopts : secondlevelstring, parse(",")
		local allsecondlevelopts: subinstr local allsecondlevelopts `","' `""' 
		twostep_cprplot `wgt' , `allsecondlevelopts' macroid(`macroid') 
		
	}


	// Added variable plot for the macro level linear regression
	else if "`secondcmd'" == "avplot" {

		ParseFirst `firstlevelstring'
		local model `r(subcmd)'

		preserve
		tempvar touse wgt
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring'
		local macroid `r(macroid)'
		
		ParseSecond `secondlevelstring'
		if strpos(`"`r(options)'"',"hascons") local hascons hascons
		if strpos(`"`r(options)'"',"nocons") local nocons nocons
		if strpos(`"`r(options)'"',"tsscons") local tsscons tsscons
		
		quietly twostep_edv `r(secondlevelvars)' `r(if)' `r(in)', `hascons' `nocons' `tsscons' keepweights(`wgt') method(`r(method)')

		if substr("`model'",1,3) != "reg" display `"{txt}Warning: First level model not -regress-. Use on own risk"'
		ereturn repost

		gettoken litter allsecondlevelopts : secondlevelstring, parse(",")
		local allsecondlevelopts: subinstr local allsecondlevelopts `","' `""' 
		quietly twostep_avplot `wgt' , `allsecondlevelopts' macroid(`macroid')
		
	}

	
	// The -regby- Plots (i.e. Bowers/Drakes figure 3)
	else if "`secondcmd'" == "regby" {
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'

		ParseSecond `secondlevelstring'
		local secondlevelvars `r(secondlevelvars)'
		gettoken seconddepvar secondindepvar: secondlevelvars
		local microby `r(microby)'
		
		local secondlevelstring = subinstr("`secondlevelstring'","`seconddepvar'","_all",.)

		summarize `=subinstr("`seconddepvar'","_b_","",.)', meanonly
		local min = r(min)
		local max = r(max)
		
		twostep_mk2nd `microby' `bystring': `firstlevelstring' ||  `secondlevelstring'
		ParseByString `bystring'
		local byvars  `r(byvar)' 

		gettoken secondlevelstring allsecondlevelopts : secondlevelstring, parse(",")
		local allsecondlevelopts = subinstr("`allsecondlevelopts'",",","",1)

		twostep_regby `secondlevelvars' ///
		  , min(`min') max(`max') `allsecondlevelopts' _byvars(`byvars') microby(`microby') 
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
		local allsecondlevelopts = subinstr(`"`allsecondlevelopts'"',`","',`""',1)
		twostep_dot `secondlevelstring', `allsecondlevelopts' over(`byvar')
	}

	// An arbitrary Fallback command for the macro level
	else {
		preserve
		tempvar touse
		mark `touse' `firstif' `firstin'
		quietly keep if `touse'
		
		twostep_mk2nd `bystring': `firstlevelstring' || `secondlevelstring'
		twostep_fallback `secondlevelstring'
		
	}
end

* avplot for second level regression
program define twostep_avplot

	local depvar `e(depvar)'
	local indepvars: colnames e(b)
	gettoken interestvar controls: indepvars
	local controls: subinstr local secondlevelstring "_cons" "", all
	
	ParseSecond `0'
	local scopts `r(scopts)'
	local regopts `r(regopts)'
	local mlabopts `r(mlabopts)'
	local options `r(options)'
	local title `r(title)'
   local ytitle `r(ytitle)'
   local ytitle `r(xtitle)'
   local legend  `r(legend)'
	local method `r(method)'
	local macroid `r(macroid)'

	if strpos(`"`r(options)'"',"hascons") local hascons hascons
	if strpos(`"`r(options)'"',"nocons") local nocons nocons
	if strpos(`"`r(options)'"',"tsscons") local tsscons tsscons
   local options: subinstr local options "hascons" "", all 
   local options: subinstr local options "nocons" "", all 
   local options: subinstr local options "tsscons" "", all 
	
	tempname resid1 resid2

	regress `depvar' `controls' [aweight=`1'], `hascons' `nocons' `tsscons'
	predict double `resid1', resid

	regress `interestvar' `controls' [aweight=`1'], `hascons' `nocons' `tsscons'
	predict double `resid2', resid
	
	// Default options
//	if "`title'"== "" local title Macro-Level Added Variable Plot
   if "`ytitle'"== "" local ytitle e(`depvar' | X)
   if "`xtitle'"== "" local xtitle e(`interestvar' | X)
	
   if "`legend'"== "" local legend off

	graph twoway ///
	  || scatter `resid1' `resid2',  ms(i) mlabpos(0) mlabcolor(gs11) mlab(`macroid') `mlabopts' ///
	  || scatter `resid1' `resid2' [aweight=`1'],  ms(Oh) mstyle(p1) `scopts' ///
	  || lfit `resid1' `resid2'  [aweight=`1'], lstyle(p2) sort lpattern(solid) `regopts' ///
	  || if e(sample),  ///
	  title(`title')  ///
	  ytitle(`ytitle') xtitle(`xtitle')  ///
	  legend(`legend') ///
	  `options' 
end



* Create macro level Data

program define twostep_mk2nd, rclass
	
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
		
		// Swap macro level data 
		if `"`using'"' == `""' {
			fvexpand `secondindepvar'
			if "`r(fvops)'" != "" {
				RemoveFvBits `secondindepvar'
				local secondindepvar `r(cleanlist)' 
			}
			save `thisdata'
			keep `byvar' `secondindepvar' `iflist'

			// Check macro variables to be constant
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
		if "`vce'" != "" {
				local vce vce(`vce')
		}

		if "`weight'" == "pweight" {
			local weight "aweight"
			if "`vce'" == "" {
				local vce vce(robust)
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

	return local macroid `byvar'

end

* edv (Re-Implentation of Lewis/Linzer's edvreg)
program define twostep_edv

	syntax varlist(fv) [if] [in] [, Method(string) level(passthru) vce(passthru) NOCONStant Hascons keepweights(string) *]
	gettoken depvar indepvars: varlist
	local sename = subinstr("`depvar'", "_b","_se",.)

	tempvar omegavar sumomegavar weight

	if "`method'" == "" local method fgls1
	local creator = cond("`method'"=="fgls2","(1/_n_model)","`sename'^2")  // UK: edvreg uses (1/_n_model)^2

	quietly {
		gen double `omegavar'  = `creator' `if' `in'
		sum `omegavar', meanonly
		local sumomegavar = r(sum)
		
		regress `depvar' `indepvars' `if' `in'
		local dof = e(df_r) 
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
		local notused = cond(!mi(`=r(notused)'),`=r(notused)',0)
		local robust  `r(robust)'
		local constrained `r(constrained)'
	}
	if `notused' disp "{txt}Warning: {res}`notused'{txt} macro level observations dropped due to non-positive weights."
		
	quietly regress `depvar' `indepvars' [aw=`weight'] `if' `in', `level' `vce' `noconstant' `hascons' `options' `robust'
	disp _n "{ul:Estimated dependent variable regression}" _n _n ///
	"{txt}Macro-level results using {res}`method'"
	regress
	disp "{txt}Sampling Variance Proportion = {res}" %4.3f `omega2'/(e(N)*`sigma2' + `omega2') " `constrained'"

	if "`keepweights'" != "" gen double `keepweights' = `weight' if e(sample)
end
	
* cprplot for  micro level regressions
program define twostep_microcpr

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
			capture confirm string variable `byvar'
			if _rc == 7 {
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
			else {
				regress `firstdepvar' `firstindepvar' if `byvar' == `"`k'"' [`weight'`exp'],  `vce' `noconstant' `hasconstant' `tsconstant'
				predict double  `withinresid', resid
				replace `withincpr' = _b[`seconddepvar']*`seconddepvar' + `withinresid' if `byvar' == `"`k'"'
				replace `withinb' = _b[`seconddepvar'] if `byvar' == `"`k'"'
				if "`statlist'" != "" {
					foreach stat in `statlist' {
						replace _stat_`stat' = e(`stat') if `byvar' == `"`k'"'
					}
			}
			drop `withinresid' 

			}
			
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

		bys `order' `byvar': gen `rank' = _n==1 `secondin' `secondif'
		replace `rank' = sum(`rank') `secondin' `secondif'

		tempvar label
		capture confirm string variable `byvar'
		if _rc == 7 {
			decode `byvar', gen(`label')
		}
		else gen `label' = `byvar'
		replace `label' = `label' + ", `x' = " +  strofreal(`order',"%4.3f")
		mylabmask `rank' `secondif' `secondin', value(`label')  
		local order `withinb'
	}


	// Default options
//	if "`title'"== "" local title Component-Plus-Residual Plots by `=cond(`"`:variable label `byvar''"' ==`""' ,`"x"', `"`:variable label `byvar''  "')'
   if "`ytitle'"== "" local ytitle Component-plus-residual
   if "`legend'"== "" local legend order(2 "Linear Fit (All)" 3 "Linear Fit (Within)" 4 "LOWESS (Within)")
	if "`note'" == "" local note Plots ordered by field rank of b_`byname'
	if "`byopts'"== "" local byopts compact title(`title') note(`note')

	label variable `withincpr' "Residual + Component"
	label variable `totalcprhat' "Overall Regression"
	
	graph twoway ///
	  || scatter `withincpr' `seconddepvar', ms(oh) mcolor(gs8) `scopts'  ///
	  || line `totalcprhat' `seconddepvar', lcolor(gs11) sort  `allopts' ///
	  || lfit `withincpr' `seconddepvar', lstyle(p2) lpattern(dash) `regopts'  ///
	  || lowess `withincpr' `seconddepvar', lstyle(p1) lpattern(solid) `lowessopts' ///
	  || , by(`rank', `byopts') ///
	  ytitle(`ytitle')  ///
	  legend(`legend') ///
	  `options' 
end


* Box-plot of DF-Betas for micro level regressions
program define twostep_microdfb

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
	local overopts `r(overopts)'
	local options `r(options)'
	local title `r(title)'
   local ytitle `r(ytitle)'
   local note  `r(note)'
	local box `r(box)'
	local marker `r(marker)'
	local medline `r(medline)'
	local medtype `r(medtype)'

	gettoken order: secondindepvar
	local seconddepvar = subinstr("`seconddepvar'","_b_","",.)

	ParseByString `bystring'
	local byvar `r(byvar)'
	local statlist `r(statlist)'

	quietly {
		
		tempvar dfbeta df rank 	
		
		// Within Regressions
		levelsof `byvar', local(K)
		gen `dfbeta' = .
		foreach k of local K {
			capture confirm string variable `byvar'
			if _rc == 7 {
				regress `firstdepvar' `firstindepvar' if `byvar' == `k' [`weight'`exp'],  `vce' `noconstant' `hasconstant' `tsconstant'
				predict `df', dfbeta(`seconddepvar') 
				replace `dfbeta' = `df' if `byvar' == `k'
				drop `df'
			}
			else {
				regress `firstdepvar' `firstindepvar' if `byvar' == `"`k'"'  [`weight'`exp'],  `vce' `noconstant' `hasconstant' `tsconstant'
				predict `df', dfbeta(`seconddepvar')
				replace `dfbeta' = `df' if `byvar' == "`k'"
				drop `df'
			}
			
		}
		label variable `dfbeta' "DF-Beta"
	
			// Order the boxes
		if "`order'" == "" {
			local order `byvar'
		}
		else {
			local x =regexr("`order'","_[0-9A-Za-z]+_","")
			local byname `order'
		}
		
		bys `order' `byvar': gen `rank' = _n==1 `secondin' `secondif'
		replace `rank' = sum(`rank') `secondin' `secondif'
		
		tempvar label
		capture confirm string variable `byvar'
		if _rc == 7 {
			decode `byvar', gen(`label')
		}
		else gen `label' = `byvar'
		
		mylabmask `rank' `secondif' `secondin', value(`label')  

	}

	// Default options
//	if "`title'"== "" local title DF-Betas for `seconddepvar' by `=cond(`"`:variable label `byvar''"' ==`""' ,`"x"', `"`:variable label `byvar''  "')'
	if "`box'" == "" local box fcolor(none) lcolor(black)
	if "`marker'" == "" local marker ms(oh) mlcolor(black)
	if "`medtype'" == "" local medtype line
	if "`medline'" == "" local medline lcolor(black) 

		
	graph hbox `dfbeta'  ///
	  , over(`rank', `overopts') ///
	  ytitle(`ytitle') title(`title')  ///
	  box(1, `box') marker(1, `marker')  ///
	  medtype(`medtype') medline(`medline') ///
	  `options'  
end



* cprplot for macro level regression
program define twostep_cprplot

	local depvar `e(depvar)'
	local indepvars: colnames e(b)
	gettoken interestvar controls: indepvars
	local controls: subinstr local secondlevelstring "_cons" "", all

	ParseSecond `0'
	local scopts `r(scopts)'
	local regopts `r(regopts)'
	local lowessopts `r(lowessopts)'
	local mlabopts `r(mlabopts)'
	local options `r(options)'
	local title `r(title)'
   local ytitle `r(ytitle)'
   local legend  `r(legend)'
	local method `r(method)'
   local macroid `r(macroid)' 
	
	tempname resid cpr
	predict double  `resid', resid
	gen `cpr' = `resid' + _b[`interestvar'] * `interestvar'

	// Default options
//	if "`title'"== "" local title Macro-Level Component-Plus-Residual Plot
   if "`ytitle'"== "" local ytitle Component-plus-residual
   if "`legend'"== "" local legend order(3 "Linear Fit" 4 "LOWESS")

	graph twoway ///
	  || scatter `cpr' `interestvar', ms(i) mlab(`macroid') mlabpos(0) mlabcolor(gs11) `mlabopts' ///
	  || scatter `cpr' `interestvar' [aweight=`1'], mstyle(p3) ms(Oh) `scopts' ///
	  || lfit `cpr' `interestvar'  [aweight=`1'], lstyle(p2) sort lpattern(dash) `regopts' ///
	  || lowess `cpr' `interestvar', lstyle(p1) lpattern(solid) `lowessopts' ///
	  || if e(sample),  ///
	  title(`title')  ///
	  ytitle(`ytitle')  ///
	  legend(`legend') ///
	  `options' 

end

* Regby-plot
program define twostep_regby
	syntax varlist [if] [in]   ///
	  [ , min(real 0) max(real 1)  ///
	  _byvars(varlist) Microby(varlist) NQuantiles(int 2)  ///
      DIscrete(varlist) *]

	gettoken depvar indepvars: varlist
	gettoken order: indepvars

	local levelby: list _byvars - microby

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
				label var ``var'' " `var' (`nquantiles' quantile groups)"
				label val ``var'' grouplab
			}
			else {
				clonevar ``var''=`var'
			}
			local groupvars `groupvars' ``var''
		}
		
		fillin `_byvars' `microby' `groupvars'
		sort  `_byvars' `microby' `depvar'
		replace `depvar' = `depvar'[_n-1] if _fillin 
		replace _b_cons = _b_cons[_n-1] if _fillin 
		
		expand 2
		bys `_byvars' `microby' `groupvars': gen `x' = cond(_n==1,`min',`max')
		gen `phat' = _b_cons + `depvar' * `x'
	}

	graph twoway ///
	  || line `phat' `x' if _fillin,  c(L) lcolor(gs14) `allopts'  ///
	  || line `phat' `x' if !_fillin, lstyle(p1) `regopts'  /// 
	  || , by(`groupvars' `microby', `byopts') ///
	  ytitle(`"`ytitle'"')  ///
	  xtitle(`xtitle')  ///
	  `options'
	
end


* dot of Coefs with C.I.
program define twostep_dot
	syntax anything [if] [in] [using] [, over(string) level(int 95) *]
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
	
	if "`xtitle'" == "" local xtitle `depvar'
	* if "`title'" == "" local title `tix' of micro level models

	tempvar lb ub rank

	quietly {
		local cif = invnormal((100-`level')/200)

		if strpos("`depvar'","_b_") {

			local sename = subinstr("`depvar'","_b","_se",.)

			gen `lb' = `depvar' - `cif'*`sename' `if' `in'
			gen `ub' = `depvar' + `cif'*`sename' `if' `in'

			local rcap 	 || rcap `lb' `ub' `rank', horizontal lstyle(p1) `ciopts'  

		}
		
		summarize `depvar' `if' `in', meanonly
		local mean = r(mean)
		
		if "`order'" == "" local note Groups ordered by size of within regression coefficients
		else local note Groups ordered by rank of `indepvars' 

		// Creates axis order
		tempname ranklb
		sort `indepvars' `depvar' `over' 
		gen  `rank':`ranklb' = _n
		local sorters: word count `indepvars'
		forv i=1/`=`sorters'-1' {
			local var: word `i' of `indepvars'
			replace `rank' = `rank' + sum(`var' != `var'[_n-1])
		}
		bys `rank': assert _n==1

		forv i=1/`=_N' {
			capture confirm string variable `over'
			if _rc == 7 {
				label define `ranklb' `=`rank'[`i']'  `"`: label (`over') `=`over'[`i']''"', modify
			}
			else label define `ranklb' `=`rank'[`i']' `"`=`over'[`i']'"', modify
			
		}

		levelsof `rank', local(K)
		graph twoway ///
		  `rcap'   ///
		  || scatter `rank' `depvar', mstyle(p1) ms(O) `scopts' ///
		  || `if' `in', ylab(`K', valuelabel angle(0) grid gstyle(dot))  ///
		  ytitle(`"`ytitle'"')  ///
		  xtitle(`xtitle')  ///
		  legend(off)  ///
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
	syntax [varlist(fv default=none)] [if] [in] ///
	  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]
	replace `weight' = 1
	return local sigma2 .
	return local omega2 .
	return local constrained "(not calculated due to option OLS)"

	// return local robust robust
end

* edv_WLS
program define twostep_wls, rclass
syntax [varlist(fv default=none)]  [if] [in]  ///
  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	replace `weight' = 1/`omega' `if' `in'
	return local sigma2 0
	return local omega2 1
	return local constrained "(constrained by option WLS)"
end

* edv_borjas
program define twostep_borjas, rclass
syntax [varlist(fv default=none)]  [if] [in]  ///
  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	local sigma2 = cond((`rss'-`sumomegavar')/`dof'<0, 0,  (`rss'-`sumomegavar')/`dof')

	replace `weight' = 1/(`sigma2' + `omega') `if' `in'

	return local sigma2 `sigma2'
	return local omega2 `sumomegavar'
end

* edv_FGLS-1
program define twostep_fgls1, rclass
	syntax [ varlist(fv default=none) ] [if] [in] ///
	  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	tempname XpX XpGX tr

	if "`varlist'" != "" {
		matrix accum `XpX' = `varlist' `if' `in' 
		matrix accum `XpGX' = `varlist' [iw = `omega'] `if' `in'
		matrix `tr' = trace(invsym(`XpX') * `XpGX')
	}
	else {
		tempvar _cons
		gen `_cons' = 1
		matrix accum `XpX' = `_cons' `if' `in', nocons
		matrix accum `XpGX' = `_cons' [iw = `omega'] `if' `in', nocons
		matrix `tr' = trace(invsym(`XpX') * `XpGX')
	}
		
	if ((`rss'-`sumomegavar' + `tr'[1,1]) / `dof') < 0 {
		local sigma2 0
		local constrained "(not estimable; constrains applied)"
	}
	else {
		local sigma2 = (`rss'-`sumomegavar' + `tr'[1,1]) / `dof'
	}
		
	replace `weight' = 1/(`sigma2' + `omega')

	return local sigma2 `sigma2'
	return local omega2 `sumomegavar'
	return local constrained "`constrained'"
end

* edv_FGLS-2
program define twostep_fgls2, rclass
	syntax [varlist(fv default=none)] [if] [in] ///
	  [, weight(varname) omega(varname) rss(real 1) sumomegavar(real 1) dof(real 1) ]

	tempvar e v omegahat
	
	predict double `e' if e(sample), resid
	replace `e' = `e'^2
	reg `e' `omega' `if' `in'
	if _b[_cons] < 0 {
		reg `e' `omega' `if' `in', nocons
		local sigma2 = 0
		local constrained "(not estimable; constrains applied)"
	}
	else {
		local sigma2 = _b[_cons]
	}

	predict double `v' if e(sample)
	replace `weight' = 1/`v' if e(sample)

	count if `weight' <= 0
	local notused = r(N)
	
	gen double `omegahat' = sum((_b[`omega']*`omega')^2)

	return local sigma2 `sigma2'
	return local omega2 `=`omegahat'[_N]'
	return local notused `notused'
	return local constrained "`constrained'"

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
	  overopts(string) ///
	  LOWESSopts(string)  ///
	  REGopts(string)  ///
	  SCopts(string)  ///
	  MLabopts(string) ///
	  TItle(string) ///
	  XTItle(string) ///
	  YTItle(string) ///
	  ALLopts(string)  ///
	  CIopts(string) ///
	  legend(string) ///
	  microby(string) ///
	  Method(string) ///
	  macroid(string) ///
	  box(string) ///
	  marker(string) ///
	  medline(string) ///
	  medtype(string) ///
	  * ] 

	gettoken subcmd secondlevelvars: anything
	
	if "`if'" != "" {
		GrepIfVarnames `if'
		return local iflist `r(iflist)'
	}
	
	return local allopts `allopts'
	return local byopts `byopts'
	return local overopts `overopts'
	return local ciopts `ciopts' 
	return local clear `clear'
	return local if `if'
	return local in `in'
	return local legend `legend'
	return local lowessopts `lowessopts'
	return local note `note'
	return local mlabopts `mlabopts'
	return local options `options'
	return local regopts `regopts'
	return local scopts `scopts'
	return local secondlevelvars `secondlevelvars'
	return local subcmd `subcmd'
	return local title `title'
	return local using `using'
	return local xtitle `xtitle'
	return local ytitle `ytitle'
	return local microby `microby'
	return local method `method'
	return local macroid `macroid'
	return local marker `marker'
	return local box `box'
	return local medline `medline'
	return local medtype `medtype'
	
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


* Labels for the re-ordered categories
// Code of labmask by  NJC 1.0.0 20 August 2002
program def  mylabmask, sortpreserve 
	version 7 
	syntax varname(numeric) [if] [in], /* 
	*/ VALues(varname) [ LBLname(str) decode ]

	* observations to use 
	marksample touse 
	qui count if `touse' 
	if r(N) == 0 { 
		error 2000 
	}	
	
	* integers only! 
	capture assert `varlist' == int(`varlist') if `touse' 
	if _rc { 
		di as err "may not label non-integers" 
		exit 198 
	}
	
	tempvar diff decoded group example 
	
	* do putative labels differ? 
	bysort `touse' `varlist' (`values'): /* 
		*/ gen byte `diff' = (`values'[1] != `values'[_N]) * `touse' 
	su `diff', meanonly 
	if r(max) == 1 { 
		di as err "`values' not constant within groups of `varlist'" 
		exit 198 
	} 

	* decode? i.e. use value labels (will exit if value labels not assigned) 
	if "`decode'" != "" { 
		decode `values', gen(`decoded') 
		local values "`decoded'" 
	} 	

	* we're in business 
	if "`lblname'" == "" { 
		local lblname "`varlist'" 
	} 
	
	* groups of values of -varlist-; assign labels 
	
	by `touse' `varlist' : /*
		*/ gen byte `group' = (_n == 1) & `touse' 
	qui replace `group' = sum(`group') 

	gen long `example' = _n 
	local max = `group'[_N]  
	
	forval i = 1 / `max' { 
		su `example' if `group' == `i', meanonly 
		local label = `values'[`r(min)'] 
		local value = `varlist'[`r(min)'] 
		label def `lblname' `value' `"`label'"', modify 	
	} 

	label val `varlist' `lblname' 
end 


