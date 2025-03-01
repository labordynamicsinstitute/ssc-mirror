{smcl}
{* *! version 1  2024-12-13}{...}
{viewerjumpto "Syntax" "multisite_regITT##syntax"}{...}
{viewerjumpto "Description" "multisite_regITT##description"}{...}
{viewerjumpto "Options" "multisite_regITT##options"}{...}

{title:Title}

{p 4 8}
{cmd:multisite_regLATE} {hline 2} This command estimates the sign of coefficients from univariate regressions of site-level LATEs on site-level characteristics in multi-site randomized trials,
see Section 5.1 of de Chaisemartin & Deeb (2024). 
The command can also be applied to stratified RCTs, to compute the coefficients from a regression of strata-level LATEs on strata-level characteristics. 
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite_regLATE outcome treatment instrument site} [if] [aweight] [{cmd:,}
{cmd:controls(}{it:varlist numeric}{cmd:)}
{cmd:mediators(}{it:varlist numeric}{cmd:)}
{cmd:y0}
{cmd:fs}
]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:outcome} is the main outcome variable of interest.
{p_end}

{p 4 8}
{cmd:treatment} is an indicator variable for whether a unit is treated.
{p_end}

{p 4 8}
{cmd:instrument} is an indicator variable for whether a unit is assigned to treatment.
{p_end}

{p 4 8}
{cmd:site} is a numeric variable identifying each site/stratum.
{p_end}

{marker options}{...}
{title:Options}

{p 4 8}
{cmd:controls(}{it:varlist}{cmd:)} gives the list of site-level characteristics {bf:that are observed and do not need to be estimated} whose coefficients' sign has to be estimated.
{p_end}

{p 4 8}
{cmd:mediators(}{it:varlist}{cmd:)} gives the list of mediators whose coefficients' sign has to be estimated. Mediators are variables that could be affected by the treatment, and that effect could in turn explain
the treatment's effect on the main outcome variable. Therefore, mediators are other outcome variables, {bf:whose site-level ITTs need to be estimaded}. 
{p_end}

{p 4 8}
{cmd: y0} indicates that the sign of the coefficient on sites' average outcome without a treatment offer should be estimated. This can be used to assess if LATEs are lower or larger in sites with a high y0.
{p_end}

{p 4 8}
{cmd: fs} indicates that the sign of the coefficient on sites' first-stage effect should be estimated. This can be used to assess if sites with the largest treatment take up rate also have the largest LATEs, which would be consistent with a Roy model.
{p_end}

{marker FAQ}{...}
{title:FAQ}

{p 4 8}
{it:What are the data requirements and assumptions required to use this command?}
{p_end}

{p 4 4} The command requires that the data be from a multi-site (stratified) randomized experiment, with at least two units assigned to treatment and control per site (stratum). As such, the command automatically drops any sites (strata) not satisfying this requirement.
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