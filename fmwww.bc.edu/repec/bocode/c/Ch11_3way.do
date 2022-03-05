**  CH 11  3 way Interaction 
**		sex-by-age-by-education 
		
version 14.2
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_1987.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_1987.dta, clear  

**   Make folder named "Output" to store saved figures or Excel files 
**	 in current directory if does not already exist
mata: st_numscalar("dout", dirout=direxists("Output")) 
if dout==0 mkdir Output



*****   AGE FOCAL *******************************************************************
*
** 	Estimate and Store Main & Interaction Effect models 
qui	nbreg memnum c.age c.ed i.sex i.race class 
qui	est store mainmod
qui	nbreg memnum c.age##c.ed##i.sex i.race class 
qui	est store intmod

intspec focal(c.age) main((c.age , name(Age) range(18(14)88))  /// 
	 (c.ed , name(Education) range(0(2)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#c.ed c.age#i.sex  c.ed#i.sex  ) int3(c.age#c.ed#i.sex ) ndig(0)

*** GFI
gfi , ndig(6)  


***  SIGREG 

** Table 11.4 1 unit effect
sigreg, save(Output/table_11_4 tab)  // present and interpret

** Table 11.4  1 s.d. effect
sigreg, save(Output/table_11_4_sdyx tab) effect(b(sdyx)) // present and interpret


***  EFFDISP Figure 11.7 
effdisp , plot(type(errbar)) effect(b(sdyx)) ///
   pltopts(xlab(0(4)20) msym(d)) ndig(1) 


*****OUTDISP ************************************************************************
***
*** AGE FOCAL
*****************************************************

** 	Estimate and Store Main & Interaction Effect models 
qui nbreg memnum c.age c.ed i.sex i.race class 
qui est store mainmod
qui nbreg memnum c.age##c.ed##i.sex i.race class 
qui est store intmod

intspec focal(c.age)  main((c.age , name(Age) range(20(20)80))  /// 
	 (c.ed , name(Education) range(0(5)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#c.ed c.age#i.sex  c.ed#i.sex  ) int3(c.age#c.ed#i.sex ) ndig(0)

***  Figure 11.10  predicted count
outdisp , ndig(3) plot(def)  out(atopt((means) _all))  tab(def) // present and interpret

***  Figure 11.11 predicted count, main effect predictions added
outdisp , out(main(mainmod)  atopt((means) _all))  ndig(3) plot(def) 

***  Figure 11.13  predicted ln(count) standardized
outdisp ,  plot(def) ndig(3) out(metric(model) dual sdy atopt((means) _all)) tab(def)

*** supplement Fig 11_13
intspec focal(c.age)  main((c.age , name(Age) range(18(14)88))  /// 
	(i.sex , name(Sex) range(0/1)) (c.ed , name(Education) range(0(5)20)) ) ///   
	int2(c.age#i.sex c.age#c.ed  c.ed#i.sex ) int3(c.age#i.sex#c.ed ) ndig(0)
outdisp ,  tab(def) ndig(3) out(metric(model) dual sdy atopt((means) _all)) 
	

*****   ED FOCAL *******************************************************************

** 	Estimate and Store Main & Interaction Effect models 
qui nbreg memnum c.ed c.age i.sex i.race class 
qui est store mainmod
qui nbreg memnum c.ed##c.age##i.sex i.race class 
qui est store intmod

intspec focal(c.ed)  main((c.age , name(Age) range(18(14)88))  /// 
	 (c.ed , name(Education) range(0(2)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#c.ed  c.ed#i.sex  c.age#i.sex ) int3(c.ed#c.age#i.sex ) ndig(0)

***  GFI
gfi , factor  


*** SIGREG
sigreg, effect(factor)  nobva ndig(3)	


***  EFFDISP  Figure 11.8 
effdisp , plot(type(cbound))  effect(factor) ndig(0) pltopts(ylab( , form(%6.2f))) 


***  OUTDISP   
intspec focal(c.ed) main((c.ed , name(Education) range(0(5)20)) ///
    (c.age , name(Age) range(20(20)80)) (i.sex , name(Sex) range(0/1)) ) ///   
	int2(c.ed#c.age c.ed#i.sex  c.age#i.sex ) int3(c.ed#c.age#i.sex ) ndig(0)

***  Table 11.6 
outdisp , tab(row(focal) save(Output/Pred_Memnum.xlsx)) ///
  out(atopt((means) _all)) ndig(2) 

***  Table 11.7 
outdisp ,  tab(row(focal) save(Output/Pred_LogMemnum.xlsx)) ///
    ndig(2) out(atopt((means) _all) metric(model) sdy)
 
***  Figure 11.12
intspec focal(c.ed) main((c.ed , name(Education) range(0(5)20)) ///
    (c.age , name(Age) range(18(23)87)) (i.sex , name(Sex) range(0/1)) ) ///   
	int2(c.ed#c.age c.ed#i.sex  c.age#i.sex ) int3(c.ed#c.age#i.sex ) ndig(0)

outdisp , out(main(mainmod)  atopt((means) _all)) plot(sing(1)) ndig(2)

 
*****   Sex FOCAL *******************************************************************

** 	Estimate and Store Main & Interaction Effect models 
qui nbreg memnum i.sex c.age c.ed  i.race class 
qui est store main
qui nbreg memnum i.sex##c.age##c.ed i.race class 
qui est store intmod

intspec focal(i.sex)  main((c.age , name(Age) range(20(10)80))  /// 
	 (c.ed , name(Education) range(0(2)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#i.sex c.ed#i.sex  c.age#c.ed ) int3(i.sex#c.age#c.ed ) ndig(0)

***  GFI
gfi 


*** SIGREG  Table 11.5 
intspec focal(i.sex)  main((c.age , name(Age) range(18(10)88))  /// 
	 (c.ed , name(Education) range(0 2(3)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#i.sex c.ed#i.sex c.age#c.ed ) int3(i.sex#c.age#c.ed) ndig(0)
	
sigreg, effect(spost(amtopt(am(binary)) atopt((means) _all))) ///
  save(Output/table_11_5 tab) ndig(2) 

  
***   EFFDISP  Figure 11.9 
intspec focal(i.sex)  main((c.age , name(Age) range(18(14)88))  /// 
	 (c.ed , name(Education) range(0(5)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#i.sex c.ed#i.sex  c.age#c.ed ) int3(i.sex#c.age#c.ed ) ndig(0)

effdisp , effect(spost(amtopt(am(binary)) atopt((means) _all))) ///
   plot(type(cbound)) ndig(0) 

