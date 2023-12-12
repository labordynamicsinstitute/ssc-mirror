**  CH 3 OLS Example with One Moderator & Categorical focal 
**		Wealth on kids x Headship Type
		
version 14.2      
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/SIPP_Wealth.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use SIPP_Wealth.dta, clear  

**   Make folder named "Output" to store saved figures or Excel files 
**	 in current directory if does not already exist
mata: st_numscalar("dout", dirout=direxists("Output")) 
if dout==0 mkdir Output



***   FOCAL = HEAD OF HOUSEHOLD *************************************************

***  Table 3.2 

regress netw10k metro i.edcat i.hoh##c.kids age agesq retired nilf hhld_income 
mat list e(b)
mat list e(V)

intspec focal(i.hoh) main( (c.kids ,  name(Children) range(0/10))  ///
	(i.hoh,  name(Headship_Type)  range(0/2))) int2(i.hoh#c.kids) ndig(0) abbrevn(14)

sigreg ,  ndig(2)

*** Figure 3_4

effdisp  , plot(type(cbound) freq(tot))  ndig(0)  pltopts(xlab(0(2)10))



***   FOCAL = KIDS  *************************************************

*** Figure 3_3
intspec focal(c.kids) main( (c.kids ,  name(Children) range(0/10))  ///
	(i.hoh,  name(Headship_Type)  range(0/2))) int2(i.hoh#c.kids) ndig(0) abbrevn(14)

effdisp  , plot(type(errbar) freq(tot)) ndig(1) pltopts(ylab(-2.5(1)1.5)) 
