{smcl}
{* *! version 0.4 22 Jul 2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install nca" "ssc install nca"}{...}
{vieweralsosee "Help nca (if installed)" "help nca"}{...}
{viewerjumpto "Syntax" "nca_power##syntax"}{...}
{viewerjumpto "Description" "nca_power##description"}{...}
{viewerjumpto "Options" "nca_power##options"}{...}
{viewerjumpto "Remarks" "nca_power##remarks"}{...}
{viewerjumpto "Examples" "nca_power##examples"}{...}
{title:Title}
{phang}
{bf:nca_power} {hline 2} Power evaluation under a necessity framework. Calculates the power of a NCA approximate permutation test given the sample size, the ceiling, the distributions of Y and X, and the signficance level.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:nca_power}
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt n(numlist integer  >0)}} number of observations to be simulated. 

{synopt:{opt r:ep(#)}} the number of simulated datasets to be created for each value of {opt n}.   

{synopt:{opt e:ffect(#)}}  the postulated effect size. 

{synopt:{opt s:lope(#)}}  The postulated slope of the ceiling line.  

{synopt:{opt ce:iling(string)}}   Ceiling method to be used in each simulation. 

{synopt:{opt xd:istribution(string)}}  The distribution to be used to simulate the conditions. Only used if {bf: xdistribution}(normal) is specified.

{synopt:{opt yd:istribution(string)}}  The distribution to be used to simulate the outcomes. Only used if {bf: ydistribution}(normal) is specified.

{synopt:{opt xm:ean(#)}}  Mean of the condition variables to be generated.  Only used if {bf: xdistribution}(normal) is specified.

{synopt:{opt xs:d(#)}}  Standard deviation of the condition variables to be generated. Only used if {bf: xdistribution}(normal) is specified.

{synopt:{opt ym:ean(#)}}  Mean of the outcome variable to be generated. Only used if {bf: ydistribution}(normal) is specified.

{synopt:{opt ys:d(#)}}  Standard deviation of the outcome variable to be generated. Only used if {bf: ydistribution}(normal) is specified.

{synopt:{opt co:rner(#)}}  Define which corner should be empty.

{synopt:{opt t:estrep(#)}}  The number of permutations to be used in the approximate premutation test.

{synopt:{opt p(#)}} specifies the significance level to be considered during for the the approximate premutation test. 

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
Power evaluation under a necessity framework. Calculates the power of a NCA approximate permutation test given the sample size, the ceiling, the distributions of Y and X, and the signficance level.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt n(numlist integer  >0)} number of observations to be simulated. The default is{bf: 20 50 100}.

{phang}
{opt r:ep(#)} the number of simulated datasets to be created for each value of {opt n}.   The default value is 100.

{phang}
{opt e:ffect(#)}  the postulated effect size. The default values is 0.1.

{phang}
{opt s:lope(#)}  the postulated slope of the ceiling line. The default values is 1. 

{phang}
{opt ce:iling(string)}   Ceiling method to be used in each simulation. The allowed ceilings are ce_fdh, cr_fdh, ce_vrs and cr_vrs. The default is ce_fdh.

{phang}
{opt xd:istribution(string)}  The distribution to be used to simulate the conditions. Only used if {bf: xdistribution}(normal) is specified.

{phang}
{opt yd:istribution(string)}  The distribution to be used to simulate the outcomes. Only used if {bf: ydistribution}(normal) is specified.

{phang}
{opt xm:ean(#)}  Mean of the condition variables to be generated. Only used if {bf: xdistribution}(normal) is specified. 

{phang}
{opt xs:d(#)}  Standard deviation of the condition variables to be generated. Only used if {bf: xdistribution}(normal) is specified.

{phang}
{opt ym:ean(#)}  Mean of the outcome variable to be generated. Only used if {bf: ydistribution}(normal) is specified.

{phang}
{opt ys:d(#)}  Standard deviation of the outcome variable to be generated. Only used if {bf: ydistribution}(normal) is specified.

{phang}
{opt co:rner(#)}  Define which corner should be empty. The default is 1. Corner 1 is the upper-left corner, corner 2 is the upper-right corner, corner 3 is the lower-left corner, and corner 4 is the lower-right corner. 

{phang}
{opt t:estrep(#)}  The number of permutations to be used in the approximate premutation test. The default value is 200.

{phang}
{opt p(#)} specifies the significance level to be considered during for the the approximate premutation test. The default is 0.05.

{marker examples}{...}
{title:Examples}

{pstd} Power calculation based on 1000 simulation for uniform X and Y, CE-FDH ceiling.  {p_end}
{phang2}{cmd:.  set seed 123456789} {p_end}
{phang2}{cmd:.  nca_power, n(100 200 300) rep(1000) }{p_end}

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