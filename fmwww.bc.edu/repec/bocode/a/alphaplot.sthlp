{smcl}
{* *! version 1.0.0 16Oct2025}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:alphaplot} {hline 2}} plots Cronbach's alpha for increasing subsets of a variable list {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:alphaplot}
{help varlist}
{ifin}
[{cmd:,} 
{opt for:mat}{cmd:(}{it:{help format:%fmt}}{cmd:)} 
{opt tw:oopts}{cmd:(}{it:{help twoway_options:twoway_options}}{cmd:)}
[{help alpha##options:alpha_options}]
]

{pstd}
{it: varlist} should be comprised of items in a factor, sorted by loading values from high to low 


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth for:mat(%fmt)}}display format for the alpha values on the graph; default is {cmd:format(%6.3f)}{p_end}
{synopt :{opth tw:oopts(twoway_options)}}specify all available options for twoway graphs {p_end}
{synopt :[{it:{help alpha##options:alpha_options}}]}specify all available options for {help alpha} {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
{opt alphaplot} produces a plot of Cronbach's alpha coefficients for increasing subsets of items ({it:k}) in the {it:varlist} ranging from 2 to {it:k}. 
The variables specified in {it:varlist} should represent the items loaded onto a {helpb factor}, ordered by their loading values from high to low. {opt alphaplot}
is a useful tool to visualize the diminishing returns of reliability with an increasing number of items loaded on a factor. However, {opt alphaplot} is not a 
substitute for content expertise, and it is possible that a different subset of items may represent the construct better than that based on sequential loading values alone.



{title:Options}

{p 4 8 2}
{opth format(%fmt)} specifies the format for displaying the alpha values on the plot. The default is {cmd:format(%6.3f)}.

{p 4 8 2} 
{opt tw:oopts}{cmd:(}{it:{help twoway_options:twoway_options}}{cmd:)} specifies all available options for twoway graphs.  

{p 4 8 2} 
[{help alpha##options:alpha_options}] specifies all available options for {help alpha}. 



{title:Examples}

{pstd}Setup

{phang2}{cmd:. use "https://www.stata-press.com/data/r19/sp2.dta", clear}{p_end}
		
{pstd}we perform factor analysis using the maximum likelihood method and limiting the output to 3 factors{p_end}		
{phang2}{cmd:. factor ghp31- ghp05, ml factor(3)}{p_end}

{pstd}we then rotate the factors and suppress output for values < 0.40. We also normalize the values{p_end}		
{phang2}{cmd:. rotate, normal blanks(0.40)}{p_end}

{pstd}we now use {opt alphaplot} to plot the loadings on factor 1 in increasing subsets, starting from 2 up to 9. We specify the loadings
in the {it:varlist} in order from high to low{p_end}		
{phang2}{cmd:. alphaplot pf02 pf04 pf03 pf05 rkind rkeep pf01 pf06 sact0}{p_end}

{pstd}same as above but we now specify that the alpha coefficients be standardized {p_end}		
{phang2}{cmd:. alphaplot pf02 pf04 pf03 pf05 rkind rkeep pf01 pf06 sact0, std}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:alphaplot} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 10 14 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 10 14 2: matrices}{p_end}
{synopt:{cmd:r(results)}}a 2 X {it:k} matrix of results shown on the plot{p_end}
{p2colreset}{...}



{marker citation}{title:Citation of {cmd:alphaplot}}

{p 4 8 2}{cmd:alphaplot} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). ALPHAPLOT: Stata module to plot Cronbach's alpha for increasing subsets of a variable list



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 7 14 2} Help: {helpb factor}, {helpb alpha}, {helpb splithalf} (if installed) {p_end}
