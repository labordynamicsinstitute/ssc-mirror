{smcl}
{* *! version 0.3  14may2021}{...}
{vieweralsosee "[R] ksmirnov" "help ksmirnov"}{...}
{viewerjumpto "Syntax" "distcomp##syntax"}{...}
{viewerjumpto "Description" "distcomp##description"}{...}
{viewerjumpto "Options" "distcomp##options"}{...}
{viewerjumpto "Stored results" "distcomp##results"}{...}
{viewerjumpto "Remarks" "distcomp##remarks"}{...}
{viewerjumpto "Examples" "distcomp##examples"}{...}
{viewerjumpto "Author" "distcomp##author"}{...}
{viewerjumpto "References" "distcomp##references"}{...}
{title:Title}

{phang}
{* phang is short for p 4 8 2}
{bf:distcomp} {hline 2}  Compare two distributions


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:distcomp}
{varname}
{ifin}
{cmd:,}
{opth "by(varname:groupvar)"}
[{opt a:lpha(#)} {opt p:value} {opt noplot}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opth "by(varname:groupvar)"}}binary variable defining two groups{p_end}
{synopt :{opt a:lpha(#)}}familywise error rate (FWER); default is {cmd:alpha(0.10)}{p_end}
{synopt :{opt p:value}}report global p-value{p_end}

{syntab:Graphical}
{synopt :{opt noplot}}suppress plot{p_end}
{p2col:{help connect_options:{bf:groptline0(}{it:connect_options}{bf:)}}}graphical options for first ECDF{p_end}
{p2col:{help connect_options:{bf:groptline1(}{it:connect_options}{bf:)}}}graphical options for second ECDF{p_end}
{p2col:{help twoway_options:{bf:gropttwoway(}{it:twoway_options}{bf:)}}}graphical options for overall plot{p_end}
{p2col:{help cline_options:{bf:groptrej(}{it:cline_options}{bf:)}}}graphical options for rejected ranges{p_end}
{p2col:{help saving_option:{bf:saving(}{it:filename}{bf:, ...)}}}save graph in
       file{p_end}
{synoptline}
{pstd}
{bf:by} is allowed; see {help by} or {manlink D by}

{pstd}
As with {help ksmirnov}, {it:{help varname:groupvar}} must have exactly two distinct values.
If it takes more, then {bf:{help if}} can be used.
For example, {input:distcomp y if g==0 | g==1 , by(g)}
{* The distribution of {varname} for the first value of {it:{help varname:groupvar}} is compared with that of the second value.}


{marker description}{...}
{title:Description}

{pstd}
{* pstd is short for p 4 4 2}
{cmd:distcomp} compares two distributions.
The {varname} is for the variable for comparison, like price or income.
The {it:{help varname:groupvar}} should contain a single variable taking only two distinct values that defines two groups, like an indicator/dummy for "male."
Sampling is assumed iid from the two respective group population distributions, and it is assumed the groups are sampled independently.
The underlying theory also assumes that {varname} has a continuous distribution, but some amount of discreteness is ok.
In particular, if there are duplicate values within each sample, but no "ties" (same value observed in both samples), then it is fine to use {cmd:distcomp}.
With many ties, there are no theoretical results.
However, simulations suggest the method becomes conservative, controlling FWER even below the nominal level.
One such simulation is in the accompanying distcomp_examples.do file.

{pstd}
The first results are for the global (goodness-of-fit) test, similar to a two-sample Kolmogorov-Smirnov test.
That is, the null hypothesis is that the two CDFs are identical.
This could be false even if the two distributions' means are identical (and {help ttest} does not reject), e.g., with N(0,1) and N(0,2) distributions.
The global test results are always reported for levels 1%, 5%, and 10%.
Optionally, a p-value is also reported; it must be simulated, which takes longer for larger samples.
(To avoid misinterpretation, when the simulated value is zero, 0.0001 is reported since there are 1e4 simulation replications.)
The test is generally more powerful than Kolmogorov-Smirnov.
The methodology was proposed by Goldman and Kaplan (2018), refining an idea from Buja and Rolke (2006); see {help "distcomp##references":References}.

{pstd}
The second results are for a multiple testing procedure.
Instead of a single global null hypothesis (that the two CDFs are identical), there is a continuum of individual null hypotheses of CDF equality at each point.
That is, if F() and G() are the two distributions' CDFs, then each individual null hypothesis is F(x)=G(x), and the procedure considers the set of such hypotheses for all x.
The multiple testing procedure rejects equality at certain values of x while controlling the probability of {it:any} type I error (false positive), known as the familywise error rate (FWER).
This particular procedure controls the finite-sample (not just asymptotic) FWER at the desired level.
The output shows the ranges of x (if any) where F(x)=G(x) is rejected at the specified FWER level.
The methodology was proposed by Goldman and Kaplan (2018); see {help "distcomp##references":References}.

{pstd}
The < and > in the printed results indicate whether the "first" group's ECDF is below (<) or above (>) the other ECDF at the statistically significant points.
For example, imagine the initial results line says "Comparing distribution of y when treated=1 vs. treated=0," so treated=1 is the "first" group.
A < next to a rejected range (like from 0.9 to 3.1) means the treated=1 ECDF is below (<) the treated=0 ECDF on this range.
Similarly, a < next to the "At a 10% level: reject" global test result indicates that there were points at which the treated=1 ECDF was far enough below the treated=0 ECDF to reject the null hypothesis of equality.
Alternatively, a (< and >) means there were also other points where the treated=1 ECDF was far enough above (>) the treated=0 ECDF to reject the null hypothesis of equality.
Note the one-sided significance level is (approximately) half the specified two-sided level.
That is, specifying a two-sided 10% level is equivalent to a one-sided 5% level; two-sided 5% level is one-sided 2.5% level; and two-sided 1% is one-sided 0.5%.
For the global p-value, if the rejection is only one direction (either < or > but not "< and >"), then a global one-sided p-value is 1-sqrt(1-p); for small p, this is approximately p/2.
The < and > make it easier to interpret the results in terms of first-order stochastic dominance and restricted stochastic dominance.

{pstd}
By default, a plot is generated with the empirical CDFs of the two groups, along with the rejected ranges (if any).

{pstd}
The restriction of FWER levels to 1%, 5%, and 10% allows nearly instantaneous computation (when a p-value is not requested).
The reason is that a table of precise "critical values" for these specific levels has been simulated ahead of time.
In small samples, as with the Kolmogorov-Smirnov test, often it is impossible to attain exactly 1%, 5%, or 10%.
For example, for certain sample sizes, it may only be possible to have FWER of 9.6% or 10.6%, but nothing in between.
To make this transparent, the exact finite-sample FWER level has also been pre-simulated and is returned.
In some cases, an analytic formula (based on simulations) is used, in which case the pre-simulated exact FWER is not available.
Except with very small samples, the practical difference between specified and actual FWER level is usually negligible.


{marker options}{...}
{title:Options}
{* dlgtab:Main}
{phang}
{opth "by(varname:groupvar)"} is required.
It specifies a binary variable that identifies the two groups whose distributions are compared.{p_end}

{phang}
{opt alpha(#)} sets the familywise error rate (FWER) level at {it:#}.
The default is 0.10, i.e., 10% probability of any false positive.
Other accepted values are 0.05 and 0.01 (meaning 5% and 1%).{p_end}

{phang}
{opt pvalue} requests the global p-value to be simulated.
The computation time depends on the sample size.
For prohibitively large samples, the global test's rejections at levels 1%, 5%, and 10% (which do not require simulation) can be used to roughly approximate the p-value.
For example, if only the 10% test rejects, then 0.05<p<0.10.{p_end}

{phang}
{opt noplot} suppresses the plot.{p_end}

{phang}
{cmd:groptline0(}{it:connect_options}{cmd:)} specifies the style of the first group's ECDF; see {manhelpi connect_options G-3}.{p_end}

{phang}
{cmd:groptline1(}{it:connect_options}{cmd:)} specifies the style of the second group's ECDF; see {manhelpi connect_options G-3}.{p_end}

{phang}
{cmd:gropttwoway(}{it:twoway_options}{cmd:)} specifies options for the overall plot; see {manhelpi twoway_options G-3}.{p_end}

{phang}
{cmd:groptrej(}{it:cline_options}{cmd:)} specifies how the rejected ranges lines are rendered; see {manhelpi cline_options G-3}.{p_end}

{phang}
{cmd:saving(}{it:filename}[{cmd:, asis replace}]{cmd:)}
	allows you to save the graph to disk; see 
	{manhelpi saving_option G-3}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:distcomp} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(rej_gof10)}}1 if global null rejected at 10% level, else 0{p_end}
{synopt:{cmd:r(rej_gof05)}}1 if global null rejected at {cmd: }5% level, else 0{p_end}
{synopt:{cmd:r(rej_gof01)}}1 if global null rejected at  1% level, else 0{p_end}
{synopt:{cmd:r(p_gof)}}global p-value{p_end}
{synopt:{cmd:r(alpha_sim)}}finite-sample FWER level (if pre-simulated lookup table used), or . if formula used{p_end}
{synopt:{cmd:r(alpha)}}nominal FWER level specified by user{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(rej_ranges)}}ranges of values for which CDF equality is rejected at each point (at the specified FWER level).
Each row is one such range (lower endpoint, upper endpoint).
Note: if none rejected, then this is a 1-by-2 matrix with . as each entry.{p_end}
{synopt:{cmd:r(N)}}number of observations (overall, first group, second group){p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
R code (with additional functionality), including code to replicate results from the paper, and a working paper version are available at: {browse "https://kaplandm.github.io"}


{marker examples}{...}
{title:Examples}

{phang}{input:. sysuse nlsw88 , clear}{p_end}
{phang}{input:. distcomp wage , by(union) pvalue noplot}{p_end}
{phang}{input:. distcomp wage if race==2 , by(union)}{p_end}
{phang}{input:. bysort race : distcomp wage , by(union) p}{p_end}
{pstd}
Additional examples are in the distcomp_examples.do file.


{marker author}{...}
{title:Author}

{pstd}
David M. Kaplan{break}Department of Economics, University of Missouri{break}
kaplandm@missouri.edu{break}{browse "https://kaplandm.github.io"}

{marker references}
{title:References}

{pstd}
Goldman, M., and Kaplan, D. M. (2018).
Comparing distributions by multiple testing across quantiles or CDF values.
Journal of Econometrics, 206(1):143-166.
URL: {browse "https://doi.org/10.1016/j.jeconom.2018.04.003"}

{pstd}
Buja, A., and Rolke, W. (2006).
Calibration for Simultaneity: (Re)Sampling Methods for Simultaneous Inference with Applications to Function Estimation and Functional Data.
Working paper.
URL: {browse "http://stat.wharton.upenn.edu/~buja/PAPERS/paper-sim.pdf"}

