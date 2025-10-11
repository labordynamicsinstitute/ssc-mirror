{smcl}
{* *! version 1.0.0 08Oct2025}{...}
{title:Title}

{p2colset 5 20 21 2}{...}
{p2col:{hi:auto_factor} {hline 2}} automates data and method checks for factor analysis {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:auto_factor}
{varlist} {ifin}
[{it:{help weight}}]
[{cmd:,} 
{opt meth:od(string)} 
{opt comp:are} 
{opt scree:plot} 
[{it:factor_options}] ]



{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt meth:od(string)}}specify the factor method to implement (pf, pcf, ipf, ml); default is to iterate through all methods {p_end}
{synopt :{opt comp:are}}iterate through all methods; same as not specifying {opt method()}{p_end}
{synopt :{opt scree:plot}}produce a screeplot; available only when {opt method()} is specified{p_end}
{synopt :[{it:factor_options}]}specify all available options for {helpb factor} {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s and {cmd:fweight}s are allowed with {cmd:factor}; 
see {help weight}.



{marker description}{...}
{title:Description}

{pstd}
{opt auto_factor} automates all of the steps typically performed as part of a factor analysis, including (1) initial checks of the
data (Kaiser-Meyer-Olkin measure of sampling adequacy, testing that all variables have variance, testing that there are no perfect linear 
dependencies among variables, Bartlett's test of sphericity, and the Doornik-Hansen omnibus test of multivariate normality for the ML method),
(2) determining the number of factors to retain (using Stata's default of all positive eigenvalues, Menger's maximum curvature, and  
screeplot), (3) test for uniqueness of variables, and (4) generating predictions. While {opt auto_factor} is not a replacement for content
expertise, it can assist in determining whether the data are appropriate for factor analysis and which method (or methods) may be most
suitable.


{title:Options}

{p 4 8 2} 
{opt meth:od(string)} specifies which factor method to implement (pf, pcf, ipf, ml). When {opt method()} is not specified, {opt auto_factor} iterates
through all methods and produces a table showing the number of factors determined for each method using Stata's default 
(the count of positive eigenvalues) and Menger's curvature. 

{p 4 8 2} 
{opt comp:are} iterates through all four methods. This is the same as not specifying {opt method()}.

{p 4 8 2} 
{opt scree:plot} produces a screeplot. {opt screeplot} is only available when a specific {opt method()} is specified.

{p 4 8 2} 
{cmd:{it:factor_options}} specify all available options for {helpb factor}. 



{title:Examples}

{pstd}
    Setup
	
        {cmd:. use "https://www.stata-press.com/data/r19/sp2.dta", clear}
		
{pstd}implement {opt auto_factor} for all four methods{p_end}

{phang2}{cmd:. auto_factor ghp31- ghp05}{p_end}

{pstd}implement {opt auto_factor} for a specific method (ipf) and specify the optional screeplot{p_end}

{phang2}{cmd:. auto_factor ghp31- ghp05, meth(ipf) scree}{p_end}




{marker results}{...}
{title:Stored results}

{pstd}
{cmd:auto_factor} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 10 14 2: Matrix}{p_end}
{synopt:{cmd:r(results)}}matrix containing the table results (only when {opt method()} is not specified or when {opt compare} is specified){p_end}
{p2colreset}{...}



{marker citation}{title:Citation of {cmd:auto_factor}}

{p 4 8 2}{cmd:auto_factor} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). AUTO_FACTOR: Stata module to automate data and method checks for factor analysis



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 7 14 2} Help: {helpb factor}, {helpb factor_postestimation}, {helpb menger} (if installed){p_end}


