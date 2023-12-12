** CH 8 Logit 3-way example
**  contact-by-edcation-by-race
		
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



*** Estimate main effects model and store with name lgtmain
logit ban c.contact c.ed i.racew age region16 class
est store lgtmain

*** Estimate main effects model and store with name lgtint
logit ban c.contact##c.ed##i.racew age region16 class
est store lgtint


***** GFI ANALYSES*****************************************************************************************************

**** Focal = CONTACT

intspec focal(c.contact) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(4)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#c.ed c.contact#i.racew c.ed#i.racew) ///
 int3(c.contact#c.ed#i.racew) ndig(0)
	
gfi, ndig(3) 

**** Focal = EDUCATION
***
intspec focal(c.ed) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(4)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#c.ed c.ed#i.racew c.contact#i.racew) ///
 int3(c.contact#c.ed#i.racew) ndig(0)
	
gfi, ndig(3) 

**** Focal = RACE
***
intspec focal(i.racew) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(4)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#i.racew c.ed#i.racew c.contact#c.ed) ///
 int3(c.contact#c.ed#i.racew) ndig(0)
	
gfi, ndig(3) 


***** FACTOR CHANGE STORY *****************************************************************************************************

**** Focal = CONTACT Table_8_6
intspec focal(c.contact) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(2)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#c.ed c.contact#i.racew c.ed#i.racew) int3(c.contact#c.ed#i.racew) ndig(0)

sigreg, effect(factor) save(Output/Table_8_6.xlsx tab) ndig(3) nobva 


**** Focal = EDUCATION Table_8_7
intspec focal(c.ed) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(2)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#c.ed c.ed#i.racew c.contact#i.racew) int3(c.contact#c.ed#i.racew) ndig(0)
	
sigreg, effect(factor) save(Output/Table_8_7.xlsx tab) ndig(3) 


**** Focal = RACE Table_8_8
intspec focal(i.racew) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(2)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#i.racew c.ed#i.racew c.contact#c.ed) int3(c.contact#c.ed#i.racew) ndig(0)

sigreg, effect(factor) save(Output/Table_8_8.xlsx tab) ndig(3) 



***** LATENT OUTCOME STORY *****************************************************************************************************

**** Focal = CONTACT *****************************************

*** SIGREG  Table 8.9  
intspec focal(c.contact) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(2)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#c.ed c.contact#i.racew c.ed#i.racew) ///
 int3(c.contact#c.ed#i.racew) ndig(0)
	
sigreg, sig(.05) effect(b(sdy)) save(Output/Table_8_9.xlsx tab mat) ndig(3) 


*** OUTDISP  Table 8.12 
intspec focal(c.contact) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(5)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#c.ed c.contact#i.racew c.ed#i.racew) /// 
 int3(c.contact#c.ed#i.racew) ndig(0)

outdisp, out(metric(model) dual sdy atopt((means) _all)) ///
	tab(save(Output/Table_8_12.xlsx))
	
	
*** OUTDISP Figure 8.7 
***
***   switch to Race as first moderator to define plot organization
intspec focal(c.contact) main((i.racew, name(Race) range(0/1)) ///
 (c.ed, name(Education) range(0(5)20)) (c.contact, name(RacialContact) range(0/3))) ///
 int2(c.contact#i.racew c.contact#c.ed c.ed#i.racew) /// 
 int3(c.contact#i.racew#c.ed) ndig(0)

outdisp, out(metric(model) dual sdy atopt((means) _all)) plot(name(Latent_Contact)) ///
	 pltopts(ylab(-.82 ".05" , custom add axis(2)) ///
	yline(-.82 , lp(shortdash) lc(gs9) lw(*.6)) tit(,size(*.8)))
	

**** Focal = EDUCATION *****************************************

*** SIGREG  Table 8.10

intspec focal(c.ed) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(2)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#c.ed c.ed#i.racew c.contact#i.racew) /// 
 int3(c.contact#c.ed#i.racew) ndig(0)
	
sigreg, effect(b(sdy)) save(Output/Table_8_10.xlsx tab mat) ndig(3) 
	
	
*** OUTDISP Figiure 8.6 
*** 
***   switch to Race as first moderator to define plot organization
intspec focal(c.ed) main((i.racew, name(Race) range(0/1)) ///
 (c.ed, name(Education) range(0(5)20)) (c.contact, name(RacialContact) range(0/3))) ///
 int2(c.ed#i.racew c.contact#c.ed c.contact#i.racew) /// 
 int3(c.contact#i.racew#c.ed) ndig(0)

outdisp, out(metric(model) dual sdy atopt((means) _all)) plot(name(Latent_Educ)) ///
	 pltopts(ylab(-.82 ".02" , custom add axis(2)) ///
	yline(-.82 , lp(shortdash) lc(gs9) lw(*.6)))


**** Focal = RACE ***********************************************************

*** SIGREG Table 8.11
intspec focal(i.racew) main((c.contact, name(RacialContact) range(0/3)) ///
 (c.ed, name(Education) range(0(1)20)) (i.racew, name(Race) range(0/1))) ///
 int2(c.contact#i.racew c.ed#i.racew c.contact#c.ed) ///
 int3(c.contact#c.ed#i.racew) ndig(0)
	
sigreg, sig(.05) effect(b(sdy)) save(Output/Table_8_11.xlsx tab mat) ndig(3) 



***** DISCRETE CHANGE AND PREDICTED PROBABILITY OUTCOME STORY **************************************************************
*****
**** Focal = CONTACT, MOD1 = RACE, MOD2 = EDUC ******************************************

*** Rerun logit to ensure order of 2way & 3way terms match focal-by-mod1-by-mod2
logit ban c.contact i.racew c.ed age region16 class
est store lgtmain

logit ban c.contact##i.racew##c.ed age region16 class
est store lgtint


*** SIGREG Table 8.13
intspec focal(c.contact) main((c.contact, name(RacialContact) range(0/3)) ///
 (i.racew, name(Race) range(0/1)) (c.ed, name(Education) range(0(2)20))) ///
 int2(c.contact#i.racew c.contact#c.ed i.racew#c.ed) ///
 int3(c.contact#i.racew#c.ed) ndig(0)
	
sigreg, effect(spost(amtopt(am(one) center) atopt((means) _all))) ///
	save(Output/Table_8_13.xlsx tab mat) ndig(3) 

	
*** OUTDISP 
intspec focal(c.contact) main((c.contact, name(RacialContact) range(0/3)) ///
 (i.racew, name(Race) range(0/1))(c.ed, name(Education) range(0(5)20))) ///
 int2(c.contact#i.racew c.contact#c.ed i.racew#c.ed) ///
 int3(c.contact#i.racew#c.ed) ndig(0)

*** Figure 8.9 Plain
outdisp, out(atopt((means) _all)) plot(def) pltopts(ylab(0(.3).9))

*** Figure 8.11 Superimposed main
outdisp, outcome(main(lgtmain) atopt((means) _all)) plot(def) pltopts(ylab(0(.3).9))


*** Figure 8.12 Superimposed main disaggregated 
outdisp, outcome(main(lgtmain) atopt((means) _all)) plot(sing(1)) pltopts(ylab(0(.3).9))


**** Focal = EDUC, MOD1 = RACE, MOD2 = CONTACT ************************************
***
*** Rerun logit so order of 2way & 3way terms match focal-by-mod1-by-mod2 ordering
logit ban c.ed i.racew c.contact age region16 class
est store lgtmain

logit ban c.ed##i.racew##c.contact age region16 class
est store lgtint


*** SIGREG Table 8.14
intspec focal(c.ed) main((c.ed, name(Education) range(0(4)20)) ///
 (i.racew, name(Race) range(0/1)) (c.contact, name(RacialContact) range(0/3))) ///
 int2(c.ed#i.racew c.ed#c.contact i.racew#c.contact) int3(c.ed#i.racew#c.contact) ndig(0)
	
sigreg, sig(.05) effect(spost(amtopt(am(one) center) atopt((means) _all))) ///
	save(Output/Table_8_14.xlsx tab mat) ndig(3) 

*** OUTDISP	
intspec focal(c.ed) main((c.ed, name(Education) range(0(5)20)) ///
 (i.racew, name(Race) range(0/1)) (c.contact, name(RacialContact) range(0/3))) ///
 int2(c.ed#i.racew c.ed#c.contact i.racew#c.contact) int3(c.ed#i.racew#c.contact) ndig(0)

*** Figure 8.8 Plain
outdisp, out(atopt((means) _all)) plot(def) pltopts(ylab(0(.3).9))

*** Figure 8.10 Superimposed main effects
outdisp, outcome(main(lgtmain) atopt((means) _all)) plot(def) pltopts(ylab(0(.3).9))


**** Focal = RACE, MOD1 = CONTACT, MOD2 = CONTACT ************************************
***
*** Rerun logit so order of 2way & 3way terms match focal-by-mod1-by-mod2
logit ban i.racew c.contact c.ed age region16 class
est store lgtmain

logit ban i.racew##c.contact##c.ed age region16 class
est store lgtint

*** SIGREG Table 8.15
intspec focal(i.racew) main((i.racew, name(Race) range(0/1)) ///
 (c.contact, name(RacialContact) range(0/3)) (c.ed, name(Education) range(0(2)20))) ///
 int2(i.racew#c.contact i.racew#c.ed c.contact#c.ed) int3(i.racew#c.contact#c.ed) ndig(0)
	
sigreg, effect(spost(amtopt(am(one)) atopt((means) _all))) /// 
	save(Output/Table_8_15.xlsx tab mat) ndig(3) 
