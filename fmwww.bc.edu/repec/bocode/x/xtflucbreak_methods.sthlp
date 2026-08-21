{smcl}
{* *! xtflucbreak 1.0.0  07aug2026}{...}
{vieweralsosee "xtflucbreak" "help xtflucbreak"}{...}
{vieweralsosee "xtflucbreak postestimation" "help xtflucbreak_postestimation"}{...}
{vieweralsosee "xtbfkbreak" "help xtbfkbreak"}{...}
{viewerjumpto "The model" "xtflucbreak_methods##model"}{...}
{viewerjumpto "Section 3: no common factors" "xtflucbreak_methods##sec3"}{...}
{viewerjumpto "Section 4: common correlated effects" "xtflucbreak_methods##sec4"}{...}
{viewerjumpto "Critical values" "xtflucbreak_methods##cv"}{...}
{viewerjumpto "The change-point estimator" "xtflucbreak_methods##khat"}{...}
{viewerjumpto "Step-to-equation map" "xtflucbreak_methods##map"}{...}
{viewerjumpto "Departures from the printed paper" "xtflucbreak_methods##departures"}{...}
{viewerjumpto "Implementation choices" "xtflucbreak_methods##choices"}{...}
{viewerjumpto "The benchmark tests" "xtflucbreak_methods##bench"}{...}
{viewerjumpto "Author" "xtflucbreak_methods##author"}{...}
{title:Title}

{phang}
{bf:xtflucbreak methods} {hline 2} equation-by-equation derivation of the fluctuation test
and the exact correspondence with Li, Xiao and Chen (2024)


{marker model}{title:The model and the hypotheses}

{pstd}
The heterogeneous panel regression (LXC eq. 1, p.1185) is

{p 12 12 2}
y{sub:it} = x{sub:it}'{&beta}{sub:i} + e{sub:it},
{space 4}e{sub:it} = {&gamma}{sub:i}'f{sub:t} + {&epsilon}{sub:it},
{space 4}x{sub:it} = {&Gamma}{sub:i}'f{sub:t} + v{sub:it},

{pstd}
with x{sub:it} of dimension K{&times}1, f{sub:t} an unobserved m{&times}1 factor, and
{&beta}{sub:i} = {&beta} + v{sub:{&beta},i}, v{sub:{&beta},i} ~ IID(0, {&Sigma}{sub:{&beta}})
(Assumption 3.3 / 4.7: a random-coefficient model). If the slopes change at an unknown
k{sub:0},

{p 12 12 2}
y{sub:it} = x{sub:it}'({&beta}{sub:i} + {&delta}{sub:i}{c 183}1{c 123}t > k{sub:0}{c 125}) + e{sub:it}.

{pstd}
H{sub:0}: {&delta}{sub:i} = 0 for all i.
H{sub:A}: {&delta}{sub:i} {&ne} 0 for i {&isin} {&Pi}, with |{&Pi}|/N {&rarr} c {&isin} (0,1].
The last condition is the panel-unit-root convention of Choi (2001) and
Im-Pesaran-Shin (2003): the break need not be in every panel, but it must be in a
non-vanishing fraction of them.

{pstd}
{bf:Timing.} The paper's displayed model writes 1{c 123}t {&ge} k{sub:0}{c 125}, but
H{sub:A} states {&delta}{sub:i} = 0 for t = 1,...,k{sub:0} and {&delta}{sub:i} {&ne} 0 for
t = k{sub:0}+1,...,T, and the post-break design matrix on p.1189 is
X{sub:1i}(T) = (0,...,0, x{sub:i,k0+1},...,x{sub:iT})'. The operative convention is
therefore 1{c 123}t > k{sub:0}{c 125}: {bf:k{sub:0} is the last pre-break period}.
{cmd:r(breakdate)} reports that period and {cmd:r(breakpost)} the first post-break one.
The paper's own application is consistent with this reading: on 1996-2020 data it dates
the break at 2008 and attributes it to policies enacted after the 2008 crisis.


