{smcl}
{p}help {hi:xtdcce}{p_end}
{hline}
{title:Title}

{p 4 4}{cmd:xtdcce} - estimating heterogeneous coefficient models using common correlated effects in a dynamic panel.{p_end}

{title:Syntax}

{p 4 13}{cmd:xtdcce} {depvar} {indepvars} {ifin} [{cmd:,}
{cmdab:p:ooled}({varlist})
{cmdab:cr:osssectional}({varlist})
{cmd:cr_lags}({it:string})
{cmdab:nocross:sectional}
{cmdab:exo:genous_vars}({varlist})
{cmdab:endo:genous_vars}({varlist})
{cmdab:ivreg2:options}({it:string}) 
{cmd:lr}({varlist})
{cmd:lr_options}({it:string}) 
{cmdab:pooledc:onstant}
{cmdab:reportc:onstant}
{cmdab:noconst:ant}
{cmd:trend}
{cmdab:pooledt:rend}
{cmdab:res:iduals}({newvar}) 
{cmdab:jack:knife}
{cmdab:rec:ursive}
{cmd: nocd}
{cmd:cluster}({it:clustervar}) 
{cmd:noomit}
{cmd:full}
{cmd:lists}
{cmdab:noi:sily}
{cmd:post_full}]{p_end}

{p 4 4}Data has to be {cmd:tsset} before using {cmd:xtdcce}; see {help tsset}.{break}
{it:varlists} may contain time-series operators; see {help tsvarlist}.{break}
{cmd:xtdcce} requires the {help moremata} package.



{title:Contents}

