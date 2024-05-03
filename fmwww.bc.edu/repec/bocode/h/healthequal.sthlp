{smcl}
{* v1.0.0 21mar2024}{...}
{hline}

{vieweralsosee "[R] help" "help help "}{...}
		{viewerjumpto "Syntax" "healthequal##syntax"}{...}
        {viewerjumpto  "Description" "healthequal##description"}{...}
        {viewerjumpto "Options" "healthequal##options"}{...}
        {viewerjumpto "Examples" "healthequal##examples"}{...}

{marker title}{...}
{title:Title}

{phang}
{bf:healthequal} {hline 2} calculates summary measures of health inequality

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:healthequal} {it:varname} [{it:{help if}}] [{it:weight}], {opt m:easure(string)} [{it:options}]

{p 4 6 2}{it:varname} specifies the variable containing the indicator estimates. Apart from the calculation of simple measures (d and r), estimates must be available for all subgroups for ordered dimensions of inequality and must be available for at least 85% of subgroups for non-ordered dimensions of inequality. The {bf:force} option can force calculations when estimates are missing.{p_end}

{p 4 6 2}{it:weight} specifies the variable containing population or sampling weights. Only {bf:pweights} are allowed; see {help weight}. For disaggregated data, this is the number of people within each subgroup (or the weighted population in the case of disaggregated estimates from a survey). For individual-level (micro) data from a survey, this is the individual sampling weight. This option is required for the calculation of aci, rci, sii and rii (unless weights are specified using {bf:svyset} and the {bf:svy} option), and are required for bgv, bgsd, cov, idisw, mdbw, mdmw, mdrw, ti and mld. It is also required for the calculation of idisu, mdmu, paf and par in the absence of the {bf:average} option and for the calculation of 95% confidence intervals of these measures.{p_end}

{synoptset 21}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt m:easure(varname)}}summary measure(s) to calculate; multiple measures may be entered, separated by spaces{p_end}

