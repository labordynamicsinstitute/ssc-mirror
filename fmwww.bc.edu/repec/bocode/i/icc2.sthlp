{smcl}
{* *! version 1.0 2024-2027}{...}
{viewerjumpto "Syntax" "icc2##syntax"}{...}
{viewerjumpto "Description" "icc2##description"}{...}
{viewerjumpto "Examples" "icc2##examples"}{...}
{viewerjumpto "References" "icc2##references"}{...}
{viewerjumpto "Author and support" "icc2##author"}{...}
{title:Title}
{phang}
{bf:icc2} {hline 2} Intraclass correlation coefficients based on crossed mixed regression


{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:icc2}
varlist(min=2
max=3)
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt r:eps(#)}} perform # bootstrap replications, see(help bootstrap:bootstrap) 

{synopt:{opt s:eed(#)}} set random-number seed to #, see(help bootstrap:bootstrap)

{synopt:{opt l:evel(#)}} set confidence level; default is level(95)

{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}Textbooks often calculate the ICC using sums of squares on a 
subject-by-measurement matrix with non-missing cells.

{pstd}The idea of the ICC is to compare the wanted variation explained by a 
factor variable on an outcome with the total variation, the total variation 
being the wanted variation by the factor variable plus the unwanted variation.{break}
Bias occurs sometimes from the measurement repetitions.

{pstd}The ANOVA-like calculations ignore all measurements by a subject if just 
one measurement for that subject is missing and may also return ICC estimates 
below zero.{break}
The latter is theoretically impossible.

{pstd}To better utilize subjects with missing measurements and avoid obtaining 
negative ICCs, it is better to use estimates from a mixed, crossed regression.

{pstd}The command -icc2- returns a matrix with the absolute and consistency ICCs 
with a 95% confidence interval and a P-value for the ICCs equal to zero.{break}
The user can obtain more precise confidence intervals using the bootstrap.


{marker examples}{...}
{title:Examples}

{phang}Setup{p_end}
{phang}{stata `". webuse judges, clear"'}{p_end}

{phang}Calculate ICCs for one-way random-effects model{p_end}
{phang}{stata `". icc2 rating target"'}{p_end}

                 |      ICC      [95%       CI]  P(ICC=0) 
    -------------+---------------------------------------
        absolute |    0.166    -0.272     0.603     0.458 

{phang}A {help mixed:mixed} crossed regression and {help nlcom:nlcom} is the 
basis for the confidence interval whereas the {help icc:icc} uses the 
F-distribution.{p_end}
{phang}{stata `". icc rating target"'}{p_end}

                    rating |        ICC       [95% conf. interval]
    -----------------------+--------------------------------------
                Individual |   .1657418      -.1329323    .7225601

{phang}We can use bootstrap options to get a more precise confidence interval.{break}
Setting the option seed alone, the default number of repetitions is 50.
{p_end}
{phang}{stata `". icc2 rating target, seed(1)"'}{p_end}

                 |      ICC      [95%       CI]  P(ICC=0) 
    -------------+---------------------------------------
        absolute |    0.166    -0.199     0.531     0.374 

{phang}Calculate ICCs for two-way random-effects model.{p_end}
{phang}{stata `". icc2 rating target judge"'}{p_end}

                 |      ICC      [95%       CI]  P(ICC=0) 
    -------------+---------------------------------------
        absolute |    0.290    -0.111     0.691     0.157 
     consistency |    0.715     0.394     1.036     0.000 

{phang}We can use the bootstrap with 100 repetitions for the confidence interval.{p_end}
{phang}{stata `". icc2 rating target judge, seed(1) reps(100)"'}{p_end}

                 |      ICC      [95%       CI]  P(ICC=0) 
    -------------+---------------------------------------
        absolute |    0.290     0.119     0.461     0.001 
     consistency |    0.715     0.560     0.870     0.000 

{phang}The difference between the absolute and consistency ICCs indicates bias from the judges.{p_end}

{phang}Calculate ICCs for two-way mixed-effects model{p_end}
{phang}As argued in 2019 Liljequist, the two-way random-effects model is the same as the two-way mixed-effects model.{p_end}
{phang}{stata `". icc2 rating target judge"'}{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(icc2)}} The absolute and consistency ICCs with a 95% confidence 
interval and a P-value for the ICCs equal to zero.{p_end}


{marker references}{...}
{title:References}

{pstd}
{break}1979 Shrout - Intraclass correlations-uses in assessing rater reliability
{break}1996 McGraw - Forming Inferences About Some Intraclass Correlation Coefficients
{break}2006 Marchenko - Estimating variance components in Stata
{break}2021 Bruun - {browse "https://www.stata.com/meeting/northern-european21/slides/Northern_Europe21_Bruun.pdf":Regression modeling for reliability/ICC in Stata}
{break}2019 Liljequist - Intraclass correlation – A discussion and demonstration of basic features


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
