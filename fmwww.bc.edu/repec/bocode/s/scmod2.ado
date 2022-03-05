*!  scmod2.ado 	Version 4.1		RL Kaufman 		8/1/2017

***  	1.0  Sign change analysis for 2 moderators adapted from scmod1.ado for 1 moderator.  Called by GFI.ADO
***		   Creates 1 table for each category of nominal focal variable
***		   Can be embedded in loops for additonal moderators display ranges
***		2.0 Added functionality for calculating when 3way specified
***		2.1 Switched from using getb.ado to coeff in global macros
***		2.3 Added BFORM option for reformatting coefficients.  Now uses value labels from global macros
***		3.0  Removed checking code and generally cleaned up code. Added SUMWGT(no) option so user can request use of unweighted summary statistics.
***		4.0  Save sign change matrix body, string matrix row/col wit sign changes when text as return
***		4.1  Corrected saved matrices when have multiple focal var effects, adapted to ordered prob models setuo

program scmod2, rclass
version 14.2
syntax ,  mod1(integer)  mod2(integer) [EQName(string asis) int3(string) BForm(string) ]
tempvar predpos predbmod
tempname bb
mat `bb'=e(b)
if "`eqname'" != "" loc eqndisp ":`eqname'"
loc bnowform "%10.0g"
if "`bform'" != "" loc bnowform "`bform'"

***		initialize predpos predbmod tempvar so can always use replace command when need to calculate % positive effects
qui gen `predpos'=.
qui gen `predbmod'=.

***		rlist = numlist of values of mod1 if interval but =  mod1 category # if nominal , 0=base
***		rlab = value labels (=rlist) for interval mod1 but = display names for categories for nominal

loc rlist "${mvrange`mod1'$sfx}"
loc nlab: list sizeof global(mvrange`mod1'$sfx)
loc rlab ""
forvalues mci=1/`nlab' {
	loc rlab "`rlab' ${mvlabm`mod1'c`mci'$sfx}"
}
loc nrow = `nlab'

***		Repeat for mod2 defining col list and labels as for rows , clist  & clab
loc clist "${mvrange`mod2'$sfx}"
loc nlab: list sizeof global(mvrange`mod2'$sfx)
loc clab ""

loc ncol = `nlab'

forvalues mci=1/`nlab' {
	loc clab "`clab' ${mvlabm`mod2'c`mci'$sfx}"
}	

***		Loop over #of focal var categories , creating 1 mod1 by mod2 table for each
***		Loop over #of mod2 var categories in sets of 5 per panel, creating additional panles as needed	. Sign change col only on last panel
***		For each type of table row (Header, B Sign/Value, Sign Changes, %Positive) loop over values/categories of mod2 var

qui{
***		Define # of repititions in sets of 5,  repition # IREP runs from  MCI2= 1+(`irep'-1)*5' to `mc2max' limited to last category mc2N
	loc mc2n: list sizeof clist
	loc m2rep=int(`mc2n'/5)
	if mod(`mc2n',5) != 0 loc m2rep=`m2rep'+1
	
***		START loop over Focal var categories, label as Table # of n if focal is nominal

forvalues	fci=1/${fcnum$sfx} {
*** Initialize matrices to store results
mat Bmodf`fci'=J(`nrow',`ncol',0)
mat rownames Bmodf`fci' = `rlab'
mat colnames Bmodf`fci' = `clab'
mat SCcolf`fci'=J(1,`ncol',0)
mat SCrowf`fci'=J(`nrow',1,0)
loc sccol ""
loc scrow ""
loc sccol2 ""
loc scrow2 ""


loc fcat ""
loc ftab " "
if ${fcnum$sfx} >1 {
	loc fcat ": ${fvnamec`fci'$sfx}"
	loc ftab "[Table `fci' of ${fcnum$sfx}]"
}
***		(Re)set counter for # of negative effects across row & across all panels /display values of mod2 for each FCI
loc rn: list sizeof rlab

forvalues rni=1/`rn' {
	loc rnneg`rni'=0
}
***		(Re)set counter for # of negative effects down column acrosss /display values of mod1 for each FCI
forvalues mci2=1/`mc2n' {
	loc cnneg`mci2'=0
}
*** Start repetition of panels if needed, set max col # on last panel
forvalues irep=1/`m2rep' {
	loc mc2max=min(5+(`irep'-1)*5,`mc2n')
	
