{smcl}
{* *! version 1.0.0 05Jul2025}{...}

{title:Title}

{p2colset 5 25 26 2}{...}
{p2col:{hi:markovfutureprob} {hline 2}} Computes the probability distribution for future periods of a Markov chain {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:markovfutureprob}
{it:transition_matrix}
[{cmd:,} 
{opt curr:ent}{opt (string)}
{opt per:iod}{opt (#)}
{opt for:mat}{it:({help format:%fmt})} ]


{pstd}
{it:transition_matrix} is the name of the symmetrical matrix containing the probability distributions of the current and following states. Each row must add up to 1.0 {p_end}


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt curr:ent(string)}}the current state for computing the future probabilities. When unspecified, probabilities for all states are computed {p_end}
{synopt:{opt per:iod(#)}}the future period (number of steps) for computing the future probabilities; the default is {opt period(2)} {p_end}
{synopt :{opth for:mat(%fmt)}}display format for numeric values in the output table; default is {cmd:format(%6.3g)}{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				



{title:Description}

{pstd}
{cmd:markovfutureprob} computes the probability distribution of expected states in future periods, given the specified current state. 



{title:Options}

{p 4 8 2}
{cmd:current(}{it:string}{cmd:)} is the current state for evaluation. If the transition matrix has rownames, the user can specify either the rowname of the 
current state or the corresponding row number of the current state. If the matrix has no rownames, then the user must specify the corresponding matrix row number of the 
current state. When {cmd: current()} is left unspecified, all states in the transition matrix are evaluated and a {it:r X c} table is created.

{p 4 8 2}
{opth format(%fmt)} specifies the format for displaying the numeric results in the table. The default is {cmd:format(%6.3g)}.


		
{title:Examples}

{pstd}This example comes from Grinstead and Snell (2012), and describes the weather in the "Land of Oz". First we replicate the 3 X 3 matrix of theoretical transition probabilities 
for rain, nice, and snow days, and then we assign each row/column with their corresponding name.  {p_end}

{phang2}{cmd:. mat Oz = (1/2 , 1/4, 1/4 \ 1/2, 0, 1/2 \  1/4, 1/4, 1/2)} {p_end}
{phang2}{cmd:. matrix rownames Oz = rain nice snow} {p_end}
{phang2}{cmd:. matrix colnames Oz = rain nice snow} {p_end}

{pstd}We use {cmd:markovfutureprob} to compute the probability distribution for two periods into the future if the current weather is snow.{p_end}

{phang2}{cmd:. markovfutureprob Oz, curr(snow) period(2)} {p_end}

{pstd}The results indicate that if today it snows, in two days there is a 37.5% probability that it will rain, an 18.8% probability that it will be nice, and a 43.8% 
probability that it will snow.  {p_end}

{pstd}We now repeat this analysis, but instead of specifying "snow" as the destination, we specify the corresponding row number for the snow state = 3. {p_end}

{phang2}{cmd:. markovfutureprob Oz, curr(3) period(2)} {p_end}

{pstd}We now use {cmd:markovfutureprob} to compute the probabilities for all states in two days from the current day. This is accomplished by leaving {cmd:current()} unspecified. {p_end}

{phang2}{cmd:. markovfutureprob Oz, period(2)} {p_end}



{title:Stored results}

{pstd}
{cmd:markovfutureprob} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(futureprobs)}}the future probability distribution{p_end}



{marker references}{title:References}

{p 4 8 2}
Grinstead C. M. and J. L. Snell (2012). Introduction to probability.
{it:American Mathematical Society}



{marker citation}{title:Citation of {cmd:markovfutureprob}}

{p 4 8 2}{cmd:markovfutureprob} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVFUTUREPROB: Stata module to compute the probability distribution for future periods of a Markov chain {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb randmarkovseq} (if installed), {helpb markovci} (if installed), {helpb markovfirstorder} (if installed), {helpb markovpredict} (if installed),
{helpb markovtheotrans} (if installed), {helpb markovmfpt} (if installed), {helpb markovrecurrence} (if installed), {helpb markovsteadystate} (if installed) {p_end}

