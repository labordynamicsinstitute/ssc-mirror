** CH 5  Count Model ExampLe 4 3way interaction
**      Age-by-Education-by-Sex
		
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



**  Estimate and Store Main Effect model & then Interaction Effect model  
nbreg memnum c.age c.ed i.sex size class 
est store main
nbreg memnum c.age##c.ed##i.sex size class 
est store int1

*** Figure 5.18 
intspec focal(c.age)  main((c.age , name(Age) range(18(14)88))  /// 
	 (c.ed , name(Education) range(0(4)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#c.ed c.age#i.sex  c.ed#i.sex  ) int3(c.age#c.ed#i.sex ) ndig(0) dvname(Memberships)

effdisp , plot(type(cbound)) ndig(2) pltopts(ylab(-.03(.02).05, labsize(*.8)))

	
*** Table 5.2 
outdisp , out(metric(obs) atopt((means) _all)) tab(save(Output/Pred_Memnum.xlsx))  ndig(3)


*** Figure 5.19
outdisp , plot(type(scat))  out(metric(model) sdy atopt((means) _all) dual ) tab(save(Output/Calcs_Fig_5_19.xlsx)) 


*** Figure 5.20 
intspec focal(c.age)  main((c.age , name(Age) range(20(20)80))  /// 
	 (c.ed , name(Education) range(0(5)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#c.ed c.age#i.sex  c.ed#i.sex  ) int3(c.age#c.ed#i.sex ) ndig(0) dvname(Memberships)

outdisp , plot(type(scat))  out(metric(obs) atopt((means) _all) main(main) ) ///
	pltopts(ylab(0(1.5)6 ) )

