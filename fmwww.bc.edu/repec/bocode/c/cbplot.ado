*!  cbplot.ado 	Version 6.3		RL Kaufman 	03/14/2019

***  	1.0 Create Confidnece Bounds Plot. Called by EFFDISP.ADO
***		2.0	Made separate PLOTCOMB.ADO as a shared ado to combine plots to replace same process in multiple ADOs
***		3.0 Added save plot data functionality
***		3.1 Incorporated improvments from ERRBPLOT, ylab setting, putexel code, noeffect line creation
***		5.0	Added mlogit functionality
***		6.0	Added factor change and spost functionality
***		6.1 Changed meaning of sigmark.  Adds Sig-NoSig vertical line to line plot but not confidence bounds
***		6.2 Use min and max of mvrange1 to define added xaxis (yaxis indirectly) min & max instead of actual variable min and max
***		6.3 Fixed float precision problem when selecting on m2var when making matrix 

program cbplot, rclass
version 14.2
syntax  ,  m1var(varname) mlab1(varname) bmod(varname) upb(varname) lowb(varname) bsig(varname) crittz(real) ci(real) /// 
	fvarnum(varname) fnum(integer)  noeffval(integer) ///
 [ titotheff(string) titdel(string) dvtxt(string) m2var(varname)  m3var(varname) mlab3(string) m3val(real 0) m3ind(integer 0) /// 
   m4ind(integer 0) m4var(varname) mlab4(string) m4val(real 0) ndig(integer 4) frqmat(string) ///
   base(string) KEEP name(string) save(string) estint(string) pltopts(string asis) pltsigmark(string) ] 
 
tempname   frqvsub  m1cat frqvar frqv savmat
tempvar    noeff 

qui {
*** Create vars and info for CB plot
loc cipct =100*`ci'

loc xfirst: word 1 of ${mvrange1$sfx}
loc mstp1: list sizeof global(mvrange1$sfx)
loc xlast: word `mstp1' of ${mvrange1$sfx}
loc xmin = `xfirst'-.05*(`xlast'-`xfirst')
loc xmax = `xlast'+.05*(`xlast'-`xfirst')

if strmatch("`pltsigmark'","*Yes*") == 1  qui sum `upb' if inrange(`m1var', `xfirst' , `xlast')  , meanonly
if strmatch("`pltsigmark'","*Yes*") == 0  qui sum `bmod' if inrange(`m1var', `xfirst' , `xlast') , meanonly

loc ymax=r(max)
loc yy = abs(r(max))
loc ylabmax = 0
if `yy' > 0 {
	loc p10 = int(log10(`yy'))-2
	loc ylabmax = round(`yy'+.5*(10^(`p10')),10^(`p10'+1))*sign(r(max))
	if `yy' < 1 {
		loc pyy=int(log10(`yy'))*2
		loc y1=`yy'*(10^(-`pyy'+1))
		loc p10=int(log10(`y1'))-1
		loc y2 =round(`y1'+ .5*(10^(`p10')),10^(`p10'+1))*sign(r(max))
		loc ylabmax= `y2'*(10^(`pyy'-1))
	}
}
*
if strmatch("`pltsigmark'","*Yes*") == 1  qui sum `lowb' if inrange(`m1var', `xfirst' , `xlast') , meanonly
if strmatch("`pltsigmark'","*Yes*") == 0  qui sum `bmod' if inrange(`m1var', `xfirst' , `xlast') , meanonly

loc yy = abs(r(min))
loc ymin=r(min)
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
if `ymax' - `ylabmax' > .3*`ylabinc' loc ylabmax = `ylabmax' + .4*`ylabinc'
if `ymin' - `ylabmin' < .3*`ylabinc' loc ylabmin = `ylabmin' - .4*`ylabinc'

loc yeffmax = `ylabmax' + .025*(`ylabmax'-`ylabmin')

loc yeffmin = `ylabmin' - .05*(`ylabmax'-`ylabmin')


***   Set # of rows/plot for saving plotdata

