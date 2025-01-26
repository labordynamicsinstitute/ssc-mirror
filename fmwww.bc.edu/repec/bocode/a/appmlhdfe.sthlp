{smcl}
{* *! version 1.0 - 09 Jan 2025}{...}
{cmd: help appmlhdfe}

{hline}

{title:Title}

{p2colset 8 21 23 0}{...}
{p2col :{cmd: appmlhdfe} {hline 2}}Asymmetric Poisson regression with high dimensional fixed effects{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:appmlhdfe}
{depvar}
{indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}


{synopt:{opt e:xpectile(#)}}estimate # expectile; default is expectile(.5) which corresponds to the conditional mean estimated by Poisson regression.{p_end}

{synopt :{opth a:bsorb(ppmlhdfe##absvar:absvars)}}categorical variables to be absorbed (fixed effects). Note that, unlike in {cmd: ppmlhdfe}, it is not possible to save separately save the estimates of each absorbed variable.

{synopt :{opth sep:aration(string)}}algorithm used to drop 
{browse "http://scorreia.com/research/separation.pdf":separated} observations and their associated regressors as in {help ppmlhdfe}. 
Valid options are {it:fe}, {it:ir}, {it:simplex}, and {it:mu} (or any combination of those).
Although {it:ir} (iterated rectifier) is the only one that can systematically correct separation arising from both regressors and fixed effects, by default the first three methods are applied ({it: fe simplex ir}).
See the {browse "http://scorreia.com/research/ppmlhdfe.pdf":ppmlhdfe paper} as well as {browse "https://github.com/sergiocorreia/ppmlhdfe/blob/master/guides/separation_primer.md":this guide} for more information.{p_end}

{synopt:{opt vce}{cmd:(}{help ppmlhdfe##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be {opt r:obust} (default) or {opt cl:uster} {help fvvarlist} (allowing two- and multi-way clustering).{p_end}

{synopt:{opth start(varname)}}vector of residuals to be used as starting values; see example below.{p_end}

{synopt:{opth res:idual(varname)}}saves the residuals as {it: varname}; see example below. {p_end}

{synopt:{opt st:rict}}check for separation in every iteration; by default, separated observations are dropped after the initial regression, and there are no further checks for separation.{p_end}

{synopt:{opt tol:erance}}tolerance used to determine convergence; the default is 1e-7.{p_end}

{synopt:{opt iter:ate}}maximum number of iterations; the default is 50.{p_end}

{synopt:{opt maxiter}}maximum number of iterations in each ppmlhdfe step; the default is 200.{p_end}

{synopt:{opt nolog}}suppress the display of the iteration log.{p_end}


{hline}

{marker weight}{...}
{p 4 6 2}{opt weights} are not allowed in the current version.{p_end}
 

{title:Description}

{pstd}
{cmd: appmlhdfe} estimates conditional expectiles using Efron's (1992) asymmetric Poisson maximum likelihood estimator; 
the expectiles are assumed to be an exponential function of a linear index, just like in standard Poisson regression. By 
default, the expectile 0.5 is estimated, which corresponds to Poisson regression.

{title:Acknowledgements}

{pstd}
{cmd: appmlhdfe} is based on the powerful {cmd: ppmlhdfe} command by Correia et al. (2019); {cmd: ppmlhdfe} needs to be installed for {cmd: appmlhdfe} to run. 


{title:Remarks}

{pstd}
{cmd: appmlhdfe} is not an official Stata command and was written by Matthew Clance and J.M.C. Santos Silva. 
For further help and support, please contact jmcss@surrey.ac.uk. Please notice that this software is provided 
as is, without warranty of any kind, express or implied, including but not limited to the warranties of 
merchantability, fitness for a particular purpose and noninfringement. In no event shall the author be liable 
for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, 
out of or in connection with the software or the use or other dealings in the software.


{title:Example}

 {hline}
{pstd}Load data{p_end}
{phang2}{stata sysuse auto, clear}{p_end}

{pstd}Basic use of {cmd: appmlhdfe} to estimate different expectiles{p_end}
{phang2}{stata appmlhdfe price mpg, a(rep78 foreign) e(.1)}{p_end}
{phang2}{stata appmlhdfe price mpg, a(rep78 foreign) e(.9)}{p_end}

{pstd}Use of {cmd: appmlhdfe} to estimate the 0.90 expectile, starting from the results of the estimation of the 0.85 expectile {p_end}
{phang2}{stata appmlhdfe price mpg, a(rep78 foreign) e(.85) res(r)}{p_end}
{phang2}{stata appmlhdfe price mpg, a(rep78 foreign) e(.9) start(r)}{p_end}



{title:Saved results}

{pstd}
The output saved in {cmd:e()} by {cmd:appmlhdfe} is essentially the same that is saved by {cmd:ppmlhdfe}; more details can be seen in {help ppmlhdfe}. Some additional results are listed below.


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(Q)}}final value of the objective function (must be smaller than {opt tolerance}){p_end}
{synopt:{cmd:e(negative)}}percentage of negative residuals{p_end}
{synopt:{cmd:e(R2)}}R-squared, computed as the square of the correlation between the dependent variable and its fitted values{p_end}


{title:References}

{phang}
Correia, S., Guimaraes, P., & Zylkin, T. (2020). 
{browse "https://doi.org/10.1177/1536867X20909691":Fast Poisson Estimation with High-dimensional Fixed Effects}, 
Stata Journal 20(1), 95-115.{p_end}

{phang}
Efron, B. (1992). 
{browse "https://www.jstor.org/stable/2290457":Poisson Overdispersion Estimates Based on the Method of Asymmetric Maximum Likelihood}, 
{it:Journal of the American Statistical Association}, Vol. 87, No. 417, 98-107. {p_end}


{center: Last modified on 9 January 2025}
