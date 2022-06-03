{smcl}
{* *! v1.1 CMUrzua 30 May 2022}{...}
{vieweralsosee "[R] help" "help help "}{...}{viewerjumpto "Syntax" "lmztest##syntax"}{...}{viewerjumpto "Description" "lmztest##description"}{...}
{viewerjumpto "Examples" "lmztest##examples"}{...}{title:Title}{phang}{bf:lmztest} {hline 2} Given a column vector of data, calculate a test statistic for Zipf's law {marker syntax}{...}{title:Syntax}{p 8 17 2}{cmdab:lmz:test}[{varname}]{in}[{cmd:,}{it:option}]{synoptset 20 tabbed}{...}{synopthdr}{synoptline}{synopt:{opt mu:(#)}} Value of mu. Only the observations greater or equal than mu are used; mu >= min({varname}).{p_end}{synoptline}{p2colreset}{...}{marker description}{...}{title:Description}{pstd}Given the column vector {varname}, {cmd:lmztest} calculates the statistic proposed in Urzúa (2000) to test for Zipf's law. Since under the null hypothesis LMZ is asymptotically distributed as a chi-squared with two degrees of freedom, the {it:p}-value is calculated accordingly. But if the number of observations is less or equal than 30, it is better to use the critical values given in Table 1 of that paper.{marker remarks}{...}{title:Remarks}

{pstd}
It is not advisable to test for Zipf's law by means of a regression (Urzúa, 2011). The LMZ test is locally optimal if the alternative distributions also exhibit a power-law behavior. More generally, one could try to test first for power-law behavior by means of the PWL test (Urzúa 2020), which can be calculated using the software program {bf:pwlaw} in the SSC Archive.

{marker examples}{...}{title:Example}{phang}{cmd:. lmztest uscities, mu(100000)}{p_end}

{marker references}{...}
{title:References}

{marker U2020}{...}
{phang}
Urzúa, C. M. 2000. A simple and efficient test for Zipf´s law. {it:Economics Letters} vol. 66, pp. 257-260.

{phang}
Urzúa, C. M. 2011. Testing for Zipf´s law: A common pitfall. {it:Economics Letters} vol. 112, pp. 254-255.

{phang}
Urzúa, C. M. 2020. A simple test for power-law behavior. {it:Stata Journal} vol. 20, no. 3, pp. 604-612.
{p_end}
