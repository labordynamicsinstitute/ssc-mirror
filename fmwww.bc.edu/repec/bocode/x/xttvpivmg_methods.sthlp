{smcl}
{* *! version 1.0.0  19aug2026}{...}
{vieweralsosee "xttvpivmg" "help xttvpivmg"}{...}
{vieweralsosee "xttvpivmg postestimation" "help xttvpivmg_postestimation"}{...}
{viewerjumpto "Model" "xttvpivmg_methods##model"}{...}
{viewerjumpto "Assumptions" "xttvpivmg_methods##assump"}{...}
{viewerjumpto "The estimator" "xttvpivmg_methods##est"}{...}
{viewerjumpto "Asymptotic theory" "xttvpivmg_methods##theory"}{...}
{viewerjumpto "Bandwidth selection" "xttvpivmg_methods##bw"}{...}
{viewerjumpto "Step-to-equation map" "xttvpivmg_methods##map"}{...}
{viewerjumpto "Faithfulness notes" "xttvpivmg_methods##faith"}{...}
{viewerjumpto "Departures and open choices" "xttvpivmg_methods##choices"}{...}
{viewerjumpto "Validation" "xttvpivmg_methods##valid"}{...}
{viewerjumpto "References" "xttvpivmg_methods##refs"}{...}

{title:Title}

{phang}
{bf:xttvpivmg methods} {hline 2} Methods and formulas for the TVP-IV-MG estimator


{pstd}
This page documents the econometrics behind {helpb xttvpivmg} and maps every block
of the implementation onto a numbered result in

{pmore}
Bai, Y., M. Marcellino and G. Kapetanios (2026), "Mean group instrumental variable
estimation of time-varying large heterogeneous panels with endogenous regressors",
{it:Econometrics and Statistics} 37, 26-41 {hline 2} referred to below as {bf:BMK}.

{pstd}
Notation follows the paper. Equation numbers in parentheses are BMK's own.


{marker model}{title:Model}

{pstd}
For i = 1,...,N and t = 1,...,T,