{p 4}{help xtdcce##description:Description}{p_end}
{p 4}{help xtdcce##options:Options}{p_end}
{p 4}{help xtdcce##model:Econometric and Empirical Model}{p_end}
{p 4}{help xtdcce##saved_vales:Saved Values}{p_end}
{p 4}{help xtdcce##examples:Examples}{p_end}
{p 4}{help xtdcce##references:References}{p_end}
{p 4}{help xtdcce##about:About}{p_end}


{marker description}{title:Description}

{p 4 4}{cmd:xtdcce} estimates a heterogeneous coefficient model in a dynamic panel with dependence between cross sectional units. 
It supports the Common Correlated Effects Estimator (CCE) by Pesaran (2006), the Dynamic Common Correlated Effects Estimator (DCCE), 
proposed by Chudik and Pesaran (2015) and the Mean Group Estimator (MG, Pesaran and Smith, 1995) and the Pooled Mean Group Estimator (PMG, Shin et. al 1999). 
Additionally {cmd:xtdcce} tests for cross sectional dependence (see {help xtcd2}) and supports instrumental variable estimations (see {help ivreg2}).


{marker options}{title:Options}

{p 4 8}{cmdab:p:ooled}({varlist}) specifies variables which estimated coefficients are constrained to be equal across all cross sectional units.
Variables may occur in {indepvars}. 
Variables in {cmd:exogenous_vars()}, {cmd:endogenous_vars()} and {cmd:lr()} may be pooled as well.{p_end}

{p 4 8}{cmdab:cr:osssectional}({varlist}) defines the variables which are added as cross sectional averages to the equation. 
Variables in {cmd:crosssectional()} may be included in {cmd:pooled()}, {cmd:exogenous_vars()}, {cmd:endogenous_vars()} and {cmd:lr()}. 
Default option is to include all variables from {depvar}, {indepvars} and {cmd:endogenous_vars()}. Variables in {cmd: crosssectional()} are partialled out, the coefficients not estimated and reported.{p_end}

{p 4 8 12}{cmd:cr_lags}({it:string}) sets the number of lags of the cross sectional averages. If not defined but {cmd:crosssectional()} contains a varlist, then only contemporaneous cross sectional averages are added but no lags. {cmd:cr_lags(0)} is the equivalent.{p_end}

{p 4 8 12}{cmdab:nocross:sectional} suppresses adding any cross sectional averages
Results will be equivalent to the Mean Group estimator, or if {cmd:lr()} is set to the Pooled Mean Group estimator.{p_end}

{p 4 8 12}{cmdab:pooledc:onstant} restricts the constant term to be the same across all cross sectional units.{p_end}

{p 4 8 12}{cmdab:reportc:onstant} reports the constant term. If not specified the constant is partialled out.{p_end}

{p 4 8 12}{cmdab:noconst:ant} suppresses the constant term.{p_end}

{p 4 8}{cmd:xtdcce} supports IV regressions using {help ivreg2}. 
The IV specific options are:{break}
	{cmdab:exo:genous_vars}({varlist}) defines the exogenous variables.{break}
	{cmdab:endo:genous_vars}({varlist}) defines the endogenoues variables.{break}
	{cmdab:ivreg2:options}({it:string}) passes further options to {cmd:ivreg2}, see {help ivreg2##s_options:ivreg2, options}.{break}
	{cmd:fulliv} posts all available results from {cmd:ivreg2} in {cmd: e()} with prefix {it:ivreg2_}, see {help ivreg2##s_macros: ivreg2, macros}.{break}
	{cmdab:noi:sily} displays output of {cmd:ivreg2}.{p_end}

{p 4 8}{cmd:xtdcce} is able to estimate pooled mean group models (Shin et. al 1999), similar to {help xtpmg}. {break}
	{cmd:lr}({varlist}) specifies the variables to be included in the long-run cointegration vector. The first variable is the error-correction speed of adjustment term.{break}
	{cmd:lr_options}({it:string}), options for the long run coefficients. Options are:{break}{break}{p_end}
	{col 12}{cmd:nodivide} coefficients are not divided by the error correction speed of adjustment vector. Equation (7) is estimated, see {help xtdcce##pmg:xtdcce, pmg options}.
	{col 12}{cmd:xtpmgnames} coefficient names in {cmd: e(b_p_mg)} (or {cmd: e(b_full)}) and {cmd: e(V_p_mg)} (or {cmd: e(V_full)}) match the name convention from {help xtpmg}.

{p 4 8 12}{cmd:trend} adds a linear unit specific trend. May not be combined with {cmd:pooledtrend}.{p_end}

{p 4 8 12}{cmdab:pooledt:rend} adds a linear common trend. May not be combined with {cmd:trend}.{p_end}

{p 4 8 12}{cmdab:res:iduals}({newvar}) saves residuals as a new variable.{p_end}

{p 4 8}Two methods for small sample time series bias correction are supported:{break}
	{cmdab:jack:knife} applies the jackknife bias correction method. May not be combined with {cmd:recursive}.{break}
	{cmdab:rec:ursive} applies the recursive mean adjustment method. May not be combined with {cmd:jackknife}.{p_end}

{p 4 8 12}{cmd: nocd} suppresses calculation of CD test. For details about the CD test see {help xtcd2}.{p_end}

{p 4 8 12}{cmd:cluster}({it:clustervar}) clustered standard errrors, where {it:clustervar} is the cluster identifier.{p_end}

{p 4 8 12}{cmd:noomit} suppresses checks for collinearity.{p_end}

{p 4 8 12}{cmd:full} reports unit individual estimates in output.{p_end}

{p 4 8 12}{cmd:lists} shows all variable names and lags of cross sectional means.{p_end}

{p 4 8 12}{cmd:post_full} requests that individual estimates, rather than the mean group estimates are saved in {cmd:e(b)} and {cmd:e(V)}. Mean group estimates are then saved in {cmd:e(b_p_mg)} and {cmd:e(V_p_mg)}.{p_end}


{marker model}{title:Econometric and Empirical Model}

{p 2}{ul: Econometric Model}{p_end}

{p 4}Assume the following dynamic panel data model with heterogeneous coefficients:{p_end}

{col 10} (1) {col 20} y(i,t) = b0(i) + b1(i)*y(i,t-1) + x(i,t)*b2(i) + u(i,t)
{col 20} u(i,t) = g(i)*f(t) + e(i,t)

{p 4 4} where f(t) is an unobserved common factor loading, g(i) a heterogeneous factor loading, x(i,t) is a (1 x K) vector and b2(i) the coefficient vector.
The error e(i,t) is iid and the heterogeneous coefficients are randomly distributed around a common mean. It is assumed that x(i,t) is strictly exogenous.
In the case of a static panel model (b1(i) = 0) Pesaran (2006) shows that mean of the coefficients b1 and b2 (for example for b1 = 1/N sum(b1(i))) 
can be consistently estimated by adding cross sectional means of the dependent and all independent variables.
The cross sectional means approximate the unobserved factors. 
In a dynamic panel data model (b1(i) <> 0) pT lags of the cross sectional means are added to achieve consistency (Chudik and Pesaran 2015).
For both, the mean group estimates for b1 and b2 are consistently estimated as long as N,T and pT go to infinity. {p_end}

{p 2}{ul: Empirical Model}{p_end}

{p 4 4}The empirical model of equation (1) is:{p_end}

{col 10}(2){col 20} y(i,t) = b0(i) + b1(i)*y(i,t-1) + x(i,t)*b2(i) + sum[d(i)*z(i,s)] +  + e(i,t),

{p 4 4} where z(i,s) is a (1 x K+1) vector including the cross sectional means at time s and the sum is over s=t...t-pT.
{cmd:xtdcce} supports several different specifications of equation (2).{p_end}

{p 2}{ul: i) Mean Group}{p_end}

{p 4 4} If no cross sectional averages are added (d(i) = 0), then the estimator is the Mean Group Estimator as proposed by Pesaran and Smith (1995).
The estimated equation is:

{col 10}(3){col 20} y(i,t) = b0(i) + b1(i)*y(i,t-1) + x(i,t)*b2(i) + e(i,t).

{p 4 4} Equation (3) can be estimated by using the {cmd:nocross} option of {cmd:xtdcce}. The model can be either static (b(1) = 0) or dynamic (b(1) <> 0).{p_end} 

{p 2}{ul: ii) Common Correlated Effects}{p_end}

{p 4 4} The model in equation (3) does not account for unobserved common factors between units.
To do so, cross sectional averages are added in the fashion of Pesaran (2006):{p_end} 

{col 10}(4){col 20} y(i,t) = b0(i) + x(i,t)*b2(i) + d(i)*z(i,t) + e(i,t).

{p 4 4}  Equation (4) is the default equation of {cmd:xtdcce}.
Including the dependent and independent variables in {cmd:crosssectional()} and setting {cmd:cr_lags(0)} leads to the same result.
{cmd:crosssectional()} defines the variables to be included in z(i,t).
Important to notice is, that b1(i) is set to zero. {p_end}

{p 2}{ul: iii) Dynamic Common Correlated Effects}{p_end}

{p 4 4} If a lag of the dependent variable is added, endogeneity occurs and adding solely contemporaneous cross sectional averages is not sufficient any longer to achieve consistency.
However Chudik and Pesaran (2015) show, that consistency is gained if pT lags of the cross sectional averages are added:{p_end}

{col 10}(5){col 20} y(i,t) = b0(i) + b1(i)*y(i,t-1) + x(i,t)*b2(i) + sum [d(i)*z(i,s)] + e(i,t).

{p 4 4} where s = t...t-pT. Equation (5) is estimated if the option {cmd:cr_lags()} contains a positive number.{p_end}

{p 2}{ul: iv) Pooled Estimators}{p_end} 

{p 4 4} Equations (3) - (5) can be constrained that the parameters are the same across units. Hence the equations become:{p_end}

{col 10}(3-p){col 20} y(i,t) = b0 + b1*y(i,t-1) + x(i,t)*b2 + e(i,t),
{col 10}(4-p){col 20} y(i,t) = b0 + x(i,t)*b2 + d(i)*z(i,t) + e(i,t),
{col 10}(5-p){col 20} y(i,t) = b0 + b1*y(i,t-1) + x(i,t)*b2 + sum [d(i)*z(i,s)] + e(i,t).


{p 4 4}Variables with pooled (homogenous) coefficients are specified using the {cmd:pooled({varlist})} option. 
The constant is pooled by using the option {cmd:pooledconstant}.

{p 2}{ul: v) Instrumental Variables}{p_end}

{p 4 4}{cmd:xtdcce} supports estimations of instrumental variables by using the {help ivreg2} package. 
Endogenous variables (to be instrumented) are defined in {cmd:endogenous_vars({varlist})} and their instruments are defined in {cmd:exogenous_vars({varlist})}.{p_end}

{marker pmg}{p 2}{ul: vi) Pooled Mean Group Estimator}{p_end}

{p 4 4} As an intermediate between the mean group and a pooled estimation, Shin et. al (1999) differentiate between homogenous long run and heterogeneous short run effects.
Therefore the model includes mean group as well as pooled coefficients.
Equation (1) (for a better readability without the cross sectional averages) is transformed into an ARDL model:{p_end}

{col 10}(6){col 20}y(i,t) = phi(i)*(y(i,t-1) - x(i,t)*w(i)) + g0(i) + g1(i)*[y(i,t)-y(i,t-1)] + [x(i,t) - x(i,t-1)] * g2(i) + e(i,t),

{p 4 4}where phi(i) is the cointegration vector, w(i) captures the long run effects and g1(i) and g2(i) the short run effects.
Shin et. al estimate the long run coefficients by ML and the short run coefficients by OLS.
{cmd:xtdcce} estimates a slighlty different version by OLS:{p_end}

{col 10}(7){col 20}y(i,t) = phi(i)*y(i,t-1) + x(i,t)*o1(i) + g0(i) + g1(i)*[y(i,t)-y(i,t-1)] + [x(i,t) - x(i,t-1)] * g2(i) + e(i,t),

{p 4 4}where w(i) = - o1(i) / phi(i). Equation (7) is estimated by including the levels of y and x as long run variables using the {cmd:lr({varlist})} and {cmd:pooled({varlist})} options and adding the first differences as independent variables.
{cmd:xtdcce} estimates equation (7) but automatically calculates estimates for w(i).
The advantage estimating equation (7) by OLS is that it is possible to use IV regressions and add cross sectional averages to account for dependencies between units.


{marker saved_vales}{title:Saved Values}

{cmd:xtdcce} stores the following in {cmd:e()}:

{col 4} Scalars
{col 8}{cmd: e(N)}{col 27} number of observations
{col 8}{cmd: e(N_g)}{col 27} number of groups (cross sectional units)
{col 8}{cmd: e(T)}{col 27} number of time periods
{col 8}{cmd: e(K)}{col 27} number of regressors (including variables partialled out)
{col 8}{cmd: e(N_partial)}{col 27} number of partialled out variables
{col 8}{cmd: e(N_omitted)}{col 27} number of omitted variables
{col 8}{cmd: e(N_pooled)}{col 27} number of pooled (homogenous) coefficients
{col 8}{cmd: e(mss)}{col 27} model sum of squares
{col 8}{cmd: e(rss)}{col 27} residual sum of squares
{col 8}{cmd: e(F)}{col 27} F statistic
{col 8}{cmd: e(ll)}{col 27} log-likelihood (only IV)
{col 8}{cmd: e(rmse)}{col 27} root mean squared error
{col 8}{cmd: e(df_m)}{col 27} model degrees of freedom
{col 8}{cmd: e(df_r)}{col 27} residual degree of freedom
{col 8}{cmd: e(r2)}{col 27} R-squared
{col 8}{cmd: e(r2_a)}{col 27} R-squared adjusted
{col 8}{cmd: e(cd)}{col 27} CD test statistic
{col 8}{cmd: e(cdp)}{col 27} p-value of CD test statistic
{col 8}{cmd: e(minT)}{col 27} minimum time (only unbalanced panels)
{col 8}{cmd: e(avgT)}{col 27} average time (only unbalanced panels)
{col 8}{cmd: e(maxT)}{col 27} maximum time (only unbalanced panels)

{col 4} Macros
{col 8}{cmd: e(tvar)}{col 27} name of time variable
{col 8}{cmd: e(idvar)}{col 27} name of unit variable
{col 8}{cmd: e(depvar)}{col 27} name of dependent variable
{col 8}{cmd: e(indepvar)}{col 27} name of independent variables
{col 8}{cmd: e(omitted)}{col 27} omitted variables
{col 8}{cmd: e(lr)}{col 27} variables in long run cointegration vector
{col 8}{cmd: e(pooled)}{col 27} pooled (homogenous) coefficients
{col 8}{cmd: e(cmd)}{col 27} command line
{col 8}{cmd: e(cmd_full)}{col 27} command line including options
{col 8}{cmd: e(insts)}{col 27} instruments (exogenous) variables (only IV)
{col 8}{cmd: e(istd)}{col 27} instrumented (endogenous) variables (only IV)

{col 4} Matrices
{col 8}{cmd: e(b)}{col 27} coefficient vector 
{col 8}{cmd: e(V)}{col 27} variance-covariance matrix 
{col 8}{cmd: e(b_full)}{col 27} coefficient vector of individual and pooled coefficients
{col 8}{cmd: e(V_full)}{col 27} variance-covariance matrix of individual and pooled coefficients
{col 8}{cmd: e(b_p_mg)}{col 27} coefficient vector of mean group and pooled estimates if option {cmd:post_full} is used
{col 8}{cmd: e(V_p_mg)}{col 27} variance-covariance of matrix mean group and pooled estimates if option {cmd:post_full} is used

{col 4} Functions
{col 8}{cmd: e(sample)}{col 27} marks estimation sample


{marker examples}{title:Examples}

{p 4 4}An example dataset of the Penn World Tables 8 is available for download {browse "https://drive.google.com/file/d/0Bz0nTdXm8HD_VFpUZGJPSmRNMTg/view?usp=sharing":here}.
The dataset contains yearly observations from 1960 until 2007 and is already tsset.
To estimate a growth equation the following variables are used:
log_rgdpo (real GDP), log_hc (human capital), log_ck (physical capital) and log_ngd (population growth + break even investments of 5%).{p_end}


{p 4}{ul: Mean Group Estimation}{p_end}

{p 4 4}To estimate equation (3), the option {cmd:nocrosssectional} is used.
In order to obtain estimates for the constant, the option {cmd:reportconstant} is enabled. {p_end}

{p 8}{stata xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , nocross reportc}.{p_end}

{p 4 4}Omitting {cmd:reportconstant} leads to the same result, however the constant is partialled out:{p_end}

{p 8}{stata xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , nocross}.{p_end}	


{p 4}{ul: Common Correlated Effect}{p_end}

{p 4 4}Common Correlated effects (static) models can be estimated in several ways.
The first possibility is without any cross sectional averages related options:{p_end}

{p 8}{stata xtdcce d.log_rgdpo log_hc log_ck log_ngd , reportc}.{p_end}

{p 4 4}Note, that as this is a static model, the lagged dependent variable does not occur and only contemporaneous cross sectional averages are used.
Defining all independent and dependent variables in {cmd:crosssectional({varlist})} leads to the same result:{p_end}

{p 8}{stata xtdcce d.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo log_hc log_ck log_ngd)}.{p_end}

{p 4 4}The default for the number of cross sectional lags is zero, implying only contemporaneous cross sectional averages are used.
Finally the number of lags can be specified as well using the {cmd:cr_lags} option.{p_end}

{p 8}{stata xtdcce d.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo log_hc log_ck log_ngd) cr_lags(0)}.{p_end}

{p 4 4}All three command lines are equivalent and lead to the same estimation results.{p_end}


{p 4}{ul: Dynamic Common Correlated Effect}{p_end}

{p 4 4}The lagged dependent variable is added to the model again.
To estimate the mean group coefficients consistently, the number of lags is set to 3:{p_end}

{p 8}{stata xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo L.log_rgdpo  log_hc log_ck log_ngd) cr_lags(3)}.{p_end}


{p 4}{ul: Pooled Estimations}{p_end}

{p 4 4}All coefficients can be pooled by including them in {cmd:pooled({varlist})}.
The constant is pooled by using the {cmd:pooledconstant} option:{p_end}

{p 8}{stata xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo L.log_rgdpo  log_hc log_ck log_ngd) pooled(L.log_rgdpo  log_hc log_ck log_ngd) cr_lags(3) pooledconstant}.{p_end}


