*!  baryhat.ado 	Version 2.4		RL Kaufman 	11/10/2018

***  	1.0 Create Bar Charts of Predicted Outcome. Called by OUTDISP.ADO'
***				Adapted from SCATYHAT.ADO 
***		1.1 Dual option now labels outcome in y-standardized model metric 
***		2.0  Minor changes to work with mlogit
***		2.1  Fixed calc of prob for dual axis for mlogit 
***		2.2  New SDY option now labels outcome in y-standardized model metric w/ or w/o dual
***		2.3  Fix x-axis title placement for 2+ moderators 
***		2.4  Adjust & re- x-axis title placement for 2+ moderators 
***		2.5	 Added 'tot' option for frequency plot of focal variable 


program baryhat, rclass
version 14.2
syntax  ,  predint(varname) fvar(varname)  mvar1(varname)  [ mvar2(varname) mvar3(varname) mvar4(varname) mvar5(varname) mvar6(varname) ///
	predmn(varname)  estint(string)  /// 
	mlab2(string) mlab3(string) mlab4(string) mlab5(string) mlab6(string) dual(string) sdy(string) outmain(string)  frqmat(string) base(string) ///
	sing(string) ndig(integer 4) KEEP name(string) save(string) dvtxt(string) titxt(string) titxt2(string) pantxt(string) blabopts(string asis) pltopts(string asis) ]
      
tempname   frqvsub  m1cat frqvar frqv savmat yhatint yhatmn
tempvar   holdspot pctfocal

qui {

***   Set # of rows/plot for saving plotdata, loop endpoint & values/labels for focal ankd mods
loc blabtxt "`blabopts' format("%6.`ndig'f")"
loc lsz "medsmall"
if ${mvarn$sfx} ==1 loc lsz "medium"
if "`blabopts'" == "" loc blabtxt " size(`lsz') orient(vertical) format("%6.`ndig'f")"

levelsof `fvar', loc(flevs)
loc npltrow : list sizeof flevs
loc foclabs ""
loc fstp : list sizeof flevs 
forvalues fi=1/`fstp' {
	loc labnum: word `fi' of `flevs'
	loc foclabs `"`foclabs' `labnum' "${fvlabc`fi'$sfx}" "'
}
lab def fvlab$sfx `foclabs' , replace
lab val `fvar' fvlab$sfx

loc mstp = ${mvarn$sfx}
forvalues mi=1/6 {
	loc modlabs ""
	loc mstp`mi' = 1
	if `mi' < = ${mvarn$sfx} {
		levelsof `mvar`mi'', loc(mlevs`mi')
		loc mstp`mi' : list sizeof mlevs`mi'
		forvalues mmi=1/`mstp`mi'' {
			loc labnum : word `mmi' of `mlevs`mi''
			loc modlabs `"`modlabs' `labnum' "${mvlabm`mi'c`mmi'$sfx}" "'
		}
		lab def mvlab`mi'$sfx `modlabs', replace
		lab val `mvar`mi'' mvlab`mi'$sfx
	}
}
*
**************************************************** Set up info for bar chart needed with or without DUAL or OUTMAIN options
loc ysz =6.5
loc xsz = min(2+`fstp'*`mstp1'*1.15,20)
forvalues i=1/2 {
	loc sing`i' ""
	if "`sing'" == "`i'" | "`sing'" == "all" loc sing`i' "y"
}
loc grphcomb ""

*
est restore `estint'
summ `predint', meanonly
loc yaxmin = min(0, r(min))
loc yaxmax = max(0, r(max))
loc yminadj = 2
loc ymaxadj = 1
if ${mvarn$sfx} > 1 {
	loc yminadj = 5
}
*if `yaxmin' < 0 loc yminadj = 2
*if `yaxmax' <= 0 loc ymaxadj = 1.5

* set legend size
loc rsz = .7

*
if "`outmain'" != "" {
 sum `predmn' , meanonly
	loc yaxmin=min(`yaxmin',r(min))
	loc yaxmax=max(`yaxmax',r(max))
}
defaxislab `yaxmin' `yaxmax' 4

numlist "`r(labvals)'"
loc yaxlab1 "`r(numlist)'"
loc ylstp : list sizeof yaxlab1

loc yymin : word 1 of `yaxlab1'
loc yymax : word `ylstp' of `yaxlab1'

loc yaxmin = `yymin' -.05*(`yymax' - `yymin')
loc yaxmax = `yymax' +.05*(`yymax' - `yymin')

loc ymin = `yaxmin' - (`yaxmax' -`yaxmin' )*.08*`yminadj'
loc ymin2 = `yaxmin' - (`yaxmax' -`yaxmin' )*.05*`yminadj'
loc ymax = `yaxmax' + (`yaxmax' -`yaxmin' ) *.08*`ymaxadj'


*********Create regular bar chart if neither DUAL or OUTMAIN options specified *******************************

if "`outmain'" == "" & "`dual'" == "" {

