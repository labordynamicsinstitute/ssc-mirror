{smcl}
{* *! version 1.0.0  17jul2026}{...}
{vieweralsosee "xtcombreak estimate" "help xtcombreak_estimate"}{...}
{vieweralsosee "xtcombreak test" "help xtcombreak_test"}{...}
{vieweralsosee "xtcombreak methods" "help xtcombreak_methods"}{...}
{vieweralsosee "xtbreak" "help xtbreak"}{...}
{vieweralsosee "xtbfkbreak" "help xtbfkbreak"}{...}
{viewerjumpto "Syntax" "xtcombreak##syntax"}{...}
{viewerjumpto "Description" "xtcombreak##description"}{...}
{viewerjumpto "Which command do I want?" "xtcombreak##which"}{...}
{viewerjumpto "The four stages" "xtcombreak##stages"}{...}
{viewerjumpto "Options" "xtcombreak##options"}{...}
{viewerjumpto "Remarks" "xtcombreak##remarks"}{...}
{viewerjumpto "Examples" "xtcombreak##examples"}{...}
{viewerjumpto "Stored results" "xtcombreak##results"}{...}
{viewerjumpto "References" "xtcombreak##refs"}{...}
{viewerjumpto "Author" "xtcombreak##author"}{...}
{hline}
help for {hi:xtcombreak}{right: version 1.0.0 - 17jul2026}
{hline}

{title:Title}

{p 4 4}{cmd:xtcombreak} {hline 2} Common breaks in panel data: estimating the
common break date with a confidence interval (Bai 2010), and testing whether the
break really is common across units (Jiang and Kurozumi 2026).{p_end}


{marker syntax}{title:Syntax}

{p 4}{ul:Estimate the common break date, its confidence interval, and which series broke}{p_end}

