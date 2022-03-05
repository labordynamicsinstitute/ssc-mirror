*!  outdisp.ado 	Version 6.3	RL Kaufman 	11/14/2018

***  	1.0 Adapted from effdisp.ado (version 2.0)
***			Works with standard MAIN INT2 INT3 option specification. Use DEFINEFM.ADO to define focal & moderator vars & properties 
***			MAIN string contains (varlist1, name(word) cat range(numlist)) (varlist2, name(word)  cat range(numlist) ... )
***			NDIGITS(#) for format default=4.  abbrev(#) is # characters in abbreviated Stata names (default 10) in headings, labels, etc.
***			EQName(string) is the name/# of alternative to 1st equation results 
***
***			OUTcome(metric(name) atopt(string) dualaxis mainest(name))  METRIC specifies metirc for predicted values, name = MODEL metric or OBS metric(default).
***			ATOPT specifies reference values for all vars except Focal & modreating.  (ASOBS) (MEANS) or v1= v2= specifcations allowed. Default=asobs
***			DUALaxis is valid only for MODEL metric and adds 2nd y-axis labelled in observed metric.   
***			MAINest is valid only for OBSERVED metric bar charts or scatterplots and adds/superimposes main effect model predictions, 
***				name = estimates name where main effects model results are stored
***
***			PLOT(type(name) single name(name) gen(name) save(filepath) freq(name) keepfrq). TYPE default is 
***				Bar Charts for nominal FOCAL & M1  freq
***				Scatterplot for mixed nominal-interval FOCAL & M1 [x-axis = interval variable]. 
***					SINGLE option only for scatterplot, 1= indvidual plots by values of Mod1 (default is multiple curves on same plot)
***						2=indvidual plots by MOD2 (default is pairs/triplets on same graph), all = both
***				Contour plot for interval FOCAL & M1  .  LEVELS option only for contour plot; defines contour cutpoints.
***			NAME is graph name.    OPTION GEN never implemented{{ GEN(name) is name=varstub for saving plot info as vars. }}
***			SAVE saves matrices with plotinfo to filepath.  FREQ attaches relative freq  distn plot to each outcome display plot
***			(side by side smaller contour for contour plot), name specifies base: SUB= FOCAL by M1 with base defined by subsamples of M1;
***			SUBTOT = FOCAL by M1 base defined by total sample.  KEEPfrq = do not delete freq distn subplots after combining.
***
***			TABle(row(name) save(filepath) freq(name)). ROW specifies if FOCAL or M1 defines table rows/cols; NAME = FOCAL or MOD, default is MOD.
***			SAVE saves tables to filepath.  FREQ adds second table with relative freq distn below each outcome table; 
***				name specifies base: SUB= FOCAL by M1 with base defined by subsamples of M1; SUBTOT = FOCAL by M1 base defined by total sample. 
***
***			SAVE to XLSX not xls to avoid problem of too many fonts error and incomplete formatting
***
***		2.0 Made separate ado file MKMARGVAR.ADO to make variables from margins results for creating tables and graphs
***		
***		3.0 Added preserve, put quiet on, removed checking code and generally cleaned up code.  
****		Added to PLOT() syntax OPTS(asis) to allow user options, excludes LEVELS as separate option.
***			UNDOCUMENTED OPTION: MYGLOB(KEEP) so I can check easily. Added SUMWGT(no) option so user can requested use of unweighted summary statistics.
***		4.0  Adapted to use intspec.ado to set-up and save the globals for the interaction specification for re-use.  SUMWGT now INTSPEC option
***		4.1  For dual-axis option changed to use y-standardized prediction outcome in model metric 
***		5.0	 Added mlogit functionality, made pred value table produced by default if neither table() or plot(() specified
***		5.1  SDY option allows y-standardized metric w or w/o dual, for mlogit separate latent variable std dev for each ln odds contrast
***		5.2	 Saves table to Excel with font size scaled to predicted value
***		5.3	 CCUTS option allows user specified contour cutpoints
***		5.4	  Corrected caculation of standardized ln(Count) and corrected capability to analyze inflate component of ZIP and ZINB
***		5.5	  Removed ZIP and ZINB from list for which standardized g(y) can be calculated.  mean and s.d. of ln(count) are expecations of compund of 2 random vars
***		6.0	 Add functionality for observed metric  (prob) tables and figures. Corrected y-standardized predicted outcome for logit/probit & ordered logit/probit 
***			 to subtract mean (only consequence is to change Predicted Y-standardized in model metric by a constant
***		6.0	 Add functionality for scatter plot to use nominal focal to define multiple prediction lines and mvar1 to define x-axis
***		6.1   Added option TABABS for table font size to be based on absolute value or not 
***		6.2  Fixed use of type(scat) for nominal focal variable to switch role of focal and 1st moderator when focal has 2 categories, nnot just >2 
***		6.3  Fixed problem of file paths with embedded blanks in save() option. DO NOT PUT " " AROUND THE FILEPATH for OUTDISP.  
***				MUST use " " AROUND THE FILEPATH for SIGREG

program outdisp, rclass sortpreserve
version 14.2
syntax  ,  [ OUTcome(string) plot(string) TABle(string) NDIGits(integer 4) CCUTS(string asis) pltopts(string asis) blabopts(string asis) ] 
tempname frqmat hold estint h2 mzz
tempvar  predy1 abspred pred predy1mn predzi predstd fvar mvar1 mvar2 mvar3 mvar4 mvar5 mvar6 fvarmn mvarmn1 mvarmn2 mvarmn3 mvarmn4 mvarmn5 mvarmn6 fvarzi mvar1zi mvar2zi mvar3zi mvar4zi

qui {

***		check if globsave file created by instspec.ado & definefm.ado

if  fileexists("`c(tmpdir)'/globsaveeq1$sfx2.do") ==0 {
	noi disp "{err: Must run intspec.ado to setup and save interaction specification first}"
	exit
}

*** PRESERVE DATA & CURRENT ESTIMATES ON EXIT

preserve
est store `estint' 


*** load globals from eq1 to use in setup and  if-branching
capture drop esamp$sfx
qui run `c(tmpdir)'/globsaveeq1$sfx2.do


***  Get outcome options OUTMETRIC, OUTDUAL, OUTMAIN, OUTSDY
if "`outcome'" != "" {
	foreach nm in metric atopt dual main sdy {
		loc out`nm' ""
	}
	loc hout=strtrim(stritrim(`"`outcome'"'))
	while `"`hout'"' != ""  & `"`hout'"' !=  " " {
		gettoken outopt hout : hout , bind match(pp) 
		tokenize `outopt', parse("()") 
		foreach nm in metric atopt dual main sdy {
			if strmatch("`1'","`nm'*"){ 
				loc out`nm' `"`3'"'
				if strmatch("`nm'","dual") loc outdual "dual"
				if strmatch("`nm'","sdy") loc outsdy "sdy"	
				if "`nm'" == "atopt" & "`3'" == "(" {
					gettoken xx outopt : outopt , parse("(")  
					gettoken xx outopt : outopt , match(pp)
					loc outatopt "`xx'"		
				}
			}
		}	
	}
}
if "`outmetric'" == "" loc outmetric "obs"
if "`outatopt'" == "" loc outatopt "(asobs) _all"

***  Get table options TABROW, TABSAVE, TABFREQ, TABABS
if `"`table'"' == "" & `"`plot'"' == "" loc table "default"
if `"`table'"' != "" {
	foreach nm in row save freq abs {
		loc tab`nm' ""
	}
	loc htab=strtrim(stritrim(`"`table'"'))
	while `"`htab'"' != ""  & `"`htab'"' !=  " " {
		gettoken tabopt htab : htab , bind match(pp) 
		tokenize `tabopt', parse("()") 
		foreach nm in row save freq abs {
			if strmatch("`1'","`nm'*"){ 
				loc tab`nm' `"`3'"'
				if strmatch("`nm'","abs") loc tababs "abs"
			}
		}	
	}
if "`tabrow'" == "" loc tabrow "focal"
}
***  Get plot options PLTTYPE, PLTSING PLTNAME, PPLTSAVE PLTKEEP PLTFREQ & PLOTOPTS

if `"`plot'"' != "" {
	foreach nm in type sing name save keep freq   {
		loc plt`nm' ""
	}
	loc hplot=strtrim(stritrim(`"`plot'"'))
	while `"`hplot'"' != ""  & `"`hplot'"' !=  " " {
		gettoken plotopt hplot : hplot , bind match(pp) 
		tokenize `plotopt', parse("()") 
		foreach nm in type sing name save keep freq   {
			if strmatch("`1'","`nm'*"){ 
				loc plt`nm' `"`3'"'
				if "`nm'" == "keep" loc pltkeep "keep"
			}
		}	
	}
}
*
*** Check pltopts for ylab & use to set predy max and min for axis / zlab if contour
if `"`pltopts'"' != "" {
	foreach nm in ylab1 ylab2 zlab1 zlab2 {
		loc tab`nm' ""
	}
	loc nylab=0
	loc nzlab=0
	loc hplt=strtrim(stritrim(`"`pltopts'"'))
	while `"`hplt'"' != ""  & `"`hplt'"' !=  " " {
		gettoken plt hplt : hplt , bind match(pp) 
		foreach nm in ylab zlab {
			if strmatch(`"`plt'"',"`nm'*") { 	
				gettoken gg plt : plt , parse("(") 
				gettoken plt1 gg : plt , match(pp) parse("()") 
				if strmatch(`"`plt1'"',"*add*") == 0 & strmatch(`"`plt1'"',"*axis(2)*") == 0  { 
					loc ++n`nm' 
					loc `nm'`n`nm'' `"`plt1'"'
				}
				if strmatch(`"`plt1'"',"*add*") == 1 & strmatch(`"`plt1'"',"*axis(2)*") == 0 { 
					loc ++n`nm' 
					gettoken  plt2 gg : plt1 , parse(",") 
					loc `nm'`n`nm'' `"`plt2'"'
				}	
			}
		}	
	}
}
glob ypredmin$sfx ""
glob ypredmax$sfx ""

if `"`ylab1'"' != "" & strmatch(`"`ylab1'"',"*none*") == 0 & strmatch(`"`ylab1'"',"*,*") ==0 {
	numlist "`ylab1' `ylab2'" , sort
	loc nn "`r(numlist)'"
	glob ypredmin$sfx : word 1 of `nn'
	loc nlst: list sizeof nn
	glob ypredmax$sfx : word `nlst' of `nn'
}
glob zpredmin$sfx ""
glob zpredmax$sfx ""

if `"`zlab1'"' != "" {
	numlist "`zlab1' `zlab2'" , sort
	loc nn "`r(numlist)'"
	glob zpredmin$sfx : word 1 of `nn'
	loc nlst: list sizeof nn
	glob zpredmax$sfx : word `nlst' of `nn'
}
 
*
*** set PLTTYPE & LEVELS for CONTOUR to defaults if not specified.  All other options have no defaults: Not done if not specified
if "`plttype'" == "" | strmatch("`plttype'","def*") ==1   {
	loc plttype "scat"
	if "${fviscat$sfx}" == "y" | "${fisfv$sfx}" == "y" 	loc plttype "bar"
}
loc scatrev "n"
if  "`plttype'" == "scat" & ("${fviscat$sfx}" == "y" | "${fisfv$sfx}" == "y"  ) {	
	if ("${mviscat1$sfx}" == "y" | ("${misfv1$sfx}" == "y" & ${mcnum1$sfx} > 1 ) ) {
		noi disp as err "Focal Variable (${fvldisp$sfx}) and first Moderator (${mvldisp1$sfx}) both categorical (> 2 categories), one must be interval for a scatter Plot"
		exit
	}
	loc scatrev "y"
	noi disp as res "Scatterplot uses first Moderator (${mvldisp1$sfx}) as x-axis and Focal Variable (${fvldisp$sfx}) to define separate prediction lines"

}
if  "`plttype'" == "contour" & ( ("${mviscat1$sfx}" == "y" | ("${misfv1$sfx}" == "y" & ${mcnum1$sfx} > 1 ) ) | /// 
		("${fviscat$sfx}" == "y" | ("${fisfv$sfx}" == "y" & ${fcnum$sfx} > 1 ) ) ) {
	noi disp as err "Moderator 1 (${mvldisp1$sfx}) and/or Focal Variable (${fvldisp$sfx}) is categorical (> 2 categories) but must be interval for a contour Plot"
	exit
}
*
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

*** Report back options specified *******************************************************

noi disp _newline as txt "{ul:Outcome Options Specified or Default}" _newline
loc nospec "true"

foreach nm in type metric atopt dual main sdy {
	if "`out`nm''" != "" { 
		noi disp as txt "   `nm' = " as res " `out`nm''"
		loc nospec "false"
	}
}
if "`nospec'" == "true" noi disp "None specified"

if "`tabrow'" != "" {
	noi disp _newline as txt "{ul:Table Options Specified or Default}" _newline

	foreach nm in row save freq abs {
		if "`tab`nm''" != "" ///
			noi disp as txt "   `nm' = " as res " `tab`nm''"
	}
}
if `"`plot'"' != "" {
	noi disp _newline as txt "{ul:Plot Options Specified or Default}" _newline

	foreach nm in type sing name gen save keep freq  {
		if "`plt`nm''" != "" ///
			noi disp as txt "   `nm' = " as res " `plt`nm''"
	}
}
*
***		Check consistency of outcome options
if "`outmetric'" == "obs" & "`outdual'" != "" {
	noi disp _newline as err "Dualaxis option not valid for outcome in observed metric.  Ignored."  as text " "
	loc outdual  ""
}
foreach modnm in mlogit oprobit ologit {
if  "`e(cmd)'" == "`modnm'" & "`outdual'" != "" {
	noi disp _newline as err "Dualaxis option not valid for `modnm' analysis.  Ignored."  as text " "
	loc outdual  ""
}
}
if "`outmetric'" == "obs" & "`outsdy'" != "" {
	noi disp _newline as err "SDY option not valid for outcome in observed metric.  Ignored."  as text " "
	loc outsdy  ""
}
if  ("`e(cmd)'" == "zip" | "`e(cmd)'" == "zinb" ) & "`outsdy'" != "" {
	noi disp _newline as err "SDY option not valid for ZIP or ZINB.  Ignored."  as text " "
	loc outsdy  ""
}

if "`outmetric'" == "model" & "`outmain'" != "" {
	noi disp _newline as err "Added main effects option not valid for outcome in model metric.  Ignored." as text " "
	loc outmain ""
}
if "`outmain'" != "" & "`plttype'" == "contour" {
	noi disp _newline as err "Added main effects option not valid for contour plot.  Ignored." as text " "
	loc outmain ""
}

*
loc grphnmroot "`pltname'"
if "`pltname'" == "" loc grphnmroot =strtoname("${fvldisp$sfx}_${mvarn$sfx}Mods")

*** Get std dev of y-star or ln y if SDY specified
loc ystand "no"
loc ystandtxt ""
glob ystd$sfx = 1
glob ymn$sfx = 0

if "`outsdy'" == "sdy" & (inlist("`e(cmd)'","logit","logistic","ologit","probit") ==1  /// 
   | inlist("`e(cmd)'","oprobit","mlogit","poisson","nbreg"/*,"zip","zinb"*/)==1 ) {
	loc ystand "yes"
	loc ystandtxt "-Standardized"
	predict `predstd' if esamp$sfx, xb
	qui sum `predstd' if esamp$sfx
		if inlist("`e(cmd)'","logit","logistic","ologit","probit","oprobit")==1  {
		loc errvar = 1
		if inlist("`e(cmd)'","logit","logistic","ologit") ==1 	loc errvar = _pi^2/3
		glob ystd$sfx = (`r(Var)' + `errvar')^.5
		glob ymn$sfx = `r(mean)'	
	}
	if inlist("`e(cmd)'","poisson","nbreg"/*,"zip","zinb"*/)==1 {
		qui sum `e(depvar)' if esamp$sfx
		glob ymn$sfx =ln(`r(mean)')
		glob ystd$sfx = (`r(Var)'/`r(mean)'^2)^.5
	}
}

loc mstp = ${mvarn$sfx}

***		If Freq Dist requested construct matrix

if "`pltfreq'" != "" | "`tabfreq'" != "" {
	loc frqopt "`pltfreq'"
	if "`pltfreq'" == "" loc frqopt "`tabfreq'"
	if "`pltfreq'" != "" & "`tabfreq'" != ""  & "`pltfreq'" != "`tabfreq'" ///
		noi disp _newline "{error}Warning {res}Frequency options for plot and table differ. Plot frequency option used."
	frqfocmod1 ,  freq(`frqopt')
	mat `hold' = r(frqmat)
	mat `frqmat' = `hold''
	loc fstp: list sizeof global(fvrange$sfx)		
	loc mstp1: list sizeof global(mvrange1$sfx)		
	loc cn ""
	forvalues j=1/`mstp1' {
		loc cn "`cn' ${mvlabm1c`j'$sfx}"
	}
	loc cn "`cn' Focal_value"
	mat colnames `frqmat' = `cn'
	loc rn ""
	forvalues i=1/`fstp' {
		loc rn "`rn' ${fvlabc`i'$sfx}"
	}
	mat rownames `frqmat' = `rn'
	mat `hold' =`frqmat'[.,1..`mstp1']
}
*
***  Loop over # of Equations  ( =1 except for mlogit & others TBD)
loc eqitot = ${eqnum$sfx2} 
if "${ordcatnum$sfx2}" !="" & "`outmetric'" == "obs"  loc eqitot =  ${ordcatnum$sfx2} 

