{smcl}
{* *! version 1.0.2  21sept2020}{...}
{vieweralsosee "underid" "help underid"}{...}
{vieweralsosee "ranktest" "help ranktest"}{...}
{vieweralsosee "overid9" "help overid9"}{...}
{vieweralsosee "xtoverid" "help xtoverid"}{...}
{viewerjumpto "Syntax overview" "overid##syntax"}{...}
{viewerjumpto "Options detail - linear IV estimators" "overid##options_linear"}{...}
{viewerjumpto "Options detail - after reg3 and under version control" "overid##options_reg3vc"}{...}
{viewerjumpto "Examples - linear IV estimators" "overid##examples_linear"}{...}
{viewerjumpto "Examples - nonlinear IV estimators" "overid##examples_nonlinear"}{...}
{viewerjumpto "Examples - xtreg and fixed vs random effects" "overid##examples_xtreg"}{...}
{viewerjumpto "Examples - reg3 and version control" "overid##examples_reg3vc"}{...}
{viewerjumpto "Stored results" "overid##results"}{...}
{viewerjumpto "Citation and references" "overid##references"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi: overid} {hline 2}}Postestimation tests of overidentification{p_end}
{p2colreset}{...}

{pstd}
{opt overid} computes tests of overidentifying restrictions for a regression
estimated via instrumental variables in which the number of instruments exceeds the number of regressors:
that is, for an overidentified equation.
These are tests of the joint null hypothesis that the excluded instruments are valid instruments,
i.e., uncorrelated with the error term and correctly excluded from the estimated equation.
A rejection casts doubt on the validity of the instruments.
{p_end}

{pstd}
Supported estimators:
{help ivregress}, {help ivreg2}, {help xtivreg}, {help xtivreg2}, {help xthtaylor}, {help xtabond2}, {help xtdpdgmm},
{help ivprobit}, {help ivtobit}, {help reg3}, {help ivreg29}, {help xtreg}.
{p_end}

{pstd}
{opt overid} requires the Stata module {opt ranktest}, version 02.0.03 or higher;
click {stata ssc install ranktest :here} to install
or type "ssc install ranktest" from inside Stata.
{p_end}

{pstd}
Note: {opt overid} was substantially rewritten starting with version 3.
It is now essentially a wrapper for the programs
{help underid} (used for most linear IV estimators),
{help overid9} (used for nonlinear IV estimators and {help reg3}),
and {help xtoverid} (used for testing fixed vs random effects after {help xtreg}).
Full descriptions of the tests implemented by {opt overid}
are available in the help files for these programs (click on the links).
The version of Stata required for {opt overid} is Stata 13 or higher.
The previous version of {opt overid} is now called {help overid9}.
{help xtoverid} also continues to be available.
Both {help overid9} and {help xtoverid} are included in the {opt overid} package.
To run either program, either use {opt overid} with version control ({bind:{it:version 12: overid ...}}),
or call {help overid9} or {help xtoverid} directly.
{p_end}


{marker syntax}{...}
{dlgtab 0 0:Syntax overview}


{title:Syntax and usage after linear IV estimation}
({help ivregress}, {help ivreg2}, {help xtivreg}, {help xtivreg2}, {help xthtaylor}, {help xtabond2}, {help xtdpdgmm})

{p 4 8 2}
{opt overid}
[{cmd:,} {opt jgmm2s LIMLresid jcue j2l j2lr kp wald lr center} {opt vceopt(VCE options)} {opt rkopt(ranktest options)} {opt noi:sily noreport}]

