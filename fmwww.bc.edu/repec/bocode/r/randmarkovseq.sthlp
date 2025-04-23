{smcl}
{* *! version 1.0.1 21apr2025}{...}
{* *! version 1.0.0 03apr2025}{...}

{title:Title}

{p2colset 5 22 26 2}{...}
{p2col:{hi:randmarkovseq} {hline 2}} Generate random sequence from an underlying discrete time Markov chain {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:randmarkovseq}
{cmd:,} 
{opt obs}{it:(#)} 
{opt l:abels}{it:(string)} 
{opt mat:rix}{it:(string)} 
[
{opt f:irst}{it:(string)}
{opt trans:ition}[{it:tabulate_twoway_options}]
]

 
{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt obs(#)}}number of values to generate in the sequence{p_end}
{synopt:{opt l:abels(string)}}labels to assign to sequence values. The number of labels must equal the number of values in the matrix rows {p_end}
{synopt:{opt mat:rix(string)}}the name of the symmetrical matrix containing the probability distributions of the current and following states. Each row must add up to 1.0 {p_end}

{syntab:Optional}
{synopt:{opt f:irst(string)}}specify which label value should be used to initialize the sequence{p_end}
{synopt:{opt trans:ition}}produces a transition table of the current and following states based on the sequence generated{p_end}
{synopt:[{it:tabulate_twoway_options}]}specify all available options for {helpb tabulate twoway}{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				


	
{title:Description}

{pstd}
{cmd:randmarkovseq} generates a random sequence of values based on the transition probabilities from an underlying discrete time Markov 
chain (DTMC). A DTMC is a sequence of random variables characterized by the Markov property which asserts that the distribution of the 
next state depends only on the current state and not any prior state. If the user specifies the option {cmd:transition}, a twoway 
table is produced to show the transitions from the current state to the next.

{pstd}
Note: {cmd:randmarkovseq} replaces the data in memory, so be sure to save your data!



{title:Options}

{p 4 8 2}
{cmd:obs(}{it:#}{cmd:)} the number of values to generate; {cmd:required}.

{p 4 8 2}
{cmd:labels(}{it:string}{cmd:)} labels to assign to the values generated. The number of labels should equal the number of rows in the {cmd:matrix()}; {cmd:labels()} is {cmd:required}.

{p 4 8 2}
{cmd:matrix(}{it:string}{cmd:)} matrix containing the probability distributions of the current and following states. Each row must add up to 1.0 and the matrix 
must be symmetrical (e.g. 2 X 2); {cmd:matrix()} is {cmd:required}.

{p 4 8 2}
{cmd:first(}{it:string}{cmd:)} specifies which value label should initialize the random sequencing. This does not mean that the value specified in {cmd:first()} will neccesarily be 
the first value of the sequence! If {cmd:first()} is not specified, the initial value is randomly chosen from {cmd:labels()}.

{p 4 8 2}
{cmd:transition} produces a transition table of the current and following states based on the sequence generated. The row percentages indicate the transition 
probabilities from the current state (row) to the next state (column). Pearson's chi-squared and likelihood-ratio chi-squared indicate whether the 
the state in a particular position is independent of the previous state. A significant chi-squared value indicates that the hypothesis of
independent successive states should be rejected. 

{p 4 8 2}
[{it:tabulate_twoway_options}] specifies all available options for {helpb tabulate twoway}.


		
{title:Examples}

{pstd}
Generate a 4 X 4 matrix of transition probabilities, based on Table 1 of Avery and Henderson (1999){p_end}

{phang2}{cmd:. mat A = (.3585, .1434, .1667, .3314 \  .3840, .1559, .0228, .4373 \ .3053, .1991, .1504, .3452 \ .2845, .1820, .1767, .3568)}

{pstd}
Generate a sequence of 1562 values labelled "A", "C", "G" and "T" using the transition probabilities in matrix A. We specify the "expected" 
option for the twoway tabulation. The resulting transition table is similar to that of the original data in Table 1 of Avery and Henderson (1999) {p_end}

{phang2}{cmd:. randmarkovseq , obs(1562) labels(A C G T) matrix(A) trans expected}

{pstd}
Same as above, but specify that the value "A" should be used to initialize the random sequence generation {p_end}

{phang2}{cmd:. randmarkovseq , obs(1562) labels(A C G T) matrix(A) first(A) trans expected}


	
{title:Stored results}

{pstd}
{cmd:randmarkovseq} stores the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 11 12 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}the two-way tabulation frequencies from the transition table{p_end}



{marker references}{title:References}

{p 4 8 2}
Avery P. J. and D. A. Henderson. (1999). Fitting Markov chain models to discrete state series such as DNA sequences. 
{it:Journal of the Royal Statistical Society Series C: Applied Statistics} 48: 53-61.



{marker citation}{title:Citation of {cmd:randmarkovseq}}

{p 4 8 2}{cmd:randmarkovseq} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). randmarkovseq: Stata module for generating a random sequence from an underlying discrete time Markov chain {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb tabulate twoway}, {helpb markov} (if installed){p_end}