loc fopenyet "no"

forvalues eqi=1/ `eqitot' {
glob eqinow$sfx2 = `eqi' 
glob eqnow$sfx2: word `eqi' of ${eqlist$sfx2}
if "${eqnow$sfx2}" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 & ( "`e(cmd)'" != "mlogit" | ///
	( "`e(cmd)'" == "mlogit"  & "`outmetric'" != "obs" ) ) continue

***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
if "${ordcatnum$sfx2}" == "" qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do
loc titdv "g(${dvname$sfx})"
if "`coeftype'" == "spost" | "`coeftype'" == "factor" loc titdv "${dvname$sfx}"

loc dvadd ""
loc margout ""
if "${ordcatnum$sfx2}" !="" {
	qui run `c(tmpdir)'/globsaveeq1$sfx2.do
	loc dvadd ":${eqnow$sfx2}"
		loc margout "out(`eqi')"
}

***  calc latent s.d. and meanfor mlogit if sdy axis requested
if "`outsdy'" != "" & "`e(cmd)'" == "mlogit" {
	loc errvar = _pi^2/3
	capture drop `predstd' 
	predict `predstd' if esamp$sfx, xb outcome("${eqnow$sfx2}")
	qui sum `predstd' if esamp$sfx
	glob ystd$sfx = (`r(Var)' + `errvar')^.5
	glob ymn$sfx = `r(mean)'	
}
*
if "`outsdy'" != "" {
	noi disp _newline as txt "Standard deviation of g(${dvname$sfx}) = " as res %8.4f ${ystd$sfx} as txt " "_newline
	if inlist("`e(cmd)'","poisson","nbreg","logit","logistic","mlogit", "ologit","probit"/*,"zip","zinb"*/) == 1  	noi disp as txt "               Mean = " as res %8.4f ${ymn$sfx} as txt " "_newline
}
loc grphnm "`grphnmroot'"
if ${eqnum$sfx2} > 1 | ("${ordcatnum$sfx2}" !="" & "`outmetric'" == "obs") loc grphnm "`grphnmroot'_`=substr("${eqnow$sfx2}",1,6)'"
loc titdv "${dvname$sfx} `dvadd'"
if "`outmetric'" == "model" loc titdv "g(${dvname$sfx})"


