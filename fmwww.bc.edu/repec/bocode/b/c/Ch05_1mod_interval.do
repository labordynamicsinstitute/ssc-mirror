** CH 5  Count Model Example One Moderator 
**      SEI-by-Work_Family_Conflict
		
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



**  Estimate and Store Main Effect model & then Interaction Effect model  

nbreg pmhdays sei wfconflict age educ childs female if wrkstat <=4
est store main

nbreg pmhdays c.sei##c.wfconflict age educ childs female  if wrkstat <=4
est store int2


**** EFFDISP  Fig 5.14 

intspec  focal(c.wfconflict) main( (c.sei ,  name(OccStatus) range(20(15)95))  (c.wfconflict,  name(WorkVsFam)  range(1/4))) ndig(0) int2(c.sei#c.wfconflict) ///
	dvname(Poor Mental Health Days) abbrevn(23)
effdisp , plot(type(cbound)) ndig(2)

***  Predicted value tables observed & model metrics to get numbers for plot interpretations
outdisp , tab(def)  out(metric(model) atopt((means) _all)  ) 
outdisp , tab(def)  out(metric(obs) atopt((means) _all)  ) 

*** OUTDISP  Fig 5.15 & 5.16 & 5.17

outdisp , plot(type(scat))  out(metric(model) atopt((means) _all) dual ) ///
	pltopts(ylab(-.2(.9)2.5 ))

intspec  focal(c.wfconflict) main( (c.sei ,  name(OccStatus) range(20(25)95))  (c.wfconflict,  name(WorkVsFam)  range(1/4))) ndig(0) int2(c.sei#c.wfconflict) ///
	dvname(Poor Mental Health Days) abbrevn(23)

outdisp , plot(type(scat))  out(metric(obs) atopt((means) _all) main(main)) ///
	pltopts(ylab(0(3)12) tit( , size(*.9)))

outdisp , plot(type(scat) single(1) name(WFC_SES))  out(metric(obs)  atopt((means) _all) main(main))  ///
	pltopts(ylab(0(3)12) )  
