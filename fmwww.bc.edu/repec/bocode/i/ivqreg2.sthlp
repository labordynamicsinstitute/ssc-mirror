{smcl}
{* *! version 1.5 4 Mar 2023}{...}
{cmd:help ivqreg2} 

{hline}

{title:Title}

{p2colset 8 19 19 2}{...}
{p2col :{cmd: ivqreg2} {hline 2}}Structural quantile function estimation{p_end}
{p2colreset}{...}


{title:Syntax}

{phang}

{p 8 13 2}
{cmd:ivqreg2} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]


{synoptset 25 tabbed}{...}
{marker options}{...}
{synopthdr :options}
{synoptline}

{synopt :{opt q:uantile(#[#[# ...]])}}estimate {it:#} quantile; default is {cmd:quantile(.5)}{p_end}

{synopt :{opt inst:ruments(varlist)}}list of instruments, including control variables; by default no instruments are 
used and restricted quantile regression is performed{p_end}

{synopt :{opt ls}}displays the estimates of the location and scale parameters{p_end}

{synopt :{opt mu:sigma}}uses a simpler method to choose the starting values; this was the default in earlier versions{p_end}

{synopt:{it:{help ivqreg2##gmm_options:gmm options}}}{cmd: gmm} options to control the maximization process{p_end}

{synoptline}
{p2colreset}{...}

{phang}{cmd:ivqreg2} does not allow {cmd:weight}s.{p_end}


{title:Description}

{pstd}
{cmd:ivqreg2} estimates the structural quantile functions defined by Chernozhukov and Hansen (2008) using the method of Machado and Santos Silva (2019). If no instruments are
specified, {cmd:ivqreg2} estimates the regression quantiles imposing the restriction that quantiles do not cross (see also of He, 1997).


{marker options}
{title:Options}

{phang}{opt quantile(#[#[# ...]])} specifies the quantile to be estimated and should be
a number strictly between 0 and 1. The default value of 0.5 corresponds to the median.
The quantiles can be specified as a list, in which case estimation will be performed
for each quantile.

{phang}{opt instruments(varlist)} list of instruments, including control variables; by default no instruments are 
used and restricted quantile regression is performed{p_end}

{phang}{opt ls} displays the estimates of the location and scale parameters{p_end}

{phang}{opt musigma} uses a simpler method to choose the starting values and allows the replication of the results obtained with earlier versions of the commanad{p_end}

{marker gmm_options}{...}
{phang}
{it:gmm options}:
{opt one:step},
{opt two:step},
{opt quickd},
{opt winitial(string)},
{opt tech:nique(string)},
{opt conv_maxiter(#)},
{opt tracelevel(string)},
{opt conv_ptol(#)},
{opt conv_vtol(#)},
{opt conv_nrtol(#)},
{opt from(init_specs)}; see {manhelp gmm R} for more details.

{title:Remarks}

{pstd}
{cmd: ivqreg2} was written by J.A.F. Machado and J.M.C. Santos Silva and it is not an 
official Stata command. For further help and support, please contact jmcss@surrey.ac.uk. Please notice 
that this software is provided as is, without warranty of any kind, express or implied, including but 
not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. 
In no event shall the authors be liable for any claim, damages or other liability, whether in an action 
of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other 
dealings in the software.


{title:Examples}

    {hline}
{pstd}Setup: import Kathryn Graddy's fish data{p_end}        
{cmd:. import delimited "https://tinyurl.com/Graddy-data"}

{pstd}Structural quantile functions for a range of quantiles using stormy and rainy as instruments for price{p_end}
. {stata ivqreg2 qty price, inst(stormy rainy) q(0.15 .25 .5 .75 .85)}

{pstd}Same regression as above but including day dummies as controls{p_end}
. {stata ivqreg2 qty price day*, inst(stormy rainy day*) q(0.15 .25 .5 .75 .85)}

{pstd}Structural median using stormy as an instrument for price; location and scale estimates are reported{p_end}
. {stata ivqreg2 qty price, inst(stormy) ls}

{pstd}Restricted regression quantiles for a range quantiles{p_end}
. {stata ivqreg2 qty price,  q(0.1(0.1).9)}

    {hline}


{title:Saved results}

{pstd}
When only one quantile is estimated, {cmd:ivqreg2} saves the following results in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(Q)}}GMM criterion{p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 otherwise{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ivqreg2}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}covariance matrix{p_end}
{synopt:{cmd:e(q)}}estimated quantile of the scaled errors{p_end}
{synopt:{cmd:e(b_location)}}location-coefficients vector{p_end}
{synopt:{cmd:e(V_location)}}location-coefficients covariance matrix{p_end}
{synopt:{cmd:e(b_scale)}}scale-coefficients vector{p_end}
{synopt:{cmd:e(V_scale)}}scale-coefficients covariance matrix{p_end}


{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{pstd}
If multiple quantiles are estimated, {cmd:ivqreg2} also saves b, V, and q for each quantile with names of the form (for the first quartile) e(b_25), e(V_25), and e(q_25). In this case, the matrices e(b), e(V), and e(q) contain the results for the last estimated quantile.


{title:References}

{phang} Chernozhukov, V. and Hansen, C. (2008). "{browse "http://www.sciencedirect.com/science/article/pii/S0304407607001455":Instrumental Variable Quantile Regression: A Robust Inference Approach}," {it: Journal of Econometrics}, 142, 379-398.{p_end}

{phang} He, X. (1997). "{browse "http://www.tandfonline.com/doi/abs/10.1080/00031305.1997.10473959":Quantile Curves Without Crossing}," {it: The American Statistician}, 51, 186-192.{p_end} 
{phang} Machado, J.A.F. and Santos Silva, J.M.C. (2019), {browse "https://doi.org/10.1016/j.jeconom.2019.04.009":Quantiles via Moments}, {it: Journal of Econometrics}, 213(1), pp. 145-173.{p_end} 

{title:Also see}

{psee}
Manual:  {manlink R gmm}

