*!  solvebvquad.ado Version 1.1		RL Kaufman 	07/13/2016

***  	1.0  Used for JN Significance region calculations. Extended/replace getqabc. Called by SIGREG.ADo
***			Calculates  coefficients a-tilde, b-tilde, c-tilde (AT BT CT) for solving
***			Boundary value BV from quadratic equation. Calculats derivaive at BV to deetermine is change is to sig or not-sig. 
***			Returns BV1 DBV1 BV2 DBV2 (missing if complex).  BV1 is for change to NOT-SIG, BV2 is for change to SIG
***		    MOD1=moderator number whose bound vals are sought.
***			WCRIT = critical value, FNUM= category # of focal var,  MODS= list of other moderator numbers, 
***			MODSC=category # of other mods, MODSV= value of vars indexed by MODS (1 or 0 if categoery f a dummy var)
***		1.1 Allows 3way F*M1*M2 wih Ff*M3 and F*M4

program solvebvquad, rclass
version 14.2
syntax  , mod1(integer) wcrit(real) fnum(integer) [ mods(numlist integer) modsc(numlist integer) modsv(numlist) int3(string) EQName(string)]
tempname vget vb

***		Collect names of all variables.  Focal + Focal*All Mods. NOTE MOD1 can only be an interval (single dummy) measure
***			Will be screened by calling program
loc nmods: list sizeof mods
loc vblist "${fvarc`fnum'$sfx} ${f`fnum'm`mod1'c1$sfx}"
if `nmods' >0 {
	forvalues i=1/`nmods' {
		loc mn: word `i' of `mods'
		loc mc: word `i' of `modsc'
		loc vblist "`vblist' ${f`fnum'm`mn'c`mc'$sfx}"
	}
}
***	If 3way interaction determine what in MODS corresponds to M2 (M1).  Screened by SIGREG.ADO so MOD1 must be M1(M2)
if "`int3'"=="y" 	{
	forvalues i=1/`nmods' {
		loc mn: word `i' of `mods'
		loc mc: word `i' of `modsc'
		loc mv: word `i' of `modsv'
		if `mn' <= 2 {
			if `mod1' == 1 {
				loc mc1 = 1
				loc mod2 = 2
				loc mc2 = `mc'
				loc intmv = `mv'
			}
			if `mod1' == 2 {
				loc mc1 = 1
				loc mod2 = 1
				loc mc2 = `mc'
				loc intmv = `mv'				
			}
		}	
	}


/*	if `mod1' == 1 { 
		loc intm1 = 1
		loc intm2 = 2 
		loc intmc1= 1
	}
	if `mod1' == 2 {
		loc intm1 = 2
		loc intm2 = 1
		loc intmc2 = 1
	}
	forvalues i=1/`nmods' {
		loc mn: word `i' of `mods'
		loc mc: word `i' of `modsc'
		loc mv: word `i' of `modsv'
		if `mn' <= 2 {
			loc intmc`mn' = `mc'
			loc intmv = `mv'
		}	
	}
 */	
loc vblist "`vblist' ${m`mod1'c`mc1'm`mod2'c`mc2'$sfx}  ${f`fnum'm`mod1'c`mc1'm`mod2'c`mc2'$sfx}	"
}

***		Get Var(b) matrix for those variables

