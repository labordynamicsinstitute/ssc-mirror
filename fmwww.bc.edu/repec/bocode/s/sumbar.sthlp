{smcl}
{* *! version 1.0.0  31jul2025}{...}
{viewerdialog sumbar "dialog sumbar"}{...}
{vieweralsosee "[G-2] graph bar" "mansection G-2 graphbar"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[G-2] graph" "help graph"}{...}
{vieweralsosee "[R] collapse" "help collapse"}{...}
{viewerjumpto "Syntax" "sumbar##syntax"}{...}
{viewerjumpto "Description" "sumbar##description"}{...}
{viewerjumpto "Options" "sumbar##options"}{...}
{viewerjumpto "Examples" "sumbar##examples"}{...}
{viewerjumpto "Remarks" "sumbar##remarks"}{...}
{viewerjumpto "Limitations" "sumbar##limitations"}{...}
{viewerjumpto "Author" "sumbar##author"}{...}
{viewerjumpto "Acknowledgments" "sumbar##acknowledgments"}{...}
{title:Title}

{phang}
{bf:sumbar} {hline 2} Create bar charts showing sums of multiple variables with proper labels


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:sumbar}
{varlist}
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt t:itle(string)}}graph title; defaults to "Totals" or "Percentage Distribution"{p_end}
{synopt:{opt by:(varname)}}create side-by-side bars for each category{p_end}
{synopt:{opt p:ercent}}show percentages instead of raw sums{p_end}
{synopt:{opt so:rt}}sort bars in descending order by value{p_end}

