{smcl}
{* Last modified: 21 Jan 2025}{...}
{hline}
help for {hi:ginidecomp}{right: Authors: Vesa-Matti Heikkuri, Matthias Schief and Aapo Välimäki (revised Nov 2025)}
{hline}


{title:Syntax}

{p 8 17 2} {cmd:ginidecomp} {it:varname} [{it:weights}] 
	[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
	[{cmd:,} {it:options}]

{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt:{opt by:group(groupvar)}} define population subgroups based on the unique combinations of values across all the specified variables{p_end}

{synopt:{opt conf:idenceintervals}} calculate confidence intervals for the decomposition{p_end}

{synopt:{opt confidencelevel(int)}} adjust confidence level{p_end}

{synopt:{opt fulldataset}} override Monte Carlo integration

{synopt:{opt threshold(int)}} adjust threshold of Monte Carlo integration

{synoptline}

{p2colreset}{...}
{p 4 6 2}

{p 4 4 2} {cmd:fweight}s, {cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s
are allowed; see {help weights}.

{p 4 4 2} 
Multiple variables may be provided as {it:groupvar}. In this case, the program will use the {cmd: egen group()} command to define population subgroups based on the unique combinations of values across all the specified variables; see {help egen}. 


{title:Description}

{p 4 4 2} 
The {cmd:ginidecomp} command calculates the Gini coefficient and decomposes it by population subgroups. The decomposition follows the methodology introduced in Heikkuri and Schief (2024). 

{p 4 4 2} 
By default, missing values in the {it:groupvar} variables are treated as group identifiers. If you wish to exclude observations with missing {it:groupvar} values, you should use the {cmd:if} {it:!missing(groupvar)} option (see example below).

{p 4 4 2} 
If the {cmdab:by:group} option is not specified, the program only returns the aggregate Gini coefficient.

{p 4 4 2}
If the weight-variable contains non-integer values, choosing {cmd:fweight} will result in an error. Otherwise, the type of weight makes no difference computationally, although using {cmd:fweight} is recommended whenever it's appropriate.


{title:Technical details}

{p 4 4 2}
Consider a population that is partitioned into K subgroups and suppose we want to decompose income inequality. Subgroup k’s Gini coefficient, population share, and income share are denoted by G_k, pi_k, and theta_k, respectively.

{p 4 4 2}
The within-group inequality term is a weighted power mean of subgroup Gini coefficients with each subgroup weighted by the geometric mean of its
income and population share:

{p 17 17 2}
G_w = [∑ (pi_k  theta_k G_k)^(1/2)]^2

{p 4 4 2}
The between-group inequality is the difference between the cross mean absolute difference, Theta, and a weighted sum of geometric averages of subgroup mean absolute differences, delta_k, divided by twice the aggregate mean, mu:

{p 17 17 2}
G_w = (2 mu)^(-1) [Theta - ∑∑ pi_k pi_l sqrt(delta_k delta_l)] 

{p 4 4 2}
Theta is obtained as the population mean absolute difference when evaluating all within-group differences as zero. For details, see Heikkuri and Schief (2024).


{title:Options}

{p 4 8 2} 
{cmd:bygroup(}{it:groupvar}{cmd:)} requests inequality decompositions by population
subgroup, with subgroup membership defined by {it:groupvar}.

{p 4 8 2}
{cmd:confidenceintervals} requests confidence intervals for the inequality decomposition.

{p 4 8 2}
{cmd:confidencelevel(}{it:int}{cmd:)} adjusts confidence level according to {it:int}. The default is 95%. Note that the option {cmd:confidenceintervals} may be omitted if {cmd:confidencelevel({it:int})} is used.

{p 4 8 2}
{cmd:fulldataset} prevents the use of Monte Carlo integration. By default, Monte Carlo integration is used when the relevant data size exceeds a critical threshold. See further details in the remarks-section.

{p 4 8 2}
{cmd:threshold(}{it:int}{cmd:)} adjust the size of the threshold after which Monte Carlo integration is used. 


{title:Saved results} 

    r(gini)             Aggregate Gini coefficient

    r(within)           Within-group inequality 
    r(between)          Between-group inequality 

    r(within_share)     Share of Within-group inequality
    r(between_share)    Share of Between-group inequality

    r(G_se)		Standard error of aggregate Gini
    r(Gw_se)		Standard error of Within-group inequality
    r(Gb_se)		Standard error of Between-group inequality
    r(share_se)		Standard error of Within/Between-group inequality


{title:Examples}

{p 4 8 2}{cmd:. ginidecomp income [aw = wgtvar]}

{p 4 8 2}{cmd:. ginidecomp income, by(age_group)}

{p 4 8 2}{cmd:. ginidecomp income if fullTimeWork==1, by(age_group)}

{p 4 8 2}{cmd:. ginidecomp income, by(age_group sex)}

{p 4 8 2}{cmd:. ginidecomp income if !missing(age_group) & !missing(sex), by(age_group sex)}

{p 4 8 2}{cmd:. ginidecomp income in 1/100, by(sex)}

{p 4 8 2}{cmd:. ginidecomp income if year == 2025 [aw = wgtvar], by(age_group)}

{p 4 8 2}{cmd:. ginidecomp income, by(age_group sex) confidenceintervals}

{p 4 8 2}{cmd:. ginidecomp income, by(age_group) conf fulldataset}

{p 4 8 2}{cmd:. ginidecomp income, by(sex) confidencelevel(99) threshold(5000)}


{title:Remarks}

{p 4 4 2}
The computation of the confidence intervals involves creating square matrices from the dataset. The largest of these matrices (used to compute aggregate components) are of size {cmd:(nxn)}, where {cmd:n} is the total number of observations.
Other matrices (used to compute subgroup specific components) are of size {cmd:(mxm)}, where {cmd:m} is the number of observations belonging to a given subgroup. For big datasets and subgroups, these matrices can become computationally hard to handle. 
{p_end}

{p 4 4 2}
The default dynamic approach handles this issue by using Monte Carlo integration when the number of rows in a matrix would exceed a threshold, which is set to 10,000 by default.
The option {cmd:fulldataset} overrides this feature and forces the program to never use Monte Carlo integration.
{p_end}

{p 4 4 2}
While the program parses your dataset according to the {cmd:"if"} and {cmd:"in"} arguments you pass it, it's often advisable to instead pass smaller chunks of the dataset to the program using {cmd:preserve}, {cmd:drop / keep}, and {cmd:restore}. 
This can make a massive difference in runtime when you have a large dataset and you want to run {cmd:ginidecomp} using only relatively small portions of it. 
A typical example of this would be a situation where you have a dataset spanning several years, and you want to calculate the decomposition and the confidence intervals for each year.
{p_end}


{title:Authors}

{p 4 4 2}Vesa-Matti Heikkuri <vesa-matti.heikkuri@tuni.fi>{break}
Tampere University

{p 4 4 2}Matthias Schief <matthias.schief@oecd.org>{break}
Organisation for Economic Co-operation and Development (OECD)

{p 4 4 2}Aapo Välimäki <aapo.j.valimaki@tuni.fi>{break}
Tampere University

{title:Acknowledgements}

{p 4 4 2} The program ginidecomp partly builds on "ineqdecgini.ado" by Stephen P. Jenkins


{title:References}

{p 4 4 2} Heikkuri, Vesa-Matti, and Matthias Schief. {it:Subgroup Decomposition of the Gini Coefficient: A New Solution to an Old Problem}. FIT Working Paper 30, 2024. 
{browse "https://verotutkimus.fi/verotutkimus/wp-content/uploads/2024/12/FIT-WP-30-Heikkuri-Schief-Gini-Decomposition-3.pdf"}.
