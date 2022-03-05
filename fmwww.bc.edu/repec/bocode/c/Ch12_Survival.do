***CH 12 Cox model example
***  Age-by-treatment_site predicting time to addiction relapse
		
version 14.2

**  Save path of initial working directory. Used to find file legendonly.grec 
glob initpwd "`c(pwd)'"


**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/UIS.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use UIS.dta, clear  


******************************************************************************
**   Dataset was defined as survival data before it was saved using stset   **
**                                                                          **
**       stset time, failure(censor)                                        **
**                                                                          **
******************************************************************************

***  Run cox model
stcox age ndrugtx i.treat i.site c.age#i.site, nohr

****  Age =  FOCAL 
intspec focal(c.age) main( (c.age, name(Age) range(20(9)56)) (i.site, /// 
	name(Site) range(0/1))) int2( c.age#i.site)  ndig(0)

***   GFI	
gfi, factor 


***  SIGREG
sigreg , effect(factor(5)) 

*** OUTDISP  Figure 12.6
outdisp , tab(def) plot(def) 

**** Site =  FOCAL 
intspec focal(i.site) main((c.age, name(Age) range(20(9)56)) /// 
	(i.site, name(Site) range(0/1))) int2(c.age#i.site)  ndig(0)

***   GFI	
gfi, factor


***  EFFDISP   FIgure 12.5
effdisp, ndig(1) effect(factor) plot(name(effsite))


***  OUTDISP   Figure 12.7 
outdisp , tab(def) plot(def) ndig(3) /// 
	pltopts(tit("Relapse  Hazard Rate (_t) by Interaction of Site by Age")  /// 
	plotreg(ma(t+3)))

***  Stata code to produce survival curves, Figures 12.8 & 12.9
qui {
findfile legendonly.grec , path(`"PERSONAL;PLUS;"$INITPWD""')
loc filegrec "`r(fn)'"
forvalues j=1/2 {
	loc num1 =`j'
	loc num2 = `num1' +1 - (`j'-1)*2
	loc v`num1'name "age"
	numlist "20(9)56"
	loc v`num1'num "`r(numlist)'"
	loc v`num1'n: list sizeof v`num1'num
	loc v`num2'name "site"
	numlist "0/1"
	loc v`num2'num "`r(numlist)'"
	loc v`num2'n: list sizeof v`num2'num

	margins , at(`v1name'=(`v1num') `v2name'=(`v2num'))

	loc grname ""
	loc ii=0
	foreach v2 of numlist `v2num' {
		loc atlist ""
		loc i=0
		loc legtxt ""
		loc ++ii
		
		foreach v1 of numlist `v1num' {
			loc ++i
			loc atlist "`atlist' at`i'(`v1name'=`v1' `v2name'=`v2')"
			loc legtxt "`legtxt' label(`i' "(`v1name'=`v1')") "
		}
		stcurve, survival  `atlist' name(`v2name'`v2', replace) ylab(0(.2)1) leg( symx(*.8) textw(*.8)) /// 
			title("Survival Curve by `v1name', `v2name' =`v2'", size(*.8)) leg(off) scheme(s1mono) ///
			lp(solid longdash shortdash dash "_--" "__-" "_._."  "..--__") ytit( ,ma(r+2))
			loc grname "`grname' `v2name'`v2'"
			if `ii' == `v2n'{
				stcurve, survival  `atlist' name(holdleg, replace)   /// 
				scheme(s1mono) leg( `legtxt' col(1) ring(0) pos(0) ) lp(solid longdash shortdash dash "_--" "__-" "_._."  "..--__")
			graph play "`filegrec'"
			loc grname "`grname' holdleg"
			}	
	}
	noi graph combine `grname', name(Surv`v2name', replace) scheme(s1mono)
	graph drop `grname'
	}
}

