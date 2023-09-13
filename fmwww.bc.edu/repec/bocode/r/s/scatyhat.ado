 *!  scatyhat.ado 	Version 5.3	RL Kaufman 	11/10/2018

***  	2.0 Create Scatterplots of Predicted Outcome. Called by OUTDISP.AD
***			New approach for DUAL axis option. Define 2nd axis values using estimation command specific transfrom from model to observed metirc & vice versa
***
***		2.1  Revised Regular & Main-added plots with code from dual axis plot. Single plots by MOD1 and/or MOD2 .  Fixed numeric non-integer label problem 
***		2.2  Dual option now labels outcome in y-standardized model metric 
***		3.0  Minor changes to work with mlogit
***		3.1  Fixed calc of prob for dual axis for mlogit 
***		3.2  New SDY option now labels outcome in y-standardized model metric w/ or w/o dual
***		4.0	 Superimposed MAIN effects on same plot instead of side by side
***		5.0	 Reverse role of fvar and mvar1 if fvar is categorical and mvar interval: Plot yhat by mvar1 with sepaarte liness for fvar values.
***		5.1  Fixed different line styles for interaction and superimposed main effects
***		5.2  Use min and max of fvrange (mvrange) to define added xaxis min & max instead of actual variable min and max
***		5.3	 Added 'tot' option for frequency plot of focal variable 

program scatyhat, rclass
version 14.2
syntax  ,  predint(varname) fvar(varname)  mvar1(varname)  [ mvar2(varname) mvar3(varname) mvar4(varname) mvar5(varname) mvar6(varname) ///
	predmn(varname)  estint(string) scatrev(string) /// 
	mlab2(string) mlab3(string) mlab4(string) mlab5(string) mlab6(string) dual(string) sdy(string) outmain(string)  frqmat(string) base(string) ///
	sing(string) ndig(integer 4) KEEP name(string) save(string) dvtxt(string) titxt(string) titxt2(string) titxt3(string) pantxt(string)  pltopts(string asis) ]
      
tempname   frqvsub  m1cat frqvar frqv savmat yhatint yhatmn
tempvar   upb lowb noeff bsig bymv2 pctfocal


qui {
***  set xvar and plvar (prediction line = pl) names & other attributes then reverse if scatrev==y
loc xvarnm "`fvar'"
loc xvrange "fvrange"
loc xvlab "fvlab"
loc xvldisp "fvldisp"
loc plvarnm "`mvar1'"
loc plvrange "mvrange1"
loc plvlab "mvlabm1"
loc plvldisp "mvldisp1"
if "`scatrev'" == "y" {
	loc xvarnm "`mvar1'"
	loc xvrange "mvrange1"
	loc xvlab "mvlabm1"
	loc xvldisp "mvldisp1"
	loc plvarnm "`fvar'"
	loc plvrange "fvrange"
	loc plvlab "fvlab"
	loc plvldisp "fvldisp"
}

***   Set # of rows/plot for saving plotdata, loop endpoint & values for m2 if exists
qui levelsof `xvarnm', loc(flevs)
loc npltrow: list sizeof flevs
loc mstp2=1
if ${mvarn$sfx} >1 { 
	qui levelsof `mvar2', loc(m2levs)
	loc mstp2: list sizeof m2levs 
}
*** Set Roman Numeral for Panel sub-title if Multiple Eqns or Ordered Prob
loc roman "I II III IV V VI VII VIII IX X"
loc panrom ""
if ${eqnum$sfx2} > 1 | "${ordcatnum$sfx2}" != "" {
	loc panrom: word ${eqinow$sfx2} of `roman'
	loc panrom "`panrom'."
}

*
**************************************************** Set up info for scatterplot needed with or without DUAL or OUTMAIN options
forvalues i=1/2 {
	loc sing`i' ""
	if "`sing'" == "`i'" | "`sing'" == "all" loc sing`i' "y"
}
loc grphcomb ""

loc foclabs ""

loc fstp: list sizeof global(`xvrange'$sfx)
forvalues fi=1/`fstp' {
	loc labnum: word `fi' of ${`xvrange'$sfx}
	loc foclabs "`foclabs' `labnum' "${`xvlab'c`fi'$sfx}" "
	if `fi' == 1 loc xfirst = `labnum'
	if `fi' == `fstp' loc xlast = `labnum'
}
*
est restore `estint'
qui summ `predint' if inrange(`xvarnm', `xfirst' , `xlast') , meanonly
loc yaxmin = r(min)
loc yaxmax = r(max)
loc ymin = r(min)-.05*(r(max)-r(min))
loc ymax = r(max)+.05*(r(max)-r(min))


loc xmin = `xfirst'-.05*(`xlast'-`xfirst')
loc xmax = `xlast'+.05*(`xlast'-`xfirst')

