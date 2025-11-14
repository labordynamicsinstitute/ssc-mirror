{smcl}
{* *! version 1.0.0 \ Daniel Krähmer \ 04 November 2025}{...}
{vieweralsosee "[G-3] twoway_options" "help twoway_options"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}

{title:Title}

{phang}
{bf:mvplot} {hline 2} Plotting results from multiverse analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mvplot} [{cmd:if}] [{cmd:in}]{cmd:,}
{opth coef(varname)}
{cmdab:dec:isions(}{varlist}{cmd:)}
{opt ireg:ression(string)}
[{it:options}]

{synoptset 30}{...}
{synopthdr}
{synoptline}
{synopt:* {opth coef(varname)}}									coefficient estimates from the multiverse{p_end}
{synopt:* {opth dec:isions(varlist)}}							decision variables defining the multiverse{p_end}
{synopt:* {opt ireg:ression(string)}}							influence regression method (ols|wls) {p_end}

{synopt:(*) {opth se(varname)}}									standard errors of coefficient estimates{p_end}

{synopt:{opt bins(integer)}}									number of bins to segment the multiverse distribution; default is bins(20){p_end}
{synopt:{opth sig(varname)}}									indicator for statistical significance (0/1){p_end}
{synopt:{opt rowgap(#)}}										vertical space per row in bottom panel; default is rowgap(0.1){p_end}
{synopt:{opt pangap(#)}}										vertical space between panels; default is cmd:pangap(0){p_end}
{synopt:{opt iregnostar}}										suppress significance stars in influence regression{p_end}
{synopt:{opt iregnose}}											suppress standard errors in influence regression{p_end}

{synopt:{opth kdl:ine(connect_options)}}						kdensity line options{p_end}
{synopt:{opth kda:rea(area_options)}}							kdensity area options{p_end}
{synopt:{opt kdn:points(#)}}									kdensity estimation points; see option {opt n(#)} in {help kdensity} {p_end}
{synopt:{opt kdk:ernel}({it:{help kdensity##kernel:kernel}})}	kdensity kernel function{p_end}

{synopt :{it:{help twoway_options}}}							twoway options, other than {cmd:by()}{p_end}
{synoptline}
{p 4 6 2}* {cmd:coef()}, {cmdab:dec:isions()}, and {cmdab:ireg:ression()} are required. {cmd:se()} is required when {opt ireg:ression(wls)} is specified.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mvplot} visualizes results from multiverse analysis. 

{pstd}
The command produces a plot with two panels: an upper panel displaying the multiverse distribution of the target coefficient as a density function, 
and a lower panel showing the multiverse's analytical composition alongside results from an influence regression quantifying the impact of each researcher decision on the target coefficient.

{pstd}
Note that {cmd:mvplot} itself does not {it:conduct} multiverse analyses. Instead, it requires users to provide a results dataset from an already completed multiverse analysis. Hence, 
the command is best used in conjunction with the {search multivrs} command (Young & Holsteen, 2021). 

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth coef(varname)} specifies the variable containing the target coefficient (the estimand) estimated repeatedly across the multiverse analysis.

{phang}
{cmd:decisions(}{varlist}{cmd:)} specifies a list of researcher decisions underlying the multiverse. Variable values should capture analytical options. 
Variables must be numeric and should be labeled, as variable labels and value labels will appear in the final graph. 

{phang}
{opt iregression(string)} determines the type of regression model for calculating influence statistics. Options are {cmd:ols} or {cmd:wls}. Results from the influence regression are stored in {cmd:e()}. 
Note: If {cmd: iregression(wls)} is used, users {it:must} also specify option {cmd: se()}. 


{dlgtab:Optional}

{phang}
{opth se(varname)} specifies the variable containing standard errors for the coefficient estimates. This option is required when {cmd: iregression(wls)} is specified.

{phang}
{opt bins(integer)} specifies the number of bins for segmenting the multiverse distribution in the lower panel. If {opt bins(integer)} is set to the number of possible model specifications in the multiverse, 
{cmd:mvplot} will produce a specification curve (see Simonsohn et al. 2020). The default value is {cmd: bins(20)}.

{phang}
{opth sig(varname)} specifies an indicator variable (0/1) capturing whether a multiverse specification's target coefficient was statistically significant. 
You may chose your preferred alpha threshold when generating this variable.

{phang}
{opt rowgap(#)} determines the vertical space allocated to each row in the bottom panel, measured in units of the top density panel. Use this option to adjust the relative size of the bottom panel 
compared to the top panel. Increasing {cmd:rowgap()} will allocate more space to the bottom panel. A reasonable default is determined automatically.

{phang}
{opt pangap(#)} specifies extra vertical space between the two panels, measured in units of the density panel. Use this option to visually separate the two panels more clearly. The default is {cmd:pangap(0)}.

{phang}
{opt iregnostar} suppresses the display of significance stars in the influence regression output. By default, stars are shown with *** p<0.001, ** p<0.01, * p<0.05.

{phang}
{opt iregnose} suppresses the display of standard errors in the influence regression output. By default, standard errors are shown in parentheses.

{phang}
{opth kdl:ine(connect_options)} modifies the appearance of the line plot in the upper panel.

{phang}
{opth kda:rea(area_options)} modifies the appearance of the area plot in the upper panel.

{phang}
{opt kdn:points(#)} determines the number of points for estimating the density function; see {opt n(#)} in {help kdensity}. 

{phang}
{opt kdk:ernel}({it:{help kdensity##kernel:kernel}}) allows you to switch between different kernel functions for estimating the density.


{dlgtab:Twoway options}

{phang}
{it:twoway_options} are general options for {help twoway} graphs, excluding {cmd:by()}. Because of how {cmd:mvplot} operates internally, users should note the following:

{pmore}
{bf:Y-axis labels:} labels for the density plot (top panel, left side) can be customized using regular {cmd:ylabel()} syntax; y-axis labels for researcher decisions (bottom panel, left side) 
should be customized using {cmd:ylabel(..., axis(1))}; y-axis labels for influence estimates (bottom panel, right side) should be customized using {cmd:ylabel(..., axis(2))}.

{pmore}
{bf:Legend:} By default, {cmd:mvplot} produces no legend. Users may add a legend, but should keep in mind that multiverse plots contain a large number of rbar plots in the bottom panel which will clutter the legend. 
Hence, if a legend is added, it is recommended to display only the first and second twoway plot, using {cmd:legend(order(1 "..." 2 "..."))}.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mvplot} stores the influence regression results in {cmd:e()}, following standard {cmd:regress} output conventions.


{marker examples}{...}
{title:Examples}


{pstd}
Install the {cmd:multivrs} ado to conduct a multiverse analysis:

        . {stata ssc install multivrs}

{pstd}
Load demo data:

        . {stata sysuse nlsw88, clear}
		
{pstd}
Run a multiverse analysis and save the results:

        . {stata cap erase mva_results.dta}
        . {stata cap erase mva_results.do}
        . {stata qui multivrs regress union hours age grade collgrad married south smsa c_city ttl_exp tenure, saveas(mva_results) noplot}
		
{pstd}
Load results:

        . {stata use mva_results, clear}

{pstd}
Plot:

        . {stata mvplot, coef(b_intvar) dec(r_*) ireg(ols) name(g1, replace)}


{pstd}
{bf:Note:} While the graph {bf:g1} already shows the distribution of multiverse estimates (top panel) and patterns in analytical decisions (bottom panel), 
it has poor labels and suboptimal scaling. We can easily address these problems by modifying the underlying data:

        . {stata generate b_intvar_resc = 1000 * b_intvar}
        . {stata lab var r_age 			"Age"}
        . {stata lab var r_grade 		"Grade completed"}
        . {stata lab var r_collgrad		"Collage graduate"}
        . {stata lab var r_married 		"Married"}
        . {stata lab var r_south 		"Region"}
        . {stata lab var r_smsa 		"SMSA"}
        . {stata lab var r_c_city 		"Central city"}	 
        . {stata lab var r_ttl_exp		"Work Experience"}
        . {stata lab var r_tenure		"Job tenure"}
        . {stata lab define r_lbl		0 "Excluded" 1 "Included"}		
        . {stata lab val r_* r_lbl}		

{pstd}
Plot (with added {it:{help twoway_options}}):

        . {stata local twopt1 ylab(0(0.5)1) yline(0, lcolor(black)) ytitle(, margin(t=3 r=-5)) graphregion(margin(l=15) color(white))}
        . {stata local twopt2 title("Effect of union membership on working hours (varying controls)", size(medium) margin(bottom))}
        . {stata mvplot, coef(b_intvar_resc) dec(r_*) bins(20) ireg(ols) rowgap(0.1) `twopt1' `twopt2' name(g2, replace) }

{marker author}{...}
{title:Author}

{pstd}
Daniel Krähmer (LMU Munich) and Cristobal Young (Cornell University)

{pstd}
Contact: daniel.kraehmer@soziologie.uni-muenchen.de


{marker references}{...}
{title:References}

{pstd}
Young, C. & Holsteen, K. 2021. "MULTIVRS: Stata module to conduct multiverse analysis," Statistical Software Components S458927, Boston College Department of Economics, revised 15 Apr 2021. 

{pstd}
Simonsohn, U., Simmons, J.P. & Nelson, L.D. 2020. "Specification curve analysis," Nat Hum Behav 4, 1208–1214 (2020). https://doi.org/10.1038/s41562-020-0912-z

