**  CH 3 OLS Example with 3way Interaction
**      sex-by-age-by-education
		
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


reg memnum i.sex##c.age##c.ed size class if out3 !=1
mat list e(b)
mat list e(V)

*** Figure 3.2
intspec focal(i.sex)  main((i.sex , name(Sex) range(0/1)) /// 
	(c.age , name(Age) range(20(10)90))  (c.ed , name(Education) range(0(4)20))) ///   
	int2( c.age#i.sex c.ed#i.sex c.age#c.ed ) int3(i.sex#c.age#c.ed ) ndig(0)

sigreg, plot(female) pltopts(xlab(20(10)90) ylab(0(4)20))


*** Table 3.4 
intspec focal(i.sex)  main((c.age , name(Age) range(18(10)88))  /// 
	 (c.ed , name(Education) range(0(2)20)) (i.sex , name(Sex) range(0/1))) ///   
	int2(c.age#i.sex c.ed#i.sex  c.age#c.ed ) int3(i.sex#c.ed#c.age ) ndig(0)

sigreg , nobva save(Output/Table_3_4.xlsx tab) ndig(3)


** Fig 3.7
intspec focal(i.sex)  main( (c.ed , name(Education) range(0(1)20))  /// 
	(c.age , name(Age) range(18(10)88)) (i.sex , name(Sex) range(0/1))) ///   
	int2(i.sex#c.ed  i.sex#c.age c.age#c.ed ) int3(i.sex#c.ed#c.age ) ndig(0)
	
effdisp, plot(freq(subtot) name(Ed)) ndig(1) pltopts(xlab(0(4)20))


** Fig 3.8
intspec focal(i.sex)  main( (c.ed , name(Education) range(0(1)20))  /// 
	(c.age , name(Age) range(18(23)87)) (i.sex , name(Sex) range(0/1))) ///   
	int2(i.sex#c.ed  i.sex#c.age c.age#c.ed ) int3(i.sex#c.ed#c.age ) ndig(0)
effdisp, plot(type(cbound) freq(subtot) )ndig(1) pltopts(xlab(0(4)20))


** Fig 3.9
intspec focal(i.sex)  main( (c.ed , name(Education) range(0(4)20))  /// 
	(c.age , name(Age) range(18(14)88)) (i.sex , name(Sex) range(0/1))) ///   
	int2(i.sex#c.ed  i.sex#c.age c.age#c.ed ) int3(i.sex#c.ed#c.age ) ndig(0)
effdisp, plot(type(contour) freq(subtot)) ndig(1) sigmark pltopts(ccuts(-2.6(.65)1.30) )

