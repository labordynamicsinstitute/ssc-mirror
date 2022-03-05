*!  frqmod.ado	 Version 2.0		RL Kaufman 	09/29/2016

***  	1.0 Calculate relative freq distn for M1, either total or for subgroups defined by M2  Return results in matrix FRQMAT
***			MODS option  not currently functional.  Would allow for subgroup %distribution defined by M2 x M3 x ... . 
***			Called by EFFDISP.ADO
***
***		2.0	Added e(sample) selection and weighting option to calculate freq distn


program frqmod, rclass
version 14.2
syntax , mod1(string) [ mods(numlist integer) freq(string) ]
tempname bb  basev base2v frqmat colval
tempvar  m1cat m1base bym2var

qui{ 
** Create list of non-factor-var dummies for M1 to get FREQ matrix for M1 using tabstat
if "${mviscat1$sfx}" == "y" {
	loc vlist "`basev'0"
	loc basegen "gen `basev'0 = 1 "
	forvalues j=1/${mcnum1$sfx} {
		loc vn: word `j' of `mod1'
		if "${misfv1$sfx}" == "y" { 
			gen `basev'`j' = `vn'
			loc basegen "`basegen' - `basev'`j'"
			loc vlist "`vlist' `basev'`j'"	
		}
		if "${misfv1$sfx}" != "y" { 
			loc basegen "`basegen' - `vn'"
			loc vlist "`vlist' `vn'"
		}
	}
	`basegen'
}

*Build cut list to categorize interval var using mvrange newval = dispval +/- .5*(display value gap)
if "${mviscat1$sfx}" != "y" {
loc vlist ""
	loc nr: list sizeof global(mvrange1$sfx)
	loc cut1 = ${mmin1$sfx}-.05*abs(${mmin1$sfx}+.1)
	forvalues ri = 1/`nr' {
		loc val: word `ri' of ${mvrange1$sfx}
		if `ri' != `nr' loc valnxt: word `=`ri'+1' of ${mvrange1$sfx}
		loc cut2 = `val' + .5*(`valnxt' - `val')
		if `ri' < `nr' gen `basev'`ri' = inrange(`mod1',`cut1',`cut2')
		if `ri' == `nr' gen `basev'`ri' = `mod1' > `cut1' & `mod1' < .
		loc vlist "`vlist' `basev'`ri'"
		loc cut1 = `cut2' +.000001
	}
}
***	Set up colval and labels for FRQMAT
loc nc: list sizeof global(mvrange1$sfx)
mat `colval' = J(1,`nc',.)
loc cn ""
forvalues j=1/`nc' {
	loc cv: word `j' of  ${mvrange1$sfx}
	mat `colval'[1,`j']= `cv'
	loc cn "`cn' ${mvlabm1c`j'$sfx}"
}
loc nr = 1
loc rn "TotSum"
if ${mvarn$sfx} > 1 &  ("`freq'" == "sub" | "`freq'" == "subtot" ) {
	loc rn ""
	loc nr : list sizeof global(mvrange2$sfx)
	forvalues i=1/`nr' {
		
		loc rn "`rn' m2cat`i'"
*		loc rn "`rn' `=strtoname("m2cat${mvlabm2c`i'$sfx}")'"
	}
}
loc rn "`rn' m1cat"
mat `frqmat' = J(`=`nr'+1',`nc',.)
loc  matr "r(StatTotal) \ "

if ${mvarn$sfx} == 1 |  "`freq'" == "tot"  {
	tabstat `vlist'  if esamp$sfx  ${sumwgt$sfx} , st(sum) save
}
*
** if #MODS > 1 Create BY var for M2 to get FREQ matrix for M1 using tabstat if FREQ=sub  specified
if ${mvarn$sfx} > 1 & ("`freq'" == "sub" | "`freq'" == "subtot" ) {
loc  matr ""
	if "${mviscat2$sfx}" == "y" {
		loc gentxt "${mvar2c1$sfx}"
		if ${mcnum2$sfx} > 1 {
			forvalues j=2/${mcnum2$sfx} {
				loc gentxt "`gentxt' + `j'*${mvar2c`j'$sfx}"
			}
		}
	}
	if "${mviscat2$sfx}" != "y" {
		loc gentxt "0"
		loc nr: list sizeof global(mvrange2$sfx)
		loc cut1 = ${mmin2$sfx}-.05*(abs(${mmin2$sfx})+.1)
		forvalues ri = 1/`nr' {
			loc val: word `ri' of ${mvrange2$sfx}
			if `ri' != `nr' loc valnxt: word `=`ri'+1' of ${mvrange2$sfx}
			loc cut2 = `val' + .5*(`valnxt' - `val')
			if `ri' < `nr' gen `base2v'`ri' = inrange(${mvar2c1$sfx},`cut1',`cut2')
			if `ri' == `nr' gen `base2v'`ri' = ${mvar2c1$sfx} > `cut1' & ${mvar2c1$sfx} < .
			loc gentxt "`gentxt' + `ri'*`base2v'`ri'"
			loc cut1 = `cut2' + .000001
		}
	}
	forvalues i=1/`nr' {
		loc  matr "`matr' r(Stat`i') \ "
	}
	gen `bym2var' = `gentxt'
	tabstat `vlist'  if esamp$sfx  ${sumwgt$sfx} , st(sum) save by(`bym2var') not
}
loc  matr "`matr' "
mat `frqmat' = [`matr' `colval']
mat colnames `frqmat' = `cn'
mat rownames `frqmat' = `rn'
return mat frqmat = `frqmat'
}
end
