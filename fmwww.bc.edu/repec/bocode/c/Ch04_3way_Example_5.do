** CH  4   OLS 3way & Example 5
**     sex-by-age-by-ed 
		
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



reg memnum c.ed##c.age##i.sex size class if out3 !=1

*** Table 4.5 

intspec focal(i.sex)  main((c.age , name(Age) range(18(10)88))  /// 
	 (c.ed , name(Education) range(0(4)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#i.sex  c.ed#i.sex  c.ed#c.age ) int3(c.ed#c.age#i.sex ) ndig(0)

outdisp , out(atopt((means) _all)) tab(row(mod) save(Output/Table_4_5.xlsx)) ndig(3)


*** Figure 4.10  Scatter Focal = education
reg memnum c.ed##i.sex##c.age size class if out3 !=1
intspec focal(c.ed)  main( (c.ed , name(Education) range(0(4)20))  /// 
	(i.sex , name(Sex) range(0/1)) (c.age , name(Age) range(18(14)89)) ) ///   
	int2(c.ed#i.sex c.ed#c.age   i.sex#c.age ) int3(c.ed#i.sex#c.age) /// 
	ndig(0) dvname(Memberships)
outdisp , plot(type(scat)) out(atopt((means) _all)) ndig(2) 


*** Figure 4.11  Scatter Focal = age
reg memnum c.age##i.sex##c.ed size class if out3 !=1
intspec focal(c.age)  main((i.sex , name(Sex) range(0/1)) (c.ed , name(Education) range(0(4)20))  /// 
	 (c.age , name(Age) range(18(14)89)) ) ///   
	int2(i.sex#c.age  c.ed#c.age i.sex#c.ed) int3(c.age#i.sex#c.ed) ///
	ndig(0) dvname(Memberships)

outdisp , plot(type(scat)) out(atopt((means) _all)) ndig(2) 


*** Figure 4.12 Bar chart

reg memnum i.sex##c.age##c.ed size class if out3 !=1

intspec focal(i.sex)  main( (c.ed , name(Education) range(0(4)20)) (c.age , name(Age) range(18(14)88))  /// 
	(i.sex , name(Sex) range(0/1))) ///   
	int2(i.sex#c.ed i.sex#c.age  c.ed#c.age   ) int3(i.sex#c.ed#c.age) /// 
	dvname(Memberships) ndig(0)

outdisp , out(atopt((means) _all)) plot(def) ndig(2) pltopts(plotreg(ma(t +3 b +3)))


*** Figure 4.13  Contour
reg memnum c.age##c.ed##i.sex size class if out3 !=1

intspec focal(c.age)  main( (c.ed , name(Education) range(0(4)20)) (c.age , name(Age) range(18(14)88))  /// 
	(i.sex , name(Sex) range(0/1))) ///   
	int2(i.sex#c.age  c.ed#c.age  i.sex#c.ed  ) int3(c.age#c.ed#i.sex) ///
	dvname(Memberships) ndig(0)


outdisp, plot(type(contour)) out(atopt((means) _all)) pltopts(ccuts(-3(1)4) clegend(tit( , size(2.8)))) ndig(0) 
