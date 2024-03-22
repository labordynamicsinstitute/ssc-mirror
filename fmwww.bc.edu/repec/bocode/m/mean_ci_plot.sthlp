{smcl}
{* March 19, 2024}
{hline}
Help for {cmd:mean_ci_plot}
{hline}

{title:Description}

{pstd}{cmd:mean_ci_plot} offers a user-friendly command for visualizing means and confidence intervals of specified variables, with an option for disaggregation. It also offers the flexibility to adapt to a wide range of graphical preferences. 

{title:Syntax}

{pstd}{cmd:mean_ci_plot} {help varlist} [{help IF}] [{help IN}], [by({help varname})] [scale] [title()] [graphopts()]

{synoptset 20 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt by(varname)}}This specifies the grouping variable. The {help varname} must be a labelled factor variable.{p_end}

{synopt:{opt scale}}Allows the user to scale the Y-Axis to the percentage scale. Useful for visualizing percentages, proportions and rates.{p_end}

{synopt:{opt title}}Allows users to specify a custom title for the graph. If not used, the default title is "Means and confidence intervals".{p_end}

{synopt:{opt graphopts(string)}}Allows the user to pass any Stata graph options into the program. For example, a custom subtitle and/or note (or make changes to the axis labels, ticks and so on). Must be specified as a string enclosed in quotation marks. Users should refer to the official Stata documentation for a comprehensive list of graph options.{p_end}

{synoptline}
{p 6 2 2}{p_end}

{title:Examples}

{pstd}Setting up an example dataset.{p_end}

{phang2}. {stata sysuse auto.dta, clear}{p_end}
{phang2}. {stata gen pct_score = runiform()*100}{p_end}
{phang2}. {stata lab var pct_score "Percentage Score"}{p_end}


{ul:Example 1}

{pstd}Mean + 95% confidence interval of three continuous variables with no group variable.{p_end}

{phang2}. {stata mean_ci_plot mpg trunk turn}{p_end}

{ul:Example #2}

{pstd}Mean + 95% confidence interval of three continuous variables with a group variable.{p_end}

{phang2}. {stata mean_ci_plot mpg trunk turn, by(foreign)}{p_end}

{ul:Example #3}

{pstd}Mean + 95% confidence interval of a percentage variable while using the "title" option.{p_end}

{phang2}. {stata mean_ci_plot pct_score, title("My custom title")}{p_end}

{ul:Example #4}

{pstd}Mean + 95% confidence interval of a percentage variable while using the "scale" option.{p_end}

{phang2}. {stata mean_ci_plot pct_score, scale}{p_end}
	
{ul:Example #5}

{pstd} Editing the look of the graph via "graphopts".{p_end}

{phang2}. {stata mean_ci_plot mpg trunk turn, by(foreign) graphopts(msymbol(S) xtitle("My X-Axis"))}{p_end}
	
{ul:Example #6}

{pstd} Using an IF/IN condition.{p_end}

{phang2}. {stata mean_ci_plot mpg trunk turn if price > 5000, by(foreign)}{p_end}


{title:Notes}

{pstd} 1. This program requires the {cmd:coefplot} package. If not already installed, it can be installed from SSC by running "ssc install coefplot, replace".

{title:Acknowledgments}

{pstd} We would like to thank Ben Jann, who developed {help coefplot}, which our command builds on. 

{title:Authors}

{pstd}Zaeen de Souza, Frontline Impact{break} 
         zaeen.desouza19_mec@apu.edu.in 

{pstd}Kabira Namit, World Bank {break} 
         knamit@worldbank.org	
		 
		 
		 
		 
		 

		 