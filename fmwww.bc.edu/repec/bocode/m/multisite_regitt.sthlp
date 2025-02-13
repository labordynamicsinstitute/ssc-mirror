{smcl}
{* *! version 1  2024-12-13}{...}
{viewerjumpto "Syntax" "multisite_regITT##syntax"}{...}
{viewerjumpto "Description" "multisite_regITT##description"}{...}
{viewerjumpto "Options" "multisite_regITT##options"}{...}

{title:Title}

{p 4 8}
{cmd:multisite_regITT} {hline 2} This command computes the coefficients from a regression of site-level ITTs on site-level characteristics in multi-site randomized trials
studied in de Chaisemartin & Deeb (2024), the standard errors of those coefficients, and the regression's R-squared. 
The command can also be applied to stratified RCTs, to compute the coefficients from a regression of strata-level ITTs on strata-level characteristics. 
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8}{cmd:multisite_regITT outcome instrument site} [if] [aweight] [{cmd:,}
{cmd:controls(}{it:varlist numeric}{cmd:)}
{cmd:mediators(}{it:varlist numeric}{cmd:)}
{cmd:y0}
{cmd:fs(}{it:treatment numeric}{cmd:)}
]
{p_end}

{synoptset 28 tabbed}{...}

{marker description}{...}
{title:Description}

{p 4 8}
{cmd:outcome} is the main outcome variable of interest.
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
{cmd:controls(}{it:varlist}{cmd:)} gives the list of site-level characteristics {bf:that are observed and do not need to be estimated} to be included in the regression.
{p_end}

{p 4 8}
{cmd:mediators(}{it:varlist}{cmd:)} gives the list of mediators to be included in the regression. Mediators are variables that could be affected by the treatment, and that effect could in turn explain
the treatment's effect on the main outcome variable. Therefore, mediators are other outcome variables, {bf:whose site-level ITTs need to be estimaded}. 
{p_end}

{p 4 8}
{cmd: y0} indicates that the site's average outcome without a treatment offer should be included in the regression. This can be used to assess if ITT effects are lower or larger in sites with a high y0, to assess if treatment offers reduce or increase
inequalities across sites. 
{p_end}

{p 4 8}
{cmd: fs(}{it:treatment}{cmd:)} indicates that the site's first-stage effect should be included in the regression. {it:treatment} is an indicator variable for whether a unit is treated.
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