** CH 9  Multinomial Logit Model  One Moderator
**      Education-by-Religious attendance
		
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

**  Estimate and Store Interaction Effect model Base=Moderate in mlgt3rd
mlogit polviews3 c.educ##c.attendmonth age  class female i.race, base(2)
est store mlgt3rd

**  Estimate and Store Interaction Effect model Base=Liberal in mlgtint
mlogit polviews3 c.educ##c.attendmonth age  class female i.race, base(1)
est store mlgtint



************** GFI ************************************************************************
***
****  FOCAL = educ   ***************************************

intspec focal(c.educ) main((c.educ, name(Education) range(0(4)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4))) int2(c.educ#c.attendmonth) ndig(0)  

gfi , ndig(4) 

*** 3rd contrast Con:Mod
est restore mlgt3rd
intspec focal(c.educ) main((c.educ, name(Education) range(0(4)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4))) int2(c.educ#c.attendmonth) ndig(0)  eqname(Conservative)
gfi , ndig(4) 

****
****  FOCAL = attend

est restore mlgtint
intspec focal(c.attendmonth) main((c.educ, name(Education) range(0(4)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4))) int2(c.attendmonth#c.educ) ndig(0)  

gfi , ndig(4) 

*** 3rd contrast Con:Mod
est restore mlgt3rd
intspec focal(c.attendmonth) main((c.educ, name(Education) range(0(1)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4))) int2(c.attendmonth#c.educ) ndig(0)  eqname(Conservative)
gfi , ndig(4) 


************** FACTOR CHANGE   SIGREG ***************************************
****
****  FOCAL = educ
est restore mlgtint

intspec focal(c.educ) main((c.educ, name(Education) range(0(4)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4))) int2(c.educ#c.attendmonth) ndig(0)  

sigreg , effect(factor(sd)) save(Output/Table_9_2.xlsx tab) ndig(3) 

*** 3rd contrast Con:Mod
est restore mlgt3rd

intspec focal(c.educ) main((c.educ, name(Education) range(0(4)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4))) int2(c.educ#c.attendmonth) ndig(0)  eqname(Conservative)

sigreg , effect(factor(sd)) save(Output/Table_9_2B.xlsx tab) ndig(3) 


************** DISCRETE CHANGE    SIGREG*************************************
****
****  FOCAL = attend

mlogit polviews3 c.attendmonth##c.educ age  class female i.race, base(1)
est store mlgtint

intspec focal(c.attendmonth) main((c.attendmonth, name(Attend) range(0(1)4))(  /// 
	c.educ, name(Education) range(0(4)20))) int2(c.attendmonth#c.educ) ndig(0)  

sigreg , effect(spost(amtopt(am(sd) center) atopt((means) _all))) ///
  nobva save(Output/Table_9_3 tab)


 *** list bases for sigreg table
 forvalues ee=0(4)20 {
  qui  mchange attendmonth , am(sd) center at((means) _all educ=`ee' ) 
  mat list r(basepred), title("Educ = `ee'")
  }
*

*** Discrete change effects from a main effect model
qui mlogit polviews3 c.attendmonth  c.educ age  class female i.race, base(1)
mat tabdc=J(3,6,.)
mat rownames tabdc = `e(eqnames)'
mat colnames tabdc =  0 4 8 12 16 20
loc cc=0
 forvalues aa=0(4)20 {
  loc ++ cc
  qui  mchange attendmonth , am(sd) center at((means) _all educ =`aa' ) 
  mat hh=  r(table)
  forvalues j=1/3 {
  mat tabdc[`j',`cc'] =hh[1,`j']
  }
  }
mat list tabdc ,  form(%8.4f)


*** sensitivity of discrete change effects to choice of substantively interesting cases
est restore mlgtint

sigreg , effect(spost(amtopt(am(sd) center) atopt((means) _all race=1 female=0))) nobva 
sigreg , effect(spost(amtopt(am(sd) center) atopt((means) _all race=1 female=1))) nobva 
sigreg , effect(spost(amtopt(am(sd) center) atopt((means) _all race=2 female=0))) nobva 
sigreg , effect(spost(amtopt(am(sd) center) atopt((means) _all race=2 female=1))) nobva 
sigreg , effect(spost(amtopt(am(sd) center) atopt((means) _all race=3 female=0))) nobva 
sigreg , effect(spost(amtopt(am(sd) center) atopt((means) _all race=3 female=1))) nobva 



************** PRED PROB TABLES & PLOTS  ***************************************
****
****  FOCAL = educ
mlogit polviews3  c.educ c.attendmonth age  class female i.race, base(1)
est store mlgtmain
mlogit polviews3 c.educ##c.attendmonth age  class female i.race, base(1)
est store mlgtint

****  FIgure 9.1 
intspec focal(c.educ) main((c.educ, name(Education) range(0(5)20))  /// 
	(c.attendmonth, name(Attend) range(0(2)4))) int2(c.educ#c.attendmonth) ndig(0)  

outdisp , out( main(mlgtmain) atopt((means) _all)) plot(name(PolEd) ) /// 
	pltopts(ylab(0(.2).8))

	
****  FOCAL = attend
***
*** TABLE 9.5 uses different display  values then following Figure***
intspec focal(c.attendmonth) main((c.educ, name(Education) range(0(5)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4 4.33))) int2(c.educ#c.attendmonth) ndig(1)  

outdisp , out( metric(obs) atopt((means) _all)) ndig(3) tab(save(Output/Table_9_5.xlsx)) 

*** Figure 9.2
intspec focal(c.attendmonth) main((c.educ, name(Education) range(4(8)20))  /// 
	(c.attendmonth, name(Attend) range(0(2)4))) int2(c.educ#c.attendmonth) ndig(0)  

outdisp , out( main(mlgtmain) atopt((means) _all)) plot(name(PolAttend) ) /// 
	pltopts(ylab(0(.2).8))


*** sensitivity to asobs and substantively interesting cases
intspec focal(c.educ) main((c.educ, name(Education) range(0(4)20))  /// 
	(c.attendmonth, name(Attend) range(0(1)4 4.33))) int2(c.educ#c.attendmonth) ndig(1)  
outdisp , out( metric(obs) atopt((asobs) _all)) 

outdisp , out( metric(obs) atopt((means) _all race=1 female=0)) 
outdisp , out( metric(obs) atopt((means) _all race=1 female=1)) 
outdisp , out( metric(obs) atopt((means) _all race=2 female=0)) 
outdisp , out( metric(obs) atopt((means) _all race=2 female=1)) 
outdisp , out( metric(obs) atopt((means) _all race=3 female=0)) 
outdisp , out( metric(obs) atopt((means) _all race=3 female=1)) 




************** PRED LN ODDS/STANDARDIZED LATENT VARIABLE TABLES & PLOTS  ***************************************

*** Figure 9.3
est restore mlgtint
intspec focal(c.educ) main((c.educ, name(Education) range(0(5)20))  /// 
	(c.attendmonth, name(Attend) range(0(2)4))) int2(c.educ#c.attendmonth) ndig(0)  

outdisp , out(  metric(model) sdy atopt((means) _all)) plot(name(PolEd_SDY))  ///
 pltopts(ylab(-1(.5)1 ) ytit( , size(*.8)) tit( , size(*.8))  leg(cols(1)))

** Also for Figure 9.3
 
est restore mlgt3rd
intspec focal(c.educ) main((c.educ, name(Education) range(0(5)20))  /// 
	(c.attendmonth, name(Attend) range(0(2)4))) int2(c.educ#c.attendmonth) ndig(0)  eqname(Conservative)

outdisp , out(  metric(model) sdy atopt((means) _all)) plot(name(PolEd_SDY3rd))  /// 
 pltopts(ylab(-1(.5)1 ) ytit( , size(*.8)) tit( , size(*.8))  leg(cols(1)))
   

****
****  FOCAL = attend  Rerun models to reorder focal##moderator
mlogit polviews3 c.attendmonth##c.educ age  class female i.race, base(2)
est store mlgt3rd

mlogit polviews3 c.attendmonth##c.educ age  class female i.race, base(1)
est store mlgtint

** Figure 9.4
intspec focal(c.attendmonth) main((c.attendmonth, name(Attend) range(0(1)4))(  /// 
	c.educ, name(Education) range(0(10)20))) int2(c.attendmonth#c.educ) ndig(0)  

outdisp , out(  metric(model) sdy atopt((means) _all))  plot(name(PolAtt_SDY)) ///
 pltopts(ylab(-1(.5)1) ytit( , size(*.8)) tit( , size(*.8))  leg(cols(1)))

 ** Also for Figure 9.4
est restore mlgt3rd
intspec focal(c.attendmonth) main((c.attendmonth, name(Attend) range(0(1)4))(  /// 
	c.educ, name(Education) range(0(10)20))) int2(c.attendmonth#c.educ) ndig(0)  eqname(Conservative)

outdisp , out(  metric(model) sdy atopt((means) _all))  plot(name(PolAtt_SDY3rd)) ///
 pltopts(ylab(-1(.5)1) ytit( , size(*.8)) tit( , size(*.8))  leg(cols(1)))
