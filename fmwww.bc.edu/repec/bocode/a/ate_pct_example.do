clear

use ate_pct_example,clear
*(1) First run a semi-log regression, to get the estimate of tauhat.

reg lny x gr1 gr2 gr3, robust 

*(2) Then compute various measures of ATE in percentage points.

ate_pct gr1 gr2 gr3 

ate_pct gr1 gr2 gr3,  truew

ate_pct gr1 gr2 gr3,  groupsize(1 1 1) truew

ate_pct gr1 gr2 gr3,  groupsize(15 24 37) // this is exactly the same as ate_pct gr1 gr2 gr3 as 15 24 37 are the sample size for the three treatment group