mat `vget'=e(V)
getvb , matrix("`vget'") vname("`vblist'") eqn(`eqname') nokeep
mat `vb'= r(vbext)
***	Calculate AT, BT, CT 

loc at= `wcrit'*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1$sfx}")))-(${bf`fnum'm`mod1'c1$sfx})^2
loc bt=`wcrit'*2*(el(`vb',rownumb(`vb',"${fvarc`fnum'$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1$sfx}")))  /// 
	-2*(${bfvarc`fnum'$sfx})*(${bf`fnum'm`mod1'c1$sfx})
loc ct= `wcrit'*(el(`vb',rownumb(`vb',"${fvarc`fnum'$sfx}"),colnumb(`vb',"${fvarc`fnum'$sfx}")))  /// 
	-(${bfvarc`fnum'$sfx})^2
***  disp "one", `at', `bt', `ct'
if `nmods'!=0 {
	forvalues j=1/`nmods' {
		loc mn: word `j' of `mods'
		loc mc: word `j' of `modsc'
		loc mv: word `j' of `modsv'
		loc bt= `bt' + `wcrit'*2*(`mv')*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1$sfx}"),colnumb(`vb',"${f`fnum'm`mn'c`mc'$sfx}"))) ///
			-2*(${bf`fnum'm`mod1'c1$sfx})*(${bf`fnum'm`mn'c`mc'$sfx})*(`mv')
		loc ct = `ct' + `wcrit'*(2*(`mv')*(el(`vb',rownumb(`vb',"${fvarc`fnum'$sfx}"),colnumb(`vb',"${f`fnum'm`mn'c`mc'$sfx}")))  /// 
			+  (`mv')^2*(el(`vb',rownumb(`vb',"${f`fnum'm`mn'c`mc'$sfx}"),colnumb(`vb',"${f`fnum'm`mn'c`mc'$sfx}")) )) ///
			-2*(`mv')*(${bfvarc`fnum'$sfx})*(${bf`fnum'm`mn'c`mc'$sfx}) -(`mv')^2*(${bf`fnum'm`mn'c`mc'$sfx})^2
		if `nmods' >1 {
			forvalues k= `=`j'+1'/`nmods'{
				loc mn2: word `k' of `mods'
				loc mc2: word `k' of `modsc'
				loc mv2: word `k' of `modsv'
				loc ct = `ct' + `wcrit'*2*(`mv')*(`mv2')*(el(`vb',rownumb(`vb',"${f`fnum'm`mn'c`mc'$sfx}"),colnumb(`vb',"${f`fnum'm`mn2'c`mc2'$sfx}")) ) /// 
						- 2*(`mv')*(`mv2')*(${bf`fnum'm`mn'c`mc'$sfx})*(${bf`fnum'm`mn2'c`mc2'$sfx})
			}
		}
		if "`int3'" == "y" & `mn' <= 2 {
			loc mv = `intmv'
			loc at = `at' +  `wcrit'*(2*(`mv')*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc'$sfx}"))) ///
				+ (`mv')^2*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc'$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc'$sfx}")) )) ///
			   - 2*(`mv')*(${bf`fnum'm`mod1'c1$sfx})*(${bf`fnum'm`mod1'c1m`mod2'c`mc'$sfx}) -(`mv')^2*(${bf`fnum'm`mod1'c1m`mod2'c`mc'$sfx})^2
			   loc bt = `bt' + `wcrit'*((2*(`mv'))*(el(`vb',rownumb(`vb',"${fvarc`fnum'$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc'$sfx}"))) ///
				+ (2*(`mv'^2)*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc'$sfx}"),colnumb(`vb',"${f`fnum'm`mod2'c`mc'$sfx}")) ))) ///
				-2*(`mv')*((${bfvarc`fnum'$sfx})*(${bf`fnum'm`mod1'c1m`mod2'c`mc'$sfx})) /// 
				-2*(`mv'^2)*(${bf`fnum'm`mod2'c`mc'$sfx})*(${bf`fnum'm`mod1'c1m`mod2'c`mc'$sfx})
		}
	}
}
*mat holdvb = `vb'
**** 		Calculate BV1 and BV2
****		Screen for no solution ( AT=0 or (`bt')^2-4*(`at')*(`ct') < 0). I.e., sig never changes
loc sqbt = (`bt')^2-4*(`at')*(`ct')
	loc dbv1 =.
	loc dbv2 =.

if `at'==0 | `sqbt' <0 {
	loc bv1 =.
	loc dbv1 =.
	loc bv2 =.
	loc dbv2 =.
}
else {
	loc bv1= (-`bt'+((`bt')^2-4*(`at')*(`ct'))^.5)/(2*(`at'))
	loc bv2= (-`bt'-((`bt')^2-4*(`at')*(`ct'))^.5)/(2*(`at'))
}
****	Get derivatives for each boundary value.  Need bmod var(bmod) and derivatves of each w.r.t to MOD1
forvalues j=1/2 {
	if `bv`j'' !=. {
		getbvarbmod , mods(`mod1' `mods') fnum(`fnum') modsv(`bv`j'' `modsv') modsc(1 `modsc') int3("`int3'") eqn(`eqname')
		loc bmod= r(bmod)
		loc vbmod= r(vbmod)
		loc db= ${bf`fnum'm`mod1'c1$sfx}
		loc dvb=2*(`bv`j'')*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1$sfx}"))) ///
					+ 2*(el(`vb',rownumb(`vb',"${fvarc`fnum'$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1$sfx}")))
		if `nmods' > 0 {
			loc vn: word 2 of `vblist'
			forvalues i=1/`nmods' {
				loc mn2: word `i' of `mods'
				loc mc2: word `i' of `modsc'
				loc mv2: word `i' of `modsv'
				loc vn2: word `=`i'+2' of `vblist'
				loc dvb = `dvb' + 2*(`mv2')*(el(`vb',rownumb(`vb',"`vn'"),colnumb(`vb',"`vn2'")))
				if "`int3'" == "y" & `mn2' <= 2 {
					loc db= `db' + (`mv2')*(${bf`fnum'm`mod1'c1m`mod2'c`mc2'$sfx})
					loc dvb = `dvb' + 2*(`mv2')*(el(`vb',rownumb(`vb',"${fvarc`fnum'$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc2'$sfx}"))) ///
							+4*(`bv`j'')*(`mv2')*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc2'$sfx}"))) ///
							+2*(`mv2')^2*(el(`vb',rownumb(`vb',"${f`fnum'm`mod2'c`mc2'$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc2'$sfx}"))) ///
							+2*(`bv`j'')*((`mv2')^2)*(el(`vb',rownumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc2'$sfx}"),colnumb(`vb',"${f`fnum'm`mod1'c1m`mod2'c`mc2'$sfx}")))			
				}
			}
		}
		loc dbv`j' = 2*(`bmod')/(`vbmod')*(`db') - (`dvb')* (`bmod'/`vbmod')^2
	}
}
return sca bv1= `bv1'
return sca dbv1= `dbv1'
return sca bv2= `bv2'
return sca dbv2= `dbv2'
end
