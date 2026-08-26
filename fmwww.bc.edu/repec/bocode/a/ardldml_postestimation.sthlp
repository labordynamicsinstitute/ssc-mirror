{smcl}
{* *! version 1.0.0  24aug2026}{...}
{vieweralsosee "ardldml" "help ardldml"}{...}
{vieweralsosee "ardldml methods" "help ardldml_methods"}{...}
{vieweralsosee "ardldml examples" "help ardldml_examples"}{...}
{viewerjumpto "Syntax" "ardldml_postestimation##syntax"}{...}
{viewerjumpto "estat absorption" "ardldml_postestimation##absorption"}{...}
{viewerjumpto "estat penalty" "ardldml_postestimation##penalty"}{...}
{viewerjumpto "estat classical" "ardldml_postestimation##classical"}{...}
{viewerjumpto "estat blocks" "ardldml_postestimation##blocks"}{...}
{viewerjumpto "estat null" "ardldml_postestimation##null"}{...}
{viewerjumpto "predict" "ardldml_postestimation##predict"}{...}
{viewerjumpto "Stored results" "ardldml_postestimation##results"}{...}
{viewerjumpto "Author" "ardldml_postestimation##author"}{...}

{title:Title}

{phang}
{bf:ardldml postestimation} {hline 2} postestimation tools for {helpb ardldml}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:estat} {cmdab:absorp:tion}{cmd:,} {opth drop(varlist)}
[{opt b:reps(#)} {opt seed(#)} {opt l:evel(#)} {opt mzalt(string)} {opt nota:ble}]

{p 8 15 2}
{cmd:estat} {cmdab:pen:alty}
[{cmd:,} {opt rules(string)} {opt proj:ections(string)}
{opt lagsg:rid(numlist)} {opt b:reps(#)} {opt seed(#)}]

{p 8 15 2}
{cmd:estat} {cmdab:class:ical}
[{cmd:,} {opt ord:er(#)} {opt nsim(#)} {opt seed(#)} {opt l:evels(numlist)}]

{p 8 15 2}
{cmd:estat} {cmdab:blo:cks} [{cmd:,} {opt graph} {opt name(string)} {it:twoway_options}]

{p 8 15 2}
{cmd:estat} {cmdab:null} [{cmd:,} {opt name(string)} {opt nogr:aph} {it:twoway_options}]

{p 8 15 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {opt xb} | {opt r:esiduals} | {opt ec}]

{pstd}
All subcommands leave your {cmd:e()} results untouched: the ones that refit
internally hold and restore them.


{marker absorption}{...}
{title:estat absorption}

{pstd}
{bf:This is the most important thing in the package to run, and the easiest to
skip.}

{pstd}
Residualisation is valid only when the controls remove {it:nuisance} stochastic
trends, not the equilibrium relation being tested. If a control is itself part
of the equilibrium system, partialling it out absorbs the very trend the test is
meant to detect, driving the effective integrated count toward zero and
destroying the relation rather than cleaning it. The estimand changes: a
non-rejection then reflects over-absorption, not the absence of a long-run
relationship. That requirement (the paper's Assumption 5, that the nuisance
space does not span the cointegrating relation of interest) cannot be verified
directly. This is the practical substitute.

{pstd}
{cmd:estat absorption} runs the four fits of Definition 2 -- full and reduced
control sets, crossed with the adaptive and the comparison m_Z projection -- and
reports the two gaps

{p 8 8 2}
Delta_m = p_plain - p_adaptive{break}
Delta_W = p_full  - p_reduced{p_end}

{pstd}
read together with the stability of the long-run coefficient across the four
fits.

{phang}
{opth drop(varlist)} names the controls omitted from the reduced set.
{bf:Required}, and the choice is economic: pick the controls most likely to be
cointegrated with the tested relation itself. In the paper's pass-through
application these are money and the oil price.

{phang}
{opt breps(#)} sets the replications per fit; four bootstraps are run, so cost
is roughly four times a single fit. Defaults to whatever the fitted model used.

{phang}
{opt seed(#)} seeds the first fit; the others are offset so the four bootstraps
are independent.

{phang}
{opt mzalt(string)} chooses the comparison arm: {cmd:plain} (default, vanilla
L1) or {cmd:ols} (unpenalised). See point 6 of
{helpb ardldml_methods:ardldml methods} for why the default is {cmd:plain}.

{pstd}
{bf:How to read it (the paper's Remark 9).} A large positive Delta_W -- a
verdict that rejects under the reduced set but not under the full set --
together with a long-run coefficient that is more sharply estimated under the
reduced fit, is evidence that the nuisance space is absorbing part of the tested
relation. Assumption 5 is then locally violated and {bf:the reduced-set verdict
is the more credible one}. Concordant verdicts across the four fits indicate the
conclusion is not an artefact of over-absorption.

{pstd}
{bf:It is a hypothesis-generating device, not a formal test.} It has no size and
no power. It tells you where to look.


{marker penalty}{...}
{title:estat penalty}

{pstd}
Sweeps the penalty rule, the m_Z projection and the lag order -- the robustness
grid of the paper's Section 7.5. The paper's own tables show a verdict that
rejects at one penalty and not at another. Reporting a single cell from this
grid is specification search; reporting the grid is the method.

{phang}
{opt rules(string)} penalty rules to try; default {cmd:low medium high}.

{phang}
{opt projections(string)} projections to try; default
{cmd:adaptive plain ols}.

{phang}
{opt lagsgrid(numlist)} short-run lag orders; defaults to the fitted value.

{phang}
{opt breps(#)} draws per cell. Omitted by default, which skips the bootstrap and
makes the sweep fast; supply it when you want a p-value in every cell.

{pstd}
{bf:The column to watch is n selected Z}, the number of control {bf:levels} the
m_Z projection retained. It is the empirical counterpart of the effective
integrated count: 0 means nothing was absorbed, so the test sits at the
classical corner and orthogonalisation did nothing; a large value means heavy
absorption. A long-run coefficient that changes sign across this grid is a
warning that the conditioning set, not the data, is driving the answer, and the
command says so explicitly.


{marker classical}{...}
{title:estat classical}

{pstd}
Runs the classical Pesaran, Shin and Smith (2001) bounds test on the same
sample, as a benchmark that conditions on nothing. All three steps are reported,
because rejecting the joint F alone is not evidence of a level relationship: two
degenerate cases survive it, so the t test on the speed of adjustment and the
Wald test on the long-run coefficients are shown alongside.

{pstd}
The bracket is {bf:simulated} from the Pesaran-Shin-Smith Table CI
data-generating process {bf:at your sample size}, not read from a table
calibrated at T = 1000. That is what makes it comparable: for short samples the
published asymptotic bounds are the wrong reference, which is the same finite-
sample concern that motivates the whole method.

{phang}
{opt order(#)} short-run order of the differenced focal regressor; default 1
(contemporaneous term only).

{phang}
{opt nsim(#)} replications for the bracket; default 20000. Tail quantiles settle
slowly, so reduce this only for exploratory work.

{phang}
{opt levels(numlist)} significance levels; default {cmd:0.10 0.05 0.01}.

{pstd}
Expect the two tests to disagree sometimes. That is the point: a statistic
comfortably above 5.73 may sit below the DML-Bounds critical value once the
integrated nuisance is accounted for.


{marker blocks}{...}
{title:estat blocks}

{pstd}
Reports the h-block cross-fitting partition: each evaluation window, its extent,
and how much sample was left for training after the buffer was removed. The
buffer is what buys the decoupling, but it costs sample -- at most h(K-1)
observations from each training set -- and this makes the trade-off visible
rather than implicit. Add {opt graph} to draw it.

{pstd}
Use it {it:before} committing to a configuration on a short sample. With no
buffer the training share is 1 - 1/K; each unit of h removes roughly 2h/n more.


{marker null}{...}
{title:estat null}

{pstd}
Summarises the stored bootstrap null distribution -- its mean, spread and upper
percentiles against the observed statistic and the critical value -- and plots
it. This is the honest way to see how far the realised null sits from the
tabulated 4.94/5.73 values that do not apply.

{phang}
{opt nograph} suppresses the plot and reports the table only.


{marker predict}{...}
{title:predict}

{pstd}
{cmd:predict} recomputes the first stage and returns an orthogonalised series.

{phang}
{opt xb} (the default) gives the fitted value of the orthogonalised level
regression.

{phang}
{opt residuals} gives its residual, that is, the part of the residualised
differenced outcome that the residualised levels do not explain.

{phang}
{opt ec} gives the residualised equilibrium error, L.{it:depvar} minus theta
times L.{it:focalvar}, both taken {bf:after} the controls are partialled out.
This is the series to plot when you want to look at the estimated long-run
relation -- but only once the test has actually rejected. Under a non-rejection
it is a picture of a relation the data do not support.

{pstd}
All are missing for the first p+1 observations of the estimation sample, which
the design consumes.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:estat absorption} stores in {cmd:r()}:{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:r(delta_m)}, {cmd:r(delta_W)}}the two gaps of Definition 2{p_end}
{synopt:{cmd:r(theta_spread)}}range of theta across the four fits{p_end}
{synopt:{cmd:r(table)}}4 x 8 matrix, one row per fit{p_end}
{synopt:{cmd:r(dropped)}, {cmd:r(mzalt)}}what was dropped, which comparison arm{p_end}

{pstd}{cmd:estat penalty} stores in {cmd:r()}:{p_end}
{synopt:{cmd:r(table)}}one row per cell{p_end}
{synopt:{cmd:r(theta_min)}, {cmd:r(theta_max)}}range of theta over the grid{p_end}
{synopt:{cmd:r(sign_flip)}}1 if theta changes sign across the grid{p_end}

{pstd}{cmd:estat classical} stores in {cmd:r()}:{p_end}
{synopt:{cmd:r(F)}, {cmd:r(t)}}the step-1 and step-2 statistics{p_end}
{synopt:{cmd:r(wald)}, {cmd:r(wald_p)}}the step-3 Wald test on theta{p_end}
{synopt:{cmd:r(alpha)}, {cmd:r(theta)}}speed of adjustment, long-run coefficients{p_end}
{synopt:{cmd:r(bounds)}}simulated bracket, one row per level{p_end}
{synopt:{cmd:r(N)}, {cmd:r(k)}}sample and number of forcing regressors{p_end}

{pstd}{cmd:estat blocks} stores {cmd:r(table)}; {cmd:estat null} stores
{cmd:r(p50)}, {cmd:r(p95)}, {cmd:r(crit)} and {cmd:r(p)}.{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
