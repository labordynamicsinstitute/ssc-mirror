{smcl}
{* *! version 1.0.0  28jul2025}{...}
{viewerdialog stackbar "dialog stackbar"}{...}
{vieweralsosee "[G-2] graph bar" "mansection G-2 graphbar"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[G-2] graph" "help graph"}{...}
{vieweralsosee "[R] contract" "help contract"}{...}
{vieweralsosee "[R] collapse" "help collapse"}{...}
{viewerjumpto "Syntax" "stackbar##syntax"}{...}
{viewerjumpto "Description" "stackbar##description"}{...}
{viewerjumpto "Options" "stackbar##options"}{...}
{viewerjumpto "Examples" "stackbar##examples"}{...}
{viewerjumpto "Remarks" "stackbar##remarks"}{...}
{viewerjumpto "Author" "stackbar##author"}{...}
{viewerjumpto "Acknowledgments" "stackbar##acknowledgments"}{...}
{title:Title}

{phang}
{bf:stackbar} {hline 2} Create stacked percentage bar charts for survey data visualization


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:stackbar}
{varlist}
{ifin}
{cmd:,} {opt over(varname)}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt over(varname)}}create stacked bars for each category; required{p_end}
{synopt:{opt t:itle(string)}}graph title; defaults to "Stacked Percentage Bar"{p_end}
{synopt:{opt n:}}show sample sizes in title and category labels{p_end}

