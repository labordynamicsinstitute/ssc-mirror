{smcl}
{* *! version 0.0.2  29sep2025}{...}
{hline}
help for {hi: gweakivtest}
{hline}

{title: A robust test for weak instruments for 2SLS with multiple endogenous regressors}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2} {cmdab:gweakivtest} [{cmd:,} {opt criterion(crit)} {opt target(targetname)} {opt retain(varname)} {opt alpha(#)} {opt tau(#)} {opt points(#)} {opt verbosity(#)}]

{synoptset 20 tabbed}{...}
{marker options}{...}
{synopthdr}
{synoptline}
{synopt: {opt criterion(crit)}}bias criterion to use, either rel or abs; default is abs{p_end}
{synopt: {opt target(targetname)}}target to use, either beta (entire parameter vector) or the coefficient corresponding to one of the endogenous variables; default is beta{p_end}
{synopt: {opt retain(varname)}}which endogenous variable to retain for Sanderson-Windmeijer (reduced rank) setting; omit for Stock-Yogo setting (default){p_end}
{synopt: {opt alpha(#)}}significance level; default is {opt alpha(0.05)}{p_end}
{synopt: {opt tau(#)}}bias tolerance; default is {opt tau(0.1)}{p_end}
{synopt: {opt points(#)}}number of starting points for the optimization step; default is {opt points(1000)}{p_end}
{synopt: {opt verbosity(#)}}level of run information displayed onscreen during execution; default is {opt verbosity(0)}{p_end}
{synopt: {opt noplugin}}requests that the secondary Mata-only implementation of the command is used{p_end}
{synopt: {opt procs(#)}}number of processors to run plugin code across; default is number of processors on machine{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{p 4 4 2}{cmd:gweakivtest} implements the robust weak instruments test of Lewis 
and Mertens (2025). It is a postestimation command for {cmd:ivreg2} and 
{cmd:ivregress}.

{p 4 4 2}{cmd:gweakivtest} tests the null hypothesis of weak instruments for 
two-stage least squares (2SLS) models with multiple endogenous regressors, 
generalizing existing bias-based tests for instrument strength in 2SLS models. 
Specifically, it (1) generalizes the bias-based tests for weak instrument of 
Stock and Yogo (2005) (developed under uniformly weak instruments) and Sanderson 
and Windmeijer (2016) (developed under a rank-deficient first-stage) to be 
robust to heteroskedasticity, autocorrelation and clustering (indeed, any form 
of covariance matrix), and (2) extends the Montiel Olea and Pflueger (2013) 
robust test for models with a single endogenous regressor (as implemented in 
{cmd:weakivtest}) to multiple endogenous regressors. Like that of Montiel Olea 
and Pflueger (2013), the test is based on a Nagar (1959) approximation of the 
bias of the 2SLS estimator. 

{p 4 4 2}The test rejects the null hypothesis when the generalized test 
statistic exceeds a critical value, which depends on the asymptotic covariance 
matrix of reduced-form and first-stage OLS coefficients, the desired 
significance level, alpha, and the desired bias tolerance threshold, tau. 
In models with a single endogenous regressor, the test-statistic and critical 
values are equivalent to Montiel Olea and Pflueger (2013), except in models 
with  one or two instruments. With one instrument, the critical values are based
on the median bias, since the mean bias does not exist. With two instruments, 
the Nagar approximation of the bias relied upon by both tests is potentially 
poor, suggesting a more conservative bound on the bias is preferable.

{p 4 4 2}Relative to all three papers, the test gives the option of testing for 
bias in a single coefficient, instead of the whole parameter vector. This can be 
controlled via the optional argument {opt target()}.

{p 4 4 2}Note that the test is not appropriate (and therefore {cmd:gweakivtest}
does not work) for estimation methods other than 2SLS. Note also that the test
only extends the bias-based test of Stock and Yogo (2005), not their size-based
test.

{p 4 4 2}Weighted 2SLS is supported, with the same weights used throughout the 
test as were specified in the original 2SLS regression. Small sample (degrees
of freedom) adjustments are made consistently with the original 2SLS regression,
i.e. if that regression included the {opt small} option.

{p 4 4 2}This implementation of the Lewis and Mertens (2025) test is a port 
of the original Matlab code written by the paper authors. The Stock and Yogo 
(2005) test for instrument strength is available in {cmd:ivreg2} and in the 
{cmd: ivregress} postestimation command {cmd:estat firststage}. The Montiel-Olea
and Pflueger (2013) test for instrument strength is implemented in 
{cmd:weakivtest}.

{p 4 4 2}Note: You must install {cmd:avar} by typing "ssc install avar" before running {cmd:gweakivtest}.


{marker options}{...}
{title:Options}

{phang}
{opt criterion(crit)} specifies the bias criterion to use, either abs (absolute) or rel
	(relative); the default is abs.

{phang}
{opt target(targetname)} specifies the target for the bias criterion, either beta (meaning the full vector of coefficients on all endogenous variables) or the name of a single endogenous variable; the
	default is beta.

{phang}
{opt retain(varname)} specifies which endogenous variable to retain for
	Sanderson-Windmeijer setting; omit for Stock-Yogo setting (default).

{phang}
{opt alpha(#)} specifies the significance level for the test, expressed as a 
   decimal; the default is {opt alpha(0.05)}.

{phang}
{opt tau(#)} specifies bias tolerance threshold, expressed 
   as a decimal; the default is {opt tau(0.1)}.

{phang}
{opt points(#)} specifies the number of starting points for the optimization
   step in computing the critical values; the default is {opt points(1000)}.

{phang}
{opt verbosity(#)} sets the level of runtime information displayed on screen 
   during execution. A value of 0 means no information; 1 means high-level 
   progress information is displayed; 2 adds information about progress of 
   top-level iterations; 3 displays line-by-line information about top-level 
   iterations; 4 reports detailed low-level information (for debugging). The 
   default is {opt verbosity(0)}.

{phang}
{opt noplugin} requests that the Mata-only implementation of the command is used
	and not the default compiled plugin; see technical details below.

{phang}
{opt procs(#)} specifies the number of processors to run plugin code across;
    the default is number of processors on the machine. Ignored if option
	{opt noplugin} specified.


{marker technical}{...}
{title:Technical details}

{p 4 4 2}There are two main parts to the code underlying the {cmd:gweakivtest} 
command: calculating the test statistic, and calculating the critical value. 
The former is not too computationally burdensome and is therefore implemented 
in Stata's matrix language, Mata. The latter, however, is much more 
computationally intensive and efficiency can be increased significantly using 
sparse matrices (which Mata doesn't have), so the primary implementation is as 
a plugin written in C++.

{p 4 4 2}Plugins are compiled code, so are platform-specific. We have provided 
versions for Windows, Linux and Mac (Apple and Intel silicon). The Windows 
version has been tested relatively extensively, while the versions for Linux and
Mac less so. Plugins can be somewhat fragile and have a tendency to bring Stata 
down with relatively little provocation. Apologies in advance if this happens to
you, and please let us know!

{p 4 4 2}To guard against problems with the plugin, we have included a secondary 
implementation of the critical value calculation entirely in Mata. This can be 
selected using the {opt noplugin} option. For relatively small problems, it 
tends to run quickly and terminate with moderately helpful error messages rather
than bringing Stata down. But it cannot handle even medium-sized cases due to 
memory requirements without sparse matrices, and will likely cause Stata to
seize up. So you know whether this is likely to happen, the command issues a
warning if the memory requirement is likely to be excessive and reports an
estimated execution time.

{p 4 4 2}The Mata-native implementation also has a second limitation. A key 
part of the algorithm involves solving a constrained optimization problem. Mata 
doesn't include routines for constrained optimization, so constraints have had 
to be imposed via a transformation of variables. This seems to work reasonably 
well but, in testing, we did find a number of instances where convergence is not
achieved or the solution deviates slightly from the one found by the plugin.
Convergence issues are flagged in the returned values but, for this reason, we 
prefer to rely on the results from the plugin.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{stata "webuse mroz" : . webuse mroz}{p_end}

{pstd}Run 2SLS using ivregress{p_end}
{phang2}{stata "ivregress 2sls lwage city (exper educ = age kidslt6 kidsge6 motheduc fatheduc) if inlf == 1, vce(robust)" : . ivregress 2sls lwage city (exper educ = age kidslt6 kidsge6 motheduc fatheduc) if inlf == 1, vce(robust)}{p_end}

{pstd}Perform Lewis-Mertens weak IV test{p_end}
{phang2}{stata "gweakivtest" : . gweakivtest}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gweakivtest} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(alpha)}}specified significance level alpha{p_end}
{synopt:{cmd:r(tau)}}specified relative bias threshold{p_end}
{synopt:{cmd:r(gmin)}}Stock-Yogo (or Sanderson-Windmeijer) test statistic{p_end}
{synopt:{cmd:r(gmin_generalized)}}Lewis-Mertens test statistic{p_end}
{synopt:{cmd:r(sybb_cv)}}Stock-Yogo (or Sanderson-Windmeijer) bias-based critical value{p_end}
{synopt:{cmd:r(sybbn_cv)}}Stock-Yogo (or Sanderson-Windmeijer) bias-based critical value under Nagar approximation{p_end}
{synopt:{cmd:r(lmc_cv)}}Lewis-Mertens conservative critical value{p_end}
{synopt:{cmd:r(lmc_converged)}}Calculation of Lewis-Mertens conservative critical value successfully converged{p_end}
{synopt:{cmd:r(lms_cv)}}Lewis-Mertens sharp critical value{p_end}
{synopt:{cmd:r(lms_converged)}}Calculation of Lewis-Mertens sharp critical value successfully converged{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:r(W)}}Covariance matrix of first-stage and reduced form coefficients{p_end}
{synopt:{cmd:r(Sig)}}Covariance matrix of first-stage and reduced form residuals{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Lewis, D. J., and K. Mertens, 2025. "A robust test for weak instruments with multiple endogenous regressors." {it:Review of Economic Studies}, forthcoming{p_end}

{phang}
Montiel Olea, J. L. and C. E. Pflueger, 2013. "A robust test for weak instruments." {it:Journal of Business and Economic Statistics}, 31, 358-369.{p_end}

{phang}
Sanderson, E. and F. Windmeijer, (2016). "A weak instrument F-test in linear IV models with multiple endogenous variables." {it:Journal of Econometrics}, 190(2), 212–221.{p_end}

{phang}
Stock, J. and M. Yogo, 2005. "Testing for weak instruments in linear IV regression." {it:In Identification and Inference for Econometric Models: Essays in Honor of Thomas Rothenberg}, Chapter 5, 80-108.{p_end}
		

{marker authors}{...}
{title:Authors}

{phang}
Daniel J. Lewis, University College London, London WC1H 0AX, United Kingdom
(daniel.lewis920@gmail.com)

{phang}
Karel Mertens, Federal Reserve Bank of Dallas and CEPR, Dallas TX 75201, USA
(mertens.karel@gmail.com)

{phang}
Jonathan Shaw, Institute for Fiscal Studies, London NW1 4DF, United Kingdom
(jon@jonshaw.net)

	
{marker also}{...}
{title:Also see}

{p 4 4 2}{help ivregress}, {help ivregress_postestimation}, 
{help ivreg2} (if installed), {help avar} (if installed),
{help weakivtest} (if installed) 
{p_end}
