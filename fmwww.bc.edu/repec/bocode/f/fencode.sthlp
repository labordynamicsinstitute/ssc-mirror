{smcl}
{* *! version 1.1.0  01sep2025}{...}
{viewerdialog fencode "dialog fencode"}{...}
{vieweralsosee "[D] encode" "mansection D encode"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] decode" "help decode"}{...}
{vieweralsosee "[D] label" "help label"}{...}
{vieweralsosee "[G-2] graph bar" "help graph bar"}{...}
{viewerjumpto "Syntax" "fencode##syntax"}{...}
{viewerjumpto "Description" "fencode##description"}{...}
{viewerjumpto "Options" "fencode##options"}{...}
{viewerjumpto "Examples" "fencode##examples"}{...}
{viewerjumpto "Remarks" "fencode##remarks"}{...}
{viewerjumpto "Author" "fencode##author"}{...}
{viewerjumpto "Acknowledgments" "fencode##acknowledgments"}{...}
{title:Title}

{phang}
{bf:fencode} {hline 2} Encode string or numeric variable into numeric codes ordered by frequency


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:fencode}
{varname}
[{cmd:,} {opt gen:erate(newvar)} {opt asc:ending}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt gen:erate(newvar)}}name of new variable; default is {it:varname}{cmd:_fencode}{p_end}
{synopt:{opt asc:ending}}order categories from least to most frequent; default is most to least frequent{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fencode} provides frequency-based encoding of string and numeric variables. 
Unlike {cmd:encode} which assigns codes alphabetically, {cmd:fencode} assigns 
numeric codes ordered by frequency (descending or ascending). The command accepts 
both string variables and labeled numeric variables with non-sequential codes, 
standardizing them to sequential order. This functionality is particularly valuable 
for creating tables and graphs where frequency ordering improves interpretability, 
and for regression analysis where the most frequent category serves as a more 
meaningful base category.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt generate(newvar)} specifies the name of the new encoded variable. If not specified,
the new variable is named {it:varname}{cmd:_fencode} where {it:varname} is the name of the
variable being encoded.

{phang}
{opt ascending} orders categories from least frequent (code 1) to most frequent. The default
ordering is descending, with the most frequent category receiving code 1.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage demonstrating default behavior and options:{p_end}
{phang2}. {stata webuse hbp2, clear}{p_end}
{phang2}. {stata fencode sex}{space 14}// Creates sex_fencode with default name{p_end}
{phang2}. {stata fencode sex, gen(gender)}{space 3}// Same result with explicit name{p_end}
{phang2}. {stata fencode sex, gen(gender_asc) ascending}{space 2}// Ascending order{p_end}

{pstd}Working with city temperature data:{p_end}
{phang2}. {stata sysuse citytemp, clear}{p_end}
{phang2}. {stata fencode region}{p_end}
{phang2}. {stata graph bar (count), over(region_fencode) title("Cities by Region (automatically ordered by frequency)")}{p_end}

{pstd}Standardizing arbitrary category codes:{p_end}
{phang2}. {stata sysuse voter, clear}{p_end}
{phang2}. {stata fencode candidat}{space 3}// Converts codes 2,3,4 to clean 1,2,3{p_end}

{pstd}Using frequency ordering for regression base categories:{p_end}
{phang2}. {stata webuse hbp2, clear}{p_end}
{phang2}. {stata fencode age_grp}{p_end}
{phang2}. {stata fencode sex}{p_end}
{phang2}. {stata logit hbp i.age_grp_fencode i.sex_fencode}{space 2}// Most frequent age group as base{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
Stata's {cmd:encode} command provides essential functionality for converting string variables to 
labeled numeric variables. However, it presents several limitations in practice. First, {cmd:encode} 
assigns numeric codes alphabetically, which often conflicts with analytical needs where frequency 
or logical ordering would be more appropriate. This limitation becomes particularly apparent when 
using Stata's otherwise excellent {cmd:table} command, which lacks built-in sorting options. For instance, the command 
{cmd:table (varname), statistic(freq) statistic(percent)} produces output in the order of the 
underlying numeric codes, with no option to reorder by frequency or other criteria.

