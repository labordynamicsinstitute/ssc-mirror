** CH 7  OLS Model Two Moderators
**      FamilyIncome-by-Cohort  FamilyIncome-by-Education
		
version 14.2			
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_2010.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_2010.dta, clear  

**   Make folder named "Output" to store saved figures or Excel files 
**	 in current directory if does not already exist
mata: st_numscalar("dout", dirout=direxists("Output")) 
if dout==0 mkdir Output



**  Estimate and Store Interaction Effect model  
reg childs c.faminc10k##(i.cohort c.educ) sibs i.race religintens  if age>39 
est store intmod


***  COHORT FOCAL ********************************************************

intspec  focal(i.cohort)  /// 
	main((c.faminc10k , name(Family_Inc) range(1(3)19)) /// 
		(i.cohort, name(Cohort))) ///
	int2(c.faminc10k#i.cohort) ndig(0) 

	
***   GFI
gfi , ndig(3) 


*** SIGREG
sigreg, sig(.05)  ndig(3)  


***  EFFDISP   Figure 7.5
effdisp , ndig(1) plot(name(etest))


*** OUTDISP   Figure 7.6
outdisp, out(atopt( (means) _all))  plot(name(otest)) table(row(mod)) ndig(2) 



***  ED FOCAL ********************************************************
reg childs c.faminc10k##(i.cohort c.educ) sibs i.race religintens  if age>39 

intspec  focal(c.ed)  /// 
	main((c.faminc10k , name(Family_Inc) range(1(3)19)) /// 
		(c.educ , name(Education) range(0(4)20)) ) ///
	int2( c.faminc10k#c.educ ) ndig(0) 


*** GFI
gfi ,  ndig(4) 


*** SIGREG
sigreg,  ndig(4)  


*** OUTDISP   Figure 7.7.1
outdisp, out(atopt( (means) _all))   plot(name(Plot1)) tab(row(mod)) 

*** Figure 7.7.2
outdisp, out(atopt( (means) _all))   plot(name(Plot2))  pltopts(xlab(0(4)20) ///
	ylab(1 3 5) ymtick(2 4, tl(*2)) ysc(r(.5)))


*** Remove value labels from educ to make result labelling less messy
lab val educ

	
***  faminc10k FOCAL ********************************************************
reg childs c.faminc10k##(i.cohort c.educ) sibs i.race religintens  if age>39

intspec  focal(c.faminc10k)  /// 
	main((c.faminc10k , name(Family_Inc) range(1(3)19)) /// 
		(i.cohort , name(Cohort)) ///
		(c.educ , name(Education) range(0(5)20)) ) ///
	int2(c.faminc10k#i.cohort c.faminc10k#c.educ ) ndig(0) 

	
*** GFI   Figure 7.8
gfi ,  ndig(4) path(all, ndig(4) boxw(1.5) /// 
	title("Interaction of Family Income by Cohort, Family Income by Education"))


***  SIGREG
intspec  focal(c.faminc10k)  /// 
	main((c.faminc10k , name(Family_Inc) range(1(3)19)) /// 
		(i.cohort , name(Cohort)) ///
		(c.educ , name(Education) range(0(2)20)) ) ///
	int2(c.faminc10k#i.cohort c.faminc10k#c.educ ) ndig(0) 

sigreg,  sig(.05) ndig(4)  

*** Table 7.4
sigreg,  sig(.05) ndig(4) save(Output/Table_7_4.xlsx table)


***  EFFDISP   Figure 7.9.1 and 7.9.2
intspec  focal(c.faminc10k)  /// 
	main((c.faminc10k , name(Family_Inc) range(1(3)19)) /// 
		(c.educ , name(Education) range(0(5)20))  ///
		(i.cohort , name(Cohort))) ///		
	int2( c.faminc10k#c.educ c.faminc10k#i.cohort) ndig(0) 

effdisp, plot(type(cbound) name(FamInc)) ndig(1) pltopts(ylab(-.3(.2).3))
graph export Output/Figure_7_9_1.png, replace name(FamIncPan_1)
graph export Output/Figure_7_9_2.png, replace name(FamIncPan_2)


**** OUTDISP 

intspec  focal(c.faminc10k)  /// 
	main((c.faminc10k , name(Family_Inc) range(1(4.5)19)) /// 
		(c.educ , name(Education) range(0(5)20))  ///
		(i.cohort , name(Cohort))) ///		
	int2( c.faminc10k#c.educ c.faminc10k#i.cohort) ndig(1) 

***  FIgure 7.10, Table 7.5
outdisp, out(atopt((means) _all)) plot(name(Childs_by_IncCohEd)) ndig(2) ///
	tab(rowvar(mod) save(Output/Table_7_5.xlsx)) 	pltopts(ylab(0(2)6) ymtick(1 3 5, tl(*2)) ytit("Number of Children") /// 
    xtit("Family Income") xlab(1 "$10K" 7 "$70K" 13 "$130K" 19 "$190K"))
graph export Output/Figure_7_10_1.png, replace name(Childs_by_IncCohEd_A)
graph export Output/Figure_7_10_2.png, replace name(Childs_by_IncCohEd_B)


** Determine value of moderator at which differences among effects of categories of a nominal focal predictor become not significant
**  Must run mcattest.ado from icalc_spec package or highlight and run program below
mcattest,  mcvar(cohort) var2(faminc10k) vallist(0(1)20)
mcattest,  mcvar(cohort) var2(faminc10k) vallist(15(.1)17)



program mcattest
version 14.1
syntax  , mcvar(varname) var2(varname) vallist(string) 
tempname estnm
qui{
est store `estnm'
levelsof `mcvar', loc(nval)
loc ncat : list sizeof nval
mtable , at (`var2' "= (`vallist')" `mcvar'=(`nval')) atmeans stat(pvalue noci) post
mlincom , clear
loc atind = 1-`ncat'
forvalues fi = `vallist' {
	loc atind= `atind' + `ncat'
	loc difftxt ""
	forvalues i=1/`=`ncat'-1' {
	forvalues j=1/`=`ncat'- `i'' {
	
		if `j' == 1 & `i'== 1 loc difftxt "`difftxt' `=`atind'+`j'' - `atind'  "
		if `j' > 1 | `i' > 1 loc difftxt "`difftxt' + `=`atind'+`j'+`i'-1' - `=`atind'+`i'-1'  "
	}
	}
	mlincom `difftxt' , add rowname("`fi'")
}
}
mlincom
qui est restore `estnm'
end 
