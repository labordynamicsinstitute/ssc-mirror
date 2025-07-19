{smcl}
{* *! version 1.0.0 04Jul2025}{...}

{title:Title}

{p2colset 5 26 27 2}{...}
{p2col:{hi:markovsteadystate} {hline 2}} Steady state probabilities for Markov chains{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:markovsteadystate}
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
{cmd:markovsteadystate} computes the steady-state probabilities of the Markov chain (also referred to as equilibrium distribution or stationary distribution), indicating the 
long-term behavior of the system regardless of the initial state. In other words, it is the state the chain settles into after many transitions.



{title:Options}

{p 4 8 2}
{opth format(%fmt)} specifies the format for displaying the numeric results in the table. The default is {cmd:format(%6.3g)}.


		
{title:Examples}

{pstd}For this example we generate a 4 X 4 matrix of transition probabilities, based on Table 1 of Avery and Henderson (1999).  {p_end}

{phang2}{cmd:. matrix pre = (0.36, 0.14, 0.17, 0.33 \ 0.38, 0.16, 0.02, 0.44 \ 0.31, 0.20, 0.15, 0.34 \ 0.28, 0.18, 0.18, 0.36)} {p_end}
{phang2}{cmd:. matrix rownames pre = A C G T} {p_end}
{phang2}{cmd:. matrix colnames pre = A C G T} {p_end}

{pstd}We use {cmd:markovsteadystate} to compute the steady-state probabilities of the Markov chain. {p_end}

{phang2}{cmd:. markovsteadystate pre} {p_end}

{pstd}The results indicate that the system will be in state "A" for approximately 32.7% of the time, 16.6% of the time in state "C", 
14.6% of the time in sate "G", and 36.1% of the time in state "T". {p_end}



{title:Stored results}

{pstd}
{cmd:markovsteadystate} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(steadystate)}}the steady state probabilities{p_end}




{marker references}{title:References}

{p 4 8 2}
Avery P. J. and D. A. Henderson. (1999). Fitting Markov chain models to discrete state series such as DNA sequences. 
{it:Journal of the Royal Statistical Society Series C: Applied Statistics} 48: 53-61.



{marker citation}{title:Citation of {cmd:markovsteadystate}}

{p 4 8 2}{cmd:markovsteadystate} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVSTEADYSTATE: Stata module to compute steady state probabilities for Markov chains. {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb randmarkovseq} (if installed), {helpb markovci} (if installed), {helpb markovfirstorder} (if installed), {helpb markovpredict} (if installed),
{helpb markovtheotrans} (if installed), {helpb markovmfpt} (if installed) {p_end}

