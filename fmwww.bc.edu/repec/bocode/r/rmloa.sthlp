{smcl}
{* *! version 1.0.0 02Aug2021}{...}
{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{hi:rmloa} {hline 2}} Limits of agreement for data with repeated measures {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:rmloa}
{it: yvar}
{it: xvar}
{ifin}
[,
{opt i}{cmd:(}{it:{help varname:varname}{cmd:})}
{opt con:stant}
{opt l:evel(#)}
{opt fig:ure}[{cmd:(}{it:{help twoway_options:twoway_options}}{cmd:)}]

{pstd}
{it:yvar} is the dependent variable and {it:xvar} is the independent variable


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt i(varname)}}subject identifier; when {cmd: i()} is not specified, the LOA is computed assuming that paired (yvar-xvar) observations are independent{p_end}
{synopt :{opt con:stant}}computes LOA for when the true value is constant; default is to use the method for when the true value varies {p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt fig:ure}[{cmd:(}{it:{help twoway_options:twoway_options}}{cmd:)}]}produce a graphical display of the LOA{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:rmloa}; see {manhelp by D}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt rmloa} computes Bland and Altman's limits of agreement (LOA) for paired X-Y observations. When {cmd:i()} is not specified, the LOA is 
computed assuming that each X-Y paired observation is independent of all other observations (Bland and Altman 1986). When {cmd:i()} is specified,
LOA is computed for repeated measures, using either the method where the true value of the difference is constant 
(by specifying the {cmd: constant} option), or the default, which uses the method where the true value of the difference varies 
(see Bland and Altman [2007] for the details of these methods).    

{pstd}
When the {opt figure} option is specified, a graph is generated that plots the difference between the Y and X variable against the mean of Y and X, 
together with the upper and lower limits of agreement and mean difference.  


{title:Options}

{p 4 8 2} 
{cmd:i(}{it:varname}{cmd:)} specifies the subjects' identifier. When {cmd: i()} is not specified, 
LOA is computed assuming that paired (yvar-xvar) observations are independent of all other pairs.

{p 4 8 2} 
{cmd:constant} computes LOA for when the true value is constant; 
default is to use the method for when the true value varies.

{p 4 8 2} 
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for
limits of agreement.  The default is {cmd:level(95)} or whatever is set by
{helpb set level}.

{p 4 8 2} 
{cmd:figure}[{cmd:(}{it:{help twoway_options:twoway_options}}{cmd:)}] produces a Bland and Altman graph that plots the difference 
between {it:dvar} and {it:xvar} against the mean of {it:dvar} and {it:xvar}. When {cmd: i()} is specified, subjects' identifiers 
are used for the markers. A line is superimposed representing the mean difference,
along with lines for the lower and upper limits of agreement. Specifying {cmd:figure} 
without options uses the default graph settings.



{title:Examples}

{pstd}Setup for independent observations {p_end}
{phang2}{cmd:. use bland1986.dta}{p_end}

{pstd}Basic specification when X-Y pairs are independent of other observations{p_end}
{phang2}{cmd:. rmloa wright mini, fig}{p_end}

{pstd}Setup for repeated measures{p_end}
{phang2}{cmd:. use bland2007.dta}{p_end}

{pstd}Specification for repeated measures using the method where the true value varies{p_end}
{phang2}{cmd:. rmloa rv ic, i(subj) fig}{p_end}

{pstd}Specification for repeated measures using the method where the true value is constant{p_end}
{phang2}{cmd:. rmloa rv ic, i(subj) constant fig}{p_end}



{title:Comments}

{pstd} The LOA results produced by {cmd:loa} for repeated measures do not match those reported in Bland and Altman (2007) due to
mathematical errors in that paper. This was reported by Jones (2019) in a subsequent letter to the editor. 



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rmloa} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(diff)}}mean difference between {it:yvar} and {it:xvar} {p_end}
{synopt:{cmd:r(sd)}}standard deviation of the difference{p_end}
{synopt:{cmd:r(lb)}}lower limit of agreement{p_end}
{synopt:{cmd:r(ub)}}upper limit of agreement{p_end}
{synopt:{cmd:r(obs)}}number of observations in estimation sample{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Bland, J. M., and D. G. Altman.  1986. Statistical methods for assessing agreement between two methods of clinical measurement. {it:Lancet} I: 307-310.{p_end}

{p 4 8 2}
Bland, J. M. and D. G. Altman. 2007. Agreement between methods of measurement with multiple observations per individual. {it:Journal of Biopharmaceutical Statistics} 
17: 571-582.{p_end}

{p 4 8 2}
Jones, W. S. 2019. Letter to the editor: Arithmetic error in Bland, J. M., & Altman, D. G. 2007. Agreement between methods of measurement with
multiple observations per individual. {it:Journal of Biopharmaceutical Statistics} 29: 574-575.{p_end}



{marker citation}{title:Citation of {cmd:rmloa}}

{p 4 8 2}{cmd:rmloa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2021). RMLOA: Stata module to compute limits of agreement for data with repeated measures.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb concord} (if installed), {helpb batplot} (if installed), {helpb rmcorr} (if installed) {p_end}

