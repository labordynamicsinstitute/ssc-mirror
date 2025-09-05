{smcl}
{* *! version 1.0.0  25nov2024}{...}

{p2colset 1 24 26 2}{...}
{p2col:{bf:descriptive_table} {hline 2}}Descriptive table with suppression of small cell counts in an active Word (.docx) document{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:descriptive_table} {varlist} {ifin} [{cmd:,} {it:options}] 

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt col:_var}}The variable that defines columns in the table{p_end}
{synopt:{opt title}}Title of the table (placed just before the table){p_end}
{synopt:{opt footnote}}Footnote of the table (placed as the last row of the table){p_end}
{synopt:{opt suppression_threshold}}Threshold under which values are suppressed as <threshold (default is no suppression){p_end}
{synopt:{opt nomeansd}}Do not display mean and standard deviation for continuous variables{p_end}
{synopt:{opt med_iqr}}Display median and interquartile range for continuous variables{p_end}
{synopt:{opt minmax}}Display minimum and maximum for continuous variables{p_end}
{synopt:{opt nomiss_percent}}Do not include missing values in the calculation of percentages{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:descriptive_table} creates a descriptive table, optionally with suppression in an active Word document generated using {manhelp putdocx RPT:putdocx}. It is meant to be used in the middle of a sequence of {cmd:putdocx} commands, it needs to
be preceded by a {cmd:putdocx begin} or will generate {error:error 198 document not created}.

{pstd}
The suppression algorithm is meant to suppress values below the threshold AND a sufficient number of other cells to avoid deriving the suppressed values by simple addition or subtraction across rows or columns.

{pstd}
The {varlist} treats variables as categorical variables if it has an {cmd:i.}, has a label, or is a string variable. In all other cases the variable is treated as continuous. 

{pstd}
A categorical variable is treated as a binary if it has 2 levels and is not a string and does not have an {cmd:i.}; this can be escaped in the function call by adding an {cmd:i.}. If binary, only the top level is printed.
Continuous variable results are rounded based on their format in the dataset. To change formatting in the table, adjust the {manhelp format D:format} directly.

{marker limits}{...}
{title:Limits}

{pstd}
Internally the {cmd:tabulate} command is called. This program is subject to the same limits, see {manhelp tabulate_twoway##limits R:tabulate twoway}.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse nlsw88.dta}{p_end}

{pstd}Format continuous variables (see above for rationale){p_end}
{phang2}{cmd:. format age %12.0f}{p_end}
{phang2}{cmd:. format wage %12.2f}{p_end}

{pstd}Start Word (.docx) document{p_end}
{phang2}{cmd:. putdocx begin}{p_end}

{pstd}Run actual table commands{p_end}
{phang2}{cmd:. descriptive_table age i.married never_married collgrad i.south i.industry wage hours, title("No suppression, single column") footnote("Example footnote.") med_iqr minmax}{p_end}
{phang2}{cmd:. descriptive_table age i.married never_married collgrad i.south i.industry wage hours, col(race) title("No suppression, multiple columns") footnote("Example footnote.") med_iqr minmax}{p_end}
{phang2}{cmd:. descriptive_table age i.married never_married collgrad i.south i.industry wage hours, title("Suppression, single column") footnote("Example footnote.") med_iqr minmax suppression_threshold(6)}{p_end}
{phang2}{cmd:. descriptive_table age i.married never_married collgrad i.south i.industry wage hours, col(race) title("Suppression, multiple columns") footnote("Example footnote.") med_iqr minmax suppression_threshold(6)}{p_end}

{pstd}Save Word (.docx) document{p_end}
{phang2}{cmd:. putdocx save "example-tables.docx", replace}{p_end}

{marker standalone}{...}
{title:Standalone use of suppression algorithm}

{pstd}
A user can also use the suppression algorithm without creating a descriptive table. The implementation of suppression uses mata, and these mata functions can be called as long as the internal naming conventions are used.

{pstd}First, explicitly include the descriptive table code to load the mata code in the active .do file or console:{p_end}
{phang2}{cmd:. findfile descriptive_table.ado}{p_end}
{phang2}{cmd:. include "`r(fn)'"}{p_end}

{pstd}Next, define the input table (as a matrix), the suppression threshold, and an empty matrix to store the suppression results (certain functions, such as {manhelp tabulate_twoway##limits R:tabulate twoway}, can also output directly into a matrix instead):{p_end}
{phang2}{cmd:. matrix _supp_data = (13,4,0\4,0,0\24,4,1\229,134,4\62,27,1)}{p_end}
{phang2}{cmd:. scalar _supp_threshold = 6}{p_end}
{phang2}{cmd:. matrix _supp_suppression = (.)}{p_end}

{pstd}These EXACT variable and matrix names are used in the mata code and MUST be used for the code to work.{p_end}

{pstd}Finally, run the suppression function in mata:{p_end}
{phang2}{cmd:. mata: do_suppression()}{p_end}
{phang2}{cmd:. matrix list _supp_suppression}{p_end}

{pstd}Note that 0 means no suppression, 1 means primary suppression (a value less than the threshold), and 2 means secondary suppression (a value that requires suppression to avoid manual derivation of the primary suppression values).{p_end}

{marker author}{...}
{title:Authors}

{pstd}
Christiaan Righolt & Colton Poitras, Orthopaedic Innovation Centre, Winnipeg, Canada