* set legend size
loc rsz = .7
qui levelsof(`plvarnm'), loc(mlev1)
loc m1num: list sizeof mlev1


separate `predint' if `predint'  <. , by(`plvarnm') gen(`yhatint') seq
loc mstp1: list sizeof global(`plvrange'$sfx)

forvalues m1=1/`m1num' {
	lab var `yhatint'`m1' "${`plvldisp'$sfx}=${`plvlab'c`m1'$sfx}"
}
*
if "`outmain'" != "" {
qui sum `predmn' if inrange(`xvarnm', `xfirst' , `xlast'), meanonly
	loc yaxmin=min(`yaxmin',r(min))
	loc yaxmax=max(`yaxmax',r(max))
}
defaxislab `yaxmin' `yaxmax' 3
numlist "`r(labvals)'"
loc yaxlab1 "`r(numlist)'"


*********Create scatterplot if neither DUAL nor OUTMAIN options specified *************************

if "`outmain'" == "" & "`dual'" == "" {


********************** One Moderator

if ${mvarn$sfx} == 1  {

if "`sing1'" != "y" ///
	scatter `yhatint'* `xvarnm' if inrange(`xvarnm' , `xfirst', `xlast') ,  name(`name', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
		lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
		lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
		scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) ylab( `yaxlab1', labsize(*1.2) nogrid)  ylab( `ymin' " " `ymax' " " , add tstyle(none) custom)  ///
		xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)   title("`titxt'" "`titxt2'.", size(*.85) m(b+2)) yti("`dvtxt'", m(r+2)) ///
		xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) ysize(6.5) xsize(5.5)  /// 
		leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst)  `pltopts'

if "`sing1'" == "y" {

	forvalues m1i=1/`m1num' {
		loc m1val: word `m1i' of `mlev1' 
		loc m1lab "${`plvlab'c`m1i'$sfx}"
		loc panadd1 "_`=substr("${`plvldisp'$sfx}",1,8)'`m1i'"
		
		scatter `yhatint'`m1i' `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') ,  name(`name'`panadd1', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
			lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
			lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
			scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) ylab( `yaxlab1', labsize(*1.2) nogrid)  ylab( `ymin' " " `ymax' " " , add tstyle(none) custom)  ///
			xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)   title("`titxt'" "`titxt2'.", size(*.85) m(b+2)) yti("`dvtxt'", m(r+2)) ///
			subti("${`plvldisp'$sfx} = `m1lab' (`m1val')", size(*1) pos(11) just(left) )  xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) ysize(6.5) xsize(5.5)  /// 
			leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst)  `pltopts'
	}
}
}  
*
********************** 2+ Moderators

if ${mvarn$sfx} > 1 {
	loc gnum=0
	loc subtxt ""
	loc xsz = 8
	loc ysz = 6.5 
	loc inc=2
	if "`sing2'" == "y" loc inc=1
	loc panadd2 ""
	
forvalues m2i=1(`inc')`mstp2' {
	loc m2end = `m2i'+1
	if `mstp2' - `m2i' == 2 {
		loc m2end = `mstp2' 
		loc xsz = 11.5
		loc ysz = 6.5 
	}
	if `inc' == 1 {
		loc m2end = `m2i' 
		loc xsz = 6.5
		loc ysz = 7.25 
	}
	loc if1: word `m2i' of `m2levs'
	loc if2: word `m2end' of `m2levs'
	loc ++ gnum
	
	capture drop `bymv2'
	gen `bymv2' =`mvar2' 
	loc lbl: value label `mvar2'
	lab val `bymv2' `lbl'
	replace `bymv2' = . if inrange(`mvar2',`if1',`if2')!=1

	if "`sing2'" == "y" loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`m2i'"
	if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `panrom'`=char(64+`gnum')' for ${mvldisp2$sfx}", pos(11) just(left) size(*.8))"'

	if "`sing1'" != "y" {
	
		scatter `yhatint'* `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') & inrange(`bymv2',`if1',`if2')==1, by(`mvar2' , rows(1) imarg(r+5) /// 
			title("`titxt'" "`titxt2'.", size(*.85) m(b+2)) `subtxt'  note("") )  subti( , size(*1))  /// 
			name(`name'_`=char(64+`gnum')'`panadd2', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
			lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
			lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
			scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2))  ylab( `yaxlab1', labsize(*1.2) nogrid)   ylab(`ymin' " " `ymax' " " , add tstyle(none) custom)  ///
			xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)    yti("`dvtxt'",  m(r+8) ) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) /// 
			leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst ) ///
			ysize(`ysz') xsize(`xsz')  `pltopts'
	}
	if "`sing1'" == "y" {
	
		forvalues m1i=1/`m1num' {
			loc m1val: word `m1i' of `mlev1' 
			loc m1lab "${`plvlab'c`m1i'$sfx}"
			loc subtxt `"subti("${`plvldisp'$sfx} = `m1lab' (`m1val')", pos(11) just(left) size(*1))"'
			if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `panrom'`=char(64+`gnum')' for ${mvldisp2$sfx}, ${`plvldisp'$sfx} = `m1lab' (`m1val')", pos(11) just(left) size(*.8))"'
			loc panadd1 "`=substr("${`plvldisp'$sfx}",1,4)'`m1i'"
			
			
			scatter `yhatint'`m1i' `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') & inrange(`mvar2',`if1',`if2')==1, by(`mvar2' , rows(1) imarg(r+5) /// 
				title("`titxt'" "`titxt2'.", size(*.85) m(b+2)) `subtxt'  note("") )   subti( , size(*.8)) /// 
				name(`name'_`=char(64+`gnum')'`panadd2'`panadd1', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
				lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
				lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
				scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2))  ylab( `yaxlab1', labsize(*1.2) nogrid)   ylab(`ymin' " " `ymax' " " , add tstyle(none) custom)  ///
				xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)    yti("`dvtxt'",  m(r+8) ) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) /// 
				leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst) ///
				ysize(`ysz') xsize(`xsz')  `pltopts'
		}
	}
	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 
}
}
}
*
*********Create scatterplot with OUTMAIN option : Superimposed main effect predicion **********************************************