{p 8 8 2}{bf:y_it = x_it' b_it + u_it}{space 20}(1){p_end}
{p 8 8 2}{bf:x_it = P_it' z_it + v_it}{space 19}(2){p_end}

{pstd}
with x_it a k x 1 vector of regressors (one element being a constant), z_it a
p x 1 vector of instruments with p >= k, P_it the p x k first-stage coefficient
matrix, and v_it a k x 1 error vector. The regressors are correlated with u_it;
the instruments are not, but are correlated with x_it.

{pstd}
The coefficients follow the random-coefficient decomposition (13):

{p 8 8 2}{bf:b_it = b0(t) + e_it}{space 24}(13){p_end}

{pstd}
where b0(t) = E(b_it) is a deterministic sequence of cross-sectional mean
coefficients {hline 2} the {bf:estimand} {hline 2} and e_it is a mean-zero random
deviation. Both components are restricted only by smoothness, not by any
parametric form.

{pstd}
This nests the standard random-coefficient panel model of Hsiao and Pesaran (2008)
as the special case b0(t) = b0, e_it = e_i (Remark 2), and extends Chen and Huang
(2018) by allowing both cross-sectional heterogeneity and endogenous regressors.


{marker assump}{title:Assumptions}

{p2colset 8 24 26 2}{...}
{p2col :{bf:2.1}}Moment bounds of order theta > 8 on x, u, z, v; strong mixing with
geometrically decaying coefficients; the matrix Szz(t) = E(z_it z_it') has
uniformly bounded inverse. Serial correlation and conditional heteroskedasticity of
unknown form are permitted.{p_end}
{p2col :{bf:2.2}}{bf:Cross-sectional independence} of (x_i, z_i, u_i, v_i, e_i, P_i)
across i. This is the binding restriction: there is no common-factor or CCE variant
of this estimator.{p_end}
{p2col :{bf:2.3}}Elements of P_it satisfy a Holder smoothness condition with
exponent g1 and have thin-tailed distributions.{p_end}
{p2col :{bf:2.4}}(i) b0(t) is deterministic; (ii) b0(t) is Holder continuous with
exponent g2, i.e. b0(t) = g(t/T) for a Holder-g2 function g; (iii) the random part
e_it is smooth with exponent g3 and thin-tailed. Condition (ii) is strictly weaker
than the twice-differentiability required by Chen and Huang (2018), which is the
case g2 = 1.{p_end}
{p2col :{bf:2.5}}E(u_it|z_it) = 0 and E(v_it|z_it) = 0; the matrix
P_it' Szz(t) P_it has uniformly bounded inverse (identification / rank).{p_end}
{p2col :{bf:2.6}}H = o(L / (log T)^max(1,2/a)) and L = o(T^g1). Note the ordering:
{bf:H must be of smaller order than L}. See {help xttvpivmg_methods##choices:open
choice 4}.{p_end}
{p2colreset}{...}

{pstd}
The scaled random walk X(t) = xi(t)/sqrt(t), with xi a random walk with N(0,1)
innovations, satisfies 2.3 and 2.4 with g = 1/2. This is the class used in BMK's
Monte Carlo and it is what {bf:xttvpivmg_example.do} simulates.


{marker est}{title:The estimator}

{pstd}
{bf:Kernel weights} (5). With bandwidths H (second stage) and L (first stage),

{p 8 8 2}{bf:b_j,t(H) = K(|j-t|/H)}{space 4}and{space 4}{bf:b_j,t(L) = K(|j-t|/L)}{space 8}(5){p_end}

{pstd}
K(.) is non-negative and continuous, with bounded or unbounded support, satisfying
the tail condition (7): |K(x)| <= C(1+x^v)^(-1) with v >= 2. Implemented kernels:

{p2colset 8 34 36 2}{...}
{p2col :{bf:Gaussian}}K(x) = exp(-x^2/2){p_end}
{p2col :{bf:Epanechnikov}}K(x) = 0.75(1-x^2) I{c 123}|x|<=1{c 125}{p_end}
{p2col :{bf:rectangle / uniform}}K(x) = 0.5 I{c 123}|x|<=1{c 125}{p_end}
{p2col :{bf:exponential}}K(x) = exp(-c x^a), c > 0, a > 0{p_end}
{p2colreset}{...}

{pstd}
The estimator is a ratio of two kernel-weighted sums, so any multiplicative
constant in K cancels exactly. The 0.5 and 0.75 above are therefore numerically
irrelevant and are retained only for fidelity to the paper's definitions.

{pstd}
Both bandwidths must satisfy (6): c1*T^(1/(theta/4-1)+d) <= H, L <= c2*T^(1-d).

{pstd}
{bf:First stage} (4). For each unit i and each evaluation point t, a
kernel-weighted local-constant projection of x on z:

{p 8 8 2}{bf:Phat_it = [ sum_j b_j,t(L) z_ij z_ij' ]^(-1) [ sum_j b_j,t(L) z_ij x_ij' ]}{space 6}(4){p_end}

{pstd}
This is a p x p solve followed by a p x k multiply, repeated for every (i,t).

{pstd}
{bf:Second stage} (3). The time-varying IV estimator for unit i at date t:

{p 8 8 2}{bf:bhat^IV_it = [ sum_j b_j,t(H) Phat_ij' z_ij x_ij' ]^(-1) [ sum_j b_j,t(H) Phat_ij' z_ij y_ij ]}{space 3}(3){p_end}

{pstd}
{bf:Mean group} (8). The estimator of the cross-sectional mean path:

{p 8 8 2}{bf:bhat_MG(t) = (1/N) sum_i bhat^IV_it}{space 20}(8){p_end}

{pstd}
which generalises the OLS-type mean-group estimator of Pesaran and Smith (1995)
from a constant mean coefficient to a time-varying mean path.

{pstd}
{bf:Exogenous regressors and dynamics} (Remark 4). Weakly exogenous regressors g_it
satisfying E(u_it|g_it) = 0 are accommodated by augmenting the instrument block
rather than the instrument list:

{p 8 8 2}{bf:bhat^IV_it = [ sum_j b_j,t(H) [Phat_ij'z_ij : g_ij] x_ij' ]^(-1) [ sum_j b_j,t(H) [Phat_ij'z_ij : g_ij] y_ij ]}{p_end}

{pstd}
This is what admits dynamic panel models with y_i,t-1 as a regressor, following
Hsiao, Pesaran and Tahmiscioglu (1999).

{pstd}
{bf:Fixed effects} (Remark 1). Two equivalent treatments. (a) Set x_1,it = 1; then
b_1,it is itself a time-varying fixed effect. (b) Write y_it = a_i + x_it'b_it +
u_it (or a_it), regress y and x separately on a constant, and run the model on the
residuals. The pre-step may be time-invariant or itself kernel-smoothed, and BMK
show it does not affect the asymptotic analysis.


{marker theory}{title:Asymptotic theory (Theorem 1)}

{pstd}
Define r(T,H,g) = (H/T)^g + sqrt(log T / H) and
r(T,H,g,a) = sqrt(log T / H) + (H/T)^g (log T)^(1/a)  {space 2}(16).

{pstd}
{bf:(i) Uniform consistency.} As (N,T) -> infinity,

{p 8 8 2}max_t ||bhat_MG(t) - b0(t)|| = Op( r(T,L,g1,a) + (log T)^(1/a) r(T,H,g2) / sqrt(N)
+ (log T)^(1/a) (H/T)^g3 / sqrt(N) + (log T)^(2/a) / sqrt(N) ).{p_end}

{pstd}
{bf:(ii) Pointwise asymptotic normality.} If (H/T)^g2 = o(N^(-1/2)), then for
t = floor(Tr) with 0 < r < 1,

{p 8 8 2}{bf:sqrt(N) Sigma_e(t)^(-1/2) ( bhat_MG(t) - b0(t) ) -> N(0, I_k)}{p_end}

{pstd}
where Sigma_e(t) = lim Var( (1/sqrt(N)) sum_i e_it ), consistently estimated by

{p 8 8 2}{bf:Sigmahat_e(t) = (1/N) sum_i ( bhat^IV_it - bhat_MG(t) )( bhat^IV_it - bhat_MG(t) )'}{space 4}(17){p_end}

{pstd}
{bf:Why the variance is so simple.} Appendix B shows the expansion collapses to

{p 8 8 2}{bf:sqrt(N) ( bhat_MG(t) - b0(t) ) = (1/sqrt(N)) sum_i e_it + op(1)}{p_end}

{pstd}
The kernel-IV sampling error is Op(1/sqrt(NH)) and the smoothing bias is
Op((H/T)^g2); both are dominated by the Op(1/sqrt(N)) heterogeneity term. Hence
{bf:no HAC estimator, no long-run variance and no bootstrap are required} {hline 2}
the standard error is purely the cross-sectional dispersion of the N unit paths,
exactly as in a conventional mean-group estimator.

{pstd}
{bf:Correlated random coefficients.} No dependence assumption between e_it and
x_it is used. The key ingredient is the smoothness condition (15) on e_it, not an
orthogonality condition. So unlike the standard random-coefficient MG estimator,
which is inconsistent when E(e_i|x_it) is non-zero, TVP-IV-MG remains valid. BMK
build this case into their Monte Carlo deliberately.

{pstd}
{bf:The (N,T) regime.} The normality condition (H/T)^g2 = o(N^(-1/2)) means
sqrt(N)/T^(g2(1-h)) -> 0 with H = T^h. With g2 = 1/2 and h = 1/2 this is
sqrt(N)/T^0.25 -> 0: {bf:T must diverge faster than N}. BMK's Tables 1-3 show
coverage rising in T but {it:falling} in N for fixed T, which is this condition
biting.


{marker bw}{title:Bandwidth selection (section 2.3)}

{pstd}
{bf:Rule of thumb.} H = T^h for 0 < h < 1. Giraitis, Kapetanios and Yates (2018)
find h = 1/2 best in finite samples; BMK use H = L = T^0.5 as their benchmark.

{pstd}
{bf:Leave-one-unit-out cross-validation.} Adapted from Sun, Carroll and Li (2009).
Remove unit i and form

{p 8 8 2}{bf:bhat^(-i)_MG(t) = (1/N) sum_{c 123}j != i{c 125} bhat^IV_j(t)}{p_end}

{pstd}
then choose (H,L) to minimise

{p 8 8 2}{bf:sum_i sum_t ( y_it - x_it' bhat^(-i)_MG(t) )^2}{p_end}

{pstd}
The search is over a two-dimensional grid of exponents T^b. BMK's Monte Carlo uses
b in {c 123}0.3,0.4,0.5,0.6,0.7{c 125}; their empirical application uses
b in {c 123}0.30,0.35,...,0.85{c 125} and selects {bf:H = T^0.65, L = T^0.30}.

{pstd}
{bf:Implementation note.} The leave-one-out average requires no re-estimation:
bhat^(-i)_MG(t) = ( sum_j bhat_j(t) - bhat_i(t) ) / N. One estimation pass per
(H,L) pair therefore suffices, followed by N cheap subtractions.


{marker map}{title:Step-to-equation map}

{pstd}
Each row names a block of {bf:xttvpivmg.ado} and the result it implements.

{p2colset 4 34 36 2}{...}
{p2col :{bf:Code}}{bf:Implements}{p_end}
{p2line}
{p2col :{cmd:_tvpiv_kgen()}}kernel K(.) and the tail condition (5), (7){p_end}
{p2col :{cmd:_tvpiv_wt()}}the weights b_j,t = K(|j-t|/bw) for fixed t (5){p_end}
{p2col :{cmd:_tvpiv_unit()} first loop}first stage Phat_it (4){p_end}
{p2col :{space 4}... assignment to {cmd:Xh}}the projection xhat_ij = Phat_ij' z_ij (3), Remark 4{p_end}
{p2col :{cmd:_tvpiv_unit()}, second loop}second stage bhat^IV_it (3){p_end}
{p2col :{cmd:_tvpiv_all()}}loop over units; the {cmd:dmode} branches are Remark 1{p_end}
{p2col :{cmd:_tvpiv_tvdemean()}}Remark 1(b) with a time-varying fixed effect{p_end}
{p2col :{cmd:_tvpiv_mg()}}mean-group average (8){p_end}
{p2col :{cmd:_tvpiv_cvobj()}}leave-one-unit-out CV objective (section 2.3){p_end}
{p2col :variance loop in {cmd:xttvpivmg_work()}}Sigmahat_e(t) and Var(bhat_MG(t)) (17), Thm 1(ii){p_end}
{p2col :trimming block}the interior-point restriction of Thm 1(ii); the window
t = H+1,...,T-H of section 3{p_end}
{p2col :{cmd:xttvpivmg_graph}}Figure 1: path, pointwise band, zero line{p_end}
{p2colreset}{...}


{marker faith}{title:Faithfulness notes}

{pstd}
Points at which a plausible-looking shortcut would {bf:not} reproduce the paper.
Each was checked explicitly against the text and against the independent gretl
implementation {bf:ketvals}.

{phang}
{bf:1. Phat is evaluated at the summation index j, not at t.} Equation (3) reads
Phat_ij' z_ij inside a sum over j. Using Phat_it' z_ij instead {hline 2} the
natural mistake, since t is the evaluation point {hline 2} gives an estimator that
is only asymptotically equivalent and carries finite-sample contamination. The
implementation computes Phat for every j first, then forms the row-wise fitted
values. This matches the {cmd:xfithat} construction in {bf:ketvals}.

{phang}
{bf:2. The second-stage matrix is not symmetric.} A(t) = sum_j b_j,t xhat_ij x_ij'
has xhat on the left and x on the right. It must be inverted with an LU solve;
using a symmetric-matrix routine such as {cmd:invsym()} would silently symmetrise
it and change the estimates. The first-stage Szz {it:is} symmetric and does use
{cmd:invsym()}, which additionally supplies a generalized inverse under benign
collinearity.

{phang}
{bf:3. The kernel constant cancels, the bandwidth does not.} K enters only through
ratios, so scale factors are irrelevant; but H appears inside K(|j-t|/H) and is
therefore fully consequential. The Gaussian kernel is {bf:not} truncated at |j-t|
<= H: it has unbounded support and every observation enters at every date.

{phang}
{bf:4. The estimator is two-sided.} b_j,t(H) uses j both below and above t. These
are smoothed, not filtered, estimates and are not available in real time.

{phang}
{bf:5. The variance divisor is N^2, not N(N-1).} Equation (17) defines Sigmahat_e
with divisor N, and Theorem 1(ii) then divides by N again. The conventional
Pesaran-Smith mean-group variance uses N(N-1). The default here is the paper's;
{cmd:vce(mg)} gives the convention.

{phang}
{bf:6. Trimming is not cosmetic.} Theorem 1(ii) holds at interior points
t = floor(Tr), 0 < r < 1. At the boundary the kernel becomes one-sided and both
bias and variance change. BMK compute all reported statistics on
t = H+1,...,T-H, and so does this command by default.

{phang}
{bf:7. The constant belongs in both x and z.} Equation (1) states that one element
of x_it is a constant, and BMK's empirical instrument set begins with an intercept.
Both are added automatically unless {cmd:noconstant} is given.

{phang}
{bf:8. Exogenous regressors instrument themselves.} Projecting an exogenous
regressor on an instrument set that contains it returns it exactly (the local
weighted regression fits perfectly). Skipping that projection is therefore an exact
algebraic simplification, not an approximation, and is precisely Remark 4.


{marker choices}{title:Departures and open choices}

{pstd}
Places where BMK are silent or internally inconsistent, and what this command does.
None of these is hidden; each is a documented decision.

{phang}
{bf:1. CV summation range.} Section 2.3 writes the objective as a sum over
t = 1,...,T, but every reported statistic in section 3 is computed on the trimmed
interior. Untrimmed cross-validation lets boundary bias drive the bandwidth choice.
{bf:Default:} trim the CV objective too. {bf:Override:} {cmd:nocvtrim}.

{phang}
{bf:2. Leave-one-out divisor.} BMK print (1/N) sum_{c 123}j!=i{c 125}, which sums
N-1 terms but divides by N. Sun, Carroll and Li (2009), from which the procedure is
adapted, use 1/(N-1). {bf:Default:} the paper's 1/N. {bf:Override:}
{cmd:cvdivisor(nminus1)}. In practice this shifts the objective level but seldom
the argmin.

{phang}
{bf:3. Variance divisor.} As in faithfulness note 5. {bf:Default:} {cmd:vce(paper)}.

{phang}
{bf:4. Assumption 2.6 versus the empirical result.} Assumption 2.6 requires
H = o(L/(log T)^max(1,2/a)) {hline 2} H of smaller order than L. The
cross-validation in BMK's own application selects H = T^0.65 against L = T^0.30,
the opposite ordering, and the paper does not remark on it. This command does not
constrain the CV grid to conceal the tension: if CV returns h > l, that is what is
reported. Users writing up CV-selected bandwidths should note the issue.

{phang}
{bf:5. Unbalanced panels and gaps.} BMK are silent; the kernel sums assume a
complete regular rectangle and |j-t| is measured in {it:index} units. This command
requires a balanced, gap-free panel on a regular time grid and errors out otherwise
rather than guessing.

{phang}
{bf:6. Singular unit-date systems.} Not discussed by BMK. This command drops the
offending unit from the mean-group average at that date only, and reports the
count in {cmd:e(nsing)}.

{phang}
{bf:7. Not provided, not invented.} BMK give no test of H0: b0(t) = b0, no uniform
confidence band, no weak-instrument diagnostic, and no CSD-robust variant. None is
supplied here. Per-period Hausman and Sargan statistics exist in Giraitis,
Kapetanios and Marcellino (2021) for the {it:time-series} case and are implemented
in the gretl package {bf:ketvals}, but they are not part of BMK.


{marker valid}{title:Validation}

{pstd}
{bf:Against the paper's own Monte Carlo.} {bf:xttvpivmg_example.do} reproduces
BMK's DGP of section 3: a dynamic panel with a time-varying intercept, a
time-varying autoregressive coefficient, one exogenous and one endogenous
regressor, time-varying endogeneity, and correlated random coefficients. All
time-varying parameters are scaled random walks X(t) = xi(t)/sqrt(t), giving
g1 = g2 = g3 = 1/2. The script checks that the estimated paths track the true
b0(t), that accuracy improves with both N and T, and that CV outperforms the rule
of thumb {hline 2} the paper's central Monte Carlo findings.

{pstd}
{bf:Against an independent implementation.} The N per-unit paths are exactly the
time-series estimator of Giraitis, Kapetanios and Marcellino (2021), implemented
independently in gretl by Valentini and Lucchetti as {bf:ketvals}. Running
{cmd:tv_IV} unit by unit and averaging reproduces {cmd:e(bmg)}. Note that
{bf:ketvals} reports the {it:time-series} sandwich variance
(K2/K^2)(P'Szz P)^(-1)(P'Szu P)(P'Szz P)^(-1), which is a different object from
eq. (17) and should {bf:not} be expected to match {cmd:e(semg)}.

{pstd}
{bf:A caution from the replication literature.} Lucchetti and Valentini (2023)
report that a coding oversight may have affected some results in the original
Giraitis, Kapetanios and Marcellino (2021) paper, while confirming that the
estimator is remarkably robust across kernels and bandwidths. Their paper is worth
reading before relying on any implementation of this family, including this one.


{marker refs}{title:References}

{phang}
Bai, Y., M. Marcellino and G. Kapetanios. 2026. {it:Econometrics and Statistics}
37: 26-41. doi:10.1016/j.ecosta.2023.06.004

{phang}
Chen, B. and L. Huang. 2018. Nonparametric testing for smooth structural changes in
panel data models. {it:Journal of Econometrics} 202(2): 245-267.

{phang}
Dendramis, Y., L. Giraitis and G. Kapetanios. 2021. {it:Econometric Theory} 37(6):
1100-1134.

{phang}
Giraitis, L., G. Kapetanios and M. Marcellino. 2021. {it:Journal of Econometrics}
224(2): 394-415. doi:10.1016/j.jeconom.2020.08.013

{phang}
Giraitis, L., G. Kapetanios and T. Yates. 2014. {it:Journal of Econometrics}
179(1): 46-65.

{phang}
Giraitis, L., G. Kapetanios and T. Yates. 2018. {it:Journal of Time Series
Analysis} 39(2): 129-149.

{phang}
Hsiao, C. and M. H. Pesaran. 2008. Random coefficient models. In {it:The
Econometrics of Panel Data}, 185-213. Springer.

{phang}
Hsiao, C., M. H. Pesaran and A. K. Tahmiscioglu. 1999. Bayes estimation of
short-run coefficients in dynamic panel data models. In {it:Analysis of Panel Data
and Limited Dependent Variable Models}, 268-296. Cambridge University Press.

{phang}
Lucchetti, R. and F. Valentini. 2023. {it:Empirical Economics} 65(6): 3001-3026.
doi:10.1007/s00181-023-02450-6

{phang}
Pesaran, M. H. and R. Smith. 1995. {it:Journal of Econometrics} 68(1): 79-113.

{phang}
Sun, Y., R. J. Carroll and D. Li. 2009. {it:Advances in Econometrics} 25: 101-129.
doi:10.1108/S0731-9053(2009)0000025006


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}


{title:Also see}

{psee}
{help xttvpivmg:xttvpivmg}, {help xttvpivmg_postestimation:xttvpivmg postestimation}
{p_end}
