{smcl}
{* *! version 1.0.0  30sep2022}{...}
{viewerjumpto "Syntax" "tmpinv##syntax"}{...}
{viewerjumpto "Description" "tmpinv##description"}{...}
{viewerjumpto "Methods and formulas" "tmpinv##methods"}{...}
{viewerjumpto "Examples" "tmpinv##examples"}{...}
{viewerjumpto "Remarks" "tmpinv##remarks"}{...}
{viewerjumpto "References" "tmpinv##references"}{...}
{p2colset 1 15 17 2}{...}

{title:Title}
{phang}
{bf:tmpinv} {hline 2} solve an under-, over- and identified linear problem
without an objective function (a "hybrid" LP-LS problem) of Transaction
Matrix (TM) type with the help of the Moore-Penrose pseudoinverse, singular
value decomposition (SVD), and a t-test of the mean normalized RMSE

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:tmpinv}
{help varlist|matname:{it:varlist|matname}} (rowsums first)
{ifin}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Constructing the LHS}
{synopt:{opth s:lackvars(varlist|matname)}}the SLACK VARIABLES part of {bf:`a`},
        two columns, rowsums first{p_end}
{synopt:{opth v:alues(varname|colvector)}}the KNOWN VALUES part of {bf:`b`}
        whose length should be equal to the one of the TM, missing values
        included, {cmd:colshape(`TM`, 1) = `V`}{p_end}
{synopt:{opt zerod:iagonal}}set all diagonal elements of the TM to 0 in {bf:`a`}
        {p_end}

{syntab:SVD-based estimation}
{synopt:{opth tol:erance(real)}}{helpb [M-1] tolerance:roundoff error},
        a number to determine when a number is small enough to be considered
        zero (optional, not specifying {it:tol} is equivalent to specifying
        {it:tol}=0){p_end}
{synopt:{opth l:evel(#)}} confidence level (by default: {helpb clevel:c(level)})

{syntab:Monte-Carlo-based t-test}
{synopt:{opt trace}}display t-test output for each contiguous submatrix{p_end}
{synopt:{opt dist:ribution}}display main percentiles of the Monte
        Carlo-simulated distribution{p_end}

{syntab:Compensatory operations}
{synopt:{opth iter:ate(#)}}number of iterations, set {it:iter}=0 to disable
        completely, {it:iter}=1 to choose the first improvement in up to
        {bf:500} iterations (default), greater number to minimize the normalized
        RMSE {it:(compensatory operations require {bf:values()} to be defined)}
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
The algorithm solves the so-called "hybrid" linear programming-least squares
(LP-LS) Transaction Matrix (TM) problems with the help of the Moore-Penrose
inverse (pseudoinverse), calculated using singular value decomposition
(SVD). The method includes a 50x50 contiguous submatrix estimation and a t-test
of mean RMSE, normalized by standard deviation, from a pre-simulated
distribution (Monte-Carlo, 50,000 iterations with matrices consisting of normal
random variates), fine-tuned via compensatory slack variables until NRMSE is
minimized if {bf:values()} are defined.

{pstd}
{cmd:tmpinv} is a sister program to {helpb lppinv}, focusing on a) one type of
the LP-LS problems (TM), b) dividing the TM into contiguous submatrices with
the size of up to (49 + 1 Rest of World)x(49 + 1 Rest of World), c) being based
on a simulated Monte Carlo distribution for {helpb ttesti}, and d) performs
eventual compensatory operations on KNOWN VALUES ({bf:`V`}), minimizing the
NRMSE (given the "irregularity" of its distribution, the rule of thumb is to use
more iterations in {bf:iter(#)} to achieve better results).

{pstd}
The {helpb ttesti} tests the mean NRMSE against the no-{bf:values()} sample
scenario which yields highest NRMSE, ergo poor test results indicate a severely
misidentified model. Use the {bf:distribution} option for additional assessment.

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
{cmd:tmpinv} returns matrix {bf:r(solution)} and matrix {bf:r(nrmse)}. In
addition, matrix {bf:r(nrmse_dist)} is available with the help of the command:
{break}{cmd:. return list, all}

{marker methods}{...}
{title:Methods and formulas}

{pstd}
The problem is written as a matrix equation {bf:`a @ x = b`} where {bf:`a`}
consists of coefficients for CONSTRAINTS and for SLACK VARIABLES (the upper
part) as well as for the identity matrix {bf:I}() (the lower part) as
illustrated in Figure 1. SLACK VARIABLES can be omitted.

{pstd}
{break}{bf:Figure 1: Matrix equation `a @ x = b`}
{break} {bind:                            }`a`{bind:                          }
       |{bind:     }`b`
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}| CONSTRAINTS OF THE TRANSACTION MATRIX | SLACK VARIABLES | CONSTRAINTS |
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}|{bind:                 }{bf:I}(){bind:                  }
       |{bind:   }COMPENSATORY{bind:  }|{bind: }KNOWN VALUES{bind:}|
{break}+–––––––––––––––––––––––––––––––––––––––––––––––––––––––––+–––––––––––––+
{break}Source: self-prepared

{pstd}
The solution of the equation, {bf:`x = pinv(a) @ b`}, is estimated with the
help of {help mf_svsolve:SVD} and is a {bf:minimum-norm least-squares}
{bf:generalized solution} if rank of {bf:`a`} is not full. To check if {bf:`a`}
is within computational limits, its (maximum) dimensions can be calculated
using the formulas:
{break}{bind:    • }{bf:(M * N) x (M * N)}{bind:       }{bf:TM} without
slack variables;
{break}{bind:    • }{bf:(M * N) x (M * N + 1)}{bind:   }{bf:TM} with slack
variables;

{pstd}
where {bf:M} and {bf:N} are the dimensions of the transaction matrix.

{marker examples}{...}
{title:Examples}

        TM problem (with Monte Carlo t-test based on uniform distribution):
        {cmd:. clear}
        {cmd:. set obs 100}
        {cmd:. gen rowsum = rnormal(15, 100)}
        {cmd:. gen colsum = rnormal(12, 196)}
        {cmd:. tmpinv rowsum colsum, level(90)}
        {cmd:. tmpinv rowsum colsum, zerod dist}

        TM problem (with compensatory operations):
        ...
        {cmd:. mata: st_matrix("RHS", st_data(1::10,1..2))}
        {cmd:. gen known = rnormal(18, 252) if _n <= 50}
        {cmd:. tmpinv RHS, v(known) level(90)}
        {cmd:. matlist r(solution)}

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
