{smcl}
{cmd:help usesome}
{hline}

{title:Title}

{p 5 14 2}
{cmd:usesome} {hline 2} {help Use} subset of Stata dataset


{title:Syntax}

{p 8 8 2}
{cmd:usesome} {it:{help usesome##varspec:varspec}}
{ifin} 
{helpb using} {it:{help filename}}
[{cmd:,}
{it:{help usesome##opts:options}}]

{p 8 8 2}
{cmd:usesome}
{ifin} 
{helpb using} {it:{help filename}}
[{cmd:,}
{it:{help usesome##opts:options}} 
{it:{help usesome##s_opts:selection-options}}]


{marker varspec}{...}
{p 5 10 2}
where {it:varspec} is

{p 10 10 2}
[{varlist}] [{cmd:(}{it:{help numlist}}{cmd:)}] {it:...}

{p 5 10 2}
and {it:numlist} refers to the positions of variables in the 
dataset; negative numbers specify distance from the end of 
the dataset. {it:numlists} must be enclosed in parentheses.

{p 5 10 2}
If {it:filename} is specified without an extension, {bf:.dta} 
is assumed. If {it:filename} contains embedded spaces, it must 
be enclosed in double quotes. 


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt clear}}replace the data in memory 
{p_end}
{synopt:{opt nol:abel}}do not load value labels
{p_end}

{synopt:{opt not}}load variables not specified in {it:varspec}
{p_end}

{syntab:{it:selection-options}}
{synopt:{opt has(spec)}}load variables that match {it:spec}; 
see {help ds} 
{p_end}
{synopt:{opt not(spec)}}load variables that do not match {it:spec}; 
see {help ds}
{p_end}
{synopt:{opt inse:nsitive}}perform case-insensitive pattern matching
{p_end}
{synopt:{cmd:findname(}{it:{help findname:findname-options}}{cmd:)}}load 
variables returned by {help findname}
{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:usesome} is a convenience command for loading a subset of 
a Stata dataset into memory. The command makes it easy to 
specify variables ...

{phang2}
... referring to column positions in the dataset
{p_end}

{phang2}
... {cmd:not} to be loaded
{p_end}

{phang2}
... referring to properties (e.g., numeric variables)
{p_end}

{pstd}
{cmd:usesome} is mainly intended for use with flavors of Stata, 
namely Stata BE (which was called Stata IC before Stata 17), 
that cannot load the full dataset due to restricting the number 
of variables.


{marker opts}{...}
{title:Options}

{phang}
{opt clear} replaces the data in memory, even though the 
current data have not been saved to disk; same as with {help use}.

{phang}
{opt nolabel} does not load value labels from {it:filename}; 
same as with {help use}.

{phang}
{opt not} loads variables not specified in {it:varspec} from 
{it:filename}. 

{marker s_opts}{...}
{dlgtab:Selection options}

{phang}
{opt has(spec)} and {opt not(spec)} select from {it:filename} 
the subset of variables that meet or fail the specification 
{it:spec}; see {help ds}.

{p 8 8 2}
When specified for loading a subset of a dataset with more than 
{ccl maxvar} variables, {opt has()} and {opt not()} will be slow.

{p 8 8 2}
Although it is no longer shown in the syntax diagram, {opt has()} 
and {opt not()} may be specified together with {it:varspec} and, if 
they are, add to {it:varspec} all variables that meet or fail the 
specification {it:spec}.

{p 8 8 2}
To select from {it:varspec} the subset of variables that meet or 
fail the specification {it:spec}, specify 
{cmd:ds(has(}{it:spec}{cmd:)} [{opt insensitive}]{cmd:)} or 
{cmd:ds(not(}{it:spec}{cmd:)} [{opt insensitive}]{cmd:)}.
		
{phang}
{opt insensitive} specifies that {opt has()} and {opt not()} perform 
case insensitive matching. 

{phang}
{cmd:findname(}{it:{help findname:findname-options}}{cmd:)} uses 
community-contributed {help findname} (Cox 2010a, 2010b, 2012, 2015, 2020) 
to select variables by properties. Only options for selecting variables 
are allowed. Option {opt columns()} is not allowed; variable column 
positions should instead be specified in {it:varspec}.


{title:Examples}

{pstd}
Load the first three and last three variables from the auto dataset.

{phang2}{stata "usesome (1/3 -3/-1) using http://www.stata-press.com/data/r12/auto.dta , clear":. usesome (1/3 -3/-1) using http://www.stata-press.com/data/r12/auto.dta , clear}

{pstd}
Load all variables except {cmd:foreign} from the auto dataset.

{phang2}{stata "usesome foreign using http://www.stata-press.com/data/r12/auto.dta , clear not":. usesome foreign using http://www.stata-press.com/data/r12/auto.dta , clear not}{p_end}

{pstd}
Load all variables with value labels attached from the auto dataset.

{phang2}{stata "usesome using http://www.stata-press.com/data/r12/auto.dta , clear has(vallabel)":. usesome using http://www.stata-press.com/data/r12/auto.dta , clear has(vallabel)}


{title:Saved results}

{pstd}
{cmd:usesome} saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(k)}}number of variables in {it:filename}{p_end}
{synopt:{cmd:r(chunks)}}number of {it:varlist}s 
({cmd:r(k)}/{ccl maxvar}){p_end}

{pstd}
Macros{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(varspec)}}{it:varspec}, fully expanded
{p_end}
{synopt:{cmd:r(varlist)}}variable names in {it:filename} 
(if {cmd:r(k)} < {ccl maxvar})
{p_end}
{synopt:{cmd:r(varlist}{it:#}{cmd:)}}variables in the {it:#} chunk 
of {it:filename}
{p_end}


{title:References}

{p 4 8 2}
Cox, N. J. 2020. Update: Finding variable names. {it:Stata Journal}
volume 20, number 4. ({browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X20931029":dm0048_4})
{p_end}
{p 4 8 2}
Cox, N. J. 2015. Update: Finding variable names. {it:Stata Journal}
volume 15, number 2. ({browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X1501500220":dm0048_3})
{p_end}
{p 4 8 2}
Cox, N. J. 2012. Update: Finding variable names. {it:Stata Journal}
volume 12, number 1. ({browse "http://www.stata-journal.com/article.html?article=up0035":dm0048_2})
{p_end}
{p 4 8 2}
Cox, N. J. 2010a. Update: Finding variable names. {it:Stata Journal} 
volume 10, number 4. ({browse "http://www.stata-journal.com/article.html?article=up0030":dm0048_1})
{p_end}
{p 4 8 2}
Cox, N. J. 2010b. Speaking Stata: Finding variables. {it:Stata Journal}
volume 10, number 2. ({browse "http://www.stata-journal.com/article.html?article=dm0048":dm0048})
{p_end}


{title:Author}

{pstd}
Daniel Klein{break}
{* German Centre for Higher Education Research and Science Studies{break}}
klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {help use}, {help describe}, {help ds}
{p_end}

{psee}
if installed: {help findname}, {help usedrop}, 
{help chunky}, {help savesome}
{p_end}
