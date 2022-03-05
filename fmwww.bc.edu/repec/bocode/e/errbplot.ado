*!  errbplot.ado 	Version 6.1	RL Kaufman 	03/14/2019

***  	1.0 Create Error Bars Plot. Called by EFFDISP.ADO  Adapted from CBPLOT.ADO
***		2.0 Added user-specified PLTOPTS & fixed minor glitches 
***		3.0	Added mlogit functionality
***		4.0 Added marker chart option for effect dispplay with  no significance marking
***		5.0	Changed marker chart to dropline
***		6.0	Added Factor and SPOST functionality 
***		6.1 Fixed float precision problem when selecting on m2var when making matrix 

program errbplot, rclass
version 14.2
syntax  ,  m1var(varname) mlab1(varname) bmod(varname) upb(varname) lowb(varname) crittz(real) ci(real) ///
 fvarnum(varname) fnum(integer) noeffval(integer) ///
 [ titotheff(string) titdel(string) dvtxt(string) m2var(varname)  m3var(varname) mlab3(string) m3val(real 0) m3ind(integer 0) /// 
   m4ind(integer 0) m4var(varname) mlab4(string) m4val(real 0) ndig(integer 4) frqmat(string) ///
   base(string) KEEP name(string) save(string) estint(string) pltopts(string asis) pltsigmark(string) ] 
 
tempname   frqvsub  m1cat frqvar frqv savmat holdmat
tempvar   noeff sebar 

qui {
*** Create vars and info for EB plot ( y & x axis limits)
loc cipct =100*`ci'
gen `sebar' = `upb' - `bmod'
if strmatch("`pltsigmark'","*Yes*") == 1  qui sum `upb' , meanonly
if strmatch("`pltsigmark'","*Yes*") == 0  qui sum `bmod' , meanonly
loc ymax =r(max)
loc yy = abs(r(max))
loc ylabmax = 0
if `yy' > 0 {
	loc p10 = int(log10(`yy'))-1
	loc ylabmax = round(`yy'+.5*(10^(`p10')),10^(`p10'+1))*sign(r(max))
	if `yy' < 1 {
		loc pyy=int(log10(`yy'))*2
		loc y1=`yy'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))*sign(r(max))
		loc ylabmax= `y2'*(10^(`pyy'-1))
	}
}
loc yeffmax = `ylabmax' + .025*(r(max)-r(min))*sign(r(max))

if strmatch("`pltsigmark'","*Yes*") == 1  qui sum `lowb' , meanonly
if strmatch("`pltsigmark'","*Yes*") == 0  qui sum `bmod' , meanonly
loc yy = abs(r(min))
loc ymin =r(min)
loc ylabmin = 0
if `yy' > 0 {
	loc p10 = int(log10(`yy'))-1
	loc ylabmin = round(`yy'+.5*(10^(`p10')),10^(`p10'+1))*sign(r(min))
	if `yy' < 1 {
		loc pyy=int(log10(`yy'))*2
		loc y1=`yy'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))*sign(r(min))
		loc ylabmin= `y2'*(10^(`pyy'-1))
	}

}
loc yeffmin = `ylabmin' - .1*(r(max)-r(min))
loc yy = (`ylabmax' - `ylabmin')/4 
loc p10 = int(log10(`yy'))-1
loc ylabinc = round(`yy',10^(`p10'+1))
	if `yy' < 1 {
		loc pyy=int(log10(`yy'))*2
		loc y1=`yy'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))
		loc ylabinc= `y2'*(10^(`pyy'-1))
	}

if `ylabmax' == . | `ylabmin' == . | `ylabinc' == . {
	loc ylabmax = `ymax'
	loc ylabmin = `ymin'
	loc ylabinc = (`ylabmax' - `ylabmin')/4 
}
qui summ `m1var'
loc xmin = r(min) - .05*(r(max)-r(min))
loc xmax = r(max) + .05*(r(max)-r(min))
loc xlabtxt ""
loc nlab: list sizeof global(mvrange1$sfx)
forvalues i=1/`nlab' {
	loc val: word `i' of  ${mvrange1$sfx}
	loc xlabtxt " `xlabtxt' `val' "${mvlabm1c`i'$sfx}" "
}
capture {
	lab def mlabdef$sfx `xlabtxt' , replace
	lab val `m1var' mlabdef$sfx
}


