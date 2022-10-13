{smcl}
{* *! version 1.1.0  07oct2022}{...}
{viewerjumpto "Syntax" "tmpinv##syntax"}{...}
{viewerjumpto "Description" "tmpinv##description"}{...}
{viewerjumpto "Methods and formulas" "tmpinv##methods"}{...}
{viewerjumpto "Examples" "tmpinv##examples"}{...}
{viewerjumpto "Remarks" "tmpinv##remarks"}{...}
{viewerjumpto "References" "tmpinv##references"}{...}
{p2colset 1 15 17 2}{...}

{title:Title}
{phang}
{bf:tmpinv} {hline 2} solve an under-, over-, and identified linear problem
without an objective function (a "hybrid" LP-LS problem) of Transaction
Matrix (TM) type with the help of the Moore-Penrose pseudoinverse, singular
value decomposition (SVD), an F-test from linear regression/a t-test of mean
normalized RMSE, and results adjustment for extreme values

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:tmpinv}
{help varlist|matname:{it:varlist|matname}} (rowsums first, missing skipped)
{ifin}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Constructing the LHS and RHS}
{synopt:{opth s:lackvars(varlist|matname)}}the SLACK VARIABLES part of {bf:`a`},
        two columns, rowsums first{p_end}
{synopt:{opth v:alues(varname|colvector)}}the KNOWN VALUES part of {bf:`b`}
        whose length should be equal to the one of the TM, missing values
        included, {cmd:colshape(`TM`, 1) = `V`}{p_end}
{synopt:{opt zerod:iagonal}}set all diagonal elements of the TM to 0 in {bf:`a`}
        {p_end}
{synopt:{opth adj:ustment(strings:string)}}adjustment for extreme values to
        match the RHS via shares of row/column sums, {bf:"row"}, {bf:"col"},
        or {bf:"ave"} (mean of both), not specified ≠ no adjustment{p_end}

