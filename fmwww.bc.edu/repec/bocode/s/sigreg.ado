*!  sigreg.ado Version 6.5		RL Kaufman 	4/4/2019

***  	1.0 Work with standard MAIN INT2 INT3 option specification. Use DEFINEFM.ADO to define focal & moderator vars & properties 
***			MAIN string contains (varlist1, name(word) range(numlist)) (varlist2, name(word)  range(numlist))
***			ADDED options:  SIGLEV(#,adjtype)  p=.05 default, adjtypes = POThoff BONferroni SIDak(can specify POThoff with either BON or SID). NDIGITS for format default=2
***			PLOTJN(name, skip# gen(name)) plots 2 Mod boundary values.  SKIP# = Plot only every SKIP# marker, default = 10
***			Works for J-N tafor up to 4 moderators, including one 3way.  BV plot for 2 mods
***		2.0 Add functionality for empirically defined significance region tables for 2 mods
***			ADDED options: SAVE(path\filename  MATrix TABle) saves matrices/formatted table for each Category of Focal, 
***		2.1 Add functionality for loopinng over 1-2 other mods (MOD3 MOD4).  Now does significance region tables for single mod with saving option
***			Displays value labels if exist on tables & graphs
***		2.2 Switches to use of global macros for variable min and max
***
***		3.0	Added preserve, put quiet on, removed checking code and generally cleaned up code.  Added key to sig region table
***			UNDOCUMENTED OPTION: MYGLOB(KEEP) so I can check easily.
***		3.1 Fixed repeated message about saving sig reg table to Excel 
***		4.0  Adapted to use intspec.ado to set-up and save the globals for the interaction specification for re-use.  SUMWGT now INTSPEC option
*** 	4.1  Added options to empirical sig region table to choose effect = b , factor change, or spost specification.  
*** 	4.2 Added note to empirical sig region table reporiting the spost effect type and at( ) specification.  
***		4.3 Added option for y*-standardized effect effect(b(sdy))
***		4.4 Fixed problem with getting Spost s.e. for multi-outcome GLMs, Added NOBVA option(no bound val analysis) & echo back options
***		5.0 Added  functionality for mlogit. 
***		5.1  Added option for both y*-standardized & x std dev effect --  effect(b(sdyx))
***		5.2  Extended standardized sdy & sdyx to mlogit with unique latent var for each cat:ref cat
***		5.3  Corrected highlighting for factor change results so "negative" is <1 and "positive" > 1
***		5.4  Added Sidak correction to multiple testing options
***		6.0	 Added functionality for predicted prob for catergoires of ordered prob models
***		6.1  Added survuval models as allowable for factor change effect (check existence e(t0) = _t0)
***		6.2  Added check for SPOST only can use factor variables
***		6.3	 Changed fill patterns for Excel formatted tables to be consistent with book graphics
***		6.4  Fixed problem of file paths with embedded blanks in save() option
***		6.5  Attempt to fix error writing Excel table on Mac 
program sigreg, rclass sortpreserve
version 14.2
syntax  , [ SIGlev(string) SAVE(string) CONCISE  PLOTjn(string) NDIGits(integer 4) pltopts(string asis) ///
			effect(string) NOBVA ] 
tempname bb m1bv m2bv m1 m2 m1bvsig m1bvns m2bvsig m2bvns srb srsig srvb estint mchg
tempvar  rowvar bval1 sigchg1 bval2 sigchg2 predstd 

qui {

***		check if globsave file created by instspec.ado & definefm.ado

if  fileexists("`c(tmpdir)'/globsaveeq1$sfx2.do") ==0 {
	noi disp "{err: Must run intspec.ado to setup and save interaction specification first}"
	exit
}

*** PRESERVE DATA & CURRENT ESTIMATES ON EXIT

preserve
est store `estint' 
loc estcmd "`e(cmd)'"
glob dvcat$sfx "`e(k_cat)'"

*** load globals from eq1 to use in setup and  if-branching
capture drop esamp$sfx
qui run `c(tmpdir)'/globsaveeq1$sfx2.do


loc fopenyet "no"

***  Get plot name PLTNM, skip# SK1 & varstub PLTSTUB to save to for 2 MOD boundary value plot 
gettoken pltnm gg : plotjn , parse(",")
if "`pltnm'" == "" loc pltnm "boundary_values"
gettoken  gg1 gg : gg , parse(",")
if "`gg1'" != "" gettoken  gg1 gg : gg 
if "`gg'" != "" gettoken  gg2 gg : gg 

forvalues i=1/2 {
	if "`gg`i''" != "" {
	if regexm("`gg`i''"," gen")== 1 {
		gettoken  gg3 gg4 : gg`i' , parse("()")
		gettoken  gg3 gg4 : gg4 , parse("()") match(gh)
		loc pltstub `"`gg3'"'
	}
	if regexm("`gg`i''","gen")!= 1 loc sk1= `gg`i''
}
}
*** set default skip SK1=10
if "`sk1'" == "" loc sk1=10

*** set skipbva option
loc skipbva "no"
if "`nobva'" == "nobva" loc skipbva "yes"
if "`coeftype'" == "spost" {
	loc skipbva "yes"
	if 	"`nobva'" != "nobva" noi disp _newline "{err: Boundary Value Analysis not possile for SPOST effects. Option ignored.}"
}
*** Get coeftype  for significance region tables, set defaults and parse out delta for factor change or spost specs
loc coeftype "b"
loc fcdel  "1"
loc titdel "(1 unit difference)"
loc titdvdel ""
loc amtopt "am(one)"
loc atopt "(asobs) _all"
glob ystd$sfx = 1

loc hctype=strtrim(stritrim(`"`effect'"'))
gettoken coeftype hctype : hctype , parse("()")
if "`coeftype'" == "spost" loc titdel ""
gettoken  hctype ctopt: hctype , bind match(pp)
while `"`hctype'"' != ""  & `"`hctype'"' !=  " " {
	gettoken ctopt hctype : hctype ,  bind match(pp) 
	if "`coeftype'" == "factor" | "`coeftype'" == "b"  {
		if "`ctopt'" != ""  { 
			loc fcdel  "`ctopt'"
			loc titdel "(`ctopt' unit difference)"
			loc signfc ""
			if strmatch("`ctopt'","*-*") ==1 {
				loc signfc "-"
				loc ctopt = subinstr("`ctopt'","-","",1)
			}		
		}
		if "`ctopt'" == "sd" { 
			loc fcdel "`signfc'${fsd$sfx}"
			loc titdel "(`signfc'1 s.d. difference)"
		}
		if "`ctopt'" == "sdy" | "`ctopt'" == "sdyx" { 
			loc ystand "no"
			loc xstand "no"
			glob ystd$sfx = 1

			if inlist("`e(cmd)'","logit","logistic","ologit","probit", /// 
			  "oprobit","poisson","nbreg","zip","zinb")==1 {
				loc ystand "yes"
				if inlist("`e(cmd)'","logit","logistic","ologit","probit","oprobit")==1  {
					loc errvar = 1
					if inlist("`e(cmd)'","logit","logistic","ologit") ==1 	loc errvar = _pi^2/3
					predict `predstd' if e(sample), xb
					qui sum `predstd' if e(sample)
					glob ystd$sfx = `signfc'(`r(Var)' + `errvar')^.5
				}
				if inlist("`e(cmd)'","poisson","nbreg","zip","zinb")==1 {
					qui sum `e(depvar)' if e(sample)
					glob ystd$sfx = (`r(Var)'/`r(mean)'^2)^.5
				}
			}
			if "`ystand'" == "yes" {
				loc fcdel=`signfc'1/${ystd$sfx}
				loc titdel "(`signfc'1 unit difference)"
				loc titdvdel "-standardized"
				if "`ctopt'" == "sdyx" {
					loc fcdel= `fcdel'*${fsd$sfx}	
					loc xstand "yes"
					loc titdel "(`signfc'1 s.d. difference)"
				}
			}
			if "`e(cmd)'" == "mlogit" {
				loc ystand "yes" 
				if "`ctopt'" == "sdyx" loc xstand "yes"
			}
			if "`ystand'" == "no" noi disp _newline "{err: g(y) standardization not valid option for {txt: `e(cmd)'}. Option ignored.}"
		}
	} 
	if "`coeftype'" == "spost" {
		gettoken ctopt2 ctopt : ctopt , parse("(")
		gettoken ctopt3 ctopt : ctopt , bind match(pp)
		foreach nm in amtopt atopt {
			if strmatch("`ctopt2'","`nm'")	loc `nm' `"`ctopt3'"'
		}
	}
}
if "`coeftype'" == "" loc coeftype "b"
*** Check applicability of factor change option
loc fcc "no"
 if "`coeftype'" == "factor" {
	if inlist("`e(cmd)'","logit","logistic","ologit","mlogit","poisson","nbreg","zip","zinb")==1 | "`e(t0)'" == "_t0" loc fcc "yes"
	if "`fcc'" == "no" {
		loc coeftype "b" 
		noi disp _newline "{err: factor change not valid option for {txt: `e(cmd)'}. Option ignored.}"
	}
}

*** For getting SPOST effect verify that focal and modmerator are in factor var notation
if "`coeftype'" == "spost" & strmatch("${fmlist$sfx}","*#*") ==0 {
	noi disp _newline "{err: Focal and moderator must be specified in factor var notation for SPOST effect calculation. SIGREG terminated}."
	exit
	}
 *** Set critical value level PSIG,  adjustment methods ADJ1 (Bonoferroni or Sidak) ADJ2 (Pothoff) and distribution type DIST
***  Save QPOT and DFR for calculating p-level for significance region tables
gettoken alp mult : siglev , parse(",")  
loc psig=.05
if "`alp'"!="" loc psig= `alp'
loc adj1 ""
loc dist "Chi_sq" 
if strmatch("`mult'","*bon*") ==1 {
	loc psig= `psig'/(${fcnum$sfx}*(${fcnum$sfx}+1)/2)
	loc adj1 "bonferroni"
}
if strmatch("`mult'","*sid*") ==1 {
	loc psig= 1-(1-`psig')^(1/${fcnum$sfx})
	loc adj1 "sidak"
}
loc qpot=0
if strmatch("`mult'","*pot*") ==1 { 
	loc adj2 "potthoff"
	forvalues i=1/${mvarn$sfx} {
		loc qpot= `qpot' + ${mcnum`i'$sfx}
	}
}
if "`e(F)'" == ""   loc critfc = invchi2tail(`qpot'+1,`psig')
if "`e(F)'" != "" {
	loc critfc= invFtail(`qpot'+1,`e(df_r)',`psig')
	loc dfr=`e(df_r)'
	loc dist "F"
}
*** Text to print reporting critical value and adjustments
loc crtval=strofreal(`critfc',"%7.3f")
loc pval=strofreal(`psig',"%7.4f")
loc adjtxt "Critical value `dist' = {res:`crtval'} set with p = {res:`pval'}"
if "`adj2'" != "" | "`adj1'" != "" loc adjtxt "`adjtxt' , adjusted by `adj1' `adj2' method(s)"

*** Report back options specified *******************************************************
noi disp _newline as txt "{ul:Boundary Value Analysis Options Specified or Default}" _newline
	noi disp as txt "    Skip BVA  = " as res " `skipbva'"
	if "`skipbva'" == "no" noi disp as txt "    Details " as res " `concise'"
	if "`plotjn'" != "" 	noi disp as txt "   BV Plot saved as " as res " `pltnm'"
	if "`plotopts'" != "" 	noi disp as txt "   customized with" as res " `pltopts'"

noi disp _newline as txt "{ul:Significance Region Table Options Specified or Default}" _newline
	noi disp as txt "    `adjtxt' " 
	noi disp as txt "    Effect type = " as res "`coeftype'   `titdel' "
	if "`coeftype'" == "spost"   noi disp as text "        amtopt = " as res "`amtopt'" as txt "  atopt = " as res "`atopt'" 
	noi disp as txt "    Decimals reported in tables = {res:`ndigits'}"
	if "`save'" != "" 	noi disp as txt "    Sig Region results saved: " as res " `save'"
noi disp _newline as txt " "




***		One Moderator **************************************************************************************************************
***						Do Boundary Value Calc/Tables 1st then Sig Region Table.  No BV PLOT needed.
************************************************************************************************************************************


if ${mvarn$sfx}==1  {

***  Can only do BV for interval single/dummy moderator.  Screen using MCNUM1 = # cats for Mod 1

if ${mcnum1$sfx} == 1 & "`skipbva'" == "no" {

***  Loop over # of Equations  (=1 except for mlogit & others TBD)
***     For ologit/oprobit and SPOST effect, set eqitot = # of DV categories 
***
loc eqitot = ${eqnum$sfx2} 
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost"  loc eqitot =  ${ordcatnum$sfx2} 

forvalues eqi=1/ `eqitot' {
glob eqnow$sfx2: word `eqi' of ${eqlist$sfx2}
if "${eqnow$sfx2}" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 continue

***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
if "${ordcatnum$sfx2}" == "" | "`coeftype'" != "spost" qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do
loc titdv "g(${dvname$sfx})"
if "`coeftype'" == "spost" | "`coeftype'" == "factor" loc titdv "${dvname$sfx}"

loc dvadd ""
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost" {
	qui run `c(tmpdir)'/globsaveeq1$sfx2.do
	loc dvadd ":${eqnow$sfx2}"
}

** Initialize counter for rows of table I and variables to hold info to list in table using LIST command
loc i=0
foreach v in `rowvar' `bval1' `sigchg1' `bval2' `sigchg2' {
	generate `v' = ""
}
noi disp _newline(2) as txt ///
	" {ul:Boundary Values for Significance of Effect of ${fvldisp$sfx} on {res:g(${dvname$sfx}`dvadd')} Moderated by ${mvldisp1$sfx}}" ///
	_newline "   `adjtxt'" 

***  For nominal focal (FCNUM >1) Loop over categories which each have diffferent moderated effects.
***  SOLVEBVQUAD.ADO solves the quadratic eqn to get boundary values and derivative to determine chnage to Sig Deriv >0) vs Chg to NS (Deriv <0) at BV
forvalues fci=1/${fcnum$sfx} {
	solvebvquad  , mod1(1) wcrit(`critfc') fnum(`fci') eqn(${eqname$sfx})
	foreach nm in bv1 dbv1 bv2 dbv2 {
		loc `nm'=`r(`nm')'
	}

**** Format vars to create table, set varname to retae Table Column Headers
	format `rowvar' %12s		/* Focal var name/cat */
	format `bval1' %-12s		/* 1st Boundary Value */
	format `sigchg1' %-13s		/* Direction of 1st significance change */
	format `bval2' %-12s		/* 2nd Boundary Value */
	format `sigchg2' %-13s		/* Direction of 2nd significance change */

	char `rowvar'[varname] "Effect of ${fvldisp$sfx}"
	char `bval1'[varname] "When ${mvldisp1$sfx} >= "
	char `bval2'[varname] "When ${mvldisp1$sfx} >= "
	char `sigchg1'[varname] "Sig Changes"
	char `sigchg2'[varname] "Sig Changes"
	
*** Label 1st column with name focal var categories if nominal and as effect of focal var if interval
	replace `rowvar' = "${fvnamec`fci'$sfx}" in `=`i'+1'
	if ${fcnum$sfx} == 1  {
		char `rowvar'[varname] " "
		replace `rowvar' = "Effect of ${fvnamec`fci'$sfx}" in `=`i'+1'
	}

***   Fill in BVs and Direction of Change Info.  CONCISE excludes Derivative values,numeric BVs for out-of-range sig changes
		loc ++i
		forvalues j=1/2 {
			if `dbv`j'' < 0 {
				replace `sigchg`j'' = " to Not Sig " in `i'
				if "`concise'" != "concise" replace `sigchg`j'' = " to Not Sig ["+ strofreal(`dbv`j'',"%8.`ndigits'f") + "]" in `i'
			}			
			if `dbv`j'' >= 0 {
				replace `sigchg`j'' = "   to Sig " in `i'
				if "`concise'" != "concise" replace `sigchg`j'' = " to Sig ["+ strofreal(`dbv`j'',"%8.`ndigits'f") + "]" in `i'
			}
			if `dbv`j'' == . replace `sigchg`j'' = "   Never " in `i'
			if `bv`j'' != . replace `bval`j'' = "     "+strofreal(`bv`j'',"%12.`ndigits'f") in `i'
			if `bv`j''  < ${mmin1$sfx} {
				replace `bval`j'' = " " + strofreal(`bv`j'',"%12.`ndigits'f") + " (< min)" in `i'
				if "`concise'" == "concise" {
					replace `bval`j'' = "    NA (< min)" in `i'
					replace `sigchg`j'' = "    NA   " in `i'
				}
			}
			if `bv`j''  > ${mmax1$sfx} & `bv`j'' < . {
				replace `bval`j'' = " " + strofreal(`bv`j'',"%12.`ndigits'f") + " (> max)" in `i'
				if "`concise'" == "concise" {
					replace `bval`j'' = "    NA (> max)   " in `i'
					replace `sigchg`j'' = "    NA   " in `i'
				}
			}
			if `bv`j'' == . replace `bval`j'' = "     NA " in `i'
		}
}
***
***  LIST results then drop tempvars

noi list `rowvar' `bval1' `sigchg1' `bval2' `sigchg2'  in 1/`i',  abb(20)	noobs sep(0) subvarname  tab div 
if "`concise'" != "concise" noi disp as txt "     Note: Derivatives of Boundary Values in [ ]"
drop `rowvar' `bval1' `sigchg1' `bval2' `sigchg2' 
}
}
*** 
*** For Nominal moderator report that can't get BV, If requested BV plot report that is not a valid option for single mod
if "`skipbva'" == "no" {
if ${mcnum1$sfx} > 1 {
noi disp _newline(2) as err "Cannot calculate boundary values when moderator is categorical with > 2 categories" ///
	_newline as txt "Proceeding to empirically defined significance region analysis" _newline
}
if "`plotjn'" != ""  noi disp as error _newline(2) "Can only do boundary value plot for 2 moderator model. " ///
  "You specified {res:1} moderator" as txt " "
}
*
*** Significance Region Table Calculations *********************************************************************************

***  Loop over # of Equations  (=1 except for mlogit & others TBD)
***     For ologit/oprobit and SPOST effect, set eqitot = # of DV categories 
***
loc eqitot = ${eqnum$sfx2} 
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost"  loc eqitot =  ${ordcatnum$sfx2} 

forvalues eqi=1/ `eqitot' {

glob eqnow$sfx2: word `eqi' of ${eqlist$sfx2}
if "${eqnow$sfx2}" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 & ( "`e(cmd)'" != "mlogit" | ///
	( "`e(cmd)'" == "mlogit"  & "`coeftype'" != "spost" ) ) continue

***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
if "${ordcatnum$sfx2}" == "" | "`coeftype'" != "spost" qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do
loc margout ""
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost" {
	qui run `c(tmpdir)'/globsaveeq1$sfx2.do
	loc margout "out(`eqi')"
	}

if "`ystand'" == "yes"  & "`estcmd'" == "mlogit" {
	loc errvar = _pi^2/3
	capture drop `predstd' 
	predict `predstd' if e(sample), xb outcome("${eqnow$sfx2}")
	qui sum `predstd' if e(sample)
	glob ystd$sfx = (`r(Var)' + `errvar')^.5
	loc fcdel=`signfc'1/${ystd$sfx}
	loc titdvdel "-standardized"
	if  "`xstand'" == "yes" {
		loc fcdel= `fcdel'*${fsd$sfx}	
		loc titdel "(`signfc'1 s.d. difference)"
	}
}
loc titdv "g(${dvname$sfx})"
if "`coeftype'" == "spost" | "`coeftype'" == "factor" loc titdv "${dvname$sfx}"
if "`coeftype'" == "spost" & inlist("`e(cmd)'","mlogit","ologit","oprobit") == 1  {
	loc titdv "`e(depvar)'[${eqnow$sfx2}]"
*	loc amtopt "`amtopt' out(`eqi')"
}
loc titdv "`titdv'`titdvdel'"

