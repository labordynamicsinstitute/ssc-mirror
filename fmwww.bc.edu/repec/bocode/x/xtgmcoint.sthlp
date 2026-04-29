{smcl}
{* *! version 1.0  25apr2026}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:xtgmcoint} {hline 2}}Estimate the cointegrating relationship in heterogeneous panels using Pedroni's group-mean Fully Modified OLS (FMOLS) and Dynamic OLS (DOLS){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:xtgmcoint} {depvar} {indepvars} {ifin} {cmd:,} {opt method(string)} [{it:options}]


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt method(string)}}{cmd:dols} or {cmd:fmols}{p_end}

{syntab:Common to both methods}
{synopt:{opt tdum}}include common time dummies (subtract cross-section means at each time period){p_end}
{synopt:{opt trend}}include linear time trend{p_end}
{synopt:{opt b(numlist)}}null hypothesis vector for the long-run coefficients (one value per regressor, or a single value applied to all); default 0{p_end}
{synopt:{opt average(string)}}{cmd:simple} (default), {cmd:sqrt}, {cmd:precision}{p_end}
{synopt:{opt full}}display regression details for each cross-section unit{p_end}
{synopt:{opt ttest}}use t-distribution (with finite-sample degrees of freedom) instead of standard normal for unit-level p-values and confidence intervals when {cmd:full} is specified{p_end}