loc npltrow = 51

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
	mat colnames `frqmat' = `cnm'
	svmat `frqmat' , names(col)
	mat `frqvar'= `frqmat'[.,1..`cnum']
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

loc titletxt `"`titotheff' Effect of ${fvldisp$sfx} `titdel' Moderated by ${mvldisp1$sfx}"'
loc subtittxt ""
if strmatch("`pltsigmark'","*Yes*") == 1   loc subtittxt `" subtit( "`cipct'% Confidence Bounds" , size(*.9) m(b+1)  ) "'

loc titxtcomb ""
loc titsz = "*.7"
loc titint "${mvldisp1$sfx}"
if "${bf1m1c1m2c1$sfx}" != "" loc titint " the Interaction of ${mvldisp1$sfx} "

loc legoff  ""
if "`frqmat'" != "" 	loc legoff " legend(off)"

loc legefftxt "${fvldisp$sfx}"
loc titxtfv  ""
if ${fcnum$sfx} > 1 & "`m2var'" == ""  {
*	loc titxtfv "`titotheff' Effect of ${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx} "
	loc titxtfv "${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx}, "
	loc titletxt "${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx}"
	loc legoff " legend(off)"
	loc legefftxt "${fvldisp$sfx}"
	loc titsz = "*.7"
}
loc m2val: word `m2' of ${mvrange2$sfx}
*if "${mviscat2$sfx}" == "y" loc m2val = inrange(`m2',1,100)
if "`m2var'" != "" {
	loc legoff " legend(off)"
	loc addif "& `m2var' == float(`m2val')"
	loc titletxt "`titxtfv' ${mvldisp2$sfx} = ${mvlabm2c`m2'$sfx}"
	loc titsz = "*.7"
	loc titxtcomb "`titint' and ${mvldisp2$sfx}"
}
if "`m3var'" != "" {
	loc addif "`addif' & `m3var' == float(`m3val')"
	loc titletxt "`titxtfv' ${mvldisp2$sfx} = ${mvlabm2c`m2'$sfx} & ${mvldisp3$sfx} =  `mlab3'"
	loc titsz = "*.7"
	loc titxtcomb "`titint', ${mvldisp2$sfx} and ${mvldisp3$sfx}"
}

***  Create sig change info

loc isig = 0
loc ins = 0

forvalues j=1/3 {
	loc sig`j' ""
	loc ns`j' ""
	loc addsig`j' ""
	loc addns`j' ""
}

if strmatch("`pltsigmark'","*Yes*") == 1 |  strmatch("`pltsigmark'","*Vertical*") {

mkmat `bsig' `m1var'  if `fvarnum' == `fnum' `addif'  , mat(signe) nomiss


loc siglst =el(signe,1,1)

forvalues i=2/`=rowsof(signe)' {
	loc signow =el(signe,`i',1)
	loc sigchg =`signow' - `siglst'
	if `sigchg' != 0 {
		if `sigchg' > 0 {
			loc ++isig
			loc sig`isig'= el(signe,`i',2) - (el(signe,`i',2) - el(signe,`=`i' - 1',2) ) / 2
		}
		if `sigchg' < 0 {
			loc ++ins
			loc ns`ins'= el(signe,`i',2) - (el(signe,`i',2) - el(signe,`=`i' - 1',2) ) / 2
		}
		loc siglst = `signow'
	}
	}
