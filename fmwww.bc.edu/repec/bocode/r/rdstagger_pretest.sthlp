{smcl}
{* *! version 1.0.0 Subir Hait 2026}{...}
{viewerjumpto "Syntax"        "rdstagger_pretest##syntax"}{...}
{viewerjumpto "Description"   "rdstagger_pretest##description"}{...}
{viewerjumpto "Options"       "rdstagger_pretest##options"}{...}
{viewerjumpto "Saved results" "rdstagger_pretest##saved"}{...}
{viewerjumpto "Examples"      "rdstagger_pretest##examples"}{...}

{title:Title}

{p 4 18 2}
{bf:rdstagger_pretest} {hline 2} Pre-treatment parallel trends falsification tests
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rdstagger_pretest} [{cmd:,} {opt method(string)}]

{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt method(string)}}test type; default {cmd:both}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rdstagger_pretest} tests the parallel trends assumption using
pre-treatment cohort-period cells from the ATT(g,t) matrix stored by
{helpb rdstagger}. Under the null hypothesis of parallel trends, all
pre-treatment ATT(g,t) cells should be zero (or statistically
indistinguishable from zero).

{pstd}
Two tests are available. The {cmd:joint} test conducts a Wald chi-squared
test of H{subscript:0}: ATT(g,t) = 0 simultaneously for all pre-treatment
cells. The {cmd:individual} test reports cell-by-cell t-statistics, which
is useful for identifying specific cohort-period combinations that drive
any rejection.

{pstd}
Note that the joint test uses the assumption of independence across cells.
For a more conservative test, use {cmd:bootstrap} standard errors when
running {helpb rdstagger}.

{marker options}{...}
{title:Options}

{phang}
{opt method(string)} selects which test(s) to report:

{p2colset 9 24 24 2}{...}
{p2col:{cmd:joint}}Wald chi-squared test. Degrees of freedom equal the
number of non-missing pre-treatment cells.{p_end}
{p2col:{cmd:individual}}Cell-by-cell t-tests. Each pre-treatment ATT(g,t)
is divided by its standard error. Cells significant at 5% are flagged
with an asterisk (*).{p_end}
{p2col:{cmd:both}}Both joint and individual tests (default).{p_end}

{marker saved}{...}
{title:Saved results}

{pstd}{cmd:rdstagger_pretest} saves in {cmd:e()}:

{synoptset 22}{...}
{synopt:{cmd:e(pretest_chi2)}}joint Wald chi-squared statistic{p_end}
{synopt:{cmd:e(pretest_df)}}degrees of freedom for joint test{p_end}
{synopt:{cmd:e(pretest_pval)}}p-value for joint test{p_end}

{pstd}
All original {helpb rdstagger} results in {cmd:e()} are preserved.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. rdstagger_sim, n(400) periods(8) cohorts(3) seed(42)}{p_end}
{phang2}{cmd:. rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)}{p_end}
{phang2}{cmd:. rdstagger_pretest, method(both)}{p_end}

{pstd}Check joint test result programmatically:{p_end}
{phang2}{cmd:. di "Pre-test p-value: " e(pretest_pval)}{p_end}

{title:Also see}

{psee}
{helpb rdstagger}, {helpb rdstagger_agg}, {helpb rdstagger_plot}
{p_end}