if "`outmain'" != "" {

summ `predmn' if inrange(`xvarnm', `xfirst' , `xlast'), meanonly
loc ymin = min(`ymin',r(min)-.05*(r(max)-r(min)))
loc ymax = max(`ymax',r(max)+.05*(r(max)-r(min)))

loc yhattxt ""
separate `predmn' if `predmn'  <. & `predmn' < ., by(`plvarnm') gen(`yhatmn') seq


loc mstp1: list sizeof global(`plvrange'$sfx)
forvalues m1=1/`m1num' {
	lab var `yhatint'`m1' "${`plvldisp'$sfx}=${`plvlab'c`m1'$sfx}"
	lab var `yhatmn'`m1' "${`plvldisp'$sfx}=${`plvlab'c`m1'$sfx}"
	if "`sing1'" == "y" {
		lab var `yhatint'`m1' "Int:${`plvldisp'$sfx}=${`plvlab'c`m1'$sfx}"
		lab var `yhatmn'`m1' "Main:${`plvldisp'$sfx}=${`plvlab'c`m1'$sfx}"
	}
	loc yhattxt "`yhattxt' `yhatint'`m1' `yhatmn'`m1'"
}
*
********************** One Moderator

if ${mvarn$sfx} == 1  {

if "`sing1'" != "y" {

	scatter `yhatint'* `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') ,  name(`name'_int_main, replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
		lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
		lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
		scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) ylab( `yaxlab1', labsize(*1.2) nogrid)  ylab( `ymin' " " `ymax' " " , add tstyle(none) custom)  ///
		xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)   title("`titxt'" "`titxt2', Added Main Effects.", size(*.8) m(b+2)) yti("`dvtxt'", m(r+8)) ///
		xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) ysize(6.5) xsize(5.5)  /// 
		leg( subti("`dvtxt' by ${`xvldisp'$sfx} for" "Interactive                           Additive", /// 
		size(*`rsz')) cols(2) colfirst size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') marg(r+2) ) `pltopts' ///
	|| 	scatter `yhatmn'* `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') ,  conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
		lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
		lc(gs12 gs12 gs12 gs12 gs12 gs12 gs12 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs12) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
		 `pltopts'
	
}
if "`sing1'" == "y" {
	forvalues m1i=1/`m1num' {
		loc m1val: word `m1i' of `mlev1' 
		loc m1lab "${`plvlab'c`m1i'$sfx}"
		loc panadd1 "_${`plvldisp'$sfx}_`m1i'"
		
	scatter `yhatint'`m1i' `yhatmn'`m1i' `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') ,    title("`titxt'" "`titxt2'" "with Added Main Effect Predictions.", size(*.65) m(b+2)) /// 
		name(`name'`panadd1', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
		lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
		lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
		scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) ylab(`yaxlab1' , nogrid labsize(*1.2)) ylab( `ymin' " " `ymax' " " , add tstyle(none) custom)  ///
		xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)  yti("`dvtxt'", m(r+8)) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) ysize(6.5) xsize(5.5) /// 
		subti("${`plvldisp'$sfx} = `m1lab' (`m1val')", size(*.85) pos(11) just(left) )  /// 
		leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) rows(2) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst)  `pltopts'
	}
}

}  
*
********************** 2+ Moderators
 
if ${mvarn$sfx} > 1 {
	loc gnum=0
	loc subtxt ""
*	loc xsz = 9
*	loc ysz = 7.5
	loc xszhold=9
	loc yszhold=7.5
	loc yszadj=1
	if "`sing1'" != "y" loc yszadj=1.5
	loc inc=2
	if "`sing2'" == "y" loc inc=1
	loc panadd2 ""
	
