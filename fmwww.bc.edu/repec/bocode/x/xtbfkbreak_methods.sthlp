{smcl}
{* *! xtbfkbreak version 1.0.0  11jul2026}{...}
{vieweralsosee "xtbfkbreak" "help xtbfkbreak"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{vieweralsosee "xtbreak" "help xtbreak"}{...}
{viewerjumpto "Overview" "xtbfkbreak_methods##overview"}{...}
{viewerjumpto "Notation and model" "xtbfkbreak_methods##notation"}{...}
{viewerjumpto "Step 1: the CCE transformation" "xtbfkbreak_methods##step1"}{...}
{viewerjumpto "Step 2: estimating the break dates" "xtbfkbreak_methods##step2"}{...}
{viewerjumpto "Step 3: the regime slopes" "xtbfkbreak_methods##step3"}{...}
{viewerjumpto "Endogeneity and IV equivalence" "xtbfkbreak_methods##iv"}{...}
{viewerjumpto "Breaks in the factor loadings" "xtbfkbreak_methods##loadings"}{...}
{viewerjumpto "Asymptotics" "xtbfkbreak_methods##asymptotics"}{...}
{viewerjumpto "Equation map" "xtbfkbreak_methods##map"}{...}
{viewerjumpto "Author" "xtbfkbreak_methods##author"}{...}
{title:Title}

{phang}
{bf:xtbfkbreak methods} {hline 2} Estimation mathematics behind
{helpb xtbfkbreak}{p_end}

{pstd}
This page documents the estimator implemented by {helpb xtbfkbreak}, mapping each
step to the equations of Baltagi, Feng & Kao (2016, 2019).  For syntax, options
and interpretation see {help xtbfkbreak:xtbfkbreak}.

{marker overview}{...}
{title:Overview}

{pstd}
The estimand is a heterogeneous panel with slope coefficients that shift at one or
more {it:common} unknown dates, and cross-sectional dependence coming from an
unobserved multifactor error structure.  The estimator has three steps:
{bf:(1)} partial the factors out with cross-section averages (CCE); {bf:(2)}
estimate the break date(s) by least squares on the transformed data; {bf:(3)}
estimate the regime slopes panel-by-panel and average them (mean group).  A break
in the factor {it:loadings} requires no extra machinery because CCE removes the
factors rather than estimating them.

{marker notation}{...}
{title:Notation and model}

{pstd}
For {it:i}=1,...,N and {it:t}=1,...,T, with a slope break at {it:k0} and (possibly
different) loading break at {it:k1}:

{p 8 8 2}{it:y(it)} = {it:x(it)}'{it:b(i)}(k0) + {it:e(it)},{p_end}
{p 8 8 2}{it:e(it)} = {it:g(i)}(k1)'{it:f(t)} + {it:eps(it)},{p_end}
{p 8 8 2}{it:x(it)} = {it:G(i)}'{it:f(t)} + {it:v(it)},{p_end}

{pstd}
where {it:b(i)}(k0) equals {it:b1(i)} for {it:t}{c 264}{it:k0} and {it:b2(i)}
afterwards, {it:f(t)} is an {it:m}-vector of unobserved factors, {it:g(i)} and
{it:G(i)} are heterogeneous loadings, and {it:eps} and {it:v} are idiosyncratic
errors.  In the 2019 model {it:eps(it)} and {it:v(it)} may be correlated, so
{it:x(it)} is endogenous both through {it:f(t)} and directly through
{cmd:Cov(}{it:eps},{it:v}{cmd:)}{cmd:!=}0.  Stacking over {it:t} gives, for each
panel, {it:Y(i)} = {it:X(i)}{it:b(i)} + {it:F g(i)} + {it:eps(i)}.

{marker step1}{...}
{title:Step 1: the CCE transformation}

{pstd}
Collect {it:w(it)}=({it:y(it)},{it:x(it)}',{it:z(it)}')' and form the
cross-section averages {it:wbar(t)}.  Combining the equations,
{it:wbar(t)} = {it:C(k0,k1)}'{it:f(t)} + {it:ubar(t)}, where the averaging matrix
{it:C} inherits the regime structure of the model.  By Pesaran's Lemma 1 the
averaged idiosyncratic terms vanish, {it:ubar(t)} {&rarr} 0 as {it:N}{&rarr}{&infin},
{it:regardless of the correlation between eps and v}.  Hence {it:wbar(t)} is a
valid proxy for {it:f(t)} even under endogeneity.

{pstd}
Let {it:W} be the T{c 215}({it:p}+1+...) matrix whose columns are a
{bf:constant}, the cross-section averages of {it:y}, of the regressors, and of the
instruments, and (optionally) {it:#} lags of these.  Define the annihilator

{p 12 12 2}{it:Mw} = {it:I(T)} - {it:W}({it:W}'{it:W}){c 94}(-1){it:W}'.{p_end}

{pstd}
Premultiplying the model by {it:Mw} wipes out {it:F}: each element of
{it:Mw F g(i)} is {it:Op}(1/{it:sqrt(N)}) and vanishes (BFK 2016 Lemma 6; BFK 2019
eq. 19).  {bf:Why the constant is in} {it:W}{bf::} under a break the factor enters
in two directions, {it:f} and {it:f}{c 215}1{c 123}{it:t}>{it:k}{c 125}, so
{it:W} must span {c 123}1, {it:f}, {it:f}{c 215}1{c 123}{it:t}>{it:k}{c 125}{c 125};
including the constant (Pesaran's augmentation on [1,{it:ybar},{it:xbar}]) provides
the extra dimension and removes the regime-split factor.  Omitting it biases the
slopes while leaving the break date consistent.  When {opt nocce} is used,
{it:Mw}={it:I}.

{marker step2}{...}
{title:Step 2: estimating the break dates}

{pstd}
On the transformed data the break date solves

{p 12 12 2}{it:khat} = argmin(k) {it:{&Sigma}(i) SSR(i)(k)},{p_end}

{pstd}
where {it:SSR(i)(k)} is the residual sum of squares from regressing the
transformed {it:y} on a regime-split design (BFK 2016 eq. 24; BFK 2019 eq. 21).
The search is by {bf:OLS} by default: following Perron & Yamamoto (2015), the OLS
break estimator stays consistent even when the regressors are endogenous, because
a shift in the true slope implies a shift in the OLS pseudo-true value at the same
date.  Candidate dates are restricted so every regime has at least
{opt trim()}{c 215}T periods.  With multiple breaks the dates are added one at a
time (Bai 2010): each new break maximises the reduction in the pooled SSR given
the breaks already found.  {opt ivbreak} replaces OLS by 2SLS in this step (BFK
2019, Fig. 2), which is offered only for comparison.

{pstd}
{bf:Super-consistency.}  In a single time series only the break {it:fraction}
{it:k0}/T is estimable.  Pooling N series that share the break lets the pooled
objective concentrate on the exact date: {it:P}({it:khat}={it:k0}){&rarr}1 (BFK
2016 Theorem 1; BFK 2019 Theorem 1).  This is what lets Step 3 treat the date as
if known.

{marker step3}{...}
{title:Step 3: the regime slopes}

{pstd}
Given {it:khat}, the design is built {bf:regime by regime and then transformed}:
for each regime {it:r} the raw block [1{c 123}reg {it:r}{c 125},
{it:x}{c 215}1{c 123}reg {it:r}{c 125}] is premultiplied by {it:Mw}
(transform-after-split, BFK eq. 20-23), giving each regime its own intercept and
slopes.  For panel {it:i} the slope block is

{p 12 12 2}{it:bhat(i)} = ({it:Xtil(i)}'{it:Xtil(i)}){c 94}(-1){it:Xtil(i)}'{it:Ytil(i)}   (exogenous),{p_end}

{pstd}
or the 2SLS analogue under endogeneity (below).  The {bf:mean-group} estimator and
its variance are

{p 12 12 2}{it:bMG} = (1/N){it:{&Sigma}(i) bhat(i)},{p_end}
{p 12 12 2}{it:Var(bMG)} = (1/[N(N-1)]) {it:{&Sigma}(i)} ({it:bhat(i)}-{it:bMG})({it:bhat(i)}-{it:bMG})',{p_end}

{pstd}
the non-parametric MG variance of Pesaran (2006).  Because {it:khat} is
super-consistent, {it:bMG} has the same limiting distribution as if {it:k0} were
known (BFK 2016 Prop. 2; BFK 2019 Prop. 1), so no correction for the estimated
date is needed.  The reported structural-change contrast {&delta} = {it:b2}-{it:b1}
uses the corresponding block of {it:Var(bMG)}.

{marker iv}{...}
{title:Endogeneity and the IV equivalence}

{pstd}
Under endogeneity Step 3 uses per-regime 2SLS with instruments {it:Ztil}={it:Mw
Z} (the exogenous regressors instrument themselves).  {cmd:xtbfkbreak} transforms
everything by {it:Mw} first and then runs 2SLS.  This is {it:numerically
identical} to BFK (2019) eq. 23, which projects on the instruments {it:and} the
cross-section averages {it:W}: since {it:Pw Mw}=0 one has
{it:P[Z,W]}({it:Mw X}) = {it:P(Mw Z)}({it:Mw X}), and because the fitted values lie
in the range of {it:Mw} the two estimators coincide.  In words, the cross-section
averages enter the first stage {it:implicitly} through {it:Mw}.  A practical
consequence: an instrument helps only through the part of it left after {it:Mw}
and the regime intercepts remove the factors and the fixed effect - it must move
the regressor's {it:idiosyncratic} component (see the
{help xtbfkbreak##remarks:instruments} remark).

{marker loadings}{...}
{title:Breaks in the factor loadings}

{pstd}
A break in {it:g(i)} at {it:k1}{c 33}={it:k0} is handled automatically.  Because
CCE removes the factors rather than estimating them, a loading break only enlarges
the effective factor space (Breitung & Eickmeier 2011); as long as the
{help xtbfkbreak##remarks:rank condition} holds with the enlarged set, {it:Mw}
still wipes the factors out and neither the break date nor the slopes are affected
(BFK 2019, Sec. 3.2).  This is the key point that distinguishes the CCE route from
interactive-fixed-effects approaches that must detect and model the loading break.

{marker asymptotics}{...}
{title:Asymptotics and requirements}

{pstd}
Results are joint ({it:N},{it:T}){&rarr}{&infin} with {it:sqrt(T)/N}{&rarr}0.  The
break-magnitude condition {it:{&phi}(N)}{&rarr}{&infin} rules out no-break-in-any-series;
the rank condition requires {it:m}{c 264}{it:p}+1 in each regime with non-zero mean
loadings.  The mean-group standard errors are reliable only for reasonably large
{it:N}.  The command does not test for the number of breaks nor report a
confidence interval for the date; see the guidance under
{help xtbfkbreak##remarks:Remarks}.

{marker map}{...}
{title:Equation map}

{p2colset 8 34 36 2}{...}
{p2col :{bf:Command step}}{bf:Paper equation}{p_end}
{p2col :CCE annihilator {it:Mw}}BFK16 eq. 20; BFK19 eq. 19{p_end}
{p2col :Pooled-SSR break search}BFK16 eq. 24; BFK19 eq. 21{p_end}
{p2col :Super-consistency of {it:khat}}BFK16 Thm 1; BFK19 Thm 1{p_end}
{p2col :Regime slopes (CCE)}BFK16 eq. 23{p_end}
{p2col :Regime slopes (CCE-IV)}BFK19 eq. 23-24{p_end}
{p2col :Mean group + MG variance}Pesaran (2006); BFK16 Prop. 2{p_end}
{p2col :Loading-break robustness}BFK19 Sec. 3.2, fn. 4{p_end}
{p2col :Multiple breaks (sequential)}BFK16 Sec. 5 (Bai 2010){p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}merwanroudane920@gmail.com{p_end}
{pstd}{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Back to {help xtbfkbreak:xtbfkbreak}.{p_end}
