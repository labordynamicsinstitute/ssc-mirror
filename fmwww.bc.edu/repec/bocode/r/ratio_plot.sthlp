{smcl}
{* April 3, 2024}
{hline}
Help for {cmd:ratio_plot}
{hline}

{title:Description}

{pstd}{cmd:ratio_plot} is designed to plot ratios and confidence intervals of specified variables with an option for disaggregation. Essentially, ratio_plot mirrors the output of Stata's in-built ratio command in a graphical format. It also offers the flexibility to adapt to a wide range of graphical preferences. 

{title:Syntax}

{pstd}{cmd:ratio_plot} {help varlist} [{help IF}] [{help IN}], Base({help varname}) [Over({help varname})] [Title({help string})] [Sort] [SCale] [Graphopts({help string})]

{synoptset 20 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt Base(varname)}}Specifies the denominator variable in the ratio calculation. Essential for determining the ratio.{p_end}

{synopt:{opt Over(varname)}}Defines the grouping variable for disaggregating the ratio calculation over different categories.{p_end}

{synopt:{opt Title(string)}}Allows users to provide a custom title for the graph. Defaults to "Ratio graph" if not specified.{p_end}

{synopt:{opt Sort}}Enables sorting of the ratio values in the plotted graph. Useful for ordered comparisons and relevant only if used in conjunction with the 'over' option. If not selected, ratios will default to an alphabetic order. {p_end}

{synopt:{opt Scale}}Adjusts the scale of the graph to be between 0 and 1. By default, ratios are presented without scaling.{p_end}

{synopt:{opt Graphopts(string)}}Facilitates the inclusion of additional Stata graph options. Must be specified as a string in quotation marks. This option offers extensive customization of the graphical output.{p_end}

{synoptline}
{p 6 2 2}{p_end}

{title:Examples}

{pstd}Setting up an example dataset.{p_end}

{phang2}. {stata webuse census2, clear}{p_end}

{ul:Example 1}

{pstd}Plotting a basic ratio of one variable over another without grouping.{p_end}

{phang2}. {stata ratio_plot divorce, base(marriage)}{p_end}

{ul:Example #2}

{pstd}Plotting ratios over categories defined by a third variable, including custom title.{p_end}

{phang2}. {stata ratio_plot divorce, base(marriage) over(region) title("Ratio of divorce to marriage")}{p_end}

{ul:Example #3}

{pstd}Customizing the graph's scale, sorting the ratios and adding additional graph options.{p_end}

{phang2}. {stata ratio_plot divorce, base(marriage) over(region) scale sort graphopts(msymbol(S) xtitle("My X-Axis"))}{p_end}

{ul:Example #4}

{pstd}Additional example of using the graph options.{p_end}

{phang2}. {stata ratio_plot divorce, base(marriage) over(region) sort scale graphopts(msymbol(S) xtitle("My X-Axis") recast(bar) barwidth(0.5) citop  fcolor(*.7) mlabpos(2))}{p_end}

{title:Notes}

{pstd} 1. This program is a wrapper for the {cmd:coefplot} package. If {cmd:coefplot} is not already installed, it must be installed from SSC with the command "ssc install coefplot, replace".

{pstd} 2. The sort and scale options do not require arguments. 

{pstd} 3. Standard errors and confidence intervals are drawn directly from Stata's in-built ratio program. It is important to note that these standard errors are estimated simultaneously and as such, for each subgroup ratio the Degrees of Freedom used for estimating the 95% Confidence Interval are based on the overall (pooled) sample size (N) as opposed to the sub-group specific Ns.

{title:Acknowledgments}

{pstd} Special thanks to Ben Jann, the creator of {help coefplot}, which serves as the foundational tool for {cmd:ratio_plot}. 

{title:Authors}

{pstd}Kabira Namit, World Bank {break} 
         knamit@worldbank.org

{pstd}Zaeen de Souza, Frontline Impact{break} 
         zaeen.desouza19_mec@apu.edu.in 
		 
		 
		 

		 