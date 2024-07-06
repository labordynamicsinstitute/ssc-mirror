{smcl}
{* July 4, 2024}
{hline}
Help for {cmd:diff_plot}
{hline}

{title:Description}

{pstd}The {cmd:diff_plot} is designed to create a customized visual representation of the canonical difference-in-differences (DiD) estimation, which is commonly used in causal inference. This program is tailored for the simplest 2x2 case, where we have one treatment group, one control group, one period prior to intervention, and one period post-intervention. It generates a line graph that illustrates the changes in an outcome variable over the two time periods for both the treatment and control groups. Crucially, the graph also includes an optional parallel trend line, which simulates the counterfactual trend for the treatment group in the absence of any treatment, based on the parallel trend assumption. This tool is particularly useful for organizations such as NGOs and research institutions that have baseline and endline data and want to visualize changes in both the treatment and control groups as part of their project evaluations.{p_end}

{title:Syntax}

{pstd}{cmd:diff_plot} {help varlist} [{help if}] [{help in}], time({help varname}) group({help varname}) [drop_trend] [title(string)] [decimals(integer)] [scale] [graphopts(string)] [l1_opts(string)] [l2_opts(string)] [l3_opts(string)] [m1_opts(string)] [m2_opts(string)] [m3_opts(string)]{p_end}

{synoptset 20 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt time(varname)}}Specifies the time variable, which must contain exactly two unique values representing the two time periods.{p_end}

{synopt:{opt group(varname)}}Specifies the group variable, which must contain exactly two unique values representing the treatment and control groups.{p_end}

{synopt:{opt drop_trend}}Drops the parallel trend line from the graph.{p_end}

{synopt:{opt title(string)}}Specifies the title of the graph. If not specified, a default title will be generated.{p_end}

{synopt:{opt decimals(integer)}}Specifies the number of decimal places to display for the values. Default is 2.{p_end}

{synopt:{opt scale}}Specifies whether to scale the y-axis to have a range from 0 to 100. Useful for percentages, proportions, and rates.{p_end}

{synopt:{opt graphopts(string)}}Specifies additional graph options to be passed to the graph command.{p_end}

{synopt:{opt l1_opts(string)}}Specifies options for the line representing the control group.{p_end}

{synopt:{opt l2_opts(string)}}Specifies options for the line representing the treatment group.{p_end}

{synopt:{opt l3_opts(string)}}Specifies options for the parallel trend line.{p_end}

{synopt:{opt m1_opts(string)}}Specifies options for the markers representing the control group.{p_end}

{synopt:{opt m2_opts(string)}}Specifies options for the markers representing the treatment group.{p_end}

{synopt:{opt m3_opts(string)}}Specifies options for the markers representing the parallel trend line.{p_end}

{synoptline}
{p 6 2 2}{p_end}

{title:Examples}

{pstd}Creating a difference-in-differences plot with default settings{p_end}

{phang2}. {stata webuse bplong, clear}{p_end}

{phang2}. {stata diff_plot bp, group(sex) time(when)}{p_end}

{pstd}Dropping the trend line{p_end}

{phang2}. {stata diff_plot bp, group(sex) time(when) drop_trend}{p_end}

{pstd}Fewer decimals{p_end}

{phang2}. {stata diff_plot bp, group(sex) time(when) decimals(1)}{p_end}

{pstd}Using the if clause{p_end}

{phang2}. {stata "use https://www.stata-press.com/data/r17/hospdd.dta, clear"}{p_end}

{phang2}. {stata diff_plot satis if month == 4 | month == 7, group(procedure) time(month)}{p_end}

{pstd}Using additional graphical options{p_end}

{phang2}. {stata diff_plot satis if month == 4 | month == 7, group(procedure) time(month) graphopts(ylabel(3.3(1)4.3))}{p_end}

{pstd}Using a different dataset{p_end}

{phang2}. {stata "use https://dss.princeton.edu/training/Panel101.dta, clear"}{p_end}

{phang2}. {stata gen time = 0}{p_end}

{phang2}. {stata replace time = 1 if year >= 1994}{p_end}

{phang2}. {stata gen treated = 0}{p_end}

{phang2}. {stata replace treated = 1 if country > 4}{p_end}

{phang2}. {stata replace y = y / 1000000}{p_end}

{pstd}Using graphical options to change colors of lines, markers, and values{p_end}

{phang2}. {stata diff_plot y, group(treated) time(time) l1_opts(lcolor(red)) l2_opts(lcolor(black)) l3_opts(lcolor(black)) m1_opts(mcolor(red) mlabcolor(red)) m2_opts(mcolor(black) mlabcolor(black)) m3_opts(mcolor(black) mlabcolor(black))}{p_end}

{pstd}Use a custom title and omitting the subtitle{p_end}

{phang2}. {stata diff_plot y, group(treated) time(time) title("Difference-in-Differences") graphopts(subtitle(""))}{p_end}

{title:Notes}

{pstd}This program requires the {cmd:elabel} package for full functionality. This must be installed from SSC with the command "ssc install elabel, replace".{p_end}

{title:Acknowledgments}

{pstd}Special thanks to Ketki Samel, Shritha Sampath, Zaeen de Souza, and Prabhmeet Kaur for their code reviews. Their insights and suggestions were invaluable in refining and improving this program.{p_end}

{title:Authors}

{pstd}Kabira Namit, World Bank {break}
         knamit@worldbank.org

