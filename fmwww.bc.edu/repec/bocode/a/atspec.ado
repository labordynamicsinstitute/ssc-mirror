*!  atspec.ado 	Version 3.0		RL Kaufman 	7/11/2018

***  	1.0   Build at specification for margins.  PLTTYPE & INT3WAY set by user.  MODEL = INT or MAIN, MAIN used only to supeimpose main effects plot.
***
***		2.0	  Create separate handling for all interval variables, did not work aas part of factor var handling
***
***		3.0		Fix handling if F or M1 or (M2&3way) is categorical

program atspec, rclass
version 14.2
syntax , outmetric(string) plttype(string) model(string) int3way(string) outatopt(string) scatrev(string)

qui {   
loc atmodset ""
loc vtype "interval"
fvexpand(${fm1list$sfx})
if "`r(fvops)'" == "true" loc vtype "fv"
if ${mvarn$sfx} >1  {
	fvexpand(${fm2list$sfx})
	if "`r(fvops)'" == "true" loc vtype "fv"
}
if  "${fisfv$sfx}"!="y" & "${fiscat$sfx}"=="y" |  "${misfv1$sfx}"!="y" & "${mviscat1$sfx}"=="y" | ///
	( ${mvarn$sfx} >1 & "${misfv2$sfx}"!="y" & "${mviscat2$sfx}"=="y" ) {
	loc vtype= "cat"
}
***  F, M1 & M2 Factor vars or factor + interval vars *****************************************************************************************************

if   "`vtype'" == "fv"  {

*** FOCAL
	if  "${fisfv$sfx}"=="y" {
		getfvname  ${fvlist$sfx}
		loc focname "`r(vname)'"
		levelsof `focname'
		loc atfocal "`focname' = (`r(levels)')"
		loc atfocaltab "`atfocal'"
	}
	if  "${fisfv$sfx}"!="y"  loc atfocal "${fvarc1$sfx} = (${fvrange$sfx})"
	if  "${fisfv$sfx}"!="y" & ("`plttype'" == "contour" | ( "`plttype'" == "scat" & "`scatrev'" !="y" )) {
		loc atfocaltab "`atfocal'"
		loc atfocal "${fvarc1$sfx} = (${fmin$sfx}(`=(${fmax$sfx}-${fmin$sfx})/25')${fmax$sfx})"
	}
***  MOD1
	if  "${misfv1$sfx}"=="y" {
		getfvname ${mvlist1$sfx}
		loc mod1name "`r(vname)'"
		levelsof `mod1name'
		loc atmod1 "`mod1name' = (`r(levels)')"
		loc atmod1tab "`atmod1'"	
	}
	if  "${misfv1$sfx}"!="y" {	
		loc atmod1 "${mvar1c1$sfx} = (${mvrange1$sfx})"
		if   ("`plttype'" == "contour" | "`plttype'" == "scat")  loc atmod1tab "`atmod1'"	
		if   "`plttype'" == "contour" | ( "`plttype'" == "scat" & "`scatrev'" == "y" ) ///
			loc atmod1 "${mvar1c1$sfx} = (${mmin1$sfx}(`=(${mmax1$sfx}-${mmin1$sfx})/25')${mmax1$sfx})"
	}
***  MOD2 if 3way interaction
	if "`int3way'" == "y" {
		if  "${misfv2$sfx}"=="y" {
				getfvname ${mvlist2$sfx}
			loc mod2name "`r(vname)'"
			 levelsof `mod2name'
			loc atmodset "`mod2name' = (`r(levels)')"
		}
		if  "${misfv2$sfx}"!="y"   loc atmodset "${mvar2c1$sfx} = (${mvrange2$sfx})"
	
	}
