{smcl}
{* 06jul2026}{...}
{vieweralsosee "xtpmg" "help xtpmg"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "estat" "help estat"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{viewerjumpto "Syntax" "xtpmg_postestimation##syntax"}{...}
{viewerjumpto "Description" "xtpmg_postestimation##description"}{...}
{viewerjumpto "Graph subcommands" "xtpmg_postestimation##graph"}{...}
{viewerjumpto "Bootstrap subcommand" "xtpmg_postestimation##boot"}{...}
{viewerjumpto "Options" "xtpmg_postestimation##options"}{...}
{viewerjumpto "Stored results" "xtpmg_postestimation##results"}{...}
{viewerjumpto "Examples" "xtpmg_postestimation##examples"}{...}
{viewerjumpto "References" "xtpmg_postestimation##refs"}{...}
{viewerjumpto "Author" "xtpmg_postestimation##author"}{...}
{cmd:help xtpmg postestimation} {right:version 2.1.1}
{hline}

{title:Title}

{p2colset 5 31 33 2}{...}
{p2col :{cmd:xtpmg postestimation} {hline 2}}Postestimation tools for {helpb xtpmg}{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are available after {cmd:xtpmg} (for the
{cmd:pmg} and {cmd:mg} estimators, which produce heterogeneous per-panel
coefficients):

{synoptset 22 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb xtpmg_postestimation##graph:estat box}}box plot of the per-panel coefficient distribution{p_end}
{synopt :{helpb xtpmg_postestimation##graph:estat bar}}bar plot of each panel's coefficient(s){p_end}
{synopt :{helpb xtpmg_postestimation##graph:estat rcap}}range (caterpillar) plot: per-panel point estimate and 95% CI{p_end}
{synopt :{helpb xtpmg_postestimation##boot:estat bootstrap}}bootstrap standard errors / confidence intervals{p_end}
{synopt :{helpb xtpmg_postestimation##haus:estat hausman}}Hausman test and long-run coefficient comparison graph{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The {cmd:estat} graph subcommands mirror the interface of {helpb xtdcce2}
(Ditzen). The per-panel estimates are those stored in {cmd:e(b_i)} and
{cmd:e(se_i)}; the dashed reference line is the mean-group estimate.


{marker syntax}{...}
{title:Syntax}

{pstd}
{ul:Per-panel coefficient graphs}

{p 8 16 2}
{cmd:estat} {it:graphtype} [{it:coeflist}] {ifin}
[{cmd:,} {opt comb:ine(string)} {opt ind:ividual(string)}
{opt nomg} {opt clear:graph} {opt drop:zero}]

{synoptset 20}{...}
{synopt:{it:graphtype}}Description{p_end}
{synoptline}
{synopt :{opt box}}box plot{p_end}
{synopt :{opt bar}}bar plot{p_end}
{synopt :{opt rcap}}range plot (per-panel point estimate + 95% CI){p_end}
{synoptline}

{pstd}
{it:coeflist} is an optional list of coefficient names to plot (for example
{cmd:ec}, or a short-run variable such as {cmd:x1}). Names are matched by their
base variable name, so {cmd:x1} matches {cmd:D.x1}. If omitted, all estimated
coefficients except the constant are plotted. {cmd:ec} denotes the
error-correction (speed-of-adjustment) term.

{pstd}
{ul:Bootstrap}

{p 8 16 2}
{cmd:estat bootstrap} [{cmd:,} {opt rep:s(#)} {opt seed(string)}
{opt perc:entile} {opt l:evel(#)} {opt wild} {opt showind:ividual}]

{pstd}
{ul:Hausman comparison graph}

{p 8 16 2}
{cmd:estat hausman} {it:estname1} {it:estname2} [{it:estname3} ...]
[{cmd:,} {opt sigma:more} {opt nog:raph} {opt name(string)}]

{p 8 8 2}
where {it:estname1}, {it:estname2}, ... are the names of {cmd:estimates store}d
{cmd:xtpmg} fits (for example {cmd:mg}, {cmd:pmg}, {cmd:dfe}). The Hausman test
is run on the first two (consistent vs efficient); all listed estimators are
shown in the graph.


{marker graph}{...}
{title:Graph subcommands (box, bar, rcap)}

{pstd}
These commands visualize the heterogeneity of the per-panel estimates that
{cmd:xtpmg} produces under the {cmd:pmg} and {cmd:mg} estimators. They are not
available after {cmd:dfe} (which has no per-panel coefficients).

{phang}
{cmd:estat box} draws a box plot of the distribution of each selected
coefficient across panels.

{phang}
{cmd:estat bar} draws, for each selected coefficient, a bar chart of the panel
point estimates. Multiple coefficients are combined into one figure.

{phang}
{cmd:estat rcap} draws a range (caterpillar) plot: for each selected
coefficient the per-panel point estimate is shown with its 95% confidence
interval, together with the mean-group estimate (dashed line).


{marker boot}{...}
{title:Bootstrap subcommand}

{pstd}
{cmd:estat bootstrap} computes bootstrap standard errors and confidence
intervals for the reported coefficient vector {cmd:e(b)} by the
{it:cross-section (panel) bootstrap}: panels (cross-sectional units) are drawn
with replacement, and {cmd:xtpmg} is re-estimated on each resample using the
exact original command (including any automatic lag selection). See Westerlund,
Petrova and Norkute (2019) and Goncalves and Perron (2014).

{pstd}
By default the bootstrap standard error (the standard deviation of the
bootstrap replicates) is reported, and confidence intervals are formed by the
normal approximation {cmd:b +/- z*se}. With {opt percentile} the intervals are
the empirical percentiles of the bootstrap distribution.

{pstd}
The user's estimation results are protected during resampling and restored on
exit, so {cmd:e(b)}, {cmd:e(V)} and the active estimates are unchanged
afterwards.

{pstd}
{bf:Note.} The {opt wild} option is reserved for a future release. The wild
bootstrap of the error-correction equation requires re-cumulating the dependent
variable under the null so that the level term in the error-correction
component remains consistent; until that is implemented correctly, specifying
{opt wild} prints a note and falls back to the cross-section bootstrap.


{marker haus}{...}
{title:Hausman comparison graph}

{pstd}
{cmd:estat hausman} draws a forest-style plot of the {bf:long-run} coefficients
from two or more stored {cmd:xtpmg} fits (each with its 95% confidence
interval), and runs the Hausman specification test on the first two. It prints
the test result (chi-squared, degrees of freedom, p-value) and annotates it on
the graph.

{pstd}
Order the estimators {it:less-restrictive first}: the first is treated as the
consistent estimator ({cmd:b}) and the second as the efficient-under-H0
estimator ({cmd:B}). For the standard PMG test use {cmd:estat hausman mg pmg}.
Overlapping intervals across estimators indicate that the estimates do not
differ systematically (consistent with a large p-value). The active estimation
results are restored on exit. See also the model-selection guide in
{helpb xtpmg##hausman:help xtpmg}.


{marker options}{...}
{title:Options}

{dlgtab:Graph options}

{phang}
{opt combine(string)} passes {it:string} as options to the combined
{helpb graph combine} (bar and rcap) or to {helpb graph box}.

{phang}
{opt individual(string)} passes {it:string} as options to each individual panel
graph (bar and rcap only).

{phang}
{opt nomg} suppresses the mean-group reference line in the bar and rcap graphs.

{phang}
{opt cleargraph} clears the default styling of the graph command, best used
together with {opt combine()} and {opt individual()} to supply your own look.

{phang}
{opt dropzero} does not display coefficients that are identically zero across
panels.

{dlgtab:Bootstrap options}

{phang}
{opt reps(#)} sets the number of bootstrap replications; the default is
{cmd:reps(100)}.

{phang}
{opt seed(string)} sets the random-number seed; see {helpb seed}.

{phang}
{opt percentile} reports percentile confidence intervals instead of the
normal-approximation intervals.

{phang}
{opt level(#)} sets the confidence level; the default is {cmd:level(95)} (or as
set by {helpb set level}).

{phang}
{opt wild} requests the wild bootstrap (currently falls back to the
cross-section bootstrap; see the note above).

{phang}
{opt showindividual} is reserved for displaying unit-specific bootstrap results.

{dlgtab:Hausman options}

{phang}
{opt sigmamore} bases both covariance matrices on the same disturbance-variance
estimate; recommended for numerical stability (passed to {helpb hausman}).

{phang}
{opt nograph} reports the Hausman test only, without producing the graph.

{phang}
{opt name(string)} sets the name of the graph; the default is
{cmd:xtpmg_hausman}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:estat rcap}, {cmd:estat bar} and {cmd:estat box} return in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(graph_name)}}name of the (combined) graph created{p_end}

{pstd}
{cmd:estat bootstrap} returns in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(reps)}}number of successful bootstrap replications{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(method)}}{cmd:cross-section}{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(se_boot)}}bootstrap standard errors{p_end}
{synopt:{cmd:r(ci_lo)}}lower percentile confidence limits{p_end}
{synopt:{cmd:r(ci_hi)}}upper percentile confidence limits{p_end}

{pstd}
{cmd:estat hausman} returns in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(chi2)}}Hausman chi-squared statistic{p_end}
{synopt:{cmd:r(df)}}degrees of freedom{p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(graph_name)}}name of the comparison graph{p_end}

{pstd}
The per-panel matrices used by the graph subcommands are stored by {cmd:xtpmg}
itself in {cmd:e(b_i)}, {cmd:e(se_i)} and {cmd:e(coef_i)}; see
{helpb xtpmg##results:help xtpmg}.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. webuse pig}{p_end}
{phang2}{cmd:. xtpmg d.weight d.week, lr(l.weight week) pmg replace}{p_end}

{pstd}{bf:Caterpillar plot of the per-panel error-correction term}{p_end}
{phang2}{cmd:. estat rcap ec}{p_end}

{pstd}{bf:Caterpillar plot of all coefficients}{p_end}
{phang2}{cmd:. estat rcap}{p_end}

{pstd}{bf:Bar plot without the mean-group line}{p_end}
{phang2}{cmd:. estat bar, nomg}{p_end}

{pstd}{bf:Box plot of the coefficient distributions}{p_end}
{phang2}{cmd:. estat box}{p_end}

{pstd}{bf:Cross-section bootstrap, 500 replications}{p_end}
{phang2}{cmd:. estat bootstrap, reps(500) seed(12345)}{p_end}

{pstd}{bf:Percentile bootstrap confidence intervals}{p_end}
{phang2}{cmd:. estat bootstrap, reps(500) seed(12345) percentile}{p_end}

{pstd}{bf:Hausman comparison graph (MG vs PMG, plus DFE)}{p_end}
{phang2}{cmd:. xtpmg d.weight d.week, lr(l.weight week) pmg replace}{p_end}
{phang2}{cmd:. estimates store pmg}{p_end}
{phang2}{cmd:. xtpmg d.weight d.week, lr(l.weight week) mg replace}{p_end}
{phang2}{cmd:. estimates store mg}{p_end}
{phang2}{cmd:. xtpmg d.weight d.week, lr(l.weight week) dfe replace}{p_end}
{phang2}{cmd:. estimates store dfe}{p_end}
{phang2}{cmd:. estat hausman mg pmg dfe, sigmamore}{p_end}


{marker refs}{...}
{title:References}

{phang}
Goncalves, S. and B. Perron. 2014. Bootstrapping factor-augmented regression
models. {it:Journal of Econometrics} 182: 156-173.

{phang}
Pesaran, M.H. 2015. Testing weak cross-sectional dependence in large panels.
{it:Econometric Reviews} 34: 1089-1117.

{phang}
Westerlund, J., Y. Petrova, and M. Norkute. 2019. CCE in fixed-T panels.
{it:Journal of Applied Econometrics} 34: 746-761.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
{space 2}Help:  {helpb xtpmg}, {helpb estat}, {helpb xtdcce2}
{p_end}