*
loc svsig ""
loc svns ""
loc chgn = max(`isig', `ins')
forvalues j=1/`chgn' {
	loc addsig`j' ""
	loc addns`j' ""
*	if "`sig`j''" != "" & strmatch("`pltsigmark'","*Yes*") == 1 {
	if "`sig`j''" != "" {
		loc addsig`j' = " || scatteri `yeffmin' `sig`j'' `=`yeffmin'+.05*(`yeffmax' -`yeffmin')' `sig`j'' (12) " + `"""' +"NS───Sig" + `"""' +",  ms(i) xline(`sig`j'', lc(gs7) lp(solid) lw(*.8)) "
		loc svsig "`svsig' `=strofreal(`sig`j'',"%9.`ndig'f")'"
	}
*	if "`ns`j''" != "" & strmatch("`pltsigmark'","*Yes*") == 1 {
	if "`ns`j''" != ""  {
		loc addns`j' = " || scatteri `yeffmin'  `ns`j'' `=`yeffmin'+.05*(`yeffmax' -`yeffmin')' `ns`j'' (12) " + `"""' + "Sig───NS" + `"""' +" ,  ms(i)  xline(`ns`j'', lc(gs7) lp(solid) lw(*.8))"   
		loc svns "`svns' `=strofreal(`ns`j'',"%9.`ndig'f")'"
	}
	}
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
if ( `yeffmax' < `noeffval') | (`yeffmin' > `noeffval' ) loc noeffline ""
*if (`yeffmin' < -.5 +1.45*`noeffval' & `yeffmax' < -.5 +1.45*`noeffval') | (`yeffmin' > .5 +.55*`noeffval' & `yeffmax' > .5 +.55*`noeffval') loc noeffline ""

loc ytxt "`upb' `bmod' `lowb'"
loc legtxt `""  — — — —    Upper Bound" " " "  —————    Effect of `legefftxt'" " " "  — — — —    Lower Bound""'
loc lptxt "dash solid dash"
loc ordtxt `" order ( 1 "Upper Bound" 2 "Effect of `legefftxt'" 3 "Lower Bound")"'
if strmatch("`pltsigmark'","*Yes*") == 0 {
	loc ytxt " `bmod' "
	loc legtxt `" "  —————    Effect of `legefftxt'" "'
	loc lptxt "solid "
	loc ordtxt `" on label( 1 "Effect of `legefftxt'")"'	
}

loc lgap=3.5
if "`m2var'" != "" {
	loc lgap =1
	if mod(`mstp2',3) ==0 | (mod(`mstp2',3) ==2 & `m2' <= 3*int(`mstp2'/3)) loc lgap = .9
	if mod(`mstp2',3) ==1 & `m2' <= 3*(int(`mstp2'/3)-1) loc lgap = .9
	if `mstp2' == 4 | `mstp2'==2 loc lgap = 1
	loc lgap=.5
}

scatter `ytxt'  `m1var' if `bmod' < . & `fvarnum' == `fnum' & inrange(`m1var', `xfirst' , `xlast')  `addif' , conn(l l l ) /// 
	lp(`lptxt' ) lc(black black black ) ms(i i i ) `noeffline' scheme(s1mono)  /// 
	ysc(r(`yeffmin' `yeffmax'))  `noplt' ylab(`ylabmin'(`ylabinc')`ylabmax' , nogrid form(%9.`ndig'f) labsize(*1.2) labgap(*`lgap')) lw(*1 *1 *1 *.8) ///
	name(`name'`top'`gnmadd', replace) 	title("`titletxt'",  size(`titsz') m(b+1)) `subtittxt' xti("${mvldisp1$sfx}", size(*1) m(t+1))   /// 
	yti("Effect on `dvtxt'", size(*.85) m(r+2)) graphreg(fc(white) ma(zero) style(none)) xlab( ${mvrange1$sfx} , labsize(*1.2) form(%9.${mvdigit1$sfx}f)) xsc(r(`xmin' `xmax')) ///
	plotr(m(tiny) style(none)) legend( col(1) `ordtxt' size(*1) pos(6) rowg(*.5)) `legoff' `xaxoff' ///
	   `pltopts' `addsig1' `addns1' `addsig2' `addns2' `addsig3' `addns3'  

 

if "`frqmat'" != "" {

loc ylabsz = 1.2
if "`m2var'" != "" | ${fcnum$sfx} > 1 loc ylabsz = .96

loc xlabopt ""
if strpos("`pltopts'","xlab") !=0 {
	loc nw=wordcount("`pltopts'")
	forvalues ww=1/`nw' {
		loc xword: word `ww' of `pltopts' 
		if strmatch("`xword'","*xlab*") == 1 loc xlabopt "`xword'"
	}
}

tw spike `vv' `m1cat',  ysca(reverse r(0) ) scheme(s1mono) ylabel( `=`ypctmax'/3' " " `=`ypctmax'/3*2' " "  `ypctmax', nogrid labsize(*`ylabsz') labgap(*`lgap') ) /// 
	yline(0, lw(*.8) ) xlabel(${mvrange1$sfx} , labsize(*1) form(%9.${mvdigit1$sfx}f)) fysize(20)   name(`name'Bot`gnmadd', replace)   /// 
    lc(black) lw(*5) graphregion(margin(zero) style(none))  ytitle("Pct", size(*.85) margin(r+2)) xtitle("${mvldisp1$sfx}" , size(*1) m(t+2) ) ///
	xsc(r(`xmin' `xmax')) plotr(m(l=0 r=0 t=0 b=0) style(none)) nodraw `xlabopt'

	if "`m2var'" != "" | ${fcnum$sfx} > 1  ///
		graph combine `name'Top`gnmadd' `name'Bot`gnmadd', ysize(4.5) xsize(5)  xcommon cols(1) name(`name'`gnmadd', replace) ////
			graphreg(fc(white) style(none)) plotr(m(tiny) style(none)) imargin(0 0 0 0) nodraw iscale(*1.3)
			
	if "`m2var'" == "" & ${fcnum$sfx} == 1  ///
		graph combine `name'Top`gnmadd' `name'Bot`gnmadd', ysize(4.5) xsize(5)  xcommon cols(1) name(`name'`gnmadd', replace) ////
			graphreg(fc(white) style(none)) plotr(m(tiny) style(none)) imargin(0 0 0 0) /// 
			cap(`legtxt', pos(6) linegap(*.25) j(left) margin(t+1 b+1) fc(white) bmargin(t+2) box size(*.8) ) iscale(*1.3)
	
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
		B`=`rownum'+2' = "  Mod2= ${mvldisp2$sfx}"  B`=`rownum'+3' = "  Mod3= ${mvldisp3$sfx}" 
	loc mv2="."
	if "`m2'" != "" loc mv2 = `m2'
	loc mv3="."
	if "`m3var'" != "" loc mv3 = `m3val'
	if ${plotnum$sfx} == 1	/// 
		putexcel B1 = "Focal= ${fvldisp$sfx}" C1 = "upb" D1 = "bmod" E1 = "lowb" F1= "M1Value" G1 = "M1Label" H1 = "${fvldisp$sfx}" I1="FocalLabel" J1 = "Mod2Value" K1="M2Label" L1 = "Mod3Value" M1="M3Label"
*	mkmat `bmod' `sebar' `m1var' in `=`rownum'-1'/`=`rnadj'-1', mat(`savmat')
	mkmat `upb' `bmod' `lowb' `m1var' in `=`rownum'-1'/`=`rnadj'-1', mat(`savmat')
	putexcel C`rownum'= mat(`savmat') 
	putexcel H`rownum':H`rnadj'= `fnum' I`rownum':I`rnadj'= "${fvlabc`fpnum'$sfx}" J`rownum':J`rnadj'= `mv2' K`rownum':K`rnadj'= "${mvlabm2c`m2'$sfx}" L`rownum':L`rnadj'= `mv3' M`rownum':M`rnadj'= "`mlab3'"
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
loc combti `"`titotheff' Effect of `fvtxt' `titdel'" "Moderated by `titxtcomb'"'
loc combleg `""  — — —      Upper Bound" " " "  ————    Effect of `legefftxt'" " " "  — — —      Lower Bound""'
if strmatch("`pltsigmark'","*Yes*") == 0 {
	loc combleg `" "  —————    Effect of `legefftxt'" "'
}
plotcomb , grphcomb(`grphcomb') title(`combti') grname(`name'`gnmtxt') legend(`combleg') plttype(cbound)
}
if "`keep'" != "keep" & "`grphcomb'" != "" graph  drop `grphcomb'
}
end