{p 4}{ul: Instrumental Variables}{p_end}
{p 4 4}Endogenous variables can be instrumented by using options {cmd:endogenous_vars({varlist})} and {cmd:exogenous_vars({varlist})}.
Internally {help ivreg2} estimates the individual coefficients.
Using the lagged level of physical capital as an instrument for the contemporaneous level, leads to:{p_end}

{p 8}{stata xtdcce d.log_rgdpo L.log_rgdpo log_hc log_ck log_ngd , reportc cr(d.log_rgdpo L.log_rgdpo  log_hc log_ck log_ngd) cr_lags(3) endo(log_ck) exo(L.log_ck) ivreg2options(nocollin noid)}.{p_end}

{p 4 4}Further {cmd:ivreg2} options can be passed through using {cmd:ivreg2options}. Stored values in {cmd:e()} from {cmd:ivreg2options} can be posted using the option {cmd:fulliv}.


{p 4}{ul: Pooled Mean Group Estimations}{p_end}

{p 4 4}Variables of the long run cointegration vector are defined in {cmd:lr({varlist})}, where the first variable is the error correction speed of adjustment term.
To ensure homogeneity of the long run effects, the corresponding variables have to be included in the {cmd:pooled({varlist})} option.{p_end}

{p 8}{stata xtdcce d.log_rgdpo d.L.log_rgdpo d.log_hc d.log_ck d.log_ngd , reportc lr(L.log_rgdpo log_hc log_ck log_ngd) p(L.log_rgdpo log_hc log_ck log_ngd)}{p_end}

