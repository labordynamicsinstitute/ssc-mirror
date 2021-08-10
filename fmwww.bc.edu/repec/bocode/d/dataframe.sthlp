{smcl}
{* *! version 1.0  31oct2014}{...}
{title:Title}
{vieweralsosee "preserve" "help preserve"}{...}

{p2colset 5 21 23 2}{...}
{p2col :{manlink P dataframe} {hline 2}}Store and restore stata datasets to/from memory{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{phang}Store dataset to memory

{p 8 15 2}
{opt dataframe} {opt store} {cmd:}{it:name}{cmd:}

{p 8 15 2}
{opt dataframe} {opt store} {varlist} {ifin}, {cmd:name(}{it:name}{cmd:)}

{phang}Recover dataframe from memory

{p 8 15 2}
{opt dataframe} {opt restore} {it:name} [, {cmd:nodrop} {cmd:clear}]

{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt:{opt nodrop}}Instructs {cmd:dataframe} to not drop the dateframe on restore{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dataframe} is intended to bypass some of the limitations of only having
one dataset in memory at a time. dataframe is similar to {help preserve}, with
the key differences being 1) {cmd:dataframe} stores the dataset in memory, rather than to
disk, and 2) multiple dataframes may exist in memory at the same time.

{marker limitations}{...}
{title:Limitations}

{pstd}
{cmd:dataframe} does not store dataset or variable characteristics at the moment. 
This will be added in a future revision.

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:dataframe store} stores the stata dataset in memory as a mata object.
Users with low amounts of memory and large dataset should take heed when using {cmd:dataframe}.

{marker author}{...}
{title:Author:}

{pstd}
Andrew Maurer. October 31, 2014

{marker examples}{...}
{title:Examples:}

    {hline}
{pstd}Store all data as dataframe{p_end}
{phang2}{cmd:. sysuse auto, clear}

{phang2}{cmd:. dataframe store mydataframe)}

{phang2}{cmd:. clear}

{phang2}{cmd:. dataframe restore mydataframe)}

{pstd}Store a subset of data as dataframe{p_end}
{phang2}{cmd:. sysuse auto, clear}

{phang2}{cmd:. dataframe store make price mpg foreign if foreign, name(mydataframe))}

{phang2}{cmd:. dataframe restore mydataframe, clear)}

    {hline}

{marker todo}{...}
{title:To do}

{pstd}
Work on adding:

{pstd}
- give error message if {it:name} is not a valid dataframe (for dataframe restore)

{pstd}
- dataframe save (to valid dta file) (ie equiv to save with IF/IN)

{pstd}
- dataframe list

{pstd}
- dataframe restore IF/IN

{pstd}
- allow accessing data in dataframe by variable name 

{pstd}
- align dataframe restore behavior with "use"{p_end}
	- 	what to do if there's an empty dataset, but there are 
		dataset characteristics, value labels, mata objects, etc?

{pstd}
- add support for storing/restoring variable and dataset characteristics

{pstd}
- add support for merging from dataframe to dataset






