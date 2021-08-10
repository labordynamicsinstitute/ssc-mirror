{smcl}
{* *! version 1.0.0  07sep2013}{...}
{hline}
help for {hi: ivrobust}
{hline}

{title:Weak instrument test for TSLS and LIML with heteroskedasticity, serial correlation, and clustering}

{title:Syntax}

{p 8 14 2} {cmdab:ivrobust} {it:depvar} [{it:indepvars}] {cmd:(}{it:endogvar}{cmd:=}{it:varlist_iv}{cmd:)}
{ifin} [{cmd:,} {it:options}]

{p 8 14 2} {cmd:by}, and {cmd:xi} are allowed; see {help prefix}.

{title:Description}

{p 4 4 2}{cmd:ivrobust} implements the weak instrument test of Montiel Olea and Pflueger (2013) that is robust to heteroskedasticity, serial correlation, and clustering. {cmd:ivrobust} tests the null hypothesis of weak instruments for both Two-Stage Least Squares (TSLS) and Limited Information Maximum Likelihood (LIML) with one single endogenous regressor. The test rejects the null hypothesis when the effective F statistic exceeds a critical value, which depends on the estimator (TSLS or LIML), the significance level, and the desired weak instrument threshold tau.{cmd: ivrobust} extends the Stock and Yogo (2005) weak instrument tests available in {cmd:ivreg2} and in the {cmd: ivregress} postestimation command {cmd:estat firststage}.

{p 4 4 2}{cmd:ivrobust} tests for weak instruments in a linear regression of {it:depvar} onto {it:indepvars} and {it:endogvar} using {it:varlist_iv} and {it:indepvars} as instruments for {it:endogvar}. By default, {it:indepvars} includes a constant term.

{title:Options}

{p 4 4 2}{cmdab:cl:uster}{cmd:(}{it:varname}{cmd:)} estimates a variance-covariance matrix clustered by {it:varname}.

