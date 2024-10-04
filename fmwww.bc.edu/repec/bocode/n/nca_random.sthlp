{smcl}
{* *! version 1.0  3 Oct 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc nca"}{...}
{vieweralsosee "Help nca (if installed)" "help nca"}{...}
{viewerjumpto "Syntax" "C:\ado\plus\n\nca_random##syntax"}{...}
{viewerjumpto "Description" "C:\ado\plus\n\nca_random##description"}{...}
{viewerjumpto "Options" "C:\ado\plus\n\nca_random##options"}{...}
{viewerjumpto "Remarks" "C:\ado\plus\n\nca_random##remarks"}{...}
{viewerjumpto "Examples" "C:\ado\plus\n\nca_random##examples"}{...}
{title:Title}
{phang}
{bf:nca_random} {hline 2} Generates random datapoints for y and x to be used for necessary condition analysis (NCA).

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:nca_random}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt n:obs(#)}}  Number of observations. Default value is 1000.

{synopt:{opt r:eps(#)}}  Number of (x,y) variables to be created. Default value is 1.

{synopt:{opt slope(#)}}  The slope of the ceiling line .Default value is 1.

{synopt:{opt intercept(#)}}  The intercept of the ceiling line. Default value is 0.

{synopt:{opt distrx(string)}} Distribution of the x to be simulated. Can be  {bf: normal} or {bf: uniform}. Default is {bf: uniform}.

{synopt:{opt distry(string)}}  Distribution of the y to be simulated. Can be  {bf: normal} or {bf: uniform}. Default is {bf: uniform}. 

{synopt:{opt meanx(#)}}  Mean of the x variables. Valid only if {opt distrx} is {bf: normal} Default value is 0.

{synopt:{opt sdx(#)}}  Standard deviation of the x variables. Valid only if {opt distrx} is {bf: normal} Default value is 1.

{synopt:{opt meany(#)}}  Mean of the y variables. Valid only if {opt distry} is {bf: normal}. Default value is 0.

{synopt:{opt sdy(#)}}  Standard deviation of the y variables. Valid only if {opt distry} is {bf: normal}. Default value is 1.

{synopt:{opt scopex(numlist)}}  Scope of the x variables. Valid only if {opt distrx} is {bf: uniform}.

{synopt:{opt miny(#)}}  Minimum of the y variables. Valid only if {opt distry} is {bf: uniform}. Default value is 0.

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd} {bf:nca_random} {hline 2} Generates random datapoints for y and x to be used for necessary condition analysis. The x and y variables are written in the current dataset as {bf: x1}, ... , {bf: x reps}

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt n:obs(#)}   Number of observations. Default value is 1000.

{phang}
{opt r:eps(#)}  Number of (x,y) variables to be created. Default value is 1. To be used for power analysis.

{phang}
{opt slope(#)}  The slope of the ceiling line. Default value is 1.

{phang}
{opt intercept(#)}   The intercept of the ceiling line. Default value is 0.

{phang}
{opt distrx(string)}  Distribution of the x to be simulated. Can be  {bf: normal} or {bf: uniform}. For {bf: distrx(uniform)}, {cmd nca_random} generates random uniform numbers in the range given by {bf: scopex}. For For {bf: distrx(normal)}, it generates random numbers from a normal distribution with mean and standard deviation given by {bf: meanx} {bf: sdx}.

{phang}
{opt distry(string)}  Distribution of the y to be simulated. Can be  {bf: normal} or {bf: uniform}. For {bf: distry(uniform)}, {cmd nca_random} generates random uniform numbers in the range given by {bf: miny} and {bf: intercept} + {bf: slope}*{bf: x}. For For {bf: distry(normal)}, it generates random numbers from a normal distribution with mean and standard deviation given by {bf: meany} {bf: sdy} truncated from above, where the truncation points are given by {bf: minx} and {bf: intercept} + {bf: slope}*{bf: x}.

{phang}
{opt meanx(#)}  Mean of the x variables. Valid only if {opt distrx} is {bf: normal} Default value is 0.

{phang}
{opt sdx(#)}  Standard deviation of the x variables. Valid only if {opt distrx} is {bf: normal} Default value is 1.

{phang}
{opt meany(#)}  Mean of the y variables. Valid only if {opt distry} is {bf: normal}. Default value is 0.

{phang}
{opt sdy(#)}  Standard deviation of the y variables. Valid only if {opt distry} is {bf: normal}. Default value is 1.

{phang}
{opt scopex(numlist)}  Scope of the x variables. Valid only if {opt distrx} is {bf: uniform}.

{phang}
{opt miny(#)}  Minimum of the y variables. Valid only if {opt distry} is {bf: uniform}. Default value is 0.



{marker examples}{...}
{title:Examples}

{pstd}Generate 1000 observations from the uniform distribution. y is bounded by the y=x line{p_end}
{phang2}{cmd:. clear} {p_end}
{phang2}{cmd:. nca_random }{p_end}
{phang2}{cmd:. twoway (scatter y1 x1) (function y=x, range(0 1) ), legend(off) }{p_end}

{pstd}Generate 10 replications of 1000 observations from the uniform distribution. The scope of x is (50,100) y is bounded by the y=2+2x line. {p_end}
{phang2}{cmd:. clear} {p_end}
{phang2}{cmd:. nca_random, reps(10) scopex(50 100) intercept(2) slope(2) }{p_end}
{phang2}{cmd:. twoway (scatter y1 x1) (function y=2*x + 2, range(50 100) ), legend(off) }{p_end}
{phang2}{cmd:. twoway (scatter y10 x10) (function y=2*x + 2, range(50 100) ), legend(off) }{p_end}

{pstd}Generate 10 replications of 1000 observations from the normal distribution. The x has mean 50 and standard deviation equal to 3, y has mean=250, sd=30 and is bounded by the y=2+2x line. {p_end}
{phang2}{cmd:. clear} {p_end}
{phang2}{cmd:. nca_random, reps(10)  distrx(normal) meanx(50) sdx(3) distry(normal)  meany(250) sdy(30) intercept(2) slope(2) }{p_end}
{phang2}{cmd:. twoway (scatter y1 x1) (function y=2*x + 2, range(40 60) ), legend(off) }{p_end}

{title:Author}
{pstd}Daniele Spinelli{p_end}
{pstd}Department of Statistics and Quantitative Methods {p_end}
{pstd}University of Milano-Bicocca{p_end}
{pstd}Milan, Italy{p_end}
{pstd}daniele.spinelli@unimib.it{p_end}