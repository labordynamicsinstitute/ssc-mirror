{smcl}
{* *! version 1  2024-12-13}{...}
{viewerjumpto "Syntax" "multisite_varITT##syntax"}{...}
{viewerjumpto "Description" "multisite_varITT##description"}{...}

{title:Title}

{p 4 8}
{cmd:multisite_varITT} {hline 2} Estimates and conducts inference on the variance of ITTs across sites in multi-site randomized trials, 
and provides the ratio of the standard deviation of ITTs across sites to the average ITT, see Section 4.1 of de Chaisemartin & Deeb (2024). 
The command can also be used to estimate the variance of ITT effects across strata in stratified RCTs.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite_varITT outcome instrument site} [if] [aweight]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:outcome} is the dependent variable of interest.
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
{it:What are the data requirements to use this command?}
{p_end}

{p 4 4} The command requires that the data be from a multi-site (stratified) randomized experiment, with at least two units assigned to treatment and control per site (stratum). As such, the command automatically drops any sites (strata) not satisfying this requirement.
{p_end}

{p 4 8}
{it:The results in the paper allow for weights w_s, what w_s does the command use?}
{p_end}

{p 4 4} The command automatically weights each site by its sample size: w_s=n_s/n
{p_end}

{p 4 8}
{it:What does [aweight] do then?}
{p_end}

{p 4 4}
[aweight] allows to use weights to estimate the ITT effects in each site, and the variance of those effects. [aweight] does not affect w_s. 
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