{syntab:DOLS-specific (method(dols))}
{synopt:{opt dlags(#)}}leads/lags of D.x in the DOLS regression; default 2{p_end}
{synopt:{opt lags(#)}}Bartlett kernel lag for Newey-West HAC; default auto{p_end}
{synopt:{opt pedroni2001}}option to replicate Pedroni (2001) Table 1 panel results; uses the (T+2*lags) HAC denominator from the original code instead of the default T denominator{p_end}

{syntab:FMOLS-specific (method(fmols))}
{synopt:{opt lags(#)}}Bartlett kernel lag for long-run covariance; default auto{p_end}

{syntab:Post-estimation}
{synopt:{opt resid(name)}}save residuals (matches RATS %resids: y - alpha_GM - X*beta_panel){p_end}
{synopt:{opt fit(name)}}save fitted values (= y - resid){p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:xtgmcoint} estimates Pedroni's (2000, 2001) between-dimension group-mean
panel cointegration estimators in heterogeneous panels:

{phang2}
{cmd:method(dols)} - Group-Mean Panel Dynamic OLS (Pedroni 2001).
Replicates RATS {cmd:@paneldols} ({cmd:paneldols.src}, SSC: RTS00150).{p_end}

{phang2}
{cmd:method(fmols)} - Group-Mean Panel Fully Modified OLS (Pedroni 2000).
Replicates RATS {cmd:@panelfm} ({cmd:panelfm.src}, SSC: RTS00151).{p_end}

{pstd}
Output matches the corresponding RATS routine to four decimal places
across univariate and multivariate specifications, balanced and unbalanced
panels, with or without time dummies and trend, and all three averaging
methods ({cmd:simple}, {cmd:sqrt}, {cmd:precision}).


{title:Post-estimation variables}

{pstd}
A single post-estimation variable can be saved to the dataset.

{synoptset 22 tabbed}{...}
{synopt:{opt resid(name)}}{bf:Residuals}: {it:y[it] - alpha_GM - X[it]'*beta_panel},
computed using the panel-mean slope coefficients on x and the simple mean of
unit-level intercepts. This corresponds exactly to the {it:%RESIDS} series
produced by Pedroni's RATS routines (paneldols.src and panelfm.src), and is
the input typically used for panel cointegration tests such as Pedroni's
PP/ADF, Westerlund (2005, 2007), or Kao tests.{p_end}

{synopt:{opt fit(name)}}{bf:Fitted values}: {it:y[it] - resid[it]}, the model's
predicted value of {it:y[it]} using the panel-mean slope coefficients and the
group-mean of unit intercepts. Equivalent to RATS' {cmd:set fit = y - %resids}.{p_end}


{title:Examples}

{pstd}
{bf:Example 1: Replication of Pedroni (2001), Table 1 - xtgmcoint and RATS Codes}

{pstd}
To replicate Pedroni (2001) Table 1 results in RATS, click the link below
for the required files:

{phang2}{browse "https://eruygurakademi.com/datasets/rats_req_files.txt"}{p_end}

{pstd}
or download the zip archive shown below:

{phang2}{browse "https://eruygurakademi.com/datasets/pedroni2001_replication_winrats.zip"}{p_end}

{pstd}
Place the files in this archive into a folder and set that folder as the
working directory in RATS. Running the {cmd:pedroni_ppp.rpf} file from
the zip archive produces the following results:

{p 8 8 2}Country{space 8}FMOLS{space 4}t-stat{space 4}DOLS{space 6}t-stat{p_end}
{p 8 8 2}UK{space 13}0.68{space 4}-2.59**{space 4}0.67{space 5}-1.88*{p_end}
{p 8 8 2}Belgium{space 8}0.31{space 4}-1.74*{space 5}0.23{space 5}-1.93*{p_end}
{p 8 8 2}Denmark{space 8}1.63{space 5}1.95*{space 5}1.90{space 6}2.80**{p_end}
{p 8 8 2}France{space 9}2.00{space 5}5.95**{space 4}2.21{space 6}7.96**{p_end}
{p 8 8 2}Germany{space 8}0.80{space 4}-1.42{space 6}0.91{space 5}-0.59{p_end}
{p 8 8 2}Italy{space 10}0.97{space 4}-0.48{space 6}1.08{space 6}1.11{p_end}
{p 8 8 2}Holland{space 8}0.69{space 4}-1.92*{space 5}0.66{space 5}-2.03*{p_end}
{p 8 8 2}Sweden{space 9}1.22{space 5}1.16{space 6}1.16{space 6}0.81{p_end}
{p 8 8 2}Switzerland{space 4}1.27{space 5}1.96*{space 5}1.36{space 6}2.21*{p_end}
{p 8 8 2}Canada{space 9}1.44{space 5}2.01*{space 5}1.43{space 6}1.85*{p_end}
{p 8 8 2}Japan{space 10}1.79{space 5}5.21**{space 4}1.75{space 6}4.94**{p_end}
{p 8 8 2}Greece{space 9}1.02{space 5}0.54{space 6}0.99{space 5}-0.36{p_end}
{p 8 8 2}Portugal{space 7}1.05{space 5}1.41{space 6}1.09{space 6}2.42*{p_end}
{p 8 8 2}Spain{space 10}0.93{space 4}-0.83{space 6}1.02{space 6}0.18{p_end}
{p 8 8 2}Turkey{space 9}1.10{space 5}6.36**{space 4}1.11{space 6}5.74**{p_end}
{p 8 8 2}New Zealand{space 4}1.11{space 5}2.58**{space 4}1.02{space 6}0.60{p_end}
{p 8 8 2}Chile{space 10}1.21{space 5}10.32**{space 3}1.37{space 6}10.77**{p_end}
{p 8 8 2}Mexico{space 9}1.03{space 5}3.43**{space 4}1.03{space 6}3.54**{p_end}
{p 8 8 2}India{space 10}2.12{space 5}8.15**{space 4}2.06{space 6}7.67**{p_end}
{p 8 8 2}South Korea{space 4}0.93{space 4}-1.06{space 6}0.88{space 5}-1.44{p_end}

{p 8 8 2}Panel Results{p_end}
{p 8 8 2}Without Time Dummies{p_end}
{p 8 8 2}Between{space 8}1.17{space 5}8.67**{space 4}1.20{space 6}9.34**{p_end}
{p 8 8 2}With Time Dummies{p_end}
{p 8 8 2}Between{space 8}1.12{space 4}13.48**{space 3}1.14{space 5}12.50**{p_end}

{pstd}
The corresponding {cmd:xtgmcoint} commands to produce the same results
are as follows:

{phang2}{cmd:. use https://eruygurakademi.com/datasets/pedronidata.dta, clear}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) dlags(4) lags(4) b(1) full ttest}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) lags(4) b(1) full ttest}{p_end}

{pstd}
Note that in Pedroni (2001), panel results of Table 1 are produced with
{cmd:lags=5, mlags=5}. In {cmd:xtgmcoint}, the Pedroni (2001) Table 1
panel "Between" values for DOLS are reproduced exactly with the
{cmd:pedroni2001} option, which uses the (T+2*lags) HAC denominator
from the original code:

{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) dlags(5) lags(5) b(1) pedroni2001}{p_end}
{phang2}{it:beta = 1.2024, t = 9.5374  (Pedroni 2001 Table 1: 1.20, 9.54)}{p_end}

{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) dlags(5) lags(5) b(1) tdum pedroni2001}{p_end}
{phang2}{it:beta = 1.1409, t = 12.7611  (Pedroni 2001 Table 1: 1.14, 12.76)}{p_end}


{pstd}
{bf:Example 2: Model specifications}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/pedronidata.dta, clear}{p_end}

{pstd}
With constant (default):

{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols)}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols)}{p_end}

{pstd}
Model with trend:

{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) trend}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) trend}{p_end}

{pstd}
With time dummies:

{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) tdum}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) tdum}{p_end}

{pstd}
With time dummies and trend:

{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) tdum trend}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) tdum trend}{p_end}

{pstd}
With different lag options:

{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) lags(5) dlags(5) trend}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) lags(5) trend}{p_end}

