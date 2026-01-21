{smcl}
{* *! version 1.0.0  20nov2025}{...}
{viewerjumpto "Syntax" "lppinv##syntax"}{...}
{viewerjumpto "Description" "lppinv##description"}{...}
{viewerjumpto "Postestimation" "lppinv##postestimation"}{...}
{viewerjumpto "Remarks" "lppinv##remarks"}{...}
{viewerjumpto "Examples" "lppinv##examples"}{...}
{viewerjumpto "Stored results" "lppinv##results"}{...}

{title:Title}
{phang}
{cmd:lppinv} {hline 2} Linear Programming via Regularized Least Squares (LPPinv)
is a modular two-step estimator for solving underdetermined, ill-posed, or
structurally constrained linear and quadratic programming problems using
least-squares and convex optimization

{title:Requirements}
{phang}
Because Stata does not provide native convex optimization tools, estimation is
performed using the Python 3 module {bf:pylppinv}, which must be installed and
available to Stata's Python integration. Installation can be performed from the
system shell:

{phang}
{cmd:. shell pip {space 1} install {space 18}pylppinv}{p_end}
{phang}
{cmd:. shell conda install -c ilyabolotov -y pylppinv}{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:lppinv}
{help strings:{it:string}}
{ifin}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Problem definition}
{synopt :{it:string}}One of: {bf:nonneg} - enforce nonnegativity constraints,
        the standard setting in real-world linear and quadratic programming
        problems, or {bf:free} - enforce no constraints.{p_end}

{syntab:Right-hand side}
{synopt :{opth bub:(strings:string)}}Right-hand side vector for inequality
        constraints, {help varname:{it:varname}} or
        {it:name of an existing matrix}. Please note that at least one of
        {bf:bub({help strings:{it:string}})} or
        {bf:beq({help strings:{it:string}})} must be provided, matched by
        a corresponding {bf:aub({help strings:{it:string}})} or
        {bf:aeq({help strings:{it:string}})}.{p_end}
{synopt :{opth beq:(strings:string)}}Right-hand side vector for equality
        constraints, {help varname:{it:varname}} or
        {it:name of an existing matrix}. Please note that at least one of
        {bf:bub({help strings:{it:string}})} or
        {bf:beq({help strings:{it:string}})} must be provided, matched by
        a corresponding {bf:aub({help strings:{it:string}})} or
        {bf:aeq({help strings:{it:string}})}.{p_end}

{syntab:Left-hand side}
{synopt :{opth aub:(strings:string)}}Matrix for inequality constraints
        {bf:aub({help strings:{it:string}})} ⋅ {bf:x} ≤
        {bf:bub({help strings:{it:string}})}, {help varlist:{it:varlist}}
        or {it:name of an existing matrix}. Please note that at least one of
        {bf:aub({help strings:{it:string}})} or
        {bf:aeq({help strings:{it:string}})} must be provided, matched by
        a corresponding {bf:bub({help strings:{it:string}})} or
        {bf:beq({help strings:{it:string}})}.{p_end}
{synopt :{opth aeq:(strings:string)}}Matrix for equality constraints
        {bf:aeq({help strings:{it:string}})} ⋅ {bf:x} =
        {bf:beq({help strings:{it:string}})}, {help varlist:{it:varlist}}
        or {it:name of an existing matrix}. Please note that at least one of
        {bf:aub({help strings:{it:string}})} or
        {bf:aeq({help strings:{it:string}})} must be provided, matched by
        a corresponding {bf:bub({help strings:{it:string}})} or
        {bf:beq({help strings:{it:string}})}.{p_end}

