{smcl}

help for {hi:xttest4}                            (Version 1.3, 19 Nov 2025)


{title: Kezdi (2003) test for heteroscedasticity in Fixed Effects models with large N, small T}

{p 8 16 2}    {cmd: xttest4} 

{p 4 8 2}{cmd:xttest4} is a post-estimation command used to test the heteroscedasticity of errors after estimating a Fixed-effects model. Data must be {help xtset}.

{title:Description}

{p 4 8 2}{cmd:xttest4} computes three test statistics (h1, h2, h3) for the three null hypotheses as described in Kezdi (2003):

{p 8 8 2} H1: Cross-sectional homoskedasticity.

{p 8 8 2} H2: Serially uncorrelated: e_it, x_it or both.

{p 8 8 2} H3: Homoskedasticity and serially uncorrelated.

{p 4 8 2}The alternative hypothesis for all three is:

{p 8 8 2} Ha: Heteroskedasticity.

{p 4 8 2}More specifically:

{p 8 8 2} H1 implies that e_it is cross-sectionally homoskedastic, possibly with time-varying variance and serial autocorrelation.

{p 8 8 2} H2 implies that e_it, x_it or both are serially uncorrelated, e_it may be heteroskedastic (cross-sectionally and time dimensions).

{p 8 8 2} H3 implies that e_it is homoskedastic (cross-sectionally and time dimensions) and e_it, x_it or both are serially uncorrelated.

{p 4 8 2}Kezdi (2003) proposes three test statistics corresponding to both null hypotheses. All three are asymptotically (N->infinity, T fixed) chi-squared with [1+K*(K+1)/2] degrees of freedom.

{p 4 8 2}The latest version of {cmd:xttest4} can be found at the following link: {browse "https://github.com/ManhHB94/":https://github.com/ManhHB94/}{p_end}


{title:Citation}
{p 4 8 2}{cmd:xttest4} is not an official Stata command.
It is a free contribution to the research community.
Please cite it as such: {p_end}
{p 8 8 2}Manh Hoang Ba, 2025. "XTTEST4: Stata module to calculate heterokedasticity tests for fixed effects models," Statistical Software Components S459492, Boston College Department of Economics, revised 15 Aug 2025.{p_end}


{title:Examples}

	. webuse abdata, clear

	. xtreg n k w ys if id <=100, fe

	. xttest4

	. xtreg n l(0/1).(k w ys) i.year, fe

	. xttest4

	. xtreg n c.(k w ys)##c.(k w ys) i.year, fe

	. xttest4	


{title:References}

{p 4 8 2} Kezdi, G. (2003). Robust standard error estimation in fixed-effects panel models. Available at SSRN 596988.


{title:Authors}

	Manh Hoang Ba, Eureka Uni Team, VNM
	hbmanh9492@gmail.com


{title:Also see}

Online:  help for {help xttest3} {if installed}, {help xtgls2} {if installed}, {help xtreg}.