***			Set columan and row labels
loc cval: list sizeof global(mvrange1$sfx)
loc cn ""
forvalues j=1/`cval' {
	loc cn "`cn' ${mvlabm1c`j'$sfx}"
}
loc rn ""
forvalues i=1/${fcnum$sfx} {
	loc rn "`rn' ${fvnamec`i'$sfx}"
}

*** open file if request saving matrix or table (in separate sheets). Uses PUTEXCEL
if "`save'" != "" {
	loc cpos=strpos("`save'", ",") -1
	loc pfile = substr("`save'",1, `cpos')
	loc pfile = strrtrim("`pfile'")
	loc svstub = substr("`save'", `=`cpos'+2', .)
	loc mt1: word 1 of `svstub'
	loc mt2: word 2 of `svstub'
**	loc pfile: word 1 of `save'
**	loc mt1: word 2 of `save'
**	loc mt2: word 3 of `save'
	loc matyn ""
	loc tabyn ""
	if strmatch("`mt1'","mat*")==1 	| strmatch("`mt2'","mat*")==1  loc matyn "y"
	if strmatch("`mt1'","tab*")==1 	| strmatch("`mt2'","tab*")==1  loc tabyn "y"
	loc repmod "modify"
	if "`fopenyet'" == "no" {
		loc fopenyet "yes"
		loc repmod "replace"
	}	
putexcel set "`pfile'" , sheet(mat_${eqnow$sfx2}, replace) `repmod'
putexcel A1= ("Matrices")
putexcel set "`pfile'" , sheet(tab_${eqnow$sfx2}, replace) modify
putexcel A1= ("Table")
}
*** set line separator length, indent, row & col labels as strings using RCFORM.ADO
loc hlinsz=max(`cval'*11+16, 52)
loc indent = round(max(1, `=(52-10*`cval'-15)/2'))
rcform , nmlist("`cn'") nmsz(`cval') len(10)
loc cnstr "`r(nmstr)'"
rcform , nmlist("`rn'") nmsz(${fcnum$sfx}) len(13)
loc rnstr "`r(nmstr)'"

***	Matrices: SRB = moderated effect, SRVB = Var(bmod),   SRSIG = pvalue of WALD test
mat `srb'=J(${fcnum$sfx},`cval',.)
mat rowna `srb' = `rn'
mat colna `srb' = `cn' 
mat `srvb'=J(${fcnum$sfx},`cval',0)
mat rowna `srvb' = `rn'
mat colna `srvb' = `cn' 
mat `srvb'=J(${fcnum$sfx},`cval',0)
mat rowna `srvb' = `rn'
mat colna `srvb' = `cn' 
mat `srsig'=J(${fcnum$sfx},`cval',0)
mat rowna `srsig' = `rn'
mat colna `srsig' = `cn' 

*** Loop over Focal var category effects. Loop over display values of moderatorm MVRANGE at which test focal effect
*** GETBVARBMOD.ADO   moderated effect (bmod) and its varaince (vbmod)
*** 	results used to  calc p-level uisng F or Chi-square as set above in DIST. QPOT >0 does Pothhoff adjustment
***coeftype b=default  factor = factorchg option  spost = spost option indicator

forvalues fci=1/${fcnum$sfx} {
	forvalues j=1/`cval' {
		loc c1=1
		loc v1: word `j' of ${mvrange1$sfx} 
		if ${mcnum1$sfx} > 1 {
			loc c1=`j'-1*inrange(`j',2,`cval')
			loc v1=1*inrange(`j',2,`cval')
		}
if "`coeftype'" != "spost"	{ 
	getbvarbmod , fnum(`fci') mods(1) modsc(`c1') modsv(`v1') eqn(${eqname$sfx})
	mat `srb'[`fci',`j']=`r(bmod)'*`fcdel'
	if "`coeftype'"== "factor" 	mat `srb'[`fci',`j']=exp(`r(bmod)'*`fcdel')
	mat `srvb'[`fci',`j']=`r(vbmod)'
	mat `srsig'[`fci',`j'] = chi2tail(`qpot'+1,(`r(bmod)')^2/`r(vbmod)') 
	if "`dist'" == "F"   mat `srsig'[`fci',`j'] = Ftail(`qpot'+1,`dfr',(`r(bmod)')^2/`r(vbmod)')
}
	if "`coeftype'" == "spost" {
		loc m1sp "${mvar1c1$sfx}"
		loc v1sp "`v1'"
		if "${mvroot1$sfx}" != "" {
			loc m1sp "${mvroot1$sfx}"
			qui levelsof `m1sp', loc(mlev1)
			loc v1sp : word `j' of `mlev1'
		}
		loc vernum = _caller()
		version `vernum'
		version `vernum' , user
		version `vernum' : mchange ${fvarc`fci'$sfx} , `amtopt' at( `atopt' `m1sp' = `v1sp' ) stats(se) 	`margout'
		version 14.2
		loc rnm: rownames r(table)
		loc serow= strmatch("`rnm'","*Std Err*")
		loc sp: roweq r(table), quoted
		loc spvar : word 1 of `sp'
		loc sp: rownames r(table), quoted
		loc sinc=1+`serow'*(1-inlist(${fcnum$sfx},1))
		loc sptype ""
		forvalues ss=1(`sinc')`=`sinc'*${fcnum$sfx}' {
			loc sp1: word `ss' of `sp'
			loc sptype "`sptype'  `sp1'"
		}
		loc spatspec "`atopt'"
		mat `mchg' = r(table)
		if `serow' == 0 {
			loc mcb = el(`mchg',`fci',1)
			loc mcvar = el(`mchg',`fci',2)^2
		}
		if `serow' == 1 {
			loc mrow=`fci'*`sinc'-1 
			if ${fcnum$sfx} == 1 loc mrow = `fci'
			loc mcol=`eqi'
			if "${ordcatnum$sfx2}" !="" loc mcol=1
			loc mcb = el(`mchg',`mrow',`mcol')
			loc mcvar = el(`mchg',`=`mrow'+1',`mcol')^2
		}		
		mat `srb'[`fci',`j'] = `mcb'
		mat `srvb'[`fci',`j']=`mcvar'
		mat `srsig'[`fci',`j'] = chi2tail(`qpot'+1,(`mcb')^2/`mcvar') 
		if "`dist'" == "F"   mat `srsig'[`fci',`j'] = Ftail(`qpot'+1,`dfr',(`mcb')^2/`mcvar') 
}
	}
}
*GOBBLE
loc titeff "Effect"
if "`coeftype'" == "factor" loc titeff "Factor Change Effect"
if "`coeftype'" == "spost" loc titeff "SPOST Change Effect"

