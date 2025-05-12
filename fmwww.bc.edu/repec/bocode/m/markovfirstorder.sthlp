{smcl}
{* *! version 1.0.0 09May2025}{...}

{title:Title}

{p2colset 5 25 26 2}{...}
{p2col:{hi:markovfirstorder} {hline 2}} Assesses whether a sequence follows an independent state model or a first-order Markov chain model  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:markovfirstorder}
{it:varname}
[{cmd:,} 
{opt noi:sily}]

{pstd}
{it: varname} is a sequence of values assumed to form a discrete time Markov chain (DTMC); {it: varname} can be either {it: string} or {it: numeric}



{title:Description}

{pstd}
{cmd:markovfirstorder} assesses whether a sequence of values follows an independent state model or a first-order Markov chain model (Avery and Henderson 1999). An independent state 
model assumes that the state in a particular position of the sequence is independent of the previous state. An independent state model is presented as a two-way table and evaluated 
using Pearson's chi-squared statistic. A statistically significant chi-squared indicates that the hypothesis of independent successive states should be rejected. Next, a first-order 
Markov chain model is assessed by analyzing a three-way table of the number of times that triplet ({it:i, j, k}) occurs where {it:i, j, k} = 1, 2, . . ., {it:b}. The Pearson's chi-squared 
statistic for a first-order Markov chain model is computed by summing the chi-squared statistic over all triplets ({it:i, j, k}), and where the degrees of freedom = {it:k} * ({it:k} - 1)^2.
A statistically significant chi-squared statistic indicates that the sequence follows a higher order than a first-order Markov chain model. See Avery and Henderson (1999) for a comprehensive
discussion. 



{title:Options}

{p 4 8 2}
{opt noi:sily} displays two-way tables for each of the {it:k} states comprising the first-order Markov chain model {p_end}



{title:Examples}

{pstd}
setup using preproglucacon data {p_end}

{phang2}{cmd:.use "Avery_preproglucacon.dta"}

{pstd}
Assess whether the data follow an independent state model or first-order Markov chain model {p_end}

{phang2}{cmd:. markovfirstorder sequence}

{pstd}
Same as above but also show results for each of the states analyses {p_end}

{phang2}{cmd:. markovfirstorder sequence, noi}



{title:Stored results}

{pstd}
{cmd:markovfirstorder} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 18 19 2: scalars}{p_end}
{synopt:{cmd:r(chi2)}}Pearson's chi-squared statistic{p_end}
{synopt:{cmd:r(p)}}p-value for Pearson's chi-squared statistic{p_end}

{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}the first-order Markov chain frequency table {p_end}
{synopt:{cmd:r(rowprobs)}}the row probabilities from the first-order table{p_end}



{marker references}{title:References}

{p 4 8 2}
Avery P. J. and D. A. Henderson. (1999). Fitting Markov chain models to discrete state series such as DNA sequences. 
{it:Journal of the Royal Statistical Society Series C: Applied Statistics} 48: 53-61.



{marker citation}{title:Citation of {cmd:markovfirstorder}}

{p 4 8 2}{cmd:markovfirstorder} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVFIRSTORDER: Stata module for assessing whether a sequence follows an independent state model or a first-order Markov chain model. {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb tabi}, {helpb markov} (if installed), {helpb randmarkovseq} (if installed), {helpb markovci} (if installed), {helpb matchi2} (if installed) {p_end}

