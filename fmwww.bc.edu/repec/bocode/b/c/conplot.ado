*!  conplot.ado 	Version 4.1		RL Kaufman 	11/07/2018

***  	1.0 Create Contour Plot of Moderated Effect. Called by EFFDISP.ADO.  Adapted from CBPLOT Version 3.1
***		2.0 Added user-specified PLTOPTS & fixed minor glitches 
***		3.0	Added mlogit functionality
***		3.1 CCUTS option allows user defined contour cutpoints
***		4.0	Added factor change and spost functionality
***		4.1 Use min and max of mvrange1/mvrange2 to define added xaxis/yaxis (zaxis indirectly) min & max instead of actual variable min and max


program conplot, rclass
version 14.2
syntax  ,  m1var(varname) mlab1(varname) m2var(varname) mlab2(varname) bmod(varname) bsig(varname) crittz(real) ///
	ci(real) fvarnum(varname) fnum(integer)  ///
 [  titotheff(string) titdel(string) dvtxt(string)  m3var(varname) mlab3(string) m3val(real 0) m3ind(integer 1) /// 
   m4ind(integer 0) m4var(varname) mlab4(string) m4val(real 0) ndig(integer 3) frqmat(string) ///
   base(string) KEEP name(string) save(string) pltsigmark(string) heatmap estint(string) ccuts(string asis) pltopts(string asis) ] 
 
tempname   frqvsub  frqvar frqv savmat pct m1cat m2cat sigmat
tempvar    sigm nsm selvar holdbmod


if ${mcnum1$sfx} > 1 | ${mcnum2$sfx} > 1    /// 
	noi disp in red "Contour plots moderators must be interval or nominal with single dummy. One or both are categorical with > 1 category"