*** 	define last point/position of row and line length for results box, b sign/value cols start in 17, 11 digit wide, 13 for Sign Changes col
***		Adjust for sign changes column only on last repetition
	loc lastpt=17+(`mc2max'-(`irep'-1)*5)*11
	loc linlgth= `lastpt'-15
	loc linlgth2= `linlgth'+1
	loc sgchg ""
	if `irep' == `m2rep' {
		loc lastpt=17+(`mc2max'-(`irep'-1)*5)*11 +13
		loc linlgth= `lastpt'-15
		loc linlgth2= `linlgth'-13
	}
	loc mc2beg=1+(`irep'-1)*5
***		FMTSTR = string formatting a row	RESSTR = string containing row results/content used for mata printf function
***		Print table title then header.  Loop over MCI2 to create column of results for mod2 value/category 
	loc fmtstr ""
	loc resstr ""
	loc pannum ""
	
***		Code for Formatted table WITHOUT sign change column if not last repeition of panel
if `irep' != `m2rep' {

***		Construct & print title & header rows
	if `m2rep' > 1 loc pannum "[Panel `irep' of `m2rep']"
	noi disp _newline  as txt `" Sign Change Analysis of Effect of {bf:${fvldisp$sfx}`fcat'} on g({bf:${dvname$sfx}`eqndisp'})"'  _col(`=max(69,`lastpt'-13)')"`ftab'" ///
		_newline `" Moderated by {bf:${mvldisp`mod1'$sfx}} (M1) and {bf:${mvldisp`mod2'$sfx}} (M2) "' _newline _col(`=max(58,`lastpt'-13)') "`pannum'" 
	noi mata: printf(" {txt}{hline `=15+`linlgth''}\n{col 27}%-45s\n","Effect of ${fvnamec`fci'$sfx}  ") 	
	noi mata: printf(" {txt}{hline 13}{c TT}{hline `linlgth2'}\n {col 15}{c |}{col 17}%-22s\n","       When ${mvldisp2$sfx} = ") 	
	noi mata: printf(" {txt}%4s{col 15}{c |}  {hline `=`linlgth'-4'}\n","When") 
		loc fmtstr " {txt}%-12s{col 15}{c |}"
		loc resstr `"${mvldisp`mod1'$sfx}="'
		
	forvalues mci2=`mc2beg'/`mc2max' {
		loc fmtstr "`fmtstr'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'} %-9s"
		loc cval: word `mci2' of `clist'
		loc clabi: word `mci2' of `clab'
*		if ${mcnum`mod2'$sfx} == 1 {
*			loc clabi=string(`cval',"%8.`ndig'f")+ " "
*		}
		loc resstr `"`resstr'","`clabi'"'
	}
		noi mata: printf("`fmtstr'\n","`resstr'")
		noi mata: printf("%1s{txt}{hline 13}{c +}{hline `linlgth2'}\n"," ") 
***	  Loop over # of display values/categories of mod1, report row label value/name and sign & value of focal effect
***			for each display value/category of mod2 in columns
		loc rn: list sizeof rlab
		
		forvalues rni=1/`rn' {
			loc rval: word `rni' of `rlist'
			loc rlabi: word `rni' of `rlab'
			loc rfmt "%-11s"
			if ${mcnum`mod1'$sfx} == 1 {
*				loc rlabi=string(`rval',"%9.3f")+ "  "
				loc rfmt "%11s"				
			}
			loc fmtstr0 " {txt}{col 15}{c |}\n {txt} `rfmt'{col 15}{c |}"
			loc resstr0 `"`rlabi'"'
			loc fmtstr " {txt}{col 15}{c |}"
			loc resstr ""
			forvalues mci2=`mc2beg'/`mc2max' {
				loc cval: word `mci2' of `clist'

