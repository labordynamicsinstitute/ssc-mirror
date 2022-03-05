*!  definefm.ado Version 6.4	RL Kaufman 	03/18/2019

***  	Define focal and moderator variables and their proerties
***  	1.0  Works with MAIN INT2 INT3 option specification only. MAIN string contains 
***		     (varlist1, cat name(word) range(numlist)) (varlist2, cat name(word)  range(numlist)) ...
***		      Worked for MAIN using global macros
***		1.1  Added suffix to global macros defined as  "x`c(username)'" abbreviated to 10 characters
***			 removed "cat" from display option .  If varlist has > 1 var treated as categorical
***			 removed order from general options
***		1.2  padded names < abbrevn characters to abbrevn, default 12
***		2.0  Added expanding/assiging numlist display ranges, chnage input syntax to eliminate 
***			 display(  ) replaced with NAME() and RANGE() in any order after "varlist,"
***		2.1  Added assigning (F)MVNAMES to factor variables using root var value labels if exist
***		2.1.a	Fixed small glitches
***		2.2	 Added storing coefficents in global macros
***		2.2a Added parallel terms for 3way varnames/coeffs so can reference as f_i_m1_j_m2_k or as f_i_m2_k_m1_j
***		2.3 Set (f)mvrange to 0/#categories for categorical variables and added global containing value labels
***			corresponding to f.mvrange.  also NDIG option for #of digits
***		2.4 Added global to declare variable categorical MVISCAT# and FVISCAT: Speciyy CAT in MAIN((varlist cat name ...
***		2.5 Changed parsing of syntx to fix problems with parsing numlists
***		2.6 Forced display value range list to be 0/mcnum if option CAT specified
***	
***		3.0 Added definition of variable ESAMP$SFX to select user defined sample & global macros SUMWGT, WGTTYPE, WGTEXP user defined weighting
***			Weights treated as analytic weights when calcualating sample summary statistics BUT as user defined type for Margins .  NOT TESTED YET.
***			Added SUMWGT(no) option so user can request use of unweighted summary statistics
***		4.0 Added reporting of basic interaction model specifications
***		4.1 Fixed problem of too few cat vars & mis-labeled values if no user-value labels
***		4.2 Fixed problem of base other than 1st category for i.factorvar not hanlded properly
***		4.3 added  mvroot# with root name of moderator factor variables for use in SIGREG spost option
***		5.0 added  functionality for mlogit.  NEW: Programmer required options EQNOW(#) CMDNM(String) added
***		5.1 Changed range() options for +/- 2 s.d to include +/` 1 sd 
***		6.0 Save numdigits in globals for displaying predictor values based on range() optiont numlist
***			CHnae ndig() to ndigits()
***		6.1 fixed problem of glob sfx2 containing "~"
***		6.2 fixed problem of glob sfx containing "_" or other non alphanumeric characters
***		6.3 fixed problem with assigning name to global fvarc1$sfx and the focal var range when intspec does not include a range
***		6.4 fixed problem with defining default range for 2 category factor variable when range not user defined 


program definefm, rclass
version 14.2
syntax  , focal(varlist fv)  main(string asis)  int2(varlist fv)  eqnow(integer) cmdnm(string) ///
			[ DVName(string) EQName(string) int3(varlist fv) abbrevn(integer 12) NRANge(integer 5) pad NDIGits(integer 2) sumwgt(string) ] 
tempname bb

qui {			
*** 	clear global macros with $sfx suffix if exist then define suffix
if "$sfx" != ""  {
	loc myglob:  all globals "*$sfx"
	if "`myglob'" != "" mac drop `myglob'
} 