{p 4 4 2}{cmd:bw(}{it:#}{cmd:)} estimates a heteroskedasticity and autocorrelation-consistent variance-covariance matrix computed with a Bartlett (Newey-West) kernel with {it:#} lags.

{p 4 4 2}{cmd:level(}{it:#}{cmd:)} specifies the confidence level. The default is {cmd:level(0.05)} and alternative permitted options are {cmd:level(0.01)}, and  {cmd:level(0.10)}.

{p 4 4 2}{cmd:eps(}{it:#}{cmd:)} specifies the input parameter for the Nelder-Mead optimization technique; default is {cmd:eps(1e-3)}.

{marker s_examples}{title:Examples}

{pstd}Setup: Use Klein data{p_end}
{phang2}{stata "webuse klein" : . webuse klein, clear}{p_end}

{phang2}{stata "tsset yr" : . tsset yr}{p_end}

{pstd}Test for weak instruments requesting a Newey-West kernel with six lags{p_end}
{phang2}{stata "ivrobust consump l.profits ( wagetot = govt taxnetx year wagegovt capital1 totinc1), bw(6)" : . ivrobust consump profits1 (wagetot = govt taxnetx year wagegovt capital1 totinc1), bw(6)}{p_end}

{title:Saved results}

{p 4 4 2}{cmd:ivrobust} saves the following results in {cmd:r()}:

{p 4 4 2}Macros{p_end}
{col 4} {cmd:r(N)}{col 25} Number of Observations
{col 4} {cmd:r(K)} {col 25} Number of Instruments 
{col 4} {cmd:r(level)} {col 25} Test Significance Level
{col 4} {cmd:r(eps)} {col 25} Optimization Parameter
{col 4} {cmd:r(F_eff)} {col 25} Effective F Statistic
 
{col 4} {cmd:r(c_TSLS_5)} {col 25} TSLS Critical Value for tau{it:=}5{it:%}
{col 4} {cmd:r(c_TSLS_10)} {col 25} TSLS Critical Value for tau{it:=}10{it:%}
{col 4} {cmd:r(c_TSLS_20)} {col 25} TSLS Critical Value for tau{it:=}20{it:%}
{col 4} {cmd:r(c_TSLS_30)} {col 25} TSLS Critical Value for tau{it:=}30{it:%}

{col 4} {cmd:r(c_LIML_5)} {col 25} LIML Critical Value for tau{it:=}5{it:%}
{col 4} {cmd:r(c_LIML_10)} {col 25} LIML Critical Value for tau{it:=}10{it:%}
{col 4} {cmd:r(c_LIML_20)} {col 25} LIML Critical Value for tau{it:=}20{it:%}
{col 4} {cmd:r(c_LIML_30)} {col 25} LIML Critical Value for tau{it:=}30{it:%}

{col 4} {cmd:r(c_simp_5)} {col 25} TSLS Simplified Conservative Critical Value for tau{it:=}5{it:%}
{col 4} {cmd:r(c_simp_10)} {col 25} TSLS Simplified Conservative Critical Value for tau{it:=}10{it:%}
{col 4} {cmd:r(c_simp_20)} {col 25} TSLS Simplified Conservative Critical Value for tau{it:=}20{it:%}
{col 4} {cmd:r(c_simp_30)} {col 25} TSLS Simplified Conservative Critical Value for tau{it:=}30{it:%}

{col 4} {cmd:r(x_TSLS_5)} {col 25} TSLS Non-Centrality Parameter for tau{it:=}5{it:%}
{col 4} {cmd:r(x_TSLS_10)} {col 25} TSLS Non-Centrality Parameter for tau{it:=}10{it:%}
{col 4} {cmd:r(x_TSLS_20)} {col 25} TSLS Non-Centrality Parameter for tau{it:=}20{it:%}
{col 4} {cmd:r(x_TSLS_30)} {col 25} TSLS Non-Centrality Parameter for tau{it:=}30{it:%}

{col 4} {cmd:r(K_eff_TSLS_5)} {col 25} TSLS Effective Degrees of Freedom for tau{it:=}5{it:%}
{col 4} {cmd:r(K_eff_TSLS_10)} {col 25} TSLS Effective Degrees of Freedom for tau{it:=}10{it:%}
{col 4} {cmd:r(K_eff_TSLS_20)} {col 25} TSLS Effective Degrees of Freedom for tau{it:=}20{it:%}
{col 4} {cmd:r(K_eff_TSLS_30)} {col 25} TSLS Effective Degrees of Freedom for tau{it:=}30{it:%}

{col 4} {cmd:r(x_LIML_5)} {col 25} LIML Non-Centrality Parameter for tau{it:=}5{it:%}
{col 4} {cmd:r(x_LIML_10)} {col 25} LIML Non-Centrality Parameter for tau{it:=}10{it:%}
{col 4} {cmd:r(x_LIML_20)} {col 25} LIML Non-Centrality Parameter for tau{it:=}20{it:%}
{col 4} {cmd:r(x_LIML_30)} {col 25} LIML Non-Centrality Parameter for tau{it:=}30{it:%}

{col 4} {cmd:r(K_eff_LIML_5)} {col 25} LIML Effective Degrees of Freedom for tau{it:=}5{it:%}
{col 4} {cmd:r(K_eff_LIML_10)} {col 25} LIML Effective Degrees of Freedom for tau{it:=}10{it:%}
{col 4} {cmd:r(K_eff_LIML_20)} {col 25} LIML Effective Degrees of Freedom for tau{it:=}20{it:%}
{col 4} {cmd:r(K_eff_LIML_30)} {col 25} LIML Effective Degrees of Freedom for tau{it:=}30{it:%}

{col 4} {cmd:r(x_simp_5)} {col 25} TSLS Simplified Non-Centrality Parameter for tau{it:=}5{it:%}
{col 4} {cmd:r(x_simp_10)} {col 25} TSLS Simplified Non-Centrality Parameter for tau{it:=}10{it:%}
{col 4} {cmd:r(x_simp_20)} {col 25} TSLS Simplified Non-Centrality Parameter for tau{it:=}20{it:%}
{col 4} {cmd:r(x_simp_30)} {col 25} TSLS Simplified Non-Centrality Parameter for tau{it:=}30{it:%}

{col 4} {cmd:r(K_eff_simp_5)} {col 25} TSLS Simplified Effective Degrees of Freedom for tau{it:=}5{it:%}
{col 4} {cmd:r(K_eff_simp_10)} {col 25} TSLS Simplified Effective Degrees of Freedom for tau{it:=}10{it:%}
{col 4} {cmd:r(K_eff_simp_20)} {col 25} TSLS Simplified Effective Degrees of Freedom for tau{it:=}20{it:%}
{col 4} {cmd:r(K_eff_simp_30)} {col 25} TSLS Simplified Effective Degrees of Freedom for tau{it:=}30{it:%}

{marker references}{...}
{title:References}

{marker Baum2007}{...}
{phang}
Baum, C. F., M. E. Schaffer, and S. Stillman. 2007. Enhanced routines for instrumental variables/generalized method of moments and testing. {it:Stata Journal} 7:465-506.

{marker Baum2010}{...}
{phang}
Baum, C. F., M. E. Schaffer, and S. Stillman. 2010.  IVREG2: Stata module for extended instrumental variables/2SLS and GMM estimation. {browse "http://ideas.repec.org/c/boc/bocode/s425401.html"}.

{marker C2003}{...}
{phang}
Campbell, J. Y. 2003. Consumption-based asset pricing. {it:Handbook of the Economics of Finance, Vol. 1} 803-887.

{marker Mikusheva}{...}
{phang}
Mikusheva, A. and B. P. Poi. 2006. Tests and confidence sets with correct size when instruments are potentially weak. {it:Stata Journal} 6:335-347.

{marker MOP2013}{...}
{phang}
Montiel Olea, J. L. and C. E. Pflueger. 2013. A robust test for weak instruments. {it:Journal of Business and Economic Statistics} 31:358-369.

{marker MOPW2013}{...}
{phang}
Montiel Olea, J. L., C. E. Pflueger, and Su Wang. 2013. A robust test for weak instruments in Stata. {browse "http://papers.ssrn.com/sol3/papers.cfm?abstract_id=2323012"}.

{marker NW1987}{...}
{phang}
Newey, W. and K. D. West. 1987. A simple, positive semi-definite, heteroskedasticity and
autocorrelation consistent covariance matrix. {it:Econometrica} 55:703-708.

{marker StockYogo2005}{...}
{phang}
Stock, J. and M. Yogo. 2005. Testing for weak instruments in linear IV regression. {it: In Identification and Inference for Econometric Models: Essays in Honor of Thomas Rothenberg} Chapter 5 80-108.

{marker Yogo2004}{...}
{phang}
Yogo, M. 2004. Estimating the elasticity of intertemporal substitution when instruments
are weak. {it:Review of Economics and Statistics} 86:797-810.
{p_end}

{marker authors}{...}
{title:Authors}

	Jose Luis Montiel Olea, New York University, New York NY 10012, USA
	montiel.olea@nyu.edu

	Carolin E. Pflueger, University of British Columbia, Vancouver BC V6T 1Z2, Canada
	carolin.pflueger@sauder.ubc.ca

	Su Wang, London School of Economics, London WC2A 2AE, United Kingdom
	s.wang50@lse.ac.uk.

{marker also}{...}
{title:Also see}

{p 4 4 2}{help ivregress}, {help ivreg}, 
{help ivregress_postestimation}, {help ivreg2} (if installed); {help condivreg} (if installed)
{p_end}