**  CH 4 OLS Examples All Categorical:  focal & 1-2 moderators
**		Example 1: Wealth on education x Headship Type
**		Example 2: Wealth on anykids x Headship Type education x Headship Type
		
version 14.2
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/SIPP_Wealth.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use SIPP_Wealth.dta, clear  



** Figure 4.2  Example 1: 1 mod categorical
regress netw10k metro i.edcat##i.hoh i.anykids age agesq retired nilf hhld_income 

intspec focal(i.edcat) main( (i.edcat, name(Education) range(0/4))   ///
	(i.hoh, name(Head_Type)  range(0/2)) ) ///
	int2(i.edcat#i.hoh) ndig(0) abbrevn(14)

outdisp, plot(type(bar)) out(atopt((means) _all)) ndig(1) pltopts(plotregion(ma(t +4)))


**Figure 4.3 Example 2: 2 mods categorical
regress netw10k metro i.hoh##i.edcat i.hoh##i.anykids age agesq retired nilf hhld_income 

intspec focal(i.hoh) main( (i.edcat, name(Education) range(0/4)) (i.anykids,  name(Children) range(0/1))  ///
	(i.hoh, name(Head_Type)  range(0/2))) int2( i.hoh#i.edcat i.hoh#i.anykids) ndig(0) abbrevn(11) 

outdisp, plot(type(bar)) out(atopt((means) _all)) ndig(1) pltopts(plotregion(ma(t +4))) 