loc sfx11 "`=abbrev("x`c(username)'",10)'"
glob sfx "`=subinstr("`=strtoname("`sfx11'",0)'","_","x",.)'"

glob sfx  =subinstr("$sfx","~","",.)


***  define ordered color list gs# for bar charts
glo gslist$sfx "0 9 6 11 8 13 10 15 12 16" 	

***   save eqname 
if "`eqname'" != "" glo eqname$sfx "`eqname'"

***  User defined E(SAMPLE) and WEIGHTS for current model

if `eqnow' == 1 gen esamp$sfx = e(sample)
glob wgttype$sfx ""
glob wgtexp$sfx ""
glob sumwgt$sfx ""
if "`e(wtype)'" != "" {
	glob wgttype$sfx "`e(wtype)'"
	glob wgtexp$sfx "`e(wexp)'"
if "`sumwgt'" != "no"	glob sumwgt$sfx "[aweight `e(wexp)']"
}
*
***		Define focal and moderator main effect variables , display names, categorical and ranges 
stripfv "`focal'" 
glo fvlist$sfx "`r(strip)'"
loc ti=0
loc hmain=strtrim(stritrim(`"`main'"'))
while `"`hmain'"' != ""  & `"`hmain'"' !=  " "{
loc ++ti
gettoken main`ti' hmain : hmain , bind match(pp) 
}
loc modn=0
forvalues i=1/`ti' {
	gettoken vv`i' rest : main`i' , parse(",") 
	gettoken gg rest : rest , parse(",") 
	foreach nm in name range cat {
		loc `nm'inp = 0
		loc `nm'opt ""
	}
	while "`rest'" != ""  & "`rest'" !=  " " {
		gettoken mainopt rest  : rest , bind match(pp) 
		tokenize `mainopt', parse("()") 
			foreach nm in name range cat {
				if "`1'" == "`nm'" {
				loc `nm'inp =1
				loc `nm'opt `"`3'"'
				if "`nm'" == "range" {
					gettoken  gg hold : mainopt, bind parse("(")
					gettoken  rangeopt hold : hold ,  match(pp) 
				}				
			}	
		}
	}	
if `rangeinp'== 1 | `nameinp' ==1 | `catinp' == 1 {
		stripfv "`vv`i''" 
		loc vvar "`r(strip)'"
		loc isfv "`r(isfv)'"
		loc vvnum = `r(nvar)'
		if "`vvar'"!="${fvlist$sfx}" {
			loc ++modn
			glo mvlist`modn'$sfx "`vvar'"
			glo mcnum`modn'$sfx =`vvnum'
			glo mviscat`modn'$sfx "n"
			glo misfv`modn'$sfx "`isfv'"
			if `catinp' == 1 glo mviscat`modn'$sfx "y"
***		If moderator > 1 category or CAT option given to single dummy or moderator is factor variable,  mvrange is set to 0/mcnum because all categories will be displayed
***			mvdigit is set to 0 digits for axis label
			if ${mcnum`modn'$sfx} > 1 | `catinp' == 1  | "${misfv`modn'$sfx}" == "y" { 
				numlist "0/${mcnum`modn'$sfx}"
				glo mvrange`modn'$sfx  "`r(numlist)'"
				glob mvdigit`modn'$sfx = 0

			}
			
***		Set category variables and their display names
			if "`isfv'"== "n" {
				forvalues j=1/${mcnum`modn'$sfx}  {
					loc vnm: word `j' of `vvar'
					glo mvar`modn'c`j'$sfx "`vnm'" 
					proprstr "`vnm'" `abbrevn' "`pad'"
					glo mvname`modn'c`j'$sfx ="`r(padded)'"
				}
				proprstr "base" `abbrevn' "`pad'"
				glo mvname`modn'c0$sfx ="`r(padded)'"		
			}
			if "`isfv'"== "y" {
				fvexpand(`vv`i'')
				loc mvarlst `r(varlist)'
				loc vv: word 1 of `mvarlst'
				getfvname `vv'
				glob mvroot`modn'$sfx "`r(vname)'"
				loc pp=strpos("`vv'",".")
				loc pp1=`pp'+1		
				loc vvar= substr("`vv'",`pp1',.)
				loc rlab ""
				loc vln: list sizeof mvarlst
				loc jj=0
				forvalues j=1/`vln' {
***		Define mvar modn c'jj' based on VVAR (stripped base var) , mvname 'jj' also
					loc vv: word `j' of `mvarlst'
