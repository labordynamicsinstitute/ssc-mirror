{smcl}
{* *! version 1.0.0  17jul2026}{...}
{vieweralsosee "xtcombreak" "help xtcombreak"}{...}
{vieweralsosee "xtcombreak estimate" "help xtcombreak_estimate"}{...}
{vieweralsosee "xtcombreak test" "help xtcombreak_test"}{...}
{viewerjumpto "Regime" "xtcombreak_methods##regime"}{...}
{viewerjumpto "Bai: the estimator" "xtcombreak_methods##bai"}{...}
{viewerjumpto "Bai: the confidence interval" "xtcombreak_methods##baici"}{...}
{viewerjumpto "Bai: variance breaks and QML" "xtcombreak_methods##baiqml"}{...}
{viewerjumpto "JK: the statistic" "xtcombreak_methods##jk"}{...}
{viewerjumpto "JK: the three reductions" "xtcombreak_methods##reduce"}{...}
{viewerjumpto "JK: critical values" "xtcombreak_methods##jkcv"}{...}
{viewerjumpto "Step-to-equation map" "xtcombreak_methods##map"}{...}
{viewerjumpto "Faithfulness notes" "xtcombreak_methods##faith"}{...}
{viewerjumpto "Author" "xtcombreak_methods##author"}{...}
{hline}
help for {hi:xtcombreak methods}{right: version 1.0.0 - 17jul2026}
{hline}

{title:Title}

{p 4 4}{cmd:xtcombreak methods} {hline 2} Equation-by-equation derivation, the
step-to-equation map, and the exact algebraic reductions used.{p_end}

{p 4 4}This page documents {bf:what the code computes and where each formula comes
from}, so any step can be checked against the source papers.{p_end}


{marker regime}{title:1. The asymptotic regime -- do the two papers agree?}

{p 4 4}This is checked first, because it decides whether one command can host
both. The answer is {bf:yes}, in their main frameworks.{p_end}

{synoptset 42 tabbed}{...}
{synopt:{bf:Source and condition}}{bf:Direction}{p_end}
{synoptline}
{synopt:Bai Assumption 2 (eq.2): N{sup:-1/2}SUM d{sub:i}{sup:2} -> inf}N -> inf suffices; T fixed or not{p_end}
{synopt:Bai Thm 3.2 (eq.4 + eq.5): N*log(log T)/T -> 0}{bf:T >> N}{p_end}
{synopt:Bai sec.4 CI (Lemma 4.1 invokes eq.5)}{bf:T >> N}{p_end}
{synopt:Bai sec.5 QML ("T is larger than N", p.84)}{bf:T >> N}{p_end}
{synopt:Bai Remark 3 (p.87): k0 free, single-obs regime}{bf:N >> T} (T/N -> 0){p_end}
{synopt:JK Assumption 2(iii): T/N -> inf}{bf:T >> N}{p_end}
{synoptline}

{p 4 4}Bai's confidence interval, his QML, and JK's test {bf:all} want T large
relative to N. The only divergence is Bai's Remark 3 -- the special mode where k0
is unrestricted and a regime may hold one observation -- which sits outside his CI
framework.{p_end}

{p 4 4}Consequence for reading output: under Assumption 2 the {bf:point estimate}
khat needs no T/N condition at all and stays consistent when T < N. It is the
{bf:CI} that rests on eq.(5). The command says so rather than issuing a blanket
warning.{p_end}


{marker bai}{title:2. Bai (2010): the estimator}

{p 4 4}{ul:2.1 Least squares (his sec.3)}{p_end}

{p 8 8}Ybar{sub:i1} = (1/k) SUM{sub:t<=k} Y{sub:it}{break}
Ybar{sub:i2} = (1/(T-k)) SUM{sub:t>k} Y{sub:it}{p_end}

{p 8 8}S{sub:iT}(k) = SUM{sub:t<=k}(Y{sub:it}-Ybar{sub:i1}){sup:2} + SUM{sub:t>k}(Y{sub:it}-Ybar{sub:i2}){sup:2}{p_end}

