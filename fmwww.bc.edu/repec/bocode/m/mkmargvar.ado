*!  mkmargvar.ado 	Version 2.1		RL Kaufman 	03/06/2018

***		1.0 Make variables from margins results for creating tables and graphs
***		2.0	Fixed non-integer value label problem
***		2.1 fixed problem with user-defined interaction terms

program mkmargvar, rclass
version 14.2
args  main plttype predy1 fvar mvar1 scatrev mvar2 mvar3 mvar4 
tempname h1 h2 vardat  

loc imn ""
if "`main'" == "main" loc imn "mn"
mat `h1' = e(at)
mat keeph1 = e(at)
mat keepb = e(b)

capture: lab drop fv$sfx 
capture: lab drop mv1$sfx 
capture: lab drop mv2$sfx
capture: lab drop mv3$sfx
capture: lab drop mv4$sfx
capture: drop `predy1'
capture: drop `fvar'
capture: drop `mvar1' 
capture: drop `mvar2'
capture: drop `mvar3' 
capture: drop `mvar4'

***  set xv and plv (predction line = pl)  other attributes BUT NNIT VAR NAMES then reverse if scatrev==y

loc xvrange "fvrange"
loc xvlab "fvlab"
loc xvldisp "fvldisp"
loc plvrange "mvrange1"
loc plvlab "mvlabm1"
loc plvldisp "mvldisp1"
if "`scatrev'" == "y" {
	loc xvrange "mvrange1"
	loc xvlab "mvlabm1"
	loc xvldisp "mvldisp1"
*	loc plvarnm "`fvar'"
	loc plvlab "fvlab"
	loc plvldisp "fvldisp"
}


loc cn "`predy1'"
loc nkp = 1+${mvarn$sfx}
loc nf: list sizeof global(fvlist$sfx)
if  "${fisfv$sfx}"=="y" | "${fviscat$sfx}"=="y" {
	loc nkp = `nkp' + `nf'
	if "${fisfv$sfx}"!="y" loc nkp = `nkp' - 1
}
loc genfvar "gen `fvar' = 0 "
loc fvallab "lab def fv$sfx "
loc flabalt "lab def fv$sfx "
loc genfvaralt "recode `vardat'${fvlist$sfx}`imn' "
loc useflabalt ""
loc frevcode ""
loc usefrevcode ""
if `nf' > 1 | "${fisfv$sfx}" == "y" | "${fviscat$sfx}" == "y" loc fvallab `"`fvallab' 0 "Base" "'

if "${fisfv$sfx}" != "y" { 
	if `nf' > 1 {
	
		forvalues fi=1/`nf' {
			loc vn: word `fi' of ${fvlist$sfx}
			loc cn "`cn' `vardat'`vn'`imn'"
			loc genfvar "`genfvar' + `fi'*`vardat'`vn'`imn' "
			loc fvallab = `"`fvallab' `fi' "${fvlabc`=`fi'+1'$sfx}" "' 
		}
	}
	if `nf' == 1 {
		loc cn "`cn' ${fvlist$sfx}`imn'"
		loc genfvar "`genfvar' + `vardat'${fvlist$sfx}`imn' "
		loc nr: list sizeof global(fvrange$sfx)
		
		forvalues fi=1/`nr' {
			loc fval: word `fi' of ${fvrange$sfx}
			loc fvallab = `"`fvallab' `fval' "${fvlabc`fi'$sfx}" "' 
			if mod(`fval',int(`fval')) !=0 loc useflabalt "true"
			loc flabalt = `"`flabalt' `fi' "${fvlabc`fi'$sfx}" "' 
			loc genfvaralt "`genfvaralt' (`fval' = `fi' )"
			loc frevcode "`frevcode'  (`fi' = `fval' )"
		}
		if "`useflabalt'" == "true" & ("`plttype'" == "bar" | "`plttype'" == "notplot" ) { 
			loc fvallab `"`flabalt'"'
			loc genfvar "`genfvaralt' , gen(`fvar')"
			loc usefrevcode "true"
		}
	}			
}
if "${fisfv$sfx}" == "y" { 
	getfvname  ${fvlist$sfx}
	loc focname "`r(vname)'"
	getfvbase i.`focname'
	loc bnum = r(fvbase)
	levelsof `focname'
	loc flev "`r(levels)'"
	loc genfvar "gen `fvar' = `bnum' "

	forvalues fi=1/`=`nf'+1' {
		loc fval: word `fi' of `flev'
		if `fval' != `bnum' { 
			loc cn "`cn' `focname'`fval'`imn'"
			loc genfvar "`genfvar' + (`fval'-`bnum')*`vardat'`focname'`fval'`imn' "	
		}
		loc fvallab = `"`fvallab' `fval' "${fvlabc`fi'$sfx}" "' 		
	}
}
loc colext ""
foreach nm in ${fvlist$sfx} {
	loc colext `"`colext' , `h1'[.,"`nm'"] "'
}

loc mstp=${mvarn$sfx}