{p 4 4}{cmd:xtdcce} internally estimates equation (7) and then recalculates the long run coefficients, such that estimation results for equation (8) are obtained.
Equation (7) can be estimated adding {cmd:nodivide} to {cmd:lr_options()}.
A second option is {cmd:xtpmgnames} in order to match the naming convention from {help xtpmg}.

{p 8}{stata xtdcce d.log_rgdpo d.L.log_rgdpo d.log_hc d.log_ck d.log_ngd , reportc lr(L.log_rgdpo log_hc log_ck log_ngd) p(L.log_rgdpo log_hc log_ck log_ngd) lr_options(nodivide)}{p_end}

{p 8}{stata xtdcce d.log_rgdpo d.L.log_rgdpo d.log_hc d.log_ck d.log_ngd , reportc lr(L.log_rgdpo log_hc log_ck log_ngd) p(L.log_rgdpo log_hc log_ck log_ngd) lr_options(xtpmgnames)}{p_end}


{marker references}{title:References}

{p 4 8}Baum, C. F., M. E. Schaffer, and S. Stillman 2007.
Enhanced routines for instrumental variables/generalized method of moments estimation and testing.
Stata Journal 7(4): 465-506{p_end}

{p 4 8}Chudik, A., and M. H. Pesaran. 2015.
Common correlated effects estimation of heterogeneous dynamic panel data models with weakly exogenous regressors.
Journal of Econometrics 188(2): 393-420.{p_end}

