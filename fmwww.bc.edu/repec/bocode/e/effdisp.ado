*!  effdisp.ado 	Version 7.6	RL Kaufman 	04/05/2019

***  	1.0 Work with standard MAIN INT2 INT3 option specification. Use DEFINEFM.ADO to define focal & moderator vars & properties 
***			MAIN string contains (varlist1, name(word) cat range(numlist)) (varlist2, name(word)  cat range(numlist))
***			ADDED options:  CILEV(#,adjtype)  p=.05 default, adjtypes = POThoff BONferroni (can specify both). NDIGITS for format default=4
***
***			PLOT(type(name) name(name) gen(name) keep save(filepath) freq(name). TYPE default is Error Bars for nominal M1 (inclduing single dummy) 
***			and Confidence Bounds  for interval M1. Option for doing Contour Plot.  NAME is graph name, GEN(name) is name=varstub for saving plot info as vars. 
***			SAVE saves matrices with plotinfo to filepath.  FREQ attaches relaktve freq  distn plot to each effect display plot
***			(side by side smaller contour for contour plot), name speciifes base & if by M2:  TOT=M1 base total sample ///
***			SUB= M1 x M2 base defined by subsamples of M2. SUBTOT = M1 x M2 base defined by total samples
***			KEEP means  do not delete subplots after combining.
***			CBOUND plot functional
***
***		2.0	Added SERRBAR plot functionality
***
***		3.0	Added preserve, put quiet on, removed checking code and generally cleaned up code.  
****		Added to PLOT() syntax OPTS(asis) to allow user options, excludes LEVELS as separate option.
***			UNDOCUMENTED OPTION: MYGLOB(KEEP) so I can check easily. Added SUMWGT(no) option so user can requested use of unweighted summary statistics.
***		4.0  Adapted to use intspec.ado to set-up and save the globals for the interaction specification for re-use.  SUMWGT now INTSPEC option
***		5.1	Added mlogit functionality, 1st pass at getting drop-line and connected line plots
***		6.0	Added drop-line and connected line plots
***		6.0	Added CCUTS optioN for user defined contour cutpoints
***		7.0	Added Factor Change and SPOST coeff functionality
***		7.1  Added Sidak correction to multiple testing options
***		7.3  Added survuval models as allowable for factor change effect (check existence e(t0) = _t0)
***		7.4  set matsize to 676 if max_matsize >= 676, needed for plotting and saving plotdata
***		7.5  Use min and max of mvrange1/mvrange2 to define calculation points for contour plot instead of actual variable min and max
***		7.6  Fix error in putexcel code only on mac OS platforms when using save() option

program effdisp, rclass sortpreserve
version 14.2
syntax  ,  [ CIlev(string) DETAIL NDIGits(integer 4) effect(string) plot(string)  ///
	 SIGMARK heatmap ccuts(string asis) pltopts(string asis) ] 
tempname frqmat h2 hold obsmatch estint effb effvb mchg
tempvar   m1val m2val m3val m4val fvarnum bmod bmodup bmodlo bmodsig m1vlab m2vlab m3vlab m4vlab fvlab m1vnm m2vnm m3vnm m4vnm fvnm predstd

qui {

***		check if globsave file created by instspec.ado & definefm.ado

if  fileexists("`c(tmpdir)'/globsaveeq1$sfx2.do") ==0 {
	noi disp "{err: Must run intspec.ado to setup and save interaction specification first}"
	exit
}

*** PRESERVE DATA & CURRENT ESTIMATES ON EXIT

preserve
est store `estint' 
glob dvcat$sfx "`e(k_cat)'"

*** load globals from eq1 to use in setup and  if-branching
capture drop esamp$sfx
qui run `c(tmpdir)'/globsaveeq1$sfx2.do

*** Get coeftype  for plotting, set defaults and parse out delta for factor change or spost specs
loc coeftype "b"
loc fcdel  "1"
loc titdel "(`= ustrunescape("\u0394")' = 1)"
loc amtopt "am(one)"
loc atopt "(asobs) _all"
loc noeff = 0
glob ystd$sfx = 1

loc hctype=strtrim(stritrim(`"`effect'"'))
gettoken coeftype hctype : hctype , parse("()")
if "`coeftype'" == "spost" loc titdel ""
gettoken  hctype ctopt: hctype , bind match(pp)
while `"`hctype'"' != ""  & `"`hctype'"' !=  " " {
	gettoken ctopt hctype : hctype ,  bind match(pp) 
	if "`coeftype'" == "factor" | "`coeftype'" == "b"  {
		if "`ctopt'" != ""  { 
			loc fcdel  "`ctopt'"
			loc titdel "(`= ustrunescape("\u0394")' = `ctopt')"
		}
		if "`ctopt'" == "sd" { 
			loc fcdel "${fsd$sfx}"
			loc titdel "(`= ustrunescape("\u0394")' = 1 s.d.)"
		}
		if "`ctopt'" == "sdy" | "`ctopt'" == "sdyx" { 
			loc ystand "no"
			loc xstand "no"
			glob ystd$sfx = 1

			if inlist("`e(cmd)'","logit","logistic","ologit","probit", /// 
			  "oprobit","poisson","nbreg","zip","zinb")==1 {
				loc ystand "yes"
				if inlist("`e(cmd)'","logit","logistic","ologit","probit","oprobit")==1  {
					loc errvar = 1
					if inlist("`e(cmd)'","logit","logistic","ologit") ==1 	loc errvar = _pi^2/3
					predict `predstd' if e(sample), xb
					qui sum `predstd' if e(sample)
					glob ystd$sfx = (`r(Var)' + `errvar')^.5
				}
				if inlist("`e(cmd)'","poisson","nbreg","zip","zinb")==1 {
					qui sum `e(depvar)' if e(sample)
					glob ystd$sfx = (`r(Var)'/`r(mean)'^2)^.5
				}
			}
			if "`ystand'" == "yes" {
				loc fcdel=1/${ystd$sfx}
				loc titdel "(g(y)-standardized)"
				if "`ctopt'" == "sdyx" {
					loc fcdel= `fcdel'*${fsd$sfx}	
					loc xstand "yes"
					loc titdel "(g(y)- & focal- standardized)"					
				}
			}
			if "`e(cmd)'" == "mlogit" {
				loc ystand "yes" 
				if "`ctopt'" == "sdyx" loc xstand "yes"
			}
			if "`ystand'" == "no" noi disp _newline "{err: g(y) standardization not valid option for {txt: `e(cmd)'}. Option ignored.}"
		}
	} 
	if "`coeftype'" == "spost" {
		gettoken ctopt2 ctopt : ctopt , parse("(")
		gettoken ctopt3 ctopt : ctopt , bind match(pp)
		foreach nm in amtopt atopt {
			if strmatch("`ctopt2'","`nm'")	loc `nm' `"`ctopt3'"'
		}
	}
}
if "`coeftype'" == "" loc coeftype "b"
*** Check applicability of factor change option
loc fcc "no"
 if "`coeftype'" == "factor" {
	loc noeff=1
	if inlist("`e(cmd)'","logit","logistic","ologit","mlogit","poisson","nbreg","zip","zinb")==1 | "`e(t0)'" == "_t0" loc fcc "yes"
	if "`fcc'" == "no" {
		loc coeftype "b" 
		loc noeff=0
		noi disp _newline "{err: factor change not valid option for {txt: `e(cmd)'}. Option ignored.}"
	}
}
*** Report back Effect type info specified
noi disp _newline as txt "{ul:Effect type Specified}" _newline
noi disp as txt "   Effect type = " as res "`coeftype'   `titdel' " 
if "`coeftype'" == "spost"  noi disp as txt "        Spost amount options: " as res "`amtopt'" _newline as txt "        Spost at options: " as res "`atopt'"
 

***  Get plot options PLtTYPE, PLTNAME, PLTGEN ,PLTSAVE PLTKEEP & PLTFREQ

if `"`plot'"' != "" {
	foreach nm in type name gen save keep freq {
		loc plt`nm' ""
	}
	loc hplot=strtrim(stritrim(`"`plot'"'))
	while `"`hplot'"' != ""  & `"`hplot'"' !=  " " {
		gettoken plotopt hplot : hplot , bind match(pp) 
		tokenize `plotopt', parse("()") 
		foreach nm in type name gen save keep freq {
			if "`1'" == "`nm'" { 
				loc plt`nm' `"`3'"'
				if "`nm'" == "keep" loc pltkeep "keep"
			}
		}	
	}
}

loc pltsigmark "No"
if "`sigmark'" != "" | "`plttype'" == "cbound" | "`plttype'" == "errbar" | "`plttype'" == "" loc pltsigmark "Yes"
if "`sigmark'" != "" & "`plttype'" == "line" loc pltsigmark "Vertical"

** set matsize if too small for plots
loc msz = 676
if "`plttype'" == "contour" & ${mvarn$sfx} > 1  {
	loc m2n: list sizeof global(mvrange2$sfx)
	loc msz = 676*`m2n' 
}

if `c(max_matsize)' < `msz' { 
	noi disp in red "maximum matsize < minimum needed (676) for plot"
	exit
}
if `c(matsize)' < `msz' set matsize `msz'

*** Report back options specified
noi disp _newline as txt "{ul:Plot Options Specified}" _newline
loc nospec "true"

foreach nm in type name gen save keep freq sigmark {
	if "`plt`nm''" != "" { 
		noi disp as txt "   `nm' = " as res " `plt`nm''"
		loc nospec "false"
	}
}
if "`nospec'" == "true" noi disp "None specified"


*** set PLTTYPE to default if not specified.  All other options have no defaults: Not done if not specified
if "`plttype'" == "" {
	loc pltsigmark "Yes"
	loc plttype "cbound"
	if "${mviscat1$sfx}" == "y" |  "${misfv1$sfx}" == "y"	loc plttype "errbar"
	loc mod1 = 1
	noi disp as txt "   type = " as res " `plttype'" as txt " by default"
}
if "`plttype'" == "cbound"  & ( ${mcnum1$sfx} > 1 | "${mviscat1$sfx}" == "y" ) {
	noi disp as err _newline "Moderator 1 (${mvldisp1$sfx}) is categorical but must be interval for a C-Bound Plot"
	exit
}
if ${mvarn$sfx} > 1 {
if "`plttype'" == "contour"  & (( ${mcnum1$sfx} > 1 | "${mviscat1$sfx}" == "y" ) | ( ${mcnum2$sfx} > 1 | "${mviscat2$sfx}" == "y" ) ) {
	noi disp as err _newline "Moderator 1 (${mvldisp1$sfx}) and/or Moderator 2 (${mvldisp2$sfx}) is categorical but must be interval for a Contour Plot"
	exit
}
}

if "`plttype'" == "contour"  & ${mvarn$sfx} < 2 {
	noi disp as err _newline "Must have 2 (interval) Moderators for a Contour Plot, only 1 Moderator specified: ${mvldisp1$sfx} "
	exit
}
if "`plttype'" == "line" loc plttype "cbound"
if "`plttype'" == "drop" loc plttype "errbar"

loc grphnmroot "`pltname'"
if "`pltname'" == "" loc grphnmroot =strtoname("${fvldisp$sfx}_${mvarn$sfx}Mods")

*** Set critical value level using PSIG = alpha adjusted if specify Bonoferroni, Sidak and/or Pothoff. Save distribution type DIST
gettoken cival mult : cilev , parse(",")  
loc ciprp=.95
if "`cival'" != "" loc ciprp = `cival'
loc psig=1-`ciprp'
loc dist "Chi_sq" 
loc adj1 ""
if strmatch("`mult'","*bon*") ==1 {
	loc psig= `psig'/(${fcnum$sfx}*(${fcnum$sfx}+1)/2)
	loc adj1 "bonferroni"
}
if strmatch("`mult'","*sid*") ==1 {
	loc psig= 1-(1-`psig')^(1/${fcnum$sfx})
	loc adj1 "sidak"
}
loc adj2 ""
loc qpot=0
if strmatch("`mult'","*pot*") ==1 { 
	forvalues i=1/${mvarn$sfx} {
		loc qpot= `qpot' + ${mcnum`i'$sfx}
	}
	loc adj2 "potthoff"	
}
if "`e(F)'" == ""   loc critfc = invchi2tail(`qpot'+1,`psig')

if "`e(F)'" != "" 	{ 
	loc critfc= invFtail(`qpot'+1,`e(df_r)',`psig')
	loc dist "F" 
}
loc crittz = `critfc'^.5

noi disp _newline as txt "`=`ciprp'*100'% Confidence intervals calculated with critical value `dist' = " as res %8.3f `critfc' as txt " ."  _newline
noi if "`adj2'" != "" | "`adj1'" != "" disp as txt "   alpha-value adjusted by {res:`adj1' `adj2'} method(s)" _newline

***		If Freq Dist requested construct matrix
if "`pltfreq'" != "" {
	frqmod , mod1(${mvlist1$sfx}) freq(`pltfreq')
	mat `hold' = r(frqmat)
	mat `frqmat' = `hold''
	loc mstp1: list sizeof global(mvrange1$sfx)	
	loc mstp2 = 1
	loc cn "Count"
	if "`pltfreq'" != "tot" {
		loc mstp2: list sizeof global(mvrange2$sfx)	
		loc cn ""
		forvalues j=1/`mstp2' {
			loc cn "`cn' ${mvlabm2c`j'$sfx}"
		}
		loc cn "`cn' Focal_value"
	}
	mat colnames `frqmat' = `cn'
	loc rn ""
	forvalues i=1/`mstp1' {
		loc rn "`rn' ${mvlabm1c`i'$sfx}"
	}
	mat rownames `frqmat' = `rn'
	mat `hold' =`frqmat'[.,1..`mstp2']

}

***  Loop over # of Equations  ( =1 except for mlogit & others TBD)
***     For ologit/oprobit and SPOST effect, set eqitot = # of DV categories 
***
loc eqitot = ${eqnum$sfx2} 
if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost"  loc eqitot =  ${ordcatnum$sfx2} 

loc fopenyet "no"

forvalues eqi=1/ `eqitot' {
glob eqnow$sfx2: word `eqi' of ${eqlist$sfx2}
if "${eqnow$sfx2}" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 & ( "`e(cmd)'" != "mlogit" | ///
	( "`e(cmd)'" == "mlogit"  & "`coeftype'" != "spost" )  ) continue

***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
if "${ordcatnum$sfx2}" == "" | "`coeftype'" != "spost" qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do
loc titdv "g(${dvname$sfx})"
if "`coeftype'" == "spost" | "`coeftype'" == "factor" loc titdv "${dvname$sfx}"

loc dvadd ""
loc margout ""

if "${ordcatnum$sfx2}" !="" & "`coeftype'" == "spost" {
	qui run `c(tmpdir)'/globsaveeq1$sfx2.do
	loc dvadd ":${eqnow$sfx2}"
		loc margout "out(`eqi')"
}



loc grphnm "`grphnmroot'"
if ${eqnum$sfx2} > 1 | "${ordcatnum$sfx2}" !="" loc grphnm "`grphnmroot'_${eqnow$sfx2}"

if "`ystand'" == "yes"  & "`estcmd'" == "mlogit" {
	loc errvar = _pi^2/3
	capture drop `predstd' 
	predict `predstd' if e(sample), xb outcome("${eqnow$sfx2}")
	qui sum `predstd' if e(sample)
	glob ystd$sfx = (`r(Var)' + `errvar')^.5
	loc fcdel=1/${ystd$sfx}
	loc titdel "(g(y)-standardized)"
	if  "`xstand'" == "yes" {
		loc fcdel= `fcdel'*${fsd$sfx}	
		loc titdel "(g(y)- & focal- standardized)"					
	}
}
loc titdv "g(${dvname$sfx})"
loc titotheff "" 

if "`coeftype'" == "spost" | "`coeftype'" == "factor" {
	loc titdv "${dvname$sfx}`dvadd'"
	loc titotheff "Factor " 
	if "`coeftype'" == "spost" 	loc titotheff "SPOST " 
}

if "`coeftype'" == "spost" & "`e(cmd)'" == "mlogit" {
	loc titdv "`e(depvar)'[${eqnow$sfx2}]"
*	loc amtopt "`amtopt' out(`eqi')"
}
if `eqi' ==1 loc titdelhold "`titdel'"
*loc titdel "`titdelhold' on ${dvname$sfx}`dvadd'"

***		If Save plot data requested, Set up save spreadsheet & save Freq Dist if used

if "`pltsave'" != "" {
	loc savenm `"`pltsave'"'
	if strpos("`savenm'",".") == 0 loc savenm `"`savenm'.xlsx"'
	noi disp _newline  as txt "Plot data written to sheet {res:{it:plotdata_${eqnow$sfx2}}} of " as res "`savenm'"
	glob plotnum$sfx=0
	
	loc repmod "modify"
	if "`fopenyet'" == "no" {
		loc repmod "replace"
		loc fopenyet "yes"	
	}
	putexcel set "`savenm'" , sheet(frqdistdata, replace) `repmod'
	putexcel A1 = (" ") 
	putexcel set "`savenm'" , sheet(plotdata_${eqnow$sfx2}, replace) modify
	putexcel A1 = ("`titotheff' Effect `titdel' Plot ") 
	mata: b=xl();b.load_book("`savenm'"); b.set_sheet("plotdata_${eqnow$sfx2}"); b.set_mode("closed"); b.set_column_width(2,2,40);b.set_text_wrap(2,2,"on")
	if "`pltfreq'" != ""  {
	noi disp _newline  as txt "Frequency distribution data written to sheet {res:{it:frqdistdata}} of " as res "`savenm'"

		putexcel set "`savenm'" , sheet(frqdistdata) modify
		putexcel B2 = mat(`frqmat'[.,1..`mstp2']) , names right
		putexcel B2 = ("${mvldisp1$sfx}")  , italic
		loc rown = 3+(2+`mstp1')
		mata: fmat=st_matrix("`hold'"); fsum= sum(fmat); fsumcol = colsum(fmat);  st_numscalar("fsum",fsum);  st_matrix("fsumcol",fsumcol); 
		mat `h2' = `hold'*100/fsum
		if  "`pltfreq'" == "tot" {
			putexcel E2 = mat(`h2') , names nform(".0") right
			putexcel C2 = ("Count")
			putexcel E2 = ("${mvldisp1$sfx}")  , italic
			putexcel F2 = ("Percent")
		}
		if  "`pltfreq'" != "tot" {
			putexcel B`=`rown'+2' = mat(`h2') , names nform(".0")
			mat `h2' = `hold'
			
			forvalues i=1/`mstp1' {
			forvalues j=1/`mstp2' {
				sca hhh = 100/el("fsumcol",1,`j')
				mat `h2'[`i',`j'] = `hold'[`i',`j']*hhh
			}
			}
			putexcel B`=2*`rown'+1' = mat(`h2') , names nform(".0")
			putexcel A`rown' = ("Total Percents")  A`=2*`rown'-1' = ("Col Percents") 
			putexcel C1 = ("${mvldisp2$sfx}")  B`=`rown'+2' = ("${mvldisp1$sfx}")  C`=`rown'+1' = ("${mvldisp2$sfx}") B`=2*`rown'+1' = ("${mvldisp1$sfx}")  C`=2*`rown'' = ("${mvldisp2$sfx}"), italic		
		}
	}
mata: b.set_mode("closed")
}


/*
if "`pltsave'" != "" {
	glob plotnum$sfx=0
	putexcel set "`pltsave'" , sheet(frqdistdata) replace
	putexcel A1 = " " 
	putexcel set "`pltsave'" , sheet(plotdata) replace
	putexcel A1 = " " 
	mata: b=xl();b.load_book("`pltsave'"); b.set_sheet("plotdata"); b.set_mode("closed"); b.set_column_width(2,2,40);b.set_text_wrap(2,2,"on")
	if "`pltfreq'" != "" {
		putexcel set "`pltsave'" , sheet(frqdistdata) modify
		putexcel B2 = mat(`frqmat') , names
		putexcel B2 = "m1catlab" 
	}
}
*/

***** Start plot loop set up **************************************************************************************************************
*** 	Loop over # Focal var categories. If only M1 combine subplots over focal var cats. 
***		otherwise create 1 combined over M2 for each combination of M3 by M4

forvalues i=2/4 {
	loc mod`i' ""
	loc mstp`i' = 1
	loc rval`i' ""
	loc rvalplt`i'=.
	loc rlab`i' "."
	if ${mvarn$sfx}  >= `i' {
		loc mstp`i': list sizeof global(mvrange`i'$sfx)
		loc mrng`i' = `mstp`i''
		loc mod`i' = `i'		
	}
} 

***	Set loop info for M1 & M2 depending on PLTTYPE  
***		CBOUND & ERRRBAR:  List of Display values & MSTP2 already # values 
***		CONTOUR: 26 plot points min(inc)max  

***		CREATE ERRBAR OPTION TO CONNECT CI POINTS

***  M1 info
loc mstp1: list sizeof global(mvrange1$sfx)
loc mrng1 = `mstp1'

if "`plttype'" ==  "errbar"  loc looplst1 "${mvrange1$sfx}"	
if "`plttype'" == "cbound" {
	loc mstp1=51
	numlist "${mmin1$sfx}(`=(${mmax1$sfx}-${mmin1$sfx})/50')${mmax1$sfx}"
	loc looplst1 "`r(numlist)'"
}
if "`plttype'" ==  "contour" {
	loc mstp1=26
	loc xfirst: word 1 of ${mvrange1$sfx}
	loc mlast: list sizeof global(mvrange1$sfx)
	loc xlast: word `mlast' of ${mvrange1$sfx}
	numlist "`xfirst'(`=(`xlast'-`xfirst')/25')`xlast'"
	loc looplst1 "`r(numlist)'"
}
if ${mvarn$sfx} > 1 {
***  M2 info
	if "`plttype'" == "cbound" | "`plttype'" ==  "errbar"  loc looplst2 "${mvrange2$sfx}"		
	if "`plttype'" ==  "contour" {
		loc mstp2=26
		loc xfirst: word 1 of ${mvrange2$sfx}
		loc mlast: list sizeof global(mvrange2$sfx)
		loc xlast: word `mlast' of ${mvrange2$sfx}
		numlist "`xfirst'(`=(`xlast'-`xfirst')/25')`xlast'"
		loc looplst2 "`r(numlist)'"
	}
}
*****************************************************************************************************************************
***
***  	Need to loop over FCI & M2-M4 twice , once to create matrices in MATA with plot data & then to create plots
***
***		FIRST LOOP

*** Loop over additional moderators.  M1 plus up to 3  more.  Set loop m# stop val = 1 if MOD# not specified
***
***		Set up loop var display values & labels (RVAL3/RLAB3, RVAL4/RLAB4). For multicat use cat names for "value" labels
***			For interval/single dummmy nominal: RVAL=display value
***			For multi-cat nominal: RVAL=1 for non-Base categories but =0 for Base category so rval*b = 0

*** Set up mata matrix for data transfer to/from Stata , matching ID to save MATA matrix to particular observations
***		Counters NDI = running total  NDW = running count reset at 1000 when write

loc ndat = `mstp1' * `mstp2' * `mstp3' * `mstp4'*${fcnum$sfx}
if `ndat' > _N set obs `ndat'
capture drop `obsmatch'
gen int `obsmatch' = _n 
loc ndi = 0
loc ndw = 0

***  PLTNUM has values in cols 1-9 for m1, m2, m3, m4, fci ,bmod, upbmod, lobmod, bsig .  
*** PLTLAB has corresponding labels col 1-5 and varnames col 6-10 for values for the values in PLTNUM. 
loc nrow=1000
if `ndat' < `nrow' loc nrow=`ndat'
mata: pltnum=J(`nrow',9,.) ;  pltlab=J(`nrow',10," ") ; `obsmatch'=J(`nrow',1,.)

*** initialize string variables created from pltlab to be length 30
foreach v in m1vlab m2vlab m3vlab m4vlab fvlab m1vnm m2vnm m3vnm m4vnm fvnm {
	capture drop ``v''
	gen str30 ``v'' = "."
}


forvalues fci = 1/${fcnum$sfx} {

forvalues m4=1/`mstp4' {
	if "`mod4'" != "" {
		loc rval4: word `m4' of ${mvrange`mod4'$sfx}
		loc rvalplt4=`rval4'
		loc rlab4 = "${mvlabm`mod4'c`m4'$sfx}" 
		loc  mc4=1
		
*** if CAT 1st category  set rval4= 0  and   mc4= 1, else rval4= 1 mc=4 mm-1 
		if ${mcnum`mod4'$sfx} >1 {	
				loc rval4=inrange(`m4',2,`mstp4')
			loc mc4=`m4'-1*inrange(`m4',2,`mstp4')
		}
	}
forvalues m3=1/`mstp3' {
	if "`mod3'" != "" {
	loc rval3: word `m3' of ${mvrange`mod3'$sfx}
		loc rvalplt3=`rval3'
	loc rlab3 = "${mvlabm`mod3'c`m3'$sfx}"
	loc mc3=1
	
*** if CAT 1st category  set rval3= 0  and   mc3= 1, else rval3= 1 mc=3 mm-1 

		if ${mcnum`mod3'$sfx} >1 {
			loc rval3=inrange(`m3',2,`mstp3')
			loc mc3=`m3'-1*inrange(`m3',2,`mstp3')
		}
	}

forvalues m2=1/`mstp2' {
	if "`mod2'" != "" {
		loc rval2: word `m2' of `looplst2'
		loc rvalplt2=`rval2'
		loc rlab2 = "${mvlabm`mod2'c`m2'$sfx}"
		loc mc2=1

*** if  CONTOUR reset labels
	if "`plttype'" == "contour" {
		loc rlab2 ""
		forvalues i=1/`mrng2' {
			loc llab: word `i' of ${mvrange`mod2'$sfx}
			if `rval2' ==  `llab' {
				loc rlab2= strofreal(`llab',"%10.2f")
			}
		}
	}

*** if CAT 1st category  set rval2= 0  and   mc2= 1, else rval2= 1 mc2= mm-1 

	if ${mcnum`mod2'$sfx} >1 {
		loc rval2=inrange(`m2',2,`mstp2')
		loc mc2=`m2'-1*inrange(`m2',2,`mstp2')
	}
}	
forvalues m1=1/`mstp1' {
	loc rval1: word `m1' of `looplst1'
	loc rvalplt1 = `rval1'
	loc rlab1 = "${mvlabm1c`m1'$sfx}"
	loc mc1=1
	
*** if CBOUND or CONTOUR reset labels
	if "`plttype'" != "errbar" {
		loc rlab1 ""
		forvalues i=1/`mrng1' {
			loc llab: word `i' of ${mvrange1$sfx}
			if `rval1' ==  `llab' {
				loc rlab1= strofreal(`llab',"%10.2f")
			}
		}
	}
*** if CAT 1st category  set rval1= 0  and   mc1= 1, else rval1= 1 mc=1 mm-1 

	if ${mcnum1$sfx} >1 {
		loc rval1=inrange(`m1',2,`mstp1')
		loc mc1=`m1'-1*inrange(`m1',2,`mstp1')
	}

if "`coeftype'" != "spost"	{ 
getbvarbmod , fnum(`fci') mods(1 `mod2' `mod3' `mod4') modsc(`mc1' `mc2' `mc3' `mc4') /// 
	modsv(`rval1' `rval2' `rval3' `rval4' ) int3(${int3way$sfx}) eqn(${eqname$sfx})
	loc effb = `r(bmod)'*`fcdel'
	loc effupb = `effb'+`fcdel'*`r(vbmod)'^.5*`crittz'
	loc efflob = `effb'-`fcdel'*`r(vbmod)'^.5*`crittz'
	loc effsig = 1- inrange(0,`efflob', `effupb')
	if "`coeftype'"== "factor" {	
		loc effb =exp(`r(bmod)'*`fcdel')
		loc effupb = exp(`effupb') 
		loc efflob = exp(`efflob') 
}	
}	
	if "`coeftype'" == "spost" {
		loc m1sp "${mvar1c1$sfx}"
		loc v1sp "`rval1'"
		if "${mvroot1$sfx}" != "" {
			loc m1sp "${mvroot1$sfx}"
			qui levelsof `m1sp', loc(mlev1)
			loc v1sp : word `m1' of `mlev1'
		}
		loc attxt ""
		if ${mvarn$sfx} > 1 {
			forvalues mmm=2/4 {
			if "`mod`mmm''" != "" {
				loc modnm "${mvar`mod`mmm''c`mc`mmm''$sfx}"
				if "${mvroot`mmm'$sfx}" != "" loc modnm "${mvroot`mmm'$sfx}"
				loc attxt "`attxt' `modnm' = `rval`mmm''" 
			}
			}
		}
		loc vernum = _caller()
		version `vernum'
		version `vernum' , user
		version `vernum' : mchange ${fvarc`fci'$sfx} , `amtopt' at( `atopt' `m1sp' = `v1sp' `attxt' ) stats(se) `margout'	 
		version 14.2
	
		loc rnm: rownames r(table)
		loc serow= strmatch("`rnm'","*Std Err*")
		loc sp: roweq r(table), quoted
		loc spvar : word 1 of `sp'
		loc sp: rownames r(table), quoted
		loc sinc=1+`serow'*(1-inlist(${fcnum$sfx},1))
		loc sptype ""
		forvalues ss=1(`sinc')`=`sinc'*${fcnum$sfx}' {
			loc sp1: word `ss' of `sp'
			loc sptype "`sptype'  `sp1'"
		}
		loc spatspec "`atopt'"
		mat `mchg' = r(table)
		if `serow' == 0 {
			loc mcb = el(`mchg',`fci',1)
			loc mcvar = el(`mchg',`fci',2)^2
		}
		if `serow' == 1 {
			loc mrow=`fci'*`sinc'-1 
			if ${fcnum$sfx} == 1 loc mrow = `fci'
			loc mcol= `eqi'
			if "${ordcatnum$sfx2}" !="" loc mcol=1
			loc mcb = el(`mchg',`mrow',`mcol')
			loc mcvar = el(`mchg',`=`mrow'+1',`mcol')^2
		}	
		loc effb = `mcb'
		loc effupb = `effb'+`mcvar'^.5*`crittz'
		loc efflob = `effb'-`mcvar'^.5*`crittz'
		loc effsig = 1- inrange(0,`efflob', `effupb')
}
	
loc ++ndi
loc ++ndw
mata: pltnum[`ndw',.] =(`rvalplt1', `rvalplt2' ,`rvalplt3' ,`rvalplt4' ,`fci' , `effb' , `effupb' , `efflob' , `effsig' ); pltlab[`ndw',.] =("`rlab1'", "`rlab2'", "`rlab3'", "`rlab4'", "${fvnamec`=`fci'+1'$sfx}","${mvar1c`mc1'$sfx}", "${mvar2c`mc2'$sfx}", "${mvar3c`mc3'$sfx}","${mvar4c`mc4'$sfx}","${fvarc`fci'$sfx}"); `obsmatch'[`ndw',1] = `ndi'
if `ndw' == 1000 | `ndi' == `ndat' {

	getmata (`m1val' `m2val' `m3val' `m4val' `fvarnum' `bmod' `bmodup' `bmodlo' `bmodsig' )=pltnum , id(`obsmatch') update
	getmata (`m1vlab' `m2vlab' `m3vlab' `m4vlab' `fvlab' `m1vnm' `m2vnm' `m3vnm' `m4vnm' `fvnm')=pltlab , id(`obsmatch') update
	loc ndw=0
	loc nrow=min(1000,`=`ndat'-`ndi'')
if `ndi' < `ndat'	mata: pltnum=J(`nrow',8,.) ;  pltlab=J(`nrow',10," ") ;  `obsmatch'=J(`nrow',1,.)
}

** Close MOD2 loop (m2)
}
	
** Close MOD2 loop (m
}
	
** Close MOD3 loop (m3)
}
	
** Close MOD4 loop (m4)
}
	
** Close FCI loop
}

*****************************************************************************************************************************
*** SECOND LOOP

loc dvtxt "g(${dvname$sfx})"
if ("`e(cmd)'" == "mlogit" |  "${ordcatnum$sfx2}" !="") & "`coeftype'" == "spost"  loc dvtxt "`e(depvar)'[${eqnow$sfx2}]"


forvalues i=2/4 {
	loc mod`i' ""
	loc mstp`i' = 1
	if ${mvarn$sfx}  >= `i' {
		loc mstp`i': list sizeof global(mvrange`i'$sfx)
		loc mod`i' = `i'		
		loc mc`i' ""
	}
} 
*
glo grnames$sfx "" 
glo pannum$sfx=0
forvalues fci = 1/${fcnum$sfx} {

*** Loop over additional moderators.  M1 plus up to 3  more.  Set loop m# stop val = 1 if MOD# not specified
***
***		Set up loop var display values & labels (RVAL3/RLAB3, RVAL4/RLAB4). For multicat use cat names for "value" labels
***			For interval/single dummmy nominal: RVAL=display value
***			For multi-cat nominal: RVAL=1 for non-Base categories but =0 for Base category so rval*b = 0

	forvalues m4=1/`mstp4' {
		if "`mod4'" != "" {
			loc rval4: word `m4' of ${mvrange`mod4'$sfx}
			loc rlab4 = "${mvlabm`mod4'c`m4'$sfx}" 
			loc  mc4=1
			
*** if 1st category  set rval4= 0  and   mc4= 0, else rval4= 1 mc=4 mm-1 
			if ${mcnum`mod4'$sfx} >1 {	
					loc rval4=inrange(`m4',2,`mstp4')
				loc mc4=`m4'-1
			}
		}
		forvalues m3=1/`mstp3' {
			if "`mod3'" != "" {
			loc rval3: word `m3' of ${mvrange`mod3'$sfx}
			loc rlab3 = "${mvlabm`mod3'c`m3'$sfx}"
			loc mc3=1
			
*** if 1st category  set rval3= 0  and   mc3= 0, else rval3= 1 mc=3 mm-1 

				if ${mcnum`mod3'$sfx} >1 {
					loc rval3=inrange(`m3',2,`mstp3')
					loc mc3=`m3'-1
				}
			}

**	  Run plot type specified for focal against M1. Each returns a graph combined with FRQ plot if requested.
	
	loc frqtxt ""
	if "`pltfreq'" != "" loc frqtxt "frqmat(`frqmat') base("`pltfreq'")"
	loc modstxt ""
	if "`mod2'" != "" {
		loc modstxt "`modstxt' m2var(`m2val')"
		if "`plttype'" == "contour"  loc modstxt "`modstxt'  mlab2(`m2vlab')"

		forvalues j=3/4 {	
			if "`mod`j''" != "" loc modstxt "`modstxt' m`j'val(`rval`j'') mlab`j'(`rlab`j'') m`j'var(`m`j'val') m`j'ind(`m`j'')"
		}
	}
	if "`plttype'" ==  "cbound"  /// 
		cbplot , m1var(`m1val') mlab1(`m1vlab') bmod(`bmod') upb(`bmodup') lowb(`bmodlo') bsig(`bmodsig') fvarnum(`fvarnum') ci(`ciprp') `frqtxt' `modstxt' /// 
			ndig(`ndigits') crittz(`crittz') `pltkeep' name(`grphnm') fnum(`fci') save(`pltsave')   estint("`estint'") /// 
			pltopts(`pltopts') pltsigmark(`pltsigmark') noeffval(`noeff') titotheff(`titotheff') titdel(`titdel') dvtxt(`dvtxt')
	
	if "`plttype'" ==  "errbar"  /// 
		errbplot , m1var(`m1val') mlab1(`m1vlab') bmod(`bmod') upb(`bmodup') lowb(`bmodlo') fvarnum(`fvarnum') ci(`ciprp') `frqtxt' `modstxt' /// 
			ndig(`ndigits') crittz(`crittz') `pltkeep' name(`grphnm') fnum(`fci') save(`pltsave')  estint("`estint'") /// 
			pltopts(`pltopts') pltsigmark(`pltsigmark') noeffval(`noeff') titotheff(`titotheff') titdel(`titdel') dvtxt(`dvtxt')
			
	
	if "`plttype'" ==  "contour" ///
		conplot , m1var(`m1val') mlab1(`m1vlab') bmod(`bmod') bsig(`bmodsig')  fvarnum(`fvarnum') ///
			ci(`ciprp') `frqtxt' `modstxt'   `heatmap'  /// 
			ndig(`ndigits') crittz(`crittz') `pltkeep' name(`grphnm') fnum(`fci') save(`pltsave')  estint("`estint'") /// 
			ccuts(`ccuts') pltopts(`pltopts') pltsigmark(`pltsigmark') titotheff(`titotheff') titdel(`titdel') dvtxt(`dvtxt')
			
			
** Close MOD3 loop (m3)
		}
		
** Close MOD4 loop (m4)
	}
	
** Close FCI loop
}
*** Combiine graphs over Focal cats if fcnum > 1 AND only M1 specified EXCEPT for Contour only M1 & M2

if ( ${fcnum$sfx} > 1 & ((${mvarn$sfx} == 1 & "`plttype'" != "contour") /// 
					| (${mvarn$sfx} == 2 & "`plttype'" == "contour")))  ///
					| (${fcnum$sfx} == 1 & ${mvarn$sfx} == 3  & "`plttype'" == "contour" )   { 
					
	if ${fcnum$sfx} > 3 glo pannum$sfx = ${pannum$sfx} + 1
	
	loc combti `"`titotheff' Effect of ${fvldisp$sfx} `titdel'"  "Moderated by ${mvldisp1$sfx}"'
	if "`pltsigmark'" != "Yes" 	loc combti "`titotheff' Effect of ${fvldisp$sfx} `titdel' Moderated by ${mvldisp1$sfx}"

		
	if "`plttype'" == "cbound" 	loc combleg `""  - - - -    Upper Bound" " " "  ——   Effect of ${fvldisp$sfx}" " " "  - - - -    Lower Bound""'
	if "`plttype'" == "cbound" & "`pltsigmark'" != "Yes"	loc combleg `" "  ——   Effect of ${fvldisp$sfx}" "'

	if "`plttype'" == "errbar" 	loc combleg  `""  ♦   Effect of ${fvldisp$sfx}      `=ustrunescape("\u251C")'`=ustrunescape("\u2500")'`=ustrunescape("\u2500")'`=ustrunescape("\u2524")'   CI Bounds""'
	if "`plttype'" == "errbar" & "`pltsigmark'" != "Yes"	loc combleg  `""  ♦   Effect of ${fvldisp$sfx} ""'

	if "`plttype'" == "contour" { 
		loc combleg  "NONE"
		loc txtint "${mvldisp1$sfx} and ${mvldisp2$sfx}"
		if "${int3way$sfx}" == "y"  loc txtint "the Interaction of ${mvldisp1$sfx} and ${mvldisp2$sfx}"	
		loc combti " `titotheff' Effect of ${fvldisp$sfx} `titdel' Moderated by `txtint'"
		if ${mvarn$sfx} == 3  ///
			loc combti " `titotheff' Effect of ${fvldisp$sfx} `titdel' Moderated by `txtint', by ${mvldisp3$sfx}"	
	}
	plotcomb , grphcomb(${grnames$sfx}) title(`combti') grname(`grphnm') legend(`combleg') plttype(`plttype')

if "`pltkeep'" != "keep" graph drop ${grnames$sfx}
}
} 
loc mygloblist:  all globals "*$sfx"
mac drop `mygloblist'
*
est restore `estint'

** Close quiet loop
}
end
