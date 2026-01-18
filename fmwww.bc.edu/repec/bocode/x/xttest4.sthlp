{smcl}

help for {hi:xttest4}                            (Version 1.4, 17 Jan 2026)


{title: Test for heteroscedasticity in fixed-T panel data models}

{p 8 16 2}    {cmd: xttest4} [{cmd:,} {cmd:kezdi}] 

{p 4 8 2}{cmd:xttest4} is a post-estimation command used to test the heteroscedasticity of errors after estimating a fixed-effects or random-effects model.

{title:Description}

{p 4 8 2}{cmd:xttest4} calculates LM statistics based on artificial regression designed to test the homokedasticity assumption for errors of fixed-effects models (Juhl & Sosa-Escudero, 2014) and composite errors of random-effects models (Montes-Rojas & Sosa-Escudero, 2011).

{p 4 8 2}In fixed-effects models, when option {cmd:kezdi} is specified, {cmd:xttest4} computes three test statistics (h1, h2, h3) for the three null hypotheses as described in Kezdi (2003):

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

{pstd}To update the {cmd:xttest4} package to the latest version, run either of the following commands{p_end}
{phang2}. {stata `"ssc install xttest4, replace"'}{p_end}
{phang2}. {stata `"net install xttest4, from("https://raw.githubusercontent.com/ManhHB94/xttest4/main/") replace"'}{p_end}


{title:Citation}
{p 4 8 2}{cmd:xttest4} is not an official Stata command.
It is a free contribution to the research community.
Please cite it as such: {p_end}
{p 8 8 2}Manh Hoang-Ba, 2025. "XTTEST4: Stata module to calculate heterokedasticity tests for fixed effects models," Statistical Software Components S459492, Boston College Department of Economics, revised 15 Aug 2025.{p_end}


{title:Examples}

{phang2} {stata . webuse abdata, clear}{p_end}

{phang2} {stata `". xtreg n k w ys if id <=100, fe"'}{p_end}

{phang2} {stata `". xttest4"'}{p_end}

{phang2} {stata `". xtreg n l(0/1).(k w ys) i.year, fe"'}{p_end}

{phang2} {stata `". xttest4, kezdi"'}{p_end}

{phang2} {stata `". xtreg n c.(k w ys)##c.(k w ys) i.year, re"'}{p_end}

{phang2} {stata `". xttest4"'}{p_end}


{title:References}

{p 4 8 2}Juhl, T., & Sosa-Escudero, W. (2014). Testing for heteroskedasticity in fixed effects models. {it:Journal of econometrics}, 178, 484-494.

{p 4 8 2}Kezdi, G. (2003). Robust standard error estimation in fixed-effects panel models. Available at SSRN 596988.

{p 4 8 2}Montes-Rojas, G., & Sosa-Escudero, W. (2011). Robust tests for heteroskedasticity in the one-way error components model. {it:Journal of Econometrics}, 160(2), 300-310.



{title:Authors}

	Manh Hoang-Ba, Eureka Uni Team, VNM
	hbmanh9492@gmail.com


{title:Also see}

Online:  help for {help xttest3} {if installed}, {help xtgls2} {if installed}, {help xtreg}.

