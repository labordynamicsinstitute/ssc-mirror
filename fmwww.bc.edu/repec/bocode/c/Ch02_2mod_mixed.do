**  CH 2 Logit Example with 2 moderators
**      race-by-region  race-by-education
		
version 14.2
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_1987.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_1987.dta, clear  


logit ban i.racew##region16  i.racew##c.ed age class contact 
mat list e(b)
mat list e(V)

**  interaction specification for Table 2.1 and GFI

intspec focal(i.racew) main((c.ed, name(Education) range(0 20)) (i.region16, name(Region) range(0/1)) (i.racew, name(Race))) ///
	int2(i.racew#c.ed i.racew#i.region16)
	
gfi, ndigit(3)

****  Figure 2.4 interaction specification
intspec focal(i.racew) main((c.ed, name(Education) range(0(4)20)) (i.region16, name(Region) range(0/1)) (i.racew, name(Race))) ///
	int2(i.racew#c.ed i.racew#i.region16)

effdisp , plot(type(line) freq(subtot)) ndig(1)
