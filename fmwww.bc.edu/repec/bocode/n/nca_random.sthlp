{smcl}
{* *! version 0.7 09 Jul 2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install nca" "ssc install nca"}{...}
{vieweralsosee "Help nca (if installed)" "help nca"}{...}
{viewerjumpto "Syntax" "nca_random##syntax"}{...}
{viewerjumpto "Description" "nca_random##description"}{...}
{viewerjumpto "Options" "nca_random##options"}{...}
{viewerjumpto "Remarks" "nca_random##remarks"}{...}
{viewerjumpto "Examples" "nca_random##examples"}{...}
{title:Title}
{phang}
{bf:nca_random} {hline 2} Generates random datapoints for y and x to be used for necessary condition analysis (NCA).


{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:nca_random}
[{it: stub} {it:varname}]
[{cmd:,}
{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required }
{synopt:{opt n(#)}} Number of observations.

{synopt:{opt i:ntercepts(numlist)}} A list of intercepts.

{synopt:{opt s:lopes(numlist)}} A list of slopes. 

{syntab:Optional}
{synopt:{opt c:orner(#)}} Define which corner should be empty, default is 1 (upper left).

{synopt:{opt xd:istribution(string)}}  The distribution to be used to simulate the conditions.

{synopt:{opt yd:istribution(string)}}  The distribution to be used to simulate the outcomes.

{synopt:{opt xm:ean(#)}}  Mean of the condition variables to be generated. Only used if {bf: xdistribution}(normal) is specified.

{synopt:{opt ym:ean(#)}}  Mean of the outcome variable to be generated. Only used if {bf: ydistribution}(normal) is specified. 

{synopt:{opt xs:d(#)}}  Standard deviation of the condition variables to be generated. Only used if {bf: xdistribution}(normal) is specified.

{synopt:{opt ys:d(#)}}  Standard deviation of the outcome variable to be generated. Only used if {bf: ydistribution}(normal) is specified.

{synopt:{opt clear}} Clear the current dataset

{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:stub} contain the prefix of all of the conditions to be generated. {it: varname} contains the name of the outcome variable to be generated. The default are {bf:X} for {it:stub} and {bf:Y} for {it:varname}.

{marker description}{...}
{title:Description}
{pstd}
Generates random datapoints for Y and X to be used for necessary condition analysis (NCA).

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt n(#)}  The number of observations to be generated.

{phang}
{opt i:ntercepts(numlist)} A list of real numbers containing the intercepts. Users can choose to specify {bf: intercepts} with the same length as {bf: slopes} or to specify a single intercept, that will be replicated to match the lenght of {bf: slopes}.  The number of conditions to be generated is equal to the length of {bf: slopes} and {bf: intercepts}. 

{phang}
{opt s:lopes(numlist)}  A list of real numbers containing the slopes. Users can choose to specify {bf: slopes} with the same length as {bf: intercepts} or to specify a single intercept, that will be replicated to match the lenght of {bf: intercepts}. The number of conditions to be generated is equal to the length of {bf: slopes} and {bf: intercepts}.

{phang}
{opt c:orner(#)} Define which corner should be empty, default is 1 (upper left).

{phang}
{opt xd:istribution(string)}  the distribution to be used for the conditions. Specify {bf: uniform} or {bf: normal}. The default is {bf: uniform}.

{phang}
{opt yd:istribution(string)}  the distribution to be used for the outcome. Specify {bf: uniform} or {bf: normal}. The default is {bf: uniform}.

{phang}
{opt xm:ean(#)}  Mean of the condition variables to be generated. The default is 0.5. Only used if {bf: xdistribution}(normal) is specified.

{phang}
{opt ym:ean(#)}  Mean of the outcome variable to be generated. The default is 0.5. Only used if {bf: ydistribution}(normal) is specified.

{phang}
{opt xs:d(#)}  Standard deviation of the condition variables to be generated. The default is 0.2. Only used if {bf: xdistribution}(normal) is specified.

{phang}
{opt ys:d(#)}  Standard deviation of the outcome variable to be generated. The default is 0.2. Only used if {bf: ydistribution}(normal) is specified.

{phang}
{opt clear} Clear the current dataset.

{marker examples}{...}
{title:Examples}

{pstd} Generate 1000 observations from the uniform distribution. y is bounded by the y=x line{p_end}
{phang2}{cmd:. clear} {p_end}
{phang2}{cmd:. nca_random, n(1000) slopes(1) intercepts(0) }{p_end}
{phang2}{cmd:. twoway (scatter Y X) (function y=x), legend(off) }{p_end}


{pstd} Generate 1000 observations. y is bounded by the y=x1 and y=0.1+0.5x2 line. {p_end}
{phang2}{cmd:. clear} {p_end}
{phang2}{cmd:. nca_random, n(1000) intercepts(0 0.1) slopes(1 0.5) }{p_end}
{phang2}{cmd:. twoway (scatter Y X1) (function y=x), legend(off) }{p_end}
{phang2}{cmd:. twoway (scatter Y X2) (function y=0.1+0.5*x), legend(off) }{p_end}

{pstd}Generate 1000 observations from the normal distribution (both x and y). The x has mean 0.4 and standard deviation equal to 0.1, y is bounded by the y=0.1+0.4x line and has 0.5 mean and 0.2 standard devation. {p_end}
{phang2}{cmd:. clear} {p_end}
{phang2}{cmd:. nca_random, n(1000)  intercepts(0.1) slopes(0.4) xdistribution(normal) xmean(0.4) xsd(0.1) ydistribution(normal)}{p_end}
{phang2}{cmd:. twoway (scatter Y X) (function y=0.4*x + 0.1 ), legend(off) }{p_end}

{pstd} Generate 1000 observations from the uniform distribution. y is bounded from below by the y=1-x line. {p_end}
{phang2}{cmd:. clear} {p_end}
{phang2}{cmd:. nca_random, n(1000) slopes(-1) intercepts(1) corner(3) }{p_end}
{phang2}{cmd:. twoway (scatter Y X) (function y=1-x), legend(off) }{p_end}

{title:Authors}
{pstd}Daniele Spinelli{p_end}
{pstd}Department of Statistics and Quantitative Methods {p_end}
{pstd}University of Milano-Bicocca{p_end}
{pstd}Milan, Italy{p_end}
{pstd}daniele.spinelli@unimib.it{p_end}

{pstd}Jan Dul{p_end}
{pstd}Department of Technology & Operations Management{p_end}
{pstd}Rotterdam School of Management{p_end}
{pstd}Rotterdam, The Netherlands{p_end}
{pstd}jdul@rsm.nl{p_end}

{title:Contributors}
{pstd}Govert Buijs{p_end}
{pstd}Department of Technology & Operations Management{p_end}
{pstd}Rotterdam School of Management{p_end}
{pstd}Rotterdam, The Netherlands{p_end}
{pstd}buijs@rsm.nl{p_end}
