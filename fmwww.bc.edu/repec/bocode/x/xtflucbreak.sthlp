{smcl}
{* *! xtflucbreak 1.0.0  07aug2026}{...}
{vieweralsosee "xtflucbreak methods" "help xtflucbreak_methods"}{...}
{vieweralsosee "xtflucbreak postestimation" "help xtflucbreak_postestimation"}{...}
{vieweralsosee "xtbfkbreak" "help xtbfkbreak"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtflucbreak##syntax"}{...}
{viewerjumpto "Description" "xtflucbreak##description"}{...}
{viewerjumpto "Options" "xtflucbreak##options"}{...}
{viewerjumpto "Interpreting the output" "xtflucbreak##output"}{...}
{viewerjumpto "Remarks and practical guidance" "xtflucbreak##remarks"}{...}
{viewerjumpto "Examples" "xtflucbreak##examples"}{...}
{viewerjumpto "Stored results" "xtflucbreak##results"}{...}
{viewerjumpto "References" "xtflucbreak##references"}{...}
{viewerjumpto "Author" "xtflucbreak##author"}{...}
{title:Title}

{phang}
{bf:xtflucbreak} {hline 2} Fluctuation test for a structural change at an unknown
date in heterogeneous panel data models, with or without common correlated effects


{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:xtflucbreak} [{depvar} {indepvars}] {ifin}
[{cmd:,} {it:options}]

{pstd}
With no varlist the command runs as {help xtflucbreak_postestimation:postestimation}
and reads the model from the estimation results in memory.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt cce}}filter out unobserved common factors with cross-section averages
(Li-Xiao-Chen section 4); the default is the section-3 branch{p_end}
{synopt:{opt nocceconstant}}omit the constant column from the CCE projection, reproducing
the literal M{sub:w} printed on p.1190{p_end}
{synopt:{opt ccal:ags(#)}}augment the cross-section averages with {it:#} lags; default
{cmd:ccalags(0)}{p_end}
{synopt:{opt nocons:tant}}do not include an intercept among the tested coefficients{p_end}

{syntab:Test}
{synopt:{opt l:evel(#)}}overall significance level in percent; default {cmd:level(5)}{p_end}
{synopt:{opt trim:ming(#)}}fraction of T trimmed at each end of the search grid;
default {cmd:trimming(0.10)}{p_end}
{synopt:{opt asym:ptotic}}decide on the literal LXC statistic instead of the
finite-sample standardised one {bf:(over-rejects; see Options)}{p_end}
{synopt:{opt nosigma:scale}}drop the 1/sigmahat{sub:i} scaling, reproducing the literal
section-4 display{p_end}
{synopt:{opt chol:esky}}use the Cholesky factor of Qhat{sub:i} instead of the symmetric
square root{p_end}

{syntab:Benchmarks}
{synopt:{opt comp:are}}also report the Wald 1, Wald 2 and CUSUM tests of Antoch et al.
(2018) with wild-bootstrap critical values{p_end}
{synopt:{opt reps(#)}}bootstrap replications for {opt compare}; default {cmd:reps(1000)}{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}

{syntab:Reporting}
{synopt:{opt graph}}draw the fluctuation paths, the change-point profile, the panel-level
shifts and (with {opt compare}) the benchmark processes{p_end}
{synopt:{opt flucname(name)}}name for the fluctuation-path graph; default {cmd:xtfb_fluc}{p_end}
{synopt:{opt breakname(name)}}name for the change-point graph; default {cmd:xtfb_break}{p_end}
{synopt:{opt unitname(name)}}name for the panel-shift graph; default {cmd:xtfb_units}{p_end}
{synopt:{opt compname(name)}}name for the benchmark graph; default {cmd:xtfb_compare}{p_end}
{synopt:{opt show:units}}list the per-panel shift norms{p_end}
{synopt:{opt listunits(#)}}how many panels to list; default {cmd:listunits(10)}{p_end}
{synopt:{opt nowarn:ings}}suppress the sample-size / assumption diagnostics{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
The data must be {helpb xtset} and {bf:balanced} on the estimation sample.{p_end}


{marker description}{title:Description}

{pstd}
{cmd:xtflucbreak} implements the fluctuation test of {bf:Li, Xiao and Chen (2024)} for a
structural change at an {it:unknown} date in the heterogeneous panel regression

{p 12 12 2}
y{sub:it} = x{sub:it}'({&beta}{sub:i} + {&delta}{sub:i}{c 183}1{c 123}t > k{sub:0}{c 125}) + e{sub:it},
{space 4}i = 1,...,N,{space 2}t = 1,...,T,

{pstd}
where every panel has its own slope vector {&beta}{sub:i}. The null is
H{sub:0}: {&delta}{sub:i} = 0 for all i; the alternative allows a break in a fraction
c > 0 of the panels.

{pstd}
The idea (Chu and White 1992; Ploberger, Kraemer and Kontrus 1989) is that if the
coefficients are constant, the recursive estimator {&beta}hat{sub:i}(k) computed on the
first k observations should not wander far from the full-sample {&beta}hat{sub:i}.
The command aggregates that wandering across panels,

{p 12 12 2}
S(k) = N{sup:-1/2} {&Sigma}{sub:i} (1/sigmahat{sub:i})(k/{&radic}T){c 183}Qhat{sub:i}{sup:1/2}({&beta}hat{sub:i}(k) - {&beta}hat{sub:i}),

{pstd}
which converges to a K-dimensional Brownian bridge under H{sub:0}. The null is rejected
when any component of max{sub:k}|S(k)| exceeds the Kolmogorov critical value at a
Sidak-adjusted level. The change point is estimated by the argmax of the same process.

{pstd}
Two branches are implemented in one command:

{p 8 12 2}
{bf:Section 3} (default) assumes no unobserved common factors: the panels are
cross-sectionally independent and OLS per panel is consistent.

{p 8 12 2}
{bf:Section 4} ({opt cce}) allows the regressors {it:and} the errors to load on
unobserved common factors. The factors are projected out with the cross-section averages
of (y, x) following Baltagi, Feng and Kao (2016), and the same statistic is computed on
the filtered data. This branch additionally needs {&radic}T/N {&rarr} 0.

{pstd}
{cmd:xtflucbreak} answers "{it:is there a break, and when?}". It does not estimate the
post-break slopes. For that, feed the estimated date to {helpb xtbfkbreak}, which
implements the Baltagi-Feng-Kao estimator that this paper's CCE branch is built on.


{marker options}{title:Options}

{dlgtab:Model}

{phang}
{opt cce} switches to the section-4 branch. The T{&times}(K+1) matrix of cross-section
averages Wbar = (ybar{sub:t}, xbar{sub:t}') is formed and the annihilator
M{sub:w} = I - Wbar(Wbar'Wbar){sup:-1}Wbar' is applied to y and to X before anything else.
Use it whenever a cross-sectional dependence test such as {helpb xtcd2} rejects, or when
the regressors are plausibly driven by common shocks. Note that under {opt cce} the
intercept is absorbed by M{sub:w} and is {it:not} among the tested coefficients.

{phang}
{opt nocceconstant} builds M{sub:w} from Wbar alone, exactly as printed in the paper.
The default adds a constant column, which is Pesaran's (2006) CCE augmentation and what
{helpb xtbfkbreak} does, so that the two commands agree numerically. With a slope break
the augmented projection also spans the regime-split factor space, which the bare Wbar
does not. Specify this option only to reproduce the literal display.

{phang}
{opt ccalags(#)} adds {it:#} lags of the cross-section averages to the projection, in the
spirit of Chudik and Pesaran's dynamic CCE. The first {it:#} periods are dropped, so T
falls by {it:#}. The paper uses no lags.

{phang}
{opt noconstant} removes the intercept from x{sub:it}. The paper's own Model 1 has
x{sub:it} = (1, x1{sub:it})', i.e. the intercept {it:is} one of the K tested coefficients,
which is the default here. Under {opt cce} this option has no effect.

{dlgtab:Test}

{phang}
{opt level(#)} sets the {it:overall} probability of a false alarm {&alpha}. The per-component
level is the Sidak correction {&alpha}* = 1 - (1-{&alpha}){sup:1/K}, exactly as in the
paper's Remark 3.5. With {&alpha} = 0.05 and K = 2 this gives {&alpha}* = 0.025321 and a
critical value of 1.4781 (the paper prints 1.4782).

{phang}
{opt trimming(#)} restricts the search to
{it:#}{c 183}T {&le} k {&le} (1-{it:#}){c 183}T. The paper's displays say
max{sub:1<k<T} with no trimming, but that cannot be what produced its published size
table: with the grid starting at k = K the recursive estimate is fitted on K observations
and the variance of S(k) there is roughly 10{sup:5} times the Brownian-bridge value, so
the test rejects almost always under H{sub:0}. Measured empirical size at the nominal 5%
level, LXC Model 1, iid errors, N = T = 50:

{p 12 12 2}
{cmd:trimming(0)} {&rarr} 0.674 {space 6} {cmd:trimming(0.05)} {&rarr} 0.140 {space 6}
{cmd:trimming(0.10)} {&rarr} 0.050 {space 6} {cmd:trimming(0.15)} {&rarr} 0.050

{pmore}
{cmd:trimming(0.10)} reproduces the paper's own Table 1 (0.050 iid, 0.070 unequal
variances, 0.062 GARCH against their 0.050 / 0.081 / 0.069), which is strong evidence that
this is what they did. It is therefore the default. The grid is additionally floored at the
first k for which X{sub:i}(k)'X{sub:i}(k) is invertible in {it:every} panel; the effective
range is printed in the header.

{phang}
{opt asymptotic} makes the {it:literal} LXC statistic the decision rule. By default
{cmd:xtflucbreak} rescales each component of S(k) by
{&radic}(s(1-s) / Var[S(k)]), where Var[S(k)] is the {it:exact} conditional variance
(1/N){&Sigma}{sub:i}(k{sup:2}/T){c 183}diag(Qhat{sub:i}{sup:1/2}(A{sub:ik}{sup:-1} -
A{sub:iT}{sup:-1})Qhat{sub:i}{sup:1/2}) rather than its asymptotic limit s(1-s). The two
coincide as (N,T) {&rarr} {&infin}, so the default {it:is} the paper's statistic
asymptotically; it differs only in finite samples, where the literal form is badly
oversized because E[A{sub:k}{sup:-1}] = {&Sigma}{sup:-1}/(k-K-1), not
{&Sigma}{sup:-1}/k. The literal statistic and its p-value are printed in every table and
returned in {cmd:r(stat_lxc)} and {cmd:r(p_lxc)}, so the paper's number is always
recoverable. Measured size at the nominal 5% level:

{p 8 12 2}
{space 24}{it:literal}{space 12}{it:default}{break}
{space 4}Model 1, N=T=50 {space 8}0.050{space 15}0.038{break}
{space 4}Model 1, N=50 T=25{space 6}0.255{space 15}0.028{break}
{space 4}Model 2 (CCE), N=T=50{space 3}0.100{space 15}0.062 {space 3}(LXC Table 6: 0.059){break}
{space 4}Model 2, N=200 T=50 {space 4}0.098{space 15}0.045

{pmore}
In the CCE branch the default also matches the paper's {it:power} table more closely
(0.870 against LXC Table 7's 0.870 for {&delta} = (0.2,0)', versus 0.912 for the literal
form). Use {cmd:asymptotic} only to reproduce a published number, never for inference on a
short panel.

{phang}
{opt nosigmascale} drops the 1/sigmahat{sub:i} factor. The paper's section-4 statistic as
typeset has no such factor, but Theorem 4.8 claims a {it:standard} Brownian bridge limit,
which cannot hold without it unless {&sigma}{sub:i} {&equiv} 1. The default therefore keeps
the scaling in both branches. See {help xtflucbreak_methods:help xtflucbreak methods}.

{phang}
{opt cholesky} replaces the symmetric square root of Qhat{sub:i} by its Cholesky factor.
Both satisfy AA' = Qhat{sub:i} and both give an asymptotically standard bridge, but the
components differ. With the {it:symmetric} root (the default, and the natural reading of
Qhat{sup:1/2}) the value of max{sub:j} is invariant to the order of the regressors. With
the Cholesky factor it is not, but component 1 then involves only the first regressor,
component 2 only the first two, and so on, which can be easier to interpret.

{dlgtab:Benchmarks}

{phang}
{opt compare} adds the three tests that Li, Xiao and Chen benchmark against in their
Tables 1-9: two Wald-type statistics and a CUSUM statistic from Antoch et al. (2018),
each with wild-bootstrap critical values. They are computed on the {bf:raw}, untransformed
data with an intercept, which is exactly the configuration used in the paper's tables --
Antoch et al. have no CCE variant, and their loss of power under common factors is the
point of the comparison.

{phang}
{opt reps(#)} and {opt seed(#)} control the wild bootstrap. Antoch et al. use B = 1000.

{dlgtab:Reporting}

{phang}
{opt graph} draws up to four figures: the fluctuation paths |S(k){sup:(j)}| with the
critical band, the ||V(k)|| change-point profile, the panel-level shifts at khat, and
(with {opt compare}) the three benchmark detection processes.

{phang}
{opt showunits} adds a table of ||{&delta}hat{sub:i}|| and sigmahat{sub:i} per panel.
The full vectors are always available in {cmd:r(shift)} and {cmd:r(sigma)}.


{marker output}{title:Interpreting the output}

{pstd}{bf:Header block.} Confirms which branch ran, how the CCE filter was built, which
square root was used, whether the sigma scaling is on, and the effective search grid
{it:k = klo ... khi}. It also prints T/N and {&radic}T/N, the two ratios the asymptotics
depend on.

{pstd}{bf:Fluctuation statistic table.} One row per component j of
Qhat{sub:i}{sup:1/2}({&beta}hat{sub:i}(k) - {&beta}hat{sub:i}). The arrow marks the
component attaining the overall maximum.

{p 8 12 2}
{it:Statistic} is max{sub:k}|S(k){sup:(j)}| over the admissible grid, on the
finite-sample standardised scale (see {opt asymptotic}). The last column,
{it:LXC as printed}, is the same maximum on the paper's literal scale.

{p 8 12 2}
{it:Crit. value} is the same C{sub:1}({&alpha}*) for every component -- it is a
{it:per-component} threshold, and the Sidak adjustment is what keeps the {it:family-wise}
error at {&alpha}.

{p 8 12 2}
{it:p-value} is the Kolmogorov tail probability of that component's statistic. The overall
p-value at the foot of the table is 1 - (1 - min{sub:j}p{sub:j}){sup:K}, the exact inverse
of the Sidak rule: it is below {&alpha} if and only if some component exceeds
C{sub:1}({&alpha}*).

{pstd}
{bf:A component is not a regressor.} Qhat{sub:i}{sup:1/2} rotates the coefficient
deviations, and the rotation differs across panels, so "component 2 rejected" does not mean
"the second regressor broke". Use the shift table (below) for statements about individual
coefficients, or {opt cholesky} for a partially triangular reading.

{pstd}{bf:Change-point block.} khat = argmax{sub:k}||V(k)||, where
V(k) = {&radic}(NT){c 183}S(k). Because the model is
{&delta}{sub:i}1{c 123}t > k{sub:0}{c 125}, khat is the {bf:last pre-break period}; the
regime switches at khat+1. Both dates are printed on the time variable's own scale.
No confidence interval is given: the paper proves consistency (Theorem 3.8/4.12) but
explicitly leaves the limiting distribution of khat to future research.

{pstd}{bf:Panel shift block.} For each component, the mean, standard deviation and
percentage positive of
{&delta}hat{sub:i} = {&beta}hat{sub:i}(khat+1..T) - {&beta}hat{sub:i}(1..khat), an
unrestricted regime contrast in the {it:original} coefficient space. The sign-concordance
figure matters: S(k) aggregates {it:signed} deviations across i, so breaks running in
opposite directions cancel. A near 50/50 split means the test was working against itself,
and a non-rejection in that configuration is weak evidence.

{pstd}{bf:Benchmark block} ({opt compare}). Wald 1, Wald 2 and CUSUM with bootstrap
critical values and p-values. The three statistics live on very different scales by
construction (different weighting matrices C{sub:i,t}); compare each to its own critical
value, never to each other.

{pstd}{bf:Diagnostics.} Warnings fire when T < 50 (below the smallest T in the paper's
Monte Carlo), when {&radic}T/N is not small under {opt cce} (Theorem 4.8's rate condition),
when N < 20 (the aggregation over i is a CLT), and when khat lands on the edge of the grid.


{marker remarks}{title:Remarks and practical guidance}

{pstd}{bf:Which branch?} Run a cross-sectional dependence test first
({helpb xtcd2}, or {cmd:xttestpanel csd}). If it rejects, use {opt cce}: the section-3
statistic is not merely inefficient under common factors, it is built on inconsistent
per-panel OLS. If it does not reject, the section-3 branch is the more powerful of the two
-- the paper's Table 7 shows power falling markedly once the factors are there.

{pstd}{bf:Sample size.} The paper's designs are N, T {&isin} {c 123}50, 100, 200{c 125}.
Power at k{sub:0} = T/2 is essentially 1 in the no-CCE branch even at N = T = 50, and
0.38-0.87 in the CCE branch depending on where the break sits in the coefficient vector.
Power is lowest for breaks near an endpoint (Table 4) and when only a fraction of panels
break (Tables 5 and 9). The precision of khat improves mainly with {bf:N}, not T
(Figures 4-6).

{pstd}{bf:Balanced panels only.} S(k) sums over i at a common k, so all panels must share
the same time grid. Unbalanced data is refused rather than silently mishandled.

{pstd}{bf:One break.} The theory covers a single change point. A rejection is consistent
with several breaks, gradual change, or a break in a subset of panels; the argmax will
then pick the dominant one. Re-running on sub-periods around khat is the practical
diagnostic.

{pstd}{bf:Errors.} Assumption 3.1 needs a martingale-difference {&epsilon}{sub:it} with
constant conditional variance per panel; it does {it:not} need homoskedasticity across
panels, and the paper's simulations confirm the test survives panel-specific variances and
GARCH(1,1). It does {it:not} allow serial correlation in {&epsilon}{sub:it}; if you suspect
it, model it (add lags) rather than relying on the test.

{pstd}{bf:What to do after a rejection.} Take khat to {helpb xtbfkbreak} for regime-wise
CCE mean-group slopes and a break-date confidence interval:

{p 8 12 2}{cmd:. xtflucbreak y x1 x2, cce}{p_end}
{p 8 12 2}{cmd:. xtbfkbreak y x1 x2, breaks(1)}{p_end}

{pstd}{bf:Departures from the printed paper.} Three, all documented with the evidence in
{help xtflucbreak_methods:help xtflucbreak methods}, and two of them switchable:

{p 8 12 2}
(1) The absolute value is taken {it:outside} the sum over panels, as Theorem 3.4 requires;
inside, as Remark 3.5 typesets it, the statistic diverges under H{sub:0}. No switch --
the literal form has no valid critical value.

{p 8 12 2}
(2) The 1/sigmahat{sub:i} scaling is retained in the CCE branch, which Theorem 4.8's
standard-bridge claim requires but the printed statistic omits. Switch:
{cmd:nosigmascale}.

{p 8 12 2}
(3) Each component is standardised by its exact finite-sample variance rather than by the
asymptotic s(1-s), and the search grid is trimmed 10% by default. Without these the test
has empirical size 0.67 at N = T = 50 and 0.26 at T = 25. Switches: {cmd:asymptotic} and
{cmd:trimming()}. The literal statistic is reported regardless.


{marker examples}{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}The basic test{p_end}
{phang2}{cmd:. xtflucbreak invest mvalue kstock}{p_end}

{pstd}With every figure and the per-panel table{p_end}
{phang2}{cmd:. xtflucbreak invest mvalue kstock, graph showunits}{p_end}

{pstd}Allowing unobserved common factors{p_end}
{phang2}{cmd:. xtflucbreak invest mvalue kstock, cce}{p_end}

{pstd}Against the Wald and CUSUM benchmarks{p_end}
{phang2}{cmd:. xtflucbreak invest mvalue kstock, compare reps(999) seed(12345)}{p_end}

{pstd}At the 1% level, trimming 10% of the sample at each end{p_end}
{phang2}{cmd:. xtflucbreak invest mvalue kstock, level(1) trimming(0.1)}{p_end}

{pstd}As postestimation, reusing the model in memory{p_end}
{phang2}{cmd:. xtreg invest mvalue kstock, fe}{p_end}
{phang2}{cmd:. xtflucbreak}{p_end}

{pstd}Then estimate the regimes at the detected date{p_end}
{phang2}{cmd:. xtflucbreak invest mvalue kstock, cce}{p_end}
{phang2}{cmd:. xtbfkbreak invest mvalue kstock, breaks(1)}{p_end}

{pstd}A full simulated demonstration reproducing both Monte Carlo designs of the paper is
in the ancillary file {bf:xtflucbreak_example.do}, retrievable with
{cmd:net get xtflucbreak}.


{marker results}{title:Stored results}

{pstd}{cmd:xtflucbreak} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}max over components of max{sub:k}|S(k)| (decision statistic){p_end}
{synopt:{cmd:r(stat_lxc)}}the same maximum on the literal LXC scale{p_end}
{synopt:{cmd:r(p_lxc)}}its Sidak p-value{p_end}
{synopt:{cmd:r(cv)}}critical value C{sub:1}({&alpha}*){p_end}
{synopt:{cmd:r(p)}}overall Sidak p-value{p_end}
{synopt:{cmd:r(alphastar)}}per-component level {&alpha}*{p_end}
{synopt:{cmd:r(level)}}overall level in percent{p_end}
{synopt:{cmd:r(reject)}}1 if H{sub:0} is rejected, 0 otherwise{p_end}
{synopt:{cmd:r(khat)}}estimated change point, as an index 1..T{p_end}
{synopt:{cmd:r(breakdate)}}last pre-break period on the time variable's scale{p_end}
{synopt:{cmd:r(breakpost)}}first post-break period{p_end}
{synopt:{cmd:r(kfrac)}}khat/T{p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}periods per panel used (net of {opt ccalags()}){p_end}
{synopt:{cmd:r(K)}}number of tested coefficients{p_end}
{synopt:{cmd:r(kmin)}}, {cmd:r(kmax)} bounds of the admissible search grid{p_end}
{synopt:{cmd:r(jmax)}}component attaining the maximum{p_end}
{synopt:{cmd:r(fracpos)}}sign-concordance index of the panel shifts{p_end}
{synopt:{cmd:r(wald1)}}, {cmd:r(wald1_cv)}, {cmd:r(wald1_p)} Wald 1 ({opt compare}){p_end}
{synopt:{cmd:r(wald2)}}, {cmd:r(wald2_cv)}, {cmd:r(wald2_p)} Wald 2 ({opt compare}){p_end}
{synopt:{cmd:r(cusum)}}, {cmd:r(cusum_cv)}, {cmd:r(cusum_p)} CUSUM ({opt compare}){p_end}
{synopt:{cmd:r(reps)}}bootstrap replications ({opt compare}){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtflucbreak}{p_end}
{synopt:{cmd:r(cmdline)}}command as typed{p_end}
{synopt:{cmd:r(depvar)}}, {cmd:r(indepvars)}, {cmd:r(panelvar)}, {cmd:r(timevar)}{p_end}
{synopt:{cmd:r(transform)}}{cmd:none} or {cmd:CCE (...)}{p_end}
{synopt:{cmd:r(root)}}{cmd:symmetric} or {cmd:cholesky}{p_end}
{synopt:{cmd:r(sigmascale)}}1 if the 1/sigmahat{sub:i} scaling was applied{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(S)}}grid {&times} (2K+2): k, time value, the K decision-scale components of
S(k), then the K literal-LXC components{p_end}
{synopt:{cmd:r(V)}}grid {&times} 3: k, time value, ||V(k)||{p_end}
{synopt:{cmd:r(stats)}}K {&times} 5: statistic, critical value, p-value, reject, literal-LXC
statistic{p_end}
{synopt:{cmd:r(bi)}}N {&times} (K+1): panel id, full-sample {&beta}hat{sub:i}{p_end}
{synopt:{cmd:r(shift)}}(N+3) {&times} (K+1): panel id and {&delta}hat{sub:i}; the last three
rows are the mean, sd and percent positive{p_end}
{synopt:{cmd:r(sigma)}}N {&times} 2: panel id, sigmahat{sub:i}{p_end}
{synopt:{cmd:r(compare)}}3 {&times} 3: statistic, bootstrap cv, bootstrap p for Wald 1,
Wald 2, CUSUM ({opt compare}){p_end}
{synopt:{cmd:r(cprofile)}}grid {&times} 5: t, time value, |Wald 1|, |Wald 2|, |CUSUM|
processes ({opt compare}){p_end}
{p2colreset}{...}


{marker references}{title:References}

{phang}
Antoch, J., J. Hanousek, L. Horvath, M. Huskova, and S. Wang. 2018.
Structural breaks in panel data: Large number of panels and short length time series.
{it:Econometric Reviews} 38(7): 828-855.

{phang}
Baltagi, B. H., Q. Feng, and C. Kao. 2016.
Estimation of heterogeneous panels with structural breaks.
{it:Journal of Econometrics} 191: 176-195.

{phang}
Chu, C.-S. J., and H. White. 1992.
A direct test for changing trend.
{it:Journal of Business and Economic Statistics} 10: 289-299.

{phang}
Leisch, F., K. Hornik, and C.-M. Kuan. 2000.
Monitoring structural changes with the generalized fluctuation test.
{it:Econometric Theory} 16: 835-854.

{phang}
Li, F., Y. Xiao, and Z. Chen. 2024.
A fluctuation test for structural change detection in heterogeneous panel data models.
{it:Journal of Systems Science and Complexity} 37(3): 1184-1208.

{phang}
Pesaran, M. H. 2006.
Estimation and inference in large heterogeneous panels with a multifactor error structure.
{it:Econometrica} 74: 967-1012.


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Bug reports and suggestions are welcome.


{title:Also see}

{psee}
Manual: {manhelp xtset XT}, {manhelp xtreg XT}

{psee}
Online: {help xtflucbreak_methods:xtflucbreak methods},
{help xtflucbreak_postestimation:xtflucbreak postestimation},
{helpb xtbfkbreak}, {helpb xtcombreak}, {helpb xtreg}
