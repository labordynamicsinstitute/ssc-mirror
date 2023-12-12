** CH 12 Polynomial Example 
** Race by (Age, Age Squared)
**                   
		
version 14.2
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/GSS_2010.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use GSS_2010.dta, clear  



set scheme s1mono

**  Regression with race interaction with quadratic age in factor notation

reg educ i.race##c.age##c.age i.female pared  if wrkstat != 6
est store factmod

***  Moderated effect of race by quadratic age at selected age values
margins , dydx(race) at(age=(18(18)90) (means) _all)


***  Moderated effect of Age by Race at seleceted age values
margins , dydx(age) at(race=(1/3) age=(20(10)90) (means) _all)


*** Figure 12.1 
margins , at(race=(1/3) age=(20(5)90) (means) _all)

marginsplot , plotd(race)  xdim(age) noci name(AgebyRace, replace)  ///
  plot1opts(ms(i) lp(solid) lc(black) lw(*1.5)) plot2opts(ms(i) lp(dash) /// 
  lc(black) lw(*1.5)) plot3opts(ms(i) lp(longdash) lc(black) lw(*1.5)) xlab(20(10)90)

*** Figure 12.2 
est restore factmod
margins , at(race=(1/3) age=(20(14)90) (means) _all)
marginsplot , byd(age)  xdim(race) plot(race) recast(bar) noci /// 
  name(RacebyAge, replace) plot1opts(fc(black))  plot2opts(fc(gs13)) ///
  plotopts(barwidth(.75) ysc(r(10)) leg( rows(1)))
  
