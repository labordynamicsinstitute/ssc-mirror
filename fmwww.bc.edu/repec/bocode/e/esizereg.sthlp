{smcl}
{* *! version 2.0.3 07Mar2024}{...}
{* *! version 2.0.2 29Feb2024}{...}
{* *! version 2.0.1 26Feb2024}{...}
{* *! version 2.0.0 29May2019}{...}

{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:esizereg} {hline 2}} Effect size based on a linear regression coefficient  {p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{pstd}
Postestimation version of esizereg 

{p 8 14 2}
{cmd:esizereg}
{it: coef_name}
{cmd:,}
[
{opt coh:ensd} 
{opt hed:gesg}
{opt lev:el(#)}
]


{pstd}
Immediate form of esizereg

{p 8 14 2}
{cmd:esizeregi}
{it: #coefficient}
{cmd:,}
{opt sd:p(#)}
{opt n1(#)}
{opt n2(#)}
[
{opt coh:ensd} 
{opt hed:gesg}
{opt lev:el(#)}
]


{pstd}
In the postestimation version of {cmd:esizereg}, {it: coef_name} identifies a coefficient in the preceding estimation model. {it: coef_name} is typically 
a variable name with or without a level indicator (see {helpb fvvarlist}). The easiest way to identify the {it: coef_name} assigned by the estimation model 
is to specify the {cmd: coeflegend} option; see {helpb estimation options}.  

{pstd}
In the immediate version of {cmd:esizereg}, {it: coefficient} is the actual numeric value of the coefficient.

{pstd}
In either version of {cmd:esizereg}, the coefficient must be for binary level variable, as {cmd: esizereg} computes the standardized mean difference between 2 levels of a variable.


{synoptset 16 tabbed}{...}
{synopthdr:esizereg}
{synoptline}
{synopt:{opt coh:ensd}}report Cohen's {it:d} (1988) {p_end}
{synopt:{opt hed:gesg}}report Hedges's {it:g} (1981) {p_end}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}


{synoptset 16 tabbed}{...}
{synopthdr:esizeregi}
{synoptline}
{p2coldent:* {opt sd:p(#)}}the within-sample pooled standard deviation{p_end}
{p2coldent:* {opt n1(#)}}number of observations in group 1{p_end}
{p2coldent:* {opt n2(#)}}number of observations in group 2{p_end}
{synopt:{opt coh:ensd}}report Cohen's {it:d} (1988) {p_end}
{synopt:{opt hed:gesg}}report Hedges's {it:g} (1981) {p_end}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}* {opt sdp, n1} and {opt n2} are required.{p_end}



{title:Description}

{pstd}
{opt esizereg} is a postestimation command that calculates Cohen's {it:d} (Cohen 1988) and Hedges's {it:g} (Hedges 1981) effect size for both the {it: unadjusted} 
and {it: adjusted} mean difference of a continuous variable between two groups. {opt esizereg} uses the unstandardized regression coefficient of the treatment 
variable as the numerator (which is equivalent to the difference between two covariate {it:unadjusted} or {it:adjusted} means) and uses the pooled within-sample 
estimate of the population standard deviation (estimated with {helpb margins}) as the denominator. Estimation models currently supported by {opt esizereg} 
are {helpb regress}, {helpb tobit}, {helpb truncreg}, {helpb hetregress}, {helpb xtreg}, {helpb intreg}, {helpb meintreg} and {helpb metobit}. When a 
{helpb weight} is specified in the estimation model, {opt esizereg} produces a weighted effect size estimate.

{pstd}
{cmd: esizeregi} is the immediate form of {cmd:esizereg}; see {helpb immed}.


{title:Remarks}

{pstd}
Whereas {help esize} computes confidence intervals based on the {it:t}-distribution, {cmd:esizereg} computes confidence intervals based on the 
{it:z}-distribution. The reason for this descrepancy is that {cmd:esizereg} is a post-estimation command following most regression-type models 
that estimate values on the {it:z}-distribution (with the exception of {help regress}), while {help esize} is based on the {it:t}-test. Functionally, 
the confidence intervals produced by the two methods are nearly identical, even when the sample size is small. The user can test this issue by comparing 
the results of {cmd:esizereg} and {help esize} at different sample sizes using {it:unadjusted} data.


{title:Options}

{p 4 8 2}
{cmd:sdp(}{it:#}{cmd:)} specifies the within-sample pooled standard deviation. This can be derived by running the post-estimation {helpb margins} command without any
predictor variables, and then converting the pooled standard error to the pooled standard deviation by multipying it by the square-root of N (standard error * sqrt(N));
{cmd: sdp() is required for esizeregi}.

{p 4 8 2}
{cmd:n1(}{it:#}{cmd:)} specifies the number of observations in group 1. The number of observations in each group can be found by running the {helpb tabulate oneway} command on the
treatment variable; {cmd: n1() is required for esizeregi}.

{p 4 8 2}
{cmd:n2(}{it:#}{cmd:)} specifies the number of observations in group 2; {cmd: n2() is required for esizeregi}.

{p 4 8 2}
{cmd:cohensd} specifies that Cohen's {it:d} (1988) be reported.

{p 4 8 2}
{cmd:hedgesg} specifies that Hedges's {it:g} (1981) be reported.

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for confidence intervals. The default is {cmd:level(95)}. 



{title:Examples}

{pstd}
{opt 1) esizereg:}{p_end}

{pmore}Setup{p_end}
{pmore2}{bf:{stata "webuse cattaneo2": . webuse cattaneo2}} {p_end}

{pmore} A simple case with no covariate adjustment. We estimate the treatment effect of {cmd: mbsmoke} on {cmd: bweight}. {p_end}
{pmore2}{bf:{stata "regress bweight mbsmoke": . regress bweight mbsmoke}} {p_end}

{pmore} Compute the effect size for {cmd: mbsmoke}. {p_end}
{pmore2}{bf:{stata "esizereg mbsmoke": . esizereg mbsmoke}} {p_end}

{pmore} Compare the results with those produced by {cmd:esize}. {p_end}
{pmore2}{bf:{stata "esize twosample bweight, by(mbsmoke)": . esize twosample bweight, by(mbsmoke)}} {p_end}

{pmore} We now estimate the treatment effect of {cmd: mbsmoke} on {cmd: bweight}, controlling for several covariates (which {cmd:esize} cannot do). {p_end}
{pmore2}{bf:{stata "regress bweight mbsmoke mmarried mage fbaby medu": . regress bweight mbsmoke mmarried mage fbaby medu}} {p_end}

{pmore} Compute the effect size for {cmd: mbsmoke}. {p_end}
{pmore2}{bf:{stata "esizereg mbsmoke": . esizereg mbsmoke}} {p_end}

{pmore} Re-estimate the model, now specifying {cmd:mbsmoke} as a factor variable, and adding a pweight. {p_end}
{pmore2}{bf:{stata "regress bweight i.mbsmoke mmarried mage fbaby medu [pw=nprenatal]": . regress bweight i.mbsmoke mmarried mage fbaby medu [pw=nprenatal]}} {p_end}

{pmore} Compute the weighted effect size for {cmd: 1.mbsmoke}. {p_end}
{pmore2}{bf:{stata "esizereg 1.mbsmoke": . esizereg 1.mbsmoke}} {p_end}

{pstd}
{opt 2) esizeregi:}{p_end}

{pmore} Estimate the treatment effect of {cmd: mbsmoke} on {cmd: bweight}, controlling for several covariates. {p_end}
{pmore2}{bf:{stata "regress bweight mbsmoke mmarried mage fbaby medu": . regress bweight mbsmoke mmarried mage fbaby medu}} {p_end}

{pmore} Get the pooled standard error of the adjusted model using {help margins}. {p_end}
{pmore2}{bf:{stata "margins": . margins}} {p_end}

{pmore} Convert the pooled standard error to a pooled standard deviation by multipying it by the square-root of N (4642). {p_end}
{pmore2}{bf:{stata "display 8.253892 * sqrt(4642)": . display 8.253892 * sqrt(4642)}} {p_end}

{pmore} Get the number of observations in each group of {cmd: mbsmoke}. {p_end}
{pmore2}{bf:{stata "tab mbsmoke": . tab mbsmoke}} {p_end}

{pmore} Compute the effect size. {p_end}
{pmore2}{bf:{stata "esizeregi -224.422, sdp(562.35602) n1(864) n2(3778)": . esizeregi -224.422, sdp(562.35602) n1(864) n2(3778)}} {p_end}

{pmore} Conduct a sensitivity analysis using the effect size and standard error values produced by {cmd: esizereg}. {p_end}
{pmore2}{bf:{stata "evalue smd  -0.399075, se(0.037937)": . evalue smd  -0.399075, se(0.037937)}} {p_end}

{pmore} Same as above, but using the local macros d and se generated by {cmd: esizereg} or {cmd: esizeregi}. {p_end}
{pmore2}{bf:{stata "evalue smd `d', se(`se')": . evalue smd `d', se(`se')}} {p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:esizereg} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(est)}}model coefficient for the point estimate{p_end}
{synopt:{cmd:r(V)}}pooled variance{p_end}
{synopt:{cmd:r(sdpooled)}}pooled standard deviation{p_end}
{synopt:{cmd:r(n1)}}sample size of group 1{p_end}
{synopt:{cmd:r(n2)}}sample size of group 2{p_end}
{synopt:{cmd:r(d)}}Cohen's {it:d}{p_end}
{synopt:{cmd:r(se)}}standard error of the Cohen's {it:d} estimate{p_end}
{synopt:{cmd:r(lb_d)}}lower confidence bound for Cohen's {it:d}{p_end}
{synopt:{cmd:r(ub_d)}}upper confidence bound for Cohen's {it:d}{p_end}
{synopt:{cmd:r(g)}}Hedge's {it:g}{p_end}
{synopt:{cmd:r(lb_g)}}lower confidence bound for Hedge's {it:g}{p_end}
{synopt:{cmd:r(ub_g)}}upper confidence bound for Hedge's {it:g}{p_end}
{p2colreset}{...}



{pstd}
{cmd:esizereg} also stores the following local macros, making them accessible for later use:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:d}}Cohen's {it:d}{p_end}
{synopt:{cmd:g}}Hedge's {it:g}{p_end}
{synopt:{cmd:se}}standard error of the Cohen's {it:d} estimate{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Cohen, J. 1988.  {it: Statistical Power Analysis for the Behavioral Sciences}. 2nd ed.  Hillsdale, NJ: Erlbaum.{p_end}

{p 4 8 2}
Hedges, L. V. 1981. Distribution theory for Glass's estimator of effect size and related estimators.  {it:Journal of Educational Statistics} 6: 107-128.{p_end}

{p 4 8 2}
Lipsey, M. W., and Wilson, D. B. (2001). Applied social research methods series; Vol. 49. {it:Practical meta-analysis}. Thousand Oaks, CA, US: Sage Publications, Inc. {p_end}



{marker citation}{title:Citation of {cmd:esizereg}}

{p 4 8 2}{cmd:esizereg} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2019). ESIZEREG: Stata module for calculating effect size based on a linear regression coefficient. 
Statistical Software Components S458607, Boston College Department of Economics. {p_end}



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb esize}, {helpb evalue} , {helpb evalue_estat} if installed {p_end}

