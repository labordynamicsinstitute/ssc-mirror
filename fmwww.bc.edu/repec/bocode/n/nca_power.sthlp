{smcl}
{* *! version 1.0 21 Oct 2024}{...}
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
{bf:nca_power} {hline 2} NCA power

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
{synopt:{opt n(numlist integer  >0)}} number of observations to be simulated. The default is{bf: 20 50 100}.

{synopt:{opt r:ep(#)}} the number of simulated datasets to be created for each value of {opt n}.   The default value is 100.

{synopt:{opt e:ffect(#)}}  the postulated effect size. The default values is 0.1.

{synopt:{opt s:lope(#)}}  The postulated slope of the ceiling line. The default values is 1. 

{synopt:{opt c:eiling(string)}}   Ceiling method to be used in each simulation. The allowed ceilings are ce_fdh, cr_fdh, ce_vrs and cr_vrs. The default are ce_fdh and cr_fdh.

{synopt:{opt xd:istribution(string)}}  The distribution to be used to simulate the conditions.

{synopt:{opt yd:istribution(string)}}  The distribution to be used to simulate the outcomes.

{synopt:{opt xm:ean(#)}}  Mean of the condition variables to be generated. 

{synopt:{opt xs:d(#)}}  Standard deviation of the condition variables to be generated.

{synopt:{opt ym:ean(#)}}  Mean of the outcome variable to be generated.

{synopt:{opt ys:d(#)}}  Standard deviation of the outcome variable to be generated.

{synopt:{opt cor:ner(#)}}  Define which corner should be empty.

{synopt:{opt t:estrep(#)}}  The number of permutations to be used in the approximate premutation test. The default value is 200.

{synopt:{opt sig:nificance(#)}} specifies the significance level to be considered during for the the approximate premutation test. The default is 0.01*(100 - {it:  $S_level}), where {it:  $S_level} is the default confidence level for confidence intervals for all commands that report confidence intervals (see also {bf: help set level} and {bf: macro dir}).

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

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
{opt s:lope(#)}  The postulated slope of the ceiling line. The default values is 1. 

{phang}
{opt c:eiling(string)}   Ceiling method to be used in each simulation. The allowed ceilings are ce_fdh, cr_fdh, ce_vrs and cr_vrs. The default are ce_fdh and cr_fdh.

{phang}
{opt xd:istribution(string)}  The distribution to be used to simulate the conditions.

{phang}
{opt yd:istribution(string)}  The distribution to be used to simulate the outcomes.

{phang}
{opt xm:ean(#)}  Mean of the condition variables to be generated. 

{phang}
{opt xs:d(#)}  Standard deviation of the condition variables to be generated.

{phang}
{opt ym:ean(#)}  Mean of the outcome variable to be generated.

{phang}
{opt ys:d(#)}  Standard deviation of the outcome variable to be generated.

{phang}
{opt cor:ner(#)}  Define which corner should be empty.

{phang}
{opt t:estrep(#)}  The number of permutations to be used in the approximate premutation test. The default value is 200.

{phang}
{opt sig:nificance(#)} specifies the significance level to be considered during for the the approximate premutation test. The default is 0.01*(100 - {it:  $S_level}), where {it:  $S_level} is the default confidence level for confidence intervals for all commands that report confidence intervals (see also {bf: help set level} and {bf: macro dir}).




{marker examples}{...}
{title:Examples}
 nca_power, n(100 200 300) rep(100) 

{title:Author}
{pstd}Daniele Spinelli{p_end}
{pstd}Department of Statistics and Quantitative Methods {p_end}
{pstd}University of Milano-Bicocca{p_end}
{pstd}Milan, Italy{p_end}
{pstd}daniele.spinelli@unimib.it{p_end}


