{smcl}
{* *! version 1.0.1  31jan2022}{...}
{vieweralsosee "[TS] arima" "mansection TS arima"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] arima postestimation" "help arima postestimation"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "lppinv##syntax"}{...}
{viewerjumpto "Description" "lppinv##description"}{...}
{viewerjumpto "Methods and formulas" "lppinv##methods"}{...}
{viewerjumpto "Examples" "lppinv##examples"}{...}
{viewerjumpto "Remarks" "lppinv##remarks"}{...}
{viewerjumpto "References" "lppinv##references"}{...}
{p2colset 1 15 17 2}{...}

{title:Title}
{phang}
{bf:lppinv} {hline 2} solve an under-, over- and identified linear problem
without an objective function (a "hybrid" LP-LS problem) with the help of
the Moore-Penrose pseudoinverse and singular value decomposition (SVD) and
test the normalized RMSE

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:lppinv}
{help varlist|matname:{it:varlist|matname}}
{ifin}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:"Hybrid" LS-LP problem type}
{synopt:{opt cols}}non-typical constrained OLS ({bf:cOLS})
        (see {help lppinv##description:Description})
        {p_end}
{synopt:{opt tm}}Transaction Matrix ({bf:TM}), options {opt cols} and {opt tm}
        are mutually exclusive (not specifying any of them equals {bf:custom})
        {p_end}

{syntab:Constructing the LHS}
{synopt:{opth m:odel(varlist|matname)}}the MODEL part of {bf:`a'}
        (see {help lppinv##methods:Methods and formulas})
        {p_end}
{synopt:{opth c:onstraints(varlist|matname)}}the CONSTRAINTS part of {bf:`a'}
        {p_end}
{synopt:{opth s:lackvars(varlist|matname)}}the SLACK VARIABLES part of {bf:`a'}
        {p_end}
{synopt:{opt zerod:iagonal}}set all the diagonal elements of {bf:`a'} to 0
        {p_end}

{syntab:SVD-based estimation}
{synopt:{opth tol:erance(real)}}{helpb [M-1] tolerance:roundoff error},
        a number to determine when a number is small enough to be considered
        zero (optional, not specifying {it:tol} is equivalent to specifying
        {it:tol}=1){p_end}
{synopt:{opth l:evel(#)}} confidence level (by default: {helpb clevel:c(level)})

{syntab :Monte-Carlo-based t-test}
{synopt:{opth seed(#)}}random-number seed, # is any number between 0 and
        2^31-1 (or 2,147,483,647)
        (by default:{helpb set_seed: c(rngseed_mt64s)}) {p_end}
{synopt:{opth iter:ate(#)}}number of iterations, # must be divisible
        by 50 (by default: {bf:500}){p_end}
{synopt:{opth dist:ribution(string)}}random-variable generating function, name
        of an earlier declared {helpb m2_ftof:Mata object} returning a
        {bf:real matrix (r x c)} with two arguments, real scalars {bf:r} and
        {bf:c} (by default: {bf:lppinv_runiform}, see 
        {help lppinv##examples:Examples} on how to pass {bf:rnormal()} to
        {cmd:lppinv}, the full list of  built-in functions is available
        {help mf_runiform:here}){p_end}
{synopt:{opt nomc}}skip the Monte Carlo-based t-test{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators if data are
{helpb tsset}; see {help tsvarlist}.
{p_end}
{p 4 6 2}
{opt by}, {opt collect}, {opt fp}, {opt rolling}, {opt statsby}, and {cmd:xi}
are allowed; see {help prefix}.{p_end}
{marker weight}{...}
{p 4 6 2}
{opt weight}s are not allowed; see {help weights}.
{p_end}
{p 4 6 2}
See {manhelp regress_postestimation R:regress postestimation} for features
available after estimation.{p_end}

{marker description}{...}
{title:Description}

{pstd}
The algorithm solves "hybrid" least squares linear programming (LS-LP) problems
with the help of the Moore-Penrose inverse (pseudoinverse), calculated using
{help mf_svsolve:singular value decomposition (SVD)}, with emphasis on
estimation of non-typical constrained OLS ({bf:cOLS}), Transaction Matrix
({bf:TM}), and {bf:custom} (user-defined) cases. The pseudoinverse offers
a unique solution and may be the best linear unbiased estimator (BLUE) for a
group of problems under certain conditions, see Albert (1972). Over- and
identified problems are accompanied by {helpb regress:regression} analysis,
which is feasible in their case. For such and especially all remaining cases,
a Monte-Carlo-based {helpb ttest:t-test} of mean {bf:NRMSE} (normalized
by variance of the RHS) is performed, the sample being drawn from a uniform
or user-provided distribution (via a {help m2_ftof:Mata function}).

{pstd}
Non-typical constrained OLS ({bf:cOLS}) is based on constraints in model and/or
data but not in parameters. Typically, such models are of size ≤ {bf:2N} where
{bf:N} is the number of observations (Bolotov, 2014). Furthermore, the number
of their parameters may vary in the LHS from row to row (e.g. level vs
derivative).

{pstd}
{bf:Example of a non-typical cOLS problem:}
{break}{it:Estimate the trend and the cyclical component of a country's GDP}
{it:given the textbook or any other definition of its peaks, troughs, and}
{it:saddles.}

{pstd}
Transaction Matrix ({bf:TM}) of size ({bf:M x N}) is a formal model of
interaction between {bf:M} and {bf:N} elements in a system (Bolotov, 2015). For
example,
{break}{bind:    • }an input-output table (IOT) is a type of {bf:TM}
where {bf:M = N} and the elements are industries;
{break}{bind:    • }a matrix of trade/investment/etc. is a type of {bf:TM}
where {bf:M = N} and the elements are countries or (macro)regions in which
diagonal elements must, in some cases, be equal to zero;
{break}{bind:    • } a matrix of country/product structure where {bf:M ≠ N}
and some elements are known;
{break}{bind:    }...

{pstd}
{bf:Example of an TM problem:}
{break}{it:Estimate the input-output table or a matrix of trade/investment},
{it:the technical coefficients or (country) shares of which are unknown.}

{pstd}
{cmd:lppinv} returns matrix {bf:r(solution)}, scalar {bf:r(nrmse)}, and
{helpb ttest:t-test} results. In addition, matrix {bf:r(a)} is available with
the help of the command: {break}{cmd:. return list, all}.

{marker methods}{...}
{title:Methods and formulas}

{pstd}
The problem is written as a matrix equation {bf:`a @ x = b`} where {bf:`a`}
consists of coefficients for CONSTRAINTS and for SLACK VARIABLES (the upper
part) as well as for MODEL (the lower part) as illustrated in Figure 1. Each
part of {bf:`a`} can be omitted to accommodate a special case:
{break}{bind:    • }{bf:cOLS} problems require no case-specific CONSTRAINTS;
{break}{bind:    • }{bf:TM} problems require case-specific CONSTRAINTS, no
problem CONSTRAINTS, and an optional MODEL;
{break}{bind:    • }SLACK VARIABLES are non-zero only for inequality
constraints and are omitted if problems don't include any;
{break}{bind:    }...

{pstd}
{break}{bf:Figure 1: Matrix equation `a @ x = b`}
{break} {bind:                            }`a`{bind:                          }
       |{bind:     }`b`
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}| CONSTRAINTS (PROBLEM + CASE-SPECIFIC) | SLACK VARIABLES | CONSTRAINTS |
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}|{bind:                          }MODEL{bind:                         }
       |{bind:    }MODEL{bind:    }|
{break}+–––––––––––––––––––––––––––––––––––––––––––––––––––––––––+–––––––––––––+
{break}Source: self-prepared

{pstd}
The solution of the equation, {bf:`x = pinv(a) @ b`}, is estimated with the
help of {help mf_svsolve:SVD} and is a {bf:minimum-norm least-squares}
{bf:generalized solution} if rank of {bf:`a`} is not full. To check if {bf:`a`}
is within computational limits, its (maximum) dimensions can be calculated
using the formulas:
{break}{bind:    • }{bf:(2 * N) x (K + K*)}{bind:      }{bf:cOLS} without
slack variables;
{break}{bind:    • }{bf:(2 * N) x (K + K* + 1)}{bind:  }{bf:cOLS} with
slack variables;
{break}{bind:    • }{bf:(M * N) x (M * N)}{bind:       }{bf:TM} without
slack variables;
{break}{bind:    • }{bf:(M * N) x (M * N + 1)}{bind:   }{bf:TM} with slack
variables;
{break}{bind:    • }{bf:M x N}{bind:                   }{bf:custom} without
slack variables;
{break}{bind:    • }{bf:M x (N + 1)}{bind:             }{bf:custom} with
slack variables;

{pstd}
where, in {bf:cOLS} problems, {bf:K} is the number of independent variables
in the model (including the constant), {bf:K*} ({bf:K*} \not \in {bf:K})
is the number of extra variables in CONSTRAINTS, and {bf:N} is the number of
observations; in {bf:TM} problems, {bf:M} and {bf:N} are the dimensions of
the transaction matrix; and in custom cases, {bf:M} and {bf:N} or
{bf:M x (N + 1)} are the dimensions of {bf:`a`} (fully user-defined).

{marker remarks}{...}
{title:Remarks}

{pstd}
For Python-savy users there is a Python version of {cmd:lppinv}
{browse "https://pypi.org/project/lppinv/"} with similar functionality.

{marker examples}{...}
{title:Examples}

        cOLS problem:
        {cmd:. sysuse gnp96.dta, clear}
        {cmd:. gen correction = runiform()}
        {cmd:. lppinv gnp96, cols m(time) c(d.gnp96) s(correction)}

        TM problem (with Monte Carlo t-test based on uniform distribution):
        {cmd:. clear}
        {cmd:. set obs 30}
        {cmd:. gen rowsum = rnormal(15, 100)}
        {cmd:. gen colsum = rnormal(12, 196)}
        {cmd:. lppinv rowsum colsum, tm level(90)}
        {cmd:. matlist r(solution)}

        TM problem (with Monte Carlo t-test based on normal distribution):
        ...
        {cmd:. mata: function lppinv_normal(r, c) return(rnormal(r,c, 0, 1))}
        {cmd:. lppinv rowsum colsum, tm level(90) dist(lppinv_normal)}
        {cmd:. matlist r(solution)}

{marker references}{...}
{title:References}

{phang}
Albert, A., 1972. {it:Regression And The Moore-Penrose Pseudoinverse.}
    New York: Academic Press.

{phang}
Bolotov, I. 2014. {it:Modelling of Time Series Cyclical Component on a Defined}
{it:Set of Stationary Points and its Application on the US Business}
{it:Cycle}. [Paper presentation]. The 8th International Days of Statistics and
Economics: Prague.
{browse "https://msed.vse.cz/msed_2014/article/348-Bolotov-Ilya-paper.pdf"}

{phang}
Bolotov, I. 2015. {it:Modeling Bilateral Flows in Economics by Means of Exact}
{it:Mathematical Methods.} [Paper presentation]. The 9th International Days of
Statistics and Economics: Prague.
{browse "https://msed.vse.cz/msed_2015/article/111-Bolotov-Ilya-paper.pdf"}