{syntab:Prior information}
{synopt :{opth lower:bound(numlist)}}Lower bounds on cell values. If a single
        value is given (please use missing values {bf:.} or {bf:.a-z} for
        {bf:-∞}), it is applied to all variables. Under {bf:nonneg}, negative
        values in {bf:lowerbound({help numlist:{it:numlist}})} will produce an
        error.{p_end}
{synopt :{opth upper:bound(numlist)}}Upper bounds on cell values. If a single
        value is given (please use missing values {bf:.} or {bf:.a-z} for
        {bf:∞}), it is applied to all variables. Under {bf:nonneg}, negative
        values in {bf:upperbound({help numlist:{it:numlist}})} will produce an
        error.{p_end}
{synopt :{opth replace:value(numlist)}}Final replacement value (real or missing
        {bf:.} or {bf:.a-z}) for any cell in the solution matrix that violates
        the bounds specified in {bf:lowerbound({help numlist:{it:numlist}})}
        and {bf:upperbound({help numlist:{it:numlist}})} by more than a
        tolerance equal to {bf:tolerance({help real:{it:real}})}.{p_end}

{syntab:Estimation (first step)}
{synopt :{opth r:(#)}}Number of refinement iterations for the
        pseudoinverse-based estimator {bf:z-hat} (default {bf:1}).{p_end}
{synopt :{opth z:(name)}}A symmetric idempotent matrix (projector) defining
        the subspace for Bott-Duffin pseudoinversion. By default, the identity
        matrix is used, reducing the Bott-Duffin inverse to the Moore-Penrose
        case.{p_end}
{synopt :{opth rcond:(real)}}Regularization parameter for the Moore-Penrose
        and Bott-Duffin inverses, providing numerically stable inversion and
        ensuring convergence of singular values. If {bf:-1}, an automatic
        tolerance equal to {bf:tolerance({help real:{it:real}})} is
        applied. If set to a {bf:positive number} in ({bf:0}, {bf:1}),
        it specifies the relative cutoff below which small singular values are
        treated as zero (default {bf:0}, i.e. no regularization).{p_end}
{synopt :{opth tol:erance(real)}}Convergence tolerance for NRMSE change
        between refinement iterations. If {bf:-1}, an automatic tolerance
        equal to the {it:square root of machine epsilon} is applied. If set to
        a {bf:non-negative number} in [{bf:0}, {bf:1}), it specifies a
        custom tolerance for the estimator (default {bf:-1}).{p_end}
{synopt :{opth iter:ationlimit(#)}}Maximum number of iterations allowed in the
        refinement loop (default {bf:50}).{p_end}

{syntab:Estimation (second step)}
{synopt :{opt nofinal}}Suppress the second step, a convex programming problem
        solved to refine {bf:z-hat}. The resulting solution {bf:z}^* minimizes
        a weighted L1/L2 norm around {bf:z-hat} subject to {bf:A}{bf:z} =
        {bf:b}.{p_end}
{synopt :{opth alpha:(real)}}Regularization parameter (weight) in the final
        convex program: {bf:α} = {bf:0} - Lasso (L1 norm), {bf:α} = {bf:1} -
        Tikhonov Regularization/Ridge (L2 norm), or {bf:0} < {bf:α} < {bf:1}
        - Elastic Net. If {bf:-1}, {bf:α} is chosen, based on an error
        rule: {bf:α} = min({bf:1.0}, NRMSE_{{bf:α} = {bf:0}} / (NRMSE_{{bf:α}
        = {bf:0}} + NRMSE_{{bf:α} = {bf:1}} +
        {bf:tolerance({help real:{it:real}})})). If a
        {help numlist:{it:numlist}}, with each value in [{bf:0}, {bf:1}], is
        provided, each candidate is evaluated via a full solve, and the {bf:α}
        with the smallest NRMSE is selected (default {bf:-1}).{p_end}
{synopt :{opth cvx:opt(string asis)}}Python keyword arguments passed to the
        CVXPY solver in {bf:pylppinv}.{p_end}

{syntab:Other}
{synopt :{opt miss:ingokay}}Treat Stata missing values {bf:.} and {bf:.a-z} as
        observations and forward them to {bf:pylppinv} as {cmd:numpy.nan}. For
        example, when at least two of {bf:bub({help strings:{it:string}})},
        {bf:beq({help strings:{it:string}})},
        {bf:aub({help strings:{it:string}})}, and
        {bf:aeq({help strings:{it:string}})} are sourced from the dataset
        and do not share the same number of rows.{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
{help varname} and {help varlist} in {bf:bub({help strings:{it:string}})},
{bf:beq({help strings:{it:string}})},
{bf:aub({help strings:{it:string}})}, and
{bf:aeq({help strings:{it:string}})} may not contain time-series operators
or factor variables and are filtered by {ifin} with missing values being
excluded by default; see {help tsvarlist} and {help fvvarlist}.{p_end}
{p 4 6 2}
{opt by}, {opt collect}, {opt fp}, {opt rolling}, {opt statsby}, and {cmd:xi}
are allowed; see {help prefix}.{p_end}
{marker weight}{...}
{p 4 6 2}
{cmd:weight}s are not allowed; see {help weight}.
{p_end}
{p 4 6 2}
See {ul:{bf:Postestimation}} for features available after estimation.{p_end}

{marker description}{...}
{title:Description} 

{pstd}
{cmd:lppinv} implements the
{bf:Convex Least Squares Programming (CLSP) estimator}, a modular two-step
convex optimization framework, capable of addressing ill-posed and
underdetermined problems. After reformulating a problem in its canonical form,
{bf:A}{bf:z} = {bf:b} -- where {bf:A}^(r) = [{bf:C}, {bf:S}\
{bf:M}^(r), {bf:Q}^(r)], {bf:C} - constraints matrix, {bf:S} - sign slack
matrix, {bf:M}^(r) - model matrix, and {bf:Q}^(r) - zero matrix or reverse-sign
slack matrix for residuals -- Step 1 yields an iterated (if r > 1) minimum-norm
least-squares estimate {bf:zhat} = ({bf:A}_Z^†){bf:b} on a constrained subspace
defined by a symmetric idempotent {bf:Z} (reducing to the Moore-Penrose
pseudoinverse when {bf:Z} = {bf:I}) -- where ({bf:A}_Z^†)^(r) =
(({bf:Z}({bf:A}^(r))^{c TT}{bf:A}^(r){bf:Z})^†){bf:Z}({bf:A}^(r))^{c TT} is the
Bott-Duffin inverse with a left projector {bf:P}_Z^L (reduced to
({bf:A}^†)^(r) = ((({bf:A}^(r))^{c TT}{bf:A}^(r))^†)({bf:A}^(r))^{c TT} when
{bf:Z} = {bf:I}). The optional Step 2 corrects {bf:zhat} by solving a convex
program, which penalizes deviations using a Lasso/Ridge/Elastic Net-inspired
scheme parameterized by {bf:α} ∈ [{bf:0}, {bf:1}] and yields {bf:z}^*. The
second step guarantees a unique solution for {bf:α} ∈ ({bf:0}, {bf:1}] and
coincides with the Minimum-Norm BLUE (MNBLUE) when {bf:α} = {bf:1}.

{pstd}
{bf:Numerical stability of {bf:A}:}

{pstd}
For general cases, the conditioning of {bf:A} -- with respect to the problem
constraints (i.e., rows) in [{bf:C}, {bf:S}] -- is analyzed from the point of
view of its sensitivity to (a) iterations in Step 1 (using a decomposition
derived from the inequality kappa({bf:A}) ≤ kappa({bf:B}) kappa([{bf:C},
{bf:S}]), where {bf:B} is ({bf:A}^(r))^†[{bf:C}, {bf:S}], the variable part of
{bf:A} in terms of iterations), and (b) dropping a single row in [{bf:C},
{bf:S}]. To assess the angular alignment of rows in [{bf:C}, {bf:S}] as
vectors, a cosine-based mean root square alignment (RMSA) is constructed, with
values close to ±1 indicating near-collinearity and potential ill-conditioning
and values near 0 implying near-orthogonality and improved numerical stability
(RMSA can be calculated for both [{bf:C}, {bf:S}] and [{bf:C}, {bf:S}] reduced
by one row accompanied by changes in conditioning and solutions).

{pstd}
{bf:Goodness of fit:}

{pstd}
The CLSP estimator employs goodness-of-fit statistics robust to the (potential)
underdeterminedness of solved problems: partial R^2 (i.e., the adaptation of
R^2 to the CLSP structure, where the term "partial" stands for statistics
related to the subvector {bf:x}^* in {bf:z}^*, corresponding to the columns of
{bf:C} and {bf:M}, as opposed to {bf:y}^*  in {bf:z}^*, corresponding to the
columns of {bf:S} and {bf:Q}), normalized RMSE (NRMSE), t-test for the mean of
the NRMSE -- with the sample generated via bootstrap resampling of residuals
(quicker) or from repeated reestimations based on randomly generated {bf:b}
(more precise, Monte Carlo simulation) -- and a diagnostic interval derived
from the condition number of {bf:A} and the norms of residuals and {bf:b}
(constructed from the condition number inequality, where the residuals are
assumed to be the perturbation, and perturbation for each value of {bf:z}^* is
considered to be uniform).

{marker postestimation}{...}
{title:Postestimation}

{pstd}
For total RMSA and sensitivity of [{bf:C}, {bf:S}] to dropping one row:
{break}
{cmdab:. lppinv estat corr}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opt reset:}}Force recomputation of all diagnostic values instead of
        replaying previously stored results.{p_end}
{synopt :{opth thresh:old(real)}}If positive, limits the output to constraints
        with {bf:e(rmsa_i)} ≥ {bf:threshold({help real:{it:real}})}.{p_end}
{synopt :{opt bar}}Display a vertical bar chart for {bf:e(rmsa_i)} or for the
        stored result named in {bf:matrix({help strings:{it:string}})}. If the
        stored result is a matrix, a panel of bar charts is produced, with the
        number of columns controlled by {bf:ncols({help #:{it:#}})}. Mutually
        exclusive with {bf:hbar}.{p_end}
{synopt :{opt hbar}}Display a horizontal bar chart for {bf:e(rmsa_i)} or for
        the stored result named in {bf:matrix({help strings:{it:string}})}. If
        the stored result is a matrix, a panel of horizontal bar charts is
        produced, with the number of columns controlled by
        {bf:ncols({help #:{it:#}})}. Mutually exclusive with {bf:bar}.{p_end}
{synopt :{opth mat:rix(string)}}Stored result in e() to graph
        (default {bf:rmsa_i}). Requires {bf:bar} or {bf:hbar}.{p_end}
{synopt :{opth ncol:s(#)}}Number of columns in the graph panel when plotting
        a matrix (default {bf:1}). Requires {bf:bar} or {bf:hbar}.{p_end}

{synoptline}
{p2colreset}{...}

{pstd}
For the bootstrap/Monte Carlo t-test for the mean of NRMSE:
{break}
{cmdab:. lppinv estat ttest}
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opt reset:}}Force a new generation of the t-test sample instead of
        replaying previously stored results.{p_end}
{synopt :{opth sample:size(#)}}Size of the Monte Carlo simulated sample under
        H0 (default {bf:50}).{p_end}
{synopt :{opth seed:(#)}}Optional random seed to override the default
        (default {bf:123456789}). Requires {bf:simulate}.{p_end}
{synopt :{opth dist:ribution(string)}}Distribution for generating synthetic
        {bf:b} vectors. One of: {bf:normal}, {bf:uniform}, or {bf:laplace}
        (default {bf:normal}). Requires {bf:simulate}.{p_end}
{synopt :{opt part:ial}}Run the t-test on the partial NRMSE: during
        simulation, the entries in {bf:C} are preserved and the entries in
        {bf:M} are simulated.{p_end}
{synopt :{opt sim:ulate}}Perform a parametric Monte Carlo simulation by
        generating synthetic right-hand side vectors {bf:b}. Otherwise, execute
        a nonparametric bootstrap procedure on residuals without
        re-estimation.{p_end}
{synopt:{opth l:evel(#)}}Set confidence level (default {bf:95}){p_end}

{synoptline}
{p2colreset}{...}

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:lppinv} requires an executable of a Python 3 installation
(Python 3.10 or higher) set with the help of {cmd:python set exec} command!
{break}For Python users, there is a standalone Python implementation {browse "https://pypi.org/project/pylppinv/"} with the same functionality.
{break}Likewise, for R users, there is an R equivalent {browse "https://cran.r-project.org/web/packages/rlppinv/"}.

{pstd}
For a pure Stata alternative, with reduced second step functionality, consult
{helpb lppinvl2}.

{pstd}
For detailed information on {cmd:python set exec}, consult {helpb python}.

{marker examples}{...}
{title:Examples}

        * LPRLS/QPRLS, based on an underdetermined and potentially infeasible
        * problem
        {cmd:. clear}
        {cmd:. local seed = 123456789}
        {cmd:. set   seed  `seed'}

        * sample (dataset)
        {cmd:. mata: A_ub = rnormal(50, 500, 0, 1)}
        {cmd:. mata: st_matrix("A_ub", A_ub)}
        {cmd:. mata: A_eq = rnormal(25, 500, 0, 1)}
        {cmd:. mata: st_matrix("A_eq", A_eq)}
        {cmd:. mata: b_ub = rnormal(50,   1, 0, 1)}
        {cmd:. mata: st_matrix("b_ub", b_ub)}
        {cmd:. mata: b_eq = rnormal(25,   1, 0, 1)}
        {cmd:. mata: st_matrix("b_eq", b_eq)}
        {cmd:. quiet lppinv free, aub(A_ub) aeq(A_eq) bub(b_ub) beq(b_eq) r(1) alpha(1.0)}

        * results
        {cmd:. display "x hat (x_M hat):"}
        {cmd:. matlist e(x), format(%9.4f)}
        {cmd:. estat ttest, samplesize(30) seed(`seed') distribution(normal)}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:lppinv} stores the following in {cmd:e()}:
{break}(developers may be interested in {cmd:. ereturn list, all})

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(r)}}number of refinement iterations performed in the first step
       {p_end}
{synopt:{cmd:e(tolerance)}}convergence tolerance for NRMSE change between
       refinement iterations{p_end}
{synopt:{cmd:e(alpha)}}regularization parameter (weight) in the final convex
       program{p_end}
{synopt:{cmd:e(kappaC)}}spectral kappa() for [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:e(kappaB)}}spectral kappa() for {bf:B} = {bf:A}^†[{bf:C},
       {bf:S}]{p_end}
{synopt:{cmd:e(kappaA)}}spectral κ() for {bf:A}{p_end}
{synopt:{cmd:e(r2_partial)}}R^2 for {bf:M} in {bf:A}{p_end}
{synopt:{cmd:e(nrmse)}}mean square error calculated from {bf:A} and normalized
       by standard deviation (NRMSE){p_end}
{synopt:{cmd:e(nrmse_partial)}}mean square error calculated from {bf:M} in
       {bf:A} and normalized by standard deviation (NRMSE){p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lppinv}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(title)}}estimator title{p_end}
{synopt:{cmd:e(final)}}presence of the second step in estimation, {bf:True} or
       {bf:False}{p_end}
{synopt:{cmd:e(seed)}}random seed in the Monte Carlo-based t-test{p_end}
{synopt:{cmd:e(distribution)}}distribution for generating simulated {bf:b}
            vectors in the Monte Carlo-based t-test{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(zhat)}}vector of the first-step estimate{p_end}
{synopt:{cmd:e(z)}}vector of the final solution. If the second step is
       disabled, it equals {bf:zhat}{p_end}
{synopt:{cmd:e(x)}}vector containing the variable component of {bf:z}{p_end}
{synopt:{cmd:e(y)}}vector containing the slack component of {bf:z}{p_end}
{synopt:{cmd:e(z_lower)}}lower bound of the diagnostic interval (confidence
       band) based on kappa({bf:A}) for {bf:z}{p_end}
{synopt:{cmd:e(z_upper)}}upper bound of the diagnostic interval (confidence
       band) based on kappa({bf:A}) for {bf:z}{p_end}
{synopt:{cmd:e(x_lower)}}lower bound of the diagnostic interval (confidence
       band) based on kappa({bf:A}) for {bf:x}{p_end}
{synopt:{cmd:e(x_upper)}}upper bound of the diagnostic interval (confidence
       band) based on kappa({bf:A}) for {bf:x}{p_end}
{synopt:{cmd:e(y_lower)}}lower bound of the diagnostic interval (confidence
       band) based on kappa({bf:A}) for {bf:y}{p_end}
{synopt:{cmd:e(y_upper)}}upper bound of the diagnostic interval (confidence
       band) based on kappa({bf:A}) for {bf:y}{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{pstd}
In addition to the above, the following is stored in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:r(rmsa_i)}}summary statistics for RMSA after dropping one row in
       [{bf:C}, {bf:S}] ({bf:i} indicates each row){p_end}
{synopt:{cmd:r(rmsa_dkappaC)}}summary statistics for changes in {bf:e(kappaC)}
       after dropping one row in [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:r(rmsa_dkappaB)}}summary statistics for changes in {bf:e(kappaB)}
       after dropping one row in [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:r(rmsa_dkappaA)}}summary statistics for changes in {bf:e(kappaA)}
       after dropping one row in [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:r(rmsa_dnrmse)}}summary statistics for changes in {bf:e(nrmse)}
       after dropping one row in [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:r(rmsa_dzhat)}}summary statistics for changes in {bf:e(zhat)}
       after dropping one row in [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:r(rmsa_dz)}}summary statistics for changes in {bf:e(z)}
       after dropping one row in [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:r(rmsa_dx)}}summary statistics for changes in {bf:e(x)}
       after dropping one row in [{bf:C}, {bf:S}]{p_end}
{synopt:{cmd:r(z_lower)}}summary statistics for the lower bound of the
       diagnostic interval (confidence band) based on kappa({bf:A}) for
       {bf:z}{p_end}
{synopt:{cmd:r(z_upper)}}summary statistics for the upper bound of the
       diagnostic interval (confidence band) based on kappa({bf:A}) for
       {bf:z}{p_end}
{synopt:{cmd:r(x_lower)}}summary statistics for the lower bound of the
       diagnostic interval (confidence band) based on kappa({bf:A}) for
       {bf:x}{p_end}
{synopt:{cmd:r(x_upper)}}summary statistics for the upper bound of the
       diagnostic interval (confidence band) based on kappa({bf:A}) for
       {bf:x}{p_end}
{synopt:{cmd:r(y_lower)}}summary statistics for the lower bound of the
       diagnostic interval (confidence band) based on kappa({bf:A}) for
       {bf:y}{p_end}
{synopt:{cmd:r(y_upper)}}summary statistics for the upper bound of the
       diagnostic interval (confidence band) based on kappa({bf:A}) for
       {bf:y}{p_end}
{p2colreset}{...}

{pstd}
Note that results stored in r() are updated when the command is replayed and
will be replaced when any r-class command is run after the estimation command,
including {cmd:estat corr} and {cmd:estat ttest}.

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
    Thanks for citing this software and my works on the topic:

{p 8 8 2}
    Bolotov, I. (2025). CLSP: Linear Algebra Foundations of a Modular Two-Step
    Convex Optimization-Based Estimator for Ill-Posed Problems. Mathematics,
    13, 3476. Available from {browse "https://doi.org/10.3390/math13213476"}.
