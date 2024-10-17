{smcl}
{* *! version 1.0  15oct2024}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "sumdocx##syntax"}{...}
{viewerjumpto "Description" "sumdocx##description"}{...}
{viewerjumpto "Options" "sumdocx##options"}{...}
{viewerjumpto "Examples" "sumdocx##examples"}{...}
{viewerjumpto "Author" "sumdocx##author"}{...}
{viewerjumpto "Acknowledgments" "sumdocx##acknowledgments"}{...}
{title:Title}

{phang}
{bf:sumdocx} {hline 2} Generate comprehensive summary statistics and comparison tables in Word

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:sumdocx} {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt by(varname)}}perform two-group comparison{p_end}
{synopt:{opt t:itle(string)}}specify title for the table{p_end}
{synopt:{opt s:ave(string)}}specify filename to save the Word document{p_end}
{synopt:{opt th:reshold(#)}}set p-value threshold for significance (default is set at 0.05){p_end}
{synopt:{opt d:ecimals(#)}}set number of decimal places (default is set at 2 decimal places){p_end}
{synopt:{opt f:ont(string)}}specify font for the table (default is set to match your system settings){p_end}
{synopt:{opt si:ze(#)}}specify font size for the table (default is set as size 8){p_end}
{synopt:{opt c:olor(string)}}specify color for the header row (default is set as a shade of blue){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:sumdocx} creates comprehensive summary statistics tables in Microsoft Word format with just a single line of code. It offers two main functionalities:

{pmore}
1. Single-variable summaries: For each numerical variable, {cmd:sumdocx} provides a rich set of statistics including the number of observations (N), mean, median, minimum, maximum, percentage of observations at the minimum and maximum values, and the count of missing values. This comprehensive overview allows researchers to quickly understand the distribution and key characteristics of their variables.

{pmore}
2. Two-group comparisons: When using the {opt by()} option, {cmd:sumdocx} provides summary statistics similar to balance tables for comparing two groups. It presents the number of observations and means for both groups, calculates the difference in means, performs a t-test (assuming unequal variances between groups), and reports the p-value. This feature is useful for assessing balance in randomized controlled trials, comparing treatment and control groups, or any scenario where you need to contrast two subsets of your data (like pre-tests and post-tests).

{pstd}
{cmd:sumdocx} is designed to handle multiple variables with different sample sizes (rather than reducing all the variables included in the command to a common subset), making it robust for real-world datasets with missing values. Its output is directly formatted for reports, hopefully saving researchers, international organizations and iNGOs time and effort. With customizable options for fonts, colors, and decimal places, tables produced by {cmd:sumdocx} can be immediately incorporated into papers, presentations, or reports. 

{pstd}
This command requires Stata version 15 or higher due to its use of the {cmd:putdocx} command. 

{pstd}
This command filters out string variables to allow users to use the wildcard * and summarize all numerical variables in the dataset. The ignored string variables are displayed as part of the output. 

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt by(varname)} specifies a binary variable for two-group comparison. If specified, the program will perform t-tests between the two groups for each variable.

{phang}
{opt title(string)} adds a title to the output table.

{phang}
{opt save(string)} specifies the filename to save the Word document. If not specified, {cmd:sumdocx} can be used as part of a longer {cmd:putdocx} based report. 

{phang}
{opt threshold(#)} sets the p-value threshold for determining statistical significance in two-group comparisons. The default is set at 0.05.

{phang}
{opt decimals(#)} sets the number of decimal places for numeric output. The default is set at 2.

{phang}
{opt font(string)} specifies the font to be used in the table. If not specified, the default font (as per your system settings - most likely, Aptos) is used. 

{phang}
{opt size(#)} specifies the font size to be used in the table. Default font size is 8. 

{phang}
{opt color(string)} specifies the color for the first row of the table. The default is "1F497D" (my preferred shade of blue).

{marker examples}{...}
{title:Examples}

{phang2} {stata sysuse auto.dta, clear}{p_end}

{pstd}Basic use:{p_end}
{phang2} {stata sumdocx price weight mpg, save(auto)}{p_end}

{pstd}Using the by option:{p_end}
{phang2} {stata sumdocx price weight mpg, by(foreign) save(auto_foreign)}{p_end}

{pstd}Using a higher threshold for the p-value and adding a table title:{p_end}
{phang2} {stata sumdocx *, by(foreign) threshold(0.01) title("Auto Performance by Car Origin Status") save(auto_foreign2)}{p_end}

{pstd}Additional customization:{p_end}
{phang2} {stata sumdocx *, decimals(3) font("Calibri Light") size(9) color(FFA500) save(auto_customization)}{p_end}

{pstd}More customization:{p_end}
{phang2} {stata sumdocx *, by(foreign) font("Garamond") size(8.5) color(navy) save(more_customization)}{p_end}

{marker author}{...}
{title:Author}

{pstd} Kabira Namit, World Bank, knamit@worldbank.org

{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd} Special thanks to Zaeen de Souza, Ketki Samel and Prabhmeet Kaur for testing and reviewing sumdocx.{p_end}


