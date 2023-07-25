{smcl}
{* *! version 1.0.0 \ Daniel Krähmer \ May 2023}{...}
{vieweralsosee "[G-3] line_options" "help line_options"}{...}
{vieweralsosee "[G-3] marker_options" "help marker_options"}{...}
{vieweralsosee "[G-3] twoway_options" "help twoway_options"}{...}
{vieweralsosee "[G-4] colorstyle" "help colorstyle"}{...}
{vieweralsosee "[R] level" "mansection R level"}{...}

{title:Title}

{phang}
{bf:mfcurve} {hline 2} Plotting results from multifactorial research designs


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mfcurve} {varname},
{cmd:factors(}{varlist}{cmd:)}
[{it:options}]

{synoptset 30}{...}
{synopthdr}
{synoptline}
{synopt:{opth groupvar(varname)}}determine groups based on variable {varname} {p_end}
{synopt:{cmd:test(mean|zero)}}test coefficients for statistical significance {p_end}
{synopt:{opt level(#)}}set confidence level for significance testing{p_end}
{synopt:{opt show(show_options)}}add elements to the plot (see details below){p_end}
{synopt :{opt boxplot}}display boxplots instead of point estimates{p_end}
{synopt :{opth style_m_sig(marker_options)}}rendition of markers, significant {p_end}
{synopt :{opth style_m_nosig(marker_options)}}rendition of markers, non-significant {p_end}
{synopt :{opth style_ci_sig(line_options)}}rendition of confidence intervals, significant{p_end}
{synopt :{opth style_ci_nosig(line_options)}}rendition of confidence intervals, non-significant {p_end}
{synopt :{opth style_ind_act(marker_options)}}rendition of indicators, active {p_end}
{synopt :{opth style_ind_pas(marker_options)}}rendition of indicators, passive {p_end}
{synopt :{opth style_l_mean(line_options)}}rendition of meanline, if specified via show(mean) {p_end}
{synopt :{it:{help twoway_options}}}twoway options, other than {cmd:by()}{p_end}
{synoptline}

{synoptset 30}{...}
{synopthdr:show_options}
{synoptline}
{synopt :{cmd: mean}}adds a horizontal line at the overall mean of {varname}{p_end}
{synopt :{cmd: sig}}contrasts significant and non-significant estimates{p_end}
{synopt :{cmd: ci_regular}}adds confidence intervals to coefficients, using solid lines {p_end}
{synopt :{cmd: ci_gradient}}adds confidence intervals to coefficients, using color gradients{p_end}
{synopt :}Note: In line with Stata Tip 103 (Kohler & Eckman, 2011) users are encouraged to use color gradients to express uncertainty.
They should keep in mind, though, that this option adds many layers to the graph (~20 per group), potentially resulting in memory issues
(especially if the number of factors and levels in {cmd:factors(}{varlist}{cmd:)} is large).{p_end}
{synopt :{cmd: groupsize}}adds case numbers to the x-axis {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mfcurve} plots the mean of variable {varname} over all multifactorial combinations in {cmd:factors(}{varlist}{cmd:)}. 

{pstd}
The plot consists of two subgraphs: an upper panel, displaying the mean outcome per group; and a lower panel, indicating the presence/absence of each factor level.
Symbols in the upper panel are referred to as markers; symbols in the lower panel are referred to as indicators.
The graph follows the overall aesthetics of a specification curve but displays effect variation across {it:treatment} specifications instead of effect variation across {it:model} specifications.


{marker options}{...}
{title:Options}

{phang}
{opth groupvar(varname)} allows users to specify what variable should be used to label subgroups. By default, {cmd: mfcurve} is agnostic and assigns numerical IDs based on all possible combinations in {cmd:factors(}{varlist}{cmd:)}.

{phang}
{cmd:test(}...{cmd:)} tests coefficients for statistical significance using t-tests. 

{pmore2}
{cmd:test(mean)} performs two-sample t tests on the equality of means of {varname} in each group (treatment) against the pooled mean across all other groups (control).
By design, the composition of the control group depends on the choice of the treatment group, meaning the reference value to be tested against will vary across t tests.
As a result, a coefficient's confidence interval might overlap with the {it: overall mean}, i.e. displayed by {cmd: show(mean)}, despite being significantly different from the mean {it: in the control group}, according to the t test.
Similarly, two neighboring coefficients may differ with regards to their statistical significance despite having seemingly identical confidence intervals. 

{pmore2}
{cmd:test(zero)} performs one-sample t tests for each group against zero.

{phang}
{opt level(#)} enables users to set the confidence level for significance testing; see {mansection R level:[R] level}. Unless specified otherwise, the default value is level(95).

{phang}
{cmd:show(}...{cmd:)} lets users add visual elements to the plot (see {it: show_options} above).

{phang}
{cmd: boxplot} replaces point estimates with boxplots (see Cox, 2009). This option may only be specified if {varname} is polytomous and cannot be combined with {cmd: test(}...{cmd:)} and {cmd: show(}...{cmd:)}.

{phang}
{opth style_m_sig(marker_options)} enables users to manipulate the rendition of significant markers. 

{phang}
{opth style_m_nosig(marker_options)} enables users to manipulate the rendition of non-significant markers. 

{phang}
{opth style_ci_sig(line_options)} enables users to manipulate the rendition of significant confidence intervals. 

{pmore2}
{red:Note:} If {cmd: show(ci_gradient)} is used, the CI's color needs to be determined using {cmd: {red:color}(}{help colorstyle}{cmd:)} instead of {cmd: {red:lcolor}(}{help colorstyle}{cmd:)}.

{phang}
{opth style_ci_nosig(line_options)} enables users to manipulate the rendition of non-significant confidence intervals. 

{pmore2}
{red:Note:} If {cmd: show(ci_gradient)} is used, the CI's color needs to be determined using {cmd: {red: color}(}{help colorstyle}{cmd:)} instead of {cmd: {red: lcolor}(}{help colorstyle}{cmd:)}.

{phang}
{opth style_ind_act(marker_options)} enables users to manipulate the rendition of active indicators. 

{phang}
{opth style_ind_pas(marker_options)} enables users to manipulate the rendition of passive indicators. 

{phang}
{opth style_l_mean(line_options)} enables users to manipulate the rendition of the meanline, if specified via show(mean). 


{marker results}{...}
{title:Stored results}

{synoptset 30 tabbed}{...}
{p2col 5 15 19 2: Matrix}{p_end}
{synopt:{cmd:r(testresults)}}if option {cmd:test(}...{cmd:)} has been specified, the matrix contains the details of the t tests (i.e. means, standard deviations, sample sizes, confidence intervals, p-values, etc.) for all groups.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{cmd: mfcurve} may, for instance, be used descriptively to plot the average income across distinct groups defined by race, region, and union membership:
	
	. {stata sysuse nlsw88, clear}
	. {stata drop if missing(race, south, union, wage)}
	. {stata mfcurve wage, factors(race south union)}
	
{pstd}
In the graph, higher hourly wages seem to be associated with union membership and not living in the south. To assess if this is due to small cell sizes in certain subgroups, we can type:
	
	. {stata mfcurve wage, factors(race south union) show(groupsize)}
	
{pstd}
Indeed, there are very few observations with race == "other" (groups 9-11), so we might want to drop these. We then test if the income of each remaining group differs significantly (at the 99% level) from the mean income across all other groups:

	. {stata drop if race == 3}
	. {stata mfcurve wage, factors(race south union) show(sig) test(mean) level(99)}

{pstd}
To convey more information, we might want to add the overall mean and display confidence intervals:
	
	 {stata mfcurve wage, factors(race south union) show(sig mean ci_regular) test(mean) level(99)}

{pstd}
The ylabels in the graph's lower panel are based on the variables in factors(...). We can rename/relabel those variables to improve the graph's appearance. 

	. {stata rename race Race}
	. {stata rename south Region}
	. {stata label define region_lbl 0"North" 1"South"}
	. {stata label values Region region_lbl}
	. {stata rename union Union}
	. {stata label define union_lbl 0"No" 1"Yes"}
	. {stata label values Union union_lbl}
	
	. {stata mfcurve wage, factors(Race Region Union) show(sig mean ci_regular) test(mean) level(99)}
	
{pstd}
Finally, we obtain a full-fledged {cmd: mfcurve} using color gradients to express uncertainty in estimates, 
removing the automatically generated (and here: meaningless) group identifiers on the x-axis, 
customizing the marker symbols, and specifying a few general twoway_options. Note that due to the option {cmd: show(ci_gradient)} the graph will take a few seconds to compile.
	
	. {stata local twoptions xlab(none) ylab(5(1)11) ytitle("Hourly Wage (in US$)") xtitle("") graphregion(color(white))}
	. {stata mfcurve wage, factors(Race Region Union) show(sig mean ci_gradient) test(mean) level(99) style_m_sig(msymbol(D)) `twoptions'}

	
{marker references}{...}
{title:References}

{pstd}
Kohler, Ulrich, and Stephanie Eckman. 2011. "Stata Tip 103: Expressing Confidence with Gradations." {it:The Stata Journal} 11(4):627–31. doi: 10.1177/1536867X1201100409.

{pstd}
Cox, Nicholas J. 2009. "Speaking Stata: Creating and Varying Box Plots." The Stata Journal: Promoting Communications on Statistics and Stata 9(3):478–96. doi: 10.1177/1536867X0900900309.


{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
This ado has drawn inspiration from the Stata ado {cmd: speccurve}, authored by Hans H. Sievertsen. Thanks to my colleagues at the Department of Sociology at LMU Munich for their helpful comments and suggestions. 


{marker author}{...}
{title:Author Details}

{pstd}
Daniel Krähmer, Ludwig-Maximilans-Universität (LMU) Munich

{pstd}
Contact: daniel.kraehmer@soziologie.uni-muenchen.de

 