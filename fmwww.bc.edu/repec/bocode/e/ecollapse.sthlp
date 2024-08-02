{smcl}
{viewerjumpto "Syntax" "ecollapse##syntax"}{...}
{viewerjumpto "Description" "ecollapse##description"}{...}
{viewerjumpto "Options" "ecollapse##options"}{...}
{viewerjumpto "Examples" "ecollapse##examples"}{...}

{title:Title}

{p 4 4}
{cmd:ecollapse} {hline 2} Extension of {cmd:collapse} to string variables.
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 4}
{cmd:ecollapse}
{it:... }{cmd:[(union)}{it: varlist}
{cmd:(concat)}{it: varlist}{cmd:],}
{cmd:by(}{it:varlist}{cmd:)}
{cmd:[delim(}{it:string}{cmd:)}
{cmd:sorted(}{it:varlist}{cmd:)]}
{p_end}

{p 4 4}
{it:"..."} is any other argument of baseline {cmd:collapse}.
{p_end}

{marker description}{...}
{title:Description}

{p 4 4}
This package extends base Stata {cmd:collapse} 
to summarize string variables by group. Two methods
are supported so far:
{p_end}

{p 8 8}
{cmd:(concat)}
Observations of {it:varlist} within the same {it:by}
level are stacked together. The user can set 
the concatenation order with {cmd:sorted()} option.
{p_end}

{p 8 8}
{cmd:(union)}
Distinct values of {it:varlist} within the same {it:by}
level are stacked together. This collapse option 
is optimized via bitmasking. As a result, 
this method is only feasible for 
string variables with at most 25 different values.
{p_end}

{p 4 4}
Any other argument of {cmd:collapse}
(e.g. {cmd:(max)}, {cmd:(mean)}, {cmd:(firstnm)}, ...)
can be specified within {cmd:ecollapse}.
Differently from traditional {cmd:collapse},
variable labels are preserved after collapsing.
{p_end}

{p 4 4}
Here's a visual example:

    +----------------------+
    | groupvar   A   B   C |
    |----------------------|    ->              +----------------------------+
    |        1   A   A   9 |    ecollapse       | groupvar       A     B   C |
    |        1   B   B   4 |    (concat) A      |----------------------------|
    |        1   A   A   7 |    (union)  B      |        1   A,B,A   A,B   9 |
    |        2   B   B   9 |    (max)    C      |        2   B,A,B   A,B   9 |
    |        2   A   A   7 |    , by(groupvar)  +----------------------------+
    |        2   B   B   9 |    ->
    +----------------------+

{marker options}{...}
{title:Options}

{p 4 4}
{cmd:delim(}{it:string}{cmd:)}: 
delimiter to be used in 
concatenations (default = ",").
{p_end}

{p 4 4}
{cmd:sorted(}{it:varlist}{cmd:)}: 
sort by {it:varlist} within {it:by}
before collapsing.
{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{stata clear}{p_end}
{phang2}{stata set seed 0}{p_end}
{phang2}{stata set obs 100}{p_end}
{phang2}{stata gen groupvar = mod(_n-1, 5) + 1}{p_end}
{phang2}{stata gen numvar = uniform()}{p_end}
{phang2}{stata gen strvar1 = char(floor(65 + uniform() * 5))}{p_end}
{phang2}{stata gen strvar2 = strvar1}{p_end}
{phang2}{stata sort groupvar numvar}{p_end}
{phang2}{stata drop in 1/15}{p_end}
{phang2}{stata ecollapse (concat) strvar1 (union) strvar2 (mean) numvar, by(groupvar) sorted(strvar1)}{p_end}

{marker author}{...}
{title:Author}

{p 4 4}
Diego Ciccia, Sciences Po. 
{browse "https://github.com/DiegoCiccia":Github}.
{browse "mailto:diego.ciccia@sciencespo.fr":diego.ciccia@sciencespo.fr}
{p_end}