***  OTHER MODS
	if ${mvarn$sfx} > 1 {
		loc mstp = ${mvarn$sfx} 
		
		forvalues mi=2/`mstp' {
			if "`int3way'" != "y" | `mi' != 2 {
				if  "${misfv`mi'$sfx}"=="y" {
					getfvname ${mvlist`mi'$sfx}
					loc mod`mi'name "`r(vname)'"
					 levelsof `mod`mi'name'
					loc atmodset "`atmodset' `mod`mi'name' = (`r(levels)')"
				}
			if  "${misfv`mi'$sfx}"!="y"  loc atmodset "`atmodset' ${mvar`mi'c1$sfx} = (${mvrange`mi'$sfx})"
			}
		}
	}
	loc atinfo " at( `outatopt' `atfocal' `atmod1' `atmodset' ) "
	return loc atinfo "`atinfo'"
	if "`plttype'" == "contour" | "`plttype'" == "scat" {
		loc atinfotab " at( `outatopt' `atfocaltab' `atmod1tab' `atmodset' ) "
		return loc atinfotab "`atinfotab'"	
	}
}
****  No factor vars and at least 1 cat var among F, M1, M2 *********************************************************************************************************
noi {
if  "`vtype'" == "cat" {

	loc atinfo ""
	
	loc fstart=1
	loc fstp: list sizeof global(fvrange$sfx)
	if "${fiscat$sfx}"=="y" {
		loc fstart=0
		loc fstp : list sizeof global(fvlist$sfx)
	}
	
	loc m1start=1
	loc m1stp: list sizeof global(mvrange1$sfx)
	if "${mviscat1$sfx}" == "y" {
		loc m1start=0
		loc m1stp : list sizeof global(mvlist1$sfx)
	}
	
	loc m2start=0
	loc m2stp = 0
	if ${mvarn$sfx} > 1 {
		loc m2start=1
		loc m2stp: list sizeof global(mvrange2$sfx)
		if "${mviscat2$sfx}"=="y" {
			loc m2start=0
			loc m2stp : list sizeof global(mvlist2$sfx)
	}	
	}
	
if "`model'" == "int" {	
	forvalues fi=`fstart'/`fstp' {	
	forvalues m1j=`m1start'/`m1stp' {   
	forvalues m2k=`m2start'/`m2stp' {	

	*** Loop over dummies [range  for interval] and set 0/1 if var-index matches value [var to range value] then add to at specification. 
	***			first for F, then M1 & F*M1, then M2, F*M2, M1*M2, F*M1*M2

	loc atinfo "`atinfo' at ( `outatopt' "

	if "${fiscat$sfx}"=="y" {
		forvalues fv=1/`fstp' {
			loc vn: word `fv' of ${fvlist$sfx}
			loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')' "
		}
	}
	
	if "${fiscat$sfx}"!="y" {
		loc valf: word `fi' of ${fvrange$sfx}		
		loc atinfo "`atinfo' ${fvlist$sfx} = `valf' "
	}	
	if "${mviscat1$sfx}" == "y" {	
		forvalues m1 = 1/`m1stp' {
			loc vn: word `m1' of ${mvlist1$sfx}
			loc atinfo "`atinfo' `vn' = `=inlist(`m1',`m1j')' "
			
			if "${fiscat$sfx}" == "y" {
				forvalues fv=1/`fstp' {
					loc ind1= (`fv'-1)*`m1stp'+`m1'
					loc vn: word `ind1' of ${fm1list$sfx}	
					loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*inlist(`m1',`m1j')' "
				}
			}
			if "${fiscat$sfx}" !="y" {
					loc valf: word `fi' of ${fvrange$sfx}		
					loc vn: word `m1' of ${fm1list$sfx}	
					loc atinfo "`atinfo' `vn' = `=`valf'*inlist(`m1',`m1j')' "
				}	
		}
	}
	if "${mviscat1$sfx}" !="y" {
		loc valm1: word `m1j' of ${mvrange1$sfx}		
		loc atinfo "`atinfo' ${mvlist1$sfx} = `valm1'"
			
			if "${fiscat$sfx}" == "y" {
				forvalues fv=1/`fstp' {
					loc vn: word `fv' of ${fm1list$sfx}	
					loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*`valm1'' "
				}
			}
			if "${fiscat$sfx}" !="y" {
					loc valf: word `fi' of ${fvrange$sfx}
					loc atinfo "`atinfo' ${fm1list$sfx} = `=`valf'*`valm1'' "
				}			
		}
	if  ${mvarn$sfx} > 2 {
		noi disp _newline "{err: If not using factor var notation, model limited to 3-way interaction or <= 2 moderators. OUTDISP terminated}."
	exit
	}
	if  ${mvarn$sfx} ==2 {
		if "${mviscat2$sfx}" == "y" {	
			forvalues m2 = 1/`m2stp' {
				loc vn: word `m2' of ${mvlist2$sfx}
				loc atinfo "`atinfo' `vn' = `=inlist(`m2',`m2k')' "
				
				if "${fiscat$sfx}" == "y" {
					forvalues fv=1/`fstp' {
						loc ind1= (`fv'-1)*`m2stp'+`m2'
						loc vn: word `ind1' of ${fm2list$sfx}	
						loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*inlist(`m2',`m2k')' "
					}
				}
				if "${fiscat$sfx}" !="y" {	
					loc vn: word `m2' of ${fm2list$sfx}	
					loc valf: word `fi' of ${fvrange$sfx}
					loc atinfo "`atinfo' `vn' = `=`valf'*inlist(`m2',`m2k')' "
				}		
			}
	}
		if "${mviscat2$sfx}" !="y" {	
			forvalues m2 = 1/`m2stp' {
				loc valm2: word `m2' of ${mvrange2$sfx}
				loc atinfo "`atinfo' ${mvlist2$sfx} = `valm2'"
				
				if "${fiscat$sfx}" == "y" {
					forvalues fv=1/`fstp' {
						loc vn: word `fv' of ${fm2list$sfx}	
						loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*`valm2'' "
					}
				}
					if "${fiscat$sfx}" !="y" {
						loc valf: word `fi' of ${fvrange$sfx}
						loc atinfo `atinfo' ${fm2list$sfx} = `=`valf'*`valm2'' "
					}		
			}
		}	
	***  M1xM2 and FxM1xM2 if 3way interaction
	if "`int3way'" == "y" {
	
		***  M1xM2
		if  "${mviscat2$sfx}"=="y" {
			forvalues m2 = 1/`m2stp' {
				if "${mviscat1$sfx}" == "y" {
					forvalues m1=1/`m1stp' {
						loc ind1= (`m1'-1)*`m2stp'+`m2'
						loc vn: word `ind1' of ${m1m2list$sfx}	
						loc atinfo #`atinfo' `vn' = `=inlist(`m1',`m1j')*inlist(`m2',`m2k')' "
					}
				}
				if "${mviscat1$sfx}" !="y" {	
					loc vn: word `m2' of ${m1m2list$sfx}	
					loc valm1: word `m1j' of ${mvrange1$sfx}
					loc atinfo "`atinfo' `vn' = `=`valm1'*inlist(`m2',`m2k')' "
				}		
			}
		}
		if  "${mviscat2$sfx}"!="y" {
			loc valm2: word `m2k' of ${mvrange2$sfx}
			if "${mviscat1$sfx}" == "y" {
				forvalues m1=1/`m1stp' {
					loc ind1= (`m1'-1)*`m2stp'+`m2'
					loc vn: word `ind1' of ${m1m2list$sfx}	
					loc atinfo "`atinfo' `vn' = `=`valm1'*inlist(`m2',`m2k')' "
				}
			}
			if "${mviscat1$sfx}" !="y" {	
				loc vn: word `m2' of ${m1m2list$sfx}	
				loc valm1: word `m1j' of ${mvrange1$sfx}
				loc atinfo "`atinfo' ${m1m2list$sfx} = `=`valm1'*`valm2'' "
			}		
		}
		
		***  FxM1xM2
		if  "${fiscat$sfx}"=="y" {
			forvalues fv = 1/`fstp' {
			if  "${mviscat1$sfx}"=="y" {
				forvalues m1 = 1/`m1stp' {
					if "${mviscat2$sfx}" == "y" {
						forvalues m2=1/`m2stp' {
							loc ind1= (`fv'-1)*(`m1'-1)*`m2stp'+`m2'
							loc vn: word `ind1' of ${fm1m2list$sfx}	
							loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*inlist(`m1',`m1j')*inlist(`m2',`m2k')' "
						}
					}
					if "${mviscat2$sfx}" !="y" {	
						loc ind1= (`fv'-1)*`m1stp'+`m1'
						loc vn: word `ind1' of ${fm1m2list$sfx}						
						loc valm2: word `m2j' of ${mvrange2$sfx}
						loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*`valm2'*inlist(`m1',`m1j')' "
					}		
				}
			}
			if  "${mviscat1$sfx}"!="y" {
				loc valm1: word `m1j' of ${mvrange1$sfx}
				if "${mviscat2$sfx}" == "y" {
					forvalues m2=1/`m2stp' {
						loc ind1= (`fv'-1)*`m2stp'+`m2'
						loc vn: word `ind1' of ${fm1m2list$sfx}	
						loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*`valm1'*inlist(`m2',`m2k')' "
					}
				}
				if "${mviscat1$sfx}" !="y" {	
					loc vn: word `fv' of ${fm1m2list$sfx}	
					loc valm1: word `m1j' of ${mvrange1$sfx}
					loc valm2: word `m2k' of ${mvrange2$sfx}
					loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')*`valm1'*`valm2'' "
				}		
			}
		}
		}
	
		if  "${fiscat$sfx}"!="y" {
			loc valf: word `fi' of ${fvrange$sfx}
	
			if  "${mviscat1$sfx}"=="y" {
				forvalues m1 = 1/`m1stp' {
					if "${mviscat2$sfx}" == "y" {
						forvalues m2=1/`m2stp' {
							loc ind1= (`m1'-1)*`m2stp'+`m2'
							loc vn: word `ind1' of ${fm1m2list$sfx}	
							loc atinfo "`atinfo' `vn' = `=`valf'*inlist(`m1',`m1j')*inlist(`m2',`m2k')' "
						}
					}
					if "${mviscat2$sfx}" !="y" {	
						loc ind1= `m1'
						loc vn: word `ind1' of ${fm1m2list$sfx}						
						loc valm2: word `m2j' of ${mvrange2$sfx}
						loc atinfo "`atinfo' `vn' = `=`valf'*`valm2'*inlist(`m1',`m1j')' "
					}		
				}
			}
			if  "${mviscat1$sfx}"!="y" {
				loc valm1: word `m1j' of ${mvrange1$sfx}
				if "${mviscat2$sfx}" == "y" {
					forvalues m2=1/`m2stp' {
						loc ind1= `m2'
						loc vn: word `ind1' of ${fm1m2list$sfx}	
						loc atinfo "`atinfo' `vn' = `=`valf'*`valm1'*inlist(`m2',`m2k')' "
					}
				}
				if "${mviscat2$sfx}" !="y" {	
					loc vn: word `fv' of ${fm1m2list$sfx}	
					loc valm1: word `m1j' of ${mvrange1$sfx}
					loc valm2: word `m2k' of ${mvrange2$sfx}
					loc atinfo "`atinfo' `vn' = `=`valf'*`valm1'*`valm2'' "
				}		
			}
		}	
	}
	}
	loc atinfo "`atinfo' )"
	}
	}
	}
	}
	ret loc atinfo "`atinfo'"
	ret loc atinfotab "`atinfo'"
	
