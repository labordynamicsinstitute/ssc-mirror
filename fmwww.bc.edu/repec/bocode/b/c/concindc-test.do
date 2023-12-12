clear
set mem 20m
set matsize 8000

global wdir L:\Research\CI-Categorical-Income
cd $wdir
capture log close 
log using $wdir\temp.smcl, replace
use $wdir\concindc-test.dta, clear

capture drop rran
gen rran= uniform()

/* use Wagstaff et al. World Bank grouped Vietnam dataset */
* see http://siteresources.worldbank.org/INTPAH/Resources/Publications/Quantitative-Techniques/concentration_index.xls

/* with provided standard error */
concindc health3w [fweight=wt3w] , wel(inc3w ) sigma(stdh3w)

/* with no standard error */
concindc health3w [fweight=wt3w] , wel(inc3w )

/* or alternatively */
concindc health3w [fweight=wt3w] , wel(inc3w ) sigma(zeros)

/* using six observations */
/* Demonstrating upper bound */
gsort inc +health
concindexi health, wel(inc )
concindc health, wel(inc )

/* Demonstrating lower bound */

gsort inc -health
concindexi health, wel(inc )
concindc health, wel(inc )

/* random sorting */

gsort inc +rran
concindexi health, wel(inc ) cle
concindc health, wel(inc )

/* expand to 2000 observations */

gsort inc +health5
concindexi health5, wel(inc5 ) 
concindc health5, wel(inc5 )

gsort inc -health5
concindexi health5, wel(inc5 )
concindc health5, wel(inc5 )

/* comparing results from concindexi and cocindc */

gsort inc +rran
concindexi health5, wel(inc5 ) cle
concindc health5, wel(inc5 )

/* simulation with 2000 replications */
local maxj=2000
local j=1
while `j'<=`maxj' {
qui capture drop tem
qui gen tem = uniform()
qui sort tem
qui concindexi health, wel(inc)
qui local j=`j'+1
}
qui capture drop tem
mat A=r(CII)
capture drop ci1 ci2
svmat A, names(ci) 
sum ci1, detail

translate $wdir\temp.smcl $wdir\worklog-10-19.log, replace
capture log close
capture erase $wdir\temp.smcl