***
***  Following code saves formatted Sig Region Table Header lines to table sheet of excel file if SAVE option (table) specified
*** 
if "`tabyn'" == "y" {
*	noi disp _newline  as txt "Formatted Significance Region table written to sheet {res:{it:Table}} of " as res "`pfile'"
	putexcel set "`pfile'" , sheet(tab_${eqnow$sfx2}) modify
	putexcel B5=("`titeff' of ${fvldisp$sfx} `titdel' on `titdv' Moderated by ${mvldisp1$sfx},") ///
			 B6=("Formatted to Highlight Sign and Significance")
	putexcel (B7:`=char(65+`cval'+1)'7) , border(bottom,double)
	putexcel (C8:`=char(65+`cval'+1)'8) , merge border(bottom,thin) hcenter
	putexcel C8 = "${mvldisp1$sfx}" 
	putexcel B9= ("Effect of") , hcenter
	forvalues j=1/`cval' {
		loc chd: word `j' of `cnstr' 
		putexcel `=char(66+`j')'9 = "`chd'" , hcenter		
	}
	putexcel (B9:`=char(65+`cval'+1)'9) , border(bottom,thin)
*	putexcel B11 = "     Key: Plain font  = Pos, Not Sig     {bf:Bold font}*   = Pos, Sig " ///
*			 B12 = "          {it:Italic font} = Neg, Not Sig     {it:Italic font}* = Neg, Sig "
}
***
*** Display Sig Region Table Header.  Then Loop over Focal cat effects to display moderated effect formatted to show sign/significance
***		Body of display table built using MATA printf.  Collect format for line in FMTSTR and line contents in RESSTR