{pstd}
For a summary description of the above options, see {help overid##options_linear:below}.
For examples illustrating the use of these options, see {help overid##examples_linear:below}.
For a full description of the methods and framework used, see the help file for {help underid}.
{p_end}


{title:Syntax and usage after nonlinear IV estimation}
({help ivprobit}, {help ivtobit})

{p 4 8 2}
{opt overid}

{p 4 8 2}Note: estimation using {help ivprobit} or {help ivtobit} must use the {opt twostep} option.

{pstd}
{help ivprobit} and {help ivtobit} with the {opt twostep} option report Newey's (1987) minimum-chi-squared estimators.
Lee (1992) shows that the chi-squared statistic from these estimators provides a test of overidentifying restrictions.
For examples illustrating the use of {opt overid} after estimation by instrumental variables probit or tobit,
see {help overid##examples_nonlinear:below}.
{p_end}


{title:Syntax and usage after panel data estimation using {help xtreg} (fixed vs random effects)}

{p 4 8 2}
{opt overid}
[{cmd:,} {opt robust} {opt cl:uster(varname)}]

{pstd}
A test of fixed vs. random effects can also be seen as a test of overidentifying restrictions.
The test is implemented by xtoverid using the artificial regression approach described by Arellano (1993),
in which a random effects equation is reestimated augmented
with additional variables consisting of the original regressors transformed into deviations-from-mean form.
For examples illustrating the use of these options, see {help overid##examples_xtreg:below}.
For a full description of the methods and framework used, see the help file for {help xtoverid}.
{p_end}


{title:Syntax and usage after {help reg3} and under version control}
({help reg3}, {help ivregress}, {help ivreg2}, {help ivreg29}, {help xtivreg}, {help xtivreg2}, {help xthtaylor}, {help ivprobit}, {help ivtobit})

{p 4 8 2}
{opt overid}

{p 4 8 2}
{opt version} {it:ver} {cmd: : overid}
[{cmd:,} {opt chi2 dfr f all}]

{p 4 8 2}where {it:ver} is a Stata version number between 9 and 12 inclusive.

{pstd}
For a summary description of the above options, see {help overid##options_reg3vc:below}.
For examples illustrating the use of these options, see {help overid##examples_reg3vc:below}.
For a full description of the methods and framework used, see the help file for {help overid9}.
{p_end}


{marker options_linear}{...}
{dlgtab 0 0:Options detail - linear IV estimators}

{p 4 8 2}
{opt overid}
[{cmd:,} {opt jcue jgmm2s j2l j2lr kp sw wald lr center} {opt vceopt(VCE options)} {opt rkopt(ranktest options)} {opt noi:sily noreport}
{opt usemeans repstata} {opt maineq(estimator)}]

{synoptset 22}{...}
{p2col 3 4 4 2:Tests}{p_end}
{synopt :{opt jgmm2s}}J statistic from 2-step GMM (robust default) or 2SLS (iid default){p_end}
{synopt :{opt LIMLresid}}use LIML residuals instead of 2SLS residuals (iid only) (equivalent to Anderson canonical correlations test{p_end}
{synopt :{opt jcue}}Cragg-Donald test, J statistic from GMM CUE (robust only){p_end}
{synopt :{opt j2l}}J2L statistic (robust only){p_end}
{synopt :{opt j2lr}}J2LR statistic (robust only){p_end}
{synopt :{opt kp}}Kleibergen-Paap test (robust only){p_end}

{p2col 3 4 4 2:Main options}{p_end}
{synopt :{opt wald}}report Wald-type instead of default LM-type test{p_end}
{synopt :{opt lr}}report LR instead of default LM-type test (Anderson test only){p_end}
{synopt :{opt center}}specifies that the moments in the robust VCE are centered so that they have mean zero{p_end}

{p2col 3 4 4 2:VCE options}{p_end}
{synopt :{it:(default)}}take VCE options from IV estimation{p_end}
{synopt :{opt vceopt(VCE options)}:}override IV VCE specification with user-specified option list selected from the following:{p_end}
{synopt :{bind:  }{opt iid}}report tests using unrobust (standard) VCE that assumes iid{p_end}
{synopt :{bind:  }{cmdab:rob:ust}}report tests that are robust to arbitrary heteroskedasticity{p_end}
{synopt :{bind:  }{opt cluster(varlist)}}report tets that are robust to heteroskedasticity and within-cluster correlation; 2-way clustering is supported{p_end}
{synopt :{bind:  }{opt bw(#)}}report tests that are autocorrelation-consistent (AC)
or (with the {opt robust} option) heteroskedasticity- and autocorrelation-consistent (HAC),
with bandwidth equal to #{p_end}
{synopt :{bind:  }{opt kernel(string)}}specifies the kernel to be used for AC and HAC covariance estimation (default=Bartlett a.k.a. Newey-West){p_end}
{p 2}For more details on available VCE options, see help {help avar} or {help ivreg2}.{p_end}

{p2col 3 4 4 2:Rarely-used options}{p_end}
{synopt :{opt rkopt(options)}}additional options to pass to {cmd:ranktest}, e.g., optimization settings; see {help ranktest}{p_end}
{synopt :{opt noi:sily}}report output of internal call to {help ranktest}{p_end}
{synopt :{opt noreport}}suppress detailed output relating to {help xtabond2}{p_end}
{synopt :{opt nopartial}}}keep the exogenous regressors X in the list of both endogenous regressors Y and instruments Z{p_end}
{synopt :{opt usemeans}}(after {help xtivreg} or {help xthtaylor} only) use means instead of demeaned exogenous regressors as IVs{p_end}
{synopt :{opt repstata}}(after {help xtivreg} or {help xthtaylor} only) use Stata method for exogenous regressors in random effects models{p_end}
{synopt :{opt maineq(estimator)}}(requires {help ivreg2}) re-estimate and report main equation; {cmd:estimator} may be {opt iv}, {opt gmm2s} or {opt cue}{p_end}

{p 2 2 2}NB: the default for {opt overid} is {opt jgmm2s},
whereas the default for {help underid} is to use LIML residuals in the iid case
(equivalent to Anderson's canonical correlations test)
and CUE GMM J in the non-iid case.
Calling {opt overid} with the {opt limlresid} option will replicate the default behavior of {opt underid}.
See the {help overid##examples_linear:examples} below and help {help underid} for details.{p_end}

{p 2 2 2}{cmd:overid} as used above requires the Stata module {cmd:ranktest}, version 02.0.03 or higher;
click {stata ssc install ranktest :here} to install
or type "ssc install ranktest" from inside Stata.{p_end}

{p 2 2 2}Additional robust covariance options accepted by {help avar} may be included as options to {opt underid}.
See help {help avar}, {help ivreg2} or {help ranktest} for details.{p_end}


{marker options_xtreg}{...}
{dlgtab 0 0:Options detail - panel data estimation using xtreg (fixed vs random effects)}

{p 4 8 2}
{opt overid}
[{cmd:,} {opt robust} {opt cl:uster(varname)}]

{synopt :{opt robust}}report a heteroskedasticity-robust overidentification test{p_end}
{synopt :{opt cluster(varname)}}report a cluster-robust overidentification test{p_end}


{marker options_reg3vc}{...}
{dlgtab 0 0:Options detail - after reg3 and under version control}

{p 4 8 2}
{opt overid}

{p 4 8 2}
{opt version} {it:ver} {cmd: : overid}
[{cmd:,} {opt chi2 dfr f all}]

{p 4 8 2}where {it:ver} is a Stata version number between 9 and 12 inclusive.

{synopt :{opt chi2}}report Sargan's and Basmann's chi-squared statistics{p_end}
{synopt :{opt dfr}}equivalent to {opt chi2} but incorporating an (N-K) small-sample correction to the Sargan statistic{p_end}
{synopt :{opt f}}report the pseudo-F test versions of the Sargan ((N-K)/(L-K)) and Basmann ((N-L)/(L-K)) statistics{p_end}
{synopt :{opt all}}report all 5 statistics{p_end}


{marker examples_linear}{...}
{dlgtab 0 0:Overidentification examples - linear IV estimators}

{pstd}
Instrumental variables.  Examples follow Hayashi 2000, p. 255.
{p_end}
{phang}. {stata "use http://fmwww.bc.edu/ec-p/data/hayashi/griliches76.dta, clear"}{p_end}

{pstd}
2SLS with Sargan J statistic (iid case).
{p_end}
{phang}. {stata ivreg2 lw s expr tenure rns smsa i.year (iq=med kww age mrt)}{p_end}
{phang}. {stata di e(j)}{p_end}

{pstd}
Replicate Sargan J statistic: iid case, 2SLS residuals.
{p_end}
{phang}. {stata overid}{p_end}
{phang}. {stata di r(j_oid)}{p_end}
{pstd}
Sargan J statistic, iid case using LIML residuals.
{p_end}
{phang}. {stata overid, limlresid}{p_end}

{pstd}
2SLS with heteroskedastic-robust Sargan-Hansen J statistic (equivalent to J from 2-step GMM).
{p_end}
{phang}. {stata ivreg2 lw s expr tenure rns smsa i.year (iq=med kww age mrt), rob}{p_end}
{phang}. {stata di e(j)}{p_end}

{pstd}
Reproduce {help ivreg2} Hansen J overid statistic.
{p_end}
{phang}. {stata overid}{p_end}
{phang}. {stata di r(j_oid)}{p_end}
{pstd}
CUE GMM J statistic.
{p_end}
{phang}. {stata overid, jcue}{p_end}

{pstd}
Reproduce J and coefficient estimates for CUE.
Note the {opt nopartial} option is required in order to reproduce both the CUE estimates
of the coefficients on the exogenous regressors and the Hansen J statistic.
Coefficient estimates differ slightly because of different methods of numerical optimization.
{p_end}
{phang}. {stata ivreg2 lw s expr tenure rns smsa i.year (iq=med kww age mrt), rob cue}{p_end}
{phang}. {stata underid, overid nopartial rkopt(noevorder)}{p_end}
{phang}. {stata mat list r(b_oid)}{p_end}

{pstd}
Dynamic panel data using {help xtabond2}.
Note that the {help xtabond2} option {opt svmat} is required,
and that this option in turn requires the Mata option {helpb matafavor} to be set for {opt speed}.
{p_end}
{phang}. {stata "use http://www.stata-press.com/data/r7/abdata.dta, clear"}{p_end}

{pstd}
Two-step estimator, no level equation.
{opt xtabond2} uses the default {opt h(2)} option,
and internally {opt overid} uses the {opt nopartial} option in order to reproduce the results.
{p_end}
{phang}. {stata xtabond2 n L.n L(0/1).(w k) yr1979-yr1984, gmm(L.(w k n), lag(1 1)) iv(yr1979-yr1984) robust twostep noleveleq svmat}{p_end}

{pstd}
Reproduce {help xtabond2} Hansen J overid statistic.
{p_end}
{phang}. {stata di e(hansen)}{p_end}
{phang}. {stata overid}{p_end}
{pstd}
CUE GMM J statistic.
Use {opt noreport} option to suppress report of variable transformations.
Use {opt noisily} option to display underlying {help ranktest} output.
{p_end}
{phang}. {stata overid, jcue noreport noi}{p_end}
{pstd}
Examine CUE coefficients and VCE for endogenous regressors.
{p_end}
{phang}. {stata mat list r(b_oid)}{p_end}
{phang}. {stata mat list r(V_oid)}{p_end}

{pstd}
Reproduce {help xtdpdgmm} Hansen J overid statistic.
{p_end}
{phang}. {stata "xtdpdgmm L(0/1).n w k, gmmiv(L.n, l(1 4) c m(d)) iv(w k, d m(d)) twostep vce(robust)"}{p_end}
{phang}. {stata estat overid}{p_end}
{phang}. {stata overid}{p_end}
{pstd}
CUE GMM J statistic.
Also examine CUE coefficients and VCE for endogenous regressors.
{p_end}
{phang}. {stata overid, jcue}{p_end}
{phang}. {stata mat list r(b_oid)}{p_end}
{phang}. {stata mat list r(V_oid)}{p_end}

{pstd}
Static panel data.  Examples based on Stata command help files.
{p_end}
{phang}. {stata webuse nlswork, clear}{p_end}
{phang}. {stata tsset idcode year}{p_end}
{phang}. {stata gen age2=age^2}{p_end}
{phang}. {stata gen black=(race==2)}{p_end}

{pstd}
Fixed effects.
{p_end}
{phang}. {stata xtivreg ln_wage age (tenure = union south), fe}{p_end}
{pstd}
LIML-based tests for the iid case.
{p_end}
{phang}. {stata overid, limlresid}{p_end}
{pstd}
Cluster-robust test.
{p_end}
{phang}. {stata overid, vceopt(cluster(idcode))}{p_end}

{pstd}
G2SLS; note overid degrees of freedom: 2 (union, south) - 1 (tenure) = 1.
{p_end}
{phang}. {stata xtivreg ln_wage age (tenure = union south), re}{p_end}
{phang}. {stata overid}{p_end}

{pstd}
EC2SLS; dof = 6 (mean and mean-deviation of union, south, age) - 2 (GLS transform of tenure, age) = 4.
{p_end}
{phang}. {stata xtivreg ln_wage age (tenure = union south), ec2sls}{p_end}
{phang}. {stata overid}{p_end}

{pstd}
EC2SLS; changing the number of included exogenous variables changes the dof of the overid stat.
4 (mean and mean-deviation of union, south) - 1 (GLS transform of tenure) = 3.
{p_end}
{phang}. {stata xtivreg ln_wage (tenure = union south), ec2sls}{p_end}
{phang}. {stata overid}{p_end}

{pstd}
Hausman-Taylor estimation; 2-step GMM J stats.
Note that underlying estimation differs from original; Stata's
{opt xthtaylor} treats GLS-transformed exogenous regressors as endogenous.
dof = 2 (exogenous time-varying age, age2) - 1 (endogenous time-invariant grade) = 1.
{p_end}
{phang}. {stata xthtaylor ln_wage age age2 tenure hours black birth_yr grade, endog(tenure hours grade)}{p_end}
{phang}. {stata overid}{p_end}
{phang}. {stata mat list e(b)}{p_end}
{phang}. {stata mat list r(b0_oid)}{p_end}

{pstd}
As above but use {opt repstata} option; confirm underlying estimation now matches original.
{p_end}
{phang}. {stata xthtaylor ln_wage age age2 tenure hours black birth_yr grade, endog(tenure hours grade)}{p_end}
{phang}. {stata overid, repstata}{p_end}
{phang}. {stata mat list e(b)}{p_end}
{phang}. {stata mat list r(b0_oid)}{p_end}


{marker examples_nonlinear}{...}
{dlgtab 0 0:Overidentification examples - nonlinear IV estimators}

{pstd}
Examples are overidentified versions of the examples in the Stata help files for {help ivprobit} and  {help ivtobit}.
Note that the {opt twostep} is required for both estimators.
{p_end}

{pstd}
Load data and create an additional instrument.
{p_end}
{phang}. {stata "webuse laborsup, clear"}{p_end}
{phang}. {stata "gen male_educ_sq = male_educ^2"}{p_end}

{pstd}
IV probit:
{p_end}
{phang}. {stata ivprobit fem_work fem_educ kids (other_inc = male_educ male_educ_sq), twostep}{p_end}
{phang}. {stata "overid"}{p_end}

{pstd}
IV tobit:
{p_end}
{phang}. {stata ivtobit fem_inc fem_educ kids (other_inc = male_educ male_educ_sq), ll twostep}{p_end}
{phang}. {stata "overid"}{p_end}


{marker examples_xtreg}{...}
{dlgtab 0 0:Overidentification examples - panel data estimation using xtreg (fixed vs random effects)}

{phang}. {stata webuse abdata, clear}

{pstd}
Artificial regression overid test of fixed vs random effects.
Estimate using random effects, then test.
{p_end}
{phang}. {stata xtreg n w k, re}{p_end}
{phang}. {stata overid}{p_end}
{pstd}
Cluster-robust version.
{p_end}
{phang}. {stata overid, cluster(id)}{p_end}

{pstd}
In the homoskedastic balanced panel case,
a Hausman test using sigma from FE estimation is numerically equal to the artificial regression overid statistic.
First estimate using random effects and report {opt overid} test result.
{p_end}
{phang}. {stata xtreg n w k if year>=1978 & year<=1982, re}{p_end}
{phang}. {stata overid}{p_end}
{phang}. {stata di r(j)}{p_end}
{pstd}
Hausman test of fixed vs random effects.
{p_end}
{phang}. {stata est store re}{p_end}
{phang}. {stata xtreg n w k if year>=1978 & year<=1982, fe}{p_end}
{phang}. {stata est store fe}{p_end}
{pstd}
Test statistic is identical.
{p_end}
{phang}. {stata hausman fe re, sigmaless}{p_end}
{phang}. {stata di r(chi2)}{p_end}


{marker examples_reg3vc}{...}
{dlgtab 0 0:Overidentification examples - estimation using reg3 and version control}

{pstd}
Overidentification tests after estimation by {opt reg3}.
{p_end}

{phang}. {stata "webuse klein, clear"}{p_end}
{phang}. {stata "constraint define 1 [consump]wagepriv = [consump]wagegovt"}{p_end}
{phang}. {stata "constraint define 2 [consump]govt = [wagepriv]govt"}{p_end}

{phang}. {stata "reg3 (consump wagepriv wagegovt govt invest) (wagepriv consump govt capital1 taxnetx)"}{p_end}
{phang}. {stata "overid"}{p_end}

{phang}. {stata "reg3 (consump wagepriv wagegovt govt invest) (wagepriv consump govt capital1 taxnetx), c(1 2)"}{p_end}
{phang}. {stata "overid"}{p_end}

{pstd}
Version control examples.
Using version 12 or earlier causes overid to branch to overid version 2.0.08, also available as {opt overid9}.
{p_end}
{phang}. {stata "use http://fmwww.bc.edu/ec-p/data/hayashi/griliches76.dta, clear"}{p_end}
{phang}. {stata ivreg2 lw s expr tenure rns smsa (iq=med kww age mrt)}{p_end}
{phang}. {stata "version 12: overid, all"}{p_end}
{phang}. {stata "overid9, all"}{p_end}

{pstd}
Replicate Sargan chi-sq statistic using current version of {opt overid}.
{p_end}
{phang}. {stata "overid, jgmm2s"}{p_end}
{pstd}
Replicate Basmann chi-sq statistic using current version of {opt overid}.
{p_end}
{phang}. {stata "overid, jgmm2s wald small"}{p_end}


{marker results}{...}
{dlgtab 0 0:Stored results}

{pstd}
For stored results after linear IV estimation, see the help file for {help underid##results:underid}.
{p_end}


{marker references}{...}
{dlgtab 0 0:Citation and references}


{title:Citation}

{p}{opt overid} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{phang}Baum, C.F., Schaffer, M.E., Stillman, S., Wiggins, V., Windmeijer, F. 2020.
overid: Stata module to calculate tests of overidentifying restrictions.
{browse "https://ideas.repec.org/c/boc/bocode/s396802.html"}{p_end}


{title:References}

{p 0 4} Arellano, M. 1993.
On the testing of correlated effects with panel data.
Journal of Econometrics, Vol. 59, Nos. 1-2, pp. 87-97.

{p 0 4}Lee, L. 1992.
Amemiya's Generalized Least Squares and Tests of Overidenfication in Simultaneous Equation Models with Qualitative or Limited Dependent Variables.
Econometric Reviews, Vol. 11, No. 3, pp. 319-328.

{p 0 4}Newey, W.K. 1987.
Efficient Estimation of Limited Dependent Variable Models with Endogeneous Explanatory Variables.
Journal of Econometrics, Vol. 36, pp. 231-250.


{title:Authors}

	Christopher F Baum, Boston College, USA
	baum@bc.edu

	Mark E Schaffer, Heriot-Watt University, UK
	m.e.schaffer@hw.ac.uk

	Steven Stillman, University of Bolzano, Italy
	steven.stillman@unibz.it

	Vince Wiggins, Stata Corporation, USA
	vwiggins@stata.com

	Frank Windmeijer, Oxford University, UK
	frank.windmeijer@stats.ox.ac.uk