{marker sec3}{title:Section 3: no common correlated effects}

{pstd}
Set {&gamma}{sub:i} = 0, {&Gamma}{sub:i} = 0. Per-panel OLS on the full sample and on the
first k observations (LXC eq. 2 and the display below it, p.1187):

{p 12 12 2}
{&beta}hat{sub:i} = (X{sub:i}'X{sub:i}){sup:-1}X{sub:i}'Y{sub:i},
{space 6}{&beta}hat{sub:i}(k) = (X{sub:i}(k)'X{sub:i}(k)){sup:-1}X{sub:i}(k)'Y{sub:i}(k).

{pstd}
With Qhat{sub:i} = X{sub:i}'X{sub:i}/T and
sigmahat{sub:i}{sup:2} = (1/T){&Sigma}{sub:t}(ehat{sub:it} - ebar{sub:i}){sup:2}
computed from the full-sample residuals, the fluctuation process is

{p 12 12 2}
S(k) = N{sup:-1/2} {&Sigma}{sub:i} (1/sigmahat{sub:i})(k/{&radic}T){c 183}Qhat{sub:i}{sup:1/2}({&beta}hat{sub:i}(k) - {&beta}hat{sub:i}).

{pstd}
{bf:Why this is a bridge.} Substituting the OLS formulas,
Qhat{sub:i}{sup:1/2}(X{sub:i}(k)'X{sub:i}(k)){sup:-1} {&asymp} (1/k)Qhat{sub:i}{sup:-1/2},
so

{p 12 12 2}
(k/{&radic}T){c 183}Qhat{sub:i}{sup:1/2}({&beta}hat{sub:i}(k) - {&beta}hat{sub:i})
{&asymp} T{sup:-1/2}Qhat{sub:i}{sup:-1/2}{&Sigma}{sub:t{&le}k}x{sub:it}e{sub:it}
- (k/T){c 183}T{sup:-1/2}Qhat{sub:i}{sup:-1/2}{&Sigma}{sub:t{&le}T}x{sub:it}e{sub:it}.

{pstd}
By the functional CLT of Assumptions 3.1-3.2 the first term is W{sub:i}(s) with
s = k/T and the second is sW{sub:i}(1), so the difference is a Brownian bridge
B{sub:i}(s). Dividing by sigmahat{sub:i} standardises the variance
{&Omega} = E(x{sub:it}x{sub:it}'{&epsilon}{sub:it}{sup:2}) = {&sigma}{sub:i}{sup:2}Q{sub:i}
to the identity, so B{sub:i} is a {it:standard} K-dimensional bridge. Averaging over i
with the N{sup:-1/2} normalisation and a second CLT across panels (LXC Appendix, p.1205)
gives Theorem 3.4:

{p 12 12 2}
max{sub:1<k<T} S(k) {&rArr} sup{sub:0{&le}s{&le}1} B(s).

{pstd}
Note the algebraic point: the paper writes Qhat{sub:i}{sup:1/2}, not
Qhat{sub:i}{sup:-1/2}. That is correct, because it multiplies a matrix that already
contains the inverse (X{sub:i}(k)'X{sub:i}(k)){sup:-1}; the net standardiser is
Qhat{sub:i}{sup:-1/2}, as the display above shows. The code applies the paper's form
literally.


{marker sec4}{title:Section 4: common correlated effects}

{pstd}
When {&gamma}{sub:i} {&ne} 0 and {&Gamma}{sub:i} {&ne} 0, per-panel OLS is inconsistent.
Stack w{sub:it} = (y{sub:it}, x{sub:it}')' and take cross-section averages. Because
w{sub:it} = C{sub:i}'f{sub:t} + z{sub:it} with C{sub:i} = ({&gamma}{sub:i}, {&Gamma}{sub:i})
{c 183} [1, 0; {&beta}{sub:i}, I{sub:K}], Baltagi-Feng-Kao (2016) show that under
Assumption 4.4 (rank Cbar = m {&le} K+1)

{p 12 12 2}
f{sub:t} - (CbarCbar'){sup:-1}Cbar wbar{sub:t} {&rarr}{sub:p} 0.

{pstd}
Hence wbar{sub:t} spans the factor space asymptotically and

{p 12 12 2}
M{sub:w} = I{sub:T} - Wbar(Wbar'Wbar){sup:-1}Wbar',
{space 4}Wbar = (wbar{sub:1},...,wbar{sub:T})',

{pstd}
annihilates it up to O{sub:p}(N{sup:-1/2}). The whole section-3 construction is then
repeated on Ytil{sub:i} = M{sub:w}Y{sub:i}, Xtil{sub:i} = M{sub:w}X{sub:i} (LXC eq. 4), with
Qchk{sub:i} = Xtil{sub:i}'Xtil{sub:i}/T. Theorem 4.8 gives the same Brownian-bridge limit
provided {&radic}T/N {&rarr} 0 -- the rate at which the factor-estimation error must vanish
relative to the T{sup:1/2} scaling of the fluctuation process. {cmd:xtflucbreak} prints
{&radic}T/N in the header and warns when it exceeds 0.15.

{pstd}
{bf:The intercept.} Under M{sub:w} a constant column of X{sub:i} would be annihilated,
producing an exactly singular Xtil{sub:i}'Xtil{sub:i}. So in the CCE branch the intercept
is absorbed rather than tested, and K equals the number of listed regressors. This matches
the paper's own Model 2, whose DGP has {&alpha}{sub:i} in the equation but
x{sub:it} = {&Gamma}{sub:i}'f{sub:t} + v{sub:it} with no constant column and K = 2.


{marker cv}{title:Critical values}

{pstd}
Remark 3.5 rejects H{sub:0} when, for some component j,

{p 12 12 2}
max{sub:1<k<T}|S(k){sup:(j)}| {&ge} C{sub:1}({&alpha}*),
{space 4}{&alpha}* = 1 - (1-{&alpha}){sup:1/K},

{pstd}
where C{sub:1} inverts

{p 12 12 2}
P(sup{sub:0{&le}u{&le}1}|B(u)| {&ge} x) = {&Sigma}{sub:k{&ne}0}(-1){sup:k+1}exp(-2k{sup:2}x{sup:2})
= 2{&Sigma}{sub:k{&ge}1}(-1){sup:k+1}exp(-2k{sup:2}x{sup:2}).

{pstd}
This is the {bf:Kolmogorov} distribution -- the same law as the one-sample
Kolmogorov-Smirnov statistic. {&alpha}* is the Sidak (not Bonferroni) correction: if the K
component tests were independent, controlling each at {&alpha}* controls the family at
exactly {&alpha}. The paper's worked value is reproduced: at {&alpha} = 0.05 and K = 2,
{&alpha}* = 0.025321 and C{sub:1} = 1.4781 (the paper prints 1.4782).

{pstd}
{cmd:xtflucbreak} inverts the series by bisection. For x < 1 the alternating series loses
precision, so the theta-function form

{p 12 12 2}
P(sup|B| {&le} x) = ({&radic}(2{&pi})/x){&Sigma}{sub:k{&ge}1}exp(-(2k-1){sup:2}{&pi}{sup:2}/(8x{sup:2}))

{pstd}
is used there instead. The two agree to machine precision near x = 1.

{pstd}
The reported overall p-value is 1 - (1 - min{sub:j}p{sub:j}){sup:K}. This is exactly
equivalent to the rule above: min{sub:j}p{sub:j} {&le} {&alpha}* if and only if
1 - (1-min{sub:j}p{sub:j}){sup:K} {&le} {&alpha}.


{marker khat}{title:The change-point estimator}

{pstd}
Remark 3.7 defines V(k) = {&Sigma}{sub:i}(k/sigmahat{sub:i})Qhat{sub:i}{sup:1/2}({&beta}hat{sub:i}(k)-{&beta}hat{sub:i})
and khat = argmax{sub:1<k<T}||V(k)||, with ||{c 183}|| the Euclidean norm of the K-vector
taken {it:after} summing over panels. The motivation is the expected-value calculation on
p.1188-1189: |E(V(k){sup:(j)})| increases in k up to k{sub:0} and decreases thereafter, so
its maximum locates the break.

{pstd}
Note that V(k) = {&radic}(NT){c 183}S(k) identically, so the argmax is invariant to the
scaling and {cmd:xtflucbreak} computes it from S(k) directly. Theorem 3.8 (and 4.12 in the
CCE case) establishes khat {&rarr}{sub:p} k{sub:0} following Proposition 1 of Feng, Kao and
Lazarova (2009).

{pstd}
{bf:No confidence interval is reported.} The paper's own conclusion states this
explicitly: "this work only discusses the consistency of the change-point estimator,
derive its asymptotic distribution is the next research topic". Anything the command
printed as an interval would be invented. Use {helpb xtbfkbreak}, which implements the
Baltagi-Feng-Kao estimator and its interval, if you need one.


{marker map}{title:Step-to-equation map}

{pstd}Every block of the engine against the paper it comes from.

{p2colset 5 22 24 2}{...}
{p2col :{bf:Code}}{bf:Paper}{p_end}
{p2line}
{p2col :F1}{&beta}hat{sub:i} = (X{sub:i}'X{sub:i}){sup:-1}X{sub:i}'Y{sub:i} {space 8}LXC eq.(2), p.1187{p_end}
{p2col :F2}{&beta}hat{sub:i}(k), recursive OLS {space 8}LXC p.1187{p_end}
{p2col :F3}Qhat{sub:i} = X{sub:i}'X{sub:i}/T; sigmahat{sub:i}{sup:2} = (1/T){&Sigma}(ehat-ebar){sup:2} {space 2}LXC p.1187{p_end}
{p2col :F4}S(k) {space 8}LXC p.1187{p_end}
{p2col :F5}Sidak rule, {&alpha}* = 1-(1-{&alpha}){sup:1/K} {space 8}LXC Remark 3.5{p_end}
{p2col :F6}Kolmogorov inversion for C{sub:1}({&alpha}*) {space 8}LXC Remark 3.5{p_end}
{p2col :F7}khat = argmax ||V(k)|| {space 8}LXC Remark 3.7{p_end}
{p2col :F8}M{sub:w} from (ybar, xbar) {space 8}LXC p.1190; BFK 2016 eq.20{p_end}
{p2col :F9}{&beta}til{sub:i}, {&beta}til{sub:i}(k), Qchk{sub:i} {space 8}LXC eq.(4), p.1191{p_end}
{p2col :F10}Stil(k), rate condition {&radic}T/N {&rarr} 0 {space 8}LXC Theorem 4.8{p_end}
{p2col :A1-A9}benchmark tests, see below {space 8}Antoch et al. (2018){p_end}
{p2line}
{p2colreset}{...}

{pstd}
Limit theory used, for the record: Theorem 3.4 (null, no CCE), Theorem 3.6 (consistency
under H{sub:A}), Theorem 3.8 (khat consistent), Theorem 4.8 (null, CCE), Theorem 4.10
(consistency, CCE), Theorem 4.12 (khat consistent, CCE).


{marker departures}{title:Departures from the printed paper}

{pstd}
Two places in the article are internally inconsistent. In both, {cmd:xtflucbreak} follows
the {it:theorems}, because the theorems are what the critical value is derived from. Both
are switchable so the literal text can be reproduced.

{pstd}
{bf:(D1) Where the absolute value goes.} Remarks 3.5 and 4.9 typeset

{p 12 12 2}
max{sub:k} N{sup:-1/2}{&Sigma}{sub:i}{c 123}(1/sigmahat{sub:i})(k/{&radic}T)|({c 183}){sup:(j)}|{c 125} {&ge} C{sub:1}({&alpha}*),

{pstd}
with |{c 183}| {it:inside} the sum over i. Taken literally this cannot work: under
H{sub:0} each summand converges to |B{sub:i}(s)|, a non-negative random variable with
positive mean, so N{sup:-1/2}{&Sigma}{sub:i}|B{sub:i}(s)| {&rarr} {&infin} and the test
would reject with probability one for any fixed critical value. Theorem 3.4 states the
limit for S(k) {it:without} absolute values, and the quoted distribution function is that
of sup|B|, the two-sided bridge. The bars therefore belong {it:outside} the sum:

{p 12 12 2}
max{sub:k} |N{sup:-1/2}{&Sigma}{sub:i}{c 123}(1/sigmahat{sub:i})(k/{&radic}T)({c 183}){sup:(j)}{c 125}|.

{pstd}
That is what the command computes. There is no option to reproduce the literal form,
because it has no valid critical value.

{pstd}
{bf:(D2) The missing sigma in section 4.} The section-4 statistic is printed as

{p 12 12 2}
Stil(k) = N{sup:-1/2}{&Sigma}{sub:i}{c 123}(k/{&radic}T)Qchk{sub:i}{sup:1/2}({&beta}til{sub:i}(k) - {&beta}til{sub:i}){c 125},

{pstd}
with no 1/sigmatil{sub:i}. But Theorem 4.8 asserts convergence to a {it:standard}
Brownian bridge and Remark 4.9 uses the {it:same} C{sub:1}({&alpha}*) as section 3. Both
require the variance standardisation; without it the limit is a bridge with variance
E({&sigma}{sub:i}{sup:2}) per component. The omission is nearly invisible in the paper's
own Table 6 because its DGP draws
{&sigma}{sub:i}{sup:2} ~ U(0.5,1.5), so E({&sigma}{sub:i}) {&asymp} 0.98 and the scaling is
almost exactly one -- which is very likely why it survived. The default therefore applies
1/sigmatil{sub:i} in both branches; {cmd:nosigmascale} reproduces the printed form.

{pstd}
{bf:(D3) The finite-sample size problem, and the trimming the paper does not mention.}
This is the one that matters most in practice.

{pstd}
S(k) is asymptotically a standard Brownian bridge, so Var(S(k){sup:(j)}) {&rarr} s(1-s)
with s = k/T. Its {it:exact} variance, conditional on X and under
Var(e{sub:i}) = {&sigma}{sub:i}{sup:2}I, is

{p 12 12 2}
Var[(k/{&radic}T)Qhat{sub:i}{sup:1/2}({&beta}hat{sub:i}(k)-{&beta}hat{sub:i})]
= (k{sup:2}/T){c 183}Qhat{sub:i}{sup:1/2}(A{sub:ik}{sup:-1} - A{sub:iT}{sup:-1})Qhat{sub:i}{sup:1/2}{c 183}{&sigma}{sub:i}{sup:2},
{space 4}A{sub:ik} = X{sub:i}(k)'X{sub:i}(k).

{pstd}
Replacing A{sub:ik}{sup:-1} by (kQ{sub:i}){sup:-1} gives the bridge variance s(1-s), but
that substitution is poor for small k. For Gaussian regressors A{sub:ik} is Wishart with k
degrees of freedom and E[A{sub:ik}{sup:-1}] = {&Sigma}{sup:-1}/(k-K-1), {it:not}
{&Sigma}{sup:-1}/k. The variance is therefore inflated by a factor

{p 12 12 2}
[1/(k-K-1) - 1/(T-K-1)] / [1/k - 1/T],

{pstd}
which at k = T/2 = 25, T = 50, K = 2 equals 1.208. Simulation confirms this exactly (ratio
1.20). Near the start of the grid the inflation is catastrophic: at k = K the subsample fit
is exact and the measured ratio is 2.7{&times}10{sup:6}; at k = K+1 it is 18.5, at K+2 it
is 3.0.

{pstd}
The consequence is that {cmd:max{sub:1<k<T}}, as printed, is dominated by the first few
points of the grid. Measured empirical size at the nominal 5% level, LXC Model 1, iid
errors, N = T = 50, 500 replications:

{p2colset 8 30 32 2}{...}
{p2col :{cmd:trimming(0)}}0.674{p_end}
{p2col :{cmd:trimming(0.05)}}0.140{p_end}
{p2col :{cmd:trimming(0.10)}}0.050{p_end}
{p2col :{cmd:trimming(0.15)}}0.050{p_end}
{p2colreset}{...}

{pstd}
{cmd:trimming(0.10)} reproduces the paper's Table 1 across all three error processes
(0.050 / 0.070 / 0.062 measured, against 0.050 / 0.081 / 0.069 published) and its Table 2
power (0.988 against 1.000). That agreement is strong evidence that the published results
were produced with roughly 10% trimming, and it is the default here.

{pstd}
Trimming a fixed {it:fraction of T} is not enough on short panels, though, because the
blow-up is governed by k relative to {it:K}, not to T. At T = 25 -- the length of the
paper's own application -- {cmd:trimming(0.10)} still starts the grid at k = 3, and the
measured size is 0.255 (Model 1) and 0.388 (Model 2). The command therefore standardises
each component by its exact conditional variance,

{p 12 12 2}
S*(k){sup:(j)} = S(k){sup:(j)}{c 183}{&radic}( s(1-s) / Vhat(k){sup:(j)} ),
{space 4}Vhat(k) = (1/N){&Sigma}{sub:i}(k{sup:2}/T){c 183}diag(Qhat{sub:i}{sup:1/2}(A{sub:ik}{sup:-1}-A{sub:iT}{sup:-1})Qhat{sub:i}{sup:1/2}),

{pstd}
which requires no distributional assumption beyond the homoskedasticity already imposed by
Assumption 3.1, and satisfies Vhat(k) {&rarr} s(1-s), so S*(k) and S(k) have the same limit
and the same Kolmogorov critical value. Measured size at the nominal 5% level:

{p2colset 8 34 36 2}{...}
{p2col :}{it:literal}{space 8}{it:standardised}{p_end}
{p2col :Model 1, N = T = 50}0.050{space 12}0.038{p_end}
{p2col :Model 1, N = 50, T = 25}0.255{space 12}0.028{p_end}
{p2col :Model 2 (CCE), N = T = 50}0.100{space 12}0.062{p_end}
{p2col :Model 2 (CCE), N = 200, T = 50}0.098{space 12}0.045{p_end}
{p2colreset}{...}

{pstd}
In the CCE branch the standardised form is also the {it:closer} match to the paper's own
tables: size 0.062 against LXC Table 6's 0.059, and power 0.870 against Table 7's 0.870 for
{&delta} = (0.2,0)' (the literal form gives 0.100 and 0.912). The default is therefore the
standardised statistic; {cmd:asymptotic} restores the literal one, and the literal value
and p-value are printed and returned in every case so any published number stays
recoverable.

{pstd}
{bf:khat is left alone.} The change-point estimator continues to maximise the {it:raw}
||V(k)|| of Remark 3.7, because that is the object Theorems 3.8 and 4.12 prove consistency
for. Measured break-date accuracy is indistinguishable between the two at T {&ge} 50
(fraction within {&plusmn}3 of k{sub:0} at N = T = 50: 0.925 raw, 0.930 standardised); only
at T = 25 does the standardised argmax do noticeably better (0.843 against 0.682). That
gap is documented rather than acted on, since departing from a proved result is not
warranted by a difference this size at usable sample sizes.

{pstd}
{bf:A fourth, minor one.} The Appendix proof of Theorem 3.4 writes
T{sup:-1/2}{&Sigma}{sub:i}B{sub:i}(s) {&rArr} B(s) as N {&rarr} {&infin} (p.1205). The
normalisation must be N{sup:-1/2}, as it is in the statement of the theorem and everywhere
else. This is a typographical slip with no consequence for the code.


{marker choices}{title:Implementation choices the paper leaves open}

{pstd}
{bf:The lower end of the search grid.} The paper searches 1 < k < T but
{&beta}hat{sub:i}(k) does not exist until X{sub:i}(k)'X{sub:i}(k) is invertible, which
needs at least K observations and can need more if the early regressor values are
collinear. {cmd:xtflucbreak} finds, for each panel, the first k at which the accumulated
cross-product is of full rank, takes the {it:maximum} over panels, and starts the grid
there. The bound is reported in the header. No trimming beyond that is applied by default:
the k/{&radic}T weight already down-weights small k, which is precisely what makes a
fluctuation test usable without a trimming parameter. {cmd:trimming()} is offered for
robustness checks, not as a default.

{pstd}
{bf:Which square root.} Qhat{sup:1/2} is not unique. The default is the symmetric
positive semi-definite root computed from the eigendecomposition, which is the standard
reading of the notation. It has a useful property: permuting the regressors permutes the
components of S(k), because the symmetric root of PQP' is PQ{sup:1/2}P'. So
max{sub:j} -- and therefore the test decision -- does not depend on the order in which
regressors are listed. The Cholesky alternative ({cmd:cholesky}) does not have this
property, but its lower-triangular structure means component 1 loads only on the first
coefficient, component 2 on the first two, and so on.

{pstd}
{bf:Components are rotated.} Because Qhat{sub:i}{sup:1/2} differs across panels, component
j of S(k) is a panel-varying linear combination of coefficient deviations. A rejection on
component j does {it:not} identify a regressor. That is a property of the statistic, not of
the implementation. The per-panel shift table reports
{&delta}hat{sub:i} = {&beta}hat{sub:i}(khat+1..T) - {&beta}hat{sub:i}(1..khat) in the
original coefficient space, which is the quantity to quote when discussing which
coefficient moved.

{pstd}
{bf:The CCE constant.} The paper's M{sub:w} is built from Wbar alone. Pesaran's (2006)
CCE augmentation, and Baltagi-Feng-Kao's implementation, include a constant column
alongside the averages; under a slope break this also spans the regime-split factor space
{c 123}1, f, f{c 183}1{c 123}t>k{sub:0}{c 125}{c 125}, so both the factor and its
regime-split copy are removed. Omitting the constant leaves the regime-split factor in the
errors. The default therefore includes it, which also makes {cmd:xtflucbreak} and
{helpb xtbfkbreak} numerically consistent on the same data. {cmd:nocceconstant} reproduces
the literal display.

{pstd}
{bf:Balanced panels.} S(k) is a sum over i evaluated at a {it:common} k. With unequal T
the panels would be evaluated at different points of their own bridges and the aggregation
would be meaningless, so unbalanced data is refused rather than silently truncated.


{marker bench}{title:The benchmark tests}

{pstd}
{cmd:compare} implements the three statistics Li, Xiao and Chen benchmark against, from
Antoch, Hanousek, Horvath, Huskova and Wang (2018). Let
Z{sub:it} = {&Sigma}{sub:v{&le}t}x{sub:iv}x{sub:iv}',
ehat{sub:iv} = y{sub:iv} - x{sub:iv}'{&beta}hat{sub:iT}, and
s{sub:it} = {&Sigma}{sub:v{&le}t}x{sub:iv}ehat{sub:iv}.

{pstd}
The general Wald-type process is
U{sub:N}(t) = {&Sigma}{sub:i}({&beta}hat{sub:it}-{&beta}hat{sub:iT})'C{sub:it}({&beta}hat{sub:it}-{&beta}hat{sub:iT}).
Since Z{sub:it}({&beta}hat{sub:it} - {&beta}hat{sub:iT}) = s{sub:it} exactly, the two
weighting matrices used in the paper collapse to score forms:

{p 8 12 2}
{bf:Wald 1} C{sub:it} = Z{sub:it}Z{sub:it} {space 6}{&rArr} U{sub:N}(t) = {&Sigma}{sub:i} s{sub:it}'s{sub:it} {space 8}(Antoch S1, d = 2)

{p 8 12 2}
{bf:Wald 2} C{sub:it} = Z{sub:it}Z{sub:iT}{sup:-1}Z{sub:it} {space 2}{&rArr} U{sub:N}(t) = {&Sigma}{sub:i} s{sub:it}'Z{sub:iT}{sup:-1}s{sub:it} {space 2}(Antoch S2, d = 5)

{p 8 12 2}
{bf:CUSUM} V{sub:N}(t) = {&Sigma}{sub:i}{&Sigma}{sub:s{&le}t}ehat{sub:is}{sup:2} {space 6}(Antoch eq. 2.5)

{pstd}
Each is centred by its mean under H{sub:0} (Antoch eq. 3.1-3.4), with
sigchk{sub:i}{sup:2} = (1/(T-d)){&Sigma}{sub:t}ehat{sub:it}{sup:2} (eq. 3.10) -- note this
is a {it:different} variance estimator from LXC's, and each paper's own is used:

{p 12 12 2}
Ahat{sup:(1)}{sub:N}(t) = {&Sigma}{sub:i}sigchk{sub:i}{sup:2}{c 183}tr(C{sub:it}(Z{sub:it}{sup:-1} - Z{sub:iT}{sup:-1})),
{break}
Ahat{sup:(2)}{sub:N}(t) = {&Sigma}{sub:i}sigchk{sub:i}{sup:2}{c 183}(t - tr(Z{sub:it}Z{sub:iT}{sup:-1})).

{pstd}
The reported statistic is
max{sub:t}|N{sup:-1/2}(U{sub:N}(t) - Ahat{sub:N}(t))| over d {&le} t {&le} T-d.

{pstd}
{bf:Wild bootstrap} (Antoch sec. 4.1-4.2). With q{sub:it} the panel-i contribution to the
process, put
{&phi}{sub:it} = q{sub:it} - N{sup:-1}{&Sigma}{sub:j}q{sub:jt},
draw {&zeta}{sub:i} ~ N(0,1) independently across panels, and form
U*{sub:N}(t) = N{sup:-1/2}{&Sigma}{sub:i}{&zeta}{sub:i}{&phi}{sub:it}. The bootstrap
statistic is max{sub:t}|U*{sub:N}(t)|; the critical value is its (1-{&alpha}) quantile over
B replications. Because the centring is by the cross-sectional mean, the bootstrap
reproduces the centred observed process automatically -- Ahat{sub:N}(t) does not enter it.
The whole replication is a single matrix product {&Phi}'{&zeta}, so B = 1000 is cheap.

{pstd}
{bf:Raw data.} The benchmarks are always computed on the untransformed data with an
intercept, even when {cmd:cce} is specified for the fluctuation test. That is deliberate:
it is the configuration in the paper's Tables 6-9, where the Wald and CUSUM tests are
applied to factor-contaminated data because no CCE variant of them exists. Their collapse
in power there is the comparison's whole point.


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Online: {help xtflucbreak:xtflucbreak},
{help xtflucbreak_postestimation:xtflucbreak postestimation},
{helpb xtbfkbreak}