***		Check if VV contains "b" -- is the base category
					loc bp=strpos("`vv'","b.")	
					loc pp=strpos("`vv'",".")
					loc pp1=`pp'-1
					if `bp' !=0 loc pp1=`bp'-1					
					loc vval= substr("`vv'",1,`pp1')
					getvallab `vvar' `vval'
					if "${vlexst$sfx}" == "" {
						proprstr "`vv'" `abbrevn' "`pad'"
						if `bp'==0 { 
							loc ++jj
							glo mvname`modn'c`jj'$sfx ="`r(padded)'"
						}
						if `bp'!=0 	glo mvname`modn'c0$sfx ="`r(padded)'"
						if `jj'>0 & `bp' == 0 glo mvar`modn'c`jj'$sfx "`vv'" 
					}
					if "${vlexst$sfx}" != "" {
						if `bp'!=0 	glo mvname`modn'c0$sfx = "`r(vlab)'"
						if `bp'==0 	{
							loc ++jj
							glo mvname`modn'c`jj'$sfx ="`r(vlab)'"
						}
						if `jj'>0 & `bp' == 0 glo mvar`modn'c`jj'$sfx "`vv'" 
					}
				}
			}
		***		Create user defined ranges and set axis label digits
			if  `rangeinp' ==1 & ${mcnum`modn'$sfx} ==1 & `catinp' != 1 {
				loc rdef=inlist("`rangeopt'","minmax","meanpm1","meanpm2","meanpm1mm","meanpm2mm")
				if `rdef'==0 { 
					numlist "`rangeopt'"
					glo mvrange`modn'$sfx  "`r(numlist)'"
					axisdigit "`r(numlist)'"
					glob mvdigit`modn'$sfx =r(numd)
				}
				if `rdef'==1 {
					glob mvdigit`modn'$sfx = `ndigits'
					qui summ ${mvar`modn'c1$sfx} if esamp$sfx  ${sumwgt$sfx}
					foreach rt in max min sd mean {
						loc rr`rt'=r(`rt')
					}
					loc rrmp1= `rrmean'+`rrsd'
					if `rrmp1'> `rrmax' loc rrmp1 =`rrmax'
					loc rrmm1= `rrmean'-`rrsd'
					if `rrmm1' < `rrmin' loc rrmm1  =`rrmin'
					loc rrmp2= `rrmean'+2*`rrsd'
					if `rrmp2'> `rrmax' loc rrmp2  =`rrmax'
					loc rrmm2= `rrmean'-2*`rrsd'
					if `rrmm2'< `rrmin' loc rrmm2  =`rrmin'
					loc inc = (`rrmax' - `rrmin' )/`nrange'
					if "`rangeopt'" == "minmax" numlist "`rrmin'(`inc')`rrmax'"
					if "`rangeopt'" == "meanpm1" numlist "`rrmm1' `rrmean' `rrmp1'"
					if "`rangeopt'" == "meanpm2" numlist "`rrmm2' `rrmm1' `rrmean' `rrmp1' `rrmp2'"
					if "`rangeopt'" == "meanpm1mm" numlist "`rrmin' `rrmm1' `rrmean' `rrmp1' `rrmax'"
					if "`rangeopt'" == "meanpm2mm" numlist "`rrmin' `rrmm2' `rrmm1' `rrmean' `rrmp1' `rrmp2' `rrmax'"
					glo mvrange`modn'$sfx  "`r(numlist)'"
				}
			}
***		Create user defined display name
			if  `nameinp'==1 {
				proprstr "`nameopt'" `abbrevn' "`pad'"
				glo mvldisp`modn'$sfx  "`r(padded)'" 
			}
		}
		if "`vvar'"=="${fvlist$sfx}" {
			glo fcnum$sfx =`vvnum'
			glo fisfv$sfx "`isfv'"
			glo fviscat$sfx "n"
			if `catinp' == 1 glo fviscat$sfx "y"
			if "`isfv'"== "n" {
				forvalues j=1/${fcnum$sfx}  {
					loc vnm: word `j' of `vvar'
					glo fvarc`j'$sfx "`vnm'" 
					proprstr "`vnm'" `abbrevn' "`pad'"
					glo fvnamec`j'$sfx ="`r(padded)'"
				}
				proprstr "base" `abbrevn' "`pad'"
				glo fvnamec0$sfx ="`r(padded)'"		
			}
			if "`isfv'"== "y" {
				fvexpand(`vv`i'')
				loc fvarlst `r(varlist)'
				loc vv: word 1 of `fvarlst'
				loc pp=strpos("`vv'",".")
				loc pp1=`pp'+1		
				loc vvar= substr("`vv'",`pp1',.)
				loc rlab ""
				loc vln: list sizeof fvarlst
				loc jj=0
				forvalues j=1/`vln' {
***		Define fvarc'jj'  based on VVAR (stripped base var) and fvnamec`jj the same
					loc vv: word `j' of `fvarlst'
