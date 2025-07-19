{smcl}
{* *! version 1.1.0 07Jul2025}{...}
{* *! version 1.0.0 19Jun2025}{...}

{title:Title}

{p2colset 5 24 25 2}{...}
{p2col:{hi:markovtheotrans} {hline 2}} Tests whether a discrete time Markov chain is consistent with a theoretical transition matrix {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:markovtheotrans}
{it:varname}
{cmd:,} 
{opt trans}({it:string})

{pstd}
{it: varname} is a sequence of values assumed to form a discrete time Markov chain (DTMC); {it: varname} can be either {it: string} or {it: numeric}



{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt trans(string)}}the name of the symmetrical matrix containing the theoretical probability distribution to be be tested; {cmd: trans() is required} {p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				


	
{title:Description}

{pstd}
{cmd:markovtheotrans} tests whether the transition matrix of a discrete time Markov chain (DTMC) is consistent with a theoretical transition matrix, 
according to Kullback et al. (1962). A non-significant chi-squared test indicates that the DTMC is consistent with the theoretical transition matrix.  



{title:Options}

{p 4 8 2}
{cmd:trans(}{it:string}{cmd:)} is the matrix containing the theoretical probability distribution to be tested. Each row must add up to 1.0 and the matrix must 
be symmetrical (e.g. 2 X 2); {cmd:trans()} is {cmd:required}.



		
{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. use "kulback.dta"} {p_end}

{pstd}Replicate the 3 X 3 matrix of theoretical transition probabilities in Kulback et al. (1962) {p_end}

{phang2}{cmd:. matrix trans = (0.625, 0.250, 0.125 \ 0.250, 0.500, 0.250 \ 0.250, 0.375, 0.375 )} {p_end}

{pstd}Use {cmd:markovtheotrans} to test whether the discrete time Markov chain "sequence" is consistent with the theoretical transition matrix "trans".{p_end}

{phang2}{cmd:. markovtheotrans sequence , trans(trans)} {p_end}



{title:Stored results}

{pstd}
{cmd:markovtheotrans} stores the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 18 19 2: Scalars}{p_end}
{synopt:{cmd:r(r)}}number of rows{p_end}
{synopt:{cmd:r(c)}}number of columns{p_end}
{synopt:{cmd:r(chi2)}}chi-squared statistic{p_end}
{synopt:{cmd:r(p)}}{it:p}-value{p_end}



{marker references}{title:References}

{p 4 8 2}
Kullback S., Kupperman M. and H. Ku (1962). "Tests for Contingency Tables and Markov Chains."
{it:Technometrics} 4: 573–608



{marker citation}{title:Citation of {cmd:markovtheotrans}}

{p 4 8 2}{cmd:markovtheotrans} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MARKOVTHEOTRANS: Stata module to test whether a discrete time Markov chain is consistent with a theoretical transition matrix. 
Statistical Software Components S459467, Boston College Department of Economics.
{browse "https://ideas.repec.org/c/boc/bocode/s459467.html":https://ideas.repec.org/c/boc/bocode/s459467.html} {p_end}

{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb randmarkovseq} (if installed), {helpb markovci} (if installed), {helpb markovfirstorder} (if installed), {helpb markovpredict} (if installed),
{helpb markovmfpt} (if installed), {helpb markovrecurrence} (if installed), {helpb markovsteadystate} (if installed), {helpb markovfutureprob} (if installed) {p_end}