qui {
*** Create vars and info for Contour plot, optional significance markers. 
loc hlist ""
loc mstp3 = 1
if "`m3var'" != ""  loc mstp3: list sizeof global(mvrange3$sfx)

foreach i of numlist 2(6)20 25 {
foreach j of numlist 2(6)20 25 {
	loc indx = (`j' + 26*(`i' - 1)) + 26^2*(`m3ind'-1) + `mstp3'*26^2*(`fnum'-1)
	loc hlist "`hlist',`indx'"
}
}
if strmatch("`pltsigmark'","*Yes*") == 1 {
	gen `sigm' = .
	gen `nsm' = .
	gen `selvar' = . 
	replace `selvar' = 1 if inlist(_n `hlist')
	replace `sigm' = `m2var' if `bsig' == 1 & `selvar' == 1
	replace `nsm' = `m2var' if `bsig' == 0 & `selvar' == 1
}
***   Set # of rows/plot for saving plotdata
loc npltrow = 26^2
loc  nofrq ""
***   Create info for freq distn vars if requested 
if  "`frqmat'" != ""  & "`base'" == "tot" {
	noi disp " 'tot' option  not possible for freq distribution for contour plot"
}
if "`frqmat'" != "" & ( "`base'" == "sub"  | "`base'" == "subtot" ) {
	loc nofrq "pct m1cat m2cat"
	loc vnm: coln `frqmat'
	loc cnum=colsof(`frqmat')-1
	loc m2c ""
	mat m1hld = `frqmat'[.,`=`cnum'+1'..`=`cnum'+1']
	loc m1stk ""
	
	forvalues m2i=1/`cnum' {
		loc m2nm: word `m2i' of ${mvrange2$sfx}
		if `m2i' != `cnum' { 
			loc m2c "`m2c' `m2nm' , "
			loc m1stk "`m1stk'  m1hld \"
		}
		if `m2i' == `cnum' { 
			loc m2c "`m2c' `m2nm' "
			loc m1stk "`m1stk'  m1hld "			
		}
	}
	mat m2hld= [`m2c']
	mat m1frqcat = [`m1stk']
	loc m2stk ""
	loc rnum = rowsof(`frqmat')
	
	forvalues m1i=1/`rnum' {
		if `m1i' != `rnum' 	loc m2stk "`m2stk'  m2hld \"
		if `m1i' == `rnum' 	loc m2stk "`m2stk'  m2hld "		
		}
	mat holdm2 = [`m2stk']
	mat m2frqcat = vec(holdm2)	
	mat frqvar= `frqmat'[.,1..`cnum']
	mata: fmat=st_matrix("frqvar"); fsum= sum(fmat); fmax= max(fmat); fsumcol = colsum(fmat); fmaxcol= colmax(fmat); st_numscalar("fsum",fsum); st_numscalar("fmax",fmax); st_matrix("fsumcol",fsumcol); st_matrix("fmaxcol",fmaxcol)
	mat frqvec = vec(frqvar)
	mat frqm1m2 = [frqvec, m1frqcat, m2frqcat]
	mat colnames frqm1m2 = `pct' `m1cat' `m2cat'
	svmat frqm1m2 , names(col)
	mat drop m1hld m2hld m1frqcat m2frqcat holdm2 frqvar frqvec 
***	create freq distn vars & plot if requested.  
	if "`base'" == "subtot" replace `pct' = `pct'/fsum*100 if `pct' < . 	
	loc mstp2: list sizeof global(mvrange2$sfx)
	if "`base'" == "sub" {
		forvalues m2=1/`mstp2' {
			replace `pct' = `pct'/el("fsumcol",1,`m2')*100 if `m2cat' == `m2' & `pct' < . 		
		}
	}
}
****  reset MSTP2
loc mstp2=26
*** Set up substitution text and conditions
loc grphcomb ""
loc noplt "nodraw"
if "`m3var'" == ""  & ${fcnum$sfx} == 1 & "`nofrq'" == "" loc noplt ""
loc addif ""
loc titint "${mvldisp1$sfx}"
if "${bf1m1c1m2c1$sfx}" != "" loc titint " the Interaction of ${mvldisp1$sfx} "
loc titletxt ""`titotheff' Effect of ${fvldisp$sfx} `titdel' on `dvtxt'" "Moderated by `titint' and ${mvldisp2$sfx}""
loc titxtcomb ""
loc titsz = "*.8"

loc titxtfv  ""
if ${fcnum$sfx} > 1 & "`m3var'" == ""  {
	loc titxtfv "`titotheff' Effect of ${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx} `titdel' on `dvtxt' "
	loc titletxt "`titxtfv'"
	loc titsz = "*.8"
}

loc gnmadd ""
if ${fcnum$sfx}>1 loc gnmadd "f`fnum'" 
if "`m3var'" != "" {
	loc addif "& `m3var' == float(`m3val')"
	loc titletxt "`titxtfv'${mvldisp3$sfx} = ${mvlabm3c`m3ind'$sfx}"
	loc titsz = "*.8"
	loc titxtcomb "`titint' and ${mvldisp2$sfx}"
	forvalues j=3/4 {
		if  "`m`j'var'" != "" loc gnmadd "`gnmadd'm`j'`m`j'ind'"
	}
}
loc lft "Lft"
if "`nofrq'" == "" loc lft ""
loc sigmarkers ""
if strmatch("`pltsigmark'","*Yes*") == 1  loc sigmarkers = /// 
	"|| scatter `sigm' `m1var' if `m1var' < . & `sigm' < .  & `selvar' == 1, ms(d) mc( white)  msize( *1) jitter(4) jitterseed(32130387)" ///  
	+ " || scatter  `nsm' `m1var' if `m1var' < . &  `nsm' < .  & `selvar' == 1, ms( o) mc(white)  msize( *.75) jitter(4) "

***** 	Must create & use non-tempvars for contour to work

foreach nm in bmod m2var m1var `nofrq' {
	gen `nm' = ``nm''
}

loc xfirst: word 1 of ${mvrange1$sfx}
loc mlast1: list sizeof global(mvrange1$sfx)
loc xlast: word `mlast1' of ${mvrange1$sfx}
loc xmin = `xfirst'-.05*(`xlast'-`xfirst')
loc xmax = `xlast'+.05*(`xlast'-`xfirst')

loc yfirst: word 1 of ${mvrange2$sfx}
loc mlast2: list sizeof global(mvrange2$sfx)
loc ylast: word `mlast2' of ${mvrange2$sfx}
loc ymin = `yfirst'-.05*(`ylast'-`yfirst')
loc ymax = `ylast'+.05*(`ylast'-`yfirst')


