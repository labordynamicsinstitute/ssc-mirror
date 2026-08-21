{smcl}
{* *! xtflucbreak 1.0.0  07aug2026}{...}
{vieweralsosee "xtflucbreak" "help xtflucbreak"}{...}
{vieweralsosee "xtflucbreak methods" "help xtflucbreak_methods"}{...}
{vieweralsosee "xtbfkbreak" "help xtbfkbreak"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{viewerjumpto "Syntax" "xtflucbreak_postestimation##syntax"}{...}
{viewerjumpto "Description" "xtflucbreak_postestimation##description"}{...}
{viewerjumpto "Supported estimators" "xtflucbreak_postestimation##supported"}{...}
{viewerjumpto "What is read from e()" "xtflucbreak_postestimation##efetch"}{...}
{viewerjumpto "Automatic branch selection" "xtflucbreak_postestimation##branch"}{...}
{viewerjumpto "Guarantees and caveats" "xtflucbreak_postestimation##caveats"}{...}
{viewerjumpto "Examples" "xtflucbreak_postestimation##examples"}{...}
{viewerjumpto "Author" "xtflucbreak_postestimation##author"}{...}
{title:Title}

{phang}
{bf:xtflucbreak postestimation} {hline 2} testing the model in memory for a structural change


{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:xtflucbreak} {ifin} [{cmd:,} {it:options}]

{pstd}
That is, {cmd:xtflucbreak} with {bf:no varlist}. All the options documented in
{helpb xtflucbreak} remain available.


{marker description}{title:Description}

{pstd}
Applied panel work usually fits a model first and asks about parameter stability second.
Called with no varlist, {cmd:xtflucbreak} recovers the dependent variable, the regressors
and the estimation sample from the results in memory and runs the fluctuation test of
Li, Xiao and Chen (2024) on exactly that specification.

{pstd}
The test is {it:not} a test of the fitted estimator. It always re-fits per-panel OLS,
because that is the estimator whose recursive path the statistic is built on. What is
inherited from {cmd:e()} is the {it:specification} and the {it:sample}, not the
coefficients. This matters for interpretation: after {cmd:xtreg, fe} the test asks whether
the {it:heterogeneous} slopes of that same y on that same X are stable, not whether the
fixed-effects estimate is.


{marker supported}{title:Supported estimators}

{synoptset 18 tabbed}{...}
{synopthdr:Command}
{synoptline}
{synopt:{helpb regress}}pooled OLS{p_end}
{synopt:{helpb areg}}absorbed OLS{p_end}
{synopt:{helpb xtreg}}FE, RE, BE, MLE{p_end}
{synopt:{helpb xtgls}}panel GLS{p_end}
{synopt:{cmd:reghdfe}}multi-way fixed effects{p_end}
{synopt:{cmd:xtmg}}Eberhardt's mean-group, CCE-MG and AMG{p_end}
{synopt:{cmd:xtcce}}Neal's CCE estimators{p_end}
{synopt:{cmd:xtdcce2}}Ditzen's dynamic CCE{p_end}
{synopt:{cmd:xtfmg}}fully modified mean group{p_end}
{synopt:{cmd:xtpmg}}pooled mean group{p_end}
{synopt:{helpb xtbfkbreak}}Baltagi-Feng-Kao heterogeneous panels with breaks{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Anything else exits with {cmd:r(301)} and a message naming the supported set. There is no
silent fallback: guessing a specification from an unrecognised {cmd:e(b)} is how wrong
answers get produced quietly.


{marker efetch}{title:What is read from e()}

{pstd}
{bf:Dependent variable} from {cmd:e(depvar)}. If that macro holds more than one word it is
reduced to its last token and confirmed to be a variable -- {cmd:xtmg} with
{cmd:augment impose} stores it as the two-word string "adjusted {it:y}", which would
otherwise be passed on verbatim.

{pstd}
{bf:Regressors}, in this order of preference: {cmd:e(indepvars)}, {cmd:e(indepvar)},
{cmd:e(rhs)}, then the column names of {cmd:e(b)}. In the last case equation prefixes
({cmd:eq:var}) are stripped, {cmd:_cons} and the dependent variable are dropped, names
that are not variables in the current dataset are dropped, and duplicates are removed.
{cmd:e(endog)} is appended when present, so an instrumented regressor is still tested for
a break in its slope.

{pstd}
{bf:Sample} from {cmd:e(sample)}. The test sample is the intersection of {cmd:e(sample)},
any {cmd:if}/{cmd:in} you add, and non-missingness on all variables. The balance
requirement is then checked on {it:that} sample -- an estimator that dropped a singleton
panel can leave the remainder unbalanced, and the command will say so.

{pstd}
{bf:Nothing is written.} {cmd:xtflucbreak} is {cmd:rclass} and never calls an estimation
command internally, so your {cmd:e()} survives the call untouched. You can run it between
an estimation command and its own postestimation commands without {cmd:estimates store}.


{marker branch}{title:Automatic branch selection}

{pstd}
If the fitted model already controls for unobserved common factors, the CCE branch
(section 4) is selected automatically and the header says so. The rule is:

{p2colset 5 26 28 2}{...}
{p2col :{cmd:xtdcce2}, {cmd:xtcce}, {cmd:xtfmg}}always CCE{p_end}
{p2col :everything else}CCE if any of {cmd:e(title2)}, {cmd:e(model)},
{cmd:e(estimator)}, {cmd:e(transform)}, {cmd:e(title)}, {cmd:e(cmdline)} or
{cmd:e(properties)} contains "cce", "common correlated", "amg" or "augmented mean
group"{p_end}
{p2colreset}{...}

{pstd}
Several macros are scanned because estimators disagree about where they record the
variant. {cmd:xtmg} (version 1.0.1) does {it:not} set {cmd:e(cmdline)} at all -- it flags
the variant in {cmd:e(title2)} as {cmd:CCEMG}, {cmd:AMG} or {cmd:MG}. Checking only
{cmd:e(cmdline)} silently left {cmd:xtmg, cce} on the section-3 branch.

{pstd}
{cmd:AMG} also triggers the CCE branch: the augmented mean-group estimator presupposes a
common factor, so testing its specification without controlling for one would be
inconsistent. Note that {cmd:xtflucbreak} builds its own M{sub:w} in every case; it does
not reuse AMG's common dynamic process.

{pstd}
Specifying {cmd:cce} explicitly always forces the CCE branch. There is no way to force the
section-3 branch after a CCE estimator other than supplying the varlist by hand -- which is
deliberate, since that combination is almost always a mistake.

{pstd}
Note that {cmd:xtflucbreak} builds its {it:own} M{sub:w} from the cross-section averages of
(y, X); it does not reuse whatever augmentation the fitted command used. If you fitted
{cmd:xtdcce2} with extra cross-sectional averages or lags, add the matching
{cmd:ccalags()} yourself.


{marker caveats}{title:Guarantees and caveats}

{pstd}
{bf:Guaranteed.} {cmd:e()} is not modified. The estimation sample is respected. The panel
must still be {helpb xtset} and balanced on that sample.

{pstd}
{bf:Fixed effects are not inherited.} After {cmd:xtreg, fe} or {cmd:areg}, the absorbed
effects are {it:not} carried over -- the test runs per-panel OLS on the levels, and each
panel's own intercept is estimated as part of {&beta}{sub:i} (unless {cmd:noconstant} is
specified). This is the right thing to do: a panel-specific intercept is exactly what the
heterogeneous model of Li, Xiao and Chen already allows, and it is one of the coefficients
whose stability is being tested.

{pstd}
{bf:Factor variables and time-series operators.} The recovered regressor list is expanded
to plain variable names. If your model used {cmd:i.} or {cmd:L.} notation, create the
variables explicitly and pass a varlist rather than relying on postestimation mode.

{pstd}
{bf:Weights are ignored.} The statistic has no weighted version in the paper.

{pstd}
{bf:After {cmd:xtbfkbreak}.} Running the test after a model that {it:already} imposes a
break is a specification check, not a fresh test: you are asking whether the residual
specification still shows instability. Read a rejection there as evidence of a second
break or of a misplaced first one.


{marker examples}{title:Examples}

{pstd}Fit, then test{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtreg invest mvalue kstock, fe}{p_end}
{phang2}{cmd:. xtflucbreak}{p_end}

{pstd}The fitted model is untouched, so its own postestimation still works{p_end}
{phang2}{cmd:. estat vce}{p_end}

{pstd}Options work exactly as in the standalone form{p_end}
{phang2}{cmd:. xtflucbreak, graph level(1) showunits}{p_end}

{pstd}After a CCE estimator the CCE branch is selected automatically{p_end}
{phang2}{cmd:. xtmg invest mvalue kstock, cce}{p_end}
{phang2}{cmd:. xtflucbreak}{p_end}

{pstd}The recommended sequence: test for a break, then estimate the regimes{p_end}
{phang2}{cmd:. xtmg invest mvalue kstock, cce}{p_end}
{phang2}{cmd:. xtflucbreak, graph}{p_end}
{phang2}{cmd:. xtbfkbreak invest mvalue kstock, breaks(1)}{p_end}


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Online: {help xtflucbreak:xtflucbreak},
{help xtflucbreak_methods:xtflucbreak methods},
{helpb xtbfkbreak}, {helpb xtreg}