{pstd}
Second, {cmd:encode} requires explicit specification of the new variable name through the {cmd:gen()} 
option, adding unnecessary verbosity for routine data processing tasks. Third, and perhaps most 
limiting, {cmd:encode} only operates on string variables. Researchers frequently encounter labeled 
numeric variables with non-sequential codes (e.g., 2, 7, 9) from survey instruments or legacy 
systems that require standardization to sequential codes (1, 2, 3) for analysis or presentation.

{pstd}
{cmd:fencode} addresses these limitations by providing frequency-based encoding with sensible 
defaults and broader applicability. The command encodes string variables into numeric codes 
ordered by frequency, with the most frequent category receiving code 1 by default. It can also 
re-encode existing labeled numeric variables, standardizing arbitrary numeric codes into clean 
sequential series. The {opt ascending} option reverses the ordering when less frequent categories 
should appear first.

{pstd}
This functionality proves particularly valuable in several contexts:

{phang2}• {bf:Survey data analysis:} Response categories with arbitrary codes (0=Never, 1=Sometimes, 
7=Always) can be standardized to sequential codes ordered by prevalence{p_end}

{phang2}• {bf:Publication-ready tables:} Frequency tables automatically display the most important 
categories first without the need for manual sorting{p_end}

{phang2}• {bf:Panel data visualization:} Entities (firms, countries, individuals) appear in graphs 
ordered by their frequency in the dataset, improving interpretability{p_end}

{phang2}• {bf:Likert scale presentation:} Response distributions in graphs and tables follow logical 
frequency ordering rather than alphabetical ordering, particularly useful when using graphing 
commands that lack straightforward sorting options{p_end}

{pstd}
{cmd:fencode} maintains compatibility with {cmd:encode}'s core behavior: missing values remain 
missing, value labels are created automatically, and variable labels are preserved. The command 
simply extends the encoding paradigm to support frequency-based ordering and numeric input variables, 
while providing sensible defaults that reduce coding overhead.

{pstd}
{bf:Etymology:} The command name {cmd:fencode} combines "f" for frequency with "encode", 
directly indicating its purpose: frequency-based encoding.

{pstd}{bf:Handling Special Cases:}{p_end}

{pstd}
{it:Whitespace normalization:} {cmd:fencode} automatically normalizes whitespace in string
variables, preventing categories with different spacing from being treated as distinct.
Leading, trailing, and multiple internal spaces are standardized.

{pstd}
{it:Missing values:} Following {cmd:encode}'s behavior, missing values remain missing in the
encoded variable and are excluded from frequency calculations.

{pstd}
{it:Frequency ties:} When categories have identical frequencies, ties are broken alphabetically
for reproducible results.

{pstd}
{it:Numeric input:} If the input variable is numeric, it must have value labels attached.

{pstd}
{it:Variable labels:} The new variable inherits the label from the original variable.

{pstd}{bf:Comparison with encode:}{p_end}

{pstd}
While {cmd:encode} assigns codes alphabetically, {cmd:fencode} assigns them by frequency.
This difference is particularly important for:

{phang2}• {bf:Visualization:} Graphs become more interpretable with categories ordered by prevalence{p_end}

{phang2}• {bf:Tables:} Frequency tables show the most important categories prominently{p_end}

{phang2}• {bf:Analysis:} Some procedures benefit from sequential coding starting at 1{p_end}

{phang2}• {bf:Data standardization:} Non-sequential numeric codes are converted to sequential ones{p_end}

{pstd}
The original data order is preserved. Only the new variable is created.


{marker author}{...}
{title:Author}

{pstd}
Kabira Namit{break}
World Bank{break}
Email: knamit@worldbank.org


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
Thanks to Zoya Namit and Sofia Namit for playing somewhat independently and allowing their father to tinker away with Stata programs on a grey and cloudy Oxford weekend.

