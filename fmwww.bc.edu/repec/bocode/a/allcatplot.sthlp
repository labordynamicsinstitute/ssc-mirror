{smcl}
{* May 13, 2024}
{hline}
Help for {cmd:allcatplot}
{hline}

{title:Description}

{pstd}{cmd:allcatplot} ensures that all predefined response categories for a variable, including those that are not present in the dataset, are included in a graph. Traditional plotting methods omit such unselected categories, potentially skewing interpretation. {cmd:allcatplot}  uses the predefined value labels to identify and label such omitted response options and add them to the graph as zero-height bars. It also supports custom lists, labels and graph customization directly through the program syntax.{p_end}

{pstd}This program is especially useful for surveys and assessments utilizing likert scales or other structured response options, where it offers a holistic view of all potential responses in the graph, thereby ensuring a comprehensive understanding of the full range of response options.{p_end}

{pstd}Moreover, {cmd:allcatplot} can be used to do the opposite of what its name suggests: to exclude specific categories from the graph for clarity or analytical purposes. For instance, in a dataset with varied selections across options A, B, C, and D for a specific variable, the program can be configured to display only the responses for options A, B, and C (or any other combination of the four in any order of your choice). This doesn't eliminate the data for option D but merely hides it from the graph, with the displayed bar heights accurately reflecting the frequencies or percentages of responses for the displayed options as per the total count.{p_end}

{title:Syntax}

{pstd}{cmd:allcatplot} {help varlist} [{help IF}] [{help IN}], [Over({help varname})] [List(string)] [RElabel(string)] [Freq] [Sort] [Title(string)] [Missing] [Recast(string)] [Graphopts(string)]{p_end}

{synoptset 20 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt Over(varname)}}Specifies the variable over which to disaggregate the graphed data.{p_end}

{synopt:{opt List(string)}}Defines a custom list of categories to include in the graph, overriding the default order and selection.{p_end}

{synopt:{opt RElabel(string)}}Enables customization of the graph's bar labels directly through the program's syntax. To accommodate multi-word value labels, users should replace spaces with underscores (_). For instance, use "Very_Good" instead of "Very Good".{p_end}

{synopt:{opt Freq}}Plots actual frequencies instead of percentages. Percentages remain the default option.{p_end}

{synopt:{opt Sort}}Sorts the data in descending order.{p_end}

{synopt:{opt Title(string)}}Customizes the title of the graph.{p_end}

{synopt:{opt Missing}}Includes information about the number of missing observations in the dataset in the graph subtitle.{p_end}

{synopt:{opt Recast(string)}}Changes the type of graph (e.g., from bar to hbar).{p_end}

{synopt:{opt Graphopts(string)}}Facilitates the inclusion of additional Stata graph options. This option offers extensive customization of the graphical output.{p_end}

{synoptline}
{p 6 2 2}{p_end}

{title:Examples}

{pstd}Setting up an example dataset.{p_end}

{phang2}. {stata sysuse nlsw88.dta, clear}{p_end}

{ul:Example 1}

{pstd}Demonstrating the basic functionality of plotting all categories, even those without observations.{p_end}

{phang2}. {stata allcatplot race}{p_end}

{phang2}. {stata replace race = . if race == 3}{p_end}

{phang2}. {stata allcatplot race}{p_end}

{ul:Example 2}

{pstd}Editing labels and adding a custom title directly through the program syntax.{p_end}

{phang2}. {stata allcatplot race, relabel(white black other) title(Race of sample population)}{p_end}

{ul:Example 3}

{pstd}Adding information about the number of missing observations as a subtitle and plotting frequencies instead of percentages.{p_end}

{phang2}. {stata allcatplot race, missing}{p_end}

{phang2}. {stata allcatplot race, freq}{p_end}

{ul:Example 4}

{pstd}Using the recast option to change the graph type and applying additional graph options.{p_end}

{phang2}. {stata allcatplot race, recast(hbar)}{p_end}

{phang2}. {stata allcatplot race, freq recast(dot) graphopts(ylabel(0(500)2000))}{p_end}

{ul:Example 5}

{pstd}Customizing the order of the bars and selectively displaying certain categories.{p_end}

{phang2}. {stata allcatplot occupation, list(3 6 8)}{p_end}

{phang2}. {stata allcatplot occupation, list(8 6 3)}{p_end}

{pstd}Including an additional option that does not occur in the dataset for illustrative purposes.{p_end}

{phang2}. {stata allcatplot occupation, list(8 6 3 14) relabel(Laborers Operatives Sales Military)}{p_end}

{ul:Example 6}

{pstd}Utilizing another dataset to showcase sorting.{p_end}

{phang2}. {stata sysuse auto.dta, clear}{p_end}

{phang2}. {stata allcatplot rep78}{p_end}

{phang2}. {stata allcatplot rep78, sort}{p_end}

{pstd}Adding a bar for missing observations requires a couple of additional steps.{p_end}

{phang2}. {stata tostring rep78, gen(rep78_string)}{p_end}

{phang2}. {stata replace rep78_string = "Missing" if rep78_string == "."}{p_end}

{phang2}. {stata allcatplot rep78_string, sort}{p_end}

{ul:Example 7}

{pstd}Demonstrating the 'over' option for disaggregating data by groups, including with string variables.{p_end}

{phang2}. {stata sysuse auto.dta, clear}{p_end}

{phang2}. {stata allcatplot rep78, over(foreign) relabel(A B C D E) freq}{p_end}

{phang2}. {stata allcatplot rep78, over(foreign) missing freq recast(dot) graphopts(linegap(60))}{p_end}

{phang2}. {stata allcatplot rep78, over(foreign) sort}{p_end}

{phang2}. {stata decode foreign, gen(foreign_decode)}{p_end}

{phang2}. {stata allcatplot rep78, over(foreign_decode) missing}{p_end}

{title:Notes}

{pstd} This program requires the {cmd:elabel} and {cmd:splitvallabels} packages for full functionality. These must be installed from SSC with the command "ssc install elabel, replace" and "ssc install splitvallabels, replace".{p_end}

{pstd} If the 'over' option is used, the percentages add up to 100% for each category of 'over'. In the opinion of the authors, the bars are also arranged more intutively than the traditional Stata graph bars when the 'over' option is used.{p_end}

{title:Acknowledgments}

{pstd} Special thanks to Daniel Klein, Nick Winter, Benn Jann and Nick Cox for writing the programs that make allcatplot possible. The name of the program is a homage to Nick Cox's catplot. Thanks to Kit Baum for his valuable advice on Stata frames and disk usage. Also, thanks to Cooper Allton, Jonathan Seiden, Ketki Samel and Sai Pitre whose feedback have been invaluable in refining {cmd:allcatplot}.{p_end}

{title:Authors}

{pstd}Kabira Namit, World Bank {break} 
         knamit@worldbank.org
		 
{pstd}Zaeen de Souza, National Social Protection Secretariat - The Gambia {break} 
         zaeen.desouza19_mec@apu.edu.in
		 
{pstd}Prabhmeet Kaur Matta, University of Oxford {break} 
         prabhmeet.matta@economics.ox.ac.uk

		 
		 
		 
		 
		 
		 