forvalues m2i=1(`inc')`mstp2' {
	loc m2end = `m2i'+1
	if `mstp2' - `m2i' == 2 {
		loc m2end = `mstp2' 
		loc xszhold = 13.5
		loc yszhold  = 7.5 
	}
	if `inc' == 1 {
		loc m2end = `m2i' 
		loc xszhold  = 6.5
		loc yszhold  = 7.25 
	}
	loc if1: word `m2i' of `m2levs'
	loc if2: word `m2end' of `m2levs'
	loc ++ gnum
	
	if "`sing2'" == "y" loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`m2i'"
	if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `panrom'`=char(64+`gnum')' for ${mvldisp2$sfx}", pos(11) just(left) size(*.8))"'

	loc xsz = min(`xszhold'*`yszadj'^1.5, 20)
	loc ysz = `yszhold'*`yszadj' 
	if `xsz' == 20 loc ysz = `yszhold'*`yszadj'*20/(`xszhold'*`yszadj'^1.5)

	capture drop `bymv2'
	gen `bymv2' =`mvar2' 
	loc lbl: value label `mvar2'
	lab val `bymv2' `lbl'
	replace `bymv2' = . if inrange(`mvar2',`if1',`if2')!= 1
	
	
	if "`sing1'" != "y" {
		
		scatter `yhatint'* `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast')  , by(`bymv2' , rows(1) imarg(r+5) /// 
			title("`titxt'" "`titxt2'" "with Added Main Effect Predictions", size(*.65) m(b+2)) `subtxt'  note("") )  subti( , size(*1))  /// 
			name(`name'_int_`=char(64+`gnum')'`panadd2', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
			lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
			lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
			scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2))  ylab( `yaxlab1', labsize(*1.2) nogrid)   ylab(`ymin' " " `ymax' " " , add tstyle(none) custom)  ///
			xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)    yti("`dvtxt'",  m(r+2) ) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) /// 
			leg( tit("`dvtxt' by ${`xvldisp'$sfx} for" , size(*`rsz') ) subti("Interactive                       Additive", /// 
			size(*`rsz') justification(left) pos(12)) cols(2) colfirst size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1)) ysize(`ysz') xsize(`xsz') `pltopts' ///
		|| scatter `yhatmn'* `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast')  , by(`bymv2' , /// 
			 `subtxt'  note("") )  subti( , size(*.85))  /// 
			 conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
			lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
			lc(gs12 gs12 gs12 gs12 gs12 gs12 gs12 gs12 gs12 gs12 gs14 gs14 gs14 gs14 gs14) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
			 `pltopts'
	
	}
	
	if "`sing1'" == "y" {
	
		forvalues m1i=1/`m1num' {
		
			loc m1val: word `m1i' of `mlev1' 
			loc m1lab "${`plvlab'c`m1i'$sfx}"
			loc subtxt `"subti("${`plvldisp'$sfx} = `m1lab' (`m1val')", pos(11) just(left) size(*.85))"'
			if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `panrom'`=char(64+`gnum')' for ${mvldisp2$sfx}, ${`plvldisp'$sfx} = `m1lab' (`m1val')", pos(11) just(left) size(*.8))"'
			loc panadd1 "`=substr("${`plvldisp'$sfx}",1,4)'`m1i'"

			scatter `yhatint'`m1i' `yhatmn'`m1i'  `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') & inrange(`mvar2',`if1',`if2')==1, by(`mvar2' , rows(1) imarg(r+5) /// 
				title("`titxt'" "`titxt2'" "with Added Main Effect Predictions.", size(*.65) m(b+2)) /// 
				`subtxt'  note("" , ring(0) pos(3) orient(rvertical)) )    subti( , size(*.85)) /// 
				name(`name'_`=char(64+`gnum')'`panadd2'`panadd1', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
				lp(solid solid dash  dash longdash longdash shortdash shortdash tight_dot tight_dot "_...." "_...." "--...." "--...." "_..-.." "_..-.." ) /// 
				lc(gs0 gs9 gs0 gs7 gs0 gs7 gs0 gs7 gs0 gs7 gs0 gs7 gs0 gs7 gs0 gs7 ) lw(*1.25 *1 *1.25 *1 *1.25 *1 *1.25 *1 *1.25 *1 *1.25 *1 *1.25 *1 *1.25 *1) /// 
				scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) ylab( `yaxlab1', labsize(*1.2) nogrid) ylab( `ymin' " " `ymax' " " , add tstyle(none) custom) ///
				xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)    yti("`dvtxt'", m(r+8) )  xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) /// 
				leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst) ///
				ysize(`ysz') xsize(`xsz')  `pltopts'
		}
	}	
	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break  
}
}

}
*
*********Create scatterplot with DUAL option **********************************************