***		Check if VV contains "b" -- is base category
					loc bp=strpos("`vv'","b.")	
					loc pp=strpos("`vv'",".")
					loc pp1=`pp'-1
					if `bp' !=0 loc pp1=`bp'-1
					loc vval= substr("`vv'",1,`pp1')			
					getvallab `vvar' `vval'
					if "${vlexst$sfx}" == "" {
						proprstr "`vv'" `abbrevn' "`pad'"
						if `bp'==0 { 
							loc ++jj
							glo fvnamec`jj'$sfx ="`r(padded)'"
						}
						if `bp'!=0 	glo fvnamec0$sfx ="`r(padded)'"
						if `jj'>0 & `bp' == 0 glo fvarc`jj'$sfx "`vv'" 
					}
					if "${vlexst$sfx}" != "" {
						if `bp'!=0 	glo fvnamec0$sfx = strtoname("`r(vlab)'",0)
						if `bp'==0 	{
							loc ++jj
							glo fvnamec`jj'$sfx =strtoname("`r(vlab)'",0)
						}
						if `jj'>0 & `bp' == 0 glo fvarc`jj'$sfx "`vv'" 
					}
				}
			}
***		If focal > 1 category fvrange is set to 0/fcnum because all categories displayed 
***				fvdigit set to 0 axis label digits
			if ${fcnum$sfx} > 1  {
				numlist "0/${fcnum$sfx}"
				glo fvrange$sfx   "`r(numlist)'"
				glob fvdigit$sfx = 0

			}
			
***		Create user defined ranges
			if `rangeinp'==1 & ${fcnum$sfx} ==1 {
				loc rdef=inlist("`rangeopt'","minmax","meanpm1","meanpm2","meanpm1mm","meanpm2mm")
				if `rdef'==0 { 
					numlist "`rangeopt'"
					glo fvrange$sfx  "`r(numlist)'"
					axisdigit "`r(numlist)'"
					glob fvdigit$sfx =r(numd)				
				}
				if `rdef'==1 {
					qui summ ${fvarc1$sfx} if esamp$sfx  ${sumwgt$sfx}
					loc inc = (`r(max)' - `r(min)' )/`nrange'
					foreach rt in max min sd mean {
						loc rr`rt'=r(`rt')
					}
					loc rrmp1= `rrmean'+`rrsd'
					if `rrmp1'> `rrmax' loc rrmp1 =`rrmax'
					loc rrmm1= `rrmean'-`rrsd'
					if `rrmm1' < `rrmin' loc rrmm1  =`rrmin'
					loc rrmp2= `rrmean'+2*`rrsd'
					if `rrmp2'> `rrmax' loc rrmp2  =`rrmax'
					loc rrmm2= `rrmean'-2*`rrsd'
					if `rrmm2'< `rrmin' loc rrmm2  =`rrmin'
					loc inc = (`rrmax' - `rrmin' )/`nrange'
					if "`rangeopt'" == "minmax" numlist "`rrmin'(`inc')`rrmax'"
					if "`rangeopt'" == "meanpm1" numlist "`rrmm1' `rrmean' `rrmp1'"
					if "`rangeopt'" == "meanpm2" numlist "`rrmm2' `rrmm1' `rrmean' `rrmp1' `rrmp2'"
					if "`rangeopt'" == "meanpm1mm" numlist "`rrmin' `rrmm1' `rrmean' `rrmp1' `rrmax'"
					if "`rangeopt'" == "meanpm2mm" numlist "`rrmin' `rrmm2' `rrmm1' `rrmean' `rrmp1'`rrmp2' `rrmax'"
					glo fvrange$sfx  "`r(numlist)'"
					glob fvdigit$sfx = `ndigits'
				}
			}				
***		Create user defined display name
			if  `nameinp'==1 {
				proprstr "`nameopt'" `abbrevn' "`pad'"
				glo fvldisp$sfx "`r(padded)'" 
			}								
			if "${fvldisp$sfx}" == ""  glo fvldisp$sfx  "${fvnamec1$sfx}"
		}	
	}
	else if `rangeinp'== 0 & `nameinp' == 0 {
