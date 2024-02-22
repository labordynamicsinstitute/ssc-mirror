{smcl}
{* *! version 1.0  16feb2024}{...}
{viewerdialog "mvfilter" "dialog mvfilter, message(-mvfilter-)"}{...}
{vieweralsosee "[TS] tsfilter hp" "mansection TS tsfilterhp"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "mvfilter" "help mvfilter"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] format" "help format"}{...}
{vieweralsosee "[TS] sspace" "help sspace"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "[TS] tssmooth" "help tssmooth"}{...}
{vieweralsosee "[TS] tsfilter hp" "help tsfilter hp"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "mvfilter##syntax"}{...}
{viewerjumpto "Description" "mvfilter##description"}{...}
{viewerjumpto "Options" "mvfilter##options"}{...}
{viewerjumpto "Technical remarks" "mvfilter##remarks"}{...}
{viewerjumpto "Example" "mvfilter##example"}{...}
{viewerjumpto "Stored results" "mvfilter##results"}{...}
{p2colset 1 21 23 2}{...}
{p2col:{bf:mvfilter} {hline 2}}Multivariate time-series filter. {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:mvfilter}
{help var:{it:var}}
[{help varlist:{it:varlist}}]
{ifin} [{cmd:,} {it:options}]
{p_end}


{synoptset 25 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt:{varlist}}contains exogenous variable(s) for the observed equation{p_end}

{synopt:{opt t:rend}({newvar})}save the trend component in new a variable{p_end}

{synopt:{opt c:ycle}({newvar})}save the cyclical component in a new variable{p_end}

