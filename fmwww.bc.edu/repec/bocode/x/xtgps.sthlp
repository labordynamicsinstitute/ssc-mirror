{smcl}
{* 26aug2024}{...}
{cmd:help xtgps}{right:version:   2.5}
{right:also see:  {helpb xtscc}}
{hline}

{title:Title}

{p 4 8}
{cmd:xtgps}  -  Estimation of Hoechle, Schmid, and Zimmermann's (2024) GPS-regression model for analyzing asset returns {p_end}


{title:Syntax}

{p 8 14 2}
{cmd:xtgps}
{depvar}
{it:subjectvar(s)}
{ifin}
{weight}
[, {it:options}]


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tsv:ars(varlist)}}{it:varlist} containing the market variables (i.e. the variables of the performance measurement model){p_end}
{synopt:{opt cont:rolvars(varlist)}}{it:varlist} of control variables{p_end}
{synopt:{opt lag:(#)}}set maximum lag order of autocorrelation; default is H(T)=floor[4(T/100)^(2/9)]{p_end}
{synopt:{opt noc:onstant}}suppress the regression constant{p_end}
{synopt:{opt ase}}return (asymptotic) Driscoll-Kraay SE without small sample adjustment{p_end}
{synopt:{opt fe:}}Estimate the GPS-model by aid of the fixed effects (within) estimator;
the default is pooled OLS.{p_end}
{synopt:{opt re:}}Estimate the GPS-model by aid of the GLS random effects estimator;
the default is pooled OLS.{p_end}
{synopt:{opt vce:type(vcetype)}}Define the covariance matrix estimator that has to be applied in the estimation. See below.{p_end}

{syntab:GPS-model specification test}
{synopt:{opt spec:test}}Perform the GPS-model specification test in Hoechle, Schmid, and Zimmermann (2024).{p_end}
{synopt:{opt not:able}}Display the results from the GPS-model specification test without showing the regression results underlying the Wald-test (requires option {opt spec:test}).{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt alpha:only}}Do only display coefficient estimates for the regression constant (or, "alpha") rather than all regression coefficients.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}
{p 4 6 2}
You must {helpb xtset} your data before using {opt xtgps}.{p_end}
{p 4 6 2}
{opt by} and {opt statsby} may be used with {opt xtgps}; see {help prefix}.{p_end}
{p 4 6 2}{opt aweight}s are allowed unless option {opt re} is specified; see {help weight}.{p_end}


{title:Description}

{p 4 4 2}
{opt xtgps} estimates the GPS-regression model proposed by Hoechle, Schmid, and 
Zimmermann (2024, henceforth abbreviated as {it:HSZ}) in their working paper 
"Does Unobservable Heterogeneity Matter for Portfolio-Based Asset Pricing Tests?".
The GPS-regression model constitutes a regression-based methodology for analyzing 
asset returns. The technique easily handles multiple dimensions and continuous 
firm, fund, or investor characteristics. The method allows for investigating the 
cross-section versus time-series predictability of stock returns, and it offers 
a framework for formal tests of competing specifications. The GPS-model nests 
conventional portfolio sorts (where assets are sorted into portfolios based on 
one or more characteristics) as a special case. Estimation results therefore have
a straightforward economic interpretation.{p_end}

{p 4 4 2}
Estimating the GPS-regression model with option {opt vce:type} being set to 
{opt vce:type(spatial)} (the default value) yields standard error estimates which 
are heteroscedasticity consistent and robust to general forms of cross-sectional 
and temporal dependence. When the {opt vce:type} is differently specified, then the 
standard error estimates tend to be overly optimistic - at least when cross-sectional 
dependence is present in the data which is likely for microeconometric panels.{p_end}

{p 4 4 2}
 The GPS-model contains up to four types of explanatory variables:{p_end}
 
{pmore}
 1) The {opt subjectvars} contain subject (i.e. firm, fund, individual investor, etc.) 
 specific characteristics. These variables are allowed to vary across both the 
 cross-sectional dimension as well as over time. In the notation of {it:HSZ}, 
 the subject characteristics form the z-vector.{p_end}

{pmore}
 2) The {opt tsvars} change over time but do not vary across subjects. In {it:HSZ}'s 
 notation, these market level variables (together with a constant that is 
 automatically added) form the x-vector.{p_end}

