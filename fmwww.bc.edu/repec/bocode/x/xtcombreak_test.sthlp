{smcl}
{* *! version 1.0.0  17jul2026}{...}
{vieweralsosee "xtcombreak" "help xtcombreak"}{...}
{vieweralsosee "xtcombreak estimate" "help xtcombreak_estimate"}{...}
{vieweralsosee "xtcombreak methods" "help xtcombreak_methods"}{...}
{vieweralsosee "xtbreak" "help xtbreak"}{...}
{viewerjumpto "Syntax" "xtcombreak_test##syntax"}{...}
{viewerjumpto "Description" "xtcombreak_test##description"}{...}
{viewerjumpto "Options" "xtcombreak_test##options"}{...}
{viewerjumpto "Interpreting the output" "xtcombreak_test##output"}{...}
{viewerjumpto "Power: when this test fails you" "xtcombreak_test##power"}{...}
{viewerjumpto "What a rejection does not tell you" "xtcombreak_test##ambig"}{...}
{viewerjumpto "The pre-test problem" "xtcombreak_test##pretest"}{...}
{viewerjumpto "Examples" "xtcombreak_test##examples"}{...}
{viewerjumpto "Stored results" "xtcombreak_test##results"}{...}
{viewerjumpto "Author" "xtcombreak_test##author"}{...}
{hline}
help for {hi:xtcombreak test}{right: version 1.0.0 - 17jul2026}
{hline}

{title:Title}

{p 4 4}{cmd:xtcombreak test} {hline 2} Test the null that the structural break
occurs at a {bf:common} date across all units of a heterogeneous panel
(Jiang and Kurozumi 2026).{p_end}


{marker syntax}{title:Syntax}

