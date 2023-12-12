** CH 8  Logit (Probit) Model  One Moderator
**      SES-by-AGE
		
version 14.2			
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_1998.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_1998.dta, clear  

**   Make folder named "Output" to store saved figures or Excel files 
**	 in current directory if does not already exist
mata: st_numscalar("dout", dirout=direxists("Output")) 
if dout==0 mkdir Output


** Set current directory then read in data from folder "Data" in current directory

cd "c:\ICALC_Examples"
use Data\GSS_1998.dta, clear  

**  Estimate and Store Interaction Effect model  

logit gun i.sex##i.location c.age##c.age educ i.fearnbhd i.race
est store lgtint


********** Focal= SEX **********
intspec focal(i.sex) main( (i.sex, name(Sex) range(0/1)) /// 
	(i.location, name(Location) range(1/3))) int2(i.sex#i.location) ndig(3)

	
*** GFI
gfi , factor


***  SIGREG

***  Effect on latent outcome /ln odds
sigreg 

***  effect on latent outcome in s.d. units
sigreg , effect(b(sdy)) nobva

***  effect as factor change
sigreg , effect(factor)

*** effect as discrete change
sigreg , effect(      /// 
		spost(           /// 
			amtopt(am(bin) )  /// 
			atopt((means) _all)   )) nobva

*** create sig region table based on main effects model			
logit gun i.sex i.location c.age##c.age educ fearnbhd race

mchange sex , at((means) _all location=1) am(bin) brief
mchange sex , at((means) _all location=2) am(bin) brief
mchange sex , at((means) _all location=3) am(bin) brief


			
*** effdisp    Figure 8.1
est restore lgtint
effdisp , ndig(1)



********** Focal= LOCATION **********
***
***   Rerun model so order of vars in interaction on logit the same as specified for int2\
***
****************************************************************************************************

logit gun i.location##i.sex c.age##c.age educ fearnbhd race

intspec focal(i.location) main( (i.location, name(Location) range(1/3)) ///
	(i.sex, name(Sex) range(0/1)) ) int2(i.location#i.sex)
	
gfi , factor


***  SIGEG

***  effect on ln odds
sigreg 

***  effect on latent outcome in s.d. units 
sigreg , effect(b(sdy))

***  effect as factor change
sigreg , effect(factor)

*** effect as discrete change
sigreg , effect(      /// 
		spost(           /// 
			amtopt(am(bin) )  /// 
			atopt((means) _all)   )) nobva
			
*** discrete change effects from a main effects model
logit gun i.sex i.location c.age##c.age educ fearnbhd race

mchange location , at((means) _all sex=0) am(bin) brief
mchange location , at((means) _all sex=1) am(bin) brief


***  OUTDISP 

***  switch back to sex as focal 
logit gun i.sex##i.location c.age##c.age educ fearnbhd race
est store lgtint 

intspec focal(i.sex) main( (i.sex, name(Sex) range(0/1)) /// 
	(i.location, name(Location) range(1/3))) int2(i.sex#i.location) ndig(3)

outdisp , out(atopt( (means) _all)) tab(def)  plot(def) ndig(2) pltopts(ylab(0(.25)1))


***  Compare predictions from interaction effects to main effects only model
***    first run and save main effects then restore interaction model estimates
quiet logit gun i.sex i.location c.age##c.age educ fearnbhd race
est store lgtmain
est restore lgtint 

outdisp , plot(type(bar) name(barmain)) /// 
	outcome(main(lgtmain) atopt( (means) _all)) ndig(2) pltopts(ylab(0(.25)1))
	

*** Predicted model metric (y*-standardized axis & dual axis) 

outdisp , plot(type(bar) name(barmodeldual)) tab(def) /// 
	outcome(metric(model) dual sdy atopt( (means) _all) ) ndig(2)  pltopts(ylab(-.25(.5)1.25) ysc(r(-.5 1.4)))

	graph export Output/Figure_8_4.png , replace



***  Compare probit to logit

probit gun i.sex i.location c.age##c.age educ fearnbhd race
est store probmain
fitstat , saving(probmain)
 

quiet {
	probit gun i.sex##i.location c.age##c.age educ fearnbhd race
	est store probmod
	mat pb=e(b)
	intspec focal(i.sex) main( (i.sex, name(Sex) range(0/1)) /// 
		(i.location, name(Location) range(1/3))) int2(i.sex#i.location)
	noi sigreg , effect(b(sdy))
	noi outdisp , plot(type(bar) name(barprobit)) tab(def) out(atopt( (means) _all)) /// 
		ndig(2) pltopts(ylab(0(.2).8) text( 1 0 "Probit" ,size(*1.2) place(west) j(left)) ///
		plotreg(ma(t +3))) 

	logit gun i.sex##i.location c.age##c.age educ fearnbhd race
	est store logtmod
	mat lb=e(b)
	intspec focal(i.sex) main( (i.sex, name(Sex) range(0/1)) /// 
		(i.location, name(Location) range(1/3))) int2(i.sex#i.location)
	noi sigreg , effect(b(sdy))
	noi outdisp , plot(type(bar) name(barlogit)) tab(def) out(atopt( (means) _all)) ///
		ndig(2) pltopts(ylab(0(.2).8) text( 1 0 "Logit" ,size(*1.2) place(west) j(left)) ///
		plotreg(ma(t +3)))
}

est tab logtmod probmod , b(%8.4f) p(%6.3f)