{syntab:SVD-based estimation}
{synopt:{opth subm:atrix(#)}}maximum size of each contiguous submatrix, set
        {it:subm}≤2 for (over-)identification, OLS estimation, and an F-test
        from linear regression (default, {it:slower}), or a greater number
        (maximum is {bf:50}, {it:faster}) for under-identification, minimum-norm
        least-squares generalized solution, and a t-test of mean NRMSE{p_end}
{synopt:{opth tol:erance(real)}}{helpb [M-1] tolerance:roundoff error},
        a number to determine when a number is small enough to be considered
        zero (optional, not specifying {it:tol} is equivalent to specifying
        {it:tol}=0){p_end}
{synopt:{opth l:evel(#)}} confidence level (by default: {helpb clevel:c(level)})

{syntab:Monte-Carlo-based t-test}
{synopt:{opt trace}}display regression/t-test output for each contiguous
        submatrix{p_end}
{synopt:{opt dist:ribution}}display nine main percentiles of the Monte
        Carlo pre-simulated distribution{p_end}

{syntab:Compensatory operations}
{synopt:{opth iter:ate(#)}}number of iterations, set {it:iter}=0 to disable
        completely, {it:iter}=1 to choose the first improvement in up to
        {bf:500} iterations (default), or a greater number to minimize the NRMSE
        {it:(compensatory operations require non-empty {bf:values()})}
        {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by}, {opt collect}, {opt fp}, {opt rolling}, {opt statsby}, and {cmd:xi}
are allowed; see {help prefix}.{p_end}
{marker weight}{...}
{p 4 6 2}
{opt weight}s are not allowed; see {help weights}.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
The algorithm solves "hybrid" linear programming-least squares (LP-LS)
Transaction Matrix (TM) problems with the help of the Moore-Penrose inverse
(pseudoinverse), calculated using singular value decomposition (SVD). The
estimation using {bf:2x2} (by default) to {bf:50x50} contiguous submatrices,
repeated with compensatory slack variables until NRMSE is minimized in a given
number of iterations (if {bf:values()} are defined), is followed by an F-test
from linear regression/t-test of mean NRMSE from a pre-simulated distribution
(Monte-Carlo, {bf:50,000} iterations with matrices consisting of normal random
variates, estimated with increased precision, {it:tol}={bf:c(epsdouble)}). The
result is adjusted for extreme values to match {bf:`b`} with the help of
shares of estimated row sums/column sums/mean of both if {bf:adjustment()} is
specified.

{pstd}
{cmd:tmpinv} is a sister program to {helpb lppinv} 1) focusing on one type of
LP-LS problems (TM), 2) dividing the TM into contiguous submatrices with the
size of up to {bf:(49 + sum of rest)x(49 + sum of rest)}, 3) being based
on {helpb regress} results (F-test) for {bf:subm(≤2)} or on a pre-simulated
Monte Carlo distribution and {helpb ttesti} for {bf:subm(>2)}, 4) performing
eventual "compensatory operations" by adding a slack variable equal to residuals
of KNOWN VALUES/their estimates from the previous step to {bf:`a`}, attempting
to minimize NRMSE, and 5) adjusting the result to match CONSTRAINTS in {bf:`b`}
(if enabled).

{p 8 8 2}
{bf:NB} The rule of thumb is to use as many iterations in {bf:iter(#)} as
possible since more iterations = lower NRMSE.

{pstd}
The {helpb ttesti} tests the mean NRMSE against a no-{bf:values()} {bf:50,000}
sample, which yielded the highest errors; ergo, poor test results indicate a
severely misidentified model. Use the {bf:distribution} option to compare
the NRMSE for each submatrix with the main percentiles of the sample (they are
sometimes easier to interprete than the t-test).

{pstd}
{bf:What is a TM?}
{break}Transaction Matrix ({bf:TM}) of size ({bf:M x N}) is a formal model of
interaction between {bf:M} and {bf:N} elements in any imaginable system, such as
the national economy, trade, investment, etc. (Bolotov, 2015). For
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
{bf:Example of a TM problem:}
{break}{it:Estimate the input-output table or a matrix of trade/investment},
{it:the technical coefficients, or (country) shares of which are unknown.}

{pstd}
{cmd:tmpinv} clears estimation results and returns (matrix) {bf:r(solution)}
and (matrix) {bf:r(tests)}. In addition, (matrix) {bf:r(nrmse_dist)} is
available with the help of the command:
{break}{cmd:. return list, all}

{marker methods}{...}
{title:Methods and formulas}

{pstd}
The LP-LS problem is written as a matrix equation {bf:`a @ x = b`} where
{bf:`a`} consists of coefficients for CONSTRAINTS (aka the "characteristic
matrix" which depends on {bf:M} and {bf:N} of the TM and is automatically
generated by the software) and for SLACK VARIABLES (the upper part) as well as
for the identity matrix  {bf:I}() (the lower part) as illustrated in
Figure 1. SLACK VARIABLES can be omitted.

{pstd}
{break}{bf:Figure 1: Matrix equation `a @ x = b`}
{break} {bind:                            }`a`{bind:                          }
       |{bind:     }`b`
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}| CONSTRAINTS OF THE TRANSACTION MATRIX | SLACK VARIABLES | CONSTRAINTS |
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}|{bind:                 }{bf:I}(){bind:                  }
       |{bind: }COMPENSATORY S.{bind: }|{bind:   }KNOWN V.{bind:  }|
{break}+–––––––––––––––––––––––––––––––––––––––––––––––––––––––––+–––––––––––––+
{break}Source: self-prepared

{pstd}
The solution of the equation, {bf:`x = pinv(a) @ b`}, is estimated with the
help of {help mf_svsolve:SVD} and is a {bf:minimum-norm least-squares}
{bf:generalized solution} if the rank of {bf:`a`} is not full. To check if 
bf:`a`} is within computational limits, its (maximum) dimensions can be
calculated using the formulas:
{break}{bind:    • }{bf:(M + N){bind:         }x (M * N)}{bind:        }{bf:TM}
without slack variables and known values;
{break}{bind:    • }{bf:(M + N + M * N) x (M * N)}{bind:        }{bf:TM} without
slack variables but with known values;
{break}{bind:    • }{bf:(M + N){bind:         }x (M * N + 1)}{bind:    }{bf:TM}
with slack variables but without known values;
{break}{bind:    • }{bf:(M + N + M * N) x (M * N + 1)}{bind:    }{bf:TM} with
slack variables and known values.

{pstd}
where {bf:M} and {bf:N} are the dimensions of the transaction matrix.

{marker examples}{...}
{title:Examples}

        TM problem (with Monte Carlo t-test based on uniform distribution):
        {cmd:. clear}
        {cmd:. set obs 30}
        {cmd:. gen rowsum = rnormal(15, 100)}
        {cmd:. gen colsum = rnormal(12, 196)}
        {cmd:. tmpinv rowsum colsum, level(90)}
        {cmd:. tmpinv rowsum colsum, zerod dist}

        TM problem (with compensatory operations):
        ...
        {cmd:. mata: st_matrix("RHS", st_data(1::5,1..2))}
        {cmd:. gen known = rnormal(18, 252) if _n <= 25}
        {cmd:. tmpinv RHS in 1/25, v(known) subm(50) level(90)}
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
    Bolotov, I. (2022). TMPINV: Stata module to solve an under-, over- and
    identified Transaction Matrix (TM) problem with the help of the
    Moore-Penrose pseudoinverse, singular value decomposition (SVD), an F-test
    from linear regression/t-test of mean normalized RMSE, and results
    adjustment for extreme values. Available from
    {browse "https://ideas.repec.org/c/boc/bocode/s459131.html"}.

{marker references}{...}
{title:References}

{phang}
Albert, A., 1972. {it:Regression And The Moore-Penrose Pseudoinverse.}
New York: Academic Press.

{phang}
Bolotov, I. 2015. {it:Modeling Bilateral Flows in Economics by Means of Exact}
{it:Mathematical Methods.} [Paper presentation]. The 9th International Days of
Statistics and Economics: Prague.
{browse "https://msed.vse.cz/msed_2015/article/111-Bolotov-Ilya-paper.pdf"}
