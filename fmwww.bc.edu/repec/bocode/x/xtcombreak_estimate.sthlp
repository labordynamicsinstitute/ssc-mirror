{smcl}
{* *! version 1.0.0  17jul2026}{...}
{vieweralsosee "xtcombreak" "help xtcombreak"}{...}
{vieweralsosee "xtcombreak test" "help xtcombreak_test"}{...}
{vieweralsosee "xtcombreak methods" "help xtcombreak_methods"}{...}
{vieweralsosee "xtbreak" "help xtbreak"}{...}
{viewerjumpto "Syntax" "xtcombreak_estimate##syntax"}{...}
{viewerjumpto "Description" "xtcombreak_estimate##description"}{...}
{viewerjumpto "Options" "xtcombreak_estimate##options"}{...}
{viewerjumpto "Interpreting the output" "xtcombreak_estimate##output"}{...}
{viewerjumpto "Choosing an estimator" "xtcombreak_estimate##choose"}{...}
{viewerjumpto "Trimming" "xtcombreak_estimate##trim"}{...}
{viewerjumpto "Limitations" "xtcombreak_estimate##limits"}{...}
{viewerjumpto "Examples" "xtcombreak_estimate##examples"}{...}
{viewerjumpto "Stored results" "xtcombreak_estimate##results"}{...}
{viewerjumpto "Author" "xtcombreak_estimate##author"}{...}
{hline}
help for {hi:xtcombreak estimate}{right: version 1.0.0 - 17jul2026}
{hline}

{title:Title}

{p 4 4}{cmd:xtcombreak estimate} {hline 2} Estimate the common break date in
panel means and variances, with a confidence interval (Bai 2010).{p_end}


{marker syntax}{title:Syntax}

