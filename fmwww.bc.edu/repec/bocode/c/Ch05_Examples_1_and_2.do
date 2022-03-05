**  CH 5 Logistic Regression Examples 1and 2
**      Example 1:  One moderator:  Region-by-Race
**		Example 2:  Two moderators:  Race-by-Region and Race-by-Education

**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_1987.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_1987.dta, clear  



****  EXAMPLE 1 ********************************************************

**  Estimate and Store Main Effect model & then Interaction Effect model  
logit  ban i.racew c.ed i.region16   age class contact 
est store main

logit  ban i.racew##c.ed i.racew##i.region16   age class contact 
est store int2

*** Fig 5.7 & 5.8 & 5.9  & 5.10
intspec focal(i.region16) main( (i.region16, name(Region) range(0/1)) ///
	(i.racew, name(Race) range(0/1))) int2(i.racew#i.region16)
	
effdisp , plot(type(errbar)) pltopts(ylab(-1(1)2)) ndig(0)

effdisp , effect(b(sdy)) pltopts(ylab(-.5(.5)1)) ndig(1)

outdisp, plot(type(bar)) ndig(2) out(metric(model) dual)   blabopts(size(medsmall) orient(horizontal)) ///
 pltopts(ytit( , ma(r+4)) ti( ,size(*.9)))

outdisp, plot(type(bar)) ndig(3) out(metric(obs) main(main) atopts( (means) _all))  pltopts(ylab(0(.1).5))  



****  EXAMPLE 2 ********************************************************

**  Estimate and Store Main Effect model & then Interaction Effect model  
logit  ban i.racew c.ed i.region16   age class contact 
est store main

logit  ban i.racew##c.ed i.racew##i.region16   age class contact 
est store int2

*** Fig 5.11 & 5.12 & 5.13
intspec focal(c.ed) main( (c.ed, name(Education) range(0(4)20)) ///
	(i.racew, name(Race) range(0/1))) int2(i.racew#c.ed) ndig(0) dvname(Approval of Ban)  abbrevn(15) 
	
effdisp ,  effect(b(sdy)) pltopts(ylab(-.15(.05).05)) ndig(2)

outdisp, plot(type(scat)) ndig(2) out(metric(model) dual atopts((means) _all))  

outdisp, plot(type(scat)) out(metric(obs) main(main) atopts( (means) _all))  pltopts(ylab(0(.2).8))   