***   Set # of rows/plot for saving plotdata

loc npltrow: list sizeof global(mvrange1$sfx)

***   Create info for freq distn vars if requested 
if "`frqmat'" != "" {
	loc vnm: coln `frqmat'
	loc cnum=colsof(`frqmat')-1
	loc cnm ""
	forvalues j=1/`cnum' {
		loc nm: word `j' of `vnm'
		loc cnm "`cnm' `=strtoname("`frqv'`nm'")' "
	}
	loc cnm "`cnm' `m1cat'"
	mat `holdmat' = `frqmat' 
	mat colnames `holdmat' = `cnm'
	svmat `holdmat' , names(col)
	loc mcatlab "" 
	forvalues i=1/`=rowsof(`holdmat')' {
		loc mcatlab "`mcatlab'  `=el(`holdmat',`i',`=`cnum'+1')' "${mvlabm1c`i'$sfx}" "
	}
capture {
	lab def mlabdef$sfx `mcatlab' , replace
	lab val `m1cat' mlabdef$sfx
}
	mat `frqvar'= `holdmat'[.,1..`cnum']
	mata: fmat=st_matrix("`frqvar'"); fsum= sum(fmat); fmax= max(fmat); fsumcol = colsum(fmat); fmaxcol= colmax(fmat); st_numscalar("fsum",fsum); st_numscalar("fmax",fmax); st_matrix("fsumcol",fsumcol); st_matrix("fmaxcol",fmaxcol)
}
****
**** Loop over m2 values if specified, otherwise loop once over m2  
loc grphcomb ""

loc mstp2=1
if "`m2var'" != "" loc mstp2: list sizeof global(mvrange2$sfx)

***	create freq distn vars & plot if requested.  