***		If Save plot or table requested, Set up save spreadsheet & save Freq Dist if used
if "`pltsave'" != "" |  "`tabsave'" != "" {
	if "`pltsave'" != "" & "`tabsave'" != ""  & "`pltsave'" != "`tabsave'" ///
		noi disp _newline "{error}Warning {res}Save path/file name for plot and table differ. Plot path/file name used."
	loc savenm `"`pltsave'"'
	if "`pltsave'" == "" 	loc savenm `"`tabsave'"'
	if strpos("`savenm'",".") == 0 loc savenm `"`savenm'.xlsx"'
	glob plotnum$sfx=0
	if "`pltsave'" != "" noi disp _newline  as txt "Plot data written to sheet {res:{it:plotdata_${eqnow$sfx2}}} of " as res "`savenm'"
	if "`tabsave'" != "" noi disp _newline  as txt "Table data written to sheet {res:{it:table_${eqnow$sfx2}}} of " as res "`savenm'"

	loc repmod "modify"
	if "`fopenyet'" == "no" {
		loc repmod "replace"
		loc fopenyet "yes"	
	}

	putexcel set "`savenm'" , sheet(frqdistdata, replace) `repmod'
	putexcel A1 = (" ") 
	putexcel set "`savenm'" , sheet(plotdata_${eqnow$sfx2}, replace) modify
	putexcel A1 = (" ") 
	putexcel set "`savenm'" , sheet(table_${eqnow$sfx2}, replace) modify
	putexcel A1 = (" ") 
	mata: b=xl();b.load_book("`savenm'"); b.set_sheet("plotdata_${eqnow$sfx2}"); b.set_mode("open"); b.set_column_width(2,2,40);b.set_text_wrap(2,2,"on")
	if "`pltfreq'" != "" |  "`tabfreq'" != "" {
		noi disp _newline  as txt "Frequency distribution data written to sheet {res:{it:frqdistdata}} of " as res "`savenm'"
		putexcel set "`savenm'" , sheet(frqdistdata) modify
		putexcel B2 = mat(`frqmat'[.,1..`mstp1']) , names
		putexcel B2 = ("${fvldisp$sfx}")  C1 = ("${mvldisp1$sfx}") , italic
		loc rown = 3+(2+`fstp')
		mata: fmat=st_matrix("`hold'"); fsum= sum(fmat); fsumcol = colsum(fmat);  st_numscalar("fsum",fsum);  st_matrix("fsumcol",fsumcol); 
		mat `h2' = `hold'*100/fsum
		putexcel B`=`rown'+2' = mat(`h2') , names nform(".0")
		mat `h2' = `hold'
		forvalues i=1/`fstp' {
		forvalues j=1/`mstp1' {
			sca hhh = 100/el("fsumcol",1,`j')
			mat `h2'[`i',`j'] = `hold'[`i',`j']*hhh
		}
		}
		putexcel B`=2*`rown'+1' = mat(`h2') , names nform(".0")
		putexcel A`rown' = ("Total Percents")  A`=2*`rown'-1' = ("Col Percents") 
		putexcel B`=`rown'+2' = ("${fvldisp$sfx}")  C`=`rown'+1' = ("${mvldisp1$sfx}") B`=2*`rown'+1' = ("${fvldisp$sfx}")  C`=2*`rown'' = ("${mvldisp1$sfx}") , italic	
	}
mata: b.set_mode("closed")
}
*}

***** Set up margins specification  info **********************************************************************************
***			Margins at spec invariant except for contour focal and M1
***			Do first for interaction model using ATSPEC.ado and then repeat if main effects added option specified

loc outmarg " "
if ${eqnum$sfx2} > 1 loc outmarg "outcome(${eqnow$sfx2}) "
if "${ordcatnum$sfx2}" !="" loc outmarg "outcome(#`eqi') "
if ( ${eqnum$sfx2} == 1 & "`e(cmd)'" == "mlogit") | (("`e(cmd)'" == "zip" | "`e(cmd)'" == "zinb" ) & "${eqname$sfx}" == "inflate" )  loc outmarg "outcome(${eqname$sfx})" 
if ("`e(cmd)'" == "zip" | "`e(cmd)'" == "zinb" ) & "${eqname$sfx}" == "inflate" & "`outmetric'" == "obs" loc outmarg " pr "
if "`outmetric'" == "model" loc outmarg "`outmarg' xb" 
if "`outmetric'" == "model" & "${ordcatnum$sfx2}" !="" loc outmarg " xb" 
if "`outmarg'" != " " loc outmarg "predict(`outmarg')" 


*** Construct atspec for F,M1 and 3way F,M1,M2 depending on type of measure
***		(a) factor var (b)  interval var (c) all catergorical but not factor vars 

atspec, outmetric(`outmetric') plttype(`plttype') model(int) int3way(${int3way$sfx}) outatopt(`outatopt') scatrev("`scatrev'")
loc atinfo "`r(atinfo)'"

loc atinfotab "`r(atinfo)'"
if "`plttype'" == "contour" | "`plttype'" == "scat" loc atinfotab "`r(atinfotab)'"


*******************************************************************************************************************
****	Table of predicted values if specified
loc nowgt "noweights"
if "${sumwgt$sfx}" != "" loc nowgt ""

if `"`table'"' != ""  {
	glo adjzi$sfx = 0	
	est restore `estint'
	if ("`e(cmd)'" == "zip" | "`e(cmd)'" == "zinb" ) &  "`outmetric'" == "model" {
		margins if esamp$sfx  ${sumwgt$sfx} , predict(pr) at((means) _all) `nowgt'
		mat h3 = r(b)		
		glo adjzi$sfx = h3[1,1]
		est restore `estint'
	} 
 	margins if esamp$sfx  ${sumwgt$sfx} , `outmarg' `atinfotab'  post nose `nowgt'
	mkmargvar intmod notplot `predy1' `fvar' `mvar1' "n" `mvar2' `mvar3' `mvar4' 
	est restore `estint'
***** standardize predicted outcome if outmetric = model and SDY option and 
****      adjust predicted outcome in model metric if ZIP or ZINB by ln(1-pr(always zero))]]
sort `mvar1' `fvar' 
	if ("`e(cmd)'" == "zip" | "`e(cmd)'" == "zinb") & "`outmetric'" == "model" & "${eqname$sfx}" != "inflate" replace `predy1' = `predy1'+ln(1-${adjzi$sfx}) if `mvar1' < . 
	if "`ystand'" == "yes" 	replace `predy1' = (`predy1'- ${ymn$sfx}+ ln(1-${adjzi$sfx}))/${ystd$sfx}  if `mvar1' < .
	loc titxt "${dvname$sfx}"
	if "`outmetric'" == "model" loc titxt "g(${dvname$sfx})`ystandtxt'"
	if ("`e(cmd)'" == "mlogit" |  "${ordcatnum$sfx2}" !="") &  "`outmetric'" == "obs" loc titxt "`e(depvar)'[${eqnow$sfx2}]"
	if  ${eqnum$sfx2} == 1 & "`e(cmd)'" == "mlogit" &  "`outmetric'" == "obs" loc titxt "`e(depvar)'[${eqname$sfx}]"
	loc rowvar "`mvar1'"
	loc colvar "`fvar'"
	loc rownam "${mvldisp1$sfx}"
	loc colnam "${fvldisp$sfx}"
	if "`tabrow'" == "focal" {
		loc rowvar "`fvar'" 
		loc colvar "`mvar1'"
		loc rownam "${fvldisp$sfx}"
		loc colnam "${mvldisp1$sfx}"
	}
	levelsof `colvar' , loc(cloop)
	loc colnum: list sizeof cloop
	levelsof `rowvar' , loc(rloop)
	loc rownum: list sizeof rloop	

	if ${mvarn$sfx} == 1 {
	noi	disp _newline(2) "Predicted Value of `titxt' by the Interaction of ${fvldisp$sfx} with ${mvldisp1$sfx}." _newline 
	noi	tabdisp `rowvar' `colvar' if `mvar1' < . , stubwidth(18) c(`predy1') format(%10.`ndigits'f) concise cellwidth(9)
		loc titsav "`titxt' by the Interaction of ${fvldisp$sfx} with ${mvldisp1$sfx}."   
	}
	if ${mvarn$sfx} == 2  {
		loc titxt2 "by the Two-way Interactions of ${fvldisp$sfx} with" _newline "   ${mvldisp1$sfx} and with ${mvldisp2$sfx}."
		if "${int3way$sfx}" == "y" ///
			loc titxt2  "by the Three-way Interaction of ${fvldisp$sfx}, " _newline "    ${mvldisp1$sfx} and ${mvldisp2$sfx}." 
	noi	disp _newline(2) "Predicted Value of `titxt' `titxt2'" _newline 
	noi	tabdisp `rowvar' `colvar' if `mvar1' < . , stubwidth(18) c(`predy1') by(`mvar2') format(%10.`ndigits'f) concise cellwidth(9)
		loc titsav "`titxt' by the Two-way Interactions of ${fvldisp$sfx} with ${mvldisp1$sfx} and with ${mvldisp2$sfx}."
		if "${int3way$sfx}" == "y" ///
			loc titsav "`titxt' by the Three-way Interaction of ${fvldisp$sfx}, ${mvldisp1$sfx} and ${mvldisp2$sfx}." 

	}
	if ${mvarn$sfx} > 2 {
	noi	disp _newline(2) "Predicted Value of `titxt' by the Two-way Interactions of ${fvldisp$sfx} with " _newline "   ${mvldisp1$sfx}, ${mvldisp2$sfx} and ${mvldisp3$sfx}." _newline 
		 levelsof `mvar3', loc(mm3lst)
		loc titsav "`titxt' by the Two-way Interactions of ${fvldisp$sfx} with ${mvldisp1$sfx}, ${mvldisp2$sfx} and ${mvldisp3$sfx}."   
		loc pn=0
		foreach mm3 of numlist `mm3lst' {
			loc ++pn
		noi	disp "Panel `pn': ${mvldisp3$sfx} = ${mvlabm3c`pn'$sfx}"
		noi	tabdisp `rowvar' `colvar' if `mvar1' < . & `mvar3' == `mm3' , stubwidth(18) c(`predy1') by(`mvar2') format(%10.`ndigits'f) concise cellwidth(9)
		noi	disp _newline(2)
		}
	}
**************************************************Save table ********************************
if "`tabsave'" != "" {
	capture: drop ``tababs'pred'
	gen ``tababs'pred' = `tababs'(`predy1') if `mvar1' < . 

	_pctile ``tababs'pred' if `mvar1' < . , percentiles(20 40 60 80)
	forvalues qt=2/5 {
		loc qt`qt' =`r(r`=`qt'-1')'
	}
	*** Set cutpoints for differential font size
	qui sum ``tababs'pred' if `mvar1' < . , meanonly
	loc qt1 = `r(min)' -.5
	loc qt6 = `r(max)' +.5

	loc sortord ""
	if ${mvarn$sfx} == 2 	loc sortord " `mvar2' "
	if ${mvarn$sfx} == 3 	loc sortord " `mvar3' `mvar2' "
	sort `colvar' `sortord' `rowvar'
	levelsof `colvar' , loc(cloop)
	loc combtxt "mat `h2' = [ "
	sca m1st = 0 
	foreach jj of numlist `cloop' {
		mkmat `predy1' if `colvar' == `jj' , nomiss mat(`mzz'`jj')
		matname `mzz'`jj' `colvar'`jj', col(1) explicit
		if m1st == 0 loc combtxt "`combtxt' `mzz'`jj' "
		if m1st != 0 loc combtxt "`combtxt' , `mzz'`jj' "
		sca m1st = 1
	}
	`combtxt' ]
	
	forvalues mi=1/3 {
		loc m`mi'stp = 1
		if `mi' <= `mstp' {
			levelsof `mvar`mi'' , loc(hold`mi') 
			loc m`mi'stp: list sizeof hold`mi'
		}
	}
	putexcel set "`savenm'" , sheet(table_${eqnow$sfx2}) modify
	putexcel B2 = ("`titsav'")
	loc nrw = 4
	loc ncol = inrange(${mvarn$sfx},2,10)
	loc nform "#####.0000"
	if `ndigits' != 4 {
		loc nform ""
		forvalues nfi=1/`=9-`ndigits'' {
			loc nform "`nform'#"
		}
		loc nform "`nform'."		
		forvalues nfi=1/`ndigits' {
			loc nform "`nform'0"		
	}
	}
	mata: b=xl();b.load_book("`savenm'"); b.set_sheet("table_${eqnow$sfx2}"); b.set_mode("closed"); b.set_column_width(2,`=2+`ncol'+`colnum'',13);b.set_row_height(2,`=2+`m3stp'*(3+`m2stp'*(`rownum'+1))+5',25);b.set_font((2,`=2+`m3stp'*(3+`m2stp'*(`rownum'+1))+5'),(2,`=2+`colnum'+2'),"calibri",11)
	
	forvalues m3=1/`m3stp' {
		if `m3stp' > 1 {
			putexcel B`nrw' = ("Panel `m3': ${mvldisp3$sfx} = ${mvlabm3c`m3'$sfx}") italic 
			loc ++nrw
		}
		putexcel (B`nrw':`=char(66+`ncol'+`colnum')'`nrw') , border(top,medium)
		putexcel (B`=`nrw'+1':`=char(66+`ncol'+`colnum')'`=`nrw'+1') , border(bottom,medium)
		putexcel (`=char(66+`ncol'+1)'`nrw':`=char(66+`ncol'+`colnum')'`nrw' ) =  "`colnam'" , merge hcenter underline
		loc ++nrw
		if ${mvarn$sfx} > 1  putexcel B`nrw' = ("${mvldisp2$sfx}") , left  
		putexcel (`=char(66+`ncol')'`=`nrw'-1':`=char(66+`ncol')'`=`nrw'+(`m2stp'*(`rownum'+`ncol'))') , border(right,medium)		
		
		putexcel `=char(66+`ncol')'`nrw' = ("`rownam'") , left  
		forvalues cj=1/`colnum' {
			if "`tabrow'" == "mod" putexcel `=char(66+`ncol'+`cj')'`nrw' = ("${fvlabc`cj'$sfx}") , right 	
			if "`tabrow'" == "focal" putexcel `=char(66+`ncol'+`cj')'`nrw' = ("${mvlabm1c`cj'$sfx}") , right 
		}
		loc ++nrw		
		forvalues m2=1/`m2stp' {
			if ${mvarn$sfx} > 1 {
				putexcel B`nrw' = ("${mvlabm2c`m2'$sfx}") , left 
				loc ++nrw
			}
			forvalues ri = 1/`rownum' {
				if "`tabrow'" == "mod" putexcel `=char(66+`ncol')'`nrw' = ("${mvlabm1c`ri'$sfx}") , left	
				if "`tabrow'" == "focal" putexcel `=char(66+`ncol')'`nrw' = ("${fvlabc`ri'$sfx}") , left	
				loc ++nrw
			}
		loc nrw = `nrw' - `rownum'
			putexcel `=char(66+`ncol'+1)'`nrw'= mat(`h2'[`=1+(`m3'-1)*(`m2stp'*`rownum')+(`m2'-1)*`rownum''..`=`rownum'+(`m3'-1)*(`m2stp'*`rownum')+(`m2'-1)*`rownum'',1..`colnum']) , nform(`nform')  
			forvalues fnti=1/`rownum' {
			forvalues fntj=1/`colnum' {
				loc fsz=11
				forvalues fsi=2/6 {
					if `tababs'(`h2'[`=`fnti'+(`m3'-1)*(`m2stp'*`rownum')+(`m2'-1)*`rownum'',`fntj']) >= `qt`=`fsi'-1'' & `tababs'(`h2'[`=`fnti'+(`m3'-1)*(`m2stp'*`rownum')+(`m2'-1)*`rownum'',`fntj']) < `qt`fsi'' loc fsz= 10+`fsi'
				}
				if `qt6'-.5 <= 0 loc fsz = 27 - `fsz'
				putexcel `=char(66+`ncol'+`fntj')'`=`nrw'+`fnti'-1' , font(calibri ,`fsz')
			}
			}		
			
			loc nrw = `nrw' + `rownum'
		}
		putexcel (B`nrw':`=char(66+`ncol'+`colnum')'`nrw') , border(top,medium)		
		loc ++nrw
	}
}
}
********************************************************************************************************
***          Create Plot if Requested

if `"`plot'"' != ""  {
est restore `estint'
glo adjzi$sfx = 0
	if ("`e(cmd)'" == "zip" | "`e(cmd)'" == "zinb" ) &  "`outmetric'" == "model" {
		margins if esamp$sfx  ${sumwgt$sfx} , predict(pr) at((means) _all) `nowgt'
		mat h3 = r(b)		
		glo adjzi$sfx = h3[1,1]
		est restore `estint'
	} 
margins if esamp$sfx  ${sumwgt$sfx} , `outmarg' `atinfo' post nose `nowgt'
mat hold= e(at)
mkmargvar intmod  `plttype' `predy1' `fvar' `mvar1'  `scatrev' `mvar2' `mvar3' `mvar4'

est restore `estint'

***** standardize predicted outcome if outmetric = model and SDY option [[REMOVED adjust if ZIP or ZINB by ln(1-pr(always zero))]]

	if ("`e(cmd)'" == "zip" | "`e(cmd)'" == "zinb") & "`outmetric'" == "model" & "${eqname$sfx}" != "inflate" replace `predy1' = `predy1'+ln(1-${adjzi$sfx}) if `mvar1' < .	
	if "`ystand'" == "yes" 	replace `predy1' = (`predy1'- ${ymn$sfx}+ ln(1-${adjzi$sfx}) )/${ystd$sfx}  if `mvar1' < .

glob frevcode$sfx "`r(frevcode)'"
forvalues i=1/`mstp' {
	glob m`i'revcode$sfx "`r(m`i'revcode)'"
}
if "`outmain'" != "" & "`outmetric'" == "obs" {
	estimates restore `outmain'
	atspec, outmetric(`outmetric') plttype(`plttype') model(main) int3way(${int3way$sfx}) outatopt(`outatopt') scatrev("`scatrev'")
		loc atinfo "`r(atinfo)'"
	margins if esamp$sfx  ${sumwgt$sfx} , `outmarg' `atinfo' post nose `nowgt'
	mkmargvar main `plttype' `predy1mn' `fvarmn' `mvarmn1'  `scatrev' `mvarmn2' `mvarmn3' `mvarmn4'

est restore `estint'
}


***	Set loop stops for M2,.. M6... if exist & set to 1 if Not Spec .  Pass to plot programs. 
***	
forvalues i=2/6 {
	loc mod`i' ""
	loc mstp`i' = 1
	if ${mvarn$sfx}  >= `i' {
		levelsof `mvar`i'' , loc(mval`i') 
		loc mstp`i': list sizeof mval`i'
		loc mod`i' = `i'		
	}
} 


*****************************************************************************************************************************
***  LOOP Over Moderators if > 2 		Current functionality only allows 2 moderators.  REVISE LATER

glo grnames$sfx "" 
glo pannum$sfx=0

***  FRQTXT  TITXT MODTXT MAINTXT  MLABTXT used to specify options/info for plot commands .  PANTXT used for panel labelling if mods>2

loc frqtxt ""
if "`pltfreq'" != "" loc frqtxt "frqmat(`frqmat') base(`pltfreq')"

loc dvtxt "${dvname$sfx}"
if "`outmetric'" == "model" loc dvtxt "g(${dvname$sfx})`ystandtxt'"
if ("`e(cmd)'" == "mlogit" |  "${ordcatnum$sfx2}" !="") &  "`outmetric'" == "obs" loc dvtxt "`e(depvar)'[${eqnow$sfx2}]"
if  ${eqnum$sfx2} == 1 & "`e(cmd)'" == "mlogit" &  "`outmetric'" == "obs" loc dvtxt "`e(depvar)'[${eqname$sfx}]"
if ${mvarn$sfx} == 1 {
	loc titxt "`dvtxt' by the Interaction of "   
	loc titxt2 "${fvldisp$sfx} and ${mvldisp1$sfx}" 
}
if ${mvarn$sfx} == 2  {
	loc titxt "`dvtxt' by the Two-way Interactions of "
	loc titxt2 "${fvldisp$sfx} with ${mvldisp1$sfx} and ${fvldisp$sfx} with ${mvldisp2$sfx}"
	if "${int3way$sfx}" == "y" {
		loc titxt "`dvtxt' by the Three-way Interaction of"  
		loc titxt2 "${fvldisp$sfx}, ${mvldisp1$sfx} and ${mvldisp2$sfx}"
	}
}
if ${mvarn$sfx} > 2 {
	loc titxt "`dvtxt' by the Two-way Interactions of"
	loc titxt2 "${fvldisp$sfx} with ${mvldisp1$sfx}, ${mvldisp2$sfx}"
	if ${mvarn$sfx} > 3 {
		forvalues mi=4/`mstp' {
			loc titxt2 "`titxt2', ${mvldisp`mi'$sfx}"
		}
	}
	loc titxt2 "`titxt2' and ${mvldisp`mstp'$sfx}"
}
loc titxt3 "`dvtxt' by the Main Effects of"
loc modtxt ""
loc maintxt ""
if "`outmain'" != "" loc maintxt "predmn(`predy1mn') "
if ${mvarn$sfx} > 1 {
	forvalues mi=2/`mstp' {
		loc modtxt "`modtxt' mvar`mi'(`mvar`mi'')"
	loc mlabtxt`mi' ""
	loc pantxt`mi' ""
	}
	}
