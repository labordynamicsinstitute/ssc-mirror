**  CH 3 Logit Example with 2 moderators
**      race-by-region  race-by-education
		
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



logit ban i.racew##i.region16  i.racew##c.ed age class contact 
mat list e(b)
mat list e(V)

***  FOCAL = RACEW *****************************************************************

intspec focal(i.racew) main((c.ed, name(Education) range(0(2)20)) (i.region16, name(Region) range(0/1)) (i.racew, name(Race))) ///
	int2(i.racew#c.ed i.racew#i.region16) ndig(0)

*** Figure 3.1
sigreg, plot(White) ndig(4)

***  Significance region table 
sigreg, nobva ndig(2)

** Figure 3.5

effdisp , plot(type(cbound) freq(subtot)) ndig(1) pltopts(xlab(0(4)20))

** Figure 3.6
intspec focal(i.racew) main((c.ed, name(Education) range(0(5)20)) (i.region16, name(Region) range(0/1)) (i.racew, name(Race))) ///
	int2(i.racew#c.ed i.racew#i.region16)

effdisp , plot(type(errbar) freq(subtot))  ndig(1)
