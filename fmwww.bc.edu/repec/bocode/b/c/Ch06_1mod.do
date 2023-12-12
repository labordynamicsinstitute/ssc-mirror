**  CH 6  Example 1:  NBREG
**  SEI-by-Work_Family_Conflict

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


******			NOT in factor notation  wfcbysei  is product term
nbreg pmhdays wfconflict sei wfcbysei age educ childs female  if wrkstat <=4
est store nofact

intspec focal(sei) 	/// 
	main((sei, name(Job_Status) range(17(20)97)) 		///
		(wfconflict, name(W_F_Conflict)  range(1/4))) 	///
	int2(wfcbysei) dvname(Poor_M_H_Days) abbrevn(13) ndig(0)
	

*** GFI	
gfi, ndig(5)
gfi, factor ndig(5)


*** SIGREG **********************************************************************

**  effect of b
sigreg,  sig(.05 ) save(Output/sigtable_ch06_1mod.xlsx tab mat ) ndig(5) 

**  factor change for 1 s.d. change in conflict
sigreg,  sig(.05 )  ndig(3)  effect(factor(sd))

**  modelled outcome y* change for 1 unit change in conflict, scaled in s.d. of y*
sigreg,  sig(.05 )  ndig(4)  effect(b(sdy))

**  modelled outcome y* change for 1 s.d. change in conflict, scaled in s.d. of y*
sigreg,  sig(.05 )  ndig(4)  effect(b(sdyx))


** discrete change in y 
***
***  Must use factor notation to specify interaction terms and rerun nbreg
***
***  Must have Spost13 installed 

nbreg pmhdays c.sei##c.wfconflict age educ childs female  if wrkstat <=4

intspec focal(c.sei)  main( (c.sei,  name(Job_Status) range(17(20)97))  ///
	(wfconflict,  name(W_F_Conflict)  range(1/4))) /// 
	int2(c.sei#c.wfconflict) dvname(Poor_M_H_Days) abbrevn(13) ndig(0)

	
** discrete change in y for 1 unit change in conflcit

sigreg,  sig(.05 ) ndig(5) /// 
         effect(spost(amtopt(am(one)) atopt((means) _all)))
	
sigreg,  sig(.05 ) ndig(5) /// 
         effect(spost( amtopt(am(sd)) atopt((means) _all)))


*****  EFFDISP   Figure 6.4, 6.5, 6.7 

***  restore estimates from model without factor notation
est restore nofact

intspec focal(sei) 	/// 
	main((sei, name(Job_Status) range(17(20)97)) 		///
		(wfconflict, name(W_F_Conflict)  range(1/4))) 	///
	int2(wfcbysei) dvname(Poor_M_H_Days) abbrevn(13) ndig(0)

	
***  default plot with default options,   Fig 6.4
effdisp

*** revised Fig 6.5
effdisp, ndig(2) plot(freq(tot) name(StatusWFC) save(Output/StatusWFC.xlsx)) 


*** change plot type to error bar Fig 6.7
intspec focal(sei) 	/// 
	main((sei, name(Job_Status) range(17(20)97)) 		///
		(wfconflict, name(W_F_Conflict)  range(1(.5)4))) 	///
	int2(wfcbysei) dvname(Poor_M_H_Days) abbrevn(13) ndig(0)

effdisp, ndig(2) plot(type(errbar) name(StatusWFC_EB) freq(tot) save(Output/StatusWFC_Errbar.xlsx)) 


***************** CHANGE TO FACTOR NOTATION  **********************************

*** Estimate main effects model and store with name holdmn
nbreg pmhdays  sei wfconflict  age educ childs female if wrkstat <=4
est store holdmn

*** Estimate interaction model and store with name intmod
nbreg pmhdays c.sei##c.wfconflict age educ childs female if wrkstat <=4
est store intmod


*****   OUTDISP      
intspec focal(c.sei) main( (c.sei ,  name(Job_Status) range(17(20)97))  ///
	(wfconflict,  name(W_F_Conflict)  range(1/4))) int2(c.sei#c.wfconflict) ///
	dvname(Poor_M_H_Days) abbrevn(13) ndig(0)

*** Figure 6.12.left
outdisp,  plot(type(scat) name(StatusWFC))  tab(row(mod)) 

*** Figure 6.12.right
outdisp,  out(metric(model) dual) plot(type(scat) name(StatusWFCdual)) pltopts(ti( ,size(*.85)))

*** Figure 6.13
outdisp, outcome(main(holdmn)) plot(type(scat) name(StatusWFC_mn))

*** Figure 6.14
outdisp, outcome( main(holdmn)) plot(type(scat) single(1) name(StatusWFC_mn) )

