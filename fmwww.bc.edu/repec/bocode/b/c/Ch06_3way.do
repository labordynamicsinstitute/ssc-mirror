**  CH 6  NBREG Example with 3-way Interaction
**     Sex-by-Age-by-Education
		
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



*** Estimate main effects model and store with name holdmn
nbreg memnum i.female c.age c.ed  size class
est store holdmn

*** Estimate main effects model and store with name mem3way
nbreg memnum i.female##c.age##c.ed size class 
est store mem3way


***  INTSPEC 

intspec focal(i.female) ///
	main( (c.age , name(Age) range(18(10)88))       /// 
		(c.ed , name(Education) range(0(2)20))       /// 
		(i.female , name(Sex) range(0/1)))           ///   
	int2( c.age#i.female c.ed#i.female c.age#c.ed ) ///
	int3(i.female#c.age#c.ed) dvname(Memberships) ndig(0)


*****   SIGREG  output and Figure 6.3A&B
sigreg, sig(.05 ) save(Output\Figure_6_3_A.xlsx tab mat) ndig(3) plot(Bound_Values, 6) ///
	pltopts(ytit( , ma(r +2)) tit( , size(*.9)))
	

******  EFFDISP
intspec focal(i.female)  main( (c.age , name(Age) range(18(15)88)) /// 
	(c.ed , name(Education) range(0(4)20)) (i.female , name(Sex) range(0/1))) ///   
	int2(i.female#c.age i.female#c.ed c.age#c.ed) int3(c.age#c.ed#i.female) ndig(0) dvname(Memberships)

*** Figure 6.10
effdisp,  ci(.95) plot(type(contour) name(AgeEdSex)) sigmark  

*** No figure, specify cutpoints
effdisp,  ci(.95) plot(type(contour) name(AgeEdSex)) sigmark ccuts(-1.2(.3).6) 

*** Figure 6.11
effdisp,  ci(.95) plot(type(contour) keep freq(subtot) name(AgeEdSex) ) sigmark   


*****   OUTDISP
intspec focal(i.female)  main( (c.age , name(Age) range(18(20)78)) ///
	(c.ed , name(Education) range(2(6)20)) (i.female , name(Sex) range(0/1))) /// 
	int2(i.female#c.age i.female#c.ed c.age#c.ed) int3(c.age#c.ed#i.female) ///
	dvname(Memberships) abbrevn(13) ndig(0)

*** Figure 6.17.1  and 6.17.2
outdisp,   plot(type(bar) name(AgeEdSex)) outcome(atopts( (means) _all)) ndig(2) ///
	pltopts(plotreg(ma(t+2)))
	
*** Figure 6.18.1  and 6.18.2  chi
outdisp,   plot(type(bar)) outcome( main(holdmn)atopts((means) _all)) ndig(2) ///
	pltopts(plotreg(ma(t+2)))
	
*** Figure 6.19.1  and 6.19.2  chi
outdisp, plot(type(bar) name(AgeEdSexMod) ) outcome(metric(model) sdy dual atopts((means) _all)) ndig(2) ///
	pltopts(plotreg(ma(t+2 b+3)))
	
