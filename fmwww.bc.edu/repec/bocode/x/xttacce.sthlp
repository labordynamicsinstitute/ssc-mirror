{smcl}
{* *! version 1.0 13 June 2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "xturtb##syntax"}{...}
{viewerjumpto "Description" "xturtb##description"}{...}
{viewerjumpto "Options" "xturtb##options"}{...}
{viewerjumpto "Remarks" "xturtb##remarks"}{...}
{viewerjumpto "Examples" "xturtb##examples"}{...}
{title:Title}
{phang}
{bf:xttacce} {hline 2} Time Averaged Common Correlated Effects estimator (TACCE) for fixed-N panel data and SUR, with interactive fixed effects in the errors (Westerlund, Kaddoura, and Karavias 2025).


{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:xttacce}
{depvar}
{indepvars}
[{help if}]
[{help in}]


{smcl}

{p 4 6 2}
at least one {indepvars} is required. Only strongly balanced panel is supported; see {helpb xtset:[XT] xtset}. 
{p_end}

{smcl}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 Time Averaged Common Correlated Effects estimator (TACCE) for fixed-N panel data and SUR, with interactive fixed effects in the errors. The idea is to use time averages of the observables to asymptotically purge the interactive fixed effects. 
These averages are included as additional regressors and the resulting augmented regression model is estimated by least squares. The estimator is developed in Westerlund, Kaddoura, and Karavias (2025).




{marker examples}{...}
{title:Examples}


{pstd}Load the data{p_end}
{phang2}{cmd: webuse grunfeld, clear} 

{pstd}Setup{p_end}
{phang2}{cmd: xtset company year} 

{pstd}Estimation without intercept{p_end}
{phang2}{cmd:xttacce invest mvalue kstock}

{pstd}Hypothesis test after estimation{p_end}
{phang2}{cmd: test kstock==mvalue==0}


{title:Stored results}

{pstd}
{cmd:xttacce} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:e(p_num)}}number of estimated coefficients{p_end}
{synopt:{cmd:e(fstat)}}F statistic for overall significance{p_end}
{synopt:{cmd:e(N)}}number of total observations{p_end}
{synopt:{cmd:e(T)}}number of time periods per panel{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Macros}{p_end}
{synopt:{cmd:e(cmd)}}name of command {p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}list of independent variables{p_end}
{synopt:{cmd:e(panelvar)}}panel id variable{p_end}
{synopt:{cmd:e(timevar)}}time variable{p_end}
{synopt:{cmd:e(properties)}}estimation result properties {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient estimates (1 × p row vector){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of estimates{p_end}
{synopt:{cmd:e(se)}}standard errors{p_end}
{synopt:{cmd:e(t)}}t statistics{p_end}
{synopt:{cmd:e(p)}}p-values for each coefficient{p_end}
{synopt:{cmd:e(ci_lb)}}lower bound of 95% confidence interval{p_end}
{synopt:{cmd:e(ci_ub)}}upper bound of 95% confidence interval{p_end}



{title:References}
{p}
{p_end}
{pstd}

Westerlund, J., Kaddoura, Y., and Karavias, Y., 2025. Time Averaged CCE. {browse "http://dx.doi.org/10.2139/ssrn.5274776":http://dx.doi.org/10.2139/ssrn.5274776}

{title:Acknowledgements}
{p}
{p_end}
{pstd}
{cmd:xttacce} is not an official Stata command. It is a free contribution to the research community. 


{title:Authors}
{p}
{p_end}

{pstd}
Pengyu Chen{break}
University of Chicago{break}
Chicago, U.S{break}
{browse "pengyu@uchicago.edu":pengyu@uchicago.edu}