{syntab:Display}
{synopt:{opt re:cast(string)}}change graph type; defaults to "bar" for single variables, "hbar" for multiple variables{p_end}
{synopt:{opt i:ntensity(#)}}color intensity for bars; default is {cmd:intensity(50)}{p_end}

{syntab:Customization}
{synopt:{opt overopts(string)}}pass options to the {cmd:over()} specification{p_end}
{synopt:{opt blabelopts(string)}}pass options to the {cmd:blabel()} specification{p_end}
{synopt:{opt legendopts(string)}}pass options to the {cmd:legend()} specification{p_end}
{synopt:{opt graphopts(string)}}pass additional graph options{p_end}

{syntab:Export}
{synopt:{opt sa:ving(filename)}}save graph to file; defaults to PNG if no extension specified{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:stackbar} creates stacked percentage bar charts that visualize 
survey response distributions across different groups. The command handles two 
distinct types of survey questions commonly encountered in social science research,  
adapting its visualization approach based on the input data structure.

{pstd}
For single categorical variables (e.g., "What is your primary mode of transportation?"), the 
command displays the percentage distribution of responses within each comparison group, with 
stacked bars totaling 100%. This approach is ideal for visualizing how categorical responses 
vary across demographic groups, treatment conditions, or other grouping variables.

{pstd}
For multiple binary variables (e.g., "Which of the following services have you used? Check all 
that apply"), the command shows independent response rates for each option within each group. 
This treats each variable as an independent choice, making it particularly useful for analyzing 
"select all that apply" survey questions where respondents can choose multiple options.

{pstd}
The command addresses a common visualization challenge in survey research by automatically 
applying the appropriate statistical and visual treatment based on the data structure, 
eliminating the need for manual data manipulation or separate graphing procedures.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt over(varname)} specifies the grouping variable for creating stacked bars. Each category
of {it:varname} will be displayed as a separate stacked bar. String variables are automatically
encoded. This option is required.

{phang}
{opt title(string)} specifies the graph title. If not specified, defaults to 
"Stacked Percentage Bar".

{phang}
{opt n} displays sample sizes in both the graph title and individual category labels on the x-axis.
The overall sample size appears as "(N = #)" in the title, and individual group sizes appear
as "(n = #)" in the category labels.

{dlgtab:Display}

{phang}
{opt recast(string)} changes the graph type. Options include {cmd:bar} (vertical bars),
{cmd:hbar} (horizontal bars), {cmd:dot}, and other graph types supported by Stata's 
{cmd:graph} command. The command automatically defaults to {cmd:bar} for single categorical 
variables and {cmd:hbar} for multiple binary variables to optimize readability.

{phang}
{opt intensity(#)} controls the color intensity of bars, from 0 (lightest) to 100 (darkest).
Default is 50.

{dlgtab:Customization}

{phang}
{opt overopts(string)} passes options to the {cmd:over()} specification in the underlying
{cmd:graph bar} command. Use this to control category ordering, label formatting, or spacing.
For example: {cmd:overopts("sort(1) descending")} or {cmd:overopts("label(angle(45))")}.

{phang}
{opt blabelopts(string)} passes options to the {cmd:blabel()} specification. Use this to
customize bar label appearance, positioning, or formatting. For example: 
{cmd:blabelopts("position(outside)")} or {cmd:blabelopts("size(small) format(%3.0f)")}.

{phang}
{opt legendopts(string)} passes options to the {cmd:legend()} specification. Use this to
control legend positioning, styling, or visibility. For example: {cmd:legendopts("position(3)")}
or {cmd:legendopts("rows(1)")} or {cmd:legendopts("off")}.

{phang}
{opt graphopts(string)} passes additional options to the underlying {cmd:graph bar} command.
Use this for advanced customization like schemes, notes, or axis formatting.

{dlgtab:Export}

{phang}
{opt saving(filename)} saves the graph to a file. If no file extension is specified,
saves as PNG. Supported formats include .png, .pdf, .eps, .svg, and others supported by
{cmd:graph export}.


{marker examples}{...}
{title:Examples}

{pstd}Setup for examples:{p_end}
{phang2}. {stata sysuse nlsw88, clear}{p_end}

{pstd}Basic single categorical variable:{p_end}
{phang2}. {stata stackbar collgrad, over(race)}{p_end}

{pstd}Single categorical with if condition and title:{p_end}
{phang2}. {stata stackbar collgrad if age > 42, over(race) title(College Graduates by Race)}{p_end}

{pstd}Single categorical with sample size display:{p_end}
{phang2}. {stata stackbar industry if industry < 4, over(race) title(Industry Distribution by Race) n}{p_end}

{pstd}Multiple binary variables:{p_end}
{phang2}. {stata stackbar union married south, over(race)}{p_end}

{pstd}Multiple binary with sample sizes and custom title:{p_end}
{phang2}. {stata stackbar union married south, over(race) n title(Social Characteristics by Race)}{p_end}

{pstd}Override default graph type:{p_end}
{phang2}. {stata stackbar union married south, over(race) recast(bar)}{p_end}
{phang2}. {stata stackbar collgrad, over(race) recast(hbar)}{p_end}

{pstd}Legend customization:{p_end}
{phang2}. {stata stackbar collgrad, over(race) legendopts(position(3) rows(2))}{p_end}
{phang2}. {stata stackbar union married south, over(race) legendopts(rows(1) position(2))}{p_end}

{pstd}Bar label customization:{p_end}
{phang2}. {stata stackbar collgrad, over(race) blabelopts(position(outside) format(%3.0f) size(vsmall))}{p_end}

{pstd}Multiple customization options:{p_end}
{phang2}. {stata stackbar union married south, over(race) blabelopts(position(outside)) legendopts(off)}{p_end}

{pstd}Category ordering:{p_end}
{phang2}. {stata stackbar industry if industry < 3, over(race) overopts(sort(1) descending) title(Industry by Race Sorted)}{p_end}

{pstd}Complex example with multiple options:{p_end}
{phang2}. {stata stackbar union married south if age >= 25 & age <= 45, over(race) title(Working Age Characteristics) n blabelopts(size(vsmall)) legendopts(rows(1)) graphopts(note(Source - NLSW88 data))}{p_end}

{pstd}Export with full customization:{p_end}
{phang2}. {stata stackbar collgrad, over(race) title(College Education by Race) n overopts(label(angle(45))) blabelopts(format(%4.1f) color(white)) legendopts(position(6) region(lcolor(black))) saving(stackbar_example)}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:stackbar} automatically detects whether you are analyzing a single categorical variable
or multiple binary variables and applies the appropriate visualization approach:

{pstd}
{bf:Single categorical variables} are displayed with percentage distributions that sum to 100%
within each group. This is ideal for showing how responses to questions like "What is your
occupation?" vary across demographic categories.

{pstd}
{bf:Multiple binary variables} are displayed with independent response rates for each variable
within each group. This is particularly relevant for "check all that apply" questions where respondents
can select multiple options. The percentages represent the proportion of respondents in each
group who selected each option.

{pstd}
The command automatically:

{phang2}• Uses variable labels for legend entries (with fallback to variable names){p_end}
{phang2}• Handles missing values appropriately{p_end}
{phang2}• Encodes string variables automatically{p_end}
{phang2}• Calculates appropriate legend row arrangements{p_end}
{phang2}• Chooses optimal graph orientation (vertical bars for single variables, horizontal for multiple){p_end}

{pstd}
For multiple binary variables, the command validates that all variables contain only 0/1 values
and provides clear error messages if this requirement is not met.

{pstd}
The flexible "opts" system allows complete customization of all graph elements while maintaining
sensible defaults for immediate use.


{marker author}{...}
{title:Author}

{pstd}
Kabira Namit{break}
World Bank{break}
Email: knamit@worldbank.org


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
Special thanks to Catherine Johnston for suggesting the use of stacked bar charts for our current collaboration in Papua New Guinea, which led to the development of this command. And, of course, as always, thanks to Zaeen de Souza for testing and reviewing the program. {break}