noi disp _newline(2) as txt "   Significance Region for `titeff' of ${fvldisp$sfx} `titdel' " _newline ///
	as res "   on `titdv'" as txt " at Selected Values of ${mvldisp1$sfx} " _newline "{hline `hlinsz'}"
noi disp "{col `=round(`hlinsz'/2)+4'}{ul:   At ${mvldisp1$sfx}=   }" _newline ///
	"{col `indent'}Effect of {col `=`indent'+15'}{c |}  `cnstr'" ///
	_newline "{col `indent'}{hline 15}{c +}{hline `=`hlinsz'-15-`indent''}"

forvalues i=1/${fcnum$sfx} {
	loc fmtstr "{col `indent'}{txt}%11s{col `=15+`indent''}{c |}{res}"
	loc rlab = "${fvnamec`i'$sfx}"
	loc resstr "`"`rlab'"'"
	
	if "`tabyn'" == "y" putexcel B`=`i'+9'= ("`rlab'") , right border(right,thin) txtindent(1)
	
***  For each display value of moderator SRFORM.ADO formats the moderated effect for Display and for saving in Excel file
*** 				Display Format		Excel Format
***		Neg NS		italics				italics
***		Neg Sig 	italics and *		bold italics & * & solid light gray fill
***		Pos NS		plain				plain
***		Pos Sig		Bold & *			bold  & * & cell solid medium gray fill

	forvalues j=1/`cval' {
		srform , matb(`srb') matp(`srsig') r(`i') c(`j') ndig(`ndigits') psig(`psig') coeftype(`coeftype')
		loc fmtstr "`fmtstr'`r(fmt)'"
		loc resstr "`resstr',"`r(val)'""
		if "`tabyn'" == "y" putexcel `=char(66+`j')'`=`i'+9' = (`r(xval)'), `r(xfmt)' 
		}
	noi mata: printf("`fmtstr'\n",`resstr')
}
noi disp as txt "{hline `=14+`indent''}{c BT}{hline `=`hlinsz'-15-`indent''}"
noi disp as txt "     {ul:Key}: Plain font  = Pos, Not Sig     {bf:Bold font}*   = Pos, Sig "
noi disp as txt "          {it:Italic font} = Neg, Not Sig     {it:Italic font}* = Neg, Sig "
if "`coeftype'" == "spost" noi disp _newline(2) as txt "Spost Effect for {res: `spvar'} specified as amount = {res: `sptype'}" ///
	"  calculated with " _newline "   at( {res: `spatspec'} )"
if "`ystand'" == "yes" noi disp _newline(2) as txt "Std. Dev. of latent outcome  = " as res %9.4f ${ystd$sfx} as txt " "

***  Put table footer in excel.  IF SAVE option (matrix) specifeid , write matrices SRB, SRVB & SRSIG to mat_eqnow sheet of excel file

if "`tabyn'" == "y"  {
	if "`coeftype'" == "spost" ///
		putexcel B1 = ("Spost Effect for `spvar' specified as amount = `sptype' , calculated with")  B2 = ("   at( `spatspec' )")
	putexcel (B`=${fcnum$sfx}+9':`=char(65+`cval'+1)'`=${fcnum$sfx}+ 9')  , border(bottom,double)
	loc rnow = ${fcnum$sfx}+11
	putexcel B`rnow'  = ("Key") , underline
	putexcel B`=`rnow'+1' =("Plain font, no fill") D`=`rnow'+1' = ("Pos, Not Sig") D`=`rnow'+2' = ("Pos, Sig") D`=`rnow'+3' = ("Neg, Not Sig") D`=`rnow'+4' = ("Neg, Sig") , left
	putexcel (B`=`rnow'+2':C`=`rnow'+2') = ("Bold *, filled")  , merge left bold fpat(solid,"140 140 140")
	putexcel B`=`rnow'+3' =("Italic, no fill") , left italic 
	putexcel (B`=`rnow'+4':C`=`rnow'+4') =("Bold Italic *, filled") , merge left bold italic fpat(solid,"210 210 210")
	if "`ystand'" == "yes" putexcel   B`=`rnow'+6' = ("S.D. latent outcome = `= strofreal(${ystd$sfx},"%9.4f")'")

	noi disp _newline  as txt "Formatted Significance Region table written to sheet {res:{it:tab_${eqnow$sfx2}}} of " as res "`pfile'"	
}
if "`matyn'" == "y" {
	noi disp _newline  as txt "Significance Region matrices written to sheet {res:{it:mat_${eqnow$sfx2}}} of " as res "`pfile'"

	putexcel set "`pfile'" , sheet(mat_${eqnow$sfx2}) modify
	putexcel A1 = ("Coefficient, Var(Coef) and Significance Level Matrices for Effect of ${fvldisp$sfx} `titdel'") ///
		A2 = ("on `titdv' at Selected Values of ${mvldisp1$sfx} (Col)") ///
		A3 = ("Coefficient")
	putexcel B3 = mat(`srb') , names
	putexcel A`=3+(${fcnum$sfx}+2)' = ("Var(Coef)")
	putexcel B`=3+(${fcnum$sfx}+2)'= mat(`srvb') , names
	putexcel A`=3+2*(${fcnum$sfx}+2)' = ("p-level")
	putexcel B`=3+2*(${fcnum$sfx}+2)' = mat(`srsig') , names

}
}
}
***
***		Up to 4 Moderators, can include 3way only if between M1 & M2 ****************************************************
if  ${mvarn$sfx}> 1 & ${mvarn$sfx}<= 4  {

***  Loop over # of Equations  (=1 except for mlogit & others TBD)
***     For ologit/oprobit and SPOST effect, set eqitot = # of DV categories 
***
loc eqitot = ${eqnum$sfx2} 
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost"  loc eqitot =  ${ordcatnum$sfx2} 

forvalues eqi=1/ `eqitot' {
	glob eqnow$sfx2: word `eqi' of ${eqlist$sfx2}
	if "${eqnow$sfx2}" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 continue

	***		load globals created by instspec.ado & definefm.ado
	capture drop esamp$sfx
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost" qui run `c(tmpdir)'/globsaveeq1$sfx2.do
if "${ordcatnum$sfx2}" == "" | "`coeftype'" != "spost" qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do
	loc spad ""
	if "`concise'" != "concise" loc spad "___"  /*Create semblance of horizontal line separator if concise not requested*/
***		Set up value labels for BV plots (BVXLAB & BVYLAB) and Sig region tables M1NM & M2NM)
loc m1val: list sizeof global(mvrange1$sfx)
loc m1nm ""
loc bvxlab ""
forvalues mvi=1/`m1val' {
	loc m1nm "`m1nm' ${mvlabm1c`mvi'$sfx}"
	loc val: word `mvi' of ${mvrange1$sfx}
	loc bvxlab =`"`bvxlab'"' +  " `=strofreal(`val',"%10.${mvdigit1$sfx}f")'"  + `" ""' + "${mvlabm1c`mvi'$sfx}" + `"""'
}

loc m2val: list sizeof global(mvrange2$sfx)
loc bvylab ""
loc m2nm ""
forvalues mvi=1/`m2val' {
	loc m2nm "`m2nm' ${mvlabm2c`mvi'$sfx}"
	loc val: word `mvi' of ${mvrange2$sfx}
	loc bvylab =`"`bvylab'"' +  " `=strofreal(`val',"%10.${mvdigit2$sfx}f")'"  + `" ""' + "${mvlabm2c`mvi'$sfx}" + `"""'
}
*** Skip or do BVA check
	
*** do pairs of moderators as table focus, loop over other moderators. start with 1&2 then do 2&1, each looped over 3 & 4 
***	 If 4 specified then do 3 & 4 as focus looped over 1&2.  If 3 but not 4 speciifed  do 3 & 2 looped over 1.

loc nrep = 1
if ${mvarn$sfx} > 2 loc  nrep = 2

***		initialize temp vars
foreach v in `rowvar' `bval1' `sigchg1' `bval2' `sigchg2' {
capture	generate `v' = ""
}
***
***		Define which moderators treated as focus (MOD1 & MOD2) and which as loop (MOD3 & MOD4)
loc titeff "Effect"
if "`coeftype'" == "factor" loc titeff "Factor Change Effect"
if "`coeftype'" == "spost" loc titeff "SPOST Change Effect"

forvalues irep=1/`nrep' {
	loc mistp=2
	if `irep'==2 & ${mvarn$sfx}==3 loc mistp=1
	forvalues mii=1/`mistp' {
		loc mod1 = `mii'
		loc mod2 = 3-`mii'
		loc mod3 ""
		loc mod4 ""
		if ${mvarn$sfx} >= 3  loc mod3 = 3
		if ${mvarn$sfx} > 3 loc mod4 = 4
		if `irep'==2 {
			loc mod1 = 2+`mii'
			loc mod2 = 5-`mii'
			loc mod3 = 1
			loc mod4 = 2
			if ${mvarn$sfx}==3 {
				loc mod2=2	
				loc mod4 ""
			}
		}