{pmore}
 3) A full set of {opt interaction variables} between the {it:subjectvars} and 
 the {it:tsvars}. The {opt xtgps} program automatically generates the interaction 
 terms.{p_end}

{pmore}
 4) Finally, one may also include {opt controlvars} in the regression. The 
 {opt controlvars} may vary over time and/or across subjects. This variable type
 is not covered in {it:HSZ}'s original research.{p_end}

{p 4 4 2}
The {opt xtgps} program works for both balanced and unbalanced panels. 
Furthermore, it is capable to handle missing values and gaps.{p_end}


{title:Options}

{dlgtab:Model}

{phang}
{opt tsv:ars(varlist)} contains the variables of the factor model. Popular choices 
for these market level variables are the Fama and French (1993, 2015) or Carhart 
(1997) factors. The {opt tsv:ars(varlist)} variables are constant across subjects; 
they only vary over time. - If option {opt tsv:ars} is not provided, then the
x-vector just comprises a constant, and the GPS-regression model results in 
analyzing (excess) returns rather than risk-adjusted performance.

{phang}
{opt cont:rolvars(varlist)} are explanatory variables which are not part of the 
performance measurement model. For these variables, no interactions with the 
{opt tsvars} are created. Typically, this option is used to perform robustness 
checks.

{phang}
{opt lag(#)} specifies the maximum number of lags to be considered in the 
autocorrelation structure. If you do not specify this option, a lag length of 
H(T)=floor[4(T/100)^(2/9)] is chosen. Here, T denotes the number of distinct 
time periods.

{phang}
{opt noc:onstant}; see {help estimation options:[R] estimation options}. If this
option is set, then the z-vector just comprises the {it:subjectvar(s)} without 
a constant. Option {opt noc:onstant} is useful for estimating with the 
GPS-regression model (a set of) portfolio sorts. In this case, the {it:subjectvars} 
should be dummy variables defining the (e.g. quintile or decile) portfolios or 
subject group portfolios.

{phang}
{opt ase} returns asymptotic Driscoll-Kraay standard errors (i.e. Driscoll-Kraay 
standard errors without a small sample adjustment).

{phang}
{opt fe} estimates the GPS-model by aid of the fixed effects (within) estimator 
rather than with pooled OLS/WLS. If {opt fe} is chosen, then it is impossible to 
estimate the regression without a constant (i.e. option {opt noc:onstant} is not 
allowed together with option {opt fe}).

{phang}
{opt re} estimates the GPS-model by aid of the GLS random effects estimator 
rather than with pooled OLS/WLS. If {opt re} is chosen, then it is impossible to 
estimate the regression without a constant (i.e. option {opt noc:onstant} is not 
allowed together with option {opt re}). Moreover, weights are not allowed with 
{opt re} estimation.

{phang}
{opt vce:type(vcetype)} specifies how to compute the standard errors for the 
coefficient estimates. The following {opt vcetypes} are allowed: {opt mod:el} 
applies the covariance matrix estimator derived from the regression model.
Choosing {opt r:obust} computes heteroscedasticity consistent or so-called White 
standard errors. Specifying {opt cl:uster} yields panel robust or clustered 
standard errors. These standard errors are sometimes also referred to as Arellano 
standard errors. If {opt cl:uster} is chosen, then the {opt xtgps} program 
automatically selects the cross-sectional identifier specified in {opt xtset} 
to be the cluster variable. {opt boot:strap} provides bootstrapped standard 
errors and {opt jack:nife} computes jacknifed standard errors. Finally, choosing 
{opt spat:ial} or ommitting option {opt vcetype} yields Driscoll and Kraay (1998) 
standard errors. These standard errors are heteroscedasticity consistent and 
robust to very general forms of cross-sectional and temporal dependence. 
{it:HSZ} show that the (two-stage) portfolio sorts approach essentially replicates 
Driscoll and Kraay (1998) standard errors.


{dlgtab:GPS-model specification test}

{phang}
{opt spec:test} performs the GPS-model specification test proposed in {it:HSZ}).
The test can also be used to test for the validity of portfolio sorts comparing 
the performance of two portfolios such as the top and bottom portfolio of stocks 
sorted w.r.t. a firm characteristic.

{pmore}
The GPS-model specification test implements a Hausman (1978)-type test by aid of 
the auxiliary regression procedure in Wooldridge (2010, Section 10.7.3). The 
specification test thereby proceeds along the following steps:

{pmore}
1. For each explanatory variable in the GPS-model, it is checked whether the 
variable varies over both time and the cross-section. For all variables for which
this is the case, an additional variable containing subject-specific time averages 
is constructed.

{pmore}
2. Estimation of the GPS-model including the variables generated in step 1 before.
Thereby, the time-averages are added to the model as {opt cont:rolvars}. By default,
the extended GPS-model is estimated with pooled OLS/WLS. However, if option  
{opt re} is chosen, then the extended GPS-model is estimated with the FGLS
RE estimator.

{pmore}
3. Validity of the random effects (RE) assumption is finally tested by performing
a (robust) Wald test on the null hypothesis that all the coefficient
estimates on the time average variables (from step 2 above) are equal to zero.

{phang}
{opt not:able} only displays the result from the Wald-test of the GPS-model 
specification test (i.e. the regression results on which the Wald-test is based
are not displayed). Note that option {opt not:able} requires option 
{opt spec:test} to be set.


{dlgtab:Reporting}

{phang}
{opt level(#)}; see {help estimation options##level():estimation options}.

{phang}
{opt alphaonly} only displays the {opt subjectvars} and the {opt controlvars}. 
By default, the {opt xtgps} program lists all regression coefficients, i.e. also 
the coefficient estimates for the {opt tsvars} and those for the 
{opt interaction terms}.


{title:Examples}


{phang}
For meaningful examples on how to apply program {opt xtgps}, see the tutorial 
contained in do-file {opt "GPS-Model Tutorial.do"}. The respective do-file comes along 
with {opt xtgps} as an ancillary file.

{phang}{stata "webuse grunfeld" : . webuse grunfeld}{p_end}
{phang}{stata "by year, sort: egen tvar = mean(invest - kstock + mvalue/10)" : . by year, sort: egen tvar = mean(invest - kstock + mvalue/10)}{p_end}
{phang}{stata "xtgps invest mvalue kstock, tsvar(tvar) lag(2)" : . xtgps invest mvalue kstock, tsvar(tvar) lag(2)}{p_end}
{phang}{stata "xtgps invest mvalue kstock, tsvar(tvar) vcetype(cluster) re alphaonly" : . xtgps invest mvalue kstock, tsvar(tvar) vcetype(cluster) re alphaonly}{p_end}
{phang}{stata "xtgps invest mvalue kstock, tsvar(tvar) spec" : . xtgps invest mvalue kstock, tsvar(tvar) spec}{p_end}


{title:References}

{p 4 6 2}
 - Carhart, M., 1997, On Persistence in Mutual Fund Performance,
 			 {it:Journal of Finance} 52, 57-82.{p_end}

{p 4 6 2}
 - Driscoll, J. and A. Kraay, 1998, Consistent Covariance Matrix
       Estimation with Spatially Dependent Panel Data, {it:Review of Economics and Statistics}
       80, 549-560.{p_end}
       
{p 4 6 2}
 - Fama, E. and K. French, 1993, Common Risk Factors in the Returns of Bonds
 				and Stocks, {it:Journal of Financial Economics} 33, 3-56.{p_end}
				
{p 4 6 2}
 - Fama, E. and K. French, 2015, A five-factor asset pricing model, 
   {it:Journal of Financial Economics} 116, 1-22.{p_end}
       
{p 4 6 2}
 - Hoechle, D., M. Schmid, and H. Zimmermann, 2024, Does Unobservable Heterogeneity Matter for 
        Portfolio-Based Asset Pricing Tests?, {it:Working Paper} (dx.doi.org/10.2139/ssrn.3190310).{p_end}
 			 

{title:Notes}

{p 4 6 2}
- For {cmd:xtgps} to work, my {cmd:xtscc} program and Ben Jann's {cmd:estout} package need to be installed.

{title:Author}

{p 4 4}Daniel Hoechle, FHNW Business School, daniel.hoechle@fhnw.ch{p_end}



{title:Also see}

{psee}
Manual:  {bf:[R] regress}, {bf:[XT] xtreg}

{psee}
Online:  {help xtscc}, {help xtscc postestimation};{break}
{helpb xtset}, {helpb regress}, {helpb xtreg}, {helpb _robust}
{p_end}