***		get BBASE_fci = main effect of focal cat fci for mod2_mci2, BMOD1_rni & BMOD2_mci2 = 2way coef for focal_fci * mod1_rni or * mod2_`cval _mci2
***			2way effect is mod cat 1 for interval or   mod2 cat #=`row value'  (0 for base category)  mod1 cat `col value'  (0 for base category)
				loc bbase`fci'= ${bfvarc`fci'$sfx}
				loc bnow=`bbase`fci''
				
*** 	set CM1=cat # and VM1 = value of M1 to add in bmod*val .  For interval use  cat=1 of mvar with value= rval
***			for categorical use cat # stored in rlist and value=1, except base category use cat1 & value=0 (so val*bmod=0)
				loc cm1=1
				loc vm1=`rval'
				if ${mcnum`mod1'$sfx} > 1 {
					loc vm1=1
					loc cm1=`rval'
					if `rni'== 1 {
						loc vm1=0
						loc cm1=1
					}
				}
				loc bmod1`rni'= ${bf`fci'm`mod1'c`cm1'$sfx}
				loc bnow=`bnow'+`vm1'*`bmod1`rni''			

				loc cm2=1
				loc vm2=`cval'
				if ${mcnum`mod2'$sfx} > 1 {
					loc vm2=1
					loc cm2=`cval'
					if `mci2'== 1 {
						loc vm2=0
						loc cm2=1
					}
				}
				loc bmod2`mci2'= ${bf`fci'm`mod2'c`cm2'$sfx}
				loc bnow=`bnow'+`vm2'*`bmod2`mci2''		
				
***		If 3way int specified add to caclulation of BNOW
				if "`int3'" == "y" {
					loc bmod1`rni'mod2`mci2'= ${bf`fci'm`mod1'c`cm1'm`mod2'c`cm2'$sfx}
					loc bnow=`bnow'+`vm1'*`vm2'*`bmod1`rni'mod2`mci2''					
				}
***		determine sign of moderated effect & count negative effects in col and in row, used for nominal moderator
				loc sgnb=sign(`bnow')
				loc stxt= "Pos"
				if `sgnb'< 0 {
					loc stxt="Neg"
					loc ++cnneg`mci2'
					loc ++rnneg`rni'				
				}
			loc fmtstr0 "`fmtstr0'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%8s"
			loc resstr0 `"`resstr0'","`stxt' b="'
			loc fmtstr "`fmtstr'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%8s"
			loc resstr "`resstr' "`=strofreal(`bnow',"`bnowform'")'","

