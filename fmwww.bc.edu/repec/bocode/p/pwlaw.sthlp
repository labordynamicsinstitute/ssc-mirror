. {smcl}
{* *! v1.2 CMUrzua 30 May 2022}{...}
{vieweralsosee "[R] help" "help help "}{...}{viewerjumpto "Syntax" "pwlaw##syntax"}{...}{viewerjumpto "Description" "pwlaw##description"}{...}
{viewerjumpto "Examples" "pwlaw##examples"}{...}{title:Title}{phang}{bf:pwlaw} {hline 2} Given a column vector of data, calculate a test statistic for power-law behavior{marker syntax}{...}{title:Syntax}{p 8 17 2}{cmdab:pwl:aw}[{varname}]{in}[{cmd:,}{it:option}]{synoptset 20 tabbed}{...}{synopthdr}{synoptline}{synopt:{opt mu:(#)}} Value of mu. Only the observations greater than mu are used; mu >= min({varname}).{p_end}{synoptline}{p2colreset}{...}{marker description}{...}{title:Description}{pstd}Given the column vector {varname}, {cmd:pwlaw} calculates the statistic proposed in Urzúa (2020) to test for power-law behavior. Since under the null PWL is asymptotically distributed as a chi-squared with two degrees of freedom, the {it:p}-value is calculated accordingly. But if the number of observations is less or equal than 100, it is better to use the critical values given in Table 1 of that paper.{marker remarks}{...}{title:Remarks}{pstd}
The statistical test is locally optimal if the possible alternative distributions are contained in the Pareto Type (IV) family. The last output of the program provides a maximum-likelihood estimate of the shape parameter alpha. If the null hypothesis of power-law behavior cannot be rejected, this estimate may be of some interest. But if the null is rejected, then alpha is not the only parameter that determines the tail of the distribution. 

{pstd}
Using the PWL test, Urzúa (2020) examines four classical data sets: the frequency of occurrence of unique words in Moby Dick; the human populations of US cities; the frequency of occurrence of US family names; and the peak gamma-ray intensity of solar flares.

{pstd}
If the researcher is interested on testing in particular for Zipf's law, the LMZ test proposed in Urzúa (2000) can be used for that end. It can be calculated using the software program {bf:lmztest} in the SSC Archive.{marker examples}{...}{title:Examples}{phang}{cmd:. pwlaw words, mu(6)}{p_end}{phang}{cmd:. pwlaw cities, mu(52360)}{p_end}

{marker references}{...}
{title:References}

{marker U2020}{...}
{phang}
Urzúa, C. M. 2000. A simple and efficient test for Zipf´s law. {it:Economics Letters} vol. 66, pp. 257-260.

{phang}
Urzúa, C. M. 2020. A simple test for power-law behavior. {it:Stata Journal} vol. 20, no. 3, pp. 604-612.
{p_end}
