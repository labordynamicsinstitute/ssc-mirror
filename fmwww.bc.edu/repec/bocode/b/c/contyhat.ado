*!  contyhat.ado 	Version 3.3 	RL Kaufman 	11/10/2018

***  	1.0 Create Contour plots of Predicted Outcome. Called by OUTDISP.ADO'
***				Adapted from SCATYHAT.ADO and CONPLOT.ADO
***		2.0 Changed FREQ plot from stacked spike plots to contour plot.  Fixed labelling for non-integer numeric labels.
***		2.1 Dual option now labels outcome in y-standardized model metric (Z axis for contour)
***		3.0  Minor changes to work with mlogit
***		3.1  SDY option allows y-standardized metric w or w/o dual
***		3.2	CCUTS option allows user speciifed contour cutpoints
***		3.3  Use min and max of fvrange (mvrange) to define added xaxis min & max instead of actual variable min and max
***		3.4  Added warning that 'tot' option for frequency plot of focal variable not valid for contour plot

program contyhat, rclass
version 14.2
syntax  ,  predint(varname) fvar(varname)  mvar1(varname)  [ mvar2(varname) mvar3(varname) mvar4(varname) mvar5(varname) mvar6(varname) ///
	predmn(varname)  estint(string)  /// 
	mlab2(string) mlab3(string) mlab4(string) mlab5(string) mlab6(string) dual(string) sdy(string) frqmat(string) base(string) ///
	sing(string) ndig(integer 4) KEEP name(string) save(string) dvtxt(string) titxt(string) titxt2(string) pantxt(string) ccuts(string asis) pltopts(string asis) ]
tempname   frqvsub  frqvar frqv savmat yhatint yhatmn


*** create non-temp variables for tw contour command to use
foreach nm in   predint fvar  mvar1  {
capture drop `nm'$sfx 
gen `nm'$sfx = ``nm''
}
capture drop mvar2$sfx
if ${mvarn$sfx} >1 gen mvar2$sfx = `mvar2' 

***   Set # of rows/plot for saving plotdata, loop endpoint & values for m2 if exists
loc npltrow = 26^2
loc mstp2=1
if ${mvarn$sfx} >1 { 
	qui levelsof `mvar2', loc(m2levs)
	loc mstp2: list sizeof m2levs 
}

*
**************************************************** Set up info for Contour plot needed with or without DUAL [OUTMAIN not a posssilbe option]
forvalues i=1/2 {
	loc sing`i' ""
	if "`sing'" == "`i'" | "`sing'" == "all" loc sing`i' "y"
}
loc grphcomb ""

loc foclabs ""
loc fstp: list sizeof global(fvrange$sfx)
forvalues fi=1/`fstp' {
	loc labnum: word `fi' of ${fvrange$sfx}
	loc yylab "${fvlabc`fi'$sfx}"
	loc yynum=real("${fvlabc`fi'$sfx}")
	if `yynum' != . loc yylab=strofreal(`yynum')

	loc foclabs `"`foclabs' `labnum' "`yylab'" "'
}
*
forvalues mi=1/2 {
	loc modlabs`mi' ""
	loc mstp`mi' = 1
	if `mi' <= ${mvarn$sfx} {
		loc mstp`mi': list sizeof global(mvrange`mi'$sfx)
		forvalues mmi=1/`mstp`mi'' {
			loc labnum: word `mmi' of ${mvrange`mi'$sfx}
			if `mi' == 2  loc labnum: word `mmi' of `m2levs'
			loc xxlab "${mvlabm`mi'c`mmi'$sfx}"
			loc xxnum=real("${mvlabm`mi'c`mmi'$sfx}")
			if `xxnum' != . loc xxlab=strofreal(`xxnum') //,"%10.${mvdigit`mi'$sfx}f")
			loc modlabs`mi' `"`modlabs`mi'' `labnum' "`xxlab'" "'
		}
		if `mi' != 1 {
			lab def mvlab`mi'$sfx `modlabs`mi'' , replace
			lab val mvar`mi'$sfx mvlab`mi'$sfx 
		}
	}
}
*
est restore `estint'

loc xfirst: word 1 of ${mvrange1$sfx}
loc xlast: word `mstp1' of ${mvrange1$sfx}
loc xmin = `xfirst'-.05*(`xlast'-`xfirst')
loc xmax = `xlast'+.05*(`xlast'-`xfirst')

