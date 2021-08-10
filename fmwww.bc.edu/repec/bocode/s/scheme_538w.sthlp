{smcl}
{* 19feb2019}{…}
{hline}
help for {hi:scheme_538}{right:(Version 1.4)}
{hline}

{title:Title}
Scheme description: 538w graphic schemes


{* index schemes}{...}
{title:Scheme description:  538w graphic schemes}

{p 4 4 2}
The 538 scheme family is: 

	{it:schemename}{col 25}Foreground{col 38}Background{col 50}description
	{hline 80}
	{cmd:538w}{...}
{col 25}color{...}
{col 38}white{...}
{col 50}color on white
	{cmd:538}{...}
{col 25}color{...}
{col 38}gray{...}
{col 50}color on white
	{cmd:538bw}{...}
{col 25}black{...}
{col 38}white{...}
{col 50}balck and white on white 
	{hline 80}

{title:Syntax}

{p 4 4 2}
For instance, you might type

{p 8 16 2}
{cmd:. graph}
...{cmd:,}
...
{cmd:scheme(538w)}

{p 8 16 2}
{cmd:. set}
{cmd:scheme}
{cmd: 538w}
[{cmd:,}
{cmdab:perm:anently}
]

{p 4 4 2}
See help {help scheme_option} and help {help set_scheme}.


{title:Description}

{p 4 4 2}
Schemes determine the overall look of a graph; see help {help schemes}.

{p 4 4 2}
The scheme {cmd:538w} relies upon the same design as {cmd:538}. Yet instead of a gray background, the background is kept in white. 

{p 4 4 2}
The scheme {cmd:538} replicates the figure design of 538 schemes for Stata. It uses 6 colors (blue; red; green; yellow; magenta; orange).   

{p 4 4 2}
The scheme {cmd:538bw} relies upon the same design as {cmd:538}. Yet instead of a gray background, the background is kept in white. Furthermore, it uses only black and white color shades.  


{title:Remarks}

{p 4 4 2}
The schemes {cmd:538} and {cmd:538w} have a gray background tinting; The schemes {cmd:538} and {cmd:538w} use 5 colors (538b; 538r, 538g; 538y; 538m; 538o); The schemes {cmd:538} and {cmd:538w} also privde shaded red and blue coloring (538bs1-538bs11; 538rs1-538rs11); y-axis labels are horizontal; gridlines are lines; gridlines are drawn for the x- and y-axis; gridlines are thin; x- and y-axis are in gray; markers are all small; lines are medium; fonts of labels are small; legends are not framed; legends appear on the right hand side of the figure; keylabels of legends are medium large; legends rely on rows first; plotregions are omitted; intensity of pie- and bar figures is reduced to 50; borderlines of histograms and bar are thin; marker symbols are reordered to assure that points in scatters are less often overlapping.  

{p 4 4 2}
The scheme {cmd:538bw} same as above, but without background color and black/gray color shading. 

{p 4 4 2}

{p 8 16 2}
{cmd:. line}
{cmd:x}
{cmd:y}
{cmd:,}
{cmdab:lcolor(538m)}
 

{p 4 4 2}
The five colors are blue, red, green, yellow and magenta. All colors are exactly the same color shade as used by 538. 

{p 8 16 2}
{cmd:538b}
{cmd:538r}
{cmd:538g}
{cmd:538y}
{cmd:538m}
{cmd:538o}


{title:References}

{p 4 8 2}
Bischof, D. 2017. New Graphic Schemes for Stata: plotplain & plottig. Stata Journal: 17(3): 1-12. {browse "https://danbischof.com/publications/"}


{title:Author}

{p 4 4 2}
{browse „bischof@ipz.uzh.ch“:Daniel Bischof}, Department of Political Science,
University of Zurich, CH.


{title:Also see}

{p 4 14 2}
Online:  help for {help schemes}; {it:{help scheme_option}}, {help set_scheme}
{p_end}


