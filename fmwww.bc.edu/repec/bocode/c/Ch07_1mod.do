** CH 7  WLS Model One Moderator
**      SES-by-AGE
		
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



**  Estimate and Store Interaction Effect model  

reg sexfrqmonth c.age##c.ses i.female i.nevermarr childs attendmonth /// 
	if age > 24 [aweight = hetwgt]
est store intmod


*****  AGE FOCAL *****************************************************************************

*** GFI
intspec focal(c.age) main((c.age, name(Age) range(25(10)85)) /// 
	(c.ses, name(SES) range(17(10)97))) int2(c.age#c.ses) sumwgt(no)
gfi , ndig(4)


*** SIGREG  
sigreg , ndig(3) save(Output/testSR.xlsx tab)

intspec focal(c.age) main( (c.age, name(Age) range(25(10)85)) /// 
         (c.ses, name(SES) range(17(20)97))) int2(c.age#c.ses) ndig(0)
sigreg , ndig(3)  effect(b(10))


*** EFFDISP   Figure 7.1
intspec focal(c.age) main((c.age, name(Age) range(25(10)85)) /// 
	(c.ses, name(SES) range(17(10)97))) int2(c.age#c.ses) sumwgt(no)

effdisp , effect(b(10)) plot(name(Age_by_SES_by_frq) freq(tot)) ndig(1)


*** OUTDISP   Figure 7.2
intspec focal(c.age) main( (c.age, name(Age) range(25(10)85)) /// 
	(c.ses, name(SES) range(20(25)95))) int2(c.age#c.ses) ndig(0) sumwgt(no)

outdisp, out(atopt((means) _all)) plot(name(SexFrq_by_Age_by_SES)) table(default) 



*****  SES FOCAL *****************************************************************************

*** GFI
intspec focal(c.ses) main((c.age, name(Age) range(25(10)85)) /// 
	(c.ses, name(SES) range(17(10)97))) int2(c.age#c.ses) ndig(0) sumwgt(no)

gfi ,  ndig(4) 


*** SIGREG
sigreg , ndig(3)  

*** Table 7.2
sigreg , ndig(3)  effect(b(sd)) save(Output/Table_7_2.xlsx table)


*** EFFDISP    Figure 7.3
effdisp, plot(name(SES_by_Age) freq(tot)) ndig(2)


*** OUDISP    Figure 7.4
intspec focal(c.ses) main( (c.age, name(Age) range(26(11)81)) /// 
	(c.ses, name(SES) range(17(20)97))) int2(c.age#c.ses) ndig(0) sumwgt(no)

outdisp, outcome(atopt((means) _all)) plot(name(SexFrq_by_SES_by_Age) ) /// 
	table(save(Output/Table_7_3.xlsx)) 
	
