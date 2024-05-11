{smcl}
{* *! version 1  2019-02-25}{...}
{viewerjumpto "Syntax" "twowayfeweights##syntax"}{...}
{viewerjumpto "Description" "twowayfeweights##description"}{...}
{viewerjumpto "Options" "twowayfeweights##options"}{...}
{title:Title}

{p 4 8}
{cmd:twowayfeweights} {hline 2} Estimates the weights attached to the two-way fixed effects regressions
studied in de Chaisemartin & D'Haultfoeuille (2020a),
as well as summary measures of these regressions' robustness to heterogeneous treatment effects.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:twowayfeweights Y G T D [D0]} {if}
[{cmd:,}
{cmd:type(}{it:string}{cmd:)}
{cmd:summary_measures}
{cmd:test_random_weights(}{it:varlist}{cmd:)}
{cmd:controls(}{it:varlist}{cmd:)}
{cmd:other_treatments(}{it:varlist}{cmd:)}
{cmd:weight(}{it:varlist}{cmd:)}
{cmd:path(}{it:string}{cmd:)}]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:Y} is the dependent variable in the regression.
{cmd:Y} is the level of the outcome if one wants to estimate the weights attached to the fixed-effects regression,
and {cmd:Y} is the first difference of the outcome if one wants to estimate the weights attached to the first-difference regression.
{p_end}

{p 4 8}
{cmd:G} is a variable identifying each group.
{p_end}

{p 4 8}
{cmd:T} is a variable identifying each period.
{p_end}

{p 4 8}
{cmd:D} is the treatment variable in the regression.
{cmd:D} is the level of the treatment if one wants to estimate
the weights attached to the fixed-effects regression,
and {cmd:D} is the first difference of the treatment
if one wants to estimate the weights attached to the first-difference regression.
{p_end}

{p 4 8}
If {cmd:type(}{it:fdTR}{cmd:)} is specified in the option {cmd:type} below,
then the command requires a fifth argument, {cmd:D0}.
{cmd:D0} is the mean of the treatment in group g and at period t.
It should be non-missing at the first period
when a group appears in the data
(e.g. at t=1 for the groups that are in the data from the beginning),
and for all observations for which the first-difference of
the group-level mean outcome and treatment are non missing.
{p_end}

{marker options}{...}
{title:Options}

{p 4 8}
{cmd:type} is a required option that can take four values:
{it:feTR, feS, fdTR, fdS}.
If {it:feTR} is specified,
the command estimates the weights and sensitivity measures attached
to the fixed-effects regression under the common trends assumption.
With {it:feS},
it estimates the weights and sensitivity measures attached
to the fixed-effects regression under common trends and the assumption that groups' treatment
effect does not change over time.
With {it:fdTR}, it estimates the weights
and sensitivity measures attached to the first-difference regression under the common trends assumption.
Finally, with {it:fdS} it estimates the weights
and sensitivity measures attached to the first-difference regression
under common trends and the assumption that groups' treatment
effect does not change over time.
{p_end}

{p 4 8}
{cmd: summary_measures} displays complementary results from the computation of the weights. 
Specifically, the option outputs: ({it:i}) the point estimate of the coefficient on the {cmd:D} variable from a TWFE regression, 
({it:ii}) the minimum value of the standard deviation of the ATEs compatible with the coefficient from the TWFE regression 
and ATE across all treated (g,t) cells being equal to zero, ({it:iii}) the minimum value of the 
standard deviation of the ATEs compatible with the coefficient from the TWFE regression and ATE across 
all treated (g,t) cells having different signs (this is computed only if the sum of negative weights is 
different from 0). See the FAQ section for other details.

{p 4 8}
{cmd:test_random_weights} when this option is specified, the command estimates
the correlation between each variable in {it:varlist} and the weights.
Testing if those correlations significantly differ
from zero is a way to assess whether the weights are as good as randomly assigned to groups and time periods.
When {cmd:other_treatments} is specified,
the command only reports the correlation between each variable
and the weights attached to the main treatment,
not the correlations between each variable and the contamination weights attached to the other treatments.
{p_end}

{p 4 8}
{cmd:controls} is a list of control variables that are included in the regression.
Controls should not vary within each group*period cell,
because the results in in de Chaisemartin & D'Haultfoeuille (2020a)
apply to two-way fixed effects regressions with group*period level controls.
If a control does vary within a group*period cell,
the command will replace it by its average value within each group*period cell.
{p_end}