***
***		Skip BV analysis if MOD1 is multi-cat nominal or there is 3way and MOD1 > 2.  Set up record/row counter (I) and loop combo panel counter (IPAN)
if `mod1' > 2 & "${int3way$sfx}" == "y" & "`skipbva'" == "no" {
	noi disp as error _newline(2) "Can only do boundary value calculation for ${mvldisp1$sfx} & ${mvldisp2$sfx} with their Interacton, " ///
	"not for additional moderators: ${mvldisp3$sfx} ${mvldisp4$sfx}." as txt " "
}

	if ${mcnum`mod1'$sfx} == 1 & (`mod1' < 3 | "${int3way$sfx}" != "y" ) & "`skipbva'" == "no"  {
		loc i=0
		foreach v in `rowvar' `bval1' `sigchg1' `bval2' `sigchg2' {
			replace `v' = ""
		}
		loc ipan=0
		loc mstp4: list sizeof global(mvrange`mod4'$sfx)
		if `mstp4'==0 loc mstp4=1
		loc mc4 ""
***
***		Set up loop var display values & labels (RVAL3/RLAB3, RVAL4/RLAB4). For multicat use cat names for "value" labels
***			For interval/single dummmy nominal: RVAL=display value
***			For multi-cat nominal: RVAL=1 for non-Base categories but =0 for Base category so rval*b = 0

		forvalues m4=1/`mstp4' {
			if "`mod4'" != "" {
				loc rval4: word `m4' of ${mvrange`mod4'$sfx}
				loc rlab4 = "${mvlabm`mod4'c`m4'$sfx}" 
				loc  mc4=1
			if ${mcnum`mod4'$sfx} >1 {	
			
*** if 1st category  set rval4= 0  and   mc4= 0, else rval4= 1 mc=4 mm-1 
				loc rval4=inrange(`m4',2,`mstp4')
				loc mc4=`m4'-1
			}
			}
		loc mstp3: list sizeof global(mvrange`mod3'$sfx)
		if `mstp3'==0 loc mstp3=1
		loc mc3 ""
		
		forvalues m3=1/`mstp3' {
			if "`mod3'" != "" {
			loc ++ipan
			loc rval3: word `m3' of ${mvrange`mod3'$sfx}
			loc rlab3 = "${mvlabm`mod3'c`m3'$sfx}"
			loc mc3=1
			if ${mcnum`mod3'$sfx} >1 {
*** if 1st category  set rval3= 0  and   mc3= 0, else rval3= 1 mc=3 mm-1 
				loc rval3=inrange(`m3',2,`mstp3')
				loc mc3=`m3'-1
			}
			}
*** Display table title appropriate for # mods
		loc nl = 2
		if `ipan' == 1 loc nl = 6 
		loc npan=0

***  Skip BVA if nobva option		
		if "`skipbva'" == "no" {	

		if ${mvarn$sfx}< 3 {
			noi disp _newline(`nl') as txt ///
			" {ul:${fvldisp$sfx} Effect Significance, Boundary Values for ${mvldisp`mod1'$sfx} on {res:g(${dvname$sfx}`dvadd')} Given ${mvldisp`mod2'$sfx}}" ///
			_newline "   `adjtxt'"  
		}
		if ${mvarn$sfx}==3 { 
			loc npan=`mstp3'
			noi disp _newline(`nl') as txt ///
				" {ul:${fvldisp$sfx} Effect Significance, Boundary Values for ${mvldisp`mod1'$sfx} on {res:g(${dvname$sfx})} Given ${mvldisp`mod2'$sfx} & ${mvldisp`mod3'$sfx}}" ///
				_newline "   `adjtxt'" "         Panel `ipan' of `npan' : ${mvname`mod3'c`mc3'$sfx} = {res:`rlab3'}"
		}
		if ${mvarn$sfx}==4  { 
			loc npan=`mstp3'*`mstp4'
			noi disp _newline(`nl') as txt ///
				" {ul:${fvldisp$sfx} Effect Significance, Boundary Values for ${mvldisp`mod1'$sfx} on {res:g(${dvname$sfx})} Given ${mvldisp`mod2'$sfx} &${mvldisp`mod3'$sfx} & ${mvldisp`mod4'$sfx}}" ///
				_newline "   `adjtxt'" "         Panel `ipan' of `npan' : ${mvname`mod3'c`mc3'$sfx} = {res:`rlab3'}  & ${mvname`mod4'c`mc4'$sfx} = {res:`rlab4'}"
		}
***	Set up var formats and	varnames to display BV table results

		forvalues fci=1/${fcnum$sfx} {
			format `rowvar' %15s
			format `bval1' %-12s
			format `sigchg1' %-13s
			format `bval2' %-12s
			format `sigchg2' %-13s

			char `rowvar'[varname] "Effect of ${fvldisp$sfx}"
			char `bval1'[varname] "When ${mvldisp`mod1'$sfx} >= "
			char `bval2'[varname] "When ${mvldisp`mod1'$sfx} >= "
			char `sigchg1'[varname] "Sig Changes"
			char `sigchg2'[varname] "Sig Changes"

			if ${fcnum$sfx} > 1 {
				loc ++i
				replace `rowvar' = " " in `i'
				loc ++i
				replace `rowvar' = "__${fvnamec`fci'$sfx} Effect__" in `i'
				replace `bval1' = "____________`spad'" in `i'
				replace `bval2' = "____________`spad'" in `i'
				replace `sigchg1' = "____________`spad'" in `i'
				replace `sigchg2' = "____________`spad'" in `i'		
			}
			loc ++i		
			replace `rowvar' = "At ${mvldisp`mod2'$sfx} =" in `i'
***	
***	Loop over MOD2 display values to calculate MOD1 BVs contingent on values of other MODS (2,3,4)

			loc nval: list sizeof global(mvrange`mod2'$sfx)
			if ${mcnum`mod2'$sfx} > 1 loc nval= ${mcnum`mod2'$sfx} +1
			forvalues ii= 1/`nval' {
				loc ++i
				loc rlab = "${mvlabm`mod2'c`ii'$sfx}"
				loc rval: word `ii' of ${mvrange`mod2'$sfx}	
				replace `rowvar' = "`rlab'" + "  " in `i'
				loc mc2=1
				if ${mcnum`mod2'$sfx} > 1 {
					loc mc2=`ii'-1
					if `ii'==1 	loc mc2=1
					loc rval = inrange(`ii',2,`nval')
				}
				solvebvquad  , mod1(`mod1') wcrit(`critfc') fnum(`fci') mods(`mod2' `mod3' `mod4') modsc(`mc2' `mc3' `mc4') modsv(`rval' `rval3' `rval4') int3(${int3way$sfx}) eqn(${eqname$sfx}) 
				foreach nm in bv1 dbv1 bv2 dbv2 {
					loc `nm'=`r(`nm')'
				}
***
***	Interpet BVs and their derivatives to report if BV marks change to SIg or CHange to NS				
				forvalues j=1/2 {
					
					if `dbv`j'' < 0 {
						replace `sigchg`j'' = " to Not Sig " in `i'
						if "`concise'" != "concise" replace `sigchg`j'' = " to Not Sig ["+ strofreal(`dbv`j'',"%8.`ndigits'f") + "]" in `i'
					}			
					if `dbv`j'' >= 0 {
						replace `sigchg`j'' = "   to Sig   " in `i'
						if "`concise'" != "concise" replace `sigchg`j'' = " to Sig ["+ strofreal(`dbv`j'',"%8.`ndigits'f") + "]" in `i'
					}
					if `dbv`j'' == . replace `sigchg`j'' = "   Never" in `i'
					if `bv`j'' != . replace `bval`j'' = "    "+strofreal(`bv`j'',"%12.`ndigits'f") in `i'
					if `bv`j''  < ${mmin`mod1'$sfx} {
						replace `bval`j'' = " "+strofreal(`bv`j'',"%12.`ndigits'f") + " (< min)" in `i'
						if "`concise'" == "concise" {
							replace `bval`j'' = "   NA (< min)   " in `i'
							replace `sigchg`j'' = "     NA   " in `i'
						}
					}
					if `bv`j''  > ${mmax`mod1'$sfx} & `bv`j'' < . {
						replace `bval`j'' = " "+strofreal(`bv`j'',"%12.`ndigits'f") + " (> max)" in `i'
						if "`concise'" == "concise" {
							replace `bval`j'' = "   NA (> max)   " in `i'
							replace `sigchg`j'' = "     NA   " in `i'
						}
					}
					if `bv`j'' == . replace `bval`j'' = "      NA" in `i'
				}
			}			
		}
		noi list `rowvar' `bval1' `sigchg1' `bval2' `sigchg2'  in 1/`i', abb(20) noobs sep(0) subvarname  tab div 
		if "`concise'" != "concise" noi disp as txt "     Note: Derivatives of Boundary Values in [ ]"
***
***	Clear contents of listing vars & reset record counter (I) then go back and recalculate for next combination of MOD3-MOD4 values

		foreach v in `rowvar' `bval1' `sigchg1' `bval2' `sigchg2' {
			replace `v' = ""
		}
		loc i=0
		}
		}
	}
}
	if ${mcnum`mod1'$sfx} > 1 & "`skipbva'" == "no" {
	noi disp _newline(2) as err "Cannot calculate boundary values for ${mvldisp`mod1'$sfx} because it is categorical with > 2 categories" ///
		_newline as txt "Can still construct empirically defined significance region" _newline
	}
}
}
*** Plot BVs for M1 & M2. Only create plot if M2 as well as M1 are interval (single dummy).
***	Use 101 plot points from Min:Max for M1 (draw lines) and M2 (marker symbols drawn only every SK1 points).  

if ${mvarn$sfx}==2 & "`plotjn'" != ""  & ${mcnum1$sfx} == 1 & ${mcnum2$sfx} == 1  & "`skipbva'" == "no" {
	loc inc1= (${mmax1$sfx}-${mmin1$sfx})/100*1.2
	loc inc2= (${mmax2$sfx}-${mmin2$sfx})/100*1.2
	mat `m1bv' = J(101,3,.)
	mat colnames `m1bv' = `m2'  `m1bvns' `m1bvsig' 
	mat `m2bv' = J(101,3,.)
	mat colnames `m2bv' = `m1' `m2bvns' `m2bvsig' 
***
***	Draw separate plots for each effect/category of focal var
	forvalues fci=1/${fcnum$sfx} {
		loc i1=0
		loc i2=0
		forvalues vi=1/101 {
			loc ++i1
			loc mv2= ${mmin2$sfx}-5*`inc2' +`inc2'*(`i1'-1)
			solvebvquad , mod1(1) wcrit(`critfc') fnum(`fci') mods(2) modsc(1) modsv(`mv2') int3("${int3way$sfx}") eqn(${eqname$sfx})
			mat `m1bv'[`i1',1]=`mv2'
			if `r(dbv1)' < 0 {
				mat `m1bv'[`i1',2]=`r(bv1)'
				mat `m1bv'[`i1',3]=`r(bv2)'			
			}
			if `r(dbv1)' >= 0 & `r(dbv1)' < . {
				mat `m1bv'[`i1',2]=`r(bv2)'
				mat `m1bv'[`i1',3]=`r(bv1)'			
			}
		}
		forvalues vi=1/101 {
			loc ++i2
			loc mv1= ${mmin1$sfx}-5*`inc1' + `inc1'*(`i2'-1)
			solvebvquad , mod1(2) wcrit(`critfc') fnum(`fci') mods(1) modsc(1) modsv(`mv1') int3("${int3way$sfx}") eqn(${eqname$sfx})
			mat `m2bv'[`i2',1]=`mv1'
			if `r(dbv1)' < 0 {
				mat `m2bv'[`i2',2]=`r(bv1)'
				mat `m2bv'[`i2',3]=`r(bv2)'			
			}
			if `r(dbv1)' >= 0  & `r(dbv1)' < . {
				mat `m2bv'[`i2',2]=`r(bv2)'
				mat `m2bv'[`i2',3]=`r(bv1)'			
			}
		}
		svmat `m1bv' , name(col)
		svmat `m2bv' , name(col)