***  save bnow to matrix Bmod
mat Bmodf`fci'[`rni',`mci2'] = `bnow'
			}
			
***		Print row of results, Pos(Neg) b=  then row of b values 
			noi mata: printf("`fmtstr0'\n","`resstr0'") 
			noi mata: printf("`fmtstr'\n",`resstr') 
		}
***	  For nominal moderator report if sign changes acrosss categories: never or sometimes
***	  For interval moderator caclculate value where sign changes, report value if within mod max/min or Never if not
		loc fmtstr0 " {txt}{hline 13}{c +}{hline `linlgth2'}\n {txt}%12s{col 15}{c |}"
		loc resstr0 `"Sign Changes"'
		loc fmtstr " {txt}%12s{col 15}{c |}"
		loc resstr  ""given M2  ","
		
		forvalues mci2=`mc2beg'/`mc2max' {
			loc sigchg = "  Never"
			loc sigchg2 " "
			if ${mcnum`mod1'$sfx} > 1  & `cnneg`mci2'' > 0 & `cnneg`mci2'' < `rn' loc sigchg "Sometimes"
			if ${mcnum`mod1'$sfx} == 1 {
				summ ${mvar`mod1'c1$sfx} if esamp$sfx 
				loc cval: word `mci2' of `clist'
				if ${mcnum`mod2'$sfx} >1 {
					loc cval=1
					if `mci2' ==1 loc cval=0
				}				
				loc chgval=-(`bbase`fci''+`bmod2`mci2''*`cval')/`bmod1`rn''
				if "`int3'"=="y" loc chgval=-(`bbase`fci''+`bmod2`mci2''*`cval')/(`bmod1`rn''+`bmod1`rn'mod2`mci2''*`cval')
				if inrange(`chgval',`r(min)',`r(max)')==1 {
					loc sigchg= `"when M1="'
					loc sigchg2 =`"`=string(`chgval',"%8.3f")'"'
				}
			}
			if strmatch("`sigchg'","*Never*") !=1 {
				loc sccol2 "`sccol2' `" `sigchg2'"' "
				loc sccol "`sccol'  `"when M1= "' "
			}
			if strmatch("`sigchg'","*Never*") ==1 {
				loc sccol2 "`sccol2' `" `sigchg'"' "
				loc sccol "`sccol'   `" _ "' "
			}
			
			loc fmtstr0 "`fmtstr0'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%9s"
			loc resstr0 `"`resstr0'","`sigchg'"'
			loc fmtstr "`fmtstr'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%9s"
			loc resstr `"`resstr' "`sigchg2'","'
		}
***		Print sign change results, then bottom line
		noi mata: printf("%1s{txt}{col 15}{c |}\n"," ") 
		noi mata: printf("`fmtstr0'{col `=17+(`mc2max'-(`irep'-1)*5)*11'}{txt}\n","`resstr0'") 
		noi mata: printf("`fmtstr'{col `=17+(`mc2max'-(`irep'-1)*5)*11'}{txt}\n",`resstr') 
		noi mata: printf("%1s{txt}{hline 13}{c BT}{hline `linlgth2'}\n"," ") 
}
	
***		Code for Formatted table with sign change column on last repeition of panel
if `irep' == `m2rep' {
	if `m2rep' > 1 loc pannum "[Panel `irep' of `m2rep']"
	noi disp _newline  as txt `" Sign Change Analysis of Effect of {bf:${fvldisp$sfx}`fcat'} on g({bf:${dvname$sfx}`eqndisp'})"'  _col(`=max(69,`lastpt'-13)')"`ftab'" ///
		_newline `" Moderated by {bf:${mvldisp`mod1'$sfx}} (M1) and {bf:${mvldisp`mod2'$sfx}} (M2) "' _newline _col(`=max(58,`lastpt'-13)') "`pannum'" 
	noi mata: printf(" {txt}{hline `=15+`linlgth''}\n{col 27}%-45s\n","Effect of ${fvnamec`fci'$sfx}  ") 	
	noi mata: printf(" {txt}{hline 13}{c TT}{hline `linlgth2'}{c TT}{hline 13}\n {col 15}{c |}{col 17}%-22s{col `=`lastpt'-12'}{c |}\n","       When ${mvldisp2$sfx} = ") 	
	noi mata: printf(" {txt}%4s{col 15}{c |}  {hline `=`linlgth'-17'}{col `=`lastpt'-12'}{c |}%13s\n","When","Sign Changes") 
		loc fmtstr " {txt}%-12s{col 15}{c |}"
		loc resstr `"${mvldisp`mod1'$sfx}="'
		
	forvalues mci2=`mc2beg'/`mc2max' {
		loc fmtstr "`fmtstr'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'} %-9s"
		loc cval: word `mci2' of `clist'
		loc clabi: word `mci2' of `clab'
