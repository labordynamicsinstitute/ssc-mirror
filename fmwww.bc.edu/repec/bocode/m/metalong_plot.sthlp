{smcl}
{* *! metalong_plot.sthlp  metaLong for Stata 14.1}{...}
{vieweralsosee "metalong"     "help metalong"}{...}
{vieweralsosee "ml_meta"      "help ml_meta"}{...}
{vieweralsosee "ml_sens"      "help ml_sens"}{...}
{vieweralsosee "ml_spline"    "help ml_spline"}{...}
{vieweralsosee "ml_fragility" "help ml_fragility"}{...}
{hline}
{title:metalong_plot — Combined Publication-Ready Longitudinal Meta-Analysis Figures}

{title:Syntax}

{p 8 17 2}
{cmd:metalong_plot} {cmd:,}
{cmd:metafile(}{it:filename}{cmd:)}
[{cmd:sensfile(}{it:filename}{cmd:)}
{cmd:splinefile(}{it:filename}{cmd:)}
{cmd:fragfile(}{it:filename}{cmd:)}
{cmd:alpha(}{real}{cmd:)}
{cmd:delta(}{real}{cmd:)}
{cmd:title(}{string}{cmd:)}
{cmd:scheme(}{string}{cmd:)}
{cmd:saving(}{filename}{cmd:)}
{cmd:replace}]

{title:Description}

{pstd}
{cmd:metalong_plot} assembles a combined multi-panel figure from the results of the
{cmd:metaLong} pipeline. Only {cmd:metafile()} is required; each additional
file adds a panel to the figure.

{pstd}
{bf:Panel 1 — Pooled effect trajectory} (always drawn):
Plots theta(t) with a shaded confidence ribbon. Significant time points are
marked with a distinct symbol; a dashed line marks the null (theta = 0).

{pstd}
{bf:Panel 2 — Sensitivity profile} ({cmd:sensfile()} required):
Plots ITCV_adj(t) against the fragility threshold delta. Fragile time points
are shown in red.

{pstd}
{bf:Panel 3 — Spline smooth} ({cmd:splinefile()} required):
Overlays the RCS spline prediction with confidence band on the observed
pooled estimates with error bars.

{pstd}
{bf:Panel 4 — Fragility index} ({cmd:fragfile()} required):
Bar chart of the leave-k-out fragility index by time point.

{title:Required option}

{phang}
{cmd:metafile(}{it:filename}{cmd:)} specifies the path to the results dataset
saved by {helpb ml_meta}. This is always required.

{title:Optional panel options}

{phang}
{cmd:sensfile(}{it:filename}{cmd:)} adds Panel 2. Specify the path to the
dataset saved by {helpb ml_sens}.

{phang}
{cmd:splinefile(}{it:filename}{cmd:)} adds Panel 3. Specify the path to the
prediction dataset saved by {helpb ml_spline}.

{phang}
{cmd:fragfile(}{it:filename}{cmd:)} adds Panel 4. Specify the path to the
dataset saved by {helpb ml_fragility}.

{title:Appearance options}

{phang}
{cmd:alpha(}{real}{cmd:)} sets the significance level for CI ribbon (Panel 1).
Default is 0.05.

{phang}
{cmd:delta(}{real}{cmd:)} sets the fragility threshold reference line in the
sensitivity panel. Default is 0.15.

{phang}
{cmd:title(}{string}{cmd:)} sets an overall title above all panels.

{phang}
{cmd:scheme(}{string}{cmd:)} specifies the Stata graph scheme. Default is
{cmd:s2color}. Other common choices: {cmd:s1mono}, {cmd:lean2}, {cmd:538}.

{phang}
{cmd:saving(}{filename}{cmd:)} saves the combined graph to {it:filename}.gph.

{phang}
{cmd:replace} allows overwriting an existing {cmd:saving()} file.

{title:Example — full pipeline}

{phang2}{cmd:. sim_longmeta, k(20) times(0 6 12 24) seed(42) clear}

{phang2}{cmd:. ml_meta yi vi, study(study) time(time) saving(meta_res) replace}

{phang2}{cmd:. ml_sens yi vi, study(study) time(time) ///}
{phang3}{cmd:    metafile(meta_res) saving(sens_res) replace}

{phang2}{cmd:. ml_fragility yi vi, study(study) time(time) ///}
{phang3}{cmd:    metafile(meta_res) maxk(3) saving(frag_res) replace}

{phang2}{cmd:. ml_spline, metafile(meta_res) df(3) saving(spline_res) replace}

{phang2}{cmd:. metalong_plot, metafile(meta_res) sensfile(sens_res) ///}
{phang3}{cmd:    splinefile(spline_res) fragfile(frag_res) ///}
{phang3}{cmd:    title("Longitudinal Meta-Analysis") ///}
{phang3}{cmd:    saving(combined_figure.gph) replace}

{title:Notes}

{pstd}
The combined graph is produced using Stata's {helpb graph combine}. Individual
named graphs (panel1, panel2, etc.) are automatically dropped after combining.
To export to PDF or PNG, use {helpb graph export} after {cmd:metalong_plot}.

{phang2}{cmd:. metalong_plot, metafile(meta_res) sensfile(sens_res)}

{phang2}{cmd:. graph export combined.pdf, replace}

{title:See also}

{helpb ml_meta}, {helpb ml_sens}, {helpb ml_spline}, {helpb ml_fragility},
{helpb graph combine}, {helpb metalong}

{hline}
