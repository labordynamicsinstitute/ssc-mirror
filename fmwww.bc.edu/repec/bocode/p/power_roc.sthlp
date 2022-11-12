{smcl}
{* *! version 1.0.0 07nov2022}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:power roc} {hline 2}} Power and sample-size analysis for receiver operating characteristic (ROC) analysis  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compute sample size

{p 8 16 2}
{cmd:power} {help power_roc##method:{it:method}}
...
[{cmd:,} {opth p:ower(numlist)}
{help power_roc##power_options:{it:power_options}} ...]


{pstd}
Compute power

{p 8 16 2}
{cmd:power} {help power_roc##method:{it:method}}
...
[{cmd:,} {opth n(numlist)}
[{help power_roc##power_options:{it:power_options}} ...]


{marker method}{...}
{synoptset 30 tabbed}{...}
{synopthdr :method}
{synoptline}
{syntab:One sample}
{synopt :{helpb power oneroc:oneroc}}One-sample ROC analysis{p_end}

{syntab:Two samples (independent and paired)}
{synopt :{helpb power tworoc:tworoc}}Two-sample ROC analysis {p_end}
{synoptline}


{marker power_options}{...}
{synopthdr :power_options}
{synoptline}
{syntab:Main}
{p2coldent:* {opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)} {p_end}
{p2coldent:* {opth p:ower(numlist)}}power; default is {cmd:power(0.80)} {p_end}
{p2coldent:* {opth n(numlist)}}total sample size. For and independent two-sample analysis, {cmd:n()} indicates the total number of subjects taking one 
of the diagnostic tests (not the sum of both tests) {p_end}
{p2coldent:* {opth n1(numlist)}}sample size of the diseased group. For an independent two-sample analysis {cmd:n1()} indicates the number of diseased 
patients taking one of the diagnostic tests (not the sum of both tests) {p_end}
{p2coldent:* {opth n0(numlist)}}sample size of the non-diseased group. For an independent two-sample analysis {cmd:n0()} indicates the number of 
non-diseased patients taking one of the diagnostic tests (not the sum of both tests) {p_end}
{p2coldent:* {opth ratio(numlist)}}ratio of sample sizes, {cmd:N0/N1}; default is {cmd:ratio(1)}, meaning equal group sizes {p_end}
{p2coldent:* {opth corr(numlist)}}correlation between auc1 and auc2 when the same patients are being tested on both tests ({cmd:power tworoc only}); default is {cmd:corr(0)}, 
meaning independent samples.  {p_end}
{synopt :{opt onesid:ed}}one-sided test; default is two sided{p_end}
{synopt :{opt han:ley}}variance functions computed using the Hanley and McNeil (1982) method; default is to use the method by Obuchowski et al. (2004) {p_end}
{synopt :{cmdab:gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}]}graph results; see {manhelp power_optgraph PSS-2:power, graph}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* Specifying a list of values in at least two starred options, or 
two command arguments, or at least one starred option and one argument
results in computations for all possible combinations of the values; see
{help numlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
The {cmd:power roc} package is helpful for planning studies that use receiver operating characteristic (ROC) curves to evaluate the accuracy of diagnostic tests. 
An advantage of ROC curves for evaluating the accuracy of diagnostic tests is that it incorporates both {it: sensitivity} (the probability of a test detecting disease 
when the patient actually has the disease) and {it:specificity} (the probability that the test is negative when the patient is actually disease-free), into a single
measure of accuracy. {cmd:power roc} is loosely based upon the code used in the SAS® macro ROCPOWER (Zepp 1995). 

{pstd}
{opt power oneroc} computes sample size or power for a one-sample receiver operating characteristic (ROC) analysis. Variance functions 
are computed using either the method described in Obuchowski, Lieber and Wians (2004) for continuous and ordinal data assuming a binormal distibution (the default), 
or the method described by Hanley and McNeil (1982) for continuous data which is based on the Mann-Whitney version of the rank-sum test. 

{pstd}
{opt power tworoc} computes sample size or power for a two-sample receiver operating characteristic (ROC) analysis. 
When there is no correlation {cmd:corr(0)} between the two alternative AUCs ({it:auc1} and {it:auc2}), {opt power tworoc} 
computes sample size (power) for an independent two-sample test. When the correlation does not equal 0, {opt power tworoc} 
computes sample size (power) for a paired two-sample test. As with {opt power oneroc}, variance functions are computed using either the method described 
in Obuchowski, Lieber and Wians (2004) for continuous and ordinal data assuming a binormal distribution (the default), or the method described by Hanley and McNeil (1982) 
for only continuous data which is based on the Mann-Whitney version of the rank-sum test.   

{pstd}
Sample size can be computed given power, and power can be computed given sample size. Results can be displayed in a table (default) and on a graph 
({helpb power_optgraph:[PSS-2] power, graph}).  


{title:Options}

{phang}
{opth a:lpha(numlist)} sets the significance level of the test.  The
default is {cmd:alpha(0.05)}.

{phang} 
{opth p:ower(numlist)} specifies the desired power at which sample size is to be computed. 
If {cmd:power()} is specified in conjunction with {cmd:n()}, {cmd:n1()}, or {cmd:n0()}, 
then the actual power of the test is presented.

{phang} 
{opth n(numlist)} specifies the total number of subjects in the study to be used for determining power. For an independent two-sample
analysis {cmd:n()} indicates the total number of subjects taking one of the diagnostic tests (not the sum of both tests).

{phang}
{opth n1(numlist)} specifies the number of subjects in the diseased group to be used for determining power. For an independent two-sample
analysis {cmd:n1()} indicates the number of diseased patients taking one of the diagnostic tests (not the sum of both tests).

{phang} 
{opth n0(numlist)} specifies the number of subjects in the non-diseased group to be used for determining power. For an independent two-sample
analysis {cmd:n0()} indicates the number of non-diseased patients taking one of the diagnostic tests (not the sum of both tests).

{phang}
{opth ratio(numlist)} specifies the sample-size ratio of the non-diseased group relative to the diseased group, 
{cmd:N0/N1}. The default is {cmd:ratio(1)}, meaning equal allocation between the two groups.

{phang}
{opth corr(numlist)} specifies the hypothesized correlation between {it:auc1} and {it:auc2} ({cmd:power tworoc} only). When the same patients
take both diagnostic tests, we expect a correlation between the AUCs. When different groups of patients take
the two diagnostic tests (i.e. independent samples), we expect the correlation to be 0. The default is 
{cmd:corr(0)}, meaning independent samples.

{phang} 
{opt onesid:ed} indicates a one-sided test. The default is two sided. 

{phang} 
{opt han:ley} uses the Hanley and McNeil (1982) method for computing the variance functions for continuous data.
The default is the method described by Obuchowski, Lieber, and Wians (2004) which is designed for use with 
continuous and ordinal data assuming a binormal distribution. 

{phang}
{opt gr:aph}, {cmd:graph()}; see {manhelp power_optgraph PSS-2: power, graph}.



{marker examples}{...}
{title:Examples}

    {title:One-sample ROC analysis}

{pstd}
    Compute the sample size required to detect an AUC of 0.70 given an
    AUC of 0.50 under the null hypothesis using a two-sided test and computing
	variances for continuous data; assume a 5% significance level and 80% 
	power (the defaults) {p_end}
{phang2}{cmd:. power oneroc 0.50 0.70}

{pstd}
    Same as above, using a power of 90% and a one-sided test, computing variances
	using the Hanley and McNeil (1982) method {p_end}
{phang2}{cmd:. power oneroc 0.50 0.70, power(0.90) onesided hanley}

{pstd}
    Applying a range of AUC values under the alternative hypothesis
	and setting alpha levels to 0.05 and 0.01; and graphing the results {p_end}
{phang2}{cmd:. power oneroc 0.50 (0.60(0.05).95), power(0.90) onesided ratio(4) alpha(0.01 0.05) graph}

{pstd}
    For a total sample of 50 subjects, compute the power of a two-sided test to 
    detect an AUC of 0.70 given a null AUC of 0.50 and computing variances using the Obuchowski et al. (2004) method; 
	assume a 5% significance level (the default){p_end}
{phang2}{cmd:. power oneroc 0.50 0.70, n(50)}

{pstd}
    For a diseased group of 20 subjects and a ratio of 2 non-diseased patients for each diseased subject, 
	compute the power of a one-sided test to detect an AUC of 0.70 given a null AUC of 0.50 
	at the 5% significance level{p_end}
{phang2}{cmd:. power oneroc 0.50 0.70, n1(20) ratio(2) onesided}

{pstd}
	Compute powers for a range of alternative AUCs and total sample sizes, 
	graphing the results{p_end}
{phang2}{cmd:. power oneroc 0.50 (0.70(.10)0.90), n(5(5)30) graph}


    {title:Independent two-sample ROC analysis}

{pstd}
    Compute the sample size required to detect a difference between two diagnostic tests
	where the hypothesized AUCs are 0.70 and 0.90 and the null AUC is 0.70 for two independent
	samples, using a two-sided test and computing variances using the Obuchowski et al. (2004) method; 
	assume a 5% significance level and 80% power (the defaults) {p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 0.90}

{pstd}
    Same as above, using a power of 90% and a one-sided test, computing variances
	using the Hanley and McNeil (1982) method {p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 0.90, power(0.90) onesided hanley}

{pstd}
    Compute the power to detect a difference between two diagnostic tests where the hypothesized 
	AUCs are 0.70 and 0.90 and the null AUC is 0.70, where the total sample size of one of the tests 
	is 100 subjects (we assume that the other test will also have 100 subjects) using a two-sided test 
	and computing variances using the Obuchowski et al. (2004) method; 
	assume a 5% significance level and 80% power (the defaults){p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 0.90, n(100)}

{pstd}
    Same as above, but presume a ratio of 2 non-diseased patients for each diseased subject, 
	compute the power to detect a difference between two AUCs of 0.70 and 0.90, given a null AUC of 0.50 
	at the 5% significance level, computing variances using the Obuchowski et al. (2004) method {p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 0.90, n(100) ratio(2)}


    {title:Paired two-sample ROC analysis}
	
{pstd}
    Compute the sample size required to detect a difference between two diagnostic tests
	where the hypothesized AUCs are 0.70 and 0.90 and the null AUC is 0.70 and
	the same patients are tested on both diagnostic tests, assuming a correlation of 0.45 between tests.
	We specify the test to be one-sided and use the Obuchowski et al. (2004) method for computing variances.{p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 0.90, power(0.80) onesided corr(0.45)}

{pstd}
    Same as above, but applying a range of AUC values under the {it:auc2}
	and setting alpha levels to 0.05 and 0.01, graphing the results {p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 (0.75(0.05)0.95), power(0.80) onesided alpha(0.01 0.05) corr(0.45) graph}

{pstd}
    Compute the power to detect a difference between two diagnostic tests 
	where the same 60 patients take both tests and the correlation between 
	AUCs is 0.50 and the hypothesized AUCs are 0.70 and 0.90 and the null 
	AUC is 0.70, using a two-sided test and computing variances using the Obuchowski et al. (2004) method;
	assume a 5% significance level and 80% power (the defaults){p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 0.90, n(60) corr(0.50)}

{pstd}
    For a diseased group of 50 subjects and a non-diseased group of 80 subjects who took both diagnostic tests, 
	compute the power to detect a difference between two AUCs of 0.70 and 0.90, 
	given a null AUC of 0.70 at the 1% significance level, computing variances 
	using the Obuchowski et al. (2004) method and assume a correlation between AUCs of 0.30{p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 0.90, n1(50) n0(80) alpha(0.01) corr(0.30)}

{pstd}
	Compute powers for a range of {it:auc2} and total sample sizes when {it:auc1} is 0.70 and the null ({it:auc0}) 
	is 0.50, with the correlation between AUCs of 0.30, graphing the results{p_end}
{phang2}{cmd:. power tworoc 0.70 0.70 (0.75(.05)0.95), n(10(5)120) corr(0.30) graph}



{marker results}{...}
{title:Stored results}


{pstd}
{cmd:power roc} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd: r(alpha)}}significance level{p_end}
{synopt:{cmd: r(auc0)}}null AUC{p_end}
{synopt:{cmd: r(auc1)}}alternative AUC1{p_end}
{synopt:{cmd: r(auc2)}}alternative AUC2 ({cmd:power tworoc} only) {p_end}
{synopt:{cmd: r(beta)}}probability of a type II error{p_end}
{synopt:{cmd: r(delta)}}effect size{p_end}
{synopt:{cmd: r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}
{synopt:{cmd: r(ratio)}}ratio of sample sizes, N0/N1{p_end}
{synopt:{cmd: r(corr)}}correlation between AUC1 and AUC2 ({cmd:power tworoc} only) {p_end}
{synopt:{cmd: r(N)}}total sample size{p_end}
{synopt:{cmd: r(N0)}}sample size of the non-diseased group {p_end}
{synopt:{cmd: r(N1)}}sample size of the diseased group {p_end}
{synopt:{cmd: r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd: r(power)}}power{p_end}
{synopt:{cmd: r(V0)}}variance function of the null AUC {p_end}
{synopt:{cmd: r(V1)}}variance function of the alternative AUC1 {p_end}
{synopt:{cmd: r(V2)}}variance function of the alternative AUC2 ({cmd:power tworoc} only){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:oneroc} or {cmd:tworoc}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{p2colreset}{...}


{title:References}

{p 4 8 2} Hanley, J.A., and B. J. McNeil. 1982. The meaning and use of the area under a receiver operating characteristic (ROC) curve. {it:Radiology} 143:29-36 {p_end}

{p 4 8 2} Obuchowski, N.A., Lieber, M.L. and F.H. Wians Jr. 2004. ROC curves in clinical chemistry: uses, misuses, and possible solutions. {it:Clinical chemistry} 50:1118-1125.{p_end}

{p 4 8 2} Zepp, R.C. 1995. A SAS® macro for estimating power for ROC curves one-Sample and two-sample cases. {it:Proceedings of the 20th SAS Users Group International Conference} (Vol. 223).
{p_end}



{marker citation}{title:Citation of {cmd:power roc}}

{p 4 8 2}{cmd:power roc} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. 2022. POWER ROC: Stata package to compute power and sample size for ROC analyses


{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb roc}, {helpb power}, {helpb power diagnostic} (if installed){p_end}

