{smcl}
{* 1.0.2 updated 2024-3-14 / small correction / addition of sigma and }{...}
{* 1.0.1 created 2024-3-01}{...}
{vieweralsosee "[On SSC] isograph" "help isograph"}{...}
{hline}
{hi:help isogini}{...}
{right:L. Chauvel (March 2024)}
{hline}

{title:Title}

{pstd}isogini  {hline 2} Stata module to estimate isogini measures at different percentiles plus sigma and pi (version  1.0.2 ) {p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 13 2}
{cmd:isogini} {varname} {ifin} {weight}
    [{cmd:,} {it:options}]

	
{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opth rep:(numlist)}}		bootstrap repeats; REP(n){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
    {cmd:isogini} produces estimates of isogini inequality measures at percentiles 10 25 50 75 and 90. 
{p_end}	
{pstd}
	Rapid bootstrap n>20 is provided to generate the standard errors of estimates. 
{p_end}	
{pstd}
	See, among many others, Chauvel (2016 & 2024).
{p_end}	
{pstd}
        Many thanks to Philippe Van Kerm for a precise review of the earlier version of this ssc install isogini module. 


{marker options}{...}
{title:Option}

{pstd}Option concerns the number n of bootstrap iterations.{p_end}

{dlgtab:Selection of indices}

{phang}
{opth rep(numlist)} n > 20 the number of iterations; if n <= 20 or no option: no bootstrap is processed (sd=0) .
{p_end}



{title:Example 1: isogini of a Gibrat distribution}

{phang2}{cmd:clear}

{phang2}{cmd:set obs 20000}

{phang2}{cmd:gen income=exp(rnormal())}

{phang2}{cmd:isogini income }

{phang2}{cmd:ret li }

{phang2}{cmd:isogini income , rep(30)}

{phang2}{cmd:ret li }



{title:Example 2: 3 DLL distributions with gini=0.30 but very different poverty rates}
{title:Example 2: see  “dissymmetric log-logit” DLL distribution Chauvel 2023:18  }

{phang2}{cmd:clear}

{phang2}{cmd:set obs 100000}

{phang2}{cmd:gen p=(_n-.5)/_N}

{phang2}{cmd:gen inc1=(p/(1-p))^.3}

{phang2}{cmd:gen inc2=(p^(.20)/(1-p)^(.353))} 

{phang2}{cmd:gen inc3=(p^(.365)/(1-p)^(.265))}

{phang2}{cmd:capt ssc install fastgini }

{phang2}{cmd:isogini inc1, rep(30)}

{phang2}{cmd:ret li }

{phang2}{cmd:fastgini inc1}

{phang2}{cmd:isogini inc2, rep(30)}

{phang2}{cmd:ret li }

{phang2}{cmd:fastgini inc2}

{phang2}{cmd:isogini inc3, rep(30)}

{phang2}{cmd:ret li }

{phang2}{cmd:fastgini inc3}



		
{marker results}{...}
{title:Stored results}

{pstd}{cmd:isogini} stores the following in {cmd:r()}.

{pstd}
The indices and their standard deviations "sd" are saved in scalars.{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ig10)}} => isogini at first decile threshold d1 {p_end}
{synopt:{cmd:r(sdig10)}} => ig10 standard deviation {p_end}
{synopt:{cmd:r(ig50)}} => isogini at the median = p50 percentile threshold {p_end}
{synopt:{cmd:r(sdig50)}} => ig50 standard deviation {p_end}
{synopt:{cmd:r(ig25)}} => etc. {p_end}
{synopt:{cmd:r(sigma)}} => sigma coefficient etc. {p_end}
{synopt:{cmd:r(ssigma)}} => its standard deviation {p_end}
{synopt:{cmd:r(pi)}} => pi coefficient etc. {p_end}
{synopt:{cmd:r(spi)}} => its standard deviation {p_end}


{title:References}

{phang}
    Chauvel, L. (2016), The Intensity and Shape of Inequality: The ABG Method of Distributional Analysis. 
	{it:Review of Income and Wealth}, 62: 52-68. https://doi.org/10.1111/roiw.12161 {browse "https://www.roiw.org/2016/n1/3.pdf"}

{phang}
    Chauvel, L. & E. Bar-Haim (2016), "ISOGRAPH: Stata module to compute inequality over logit ranks of social hierarchy," Statistical Software Components S458255, Boston College Department of Economics, revised 08 Jun 2017.

{phang}
    Chauvel, L. (2023), "Isograph and LaSiPiKa Distribution: The Comparative Morphology of Income Inequalities and Intelligible Parameters of 53 LIS Countries 1967-2020," LIS WP 852.  {browse "https://www.lisdatacenter.org/wps/liswps/852.pdf"}   

{phang}
    Chauvel, L. (2024), Isogini as a set of indicators to compare trends and shapes of income inequality: The fading Swedish middle class society in a world of diverse dynamics.  {browse "https://www.lisdatacenter.org/newsletter"}  

{phang}

	
{title:Author}

{pstd}Louis Chauvel, University of Luxembourg, louis.chauvel@uni.lu


{title:Citation}

{phang}
Chauvel, L. (2024). isogini {c -} Stata module to estimate isogini measures at different percentiles , 
Statistical Software Components S459299, Boston College Department of Economics. Available from 
{browse "http://ideas.repec.org/c/boc/bocode/s459299.html"}.
	

{title:Also see}

{psee}
	User-written command:
    {stata ssc describe isograph:{bf:isograph}}

