{smcl}
{* *! version 1.0.0 18May2025}{...}

{title:Title}

{p2colset 5 22 23 2}{...}
{p2col:{hi:markovpredict} {hline 2}} Predicts the next state of a Markov chain model given specified past states  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:markovpredict}
{it:varname}
{cmd:,} 
{opt p:ast}({it:string})
[ {opt noi:sily} ]

{pstd}
{it: varname} is a sequence of values assumed to form a discrete time Markov chain (DTMC); {it: varname} can be either {it: string} or {it: numeric}



{title:Description}

{pstd}
{cmd:markovpredict} predicts the one-step forward state based on the conditional distribution of past states specified by the user. In the case of
ties in the mode (highest frequency) of the one-step forward state, the prediction will be randomly chosen amongst the states tied with the largest 
frequency. An error will be issued if no prediction can be made (which usually occurs when too many past states are specified).



{title:Options}

{p 4 8 2}
{opt p:ast}({it:string}) a list of one or more past states used to predict the next state, ordered from left to right from the most recent state to the most distant state. 
All past states must be specified in the same format as that of {it:varname}. Value labels are ignored for numeric variables; {cmd:past() is required}. {p_end}

{p 4 8 2}
{opt noi:sily} displays a table of frequencies of the one-step forward states, showing how the prediction was determined. {p_end}



{title:Examples}

{pstd}
Setup using preproglucacon data {p_end}

{phang2}{cmd:. use "Avery_preproglucacon.dta", clear}
 
{pstd}
Determine the one-step forward prediction when the past states are {cmd:C} and {cmd:G} (from most recent to most distant states). The variable {cmd:original} is in {it:string} format  {p_end}

{phang2}{cmd:. markovpredict original, past(C G)}

{pstd}
Same as above but also show the frequencies of the one-step forward states {p_end}

{phang2}{cmd:. markovpredict original, past(C G) nois}

{pstd}
Repeat the same analysis using the numeric variable {cmd:sequence} {p_end}

{phang2}{cmd:. markovpredict sequence, past(2 3) nois}

{pstd}
This example elicits a tie between two states for the one-step forward prediction. The resulting prediction is chosen at random  {p_end}

{phang2}{cmd:. markovpredict original, past(G T G) nois}



{title:Stored results}

{pstd}
{cmd:markovpredict} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 18 19 2: local}{p_end}
{synopt:{cmd:r(predict)}}One-step forward prediction{p_end}



{marker references}{title:References}

{p 4 8 2}
Avery P. J. and D. A. Henderson. (1999). Fitting Markov chain models to discrete state series such as DNA sequences. 
{it:Journal of the Royal Statistical Society Series C: Applied Statistics} 48: 53-61.



{marker citation}{title:Citation of {cmd:markovpredict}}

{p 4 8 2}{cmd:markovpredict} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVPREDICT: Stata module for predicting the next state of a Markov chain model given specified past states. {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb randmarkovseq} (if installed), {helpb markovci} (if installed), {helpb markovfirstorder} (if installed) {p_end}