if "`dual'" != "" {

***  Set up labels for model metric axis and obs metric dual axis
est restore `estint'
sum `predint' if inrange(`xvarnm', `xfirst' , `xlast'), meanonly
defaxislab `r(min)' `r(max)' 3
numlist "`r(labvals)'"
loc yaxlab1 "`r(numlist)'"
loc ylstp: list sizeof yaxlab1

loc vmin: word 1 of `yaxlab1'
loc v2: word 2 of `yaxlab1'
loc v3: word 3 of `yaxlab1'
loc vmax: word `ylstp' of `yaxlab1'

*** If user added y-axis labels, use their min & max 
if "${ypredmin$sfx}" != "" {
	loc vmin = ${ypredmin$sfx}
	loc vmax = ${ypredmax$sfx}
}

loc vminhold =`vmin'
loc vmaxhold =`vmax'

*** if SDY option reset predy1 min & max back to unstandardized to get dual axis label values
if "`sdy'" != "" {
	loc vmin = `vmin'*${ystd$sfx}+ ${ymn$sfx}
	loc vmax = `vmax'*${ystd$sfx}+ ${ymn$sfx}
}


defdualaxislab `vmin' `vmax' 3 `ndig'
loc yaxlab2 `"`r(labdual)'"'

********************** One Moderator

if ${mvarn$sfx} == 1  {

if "`sing1'" != "y"  ///
	scatter `yhatint'* `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') ,  name(`name', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
		lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
		lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
		scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) yaxis(1 2) ylab(`yaxlab1', labsize(*1.2) axis(1) format(%8.`ndig'g) nogrid angle(45))  /// 
		ylab(`ymin' " " `ymax' " " , add axis(1) tstyle(none) custom) ylab(`yaxlab2' , axis(2) grid gmin gmax angle(-45) glp(shortdash) glc(gs9) glw(*.6) labsize(*1.2) ) ///
		xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)   title("`titxt'" "`titxt2', Dual Outcome Axes.", size(*.8) m(b+2)) yti("`dvtxt'" , m(r+8)) ///
		yti("${dvname$sfx}" , axis(2) m(r+2) orient(rvertical)) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) ysize(5.5) xsize(5.5) /// 
		leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst )  `pltopts'

if "`sing1'" == "y" {

	forvalues m1i=1/`m1num' {
		loc m1val: word `m1i' of `mlev1' 
		loc m1lab "${`plvlab'c`m1i'$sfx}"
		loc panadd1 "_${`plvldisp'$sfx}_`m1i'"
	
	scatter `yhatint'`m1i' `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') ,  name(`name'`panadd1', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
		lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
		lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
		scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) yaxis(1 2) ylab(`yaxlab1', labsize(*1.2) axis(1) format(%8.`ndig'g) nogrid angle(45))  /// 
		ylab(`ymin' " " `ymax' " " , add axis(1) tstyle(none) custom) ylab(`yaxlab2' , axis(2) grid gmin gmax angle(-45) glp(shortdash) glc(gs9) glw(*.6) labsize(*1.2) ) ///
		xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)   title("`titxt'" "`titxt2', Dual Outcome Axes.", size(*.8) m(b+2)) yti("`dvtxt'" , m(r+8)) ///
		yti("${dvname$sfx}" , axis(2) m(r+2) orient(rvertical)) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) ysize(5.5) xsize(5.5) /// 
		subti("${`plvldisp'$sfx} = `m1lab' (`m1val')", size(*.85) pos(11) just(left) ) /// 
		leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz')) size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz')margin(r+1 l+1) colfirst ) 	 `pltopts'	
	} 
} 
}
*
********************** 2+ Moderators

if ${mvarn$sfx} > 1 {
	loc gnum=0
	loc subtxt ""
	loc xsz = 8
	loc ysz = 6.5 
	loc inc=2
	if "`sing2'" == "y" loc inc=1
	loc panadd2 ""
	
