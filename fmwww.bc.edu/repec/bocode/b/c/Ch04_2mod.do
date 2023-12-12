**  CH 4 OLS Example with 2 moderators predicting # of children 
**      faminc10k-by-age  faminc10k-by-education
		
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



*** 2 mods, all interval 

*** Get coeffcients  scaled to family income in $10k for Equations 4.7 & 4.8 and elswhere
reg childs c.faminc10k##c.educ  c.faminc10k##c.age sibs i.race religintens  if age>39 

*** Use family income in dollars for labelling tables
reg childs c.faminc##c.educ  c.faminc##c.age sibs i.race religintens  if age>39 

*** Table 4.3
intspec  focal(c.faminc)  /// 
	main((c.faminc , name(Family_Inc) range(500(15000)150500)) ///	
		(c.age , name(Age) range(40(10)80)) /// 
		(c.educ , name(Education) range(5(5)20)))  ///
	int2(c.faminc#c.age c.faminc#c.educ ) ndig(0) 

outdisp , out(atopt((means) _all)) tab(save(Output\Table_4_3.xlsx)) ndig(3)


**  Table 4.4
** Income  by Age separate

intspec  focal(c.faminc)  /// 
	main((c.faminc , name(Family_Inc) range(500(15000)150500)) ///	
		(c.age , name(Age) range(40(10)80))) /// 
	int2(c.faminc#c.age  ) ndig(0) 

outdisp , out(atopt( (means)) _all) tab(row(focal) save(Output\Table_4_4.xlsx) freq(subtot)) ndig(3)

