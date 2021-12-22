{smcl}
{* *! version 1.0  2021-10-25 Mark Chatfield}{...}
{viewerjumpto "Syntax" "tolerance##syntax"}{...}
{viewerjumpto "Description" "tolerance##description"}{...}
{viewerjumpto "Remarks" "tolerance##remarks"}{...}
{viewerjumpto "Examples" "tolerance##examples"}{...}
{viewerjumpto "Stored results" "tolerance##stored_results"}{...}
{viewerjumpto "References" "tolerance##references"}{...}
{viewerjumpto "Author" "tolerance##author"}{...}
{title:Title}

{phang}
{bf:tolerance} {hline 2} Tolerance intervals (normal distribution)


{marker syntax}{...}
{title:Syntax}

{pstd}
Generate tolerance intervals from input data:

{p 8 16 2}
{opt tolerance} {it:varname} {ifin}{cmd:,} 
{cmdab:percentofpop(}{it:#}{cmd:)} 
[{cmdab:conf:idence(}{it:#}{cmd:)}
{cmd:onesided} 
{cmdab:m:ethod(}{it:method_type}{cmd:)}]

{pstd}
Immediate command:

{p 8 16 2}
{opt tolerancei} {it:#obs #mean #sd}{cmd:,} 
{cmdab:percentofpop(}{it:#}{cmd:)} 
[{cmdab:conf:idence(}{it:#}{cmd:)}
{cmd:onesided}  
{cmdab:m:ethod(}{it:method_type}{cmd:)}]


{synoptset 22 tabbed}{...}
{marker synoptions}{...}
{synopthdr:options}
{synoptline}
{synopt: {opt percentofpop(#)}}required; specifies the percentage of the population for an interval to contain/cover{p_end}
{synopt: {opt conf:idence(#)}}specifies a {cmd:percentofpop}% tolerance interval with #% confidence is to be calculated. 
If this option is omitted, a {cmd:percentofpop}%-expectation tolerance interval is calculated 
(which is equivalent to a {cmd:percentofpop}% prediction interval){p_end}
{synopt: {opt onesided}}specifies one-sided tolerance intervals are to be calculated{p_end}
{synopt: {cmdab:m:ethod}{cmd:(}{it:method_type}{cmd:)}}The default for a two-sided {cmd:percentofpop}% tolerance interval with {cmd:conf}% confidence is an approximate method recommended by Howe (1969).
Specify {cmdab:m:ethod(howesimpler)} to use a simpler method also described by Howe (1969). See Remarks for more.{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tolerance}, and the immediate command {cmd:tolerancei}, calculate one-sided or two-sided tolerance intervals, 
assuming a sample has been drawn randomly from a normal distribution. 
The factor, k, used in the calculation (mean ± k × sd, mean - k × sd, or mean + k × sd) is also reported.
k is a function of: #obs, percentofpop, confidence and onesided. 

{pstd}
Tolerance intervals are statistical intervals that contain
(or cover) at least a percentage of a population,
either on average, or else with a stated confidence. Prediction intervals, and confidence intervals on quantiles can be regarded
as special cases of tolerance intervals (Vangel, 2005).

{pstd}
A {hi:95% tolerance interval with #% confidence} is an interval that contains at least 95% of a population, with #% confidence. 

{pstd}
A {hi:95%-expectation tolerance interval} is an interval that contains at least 95% of a population, on average. 
It is equivalent to a {hi:95% prediction interval}.
A prediction interval is an interval where a future measurement is expected to lie, with a given confidence level. See Chapter 4.7 (p55) of Meeker et al. (2017) for the formula.

{pstd}
A {cmd:one-sided p% tolerance interval with #% confidence} 
is equivalent to a {cmd:one-sided #% confidence interval for the pth percentile} (Meeker et al. 2017). 

{pstd}
[Extra] A {cmd:two-sided 95% confidence interval for the pth percentile} can be formed by 
using the bounds of one-sided p% tolerance intervals with 97.5% confidence. 
It is an oversight of {help centile:[R] centile} that this exact method is not available.


{marker remarks}{...}
{title:Remarks}

{pstd}
The old {cmd:tolerance} command (Lachenbruch 2004) was described incorrectly. 
{cmd:p(}{it:#}{cmd:)} was described as the confidence level, and {cmd:gamma(}{it:#}{cmd:)} as the coverage proportion, whereas
the opposite was true: {cmd:gamma(}{it:#}{cmd:)} was the confidence level, and {cmd:p(}{it:#}{cmd:)} the coverage proportion. 
I have deliberately avoided referring to gamma or beta in the new {cmd:tolerance} command because, confusingly,
the parameters have been used inconsistently in the literature to refer to (i) confidence level & (ii) coverage/content, and vice versa.{p_end}

{pstd}
Re: {cmd:method} for a calculating a two-sided percentofpop% tolerance interval with conf% confidence.
Approximate intervals are calculated because I have decided to calculate approximate (rather than exact - maybe I'll add this one day) values of k.
By default, Howe (1969)'s recommended method for our situation is used (k=λ_3). Young (2010) used this method.
{cmd:method(howesimpler)} will allow use of a simpler method (k=λ_1) described by Howe (1969), 
and used by {cmd:tolerance}. 
Note, the simpler method was described by Howe (1969) purely to make the point that
"nothing is gained by using the Wald-Wolfowitz approximation rather than the simpler [method]".


{marker examples}{...}
{title:Examples}

{phang2}{sf:. }{stata "sysuse auto, clear"}

    {title:Computing a 95%-expectation tolerance interval (equivalently a 95% prediction interval)}
	
{pstd}Either of these commands could be used:{p_end}

{phang2}{sf:. }{stata "tolerance mpg, percentofpop(95)"}{p_end}

{phang2}{sf:. }{stata "tolerancei 74 21.2973 5.785503, percentofpop(95)"}{p_end}

    {title:Computing a 95% tolerance interval with a 99% confidence level}

{pstd}Either of these commands could be used:{p_end}

{phang2}{sf:. }{stata "tolerance mpg, percentofpop(95) confidence(99)"}{p_end}

{phang2}{sf:. }{stata "tolerancei 74 21.2973 5.785503, percentofpop(95) confidence(99)"}{p_end}

    {title:Getting the same factors as those reported in Howe (1969)}

{pstd}Factors k=3.101 [and k=3.082] were reported in Table 1 for N=13 for the principal [and simpler] method, with percentofpop(95) confidence(95). Note the choice of mean and sd below does not affect the factor.{p_end}

{phang2}{sf:. }{stata "tolerancei 13 0.1234 0.6789, percentofpop(95) confidence(95)"}{p_end}

{phang2}{sf:. }{stata "tolerancei 13 0.1234 0.6789, percentofpop(95) confidence(95) m(howesimpler)"}{p_end}

    {title:Computing a one-sided 90% tolerance interval with 95% confidence}
	{title:(equivalently a one-sided 95% CI for the 90th percentile)}

{pstd}This reproduces the answer given in Example 4.4 (Section 4.4) in Meeker et al. (2017).{p_end}

{phang2}{sf:. }{stata "tolerancei 5 50.10 1.31, percentofpop(90) confidence(95) onesided"}{p_end}

    {title:[Extra] Computing a two-sided 95% confidence interval for the 2.5th percentile}

{pstd}{cmd:tolerance} can be used to produce an exact two-sided 95% confidence interval for the pth percentile, which {help centile:[R] centile} cannot yet do.{p_end}

{phang2}{sf:. }{stata "tolerance mpg, percentofpop(2.5) confidence(97.5) onesided"}{p_end}

{phang2}{sf:. }{stata "centile mpg, centile(2.5) level(95) meansd"}{p_end}


{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:tolerance} and {cmd:tolerancei} store the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd: r(low)}}lower bound of interval{p_end}
{synopt:{cmd: r(upp)}}upper bound of interval{p_end}
{synopt:{cmd: r(k)}}factor used for two-sided interval{p_end}
{synopt:{cmd: r(k_lb)}}factor used for one-sided interval{p_end}
{synopt:{cmd: r(k_ub)}}factor used for the other one-sided interval{p_end}

{marker references}{...}
{title:References}

{phang}Howe, W. G. (1969) Two-sided tolerance limits for normal populations - some improvements. Journal of the American Statistical Association, 64, 610–620.{p_end}
{phang}Lachenbruch, P. (2004) "TOLERANCE: Stata module to generate tolerance intervals from input data," Statistical Software Components S447401, Boston College Department of Economics, revised 19 Jan 2006.{p_end}
{phang}Meeker, W. Q., G. J. Hahn and L. A. Escobar. (2017) Statistical Intervals: A guide for practitioners and researchers. Second edition. John Wiley & Sons, Inc.{p_end}
{phang}Vangel, M. G. (2005) Tolerance Interval. In The Encyclopedia of Biostatistics, 2nd Edition, edited by P. Armitage and T. Colton. John Wiley & Sons, Ltd.{p_end}
{phang}Young, D. S. (2010) "tolerance: An R Package for Estimating Tolerance Intervals".
Journal of Statistical Software. 36 (5): 1–39. ISSN 1548-7660. Retrieved 19 February 2013.
Documentation for Version 2.0.0 (2020-02-04) here:
"https://cran.r-project.org/web/packages/tolerance/tolerance.pdf"{p_end}


{marker author}{...}
{title:Author}

{p 4 4 2}
Mark Chatfield, The University of Queensland, Australia.{break}
m.chatfield@uq.edu.au{break}