{p 8 8}SSR(k) = SUM{sub:i} S{sub:iT}(k){break}
khat = argmin{sub:1<=k<=T-1} SSR(k){p_end}

{p 4 4}Computed from cumulative sums: with
S{sub:i}(j) = SUM{sub:t<=j}Y{sub:it} and Q{sub:i}(j) = SUM{sub:t<=j}Y{sup:2}{sub:it},{p_end}

{p 8 8}SUM{sub:t<=k}(Y-Ybar{sub:1}){sup:2} = Q{sub:i}(k) - S{sub:i}(k){sup:2}/k{p_end}

{p 4 4}so the whole profile costs O(TN) rather than O(T{sup:2}N). Algebraically
identical.{p_end}

{p 4 4}Bai warns (p.80) against the tempting alternative of estimating a break
{it:per series} and averaging: it is {bf:not consistent}, because series without a
break contribute arbitrary estimates that do not fluctuate around k0.
{cmd:xtcombreak} does not offer it.{p_end}

{p 4 4}{ul:2.2 Identification}{p_end}

{p 4 4}Assumption 2: N{sup:-1/2} SUM{sub:i}(mu{sub:i2}-mu{sub:i1}){sup:2} ->
infinity. Weakened in Theorem 3.2 to eq.(4),
SUM{sub:i}(mu{sub:i2}-mu{sub:i1}){sup:2} -> infinity, at the price of eq.(5).
Neither requires every series to break.{p_end}

{p 4 4}{ul:2.3 Multiple breaks (his sec.6)}{p_end}

{p 4 4}One-at-a-time (Bai 1997a): estimate a single break; split; estimate a single
break in each subsample; retain the one giving the {bf:larger SSR reduction};
repeat; relabel ascending. Implemented as: at each step, scan every candidate in
every current segment and keep the (segment, location) with the largest
reduction{p_end}

{p 8 8}S{sub:i}[a,b] - S{sub:i}[a,kk] - S{sub:i}[kk+1,b]{p_end}

{p 4 4}summed over i. This is equivalent to minimising the total partition SSR,
since adding a break only changes the segment containing it.{p_end}


{marker baici}{title:3. Bai (2010): the confidence interval}

{p 4 4}{ul:3.1 The new limiting framework (his sec.4)}{p_end}

{p 4 4}Because P(khat = k0) -> 1, the limit is degenerate. To get a usable
distribution Bai lets the breaks shrink: mu{sub:i2}-mu{sub:i1} =
N{sup:-1/2}Delta{sub:i}, with{p_end}

{p 8 8}lim SUM{sub:i}(mu{sub:i2}-mu{sub:i1}){sup:2} = lambda   (eq.8){break}
lim SUM{sub:i}(mu{sub:i2}-mu{sub:i1}){sup:2}sigma{sup:2}{sub:i} = phi   (eq.9){p_end}

{p 4 4}Then (his Theorem 4.2){p_end}

{p 8 8}khat - k0 -> argmin{sub:l} [ |l|*lambda + 2*sqrt(phi)*W(l) ]   (eq.10){p_end}

{p 4 4}where {bf:W is a two-sided Gaussian random walk}, not a Brownian motion --
W(l) = SUM{sub:s=1..l} Z{sub:s} with Z{sub:s} iid standard normal.{p_end}

{p 4 4}The payoff, and the reason the CI needs no simulation: the Z{sub:s} are
{bf:standard normal} by a central limit theorem across i, whatever the
distribution of e{sub:it}. So unlike the univariate case, the limit does {bf:not}
depend on the error distribution, nor on strict stationarity, nor does khat-k0
diverge.{p_end}

{p 4 4}{ul:3.2 The scale and the constants}{p_end}

{p 8 8}A{sub:N} = [SUM{sub:i} d{sub:i}{sup:2}]{sup:2} / [SUM{sub:i} d{sub:i}{sup:2} sigma{sup:2}{sub:i}],
{space 3}d{sub:i} = mu{sub:i2}-mu{sub:i1}{p_end}

{p 8 8}A{sub:N}(khat - k0) -> argmin{sub:l}[|l| + 2W(l)] =: l*   (eq.12){p_end}

