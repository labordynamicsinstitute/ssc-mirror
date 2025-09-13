/******************************************
** NCA ANALYSIS
******************************************/
**1. open the dataset
findfile ncaexample.dta
use "`r(fn)'", clear
**2. nca with one condition
nca_analysis individualism innovationperformance
**3.	NCA's statistical test (MIGHT TAKE TIME!)
set seed 1234567
nca_analysis individualism innovationperformance, testrep(10000) 
**4.	Selection of ceiling lines
nca_analysis individualism innovationperformance ,  ceilings(ce_fdh)
**5.	NCA with multiple conditions
  nca_analysis individualism risktaking innovationperformance
  graph dir
**6. Displaying the bottleneck table with default values
nca_analysis individualism risktaking innovationperformance, nograph nosummaries bottlenecks
**7.	Displaying the bottleneck tables with custom values
nca_analysis individualism risktaking innovationperformance, nograph nosummaries bottlenecks(0(5)100)
**8.	Displaying the bottleneck tables with actual values 
nca_analysis individualism risktaking innovationperformance, nograph nosummaries xbottlenecks(actual) ybottlenecks(actual) bottlenecks
******the same, but with a customized table
nca_analysis individualism risktaking innovationperformance, nograph nosummaries xbottlenecks(actual) ybottlenecks(actual) bottlenecks(50(25)100 180)
**9.	Displaying the bottleneck tables with percentile and actual values 
nca_analysis individualism risktaking innovationperformance, nograph nosummaries xbottlenecks(percentile) ybottlenecks(actual) bottlenecks
/******************************************
** NCA OUTLIERS
******************************************/
nca_outliers individualism innovationperformance,  id(country) 

nca_outliers individualism innovationperformance,  id(country) scope(0 100 0 250)

nca_outliers individualism innovationperformance,  id(country)  ceil(cr_vrs)

nca_outliers individualism innovationperformance,  id(country)  k(2) 

nca_outliers individualism innovationperformance,  id(country) corner(2) // i only obtain a difference here

nca_outliers individualism innovationperformance,  id(country) corner(3)

nca_outliers individualism innovationperformance,  id(country) corner(4)


findfile ncaexample2.dta
use "`r(fn)'", clear
gen id=_n
sort innov com
nca_outliers competencetrust innovation, id(id) ceil(ce_vrs)

nca_outliers competencetrust innovation, id(id) k(1) ceil(cr_vrs)

/******************************************
** NCA RANDOM AND NCA POWER
******************************************/



/* UNIFORM */

* CORNER=1
set seed 123456
nca_random, n(1000) i(0 .5) s(1 `=2/3') clear
tw (scatter Y X1) (function y=x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 + 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=1)

* CORNER=2
set seed 123456
nca_random, n(1000) i(1 .5) s(-1 `=-2/3') clear corner(2)
tw (scatter Y X1) (function y=1-x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 - 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=2)

* CORNER=3
set seed 123456
nca_random, n(1000) i(1 .5) s(-1 `=-2/3') clear corner(3)
tw (scatter Y X1) (function y=1-x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 - 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=3)

* CORNER=4
set seed 123456
nca_random, n(1000) i(0 .5) s(1 `=2/3') clear corner(4)
tw (scatter Y X1) (function y=x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 + 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=4)


/* NORMAL */

* CORNER=1
set seed 123456
nca_random, n(1000) i(0 .5) s(1 `=2/3') clear xd(normal) yd(normal) 
tw (scatter Y X1) (function y=x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 + 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=1) subtitle(normal)

* CORNER=2
set seed 123456
nca_random, n(1000) i(1 .5) s(-1 `=-2/3') clear corner(2) xd(normal) yd(normal)
tw (scatter Y X1) (function y=1-x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 - 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=2) subtitle(normal)

* CORNER=3
set seed 123456
nca_random, n(1000) i(1 .5) s(-1 `=-2/3') clear corner(3) xd(normal) yd(normal)
tw (scatter Y X1) (function y=1-x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 - 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=3) subtitle(normal)

* CORNER=4
set seed 123456
nca_random, n(1000) i(0 .5) s(1 `=2/3') clear corner(4) xd(normal) yd(normal)
tw (scatter Y X1) (function y=x) , xline(0 1) yline(0 1) nodraw name(g1, replace)
tw (scatter Y X2) (function y=0.5 + 2/3*x), xline(0 1) yline(0 1) nodraw name(g2, replace)
graph combine g1 g2, ycommon title(corner=4) subtitle(normal)



/* NCA POWER */

// default
set seed 123456
nca_power 

/* this might take some time*/
set seed 123456
nca_power, n(50 100) rep(100) xd(normal) yd(normal)


 nca_power, n(100 200 300) rep(1000)
 
  nca_power, n(100 200 300) rep(1000) corner(2)  ceiling(cr_vrs)     