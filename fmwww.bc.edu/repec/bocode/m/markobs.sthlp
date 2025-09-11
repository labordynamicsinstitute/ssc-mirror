{smcl}
{* *! version 1.2.0  15aug2025}{...}
{cmd:help markobs}
{hline}

{title:Title}

{p2colset 5 40 42 2}{...}
{p2col:{bf:[Community-contributed] markobs} {hline 2}}Mark observations for inclusion{p_end}
{p2colreset}{...}


{title:Syntax}

    Create new marker variable

{p 8 19 2}{cmd:markobs} {it:newmarkvar}
{ifin} {weight}
[{cmd:,} {cmdab:zero:weight} {it:{help markobs##mark_options:mark_options}}]


    Modify existing marker variable

{p 8 19 2}{cmd:markobs} {it:markvar} {varlist} [{cmd:,}
{cmdab:s:trok}
{cmdab:sysmis:sok}
{it:{help markobs##markout_options:markout_options}}]


{pstd}
{cmd:aweight}s, {cmd:fweight}s, {cmd:pweight}s, and {cmd:iweight}s are
allowed; see {help weight}.{p_end}
{pstd}
Time-series operators are allowed; see {help tsvarlist}.


{title:Description}

{pstd}
{cmd:markobs}
is a wrapper for official Stata's 
{helpb mark}
and
{helpb markout}
commands. 
It creates and modifies a 0/1 to-use variable
that records which observations are to be used in subsequent code. 

{pstd}
The syntax diagrams reflect the workflow. 
The first syntax creates a new 0/1 to-use variable, {it:newmarkvar}, 
and sets it to 0 for observations 
that do not satisfy the {cmd:if} expression, 
fall outside the {cmd:in} range, 
or have a {it:weight} of zero
(see rules 1--4 and 7 in {it:Remarks} below).
No {it:varlist} is allowed.

{pstd}
Subsequent calls to {cmd:markobs} further restrict observations 
by setting an existing 0/1 to-use variable to 0 
if any of the variables in {it:varlist} are strings 
or contain missing values (see rules 5 and 6 in {it:Remarks} below).
{cmd:markobs} 
will exit with an error 
if the specified marker variable, {it:markvar}, was not created by {cmd:markobs}. 
This behavior reduces the risk of unintentionally overwriting an existing variable 
when the marker variable name is omitted or misspecified. 


{title:Options}

{phang}
{cmd:zeroweight} 
deletes rule 1 in {it:Remarks} below, 
meaning that observations will not be excluded because the weight is zero.

{phang}
{cmd:strok} 
specifies that string variables in {it:varlist} are to be allowed.  
{cmd:strok} changes rule 6 in {it:Remarks} below to read 

{pmore}
    "The marker variable is set to 0 in observations for which any of 
      the string variables in {it:varlist} is empty (contain {cmd:""})."

{phang}
{cmd:sysmissok} 
specifies that numeric variables in {it:varlist} 
equal to system missing ({cmd:.}) are to be allowed 
and only numeric variables equal to extended missing ({cmd:.a}, {cmd:.b}, ...) 
are to be excluded.
The default is 
that all missing values ({cmd:.}, {cmd:.a}, {cmd:.b}, ...) are excluded.

{marker mark_options}{...}
{phang}
{it:mark_options}
are options used with the {helpb mark} command.

{marker mark_options}{...}
{phang}
{it:markout_options}
are options used with the {helpb markout} command.


{title:Remarks}

{pstd}
When you use {cmd:markobs}, the following rules apply:

{phang}
 1.  The marker variable is set to 0 in observations for which {it:weight}
    is 0 (but see option {cmd:zeroweight}).

{phang}
2.  The appropriate error message is issued, and everything stops if
    {it:weight} is invalid (such as being less than 0 in some observation or
    being a noninteger for frequency weights).

{phang}
3.  The marker variable is set to 0 in observations for which the {cmd:if}
    {it:exp} is not satisfied.

{phang}
4.
    The marker variable is set to 0 in observations outside the {cmd:in}
    {it:range}.

{phang}
5.  The marker variable is set to 0 in observations for which any of the
    numeric variables in {it:varlist} contain a numeric missing value.

{phang}
6.  The marker variable is set to 0 in all observations if any of the
    variables in {it:varlist} are strings; see option {cmd:strok} for
    an exception.

{phang}
7.  The marker variable is set to 1 in the remaining observations.


{title:Example}

{pstd}
Setup{p_end}
{phang2}
{cmd:. sysuse auto}

{pstd}
Create a marker variable, {cmd:touse}, indicating foreign cars{p_end}
{phang2}
{cmd:. markobs touse if foreign == 1}

{pstd}
Modify the marker variable 
to exclude observations with missing values on {cmd:rep78}{p_end}
{phang2}
{cmd:. markobs touse rep78}


{title:Acknowledgments}

{pstd}
{cmd:markobs}
builds on an idea suggested by Dirk Enzmann on 
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1780903-stata-almost-excellent":Statalist}


{title:Support}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com


{title:Also see}

{psee}
Manual:  {manlink P mark}

{psee}
{space 2}Help:  {manhelp mark P}
{p_end}