{p 4 4}l* is parameter-free. Bai simulated it once (100,000 reps, his Fig.3):{p_end}

{p 8 8}P(|l*| <= 7) ~ 0.90{space 4}P(|l*| <= 11) ~ 0.95{space 4}P(|l*| <= 20) ~ 0.99{p_end}

{p 8 8}CI = [khat - floor(c/Ahat{sub:N}), khat + ceil(c/Ahat{sub:N})]   (eq.13){p_end}

{p 4 4}with c = 7, 11, 20. Bai proves Ahat{sub:N} = A{sub:N} + o{sub:p}(1)
(his eq.14), so plugging in estimates is asymptotically free.{p_end}

{p 4 4}{err}{bf:Important: eq.(13) as printed is not what Bai actually ran.}{p_end}

{p 4 4}Taken literally, eq.(13) is inconsistent with the rest of his own paper.
Three checks -- two internal to the paper, one empirical:{p_end}

{p 8 12}{bf:1. It contradicts his prose.} p.84: "Due to the use of 'floor' and
'ceiling' functions, the shortest confidence interval (by construction) would
contain {bf:three} integers (khat-1, khat, khat+1)." But when c/A < 1,
floor(c/A) = 0 and ceil(c/A) = 1, giving {c 123}khat, khat+1{c 125} -- {bf:two}
integers. Only a {bf:symmetric} [khat - ceil(c/A), khat + ceil(c/A)] has minimum
length 3, exactly as he describes.{p_end}

{p 8 12}{bf:2. It contradicts the parity of his Table 1.} Under the literal form,
whenever c/A is not an integer floor = ceil-1, so length = floor + ceil + 1 =
2*ceil, always {bf:EVEN}. His published median lengths are 9, 5, 5, 3 (90%);
13, 7, 7, 5 (95%); 23, 13, 9, 7 (99%) -- essentially all {bf:ODD}, which only
2*ceil+1 can produce.{p_end}

{p 8 12}{bf:3. Replication settles it.} 300 replications of his own p.83 design
(T=100, k0=50, shift ~ U(-1,1), e ~ N(0,1)) at the 90% level:{p_end}

{p 8 8}{space 2}N {c 124} cov(lit) cov(sym) {c 124} {bf:Bai} {c 124} len(lit) len(sym) {c 124} {bf:Bai}{break}
{space 2}5 {c 124}  0.797   0.827  {c 124} {bf:0.829} {c 124}    8       9    {c 124} {bf:9}{break}
{space 1}10 {c 124}  0.863   0.887  {c 124} {bf:0.900} {c 124}    4       5    {c 124} {bf:5}{break}
{space 1}15 {c 124}  0.890   0.933  {c 124} {bf:0.937} {c 124}    4       5    {c 124} {bf:5}{break}
{space 1}20 {c 124}  0.927   0.963  {c 124} {bf:0.949} {c 124}    2       3    {c 124} {bf:3}{p_end}

{p 4 4}The symmetric form reproduces {bf:all four} of his median lengths exactly
and his coverage to within Monte Carlo error. The literal form is systematically
one integer short and under-covers throughout.{p_end}

{p 4 4}So {cmd:cimethod(symmetric)} is the {bf:default}: it is what Bai ran and
what reproduces his published table. {cmd:cimethod(literal)} gives eq.(13) exactly
as printed, for anyone who wants the letter of the equation. The discrepancy is
documented here rather than silently patched.{p_end}

