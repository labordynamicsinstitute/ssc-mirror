{smcl}
{* *! version 1  2024-05-04}{...}
{viewerjumpto "Syntax" "stute_test##syntax"}{...}
{viewerjumpto "Description" "stute_test##description"}{...}
{viewerjumpto "Vignettes" "stute_test##vignettes"}{...}
{viewerjumpto "Options" "stute_test##options"}{...}
{viewerjumpto "Examples" "stute_test##examples"}{...}
{viewerjumpto "Saved results" "stute_test##saved_results"}{...}

{title:Title}

{p 4 4}
{cmd:stute_test} {hline 2} Stute (1997) linearity test.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 4}
{cmd:stute_test Y D [G T] {ifin}}
[{cmd:,}
{cmd:order(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)}
{cmd:brep(}{it:#}{cmd:)}
{cmd:baseline(}{it:#}{cmd:)}
{cmd:no_updates}]
{p_end}

{p 4 4}
where:
{p_end}

{p 6 6}
{cmd:Y} is the dependent variable.
{p_end}

{p 6 6}
{cmd:D} is the independent variable.
{p_end}

{p 6 6}
{cmd:G} is the group variable.
{p_end}

{p 6 6}
{cmd:T} is the time variable.
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 4}
This program implements the non-parametric test that
the expectation of Y given D is linear proposed by Stute (1997).
In the companion vignette, we sketch the intuition behind the test, as 
to motivate the use of the package and its options. 
Please refer to Stute (1997) and 
Section 3 of de Chaisemartin and D'Haultfoeuille (2024) for further details.
{p_end}

{p 4 4}
This package allows for two estimation settings:
{p_end}

{p 6 6}
1. {cmd:cross-section}: {cmd: stute_test Y D}
{p_end}
{p 9 9}
The test is run using the full dataset, treating each 
observation as an independent realization of
({cmd:Y}, {cmd:D}). 
{p_end}

{p 6 6}
2. {cmd:panel}: {cmd: stute_test Y D G T}
{p_end}
{p 9 9}
The test is run for all values of {cmd:T}, using a panel 
with {cmd:G} groups/units and {cmd:T} periods. 
In this mode, the test statistics will be computed
among observations having the same value of {cmd:T}.
The program will also return a joint test on the sum 
of the period-specific estimates.
Due to the fact that inference on the joint statistic
is performed via the bootstrap distribution of the 
sum of the test statistics across time periods, this 
mode requires a {bf:strongly balanced panel} with no gaps.
This requirement can be checked by running {stata xtset G T}.
{p_end}

{marker vignettes}{...}
{title:Vignettes}

{p 4 4}
Before calling the vignette, please 
make sure to run the following lines:
{p_end}

{p 6 6}{stata ssc install stute_test, replace}{p_end}
{p 6 6}{stata net get stute_test}{p_end}

{p 4 4}
The first line updates the package to its latest version,
while the second updates the vignette.
If there is no error message, the following line 
calls the html file of the {cmd:stute_test} vignette:
{p_end}

{p 6 6}
{browse "stute_test.html": The intuition behind stute_test.}
{p_end}

{marker options}{...}
{title:Options}

{p 4 4}
{cmd:order(}{it:#}{cmd:)}
If this option is specified, the program tests
whether the conditional expectation of {cmd:Y} given {cmd:D} is
a {it:#}-degree polynomial in {cmd:D}.
With {cmd:order(}{it:0}{cmd:)}, the command tests 
the hypothesis that the conditional mean of {cmd:Y} 
given {cmd:D} is constant.
{p_end}

{p 4 4}
{cmd:seed(}{it:#}{cmd:)}
This option allows to specify the seed
for the wild bootstrap routine.
{p_end}

{p 4 4}
{cmd:brep(}{it:#}{cmd:)}
This option allows to specify the number
of wild bootstrap replications. The default is 500.
{p_end}

{p 4 4}
{cmd:baseline(}{it:#}{cmd:)}
This option allows to select one of the periods
in the data as the baseline or omitted period.
For instance, in a dataset with the support 
of {cmd:T} equal to (2001, 2002, 2003),
{cmd:stute_test Y D G T, baseline(2001)} will 
test the hypotheses that the expectations of 
{cmd:Y}_2002 - {cmd:Y}_2001 and {cmd:Y}_2003 
- {cmd:Y}_2001 are linear functions of
{cmd:D}_2002 - {cmd:D}_2001 and {cmd:D}_2003 
- {cmd:D}_2001. This option can only be
specified in {cmd:panel} mode.
{p_end}

{p 4 8}
{cmd:no_updates}: this option stops 
automatic self-updates of the 
program, which are performed 
(on average) every 100 runs.
{p_end}

{marker examples}{...}
{title:Examples}
{phang2}{stata clear}{p_end}
{phang2}{stata set seed 0}{p_end}
{phang2}{stata set obs 200}{p_end}
{phang2}{stata gen G = mod(_n-1, 40) + 1}{p_end}
{phang2}{stata gen T = floor((_n-1)/40) + 1}{p_end}
{phang2}{stata gen D = uniform()}{p_end}
{phang2}{stata gen Y = 1 + uniform()*D}{p_end}

{phang2}{stata stute_test Y D, seed(0)}{p_end}
{phang2}{stata stute_test Y D G T, seed(0)}{p_end}
{phang2}{stata stute_test Y D G T, baseline(1) seed(0)}{p_end}

{marker saved_results}{...}
{title:Saved results}

{p 4 4}
{cmd:r(main)}: Matrix with results from the output table.
{p_end}

{p 4 4}
{cmd:r(joint)}: Matrix with joint test results.
{p_end}

{marker references}{...}
{title:References}
{p 4 4}
de Chaisemartin, C, D'Haultfoeuille, X (2024).
{browse "https://ssrn.com/abstract=4284811":Two-way Fixed Effects and Difference-in-Difference Estimators in Heterogeneous Adoption Designs}.
{p_end}
{p 4 4}
Stute, W (1997).
{browse "https://www.jstor.org/stable/2242560":Nonparametric model checks for regression}.
{p_end}


{marker authors}{...}
{title:Authors}
{p 4 4}
Clément de Chaisemartin, Economics Department, Sciences Po, France.
{p_end}
{p 4 4}
Xavier D'Haultfoeuille, CREST-ENSAE, France.
{p_end}
{p 4 4}
Diego Ciccia, Economics Department, Sciences Po, France.
{p_end}
{p 4 4}
Felix Knau, Economics Department, Sciences Po, France.
{p_end}
{p 4 4}
Doulo Sow, CREST-ENSAE, France.
{p_end}

{title:Contact}
{p 4 4}
If you wish to inquire about the functionalities of this package or to report bugs/suggestions, feel free to post your question in the Issue section of the {browse "https://github.com/chaisemartinPackages/stute_test":stute_test GitHub repository}. 
{p_end}

{title:Acknowledgement}
{p 4 4}
The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899).
{p_end}