*		if ${mcnum`mod2'$sfx} == 1 {
*			loc clabi=string(`cval',"%8.`ndig'f")+ " "
*		}
		loc resstr `"`resstr'","`clabi'"'
	}
		noi mata: printf("`fmtstr'  {c |}%13s\n","`resstr'"," given M1")
		noi mata: printf("%1s{txt}{hline 13}{c +}{hline `linlgth2'}{c +}{hline 13}\n"," ") 
***	  Loop over # of display values/categories of mod1, report row label value/name and sign & value of focal effect
***			for each display value/category of mod2 in columns
		loc rn: list sizeof rlab
		
		forvalues rni=1/`rn' {
			loc rval: word `rni' of `rlist'
			loc rlabi: word `rni' of `rlab'
			loc rfmt "%-11s"
			if ${mcnum`mod1'$sfx} == 1 {
*				loc rlabi=string(`rval',"%9.`ndig'f")+ "  "
				loc rfmt "%11s"				
			}
			loc fmtstr0 " {txt}{col 15}{c |}{col `=`linlgth'+3'}{c |}\n {txt} `rfmt'{col 15}{c |}"
			loc resstr0 `"`rlabi'"'
			loc fmtstr " {txt}{col 15}{c |}"
			loc resstr ""
			forvalues mci2=`mc2beg'/`mc2max' {
				loc cval: word `mci2' of `clist'

***		get BBASE_fci = main effect of focal cat fci for mod2_mci2, BMOD1_rni & BMOD2_mci2 = 2way coef for focal_fci * mod1_rni or * mod2_`cval _mci2
***			2way effect is mod cat 1 for interval or   mod2 cat #=`row value'  (0 for base category)  mod1 cat `col value'  (0 for base category)
				loc bbase`fci'= ${bfvarc`fci'$sfx}
				loc bnow=`bbase`fci''
*** 	set CM1=cat # and VM1 = value of M1 to add in bmod*val .  For interval use  cat=1 of mvar with value= rval
***			for categorical use cat # stored in rlist and value=1, except baset category use cat1 & value=0 (so val*bmod=0)
				loc cm1=1
				loc vm1=`rval'
				if ${mcnum`mod1'$sfx} > 1 {
					loc vm1=1
					loc cm1=`rval'
					if `rni'== 1 {
						loc vm1=0
						loc cm1=1
					}
				}
				loc bmod1`rni'= ${bf`fci'm`mod1'c`cm1'$sfx}
				loc bnow=`bnow'+`vm1'*`bmod1`rni''			
				loc cm2=1
				loc vm2=`cval'
				if ${mcnum`mod2'$sfx} > 1 {
					loc vm2=1
					loc cm2=`cval'
					if `mci2'== 1 {
						loc vm2=0
						loc cm2=1
					}
				}
				loc bmod2`mci2'= ${bf`fci'm`mod2'c`cm2'$sfx}
				loc bnow=`bnow'+`vm2'*`bmod2`mci2''			
				
***		If 3way int specified add to calculation of BNOW
				if "`int3'" == "y" {
					loc bmod1`rni'mod2`mci2'= ${bf`fci'm`mod1'c`cm1'm`mod2'c`cm2'$sfx}
					loc bnow=`bnow'+`vm1'*`vm2'*`bmod1`rni'mod2`mci2''					
				}

***		determine sign of moderated effect & count  negative effects in col and in row, used for nominal moderator
				loc sgnb=sign(`bnow')
				loc stxt= "Pos"
				if `sgnb'< 0 {
					loc stxt="Neg"
					loc ++cnneg`mci2'
					loc ++rnneg`rni'				
				}
				loc fmtstr0 "`fmtstr0'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%8s"
				loc resstr0 `"`resstr0'","`stxt' b="'
				loc fmtstr "`fmtstr'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%8s"
				loc resstr "`resstr' "`=strofreal(`bnow',"`bnowform'")'","
			
