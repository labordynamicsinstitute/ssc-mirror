{smcl}
{* *! NJC 19mar2024/30mar2024}{...}
{* *! twoway__histogram_gen version 1.1.0  15nov2022}{...}
{vieweralsosee "[G-2] graph twoway bar" "help twoway_bar"}{...}
{vieweralsosee "[G-2] graph twoway histogram" "help twoway_histogram"}{...}
{vieweralsosee "[R] histogram" "help histogram"}{...}
{viewerjumpto "Syntax" "twoway__whistogram_gen##syntax"}{...}
{viewerjumpto "Description" "twoway__whistogram_gen##description"}{...}
{viewerjumpto "Options" "twoway__whistogram_gen##options"}{...}
{viewerjumpto "Examples" "twoway__whistogram_gen##examples"}{...}
{viewerjumpto "Stored results" "twoway__whistogram_gen##results"}{...}
{title:Title}

{p 4 35 2}
{hi:twoway__whistogram_gen} {hline 2} Histogram subroutine supporting aweights and iweights


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:twoway__whistogram_gen}
	{it:varname}
	[{it:weight}]
	[{cmd:if} {it:exp}]
	[{cmd:in} {it:range}]
	[{cmd:,}
	{c -(}{it:discrete_options}|{it:continuous_options}{c )-}
	{it:common_options}]

{pstd}
where {it:discrete_options} are

	{it:discrete_options}{col 42}Description
	{hline 65}
	{cmdab:d:iscrete}{...}
{col 42}specify data are discrete
	{cmd:width(}{it:#}{cmd:)}{...}
{col 42}width of bins in {it:varname} units
	{cmd:start(}{it:#}{cmd:)}{...}
{col 42}theoretical minimum value
	{hline 65}

{pstd}
and where {it:continuous_options} are

	{it:continuous_options}{col 42}Description
	{hline 65}
	{cmd:bins(}{it:#}{cmd:)}{...}
{col 42}{it:#} of bins
	{cmd:width(}{it:#}{cmd:)}{...}
{col 42}width of bins in {it:varname} units
	{cmd:start(}{it:#}{cmd:)}{...}
{col 42}lower limit of first bin
	{hline 65}

{pstd}
and where {it:common_options} are

	{it:common_options}{col 42}Description
	{hline 65}
	{cmdab:den:sity}{...}
{col 42}draw as density (default)
	{cmdab:frac:tion}{...}
{col 42}draw as fractions
	{cmd:percent}{...}
{col 42}draw as percents
	{cmdab:freq:uency}{...}
{col 42}draw as frequencies

	{cmdab:gen:erate:(}{it:h x} [, {cmd:replace} ]{cmd:)}{...}
{col 42}generate variables

	{cmd:display}{...}
{col 42}display (bin) start and width
	{hline 64}

{pstd}
{cmd:aweight}s and {cmd:iweights} are allowed; see {help weights}. 
For more detail, see Remarks below. 


{marker description}{...}
{title:Description}

{pstd}
{cmd:twoway__whistogram_gen} generates a variable containing densities,
fractions, percents, or frequencies of the occurrence of bins (class intervals) of
{it:varname} and a corresponding variable containing bin midpoints. 
Its distinctive feature is support for {cmd:aweights} and {cmd:iweights}.

{pstd}
This tool was written for generating histograms: see
{manhelp twoway_histogram G-2:graph twoway histogram}. 
In practice, you may wish to follow by calling up 
{manhelp twoway_bar G-2:graph twoway bar}. 

{pstd}
On occasion, you may have estimated frequencies that have fractional
parts. Calling up {cmd:histogram}, 
{cmd:twoway histogram}, or {cmd:twoway__histogram_gen} will not work with such weights. Frequency weights must be integers, with no exceptions. 
A work-around for such a problem is to use this command with {cmd:iweights}
and the {cmd:frequency} option.  Other way round, the {cmd:frequency} option is
not allowed with {cmd:aweights}.

{pstd}
The intent of this command is not to generalise {cmd:twoway__histogram_gen} 
but to complement it. On the former, see also Harrison (2005). 


{marker options}{...}
{title:Options}

{phang}
{it:discrete_options} affect the parameters needed to draw a discrete
histogram.  See {manhelp histogram R} for more details.

{phang}
{it:continuous_options} affect the parameters needed to draw a continuous
histogram.  See {manhelp histogram R} for more details.

{phang}
{cmd:density},
{cmd:fraction}, 
{cmd:percent}, and 
{cmd:frequency}
    are alternatives.  They specify whether you want the histogram scaled to
    density units, fractional units, percents, or frequencies.  
    {cmd:density} is the
    default.  See {manhelp histogram R} for more details.

{phang}
{cmd:generate(}{it:h} {it:x} [{cmd:,} {cmd:replace}]{cmd:)} specifies the
names of the variables to generate.  The height of each bin will be placed in
{it:h} and the center of each bin will be placed in {it:x}.  The
{cmd:replace} option indicates that these variables may be replaced if they
already exist.

{phang}
{cmd:display} indicates that a short note be displayed indicating the number of
bins, the lower limit of the first bin, and the width of the bins.  The output
displayed is determined by whether the {cmd:discrete} option was specified.


{marker examples}{...}
{title:Examples}

{p 4 8 2}{cmd:. webuse nlswork, clear}{p_end}

{p 4 8 2}{cmd:. twoway__whistogram_gen grade [aweight=ttl_exp], percent discrete gen(percent grade_d)}{p_end}

{p 4 8 2}{cmd:. local note "note(Weighted by total experience)"}{p_end}

{p 4 8 2}{cmd:. twoway bar percent grade_d, fcolor(stc1*0.2) barw(0.8) xla(0/18) `note' name(G1, replace)}{p_end}

{p 4 8 2}{cmd:. twoway__whistogram_gen grade [iweight=ttl_exp], frequency discrete gen(frequency grade_f) }{p_end}

{p 4 8 2}{cmd:. twoway bar frequency grade_f, fcolor(stc1*0.2) barw(0.8) xla(0/18) ytitle(Total experience) name(G2, replace)}{p_end}

{p 4 8 2}{cmd:. graph combine G1 G2}{p_end}



{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, UK{break}
n.j.cox@durham.ac.uk 


{title:Acknowledgments}

{p 4 4 2}This command is just a slightly modified cousin of official 
command {help twoway__histogram_gen}. I thank Jeff Pitblado for comments. 
It is to be regarded as community-contributed. 


{title:Reference}

{p 4 8 2}Harrison, D. A. 2005. 
Stata tip 20: Generating histogram bin variables. 
{it:Stata Journal} 5: 280{c -}281. 


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:twoway__whistogram_gen} stores the following in {cmd:r()}:

{pstd}
Scalars:

	 {cmd:r(N)}      number of observations (aweights) or sum of weights (iweights)
	 {cmd:r(bin)}    number of bins
	 {cmd:r(width)}  common width of the bins
	 {cmd:r(start)}  {cmd:start()} value or minimum value of {it:varname}
	 {cmd:r(min)}    lower limit of the first non-empty bin
	 {cmd:r(max)}    upper limit of the last bin
	 {cmd:r(area)}   area of the bars

{pstd}
Macros:

	 {cmd:r(type)}   "density", "fraction", "percent", or "frequency"
