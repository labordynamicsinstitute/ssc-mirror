*! ivreg2m 1.0.5 04Jun2024 cfb 
*!         1.0.5: fix robust option
*!         1.0.4: remove BS, lincomest code, add proper e(b) and e(V) returns
*!         1.0.3: cleanup of option handling
*!         1.0.2 10may2020
*! cloned from
*! ivreg2h  1.1.03  07feb2019  cfb/mes
*! cloned from
*! xtivreg2 1.0.13 28Aug2011
*! author mes
*! 1.0.4:  reinstate xtivreg2 code to fix up vnames
*! 1.0.5:  deal with inadequate number excluded insts, logic driving est table
*! 1.0.6:  introduce gen option to generate and leave behind generated instruments, with stub and replace option
*!         fix e(cmd) and e(cmdline) macros
*! 1.0.7:  Federico Belotti bugfix, -gen- option with multiple endogenous corrected
*! 1.0.8:  handle parsing with MES parse_iv
*! 1.0.9:  allow FE option
*! 1.1.00: Bug fix - orthog(.) would crash in gen-IV-only estimation
*!         Added nooutput option and nooutput calls to ivreg2 so that collinearity and duplicates msgs appear
*!         Removed extraneous `options' macro from calls to ivreg2.  Added check for ivreg210.
*!         Bug fix - needed capture before drop if gen(,replace) option used.
*!         Added saved xtmodel macro (="fe" if FE, ="" if not panel data estimation)
*! 1.1.01: Bug fix - version control so that new ivreg2 calls correct ivreg2x as appropriate
*!         Promoted required Stata to version 9 so that ivreg29 or higher used ("partial" was "fwl" in ivreg28)
*!         Removed extraneous ivreg2x check code and misc other extraneous code.
*!         Bug fix - wouldn't run under Stata 9 because of extraneous version 10.1 statement.
*! 1.1.02: Was not passing * (`options') on to ivreg2, which meant that options such as robust were ignored
*! 1.1.03: Add Z() option to select generated instruments

program define ivreg2m, eclass byable(recall)
	version 15
	local lversion 01.0.5
// will be overridden by ivreg2 e(version) for ivreg2_p

// Needed for call to ivreg2
	local ver = _caller()
	local ver : di %6.1f `ver'

	if replay() {
		syntax [, FIRST FFIRST rf Level(integer $S_level) NOHEader NOFOoter /*
			*/ EForm(string) PLUS VERsion]

		if "`version'" != "" & "`first'`ffirst'`rf'`noheader'`nofooter'`eform'`plus'" != "" {
			di as err "option version not allowed"
			error 198
		}
		if "`version'" != "" {
			di in gr "`lversion'"
			ereturn clear
			ereturn local version `lversion'
			ereturn local cmd "ivreg2h"
			exit
		}
		if `"`e(cmd)'"' != "ivreg2h"  {
			error 301
		}
	}
// end replay()
	else {

		local cmdline "ivreg2m `*'"
// ivreg2m: allow for only one clustering variable
// 1.0.4: add gmm2s, liml options 
// 1.0.5: add robust option
		syntax [anything(name=0)] [if] [in] [aw fw pw iw/] , /* 
		    */  TA(numlist integer sort) TB(numlist integer sort) /* 
			*/	[ Ivar(varname) Tvar(varname) FIRST ffirst rf GMM2s liml /*
			*/	savefirst SAVEFPrefix(name) saverf SAVERFPrefix(name) ROBust CLuster(varname)	/*
			*/	orthog(string) ENDOGtest(string) REDundant(string) PARTIAL(string)		/*
			*/	BW(string) SKIPCOLL														/*
			*/	GEN1 GEN2(string) NOOUTput Z(string) NOI  ]			


//		di in r "options: `options'"
		parse_iv `*'
		local endo `r(endo)'
		loc endoorig `endo'
		local inexog `r(inexog)'
		local lhs `r(depvar)'
		loc origlhs `r(depvar)'
		local exexog `r(exexog)'

/*
di in r "lhs: `lhs'"
di in r "inexog: `inexog'"
di in r "endo: `endo'"
di in r "exexog: `exexog'"
*/

// ivreg2m: restrict to only one endog 
		loc nen: word count `endo'
		if `nen' > 1 {
			di as err _n "No more than one RHS endogenous variable supported"
			error 198
		}
		loc endolabl: var lab `endo'
		
// ivreg2m: restrict to only one-way clustering imposed by varname

// ivreg2m: check that endog variable is integer
		confirm numeric variable `endo', exact  
