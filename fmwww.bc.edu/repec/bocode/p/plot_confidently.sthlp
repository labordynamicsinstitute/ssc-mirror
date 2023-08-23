{smcl}
{* August 22, 2023}
{hline}
Help for {hi:plot_confidently} 
{hline}

{title:Description}

{pstd}{cmd:plot_confidently} allows users to visualize the mean and confidence interval of a specified variable, with options for up to two levels of disaggregation.

{title:Syntax}

{pstd}{cmd:plot_confidently} {help varlist} [{help IF}] [{help IN}], [over({help varname})] [by({help varname})] [graphopts()] [scale]]

{synoptset 20 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt over(varname)}} This specifies the first of up to two grouping variables. {help varname} must be a labelled factor variable.{p_end}
{synopt:{opt by(varname)}} This specifies the second grouping variable. {help varname} must be a labelled factor variable.{p_end}

{synopt:{opt graphopts(string)}}Allows the user to pass any Stata graph options into the program. For example, a custom title, subtitle and/or note (or make changes to the axis labels, ticks and so on). Must be specified as a string enclosed in quotation marks. See examples below.{p_end}
{synopt:{opt scale}}Allows the user to scale the Y-Axis to the percentage scale. Useful for visualizing percentages, proportions and rates.{p_end}
{synoptline}
{p 6 2 2}{p_end}

{title:Examples}

{phang2}. {stata sysuse auto.dta, clear}{p_end}
{phang2}. {stata label define quality 1 "Poor"  2 "Fair" 3 "Average" 4 "Good" 5 "Excellent"}{p_end}
{phang2}. {stata lab val rep78 quality}{p_end}
{phang2}. {stata gen pct_score = runiform()*100}{p_end}
{phang2}. {stata lab var pct_score "Percentage Score"}{p_end}


{ul:Example 1}

{pstd}Mean + 95% confidence interval of a continuous variable with no group variable.{p_end}

{phang2}. {stata plot_confidently price}{p_end}

{ul:Example #2}

{pstd}Mean + 95% confidence interval of a continuous variable with a single group variable.{p_end}

{phang2}. {stata plot_confidently price, over(rep78)}{p_end}

{ul:Example #3}

{pstd}Mean + 95% confidence interval of a continuous variable using two grouping variables.{p_end}

{phang2}. {stata plot_confidently price, over(rep78) by(foreign)}{p_end}

{ul:Example 4}

{pstd}Mean + 95% confidence interval of a percentage variable while using the "scale" option.{p_end}

{phang2}. {stata plot_confidently pct_score, scale}{p_end}
	
{ul: Example #5}

{pstd} Editing the look of the graph via "graphopts".{p_end}

{phang2}. {stata plot_confidently price, over(rep78) by(foreign) graphopts(msymbol(S) xtitle("My X-Axis"))}{p_end}
	
{ul: Example #6}

{pstd} Using an IF/IN condition.{p_end}

{phang2}. {stata plot_confidently price if foreign == 0, over(rep78)}{p_end}
	
{title:Acknowledgments}

{pstd} We would like to thank Ben Jann, who developed {help coefplot}, which our command builds on. We are grateful to Prabhmeet Kaur for creating an early iteration of the program, which was the inspiration for {cmd:plot_confidently}. We would also like to thank Professor Iram Siraj and Sakshi Hallan for feedback and support in the development stages of {cmd:plot_confidently}. All errors are our own.		

{title:Authors}

{pstd}Zaeen de Souza, Frontline Impact{break} 
         zaeen@frontline-impact.com

{pstd}Kabira Namit, World Bank {break} 
         knamit@worldbank.org		 
		 
		 
