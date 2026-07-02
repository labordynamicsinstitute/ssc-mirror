[XT] xtsurmg -- Fourier Seemingly Unrelated Regression Mean Group Estimator

Syntax
------

xtsurmg depvar indepvars [if] [in], [options]


Main Options
------------
fourier(#)        Include # Fourier terms to capture smooth structural changes
cce               Augment each equation with cross-section averages of the
                    dependent and independent variables (Common Correlated
                    Effects).

bootstrap(#)      Calculate bootstrap standard errors with # replications. The bootstrap option applies to the SUR route only and is ignored under cce.

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
xtsurmg implements the Fourier Seemingly Unrelated Regression Mean Group (F-SURMG) estimator for heterogeneous panel data with smooth changes (Guliyev, 2025). In its default form the estimator:

1. Estimates SUR/CCE equations for each group with/without Fourier terms
2. Calculates mean group estimates by averaging coefficients across groups
3. Computes standard errors using the Pesaran and Smith (1995) approach


Choosing an Estimator: F-SURMG vs. F-CCEMG
-------------------------------------------
Both routes are consistent for the mean slope under slope heterogeneity, but
they are designed for different combinations of panel size and
cross-sectional dependence (CSD). Guliyev (2026) maps their relative
performance using Monte Carlo evidence across weak, moderate, and strong CSD
and recommends the following:

    Panel / dependence                          Recommended estimator
    ------------------------------------------  -----------------------
    Very small N, weak CSD, 
    breaks at different
    dates across units                          F-SURMG (default; no cce)


    Small-to-moderate N, moderate CSD,
    idiosyncratic (unit-specific) breaks        F-CCEMG (cce + fourier(#))


    Large N and/or strong CSD                   CCEMG (cce, without fourier())
                                                 is usually enough; fourier()
                                                 adds only a small refinement

Examples
--------

Dataset import:
copy "https://drive.google.com/uc?export=download&id=1l66oUNXDXjNWRWXmAtpZbxiZPPYc7aQX" "g7data.dta", replace
use "g7data.dta", clear

SURMG estimation:
. xtset country year
. xtsurmg lny lnl lnk lnr

SURMG estimation with robust standard errors:
. xtsurmg lny lnl lnk lnr, vce(robust)

F-SURMG estimation with bootstrap standard errors with 100 replications - Table 7 and Appendix C in Guliyev(2025):
. xtsurmg lny lnl lnk lnr, fourier(1) bootstrap(100)

Pesaran (2006) CCE estimation:
.xtsurmg lny lnl lnk lnr,  cce

Guliyev (2026) F-CCEMG estimation:
. xtsurmg lny lnl lnk lnr, cce fourier(1)

Stored Results
-------------
Scalars:
e(groups)         Number of N
e(groups_used)    Number of units actually estimated (cce route)
e(time)           Number of T
e(bootstrap_reps) Number of bootstrap replications (if requested)

Macros:
e(estimator)      Estimator used (SURMG, F-SURMG or F-CCEMG)
e(cce)            "yes" if cce was specified, otherwise "no"
e(bootstrap)      "yes"/"no"
e(panelvar)       Panel (group) identifier
e(timevar)        Time identifier

Matrices:
e(b)              Coefficient vector (from SUR; SUR route only)
e(V)              Variance-covariance matrix (from SUR; SUR route only)
e(mg_means)       Mean group coefficients
e(mg_var)         Mean group variances
e(mg_se)          Standard errors
e(mg_z)           z-statistics
e(mg_p)           p-values

References
----------
- Guliyev, H. (2025). Heterogeneous panel data models with sharp and smooth changes: Testing green growth hypothesis in G7 countries. Innovation and Green Development, 4(3), 100245. https://doi.org/10.1016/j.igd.2025.100245

- Guliyev, H. (2026). Second-generation heterogeneous panel data model with individual and common shocks. arXiv preprint. https://doi.org/10.48550/arXiv.2606.29063

- Zellner, A. (1962). An efficient method of estimating seemingly unrelated regressions and tests for aggregation bias. Journal of the American Statistical Association, 57(298), 348-368. https://doi.org/10.1080/01621459.1962.10480664

- Pesaran, M. H., & Smith, R. (1995). Estimating long-run relationships from dynamic heterogeneous panels. Journal of Econometrics, 68(1), 79-113. https://doi.org/10.1016/0304-4076(94)01644-F

- Pesaran, M. H. (2006). Estimation and inference in large heterogeneous panels with a multifactor error structure. Econometrica, 74(4), 967-1012. https://doi.org/10.1111/j.1468-0262.2006.00692.x

Also see
--------
help sureg
help xtmg

Author: Hasraddin Guliyev
Email: hasradding@unec.edu.az