// check that endog variable takes on at least three integer values; force int	
		qui replace `endo' = int(`endo')
		qui tab `endo'
		capt assert r(r) >= 3
		if _rc > 0 {
			di as err _n "Endogenous variable `endo' must have 3 or more values"
			error 198
		}
		
// process numlists, produce Ta and Tb and validate
		loc tlist `treatment'
		loc clist `control'
//		di as err "`tlist' | `clist'"

		tempvar Ta Tb
		g `Ta' = 0
		g `Tb' = 0
		foreach v of local ta {
			qui replace `Ta' = 1 if `endo' == `v'
		}
		su `Ta', mean
		if `r(min)'==`r(max)' {
				di "Error in TA specification"
				error 198
		}
		foreach v of local tb {
			qui replace `Tb' = 1 if `endo' == `v'
		} 
		su `Tb', mean
		if `r(min)'==`r(max)' {
				di "Error in TB specification"
				error 198
		}
		if ("`noi'"=="noi") {
				tab `Ta' `endo'
				tab `Tb' `endo'
		}	
		su `endo' if !`Ta' & !`Tb', mean
		loc omitted `r(mean)'
	
		local ivreg2_cmd "ivreg2"
// cfb ivreg2m
		loc first first
		tempname regest
		capture _estimates hold `regest', restore
		capture `ivreg2_cmd', version
		if _rc != 0 {
di as err "Error - must have ivreg2 version 2.1.15 or greater installed"
		exit 601
		}
		local vernum "`e(version)'"
		loc lversion `vernum'
		capture _estimates unhold `regest'

		if "`gmm2s'" != "" & "`exexog'" == "" {
			di as err "option -gmm2s- invalid: no excluded instruments specified"
			exit 102
		}

// cfb ivreg2m: compute estimates using Ta and Tb, stacked ---------------------

		loc pp Ta Tb
		loc endov 
		tempvar lhshold esampl nul iota
		qui g `lhshold' = `lhs'
		qui g `esampl' = .
		qui g `nul' = 0
		qui g `iota' = 1
		loc lhsTa lhsTb 
		foreach p of local pp {
			loc endov "`endov' ``p''"
			tempvar lhs`p'
			qui g `lhs`p'' = `lhshold' * ``p''
			loc lhs`p' "`lhs`p''"
			lab var `lhs`p'' "y_`p'"
		}	
* Begin estimation blocks
			loc qnoout nooutput
			marksample touse
			markout `touse' `lhsTa' `lhsTb' `Ta' `Tb' `inexog' `exexog' `endov' `nul' `iota' `cluster' /* `tvar' */, strok
				
	// cfb ivreg2m
			preserve
			qui keep if `touse'
			/*
			if "`noi'"=="noi" {
				di _n "`p'"
				su ``p'' `lhs' if `touse'
			}
			loc sa			
			tsrevar `lhs', substitute
			local lhs_t "`r(varlist)'"
			tsrevar `inexog', substitute
			local inexog_t "`r(varlist)'"
			loc n_inex : word count `inexog_t'
// 1.1.03
			if "`z'" == "" {
				loc z `inexog'
			}
			tsrevar `z', substitute
			local z_t "`r(varlist)'"
*/

// di in r "@@ zt `z_t'"
// di in r "n_inex `n_inex'" _n
//			tsrevar `endo', substitute
//			local endo_t "`r(varlist)'"
//			loc n_endo : word count `endo_t'
// di in r "n_endo `n_endo'"
//			tsrevar `exexog', substitute
//			local exexog_t "`r(varlist)'"
//			loc n_exex : word count `exexog_t'
// di in r "n_exex `n_exex'"
//			tsrevar `orthog', substitute
//			local orthog_t "`r(varlist)'"
//			tsrevar `endogtest', substitute
//			local endogtest_t "`r(varlist)'"
//			tsrevar `redundant', substitute
//			local redundant_t "`r(varlist)'"
//			tsrevar `partial', substitute
//			local partial_t "`r(varlist)'"
//			local npan1 0
			local dofminus 0

