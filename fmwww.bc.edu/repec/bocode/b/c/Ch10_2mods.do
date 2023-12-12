** CH 10 Ordered Model  Two Moderators
**      Race-by-Education     Race-by-log(income) 
		
version 14.2			
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_2010.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_2010.dta, clear  

**   Make folder named "Output" to store saved figures or Excel files 
**	 in current directory if does not already exist
mata: st_numscalar("dout", dirout=direxists("Output")) 
if dout==0 mkdir Output



** remove educ value labels for simpler labelling of tables, etc. 
lab val educ 

**  Estimate and Store Main Effect models for each predctor as focal
qui {
	ologit class i.race c.educ c.loginc c.sei i.female c.age 
	est store mainrace
	ologit class i.race c.loginc c.educ c.sei i.female c.age 
	est store mainraceinc

**  Estimate and Store Interaction Effect model 
ologit class i.race##c.loginc i.race##c.educ c.sei i.female c.age 
est store intmodraceinc
ologit class i.race##c.educ i.race##c.loginc c.sei i.female c.age 
est store intmodrace
}
*
******* Education Moderated by Race**************************************************
intspec focal(c.educ) main((c.educ, name(Education) range(0(4)20)) ///
   (i.race, range(1/3) name(Race))) int2(c.educ#i.race) ndig(0)

   
***  GFI
gfi, factor


***  SIGREG
sigreg , effect(b(sdyx))


******* ln(Income) Moderated by Race**************************************************
intspec focal(c.loginc) main((i.race, range(1/3) name(Race)) /// 
   (c.loginc, name(Log_Income) range(-3(1)3))) int2(c.loginc#i.race) ndig(0)

***  GFI
gfi, factor


***  SIGREG
sigreg, effect(factor(sd)) 


*** EFFDISP   Figure 10.7
effdisp, effect(factor(sd)) ndig(1) pltopts(ylab(.5(.5)3) ti(,size(*.9)))


******* Race Moderated by Education and by ln(Income)**************************************************
intspec focal(i.race) main((i.race, range(1/3) name(Race)) /// 
   (c.educ,  name(Education) range(0(5)20)) (c.loginc, name(Log_Income) ///
   range(-3(1)3))) int2(i.race#c.educ i.race#c.loginc) ndig(1)

***  GFI   
gfi, factor


** Factor effect SIGREG
sigreg , effect(factor) save(Output/table_10_5.xlsx tab mat)


*** Discrete change effect SIGREG  Table 10.7 & 10.8
** same patterns if use log inc -3(1)3 and educ 0(4)20
intspec focal(i.race) main((i.race, range(1/3) name(Race)) /// 
   (c.educ,  name(Education) range(0(5)20)) (c.loginc, name(Log_Income) /// 
   range(-3(1.5)3))) int2( i.race#c.educ i.race#c.loginc) ndig(1)

sigreg ,effect(spost( amtopt(am(bin)) atopt((means) _all))) ndig(4) /// 
   save(Output/table_10_6.xlsx tab) nobva


*** OUTDISP

*** Table 10.9 latent outcome
intspec focal(i.race) main((i.race, range(1/3) name(Race)) (c.educ, /// 
   name(Education) range(0(5)20)) (c.loginc, name(Log_Income) range(-3(1.5)3))) ///
   int2( i.race#c.educ i.race#c.loginc) ndig(1)
	
outdisp , out(atopt((means) _all) metric(model) sdy)  /// 
   tab(save(Output/Race_2Mods_table_10_9.xlsx) ) ndig(3)


*** Figure 10.8 latent outcome
intspec focal(i.race) main((i.race, range(1/3) name(Race)) (c.educ, ///
   name(Education) range(0(4)20)) (c.loginc, name(Log_Income) range(-3(2)3))) /// 
   int2( i.race#c.educ i.race#c.loginc) ndig(0)
	
outdisp , out(atopt((means) _all) metric(model) sdy) ///
   plot(type(scat) name(EdClass)) pltopts(by( , tit( , size(*.8))) leg( rows(1)))

   
** Figure 10.9 latent outcome 
intspec focal(i.race) main((i.race, range(1/3) name(Race))  ///
	(c.loginc, name(Log_Income) range(-3(2)3)) (c.educ,  name(Education) ///
	range(2(6)20))) int2(  i.race#c.loginc i.race#c.educ) ndig(0)
	
outdisp , out(atopt((means) _all) metric(model) sdy)  plot(type(scat) /// 
   name(IncClass)) pltopts(by( , tit( , size(*.8))) leg( rows(1)))

   
est restore intmodrace
*** Figure 10.10   Superimposed Main ,   Table 10.10
intspec focal(i.race) main((i.race, range(1/3) name(Race)) ///
 (c.educ, name(Education) range(0(4)20)) (c.loginc, name(Income) /// 
 range(-3(2)3))) int2(i.race#c.educ i.race#c.loginc) ndig(0)
 
outdisp , out(atopt((means) _all) main(mainrace)) plot(type(scat) name(RaceEd)) /// 
	tab(save(Output/Table_10_10.xlsx)) ndig(3) pltopts(ylab( , format(%5.2f)))
	

**** INCOME  Figure 10.11  Superimposed Main 
est restore intmodraceinc
intspec focal(i.race) main((i.race, range(1/3) name(Race)) /// 
   (c.loginc, name(Income) range(-3(2)3))  (c.educ, name(Education) ///
   range(0 6.33 12.67 20))) int2(i.race#c.educ i.race#c.loginc) ndig(0)
   
outdisp , out(atopt((means) _all) main(mainraceinc)) plot(type(scat) name(RaceInc)) /// 
   ndig(2) pltopts(ylab( , format(%5.2f)))



****  Special topics.  

*** Testing the equivalence of Factor change interaction effects for categories of nominal moderator

ologit class i.race##c.educ i.race##c.loginc c.sei i.female c.age 

test _b[class:c.loginc]+_b[class:c.loginc#2.race] = _b[class:c.loginc]+_b[class:c.loginc#3.race]
test _b[class:2.race]+_b[class:2.race#c.educ]*12+_b[class:2.race#c.loginc]*1= ///
   _b[class:2.race] +_b[class:2.race#c.educ]*16 +_b[class:2.race#c.loginc]*3 


testnl exp(_b[class:c.loginc]+_b[class:c.loginc#2.race]) =  ///
  exp(_b[class:c.loginc]+_b[class:c.loginc#3.race])

testnl   exp(_b[class:2.race]+_b[class:2.race#c.educ]*12+_b[class:2.race#c.loginc]*1)= ///
   exp(_b[class:2.race] +_b[class:2.race#c.educ]*16 +_b[class:2.race#c.loginc]*3) 
 
 
*** Calculate the Average Standardized Latent Outcome by Race Group
predict ylat if e(sample), xb 
replace ylat = (ylat-4.6378)/2.1522 
tabstat ylat , by(race)
drop ylat

quiet {
	predict ylat if e(sample), xb
	sum ylat, meanonly
	loc latmn = r(mean)
	fitstat
	loc latsd = r(Vystar)^.5
	drop ylat
} 
margins if e(sample), exp((predict(xb)-`latmn')/`latsd') over(race)

