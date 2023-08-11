/***********************************************
/* Example Test Code for bivpoisson_ate       */
/* 08-02-2023                                 */
***********************************************/


/***********************************************
Data: 

5% sample of medical care utilization data from 
the the National Australian Medical
Expenditure Survey

(Retrieved from the Data Archive of the
Journal of Applied Econometrics)

Observation Numbers = 207

Policy variable: privins (private insurance status)

Correlated Outcomes: ofp, ofnp
(# of doctor office visits, and # of non-physician health
professional office visits)
************************************************/

clear all

set varabbrev off

use "https://github.com/zhangyl334/bivpoisson/raw/main/Health_Data.dta", clear

/*************************************************
use command bivpoisson to estimate model deep
parameters
************************************************/

bivpoisson (ofp = privins black numchron) (ofnp = privins black numchron age)

/*************************************************
list alll ereturns stored by running command bivpoisson
************************************************/
ereturn list


/*************************************************
use post-estimation command bivpoisson_ate to 
estimate average treatment effects (ATEs), its 
standared errors (S.E.s of the ATEs), and p-values
Note:
bivpoisson_ate can be used independent of bivpoisson,
since it execute the optimization routine of bivpoisson
as a subroutine within its program
************************************************/

/*************************************************
example 1: asymmetric covariates in equation 1 and 2
*************************************************/
bivpoisson_ate (ofp = privins black numchron) (ofnp = privins black numchron age) 
ereturn list

/*************************************************
restrict data to a subset.
*************************************************/
bivpoisson_ate (ofp = privins black numchron) (ofnp = privins black numchron age) if poorhlth != 1
ereturn list

/*************************************************
example 2: symmetric covariates in equation 1 and 2
************************************************/

bivpoisson_ate (ofp = privins exclhlth poorhlth numchron age married school faminc employed) (ofnp = privins exclhlth poorhlth numchron age married school faminc employed) 

ereturn list
