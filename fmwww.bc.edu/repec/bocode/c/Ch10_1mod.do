** CH 10 Ordered Model  One Moderator
**      Education-by-Sex 
		
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

**  Estimate and Store Main Effect model in mainmoded
qui ologit chemfree2 c.educ i.female ib3.race age i.polviews3 size 
qui est store mainmoded

**  Estimate and Store Interaction Effect model in intmoded
qui ologit chemfree2 c.educ##i.female ib3.race age i.polviews3 size 
qui est store intmoded


**** FOCAL: Education
intspec focal(c.educ) main((c.educ, name(Education) range(0(4)20)) /// 
  (i.female, name(Sex) range(0/1))) ndig(0) int2(c.educ#i.female)


***  GFI 
gfi, factor


*** SIGREG 

**  Standardized change in latent outcome
sigreg , effect(b(sdyx))

** Factor change in Odds (Odds ratio)
sigreg , effect(factor(sd))

** Discrete change in prob of categories
sigreg, effect(spost(amtopt(am(sd) center) atopt((means) _all)))


***  EFFDISP  Figure 10.1 
effdisp , effect(b(sdyx)) pltopts(tit(, size(*.8))) ndig(2)


***  OUTDISP Figures 10.3-10.5
intspec focal(c.educ) main( (c.educ,  name(Education) range(0(4)20)) /// 
  (i.female, name( Sex)  range(0/1))) ndig(0)  int2(c.educ#i.female)

**  Table 10.1 & Figure 10.3  Predicted Standardized Latent Outcome
outdisp , plot(name(Latent)) tab(save(Output/table_10_1.xlsx) abs)  /// 
   out(sdy metric(model) atopt((means) _all)) 
   
**  Table 10.2 & Figure 10.4  Predicted Category Probabilities
outdisp , plot(name(PredProb)) tab(save(Output/table_10_2.xlsx)) /// 
   out(atopt((means) _all) metric(obs)) pltopts(ylab(.05(.1).45))

**  Table Figure 10.5  Predicted Category Probabilities, Superimposed Main effect model
outdisp , plot(name(PrHat_Super)) out(atopt((means) _all) main(mainmoded)) ///
   pltopts(ylab(.05(.1).45) tit(  , size(*.85)))
   

**** FOCAL: Sex
***
***  Rerun model to reorder as focal##moderator
qui ologit chemfree2 i.female##c.educ ib3.race age i.polviews3 size 

intspec focal(i.female) main((c.educ, name(Educ) range(0(2)20)) /// 
   (i.female, name(Sex) range(0/1))) ndig(0) int2(i.female#c.educ)
   

***  GFI
gfi, factor


***  SIGREG

**  Standardized change in latent outcome
sigreg , effect(b(sdy)) ndig(2) concise

** Factor change in Odds (Odds ratio)
sigreg , effect(factor(1)) ndig(2)

** Discrete change in prob of categories
sigreg, effect(spost(amtopt(am(bin)) atopt((means) _all))) ndig(3)


***  EFFDISP Figure 10.2
***
***  Change display values for Education
intspec focal(i.female) main( (c.educ,  name(Educ) range(0(4)20)) ///
 (i.female, name( Sex)  range(0/1))) ndig(0) int2(i.female#c.educ)
 
effdisp, effect(spost(amtopt(am(bin)) atopt((means) _all))) ///
   pltopts(ylab( -.39(.13).39,form(%8.2f) labsize(*.75)))


**** Ordered Probit ***************************************************************************************************************

**** FOCAL: Sex   SIGREG 
oprobit chemfree2 i.female##c.educ ib3.race age i.polviews3 size 
intspec focal(i.female) main( (c.educ,  name(Educ) range(0(2)20)) /// 
   (i.female, name( Sex) range(0/1))) ndig(0) int2(i.female#c.educ)
sigreg , effect(b(sdy)) ndig(2) concise

**** FOCAL: Education  OUTDISP Figure 10.6
ologit chemfree2 c.educ##i.female ib3.race age i.polviews3 size 
intspec focal(c.educ) main( (c.educ,  name(Education) range(0(2)20)) /// 
   (i.female, name( Sex)  range(0/1))) ndig(0)  int2(c.educ#i.female)
outdisp , plot(name(PrHat_Lgt)) tab(def) out(atopt((means) _all) metric(obs)) ///
   pltopts(ylab(.05(.1).45) subti(Logit))

oprobit chemfree2 c.educ##i.female ib3.race age i.polviews3 size 
intspec focal(c.educ) main( (c.educ,  name(Education) range(0(2)20)) /// 
   (i.female, name( Sex)  range(0/1))) ndig(0)  int2(c.educ#i.female)
outdisp , plot(name(PrHat_Prbt)) tab(def) out(atopt((means) _all) metric(obs)) ///
    pltopts(ylab(.05(.1).45) subti(Probit))
