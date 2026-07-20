{smcl}
{* *! version 1.0.4  19jul2026}{...}
{vieweralsosee "[asycaus] main" "help asycaus"}{...}
{vieweralsosee "asycaus dynamic" "help asycaus_dynamic"}{...}
{vieweralsosee "asycaus fourier" "help asycaus_fourier"}{...}
{vieweralsosee "asycaus efficient" "help asycaus_efficient"}{...}
{viewerjumpto "Syntax" "asycaus_static##syn"}{...}
{viewerjumpto "Description" "asycaus_static##desc"}{...}
{viewerjumpto "Options" "asycaus_static##opts"}{...}
{viewerjumpto "Examples" "asycaus_static##ex"}{...}
{viewerjumpto "Stored results" "asycaus_static##sr"}{...}
{viewerjumpto "References" "asycaus_static##ref"}{...}

{title:Title}

{phang}{bf:asycaus static} {hline 2} Hatemi-J (2012) static asymmetric Granger-causality test with leverage bootstrap

{marker syn}{title:Syntax}

{p 8 17 2}
{cmd:asycaus static} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{marker desc}{title:Description}

{pstd}
{cmd:asycaus static} implements the static asymmetric causality test of
{bf:Hatemi-J (2012)}. The series are first decomposed into cumulative sums of
{bf:positive} and {bf:negative} shocks à la {bf:Granger and Yoon (2002)}, then
a VAR is fitted on each set of components with one additional unrestricted lag
for unit roots ({bf:Toda and Yamamoto 1995}). A modified Wald statistic tests
the null that {it:causvar} does not Granger-cause {it:depvar}.{p_end}

{pstd}
Critical values come from the {bf:leverage-adjusted bootstrap}
({bf:Hacker and Hatemi-J 2006, 2012}), which is robust to non-normality and
ARCH effects. The default lag-selection criterion is the {bf:HJC}
({bf:Hatemi-J 2003}), shown via Monte Carlo to recover the true VAR order under
unit roots and structural changes better than AIC or SBC.{p_end}

{marker opts}{title:Options}

{synoptset 22 tabbed}{...}
{synopthdr:option}
{synoptline}
{synopt :{opt maxl:ag(#)}}maximum VAR lag (default 8){p_end}
{synopt :{opt ic(string)}}{bf:aic} | {bf:aicc} | {bf:sbc} | {bf:hqc} | {bf:hjc} (default){p_end}
{synopt :{opt into:rder(#)}}TY augmentation lags (default 1){p_end}
{synopt :{opt shock(string)}}{bf:pos} | {bf:neg} | {bf:both} (default {bf:pos}){p_end}
{synopt :{opt tr:end(string)}}component transform: {bf:none} (default) | {bf:drift} | {bf:both}; {bf:drift}/{bf:both} use the deterministic-trend transformation of {bf:Hatemi-J and El-Khatib (2016)}{p_end}
{synopt :{opt boot(#)}}bootstrap replications (default 1000){p_end}
{synopt :{opt seed(#)}}RNG seed (default 12345){p_end}
{synopt :{opt ln:form}}take ln of inputs before decomposition{p_end}
{synopt :{opt nograph}}suppress the graph{p_end}
{synopt :{opt sav:ing(name)}}save graph to {it:name}.gph{p_end}
{synoptline}

{marker ex}{title:Examples}

{phang}{stata "webuse lutkepohl2, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "asycaus static dln_inv dln_inc, maxlag(4) ic(hjc) boot(500) shock(both)"}{p_end}

{marker sr}{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt :{cmd:r(results)}}rows = chosen shocks, cols = (Wald, lag, dof, CV10, CV5, CV1){p_end}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt :{cmd:r(boot)} {cmd:r(maxlag)}}options used{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt :{cmd:r(test)} {cmd:r(depvar)} {cmd:r(cause)} {cmd:r(shock)} {cmd:r(ic)}}metadata{p_end}

{marker ref}{title:References}

{phang}Hatemi-J, A. (2012). Asymmetric causality tests with an application. {it:Empirical Economics}, 43, 447–456.{p_end}
{phang}Hacker, R. S., and Hatemi-J, A. (2006). Tests for causality between integrated variables using asymptotic and bootstrap distributions. {it:Applied Economics}, 38(13), 1489–1500.{p_end}
{phang}Hatemi-J, A. (2003). A new method to choose optimal lag order in stable and unstable VAR models. {it:Applied Economics Letters}, 10(3), 135–137.{p_end}

{title:Author}
{pstd}{bf:Dr Merwan Roudane} {hline 2} {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}See {help asycaus:asycaus} for the package overview.{p_end}