{p 4 8}
{cmd:other_treatments} is a list of other treatment variables
that are included in the regression.
While the results in de Chaisemartin & D'Haultfoeuille (2020a)
do not cover two-way fixed effects regressions with several treatments,
those in de Chaisemartin & D'Haultfoeuille (2020b) do, so the command follows results from that second paper
when {cmd:other_treatments} is specified.
This option can only be used when {cmd:type(}{it:feTR}{cmd:)} is specified.
When it is specified,
the command reports the number and sum of positive and negative weights attached to the treatment,
but it does not report the summary measures of the regression's robustness to heterogeneous treatment effects,
as these summary measures are no longer applicable when the regression has several treatment variables.
The command also reports the weights attached to the other treatments.
The weights reported by the command are those in Corollary 1 in de Chaisemartin & D'Haultfoeuille (2020b).
See de Chaisemartin & D'Haultfoeuille (2020b) for further details.
{p_end}

{p 4 8}
{cmd:weight} if the regression is weighted,
the weight variable can be specified in {cmd:weight}.
If {cmd:type(}{it:fdTR}{cmd:)} is specified,
then the weight variable should be non-missing at the first period when a group appears
in the data (e.g. at t=1 for the groups that are in the data from the beginning),
and for all observations for which the first-difference
of the group-level mean outcome and treatment are non missing.
{p_end}

{p 4 8}
{cmd:path} allows the user to specify a path
(e.g D:\FolderName\project.dta) where a .dta file containing 3 variables
(Group, Time, Weight) will be saved.
This option allows the user to see the weight attached to each group*time cell.
If the {cmd:other_treatments} option is specified,
the weights attached to the other treatments are also saved in the .dta file.
{p_end}

{marker FAQ}{...}
{title:FAQ}

