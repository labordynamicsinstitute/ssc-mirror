{smcl}
{* *! version 1.0.1  19may2019}{...}
{* *! first version  17april2019}{...}
{* *! changelog}{...}
{* *! version 1.0.1  added author affiliations and description of cluster robust inference (May 19, 2019)}{...}
{cmd:help ivmediate}{right: ({browse "https://doi.org/10.1177/1536867X211000033":SJ21-1: st0611_1})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:ivmediate} {hline 2}}Causal mediation analysis for linear
instrumental-variables models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab:ivmediate} {depvar} [{indepvars}] {ifin}{cmd:,} 
{cmdab:med:iator}{cmd:(}{it:{help varname}}{cmd:)} 
{cmdab:treat:ment}{cmd:(}{it:{help varname}}{cmd:)}
{cmdab:inst:rument}{cmd:(}{it:{help varname}}{cmd:)}
[{it:options}]


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt med:iator(varname)}}include a single mediator
variable{p_end}
{p2coldent:* {opt treat:ment(varname)}}include a single treatment
variable{p_end}
{p2coldent:* {opt inst:rument(varname)}}include a single instrumental
variable (IV){p_end}
{synopt: {opt a:bsorb(varname)}}categorical variable to be absorbed{p_end}
{synopt: {opt f:ull}{cmd:}}display the full output including intermediate
regression results{p_end}
{synopt: {cmd:vce(}{it:{help vcetype}}{cmd:)}}may be {opt r:obust} or {opt cl:uster} {it:clustvar}; default is {cmd:vce(unadjusted)} standard errors{p_end}
{synopt :{opt l:evel(#)}}set level for confidence intervals; default is {cmd:level(95)}{p_end}
{synoptline}
{pstd}
* {cmd:mediator(}{it:varname}{cmd:)},
{cmdab:treatment(}{it:varname}{cmd:)}, and
{cmdab:instrument(}{it:varname}{cmd:)} are required.{p_end}
{pstd}
{it:indepvars} may contain factor variables; {help fvvarlist}.{p_end}
{pstd}
{it:indepvars} may contain time-series operators; see {help tsvarlist}.


{title:Description}

{pstd}
{cmdab:ivmediate} implements the causal mediation analysis framework for
linear IV models introduced by Dippel et al. (2019).  It estimates three
effects: 

{p 10 13 2}
i) the total effect of a single treatment T on an outcome Y, where T is
instrumented with a single IV Z, that is, a variable that affects Y only
through T,{p_end}

{p 9 13 2}
ii) the direct effect of T on Y net of the effect of a mediator variable
M, and{p_end}

{p 8 13 2}
iii) the indirect effect (mediation effect) of a third variable M through
which T affects Y.{p_end}

{pstd}
The command allows for unpacking the treatment effect from a standard IV
regression into the direct and indirect effects of (potentially) endogenous
treatment and mediator variables without the need for an additional instrument
for the mediator variable.  This compares with frameworks that require an
instrument for the mediator (Fr{c o:}lich and Huber 2017; Jun et al. 2016) or
those where random assignment of the treatment is assumed (Imai, Keele, and
Tingley 2010).

{pstd}
Results report two first-stage F statistics.  These test for the relevance of
the instrument in the regression of the treatment on the instrument (T on Z)
-- that is, the standard first stage from a two-stage least squares regression
-- and in a regression of the mediator on the instrument controlling for the
treatment (M on Z|T), which is used in the estimation of the indirect effect
(for details, see Dippel et al. [2019]).  If {opt robust} or {opt cluster} is
specified, the Kleibergen and Paap (2006) F statistic is reported.  For a
discussion, see {helpb ivreg2##s_relevance:ivreg2}.

{pstd}
Notice that exogenous controls in {indepvars} are partialled out using the
Frisch-Waugh-Lovell theorem to speed up estimation.  Hence, they are not
reported in either the intermediate or final results tables.

{pstd}
Note: The {cmd:ranktest} command has to be installed by typing 
{cmd:ssc install ranktest} prior to running {cmd:ivmediate}.


{title:Options}

{phang} 
{opth mediator(varname)} includes a single mediator variable.
{cmd:mediator()} is required.

{phang} 
{opt treatment(varname)} includes a single treatment variable.
{cmd:treatment()} is required.

{phang} 
{opt instrument(varname)} includes a single IV.  {cmd:instrument()} is
required.

{phang}
{opt absorb(varname)} allows the absorption of one fixed effect.  For details,
see {helpb areg}.

{phang}
{opt full} displays intermediate results together with the main results.
Specifying this option will display three intermediate output tables:

{phang2}
1.  the IV regression of Y on T (instrumented with Z){p_end}

{phang2}
2.  the IV regression of M on T (instrumented with Z), for which the
first-stage F statistic is reported as {cmd:first stage one} in the main
table{p_end}

{phang2}
3.  the IV regression of Y on M (instrumented with Z) and controlling for T,
for which the first-stage F statistic is reported as {cmd:first stage two} in
the main table{p_end}

{pmore}
The total effect is the coefficient on T in the first table; the direct effect
is the coefficient on T in the third table; the indirect effect is the product
of the coefficient on T in the second table and the coefficient on M in the
third.  The mediation effect as percentage of the total effect is therefore
the indirect effect divided by the total effect times 100.{p_end}

{phang}
{opt vce(vcetype)} may be {cmd:robust} to estimate Eicker/Huber/White standard
errors or may be {cmd:cluster} {it:clustervar} to estimate cluster-robust
standard errors.  The default is {cmd:vce(unadjusted)} standard errors.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  Integers between 10 and 99 inclusive are allowed.  The default is
{cmd:level(95)} or as set by {helpb set level}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}