**		gettoken vv`i' main`i' : main`i' , parse(")")
		stripfv "`vv`i''" 
		loc vvar "`r(strip)'"
		loc isfv "`r(isfv)'"
		loc vvnum= `r(nvar)'
		if "`vvar'"!="${fvlist$sfx}" {
			loc ++modn
			glo mvlist`modn'$sfx "`vvar'"
			glo misfv`modn'$sfx "`isfv'"
			glo mviscat`modn'$sfx "n"
			glo mcnum`modn'$sfx = `vvnum'
			forvalues j=1/`vvnum' {
				loc vnm: word `j' of `vvar'
				glo mvar`modn'c`j'$sfx "`vnm'" 
				proprstr "`vnm'" `abbrevn' "`pad'"
				glo mvname`modn'c`j'$sfx = "`r(padded)'"
			}			
			
			if ${mcnum`modn'$sfx} > 1 | `catinp' == 1 | "${misfv`modn'$sfx}" == "y" { 
				numlist "0/${mcnum`modn'$sfx}"
				glo mvrange`modn'$sfx  "`r(numlist)'"
				glob mvdigit`modn'$sfx = 0
			}			
			if ${mcnum`modn'$sfx} == 1 & `catinp' != 1 & "${misfv`modn'$sfx}" != "y" {
				qui summ ${mvar`modn'c1$sfx} if esamp$sfx  ${sumwgt$sfx}
				loc inc = (`r(max)' - `r(min)' )/`nrange'
				numlist "`r(min)'(`inc')`r(max)'"
				glo mvrange`modn'$sfx  "`r(numlist)'"
				glob mvdigit`modn'$sfx = `ndigits'
			}		
			glo mvldisp`modn'$sfx "${mvname`modn'c1$sfx}"
		}
		if "`vvar'"=="${fvlist$sfx}" {
			glo fisfv$sfx "`isfv'"
			glo fviscat$sfx "n"
			glo fcnum$sfx = `vvnum'
			if ${fcnum$sfx} > 1  | `catinp' == 1 | "${fisfv$sfx}" == "y" { 
				numlist "0/${fcnum$sfx}"
				glo fvrange$sfx  "`r(numlist)'"
				glob fvdigit$sfx = 0
			}	
			glo fvldisp$sfx  "${fvnamec1$sfx}"
			forvalues j=1/`vvnum' {
				loc vnm: word `j' of `vvar'
				glo fvarc`j'$sfx "`vnm'" 
				proprstr "`vnm'" `abbrevn' "`pad'"
				glo fvnamec`j'$sfx = "`r(padded)'" 
			}			
			if ${fcnum$sfx} == 1 & `catinp' != 1 & "${fisfv$sfx}" != "y" { 
				qui summ ${fvarc1$sfx} if esamp$sfx  ${sumwgt$sfx}
				loc inc = (`r(max)' - `r(min)' )/`nrange'
				numlist "`r(min)'(`inc')`r(max)'"
				glo fvrange$sfx "`r(numlist)'"
				glob fvdigit$sfx = `ndigits'				
			}	
		}	
	}
}

glo mvarn$sfx = `modn'

