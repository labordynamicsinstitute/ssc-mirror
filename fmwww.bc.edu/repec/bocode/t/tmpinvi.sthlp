{smcl}
{* *! version 1.0.0  20feb2024}{...}
{viewerjumpto "Syntax" "tmpinv##syntax"}{...}
{viewerjumpto "Description" "tmpinv##description"}{...}
{viewerjumpto "Methods and formulas" "tmpinv##methods"}{...}
{viewerjumpto "Examples" "tmpinv##examples"}{...}
{viewerjumpto "Remarks" "tmpinv##remarks"}{...}
{viewerjumpto "References" "tmpinv##references"}{...}
{p2colset 1 15 17 2}{...}

{title:Title}
{phang}
{bf:tmpinvi} {hline 2} an iterated (multistep) Transaction Matrix (TM)-specific
implementation of the LPLS estimator

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:tmpinvi}
{help varlist|matname:{it:varlist|matname}} (rowsums first, missing skipped)
{ifin}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Constructing the LHS and RHS}
{synopt:{opth s:lackvars(varlist|matname)}}the SLACK/SURPLUS VARIABLES part of
        {bf:`a`}, two columns, rowsums first{p_end}
{synopt:{opth v:alues(varname|colvector)}}the KNOWN VALUES part of {bf:`b`}
        the length of which should be equal to the one of the {bf:TM}, missing
        values included, {cmd:colshape({bf:TM}, 1) = `v`}{p_end}
{synopt:{opt zerod:iagonal}}set all diagonal elements of the TM to 0 in {bf:`a`}
        {p_end}
{synopt:{opth adj:ustment(strings:string)}}adjustment for extreme values to
        match the RHS via shares of row/column sums, {bf:"row"}, {bf:"col"},
        or {bf:"ave"} (mean of both), not specified ≠ no adjustment{p_end}

