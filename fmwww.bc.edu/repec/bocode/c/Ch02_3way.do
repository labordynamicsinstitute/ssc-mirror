**  CH 2 OLS Example with 3-way interaction
**      sex-by-education-by-age
		
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



reg memnum i.sex##c.ed##c.age size class if out3 !=1

***  interaction specification for Table 2.2 and GFI
intspec focal(i.sex)  main( (c.ed , name(Education) range(0(2)20)) /// 
	(c.age , name(Age) range(18(10)88)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.ed#i.sex  c.age#i.sex c.age#c.ed ) int3(i.sex#c.ed#c.age ) ///
	dvname(Memberships) abbrevn(13) ndig(0)

gfi,  ndig(3)  


*** ***  interaction specification for Fig (2.7 data) 2.8 , 2.9 , age as 1st moderator
reg memnum i.sex##c.age##c.ed size class if out3 !=1

intspec focal(i.sex)  main( (c.age , name(Age) range(18(10)88)) /// 
	(c.ed , name(Education) range(0(4)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2( i.sex#c.age i.sex#c.ed c.age#c.ed ) int3(i.sex#c.age#c.ed ) ndig(0)

effdisp , plot(type(contour) save(Output/Fig_2_7_data.xlsx) freq(subtot)) pltopts(ccuts(-2.2(.5)1.3)) ndig(1)

*** Fig 2.9 
effdisp , plot(type(line) freq(subtot)) ndig(1)

*** interaction specification for Fig 2.10   Treat Ed as 1st moderator
reg memnum i.sex##c.ed##c.age size class if out3 !=1

intspec focal(i.sex)  main( (c.ed , name(Education) range(0(4)20))  /// 
	(c.age , name(Age) range(18(23)87)) (i.sex , name(Sex) range(0/1))) ///   
	int2(i.sex#c.ed  i.sex#c.age c.age#c.ed ) int3(i.sex#c.ed#c.age ) ndig(0)
effdisp , plot(type(line) freq(subtot)) ndig(1)
