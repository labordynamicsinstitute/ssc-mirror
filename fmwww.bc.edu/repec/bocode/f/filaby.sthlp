{smcl}
{* *! version 0.31}{...}
{viewerjumpto "Syntax" "filaby##syntax"}{...}
{viewerjumpto "Description" "filaby##description"}{...}
{viewerjumpto "Examples" "filaby##examples"}{...}
{viewerjumpto "Author" "filaby##author"}{...}
{title:Title}
{phang}
{bf:filaby} {hline 2} marks for each value of first variable first and last 
value for second variable within a frame of maxdist.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:filaby}
varlist(min=2
max=2
numeric)
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required }
{synopt:{opt max:dist(#)}}Integer as max distance{p_end}
{syntab:Optional}
{synopt:{opt s:tub(string)}}String prefix to the tow generated variables{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}First and last value of variable 2 within a {opt maxdist} for each value 
of variable 1 is marked in variables {opt stub_first} and {opt stub_last} 
(zero one variables).

{marker examples}{...}
{title:Examples}

{pstd}Generate example data:
{break}{stata "clear"}
{break}{stata "set obs 4"}
{break}{stata "set seed 123"}
{break}{stata "gen id = _n * 100"}
{break}{stata "strofnum id"}
{break}{stata "generate exp = runiformint(1,10)"}
{break}{stata "expand exp"}
{break}{stata "drop exp"}
{break}{stata "generate time = runiformint(1,6)"}
{break}{stata "bysort id: replace time = sum(time)"}
{break}{stata "list, noobs sepby(id)"}


{pstd}Using {cmd:filaby} to create time blocks of max length 5 within each id:
{break}{stata "filaby id time, maxdist(5) stub(my)"}
{break}{stata "list, noobs sepby(id)"}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:nbru@rn.dk":nbru@rn.dk}
{p_end}
