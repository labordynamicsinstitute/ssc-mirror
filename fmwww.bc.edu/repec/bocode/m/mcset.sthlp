{smcl}
{* *! version 1 04jul2026}{...}
{cmd:help mcset}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col :{hi:mcset} {hline 2}}The Model Confidence Set (MCS){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 13 2}
{cmd:mcset} {varlist} {ifin}{cmd:,}
{opt typeboot(string)}
{opt typeloss(string)}
{opt lblock(integer)}
[ {opt bootdraws(integer)} 
  {opt alpha(real)}
  {opt stat(string)}
  {opt seed(integer)}
]

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:mcset}; see {manhelp tsset TS}. There must not be gaps in the time series. Time-series operators are not supported.{p_end}
{p 4 6 2}
{it:varlist} is a list of variables, the first of which is the actual series, and the 
following variables are forecasts from alternative models. At least two forecast series must be provided.{p_end}
{p 4 6 2}

{title:Description}

{pstd}
The {cmd:mcset} command implements
the Model Confidence Set (MCS) procedure of Hansen, Lunde, and Nason (2011), which
provides a formal way to ask which forecasting models are statistically distinguishable
from the best-performing alternatives. The main output of the procedure is not a single
“winner”, but a set of models that cannot be rejected as having superior predictive
ability at a chosen confidence level. The algorithm is based on the implementation in R provided by
Catania (2026), first described by Bernardi and Catania (2014) and the block bootstrap schemes of Baum and Otero (forthcoming).

{cmd:mcset} implements three block bootstrap schemes for dependent time series data:

{phang2}{bf:mbb}: Moving block bootstrap of observations; see K{c u:}nsch (1989) and Liu and Singh (1992){p_end}

{phang2}{bf:cbb}: Circular block bootstrap of observations; see Politis and Romano (1992){p_end}

{phang2}{bf:sbb}: Stationary block bootstrap of observations; see Politis and Romano (1994){p_end}

{title:Options}

{phang}
{opt typeboot} must be used to choose among the three block bootstrap schemes implemented by {cmd: mcs}. 

{phang}
{opt typeloss} must be used to choose among the four loss functions: {bf:rmse} for root mean square
error, {bf:mae} for mean absolute error, {bf:mape} for mean absolute percentage error, and
{bf:qlike} for the quasi-likelihood loss,  log h + sigma^2/h.

{phang}
{opt lblock} sets the length of the block of observations to bootstrap. Note that in the case of {opt sbb}, {opt lblock} corresponds to the average length of the blocks. 
Setting {opt lblock} equal to 1 yields the simple bootstrap, suitable for time independent processes, while {opt lblock} greater than 1 is suitable for time dependent processes. 
If {opt lblock} is set to zero, the auto-blocklength mechanism following Politis and White (2004), Patton et al. (2009) and Politis
        and Romano (1995) is employed. In that case, an optimal blocksize for each forecast series is computed, but the maximum of hose
        values is used in the bootstrap for all forecast series. The optimal blocksize values are returned in the blklen matrix.

{phang}
{opt bootdraws} specifies the number of block bootstrap repetitions. If not specified, it is set to 100.

{phang}
{opt alpha} specifies the significance level to be used in defining the MCS. If not specified, it defaults to 0.10. 

{phang}
{opt stat} specifies the test statistic, which can be TR or Tmax. If not specified, the routine computes TR.

{phang}
{opt seed} sets the seed for random number generation in the bootstrap results to produce reproducible results. 

{title:Stored results}

Scalars
{phang2} {bf:r(N_included)} Number of models included in MCS {p_end}
{phang2} {bf:r(N_excluded)} Number of models excluded from MCS {p_end}
{phang2} {bf:r(N_models)} Number of models evaluated {p_end}
{phang2} {bf:r(lblock)} Blocksize {p_end}
{phang2} {bf:r(bootdraws)} Number of bootstrap repetitions {p_end}
{phang2} {bf:r(N)} Number of observations {p_end}