{p 4 4}This is {bf:not} the round() variant Bai explicitly rejects on p.84 ("If we
round 7/AN to the nearest integer instead ... the shortest confidence interval
would contain a single element {c 123}khat{c 125} ... We did not consider such
intervals"), which would give minimum length 1. His minimum is 3.{p_end}

{p 4 4}Note eq.(12) is an {bf:approximation}: the change-of-variable argument
behind it is exact only for continuous l and Brownian W, whereas here l is integer
and W a random walk. Bai says so, and notes it holds well because a Gaussian random
walk and a Brownian motion agree at integer times.{p_end}

{p 4 4}{ul:3.3 Heteroskedastic vs homoskedastic A_N}{p_end}

{p 4 4}When sigma{sup:2}{sub:i} = sigma{sup:2} for all i,{p_end}

{p 8 8}[SUM d{sup:2}]{sup:2} / [SUM d{sup:2}sigma{sup:2}] = [SUM d{sup:2}]{sup:2} / (sigma{sup:2} SUM d{sup:2}) = SUM d{sup:2}/sigma{sup:2}{p_end}

{p 4 4}which is exactly what Bai states on p.83 and used in his own Monte Carlo
with sigmahat{sup:2} = SUM SUM ehat{sup:2}/(NT-2N). {cmd:anmethod(het)} is the
general form (default); {cmd:anmethod(hom)} is his Monte-Carlo form.{p_end}


{marker baiqml}{title:4. Bai (2010): variance breaks, QML and efficiency}

{p 4 4}{ul:4.1 The QML objective (his eq.16)}{p_end}

{p 8 8}sigmahat{sup:2}{sub:i1}(k) = (1/k) SUM{sub:t<=k}(Y{sub:it}-Ybar{sub:i1}){sup:2}{break}
sigmahat{sup:2}{sub:i2}(k) = (1/(T-k)) SUM{sub:t>k}(Y{sub:it}-Ybar{sub:i2}){sup:2}{p_end}

{p 8 8}U{sub:NT}(k) = k SUM{sub:i} log sigmahat{sup:2}{sub:i1}(k) + (T-k) SUM{sub:i} log sigmahat{sup:2}{sub:i2}(k){break}
khat = argmin{sub:k} U{sub:NT}(k){p_end}

{p 4 4}Consistency (his Theorem 5.1) needs {bf:either} a mean break (eq.18) or a
variance break (eq.17), where{p_end}

{p 8 8}f(x) = x - 1 - log(x),{space 3}lim SUM{sub:i} f(sigma{sup:2}{sub:i1}/sigma{sup:2}{sub:i2}) = infinity{p_end}

{p 4 4}f is minimised uniquely at x=1 with f(1)=0, so f(sigma{sup:2}{sub:i1}/sigma{sup:2}{sub:i2}) > 0
iff the variances differ. {bf:f is not symmetric in x vs 1/x}, so the ratio order
matters; the code uses pre-break over post-break, as printed.{p_end}

{p 4 4}{ul:4.2 The master scale (his eq.19)}{p_end}

{p 8 8}(tau + omega/2){sup:2} / [tau + (2+kappa)*omega/4 + mu3*pi] * (khat-k0) -> l*{p_end}

{p 4 4}with{p_end}

{p 8 8}tau = lim SUM{sub:i}(mu{sub:i1}-mu{sub:i2}){sup:2}/sigma{sup:2}{sub:i}{break}
omega = lim 2 SUM{sub:i} f(sigma{sup:2}{sub:i1}/sigma{sup:2}{sub:i2}){break}
kappa = 4th cumulant of eta{sub:it}{break}
mu3 = E(eta{sup:3}{sub:it}){break}
pi = lim SUM{sub:i} [(mu{sub:i1}-mu{sub:i2})/sigma{sub:i}][(sigma{sup:2}{sub:i1}-sigma{sup:2}{sub:i2})/sigma{sup:2}{sub:i}]{p_end}

{p 4 4}{bf:Verified to nest both corollaries:}{p_end}

{p 8 12}o omega = 0 (no variance break) gives tau{sup:2}/tau = tau, i.e.
tau(khat-k0) -> l* = his {bf:Corollary 5.3}.{p_end}

{p 8 12}o tau = 0 (no mean break) and pi = 0 gives
(omega/2){sup:2}/[(2+kappa)omega/4] = omega/(2+kappa) = his {bf:Corollary 5.4},
which he writes as [2/(kappa+2) SUM f](khat-k0) -> l*; with omega = 2 SUM f these
agree.{p_end}

{p 4 4}All three of tau, omega, pi are {bf:plain sums over i} -- the N{sup:-1} is
absorbed by the N{sup:-1/2} scaling in Delta{sub:i} and delta{sub:i}. The code uses
the sample analogues directly.{p_end}

{p 4 4}{ul:4.3 The efficiency result (his p.85)}{p_end}

{p 8 8}B{sub:N} = SUM{sub:i} d{sub:i}{sup:2}/sigma{sup:2}{sub:i}{space 4}(QML scale, his Corollary 5.3){p_end}

{p 4 4}By Cauchy-Schwarz,{p_end}

{p 8 8}(SUM d{sub:i}{sup:2}){sup:2} = (SUM (d{sub:i}/sigma{sub:i})(d{sub:i}sigma{sub:i})){sup:2}
<= (SUM d{sub:i}{sup:2}/sigma{sup:2}{sub:i})(SUM d{sub:i}{sup:2}sigma{sup:2}{sub:i}){p_end}

{p 4 4}so A{sub:N} <= B{sub:N}, with equality iff sigma{sup:2}{sub:i} is constant.
A larger scale gives a narrower CI, so {bf:QML is never less efficient than LS} --
even with no variance break. The mechanism: QML asymptotically minimises
SUM{sub:i} sigma{sup:-2}{sub:i} S{sub:iT}(k), a GLS criterion that down-weights
noisy series. The command reports both and their ratio; the example do-file
{bf:asserts} A{sub:N} <= B{sub:N} as a live check.{p_end}

{p 4 4}{ul:4.4 Why there is no WLS option}{p_end}

{p 4 4}Bai (p.85) shows that weighting by the regime-specific variances, even the
true ones, gives an {bf:inconsistent} break estimator. Counter-example:
mu{sub:i2}=2mu{sub:i1}, sigma{sub:i2}=2sigma{sub:i1}. Dividing regime 2 by 2 leaves
no break in mean or variance. LS and QML both survive; WLS does not. So it is not
offered.{p_end}

{p 4 4}{ul:4.5 The Chow test (his p.84)}{p_end}

{p 8 8}Chow{sub:i} = (muhat{sub:i2}-muhat{sub:i1}){sup:2} / [sigmahat{sup:2}{sub:i}(1/khat + 1/(T-khat))] ~ chi2(1){p_end}

{p 4 4}Valid with ordinary chi2 critical values, {bf:series by series}: as N grows,
series i contributes O(1/N) of khat, so khat is asymptotically exogenous for series
i and no correction for estimating it is needed. The argument is an N -> infinity
approximation, so the command warns when N < 15.{p_end}


{marker jk}{title:5. Jiang-Kurozumi (2026): the statistic}

{p 4 4}{ul:5.1 The break estimate (their eq.3)}{p_end}

{p 8 8}Z{sub:i}(k) = [0,...,0, x{sub:i,k+1},...,x{sub:iT}]'{break}
Y{sub:i} = X{sub:i}b{sub:i} + Z{sub:i}(k)d{sub:i} + u{sub:i}{break}
khat = argmin{sub:m<=k<=T-m} SUM{sub:i} SSR{sub:i}(k){p_end}

{p 4 4}Plain pooled least squares, per series. {bf:No CCE transformation}: JK's
Assumption 3(ii) has cross-sectionally independent errors and no factor structure.
They cite Baltagi-Feng-Kao (2016) for the consistency of khat, but their eq.(3) is
as printed above -- that is what is coded.{p_end}

{p 4 4}{ul:5.2 The CUSUM numerator (their eq.4-5)}{p_end}

{p 8 8}uhat{sub:i} = Y{sub:i} - Xbar{sub:i}(khat)bhat{sub:i}(khat){break}
US{sub:NT}(k,khat) = ( (NT){sup:-1/2} SUM{sub:i} SUM{sub:t<=k} uhat{sub:it} ){sup:2}{p_end}

{p 4 4}The sum over i is {bf:inside} the square, so panels are collapsed to a single
T-vector g{sub:t} = SUM{sub:i} uhat{sub:it} before any squaring. Coded that way.{p_end}

{p 4 4}{ul:5.3 The self-normaliser (their eq.6-10)}{p_end}

{p 4 4}Refit on four regimes split at k1 < khat < k2 (their eq.8):{p_end}

{p 8 8}Y{sub:i} = X{sub:i}b{sub:i} + X1{sub:i}(k1,khat)d{sub:1i} + X2{sub:i}(khat,k2)d{sub:2i} + X3{sub:i}(k2)d{sub:3i} + u{sub:i}{p_end}

{p 4 4}giving residuals utilde (their eq.9), and then (their eq.10){p_end}

{p 8 8}V = (1/T) SUM{sub:s=1..k1} ( (NT){sup:-1/2} SUM{sub:i} SUM{sub:t=1..s} utilde ){sup:2}{space 4}[{bf:forward}]{break}
{space 2}+ (1/T) SUM{sub:s=k1+1..khat} ( (NT){sup:-1/2} SUM{sub:i} SUM{sub:t=s..khat} utilde ){sup:2}{space 4}[{bf:BACKWARD}]{break}
{space 2}+ (1/T) SUM{sub:s=khat+1..k2} ( (NT){sup:-1/2} SUM{sub:i} SUM{sub:t=khat+1..s} utilde ){sup:2}{space 4}[{bf:forward}]{break}
{space 2}+ (1/T) SUM{sub:s=k2+1..T} ( (NT){sup:-1/2} SUM{sub:i} SUM{sub:t=s..T} utilde ){sup:2}{space 4}[{bf:BACKWARD}]{p_end}

{p 4 4}The {bf:second and fourth terms are backward partial sums}. This is the
easiest thing in the whole implementation to get wrong; it is coded exactly as
printed.{p_end}

{p 8 8}S{sub:NT}(khat) = sup{sub:(k,k1,k2) in Lambda(eps)} US{sub:NT}(k,khat) / V{sub:NT}(k1,khat,k2){p_end}


{marker reduce}{title:6. The three exact reductions}

{p 4 4}Naively this is a triple sup with an N-panel refit inside:
O(T{sup:3}*N*p{sup:3}). Three {bf:exact} algebraic reductions bring it to
O(T*N*p{sup:3}). None is an approximation.{p_end}

{p 4 4}{ul:6.1 (EQ-A) Lambda(eps) is a product set, so the sup factorises}{p_end}

{p 8 8}Lambda(eps) = {c 123}[T*eps]<=k<=[T(1-eps)]{c 125} x {c 123}[T*eps]<=k1<=khat-[T*eps]{c 125} x {c 123}khat+[T*eps]<=k2<=[T(1-eps)]{c 125}{p_end}

{p 4 4}The range of k does not depend on k1 or k2, and vice versa. The numerator
depends only on k; the denominator only on (k1,k2). Hence{p_end}

{p 8 8}sup US(k)/V(k1,k2) = [sup{sub:k} US(k)] / [inf{sub:(k1,k2)} V(k1,k2)]{p_end}

{p 4 4}{bf:Corroborated by the paper itself}: their Proposition 2 states
sup{sub:k} US{sub:NT} -> infinity (numerator alone) and Proposition 3 states
inf{sub:(k1,k2)} V{sub:NT} = O{sub:p}(1) (denominator alone). They would not state
the two separately unless the sup factorises.{p_end}

{p 4 4}{ul:6.2 (EQ-B) V is separable: V(k1,khat,k2) = A(k1) + B(k2)}{p_end}

{p 4 4}The four blocks are [1,k1], [k1+1,khat], [khat+1,k2], [k2+1,T]. So utilde
for t <= khat depends only on k1, and for t > khat only on k2. Checking every index
range in eq.(10):{p_end}

{p 8 12}term 1: s in [1,k1], inner t in [1,s] -> all t <= k1 <= khat{space 3}=> {bf:k1 only}{p_end}
{p 8 12}term 2: s in [k1+1,khat], inner t in [s,khat] -> t in [k1+1,khat]{space 3}=> {bf:k1 only}{p_end}
{p 8 12}term 3: s in [khat+1,k2], inner t in [khat+1,s] -> t in [khat+1,k2]{space 3}=> {bf:k2 only}{p_end}
{p 8 12}term 4: s in [k2+1,T], inner t in [s,T] -> t in [k2+1,T]{space 3}=> {bf:k2 only}{p_end}

{p 4 4}Therefore inf V = min{sub:k1} A(k1) + min{sub:k2} B(k2): two O(T) scans, not
an O(T{sup:2}) grid.{p_end}

{p 4 4}{bf:Cross-check}: the limiting functional in their Theorem 1 has the same
shape -- its denominator is (two integrals in tau1) + (two integrals in tau2),
separable identically. The sample statistic and its limit agree structurally, which
is strong evidence the reading is right.{p_end}

{p 4 4}{ul:6.3 (EQ-C) The stacked design equals per-regime OLS}{p_end}

{p 4 4}Since X{sub:i} = SUM{sub:r} block{sub:r} and X1, X2, X3 are blocks 2, 3, 4,{p_end}

{p 8 8}span{c 123}X{sub:i}, X1{sub:i}, X2{sub:i}, X3{sub:i}{c 125} = span{c 123}block{sub:1}, block{sub:2}, block{sub:3}, block{sub:4}{c 125}{p_end}

{p 4 4}Residuals are invariant to a non-singular reparameterisation, so utilde from
the stacked 4p-column fit is {bf:numerically identical} to four separate per-block
OLS fits. Likewise [X{sub:i}, Z{sub:i}(khat)] equals two separate fits. This is why
JK's non-cumulative parameterisation (d{sub:2i} is relative to b{sub:i}, not to
b{sub:i}+d{sub:1i}) is irrelevant here: only residuals enter eq.(10).{p_end}