/*
if "`noi'"=="noi" {
di in r "orig lhs: `origlhs'"
di in r "inexog: `inexog'"
di in r "endo: `endov'"
di in r "exexog: `exexog'"
di in r "orig endo: `endoorig'"
}
*/

// build stack list from lhsv and endov
loc sla `lhsTa' `Ta' `nul'
loc slb `lhsTb' `nul' `Tb' 
// di _n "sl: `sla' | `slb'"
loc into "`origlhs' `endoorig'_a `endoorig'_b"
// di "into: `into'"
// nendog lists stacked endog
loc nendog " `endoorig'_a `endoorig'_b"
loc difendog  " ``endoorig'_a' - ``endoorig'_b'"
// su `sla' `slb'


// add exexog
loc vva
loc vvb
// ntex lists stacked exexog
loc ntex
foreach v of local exexog {
	loc vv `v' `nul' 
	loc vva "`vva' `vv'"
	loc vv `nul' `v'
	loc vvb "`vvb' `vv'"
	loc ntex "`ntex' `v'_a `v'_b"
	
}
loc sla "`sla' `vva'"
loc slb "`slb' `vvb'"
// di _n "sl: `sla' `slb'"
// su `sla' `slb'
// di "ntex: `ntex'"
loc into "`into' `ntex'"
// di "into: `into'"

// add inexog
loc vva
loc vvb
// ntin lists stacked inexog
loc ntin
foreach v of local inexog {
	loc vv `v' `nul' 
	loc vva "`vva' `vv'"
	loc vv `nul' `v'
	loc vvb "`vvb' `vv'"
	loc ntin "`ntin' `v'_a `v'_b"
}
loc sla "`sla' `vva'"
loc slb "`slb' `vvb'"
// di _n "sl: `sla' `slb'"
// su `sla' `slb'
// di "ntin: `ntin'"
loc into "`into' `ntin'"
// di _n "into: `into'"

// di _n "cluster: `cluster'"
// add constant; estimate with noconstant
// add touse
// add cluster vars if present; for now allow only one-way clustering
loc sla "`sla' `iota' `nul' `touse' `cluster'"
loc slb "`slb' `nul' `iota' `touse' `cluster'"
// di _n "sla: `sla'"
// di _n "slb: `slb'"
// su `sla' `slb'
loc into "`into' _cons_a _cons_b touse `cluster'"
// di _n "into: `into'"
loc nkon "_cons_a _cons_b"
 
stack `sla' `slb', into(`into') clear
//			if "`noi'"=="noi" {
			//	desc
			//	su
			//	di _n "into: `into'"
//			}

		tempname b V S W firstmat touse2

//		di _n "`lhs' `ntin' (`nendog' = `ntex') `nkon'" _n


// ms
// changed `qq'(=qui) to nooutput option so that collinearity and duplicates messages reported
// added ver from _caller() so that ivreg2 called correct ivreg2x under version control.

