** CH 9  Multinomial Logit Two Moderators
** 		education-by-sex  education-by-race
		
version 14.2			
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/SIPP_Occ.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use SIPP_Occ.dta, clear  

**   Make folder named "Output" to store saved figures or Excel files 
**	 in current directory if does not already exist
mata: st_numscalar("dout", dirout=direxists("Output")) 
if dout==0 mkdir Output



******* main effect model for each as focal
mlogit currocc  i.sex  educ i.raceth age  i.married , base(4)
est store mainsex

mlogit currocc   i.raceth educ i.sex age  i.married , base(4)
est store mainrace

mlogit currocc  educ i.raceth i.sex age  i.married , base(4)
est store mainedrace
mlogit currocc  educ i.sex i.raceth age  i.married , base(4)
est store mainedsex

***** Interaction model with alternative base outcome categories
qui mlogit currocc  i.sex##c.educ i.raceth##c.educ  c.age i.married , base(2)
est store intsex2

qui mlogit currocc  i.sex##c.educ i.raceth##c.educ  c.age i.married , base(4)
est store intsex


******************** FOCAL = SEX ************************************************************
intspec focal(i.sex) main( (i.sex , name(Sex) range(0/1)) /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(c.educ#i.sex ) ndig(0) 
	
*** GFI
gfi

est restore intsex2
intspec focal(i.sex) main( (i.sex , name(Sex) range(0/1)) /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(c.educ#i.sex ) ndig(0) 
gfi


***  DISCRETE CHANGE   Table 9.6
est restore intsex

intspec focal(i.sex) main( (i.sex , name(Sex) range(0/1)) /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(c.educ#i.sex ) ndig(0) 

sigreg, effect(spost(amtopt(am(binary)) atopt((means) _all))) ///
 nobva ndig(3)  save(Output/Table_9_6.xlsx tab)


*** DC effects from a main effect model
qui mlogit currocc  i.sex  educ i.raceth age  i.married , base(4)
mat tabdc=J(4,7,.)
mat rownames tabdc = `e(eqnames)'
mat colnames tabdc =  0 3 6 9 12 15 18

loc cc=0
 forvalues mm=0(3)18 {
  loc ++ cc
  qui  mchange sex , am(bin) at((means) _all educ=`mm' ) 
  mat hh=  r(table)
  forvalues j=1/4 {
  mat tabdc[`j',`cc'] =hh[1,`j']
  }
  }

mat list tabdc ,  form(%8.3f)


*** Figure 9.5  predicted prob bar cahrt OUTDISP ********
qui est restore intsex
intspec focal(i.sex) main( (i.sex , name(Sex) range(0/1)) /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(i.sex#c.educ ) ndig(0) 
outdisp ,  plot(name(OccSexEdBar)) out(atopt( (means) _all) main(mainsex))  pltopts(ylab(0(.2)1) plotreg(ma(t +2))) ndig(2)


******************** FOCAL = RACETH ************************************************************

mlogit currocc  i.raceth##c.educ c.educ##i.sex c.age i.married , base(2)
est store intrace2

mlogit currocc  i.raceth##c.educ c.educ##i.sex c.age i.married , base(4)
est store intrace


*** GFI  
intspec focal(i.raceth) main( (i.raceth, name(RaceEth) range(1/4))  /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(i.raceth#c.educ ) ndig(0) 
	
gfi, ndig(3) 

est restore intrace2
intspec focal(i.raceth) main( (i.raceth, name(RaceEth) range(1/4))  /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(i.raceth#c.educ ) ndig(0) eqn("upperwc")
gfi, ndig(3) 

***  FACTOR
est restore intrace
intspec focal(i.raceth) main( (i.raceth, name(RaceEth) range(1/4))  /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(i.raceth#c.educ ) ndig(0) 
	
sigreg, effect(factor) ndig(3)  save(Output/Table_9_8.xlsx tab) 

est restore intrace2
intspec focal(i.raceth) main( (i.raceth, name(RaceEth) range(1/4))  /// 
	(c.educ, name(Education) range(0(3)18))) ///
	int2(i.raceth#c.educ ) ndig(0) eqn("upperwc")
	
sigreg, effect(factor)  ndig(3)  save(Output/Table_9_8_2.xlsx tab) 


*** Figure 9.6  
***   get scatterplot of latent outcome by declaring Educ as focal

mlogit currocc  c.educ##( i.sex i.raceth) c.age i.married , base(4)
est store inted
intspec focal(c.educ) main((c.educ, name(Education) range(0(3)18)) /// 
	(i.raceth, name(RaceEth) range(1/4))) 	int2(c.educ#i.raceth) ndig(0)
	
outdisp , plot(name(RaceEdLatent)) out(metric(model) sdy atopt( (means) _all) ) ///
 pltopts(ylab(-4.2(1.4)1.4) ytit( , ma(r +3)) tit( , size(*.7))) 
 
mlogit currocc  c.educ##( i.sex i.raceth) c.age i.married , base(2)
est store inted2
intspec focal(c.educ) main((c.educ, name(Education) range(0(3)18)) /// 
	(i.raceth, name(RaceEth) range(1/4))) 	int2(c.educ#i.raceth) ndig(0) eqn("upperwc")

outdisp ,  plot(name(RaceEdLatent2)) out(metric(model) sdy atopt( (means) _all) )   ///
 pltopts(ylab(-4.2(1.4)1.4) ytit( , ma(r +3)) tit( , size(*.7))) 


******************** FOCAL = EDUC ************************************************************
qui mlogit currocc  c.educ##( i.sex i.raceth) c.age i.married , base(2)
est store inted2

qui mlogit currocc  c.educ##( i.sex i.raceth) c.age i.married , base(4)
est store inted


*** GFI	
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	(i.raceth, name(RaceEth) range(1/4)) (i.sex , name(Sex) range(0/1))) ///
	int2( c.educ#i.raceth c.educ#i.sex) ndig(0) 
gfi, ndig(3)

est restore inted2 
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	(i.raceth, name(RaceEth) range(1/4)) (i.sex , name(Sex) range(0/1))) ///
	int2( c.educ#i.raceth c.educ#i.sex) ndig(0) eqn("upperwc")
gfi, ndig(3)


***  FACTOR 
***
***** By RACE & SEX simultaneously
est restore inted
intspec focal(c.educ) main((c.educ, name(Education) range(0(3)18)) ///
	(i.raceth, name(RaceEth) range(1/4)) (i.sex, name(Sex) range(0/1))) ///
	int2( c.educ#i.raceth c.educ#i.sex) ndig(0)
sigreg, effect(factor) nobva ndig(3) save(Output/Table_9_11.xlsx tab)

est restore inted2 
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	(i.raceth, name(RaceEth) range(1/4)) (i.sex , name(Sex) range(0/1))) ///
	int2( c.educ#i.raceth c.educ#i.sex) ndig(0) eqn("upperwc")
sigreg, effect(factor) nobva ndig(3) save(Output/Table_9_11_2.xlsx tab)


***** BY RACE
est restore inted
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	(i.raceth, name(RaceEth) range(1/4))) ///
	int2( c.educ#i.raceth ) ndig(0)
	
sigreg, effect(factor) nobva ndig(3) save(Output/Table_9_10_1.xlsx tab)

est restore inted2 
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	(i.raceth, name(RaceEth) range(1/4))) ///
	int2( c.educ#i.raceth ) ndig(0) eqn("upperwc")
	
sigreg, effect(factor) nobva ndig(3) save(Output/Table_9_10_2.xlsx tab)

***** BY SEX
est restore inted
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	 (i.sex , name(Sex) range(0/1))) ///
	int2( c.educ#i.sex) ndig(0)
	
sigreg, effect(factor) nobva ndig(3) save(Output/Table_9_10_3.xlsx tab)

est restore inted2 
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	(i.sex , name(Sex) range(0/1))) ///
	int2( c.educ#i.sex) ndig(0) eqn("upperwc")
	
sigreg, effect(factor) nobva ndig(3) save(Output/Table_9_10_4.xlsx tab)


**** Figure 9.7 Stacked area chart of Predicted Probabilities
***
*** USe SPOST to generate predicted probs (including cumulative across occs)
est restore inted
mgen , at((means) _all educ=(0/18) sex=(0/1) raceth=(1/4)) stub(occ)
lab val occsex mf
lab def mf2 0 "M" 1 "W"
lab val occsex mf2
lab val occraceth RE

twoway area occpr1 occeduc , by(occsex occraceth, rows(2)) color(black) xlab(0(6)18) ylab(0(.2)1) ///
	|| rarea  occCpr2  occpr1 occeduc , by(occsex occraceth) color(gs13)  ///
	|| rarea  occCpr3  occCpr2 occeduc , by(occsex occraceth) fcolor(white) lc(gs4) lw(vvthin) ///
	|| rarea  occCpr4  occCpr3 occeduc , by(occsex occraceth)  color(gs9)  ///
	        leg( label(1 "upperwc") lab(2 "lowerwc") label(3 "upperbc") lab(4 "lowerbc"))
 

****  Figure 9.8  Predicted probability Plots
***
*** Make Sex 1st moderator for plots ************************************
est restore inted
intspec focal(c.educ) main( (c.educ, name(Education) range(0(3)18)) ///
	 (i.sex , name(Sex) range(0/1)) (i.raceth, name(RaceEth) range(1/4))) ///
	int2(c.educ#i.sex c.educ#i.raceth) ndig(0)
	
outdisp ,  plot(name(EdRaceSex) save(Output/OccEdRaceSex_Phat.xlsx) single(1)) /// 
  out(main(mainedsex) atopt((means) _all)) pltopts(ylab(0(.2)1))