forvalues mi=1/`mstp' {
	loc nm: list sizeof global(mvlist`mi'$sfx)
	if  "${misfv`mi'$sfx}"=="y" | "${mviscat`mi'$sfx}"=="y" {
		loc nkp = `nkp' + `nm'
		if "${misfv`mi'$sfx}"!="y" loc nkp = `nkp' - 1
	}
	loc genmvar`mi' "gen `mvar`mi'' = 0 "	
	loc m`mi'vallab "lab def mv`mi'$sfx"
	loc mlabalt "lab def mv`mi'$sfx"
	loc usemlabalt ""
	loc genmvaralt "recode `vardat'${mvlist`mi'$sfx}`imn' "
	loc m`mi'revcode ""
	loc usem`mi'revcode ""
	if `nm' > 1 | "${misfv`mi'$sfx}" == "y" | "${mviscat`mi'$sfx}" == "y" loc m`mi'vallab `"`m`mi'vallab' 0 "Base" "'
	if "${misfv`mi'$sfx}" != "y" { 
		if `nm' >1 {
			forvalues mmi=1/`nm' {
				loc vn: word `mmi' of ${mvlist`mi'$sfx}
				loc cn "`cn' `vn'`imn'"
				loc genmvar`mi' "`genmvar`mi'' + `mmi'*`vardat'`vn'`imn' "
				loc m`mi'vallab = `"`m`mi'vallab' `mmi' "${mvlabm`mi'c`=`mmi'+1'$sfx}" "' 		
			}
		}
		if `nm' == 1 {
			loc cn "`cn' ${mvlist`mi'$sfx}`imn'"
			loc genmvar`mi' "`genmvar`mi'' + `vardat'${mvlist`mi'$sfx}`imn' "
			loc nr: list sizeof global(mvrange`mi'$sfx)
			forvalues mmi=1/`nr' {
				loc mval: word `mmi' of ${mvrange`mi'$sfx}
				loc m`mi'vallab = `"`m`mi'vallab' `mval' "${mvlabm`mi'c`mmi'$sfx}" "' 
				if mod(`mval',int(`mval')) !=0 loc usemlabalt "true"
				loc mlabalt = `"`mlabalt' `mmi' "${mvlabm`mi'c`mmi'$sfx}" "' 
				loc genmvaralt "`genmvaralt' (`mval' = `mmi' )"
				/*if `mi' == 1*/ loc m`mi'revcode "`m`mi'revcode'  (`mmi' = `mval' )"
			}
			if "`usemlabalt'" == "true" & ("`plttype'" != "contour" | `mi' != 1  ) & ("`scatrev'" == "n" | ("`scatrev'" == "y" & `mi' !=1)) { 
				loc m`mi'vallab `"`mlabalt'"'
				loc genmvar`mi' "`genmvaralt' , gen(`mvar`mi'')"
				loc usem`mi'revcode "true"
			}
		}			
	}
	if "${misfv`mi'$sfx}" == "y" { 
		getfvname  ${mvlist`mi'$sfx}
		loc modname "`r(vname)'"
		getfvbase i.`modname'
		loc bnum = r(fvbase)
		loc genmvar`mi' "gen `mvar`mi'' = `bnum' "	
		levelsof `modname'
		loc mlev "`r(levels)'"
		forvalues mmi=1/`=`nm'+1' {
			loc mval: word `mmi' of `mlev'
			if `mval' != `bnum' { 
				loc cn "`cn' `modname'`mval'`imn'"
				loc genmvar`mi' "`genmvar`mi'' + `=`mval'-`bnum''*`vardat'`modname'`mval'`imn' "
			}
			loc m`mi'vallab = `"`m`mi'vallab' `mval' "${mvlabm`mi'c`mmi'$sfx}" "' 		
		}
	}
	foreach nm in ${mvlist`mi'$sfx} {
		loc colext `"`colext' , `h1'[.,"`nm'"] "'
	}
}
*
mat `vardat' = [ e(b)' `colext']

mat colnames `vardat' = `cn'
svmat `vardat', names(matcol)
loc cstp =1
if "${fisfv$sfx}" != "y"  & `nf' > 1 { 
	loc cstp = 1 + `nf' 
	forvalues cc=2/`cstp' {
	loc cnm: word `cc' of `cn'
	ren `vardat'`cnm' `cnm'
}
} 
ren `vardat'`predy1' `predy1'
qui `genfvar'
lab var `fvar' "${fvldisp$sfx}"

if "`plttype'" == "bar" | "`plttype'" == "notplot" {
	`fvallab'
	lab val `fvar' fv$sfx
}

if "`usefrevcode'" == "true" return loc frevcode = "`frevcode'"

forvalues mi=1/`mstp' {
	qui `genmvar`mi'' 
	lab var `mvar`mi'' "${mvldisp`mi'$sfx}"
	if "`plttype'" != "contour" | `mi' != 1 {
		`m`mi'vallab'
		lab val `mvar`mi'' mv`mi'$sfx
	}
	if "`usem`mi'revcode'" == "true" return loc m`mi'revcode = "`m`mi'revcode'"
}
end