{synopt:{opt ar:(#)}}specify the order of the autoregressive process in the cycle{p_end}

{synopt:{opt s:mooth(#)}}smoothing parameter for the filter{p_end}

{synopt:{opt ty:pe(string)}}specify the type of filter used{p_end}

{syntab:Other}
{synopt:{opt det:ails}}display the details of the Kalman filter estimation{p_end}

{synopt:{opt opt:imal}}let the Kalman filter estimate the smoothing parameter{p_end}

{synopt:{opt adj:ustment}}adjust the sample variance ratio of the dynamic filter
to match the static {bf:Hodrick-Prescott} filter{p_end}

{synopt:{opt l:oop}}display the convergence of the sample variance ratio of the 
dynamic filter to the static {bf:Hodrick-Prescott} filter{p_end}

{synopt:{opt beta:cap}}constraints the autoregressive parameter to 
min(beta,0.85). The default is unconstrained beta.
dynamic filter to the static {bf:Hodrick-Prescott} filter{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {opt tsset} your data before using {cmd:mvfilter};
see {manhelp tsset TS}.{p_end}
{p 4 6 2}
{it:var} and {it:varlist} may contain time series operators; see
{help tsvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mvfilter} uses the {cmd:sspace} high-pass filter to separate a
time series into trend and cyclical components.  The trend component may
contain a deterministic or a stochastic trend.  The smoothing parameter
determines the periods of the stochastic cycles that drive the stationary cyclical
component. It allows for and AR(p) process in the cyclical component and 
for exogenous variables in the observed equation of the {cmd:sspace} representation

{pstd}
See {manlink TS sspace} and {manlink TS tsfilter} for an introduction to the methods implemented in
{cmd:mvfilter}.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt varlist} the exogenous variables will only enter the observed equation. 
In this version on {cmd:mvfilter}, expoenous variables in the state equation are
not allowed.

{phang}
{cmd:trend(}{newvar}} saves the trend component in the new variable specified 
by {it:newvar}.

{phang}
{cmd:cycle(}{newvar}} saves the trend component in the new variable specified 
by {it:newvar}.
 
{phang}
{opt ar(#)} specifies the order 0<=p<=2 of the autoregressive process of the 
cycle component. The default is AR(0). In this case, the output matches 
the output of {cmd: tsfilter hp}. 

{phang}
{opt smooth(#)} sets the smoothing parameter for the filter. Unless specified, 
the Ravn-Uhlig (2002) rule is used to set the smoothing parameter. The smoothing 
parameter must be greater than 0.

{dlgtab:Other}

{phang}
{opt optimal} forces the Kalman filter to estimate the smoothing parameter.
This works only for AR(0) (see technical remarks). 

{phang}
{opt details} display the oytput of the Kalman filter estimation 

{phang}
{opt adjust} With AR(p) p>=1, a small sample problem is introduced. {opt adjusts}
adjusts the sample variance ratio of the cycle over change in the slope of 
the trend in the dynamic filter to match the sample variance ratio in the 
static HP filter following Borio et al. (2013 and 2014).

{phang}
{opt loop} returns the adjustment factor, the SS and HP sample variance ratios
for each iteration when the option {opt adjust} is specified.

{phang}
{opt betacap} is useful whan the cyclical compnent approaches a random walk and 
would converge to its mean only after very olong time.
 
{marker remarks}{...}
{title:Tecnical Remarks}

{phang}
{opt optimal} with AR(p>=1), you cannot specify {opt optimal}. This is due to the 
fact that {cmd:sspace} does not allow for non linear constraints. Indeed, in the 
case of AR(1), the joint estimation of {bf:lambda} and the AR parameter would 
require a linear constraint in the observed equation such that the parameter (beta1)
in front of the lagged observed variable is equal to minus the parameter in front of the 
lagged state variable and a non-linear constraint on variance ratio such that it is 
equal to lambda*(1-beta1^2). Because {cmd:sspace} cannot handle this second 
constraint, {opt option} is allowed only for the static filter
with AR(0).

{phang}
with AR(p>=1), {cmd:sspace} cannot estimate the autoregressive parameters.
These are estimated before by regressing the cyclycal component of the static 
filter with AR(0) on its lag(s) and then imposed as linear restriction(s) in the 
{cmd:sspace} representation. This is due again to the fact that {cmd:sspace} does
not allow for non-linear constraints. In order to have the Kalman filter estimate
the autregressive parameters, you need to impose a non liner restriction on the 
variance ratio of lambda*(1-beta1^2) in the case of AR(1) and 
lambda*(1-beta1^2-beta2^2) in the case of AR(2). 

{phang}
{opt loop} adjusts the sample variance ratio of the dynamic filter with p>=1 to
match the sample varance ratio of the static filter with p=0. The implementation 
comes from code used for a similar application in Berger et al. (2015).

{phang}
{opt smooth(#)} Unless specified, the smoothing parameter is set as a function of the
units of the time variable (daily, weekly, monthly, quarterly, half-yearly, 
or yearly) following Ravn and Uhlig (2002). The Ravn-Uhlig rule sets {it:#} to 
1600n^4, where n is the number of periods per quarter. 

{phang}
NB: if {cmd:mvfilter} fails to converge, there is no option to adjust the intial 
conditions. This is for future implementation. At present the only suggestion to
help convergence is to change sample.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse gdp2}{p_end}

{pstd}Use {cmd:mvfilter} to estimate the cyclical component of the log of 
quarterly U.S. GDP{p_end}
{phang2}{cmd:. mvfilter gdp_ln, cycle(cyc_ss)}{p_end}

{pstd}Use {cmd:mvfilter} to estimate the cyclical component of the log of 
quarterly U.S. GDP assuming an AR(1) in the cycle{p_end}
{phang2}{cmd:. mvfilter gdp_ln, cycle(cyc_ss) ar(1)}{p_end}

{pstd}Use {cmd:mvfilter} to estimate the cyclical component of the log of 
quarterly U.S. GDP assuming an AR(1) in the cycle and adjust the sample 
variance ratio{p_end}
{phang2}{cmd:. mvfilter gdp_ln, cycle(cyc_ss) ar(1) adj}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mvfilter} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(ar_p)}}Order of the autoregressive process in the cyclycal component{p_end}
{synopt:{cmd:r(var_ratio)}}Value of the variance ratio in the SS model{p_end}
{synopt:{cmd:r(lambda)}}Value of lambda in the SS model{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:r(type)}}Filter type{p_end}
{synopt:{cmd:r(unit)}}Time frequency unit{p_end}
{synopt:{cmd:r(obs_var)}}Observed variable{p_end}
{synopt:{cmd:r(exog_var)}}Exogenous variable(s){p_end}
{synopt:{cmd:r(cycle)}}Estimated cyclical component{p_end}
{synopt:{cmd:r(trend)}}Estimated trend component{p_end}


{marker references}{...}
{title:References}

{p 4 6 2}
Borio, C., P. Disyatat and M. Juselius. 2013. {browse "https://www.bis.org/publ/work404.htm":Rethinking potential output: Embedding information about the financial cycle}. {it:BIS Working Papers}, No 404.
  {p_end}

{p 4 6 2}
Borio, C., P. Disyatat and M. Juselius. 2014. {browse "https://www.bis.org/publ/work442.htm":A parsimonious approach to incorporating economic information in measures of potential output}. {it:BIS Working Papers}, No 442.
  {p_end}

{p 4 6 2}
Berger H., T. Dowling, S. Lanau, M. Mrkaic, P. Rabanal and M. Taheri Sanjani. 2015.
{browse "https://www.imf.org/en/Publications/WP/Issues/2016/12/31/Steady-as-She-Goes-Estimating-Potential-Output-During-Financial-Booms-and-Busts-43383":Steady as She Goes — Estimating Potential Output During Financial Booms and Busts}. 
{it:IMF Working Papers}, No 2015/233.
  {p_end}
  
{p 4 6 2}
Ravn, M.O and H Uhlig. 2002. {browse "https://doi.org/10.1162/003465302317411604":On Adjusting the Hodrick-Prescott Filter for the Frequency of Observations}. {it:The Review of Economics and Statistics}, 84(2): 371–376.
  {p_end}


{marker contact}{...}
{title:Author}

{pstd}
Gregorio Impavido{break}
International Monetary Fund{break}
Email: {browse "mailto:gimpavdo@imf.org":gimpavido@imf.org}{break}
SSRN: {browse "https://papers.ssrn.com/sol3/cf_dev/AbsByAuth.cfm?per_id=429651":https://papers.ssrn.com}.
{p_end}
