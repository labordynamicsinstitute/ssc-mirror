{smcl}
{* *! version 1.0.0 21Aug2021}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:loasampsi} {hline 2}} power and sample size analysis for limits of agreement (LOA)  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:loasampsi}
{it: mu}
{it: delta}
, {opt sd(#)}
[
{opt l:evel(#)}
{opt p:ower(#)}
{opt n(#)} ]

{pstd}
{it:mu} is mean of differences and {it:delta} is maximum allowable mean difference between the two measurement methods; {it:delta} must be larger than the LOA.


{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt sd(#)}}specify the expected standard deviation of the sample differences; {cmd:sd() is required}{p_end}
{synopt :{opt l:evel(#)}}set the confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt p:ower(#)}}specify the desired power; {cmd:power()} cannot be specified together with {cmd:n()}{p_end}
{synopt :{opt n(#)}}specify the desired sample size; {cmd:n()} cannot be specified together with {cmd:power()}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
{opt loasampsi} computes sample size at a specified power, and power at a specified sample size, for Bland and Altman's (1986) limits of agreement (LOA) analysis, 
according to the method developed by Lu et al. (2016). 

{pstd}
The results produced by {opt loasampsi} are identical to those produced by the
{browse "https://ncss-wpengine.netdna-ssl.com/wp-content/themes/ncss/pdf/Procedures/PASS/Bland-Altman_Method_for_Assessing_Agreement_in_Method_Comparison_Studies.pdf":PASS Sample Size Software}
and the R package {browse "https://github.com/nwisn/blandPower/":blandPower}.


{title:Options}

{p 4 8 2} 
{cmd:sd(}{it:#}{cmd:)} specifies the expecteded stardard deviation 
of the sample differences; {cmd:sd() is required}.

{p 4 8 2} 
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for
the limits of agreement. The default is {cmd:level(95)} or whatever is set by
{helpb set level}.

{p 4 8 2} 
{cmd:power(}{it:#}{cmd:)} specifies the desired power at which sample size is to be computed. The actual power 
derived from the analysis is reported in the output. {cmd:power()} cannot be specified together with {cmd:n()}.

{p 4 8 2} 
{cmd:n(}{it:#}{cmd:)} specifies the desired sample size at which the power is to be computed. The actual power 
derived from the analysis is reported in the output. {cmd:n()} cannot be specified together with {cmd:power()}.


{title:Examples}

{pstd}
{opt 1) Computing sample size:}{p_end}

{pstd}Set the mean difference to 0.50, the delta to 7, the SD to 2.5, and power to 0.80. {p_end}
{phang2}{cmd:. loasampsi .50 7, sd(2.5) power(0.80)}{p_end}

{pstd}
{opt 2) Computing power:}{p_end}

{pstd}Same as above but we specify n = 70 to find power at that sample size. {p_end}
{phang2}{cmd:. loasampsi .50 7, sd(2.5) n(70)}{p_end}


{title:Acknowledgments}

{p 4 4 2}
I thank John Moran for testing this package.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loasampsi} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 14 18 2: Scalars}{p_end}
{synopt:{cmd:r(mu)}}mean of differences {p_end}
{synopt:{cmd:r(delta)}}maximum allowable difference{p_end}
{synopt:{cmd:r(sd)}}standard deviation of the difference{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(power)}}actual power for the computed sample size{p_end}
{synopt:{cmd:r(n)}}computed sample size{p_end}
{p2colreset}{...}


{title:References}

{p 4 8 2}
Bland, J. M., and D. G. Altman.  1986. Statistical methods for assessing agreement between two methods of clinical measurement. {it:Lancet} I: 307-310.{p_end}

{p 4 8 2}
Lu, M. J.,Zhong, W. H., Liu, Y. X., Miao, H. Z., Li, Y. C. and M. H. Ji. 2016. Sample Size for assessing agreement
between two methods of measurement by Bland-Altman method. {it:The International Journal of Biostatistics}
Article 20150039. (Published online).{p_end}



{marker citation}{title:Citation of {cmd:loasampsi}}

{p 4 8 2}{cmd:loasampsi} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2021). LOASAMPSI: Stata module to compute power and sample size for limits of agreement (LOA) analysis



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb rmloa} (if installed) {p_end}