loc yfirst: word 1 of ${fvrange$sfx}
loc ylast: word `fstp' of ${fvrange$sfx}
loc ymin = `yfirst'-.05*(`ylast'-`yfirst')
loc ymax = `ylast'+.05*(`ylast'-`yfirst')


if "`ccuts'" == "" {
qui summ `predint' if inrange(mvar1$sfx , `xfirst',`xlast')==1 & inrange(fvar$sfx ,`yfirst',`ylast')==1 , meanonly
	loc zaxmin = r(min)
	loc zaxmax = r(max)
	loc zmin = r(min)-.05*(r(max)-r(min))
	loc zmax = r(max)+.05*(r(max)-r(min))
	defaxislab `zaxmin' `zaxmax' 6
	numlist "`r(labvals)'"
	loc zaxlab1 "`r(numlist)'"
}
if "`ccuts'" != "" {
	numlist "`ccuts'"
	loc zaxlab1 "`r(numlist)'"
}


qui summ predint$sfx if inrange(mvar1$sfx , `xfirst',`xlast')==1 & inrange(fvar$sfx ,`yfirst',`ylast')==1 , meanonly
loc cctxt "ccuts(`zaxlab1')"
loc holdnlist "`zaxlab1'"

*********Create Contour plot if  DUAL option  not specified   ****MAIN EFFECTS SUPERIMPOSED NOT A POSSIBLE OPTION

if "`dual'" == "" {
********************** One Moderator

if ${mvarn$sfx} == 1  {

   tw contour predint$sfx fvar$sfx mvar1$sfx if predint$sfx < . & inrange(mvar1$sfx , `xfirst',`xlast')==1 & inrange(fvar$sfx ,`yfirst',`ylast')==1 /// 
		, scheme(s1mono) `cctxt' minmax scolor(gs15) ecolor(gs0) lc(white) ///
		  crule(lin)  xlab( `modlabs1', nogrid  labsize(*1.2))  /// 
		  ylab( `foclabs', axis(1) angle(vertical) labsize(*1.2))  xti("${mvldisp1$sfx}", size(*1.2) m(t+2)) /// 
		  yti("${fvldisp$sfx}", size(*1.2) m(r+5)) graphreg(fc(white) ma(zero) style(none)) lc(black) lw(*2) /// 
		  ztitle("") plotr(m(tiny) style(none))   name(`name', replace)  title("`titxt'" "`titxt2'.", size(*1.1) m(b+2)) ///
		  clegend(title("Predicted" "`dvtxt'" , size(*1) m(b+2)) region(lcolor(black)))   ///
		  plotregion(margin(tiny) icolor(white)) zlab(`zaxlab1', labsize(*1.2) format(%7.`ndig'f) tposition(inside) /// 
		  tlength(*4.3) labgap(*2) tlc(white) ) aspect(1)  `heatmap' legend(off)  `pltopts'

	}  
*
********************** 2 Moderators

if ${mvarn$sfx} > 1 {
	loc gnum=0
	loc subtxt ""
	loc xsz = 8.25
	loc ysz = 4.6 
	loc inc=2
	loc clegtxt "clegend(on)"
	loc notitle ""
	if "`sing2'" == "y" { 
		loc inc=1
		loc clegtxt "clegend(off)" 
		loc notitle `"title("")"'
	}
	loc panadd2 ""
	
forvalues m2i=1(`inc')`mstp2' {
	loc m2end = `m2i'+1
	if `mstp2' - `m2i' == 2 {
		loc m2end = `mstp2' 
		loc xsz = 11.2
		loc ysz = 4.6 
	}
	if `inc' == 1 {
		loc m2end = `m2i' 
		loc xsz = 4.525
		loc ysz = 4.6 
		if `m2i' == `mstp2' {
			loc clegtxt "clegend(on)" 
			loc xsz = 5.6
		}
	}
	loc if1: word `m2i' of `m2levs'
	loc if2: word `m2end' of `m2levs'
	loc ++ gnum
	
	if "`sing2'" == "y" loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`if1'"
	if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `=char(64+`gnum')' for ${mvldisp2$sfx}", m(b+2) pos(11) just(left) size(*1.1))"'

	tw contour predint$sfx fvar$sfx mvar1$sfx if predint$sfx < .  & inrange( mvar2$sfx ,`if1',`if2')==1 & inrange(mvar1$sfx , `xfirst',`xlast')==1 & /// 
	    inrange(fvar$sfx ,`yfirst',`ylast')==1 , by( mvar2$sfx , rows(1) iscale(*1.25) imarg(r+2) /// 
		title("`titxt'" "`titxt2'.", size(*1) m(b+2)) `subtxt'  note("")  `clegtxt' `notitle' ) /// 
		scheme(s1mono) `cctxt' minmax scolor(gs15) ecolor(gs0) lc(white) crule(lin)  xlab( `modlabs1', nogrid  labsize(*1.2) angle(45))  /// 
		ylab( `foclabs', axis(1) angle(-45) labsize(*1.2) )  xti("${mvldisp1$sfx}", size(*1.2) m(t+2)) /// 
		yti("${fvldisp$sfx}", size(*1.2) m(r+5)) graphreg(fc(white) ma(zero) style(none)) lc(black) lw(*2) /// 
		ztitle("") plotr(m(tiny) style(none))  name(`name'_`=char(64+`gnum')'`panadd2', replace) ///
		clegend(title("Predicted" "`dvtxt'", size(*1) m(b+2)) region(lcolor(black)))   ///
		plotregion(margin(tiny) icolor(white)) zlab(`zaxlab1', labsize(*1.2) format(%7.`ndig'f) tposition(inside) /// 
		tlength(*4.33) labgap(*2) tlc(white) ) ysize(`ysz') xsize(`xsz') `heatmap' legend(off)  subti( , fc(white) size(*1)) `notitle' `pltopts'

	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 
}
}
}
*
*********Create Contour plot with DUAL option **********************************************

if "`dual'" != "" {

***  Set up labels for model metric axis and obs metric dual axis

est restore `estint'

if "${zpredmax$sfx}" != "" & "`ccuts'" == "" {
	numlist "${zpredmin$sfx} `holdnlist' ${zpredmax$sfx}" , sort
	loc holdnlist "`r(numlist)'"
} 
dualaxislabcontour , lablst(`holdnlist') ndig(`ndig')
loc zaxlab2 `"`r(labdual)'"'


********************** One Moderator

if ${mvarn$sfx} == 1  {

	tw contour predint$sfx fvar$sfx mvar1$sfx if predint$sfx < . & inrange(mvar1$sfx , `xfirst',`xlast')==1 & inrange(fvar$sfx ,`yfirst',`ylast')==1 ///
	      , scheme(s1mono) `cctxt' minmax scolor(gs15) ecolor(gs0) lc(white) ///
		  crule(lin)  xlab( `modlabs1', nogrid  labsize(*1.2))  /// 
		  ylab( `foclabs', axis(1) angle(vertical) labsize(*1.2))  xti("${mvldisp1$sfx}", size(*1.2) m(t+2)) /// 
		  yti("${fvldisp$sfx}", size(*1.2) m(r+5)) graphreg(fc(white) ma(zero) style(none)) lc(black) lw(*2) /// 
		  ztitle("") plotr(m(tiny) style(none))   name(`name', replace)  /// 
		  title("`titxt'" "`titxt2', with Dual Outcome Axes.", size(*1.1) m(b+2)) ///
		  clegend(title("`dvtxt'" " " "[${dvname$sfx}]", size(*1) m(b+2)) region(lcolor(black)))   ///
		  plotregion(margin(tiny) icolor(white)) zlab(`zaxlab2', labsize(*1.2) format(%7.`ndig'f) tposition(inside) /// 
		  tlength(*4.3) labgap(*2) tlc(white) ) aspect(1) `heatmap' legend(off)  `pltopts'
		  
}  
*
********************** 2 Moderators

if ${mvarn$sfx} > 1 {
	loc gnum=0
	loc subtxt ""
	loc xsz = 8.2
	loc ysz = 4.6 
	loc inc=2
	loc clegtxt "clegend(on)"
	loc notitle ""
	if "`sing2'" == "y" { 
		loc inc=1
		loc clegtxt "clegend(off)" 
		loc notitle `"title("")"'
	}
	loc panadd2 ""
	
forvalues m2i=1(`inc')`mstp2' {
	loc m2end = `m2i'+1
	if `mstp2' - `m2i' == 2 {
		loc m2end = `mstp2' 
		loc xsz = 11.1
		loc ysz = 4.6 
	}
	if `inc' == 1 {
		loc m2end = `m2i' 
		loc xsz = 4.5
		loc ysz = 4.6 
		if `m2i' == `mstp2' {
			loc clegtxt "clegend(on)" 
			loc xsz = 6.125
		}
	}
	loc if1: word `m2i' of `m2levs'
	loc if2: word `m2end' of `m2levs'
	loc ++ gnum
	
	if "`sing2'" == "y" loc panadd2 "_`=substr("${mvldisp2$sfx}",1,4)'`if1'"
	if `mstp2' > 3 & "`sing2'" != "y" loc subtxt `"subti("Panel `=char(64+`gnum')' for ${mvldisp2$sfx}", m(b+2) pos(11) just(left) size(*1.1))"'


	tw contour predint$sfx fvar$sfx mvar1$sfx if predint$sfx < . & inrange( mvar2$sfx ,`if1',`if2')==1 & inrange(mvar1$sfx , `xfirst',`xlast')==1 & /// 
	    inrange(fvar$sfx ,`yfirst',`ylast')==1 , by( mvar2$sfx , rows(1) iscale(*1.25) imarg(r+2) /// 
		title("`titxt'" "`titxt2', with Dual Outcome Axes.", size(*1.1) m(b+2)) `subtxt'  note("")   subti( ,size(*1)) `clegtxt' `notitle' ) /// 
		scheme(s1mono) `cctxt' minmax scolor(gs15) ecolor(gs0) lc(white) crule(lin)  xlab( `modlabs1', nogrid  labsize(*1.2) angle(45))  /// 
		ylab( `foclabs', axis(1) angle(-45) labsize(*1.2) )  xti("${mvldisp1$sfx}", size(*1.2) m(t+2)) /// 
		yti("${fvldisp$sfx}", size(*1.2) m(r+5)) graphreg(fc(white) ma(zero) style(none)) lc(black) lw(*2) /// 
		ztitle("") plotr(m(tiny) style(none))  name(`name'_`=char(64+`gnum')'`panadd2', replace)  /// 
		clegend(title("`dvtxt'" " " "[${dvname$sfx}]", size(*1) m(b+2)) region(lcolor(black)))   ///
		plotregion(margin(tiny) icolor(white)) zlab(`zaxlab2', labsize(*1.2) format(%7.`ndig'f) tposition(inside) /// 
		tlength(*4.33) labgap(*2) tlc(white) ) ysize(`ysz') xsize(`xsz') `heatmap' legend(off)  subti( , fc(white) size(*1)) `notitle' `pltopts'

	if `mstp2' - `m2i' == 2 & "`sing2'" == "" continue, break 
}
}
}
*
***	create freq distn vars & plot if requested.  
if "`base'" == "tot" noi disp _newline(2) in red  " 'tot' option for frequency distribution not valid for contour plot, ignored"  
if "`base'" != "" & "`base'" != "tot" {
	loc cnum=colsof(`frqmat')-1
	loc cnump1 = `cnum'+1
	loc rnum=rowsof(`frqmat')
	mat `frqvar'= `frqmat'[.,1..`cnum']
	mata: fmat=st_matrix("`frqvar'"); fsum= sum(fmat); fmax= max(fmat); fsumcol = colsum(fmat); fmaxcol= colmax(fmat); st_numscalar("fsum",fsum); st_numscalar("fmax",fmax); st_matrix("fsumcol",fsumcol); st_matrix("fmaxcol",fmaxcol)
	loc focmatxt ""
	loc m1matxt ""
	
forvalues j=1/`cnum' {
	loc val: word `j' of ${mvrange1$sfx}
	mat m`j'$sfx = J(`rnum',1,`val')
	if `j' !=  `cnum' {
		loc focmatxt "`focmatxt' `frqmat'[.,`cnump1'..`cnump1'] \ "
		loc m1matxt "`m1matxt' m`j'$sfx \ "
	}
	if `j' ==  `cnum' {
		loc focmatxt "`focmatxt' `frqmat'[.,`cnump1'..`cnump1']  "
		loc m1matxt "`m1matxt' m`j'$sfx  "
	}
	
	forvalues i=1/`rnum' {
		if "`base'" == "subtot" mat `frqvar'[`i',`j'] = `frqvar'[`i',`j']*(100/fsum)
		if "`base'" == "sub" mat `frqvar'[`i',`j'] = `frqvar'[`i',`j']*(100/el("fsumcol",1,`j'))
	}
}
*
mat pct$sfx=vec(`frqvar')	
mat foc$sfx = [`focmatxt']
mat m1$sfx = [`m1matxt']
mat hold$sfx = [pct$sfx, foc$sfx, m1$sfx ] 
mat colnames hold$sfx = pctv$sfx focv$sfx m1v$sfx
svmat hold$sfx, name(col)
sum pctv$sfx , meanonly
loc zpctmax= round(r(max)+.5)
loc zinc = `zpctmax'/7 

if "`base'" == "subtot" loc titadd "-by-${mvldisp1$sfx} Combinations"	
if "`base'" == "sub" 	loc titadd " within ${mvldisp1$sfx} Subsamples"	

tw contour pctv$sfx focv$sfx  m1v$sfx  if pct < ., scheme(s1mono)  minmax scolor(gs15) ecolor(gs0) lc(white) ///
	crule(lin) name(`name'_frq, replace)   xlab(${mvrange1$sfx} , nogrid labsize(*.9) format(%12.${mvdigit1$sfx}f))   /// 
	ylab(${fvrange$sfx} , axis(1) angle(vertical) labsize(*.9)) xtitle("${mvldisp1$sfx}" , marg(t+3) size(*.9)) /// 
	ytitle("${fvldisp$sfx}" , m(r+3) size(*.9))  lc(black) lw(*2) ztitle("Percentages", orientation(rvertical) m(l+3) size(*.9)) ///     
	title("Relative Frequency of ${fvldisp$sfx}`titadd'", size(*.9) marg(b+1) justification(left)) clegend(on) clegend(region(lcolor(black)))   ///
	plotregion(margin(tiny) icolor(white)) zlab( 0(`zinc')`zpctmax', labsize(*.9) format(%5.1f) tposition(inside) tlength(*3.3) labgap(*2) tlc(white) ) /// 
	aspect(1)  

}
**
 est restore `estint'
 
**** Save plot data if specified ****************************
 
if "`save'" != "" {
	glo plotnum$sfx = ${plotnum$sfx}+1
	loc rownum =2 + `npltrow'*(${plotnum$sfx}-1)
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
		putexcel B`=`rownum'+`npltrow'*(`m2i'-1)' = "Plot Name = `name'  `m2txt'" B`=`rownum'+`npltrow'*(`m2i'-1)+1' = "`m3txt'" , txtwrap
		}
	loc vartxt ""
	
	if  ${mvarn$sfx} > 1 loc vartxt `"F1 = "${mvldisp2$sfx}" "'
	if  ${plotnum$sfx} == 1	 putexcel C1 =  "Pred${dvname$sfx}" D1 = "${fvldisp$sfx}"  E1 = "${mvldisp1$sfx}"  `vartxt'
	if  ${mvarn$sfx} > 1 loc vartxt `", "mvar2$sfx" "'

	loc skey3 ""
	if ${mvarn$sfx}>1 loc skey3 "4,"
	mata: msrt = st_data((1,`=`npltrow'*`mstp2''),("predint$sfx","fvar$sfx","mvar1$sfx"`vartxt')); msrt=sort(msrt,( `skey3' 3, 2)); b=xl();b.load_book("`save'"); b.set_sheet("plotdata_${eqnow$sfx2}"); b.set_mode("open"); b.put_number(`rownum', 3, msrt); b.close_book()
	
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

*if "`keep'" != "keep" & "`base'" != ""  graph  drop frqhold*


end
