{smcl}
{* *! version 1.1.0  2026-04-27}{...}
{viewerjumpto "Syntax" "mht_test##syntax"}{...}
{viewerjumpto "Quick start" "mht_test##quick"}{...}
{viewerjumpto "Description" "mht_test##description"}{...}
{viewerjumpto "Options" "mht_test##options"}{...}
{viewerjumpto "Examples" "mht_test##examples"}{...}
{viewerjumpto "Stored results" "mht_test##stored"}{...}
{viewerjumpto "References" "mht_test##refs"}{...}

{title:Title}

{phang}
{bf:mht_test} {hline 2} Apply optimal multiple-hypothesis testing adjustment to a list of p-values


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mht_test} {it:varname} {ifin}{cmd:,} {opt alpha:bar(#)} [{it:options}]

{pstd}
where {it:varname} is a variable holding a {bf:list of p-values} (one p-value per
observation, one observation per hypothesis). With option {opt zstat}, {it:varname}
is interpreted as a list of one-sided z-statistics instead.


{marker quick}{...}
{title:Quick start}

{pstd}Apply the optimal MHT correction to 6 hypotheses (Linear/FDA calibration):{p_end}
{phang2}{cmd:. mht_test pval, alphabar(0.05)}{p_end}

{pstd}Same input given as z-statistics:{p_end}
{phang2}{cmd:. mht_test zstat, alphabar(0.05) zstat}{p_end}

{pstd}Use the Cobb-Douglas (J-PAL) calibration with custom elasticities:{p_end}
{phang2}{cmd:. mht_test pval, alphabar(0.05) model(cobbdouglas) beta(0.13) iota(0.075)}{p_end}

{pstd}Save rejection indicators with a custom prefix:{p_end}
{phang2}{cmd:. mht_test pval, alphabar(0.05) generate(myrej)}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_test} applies the optimal multiple-hypothesis-testing adjustment from
Viviano, Wuthrich, and Niehaus (2026) to a {bf:collection of p-values} stored
in a single variable. Each observation in the active sample contributes one
hypothesis, so the number of hypotheses {bf:|J|} equals the number of in-sample
observations.

{pstd}
{bf:Note on |J|}: |J| is set to {bf:the number of in-sample observations},
i.e., the number of p-values being tested. If you pass {opt if} or {opt in}
to subset the data, |J| changes accordingly. Make sure the active sample
contains exactly the hypotheses you want to correct over.

{pstd}
The command compares five rejection rules side by side:

{phang2}1. {bf:Optimal} model-based rule (Proposition 4.1, paper):
critical value derived from the cost function.{p_end}
{phang2}2. {bf:Bonferroni}: {bf:alphabar/J}.{p_end}
{phang2}3. {bf:Holm} step-down procedure.{p_end}
{phang2}4. {bf:Benjamini-Hochberg} step-up FDR control.{p_end}
{phang2}5. {bf:Unadjusted} ({bf:alphabar}).{p_end}

{pstd}
Output includes a summary line for each procedure (test size and number of
rejections) and a per-hypothesis table showing which rule rejects which
hypothesis. Five new variables are also generated for downstream use.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt alpha:bar(#)} is the benchmark single-hypothesis size {bf:alphabar} that
would apply if there were only one hypothesis. Standard choices are 0.05 and 0.025.

{dlgtab:Input format}

{phang}
{opt zstat} indicates that {it:varname} contains one-sided z-statistics (not p-values).
The command internally converts them via {bf:1 - normal(z)} before applying the
adjustment.

{dlgtab:Cost model}

{phang}
{opt mod:el(string)} selects the cost function. Either {bf:linear} (default,
calibrated to FDA Phase III data) or {bf:cobbdouglas} (calibrated to J-PAL data).

{phang}
{opt cfs:hare(#)} (Linear only): fixed-cost share c_f / E[C]. Default {bf:0.46}
(Sertkaya et al. 2016).

{phang}
{opt jbar(#)} (Linear only): average number of subgroups in the benchmark study.
Default {bf:3}.

{phang}
{opt nmr:atio(#)}: ratio n_bar / m_bar of per-arm to benchmark sample size.
Default {bf:1.0}.

{phang}
{opt beta(#)} (Cobb-Douglas only): elasticity of cost with respect to |J|.
Default {bf:0.13} (J-PAL).

{phang}
{opt iota(#)} (Cobb-Douglas only): elasticity of cost with respect to per-arm
sample size. Default {bf:0.075} (J-PAL).

{dlgtab:Output}

{phang}
{opt gen:erate(string)} sets the prefix for the five rejection-indicator variables
created by the command. Default {bf:mht}, yielding {bf:mht_reject_opt},
{bf:mht_reject_bonf}, etc.

{phang}
{opt replace} replaces existing variables with the chosen prefix.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}: a small set of one-sided p-values{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 6}{p_end}
{phang2}{cmd:. gen pval = .}{p_end}
{phang2}{cmd:. replace pval = 0.003 in 1}{p_end}
{phang2}{cmd:. replace pval = 0.015 in 2}{p_end}
{phang2}{cmd:. replace pval = 0.030 in 3}{p_end}
{phang2}{cmd:. replace pval = 0.048 in 4}{p_end}
{phang2}{cmd:. replace pval = 0.120 in 5}{p_end}
{phang2}{cmd:. replace pval = 0.500 in 6}{p_end}

{pstd}{bf:Apply the Linear (FDA) MHT correction}{p_end}
{phang2}{cmd:. mht_test pval, alphabar(0.05)}{p_end}

{pstd}{bf:Cobb-Douglas (J-PAL) calibration}{p_end}
{phang2}{cmd:. mht_test pval, alphabar(0.05) model(cobbdouglas) replace}{p_end}

{pstd}{bf:Z-statistic input}{p_end}
{phang2}{cmd:. gen z = invnormal(1 - pval)}{p_end}
{phang2}{cmd:. mht_test z, alphabar(0.05) zstat generate(zr) replace}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_test} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(alpha_opt)}}optimal test size {bf:alpha*}{p_end}
{synopt:{cmd:r(alpha_bonf)}}Bonferroni test size {bf:alphabar/J}{p_end}
{synopt:{cmd:r(alpha_bar)}}benchmark alpha (input){p_end}
{synopt:{cmd:r(J)}}number of hypotheses tested{p_end}
{synopt:{cmd:r(n_reject_opt)}}rejections under the optimal rule{p_end}
{synopt:{cmd:r(n_reject_bonf)}}rejections under Bonferroni{p_end}
{synopt:{cmd:r(n_reject_holm)}}rejections under Holm{p_end}
{synopt:{cmd:r(n_reject_bh)}}rejections under BH/FDR{p_end}
{synopt:{cmd:r(n_reject_unadj)}}rejections unadjusted{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(model)}}cost model used (linear / cobbdouglas){p_end}

{pstd}
{cmd:mht_test} also creates the following new variables (with prefix {it:generate}, default {bf:mht}):

{phang2}{it:prefix}{bf:_reject_opt}   - 1 if rejected by the optimal rule{p_end}
{phang2}{it:prefix}{bf:_reject_bonf}  - 1 if rejected by Bonferroni{p_end}
{phang2}{it:prefix}{bf:_reject_holm}  - 1 if rejected by Holm{p_end}
{phang2}{it:prefix}{bf:_reject_bh}    - 1 if rejected by BH/FDR{p_end}
{phang2}{it:prefix}{bf:_reject_unadj} - 1 if rejected unadjusted{p_end}
{phang2}{it:prefix}{bf:_alpha_opt}    - the optimal test size (constant across rows){p_end}


{marker refs}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
{it:A model of multiple hypothesis testing}.
arXiv:2104.13367v10.
{p_end}

{phang}
Sertkaya, A., et al. (2016). Key cost drivers of pharmaceutical clinical trials in
the United States.{it: Clinical Trials}, 13(2), 117-126.
{p_end}


{title:Also see}

{psee}
Online: {help mht_critical}, {help mht_est}, {help mht_table}, {help mht_cost_estimate}
{p_end}