{p 4 13}{cmd:xtcombreak} {cmd:test} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]{p_end}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt trim:ming(#)}}trimming {it:eps} defining {it:Lambda(eps)}; default {cmd:trimming(0.1)}{p_end}
{synopt:{opt nocons:tant}}suppress the constant in x{sub:it}{p_end}
{syntab:Critical values}
{synopt:{opt sim:ulate}}simulate critical values and a p-value from JK's Theorem 1{p_end}
{synopt:{opt reps(#)}}replications for {cmd:simulate}; default 2000{p_end}
{synopt:{opt grid:points(#)}}grid points approximating the Brownian motions; default 1000{p_end}
{synopt:{opt seed(#)}}seed for {cmd:simulate}{p_end}
{synopt:{opt l:evel(#)}}level flagged in the output: {bf:10}, {bf:5} or {bf:1}; default 5{p_end}
{syntab:Reporting}
{synopt:{opt show:index}}also report the break as an index 1..T{p_end}
{synopt:{opt graph}}CUSUM-process and shift-direction plots{p_end}
{synopt:{opt cusumname(name)}}name for the CUSUM graph{p_end}
{synopt:{opt shiftname(name)}}name for the shift-direction graph{p_end}
{synoptline}

{p 4 4}At least one {indepvars} is required. The data must be {help xtset} as a
{bf:balanced} panel.{p_end}


{marker description}{title:Description}

{p 4 4}{cmd:xtcombreak test} implements Jiang and Kurozumi (2026). The model is
their eq.(1),{p_end}

{p 8 8}y{sub:it} = x{sub:it}'b{sub:i} + x{sub:it}'d{sub:i}*1{c 123}t > k0{sub:i}{c 125} + u{sub:it}{p_end}

{p 4 4}with {bf:heterogeneous} coefficients b{sub:i}, d{sub:i} across units and a
possibly unit-specific break date k0{sub:i}. The hypotheses are{p_end}

{p 8 8}{bf:H0}: k0{sub:i} = k0 for all i{col 45}(the break is common){p_end}
{p 8 8}{bf:HA}: k0{sub:g1} != k0{sub:g2} for some groups{col 45}(dates differ){p_end}

{p 4 4}{ul:Why this test exists}{p_end}

{p 4 4}Every common-break method -- Bai (2010), Baltagi-Feng-Kao (2016), Kim
(2011, 2014), Qian-Su (2016) -- buys its precision by {it:assuming} all units break
together. Jiang and Kurozumi open by noting that, before their paper, "no study has
focused on the validity of the common break assumption in panels", while evidence
suggests break points "are likely to vary significantly across individuals". This
test fills that gap.{p_end}

{p 4 4}{ul:How it works}{p_end}

{p 4 4}The statistic takes khat from the pooled least-squares search (their eq.3),
forms the squared CUSUM of the two-regime OLS residuals, and divides by a
{bf:self-normaliser} built by refitting the model on {bf:four} regimes split at
k1 < khat < k2:{p_end}

{p 8 8}S{sub:NT}(khat) = sup US{sub:NT}(k,khat) / V{sub:NT}(k1,khat,k2){p_end}

{p 4 4}Under H0 khat is consistent, the residuals behave, and the statistic has a
non-degenerate limit. Under HA, khat gets {bf:trapped between} the true break dates
(their Proposition 1) and can never match all of them, so at least one group is
always fitted at the wrong date, the CUSUM diverges at rate NT while the
denominator stays O{sub:p}(1), and the test is consistent (their Theorem 2).{p_end}

{p 4 4}The self-normaliser exists for a specific reason. The natural alternative --
a kernel long-run-variance estimate -- is consistent under H0 but badly biased
under HA, so power {it:falls} as breaks grow: the non-monotonic power problem. By
constructing a normaliser proportional to sigma{sup:2}, the long-run variance
cancels and power is monotonic. This extends Shao and Zhang (2010).{p_end}


{marker options}{title:Options}

{dlgtab:Model}

{p 4 8}{opt trimming(#)} sets eps in the admissible set{p_end}

{p 8 8}Lambda(eps) = {c 123}[T*eps] <= k <= [T(1-eps)], [T*eps] <= k1 <= khat-[T*eps],
khat+[T*eps] <= k2 <= [T(1-eps)]{c 125}{p_end}

{p 4 8}Default {cmd:trimming(0.1)}, matching the paper. {bf:Changing it invalidates
the published critical values} -- JK's Table 1 is computed at eps = 0.1 only. If
you set anything else, {cmd:xtcombreak} refuses the table and requires
{cmd:simulate}, rather than silently reporting wrong critical values.{p_end}

{p 4 8}{opt noconstant} removes the constant from x{sub:it}. JK's sec.2 states
x{sub:it} "includ[es] a constant term; thus, the first element is unity for all
t", so the default keeps it. Use this only if your {indepvars} already contains
one.{p_end}

{dlgtab:Critical values}

{p 4 8}{opt simulate} simulates the limiting distribution of Theorem 1 directly
instead of reading the table, using JK's own recipe (approximating the Brownian
motions on a grid, over many replications). Use it when:{p_end}

{p 8 12}o {cmd:trimming()} is not 0.1 -- the table does not apply;{p_end}
{p 8 12}o tau0 = khat/T falls outside [0.20, 0.80] -- outside the table;{p_end}
{p 8 12}o you want a {bf:p-value}. The published table gives critical values only,
so without {cmd:simulate} {cmd:r(p)} is missing.{p_end}

{p 4 8}{opt reps(#)} and {opt gridpoints(#)} control the simulation. JK used 10,000
replications and 2,000 grid points. The defaults here (2000/1000) are faster;
raise them for a final result. Use {opt seed(#)} for reproducibility.{p_end}

{p 4 8}{opt level(#)} chooses which of the three tabulated levels (10, 5, 1) is
flagged. All three are always reported; this only sets the graph threshold and the
headline verdict.{p_end}

{dlgtab:Reporting}

{p 4 8}{opt graph} draws the CUSUM process US{sub:NT}(k,khat) against k with the
rejection threshold, and the {bf:shift-direction} plot -- the estimated d{sub:i} by
series, coloured by sign. The latter is a power diagnostic; see
{help xtcombreak_test##power:below}.{p_end}


{marker output}{title:Interpreting the output}

{p 4 4}{ul:Test statistic block}{p_end}
{p 8 12}{bf:S_NT} -- the statistic. Compare to the critical values; it is a
{bf:one-sided upper-tail} test (reject when S is {it:large}).{p_end}
{p 8 12}{bf:numerator} -- sup{sub:k} US{sub:NT}. Diverges at rate NT under HA.{p_end}
{p 8 12}{bf:denominator} -- inf V{sub:NT}. O{sub:p}(1) under both H0 and HA
(their Proposition 3), so all the signal is in the numerator.{p_end}
{p 8 12}{bf:tau0-hat} -- khat/T. The null distribution {bf:depends on it}, so the
critical value is read at this tau0.{p_end}

{p 4 4}{ul:Critical values}{p_end}
{p 8 12}Roughly 45 / 58 / 90 at the 10/5/1% levels across most of the tau0 range.
Note how {it:large} they are -- this is a ratio of a squared CUSUM to a small
normaliser, not a chi2.{p_end}
{p 8 12}The source line says whether they came from JK Table 1 or were
simulated.{p_end}

{p 4 4}{ul:Diagnostics}{p_end}
{p 8 12}{bf:Sign concordance} -- the fraction of estimated shifts d{sub:i} sharing
the majority sign. 1.00 = all the same direction; 0.50 = an even split. Below 0.65
the command warns, because this is the configuration in which JK show the test
{bf:loses power}. See below.{p_end}
{p 8 12}Warnings also fire when T < 50 (size distortion) and T/N < 1
(Assumption 2(iii)).{p_end}


{marker power}{title:Power: when this test fails you}

{p 4 4}These come from the paper's own simulations. They matter because a
{bf:non-rejection is only as informative as the test's power}, and this test has
specific, documented blind spots.{p_end}

{p 4 4}{ul:1. Breaks in opposite directions -- power collapses}{p_end}

{p 4 4}JK sec.5 (p.96): with d{sub:1i}, d{sub:2i} ~ U(-0.5, 0.5) "our tests also
lose power in panels" -- the c'delta = 0 problem of Deng and Perron (2008). Their
own conclusion: "our test is useful when changes in individual coefficients are in
the {bf:similar direction}."{p_end}

{p 4 4}This is why {cmd:xtcombreak} reports {bf:sign concordance} and warns when it
is near 0.5. If your shifts are half positive and half negative, a non-rejection
tells you very little.{p_end}

{p 4 4}{ul:2. Breaks close together -- power falls off fast}{p_end}

{p 4 4}JK Table 6 (N=T=50, rho=0.4, 10% level), first break fixed at 0.2T:{p_end}

{p 8 8}{bf:distance   0.05T  0.1T   0.2T   0.3T   0.4T   0.5T   0.6T}{break}
{bf:power      0.116  0.317  0.794  0.932  0.952  0.926  0.869}{p_end}

{p 4 4}At 0.1T apart the test rejects only 32% of the time at the 10% level. Their
guidance: "If the distance between two breaks exceeds [0.3T], the rejection
probability reaches at least 90%."{p_end}

{p 4 4}{ul:3. Unbalanced groups -- power falls fast}{p_end}

{p 4 4}JK Table 7 (N=T=50, breaks at 0.3T and 0.7T, 10% level):{p_end}

{p 8 8}{bf:N1:N2    2:N-2   1:9    2:8    3:7    4:6    5:5}{break}
{bf:power    0.157   0.251  0.538  0.806  0.929  0.976}{p_end}

{p 4 4}"If the number of individuals in one group is much less than that in the
second group, the heterogeneity between the two groups cannot be identified."
A handful of deviant units will not be caught.{p_end}

{p 4 4}{ul:4. Small T with serial correlation -- SIZE is distorted}{p_end}

{p 4 4}JK Table 2, nominal 5%, rho = 0.4:{p_end}

{p 8 8}{bf:T=20:} 0.145 (N=10), 0.157 (N=50), {bf:0.167} (N=100){break}
{bf:T=50:} 0.086, 0.080, 0.073{break}
{bf:T=100:} 0.060, 0.064, 0.053{break}
{bf:T=200:} 0.049, 0.043, 0.050{p_end}

{p 4 4}At T=20 the test rejects three times too often, and it {bf:worsens with N}.
Size only settles near T=200. {cmd:xtcombreak} warns when T < 50. With small T,
read a rejection sceptically -- it may be size distortion, not heterogeneity.{p_end}

{p 4 4}{ul:Net advice}{p_end}

{p 4 4}The uncomfortable pattern: the test is most likely to wave you through
exactly when break heterogeneity is {bf:mild but real} -- close dates, a small
deviant group, mixed directions. That is still enough to contaminate khat, but not
enough to be caught. Treat a non-rejection as {it:weak} evidence, and lean on the
diagnostics.{p_end}


{marker ambig}{title:What a rejection does not tell you}

{p 4 4}A rejection is {bf:ambiguous} between two very different worlds:{p_end}

{p 8 12}(a) there is no common break -- each series or group has its own; or{p_end}
{p 8 12}(b) there are {bf:several common breaks} along the time dimension.{p_end}

{p 4 4}The test cannot separate them, and JK hit this in their own application
(sec.6). Testing 13 mutual-fund categories over 2005M02-2011M12, they rejected for
12 of 13 -- then had to fall back on the Bai-Perron sequential test to work out
what the rejection meant, finding multiple breaks clustered at similar dates
(early 2006, early 2008, early 2009). Only after splitting the sample did the test
fail to reject over 2008M06-2011M12, supporting {it:one} common break during the
sub-prime crisis.{p_end}

{p 4 4}So on a rejection, do what they did:{p_end}

{p 8}{cmd:. xtbreak test y x1 x2, hypothesis(3) sequential}{p_end}
{p 8}{cmd:. xtcombreak test y x1 x2 if year <= 2008}{p_end}
{p 8}{cmd:. xtcombreak test y x1 x2 if year > 2008}{p_end}

{p 4 4}Their DGP.3/H4A simulations confirm the test has high power against multiple
common breaks (Table 12) -- which is precisely why a rejection cannot rule that
out.{p_end}


{marker pretest}{title:The pre-test problem}

{p 4 4}This test is {bf:post-estimation in mechanics} -- it needs khat first, and
in fact its power {it:comes from} khat being wrong under HA -- but a
{bf:pre-test in purpose}: you run it to decide whether you may impose a common
break.{p_end}

{p 4 4}That makes it a pre-test in the technical, awkward sense. If you test, fail
to reject, and then report Bai's confidence interval as though the common break
were known, that interval's true coverage is {bf:not} its nominal level: it is
conditional on having passed a screening on the same data. {bf:Neither paper
computes this distortion.}{p_end}

{p 4 4}Like Hansen's J or a Hausman test, the null here is a {it:modelling
assumption}, so it carries the usual asymmetry: failing to reject is not evidence
the assumption holds. Combined with the power gaps above, that asymmetry bites
hard. {cmd:xtcombreak} never selects a specification for you on the basis of this
test.{p_end}


{marker examples}{title:Examples}

{p 8}{cmd:. webuse grunfeld, clear}{p_end}
{p 8}{cmd:. xtset company year}{p_end}

{p 4 4}{ul:Basic}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock}{p_end}

{p 4 4}{ul:With a p-value}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock, simulate reps(5000) seed(42)}{p_end}
{p 8}{cmd:. display "p = " r(p)}{p_end}

{p 4 4}{ul:Different trimming -- simulate is then required}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock, trimming(0.15) simulate seed(42)}{p_end}

{p 4 4}{ul:On a rejection: split the sample, as JK did}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock if year <= 1943}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock if year > 1943}{p_end}

{p 4 4}{ul:Check the power diagnostic before trusting a non-rejection}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock, graph}{p_end}
{p 8}{cmd:. display "sign concordance = " r(concord)}{p_end}
{p 12}{it:near 0.5 means mixed directions -- JK show power collapses there}{p_end}

{p 4 4}{ul:Full sequence}{p_end}
{p 8}{cmd:. xtcombreak all invest mvalue kstock}{p_end}


{marker results}{title:Stored results}

{p 4 4}{cmd:xtcombreak test} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(S)}}the test statistic S_NT{p_end}
{synopt:{cmd:r(p)}}p-value ({bf:missing} unless {cmd:simulate}){p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(cv05)}}5% critical value{p_end}
{synopt:{cmd:r(cv01)}}1% critical value{p_end}
{synopt:{cmd:r(khat)}}estimated common break index (1..T){p_end}
{synopt:{cmd:r(tau0)}}khat/T{p_end}
{synopt:{cmd:r(numerator)}}sup_k US_NT(k,khat){p_end}
{synopt:{cmd:r(denominator)}}inf V_NT(k1,khat,k2){p_end}
{synopt:{cmd:r(concord)}}sign concordance of the estimated shifts{p_end}
{synopt:{cmd:r(N)}}number of series{p_end}
{synopt:{cmd:r(T)}}number of periods{p_end}
{synopt:{cmd:r(TNratio)}}T/N{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtcombreak test}{p_end}
{synopt:{cmd:r(cvsource)}}where the critical values came from{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}regressors{p_end}
{synopt:{cmd:r(panelvar)}}panel variable{p_end}
{synopt:{cmd:r(timevar)}}time variable{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(cusum)}}T x 4: index, date, US_NT(k,khat), threshold{p_end}
{synopt:{cmd:r(breakdate)}}2 x 1: date, index{p_end}
{synopt:{cmd:r(delta)}}N x 2: id, estimated first slope shift{p_end}
{p2colreset}{...}


{marker author}{title:Author}

{p 4}Dr Merwan Roudane{p_end}
{p 4}merwanroudane920@gmail.com{p_end}
{p 4}{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