{marker jkcv}{title:7. Critical values}

{p 4 4}{ul:7.1 The table}{p_end}

{p 4 4}JK Table 1 is tabulated {bf:only at eps = 0.1}, for tau0 in [0.20, 0.80] in
steps of 0.01, at the 10/5/1% levels. tau0hat = khat/T; nearest-tau0 lookup.{p_end}

{p 4 4}If {cmd:trimming()} is not 0.1, or tau0hat falls outside [0.20, 0.80], the
table {bf:does not apply} and {cmd:xtcombreak} refuses it and requires
{cmd:simulate}, rather than silently reporting wrong numbers.{p_end}

{p 4 4}{ul:7.2 The typo at tau0 = 0.39}{p_end}

{p 4 4}The published Table 1 prints {bf:5.162} for the 10% level at tau0 = 0.39.
Every neighbour is about 45.2 (0.38 -> 45.423, 0.40 -> 45.413): the leading 4 was
dropped in typesetting. {cmd:xtcombreak} stores {bf:45.162}. This is a deliberate
correction, not a coding error, and the example do-file checks it.{p_end}

{p 4 4}{ul:7.3 Simulating Theorem 1}{p_end}

{p 4 4}With {cmd:simulate}, the limit is simulated directly using JK's own recipe
(Brownian motions approximated on a grid). The same three reductions apply. The
integrals are evaluated in {bf:closed form} from cumulative sums of W, rW and
W{sup:2}, giving O(M) per replication instead of O(M{sup:2}). For example{p_end}