{syntab:Display}
{synopt:{opt n:}}show number of observations in labels or subtitle{p_end}
{synopt:{opt to:tal}}show overall total in subtitle{p_end}
{synopt:{opt keep:miss}}include observations with missing values in varlist{p_end}
{synopt:{opt i:ntensity(#)}}color intensity for bars; default is {cmd:intensity(50)}{p_end}

{syntab:Graph options}
{synopt:{opt re:cast(string)}}change graph type (bar, hbar, dot, etc.){p_end}
{synopt:{opt over:opts(string)}}options for the over() axis{p_end}
{synopt:{opt blabel:opts(string)}}options for bar labels{p_end}
{synopt:{opt legend:opts(string)}}options for legend customization{p_end}
{synopt:{opt graph:opts(string)}}additional graph options{p_end}

{syntab:Export}
{synopt:{opt sa:ving(filename)}}save graph to file; defaults to PNG if no extension specified{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:sumbar} creates bar charts showing the sums of multiple numeric variables.
The command automatically handles variable labels, category breakdowns, and formatting issues that
make Stata's built-in {cmd:graph bar} cumbersome for this common analytical task.

{pstd}
Unlike {cmd:graph bar}, {cmd:sumbar} displays proper variable labels on axes by default,
automatically calculates totals across specified variables, and can show results as either
raw sums or percentage distributions. When used with the {cmd:by()} option, it creates
color-coded grouped bars with clean legends.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt title(string)} specifies the graph title. If not specified, defaults to "Totals" for
raw sums or "Percentage Distribution" when the {cmd:percent} option is used.

{phang}
{opt by(varname)} creates grouped bars showing sums broken down by categories defined in {it:varname}.
Each variable in the {it:varlist} will have side-by-side bars for each category value.
String variables are automatically encoded. Numeric {cmd:by()} variables must have value labels.
Missing values in the {cmd:by()} variable are excluded unless {cmd:keepmiss} is specified.

{phang}
{opt percent} displays results as percentages of the overall total across all variables rather than
raw sums. The overall total is computed from all variables and all categories combined.

{phang}
{opt sort} sorts bars in descending order by value. For grouped bars (with {cmd:by()}), 
sorting is based on the total for each variable across all categories.

{dlgtab:Display}

{phang}
{opt n} displays the number of observations used in calculations. If the number of non-missing
observations varies across variables, it is shown in individual bar labels. If constant across
all variables, it is shown in the subtitle.

{phang}
{opt total} shows the overall total across all variables in the subtitle. This total
reflects the data actually used in the graph (after applying {cmd:if/in} conditions and excluding
missing values).

{phang}
{opt keepmiss} includes observations with missing values in the {it:varlist} variables. 
By default, observations with missing values in any {it:varlist} variable are excluded.
When used with {cmd:by()}, missing values in the {cmd:by()} variable are shown as a "Missing" category.

{phang}
{opt intensity(#)} controls the color intensity of bars, from 0 (lightest) to 100 (darkest).
Default is 50.

{dlgtab:Graph options}

{phang}
{opt recast(string)} changes the graph type. Options include {cmd:bar} (default), {cmd:hbar},
{cmd:dot}, and other graph types supported by Stata's {cmd:graph} command.

{phang}
{opt overopts(string)} passes options to customize the over() axis, such as label angles,
gaps between groups, or other over()-specific options.

{phang}
{opt blabelopts(string)} passes options to customize bar labels, such as position, size,
color, or format. These options supplement the default formatting.

{phang}
{opt legendopts(string)} passes options to customize the legend. The default legend appears
at the bottom in a single row. Use this to change position, layout, or other legend properties.

{phang}
{opt graphopts(string)} passes additional options to the underlying {cmd:graph} command.
Use this for advanced customization like color schemes, axis formatting, or graph size.

{dlgtab:Export}

{phang}
{opt saving(filename)} saves the graph to a file. If no file extension is specified,
saves as PNG. Supported formats include .png, .pdf, .eps, .svg, and others supported by
{cmd:graph export}.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage with the census dataset:{p_end}
{phang2}. {stata sysuse census, clear}{p_end}
{phang2}. {stata sumbar poplt5 pop5_17 pop18p}{p_end}
{phang2}. {stata sumbar poplt5 pop5_17 pop18p, title("Age Group Statistics")}{p_end}

{pstd}With category breakdown:{p_end}
{phang2}. {stata sumbar death, by(region) title("Deaths by Region")}{p_end}

{pstd}Show as percentages:{p_end}
{phang2}. {stata sumbar poplt5 pop5_17 pop18p, by(region) percent title("Age Distribution")}{p_end}

{pstd}Horizontal bars with sorting and percentages:{p_end}
{phang2}. {stata sumbar poplt5 pop5_17 pop18p, recast(hbar) sort percent}{p_end}

{pstd}With observation counts and total:{p_end}
{phang2}. {stata replace pop5_17 = . in 10}{p_end}
{phang2}. {stata sumbar poplt5 pop5_17 pop18p, n total}{p_end}

{pstd}Include missing values:{p_end}
{phang2}. {stata replace region = . in 5/8}{p_end}
{phang2}. {stata sumbar poplt5 pop5_17 pop18p, n total keepmiss}{p_end}
{phang2}. {stata sumbar death, by(region) n keepmiss title("Deaths by Region (including missing)")}{p_end}

{pstd}Export to PDF:{p_end}
{phang2}. {stata sumbar death, by(region) saving("deaths.pdf")}{p_end}

{pstd}Advanced customization:{p_end}
{phang2}. {stata sumbar death, by(region) graphopts(scheme(s1mono)) legendopts(rows(2))}{p_end}

{pstd}Customize bar labels:{p_end}
{phang2}. {stata sumbar poplt5 pop5_17 pop18p, by(region) percent blabelopts(size(tiny) position(inside))}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:sumbar} addresses common frustrations with Stata's {cmd:graph bar} command when creating
bar charts of variable sums. 

{pstd}
The command automatically:

{phang2}• Uses variable labels for axis labels (with fallback to variable names){p_end}
{phang2}• Handles missing values appropriately{p_end}
{phang2}• Formats large numbers with commas{p_end}
{phang2}• Creates proper legends for grouped bars{p_end}
{phang2}• Encodes string {cmd:by()} variables automatically{p_end}
{phang2}• Preserves and restores the original dataset{p_end}

{pstd}
When using {cmd:by()}, numeric variables must have value labels attached. String variables
are automatically encoded to create sequential categories. Missing values in the grouping 
variable are excluded unless {cmd:keepmiss} is specified, in which case they appear as a 
"Missing" category.

{pstd}
The {cmd:percent} option calculates percentages based on the overall total across all variables
and categories combined, making it easy to see how different components contribute to the whole.

{pstd}
When {cmd:by()} contains only one category, Stata automatically hides the legend as it would
be redundant. This is standard Stata behavior for single-category graphs.


{marker limitations}{...}
{title:Limitations}

{pstd}
Variable and value labels containing special characters (particularly quotes and ampersands) 
may cause errors. If you encounter issues, consider simplifying your labels before using {cmd:sumbar}.

{pstd}
Graphs with many categories (50+) in the {cmd:by()} variable may become cluttered and difficult
to read. Consider grouping categories or using a different visualization approach for such cases.


{marker author}{...}
{title:Author}

{pstd}
Kabira Namit{break}
World Bank{break}
Email: knamit@worldbank.org


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
Special thanks to Thanh Thi Mai for the assignment that led to this work. And, of course, as always, thanks to Zaeen de Souza for testing and reviewing the program. {break}