forvalues m2i=1(`inc')`mstp2' {
	loc m2end = `m2i'+1
	if `mstp2' - `m2i' == 2 {
		loc m2end = `mstp2' 
		loc xsz = 12
		loc ysz = 7.25 
	}
	if `inc' == 1 {
		loc m2end = `m2i' 
		loc xsz = 6.5
		loc ysz = 7.25 
	}
	loc if1: word `m2i' of `m2levs'
	loc if2: word `m2end' of `m2levs'
	loc ++ gnum
	
	capture drop `bymv2'
	gen `bymv2' =`mvar2' 
	loc lbl: value label `mvar2'
	lab val `bymv2' `lbl'
	replace `bymv2' = . if inrange(`mvar2',`if1',`if2')!=1

	if "`sing2'" == "y" loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`m2i'"
	if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `panrom'`=char(64+`gnum')' for ${mvldisp2$sfx}", pos(11) just(left) size(*.8))"'
	
	if "`sing1'" != "y" {

		scatter `yhatint'* `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') & inrange(`bymv2',`if1',`if2')==1, by(`mvar2' , rows(1) imarg(r+5) /// 
			title("`titxt'" "`titxt2', with Dual Outcome Axes.", size(*.85) m(b+2)) /// 
			`subtxt'  note("${dvname$sfx}" , ring(0) pos(3) orient(rvertical)) )   subti( , size(*.85)) subti("${mvldisp2$sfx} = ", prefix size(*.85)) /// 
			name(`name'_`=char(64+`gnum')'`panadd2', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
			lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
			lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
			scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) yaxis(1 2) ylab(`yaxlab1', labsize(*1.2) axis(1) format(%8.`ndig'g) nogrid angle(45))  /// 
			ylab(`ymin' " " `ymax' " " , add axis(1) tstyle(none) custom)  ylab(`yaxlab2' , axis(2) grid gmin gmax angle(-45) glp(shortdash) glc(gs9) glw(*.6) labsize(*1.2) ) ///
			xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)    yti("`dvtxt'", axis(1) m(r+2) ) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) /// 
			leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz'))  size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst) ///
			ysize(`ysz') xsize(`xsz')  `pltopts'
				
		if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 
	}
	
	if "`sing1'" == "y" {
	
		forvalues m1i=1/`m1num' {
		
			loc m1val: word `m1i' of `mlev1' 
			loc m1lab "${`plvlab'c`m1i'$sfx}"
			loc subtxt `"subti("${`plvldisp'$sfx} = `m1lab' (`m1val')", pos(11) just(left) size(*.8))"'
			if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `panrom'`=char(64+`gnum')' for ${mvldisp2$sfx}, ${`plvldisp'$sfx} = `m1lab' (`m1val')", pos(11) just(left) size(*.8))"'
			loc panadd1 "`=substr("${`plvldisp'$sfx}",1,4)'`m1i'"
			
		scatter `yhatint'`m1i' `xvarnm' if inrange(`xvarnm', `xfirst' , `xlast') & inrange(`mvar2',`if1',`if2')==1, by(`mvar2' , rows(1) imarg(r+5) /// 
			title("`titxt'" "`titxt2', with Dual Outcome Axes.", size(*.85) m(b+2)) /// 
			`subtxt'  note("${dvname$sfx}" , ring(0) pos(3) orient(rvertical)) )   subti( , size(*.85)) /// 
			name(`name'_`=char(64+`gnum')'`panadd2'`panadd1', replace) conn(l l l l l l l l l l l l l l l) ms(i i i i i i i i i i i i i i i) /// 
			lp(solid dash longdash shortdash  tight_dot "_...." "--...." "_..-.." "--...__" "..---..") /// 
			lc(gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs0 gs7 gs7 gs7 gs7 gs7) lw(*1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1.25 *1 *1 *1 *1 *1 *1 *1 *1 .25) ///
			scheme(s1mono) graphreg(c(white))  xlab(`foclabs' , labsize(*1.2)) yaxis(1 2) ylab(`yaxlab1', labsize(*1.2) axis(1) format(%8.`ndig'g) nogrid angle(45))  /// 
			ylab(`ymin' " " `ymax' " " , add axis(1) tstyle(none) custom)  ylab(`yaxlab2' , axis(2) grid gmin gmax angle(-45) glp(shortdash) glc(gs9) glw(*.6) labsize(*1.2) ) ///
			xlab( `xmin' " " `xmax' " " , add tstyle(none) custom)    yti("`dvtxt'", axis(1) m(r+2) ) xtit("${`xvldisp'$sfx}", bm(t=0 b+5) m(t+1 b+3)) /// 
			leg( subti("`dvtxt' by ${`xvldisp'$sfx} for", size(*`rsz'))  size(*`rsz') keyg(*`rsz') symy(*`rsz') symx(*`rsz') colg(*`rsz') margin(r+1 l+1) colfirst) ///
			ysize(`ysz') xsize(`xsz')  `pltopts'
		}
	}
	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 
}
}
}

***	create freq distn vars & plot if requested.  

