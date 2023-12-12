**  CH 4 WLS Example with 1 moderator
**      age-by-ses
		
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



reg sexfrqmonth c.age##c.ses female nevermarr childs attendmonth /// 
	if age > 24 [aweight = hetwgt]

*** Table 4.1
intspec focal(c.ses) main( (c.age, name(Age) range(25(7)88)) /// 
	(c.ses, name(SES) range(17(10)97))) int2(c.age#c.ses) ndig(0) dvname("Intimacy Frequency") sumwgt(no) abbrevn(18) 

outdisp, out(atopt((means) _all))  tab(save(Output\Table_4_1.xlsx) rowvar(mod))  ndig(2) 

_pctile ses if e(sample), n(10)
global sesdecile ""
forvalues i=1/9 {
	global sesdecile "$sesdecile `=round(`r(r`i')',.1)'" 
	}
disp $sesdecile
_pctile age if e(sample), n(10)
global agedecile "`r(r1)' `r(r2)' `r(r3)' `r(r4)' `r(r5)' `r(r6)' `r(r7)' `r(r8)' `r(r9)'"

*** Table 4.2
intspec focal(c.ses) main( (c.age, name(Age) range($agedecile)) /// 
	(c.ses, name(SES) range($sesdecile))) int2(c.age#c.ses) ndig(0) dvname("Intimacy Frequency") sumwgt(no) abbrevn(18) 

outdisp, out(atopt((means) _all))  tab(save(Output\Table_4_2.xlsx) rowvar(mod))  ndig(2) 


***  Figures Example 3

*** Figure 4.4 & 4.5 Scatter
intspec focal(c.ses) main( (c.age, name(Age) range(25(16)89)) /// 
	(c.ses, name(SES) range(17(20)97))) int2(c.age#c.ses) ndig(0) dvname("Intimacy Frequency") sumwgt(no) abbrevn(18) 

outdisp, out(atopt((means) _all)) plot(type(scat)) 

intspec focal(c.age) main( (c.age, name(Age) range(25(16)89)) /// 
	(c.ses, name(SES) range(17(20)97))) int2(c.age#c.ses) ndig(0) dvname("Intimacy Frequency") sumwgt(no) abbrevn(18) 

outdisp, outcome(atopt((means) _all)) plot(type(scat) ) ndig(2) 


*** Figure 4.6  Contour
intspec focal(c.ses) main( (c.age, name(Age) range(25(16)89)) /// 
	(c.ses, name(SES) range(17(20)97))) int2(c.age#c.ses) ndig(0) ///
	dvname("Intimacy Frequency") sumwgt(no) abbrevn(18) 

outdisp, out(atopt((means) _all)) plot(type(contour)  /// 
	save(Output\Fig_4_7.xlsx)) ndig(1) pltopts( ccuts(-3(1.5)9) ///
	zlab(-3(1.5)9) cleg( tit( , size(*.625))))  