{p 8 8}I1(tau1) = INT{sub:0}{sup:tau1}[W(r) - (r/tau1)W(tau1)]{sup:2}dr{break}
{space 9}= SW2(tau1) - 2(W(tau1)/tau1)SrW(tau1) + (W(tau1)/tau1){sup:2}tau1{sup:3}/3{p_end}

{p 4 4}with SW2(x) = INT{sub:0}{sup:x}W{sup:2}, SrW(x) = INT{sub:0}{sup:x}rW. The
other three integrals expand the same way.{p_end}

{p 4 4}{bf:This is the single strongest compatibility check available.} Simulating
at eps=0.1 and tau0=0.50 must reproduce JK's published row {bf:45.476 / 57.809 /
85.984}. The example do-file runs exactly this at tau0 = 0.30, 0.50 and 0.70 and
prints the comparison. If the simulated numbers match the table, the coded
functional -- and hence the sample statistic that mirrors it -- is right.{p_end}


{marker map}{title:8. Step-to-equation map}

{p 4 4}{ul:estimate = Bai (2010)}{p_end}
{synoptset 12 tabbed}{...}
{synopt:{bf:Step}}{bf:Paper}{p_end}
{synoptline}
{synopt:E2}S{sub:iT}(k), p.80{p_end}
{synopt:E3}khat = argmin SSR(k), p.80{p_end}
{synopt:E4}U{sub:NT}(k), eq.(16){p_end}
{synopt:E6}two-step feasible GLS, p.85{p_end}
{synopt:E7}A{sub:N}, p.83{p_end}
{synopt:E8}CI, eq.(13){p_end}
{synopt:E9}B{sub:N}, p.85{p_end}
{synopt:E10}master scale, eq.(19){p_end}
{synopt:E11}per-series Chow, p.84{p_end}
{synopt:E12}multiple breaks, sec.6{p_end}
{synoptline}

