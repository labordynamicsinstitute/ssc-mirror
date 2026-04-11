{smcl}
{* *! ml_fragility.sthlp  metaLong for Stata 14.1}{...}
{vieweralsosee "metalong"  "help metalong"}{...}
{vieweralsosee "ml_meta"   "help ml_meta"}{...}
{vieweralsosee "ml_sens"   "help ml_sens"}{...}
{vieweralsosee "ml_plot"   "help ml_plot"}{...}
{hline}
{title:ml_fragility — Leave-k-out Fragility Analysis}

{title:Syntax}

{p 8 17 2}
{cmd:ml_fragility} {it:yi vi} [{it:if}] [{it:in}] {cmd:,}
{cmdab:stu:dy(}{varname}{cmd:)}
{cmdab:ti:me(}{varname}{cmd:)}
{cmd:metafile(}{it:filename}{cmd:)}
[{cmd:alpha(}{real}{cmd:)}
{cmd:maxk(}{integer}{cmd:)}
{cmd:nosmallsample}
{cmd:saving(}{filename}{cmd:)}
{cmd:replace}]

{title:Description}

{pstd}
{cmd:ml_fragility} computes the {it:fragility index} at each follow-up time point.
Studies are removed one at a time (leave-one-out) or in random combinations of
size 2 to {cmd:maxk()} (leave-k-out). The fragility index is the {it:minimum}
number of removals required to flip the significance conclusion (significant →
non-significant, or vice versa).

{pstd}
A fragility index of 1 means a single study's removal changes the conclusion.
The fragility quotient (index / k) normalises for sample size.

{title:Required options}

{phang}
{cmd:study(}{varname}{cmd:)} specifies the study (cluster) identifier variable.

{phang}
{cmd:time(}{varname}{cmd:)} specifies the numeric follow-up time variable.

{phang}
{cmd:metafile(}{it:filename}{cmd:)} specifies the path to the results dataset
saved by {helpb ml_meta}.

{title:Main options}

{phang}
{cmd:alpha(}{real}{cmd:)} sets the significance level. Default is 0.05.

{phang}
{cmd:maxk(}{integer}{cmd:)} sets the maximum number of studies to remove.
Default is 5. Larger values are more exhaustive but considerably slower.

{phang}
{cmd:nosmallsample} uses z-based (large-sample) inference in the re-fit
models instead of t(k−1).

{phang}
{cmd:saving(}{filename}{cmd:)} saves the fragility results to {it:filename}.dta.

{phang}
{cmd:replace} allows overwriting an existing {cmd:saving()} file.

{title:Saved dataset columns}

{synoptset 22 tabbed}{...}
{synopt:{opt time}}Follow-up time{p_end}
{synopt:{opt k_studies}}Number of unique studies at this time point{p_end}
{synopt:{opt p_original}}Original p-value from {cmd:ml_meta}{p_end}
{synopt:{opt sig_original}}1 if originally significant at alpha{p_end}
{synopt:{opt fragility_index}}Min removals to flip significance;{break}missing if FI > maxk{p_end}
{synopt:{opt frag_quotient}}fragility_index / k_studies{p_end}
{synopt:{opt study_removed}}Study ID whose removal flipped (leave-one-out only){p_end}

{title:Returned r() values}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(fragility)}}Matrix of results{p_end}
{synopt:{cmd:r(alpha)}}Significance level used{p_end}
{synopt:{cmd:r(maxk)}}Maximum k tested{p_end}

{title:Algorithm}

{pstd}
At each time point t with k studies:

{pstd}
{bf:Step 1 — Leave-one-out:}
For each study s, remove it, re-estimate the pooled effect with DL tau2 and
cluster-robust SE, and check whether significance flips. If any single removal
flips significance, fragility_index = 1.

{pstd}
{bf:Step 2 — Leave-k-out (k = 2 … maxk):}
If the LOO pass found no flip, up to 500 random combinations of k studies are
tested for each k. The smallest k producing a flip defines the fragility index.

{title:Note on computation time}

{pstd}
For large datasets or many time points with many studies, computation can be
slow. Reducing {cmd:maxk()} or restricting to specific time points with {cmd:if}
will accelerate the analysis.

{title:Example}

{phang2}{cmd:. sim_longmeta, k(12) times(0 6 12) seed(5) clear}

{phang2}{cmd:. ml_meta yi vi, study(study) time(time) saving(meta_res) replace}

{phang2}{cmd:. ml_fragility yi vi, study(study) time(time) ///}
{phang3}{cmd:    metafile(meta_res) maxk(3) alpha(0.05) saving(frag_res) replace}

{phang2}{cmd:. use frag_res, clear}

{phang2}{cmd:. list time k_studies fragility_index frag_quotient study_removed}

{title:References}

{phang}
Walsh, M., et al. (2014). The statistical significance of randomized controlled
trial results is frequently fragile: a case for a Fragility Index.
{it:Journal of Clinical Epidemiology}, 67(6), 622–628.

{phang}
Hedges, L.V., Tipton, E., & Johnson, M.C. (2010).
Robust variance estimation in meta-regression with dependent effect sizes.
{it:Research Synthesis Methods}, 1(1), 39-65.

{title:See also}

{helpb ml_meta}, {helpb ml_sens}, {helpb metalong_plot}, {helpb metalong}

{hline}
