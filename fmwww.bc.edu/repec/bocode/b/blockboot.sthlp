{smcl}
{* *! version 1 06dec2024}{...}
{cmd:help blockboot}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col :{hi:blockboot} {hline 2}}Block bootstrap for dependent time series{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 13 2}
{cmd:blockboot} {varlist} {ifin} {cmd:,}
{opt type(string)}
{opt pre:fix(string)}
{opt lblock:(string)}
[  {opt seed(integer)}
]

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:blockboot}; see {manhelp tsset TS}.{p_end}
{p 4 6 2}
{it:varlist} contains the list of variables to be bootstrapped.{p_end}
{p 4 6 2}

{title:Description}

{pstd}
{cmd:blockboot} implements four bootstrap schemes for dependent time series data:

{phang2}{bf:nbb}: Nonoverlapping block bootstrap of observations; see Carlstein (1986){p_end}

{phang2}{bf:mbb}: Moving block bootstrap of observations; see K{c u:}nsch (1989) and Liu and Singh (1992){p_end}

{phang2}{bf:cbb}: Circular block bootstrap of observations; see Politis and Romano (1992){p_end}

{phang2}{bf:sbb}: Stationary block bootstrap of observations; see Politis and Romano (1994){p_end}

{title:Options}

{phang}
{opt type} must be used to choose among the four block bootstrap schemes implemented by {cmd: blockboot}, namely {opt nbb} for nonoverlapping block bootstrap, {opt mbb} for moving block bootstrap, {opt cbb} for circular block bootstrap, and {opt sbb} for the stationary block bootstrap. This is a required option. 
  
{phang}
{opt prefix} can be used to provide a `stub' with which variables created in {cmd: blockboot} will be named.
These variables must not already exist in memory.
This is a required option. 

{phang}
{opt lblock} sets the length of the block of observations to bootstrap. Note that in the case of {opt sbb}, {opt lblock} corresponds to the average length of the blocks. 
Setting {opt lblock} equal to 1 yields the simple bootstrap, suitable for time independent processes, while {opt lblock} greater than 1 is suitable for time dependent processes. {opt lblock} can also be specified as {opt auto}, which triggers the optimal blocklength selection mechanism following Politis and White (2004), Patton et al. (2009) and Politis and Romano (1995). This is a required option. 

{phang}
{opt seed} sets the seed for random number generation in the bootstrap results. 

{title:Example of use}

{pstd}
We illustrate the use of the {cmd:blockboot} command using generated data. To facilitate the visualisation of the resulting bootstrapped version of the series, the variables x1 and x2 are linear trends with different initial conditions.{p_end}

{phang2}{bf:. {stata "clear all":clear all}}{p_end}

{phang2}{bf:. {stata "set obs 40":set obs 40}}{p_end}

{phang2}{bf:. {stata "gen t = _n":gen t = _n}}{p_end}

{phang2}{bf:. {stata "tsset t":tsset t}}{p_end}

{phang2}{bf:. {stata "gen x1 = t + 100":gen x1 = t + 100}}{p_end}

{phang2}{bf:. {stata "gen x2 = t + 1000":gen x2 = t + 1000}}{p_end}

{pstd}
We would like to bootstrap x1 and x2,  using a circular bootstrap where the length of each block of observations is equal to 12. To replicate the bootstrap random draws the seed is provided. The prefix option is used to generate the bootstrapped versions of the variables  as cx1 and cx2.{p_end}

{phang2}{bf:. {stata "blockboot x*, type(cbb) prefix(c) lblock(12) seed(987)":blockboot  x*, type(cbb) prefix(c) lblock(12) seed(987)}}{p_end}

{pstd}
To bootstrap using automatic selection of the block length:{p_end}

{phang2}{bf:. {stata "blockboot x*, type(cbb) prefix(ac) lblock(auto) seed(987)":blockboot  x*, type(cbb) prefix(ac) lblock(auto) seed(987)}}{p_end}

{pstd}
To bootstrap a subset of the original data:{p_end}

{phang2}{bf:. {stata "blockboot x* if tin(11,35), type(cbb) prefix(cc) lblock(12) seed(987)":blockboot  x* if tin(11,35), type(cbb) prefix(cc) lblock(12) seed(987)}}{p_end}

{pstd}
Next, we would like to draw 50 bootstrap replications of the variable x1. In this example, we use a stationary bootstrap with an average length of the blocks of observations equal to 12. The prefix option is used to generate the bootstrapped versions of the variable x1 as s1x1, s2x1, ..., and s50x1:{p_end}

{p 4 4 2}{cmd:. forvalues i = 1/50 {c -(}}{break} 
         {cmd:. {space 8}blockboot x1, type(sbb) prefix(s`i') lblock(12) seed(`=`i'+987')}{break} 
         {cmd:. {c )-}} 

{title:References}

{phang}
Carlstein, E. (1986). The use of subseries methods for estimating the variance of a general statistic from a stationary time series. The Annals of Statistics 14(3), 1171-1179.

{phang}
K{c u:}nsch, H. R. (1989). The jackknife and the bootstrap for general stationary observations. The Annals of Statistics 17, 1217-1261.

{phang}
Liu, R. Y. and Singh, K. (1992). Moving blocks jackknife and bootstrap capture weak dependence, in R. Lepage and L. Billard, eds, 'Exploring the Limits of the Bootstrap', Wiley, New York, pp. 225-248.

{phang}
Patton, A., Politis, D. N. and White, H. (2009). Correction to "automatic block-length selection for the dependent bootstrap" by D. Politis and H. White. Econometric Reviews 28(4), 372–375

{phang}
Politis, D. N. and Romano, J. P. (1992). A circular block resampling procedure for stationary data, in R. Lepage and L. Billard, eds, 'Exploring the Limits of Bootstrap', Wiley, New York, pp. 263-270.
 
{phang} 
Politis, D. N. and Romano, J. P. (1994). The stationary bootstrap. Journal of the American Statistical Association 89(428), 1303-1313.

{phang}
Politis, D. N. and Romano J. P. (1995). Bias-corrected nonparametric spectral estimation. Journal of Time Series Analysis 16(1), 67–103.

{phang}
Politis, D. N. and White, H. (2004). Automatic block-length selection for the dependent bootstrap. Econometric Reviews 23(1), 53–70.

{title:Authors}

{pstd}
Christopher F Baum{break}
Boston College{break}
Chestnut Hill, MA USA{break}
baum@bc.edu{p_end}

{pstd}
Jes{c u'}s Otero{break}
Universidad del Rosario{break}
Bogot{c a'}, Colombia{break}
jesus.otero@urosario.edu.co{p_end}
