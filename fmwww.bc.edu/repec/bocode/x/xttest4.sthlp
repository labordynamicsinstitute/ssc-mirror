{smcl}

help for {hi:xttest4}                            (Version 1.0, 04 Aug 2025)


{title: Kézdi (2003) test for heteroscedasticity in Fixed Effects Model with large N, small T}

{p 8 16 2}    {cmd: xttest4} 

{cmd:xttest4} is a post-estimation command used to test the heteroscedasticity of errors 
after estimating a Fixed Effects model.
Data must be {cmd: xtset} and {cmd: xtbalance2} command ({cmd:ssc install xtbalance2}) are also required.

{title:Description}

{cmd:xttest4} computes three test statistics (h1, h2, h3) for the three null hypotheses 
as described in Kézdi (2003):

{p 4 8 2} H1: Cross-sectional homoskedasticity.

{p 4 8 2} H2: Serially uncorrelated: e_it, x_it or both.

{p 4 8 2} H3: Homoskedasticity and serially uncorrelated.

The alternative hypothesis for all three is:

{p 4 8 2} Ha: Heteroskedasticity.

More specifically:

{p 4 8 2} H1 implies that e_it is cross-sectionally homoskedastic, possibly with time-varying variance and serial autocorrelation. (as described in Kiefer (1980))

{p 4 8 2} H2 implies that e_it, x_it or both are serially uncorrelated, e_it may be heteroskedastic (cross-sectionally and time dimensions). (as described in White (1980))

{p 4 8 2} H3 implies that e_it is the spherical error term, e_it~IID(0, sigma^2).

Kézdi (2003) proposes three test statistics corresponding to both null hypotheses. 
All three are asymptotically (N->infinity, T fixed) chi-squared with [1+K*(K+1)/2] 
degrees of freedom.


{title:Examples}

	{p 4 8 2} . webuse abdata, clear

	{p 4 8 2} . xtreg n k w ys, fe

	{p 4 8 2} . xttest4

	{p 4 8 2} . xtreg n l(0/1).(k w ys) i.year, fe

	{p 4 8 2} . xttest4

	{p 4 8 2} . xtreg n c.(k w ys)##c.(k w ys) i.year, fe

	{p 4 8 2} . xttest4	


{title:References}

{p 4 8 2} Kézdi, G. (2003). Robust standard error estimation in fixed-effects panel models. Available at SSRN 596988.


{title:Authors}

Manh Hoang Ba, Eureka Uni Team, VNM
hbmanh9492@gmail.com


{title:Also see}

Online:  help for {help xttest3} {if installed}, {help xtreg}.

