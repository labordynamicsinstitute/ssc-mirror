{smcl}
{* *! version 1.0.0 04Jul2025}{...}

{title:Title}

{p2colset 5 29 30 2}{...}
{p2col:{hi:markovmeanrecurrence} {hline 2}} Mean recurrence time for an ergodic Markov chain{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:markovmeanrecurrence}
{it:transition_matrix}
[{cmd:,} 
{opt for:mat}{it:({help format:%fmt})} ]


{pstd}
{it:transition_matrix} is the name of the symmetrical (square) matrix containing the probability distributions of the current and following states. Each row must add up to 1.0 {p_end}


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth for:mat(%fmt)}}display format for numeric values in the output table; default is {cmd:format(%6.3g)}{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				



{title:Description}

{pstd}
{cmd:markovmeanrecurrence} computes the mean recurrence time for an ergodic Markov chain, which is the average time it takes for a process, starting from a specific state, to return to that same state (Grinstead and Snell, 2012).



{title:Options}

{p 4 8 2}
{opth format(%fmt)} specifies the format for displaying the numeric results in the table. The default is {cmd:format(%6.3g)}.


		
{title:Examples}

{pstd}For this example we generate a 4 X 4 matrix of transition probabilities, based on Table 1 of Avery and Henderson (1999).  {p_end}

{phang2}{cmd:. matrix pre = (0.36, 0.14, 0.17, 0.33 \ 0.38, 0.16, 0.02, 0.44 \ 0.31, 0.20, 0.15, 0.34 \ 0.28, 0.18, 0.18, 0.36)} {p_end}
{phang2}{cmd:. matrix rownames pre = A C G T} {p_end}
{phang2}{cmd:. matrix colnames pre = A C G T} {p_end}

{pstd}We use {cmd:markovmeanrecurrence} to compute the mean recurrence time of the Markov chain. {p_end}

{phang2}{cmd:. markovmeanrecurrence pre} {p_end}

{pstd}The results indicate that the average time for the Markov chain to return to state "A" if it currently is in state "A" is 3.056 steps, 6.0 steps for the Markov
chain to return to state "C" if it currently is in state "C", etc... {p_end}



{title:Stored results}

{pstd}
{cmd:markovmeanrecurrence} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(meanrecurr)}}the mean recurrence time{p_end}




{marker references}{title:References}

{p 4 8 2}
Grinstead C. M. and J. L. Snell (2012). Introduction to probability.
{it:American Mathematical Society}

{p 4 8 2}
Avery P. J. and D. A. Henderson. (1999). Fitting Markov chain models to discrete state series such as DNA sequences. 
{it:Journal of the Royal Statistical Society Series C: Applied Statistics} 48: 53-61.



{marker citation}{title:Citation of {cmd:markovmeanrecurrence}}

{p 4 8 2}{cmd:markovmeanrecurrence} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVMEANRECURRENCE: Stata module to compute the mean recurrence time for an ergodic Markov chain. {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb randmarkovseq} (if installed), {helpb markovci} (if installed), {helpb markovfirstorder} (if installed), {helpb markovpredict} (if installed),
{helpb markovtheotrans} (if installed), {helpb markovmfpt} (if installed), {helpb markovsteadystate} (if installed), {helpb markovfutureprob} (if installed) {p_end}