if "`base'" != "" {
	loc vnm: coln `frqmat'
	loc cnum=colsof(`frqmat')-1
	loc cnm ""
	forvalues j=1/`cnum' {
		loc nm: word `j' of `vnm'
		loc cnm "`cnm' `frqv'`=strtoname("`nm'")' "
	}
	loc cnm "`cnm' `frqv'focalcat "
	mat colnames `frqmat' = `cnm'
	svmat `frqmat' , names(col)
	mat `frqvar'= `frqmat'[.,1..`cnum']
	mata: fmat=st_matrix("`frqvar'"); fsum= sum(fmat); fmax= max(fmat); fsumcol = colsum(fmat); fmaxcol= colmax(fmat); fsumrow = rowsum(fmat); fmaxrow= max(fsumrow); st_numscalar("fsum",fsum); st_numscalar("fmax",fmax); st_matrix("fsumcol",fsumcol); st_matrix("fmaxcol",fmaxcol); st_matrix("fsumrow",fsumrow); st_numscalar("fmaxrow",fmaxrow);

if "`base'" == "tot" {
	loc rnum=rowsof(`frqmat')
	gen `pctfocal'=. in 1/`rnum' 
	forvalues ffi=1/`rnum' {
		replace `pctfocal' = el("fsumrow",`ffi', 1)/fsum*100 in `ffi' 
	}
	loc ypctmax= round(fmaxrow/fsum*100+.5)
	loc titcomb "Relative Frequency of ${`xvldisp'$sfx}"
	}
forvalues m1=1/`cnum' {

	if "`base'" == "subtot" {
		loc vv: word `m1' of `cnm'
		replace `vv' = `vv'/fsum*100 if `vv'<. 	
		loc ypctmax= round(fmax/fsum*100+.5)
		loc titcomb `""Relative Frequency of ${`xvldisp'$sfx}"  "by ${`plvldisp'$sfx} Combinations""'
	}
	
	if "`base'" == "sub" {
		mat `frqvsub'=`frqvar'[.,`m1'..`m1']
		loc vv: word `m1' of `cnm'		
		replace `vv' = `vv'/el("fsumcol",1,`m1')*100 if `vv'<. 
		loc ypctmax= 0
		forvalues j=1/`cnum' {
			if (el("fmaxcol",1,`j')/el("fsumcol",1,`j'))*100 > `ypctmax' loc ypctmax = round(el("fmaxcol",1,`j')/el("fsumcol",1,`j')*100+.5)
		}
		loc titcomb `""Relative Frequency of ${`xvldisp'$sfx}"  "within ${`plvldisp'$sfx} Subsamples""'	
	}
}
loc ylabmid = round(`ypctmax'/2+.5)
loc ylabmax = 2*`ylabmid'
loc combfrq ""

if "`base'" == "tot" {
	tw spike `pctfocal' `frqv'focalcat ,  ysca( r(0) ) scheme(s1mono)  xlabel(`foclabs' , labsize(*1.2)) fysize(70) fxsize(50) /// 
		lc(black) lw(*5) graphregion(margin(l+2 r+2 b=0 t=0) style(none)) ylab(0 `ylabmid' `ylabmax', labsize(*1.2))  ytitle("Pct", size(*1) margin(r+2)) ///
		xtitle("${`xvldisp'$sfx}", size(*1) m(t+2)) plotr(m(tiny) style(none)) name(`name'Freq, replace) ///
		title("`titcomb'", pos(11) size(*.85) m(b+2)) 
}

if "`base'" != "tot" {
forvalues m1=1/`cnum' {
	loc vv: word `m1' of `cnm'
	
	if `m1' != `cnum' & "`sing'" == "" ///
		tw spike `vv' `frqv'focalcat ,  ysca( r(0) ) scheme(s1mono)  xlabel(${fmin$sfx} " " , tlc(white) labsize(*1.2)) fysize(70) fxsize(50) nodraw  /// 
			lc(black) lw(*5) graphregion(margin(l+2 r+2 b=0 t=0) style(none)) ylab(0 `ylabmid' `ylabmax', labsize(*1.2))  ytitle("Pct", size(*1.2) margin(r+2)) ///
			xtitle(" ", size(*1) m(t+2)) plotr(m(tiny) style(none)) name(frqhold`m1'$sfx, replace) /// 
			title("${`plvldisp'$sfx} = ${`plvlab'c`m1'$sfx}", pos(11) size(*.85) m(b+2)) 
			
	if `m1' == `cnum' | "`sing'" != "" ///
		tw spike `vv' `frqv'focalcat ,  ysca( r(0) ) scheme(s1mono)  xlabel(`foclabs' , labsize(*1.2)) fysize(70) fxsize(50) nodraw  /// 
			lc(black) lw(*5) graphregion(margin(l+2 r+2 b=0 t=0) style(none)) ylab(0 `ylabmid' `ylabmax', labsize(*1.2))  ytitle("Pct", size(*1) margin(r+2)) ///
			xtitle("${`xvldisp'$sfx}", size(*1) m(t+2)) plotr(m(tiny) style(none)) name(frqhold`m1'$sfx, replace) ///
			title("${`plvldisp'$sfx} = ${`plvlab'c`m1'$sfx}", pos(11) size(*.85) m(b+2)) 
			
loc combfrq "`combfrq' frqhold`m1'$sfx"	  
}

graph combine`combfrq' , cols(1) ycommon xcommon graphreg(c(white)) iscale(*1.1)  /// 
	title(`titcomb', size(*.85) m(b+2)) ysize(8) xsize(6) name(`name'Freq, replace)
}
}
**
 est restore `estint'
 
  
if "`save'" != "" {
	if "${frevcode$sfx}" != "" recode `xvarnm' ${frevcode$sfx} 
	if "${m1revcode$sfx}" != "" recode `plvarnm' ${m1revcode$sfx} 
	if "${m2revcode$sfx}" != "" recode `mvar2' ${m2revcode$sfx} 
	glo plotnum$sfx = ${plotnum$sfx}+1
	loc rownum=2 + `npltrow'*(${plotnum$sfx}-1)
	qui levelsof(`plvarnm'), loc(mlev1)
	loc m1num: list sizeof mlev1
	loc m3txt ""
	if ${mvarn$sfx} > 2	{ 
		forvalues mi=3/`mstp' {
			loc m3txt "`m3txt'   ${mvldisp`mi'$sfx} = `mlab`mi''" 
		}
	}
	putexcel set "`save'" , sheet(plotdata_${eqnow$sfx2}) modify
	mata: b=xl();b.load_book("`save'"); b.set_sheet("plotdata_${eqnow$sfx2}"); b.set_text_wrap(2,2,"on"); b.set_column_width(2,2,40)
	
	forvalues m2i=1/`mstp2' {
		loc m2txt ""
		if ${mvarn$sfx} > 1 { 
				loc mval2: word `m2i' of `m2levs'
				loc m2txt ", Separate plot for ${mvldisp2$sfx} = ${mvlabm2c`m2i'$sfx} (`mval2')" 
		}
		putexcel B`=`rownum'+`m1num'*`npltrow'*(`m2i'-1)' = "Plot Name = `name'  `m2txt'" B`=`rownum'+`m1num'*(`m2i'-1)+1' = "`m3txt'" , txtwrap
		}
		
	loc cadd = 1
	if "`outmain'" != "" loc cadd=2
	loc vartxt ""
	loc mvi=0
	
	forvalues m1i=1(`cadd')`=`cadd'*`m1num'' {
		loc ++mvi
		loc mval1: word `mvi' of `mlev1'
		loc vartxt`"`vartxt' `=char(66+`m1i')'1 = "yhatint${`plvldisp'$sfx}`mval1'" "'
		if "`outmain'" != "" loc vartxt `"`vartxt' `=char(66+`m1i' +1)'1 = "yhatmain${`plvldisp'$sfx}`mval1'" "'
	}
	loc vartxt `"`vartxt' `=char(66+`cadd'*`m1num'+1)'1 = "${`xvldisp'$sfx}" `=char(66+`cadd'*`m1num'+2)'1 = "${`plvldisp'$sfx}" `=char(66+`cadd'*`m1num'+3)'1 = "${mvldisp2$sfx}" "'
	if ${plotnum$sfx} == 1	 putexcel `vartxt'
	if "`outmain'" == "" mkmat `yhatint'* `xvarnm' `plvarnm' `mvar2' if `xvarnm' < ., mat(`savmat')
	if "`outmain'" != "" mkmat `yhattxt' `xvarnm' `plvarnm' `mvar2' if `xvarnm' < ., mat(`savmat')
	loc skey3 ""
	if ${mvarn$sfx}>1 loc skey3 "`=3+`cadd'*`m1num'',"
	mata: msrt = st_matrix("`savmat'"); msrt=sort(msrt,(`skey3'`=2+`cadd'*`m1num'',`=1+`cadd'*`m1num'')); st_matrix("`savmat'",msrt)
	putexcel C`rownum'= mat(`savmat') 
}
*
 
/* CODE FROM OTHER ADOS  FOR COMBINING PLOTS.  KEEP FOR LATER ADDING FUNCTIONALITY FOR MORE MVARS

 if "`mvar3'" != ""  loc grphcomb "`grphcomb' `name'"

*** Close m2 loop	
}
*
if ${fcnum$sfx} > 1 & ${mvarn$sfx} == 1 glo grnames$sfx "${grnames$sfx} `name'"

if "`m2var'" != "" {
if `mstp2' > 3 | ${fcnum$sfx} > 1 | "`m3var'" != "" glo pannum$sfx = ${pannum$sfx} + 1
loc fvtxt "${fvldisp$sfx}"
if ${fcnum$sfx} > 1 loc fvtxt "${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx}"
loc combti `"`cipct'% Confidence Bounds for Effect of `fvtxt'" "Moderated by `titxtcomb'"'
loc combleg `""  - - - -    Upper Bound" " " "  ——    Effect of `legefftxt'" " " "  - - - -    Lower Bound""'
plotcomb , grphcomb(`grphcomb') title(`combti') grname(`name'`gnmtxt') legend(`combleg') plttype(cbound)
}
*/
*if "`keep'" != "keep" & "`grphcomb'" != "" graph  drop `grphcomb'


capture: if "`keep'" != "keep" & "`base'" != ""  graph  drop frqhold*
}
end