{p 4 8}Blackburne, E. F., and M. W. Frank. 2007.
Estimation of nonstationary heterogeneous panels.
Stata Journal 7(2): 197-208.{p_end}

{p 4 8}Eberhardt, M. 2012.
Estimating panel time series models with heterogeneous slopes.
Stata Journal 12(1): 61-1.{p_end}

{p 4 8}Feenstra, R. C., R. Inklaar, and M. Timmer. 2015.
The Next Generation of the Penn World Table. American Economic Review. www.ggdc.net/pwt{p_end}

{p 4 8} Jann, B. 2005. 
moremata: Stata module (Mata) to provide various functions. 
Available from http://ideas.repec.org/c/boc/bocode/s455001.html.

{p 4 8}Pesaran, M. 2006.
Estimation and inference in large heterogeneous panels with a multifactor error structure.
Econometrica 74(4): 967-1012.{p_end}

{p 4 8}Pesaran, M. H., and R. Smith. 1995.
Econometrics Estimating long-run relationships from dynamic heterogeneous panels.
Journal of Econometrics 68: 79-113.{p_end}

{p 4 8}Shin, Y., M. H. Pesaran, and R. P. Smith. 1999.
Pooled Mean Group Estimation of Dynamic Heterogeneous Panels.
Journal of the American Statistical Association 94(446): 621-634.{p_end}


{marker about}{title:Author}

{p 4}Jan Ditzen (Heriot-Watt University){p_end}
{p 4}Email: {browse "mailto:jd219@hw.ac.uk":jd219@hw.ac.uk}{p_end}
{p 4}Web: {browse "www.jan.ditzen.net":www.jan.ditzen.net}{p_end}

{p 4}Thanks Arnab Bhattacharjee and Mark Schaffer for many valuable comments and suggestions.{p_end}

{p 4}The routine to check for  positive definite or singular matrices was provided by Mark Schaffer, Heriot-Watt Universtiy, Edinburgh, UK.{p_end}

{p 4 8}Please cite as follows:{break}
Ditzen, J. 2016. xtdcce: Estimating dynamic common correlated effects in Stata.
Available at jan.ditzen.net
{p_end}

{title:Also see}
{p 4 4}See also: {help xtcd2}, {help ivreg2}, {help xtmg}, {help xtpmg}, {help moremata}{p_end} 