{pstd}IV mediation analysis{p_end}
{phang2}{cmd:. ivmediate price, mediator(trunk) treatment(foreign) instrument(turn)}{p_end}

{pstd}IV mediation analysis with display of intermediate results{p_end}
{phang2}{cmd:. ivmediate price, mediator(trunk) treatment(foreign) instrument(turn) full}{p_end}

{pstd}IV mediation analysis with controls and clustered standard errors{p_end}
{phang2}{cmd:. ivmediate price mpg weight, mediator(trunk) treatment(foreign) instrument(turn) vce(cluster rep78)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ivmediate} stores the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(fstat1)}}F statistic for the excluded instruments in {cmd:first stage one} (T on Z){p_end}
{synopt:{cmd:e(fstat2)}}F statistic for the excluded instruments in {cmd:first stage two} (M on Z|T){p_end}
{synopt:{cmd:e(mepct)}}mediation effect expressed as percentage of the total effect{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters used to adjust standard errors if {cmd:cluster} was specified in {cmd:vce()}{p_end}

{synoptset 15 tabbed}{...}
{syntab:Macros}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(treat)}}name of the treatment variable{p_end}
{synopt:{cmd:e(med)}}name of the mediator variable{p_end}
{synopt:{cmd:e(inst)}}name of the IV{p_end}
{synopt:{cmd:e(vcetype)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(clustvar)}}name of the cluster variable if {cmd:cluster} was specified in {cmd:vce()}{p_end}

{synoptset 15 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}


{marker references}{...}
{title:References}

{phang}
Dippel, C., R. Gold, S. Heblich, and R. Pinto. 2019. Mediation analysis in IV
settings with a single instrument.
{browse "https://www.anderson.ucla.edu/faculty_pages/christian.dippel/IVmediate.pdf"}.

{phang}
Fr{c o:}lich, M.,  and M. Huber. 2017. Direct and indirect treatment
effects -- causal chains and mediation analysis with instrumental variables.
{it:Journal of the Royal Statistical Society, Series B} 79: 1645-1666.
{browse "https://doi.org/10.1111/rssb.12232"}.

{phang}
Imai, K., L. Keele, and D. Tingley. 2010. A general approach to causal
mediation analysis. {it:Psychological Methods} 15: 309-334.
{browse "https://doi.org/10.1037/a0020761"}.

{phang}
Jun, S. J., J. Pinkse, H. Xu, and N. Yildiz. 2016.  Multiple discrete
endogenous variables in weakly-separable triangular models.
{it:Econometrics} 4: 7.
{browse "https://doi.org/10.3390/econometrics4010007"}.

{phang}
Kleibergen, F., and R. Paap. 2006. Generalized reduced rank tests using the
singular value decomposition. {it:Journal of Econometrics} 133: 97-126.
{browse "https://doi.org/10.1016/j.jeconom.2005.02.011"}.


{marker authors}{...}
{title:Authors}

{pstd}
Christian Dippel{break}
UCLA Anderson School of Management{break}
Los Angeles, CA{break}
christian.dippel@anderson.ucla.edu

{pstd}
Andreas Ferrara{break}
University of Pittsburgh{break}
Pittsburgh, PA{break}
a.ferrara@pitt.edu

{pstd}
Stephan Heblich{break}
University of Toronto{break}
Toronto, Canada{break}
stephan.heblich@utoronto.ca


{marker also}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 21, number 1: {browse "https://doi.org/10.1177/1536867X211000033":st0611_1},{break}
          {it:Stata Journal}, volume 20, number 3: {browse "https://doi.org/10.1177/1536867X20953572":st0611}{p_end}

{p 7 14 2}
Help:  {manhelp gmm R}, {helpb ranktest} (if installed){p_end}