***		
***	
		 forvalues j=1/2 {
			 replace `m`j'bvns' = ${mmin`j'$sfx} - 10*`inc`j'' if `m`j'bvns' < ${mmin`j'$sfx} - 10*`inc`j'' &  `m`j'bvns' <=  `m`j'bvsig'
			 replace `m`j'bvns' = ${mmin`j'$sfx} - 5*`inc`j'' if `m`j'bvns' < ${mmin`j'$sfx} - 10*`inc`j'' &  `m`j'bvns' >  `m`j'bvsig' 
			 replace `m`j'bvns' = ${mmax`j'$sfx} + 10*`inc`j'' if (`m`j'bvns' > ${mmax`j'$sfx} + 10*`inc`j'' & `m`j'bvns' < . ) &  `m`j'bvns' >=  `m`j'bvsig'
			 replace `m`j'bvns' = ${mmax`j'$sfx} + 5*`inc`j'' if (`m`j'bvns' > ${mmax`j'$sfx} + 10*`inc`j'' & `m`j'bvns' < . ) &  `m`j'bvns' <  `m`j'bvsig' 
			 replace `m`j'bvsig' = ${mmin`j'$sfx} - 7.5*`inc`j'' if `m`j'bvsig' < ${mmin`j'$sfx} - 7.5*`inc`j''
			 replace `m`j'bvsig' = ${mmax`j'$sfx}+ 7.5*`inc`j'' if (`m`j'bvsig' > ${mmax`j'$sfx} + 7.5*`inc`j'' & `m`j'bvsig' < . )
		}
***	Mod 1 BV marker spacing.  One every SK1 data points		

		loc pltnm2 "`pltnm'"
		if ${fcnum$sfx} > 1 loc pltnm2 "`pltnm'_${fvnamec`fci'$sfx}"		
		scatter `m2bvns' `m2bvsig' `m1' if `m2bvns' < . | `m2bvsig' < . , conn(l l) ms(i i) lc(gs5 gs5) lp(l dash ) lw(*.7 *.7) name(`pltnm2',replace) ///
			ylab(`bvylab' , labsize(*.65) nogrid) 	ti("Boundary Value Plot for Significance of ${fvnamec`fci'$sfx} on {res:g(${dvname$sfx})}"  /// 
			  "Moderated by ${mvldisp1$sfx} and  ${mvldisp2$sfx}", size(*.65) m(b+2) ) scheme(s1mono) /// 
			xlab(`bvxlab', labsize(*.65)) xline(${mmin1$sfx}, lw(thin) lc(gs13)) ysize(5.5) xsize(5.5) ///
			xline(${mmax1$sfx}, lw(thin) lc(gs13))  yline(${mmin2$sfx} , lw(thin) lc(gs13))  yline(${mmax2$sfx} , lw(thin) lc(gs13)) /// 
			xti("${mvldisp1$sfx}", size(*.65) ) yti("${mvldisp2$sfx}", size(*.65))  xsc( r(`=${mmin1$sfx} - 10*`inc1''  `=${mmax1$sfx} + 10*`inc1'' ))    ///
			ysc( r(`=${mmin2$sfx} - 10*`inc2''  `=${mmax2$sfx} + 10*`inc2'' ))    ///
			|| scatter `m2' `m1bvns'  if _n== `sk1'*int(_n/`sk1') | _n==1 ,  ms(X) mc(gs10)	///
			|| scatter `m2' `m1bvsig' if _n== `sk1'*int(_n/`sk1') | _n==1 , ms(O) mc(gs10) ///
			legend( cols(1) order( 1 "${fvnamec`fci'$sfx} turns NS with increasing ${mvldisp2$sfx} at ${mvldisp1$sfx}" /// 
				2 "${fvnamec`fci'$sfx} turns Sig with increasing ${mvldisp2$sfx} at ${mvldisp1$sfx}" ///
				3 "${fvnamec`fci'$sfx} turns NS with increasing ${mvldisp1$sfx} at ${mvldisp2$sfx}"  /// 
				4 "${fvnamec`fci'$sfx} turns Sig with increasing ${mvldisp1$sfx} at ${mvldisp2$sfx}") size(*.7)) `pltopts'

		if "`pltstub'" != ""  {
			foreach v in m1 m2 m1bvsig m1bvns m2bvsig m2bvns {
				gen `v'_`pltstub'`fci' = ``v'' in 1/101
			}
		}
		drop  `m1' `m2' `m1bvsig' `m1bvns' `m2bvsig' `m2bvns'
		if `fci' != ${fcnum$sfx} {
			mat `m1bv' = J(101,3,.)
			mat `m2bv' = J(101,3,.)
		}
	}
	}
}
if "`skipbva'" == "no" {
if ${mvarn$sfx}>2 & "`plotjn'" != ""  disp as error _newline(2) "Can only do boundary value plot for 2 moderator model. You specified {res:${mvarn$sfx}} moderators" as txt " "

if ${mvarn$sfx}==2 & "`plotjn'" != "" & (${mcnum1$sfx}!=1 |  ${mcnum2$sfx}!=1)  disp as error _newline(2) ///
 "Cannot do boundary value plot becasue one of the moderators is categorical with > 2 categories" as txt " "
}

*****		Create Significance Region Table

***  Loop over # of Equations  (=1 except for mlogit & others TBD)
***     For ologit/oprobit and SPOST effect, set eqitot = # of DV categories 
***
loc eqitot = ${eqnum$sfx2} 
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost"  loc eqitot =  ${ordcatnum$sfx2} 


forvalues eqi=1/`eqitot' {
glob eqnow$sfx2: word `eqi' of ${eqlist$sfx2}
if "${eqnow$sfx2}" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 & ( "`e(cmd)'" != "mlogit" | ///
	( "`e(cmd)'" == "mlogit"  &"`coeftype'" != "spost" ) ) continue

***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
loc margout ""

if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost" {
	qui run `c(tmpdir)'/globsaveeq1$sfx2.do
		loc margout "out(`eqi')"
	}
if "${ordcatnum$sfx2}" == "" | "`coeftype'" != "spost" qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do

if "`ystand'" == "yes"  & "`estcmd'" == "mlogit" {
	loc errvar = _pi^2/3
	capture drop `predstd' 
	predict `predstd' if e(sample), xb outcome("${eqnow$sfx2}")
	qui sum `predstd' if e(sample)
	glob ystd$sfx = (`r(Var)' + `errvar')^.5
	loc fcdel=`signfc'1/${ystd$sfx}
	loc titdvdel "-standardized"
	if  "`xstand'" == "yes" {
		loc fcdel= `fcdel'*${fsd$sfx}	
		loc titdel "(`signfc'1 s.d. difference)"
	}
}
loc titdv "g(${dvname$sfx})"
if "`coeftype'" == "spost" | "`coeftype'" == "factor" loc titdv "${dvname$sfx}"
if "`coeftype'" == "spost" & inlist("`e(cmd)'","mlogit","ologit","oprobit") == 1  {
	loc titdv "`e(depvar)'[${eqnow$sfx2}]"
*	loc amtopt "`amtopt' out(`eqi')"
}
loc titdv "`titdv'`titdvdel'"
loc inttxt ""
if "${int3way$sfx}" == "y" loc inttxt " the Interaction of" 