if "`model'" == "main" {	

	forvalues fi=`fstart'/`fstp' {	
	forvalues m1j=`m1start'/`m1stp' {   
	forvalues m2k=`m2start'/`m2stp' {	
	
		loc atinfo "`atinfo' at ( `outatopt' "
		if  "${fiscat$sfx}"=="y" {
 			forvalues fv=1/`fstp' {
				loc vn: word `fv' of ${fvlist$sfx}
				loc atinfo "`atinfo' `vn' = `=inlist(`fv',`fi')' "
			}
		}
		if  "${fiscat$sfx}"!="y" {
 			loc valf: word `fi' of ${fvrange$sfx}
			loc atinfo "`atinfo' ${fvlist$sfx} = `valf' "
		}
		if  "${mviscat1$sfx}"=="y" {
			forvalues m1 = 1/`m1stp' {
				loc vn: word `m1' of ${mvlist1$sfx}
				loc atinfo "`atinfo' `vn' = `=inlist(`m1',`m1j')' "
			}
		}
		if  "${mviscat1$sfx}"!="y" {
			loc valm1: word `m1j' of ${mvrange1$sfx}
			loc atinfo "`atinfo' ${mvlist1$sfx} = `valm1' "
		}
		if ${mvarn$sfx} > 1 {
		if  "${mviscat2$sfx}"=="y" {		
			forvalues m2 = 1/`m2stp' {
				loc vn: word `m2' of ${mvlist2$sfx}
				loc atinfo "`atinfo' `vn' = `=inlist(`m2',`m2k')' "
			}
		}
		if  "${mviscat2$sfx}"!="y" {
			loc valm2: word `m2k' of ${mvrange2$sfx}
			loc atinfo "`atinfo' ${mvlist2$sfx} = `valm12 "
		}
		}
	loc atinfo "`atinfo' )"
	}
	}
	}
	ret loc atinfo "`atinfo'"
	ret loc atinfotab "`atinfo'"	
}
}

}
***  All interval vars 2 way or 3 way *********************************************************************************************************

