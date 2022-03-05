***CH 12 Heckman example 
***  Age-by-education predicting Home Equity with Selection on Home ownsership
		
version 14.2
**  Load data from web location
use http://www.icalcrlk.com/icalc_dta/AHS.dta, clear

** OR: Set current directory to folder where you downloaded example datasets
**     then read in data from that current directory
*			cd "c:/ICALC_Examples/Data"
*			use AHS.dta, clear  



*** Run Heckman model 
heckman equity1k i.hhraceth c.hhage##c.hheduc hhincome i.region cc anywork  numchild ///
     i.marital intermar , sel(owner= c.hheduc c.pcfborn c.pcnhblk) vce(cluster fipscode)
est store heck
sca rho1=e(rho)
sca sige=e(sigma)

*****  Truncated home equity  ********************************************
***
*** SIGREG-type Discrete change in HHEDUC , centered
mat dctrun=J(2,7,.)

margins if owner==1 & e(sample), expression( ///
	((predict(xb) + (_b[equity1k:hheduc] + _b[equity1k:c.hhage#c.hheduc]*hhage)*(.5))+ rho1*sige* normalden(predict(xbsel) /// 
		+ (_b[owner:hheduc]*(.5)))/normal(predict(xbsel)+ (_b[owner:hheduc]*(.5)))) - ///
	((predict(xb) + (_b[equity1k:hheduc] + _b[equity1k:c.hhage#c.hheduc]*hhage)*(-.5))+ rho1*sige* normalden(predict(xbsel) /// 
		+ (_b[owner:hheduc]*(-.5)))/normal(predict(xbsel)+ (_b[owner:hheduc]*(-.5))))) ///
	at( hhage=(25(10)85) (means) _all) noatlegend
mat gg =r(table)
mat dctrun[1,1] = [gg[1,1..7] \ gg[4,1..7]]

mat rownames dctrun = b_ed p 
mat colnames dctrun = age:25 35 45 55 65 75 85

matlist dctrun, format(%8.3f) lines(one) nohead tit("Significance Region Table for Effect of hheduc")


*** Predicted value plot   ***TRUNCATED  Fig 12.3

margins if owner==1 & e(sample), expression(predict(xb)+ rho1*sige* ///
 normalden(predict(xbsel))/normal(predict(xbsel))) at(hheduc=(0(5)20) ///
 hhage=(25(15)85) (means) _all) noatlegend

***  Truncated predicted value plot 
marginsplot , xdim(hheduc) plotd(hhage) noci  plotopts( ///
	subtit("Panel A. Truncated with Interaction") leg(colfirst) /// 
	ytit("Equity $1000 Truncated") ylab(0(50)250)) plot1opts(ms(i) ///
	lp(solid) lc(black) lw(*1.5)) plot2opts(ms(i) lp(dash) lc(black) lw(*1.5)) ///
	plot3opts(ms(i) lp(longdash) lc(black) lw(*1.5)) plot4opts(ms(i) /// 
	lp(shortdash) lc(black) lw(*1.5)) plot5opts(ms(i) lp("_-") lc(black) ///
	lw(*1.5) ) name(trunc, replace)

*** Main effects plot
heckman equity1k i.hhraceth c.hhage c.hheduc hhincome i.region cc anywork  numchild ///
     i.marital intermar , sel(owner= c.hheduc c.pcfborn c.pcnhblk) vce(cluster fipscode)
sca rho2=e(rho)
sca sige2=e(sigma)

margins if owner==1 & e(sample), expression(predict(xb)+ rho2*sige2* normalden(predict(xbsel))/normal(predict(xbsel)))    at(hheduc=(0(5)20) hhage=(25(15)85) (means) _all) noatlegend

marginsplot , xdim(hheduc) plotd(hhage) noci  ///
	plotopts(subtit("Panel B. Truncated with No Interaction") leg(colfirst) ///
	ytit("Equity $1000 Truncated") ylab(0(50)250 )) ///
	plot1opts(ms(i) lp(solid) lc(black) lw(*1.5)) plot2opts(ms(i) lp(dash) lc(black) lw(*1.5)) ///
	plot3opts(ms(i) lp(longdash) lc(black) lw(*1.5)) plot4opts(ms(i) lp(shortdash) lc(black) lw(*1.5)) ///
	plot5opts(ms(i) lp("_-") lc(black) lw(*1.5) ) name(truncmain, replace)


*****  CENSORED =0  home equity  ********************************************
***
*** SIGREG-type Discrete change in HHEDUC , centered
est restore heck
mat dccen=J(2,7,.)

margins if e(sample), expression( ///
   normal(predict(xbsel)+_b[owner:hheduc]*(.5) )*((predict(xb) + /// 
     (_b[equity1k:hheduc] + _b[equity1k:c.hhage#c.hheduc]*hhage)*(.5))+ /// 
     rho1*sige* normalden(predict(xbsel) + (_b[owner:hheduc]*(.5)))/  ///
	 normal(predict(xbsel)+ (_b[owner:hheduc]*(.5)))) - ///
   normal(predict(xbsel)+_b[owner:hheduc]*(-.5) )*((predict(xb) + /// 
     (_b[equity1k:hheduc] + _b[equity1k:c.hhage#c.hheduc]*hhage)*(-.5))+ /// 
	 rho1*sige* normalden(predict(xbsel) + (_b[owner:hheduc]*(-.5)))/ ///
	 normal(predict(xbsel)+ (_b[owner:hheduc]*(-.5))))) ///
   at( hhage=(25(10)85) (means) _all) noatlegend
mat gg =r(table)
mat dccen[1,1] = [gg[1,1..7] \ gg[4,1..7]]

mat rownames dccen = b_ed p 
mat colnames dccen = age:25 35 45 55 65 75 85

matlist dccen, format(%8.3f) lines(one) nohead ///
   tit("Significance Region Table for Effect of hheduc")


*** Predicted censored home equity
est restore heck
margins if e(sample), expression( (predict(xb)+ rho1*sige* ///
   normalden(predict(xbsel))/normal(predict(xbsel)))*predict(psel))  ///
   at(hheduc=(0(5)20) hhage=(25(15)85) (means) _all) noatlegend

marginsplot , xdim(hheduc) plotd(hhage) noci  plotopts(subti(Censored) /// 
   leg(colfirst) ytit("Equity $1000 Censored" )  ylab(0(50)250 )) ///
   plot1opts(ms(i) lp(solid) lc(black) lw(*1.5)) plot2opts(ms(i) lp(dash) /// 
      lc(black) lw(*1.5)) ///
   plot3opts(ms(i) lp(longdash) lc(black) lw(*1.5)) ///
   plot4opts(ms(i) lp(shortdash) lc(black) lw(*1.5)) ///
   plot5opts(ms(i) lp("_-") lc(black) lw(*1.5) ) name(censor, replace)
