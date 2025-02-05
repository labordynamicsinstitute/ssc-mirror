{smcl}
{* Last modified: 21 Jan 2025}{...}
{hline}
help for {hi:ginidecomp}{right: Authors: Vesa-Matti Heikkuri and Matthias Schief (revised Jan 2025)}
{hline}

{title:Syntax}

{p 8 17 2} {cmd:ginidecomp} {it:varname} [{it:weights}] 
	[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
	[, {cmdab:by:group}{cmd:(}{it:groupvar}{cmd:)}]


{p 4 4 2} {cmd:fweight}s, {cmd:aweights}, {cmd:pweights}, and {cmd:iweights} 
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



{title:Saved results} 

    r(gini)             Aggregate Gini coefficient

    r(within)           Within-group inequality 
    r(between)          Between-group inequality 

    r(within_pct)       Within-group inequality (%)
    r(between_pct)      Between-group inequality (%)


{title:Examples}

{p 4 8 2}{cmd:. ginidecomp income [aw = wgtvar]}

{p 4 8 2}{cmd:. ginidecomp income, by(age_group) }

{p 4 8 2}{cmd:. ginidecomp income if fullTimeWork==1, by(age_group)}

{p 4 8 2}{cmd:. ginidecomp income, by(age_group sex)}

{p 4 8 2}{cmd:. ginidecomp income if !missing(age_group) & !missing(sex), by(age_group sex)}

{p 4 8 2}{cmd:. ginidecomp income in 1/100, by(sex)}


{title:Authors}

{p 4 4 2}Vesa-Matti Heikkuri <vesa-matti.heikkuri@tuni.fi>{break}
Tampere University

{p 4 4 2}Matthias Schief <matthias.schief@oecd.org>{break}
Organisation for Economic Co-operation and Development (OECD)

{title:Acknowledgements}

{p 4 4 2} The program ginidecomp partly builds on "ineqdecgini.ado" by Stephen P. Jenkins

{title:References}

{p 4 4 2} Heikkuri, Vesa-Matti, and Matthias Schief. {it:Subgroup Decomposition of the Gini Coefficient: A New Solution to an Old Problem}. FIT Working Paper 30, 2024. 
{browse "https://verotutkimus.fi/verotutkimus/wp-content/uploads/2024/12/FIT-WP-30-Heikkuri-Schief-Gini-Decomposition-3.pdf"}.

