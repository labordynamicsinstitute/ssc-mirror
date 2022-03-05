** CH  4   OLS Example 4 with 1 mod categorical
**     Childs regressed on income-by-birth_cohort 
		
version 14.2
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_2010.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_2010.dta, clear  



** 1 Mod mixed
reg childs c.faminc10k##i.cohort c.educ sibs i.race religintens  if age>39

*** Figure 4.8 
intspec  focal(c.faminc10k)  /// 
	main((c.faminc10k , name(Family_Income) range(0(3)24)) /// 
		(i.cohort , name(Cohort) range(1/4))) ///
	int2(c.faminc10k#i.cohort) ndig(0) dvname(Number of Kids) abbrevn(14)

outdisp, plot(type(scat)) out(atopt( (means) _all)) pltopts(ylab(1.4(.4)3.4)) 


*** Figure 4.9 

intspec  focal(i.cohort)  /// 
	main((c.faminc10k , name(Family_Income) range(0(6)24)) /// 
		(i.cohort , name(Cohort) range(1/4))) ///
	int2(i.cohort#c.faminc10k) ndig(0) dvname(Number of Kids) abbrevn(14)

outdisp, plot(type(bar)) ndig(2) out(atopt( (means) _all)) pltopts(plotreg(ma(t +2))) 