{pstd}
Equivalent RATS code:

{phang2}{browse "https://www.eruygurakademi.com/datasets/ex2_rats_code.txt"}{p_end}


{pstd}
{bf:Example 3: Multivariate example}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/pedronidata.dta, clear}{p_end}
{phang2}{cmd:. gen logwpi_ratio = log(wpi/uswpi)}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio logwpi_ratio, method(dols) lags(5) dlags(5)}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio logwpi_ratio, method(fmols) lags(5)}{p_end}

{pstd}
Equivalent RATS code:

{phang2}{browse "https://www.eruygurakademi.com/datasets/ex3_rats_code.txt"}{p_end}


{pstd}
{bf:Example 4: Multivariate example with different null hypotheses per variable via b() vector}

{pstd}
The {cmd:b()} option accepts either a single value (applied to every RHS
coefficient) or a vector of values (one per RHS) for testing different null
hypotheses on different coefficients. With four right-hand-side variables
(uswpi, uscpi, cpi, wpi), test {it:H0: theta_uswpi = 1} and
{it:H0: theta = 0} for the others:

{phang2}{cmd:. xtgmcoint logexrate uswpi uscpi cpi wpi, method(dols) lags(5) dlags(5) b(1 0 0 0)}{p_end}

{pstd}
Equivalent RATS code:

{phang2}{browse "https://www.eruygurakademi.com/datasets/ex4_rats_code.txt"}{p_end}


{pstd}
{bf:Example 5: Short-T multivariate example (T=46)}

{pstd}
Truncating to first 46 months (matching typical macro-panel length):

{phang2}{cmd:. use https://eruygurakademi.com/datasets/pedronidata.dta, clear}{p_end}
{phang2}{cmd:. gen logwpi_ratio = log(wpi/uswpi)}{p_end}
{phang2}{cmd:. bysort country (time): keep if _n <= 46}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio logwpi_ratio, method(dols) lags(2) dlags(2)}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio logwpi_ratio, method(fmols) lags(2)}{p_end}

{pstd}
Equivalent RATS code:

{phang2}{browse "https://www.eruygurakademi.com/datasets/ex5_rats_code.txt"}{p_end}


{pstd}
{bf:Example 6: Comparison with xtpedroni (Neal 2014)}

{pstd}
{cmd:xtpedroni} uses a slightly different Newey-West denominator
(T+2*lags vs T). To replicate {cmd:xtpedroni}'s PDOLS results exactly,
use the {cmd:pedroni2001} option:

{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) lags(5) dlags(5) b(1) pedroni2001}{p_end}
{phang2}{cmd:. xtpedroni logexrate logratio, lags(5) mlags(5) b(1) notdum notest}{p_end}


{pstd}
{bf:Example 7: Saving residuals and fitted y values}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/pedronidata.dta, clear}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) lags(5) resid(ehat_fm) fit(yhat_fm)}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(dols) lags(5) dlags(5) resid(ehat_dols) fit(yhat_dols)}{p_end}
{phang2}{cmd:. summ ehat_fm yhat_fm ehat_dols yhat_dols}{p_end}

{pstd}
Equivalent RATS code:

{phang2}{browse "https://www.eruygurakademi.com/datasets/ex7_rats_code.txt"}{p_end}


{pstd}
{bf:Example 8: All three averaging methods}

{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) lags(5) b(1) average(simple)}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) lags(5) b(1) average(sqrt)}{p_end}
{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) lags(5) b(1) average(precision)}{p_end}

{pstd}
Equivalent RATS code:

{phang2}{browse "https://www.eruygurakademi.com/datasets/ex8_rats_code.txt"}{p_end}


{pstd}
{bf:Example 9: Density plot of unit-level estimates}

{pstd}
After estimation, unit-level coefficients can be exported and visualized:

{phang2}{cmd:. xtgmcoint logexrate logratio, method(fmols) lags(5)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. svmat e(ibetas), names(beta_)}{p_end}
{phang2}{cmd:. kdensity beta_1, normal}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
This shows the cross-section distribution of the unit-level long-run
coefficients, useful for assessing heterogeneity and identifying
outlier units.


{title:Stored results}

{pstd}
{cmd:xtgmcoint} stores the full set of estimation results in {cmd:e()},
following Stata's standard convention.

{pstd}
{bf:Scalars}

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(N)}}total number of observations used across all units{p_end}
{synopt:{cmd:e(N_g)}}number of cross-sectional units retained (units with insufficient observations are dropped){p_end}
{synopt:{cmd:e(K_x)}}number of long-run regressors (length of {it:indepvars}){p_end}
{synopt:{cmd:e(dlags)}}number of DOLS leads/lags ({cmd:method(dols)} only){p_end}
{synopt:{cmd:e(lags)}}Bartlett kernel HAC bandwidth (auto if not specified){p_end}

