**  CH 2 OLS Example with One Moderator & Categorical focal 
**		Wealth on kids x Headship Type
    		
version 14.2  
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/SIPP_Wealth.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*		use SIPP_Wealth.dta, clear

regress netw10k metro i.edcat i.hoh##c.kids c.age##c.age retired nilf hhld_income 


*** Interaction specification for GFI and Figure 2.2 for HOH focal
intspec focal(i.hoh) main( (c.kids ,  name(Children) range(0/10))  ///
	(i.hoh,  name(Headship_Type)  range(0/2))) int2(i.hoh#c.kids) ndig(0) abbrevn(14)

gfi , ndig(3)
effdisp ,  plot(type(line) freq(tot) ) ndig(0)


**** Interaction specification for GFI and Figure 2.3 for kids focal
intspec focal(c.kids) main( (c.kids ,  name(Children) range(0/2 4(2)10))  ///
	(i.hoh,  name(Headship_Type)  range(0/2))) int2(i.hoh#c.kids) ndig(0)  abbrevn(14)

gfi , ndig(3)
effdisp ,  plot(type(drop) freq(tot)) ndig(1)
