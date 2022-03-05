*!  frqfocmod1.ado	 Version 1.0		RL Kaufman 	09/28/2016

***  	1.0 Calculate relative freq distn for Focal by M1, either total or within subgroups defined by M1  Return results in matrix FRQMAT
***			MODS option  not currently functional.  Would allow for subgroup %distribution defined by M2 x M3 x ... .

program frqfocmod1, rclass
version 14.2
syntax ,  freq(string) 
tempname bb  basev base2v frqmat colval
tempvar  m1cat m1base bym1var


** Create list of non-factor-var dummies for Focal to get FREQ matrix for Focal using tabstat
if "${fviscat$sfx}" == "y" | "${fisfv$sfx}" == "y" {
	loc vlist "`basev'0"
	loc basegen "gen `basev'0 = 1 "
	forvalues j=1/${fcnum$sfx} {
		loc vn: word `j' of ${fvlist$sfx}
		if "${fisfv$sfx}" == "y" { 
			gen `basev'`j' = `vn'
			loc basegen "`basegen' - `basev'`j'"
			loc vlist "`vlist' `basev'`j'"	
		}
		if "${fisfv$sfx}" != "y" { 
			loc basegen "`basegen' - `vn'"
			loc vlist "`vlist' `vn'"
		}
	}
	
	`basegen'
}

*Build cut list to categorize interval Focal var using fvrange newval = dispval +/- .5*(display value gap)
if "${fviscat$sfx}" != "y" & "${fisfv$sfx}" != "y" {
loc vlist ""
	loc nr: list sizeof global(fvrange$sfx)
	loc cut1 = ${fmin$sfx}-.05*abs(${fmin$sfx}+.1)
	
	forvalues ri = 1/`nr' {
		loc val: word `ri' of ${fvrange$sfx}
		if `ri' != `nr' loc valnxt: word `=`ri'+1' of ${fvrange$sfx}
		loc cut2 = `val' + .5*(`valnxt' - `val')
		if `ri' < `nr' gen `basev'`ri' = inrange(${fvlist$sfx},`cut1',`cut2')
		if `ri' == `nr' gen `basev'`ri' = ${fvlist$sfx} > `cut1' & ${fvlist$sfx} < .
		loc vlist "`vlist' `basev'`ri'"
		loc cut1 = `cut2' +.000001
	}
}
***	Set up colval and labels for FRQMAT
loc nc: list sizeof global(fvrange$sfx)
mat `colval' = J(1,`nc',.)
loc cn ""

forvalues j=1/`nc' {
	loc cv: word `j' of  ${fvrange$sfx}
	mat `colval'[1,`j']= `cv'
	loc cn "`cn' ${fvlabc`j'$sfx}"
}
loc nr = 1
loc rn ""
loc nr : list sizeof global(mvrange1$sfx)

forvalues i=1/`nr' {	
		loc rn "`rn' m1cat`i'"
	}

loc rn "`rn' focalcat"
mat `frqmat' = J(`=`nr'+1',`nc',.)

loc  matr ""
	if "${mviscat1$sfx}" == "y"  | "${misfv1$sfx}" == "y" {
		loc gentxt "${mvar1c1$sfx}"
		if ${mcnum1$sfx} > 1 {
			forvalues j=2/${mcnum1$sfx} {
				loc gentxt "`gentxt' + `j'*${mvar1c`j'$sfx}"
			}
		}
	}
	if "${mviscat1$sfx}" != "y" & "${misfv1$sfx}" != "y" {
		loc gentxt "0"
		loc nr: list sizeof global(mvrange1$sfx)
		loc cut1 = ${mmin1$sfx}-.05*(abs(${mmin1$sfx})+.1)
		
		forvalues ri = 1/`nr' {
			loc val: word `ri' of ${mvrange1$sfx}
			if `ri' != `nr' loc valnxt: word `=`ri'+1' of ${mvrange1$sfx}
			loc cut2 = `val' + .5*(`valnxt' - `val')
			if `ri' < `nr' gen `base2v'`ri' = inrange(${mvar1c1$sfx},`cut1',`cut2')
			if `ri' == `nr' gen `base2v'`ri' = ${mvar1c1$sfx} > `cut1' & ${mvar1c1$sfx} < .
			loc gentxt "`gentxt' + `ri'*`base2v'`ri'"
			loc cut1 = `cut2' + .000001
		}
	}
	forvalues i=1/`nr' {
		loc  matr "`matr' r(Stat`i') \ "
	}
	gen `bym1var' = `gentxt' if ${mvar1c1$sfx} < .
	tabstat `vlist' if esamp$sfx  ${sumwgt$sfx} , st(sum) save by(`bym1var') not

	
*loc  matr "`matr' "
mat `frqmat' = [`matr' `colval']
mat colnames `frqmat' = `cn'
mat rownames `frqmat' = `rn'
return mat frqmat = `frqmat'

end
