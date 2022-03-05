** CH 11 Count Model  One Moderator
**      SEI-by-WorkFamilyConflict 
		
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

qui {
	**  Estimate and Store Main Effect models
	zinb pmhdays c.sei i.wfconflict3 age educ childs i.female if wrkstat <=4 , inf(age i.female)
	est store mainsei

	zinb pmhdays i.wfconflict3 c.sei age educ childs i.female if wrkstat <=4 , inf(age i.female)
	est store mainwfc
	fitstat , saving(main)

	**  Estimate and Store Interaction Effect models in intmodwec
	zinb pmhdays c.sei##i.wfconflict3 age educ childs i.female /// 
	   if wrkstat <=4 , inf(age i.female)
	est store intmodsei

	zinb pmhdays i.wfconflict3##c.sei age educ childs i.female /// 
	   if wrkstat <=4 , inf(age i.female)
	est store intmodwfc
}
*
***** wfconflict3 FOCAL **************************************************************************


*** GFI
intspec focal(i.wfconflict3) main((i.wfconflict3, name(WorkVsFam) range(1/3)) ///
  (c.sei, name(OccStatus) range(17(10)97))) ndig(0) int2(i.wfconflict3#c.sei)
gfi, factor ndig(3) 

***SIGREG  Tables 11.1 & 11.2
sigreg, effect(factor) save(Output/Table_11_1.xlsx tab) concise 

*** Revise dispaly values for SEI
intspec  focal(i.wfconflict3) main( (i.wfconflict3, name(WorkVsFam) range(1/3)) ///
  (c.sei, name(OccStatus) range(meanpm2))) ndig(0) int2(i.wfconflict3#c.sei)
  
sigreg, effect(factor) save(Output/sigreg_ex1_conflict_Table_11_2.xlsx tab) concise 


***  EFFDISP

***  confidence bounds, Figure 11.1
effdisp , effect(factor) ndig(0) 

***  line plot, Figure 11.2
effdisp , plot(type(line)) effect(factor) ndig(0) sigmark
graph export Output/Figure_11_2.png, replace



***** SEI FOCAL *********************************************************************************
est restore intmodsei
intspec  focal(c.sei) main( (c.sei , name(OccStatus) range(17(10)97)) ///
   (i.wfconflict3, name(WorkVsFam) range(1/3))) ndig(0) int2(c.sei#i.wfconflict3)
   
***  GFI
gfi, factor ndig(4) 

***SIGREG  
sigreg, effect(spost(amtopt(am(one) center) atopt((means) _all))) nobva  

sigreg, effect(spost(amtopt(am(sd) center) atopt((means) _all))) nobva ndig(2)


***  EFFDISP  Fig 11.3
effdisp, effect(spost( amtopt(am(sd) center)) atopt((means) _all)) ndig(0) ///
   pltopts(ylab(-3.75 " ", add custom notick)) 


***  OUTDISP 
intspec focal(c.sei) main((c.sei , name(OccStatus) range(17(16)97)) ///
  (i.wfconflict3, name(WorkVsFam) range(1/3))) ndig(0) int2(c.sei#i.wfconflict3)

**   Table 11.3 	&  Figure 11.4  Predicted Count
outdisp, tab(save(Output/table11_3.xlsx)) plot(name(obs)) out(atopt((means) _all)) ndig(1) 

**  Figure 11.5		Predicted Count, Main effect predictions superimposed
outdisp, out(main(mainsei) model(obs) atopt((means) _all)) plot(name(obsMain)) ///
   ndig(2) tab(def) pltopts(tit( , size(*.8)))

**  Figure 11.6		Predicted log Count , dual axes
outdisp, out(metric(model) dual atopt( (means) _all)) plot(name(metricDual)) ndig(2) ///
  tab(def) pltopts(ti( , size(*.85))) 
  

intspec  focal(c.sei) main( (c.sei ,  name(OccStatus) range(meanpm2))  (i.wfconflict3,  name(WorkVsFam)  range(1/3))) ndig(0) int2(c.sei#i.wfconflict3)
outdisp, tab(def)


*** Predicted prob interpretaton ************************************************************

zinb pmhdays i.wfconflict3##c.sei c.age educ childs i.female if wrkstat <=4 , ///
  inf(c.age##i.female) 

mtable , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans atvars(wfconflict3 ///
   sei) predict(pr) clear norownumbers wide
mtable , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans atvars(_none) /// 
   pr(0/9) right norownumbers wide

mgen , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans stub(ZZ) pr(0/9) noci replace
mgen , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans stub(ZZaz) predict(pr) noci replace
gen ZZpr0 = ZZprany0 -ZZazprall0

lab val ZZwfconflict3 often
forvalues i=0/9 {
	lab var ZZpr`i' "Pr(y=`i')"
}
lab var ZZsei "SES"

*** Figure 11.14
scatter  ZZpr1 ZZpr2 ZZpr3 ZZpr4 ZZpr5  ZZsei , by(ZZwfconflict3, cols(3)) /// 
   scheme(s1mono)  conn(l l l l l) name(PrSES, replace) /// 
	yaxis(1) ylab(0(.04).12, axis(1)) ysc(r(.17)  axis(1)) /// 
	aspect(1.5) ysize(5.75) xsize(6.5) leg( symy(*.7) symx(*.7) size(*.7)) ///
	|| scatter ZZpr0 ZZsei , conn(l) by(ZZwfconflict3) yaxis(2) ///
	ylab(.05(.1).25, axis(2)) ysc(r(-.72) axis(2)) 


*** Main Effects for comparison

zinb pmhdays i.wfconflict3 c.sei c.age educ childs i.female if wrkstat <=4 , /// 
  inf(c.age##i.female) 

mtable , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans atvars(wfconflict3 sei) //// 
   predict(pr) clear norownumbers wide
mtable , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans atvars(_none) pr(0/9) ///
   right norownumbers wide

mgen , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans stub(ZZmn) pr(0/9) noci replace
mgen , at(wfconflict3=(1/3) sei=(17(20)97)) atmeans stub(ZZmnaz) predict(pr) noci replace
gen ZZmnpr0 = ZZmnprany0 -ZZmnazprall0

lab val ZZmnwfconflict3 often
forvalues i=0/9 {
	lab var ZZmnpr`i' "Pr(y=`i')"
}
lab var ZZmnsei "SES"

scatter  ZZmnpr1 ZZmnpr2 ZZmnpr3 ZZmnpr4 ZZmnpr5  ZZmnsei , by(ZZmnwfconflict3, cols(3)) ///
   scheme(s1mono)  conn(l l l l l) name(PrSES, replace) /// 
   yaxis(1) ylab(0(.04).12, axis(1)) ysc(r(.17)  axis(1)) aspect(1.5) /// 
   ysize(5.75) xsize(6.5) leg( symy(*.7) symx(*.7) size(*.7)) ///
   || scatter ZZmnpr0 ZZmnsei , conn(l) by(ZZmnwfconflict3) yaxis(2) /// 
   ylab(.05(.1).25, axis(2)) ysc(r(-.72) axis(2)) 
graph export Output/Figure_11_15.png, replace

**** Interaction in the inflation model component **********************************************

zinb pmhdays i.wfconflict3##c.sei c.age educ childs i.female if wrkstat <=4 , ///
   inf(c.age##i.female) 

intspec  focal(c.age) main( (c.age , name(Age) range(18(14)88)) ///
 (i.female, name(Sex) range(0/1))) ndig(0) int2(c.age#i.female) eqname(inflate)
gfi, factor ndig(4)
