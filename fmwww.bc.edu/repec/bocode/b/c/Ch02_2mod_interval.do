**  CH 2 Logit Example with 2 moderators both interval
**      faminc10k-by-age faminc10k-by-education
		
version 14.2
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_2010.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_1987.dta, clear  

**   Make folder named "Output" to store saved figures or Excel files 
**	 in current directory if does not already exist
mata: st_numscalar("dout", dirout=direxists("Output")) 
if dout==0 mkdir Output



reg childs c.faminc10k##c.age c.faminc10k##c.educ sibs i.race religintens  if age>39

**  interaction specification for GFI and Figures 2_5 and 2_6

intspec  focal(c.faminc10k)  /// 
	main((c.faminc10k , name(Family_Inc) range(0(2)24)) /// 
		(c.age , name(Age) range(39(10)89)) ///
		(c.educ , name(Education) range(0(4)20)) ) ///
	int2(c.faminc10k#c.age c.faminc10k#c.educ ) ndig(0) 
gfi

** Save plot data to excel for 3-D Surface plot in Excel, Create Figure 2_6 contour plot
effdisp , plot(type(contour) freq(subtot) save(Output\Fig_2_5_data.xlsx)) pltopts(xsc(reverse))