***  save bnow to matrix Bmod
mat Bmodf`fci'[`rni',`mci2'] = `bnow'
			}
			
***		CAlculate sign changes for Mod2 contngent on Mod1, report in last col of each row
			loc sigchg = "    Never"
			loc sigchg2 " "
			if ${mcnum`mod2'$sfx} > 1  & `rnneg`rni'' > 0 & `rnneg`rni'' < `mc2n' loc sigchg "Sometimes"
			if ${mcnum`mod2'$sfx} == 1 {
***		RVAL already set for row.  Adjust for nominal M1
				if ${mcnum`mod1'$sfx} >1 {
					loc rval=1
					if `rni' ==1 loc rval=0
				}		
				loc chgval=-(`bbase`fci''+`bmod1`rni''*`rval')/`bmod2`mc2max''
				if "`int3'"=="y" loc chgval=-(`bbase`fci''+`bmod1`rni''*`rval')/(`bmod2`mc2max''+`bmod1`rni'mod2`mc2max''*`rval')
				summ ${mvar`mod2'c1$sfx}
				if inrange(`chgval',`r(min)',`r(max)')==1 {
					loc sigchg= `"when M2="'
					loc sigchg2 =`"`=string(`chgval',"%8.3f")'"'
				}
			}
			if strmatch("`sigchg'","*Never*") !=1 {
				loc scrow2 "`scrow2' `" `sigchg2'"' "
				loc scrow "`scrow'   `"when M2= "' "
			}
			if strmatch("`sigchg'","*Never*") ==1 {
				loc scrow2 "`scrow2' `" `sigchg'"' "
				loc scrow "`scrow'   `" _ "' "
			}
			
			loc fmtstr0 "`fmtstr0'{col `=17+(`mc2max'-(`irep'-1)*5)*11'}{txt} {c |}{res}%11s"
			loc resstr0 `"`resstr0'","`sigchg'"'	
			loc fmtstr "`fmtstr'{col `=17+(`mc2max'-(`irep'-1)*5)*11'}{txt} {c |}{res}%11s"
			loc resstr `"`resstr' "`sigchg2'""'
		
***		Print row of results, Sign b=  then row of b values 
			noi mata: printf("`fmtstr0'\n","`resstr0'") 
			noi mata: printf("`fmtstr'\n",`resstr') 
		}	
***	  For nominal Mod1 report if sign changes acrosss categories: never or sometimes
***	  For interval Mod1 caclculate value where sign changes, report value if within mod max/min or Never if not
		loc fmtstr0 " {txt}{hline 13}{c +}{hline `linlgth2'}{c +}{hline 13}\n {txt}%12s{col 15}{c |}"
		loc resstr0 `"Sign Changes"'
		loc fmtstr " {txt}%12s{col 15}{c |}"
		loc resstr  ""given M2  ","
		
		forvalues mci2=`mc2beg'/`mc2max' {
			loc sigchg = "  Never"
			loc sigchg2 " "
			if ${mcnum`mod1'$sfx} > 1  & `cnneg`mci2'' > 0 & `cnneg`mci2'' < `rn' loc sigchg "Sometimes"
			if ${mcnum`mod1'$sfx} == 1 {
				summ ${mvar`mod1'c1$sfx} if esamp$sfx 
				loc cval: word `mci2' of `clist'
				if ${mcnum`mod2'$sfx} >1 {
					loc cval=1
					if `mci2' ==1 loc cval=0
				}				
				loc chgval=-(`bbase`fci''+`bmod2`mci2''*`cval')/`bmod1`rn''
				if "`int3'"=="y" loc chgval=-(`bbase`fci''+`bmod2`mci2''*`cval')/(`bmod1`rn''+`bmod1`rn'mod2`mci2''*`cval')
				if inrange(`chgval',`r(min)',`r(max)')==1 {
					loc sigchg= `"when M1="'
					loc sigchg2 =`"`=string(`chgval',"%8.3f")'"'
				}
			
			}
			if strmatch("`sigchg'","*Never*") !=1 {
				loc sccol2 "`sccol2' `" `sigchg2'"' "
				loc sccol "`sccol'  `"when M2= "' "
			}
			if strmatch("`sigchg'","*Never*") ==1 {
				loc sccol2 "`sccol2' `" `sigchg'"' "
				loc sccol "`sccol'   `" _ "' "
			}
			loc fmtstr0 "`fmtstr0'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%9s"
			loc resstr0 `"`resstr0'","`sigchg'"'
			loc fmtstr "`fmtstr'{col `=17+(`mci2'-1-(`irep'-1)*5)*11'}{res}%9s"
			loc resstr `"`resstr' "`sigchg2'","'
		}

***		Print sign change results, then bottom line
		noi mata: printf("%1s{txt}{col 15}{c |}{col `=17+(`mc2max'-(`irep'-1)*5)*11'} {c |}\n"," ") 
		noi mata: printf("`fmtstr0'{col `=17+(`mc2max'-(`irep'-1)*5)*11'}{txt} {c |}\n","`resstr0'") 
		noi mata: printf("`fmtstr'{col `=17+(`mc2max'-(`irep'-1)*5)*11'}{txt} {c |}\n",`resstr') 
		noi mata: printf("%1s{txt}{hline 13}{c BT}{hline `linlgth2'}{c BT}{hline 13}\n"," ") 
}
	}
***		Calculate value for each sample case of moderated effect of Focal using formula in PREDB
***		Report % of positive values
		loc fmtstr " {txt}{hline 13}{c +}{hline `linlgth'}\n {txt}%-10s{col 15}{c |}"
		loc resstr `""% Positive""'		
		loc predb "`bbase`fci''"
		forvalues  mi=1/2 {
		forvalues mci=1/${mcnum`mod`mi''$sfx} {
			/*if ${mcnum`mod`mi''$sfx} ==1 */ loc predb "`predb' + ${bf`fci'm`mod`mi''c`mci'$sfx} * ${mvar`mod`mi''c`mci'$sfx}"
*			if ${mcnum`mod`mi''$sfx} !=1 loc predb "`predb' + ${bf`fci'm`mod`mi''c`mci'$sfx} * ${mvar`mod`mi''c`mci'$sfx}"
		}
		}
		if "`int3'" == "y" {
			forvalues mci1=1/${mcnum1$sfx} {
				forvalues mci2=1/${mcnum2$sfx} {
					loc predb "`predb' + ${bf`fci'm1c`mci1'm2c`mci2'$sfx} * ${mvar1c`mci1'$sfx} * ${mvar2c`mci2'$sfx}"		
				}
			}
		}
		replace `predbmod'= `predb' if esamp$sfx  
		replace `predpos'= `predbmod'>0 if esamp$sfx  
		summ `predpos' if esamp$sfx  ${sumwgt$sfx}
		loc pctpos=`r(mean)'*100
		
***		Print % Positive results and then return to top loop if need additional repetitions of table for categories of Focal var
		noi disp _newline "Percent of in-sample cases with positive moderated effect of {bf:${fvnamec`fci'$sfx}} = " as res %-6.1f `pctpos' _newline(2)

mat colnames SCcolf`fci' = `sccol2'
mat coleq SCcolf`fci' = `sccol'
mat rownames SCrowf`fci' = `scrow2'
mat roweq SCrowf`fci' = `scrow'
return mat SCcolf`fci' = SCcolf`fci'
return mat SCrowf`fci' = SCrowf`fci'
mat coleq Bmodf`fci' = ${mvldisp`mod2'$sfx}
mat roweq Bmodf`fci' = ${mvldisp`mod1'$sfx}
return mat scf`fci' = Bmodf`fci'
		}
	}

end
