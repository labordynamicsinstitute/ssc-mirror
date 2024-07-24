{smcl}
{* *! version 1  2024-05-04}{...}
{viewerjumpto "Syntax" "yatchew_test##syntax"}{...}
{viewerjumpto "Description" "yatchew_test##description"}{...}
{viewerjumpto "Vignettes" "yatchew_test##vignettes"}{...}
{viewerjumpto "Options" "yatchew_test##options"}{...}
{viewerjumpto "Examples" "yatchew_test##examples"}{...}
{viewerjumpto "Saved results" "yatchew_test##saved_results"}{...}

{title:Title}

{p 4 4}
{cmd:yatchew_test} {hline 2} Yatchew (1997), de Chaisemartin and D'Haultfoeuille (2024) linearity test.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 4}
{cmd:yatchew_test Y D [if]}
[{cmd:,}
{cmd:het_robust}
{cmd:order(}{it:#}{cmd:)}
{cmd:path_plot}
{cmd:no_updates}]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 4}
This program implements a non-parametric test that
the expectation of Y given D is linear.
The program implements both the original test proposed
by Yatchew (1997) and its heteroskedasticity-robust version proposed 
by de Chaisemartin and D'Haultfoeuille (2024). 
In the vignettes linked below, we sketch the intuition behind the two tests, as 
to motivate the use of the package and its options. 
Please refer to Yatchew (1997) and 
Section 3 of de Chaisemartin and D'Haultfoeuille (2024) for further details.
{p_end}

{p 4 4}
Yatchew (1997) proposes a useful extension of the test 
with multiple independent variables. 
The program implements this extension when the D 
argument has more than one {it:varnames}. 
It should be noted that the power and consistency of 
the test in the multivariate case are not backed by proven 
theoretical results. We implemented this extension to allow 
for testing and exploratory research. 
Future theoretical exploration of the multivariate test will depend on the demand and usage of the package.
{p_end}

{marker vignettes}{...}
{title:Vignettes}

{browse "yatchew_test_univariate.html": Univariate Yatchew Test}

{browse "yatchew_test_multivariate.html": Multivariate Yatchew Test}

{marker options}{...}
{title:Options}

{p 4 4}
{cmd:het_robust} 
By default, the test is performed under the assumption 
of homoskedasticity (Yatchew, 1997). 
If this option is specified, the test 
is performed using the heteroskedasticity-robust 
test statistic proposed by de Chaisemartin and D'Haultfoeuille (2024).
{p_end}

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
{cmd:path_plot}
This option can be used only with exactly two {it:varnames}
as the {it:D} argument. In this case, the program will produce 
a plot of the sequence of (D_1i, D_2i) that minimizes the euclidean 
distance between each pair of consecutive observations 
(see the {it:Multivariate Yatchew Test} vignette for further details).
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
{phang2}{stata gen D = uniform()}{p_end}
{phang2}{stata gen D1 = uniform()}{p_end}
{phang2}{stata gen Y = 1 + D + D1^2}{p_end}

{phang2}{stata yatchew_test Y D}{p_end}
{phang2}{stata yatchew_test Y D1, het_robust}{p_end}
{phang2}{stata yatchew_test Y D D1, path_plot}{p_end}

{marker saved_results}{...}
{title:Saved results}

{p 4 4}
{cmd:r(results)}: Matrix with program results.
{p_end}

{marker references}{...}
{title:References}
{p 4 4}
de Chaisemartin, C, D'Haultfoeuille, X (2024).
{browse "https://ssrn.com/abstract=4284811":Two-way Fixed Effects and Difference-in-Difference Estimators in Heterogeneous Adoption Designs}.
{p_end}
{p 4 4}
Yatchew, A (1997).
{browse "https://doi.org/10.1016/S0165-1765(97)00218-8":An elementary estimator of the partial linear model}.
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
If you wish to inquire about the functionalities of this package or to report bugs/suggestions, feel free to post your question in the Issue section of the {browse "https://github.com/chaisemartinPackages/yatchew_test":yatchew_test GitHub repository}. 
{p_end}

{title:Acknowledgement}
{p 4 4}
The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899).
{p_end}