*** Get coefficients for model
mat `bb'=e(b)

***  	Set mvlist display name to generic if not specified from user input
***		Assign min, max, mean & sd for each moderator to global macro
***		Set mvrange to default  if not specified from user input
***		Assign coefficients for mvar#c# to global macros
forvalues i=1/`modn' {
	if "${mvldisp`i'$sfx}" == "" glo mvldisp`i'$sfx "${mvname`i'c1$sfx}"
	qui summ ${mvar`i'c1$sfx} if esamp$sfx  ${sumwgt$sfx}
	foreach snm in min max mean sd {
		glo m`snm'`i'$sfx = r(`snm')
	}
	if ${mcnum`i'$sfx} > 1 { 
		numlist "0/${mcnum`i'$sfx}"
		glo mvrange`i'$sfx  "`r(numlist)'"
		glob mvdigit`i'$sfx = 0
	}
	if ${mcnum`i'$sfx} == 1  & "${mvrange`i'$sfx}" == "" {
		loc inc = (${mmax`i'$sfx} - ${mmin`i'$sfx} )/`nrange'
		numlist "${mmin`i'$sfx}(`inc')${mmax`i'$sfx}"
		glo mvrange`i'$sfx  "`r(numlist)'"
		glob mvdigit`i'$sfx = `ndigits'		
	}	
	forvalues j=1/${mcnum`i'$sfx} {
		getb, mat(`bb') vn(${mvar`i'c`j'$sfx}) num(y) eqn(${eqname$sfx})
		glo bmvar`i'c`j'$sfx=`r(b1ext)'
	}
	if "${misfv`i'$sfx}"=="y" glo bmvar`i'c0$sfx=0
}

***  	Set fvlist display name to variable name if not specified from user input
***		Set fvrange to default  if not specified from user input
***		Assign coefficients for fvarc# to global macros
if "${fvldisp$sfx}" == "" glo fvldisp$sfx  "${fvnamec1$sfx}"
	qui summ ${fvarc1$sfx} if esamp$sfx  ${sumwgt$sfx}
	foreach snm in min max mean sd {
		glo f`snm'$sfx = r(`snm')
	}
if ${fcnum$sfx} > 1 { 
	numlist "0/${fcnum$sfx}"
	glo fvrange$sfx  "`r(numlist)'"
	glob fvdigit$sfx = 0
}
if ${fcnum$sfx} == 1 & "${fvrange$sfx}" == "" { 
	loc inc = (${fmax$sfx} - ${fmin$sfx} )/`nrange'
	numlist "${fmin$sfx}(`inc')${fmax$sfx}"
	glo fvrange$sfx  "`r(numlist)'"
	glob fvdigit$sfx = `ndigits'
}
forvalues j=1/${fcnum$sfx} {
	getb, mat(`bb') vn(${fvarc`j'$sfx}) num(y) eqn(${eqname$sfx})
	glo bfvarc`j'$sfx=`r(b1ext)'
}
if "${fisfv$sfx}"=="y" glo bfvarc0$sfx=0
***		Assign value labels corresponding to range to global F/MVALLAB#
forvalues mi=1/${mvarn$sfx}{
	loc vlabs ""
	if ${mcnum`mi'$sfx} > 1 glo mviscat`mi'$sfx "y"
	loc nv: list sizeof global(mvrange`mi'$sfx)
	loc nv2= `nv'
	if ${mcnum`mi'$sfx} == 1 & "${misfv`mi'$sfx}" == "y" loc nv2 = 2
	forvalues nvi=1/`nv' {
		if ${mcnum`mi'$sfx} == 1 & "${misfv`mi'$sfx}" != "y" {
			loc vv: word `nvi' of ${mvrange`mi'$sfx}
			getvallab "${mvar`mi'c1$sfx}" `vv'
			loc vl "`r(vlab)'"
			if "`vl'" == "" loc vl = strofreal(`vv',"%10.${mvdigit`mi'$sfx}f")
			glo mvlabm`mi'c`nvi'$sfx= abbrev(subinstr("`vl'"," ","_",.),10)
			**** loc vlabs "`vlabs'`vl' "
		}
		if ${mcnum`mi'$sfx} > 1 | "${misfv`mi'$sfx}" == "y" {
			loc vv: word `nvi' of ${mvrange`mi'$sfx}
			if "${misfv`mi'$sfx}" == "y" 	{
				if `vv'==0 {
					tokenize  ${mvar`mi'c1$sfx}	, parse(".")
					fvexpand(i.`3')
					loc fvlst "`r(varlist)'"
					loc vvb ""
					forvalues fvi=1/`nv2' {
						loc ff: word `fvi' of `fvlst'
						tokenize `ff', parse(".")
						loc fval=strpos("`1'","b")
						if `fval' != 0 loc vvb=substr("`1'",1,`=`fval'-1')
					}
					getvallab `3' `vvb'
					loc vl "`r(vlab)'"
					if "`vl'" == "" loc vl = "Base"
					glo mvlabm`mi'c`nvi'$sfx= abbrev(subinstr("`vl'"," ","_",.),10)
					**** loc vlabs "`vlabs'`vl' "
				}
				if `vv' > 0 {
					if ${mcnum`mi'$sfx} > 1 | (${mcnum`mi'$sfx} == 1 & `vv' == 1 ) {
						tokenize  ${mvar`mi'c`vv'$sfx} , parse(".")
						getvallab `3' `1'
						loc vl "`r(vlab)'"
						if "`vl'" == "" loc vl = "${mvar`mi'c`vv'$sfx}"
						glo mvlabm`mi'c`nvi'$sfx = abbrev(subinstr("`vl'"," ","_",.),10)
						**** loc vlabs "`vlabs'`vl' "
					}
				}
			}
			if "${misfv`mi'$sfx}" != "y" 	{
				if `nvi' != 1 {
					getvallab "${mvar`mi'c`=`nvi'-1'$sfx}" 1
					loc vl "`r(vlab)'"
					if "`vl'" == "" loc vl = "${mvar`mi'c`=`nvi'-1'$sfx}"
				}
				if `nvi' == 1  loc vl "Base"
				glo mvlabm`mi'c`nvi'$sfx= abbrev(subinstr("`vl'"," ","_",.),10)
			}		
		}
	}
}
***		Repeat process for focal var
if ${fcnum$sfx} > 1 glo fviscat$sfx "y"
loc vlabs ""
loc nv: list sizeof global(fvrange$sfx)
loc nv2= `nv'
if ${fcnum$sfx} == 1 & "${fisfv$sfx}" == "y" loc nv2 = 2
forvalues nvi=1/`nv' {
	if ${fcnum$sfx} == 1 & "${fisfv$sfx}" != "y" {
		loc vv: word `nvi' of ${fvrange$sfx}
		getvallab "${fvarc1$sfx}" `vv'
		loc vl "`r(vlab)'"
		if "`vl'" == "" loc vl = strofreal(`vv',"%10.${fvdigit$sfx}f")
		glo fvlabc`nvi'$sfx = abbrev(subinstr("`vl'"," ","_",.),10)
	}
	if ${fcnum$sfx} > 1 | "${fisfv$sfx}" == "y" {
		loc vv: word `nvi' of ${fvrange$sfx}
		if "${fisfv$sfx}" == "y" 	{
			if `vv'==0 {
				tokenize  ${fvarc1$sfx}	, parse(".")
				fvexpand(i.`3')
				loc fvlst "`r(varlist)'"
				loc vvb ""
				forvalues fvi=1/`nv2' {
					loc ff: word `fvi' of `fvlst'
					tokenize `ff', parse(".")
					loc fval=strpos("`1'","b")
					if `fval' != 0 loc vvb=substr("`1'",1,`=`fval'-1')
				}
				getvallab `3' `vvb'
				loc vl "`r(vlab)'"
				if "`vl'" == "" loc vl = "Base"
				glo fvlabc`nvi'$sfx = abbrev(subinstr("`vl'"," ","_",.),10)
			}
			if `vv' > 0 {
				if ${fcnum$sfx} > 1 | (${fcnum$sfx} == 1 & `vv' == 1 ) {
					tokenize  ${fvarc`vv'$sfx} , parse(".")
					getvallab `3' `1'
					loc vl "`r(vlab)'"
					if "`vl'" == "" loc vl = "${fvarc`vv'$sfx}"
					glo fvlabc`nvi'$sfx = abbrev(subinstr("`vl'"," ","_",.),10)
				}
			}
		}
		if "${fisfv$sfx}" != "y" 	{
			if `nvi' != 1 {
				getvallab "${fvarc`=`nvi'-1'$sfx}" 1
				loc vl "`r(vlab)'"
				if "`vl'" == "" loc vl = "${fvarc`vv'$sfx}"
			}
			if `nvi' == 1  loc vl "Base"	
			glo fvlabc`nvi'$sfx = abbrev(subinstr("`vl'"," ","_",.),10)
		}		
	}
}
***
****		Process 2way terms
stripfv "`int2'" 
loc focmod "`r(strip)'"
loc mii=0
glo fmlist$sfx ""
forvalues mi=1/${mvarn$sfx} {
glo fm`mi'list$sfx ""
	forvalues i=1/${fcnum$sfx} {
		forvalues j=1/${mcnum`mi'$sfx} {
			loc ++mii 
			loc vv: word `mii' of `focmod'
			glo f`i'm`mi'c`j'$sfx "`vv'"
			glo fm`mi'list$sfx "${fm`mi'list$sfx} ${f`i'm`mi'c`j'$sfx}"
***	Assign coefficient to global macro
			getb, mat(`bb') vn(${f`i'm`mi'c`j'$sfx}) num(y) eqn(${eqname$sfx})
			glo bf`i'm`mi'c`j'$sfx =`r(b1ext)'
		}
	}
	glo fmlist$sfx "${fmlist$sfx} ${fm`mi'list$sfx}"
}