********************** One Moderator

if ${mvarn$sfx} == 1  {

	graph bar `predint' if `fvar' < . , over(`fvar') over(`mvar1', gap(*1.5) label(labsize(*1.2) ) )  name(`name', replace) asyvars subtitle(, size(*1.1) fc(gs14))  /// 
		bar(1, color(gs0) lc(gs0) ) bar(2, color(gs9) lc(gs0)) bar(3, color(gs6) lc(gs0)) bar(4, color(gs11) lc(gs0)) bar(5, color(gs8) lc(gs0)) ///
		bar(6, color(gs13) lc(gs0) ) bar(7, color(gs10) lc(gs0)) bar(8, color(gs15) lc(gs0)) bar(9, color(gs12) lc(gs0)) bar(10, color(gs16) lc(gs0)) intensity(*.75) ///
		leg(title("Predicted `dvtxt' by {it:${fvldisp$sfx}}", size(*1)) bm(t+2) rows(1) rowgap(*2) size(*1) symy(*1.4) symx(*.1755) ) ///
		ytitle("`dvtxt'", ma(r+2) size(*1.2)) scheme(s1mono) xsize(`xsz') ysize(`ysz') plotregion(margin(t+2))  blabel(bar, `blabtxt')  bargap(*1.2) ///
		ylab( `yaxlab1', labsize(*1.2) nogrid) ylab( `yaxmin' " " `yaxmax' " " , add tstyle(none) custom)  ///
		title("`titxt'" "`titxt2'.", size(*1) m(b+2)) plotreg(marg(b+2)) graphreg(marg(l+10 r+15))  ///
		text( `ymin' -2 "{it:${mvldisp1$sfx}}", size(*1.2) place(west) j(left) )   `pltopts'

	barxlinedraw mod1 "`name'"  `mstp1' 1
}	   
*
********************** 2+ Moderators

if ${mvarn$sfx} > 1 {
	loc gnum=0
	loc panbytxt ""
	loc xsz = 8
	loc ysz = 6.5 
	loc inc=2
	loc subtxt `"  subti( , size(*1)) "'
	loc subtxtby "{it:${mvldisp2$sfx}}"
	loc notit ""
	if "`sing2'" == "y" {
		loc inc=1
		loc subtxtby ""
		loc notit `"titl("") "'
	}
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
	loc if1 : word `m2i' of `mlevs2'
	loc if2 : word `m2end' of `mlevs2'
	loc ++ gnum
	if "`sing2'" == "y" {
		loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`if1'"
		loc subtxt `"subti("{it:${mvldisp2$sfx}} = ${mvlabm2c`m2i'$sfx}" , size(*1))  "'
	}
	if `mstp2' > 3 & "`sing2'" != "y" loc panbytxt `"note("Panel `=char(64+`gnum')' for ${mvldisp2$sfx}", pos(11) just(left) size(small))"'
	
	graph bar `predint' if `fvar' < . & inrange(`mvar2',`if1',`if2')==1, over(`fvar') over(`mvar1', gap(*1.25) label(labsize(*1.2) labgap(*1.5) angle(25))) ///
		by(`mvar2' , rows(1) title("`titxt'" "`titxt2'.", size(*.9) m(b+1))  `notit' `panbytxt' subti("`subtxtby'", size(*.9)) /// 
		note("")  )  /// 
		name(`name'_`=char(64+`gnum')'`panadd2', replace) asyvars subtitle(, size(*1) fc(gs14))  /// 
		bar(1, color(gs0) lc(gs0) ) bar(2, color(gs9) lc(gs0)) bar(3, color(gs6) lc(gs0)) bar(4, color(gs11) lc(gs0)) bar(5, color(gs8) lc(gs0)) ///
		bar(6, color(gs13) lc(gs0) ) bar(7, color(gs10) lc(gs0)) bar(8, color(gs15) lc(gs0)) bar(9, color(gs12) lc(gs0)) bar(10, color(gs16) lc(gs0)) intensity(*.75) ///
		leg(title("Predicted `dvtxt' by {it:${fvldisp$sfx}}", size(*.9)) bm(t+3) rows(1) rowgap(*2) size(*.95) symy(*1.4) symx(*.1755) ) ///
		ytitle("`dvtxt'", ma(r+2)) scheme(s1mono) plotregion(margin(t+2))  blabel(bar, `blabtxt')  bargap(*1.2) ///
		ylab( `yaxlab1', labsize(*1.2) nogrid) ylab( `yaxmin' " " `yaxmax' " " , add tstyle(none) custom)  ///
		 plotreg(marg(b+2)) graphreg(marg(l+10 r+15)) text( `ymin2' 50 "{it:${mvldisp1$sfx}}", size(*1.2) )  `subtxt'   `pltopts'

	if "`sing2'" != "y" barxlinedraw barby "`name'_`=char(64+`gnum')'`panadd2'"  `mstp1' `=`m2end'-`m2i'+1'
	if "`sing2'" == "y" barxlinedraw single "`name'_`=char(64+`gnum')'`panadd2'"   `mstp1' 1
*	
	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 
}
}
}
*
*********Create bar chart with OUTMAIN option **********************************************

if "`outmain'" != "" {

separate `predint' if `predint'  <. , by(`fvar') gen(`yhatint')
separate `predmn' if `predmn'  <. , by(`fvar') gen(`yhatmn')
gen `holdspot' = .

*loc mstp1 : list sizeof global(mvrange1$sfx)
loc legtxt1 `" - "Interactive: ${fvldisp$sfx} =" "'
loc legtxt2 `" - "Additive:  ${fvldisp$sfx} =" "'
loc yhattxt1 ""
loc yhattxt2 ""
loc bartxt ""

forvalues fi=1/`fstp' {
	loc labnum : word `fi' of `flevs'
	loc legtxt1 `" `legtxt1' `fi' "${fvlabc`fi'$sfx}" "'
	loc legtxt2 `" `legtxt2' `=`fi'+`fstp'+1' "${fvlabc`fi'$sfx}" "'
	loc yhattxt1 "`yhattxt1' `yhatint'`labnum' "
	loc yhattxt2 "`yhattxt2' `yhatmn'`labnum' "
	loc gsn : word `fi' of ${gslist$sfx}
	loc bartxt " `bartxt' bar(`fi' , color(gs`gsn') lc(gs0)) bar(`=`fi'+`fstp'+1' , color(gs`gsn') lc(gs0) lp(shortdash)) "
}
*
********************** One Moderator

if ${mvarn$sfx} == 1  {

	graph bar `yhattxt1' `holdspot' `yhattxt2'  if `fvar' < . ,  over(`mvar1', gap(*1.5) label(labsize(*1.2) ) )  name(`name', replace) subtitle(, size(*1.1) fc(gs14))  /// 
		`bartxt'  intensity(*.75) ///
		leg( bm(t+2) order( `legtxt1' `legtxt2' ) rows(2)  rowgap(*1) size(*1) symy(*1.4) symx(*.1755) title("Predicted `dvtxt' by {it:${fvldisp$sfx}}", size(*.8))) ///
		ytitle("`dvtxt'", ma(r+4) size(*1.2) ) scheme(s1mono) xsize(`xsz') ysize(`ysz') plotregion(margin(t+2))  blabel(bar, `blabtxt')   ///
		ylab( `yaxlab1', labsize(*1.2) nogrid) ylab( `yaxmin' " " `yaxmax' " " , add tstyle(none) custom)  ///
		title("`titxt'" "`titxt2', Interaction and Additive Models.", size(*.8) m(b+2)) plotreg(marg(b+2) /* ilc(black) */) graphreg(marg(l+2 r+2))  ///
		text( `ymin' -2 "{it:${mvldisp1$sfx}}", size(*1.2) place(west) j(left) )   `pltopts'
		
	barxlinedraw mod1 "`name'"  `mstp1' 1
}  
*
*
********************** 2+ Moderators*****

if ${mvarn$sfx} > 1 {
	loc ymin2 = `yaxmin' - (`yaxmax' -`yaxmin' )*.05*`yminadj'
	loc gnum=0
	loc panbytxt ""
	loc xsz = 9
	loc ysz = 8
	loc inc=2
	loc subtxt " subti( , size(*1)) "
	loc subtxtby "{it:${mvldisp2$sfx}}"
	loc notit ""
	if "`sing2'" == "y" {
		loc inc=1
		loc subtxtby ""
		loc notit `"titl("") "'
	}
	loc panadd2 ""
forvalues m2i=1(`inc')`mstp2' {
	loc m2end = `m2i'+1
	if `mstp2' - `m2i' == 2 {
		loc m2end = `mstp2' 
		loc xsz = 12.5
		loc ysz = 8
	}
	if `inc' == 1 {
		loc m2end = `m2i' 
		loc xsz = 9.5
		loc ysz = 7.25 
	}
	loc if1 : word `m2i' of `mlevs2'
	loc if2 : word `m2end' of `mlevs2'
	loc ++ gnum
	if "`sing2'" == "y" {
		loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`if1'"
		loc subtxt `" subti("{it:${mvldisp2$sfx}} = ${mvlabm2c`m2i'$sfx}" , size(*1)) "'
	}
	if `mstp2' > 3 & "`sing2'" != "y" loc panbytxt `"note("Panel `=char(64+`gnum')' for ${mvldisp2$sfx}", pos(11) just(left) size(*.9))"'
	
	graph bar `yhattxt1' `holdspot' `yhattxt2'  if `fvar' < . & inrange(`mvar2',`if1',`if2')==1, over(`mvar1', gap(*1.5) label(labsize(*1.2) labgap(*1.5) angle(25))) ///
		by(`mvar2' , rows(1) title("`titxt'" "`titxt2', Interaction and Additive Models.", size(*.8) m(b+2))  `notit' `panbytxt' subti("`subtxtby'", size(*.9)) /// 
		note("") ) /// 
		name(`name'_`=char(64+`gnum')'`panadd2', replace) asyvars subtitle(, size(*1) fc(gs14))  /// 
		`bartxt' intensity(*.75) ///
		leg( bm(t+4) order( `legtxt1' `legtxt2' ) rows(2)  rowgap(*.8) size(*.7) symy(*1) symx(*.1254) /// 
		title("Predicted `dvtxt' by {it:${fvldisp$sfx}}", size(*.65))) ///
		ytitle("`dvtxt'", ma(r+2)) scheme(s1mono) plotregion(margin(t+2))  blabel(bar, `blabtxt')  bargap(*1.1) ///
		ylab( `yaxlab1', labsize(*1.2) nogrid) ylab( `yaxmin' " " `yaxmax' " " , add tstyle(none) custom)  ///
		plotreg(marg(b+2) /* ilc(black) */) graphreg(marg(l+2 r+2)) text( `ymin2' 50 "{it:${mvldisp1$sfx}}", size(*1.2) ) `subtxt'   `pltopts'

	if "`sing2'" != "y" barxlinedraw barby "`name'_`=char(64+`gnum')'`panadd2'"  `mstp1' `=`m2end'-`m2i'+1'
	if "`sing2'" == "y" barxlinedraw single "`name'_`=char(64+`gnum')'`panadd2'"   `mstp1' 1
*
	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 

}
}
}
*
*********Create bar chart with DUAL option **********************************************

if "`dual'" != "" {

***  Set up labels for model metric axis and obs metric dual axis
est restore `estint'
sum `predint' , meanonly
ret list
defaxislab `r(min)' `r(max)' 3
numlist "`r(labvals)'"
loc yaxlab1 "`r(numlist)'"
loc ylstp : list sizeof yaxlab1

loc vmin : word 1 of `yaxlab1'
loc vmax : word `ylstp' of `yaxlab1'


*** If user added y-axis labels, use their min & max 
if "${ypredmin$sfx}" != "" {
	loc vmin = ${ypredmin$sfx}
	loc vmax = ${ypredmax$sfx}
}
loc vminhold =`vmin'
loc vmaxhold =`vmax'


*** if SDY option reset predy1 min & max back to unstandardized to get dual axis label values
if "`sdy'" != "" {
	
	loc vmin = `vmin'*${ystd$sfx}+${ymn$sfx}
	loc vmax = `vmax'*${ystd$sfx}+${ymn$sfx}
}

if `vmin' > 0 loc vmin = 0
if `vmax' < 0 loc vmax =0

defdualaxislabbar `vmin' `vmax' 3 `ndig' 105
loc yaxlab2 `"`r(labdual)'"'
loc yaxlab3 "`r(labvals1)'"

*loc txmin = (`vmin' - .22*(`vmax' - `vmin'))/${ystd$sfx}
*loc txmax = (`vmax' + .15*(`vmax' - `vmin'))/${ystd$sfx}

loc txmin = `vminhold' - .33*(`vmaxhold' - `vminhold')
loc txmax = `vmaxhold' + .33*(`vmaxhold' - `vminhold')


********************** One Moderator

if ${mvarn$sfx} == 1  {

	graph bar `predint' if `fvar' < . , over(`fvar') over(`mvar1', gap(*1.5) label(labsize(*1.2)) )  name(`name', replace) asyvars subtitle(, size(*1.2) fc(gs14))  /// 
		bar(1, color(gs0) lc(gs0) ) bar(2, color(gs9) lc(gs0)) bar(3, color(gs6) lc(gs0)) bar(4, color(gs11) lc(gs0)) bar(5, color(gs8) lc(gs0)) ///
		bar(6, color(gs13) lc(gs0) ) bar(7, color(gs10) lc(gs0)) bar(8, color(gs15) lc(gs0)) bar(9, color(gs12) lc(gs0)) bar(10, color(gs16) lc(gs0)) intensity(*.75) ///
		leg(title("Predicted `dvtxt' by {it:${fvldisp$sfx}}", size(*.8)) bm(t+2) rows(1) rowgap(*2) size(*1) symy(*1.4) symx(*.1755) ) ///
		ytitle("`dvtxt'", mar(r+8) size(*1.2)) scheme(s1mono) xsize(`xsz') ysize(`ysz') plotregion(margin(t+2))  blabel(bar, `blabtxt')  bargap(*1.2) ///
		ylab( `yaxlab1', labsize(*1.2) nogrid) ysc(r( `yaxmin' `yaxmax')) ylab( `yaxmin' " " `yaxmax' " " , add tstyle(none) custom) /// 
		yline( `yaxlab3' , lp(shortdash) lc(gs9) lw(*.6) ) `yrevtxt' ///
		title("`titxt'" "`titxt2', Dual Outcome Metric Axes.", size(*1) m(b+2)) plotreg(marg(b+2 t+2)) graphreg(marg(l+10 r+17) )  ///
		text( `txmin' -2 "{it:${mvldisp1$sfx}}", size(*1.2) place(west) j(left) )  text( `txmax' 105 "{it:${dvname$sfx}}" `yaxlab2' , size(*.9) placement(e) ma(l+2))  `pltopts'
	
	barxlinedraw dual "`name'"  `mstp1' 1
}
*
********************** 2+ Moderators
if ${mvarn$sfx} > 1 {

	loc txmin = `vminhold' - .3*(`vmaxhold' - `vminhold')
	loc txmin2 = `txmin' - .25*(`vmaxhold' - `vminhold')
	loc txmax = `vmaxhold' + .15*(`vmaxhold' - `vminhold')

	loc gnum=0
	loc panbytxt ""
	loc subtxt `" subti("") "'
	loc inc=2
	loc subtxtby "{it:${mvldisp2$sfx}}"
	loc notit "  "
	
	if "`sing2'" == "y" {
		loc inc=1
		loc subtxtby ""
		loc notit `"titl("") "'
		loc txmin = (`vmin' - .23*(`vmax' - `vmin'))/${ystd$sfx}
		loc txmin2 = (`=`txmin'*${ystd$sfx}' - .13*(`vmax' - `vmin'))/${ystd$sfx}
	}
	loc ysz = 6.5
	loc xsz =max( 4.5, 10*(`fstp'*`mstp1'*`inc')/16) + 1.5
	loc xsz = min(`xsz',20)
	loc panadd2 ""
	
forvalues m2i=1(`inc')`mstp2' {
	loc m2end = `m2i'+1
	if `mstp2' - `m2i' == 2  & `inc' != 1 {
		loc m2end = `mstp2' 
		loc xsz =max( 4.5, 10*(`fstp'*`mstp1'*3)/16)  + 1.5 
		loc xsz = min(`xsz',20)
		loc ysz = 6.5 
	}
	if `inc' == 1  loc m2end = `m2i' 
	loc if1 : word `m2i' of `mlevs2'
	loc if2 : word `m2end' of `mlevs2'
	loc ++ gnum
	if "`sing2'" == "y" {
		loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`if1'"
		loc subtxt `" subti("{it:${mvldisp2$sfx}} = ${mvlabm2c`m2i'$sfx}" , size(*1)) "'
	}
	if `mstp2' > 3 & "`sing2'" != "y" loc panbytxt `"note("Panel `=char(64+`gnum')' for ${mvldisp2$sfx}", pos(11) just(left) size(*.9))"'
	
	graph bar `predint' if `fvar' < . & inrange(`mvar2',`if1',`if2')==1, over(`fvar') over(`mvar1', gap(*1.5) label(labsize(*1.2) labgap(*1.5) angle(25))) ///
		over(`mvar2' , gap(*1.5) label(labsize(*1) labgap(*1.5) /*angle(25)*/) ) asyvars title("`titxt'" "`titxt2', with Dual Outcome Metric Axes.", size(*.9) m(b+1)) /// 
		note("")  `notit' `panbytxt' subti("`subtxtby'", size(*.9))  name(`name'_`=char(64+`gnum')'`panadd2', replace) subtitle(, size(*1) fc(gs14))  /// 
		bar(1, color(gs0) lc(gs0) ) bar(2, color(gs9) lc(gs0)) bar(3, color(gs6) lc(gs0)) bar(4, color(gs11) lc(gs0)) bar(5, color(gs8) lc(gs0)) ///
		bar(6, color(gs13) lc(gs0) ) bar(7, color(gs10) lc(gs0)) bar(8, color(gs15) lc(gs0)) bar(9, color(gs12) lc(gs0)) bar(10, color(gs16) lc(gs0)) intensity(*.75) ///
		leg(title("Predicted `dvtxt' by {it:${fvldisp$sfx}}", size(*.8)) bm(t+4) rows(1) rowgap(*2) size(*.9) symy(*1.4) symx(*.1755) ) ///
		ytitle("`dvtxt'", ma(r+3)) scheme(s1mono) plotregion(margin(t+2))  blabel(bar, `blabtxt')  bargap(*1.5) ///
		ylab( `yaxlab1', labsize(*1.2) nogrid) ysc(r( `yaxmin' `yaxmax')) ylab( `yaxmin' " " `yaxmax' " " , add tstyle(none) custom)  ///
		yline( `yaxlab3' , lp(shortdash) lc(gs9) lw(*.6) ) xsize(`xsz') ysize(`ysz') ///  
		text( `txmax' 102 "{it:${dvname$sfx}}" `yaxlab2' , size(*.9) placement(e) ma(l+2)) plotreg(marg(b+2)) graphreg(marg(l+10 r+15)) ///
		text( `txmin' -2 "{it:${mvldisp1$sfx}}{sf}" `txmin2' -2 "{it:${mvldisp2$sfx}}{sf}" , size(*1.2) place(west) j(left) )  `subtxt'  `pltopts'

	if "`sing2'" != "y" barxlinedraw dual "`name'_`=char(64+`gnum')'`panadd2'"  `=`m2end'-`m2i'+1' 1
	if "`sing2'" == "y" barxlinedraw dual "`name'_`=char(64+`gnum')'`panadd2'"  `mstp1' 1
			
	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 
}
}
}
*
***	create freq distn vars & plot if requested.  
if "`base'" != "" {
	loc vnm : coln `frqmat'
	loc cnum=colsof(`frqmat')-1
	loc cnm ""
	forvalues j=1/`cnum' {
		loc nm : word `j' of `vnm'
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
		loc vv : word `m1' of `cnm'
		replace `vv' = `vv'/fsum*100 if `vv'<. 	
		loc ypctmax= round(fmax/fsum*100+.5)
		loc titcomb `""Relative Frequency of ${fvldisp$sfx}"  "by ${mvldisp1$sfx} Combinations""'
	}
	if "`base'" == "sub" {
		mat `frqvsub'=`frqvar'[.,`m1'..`m1']
		loc vv : word `m1' of `cnm'		
		replace `vv' = `vv'/el("fsumcol",1,`m1')*100 if `vv'<. 
		loc ypctmax= 0
		forvalues j=1/`cnum' {
			if (el("fmaxcol",1,`j')/el("fsumcol",1,`j'))*100 > `ypctmax' loc ypctmax = round(el("fmaxcol",1,`j')/el("fsumcol",1,`j')*100+.5)
		}
		loc titcomb `""Relative Frequency of ${fvldisp$sfx}"  "within ${mvldisp1$sfx} Subsamples""'	
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
	loc vv : word `m1' of `cnm'	
	
	if `m1' != `cnum' & "`sing'" == "" ///
		tw spike `vv' `frqv'focalcat ,  ysca( r(0) ) scheme(s1mono)  xlabel(${fmin$sfx} " " , tlc(white) labsize(*1.2)) fysize(70) fxsize(50) nodraw  /// 
			lc(black) lw(*5) graphregion(margin(l+2 r+2 b=0 t=0) style(none)) ylab(0 `ylabmid' `ylabmax', labsize(*1.2))  ytitle("Pct", size(*1) margin(r+2)) ///
			xtitle(" ", size(*1.2) m(t+2)) plotr(m(tiny) style(none)) name(frqhold`m1'$sfx, replace) /// 
			title("${mvldisp1$sfx} = ${mvlabm1c`m1'$sfx}", pos(11) size(*.85) m(b+2)) 
			
	if `m1' == `cnum' | "`sing'" != "" ///
		tw spike `vv' `frqv'focalcat ,  ysca( r(0) ) scheme(s1mono)  xlabel(`foclabs' , labsize(*1.2)) fysize(70) fxsize(50) nodraw  /// 
			lc(black) lw(*5) graphregion(margin(l+2 r+2 b=0 t=0) style(none)) ylab(0 `ylabmid' `ylabmax', labsize(*.96))  ytitle("Pct", size(*1) margin(r+2)) ///
			xtitle("${fvldisp$sfx}", size(*1.2) m(t+2)) plotr(m(tiny) style(none)) name(frqhold`m1'$sfx, replace) ///
			title("${mvldisp1$sfx} = ${mvlabm1c`m1'$sfx}", pos(11) size(*.85) m(b+2)) 
			
loc combfrq "`combfrq' frqhold`m1'$sfx"	  
}
loc leftplt ""
if "`base'" != "" loc leftplt "Left"

graph combine`combfrq' , cols(1) ycommon xcommon graphreg(c(white)) iscale(*1.1)  /// 
		title(`titcomb', size(*.85) m(b+2)) ysize(8) xsize(6) name(`name'Freq, replace)
}
}
***

est restore `estint'
  
if "`save'" != "" {
	glo plotnum$sfx = ${plotnum$sfx}+1
	loc rownum=2 + `npltrow'*(${plotnum$sfx}-1)
	if "${frevcode$sfx}" != "" recode `fvar' ${frevcode$sfx} 
	if "${m1revcode$sfx}" != "" recode `mvar1' ${m1revcode$sfx} 
	if "${m2revcode$sfx}" != "" recode `mvar2' ${m2revcode$sfx} 
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
				loc mval2 : word `m2i' of `mlevs2'
				loc m2txt ", Separate plot for ${mvldisp2$sfx} = ${mvlabm2c`m2i'$sfx} (`mval2')" 
		}
		putexcel B`=`rownum'+`mstp1'*`npltrow'*(`m2i'-1)' = "Plot Name = `name'  `m2txt'" B`=`rownum'+`mstp1'*(`m2i'-1)+1' = "`m3txt'" , txtwrap
		}
		
	loc vartxt `"C1 = "yhatint" D1 = "${fvldisp$sfx}" E1 = "${mvldisp1$sfx}" F1 = "${mvldisp2$sfx}" "'
	loc fvi=0
	
	if "`outmain'" != "" {
	loc vartxt `"C1 = "yhatintTOT"  D1 = "yhatmainTOT" "'
		forvalues fi=1(2)`=2*`fstp'' {
			loc ++fvi
			loc fval1 : word `fvi' of `flevs'
			loc vartxt`"`vartxt' `=char(68+`fi')'1 = "yhatint${fvldisp$sfx}`fval1'" "'
			loc vartxt `"`vartxt' `=char(68+`fi'+1)'1 = "yhatmain${fvldisp$sfx}`fval1'" "'
		}
		loc vartxt`"`vartxt' `=char(68+2*`fstp'+1)'1 = "${fvldisp$sfx}" `=char(68+2*`fstp'+2)'1 = "${mvldisp1$sfx}" `=char(68+2*`fstp'+3)'1 = "${mvldisp2$sfx}" "'
	}
	
	if ${plotnum$sfx} == 1	 putexcel `vartxt'
	
	if "`outmain'" == "" mkmat `predint'  `fvar' `mvar1' `mvar2' if `fvar' < ., mat(`savmat')
	if "`outmain'" != "" mkmat  `predint' `predmn' `yhattxt1' `yhattxt2' `fvar' `mvar1' `mvar2' if `fvar' < ., mat(`savmat')
	loc skey " 3, 2"
	if "`outmain'" != "" loc skey "`=3+2*`fstp'', `=4+2*`fstp''"
	if ${mvarn$sfx}>1 {
		loc skey "4, 3, 2"
		if "`outmain'" != "" loc skey "`=5+2*`fstp'', `=3+2*`fstp'', `=4+2*`fstp''"
	}
	mata: msrt = st_matrix("`savmat'"); msrt=sort(msrt,(`skey')); st_matrix("`savmat'",msrt)
	putexcel C`rownum'= mat(`savmat') 
}
*

/* CODE FROM OTHER ADO-FILES FOR COMBINING PLOTS.  KEEP FOR LATER ADDING FUNCTIONALITY FOR MORE MVARS
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
*

capture: if "`keep'" != "keep" & "`base'" != ""  graph  drop frqhold*
}
end