{p 4 4}{ul:test = Jiang-Kurozumi (2026)}{p_end}
{synoptset 12 tabbed}{...}
{synopt:{bf:Step}}{bf:Paper}{p_end}
{synoptline}
{synopt:J1}khat, eq.(3){p_end}
{synopt:J3}uhat, eq.(4){p_end}
{synopt:J4}US{sub:NT}, eq.(5){p_end}
{synopt:J5-J6}4-regime design and utilde, eq.(6)-(9){p_end}
{synopt:J7}V{sub:NT}, eq.(10){p_end}
{synopt:J8}S{sub:NT}, sec.3{p_end}
{synopt:J9}Lambda(eps), sec.3{p_end}
{synopt:J10}critical values, Table 1{p_end}
{synopt:J11}simulated limit, Theorem 1{p_end}
{synoptline}


{marker faith}{title:9. Faithfulness notes -- open choices, stated}

{p 4 4}Where a paper does not fully pin something down, the choice is recorded
rather than hidden:{p_end}

{p 8 12}1. {bf:sigma{sup:2}{sub:i} in tau and pi.} In the variance-break model Bai
does not separately define the single per-series scale sigma{sub:i} that appears in
tau and pi; under his small-break framework sigma{sub:i1} ~ sigma{sub:i2} ~
sigma{sub:i}. The code uses the regime-length-weighted average
(khat*sigmahat{sup:2}{sub:i1} + (T-khat)*sigmahat{sup:2}{sub:i2})/T. This is our
choice, not his.{p_end}