{p 4 13}{cmd:xtcombreak} {cmdab:est:imate} {depvar} {ifin}
[{cmd:,} {it:options}]{p_end}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt m:ethod(ls|qml|gls)}}break-date estimator; default {cmd:method(ls)}{p_end}
{synopt:{opt br:eaks(#)}}number of breaks; default {cmd:breaks(1)}{p_end}
{synopt:{opt trim:ming(#)}}minimum regime length as a fraction of T; default {cmd:trimming(0)}{p_end}
{syntab:Inference}
{synopt:{opt l:evel(#)}}confidence level: {bf:90}, {bf:95} or {bf:99} only; default 95{p_end}
{synopt:{opt an:method(het|hom)}}form of the scale {it:A_N}; default {cmd:anmethod(het)}{p_end}
{synopt:{opt ci:method(symmetric|literal)}}CI construction; default {cmd:cimethod(symmetric)}{p_end}
{synopt:{opt ch:ow}}report the per-series Chow test at the estimated break{p_end}
{syntab:Reporting}
{synopt:{opt show:index}}also report break positions as indices 1..T{p_end}
{synopt:{opt graph}}produce the profile and shift plots{p_end}
{synopt:{opt profname(name)}}name for the break-identification graph{p_end}
{synopt:{opt shiftname(name)}}name for the per-series shift graph{p_end}
{synoptline}

{p 4 4}The data must be {help xtset} as a {bf:balanced} panel.{p_end}

{p 4 4}{bf:{err}Note:} {cmd:estimate} takes {bf:exactly one} variable and refuses
an {indepvars} list. This is not a limitation of the implementation -- Bai (2010)
is a pure mean/variance-shift model with no regressors (his eq.1 and eq.15).
Silently accepting regressors would turn it into a different paper. For a common
break in {it:slopes} use {helpb xtcombreak_test:xtcombreak test},
{helpb xtbfkbreak} or {helpb xtbreak}.{p_end}


{marker description}{title:Description}

{p 4 4}{cmd:xtcombreak estimate} implements Bai (2010). The model is{p_end}

{p 8 8}Y{sub:it} = mu{sub:i1} + e{sub:it}{col 45}t = 1, ..., k0{p_end}
{p 8 8}Y{sub:it} = mu{sub:i2} + e{sub:it}{col 45}t = k0+1, ..., T{p_end}

{p 4 4}for i = 1..N. Every series breaks at the {bf:same} unknown date k0, but the
means mu{sub:i1}, mu{sub:i2} are {bf:heterogeneous} -- so the shift
mu{sub:i2}-mu{sub:i1} varies across units and may even be positive for some and
negative for others. This is a genuine incidental-parameter problem, and Bai's
contribution is that consistency survives it.{p_end}

{p 4 4}With {cmd:method(qml)} the model widens to allow a break in the
{bf:variance} as well (Bai eq.15):{p_end}

{p 8 8}Y{sub:it} = mu{sub:i1} + sigma{sub:i1}*eta{sub:it}{col 45}t <= k0{p_end}
{p 8 8}Y{sub:it} = mu{sub:i2} + sigma{sub:i2}*eta{sub:it}{col 45}t > k0{p_end}

{p 4 4}{ul:Why a panel changes everything}{p_end}

{p 4 4}In one time series, khat - k0 = O{sub:p}(1) no matter how much data you
have: the break {it:fraction} is estimable, the break {it:date} is not. Bai's
Theorem 3.1 shows that with a panel, {bf:P(khat = k0) -> 1} as N -> infinity. The
date itself is recovered. Identification needs only{p_end}

{p 8 8}N{sup:-1/2} * SUM{sub:i} (mu{sub:i2}-mu{sub:i1}){sup:2} -> infinity{p_end}

{p 4 4}(his Assumption 2), which notably does {bf:not} require every series to
break.{p_end}

{p 4 4}Consistency also holds when a regime contains a {bf:single observation}
(his Fig.2, T=10 and k0=9) -- useful when the goal is to detect the onset of a
new regime as early as possible, without waiting for data from it.{p_end}


{marker options}{title:Options}

{dlgtab:Model}

{p 4 8}{opt method(ls|qml|gls)} selects the estimator of the break date.{p_end}

{p 8 12}{cmd:ls} (default) minimises the pooled sum of squared residuals
SSR(k) = SUM{sub:i} S{sub:iT}(k) over k in [1, T-1] (Bai p.80). Requires no
distributional assumption beyond a few moments. Cannot detect a break that occurs
{it:only} in the variance.{p_end}

{p 8 12}{cmd:qml} minimises Bai's eq.(16),
U{sub:NT}(k) = k*SUM{sub:i} log sigma{sup:2}{sub:i1}(k) + (T-k)*SUM{sub:i} log
sigma{sup:2}{sub:i2}(k). It is consistent under a break in the mean {bf:or} in
the variance {bf:or} both (his Theorem 5.1), and is {bf:never less efficient} than
LS -- see {help xtcombreak_estimate##choose:choosing an estimator}.{p_end}

{p 8 12}{cmd:gls} is Bai's two-step feasible GLS (p.85): least squares gives khat,
then sigma{sup:2}{sub:i} = S{sub:iT}(khat)/(T-2), then the break is re-estimated
minimising SUM{sub:i} S{sub:iT}(k)/sigma{sup:2}{sub:i}. Bai shows it is
asymptotically equivalent to QML.{p_end}

{p 4 8}{opt breaks(#)} sets the number of breaks. With {cmd:breaks(1)} (default)
a single break is estimated. With #>1 the {bf:one-at-a-time} method of Bai (1997a),
described in his sec.6, adds breaks sequentially: at each step the location giving
the largest reduction in the pooled SSR is retained, and the estimates are
relabelled in ascending order. Bai derives {bf:no confidence interval} for
multiple breaks; the reported interval refers to the first break only.{p_end}

{p 4 8}{opt trimming(#)} imposes a minimum regime length of #*T observations.
Default {cmd:trimming(0)}. See {help xtcombreak_estimate##trim:Trimming} -- the
default is deliberate and departing from it is a departure from Bai.{p_end}

{dlgtab:Inference}

{p 4 8}{opt level(#)} sets the confidence level. Only {bf:90}, {bf:95} and
{bf:99} are accepted, and any other value is an error rather than an
interpolation. The reason is that Bai's interval is built from three simulated
constants{p_end}

{p 8 8}P(|l*| <= 7) ~ 0.90{break}
P(|l*| <= 11) ~ 0.95{break}
P(|l*| <= 20) ~ 0.99{p_end}

{p 4 8}where l* = argmin{sub:l}{c 123}|l| + 2W(l){c 125} and W is a two-sided
Gaussian {bf:random walk} (Bai p.83, his Fig.3). He tabulates only these three.
Inventing a constant for, say, 92% would not be his method.{p_end}

{p 4 8}{opt anmethod(het|hom)} selects the form of the scale A{sub:N}.{p_end}

{p 8 12}{cmd:het} (default) uses Bai's general expression (p.83){break}
{cmd:A_N = [SUM_i d_i^2]^2 / [SUM_i d_i^2 * sigma_i^2]}, with
d{sub:i} = mu{sub:i2}-mu{sub:i1}. Allows cross-sectional heteroskedasticity.{p_end}

{p 8 12}{cmd:hom} reproduces the formula Bai used in his own Monte Carlo (p.83),
{cmd:A_N = SUM_i d_i^2 / sigma^2} with the pooled
sigma{sup:2} = SUM{sub:i}SUM{sub:t} e{sup:2}{sub:it}/(NT-2N). This is the
homoskedastic special case: when sigma{sup:2}{sub:i} is constant the two agree
exactly, which Bai states on p.83. Use it to replicate his Table 1.{p_end}

{p 4 8}{opt cimethod(symmetric|literal)} selects how the interval is built from
the scale. {bf:This exists because Bai's eq.(13), read literally, is not what he
actually ran} -- it contradicts his own prose and his own Table 1.{p_end}

{p 8 12}{cmd:symmetric} (default) uses [khat - ceil(c/A), khat + ceil(c/A)]. This
{bf:reproduces Bai's published Table 1}: on 300 replications of his own p.83
design it returns his median lengths 9, 5, 5, 3 exactly (N = 5, 10, 15, 20 at the
90% level) and his coverage to within Monte Carlo error.{p_end}

{p 8 12}{cmd:literal} uses [khat - floor(c/A), khat + ceil(c/A)] exactly as
eq.(13) prints it. It is systematically {bf:one integer shorter} and under-covers:
0.797 / 0.863 / 0.890 / 0.927 against Bai's 0.829 / 0.900 / 0.937 / 0.949.{p_end}

{p 4 8}The giveaway is parity. Under {cmd:literal}, floor = ceil-1 whenever c/A is
not an integer, so the length 2*ceil is always {bf:even}; Bai's published lengths
are almost all {bf:odd}, which only 2*ceil+1 gives. And his p.84 sentence -- "the
shortest confidence interval ... would contain {bf:three} integers (khat-1, khat,
khat+1)" -- is true only of the symmetric form; the literal one bottoms out at two.
Full evidence in {helpb xtcombreak_methods##baici:help xtcombreak methods}.{p_end}

{p 4 8}{opt chow} adds the per-series Chow test at the estimated break. Bai (p.84)
shows the {it:standard} Chow test with ordinary chi2 critical values is valid
here, provided it is run series by series: as N grows, series i contributes only
O(1/N) of khat, so khat is asymptotically {bf:exogenous} for series i and needs no
correction for being estimated. The command warns when N is small enough
(N < 15) for that argument to be thin.{p_end}

{dlgtab:Reporting}

{p 4 8}{opt showindex} additionally reports break positions as indices 1..T rather
than only as values of the time variable.{p_end}

{p 4 8}{opt graph} produces two figures: a {bf:break-identification} plot (the
objective function against candidate dates, with khat and the CI marked) and a
{bf:per-series shift} plot (mu{sub:i2}-mu{sub:i1} for every unit, coloured by
whether the Chow test rejects). {opt profname()} and {opt shiftname()} rename
them so they can be {helpb graph combine}d.{p_end}


{marker output}{title:Interpreting the output}

{p 4 4}{ul:Header}{p_end}
{p 8 12}{bf:Estimator} -- LS, QML or feasible GLS.{p_end}
{p 8 12}{bf:T/N} -- the asymptotic regime. Bai's CI needs T large relative to N
(his eq.5). A note appears when T < N.{p_end}
{p 8 12}{bf:Trimming} -- "none (k in [1, T-1])" means Bai's literal estimator.{p_end}

{p 4 4}{ul:Estimated common break date}{p_end}
{p 8 12}{bf:Break date} -- khat in the units of your time variable, with the CI.{p_end}
{p 8 12}{bf:Break index} -- the same as a position 1..T ({cmd:showindex}).{p_end}
{p 8 12}{bf:Break fraction tau0} -- khat/T. Feed this to
{helpb xtcombreak_test:xtcombreak test} mentally: its critical values depend on
tau0 and are tabulated only over [0.20, 0.80].{p_end}
{p 8 12}The line below the table shows the constant used (7/11/20) and the
realised scale A. A {bf:wide} interval means a small A: either small breaks, few
series, or noisy series.{p_end}
{p 8 12}A CI of exactly three integers {c 123}khat-1, khat, khat+1{c 125} is the
{it:narrowest} the construction can produce, because of the floor/ceiling in Bai's
eq.(13). He notes this himself (p.84). It does not mean the break is known to
within one period; it means 7/A < 1.{p_end}

{p 4 4}{ul:Scale parameters and CI efficiency}{p_end}
{p 8 12}{bf:A_N} -- the least-squares scale. {bf:B_N} -- the QML/GLS scale.{p_end}
{p 8 12}{bf:B_N / A_N >= 1 always}, by Cauchy-Schwarz (Bai p.85). A larger scale
gives a {it:narrower} interval, so this ratio {bf:is} the efficiency gain from QML.
It equals 1 exactly when sigma{sup:2}{sub:i} is constant across i -- with
homoskedastic panels LS and QML coincide, which Bai states explicitly.{p_end}
{p 8 12}With {cmd:method(qml)} five more parameters appear -- {bf:tau} (mean-break
signal), {bf:omega} (variance-break signal), {bf:kappa} (4th cumulant of eta),
{bf:mu3} (3rd moment), {bf:pi} (mean/variance-break overlap). They feed Bai's
master scale, eq.(19). See {helpb xtcombreak_methods}.{p_end}

{p 4 4}{ul:Which series actually broke}{p_end}
{p 8 12}One row per series: the estimated shift, the Chow chi2(1), its p-value and
sigma{sup:2}{sub:i}. Bai's assumptions do {bf:not} require every series to break
(Assumption 2 needs only the sum to diverge), so a mix of rejections and
non-rejections is expected and is not a sign of trouble. Series with the largest
|shift| relative to sigma{sub:i} reject first. The full matrix is in
{cmd:r(chow)}.{p_end}


{marker choose}{title:Choosing an estimator}

{p 4 4}{ul:Use {cmd:method(qml)} unless you have a reason not to.}{p_end}

{p 4 4}Bai's efficiency result (p.85) is strong and easy to miss: {bf:QML is more
efficient than least squares even when there is no break in the variance at all}.
The reason is that QML is asymptotically minimising SUM{sub:i}
sigma{sup:-2}{sub:i} S{sub:iT}(k) -- a GLS criterion. It {bf:down-weights noisy
series}. LS treats a series with sigma{sub:i}=10 as informative as one with
sigma{sub:i}=0.1.{p_end}

{p 4 4}Formally A{sub:N} <= B{sub:N} by Cauchy-Schwarz, with equality iff
sigma{sup:2}{sub:i} is constant. So:{p_end}

{synoptset 22 tabbed}{...}
{synopt:{bf:Situation}}{bf:Choice}{p_end}
{synoptline}
{synopt:Homoskedastic panel}LS and QML are equivalent; either{p_end}
{synopt:Heteroskedastic panel}{cmd:qml} or {cmd:gls} -- strictly tighter CI{p_end}
{synopt:Variance may also break}{cmd:qml} -- LS is blind to a pure variance break{p_end}
{synopt:Reluctant to assume normality}{cmd:ls} or {cmd:gls}; QML is {it:quasi}-ML, so normality is not needed for consistency, but {cmd:ls} needs the fewest moments{p_end}
{synopt:Very short regimes wanted}{cmd:ls} -- QML needs 2 obs per regime (see below){p_end}
{synoptline}

{p 4 4}{ul:A trap Bai flags, worth repeating}{p_end}

{p 4 4}You might think that if the variance breaks, you should {it:weight} by the
regime-specific variance. Bai shows (p.85) that this weighted least squares
estimator, using even the {bf:true} sigma{sub:i1}, sigma{sub:i2}, is {bf:not
consistent}. His counter-example: mu{sub:i2}=2mu{sub:i1} and
sigma{sub:i2}=2sigma{sub:i1}. Dividing the second regime by 2 removes the break
from {it:both} the mean and the variance, so there is nothing left to find. LS and
QML both survive this; WLS does not. {cmd:xtcombreak} therefore offers no WLS
option.{p_end}


{marker trim}{title:Trimming: why the default is zero}

{p 4 4}Nearly every break command trims 15% of the sample at each end. Bai's does
not, and this is not an oversight -- it is the paper's headline. His abstract:
"Consistency is obtainable {bf:even when a regime contains a single observation},
making it possible to quickly identify the onset of a new regime." His Fig.2 shows
exactly this with T=10 and k0=9.{p_end}

{p 4 4}A command that trims 15% cannot even {it:consider} k0=9 when T=10, so it
cannot reproduce Bai. {cmd:trimming(0)} is therefore the faithful default and
{cmd:estimate} searches k in [1, T-1] exactly as Bai's p.80 defines.{p_end}

{p 4 4}{ul:When to depart from it}{p_end}

{p 8 12}o {bf:QML and GLS force a minimum of 2}, whatever you ask for. At k=1 the
first regime has one observation, so sigma{sup:2}{sub:i1}(1) = 0 exactly and
log(0) = -infinity: the QML objective is undefined at the boundary. Bai sidesteps
this by assuming k0 = [T*tau0] throughout his sec.5. The command applies the
minimum silently for {cmd:qml}/{cmd:gls} and skips any k where a variance estimate
is non-positive.{p_end}

{p 8 12}o {bf:If you want the conventional framework}, set {cmd:trimming(0.15)}.
Bai's Theorem 3.1 covers both: under Assumption 2 consistency holds "whether or not
k0 is restricted".{p_end}

{p 8 12}o {bf:To compare with {helpb xtbreak}} or {helpb xtbfkbreak}, match their
trimming (0.15 by default) or the break sets differ for reasons unrelated to the
estimator.{p_end}


{marker limits}{title:Limitations -- what Bai (2010) does not provide}

{p 4 4}These are stated rather than papered over:{p_end}

{p 8 12}1. {bf:No test that a break exists.} Bai (p.79): the focus is estimation
"given its existence". If you run {cmd:estimate} on a panel with no break you will
still get a khat and a CI -- both meaningless. Run
{helpb xtbreak_test:xtbreak test} first.{p_end}

{p 8 12}2. {bf:No test that the break is common.} Bai {it:assumes} it. Use
{helpb xtcombreak_test:xtcombreak test}.{p_end}

{p 8 12}3. {bf:No established way to choose the number of breaks.} Bai's sec.6:
"for panel data, the corresponding criteria are not well understood. Our
preliminary analysis shows that, under fixed T, the AIC criterion is consistent
and the BIC is not, contrary to conventional wisdom ... Further investigation is
called for." {cmd:breaks(#)} is therefore yours to set; no automatic IC selection
is offered, because Bai does not endorse one.{p_end}

{p 8 12}4. {bf:No CI for multiple breaks.} His eq.(13) is derived for a single
break.{p_end}

{p 8 12}5. {bf:Cross-sectional independence is assumed} (Assumption 1). Bai notes
consistency survives weak cross-sectional correlation, but the CI relies on a
central limit theorem across i.{p_end}

{p 8 12}6. {bf:Serial correlation affects the limiting distribution.} Bai's
Theorem 4.2 assumes e{sub:it} uncorrelated over t; under serial correlation the
theorem still holds but the normal variables become correlated, and the
correlations enter the distribution (p.82). The reported CI does not adjust for
this.{p_end}


{marker examples}{title:Examples}

{p 8}{cmd:. webuse grunfeld, clear}{p_end}
{p 8}{cmd:. xtset company year}{p_end}

{p 4 4}{ul:Basic}{p_end}
{p 8}{cmd:. xtcombreak estimate invest}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, showindex}{p_end}

{p 4 4}{ul:All three estimators on the same data}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, method(ls)}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, method(qml)}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, method(gls)}{p_end}

{p 4 4}{ul:Compare the CI efficiency of LS and QML}{p_end}
{p 8}{cmd:. quietly xtcombreak estimate invest, method(ls) level(90)}{p_end}
{p 8}{cmd:. scalar A = r(AN)}{p_end}
{p 8}{cmd:. quietly xtcombreak estimate invest, method(qml) level(90)}{p_end}
{p 8}{cmd:. scalar B = r(BN)}{p_end}
{p 8}{cmd:. display "B_N/A_N = " B/A "   (>= 1 always, = 1 iff homoskedastic)"}{p_end}

{p 4 4}{ul:Replicate Bai's own Monte Carlo formula}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, anmethod(hom)}{p_end}

{p 4 4}{ul:Which firms broke}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, chow}{p_end}
{p 8}{cmd:. matrix C = r(chow)}{p_end}
{p 8}{cmd:. matrix S = r(shift)}{p_end}
{p 8}{cmd:. matlist C}{p_end}

{p 4 4}{ul:Two breaks}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, breaks(2) showindex}{p_end}

{p 4 4}{ul:Conventional trimming, to line up with xtbreak}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, trimming(0.15)}{p_end}
{p 8}{cmd:. xtbreak estimate invest, breaks(1)}{p_end}

{p 4 4}{ul:Graphs}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, method(qml) chow graph}{p_end}
{p 8}{cmd:. graph combine xtcb_profile xtcb_shift}{p_end}


{marker results}{title:Stored results}

{p 4 4}{cmd:xtcombreak estimate} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of series{p_end}
{synopt:{cmd:r(T)}}number of periods{p_end}
{synopt:{cmd:r(khat)}}estimated break index (1..T){p_end}
{synopt:{cmd:r(k_breaks)}}number of breaks estimated{p_end}
{synopt:{cmd:r(nties)}}number of k attaining the minimum{p_end}
{synopt:{cmd:r(AN)}}A_N, the least-squares scale (Bai p.83){p_end}
{synopt:{cmd:r(BN)}}B_N, the QML/GLS scale (Bai p.85){p_end}
{synopt:{cmd:r(scale)}}the scale actually used for the CI{p_end}
{synopt:{cmd:r(tau)}}tau, the mean-break signal (Bai p.84){p_end}
{synopt:{cmd:r(omega)}}omega, the variance-break signal{p_end}
{synopt:{cmd:r(kappa)}}kappa, 4th cumulant of eta{p_end}
{synopt:{cmd:r(mu3)}}mu3, 3rd moment of eta{p_end}
{synopt:{cmd:r(piprm)}}pi, mean/variance-break overlap (Bai eq.19){p_end}
{synopt:{cmd:r(ssr)}}minimised objective{p_end}
{synopt:{cmd:r(TNratio)}}T/N{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtcombreak estimate}{p_end}
{synopt:{cmd:r(method)}}{cmd:ls}, {cmd:qml} or {cmd:gls}{p_end}
{synopt:{cmd:r(anmethod)}}{cmd:het} or {cmd:hom}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(panelvar)}}panel variable{p_end}
{synopt:{cmd:r(timevar)}}time variable{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(breakdates)}}2 x #breaks: row 1 = dates, row 2 = indices{p_end}
{synopt:{cmd:r(ci)}}1 x 4: lower date, upper date, lower index, upper index{p_end}
{synopt:{cmd:r(ssrprofile)}}the objective by candidate date (2 columns){p_end}
{synopt:{cmd:r(shift)}}N x 4: id, mu_i2-mu_i1, mu_i1, mu_i2{p_end}
{synopt:{cmd:r(chow)}}N x 4: id, chi2(1), p-value, sigma_i^2{p_end}
{synopt:{cmd:r(sigma2)}}N x 4: id, sigma_i^2, sigma_i1^2, sigma_i2^2{p_end}
{p2colreset}{...}


{marker author}{title:Author}

{p 4}Dr Merwan Roudane{p_end}
{p 4}merwanroudane920@gmail.com{p_end}
{p 4}{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