***	Use moderator with the fewest display values as column variable (default is m1 & always m1 if m1 has <9 values)
***		
loc mod1 = 1
loc cval = `m1val'
loc cn "`m1nm'"
loc mod2 = 2
loc rval = `m2val'
loc rn "`m2nm'"
if `m2val' < `m1val' & `m1val' > 8 {
	loc mod1 = 2
	loc cval = `m2val'
	loc cn "`m2nm'"
	loc mod2 = 1
	loc rval = `m1val'
	loc rn "`m1nm'"
}
*** openfile if saving matrix or table
if "`save'" != ""  {
	loc cpos=strpos("`save'", ",") -1
	loc pfile = substr("`save'",1, `cpos')
	loc pfile = strrtrim("`pfile'")
	loc svstub = substr("`save'", `=`cpos'+2', .)
	loc mt1: word 1 of `svstub'
	loc mt2: word 2 of `svstub'

**	loc pfile: word 1 of `save'
**	loc mt1: word 2 of `save'
**	loc mt2: word 3 of `save'
	loc matyn ""
	loc tabyn ""
	if strmatch("`mt1'","mat*")==1 	| strmatch("`mt2'","mat*")==1  loc matyn "y"
	if strmatch("`mt1'","tab*")==1 	| strmatch("`mt2'","tab*")==1  loc tabyn "y"
	loc repmod "modify"
	if "`fopenyet'" == "no" {
		loc fopenyet "yes"
		loc repmod "replace"
	}
putexcel set "`pfile'" , sheet(mat_${eqnow$sfx2}, replace) `repmod'
putexcel A1= ("Matrices")
putexcel set "`pfile'" , sheet(tab_${eqnow$sfx2}, replace) modify
putexcel A1= ("Table")
}
*** set line separator length, indent, & RCFORM.ADO formats row & col labels as strings
loc hlinsz=max(`cval'*11+16, 52)
loc indent = round(max(1, `=(52-10*`cval'-15)/2'))
rcform , nmlist("`rn'") nmsz(`rval') len(13)
loc rnstr "`r(nmstr)'"
rcform , nmlist("`cn'") nmsz(`cval')  len(10)
loc cnstr "`r(nmstr)'"
ctrstr , instr("At ${mvldisp`mod2'$sfx}=") length(14)
loc colhead "`r(padded)'"

loc ipan=0
loc pantxt ""
loc mod4 ""
loc mod3 ""
if ${mvarn$sfx} >= 3  loc mod3 = 3
if ${mvarn$sfx} > 3 loc mod4 = 4
loc mstp4: list sizeof global(mvrange`mod4'$sfx)
if `mstp4'==0 loc mstp4=1
loc c4 ""
loc v4 ""
loc vlab4 " "
forvalues m4=1/`mstp4' {
	if "`mod4'" != "" {
		loc v4: word `m4' of ${mvrange`mod4'$sfx}
		loc v4hh "`v4'"
		loc vlab4 = "${mvlabm`mod4'c`m4'$sfx}"
		loc  c4=1
	if ${mcnum`mod4'$sfx} >1 {		
*** if 1st category  set v4= 0  and   c4= 1, else v4= 1 c4= index-1
		loc v4=inrange(`m4',2,`mstp4')
		loc c4=`m4'-1
		if `m4'== 1 loc c4= 1
	}
	}
loc mstp3: list sizeof global(mvrange`mod3'$sfx)
if `mstp3'==0 loc mstp3=1
loc c3 ""

forvalues m3=1/`mstp3' {
	loc ++ipan
	if "`mod3'" != "" {
	loc v3: word `m3' of ${mvrange`mod3'$sfx}
	loc v3hh "`v3'"
	loc vlab3= "${mvlabm`mod3'c`m3'$sfx}"
	loc c3=1
	if ${mcnum`mod3'$sfx} >1 {
*** if 1st category  set v3= 0  and   c3= 0, else v3= 1 c3= index-1 
		loc v3=inrange(`m3',2,`mstp3')
		loc c3=`m3'-1
		if `m3'== 1 loc c3= 1		
	}
loc pantxt "          Panel for ${mvldisp`mod3'$sfx} = `vlab3' " 
if "`mod4'" != ""  loc pantxt "          Panel for ${mvldisp`mod4'$sfx} = `vlab4'  and ${mvldisp`mod3'$sfx} = `vlab3' "
}


**
forvalues fci=1/${fcnum$sfx} {
***	SRB = moderated effect, srvb = Var(bmod)  SRSIG = p-level for WALD using DIST=F, Chi sq set above
	mat `srb'=J(`rval',`cval',.)
	mat rowna `srb' = `rn'
	mat colna `srb' = `cn' 
	mat `srsig'=J(`rval',`cval',0)
	mat rowna `srsig' = `rn'
	mat colna `srsig' = `cn' 
	mat `srvb'=J(`rval',`cval',0)
	mat rowna `srvb' = `rn'
	mat colna `srvb' = `cn' 
	
*** set mod3 & mod4 text for substitution into mchange for SPOST option
	loc sptxt ""
	if ${mvarn$sfx} > 2  { 
		loc sptxt "${mvar`mod3'c`c3'$sfx} = `v3'"
		if "`coeftype'" == "spost" & "${mvroot`mod3'$sfx}" != "" { 
			qui levelsof ${mvroot`mod3'$sfx}, loc(mlev3)
			loc v3sp : word `m3' of `mlev1'
			loc sptxt "${mvroot`mod3'$sfx} = `v3sp'"			
		}
	}
	if ${mvarn$sfx} > 3  {
		if "`coeftype'" == "spost" & "${mvroot`mod4'$sfx}" != "" { 
			qui levelsof ${mvroot`mod4'$sfx}, loc(mlev4)
			loc v4sp : word `m4' of `mlev4'
			loc sptxt " `sptxt' ${mvroot`mod4'$sfx} = `v4sp'"			
		}
		if "`coeftype'" != "spost" | "${mvroot`mod4'$sfx}" == "" loc sptxt "`sptxt' ${mvar`mod4'c`c4'$sfx} = `v4'"
	}
	forvalues i=1/`rval' {
		loc c2=1
		loc v2: word `i' of ${mvrange`mod2'$sfx} 
		loc v2hh "`v2'"
		
		if ${mcnum`mod2'$sfx} > 1 {
			loc c2=`i'-1*inrange(`i',2,`rval')
			loc v2=1*inrange(`i',2,`rval')
		}	
	forvalues j=1/`cval' {
		loc c1=1
		loc v1: word `j' of ${mvrange`mod1'$sfx} 
		loc v1hh "`v1'"
		if ${mcnum`mod1'$sfx} > 1 {
			loc c1=`j'-1*inrange(`j',2,`cval')
			loc v1=1*inrange(`j',2,`cval')
		}	