if  "`vtype'" == "interval" {
	loc atinfo ""
	loc fstp : list sizeof global(fvrange$sfx)
	loc m1stp : list sizeof global(mvrange1$sfx)
	loc m2stp = 1
	if "`int3way'" == "y" | ${mvarn$sfx} > 1  loc m2stp : list sizeof global(mvrange2$sfx)
	
if "`model'" == "int" {	
	forvalues fi=1/`fstp' {	
		loc fval: word `fi' of ${fvrange$sfx}
	forvalues m1j=1/`m1stp' {   
		loc m1val: word `m1j' of ${mvrange1$sfx}
	forvalues m2k=1/`m2stp' {	

	loc atinfo "`atinfo' at ( `outatopt' ${fvlist$sfx} = `fval' ${mvlist1$sfx}= `m1val'  ${fm1list$sfx} = `=`fval'*`m1val'' "
	if `m2stp' > 1 {
		loc m2val: word `m2k' of ${mvrange2$sfx}
		loc atinfo "`atinfo' ${mvlist2$sfx}= `m2val' ${fm2list$sfx} = `=`fval'*`m2val'' "
	
		if "`int3way'" == "y" 	loc atinfo "`atinfo' ${m1m2list$sfx}= `=`m1val'*`m2val'' ${fm1m2list$sfx} = `=`fval'*`m1val'*`m2val'' "
	}
		loc atinfo "`atinfo'  ) "
}
}
}
	ret loc atinfo "`atinfo'"
	ret loc atinfotab "`atinfo'"	

}
if "`model'" == "main" {	
	forvalues fi=1/`fstp' {	
		loc fval: word `fi' of ${fvrange$sfx}
	forvalues m1j=1/`m1stp' {   
		loc m1val: word `m1j' of ${mvrange1$sfx}
	forvalues m2k=1/`m2stp' {	

	loc atinfo "`atinfo' at ( `outatopt' ${fvlist$sfx} = `fval' ${mvlist1$sfx}= `m1val' "
	if `m2stp' > 1 {
		loc m2val: word `m2k' of ${mvrange2$sfx}
		loc atinfo "`atinfo' ${mvlist2$sfx}= `m2val' "
	}
		loc atinfo "`atinfo'  ) "
}
}
}
	ret loc atinfo "`atinfo'"
}

}
*
glo atinfo2$sfx "`atinfo'"
}
end