qui summ bmod if inrange(m2var, `yfirst', `ylast') & inrange(m1var, `xfirst', `xlast')  , meanonly
loc cctxt "ccuts(`r(min)'(`=(`r(max)'-`r(min)')/6')`r(max)')"
if "`ccuts'" != "" loc cctxt "ccuts(`ccuts')" 
	
tw contour bmod m2var m1var if bmod < . & inrange(m2var, `yfirst', `ylast') & inrange(m1var, `xfirst', `xlast'), scheme(s1mono) `cctxt' minmax scolor(gs15) ecolor(gs0) lc(white) ///
	  crule(lin) xlab(${mvrange1$sfx}, nogrid labsize(*1.2))  /// 
	  ylab(${mvrange2$sfx}, axis(1) angle(vertical) labsize(*1.2))  xti("${mvldisp1$sfx}", size(*1) m(t+2)) /// 
	  yti("${mvldisp2$sfx}", size(*1) m(r+5)) graphreg(fc(white) ma(zero) style(none)) lc(black) lw(*2) /// 
	  ztitle("Effect Ranges", orientation(rvertical) m(l+5)) plotr(m(tiny) style(none))   ///     
	  name(`name'`lft'`gnmadd', replace) 	title(`titletxt',  size(`titsz') m(b+3)) clegend(on) clegend(region(lcolor(black)))   ///
	  plotregion(margin(medium) icolor(white)) zlab(, labsize(*.9) format(%7.`ndig'f) tposition(inside) /// 
	  tlength(*3.3) labgap(*2) tlc(white) )  fysize(72) fxsize(100) `heatmap' `pltopts' legend(off)  `noplt' `sigmarkers' 
	
if "`nofrq'" != "" {

	tw contour pct m2cat m1cat  if pct < ., scheme(s1mono) zlab(#7) minmax scolor(gs15) ecolor(gs0) lc(white) ///
		crule(lin) name(`name'Rgt`gnmadd', replace)   xlab(${mvrange1$sfx} , nogrid labsize(*.9))   /// 
		ylab(${mvrange2$sfx} , axis(1) angle(vertical) labsize(*.9)) xtitle("${mvldisp1$sfx}" , marg(t+3) size(*.7)) /// 
		ytitle("${mvldisp2$sfx}" , m(r+3) size(*.7))  lc(black) lw(*2) ztitle("% Ranges", orientation(rvertical) m(l+1) size(*.65)) ///     
		title("Frequency",   size(*.6) marg(b+1) justification(left)) clegend(on) clegend( pos(6) region(lcolor(black)))   ///
		plotregion(margin(medium) icolor(white)) zlab(, labsize(*.7) format(%3.0f) tposition(inside) tlength(*3.3) labgap(*2) tlc(white) ) /// 
		fysize(75) fxsize(50) nodraw 

	if "`m3var'" != "" | ${fcnum$sfx} > 1  ///
		graph combine `name'Lft`gnmadd' `name'Rgt`gnmadd',  rows(1) ysize(6.5) xsize(12) name(`name'`gnmadd', replace) ////
			graphreg(fc(white) style(none) ) plotr(m(small) style(none)) nodraw iscale(*1.4)
			
	if "`m3var'" == "" & ${fcnum$sfx} == 1  ///
		graph combine `name'Lft`gnmadd' `name'Rgt`gnmadd', rows(1) ysize(6.5) xsize(12) name(`name'`gnmadd', replace) ////
			graphreg(fc(white) style(none)) plotr(m(small) style(none))  iscale(*1.4)
	
graph drop `name'Lft`gnmadd' `name'Rgt`gnmadd'
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
		loc mv3="."
	if "`m3var'" != "" loc mv3 = `m3val'
	if ${plotnum$sfx} == 1	{  
		putexcel B1 = "Focal= ${fvldisp$sfx}" C1 = "bmod" D1 = "M1Value" E1 = "M2Value" F1= "M1Label" G1 = "M2Label" H1 = "${fvldisp$sfx}" I1="FocalLabel" J1 = "Mod3Value" K1="M3Label" 
		if strmatch("`pltsigmark'","*Yes*") == 1 putexcel L1 = "sigmark" M1 = "notsigmark" N1 = "m1mark"
	}
	mkmat `bmod' `m1var' `m2var' in `=`rownum'-1'/`=`rnadj'-1', mat(`savmat')
	putexcel C`rownum'= mat(`savmat') 
	putexcel H`rownum':H`rnadj'= `fnum' I`rownum':I`rnadj'= "${fvlabc`fpnum'$sfx}"  J`rownum':J`rnadj'= `mv3' K`rownum':K`rnadj'= "`mlab3'"
	mata: mlabs = st_sdata((1,`npltrow'),("`mlab1' `mlab2'")); b=xl();b.load_book("`save'"); b.set_sheet("plotdata_${eqnow$sfx2}"); b.set_mode("closed"); b.put_string(`rownum',6,mlabs)
		if strmatch("`pltsigmark'","*Yes*") == 1 {
			mkmat `sigm' `nsm' `m1var' in `=`rownum'-1'/`=`rnadj'-1' if `sigm' < . | `nsm' < . , mat(`savmat')
			putexcel L`rownum'= mat(`savmat') 
		}
}
*
if "`m3var'" != ""  loc grphcomb "`grphcomb' `name'`gnmadd'"
if ( ${fcnum$sfx} > 1 & ${mvarn$sfx} == 2) | ( ${fcnum$sfx} == 1 & ${mvarn$sfx} == 3)   glo grnames$sfx "${grnames$sfx} `name'`gnmadd'"

if "`m3var'" != "" {
	loc mstp3: list sizeof global(mvrange3$sfx)
	if `mstp3' > 3 | ${fcnum$sfx} > 1  glo pannum$sfx = ${pannum$sfx} + 1
	loc fvtxt "${fvldisp$sfx}"
	if ${fcnum$sfx} > 1 loc fvtxt "${fvldisp$sfx}: ${fvlabc`=`fnum'+1'$sfx}"
	loc combti `"`titotheff' Effect of `fvtxt' `titdel'" "Moderated by `titxtcomb'"'
	loc combleg "NONE"
	plotcomb , grphcomb(`grphcomb') title(`combti') grname(`name') legend(`combleg') plttype(contour)
	}
if "`keep'" != "keep" & "`grphcomb'" != "" graph  drop `grphcomb'
}
capture: drop bmod m1var m2var `nofrq'
end