Macros
{phang2} {bf:r(excluded)} Model names for those excluded from MCS {p_end}
{phang2} {bf:r(included)} Model names for those included in MCS {p_end}
{phang2} {bf:r(typeboot)} Bootstrap scheme {p_end}
{phang2} {bf:r(typeloss)} Loss function {p_end}
{phang2} {bf:r(stat)} Test statistic {p_end}
{phang2} {bf:r(predicted)} Model names of the predicted series, in reverse order of average loss {p_end}
{phang2} {bf:r(actual)} Name of the actual series {p_end}
{phang2} {bf:r(cmdname)} Command name {p_end}

Matrices
{phang2} {bf:r(mcsres)} Result matrix {p_end}
{phang2} {bf:r(blklen)} Block length {p_end}

{title:Example of use}

{pstd}
We illustrate the use of the {cmd:mcs} command using generated data. {bf:ssc install bcuse} if needed. {p_end}

{phang2}{bf:. {stata "bcuse mcsdata2":bcuse mcsdata2}}{p_end}

{phang2}{bf:. {stata "summarize":summarize}}{p_end}

{pstd}
In these data, y is the actual series, and the m* series are forecasts of y from
different models. By construction, models A, C, E and G are more divergent from y. {p_end}

{phang2}{bf:. {stata "mcset y m*, typeboot(cbb) typeloss(rmse) lblock(12) bootdraws(1000)":mcset y m*, typeboot(cbb) typeloss(rmse) lblock(12) bootdraws(1000)}}{p_end}

{pstd}
The MCS--containing models with similar accuracy--includes the six other models, and excludes models
A, C, E and G.  {p_end}



{title:References}

{phang}
Baum, C. F., and J. Otero (2026). Bootstrapping time-dependent stationary processes.
The Stata Journal 26 (forthcoming).

{phang}
Bernardi, M., and L. Catania (2014). The Model Confidence Set package for R.
https://arxiv.org/abs/1410.8504.

{phang}
Catania, L. (2026). Package ‘MCS’. Technical report, CRAN. 
 https://search.r-project.org/CRAN/refmans/MCS/html/MCS-package.html

{phang}
Hansen, P. R., A. Lunde, and J. M. Nason (2005). Model confidence sets for forecasting
models. Working Paper 2005-07, Federal Reserve Bank of Atlanta, Atlanta, GA.

{phang}
Hansen, P. R., A. Lunde, and J. M. Nason (2011). The model confidence set. Econometrica 79(2): 453–497.

{phang}
K{c u:}nsch, H. R. (1989). The jackknife and the bootstrap for general stationary observations. The Annals of Statistics 17, 1217-1261.

{phang}
Liu, R. Y. and Singh, K. (1992). Moving blocks jackknife and bootstrap capture weak dependence, in R. Lepage and L. Billard, eds, 'Exploring the Limits of the Bootstrap', Wiley, New York, pp. 225-248.

{phang}
Patton, A., Politis, D. N. and White, H. (2009). Correction to "automatic block-length selection for the dependent bootstrap"
        by D. Politis and H. White. Econometric Reviews 28(4), 372–375

{phang}
Politis, D. N. and Romano, J. P. (1992). A circular block resampling procedure for stationary data, in R. Lepage and L. Billard, eds, 'Exploring the Limits of Bootstrap', Wiley, New York, pp. 263-270.
 
{phang} 
Politis, D. N. and Romano, J. P. (1994). The stationary bootstrap. Journal of the American Statistical Association 89(428), 1303-1313.

{phang}
    Politis, D. N. and Romano J. P. (1995). Bias-corrected nonparametric spectral estimation. Journal of Time Series Analysis
        16(1), 67–103.

{phang}
Politis, D. N. and White, H. (2004). Automatic block-length selection for the dependent bootstrap. Econometric Reviews 23(1),
        53–70.


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
