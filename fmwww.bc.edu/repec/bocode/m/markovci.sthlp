{smcl}
{* *! version 2.0.0 21jun2025}{...}
{* *! version 1.0.0 29apr2025}{...}

{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:markovci} {hline 2}} Computes parametric and nonparametric (bootstrapped) confidence intervals for discrete time Markov chains {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Non-parametric bootstrapped confidence intervals

{p 8 17 2}
{cmd:markovci_bs}
{cmd:,} 
{opt obs}{it:(#)} 
{opt l:abels}{it:(string)} 
{opt mat:rix}{it:(string)} 
[
{opt f:irst}{it:(string)}
{opt r:eps}{it:(#)}
{opt per:centile}
{opt lev:el}{it:(#)}
{opt for:mat}{it:({help format:%fmt})}
{opt sav:ing}{it:(string)}
]


{pstd}
Parametric confidence intervals

{p 8 17 2}
{cmd:markovci_pa}
{varname}
[{cmd:,}
{opt lev:el}{it:(#)}
{opt for:mat}{it:({help format:%fmt})} ]


{pstd}
{it: varname} is a sequence of values assumed to form a discrete time Markov chain (DTMC); {it: varname} must be {it: numeric} but can have value labels



{synoptset 26 tabbed}{...}
{synopthdr:markovci_bs options}
{synoptline}
{syntab:Required}
{synopt:{opt obs(#)}}number of values to generate in the sequence{p_end}
{synopt:{opt l:abels(string)}}labels to assign to sequence values. The number of labels must equal the number of values in the matrix rows {p_end}
{synopt:{opt mat:rix(string)}}the name of the symmetrical matrix containing the probability distributions of the current and following states. Each row must add up to 1.0 {p_end}

{syntab:Optional}
{synopt:{opt f:irst(string)}}specify which label value should be used to initialize the sequence{p_end}
{synopt :{opt r:eps(#)}}perform {it:#} bootstrap replications; default is {cmd:reps(50)}{p_end}
{synopt :{opt per:centile}}displays percentile confidence intervals; default is to display normal approximation confidence intervals{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opth for:mat(%fmt)}}display format for numeric values in the output tables; default is {cmd:format(%9.0g)}{p_end}
{synopt:{opt sav:ing(string)}}save results to {it:filename}. If {it:filename} already exists, it will be replaced{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}	

{synoptset 26 tabbed}{...}
{synopthdr:markovci_pa options}
{synoptline}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opth for:mat(%fmt)}}display format for numeric values in the output tables; default is {cmd:format(%9.0g)}{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				


	
{title:Description}

{pstd}
The {cmd:markovci} package computes parametric and non-parametric confidence intervals for discrete time Markov chain transition probabilities. {cmd:markovci_pa} 
computes parametric confidence intervals using the delta method following estimation of a multinomial logistic regression. {cmd:markovci_bs} bootstraps 
randomly generated data sequences based on the transition probabilities from an underlying discrete time Markov chain (using {helpb randmarkovseq} as the 
data generating process) and produces nonparametric confidence intervals. 



{title:Options}

{p 4 8 2}
{cmd:obs(}{it:#}{cmd:)} the number of values to generate; {cmd:required}.

{p 4 8 2}
{cmd:labels(}{it:string}{cmd:)} labels to assign to the values generated. The number of labels should equal the number of rows 
in the {cmd:matrix()}; {cmd:labels()} is {cmd:required}.

{p 4 8 2}
{cmd:matrix(}{it:string}{cmd:)} matrix containing the probability distributions of the current and following states. Each row must 
add up to 1.0 and the matrix must be symmetrical (e.g. 2 X 2); {cmd:matrix()} is {cmd:required}.

{p 4 8 2}
{cmd:first(}{it:string}{cmd:)} specifies which value label should initialize the random sequencing. This does not mean that the 
value specified in {cmd:first()} will neccesarily be the first value of the sequence! If {cmd:first()} is not specified, the 
initial value is randomly chosen from {cmd:labels()}.

{p 4 8 2}
{cmd:reps(}{it:#}{cmd:)} specifies the number of bootstrap replications to be performed.
The default is 50.  A total of 50-200 replications are generally adequate for
estimates of standard error and thus are adequate for normal-approximation
confidence intervals. Estimates of confidence intervals using the percentile
method typically requires 1,000 or more replications.
 
{p 4 8 2}
{cmd:percentile} displays percentile confidence intervals for bootstrapped confidence intervals; the default is to display {cmd:normal} approximation confidence intervals.

{p 4 8 2}
{cmd:level(#)} specifies the confidence level, as a percentage, for confidence intervals. The default is {cmd:level(95)} or as set by {help set level}.

{p 4 8 2}
{opth format(%fmt)} specifies the format for displaying the individual elements of the matrix. The default is {cmd:format(%9.0g)}.

{p 4 8 2}
{opth saving(string)} saves the bootstrap results to {it:filename}. {cmd:saving()} will automatically replace a previously saved version of {it:filename}.   


		
{title:Examples}

{pstd}{cmd:Non-parametric bootstrapped confidence intervals}{p_end}

{pstd}
Generate a 4 X 4 matrix of transition probabilities, based on Table 1 of Avery and Henderson (1999){p_end}

{phang2}{cmd:. mat A = (.3585, .1434, .1667, .3314 \  .3840, .1559, .0228, .4373 \ .3053, .1991, .1504, .3452 \ .2845, .1820, .1767, .3568)}

{pstd}
Produce 100 bootstrap replications of a randomly generated sequence of 1562 values labelled "A", "C", "G" and "T" using the transition probabilities in matrix A. {p_end}

{phang2}{cmd:. markovci_bs , matrix(A) obs(1562) labels(A C G T) reps(100)}

{pstd}
Same as above, but specify that the value "A" should be used to initialize the random sequence generation, and that the format of the values be displayed as %5.3f {p_end}

{phang2}{cmd:. markovci_bs , matrix(A) obs(1562) labels(A C G T) first(A) reps(100) format(%5.3f)}

{pstd}
Same as above, but we now specify that percentile CIs be computed (and thus we increase the reps to 1000), and we save the results  {p_end}

{phang2}{cmd:. markovci_bs , matrix(A) obs(1562) labels(A C G T) first(A) reps(1000) format(%5.3f) percentile saving(Avery)}


{pstd}{cmd:Parametric confidence intervals}{p_end}

{pstd}
Setup using preproglucacon data {p_end}

{phang2}{cmd:. use "Avery_preproglucacon.dta", clear}

{pstd} Compute parametric 95% confidence interval {p_end}

{phang2}{cmd:. markovci_pa sequence }

{pstd} Change the level to 99% {p_end}

{phang2}{cmd:. markovci_pa sequence, level(99) }

{pstd} Same as above but change the formatting of the values to be displayed as %5.3f {p_end}

{phang2}{cmd:. markovci_pa sequence, level(99) format(%5.3f)}


	
{title:Stored results}

{pstd}
{cmd:markovci} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(prop)}}the transition probabilities{p_end}
{synopt:{cmd:r(lcl)}}the lower confidence limit of the transition probabilities{p_end}
{synopt:{cmd:r(ucl)}}the upper confidence limit of the transition probabilities{p_end}



{marker references}{title:References}

{p 4 8 2}
Avery P. J. and D. A. Henderson. (1999). Fitting Markov chain models to discrete state series such as DNA sequences. 
{it:Journal of the Royal Statistical Society Series C: Applied Statistics} 48: 53-61.



{marker citation}{title:Citation of {cmd:markovci}}

{p 4 8 2}{cmd:markovci} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVCI: Stata module for computing parametric and nonparametric (bootstrapped) confidence intervals for discrete time Markov chains. 
Statistical Software Components S459448, Boston College Department of Economics. 
{browse "https://ideas.repec.org/c/boc/bocode/s459448.html":https://ideas.repec.org/c/boc/bocode/s459448.html} {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb randmarkovseq} (if installed), {helpb markovfirstorder} (if installed), {helpb markovpredict}	(if installed), 
{helpb markovtheotrans} (if installed) {p_end}

