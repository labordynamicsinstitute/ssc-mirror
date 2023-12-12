**  CH 6  OLS Example with 2 modorators
**     Family_Income-by-Cohort 	Family_Income-by-Education
		
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



*** Remove educ value labels to make results labelling simpler
lab val educ 

*** Estimate main effects model and store with name m2main
reg childs faminc10k sibs i.cohort educ i.race religintens c.faminc i.cohort c.educ if age>39
estimates store m2main

*** Estimate interaction effects effects model and store with name m2
reg childs c.faminc10k##i.cohort c.faminc10k##c.educ sibs i.race religintens  if age>39
estimates store m2


****  INTSPEC FAMILY INCOME BY EDUCATION ,  FAMILY INCOME BY COHORT 
intspec  focal(c.faminc10k) /// 
	main((c.educ , name(Education) range(0(2)20))     ///
		(c.faminc10k , name(Family_Inc) range(0(2)24)) /// 
		(i.cohort , name(Cohort)))        ///
	int2(c.faminc10k#c.educ c.faminc10k#i.cohort) ndig(0) 
	
***  GFI	
gfi, 	ndig(4) path(all, ndig(3) boxwidth(1.35)  ///
		title(Interaction Effects of Family Income by Education and Family Income by Cohort)) 


*****   EFFDISP

*** Figure 6.8 
effdisp,  ci(.95) plot(type(cbound) name(IncEdCohort) freq(tot) save(Output/IncEdCohort.xlsx)) /// 
	ndig(2) pltopts(ylab( -.3(.15).15 , labsize(*.8)))
	
*** Figure 6.9
intspec  focal(c.faminc10k)  /// 
	main( (c.faminc10k , name(Family_Inc) range(0(2)24)) ///
		  (i.cohort , name(Cohort) range(1/4))  /// 
		  (c.educ , name(Education) range(0(4)20))) ///
	int2(c.faminc10k#i.cohort c.faminc10k#c.educ )  

effdisp,  ci(.95) plot(type(errbar) name(IncCohortEd)  freq(tot) save(Output/IncCohortEd.xlsx)) ///
	ndig(2) pltopts(ylab( -.3(.15).15 , labsize(*.8)))

	
*****   OUTDISP
intspec  focal(c.faminc10k)  /// 
	main((c.educ , name(Education) range(0(4)20)) ///
		(c.faminc10k , name(Family_Inc) range(0(6)24)) /// 
		(i.cohort , name(Cohort) range(1/4))) ///
	int2(c.faminc10k#c.educ c.faminc10k#i.cohort) ndig(0) 

*** Figure 6.15
outdisp, plot(type(contour) name(IncEdCohort)) 

*** Figure 6.16
outdisp, plot(type(scat) name(IncEdCohort_Scat))  

*** Table 6.1
outdisp,  tab(save(Output/Table_6_1.xlsx)) ndig(2)