if  "`frqmat'" != ""  & "`base'" == "tot" {
		loc vv: word 1 of `cnm'
		replace `vv' = `vv'/fsum*100 if `vv'<.
		loc ypctmax= round(fmax/fsum*100+.5)
	}

forvalues m2=1/`mstp2' {
if "`frqmat'" != "" {

	if "`base'" == "subtot" {
		loc vv: word `m2' of `cnm'
		replace `vv' = `vv'/fsum*100 if `vv'<. 	
		loc ypctmax= round(fmax/fsum*100+.5)
	}
	
	if "`base'" == "sub" {

		mat `frqvsub'=`frqvar'[.,`m2'..`m2']
		loc vv: word `m2' of `cnm'		
		replace `vv' = `vv'/el("fsumcol",1,`m2')*100 if `vv'<. 
		loc ypctmax= 0
		forvalues j=1/`cnum' {
			if (el("fmaxcol",1,`j')/el("fsumcol",1,`j'))*100 > `ypctmax' loc ypctmax = round(el("fmaxcol",1,`j')/el("fsumcol",1,`j')*100+.5)
		}
	}
}

*** Set up substitution text and conditions
loc noplt "nodraw"
if "`m2var'" == ""  & ${fcnum$sfx} == 1 & "`frqmat'" == "" loc noplt ""
loc addif ""

loc legefftxt "${fvldisp$sfx}"
*loc legtxt `"  ♦   Effect of `legefftxt'       `=ustrunescape("\u026A")'   CI Bounds"' 
loc legtxt `"  ♦   Effect of `legefftxt'       `=ustrunescape("\u251C")'`=ustrunescape("\u2500")'`=ustrunescape("\u2500")'`=ustrunescape("\u2524")'   CI Bounds"' 
loc titletxt `"`cipct'% Confidence Intervals for" " `titotheff' Effect of ${fvldisp$sfx} `titdel' Moderated by ${mvldisp1$sfx}"'
if strmatch("`pltsigmark'","*Yes*") == 0 loc titletxt `"`titotheff' Effect of ${fvldisp$sfx} `titdel'" "Moderated by ${mvldisp1$sfx}"'

loc titxtcomb ""
loc titsz = "*.8"
loc titint "${mvldisp1$sfx}"
if "${bf1m1c1m2c1$sfx}" != "" loc titint " the Interaction of ${mvldisp1$sfx} "

loc legoff  ""
if "`frqmat'" != "" 	loc legoff " legend(off)"

loc titxtfv  ""
if ${fcnum$sfx} > 1 & "`m2var'" == ""  {
	loc titxtfv "`titotheff' Effect of ${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx} `titdel'. "
	loc titletxt "`titxtfv'"
	loc legoff " legend(off)"
	loc legefftxt "${fvldisp$sfx}"
	loc titsz = "*.7"
}
loc m2val: word `m2' of ${mvrange2$sfx}
*if "${mviscat2$sfx}" == "y" loc m2val = inrange(`m2',1,100)
if "`m2var'" != "" {
	loc legoff " legend(off)"
	loc addif "& `m2var' == float(`m2val')"
	loc titletxt "`titxtfv'${mvldisp2$sfx} = ${mvlabm2c`m2'$sfx}"
	loc titsz = "*.7"
	loc titxtcomb "`titint' and ${mvldisp2$sfx}"
}
if "`m3var'" != "" {
	loc addif "`addif' & `m3var' == float(`m3val')"
	loc titletxt "`titxtfv'${mvldisp2$sfx} = ${mvlabm2c`m2'$sfx} & ${mvldisp3$sfx} =  `mlab3'"
	loc titsz = "*.7"
	loc titxtcomb "`titint', ${mvldisp2$sfx} and ${mvldisp3$sfx}"
}
loc ysz =4
loc xsz =5
loc isc ""
loc fysz =15
if strmatch("`pltsigmark'","*Yes*") == 0 	{
	loc legtxt `"  ♦   Effect of `legefftxt' "' 
	loc ysz =4
	loc xsz =5	
	loc isc "iscale(*1.3)"
	loc fysz =20
}

loc xaxoff  ""
if "`frqmat'" != "" loc xaxoff "xscale(axis(1) off)"


loc gnmadd ""
if ${fcnum$sfx}>1 loc gnmadd "f`fnum'" 
loc m2ind = `m2'
forvalues j=2/4 {
	if  "`m`j'var'" != "" loc gnmadd "`gnmadd'm`j'`m`j'ind'"
}
loc top "Top"
if "`frqmat'" == "" loc top ""

loc noeffline "yline(`noeffval' , lp(shortdash) lc(gs12) lw(*1.1) )"
if (`yeffmin' < -.5 +1.45*`noeffval' & `yeffmax' < -.5 +1.45*`noeffval') | (`yeffmin' > .5 +.55*`noeffval' & `yeffmax' > .5 +.55*`noeffval') loc noeffline ""



if strmatch("`pltsigmark'","*Yes*") == 1 & "`titotheff'" == "" ///
	serrbar `bmod' `sebar'  `m1var' if `bmod' < . & `fvarnum' == `fnum' `addif',  yaxis(1) scheme(s1mono) msize(*2) /// 
		mvop(ms(d) lwidth(*1.1) msize(*2)) ysc(r(`yeffmin' `yeffmax'))  `noplt' ylab(`ylabmin'(`ylabinc')`ylabmax' , nogrid labsize(*1.2) form(%9.`ndig'f) ) /// 
		name(`name'`top'`gnmadd', replace)  /// 
		xlab( ${mvrange1$sfx} , valuelabel labsize(*1.2)) xsc(r(`xmin' `xmax'))  yti("Effect on `dvtxt'", size(*1) m(l +2 r+2)) /// 
		graphreg(fc(white) ma(zero) style(none)) xti("${mvldisp1$sfx}", size(*1) m(t+2)) title("`titletxt'",  size(`titsz') m(b+2)) ///
	    legend(on label(2 "Effect of `legefftxt'") label(1 "CI Bounds")  rows(1) pos(6) order(2 - " " 1 - " " 4) /// 
	    stack size(*.75) textfirst symysize(*.75) bmargin(l+2) )  plotr(m(sides) style(none)) `legoff' `xaxoff' `noeffline'  `pltopts'

if strmatch("`pltsigmark'","*Yes*") == 1 & "`titotheff'" != ""  ///	
	tw rcap `upb' `lowb' `m1var' if `bmod' < . & `fvarnum' == `fnum' `addif',  yaxis(1) scheme(s1mono) msize(*2) /// 
		 ysc(r(`yeffmin' `yeffmax'))  `noplt' ylab(`ylabmin'(`ylabinc')`ylabmax' , nogrid labsize(*1.2) format(%9.`ndig'f)) /// 
		name(`name'`top'`gnmadd', replace) ysize(`ysz') xsize(`xsz') yline(0 , lp(shortdash) lc(gs12) lw(*.8) ) /// 
		xlab( ${mvrange1$sfx} , valuelabel labsize(*1.2)) xsc(r(`xmin' `xmax'))  yti("Effect on `dvtxt'", size(*1) m(l +2 r+2)) /// 
		graphreg(fc(white) ma(zero) style(none)) xti("${mvldisp1$sfx}", size(*1) m(t+2)) title("`titletxt'",  size(`titsz') m(b+2)) ///
	    legend(on label(2 "Effect of `legefftxt'") label(1 "CI Bounds")  rows(1) pos(6) /// 
	    size(*.9) symysize(*.6) bmargin(l+2 r+1) )  plotr(m(sides) style(none)) `legoff' `xaxoff' `noeffline' `pltopts'  /// 
		||  scatter `bmod' `m1var' if `bmod' < . & `fvarnum' == `fnum' `addif' , /// 
		ms(d) lwidth(*.9) mc(black) lc(gs12) msize(*1.1) `pltopts'



if strmatch("`pltsigmark'","*Yes*") == 0 ///
	tw dropline `bmod'  `m1var' if `bmod' < . & `fvarnum' == `fnum' `addif',  yaxis(1) scheme(s1mono) /// 
		ms(d) lwidth(*.9) mc(black) lc(gs12) msize(*1.1) ysc(r(`yeffmin' `yeffmax'))  `noplt' ylab(`ylabmin'(`ylabinc')`ylabmax' , nogrid labsize(*1.2) format(%9.`ndig'f)) /// 
		name(`name'`top'`gnmadd', replace) ysize(`ysz') xsize(`xsz') yline(0 , lp(shortdash) lc(gs12) lw(*.8) ) /// 
		xlab( ${mvrange1$sfx} , valuelabel labsize(*1.2)) xsc(r(`xmin' `xmax'))  yti("Effect on `dvtxt'", size(*1) m(l +2 r+2)) /// 
		graphreg(fc(white) ma(zero) style(none)) xti("${mvldisp1$sfx}", size(*1) m(t+2)) title("`titletxt'",  size(`titsz') m(b+2)) ///
	    legend(on label(1 "  Effect of `legefftxt'")  rows(1) pos(6) /// 
	    size(*.9) symysize(*.6) bmargin(l+2 r+1) )  plotr(m(sides) style(none)) `legoff' `xaxoff'  `pltopts'

if "`frqmat'" != "" {
loc ylabsz = 1.2
if "`m2var'" != "" | ${fcnum$sfx} > 1 loc ylabsz = .96

tw spike `vv' `m1cat' if `vv' < . ,  ysca(reverse r(0)) scheme(s1mono) ylabel( `=`ypctmax'/3' " " `=`ypctmax'/3*2' " "  `ypctmax', labsize(*`ylabsz')  ) /// 
	yline(0, lw(*.8) axis(1)) xlab(${mvrange1$sfx} , valuelabel labsize(*1.2)) fysize(`fysz')  name(`name'Bot`gnmadd', replace)   /// 
    lc(black) lw(*5) graphregion(margin(zero) style(none))  ytitle("Pct", size(*1) margin(l +2 r+2)) xtitle("${mvldisp1$sfx}" , size(*1) m(t+2) ) ///
	xsc(r(`xmin' `xmax')) plotr(m(sides) style(none)) nodraw

	if "`m2var'" != "" | ${fcnum$sfx} > 1  ///
		graph combine `name'Top`gnmadd' `name'Bot`gnmadd', ysize(`ysz') xsize(`xsz') `isc'  xcommon cols(1) name(`name'`gnmadd', replace) ////
			graphreg(fc(white) style(none)) plotr(m(tiny) style(none)) imargin(0 0 0 0) nodraw  
			
	if "`m2var'" == "" & ${fcnum$sfx} == 1  ///
		graph combine `name'Top`gnmadd' `name'Bot`gnmadd', ysize(`ysz') xsize(`xsz') `isc'  xcommon cols(1) name(`name'`gnmadd', replace) ////
			graphreg(fc(white) style(none)) plotr(m(tiny) style(none)) imargin(0 0 0 0)  /// 
			cap("`legtxt'", ///
			pos(6) linegap(*.25) j(center) margin(t+1 b+1) alignment(bottom) fc(white) bmargin(t+2) box size(*.8) ) 
	
graph drop `name'Top`gnmadd' `name'Bot`gnmadd'
}
if "`save'" != "" {
	glo plotnum$sfx = ${plotnum$sfx}+1
	loc rownum=2 + `npltrow'*(${plotnum$sfx}-1)
	loc rnadj = `rownum' + `npltrow'-1
	loc fpnum = `fnum'
	if "${fviscat$sfx}" == "y" | ("${fisfv$sfx}" == "y" & ${fcnum$sfx} == 1 ) loc fpnum=`fnum'+1 
	putexcel set "`save'" , sheet(plotdata_${eqnow$sfx2}) modify
	putexcel B`rownum' = "Plot Name = `name'`gnmadd'"  B`=`rownum'+1' = "  Mod1= ${mvldisp1$sfx}" ///
		B`=`rownum'+2' = "  Mod2= ${mvldisp2$sfx}    Mod3= ${mvldisp3$sfx}" 
	loc mv2="."
	if "`m2'" != "" loc mv2 = `m2'
	loc mv3="."
	if "`m3var'" != "" loc mv3 = `m3val'
	if ${plotnum$sfx} == 1	/// 
		putexcel B1 = "Focal= ${fvldisp$sfx}" D1 = "bmod" E1 = "upper bound" F1 = "lower bound" G1 = "sebar" H1= "M1Value" I1 = "M1Label" J1 = "${fvldisp$sfx}" K1="FocalLabel" L1 = "Mod2Value" M1="M2Label" N1 = "Mod3Value" O1="M3Label"
	mkmat `bmod' `upb' `lowb' `sebar' `m1var' in `=`rownum'-1'/`=`rnadj'-1', mat(`savmat')
	putexcel D`rownum'= mat(`savmat') 
	putexcel J`rownum':J`rnadj'= `fnum' K`rownum':K`rnadj'= "${fvlabc`fpnum'$sfx}" L`rownum':L`rnadj'= `mv2' M`rownum':M`rnadj'= "${mvlabm2c`m2'$sfx}" N`rownum':N`rnadj'= `mv3' O`rownum':O`rnadj'= "`mlab3'"
	mata: mlab1 = st_sdata((1,`npltrow'),("`mlab1'")); b=xl();b.load_book("`save'"); b.set_sheet("plotdata_${eqnow$sfx2}"); b.set_mode("closed"); b.put_string(`rownum',7,mlab1)
}

*
if "`m2var'" != ""  loc grphcomb "`grphcomb' `name'`gnmadd'"


*** Close m2 loop	
}
*
if ${fcnum$sfx} > 1 & ${mvarn$sfx} == 1 glo grnames$sfx "${grnames$sfx} `name'`gnmadd'"

if "`m2var'" != "" {
if `mstp2' > 3 | ${fcnum$sfx} > 1 | "`m3var'" != "" glo pannum$sfx = ${pannum$sfx} + 1
loc fvtxt "${fvldisp$sfx}"
if ${fcnum$sfx} > 1 loc fvtxt "${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx}"
loc combti `"`cipct'% Confidence Intervals for `titotheff' Effect of `fvtxt' `titdel'" "Moderated by `titxtcomb'"'
loc combleg `""  ♦   Effect of `legefftxt'       `=ustrunescape("\u251C")'`=ustrunescape("\u2500")'`=ustrunescape("\u2500")'`=ustrunescape("\u2524")'   CI Bounds""'
if strmatch("`pltsigmark'","*Yes*") == 0 {
	loc combti `"`titotheff' Effect of `fvtxt' `titdel'" "Moderated by `titxtcomb'"'
	loc combleg `" "  ♦   Effect of `legefftxt' " "'
}


plotcomb , grphcomb(`grphcomb') title(`combti') grname(`name'`gnmtxt') legend(`combleg') plttype(errbar)

}
if "`keep'" != "keep" & "`grphcomb'" != "" graph  drop `grphcomb'
}
end

