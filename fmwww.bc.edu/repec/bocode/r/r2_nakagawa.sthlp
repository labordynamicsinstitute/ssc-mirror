{smcl}
{* *! version 1.0.0  25jun2024}{...}
{vieweralsosee "[ME] mixed" "help mixed"}{...}
{vieweralsosee "[ME] mixed postestimation" "help mixed postestimation"}{...}
{viewerjumpto "Syntax" "r2_nakagawa##syntax"}{...}
{viewerjumpto "Description" "r2_nakagawa##description"}{...}
{viewerjumpto "Examples" "r2_nakagawa##examples"}{...}
{viewerjumpto "Stored results" "r2_nakagawa##results"}{...}
{viewerjumpto "References" "r2_nakagawa##references"}{...}
{viewerjumpto "Citation" "r2_nakagawa##citation"}{...}
{viewerjumpto "Authors" "r2_nakagawa##authors"}{...}
{viewerjumpto "Acknowledgments" "r2_nakagawa##acknowledgments"}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:r2_nakagawa} {hline 2}}Nakagawa's R-squared statistic 
for multilevel mixed-effects linear regression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 19 2}
		{cmd:r2_nakagawa}


{marker description}{...}
{title:Description}

{pstd}
{cmd:r2_nakagawa} 
is a post-estimation command 
(also see: {help estat}) 
that computes the R-squared statistic following {helpb mixed}. 
R-squared is computed as described by Nakagawa and Schielzeth (2013) 
for random intercepts, 
and extended to random slopes as described by Johnson (2014). 

{pstd}
{cmd:r2_nakagawa}
computes the marginal R-squared, 
which is concerned with variance explained by the fixed effects, 
and the conditional R-squared, 
which is concerned with variance explained by both fixed and random effects 
(Nakagawa and Schielzeth 2013).

{pstd}
More specifically, the marginal R-squared is computed as: 

{phang2}
{it:Var_f} / ({it:Var_f} + {it:Var_re} + {it:Var_e}) 

{pstd}
and the conditional R-squared is computed as: 

{phang2}
({it:Var_f} + {it:Var_re}) / ({it:Var_f} + {it:Var_re} + {it:Var_e}) 

{pstd}
where {it:Var_f} is the variance of the fixed effects, {it:Var_re}
is the variance of the random effects, and {it:Var_e} is the variance of the random effects residuals.


{marker examples}{...}
{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork}{p_end}

{pstd}Random-intercept model, analogous to {cmd:xtreg}{p_end}
{phang2}{cmd:. mixed ln_w grade age c.age#c.age ttl_exp}
			{cmd:tenure c.tenure#c.tenure || id:}{p_end}
{phang2}{cmd:. r2_nakagawa}{p_end}

{pstd}Random-intercept and random-slope (coefficient) model, correlated random
effects{p_end}
{phang2}{cmd:. mixed ln_w grade age c.age#c.age ttl_exp}
			{cmd:tenure c.tenure#c.tenure || id: tenure,}
			{cmd:cov(unstruct)}{p_end}
{phang2}{cmd:. r2_nakagawa}{p_end}
{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse productivity}{p_end}

{pstd}Three-level nested model, observations nested within 
{cmd:state} nested within {cmd:region}, fit
by maximum likelihood{p_end}
{phang2}{cmd:. mixed gsp private emp hwy water other unemp || region: ||}
		{cmd:state:, mle}{p_end}
{phang2}{cmd:. r2_nakagawa}{p_end}

{pstd}Three-level nested random intercepts and random slopes (coefficients){p_end}
{phang2}{cmd:. mixed gsp private emp hwy water other unemp || region:emp }
		{cmd: || state:unemp, mle}{p_end}
{phang2}{cmd:. r2_nakagawa}	{p_end}

{pstd}Two-way crossed random effects{p_end}
{phang2}{cmd:. mixed gsp private emp hwy water other unemp || _all: R.region || _all: R.state, mle}{p_end}
{phang2}{cmd:. r2_nakagawa}	{p_end}
{hline}

{marker results}{...}
{title:Saved results}

{pstd}{cmd:r2_nakagawa} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(Var_f)}}variance of the fixed effects{p_end}
{synopt:{cmd:r(Var_re)}}variance of the random effects{p_end}
{synopt:{cmd:r(Var_e)}}variance of the random effects residuals {p_end}
{synopt:{cmd:r(r2_c)}}conditional R-squared {p_end}
{synopt:{cmd:r(r2_m)}}marginal R-squared{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Nakagawa, S., and H. Schielzeth. 2013. A general and simple method for obtaining R2 from generalized linear mixed-effects models. 
{it:Methods in Ecology and Evolution} 4: 133–142.

{phang}
Johnson, P. C. D. 2014. Extension of Nakagawa and Schielzeth's R2 GLMM to random slopes models. 
{it:Methods in Ecology and Evolution} 5: 944–946. 


{marker citation}{...}
{title:Citation of {cmd:r2_nakagawa}}

{p 4 8 2}{cmd:r2_nakagawa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Klein, D., and A. Linden. 2024. r2_nakagawa: Stata module for computing Nakagawa's R-squared statistic for multilevel mixed-effects linear regression.
{p_end}


{marker authors}{...}
{title:Authors}

{p 4 4 2}
Daniel Klein{break}
klein.daniel.81@gmail.com{break}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}


{marker acknowledgments}{...}
{title:Acknowledgments}

{p 4 4 2}
We wish to thank John Moran for advocating that we write this package.