{p 4 8}
{it:How can one interpret the summary measures of the regression's robustness to heterogeneous treatment effects?}
{p_end}

{p 4 4} When the two-way fixed effects regression has only one treatment variable,
the command reports two summary measures of the robustness
of the treatment coefficient beta to treatment heterogeneity across groups and over time.
The first one is defined in point
(i) of Corollary 1 in de Chaisemartin & D'Haultfoeuille (2020a).
It corresponds to the minimal value of the standard deviation
of the treatment effect across the treated groups and time periods
under which beta and the average treatment effect on the treated (ATT) could be of opposite signs.
When that number is large,
this means that beta and the ATT can only be of opposite signs if there is a lot of
treatment effect heterogeneity across groups and time periods.
When that number is low,
this means that beta and the ATT can be of opposite signs even if there is not a lot of
treatment effect heterogeneity across groups and time periods.
The second summary measure is defined in point
(ii) of Corollary 1 in de Chaisemartin & D'Haultfoeuille (2020a).
It corresponds to the minimal value of the standard deviation of the treatment effect across the treated groups and time periods
under which beta could be of a different sign than the treatment effect in all the treated group and time periods.
{p_end}

{p 4 8}
{it:How can I tell if the first summary measure is high or low?}
{p_end}

{p 4 4}
Assume that the first summary measure is equal to x. How can you tell if x is a low or a high amount 
of treatment effect heterogeneity? This is not an easy question to answer, but here is one possibility.  
Let us assume that the treatment effects of (g,t) cells are drawn from a uniform distribution. Then, to 
have that the mean of that distribution is 0 while its standard deviation is x, the treatment effects 
should be uniformly distributed on the [-sqrt(3)x,sqrt(3)x] interval. Then, you can ask yourself: is it 
reasonable to assume that some (g,t) cells have a treatment effect as large as sqrt(3)x, while other cells 
have a treatment effect as low as -sqrt(3)x? If the answer is negative (you think that it is not reasonable 
to assume that the treatment effect will exceed the +/-sqrt(3)x bounds for some (g,t) cells), this means that 
the uniform distribution of treatment effects compatible with an ATT of 0 and a standard deviation of x seems 
implausible to you. Then, you can consider that the command's first summary measure is high, and that it is 
unlikely that beta and the ATT are of a different sign. Conversely, if the answer is positive (you believe 
that the treatment effect might exceed the bounds for some (g,t) cells), it may not be unlikely that beta and the ATT are of a different sign. 
{p_end}

{p 4 4}
The previous sensitivity exercise assumes that treatment effects follow a uniform distribution. You may find
 it more reasonable to assume that they are, say, normally distributed. Then you can conduct the following, 
 similar exercise. If the treatment effects of (g,t) cells are drawn from a normal distribution with mean 0 
 and standard deviation x normal distribution, 95% of them will fall within the [-1.96x,1.96x] interval, and 
 5% will fall outside of that interval. Then, you can ask yourself: is it reasonable to assume that 2.5% of 
 (g,t) cells have a treatment effect larger than 1.96x, while 2.5% have a treatment effect lower than -1.96? 
 If the answer is negative (you are willing to assume that at most 2.5% of the treatment effects fall out of 
 the [-1.96x,1.96x] interval at each side), this means that the normal distribution of treatment effects compatible 
 with an ATT of 0 and a standard deviation of x seems implausible to you. Then, you can consider that the command's 
 first summary measure is high, and that it is unlikely that beta and the ATT are of a different sign.
{p_end}

{p 4 8}
{it:How can I tell if the second summary measure is high or low?}
{p_end}

{p 4 4}
Assume that the second summary measure is equal to x. To fix ideas, let us assume that beta>0. Let us 
assume that the treatment effects of (g,t) cells are drawn from a uniform distribution.  Then, one could
 have that those effects are all negative, with a standard deviation equal to x, for instance if they are 
 uniformly drawn from the [-2sqrt(3)x,0]. Then, you can ask yourself: is it reasonable to assume that some 
 (g,t) cells have a treatment effect as low as -2sqrt(3)x? If the answer is negative (you are not willing 
 to assume that some (g,t) cells have a treatment effect lower than -2sqrt(3)x), this means that the uniform 
 distribution of treatment effects compatible with sign reversal and a standard deviation of x seems implausible 
 to you. Then, you can consider that the command's second summary measure is high, and that sign reversal is unlikely.
  If the treatment effects of (g,t) cells are all negative, they cannot follow a normal distribution, so we do not discuss that possibility here.
{p_end}

{p 4 8}
{it:Can I export twowayfeweights output to LaTeX?}
{p_end}

{p 4 4}
Yes. The ado file includes a {cmd:twowayfeweights_out} subcommand to export the main table as a LaTeX tabular or standalone. Please refer to this {browse "https://github.com/chaisemartinPackages/twowayfeweights/blob/main/vignettes/vignette_1.md":tutorial} for further details.
{p_end}

{marker example}{...}
{title:Example}

The following example is based on data from F. Vella and M. Verbeek (1998), "Whose Wages Do Unions Raise? A Dynamic Model of Unionism and Wage Rate Determination for Young Men". 
Results and further details about the estimation below can be found in Section V.C of de Chaisemartin & D'Haultfoeuille (2020a).
Run the following line to load the dataset:

{phang2}use "https://raw.githubusercontent.com/chaisemartinPackages/twowayfeweights/main/wagepan_twfeweights.dta", clear{p_end}

The next line estimates the weights from a TWFE regression of log wage (Y) on union status (D), individual worker (G) and year (T) fixed effects:

{phang2}{stata twowayfeweights lwage nr year union, type(feTR) test_random_weights(educ) summary_measures}{p_end}

The next line performs the same exercise using first differences of outcome and treatment:

{phang2}{stata twowayfeweights diff_lwage nr year diff_union union, type(fdTR) test_random_weights(educ) summary_measures}{p_end}

Please note that the number of negative weights could be different from Section V.C. of de Chaisemartin and D'Haultfoeuille (2020a) due to rounding errors that affected older versions of the commands.

{marker references}{...}
{title:References}

{p 4 8}de Chaisemartin, C and D'Haultfoeuille, X (2020a). American Economic Review, vol. 110, no. 9. 
{browse "https://www.aeaweb.org/articles?id=10.1257/aer.20181169":Two-Way Fixed Effects Estimators with Heterogeneous Treatment Effects}.{p_end}

{p 4 8}de Chaisemartin, C and D'Haultfoeuille, X (2020b).
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3751060":Two-way fixed effects regressions with several treatments}.{p_end}


{title:Authors}

{p 4 8}Clément de Chaisemartin, University of California at Santa Barbara, Santa Barbara, California, USA.{p_end}
{p 4 8}Xavier D'Haultfoeuille, CREST, Palaiseau, France.{p_end}
{p 4 8}Antoine Deeb, University of California at Santa Barbara, Santa Barbara, California, USA.{p_end}

{p 4 8}The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899).{p_end}

{title:Contact}

GitHub: {browse "https://github.com/chaisemartinPackages/twowayfeweights":chaisemartinPackages/twowayfeweights}

Mail: {browse "mailto:chaisemartin.packages@gmail.com":chaisemartin.packages@gmail.com}
