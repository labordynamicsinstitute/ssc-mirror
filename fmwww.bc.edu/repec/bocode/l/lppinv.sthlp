{smcl}
{* *! version 1.1.5  14feb2024}{...}
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
{bf:lppinv} {hline 2} a non-iterated general implementation of the LPLS
estimator for cOLS, TM, and custom cases

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:lppinv}
{help varlist|matname:{it:varlist|matname}} (rowsums first for TM problems)
{ifin}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Type of the LP problem}
{synopt:{opt cols}}OLS constrained in values ({bf:cOLS})
        (see {help lppinv##description:Description})
        {p_end}
{synopt:{opt tm}}Transaction matrix ({bf:TM}), options {opt cols} and {opt tm}
        are mutually exclusive (not specifying any of them equals {bf:custom})
        {p_end}

{syntab:Constructing the LHS}
{synopt:{opth m:odel(varlist|matname)}}the MODEL part of {bf:`a`}, including an
        eventual user-provided constant as a variable|matrix column in {bf:cOLS}
        (see {help lppinv##methods:Methods and formulas})
        {p_end}
{synopt:{opth c:onstraints(varlist|matname)}}the CONSTRAINTS part of {bf:`a`}
        {p_end}
{synopt:{opth s:lackvars(varlist|matname)}}the SLACK/SURPLUS VARIABLES part of
        {bf:`a`}
        {p_end}
{synopt:{opt zerod:iagonal}}set all the diagonal elements of {bf:`a`} to 0
        {p_end}

{syntab:SVD-based estimation}
{synopt:{opth tol:erance(real)}}{helpb [M-1] tolerance:roundoff error},
        a number to determine when a number is small enough to be considered
        zero (optional, not specifying {it:tol} is equivalent to specifying
        {it:tol}=0){p_end}
{synopt:{opth l:evel(#)}} confidence level (by default: {helpb clevel:c(level)})

{syntab:Monte-Carlo-based t-test}
{synopt:{opth seed(#)}}random-number seed, # is any number between 0 and
        2^31-1 (or 2,147,483,647)
        (by default:{helpb set_seed: c(rngseed_mt64s)}){p_end}
{synopt:{opth iter:ate(#)}}number of iterations, # must be divisible
        by 50 (by default: {helpb set_iter:c(maxiter)}){p_end}
{synopt:{opth dist:ribution(string)}}random-variable generating function, name
        of an earlier declared {helpb m2_ftof:Mata object} returning a
        {bf:real matrix (r x c)} with two arguments, real scalars {bf:r} and
        {bf:c} (by default: {bf:lppinv_runiform}, see 
        {help lppinv##examples:Examples} on how to pass {bf:rnormal()} to
        {cmd:lppinv}, the full list of  built-in functions is available
        {help mf_runiform:here}){p_end}
{synopt:{opt nomc}}skip the Monte Carlo-based t-test{p_end}
{synopt:{opt notrace}}hide any output with the exception of dots{p_end}
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
The program implements the {bf:LPLS} (linear programming through least squares)
estimator with the help of the Moore-Penrose inverse (pseudoinverse), calculated
using {help mf_svsolve:singular value decomposition (SVD)}, with emphasis on the
estimation of OLS constrained in values ({bf:cOLS}), Transaction Matrix
({bf:TM}), and {bf:custom} (user-defined) cases. The pseudoinverse offers a
unique minimum-norm least-squares solution, which is the best linear unbiased
estimator (BLUE); see Albert (1972, Chapter VI). (Over)determined problems are
accompanied by {helpb regress:regression} analysis, which is feasible in their
case. For such and especially all remaining cases, a Monte Carlo-based
{helpb ttest:t-test} of mean {bf:NRMSE} (normalized by the standard deviation of
the RHS) is performed, the sample being drawn from a uniform or user-provided
distribution (via a {help m2_ftof:Mata function}).

{pstd}
OLS constrained in values ({bf:cOLS}) is an estimation  based on constraints in
the model and/or data but not in parameters. Typically, such models are of size
≤ {bf:kN}, where {bf:N} is the number of observations, since the number of their
constraints may vary in the LHS (e.g., level, derivatives, etc.).

{pstd}
{bf:Example of a cOLS problem:}
{break}{it:Estimate the trend and the cyclical component of a country's GDP}
{it:given the textbook or any other definition of its peaks, troughs, and}
{it:saddles.} For a pre-LPLS approach to this problem, see (Bolotov, 2014).

{pstd}
Transaction Matrix ({bf:TM}) of size ({bf:M x N}) is a formal model of
interaction (allocation, assignment, etc.). between {bf:M} and {bf:N} elements
in any imaginable system, such as intercompany transactions (netting tables),
industries within/between economies (input-output tables), cross-border
trade/investment (trade/investment matrices), etc., where {bf:row} and
{bf:column sums} are known, but {bf: individual elements} of the TM may not be:
{break}{bind:    • }a netting table is a type of {bf:TM}
where {bf:M = N} and the elements are subsidiaries of a MNC;
{break}{bind:    • }an input-output table (IOT) is a type of {bf:TM}
where {bf:M = N} and the elements are industries;
{break}{bind:    • }a matrix of trade/investment is a type of {bf:TM}
where {bf:M = N} and the elements are countries or (macro)regions, where
diagonal elements may be equal to zero;
{break}{bind:    • }a country-product matrix is a type of {bf:TM} where
{bf:M ≠ N} and the elements are of different types;
{break}{bind:    }...

{pstd}
{bf:Example of a TM problem:}
{break}{it:Estimate the matrix of trade/investment with/without zero diagonal}
{it:elements, the country shares in which are unknown.} For a pre-LPLS approach
to this problem, see (Bolotov, 2015).

{pstd}
{cmd:lppinv} returns matrix {bf:r(solution)}, scalar {bf:r(nrmse)}, scalar 
{bf:r(r2_c)} (R-squared for CONSTRAINTS in TM), and regression and/or
{helpb ttest:t-test} results. In addition, matrix {bf:r(a)} is available with
the help of the command: {break}{cmd:. return list, all}.

{marker methods}{...}
{title:Methods and formulas}

{pstd}
The LP problem in the {bf:LPLS} estimator is a matrix equation {bf:`a @ x = b`},
loosely based on the structure of the Simplex tableau,  where {bf:`a`} consists
of coefficients for CONSTRAINTS, LP-type CHARACTERISTIC and/or SPECIFIC, and
for SLACK/SURPLUS VARIABLES (the upper part) as well as for the MODEL (the lower
part), as illustrated in Figure 1. Each part of {bf:`a`} can be omitted to
accommodate a particular case:
{break}{bind:    • }{bf:cOLS} problems require SPECIFIC CONSTRAINTS, no
LP-type CHARACTERISTIC CONSTRAINTS, and a MODEL;
{break}{bind:    • }{bf:TM} requires LP-type CHARACTERISTIC CONSTRAINTS,
no SPECIFIC CONSTRAINTS, and an optional MODEL;
{break}{bind:    • }SLACK/SURPLUS VARIABLES are included only for inequality
constraints and should be set to {bf:1} or {bf:-1};
{break}{bind:    }...

{pstd}
{break}{bf:Figure 1: Matrix equation `a @ x = b`}
{break} {bind:                            }`a`{bind:                          }
       |{bind:     }`b`
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}| CONSTRAINTS: CHARACTERISTIC/SPECIFIC{bind: }
       | SL/SU VARIABLES | CONSTRAINTS |
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}|{bind:                          }MODEL{bind:                         }
       |{bind:    }MODEL{bind:    }|
{break}+–––––––––––––––––––––––––––––––––––––––––––––––––––––––––+–––––––––––––+
{break}Source: self-prepared

{pstd}
The solution to the equation, {bf:`x = pinv(a) @ b`}, is estimated with the
help of {help mf_svsolve:SVD} and is a {bf:minimum-norm least-squares}
{bf:generalized solution} if the rank of {bf:`a`} is not full. To check if
{bf:`a`} is within the computational limits, its (maximum) dimensions can be
calculated using the formulas:
{break}{bind:    • }{bf:(k * N) x (K + K*)}{bind:      }{bf:cOLS} without
slack/surplus variables;
{break}{bind:    • }{bf:(k * N) x (K + K* + l)}{bind:  }{bf:cOLS} with
slack/surplus variables;
{break}{bind:    • }{bf:(M + N) x (M * N)}{bind:       }{bf:TM} without
slack/surplus variables;
{break}{bind:    • }{bf:(M + N) x (M * N + l)}{bind:   }{bf:TM} with
slack/surplus variables;
{break}{bind:    • }{bf:M x N}{bind:                   }{bf:custom} without
slack/surplus variables;
{break}{bind:    • }{bf:M x (N + l)}{bind:             }{bf:custom} with
slack/surplus variables;

{pstd}
where, in {bf:cOLS} problems, {bf:K} is the number of independent variables in
the model (including the constant), {bf:K*} is the number of eventual extra
variables in CONSTRAINTS, and {bf:N} is the number of observations; in {bf:TM},
{bf:M} and {bf:N} are the dimensions of the matrix; and in {bf:custom} cases,
{bf:M} and {bf:N} or {bf:M x (N + l)} are the dimensions of {bf:`a`}.

{marker remarks}{...}
{title:Remarks}

{pstd}
For Python-savvy users, there is a Python version of {cmd:lppinv}
{browse "https://pypi.org/project/lppinv/"} with equivalent functionality.

{marker examples}{...}
{title:Examples}

        cOLS problem:
        {cmd:. sysuse gnp96.dta, clear}
        {cmd:. gen correction = runiform()}
        {cmd:. lppinv gnp96, cols m(time) c(d.gnp96) s(correction)}
        {cmd:. matlist r(solution)}

        TM problem with Monte Carlo t-test based on the uniform distribution:
        {cmd:. clear}
        {cmd:. set obs 30}
        {cmd:. gen rowsum = rnormal(15, 100)}
        {cmd:. gen colsum = rnormal(12, 196)}
        {cmd:. lppinv rowsum colsum, tm level(90)}
        {cmd:. lppinv rowsum colsum, tm zerod level(90)}
        {cmd:. matlist r(solution)}

        TM problem with Monte Carlo t-test based on the normal distribution:
        ...
        {cmd:. mata: function lppinv_normal(r, c) return(rnormal(r,c, 0, 1))}
        {cmd:. lppinv rowsum colsum, tm level(90) dist(lppinv_normal)}
        {cmd:. matlist r(solution)}

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
    Thanks for citing this software and my works on the topic:

{p 8 8 2}
    Bolotov, I. (2024). LPPINV: A non-iterated general implementation of the
    LPLS estimator in Stata.
    Available from {browse "https://ideas.repec.org/c/boc/bocode/s459045.html"}.

{marker references}{...}
{title:References}

{phang}
Albert, A., 1972. {it:Regression And The Moore-Penrose Pseudoinverse.} New
York: Academic Press.

{phang}
Bolotov, I. 2014. {it:Modeling of Time Series Cyclical Component on a Defined}
{it:Set of Stationary Points and its Application on the US Business}
{it:Cycle}. [Paper presentation]. The 8th International Days of Statistics and
Economics: Prague.
{browse "https://msed.vse.cz/msed_2014/article/348-Bolotov-Ilya-paper.pdf"}

{phang}
Bolotov, I. 2015. {it:Modeling Bilateral Flows in Economics by Means of Exact}
{it:Mathematical Methods.} [Paper presentation]. The 9th International Days of
Statistics and Economics: Prague.
{browse "https://msed.vse.cz/msed_2015/article/111-Bolotov-Ilya-paper.pdf"}

{phang}
{bf:PS} Please also check the Web of Science (WoS) for new research on LPLS.

