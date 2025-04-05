{smcl}
{* *! version 1.0.0 03apr2025}{...}

{title:Title}

{p2colset 5 22 26 2}{...}
{p2col:{hi:randmarkovseq} {hline 2}} Generate random sequence from an underlying discrete time Markov chain   {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:randmarkovseq}
{cmd:,} 
{opt s:ample}{it:(#)} 
{opt l:abels}{it:(string)} 
[
{opt mat:rix}{it:(string)} 
{opt f:irst}{it:(string)}
{opt trans:ition}[{it:tabulate_twoway_options}]
{opt seed:}{it:(#)}
]

 
{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt s:ample(#)}}number of values to generate{p_end}
{synopt:{opt l:abels(string)}}labels to assign to sequence values. If {opt matrix()} is specified, the number of labels must equal the number of values in the matrix rows {p_end}

{syntab:Optional}
{synopt:{opt mat:rix(string)}}the name of the symmetrical matrix containing the probability distributions of the current and following states. Each row must add up to 1.0 {p_end}
{synopt:{opt f:irst(string)}}specify which label value should begin the sequence{p_end}
{synopt:{opt trans:ition}}produces a transition table of the current and following states based on the sequence generated{p_end}
{synopt:[{it:tabulate_twoway_options}]}specify all available options for {helpb tabulate twoway}{p_end}
{synopt:{opt seed:(#)}}set random-number seed to #{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				


	
{title:Description}

{pstd}
{cmd:randmarkovseq} generates a random sequence of values from an underlying discrete time Markov chain (DTMC). A DTMC is a sequence of random variables characterized by the Markov
property which asserts that the distribution of the next state depends only on the current state and not any prior state. If the user specifies the option {cmd:transition}, a twoway 
table is produced to show the transitions from the current state to the next.

{pstd}
Note: {cmd:randmarkovseq} replaces the data in memory, so be sure to save your data!



{title:Options}

{p 4 8 2}
{cmd:sample(}{it:#}{cmd:)} the number of values to generate; {cmd:required}.

{p 4 8 2}
{cmd:labels(}{it:string}{cmd:)} labels to assign to the values generated. When {cmd: matrix()} is not specified, the number of unique labels 
indicates how many rows to create. For example, specifying {cmd:labels(A B C)} indicates that a 3 X 3 table should be generated with states 
labeled "A", "B" and "C". When {cmd: matrix()} is specified, the number of labels should equal the number of rows; {cmd:labels()} is {cmd:required}.

{p 4 8 2}
{cmd:first(}{it:string}{cmd:)} specifies the first value in the sequence. For example, if a sequence of randomly ordered months is generated, the user may wish
that the first month be "January".  

{p 4 8 2}
{cmd:transition} produces a transition table of the current and following states based on the sequence generated. The row percentages indicate the transition 
probabilities from the current state (row) to the next state (column). Pearson's chi-squared and likelihood-ratio chi-squared indicate whether the 
the state in a particular position is independent of the previous state. A significant chi-squared value indicates that the hypothesis of
independent successive states should be rejected. 

{p 4 8 2}
[{it:tabulate_twoway_options}] specifies all available options for {helpb tabulate twoway}.

{p 4 8 2}
{cmd:seed(}{it:#}{cmd:)} set random-number seed to #.
		


{title:Examples}

{pstd}
Generate a random sequence of exercise patterns (run, walk, and crawl) for 365 days, where
the first day starts with a run. Show the transition table  {p_end}
{phang2}{cmd:. randmarkovseq , sample(365) labels(run walk crawl) first(run) trans}

{pstd}
Generate a 3 X 3 matrix of transition probabilities, ensuring that each row equals 1.0{p_end}
{phang2}{cmd:. matrix A = (0.7, 0.2, 0.1 \ 0.3, 0.4, 0.3 \ 0.2, 0.45, 0.35)}

{pstd}
Same as above but we now use the transition probabilities in matrix A. We set the seed for 
reproducibility and specify the "expected" option for the twoway tabulation {p_end}
{phang2}{cmd:. randmarkovseq , sample(365) labels(run walk crawl) first(run) matrix(A) seed(123456789) trans expected}


	
{title:Stored results}

{pstd}
{cmd:randmarkovseq} stores the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 11 12 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}the two-way tabulation frequencies from the transition table{p_end}



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