{p 8 12}2. {bf:pi's second factor.} Bai prints
(sigma{sup:2}{sub:i1}-sigma{sup:2}{sub:i2})/sigma{sup:2}{sub:i}, though
sigma{sup:2}{sub:i2} would match his d{sub:i} = sigma{sup:2}{sub:i1}/sigma{sup:2}{sub:i2}-1
more literally. They are asymptotically equivalent under small breaks. We follow the
printed equation.{p_end}

{p 8 12}3. {bf:JK's trimming m is 2[T*eps], not [T*eps].} Their eq.(3) writes
khat = argmin over [m, T-m] without giving m a value. But Lambda(eps) needs
[T*eps] <= k1 <= khat-[T*eps], so khat >= 2[T*eps]; and khat+[T*eps] <= k2 <=
[T(1-eps)], so khat <= T-2[T*eps]. With m = [T*eps] the search can return a khat
for which {bf:Lambda(eps) is empty and the statistic does not exist} -- this fired
in testing under the alternative. Setting m = 2[T*eps] forces tau0 into
[2*eps, 1-2*eps] = [0.20, 0.80] at eps = 0.1, which is exactly the range JK
tabulate and exactly what they state below their Table 1: "the possible break
fractions tau0 are from 0.2 to 0.8 when eps = 0.1". Only m = 2[T*eps] makes
eq.(3), Lambda(eps) and Table 1's range mutually consistent.{p_end}

{p 8 12}4. {bf:Ties in the argmin.} Neither paper says what to do. We take the
{bf:smallest} minimising k and report the count in {cmd:r(nties)}.{p_end}

{p 8 12}5. {bf:JK cite Baltagi et al. (2016)} for khat's consistency, but their own
eq.(3) is plain pooled LS with no CCE step, and their model has no factors. We
implement eq.(3) as printed.{p_end}


{marker author}{title:Author}

{p 4}Dr Merwan Roudane{p_end}
{p 4}merwanroudane920@gmail.com{p_end}
{p 4}{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
