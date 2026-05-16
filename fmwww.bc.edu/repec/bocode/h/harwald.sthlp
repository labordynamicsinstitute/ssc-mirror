{smcl}
{* *! version 1.0.0 15may2026}{...}
{vieweralsosee "harreg" "help harreg"}{...}
{vieweralsosee "[R] test" "help test"}{...}
{vieweralsosee "[R] regress postestimation" "help regress postestimation"}{...}
{viewerjumpto "Syntax" "harwald##syntax"}{...}
{viewerjumpto "Description" "harwald##description"}{...}
{viewerjumpto "Options" "harwald##options"}{...}
{viewerjumpto "Examples" "harwald##examples"}{...}
{viewerjumpto "Stored results" "harwald##results"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:harwald} {hline 2}}Wald test with fixed-b critical values after harreg{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Test coefficients equal zero:

{p 8 17 2}
{cmd:harwald} [{it:coeflist}]
[{cmd:,} {it:options}]

{pstd}
Test linear hypotheses:

{p 8 17 2}
{cmd:harwald} {cmd:(}{it:exp}{cmd:)} [{cmd:(}{it:exp}{cmd:)} ...]
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt critdraws(#)}}Monte Carlo draws; default is 5000{p_end}
{synopt:{opt seed(#)}}random-number seed for simulations{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:harwald} can be used only after {helpb harreg}.{p_end}

{p 4 6 2}
{it:exp} is a linear expression of coefficients such as {cmd:x1 + x2},
{cmd:2*x1 - x2}, or {cmd:x1 + x2 - 1} (to test whether the sum equals 1).
Each term is a coefficient name, optionally preceded by a numeric constant
and {cmd:*}; terms are combined with {cmd:+} or {cmd:-}.
An expression may also use {cmd:=} to separate the left- and right-hand
sides of a restriction, e.g. {cmd:2*x1 - x2 = 1} (equivalent to
{cmd:2*x1 - x2 - 1}); each parenthesized expression may contain at most
one {cmd:=}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:harwald} performs a Wald test using the fixed-{it:b} reference distribution
that matches the estimator from the preceding {cmd:harreg} command.

{pstd}
When {it:coeflist} is specified (without parentheses), {cmd:harwald} tests the
joint hypothesis that all listed coefficients equal zero.
Equality syntax such as {cmd:harwald x1 = x2} is not accepted in this mode;
each restriction must be wrapped in parentheses (see below).
If {it:coeflist} is not specified, all estimated slope coefficients
in the model are tested (the constant and any factor-variable base or
omitted columns are excluded).

{pstd}
When parenthesized expressions are specified, {cmd:harwald} tests linear
hypotheses of the form {it:exp} = 0. Multiple expressions can be tested
jointly by specifying multiple parenthesized expressions. This is similar
to the functionality of {helpb test} after {helpb regress}.

{pstd}
For {cmd:ewc} and {cmd:ewp} estimators, the test uses an
F({it:q}, {it:nu}-{it:q}+1) distribution,
where {it:q} is the number of tested coefficients and
{it:nu} is the degrees of freedom from {cmd:e(df_fb)}.

{pstd}
For {cmd:nw} and {cmd:qs} estimators, {cmd:harwald} simulates the
fixed-{it:b} null distribution to obtain the p-value and critical value.

{marker options}{...}
{title:Options}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for the
critical value. The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt critdraws(#)} specifies the number of Monte Carlo draws used
to simulate the fixed-{it:b} critical value when the estimator is
{cmd:nw} or {cmd:qs}. The default is 5000; the minimum is 1000.

{phang}
{opt seed(#)} specifies the random-number seed for simulations.
The default ensures reproducible critical values across runs.
Specify {cmd:seed(0)} to use a different random seed each time.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset}{p_end}
{phang2}{cmd:. harreg dln_inv dln_inc dln_consump}{p_end}

{pstd}Joint test of all slope coefficients{p_end}
{phang2}{cmd:. harwald}{p_end}

{pstd}Test specific coefficients{p_end}
{phang2}{cmd:. harwald dln_inc dln_consump}{p_end}

{pstd}Test at 90% confidence level{p_end}
{phang2}{cmd:. harwald dln_inc, level(90)}{p_end}

{pstd}Test a linear combination (sum of coefficients equals zero){p_end}
{phang2}{cmd:. harwald (dln_inc + dln_consump)}{p_end}

{pstd}Test equality of coefficients (difference equals zero){p_end}
{phang2}{cmd:. harwald (dln_inc - dln_consump)}{p_end}

{pstd}Test with explicit coefficient weights{p_end}
{phang2}{cmd:. harwald (2*dln_inc - dln_consump)}{p_end}

{pstd}Test whether sum of coefficients equals 1{p_end}
{phang2}{cmd:. harwald (dln_inc + dln_consump - 1)}{p_end}

{pstd}Test using {cmd:=} syntax (equivalent restriction){p_end}
{phang2}{cmd:. harwald (dln_inc + dln_consump = 1)}{p_end}

{pstd}Joint test of multiple linear hypotheses{p_end}
{phang2}{cmd:. harwald (dln_inc + dln_consump) (dln_inc - dln_consump)}{p_end}

{pstd}Test after NW estimation with more Monte Carlo draws{p_end}
{phang2}{cmd:. harreg dln_inv dln_inc dln_consump, estimator(nw) lags(8)}{p_end}
{phang2}{cmd:. harwald dln_inc, critdraws(10000)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:harwald} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(F)}}Wald F statistic{p_end}
{synopt:{cmd:r(q)}}number of constraints (coefficients or linear hypotheses) tested{p_end}
{synopt:{cmd:r(df)}}alias of {cmd:r(q)} (for {cmd:test}-style script compatibility){p_end}
{synopt:{cmd:r(df_r)}}denominator df shown in the printed header{p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{synopt:{cmd:r(cv)}}critical value at specified level{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}
Eben Lazarus, UC Berkeley{break}
lazarus@berkeley.edu
{p_end}

{pstd}
Daniel J. Lewis, University College London{break}
daniel.j.lewis@ucl.ac.uk
{p_end}
