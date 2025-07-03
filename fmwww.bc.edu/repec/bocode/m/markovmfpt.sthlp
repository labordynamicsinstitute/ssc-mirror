{smcl}
{* *! version 1.0.0 02Jul2025}{...}

{title:Title}

{p2colset 5 20 21 2}{...}
{p2col:{hi:markovmfpt} {hline 2}} Mean first passage time for ergodic Markov chains{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:markovmfpt}
{it:transition_matrix}
[{cmd:,} 
{opt dest:ination}{opt (string)}
{opt for:mat}{it:({help format:%fmt})} ]


{pstd}
{it:transition_matrix} is the name of the symmetrical matrix containing the probability distributions of the current and following states. Each row must add up to 1.0 {p_end}


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt dest:ination(string)}}the destination (target) state for computing the mean first passage time. When unspecified, all states are evaluated as destinations {p_end}
{synopt :{opth for:mat(%fmt)}}display format for numeric values in the output table; default is {cmd:format(%6.3g)}{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				



{title:Description}

{pstd}
{cmd:markovmfpt} computes the mean time (number of steps) to go from one state to another state for the first time in an ergodic Markov chain, according to Grinstead and Snell (2012). 



{title:Options}

{p 4 8 2}
{cmd:destination(}{it:string}{cmd:)} is the destination (target) state for evaluation. If the transition matrix has rownames, the user can specify either the rowname of the 
destination state or the corresponding row number of the destination state. If the matrix has no rownames, then the user must specify the corresponding matrix row number of the 
destination state. When {cmd: destination()} is left unspecified, all states in the transition matrix are evaluated and a {it:r X c} table is created.

{p 4 8 2}
{opth format(%fmt)} specifies the format for displaying the numeric results in the table. The default is {cmd:format(%6.3g)}.


		
{title:Examples}

{pstd}This example comes from Grinstead and Snell (2012), and describes the weather in the "Land of Oz". First we replicate the 3 X 3 matrix of theoretical transition probabilities 
for rain, nice, and snow days, and then we assign each row/column with their corresponding name.  {p_end}

{phang2}{cmd:. mat Oz = (1/2 , 1/4, 1/4 \ 1/2, 0, 1/2 \  1/4, 1/4, 1/2)} {p_end}
{phang2}{cmd:. matrix rownames Oz = rain nice snow} {p_end}
{phang2}{cmd:. matrix colnames Oz = rain nice snow} {p_end}

{pstd}We use {cmd:markovmfpt} to compute the mean first passage time to a day with snow.{p_end}

{phang2}{cmd:. markovmfpt Oz, dest(snow)} {p_end}

{pstd}The results show that it takes 3.33 days (on average) to get to a snow day if we start counting from a rainy day, and 2.67 days if we start from a nice day.  {p_end}

{pstd}We now repeat this analysis, but instead of specifying "snow" as the destination, we specify the corresponding row number for the snow state = 3. {p_end}

{phang2}{cmd:. markovmfpt Oz, dest(3)} {p_end}

{pstd}We now use {cmd:markovmfpt} to compute the mean first passage time for all states. This is accomplished by leaving {cmd:destination()} unspecified. {p_end}

{phang2}{cmd:. markovmfpt Oz} {p_end}



{title:Stored results}

{pstd}
{cmd:markovmfpt} stores the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(mfpt)}}the mean first passage times{p_end}




{marker references}{title:References}

{p 4 8 2}
Grinstead C. M. and J. L. Snell (2012). Introduction to probability.
{it:American Mathematical Society}



{marker citation}{title:Citation of {cmd:markovmfpt}}

{p 4 8 2}{cmd:markovmfpt} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVMFPT: Stata module to compute mean first passage time for ergodic Markov chains {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb randmarkovseq} (if installed), {helpb markovci} (if installed), {helpb markovfirstorder} (if installed), {helpb markovpredict} (if installed),
{helpb markovtheotrans} (if installed) {p_end}