{syntab:SVD-based estimation}
{synopt:{opth subm:atrix(#)}}maximum size of each contiguous submatrix, set
        {it:subm}≤2 for (over)determination, OLS estimation, and an F-test from
        linear regression (default, {it:slow}: {it:higher quality of}
        {it:individual estimates} but potentially {it:lower overall quality}),
        or a greater number (maximum is {bf:50}, {it:faster}: {it:lower quality}
        {it:of individual estimates} but potentially {it:higher overall}
        {it:quality}) for underdetermination, minimum-norm least-squares
        generalized solution, and a t-test of mean NRMSE, based on a Monte
        Carlo-simulated distribution {p_end}
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
        {helpb set_iter:c(maxiter)} iterations (default), or a greater number to
        minimize the NRMSE
        {it:(compensatory operations require non-empty {bf:values()})}
        {p_end}

{syntab:Multistep estimation}
{synopt:{opth l:owerbound(real)}}lower bound for each element in the solution,
        each value lower than which is replaced by a missing one ({bf:.})
        {p_end}
{synopt:{opth u:pperbound(real)}}upper bound for each element in the solution,
        each value higher than which is replaced by a missing one ({bf:.})
        {p_end}
{synopt:{opth r:ound(real)}}{it:y} in {helpb round()}, in the units of which the
        solution is rounded before comparing its elements with {bf:lowerbound()}
        and/or {bf:upperbound()} (by default: {bf:8e-307})
        {p_end}
{synopt:{opt pen:alization}}add the number of missing values in rows and columns
        of the solution as {bf:slackvars()} in the model to compensate for the
        use of {bf:lowerbound()} and/or {bf:upperbound()}{p_end}
{synopt:{opth stepn:umber(#)}}number of steps in addition to the initial
        estimation (by default: {bf:2})
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
The program implements the {bf:LPLS} (linear programming through least squares)
estimator for Transaction Matrices ({bf:TM}) with the help of the Moore-Penrose
inverse (pseudoinverse), calculated using singular value decomposition
(SVD). The pseudoinverse offers a unique minimum-norm least-squares solution,
which is the best linear unbiased estimator (BLUE); see Albert (1972, Chapter
VI). The estimation using {bf:2x2} (by default) to {bf:50x50} contiguous
submatrices, repeated with compensatory slack/surplus variables until NRMSE is
minimized in a given number of iterations (if {bf:values()} are defined), is
followed by an F-test from linear regression/t-test of mean NRMSE from a
pre-simulated distribution (Monte-Carlo, {bf:50,000} iterations with matrices
consisting of normal random variates, estimated with increased precision,
{it:tol}={bf:c(epsdouble)}). The result is adjusted for extreme values to match
{bf:`b`} with the help of shares of estimated row sums/column sums/mean of both
if {bf:adjustment()} is specified.

{pstd}
{helpb tmpinv} is a sister program to {helpb lppinv} 1) focusing on a single type
of LP problems ({bf:TM}), 2) dividing the {bf:TM} into contiguous submatrices
with the size of up to {bf:(49 + sum of the rest)x(49 + sum of the rest)}, 3)
being based on {helpb regress} results (F-test) for {bf:subm(≤2)} or on a
pre-simulated Monte Carlo distribution and {helpb ttesti} for {bf:subm(>2)}, 4)
performing eventual "compensatory operations" by adding a slack/surplus variable
equal to residuals of KNOWN VALUES/their estimates from the previous step to
{bf:`a`}, attempting to minimize NRMSE, and 5) adjusting the result to match
CONSTRAINTS in {bf:`b`} (if enabled).

{p 8 8 2}
{bf:NB} The rule of thumb is to use as many iterations in {bf:iter(#)} as
possible since more iterations = lower NRMSE.

{pstd}
The {helpb ttesti} tests the mean NRMSE against a no-{bf:values()} {bf:50,000}
sample, which yielded the highest errors; ergo, poor test results indicate a
grossly misspecified model. Use the {bf:distribution} option to compare
the NRMSE for each submatrix with the main percentiles of the sample (they are
sometimes easier to interprete than the t-test).

{pstd}
{cmd:tmpinvi} is an iterated (multistep) version of {helpb tmpinv}. Each further
step, the number of which is controlled in {bf:stepnumber()}, uses the solution
obtained in the previous step, adjusted to eventual {bf:lowerbound()} and
{bf:upperbound()}, as {bf:values()} in the model with/without {bf:penalization}
of the number of missing values in rows and columns as {bf:slackvars()},
maximizing the {bf:R-squared for CONSTRAINTS}. If R-squared for CONSTRAINTS is
out of bounds (below {bf:0} or above {bf:1}), the command reports
non-convergence.

{pstd}
{bf:What is a TM?}
{break}Transaction Matrix ({bf:TM}) of size ({bf:M x N}) is a formal model of
interaction (allocation, assignment, etc.) between {bf:M} and {bf:N} elements
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
{cmd:tmpinvi} clears estimation results and returns matrix {bf:r(solution)},
matrix {bf:r(tests)}, scalar {bf:r(r2_c)} (R-squared for CONSTRAINTS), and
scalar {bf:r(r2_v)} (R-squared for KNOWN VALUES) (if available). In addition,
matrix {bf:r(nrmse_dist)} is available with the help of the command:
{break}{cmd:. return list, all}

{marker methods}{...}
{title:Methods and formulas}

{pstd}
The {bf:TM} problem is written as a matrix equation {bf:`a @ x = b`}, loosely
based on the structure of the Simplex tableau, where {bf:`a`} consists of
coefficients for CONSTRAINTS (aka the "characteristic matrix" which depends on
{bf:M} and {bf:N} of the TM and is automatically generated by the algorithm) and
for SLACK/SURPLUS VARIABLES (the upper part) as well as for the identity matrix
{bf:I} (the lower part) as illustrated in Figure 1. SLACK/SURPLUS VARIABLES can
be omitted.

{pstd}
{break}{bf:Figure 1: Matrix equation `a @ x = b`}
{break} {bind:                            }`a`{bind:                          }
       |{bind:     }`b`
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}| CONSTRAINTS OF THE TRANSACTION MATRIX | SL/SU VARIABLES | CONSTRAINTS |
{break}+–––––––––––––––––––––––––––––––––––––––+–––––––––––––––––+–––––––––––––+
{break}|{bind:                   }{bf:I}{bind:                  }
       |{bind: }COMPENSATORY S.{bind: }|{bind:   }KNOWN V.{bind:  }|
{break}+–––––––––––––––––––––––––––––––––––––––––––––––––––––––––+–––––––––––––+
{break}Source: self-prepared

{pstd}
The solution of the equation, {bf:`x = pinv(a) @ b`}, is estimated with the
help of {help mf_svsolve:SVD} and is a {bf:minimum-norm least-squares}
{bf:generalized solution} if the rank of {bf:`a`} is not full. To check if 
{bf:`a`} is within computational limits, its (maximum) dimensions can be
calculated using the formulas:
{break}{bind:    • }{bf:(M + N){bind:         }x (M * N)}{bind:        }{bf:TM}
without slack/surplus variables and known values;
{break}{bind:    • }{bf:(M + N + M * N) x (M * N)}{bind:        }{bf:TM} without
slack/surplus variables but with known values;
{break}{bind:    • }{bf:(M + N){bind:         }x (M * N + 1)}{bind:    }{bf:TM}
with slack/surplus variables but without known values;
{break}{bind:    • }{bf:(M + N + M * N) x (M * N + 1)}{bind:    }{bf:TM} with
slack/surplus variables and known values.

{pstd}
where {bf:M} and {bf:N} are the dimensions of the transaction matrix.

{marker examples}{...}
{title:Examples}

        TM problem with F-test from linear regression:
        {cmd:. clear}
        {cmd:. set obs 10}
        {cmd:. gen str13 country_id = ""}
        {cmd:. mata: st_local("b", "Country #"); st_local("e", "Rest of World")}
        {cmd:. mata: st_sstore(., "country_id", ("`b'":+strofreal(1::9)\"`e'"))}
        {cmd:. gen float exports = runiform(0, 1000)}
        {cmd:. gen float imports = runiform(0, 1000)}
        {cmd:. list}
        {cmd:. tmpinvi exports imports, zerod adj(ave)          l(0) u(1000)}
        {cmd:. matlist r(solution)}
        {cmd:. return list}

        TM problem with Monte Carlo t-test based on the uniform distribution:
        ...
        {cmd:. tmpinvi exports imports, zerod adj(ave) subm(10) l(0) u(1000)}
        {cmd:. matlist r(solution)}
        {cmd:. return list}

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
Thanks for citing this software and my works on the topic:

{p 8 8 2}
Bolotov, I. (2024). 'TMPINVI': module providing an iterated (multistep)
Transaction Matrix (TM)-specific implementation of the LPLS estimator. Available
from {browse "https://ideas.repec.org/c/boc/bocode/s459131.html"}.

{marker references}{...}
{title:References}

{phang}
Albert, A., 1972. {it:Regression And The Moore-Penrose Pseudoinverse.} New
York: Academic Press.

{phang}
Bolotov, I. 2015. {it:Modeling Bilateral Flows in Economics by Means of Exact}
{it:Mathematical Methods.} [Paper presentation]. The 9th International Days of
Statistics and Economics: Prague.
{browse "https://msed.vse.cz/msed_2015/article/111-Bolotov-Ilya-paper.pdf"}

{phang}
{bf:PS} Please also check the Web of Science (WoS) for new research on LPLS and
TM in particular.
