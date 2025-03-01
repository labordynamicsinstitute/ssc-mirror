{smcl}
{* *! version 1  2024-12-13}{...}
{viewerjumpto "Syntax" "multisite_varLATE##syntax"}{...}
{viewerjumpto "Description" "multisite_varLATE##description"}{...}

{title:Title}

{p 4 8}
{cmd:multisite_varLATE} {hline 2} Estimates and conducts inference on the variance of LATEs across sites in multi-site randomized trials, and provides the ratio of the standard deviation of LATEs across sites to the average LATE, see Section 5.2 of de Chaisemartin & Deeb (2024).
The command can also be used to estimate the variance of LATEs across strata in stratified RCTs.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite_varLATE outcome treatment instrument site} [if] [aweight]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:outcome} is the dependent variable of interest.
{p_end}

{p 4 8}
{cmd:treatment} is an indicator variable for whether a unit is treated
{p_end}

{p 4 8}
{cmd:instrument} is an indicator variable for whether a unit is assigned to treatment
{p_end}

{p 4 8}
{cmd:site} is a numeric variable identifying each site/stratum.
{p_end}


{marker FAQ}{...}
{title:FAQ}

{p 4 8}
{it:What are the data requirements and assumptions required to use this command?}
{p_end}

{p 4 4} The command requires that the data be from a multi-site (stratified) randomized experiment, with at least two units assigned to treatment and control per site (stratum). As such, the command automatically drops any sites (strata) not satisfying this requirement.
Estimating the variance of LATEs across sites requires additional assumptions, please refer to Assumption 5 in {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4615304":Estimating treatment-effect heterogeneity across sites, in multi-site randomized experiments with few units per site}
{p_end}

{p 4 8}
{it:The results in the paper allow for weights w_s, what w_s does the command use?}
{p_end}

{p 4 4} The command uses w_s=n_s/n, the proportion that site s accounts for in the population. Then, each site is weighted by the product of w_s and its first-stage effect, thus weighting each site in proportion to its number of compliers.
{p_end}

{p 4 8}
{it:What does [aweight] do then?}
{p_end}

{p 4 4}
[aweight] allows to use weights to estimate the ITT and FS effects in each site, and the variance of those effects. [aweight] does not affect w_s. 
{p_end}

{marker references}{...}
{title:References}

{p 4 8}de Chaisemartin, C and Deeb, A (2024).
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4615304":Estimating treatment-effect heterogeneity across sites, in multi-site randomized experiments with few units per site}.{p_end}



{title:Authors}

{p 4 8}Clément de Chaisemartin, Sciences Po.{p_end}
{p 4 8}Antoine Deeb, World Bank.{p_end}
{p 4 8}Bingxue Li, Sciences Po.{p_end}

{title:Contact}
{browse "mailto:adeeb1@worldbank.org":adeeb1@worldbank.org}
{browse "mailto:bingxue.li@sciencespo.fr":bingxue.li@sciencespo.fr}
{browse "mailto:chaisemartin.packages@gmail.com":chaisemartin.packages@gmail.com}