if "`coeftype'" != "spost"	{ 
	getbvarbmod , fnum(`fci') mods(`mod1' `mod2' `mod3' `mod4') modsc(`c1' `c2' `c3' `c4') modsv(`v1' `v2' `v3' `v4') int3(${int3way$sfx}) eqn(${eqname$sfx})
	mat `srb'[`i',`j']=`r(bmod)'*`fcdel'
	if "`coeftype'"== "factor" 	mat `srb'[`i',`j']=exp(`r(bmod)'*`fcdel')
	mat `srvb'[`i',`j']=`r(vbmod)'
	mat `srsig'[`i',`j'] = chi2tail(`qpot'+1,(`r(bmod)')^2/`r(vbmod)') 
	if "`dist'" == "F"   mat `srsig'[`i',`j'] = Ftail(`qpot'+1,`dfr',(`r(bmod)')^2/`r(vbmod)')
}
	if "`coeftype'" == "spost" {
		loc m1sp "${mvar`mod1'c`c1'$sfx}"
		loc v1sp "`v1'"
		if "${mvroot`mod1'$sfx}" != "" {
			loc m1sp "${mvroot`mod1'$sfx}"
			qui levelsof `m1sp', loc(mlev1)
			loc v1sp : word `j' of `mlev1'
		}
		loc m2sp "${mvar`mod2'c`c2'$sfx}"
		loc v2sp "`v2'"
		if "${mvroot`mod2'$sfx}" != "" {
			loc m2sp "${mvroot`mod2'$sfx}"
			qui levelsof `m2sp', loc(mlev2)
			loc v2sp : word `i' of `mlev2'
		}
		loc vernum = _caller()
		version `vernum'
		version `vernum' , user
		version `vernum' : 		mchange ${fvarc`fci'$sfx} , `amtopt' at( `atopt' `m1sp' = `v1sp' `m2sp' = `v2sp' `sptxt') stats(se)  `margout'	
*noi mat list r(table)
		version 14.2
		loc rnm: rownames r(table)
		loc serow= strmatch("`rnm'","*Std Err*")
		loc sp: roweq r(table), quoted
		loc spvar : word 1 of `sp'
		loc sp: rownames r(table), quoted
		loc sinc=1+`serow'*(1-inlist(${fcnum$sfx},1))
		loc sptype ""
		forvalues ss=1(`sinc')`=`sinc'*${fcnum$sfx}' {
			loc sp1: word `ss' of `sp'
			loc sptype "`sptype'  `sp1'"
		}
		loc spatspec "`atopt'"
		mat `mchg' = r(table)
		if `serow' == 0 {
			loc mcb = el(`mchg',`fci',1)
			loc mcvar = el(`mchg',`fci',2)^2
		}
		if `serow' == 1 {
			loc mrow=`fci'*`sinc'-1 
			if ${fcnum$sfx} == 1 loc mrow = `fci'
			loc mcol= `eqi'
			if "${ordcatnum$sfx2}" !="" loc mcol=1
			loc mcb = el(`mchg',`mrow',`mcol')
			loc mcvar = el(`mchg',`=`mrow'+1',`mcol')^2
		}		
		mat `srb'[`i',`j'] = `mcb'
		mat `srvb'[`i',`j']=`mcvar'
		mat `srsig'[`i',`j'] = chi2tail(`qpot'+1,(`mcb')^2/`mcvar') 
		if "`dist'" == "F"   mat `srsig'[`i',`j'] = Ftail(`qpot'+1,`dfr',(`mcb')^2/`mcvar') 
}	
	
***	if (`r(bmod)')^2/`r(vbmod)' > `critfc'  mat `srsig'[`i',`j']= 1
	}
	}
	loc panadj=(5+(`rval'+8)*`fci')*(`ipan'-1)
if "`tabyn'" == "y" {
	putexcel set "`pfile'" , sheet(tab_${eqnow$sfx2}) modify
	putexcel B`= 5+(`rval'+8)*(`fci'-1)+`panadj''=("`titeff' of ${fvnamec`fci'$sfx} `titdel' Moderated by`inttxt' ${mvldisp`mod1'$sfx} and ${mvldisp`mod2'$sfx}") ///
			 B`= 6+(`rval'+8)*(`fci'-1)+`panadj''=("on `titdv', Formatted to Highlight Sign and Significance `pantxt'")
	putexcel (B`= 7+(`rval'+8)*(`fci'-1)+`panadj'':`=char(65+`cval'+1)'`= 7+(`rval'+8)*(`fci'-1)+`panadj'') , border(bottom,double)
	putexcel (C`= 8+(`rval'+8)*(`fci'-1)+`panadj'':`=char(65+`cval'+1)'`= 8+(`rval'+8)*(`fci'-1)+`panadj'') , merge border(bottom,thin) hcenter
	putexcel C`= 8+(`rval'+8)*(`fci'-1)+`panadj'' = ("${mvldisp`mod1'$sfx}")
	putexcel B`= 9+(`rval'+8)*(`fci'-1)+`panadj''= ("${mvldisp`mod2'$sfx}") , hcenter
	forvalues j=1/`cval' {
		loc chd: word `j' of `cnstr' 
		putexcel `=char(66+`j')'`= 9+(`rval'+8)*(`fci'-1)+`panadj'' = ("`chd'") , hcenter		
	}
	putexcel (B`= 9+(`rval'+8)*(`fci'-1)+`panadj'':`=char(65+`cval'+1)'`= 9+(`rval'+8)*(`fci'-1)+`panadj'') , border(bottom,thin)
} 
noi disp _newline(2) as txt "   Significance Region for `titeff' of ${fvnamec`fci'$sfx} `titdel'" _newline ///
	as res "   on `titdv'" as txt " at Selected Values of`inttxt' ${mvldisp`mod1'$sfx} and ${mvldisp`mod2'$sfx} `pantxt'" _newline "{hline `hlinsz'}"
noi disp "{col `=round(`hlinsz'/2)+4'}{ul:   At ${mvldisp`mod1'$sfx}=   }" _newline ///
	"{col `indent'}`colhead'{col `=`indent'+15'}{c |}  `cnstr'" ///
	_newline "{col `indent'}{hline 15}{c +}{hline `=`hlinsz'-15-`indent''}"

forvalues i=1/`rval' {
	loc fmtstr "{col `indent'}{txt}%11s{col `=15+`indent''}{c |}{res}"
	loc rlab: word `i' of `rnstr'
	loc resstr "`"`rlab'"'"
	
	if "`tabyn'" == "y" putexcel B`=`i'+9+(`rval'+8)*(`fci'-1)+`panadj''= "`rlab'" , right border(right,thin) txtindent(1)
	forvalues j=1/`cval' {
		srform , matb(`srb') matp(`srsig') r(`i') c(`j') ndig(`ndigits') psig(`psig') coeftype(`coeftype')
		loc fmtstr "`fmtstr'`r(fmt)'"
		loc resstr "`resstr',"`r(val)'""
		if "`tabyn'" == "y" putexcel `=char(66+`j')'`=`i'+9+(`rval'+8)*(`fci'-1)+`panadj'' = `r(xval)', `r(xfmt)' 
		}
noi mata: printf("`fmtstr'\n",`resstr')
}
noi disp as txt "{hline `=14+`indent''}{c BT}{hline `=`hlinsz'-15-`indent''}"
if "`tabyn'" == "y"  putexcel (B`= `rval'+9 +(`rval'+8)*(`fci'-1)+`panadj'':`=char(65+`cval'+1)'`= `rval'+ 9 +(`rval'+8)*(`fci'-1)+`panadj'') , border(bottom,double)
loc panadj=(5+(3*(`rval'+2)+3)*`fci')*(`ipan'-1)
if "`matyn'" == "y" {
	putexcel set "`pfile'" , sheet(mat_${eqnow$sfx2}) modify
	putexcel A`=1+(3*(`rval'+2)+3)*(`fci'-1)+`panadj'' = ("Coefficient, Var(Coef) and Significance Level Matrices for Effect of ${fvnamec`fci'$sfx}") ///
		A`=2+(3*(`rval'+2)+3)*(`fci'-1)+`panadj''  = ("at Selected Values of`inttxt' ${mvldisp`mod1'$sfx} (Col) and ${mvldisp`mod2'$sfx} (Row) `pantxt'") ///
		A`=3+(3*(`rval'+2)+3)*(`fci'-1)+`panadj'' = ("Coefficient")
	putexcel B`=3+(3*(`rval'+2)+3)*(`fci'-1)+`panadj'' =mat(`srb') , names
	putexcel A`=3+(`rval'+2)+(3*(`rval'+2)+3)*(`fci'-1)+`panadj'' = ("Var(Coef)")
	putexcel B`=3+(`rval'+2)+ (3*(`rval'+2)+3)*(`fci'-1)+`panadj'' = mat(`srvb') , names
	putexcel A`=3+2*(`rval'+2)+ (3*(`rval'+2)+3)*(`fci'-1)+`panadj''  = ("p-level")
	putexcel B`=3+2*(`rval'+2)+ (3*(`rval'+2)+3)*(`fci'-1)+`panadj''  = mat(`srsig') , names
}
}
}
} 
noi disp as txt "     {ul:Key}: Plain font  = Pos, Not Sig     {bf:Bold font}*   = Pos, Sig "
noi disp as txt "          {it:Italic font} = Neg, Not Sig     {it:Italic font}* = Neg, Sig "
if "`coeftype'" == "spost" noi disp _newline(2) as txt "Spost Effect for {res: `spvar'} specified as amount = {res: `sptype'}" ///
	"  calculated with " _newline "   at( {res: `spatspec'} )"
if "`ystand'" == "yes" noi disp _newline(2) as txt "Std. Dev. of latent outcome  =" as res %9.4f ${ystd$sfx} as txt " "

if "`tabyn'" == "y" {
	putexcel set "`pfile'" , sheet(tab_${eqnow$sfx2}) modify
	loc rnow = `rval'+9 +(`rval'+8)*(${fcnum$sfx}-1)+`panadj'+2
	putexcel B`rnow'  = ("Key") , underline
	putexcel B`=`rnow'+1' =("Plain font, no fill") D`=`rnow'+1' = ("Pos, Not Sig") D`=`rnow'+2' = ("Pos, Sig") D`=`rnow'+3' = ("Neg, Not Sig") D`=`rnow'+4' = ("Neg, Sig") , left
	putexcel (B`=`rnow'+2':C`=`rnow'+2') = ("Bold *, filled")  , merge left bold fpat(solid,"140 140 140")
	putexcel B`=`rnow'+3' =("Italic, no fill") , left italic 
	putexcel (B`=`rnow'+4':C`=`rnow'+4') =("Bold Italic *, filled") , merge left bold italic fpat(solid,"210 210 210")
	if "`coeftype'" == "spost" ///
		putexcel B1 = ("Spost Effect for `spvar' specified as amount = `sptype' , calculated with " B2 = "   at( `spatspec' ))"
	if "`ystand'" == "yes" putexcel   B`=`rnow'+6' = ("S.D. latent outcome = `= strofreal(${ystd$sfx},"%9.4f")'")
	noi disp _newline  as txt "Formatted Significance Region table written to sheet {res:{it:tab_${eqnow$sfx2}}} of " as res "`pfile'"
}
if "`matyn'" == "y" /// 
	noi disp _newline  as txt "Significance Region matrices written to sheet {res:{it:mat_${eqnow$sfx2}}} of " as res "`pfile'"
}
}	
***	>4  Moderators ERROR****************************************************

if ${mvarn$sfx}>4 {
noi disp as error _newline(2) "Can only do calculations for up to 4 moderators.  You specified {res:${mvarn$sfx}} moderators" as txt " "
}

loc mygloblist:  all globals "*$sfx"
mac drop `mygloblist'
*
est restore `estint'
}
*
end