{pstd}
{bf:Macros}

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(cmd)}}always {cmd:xtgmcoint}{p_end}
{synopt:{cmd:e(method)}}{cmd:dols} or {cmd:fmols} (whichever was used){p_end}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(xvars)}}names of the long-run regressors{p_end}
{synopt:{cmd:e(average)}}group-mean averaging method: {cmd:simple}, {cmd:sqrt}, or {cmd:precision}{p_end}
{synopt:{cmd:e(tdum)}}{cmd:yes} if time dummies were applied, {cmd:no} otherwise{p_end}

{pstd}
{bf:Matrices - Panel-level (group-mean)}

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(b_lr)}}1 x K_x row vector of panel long-run coefficients ({it:theta_GM}). 
This is the main result reported in the output table.{p_end}
{synopt:{cmd:e(se_lr)}}1 x K_x row vector of panel standard errors, derived from cross-section dispersion of unit-level estimates.{p_end}
{synopt:{cmd:e(V_lr)}}K_x x K_x panel variance-covariance matrix.{p_end}
{synopt:{cmd:e(t_lr)}}1 x K_x row vector of panel t-statistics, computed as {it:t = (1/sqrt(N_g)) sum[i] (theta_hat[i] - b0) / SE[i]}. Distributed N(0,1) under standard panel-cointegration assumptions.{p_end}
{synopt:{cmd:e(b0)}}1 x K_x row vector of null hypothesis values for the long-run coefficients (set by {cmd:b()}; default zeros).{p_end}

{pstd}
{bf:Matrices - Unit-level (matches RATS @paneldols / @panelfm output)}

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(ibetas)}}N_g x K_x matrix. Each row {it:i} contains unit {it:i}'s long-run coefficient vector ({it:theta_hat[i]}). Matches RATS' {it:%%IBETAS}.{p_end}
{synopt:{cmd:e(istderr)}}N_g x K_x matrix of unit-level standard errors. Matches RATS' {it:%%ISTDERRS}.{p_end}
{synopt:{cmd:e(itstats)}}N_g x K_x matrix of unit-level t-statistics, computed against the null {cmd:b()} (default 0). Matches RATS' {it:%%ITSTATS}.{p_end}

{pstd}
{bf:How to access stored results}

{phang2}{cmd:. matrix list e(b_lr)}{p_end}
{phang2}{cmd:. matrix list e(ibetas)}{p_end}
{phang2}{cmd:. di "Panel coefficient: " e(b_lr)[1,1]}{p_end}
{phang2}{cmd:. di "Method used: " e(method)}{p_end}
{phang2}{cmd:. di "Number of valid units: " e(N_g)}{p_end}

{pstd}
The unit-level matrices ({cmd:e(ibetas)}, {cmd:e(istderr)}, {cmd:e(itstats)})
are useful for further analysis, e.g. constructing density plots of
unit-level estimates, identifying outlier countries, or building
heterogeneity diagnostics.


{title:References}

{phang}
Pedroni, P. 2000. Fully modified OLS for heterogeneous cointegrated panels.
{it:Advances in Econometrics} 15: 93-130.

{phang}
Pedroni, P. 2001. Purchasing power parity tests in cointegrated panels.
{it:Review of Economics and Statistics} 83(4): 727-731.

{phang}
Pedroni, P. {bf:paneldols.src} (RATS procedure, January 2000). SSC: RTS00150.

{phang}
Pedroni, P. {bf:panelfm.src} (RATS procedure). SSC: RTS00151.

{phang}
Phillips, P. C. B., and B. E. Hansen. 1990. Statistical inference in
instrumental variables regression with I(1) processes.
{it:Review of Economic Studies} 57(1): 99-125.

{phang}
Stock, J. H., and M. W. Watson. 1993. A simple estimator of cointegrating
vectors in higher order integrated systems. {it:Econometrica} 61(4): 783-820.


{title:Author}

{pstd}H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com"}{break}
{browse "mailto:eruygur@gmail.com":eruygur@gmail.com}{p_end}

{pstd}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye{break}
{browse "https://www.eruygurakademi.com"}{break}
{browse "mailto:eruygurakademi@gmail.com":eruygurakademi@gmail.com}{p_end}

{pstd}
{cmd:xtgmcoint v1.0} - April 2026{p_end}


{title:Citation}

{pstd}
Please cite as:

{phang2}
Eruygur, H. O. 2026. xtgmcoint: Native Stata implementation of Pedroni's
group-mean panel cointegration FMOLS and DOLS estimators (Pedroni 2000, 2001).
Stata package version 1.0. Available from: {browse "https://www.eruygurakademi.com"}{p_end}


{title:Also see}

{psee}
Online: help for {help xtpedroni}