{p 4 13}{cmd:xtcombreak} {cmdab:est:imate} {depvar} {ifin}
[{cmd:,} {help xtcombreak##opt_est:{it:estimate_options}}]{p_end}

{p 4}{ul:Test the null that the break date is COMMON across units}{p_end}

{p 4 13}{cmd:xtcombreak} {cmd:test} {depvar} {indepvars} {ifin}
[{cmd:,} {help xtcombreak##opt_test:{it:test_options}}]{p_end}

{p 4}{ul:Both, in the recommended order, with the pre-test caveat printed}{p_end}

{p 4 13}{cmd:xtcombreak} {cmd:all} {depvar} [{indepvars}] {ifin}
[{cmd:,} {it:options}]{p_end}

{p 4 4}The data must be {help xtset} as a {bf:balanced} panel. {depvar} and
{indepvars} may contain time-series operators.{p_end}

{marker opt_est}{...}
{synoptset 30 tabbed}{...}
{synopthdr:estimate_options}
{synoptline}
{syntab:Model}
{synopt:{opt m:ethod(ls|qml|gls)}}estimator of the break date; default {cmd:method(ls)}{p_end}
{synopt:{opt br:eaks(#)}}number of breaks; default {cmd:breaks(1)}{p_end}
{synopt:{opt trim:ming(#)}}minimum regime length as a fraction; default {cmd:trimming(0)} = none{p_end}
{syntab:Inference}
{synopt:{opt l:evel(#)}}CI level: 90, 95 or 99 only; default 95{p_end}
{synopt:{opt an:method(het|hom)}}form of {it:A_N}; default {cmd:anmethod(het)}{p_end}
{synopt:{opt ch:ow}}per-series Chow test at the estimated break{p_end}
{syntab:Reporting}
{synopt:{opt show:index}}also report break positions as indices 1..T{p_end}
{synopt:{opt graph}}break-identification and per-series shift plots{p_end}
{synopt:{opt profname(name)}}name for the profile graph{p_end}
{synopt:{opt shiftname(name)}}name for the shift graph{p_end}
{synoptline}

{marker opt_test}{...}
{synoptset 30 tabbed}{...}
{synopthdr:test_options}
{synoptline}
{syntab:Model}
{synopt:{opt trim:ming(#)}}trimming {it:eps} for {it:Lambda(eps)}; default {cmd:trimming(0.1)}{p_end}
{synopt:{opt nocons:tant}}suppress the constant in x{sub:it}{p_end}
{syntab:Critical values}
{synopt:{opt sim:ulate}}simulate critical values and a p-value instead of using the table{p_end}
{synopt:{opt reps(#)}}replications for {cmd:simulate}; default 2000{p_end}
{synopt:{opt grid:points(#)}}grid points approximating the Brownian motion; default 1000{p_end}
{synopt:{opt seed(#)}}random-number seed for {cmd:simulate}{p_end}
{synopt:{opt l:evel(#)}}level flagged in the output: 10, 5 or 1; default 5{p_end}
{syntab:Reporting}
{synopt:{opt show:index}}also report the break position as an index{p_end}
{synopt:{opt graph}}CUSUM process and shift-direction plots{p_end}
{synopt:{opt cusumname(name)}}name for the CUSUM graph{p_end}
{synopt:{opt shiftname(name)}}name for the shift-direction graph{p_end}
{synoptline}


{marker description}{title:Description}

{p 4 4}{cmd:xtcombreak} implements two complementary papers on {it:common} breaks
in panel data.{p_end}

{p 4 4}{bf:{help xtcombreak_estimate:xtcombreak estimate}} implements
{help xtcombreak##bai2010:Bai (2010)}. In a single time series only the break
{it:fraction} can be estimated consistently; the break {it:date} cannot. Bai's
result is that a panel fixes this: as N grows, P(khat = k0) -> 1, so the exact
date is recovered. This holds even when a regime contains a {bf:single
observation}, which makes it useful for pinning down the onset of a new regime
quickly. The command estimates the date by least squares, quasi-maximum
likelihood or feasible GLS, reports Bai's parameter-free confidence interval,
and runs his series-by-series Chow test to say which units actually broke.{p_end}

{p 4 4}{bf:{help xtcombreak_test:xtcombreak test}} implements
{help xtcombreak##jk2026:Jiang and Kurozumi (2026)}. Every common-break method,
including Bai's, {it:assumes} the break is at the same date for all units. This
is a real restriction and can fail. The command tests that assumption with a
self-normalised CUSUM statistic built from OLS residuals.{p_end}

{p 4 4}The two are complements. {cmd:estimate} gives you the answer;
{cmd:test} tells you whether you were entitled to ask the question that way.{p_end}


{marker which}{title:Which command do I want?}

{p 4 4}Panel break analysis in Stata now spans several commands with different
nulls. They are not substitutes:{p_end}

{synoptset 26 tabbed}{...}
{synopt:{bf:Command}}{bf:Question it answers / null}{p_end}
{synoptline}
{synopt:{helpb xtbreak_test:xtbreak test}}Is there a break {bf:at all}? How many? Null: no break{p_end}
{synopt:{helpb xtbreak_estimate:xtbreak estimate}}Where are the breaks (Bai-Perron dynamic programme)?{p_end}
{synopt:{helpb xtbfkbreak}}Slopes + breaks with CCE factors, heterogeneous panels{p_end}
{synopt:{bf:xtcombreak estimate}}The exact break {bf:date}, its {bf:CI}, and which series broke{p_end}
{synopt:{bf:xtcombreak test}}Is the break {bf:common} across units? Null: it is common{p_end}
{synoptline}

{p 4 4}{cmd:xtcombreak test} is the only one whose null hypothesis is the
common-break {it:assumption} itself.{p_end}


{marker stages}{title:The four stages -- and the two neither paper provides}

{p 4 4}A complete panel common-break analysis has four stages. Bai (2010) and
Jiang-Kurozumi (2026) cover only the middle two. Be explicit about this:{p_end}

{p 8 12}{bf:Stage 1. Does a break exist at all?} {bf:NOT provided by either
paper.} Bai (2010, p.79) is explicit: "The focus is on the estimation of the
break point {it:given its existence}". Jiang-Kurozumi's null is "the break is
common", not "there is a break". Use {helpb xtbreak_test:xtbreak test} (or
Horvath-Huskova 2012, De Wachter-Tzavalis 2012, Antoch et al. 2019 -- the
literature Jiang-Kurozumi cite for exactly this stage).{p_end}

{p 8 12}{bf:Stage 2. Where is it?} {cmd:xtcombreak estimate} (Bai) or, with
regressors and factors, {helpb xtbfkbreak} / {helpb xtbreak_estimate}. This is
an estimator, not a test.{p_end}

{p 8 12}{bf:Stage 3. Is it common?} {cmd:xtcombreak test} (Jiang-Kurozumi).
Post-estimation in mechanics -- it needs khat first -- but a {bf:pre-test} in
purpose: it licenses stage 4.{p_end}

{p 8 12}{bf:Stage 4. Which series broke, and how precise is the date?}
{cmd:xtcombreak estimate, chow} and its CI (Bai p.84, eq.13).{p_end}

{p 4 4}{cmd:xtcombreak all} prints this sequence and runs stages 3 and 4.{p_end}


{marker remarks}{title:Remarks and practical guidance}

{p 4 4}{ul:Sample-size regime: T should be large relative to N}{p_end}

{p 4 4}Both papers point the same way, which is why they can share a command:{p_end}

{p 8 12}o Bai's eq.(5), {cmd:N*log(log T)/T -> 0}, is required by his
Theorem 3.2, by the limiting distribution behind the {bf:confidence interval}
(Lemma 4.1), and by the whole QML section ("assume T is larger than N such that
(5) hold", p.84).{p_end}

{p 8 12}o Jiang-Kurozumi's Assumption 2(iii) requires {cmd:T/N -> infinity} --
"a significant condition to ensure a non-degenerate distribution of the statistic
under the null hypothesis and consistency of the test under the alternative".{p_end}

{p 4 4}The one place they diverge is Bai's Remark 3 (p.87): the special mode in
which k0 is unrestricted and a regime may hold a single observation needs
{cmd:T/N -> 0} instead. That mode is outside his CI framework.{p_end}

{p 4 4}When T < N the command prints a note. Read it carefully: under Bai's
Assumption 2 the {bf:point estimate} khat stays consistent with no T/N condition
at all, so khat is robust. It is the {bf:CI} that leans on eq.(5) and degrades.{p_end}

{p 4 4}{ul:The pre-test problem}{p_end}

{p 4 4}If you run {cmd:test}, fail to reject, and then report {cmd:estimate}'s
confidence interval as though the common break were known, that interval is a
{bf:pre-test estimator}: its true coverage is not the nominal level, because it
is conditional on having passed a screening on the same data. {bf:Neither paper
quantifies this distortion.} {cmd:xtcombreak} never selects a model for you on
the basis of the test, and prints the caveat in {cmd:xtcombreak all}.{p_end}

{p 4 4}This matters more than usual here, because the test's power failures line
up exactly with the cases where you would lean on a non-rejection hardest --
close breaks, unbalanced groups, and shifts in opposite directions. See
{helpb xtcombreak_test##power:xtcombreak test} for the numbers.{p_end}

{p 4 4}{ul:Cross-sectional dependence}{p_end}

{p 4 4}Both papers assume cross-sectionally independent errors (Bai Assumption 1;
Jiang-Kurozumi Assumption 3(ii)). Both concede it is restrictive; Jiang-Kurozumi
"leave such an extension for our future research". Check with {helpb xtcd2} or
{cmd:xttestpanel csd}. If CSD is present, consider {helpb xtbfkbreak} (CCE) or
{cmd:xtbreak, csd}, and treat these results as indicative.{p_end}

{p 4 4}{ul:Trimming}{p_end}

{p 4 4}{cmd:estimate} defaults to {cmd:trimming(0)}, i.e. Bai's literal search
over k in [1, T-1]. This is deliberate: consistency with a single-observation
regime is the paper's headline claim, and any trimming would forbid it. Most
other break commands trim 15% and cannot reproduce Bai's Fig.2. See
{helpb xtcombreak_estimate##trim:the estimate page} for when to depart from
this.{p_end}


{marker examples}{title:Examples}

{p 4 4}{ul:Setup}{p_end}

{p 8}{cmd:. webuse grunfeld, clear}{p_end}
{p 8}{cmd:. xtset company year}{p_end}

{p 4 4}{ul:1. The full recommended sequence}{p_end}

{p 8}{cmd:. xtbreak test invest mvalue kstock, hypothesis(1) breaks(1)}{p_end}
{p 12}{it:(stage 1: is there a break at all?)}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock}{p_end}
{p 12}{it:(stage 2: is it common across firms?)}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, chow}{p_end}
{p 12}{it:(stages 3-4: the date, its CI, and which firms broke)}{p_end}

{p 4 4}{ul:2. Estimation, all three estimators}{p_end}

{p 8}{cmd:. xtcombreak estimate invest}{p_end}
{p 12}{it:least squares -- Bai sec.3, the default}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, method(qml)}{p_end}
{p 12}{it:QML -- also picks up breaks in the VARIANCE (Bai sec.5)}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, method(gls)}{p_end}
{p 12}{it:two-step feasible GLS -- asymptotically equivalent to QML (Bai p.85)}{p_end}

{p 4 4}{ul:3. A tighter confidence interval}{p_end}

{p 8}{cmd:. xtcombreak estimate invest, level(90)}{p_end}
{p 8}{cmd:. xtcombreak estimate invest, method(qml) level(90)}{p_end}
{p 12}{it:QML is never less efficient than LS (A_N <= B_N, Bai p.85), so its}{p_end}
{p 12}{it:interval is never wider. Compare r(AN) and r(BN).}{p_end}

{p 4 4}{ul:4. Which firms actually broke?}{p_end}

{p 8}{cmd:. xtcombreak estimate invest, chow}{p_end}
{p 8}{cmd:. matrix C = r(chow)}{p_end}
{p 8}{cmd:. matlist C}{p_end}
{p 12}{it:column 1 = panel id, 2 = chi2(1), 3 = p-value, 4 = sigma_i^2}{p_end}

{p 4 4}{ul:5. Testing the common-break assumption}{p_end}

{p 8}{cmd:. xtcombreak test invest mvalue kstock}{p_end}
{p 12}{it:critical values from Jiang-Kurozumi Table 1}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock, simulate reps(5000) seed(42)}{p_end}
{p 12}{it:simulated critical values AND a p-value (the table gives no p-value)}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock, trimming(0.15) simulate}{p_end}
{p 12}{it:any eps other than 0.1 REQUIRES simulate -- Table 1 is only valid at 0.1}{p_end}

{p 4 4}{ul:6. Multiple breaks}{p_end}

{p 8}{cmd:. xtcombreak estimate invest, breaks(2) showindex}{p_end}
{p 12}{it:one-at-a-time method (Bai sec.6 / Bai 1997a). Bai derives no CI for}{p_end}
{p 12}{it:multiple breaks -- the reported interval is for the first break only.}{p_end}

{p 4 4}{ul:7. Graphs}{p_end}

{p 8}{cmd:. xtcombreak estimate invest, method(qml) chow graph}{p_end}
{p 8}{cmd:. xtcombreak test invest mvalue kstock, graph}{p_end}
{p 8}{cmd:. graph combine xtcb_profile xtcb_shift xtcb_cusum xtcb_dsign}{p_end}

{p 4 4}{ul:8. Simulated data with a known break (see the ancillary do-file)}{p_end}

{p 8}{cmd:. net get xtcombreak}{p_end}
{p 8}{cmd:. do xtcombreak_example.do}{p_end}
{p 12}{it:reproduces Bai's Fig.1/Fig.2/Table 1 and Jiang-Kurozumi's Tables 2/4,}{p_end}
{p 12}{it:and checks the simulated critical values against their Table 1.}{p_end}


{marker results}{title:Stored results}

{p 4 4}See {helpb xtcombreak_estimate##results:xtcombreak estimate} and
{helpb xtcombreak_test##results:xtcombreak test} for the full lists.{p_end}


{marker refs}{title:References}

{marker bai2010}{...}
{p 4 8}Bai, J. 2010. Common breaks in means and variances for panel data.
{it:Journal of Econometrics} 157(1): 78-92.
{browse "https://doi.org/10.1016/j.jeconom.2009.10.020":doi:10.1016/j.jeconom.2009.10.020}{p_end}

{marker jk2026}{...}
{p 4 8}Jiang, P., and E. Kurozumi. 2026. A new test for common breaks in
heterogeneous panel data models. {it:Econometrics and Statistics} 37: 87-125.
{browse "https://doi.org/10.1016/j.ecosta.2023.01.005":doi:10.1016/j.ecosta.2023.01.005}{p_end}

{p 4 8}Bai, J. 1997a. Estimating multiple breaks one at a time.
{it:Econometric Theory} 13(3): 315-352.{p_end}

{p 4 8}Bai, J., and P. Perron. 1998. Estimating and testing linear models with
multiple structural changes. {it:Econometrica} 66(1): 47-78.{p_end}

{p 4 8}Baltagi, B. H., Q. Feng, and C. Kao. 2016. Estimation of heterogeneous
panels with structural breaks. {it:Journal of Econometrics} 191(1): 176-195.{p_end}

{p 4 8}Brown, R. L., J. Durbin, and J. M. Evans. 1975. Techniques for testing the
constancy of regression relationships over time. {it:JRSS B} 37(2): 149-192.{p_end}

{p 4 8}Chow, G. C. 1960. Tests of equality between sets of coefficients in two
linear regressions. {it:Econometrica} 28(3): 591-605.{p_end}

{p 4 8}Deng, A., and P. Perron. 2008. A non-local perspective on the power
properties of the CUSUM and CUSUM of squares tests for structural change.
{it:Journal of Econometrics} 142(1): 212-240.{p_end}

{p 4 8}Ditzen, J., Y. Karavias, and J. Westerlund. 2025. Testing and estimating
structural breaks in time series and panel data in Stata. {it:Stata Journal}.{p_end}

{p 4 8}Shao, X., and X. Zhang. 2010. Testing for change points in time series.
{it:JASA} 105(491): 1228-1240.{p_end}


{marker author}{title:Author}

{p 4}Dr Merwan Roudane{p_end}
{p 4}merwanroudane920@gmail.com{p_end}
{p 4}{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{p 4 4}Bug reports and comments welcome.{p_end}