// cfb ivreg2m use lhs for Ta, Tb
//          but use noconstant for stacked format 
			loc nocons nocons
			loc touse touse
			loc pf qui capt
			if "`noi'"=="noi" {
				loc pf noi
			}
			version `ver': `pf' `ivreg2_cmd' `lhs' `ntin' (`nendog' = `ntex') `nkon' `wtexp' if `touse', ///
						dofminus(`dofminus') `nocons'  `first' `ffirst' `rf' `robust' ///
						cluster(`cluster') orthog(`orthog_t') endog(`endogtest_t') ///
						redundant(`redundant_t') partial(`partial_t') tvar(`tvar') bw(`bw') `options'

			tempname lc mrlate mrlate_se mrlate_pvalue mrlate_ll mrlate_ul 
// account for stacking
			loc en = int(`e(N)' / 2)

			di as res _n "MR-LATE point and interval estimate: "
			lincom `endoorig'_a -`endoorig'_b
			sca `mrlate' = `r(estimate)'
			sca `mrlate_se' = `r(se)'
			sca `mrlate_pvalue' = `r(p)'
			sca `mrlate_ll' = `r(lb)'
			sca `mrlate_ul' = `r(ub)'
			loc dof = `en' - 1	
			
			eret clear
			
// -------- code borrowed from RN lincomest ---------

  tempname beta vcov vari
  matr def `beta'=J(1,1,0)
  matr def `vcov'=J(1,1,0)
  matr def `beta'=`r(estimate)'
  scal `vari'=`r(se)'*`r(se)'
  matr def `vcov'=`vari'

  matr rownames `beta'="`origlhs'"
  matr colnames `beta'="`endo'"
  matr rownames `vcov'="`endo'"
  matr colnames `vcov'="`endo'"

  ereturn post `beta' `vcov', depname("`origlhs'") obs(`en') dof(`dof') esample(`esample')

// --------
				
/*		mat `lc' = r(table)
		sca `mrlate' = `lc'[1,1]
		sca `mrlate_se' = `lc'[2,1]
		sca `mrlate_pvalue' = `lc'[4,1]
		sca `mrlate_ll' = `lc'[5,1]
		sca `mrlate_ul' = `lc'[6,1]
*/
		eret sca mrlate = `mrlate'
		eret sca mrlate_se = `mrlate_se'
		eret sca mrlate_pvalue = `mrlate_pvalue'
		eret sca mrlate_ll = `mrlate_ll'
		eret sca mrlate_ul = `mrlate_ul'
		eret loc robust `robust'
		eret loc cluster `cluster'
		eret loc inexog `inexog'
		eret loc exexog `exexog'
		eret loc tb "`tb'"
		eret loc omitted `omitted'
		eret loc ta "`ta'"
		eret loc mmlabel "`endolabl'"
		eret loc mismeasured `endoorig'
		eret loc depvar `origlhs'
		eret loc cmd "ivreg2m"
		
}
// end else not replay



			
end



**********************************************************************
// from MES

program define parse_iv, rclass
	version 9

// cfb
	sreturn clear
		local n 0

		gettoken depvar 0 : 0, parse(" ,[") match(paren)
		IsStop `depvar'
		if `s(stop)' { 
			error 198 
		}
		while `s(stop)'==0 { 
			if "`paren'"=="(" {
				local n = `n' + 1
				if `n'>1 { 
capture noi error 198
di in red `"syntax is "(all instrumented variables = instrument variables)""'
exit 198
				}
				gettoken p depvar : depvar, parse(" =")
				while "`p'"!="=" {
					if "`p'"=="" {
						capture noi error 198 
di as err `"syntax is "(endogenous regressor = instrument variables)""'
di as err `"the equal sign "=" is required"'
						exit 198 
					}
					local endo `endo' `p'
					gettoken p depvar : depvar, parse(" =")
				}
				local temp_ct  : word count `endo'
				if `temp_ct' > 0 {
					tsunab endo : `endo'
				}
* To enable OLS estimator with (=) syntax, allow for empty exexog list
				local temp_ct  : word count `depvar'
				if `temp_ct' > 0 {
					tsunab exexog : `depvar'
				}
			}
			else {
				local inexog `inexog' `depvar'
			}
			gettoken depvar 0 : 0, parse(" ,[") match(paren)
			IsStop `depvar'
		}
		local 0 `"`depvar' `0'"'

		tsunab inexog : `inexog'
		tokenize `inexog'
		local depvar "`1'"
		local 1 " " 
		local inexog `*'
		
		return local depvar	"`depvar'"
		return local inexog	"`inexog'"
		return local exexog	"`exexog'"
		return local endo	"`endo'"
		return local robust "`robust'"

end

* Taken from ivreg2
program define Disp 
	version 8.2
	syntax [anything] [, _col(integer 15) ]
	local len = 80-`_col'+1
	local piece : piece 1 `len' of `"`anything'"'
	local i 1
	while "`piece'" != "" {
		di in gr _col(`_col') "`first'`piece'"
		local i = `i' + 1
		local piece : piece `i' `len' of `"`anything'"'
	}
	if `i'==1 { 
		di 
	}
end

program define IsStop, sclass
				/* sic, must do tests one-at-a-time, 
				 * 0, may be very large */
	if `"`0'"' == "[" {		
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
* per official ivreg 5.1.3
	if substr(`"`0'"',1,3) == "if(" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else	sret local stop 0
end

exit

