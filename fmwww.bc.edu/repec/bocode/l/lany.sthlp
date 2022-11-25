{smcl}
{* *! version 1.1.0 06Oct2022}{...}
{vieweralsosee "[D] list" "help list"}{...}
{viewerjumpto "Syntax" "lany##syntax"}{...}
{viewerjumpto "Description" "lany##description"}{...}
{viewerjumpto "Options" "lany##options"}{...}
{viewerjumpto "Examples" "lany##examples"}{...}
{title:Title}

{phang}
{bf:lany} {hline 2} list values of variables for all observations in subsets of 
the data


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:lany}
[{varlist}]
{help if}
{cmd:, by(}{varlist}{cmd:)}
[{cmd:sort(}{varlist}{cmd:)}
{it:options}]

{pstd}
{it:options} are all options allowed for {help list}


{marker description}{...}
{title:Description}

{pstd}
{cmd:lany} lists the values of variables for all observations in subsets defined
by the {cmd:by()} option when the {help if} condition is true for at least one 
observation in a subset. For example, we may have a panel dataset on educational
careers of individuals and some individuals report that they went from primary 
school immediately to university. This seems unlikely, so you want to see the
entire educational history of all persons who went to university after primary
education to see what is going on.


{marker options}{...}
{title:Options}

{phang}
{opt by(varlist)} Specifies the subsets, e.g. in a panel dataset this would be the 
person identifier.

{phang}
{opt sort(varlist)} specifies the sorting order within the subset, e.g. in a panel 
dataset this would be the wave.

{pstd}
Other options from {help list} are allowed. In particular {cmd:sepby()} can be 
helpful.


{marker examples}{...}
{title:Examples}

{pstd}
Some persons in this dataset were married in one wave and never married in the 
following wave, which cannot be true. We may want to see the entire marital status
history of these individuals.

{phang}{cmd:. webuse nlswork}{p_end}

{phang}{cmd:. lany idcode year msp nev_mar if nev_mar == 1 & msp[_n-1] == 1, by(idcode) sort(year) sepby(idcode)}{p_end}
