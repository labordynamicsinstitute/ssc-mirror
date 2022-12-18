/***********************************************
/*Example Test Code*/
***********************************************/


/***********************************************
Data: 

5% sample of medical care utilization data from 
the the National Australian Medical
Expenditure Survey

(Retrieved from the Data Archive of the
Journal of Applied Econometrics)

Observation Numbers = 207
************************************************/

clear all

set varabbrev off

use "https://github.com/zhangyl334/bivpoisson/raw/main/Health_Data.dta", clear

bivpoisson (ofp = privins black numchron) (ofnp = privins black numchron age) if fivepct_sample == 1

ereturn list
