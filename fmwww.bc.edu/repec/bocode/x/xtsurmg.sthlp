[XT] xtsurmg -- Fourier Seemingly Unrelated Regression Mean Group Estimator

Syntax
------

xtsurmg depvar indepvars [if] [in], [options]


Main Options
------------
fourier(#)        Include # Fourier terms to capture smooth structural changes
bootstrap(#)      Calculate bootstrap standard errors with # replications
vce(vcetype)      Variance-covariance estimator:
                    unadjusted  - Conventional standard errors
                    robust      - Huber/White robust standard errors
                    cluster     - Cluster-robust standard errors (specify clustvar)

Small-Sample Adjustments
------------------------
dfadj             Degrees-of-freedom adjustment
small             Report small-sample statistics
dfk               Use small-sample adjustment
dfk2              Use alternate adjustment

Reporting Options
-----------------
corr              Display correlation matrix of residuals
level(#)          Set confidence level (default is 95)
noHeader          Suppress header display
noTable           Suppress coefficient table display

Description
-----------
xtsurmg implements the Fourier Seemingly Unrelated Regression Mean Group (F-SURMG) estimator for heterogeneous panel data with smooth changes (Guliyev, 2025). The estimator:

1. Estimates SUR equations for each group with Fourier terms
2. Calculates mean group estimates by averaging coefficients across groups
3. Computes standard errors using the Pesaran and Smith (1995) approach

The Fourier terms help capture smooth changes without requiring breakpoint detection.

Examples
--------

Dataset import:
use "g7data.dta", clear

SURMG estimation:
. xtset country year
. xtsurmg lny lnl lnk lnr

SURMG estimation with robust standard errors:
. xtsurmg lny lnl lnk lnr, vce(robust)

F-SURMG estimation with bootstrap standard errors with 100 replications - Table 7 and Appendix C in Guliyev(2025):
. xtsurmg lny lnl lnk lnr, fourier(1) bootstrap(100)

Stored Results
-------------
Scalars:
e(groups)       Number of N
e(time)       	Number of T


Matrices:
e(b)              Coefficient vector (from SUR)
e(V)              Variance-covariance matrix (from SUR)
e(mg_means)       Mean group coefficients
e(mg_se)          Standard errors
e(mg_z)           z-statistics
e(mg_p)           p-values

References
----------
- Guliyev, H. (2025). Heterogeneous panel data models with sharp and smooth changes: Testing green growth hypothesis in G7 countries. Innovation and Green Development, 4(3), 100245. https://doi.org/10.1016/j.igd.2025.100245

- Zellner, A. (1962). An efficient method of estimating seemingly unrelated regressions and tests for aggregation bias. Journal of the American Statistical Association, 57(298), 348-368. https://doi.org/10.1080/01621459.1962.10480664

- Pesaran, M. H., & Smith, R. (1995). Estimating long-run relationships from dynamic heterogeneous panels. Journal of Econometrics, 68(1), 79-113. https://doi.org/10.1016/0304-4076(94)01644-F

Also see
--------
help sureg

Author: Hasraddin Guliyev
Email: hasradding@unec.edu.az