{syntab:Main}
{synopt:{opt av:erage(varname)}}indicator average for the setting{p_end}
{synopt:{opt se(varname)}}standard error of the subgroup estimates{p_end}
{synopt:{opt dim:ension(varname)}}whether the dimension is ordered (0) or non-ordered / binary (0){p_end}
{synopt:{opt o:rder(varname)}}ranking order of subgroups or individuals{p_end}
{synopt:{opt fav(varname)}}whether the indicator is favourable (1) or not (0){p_end}
{synopt:{opt sc:ale(varname)}}scale/unit of the indicator{p_end}
{synopt:{opt ref:erence(varname)}}reference subgroup indicated with 1{p_end}
{synopt:{opt svy}}can be specified when using complex survey designs if {bf:svyset} has been used to identify the survey design characteristics prior to running {bf:healthequal}{p_end}
{synopt:{opt linear}}specifies the use of a linear regression model for the calculation of SII and RII (default is logistic regression){p_end}
{synopt:{opt limits(#1 #2)}}used to specify the theoretical minimum (#1) and maximum (#2) for bounded variables{p_end}
{synopt:{opt err:eygers}}in conjunction with RCI and {bf:limits} requests the Erreygers correction of the concentration index{p_end}
{synopt:{opt wag:staff}}in conjunction with RCI and {bf:limits} requests the Wagstaff correction of the concentration index{p_end}
{synopt:{opt sim(#)}}specifies the number of simulations (default is 100){p_end}
{synopt:{opt for:mat($fmt)}}format for summary measures output{p_end}
{synopt:{opt noprint}}supresses summary measure output (default is {bf:print}){p_end}
{synopt:{opt force}}force calculation with missing indicator estimate values{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:by} is allowed; see {manhelp by D}.{p_end}

{marker description}{...}
{title:Description}

{p 4 4}{cmd:healthequal} calculates a range of summary measures of health inequality. Summary measures of health inequality summarize the amount of inequality across population subgroups using a single number - which facilitates the comparison of inequalities over time and across different settings and indicators. 

{p 4 4}Health inequalities are observed differences in health between population subgroups that are formed on the basis of dimensions of inequality. Dimensions of inequality encompass demographic, socioeconomic and geographic characteristics (e.g., age, economic status, education, and subnational region). Dimensions of inequality can be categorised as binary (with only two subgroups, such as male/female or urban/rural place of residence), ordered (with subgroups that have a natural or inherent ordering, such as education level or wealth quintiles), or non-ordered (with subgroups that cannot be inherently ranked, such as subnational regions or ethnicity). 

{p 4 4}Note that the primary indended use of {bf:healthequal} is to calculate summary measures of health inequality using disaggregated data (i.e., data that are broken down by population subgroups). However, the measures aci, rci, sii and rii used with ordered dimensions of inequality can also be calculated using individual-level (micro) data. 

{p 4 4}There is no default summary measure; the {bf:measure} option specifies the summary measure(s) to be calculated. For further information about the summary measures, calculation methods, and methodological considerations see {browse "https://doi.org/10.3390/ijerph19063697":Schlotheuber and Hosseinpoor (2022)}.

{marker options}{...}
{title:Options}

{phang}
{opt m:easure(string)} identifies the summary measure(s) to calculate. Multiple measures may be entered, separated by spaces. Inequality can be measured in either absolute or relative terms. Two measures (d and r) measure inequality between two population subgroups within a dimension of inequality, while the other measures calculated by {bf:healthequal} require data for more than two population subgroups. Four measures (aci, rci, rii and sii) measure inequality in ordered dimensions (e.g., education level, economic status). Thirteen measures (bgsd, bgv, cov, idisu, idisw, mdbu, mdbw, mdmu, mdmw, mdru, mdrw, mld, ti) measure inequality in non-ordered dimensions (e.g., subnational region, ethnicity). Two measures (paf and par) measure inequality in both ordered and non-ordered dimensions.

{synoptset 21}{...}
{synopthdr:measures}
{synoptline}
{syntab:{bf:Simple measures}}
{synopt:d}Difference{p_end}
{synopt:r}Ratio{p_end}
{synoptline}
{syntab:{bf:Regression-based measures (ordered dimensions)}}
{synopt:sii}Slope index of inequality {p_end}
{synopt:rii}Relative index of inequality {p_end}
{synoptline}
{syntab:{bf:Disproportionality measures (ordered dimensions)}}
{synopt:aci}Absolute concentration index{p_end}
{synopt:rci}Relative concentration index{p_end}
{synoptline}
{syntab:{bf:Variance measures (non-ordered dimensions)}}
{synopt:bgv}Between-group variance{p_end}
{synopt:bgsd}Between-group standard deviation{p_end}
{synopt:cov}Coefficient of variation{p_end}
{synoptline}
{syntab:{bf:Mean difference measures (non-ordered dimensions)}}
{synopt:mdmu}Mean difference from mean (unweighted){p_end}
{synopt:mdmw}Mean difference from mean (weighted){p_end}
{synopt:mdbu}Mean difference from best-performing subgroup (unweighted){p_end}
{synopt:mdbw}Mean difference from best-performing subgroup (weighted){p_end}
{synopt:mdru}Mean difference from a reference subgroup (unweighted){p_end}
{synopt:mdrw}Mean difference from a reference subgroup (weighted){p_end}
{synopt:idisu}Index of Disparity (unweighted){p_end}
{synopt:idisw}Index of Disparity (weighted){p_end}
{synoptline}
{syntab:{bf:Disproportionality measures (non-ordered dimensions)}}
{synopt:ti}Theil Index{p_end}
{synopt:mld}Mean log deviation{p_end}
{synoptline}
{syntab:{bf:Impact measures}}
{synopt:paf}Population attributable fraction{p_end}
{synopt:par}Population attributable risk{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{opt av:erage(varname)} specifies the indicator average for the setting. This option can be used for the calculation of idisu, mdmu, paf and par in the absence of specifying a {bf:weight} variable (however 95% confidence intervals will not be calculated). 

{phang}
{opt se(varname)} specifies the standard error of the subgroup estimates. This option is required for the calculation of 95% confidence intervals of d, r, bgv, bgsd, cov, idisu, idisw, mdbu, mdbw, mdmu, mdmw, mdru, mdrw, ti and mld.

{phang}
{opt dim:ension(varname)} specifies whether the dimension is ordered (e.g., economic status, education level), non-ordered (e.g., subnational region, ethnicity) or binary (e.g., sex, urban/rural place of residence). The variable {it:varname} must have the value of 1 for ordered dimensions and 0 for non-ordered and binary dimensions. This option is required for the calculation of d, r, par and paf.

{phang}
{opt o:rder(varname)} specifies the ranking order of subgroups or individuals for ordered dimensions of inequality (e.g., economic status, education). The variable {it:varname} must be at least an ordinal variable. This option is required for the calculation of aci, rci, rii and sii and is required for the calculation of d, r, par and paf if the dimension is ordered.

{phang}
{opt fav(varname)} specifies whether the indicator being measured is favourable or not. The variable {it:varname} must have the value of 1 for favourable indicators (which measure desirable health events where the ultimate goal is to achieve a maximum level, such as skilled birth attendance) and 0 for non-favourable indicators (which measure undesirable health events where the ultimate goal is to achieve a minimum level, such as under-five mortality rate). This option is required for the calculation of d, r, mdbu, mdbw, par and paf.  

{phang}
{opt s:cale(varname)} specifies the scale of the indicator being measured. For example, the scale of an indicator measured as a percentage is 100; the scale of an indicator measured as a rate per 1000 population is 1000. This option is required for the calculation of 95% confidence intervals of idisu, idisw, mdbu, mdbw, mdmu, mdmw, mdru, mdrw, par and paf. 

{phang}
{opt ref:erence(varname)} specifies a reference subgroup. The variable {it:varname} must indicate only one reference subgroup with the value 1 and must contain the value 0 for all other subgroups. This is required for the calculation of mdru and mdrw and can be used with d and r to override the default selection of the reference subgroup. 

{phang}
{opt svy} can be specified when using complex survey designs if {bf:svyset} has been used to identify the survey design characteristics prior to running {bf:healthequal}, for the calculation of aci, rci, sii and rii. 

{phang}
{opt linear} specifies the use of a linear regression model for the calculation of sii and rii (the default is logistic regression). Linear regression is recommended when using individual-level data and the indicator estimate is recorded as a continuous variable (e.g., weight or height). 

{phang}
{opt limits(#1 #2)} specifies the theoretical minimum (#1) and maximum (#2) of bounded variables for the calculation of aci and rci. Bounded variables have a finite upper limit, such as any binary variable (0,1), an index, or number of years of schooling. 

{phang}
{opt err:eygers} in conjunction with rci and {bf:limits(#1 #2)} requests the Erreygers correction of the concentration index.

{phang}
{opt wag:staff} in conjunction with rci and {bf:limits(#1 #2)} requests the Wagstaff correction of the concentration index.

{phang}
{opt sim(#)} specifies the number of simulations for the calculation of confidence intervals of bgsd, cov, idisu, idisw, mdbu, mdbw, mdmu, mdmw, mdru and mdrw. The default if {bf:sim} is not specified is 100. 

{phang}
{opt for:mat(%fmt)} specifies a format other than the default for the summary measures output.

{phang}
{opt noprint} supresses summary measure output (the default is {bf:print}).

{phang}
{opt force} forces the calculation of summary measures even if indicator estimates are missing.

{marker examples}{...}
{title:Example 1: Disaggregated data} 

{pstd}
Load example disaggregated data

{p 4 8 2}{cmd:. use sample_rmnch, clear}

{pstd}
Calculate the slope index of inequality (sii) for the ordered dimension of inequality ({it:ordered_dimension==1}) using subgroup estimates ({it:est}), subgroup population sizes ({it:pop}), and the ranking of subgroups identified in the variable {it:subgroup_order}: 

{p 4 8 2}{cmd:. healthequal est [pw=pop] if ordered_dimension==1, measure(sii) order(subgroup_order)}

{pstd}
Calculate between-group variance (bgv) for the non-ordered dimension of inequality ({it:ordered_dimension==0}) using subgroup estimates ({it:est}), subgroup population sizes ({it:pop}) and the standard error of subgroup estimates ({it:se}): 

{p 4 8 2}{cmd:. healthequal est [pw=pop] if ordered_dimension==0, measure(bgv) se(se)}

{pstd}
For each dimension of inequality, calculate the population attributable risk (par) and the population attributable fraction (paf) using subgroup estimates ({it:est}) and subgroup population sizes ({it:pop}), with the variable {it:favourable_indicator} indicating whether the indicator is favourable or not, the variable {it:ordered_dimension} indicating whether the dimension is ordered or not, and the variable {it:subgroup_order} indicating the order of subgroups (required if {it:ordered_dimension}==1). The output is formatted to 2 decimal places: 

{p 4 8 2}{cmd:. bysort dimension: healthequal est [pw=pop], measure(par paf) fav(favourable_indicator) dim(ordered_dimension) order(subgroup_order) format(%4.2f)}

{title:Example 2: Individual-level data} 

{pstd}
Load example individual-level survey data

{p 4 8 2}{cmd:. use sample_dhs, clear}

{pstd}
Calculate the absolute concentration index (aci) and relative concentration index (rci) taking survey design into account, using the indicator result ({it:sba}) and the ranking of individuals ({it:subgroup_order}): 

{p 4 8 2}{cmd:. svyset psu [pw=weight], strata(strata)}{p_end}
{p 4 8 2}{cmd:. healthequal sba, measure(aci rci) order(subgroup_order) svy}{p_end}

{title:Stored results} 

{pstd}
{cmd:healthequal} stores the following in {cmd:r()}, where {it:measure} is the summary measure that has been calculated: 

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(}{it:measure}{cmd:)}}summary measure value{p_end}
{synopt:{cmd:r(}{it:measure}{cmd:_se)}}standard error{p_end}
{synopt:{cmd:r(}{it:measure}{cmd:_ll)}}lower 95% confidence interval{p_end}
{synopt:{cmd:r(}{it:measure}{cmd:_ul)}}upper 95% confidence interval{p_end}

{title:Acknowledgements} 

{pstd}The authors would like to acknowledge Sam Harper (McGill University), George Luta (Georgetown University) and Zev Ross (ZevRoss Spatial Analysis) for their support in developing the summary measure calculations used in the Health Equity Assessment Toolkit (HEAT and HEAT Plus), and Patricia Menéndez (University of Melbourne) for review of the R version of the summary measure codes.

{title:Authors}

{pstd} 
Katherine Kirkby, Department of Data and Analytics, World Health Organization, Switzerland.

{pstd} 
Daniel A. Antiporta, Department of Data and Analytics, World Health Organization, Switzerland.

{pstd} 
Anne Schlotheuber, Department of Data and Analytics, World Health Organization, Switzerland.

{pstd} 
Ahmad Reza Hosseinpoor (corresponding author), Department of Data and Analytics, World Health Organization, Switzerland <hosseinpoora@who.int>

{title:Citation}

{pstd}
World Health Organization. 2024. healthequal: Stata module for calculating summary measures of health inequality. 

{title:References}

{pstd} 
Ahn J, Harper S, Yu M, Feuer EJ, Liu B, Luta G. Variance Estimation and Confidence Intervals for 11 Commonly Used Health Disparity Measures. {it:JCO Clin Cancer Inform}. 2018 Dec;2:1-19. 
{browse "https://doi.org/10.1200/CCI.18.00031":https://doi.org/10.1200/CCI.18.00031} 

{pstd} 
Erreygers G. Correcting the Concentration Index. {it:Journal of Health Economics}. 2009;28:504–515. 
{browse "https://doi.org/10.1016/j.jhealeco.2008.02.003":https://doi.org/10.1016/j.jhealeco.2008.02.003} 

{pstd} 
O'Donnell O, van Doorslaer E, Wagstaff A, Lindelow M. {it:Analyzing Health Equity Using Household Survey Data: A Guide to Techniques and Their Implementation}. World Bank Institute; Washington, D.C: 2008. 
{browse "https://hdl.handle.net/10986/6896":https://hdl.handle.net/10986/6896} 

{pstd} 
Schlotheuber A, Hosseinpoor AR. Summary Measures of Health Inequality: A Review of Existing Measures and Their Application. {it:Int J Environ Res Public Health}. 2022 Mar 20;19(6):3697. 
{browse "https://doi.org/10.3390/ijerph19063697":https://doi.org/10.3390/ijerph19063697} 

{pstd} 
Wagstaff A. The bounds of the concentration index when the variable of interest is binary, with an application to immunization inequality. {it:Health Economics}. 2005;14:429–432. 
{browse "https://doi.org/10.1002/hec.953":https://doi.org/10.1002/hec.953} 

{pstd}
World Health Organization. Handbook on health inequality monitoring: with a special focus on low- and middle-income countries. Geneva: World Health Organization; 2013.
{browse "https://www.who.int/publications/i/item/9789241548632":https://www.who.int/publications/i/item/9789241548632}{p_end}

{title:Also see}

{pstd} 
{help conindex}, {help concindc}, {help dstat}, {help ainequal}, {browse "https://equidade.org/siicix":siilogit} and {browse "https://equidade.org/siicix":cixr} if installed. 

{marker examples}{...}