***		Process 3way term(s) and 2way M1*M2
***
glo int3way$sfx "n"

if "`int3'" != "" {

***		M1*M2 globals  Note:  counter MII and 2way list FOCMOD carried over
***
glo int3way$sfx "y"
glo m1m2list$sfx ""
	forvalues i=1/${mcnum1$sfx} {
		forvalues j=1/${mcnum2$sfx} {
			loc ++mii 
			loc vv: word `mii' of `focmod'
			glo m1c`i'm2c`j'$sfx "`vv'"
			glo m1m2list$sfx "${m1m2list$sfx} ${m1c`i'm2c`j'$sfx}"
***	Assign coefficient to global macro
			getb, mat(`bb') vn(${m1c`i'm2c`j'$sfx}) num(y) eqn(${eqname$sfx})
			glo bm1c`i'm2c`j'$sfx =`r(b1ext)'		
		}
	}

***		Define 3 way globals
***
	stripfv "`int3'" 
	loc focmod "`r(strip)'"
	glo fm1m2list$sfx ""
	loc mii=0
	forvalues i=1/${fcnum$sfx} {
		forvalues mi1=1/${mcnum1$sfx} {
			forvalues mi2=1/${mcnum2$sfx} {
				loc ++mii 
				loc vv: word `mii' of `focmod'
				glo f`i'm1c`mi1'm2c`mi2'$sfx "`vv'"
				glo f`i'm2c`mi2'm1c`mi1'$sfx "`vv'"
				glo fm1m2list$sfx "${fm1m2list$sfx} ${f`i'm1c`mi1'm2c`mi2'$sfx}"
				glo fm212list$sfx "${fm2m1list$sfx} ${f`i'm2c`mi2'm1c`mi1'$sfx}"
***	Assign coefficient to global macro
				getb, mat(`bb') vn(${f`i'm1c`mi1'm2c`mi2'$sfx}) num(y) eqn(${eqname$sfx})
				glo bf`i'm1c`mi1'm2c`mi2'$sfx =`r(b1ext)'
				glo bf`i'm2c`mi2'm1c`mi1'$sfx =`r(b1ext)'
			}
		}
	}
}
loc dvn "`e(depvar)'"
if "`dvname'" != "" loc dvn "`dvname'"
proprstr "`dvn'" `abbrevn' "`pad'"
loc dvn = "`r(padded)'"
glo dvname$sfx "`dvn'" 

if "`cmdnm'" == "mlogit" {
	loc dvcat: word `eqnow' of ${eqlist$sfx2} 
	glo dvname$sfx "`dvn'[`dvcat':${eqbase$sfx2}]"
	if ${eqnum$sfx2}  == 1 {
		loc base "`e(baselab)'"
		if "`e(baselab)'" == "" loc base "`e(k_eq_base)'"
			glo dvname$sfx "`dvn'[`eqname':`base']"
	}
}

*** Report back basic interaction model specifications
if `eqnow' == 1 {
noi disp _newline as txt "{ul:Interaction Effects on `dvn' Specified as}" _newline
loc mt "${fvlist$sfx} "
forvalues i=1/${mvarn$sfx} {
	loc mt "`mt' ${mvlist`i'$sfx}" 
}
*
noi disp "     Main effect terms: {res:`mt' }"
noi disp "     Two-way interaction terms: {res:`int2' }"
if "`int3'" != "" 	noi disp "     Three-way interaction terms: {res:`int3'} "
noi disp _newline `"  These will be treated as: Focal variable = {res:${fvlist$sfx} ("${fvldisp$sfx}")}"' _newline "    moderated by interaction(s) with"
forvalues i=1/${mvarn$sfx} {
	noi disp `"        {res:${mvlist`i'$sfx} ("${mvldisp`i'$sfx}")}"'
}
if "`int3'" != "" 	noi disp `"     and with {res:"${mvldisp1$sfx}" x "${mvldisp2$sfx}"} "'
}
}
end