*

forvalues m3 = 1/`mstp3'  {
	if `mstp3' != 1 {
		loc mlabtxt3 "mlab3(${mvlabm3c`m3'$sfx})"
		loc pantxt3 "Panel ${pannum$sfx}: ${mvldisp3$sfx} = ${mvlabm3c`m3'$sfx}"
	}
forvalues m4 = 1/`mstp4'  {
	if `mstp4' != 1 {
		loc mlabtxt4 "mlab4(${mvlabm4c`m4'$sfx})"
		loc pantxt4 " and ${mvldisp4$sfx} = ${mvlabm4c`m4'$sfx}"	
	}
forvalues m5 = 1/`mstp5'  {
	if `mstp5' != 1 {
		loc mlabtxt5 " mlab5(${mvlabm5c`m5'$sfx})"
		loc pantxt5 " and ${mvldisp5$sfx} = ${mvlabm5c`m5'$sfx}"	
	}
forvalues m6 = 1/`mstp6'  {
	if `mstp6' != 1 {
		loc mlabtxt6 " mlab6(${mvlabm6c`m6'$sfx})"
		loc pantxt6 "`pantxt' and ${mvldisp6$sfx} = ${mvlabm6c`m6'$sfx}"	
	}
loc mlabtxt " `mlabtxt3' `mlabtxt4' `mlabtxt5' `mlabtxt6' "
loc pantxt " `pantxt3' `pantxt4' `pantxt5' `pantxt6' "

		if "`plttype'" ==  "scat" { 
			noi scatyhat , predint(`predy1') fvar(`fvar') mvar1(`mvar1') `modtxt' `maintxt' `mlabtxt' ///
				dual(`outdual') sdy(`outsdy') outmain(`outmain') scatrev(`scatrev')	 frqmat(`frqmat') base(`pltfreq') ndig(`ndigits') ///
				`pltkeep' name(`grphnm') save(`savenm') sing(`pltsing') /// 
				 dvtxt(`dvtxt') titxt(`titxt') titxt2(`titxt2') titxt3(`titxt3') pantxt(`pantxt') estint("`estint'") pltopts(`pltopts')

		}
		if "`plttype'" ==  "bar"  /// 
			baryhat,  predint(`predy1') fvar(`fvar') mvar1(`mvar1') `modtxt' `maintxt' `mlabtxt' ///
				dual(`outdual') sdy(`outsdy') outmain(`outmain') 	 frqmat(`frqmat') base(`pltfreq') ndig(`ndigits') ///
				`pltkeep' name(`grphnm') save(`savenm') sing(`pltsing') /// 
				 dvtxt(`dvtxt') titxt(`titxt') titxt2(`titxt2') pantxt(`pantxt') estint("`estint'") pltopts(`pltopts') blabopts(`blabopts')
		
		if "`plttype'" ==  "contour" ///
			contyhat ,  predint(`predy1') fvar(`fvar') mvar1(`mvar1') `modtxt' `maintxt' `mlabtxt' ///
				dual(`outdual') sdy(`outsdy') frqmat(`frqmat') base(`pltfreq') ndig(`ndigits') ///
				`pltkeep' name(`grphnm') save(`savenm') sing(`pltsing') /// 
				 dvtxt(`dvtxt') titxt(`titxt') titxt2(`titxt2') pantxt(`pantxt') estint("`estint'") ccuts(`ccuts') pltopts(`pltopts')

		loc mlabtxt "" 
		loc pantxt "" 		
	}
}
}
}
}
*
}
drop *$sfx

loc mygloblist:  all globals "*$sfx"
mac drop `mygloblist'
*
est restore `estint'

** Close quiet loop
}
end
