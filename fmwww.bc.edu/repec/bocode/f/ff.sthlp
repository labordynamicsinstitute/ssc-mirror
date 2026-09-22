{smcl}
{* ff.sthlp | ff 1.0.0 | 19sep2026 *}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "ff##syntax"}{...}
{viewerjumpto "Description" "ff##description"}{...}
{viewerjumpto "Options" "ff##options"}{...}
{viewerjumpto "Wildcards" "ff##wildcards"}{...}
{viewerjumpto "Examples" "ff##examples"}{...}
{viewerjumpto "Remarks" "ff##remarks"}{...}
{viewerjumpto "Authors" "ff##authors"}{...}
{viewerjumpto "Also see" "ff##alsosee"}{...}

{marker title}{...}
{title:Title}

{p 4 4 2}
{bf:ff} {hline 2} Browse and search Stata's built-in functions
{p_end}

{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:ff}
{p_end}

{phang}
{cmd:ff} {it:text} [{cmd:,} {opt names} {opt detail} {opt open}]
{p_end}

{phang}
{cmd:ff} [{cmd:,} {opt category(cat)}]
{p_end}

{phang}
{cmd:ff} [{cmd:,} {opt all}]
{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:ff} browses and searches Stata's built-in functions.  It reads the
function documentation shipped with your copy of Stata, so the list always
matches the Stata version you are running.  No Internet connection is needed
and nothing is hard-coded.
{p_end}

{p 4 4 2}
Typed without arguments, {cmd:ff} lists the function categories together with
the number of functions in each one.
{p_end}

{p 4 4 2}
Typed with {it:text}, {cmd:ff} searches both function names and descriptions
and lists every match together with its category and a one-line summary.
{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt category(cat)} lists only the functions belonging to category
{it:cat}.  Run {cmd:ff} with no arguments to see the available category names.
{p_end}

{phang}
{opt names} searches function names only and ignores the descriptions.
{p_end}

{phang}
{opt detail} displays the complete entry for a function: its syntax,
description, domain or range, category, and the name of the corresponding
Stata help topic.  If {it:text} matches several functions, the matches are
listed; the full entry is shown when the name is exact.
{p_end}

{phang}
{opt all} lists every built-in function without any filtering.
{p_end}

{phang}
{opt open} opens Stata's own help.  {cmd:ff} {it:name}{cmd:, open} opens the
official Stata help page for {it:name}, and {cmd:ff, open} opens
{help functions}.
{p_end}

{marker wildcards}{...}
{title:Wildcards}

{p 4 4 2}
{it:text} may contain the wildcard characters {cmd:*} (any number of
characters) and {cmd:?} (any single character).  For example,
{cmd:ff *log*} lists every function whose name contains "log".
{p_end}

{marker examples}{...}
{title:Examples}

{p 4 4 2}
List the categories and how many functions each one contains:
{p_end}

{phang2}
{cmd:. ff}
{p_end}

{p 4 4 2}
Search names and descriptions for normal:
{p_end}

{phang2}
{cmd:. ff normal}
{p_end}

{p 4 4 2}
Show the complete entry for logit:
{p_end}

{phang2}
{cmd:. ff logit, detail}
{p_end}

{p 4 4 2}
List the trigonometric and hyperbolic functions:
{p_end}

{phang2}
{cmd:. ff, category(trig)}
{p_end}

{p 4 4 2}
Search function names only:
{p_end}

{phang2}
{cmd:. ff log, names}
{p_end}

{p 4 4 2}
Open Stata's own help page for normal:
{p_end}

{phang2}
{cmd:. ff normal, open}
{p_end}

{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{cmd:ff} builds its catalog from the f_*.ihlp files in the f subdirectory of
your Stata base directory, and it takes the category of each function from
Stata's category help files: math_functions, string_functions,
datetime_functions, density_functions, random_number_functions,
trig_functions, programming_functions, matrix_functions, and
time_series_functions.  Functions that appear in none of those files are
reported under other.
{p_end}

{p 4 4 2}
The ten category labels used by {cmd:ff} are math, string, date, stat,
random, trig, prog, matrix, ts, and other.  Stata 18 documents 432 built-in
functions in these categories.
{p_end}

{p 4 4 2}
SMCL markup is stripped from the documentation, so descriptions are displayed
as plain text.
{p_end}

{p 4 4 2}
The catalog is read from disk on every call, so {cmd:ff} always reflects the
documentation actually installed on your machine.  There is no cache to
invalidate, which also means {cmd:ff} keeps working after a Stata update.
{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
{bf:WU Lianghai}{break}
School of Business, Anhui University of Technology (AHUT){break}
Ma'anshan, Anhui, China{break}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{break}

{pstd}
{bf:WU Hanyan}{break}
Department of Accountancy, City University of Hong Kong (CityU){break}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}{break}

{marker alsosee}{...}
{title:Also see}

{p 4 4 2}
{help functions}, {help math_functions}, {help string_functions},
{help datetime_functions}, {help density_functions},
{help random_number_functions}, {help trig_functions},
{help programming_functions}, {help matrix_functions},
{help time_series_functions}
{p_end}
