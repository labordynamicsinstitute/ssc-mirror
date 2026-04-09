{smcl}
{* version 1.0.0  qmodplot  Noman Arshed  26aug2025}{...}
{* Available from SSC. Type: ssc install qmodplot}{...}
{viewerjumpto "Syntax"       "qmodplot##syntax"}{...}
{viewerjumpto "Description"  "qmodplot##description"}{...}
{viewerjumpto "Key features" "qmodplot##features"}{...}
{viewerjumpto "Options"      "qmodplot##options"}{...}
{viewerjumpto "Models"       "qmodplot##models"}{...}
{viewerjumpto "Examples"     "qmodplot##examples"}{...}

{title:Title}

{phang}
{bf:qmodplot} {hline 2} Quadratic Moderation Plot: visualise conditional
curves, marginal effects, and confidence bands from moderated regression

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qmodplot},
{cmd:model(}{it:#}{cmd:)}
[{it:coefficient_options}]
[{it:variable_label_options}]
[{it:moderator_options}]
[{it:plot_options}]
[{it:ci_options}]
[{it:data_options}]
[{it:ereturn_options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Model (required)}
{synopt:{opt mod:el(#)}}1 = linear x; 2 = quadratic x; 3 = quadratic x + quadratic moderation{p_end}

{syntab:Coefficients (manual entry)}
{synopt:{opt b0(#)}}Intercept (default 0){p_end}
{synopt:{opt bx(#)}}Coefficient on {it:x}{p_end}
{synopt:{opt bxsq(#)}}Coefficient on {it:x}² (models 2 & 3){p_end}
{synopt:{opt bmo:d(#)}}Coefficient on {it:m} (moderator){p_end}
{synopt:{opt bxm(#)}}Coefficient on {it:x·m} (linear interaction){p_end}
{synopt:{opt bxsqm(#)}}Coefficient on {it:x²·m} (quadratic interaction; model 3){p_end}

{syntab:Variable labels}
{synopt:{opt xn:ame(string)}}Label for x axis (default: "x"){p_end}
{synopt:{opt mn:ame(string)}}Label for moderator (default: "m"){p_end}
{synopt:{opt yn:ame(string)}}Label for y axis (default: "y"){p_end}

{syntab:Plot range}
{synopt:{opt xr:ange(# #)}}Lower and upper x-grid bounds (default: -3 3){p_end}
{synopt:{opt np:oints(#)}}Grid points for smooth curves (default: 200){p_end}

{syntab:Moderator reference points (one required)}
{synopt:{opt mv:alues(numlist)}}Explicit moderator values — binary, ordinal, or any set of numbers{p_end}
{synopt:{opt md:ata(varname)}}Derive reference points as evenly-spaced quantiles from a variable{p_end}
{synopt:{opt nq:uantiles(#)}}Number of quantile curves from mdata() (default: 3 → p25/p50/p75){p_end}

{syntab:CI options}
{synopt:{opt ci}}Add delta-method confidence bands (requires fromereturn){p_end}
{synopt:{opt lev:el(#)}}Confidence level in % (default: 95){p_end}

{syntab:Data options}
{synopt:{opt xdata(varname)}}x variable in dataset (used for scatter and summary stats){p_end}
{synopt:{opt ydata(varname)}}y variable in dataset (used for scatter actual values and summary stats){p_end}
{synopt:{opt lab:elvar(varname)}}Label variable for cross-section/time-series scatter{p_end}
{synopt:{opt panel:id(varname)}}Panel ID variable — collapses to unit means before plotting{p_end}
{synopt:{opt cutst:ats}}Print turning-point table (models 2 & 3){p_end}
{synopt:{opt scat:ter}}Plot fitted values for each observation (or panel mean) over model curves{p_end}
{synopt:{opt savet:able(filename)}}Save cutoff table and predictions to a CSV file{p_end}

{syntab:Graph options}
{synopt:{opt ti:tle(string)}}Main title for the function graph{p_end}
{synopt:{opt sc:heme(string)}}Stata graph scheme (default: s2color){p_end}
{synopt:{opt combine}}Stack function and ME graphs into a single combined panel{p_end}
{synopt:{opt expg:raph(filename)}}Export graph(s) to file (any format supported by graph export){p_end}

{syntab:Load from last regression}
{synopt:{opt frome:return}}Read coefficients automatically from e(b){p_end}
{synopt:{opt xvar(name)}}Variable name for {it:x} in e(b){p_end}
{synopt:{opt xsqvar(name)}}Variable name for {it:x²} in e(b){p_end}
{synopt:{opt mv:ar(name)}}Variable name for {it:m} in e(b){p_end}
{synopt:{opt xmvar(name)}}Variable name for {it:x·m} in e(b){p_end}
{synopt:{opt xsqmvar(name)}}Variable name for {it:x²·m} in e(b){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:qmodplot} visualises moderated regression models where the focal variable
{it:x} may enter linearly or as a quadratic, and the moderator {it:m} may
affect both the linear and quadratic components of {it:x}. This covers the full
range from a simple interaction to a fully moderated U-shape.

{pstd}
For every call, {cmd:qmodplot} produces two publication-quality graphs:

{phang2}
{bf:qmodplot_curves} — the predicted function y = f(x) plotted at several
representative values of the moderator.  When the model is quadratic, each
curve is a parabola whose vertex shifts as the moderator changes.

{phang2}
{bf:qmodplot_me} — the marginal (partial) effect dy/dx plotted across the
x range.  For linear models this is a horizontal line; for quadratic models
the slope of the ME line shows how the curvature changes with the moderator.

{pstd}
Two key design choices distinguish {cmd:qmodplot} from generic interaction
plotters:

{phang2}
1. {bf:Quadratic moderation (Model 3).}  Most tools only plot x·m interactions.
{cmd:qmodplot} also handles x²·m, so the vertex of the parabola itself
becomes a function of the moderator — the turning point moves both
horizontally and vertically as m changes.  The {opt cutstats} table
reports exactly where each vertex falls and whether it lies within your
observed data range.

{phang2}
2. {bf:Multiple moderator reference points.}  You are not limited to the
conventional low/medium/high three-curve design.  Specify as many reference
points as you need via {opt mvalues()} — theory-driven cut-points, round
numbers, meaningful thresholds, or every level of an ordinal variable.
Alternatively use {opt mdata()} with {opt nquantiles()} to let the data
determine where the reference points fall (p25/p50/p75, decile boundaries,
etc.).  Each reference point generates one curve in both graphs.

{pstd}
The program never modifies the dataset in memory; it uses
{cmd:preserve}/{cmd:restore} throughout.


{marker features}{...}
{title:Key features at a glance}

{p2colset 5 35 37 2}{...}
{p2col:{bf:Feature}}{bf:Detail}{p_end}
{p2colreset}{...}
{p2colset 5 35 37 2}{...}
{p2col:Three nested models}Linear, quadratic, and fully quadratic-moderated{p_end}
{p2col:Any number of reference points}Use mvalues() or mdata()/nquantiles(){p_end}
{p2col:Delta-method CI bands}Transparent shading; lines visible through bands{p_end}
{p2col:Turning-point table}Vertex x* and y(x*) at every moderator value{p_end}
{p2col:Observation scatter}Label each data point on the model curves{p_end}
{p2col:Panel support}Collapses to unit means before scatter plot{p_end}
{p2col:Live data or manual entry}Works with or without a dataset loaded{p_end}
{p2col:CSV export}Full results table saved to file{p_end}
{p2col:Pure Stata}No Mata; works in Stata 14+{p_end}
{p2colreset}{...}


{marker models}{...}
{title:Models}

{dlgtab:Model 1 — Linear x, Linear Moderation}

{p 8 8 2}
y = b0 + bx·x + bmod·m + bxm·(x·m)

{p 8 8 2}
Marginal effect:  dy/dx = bx + bxm·m  {it:(constant in x — horizontal line)}

{dlgtab:Model 2 — Quadratic x, Linear Moderation}

{p 8 8 2}
y = b0 + bx·x + bxsq·x² + bmod·m + bxm·(x·m)

{p 8 8 2}
Marginal effect:  dy/dx = bx + 2·bxsq·x + bxm·m

{p 8 8 2}
Turning point:    x* = −(bx + bxm·m) / (2·bxsq)
{break}(vertex shifts along x as m changes, but curvature bxsq is constant)

{dlgtab:Model 3 — Quadratic x, Quadratic Moderation (fully moderated curvature)}

{p 8 8 2}
y = b0 + bx·x + bxsq·x² + bmod·m + bxm·(x·m) + bxsqm·(x²·m)

{p 8 8 2}
Marginal effect:  dy/dx = bx + 2·(bxsq + bxsqm·m)·x + bxm·m

{p 8 8 2}
Turning point:    x* = −(bx + bxm·m) / [2·(bxsq + bxsqm·m)]
{break}(both the vertex location AND the curvature change with m)

{pstd}
In Model 3 the moderator does not merely shift the parabola left/right
(as in Model 2); it also tilts and stretches it.  A positive bxsqm means
the U-shape becomes steeper as m increases; a negative bxsqm flattens it.
Use {opt cutstats} to see how the vertex moves across the moderator values
you have specified.


{marker options}{...}
{title:Options in detail}

{phang}
{opt model(#)} sets the functional form.  Must be 1, 2, or 3.  Coefficients
not relevant to the chosen model are accepted but ignored with a note.

{phang}
{opt mvalues(numlist)} specifies any number of moderator values at which to
draw curves.  Examples: {cmd:mvalues(0 1)} for a binary moderator;
{cmd:mvalues(-1 0 1)} for a three-level ordinal; {cmd:mvalues(2000 3000 4000)}
for a continuous moderator at theory-driven cut-points; or even
{cmd:mvalues(1 2 3 4 5)} for all five levels of a Likert scale.
You may supply {opt mdata()} alongside {opt mvalues()} — in that case
{opt mvalues()} still drives the curves and {opt mdata()} is used only
for scatter predictions and summary statistics.

{phang}
{opt mdata(varname)} names a numeric variable in memory.  {cmd:qmodplot}
computes evenly-spaced quantile positions and uses those as the reference
points.  With {opt nquantiles(3)} the positions are p25, p50, p75;
with {opt nquantiles(5)} they are p17, p33, p50, p67, p83; and so on up
to {opt nquantiles(10)}.

{phang}
{opt ci} adds {level}% confidence bands around each conditional curve and
each marginal-effect curve using the delta method.  The bands are drawn as
semi-transparent shading (25% opacity) so that the curve lines and any
overlapping bands from other moderator values remain clearly visible.
Requires {opt fromereturn} and all relevant variable-name options so that
the correct elements can be extracted from e(V).

{phang}
{opt cutstats} prints a turning-point table for models 2 and 3.  For each
moderator value the table shows: the computed vertex x*, the predicted
y(x*), and whether x* falls within the specified x range.  A baseline
row at m = 0 is always included for reference.  Not applicable to Model 1
(linear ME has no turning point).

{phang}
{opt scatter} overlays labelled data points on the model curves.
For cross-section or time-series data, each row in memory becomes one
plotted point; use {opt labelvar()} to identify points by name.
For panel data, use {opt panelid()} — the program collapses x and m to
within-unit means before computing fitted values, and labels each point
with its panel identifier.

{phang}
{opt fromereturn} reads all coefficients from the most recent estimation
results ({cmd:e(b)}).  Combine with {opt xvar()}, {opt xsqvar()},
{opt mvar()}, {opt xmvar()}, {opt xsqmvar()} to identify each term.


{marker examples}{...}
{title:Examples}

{pstd}
All examples use Stata's built-in {cmd:auto} dataset and can be
run directly after copying the commands.

{hline}
{pstd}
{ul:Example 1 — Model 1: binary moderator, manual reference points}

{pstd}
The simplest case: linear MPG effect moderated by car origin (0 = domestic,
1 = foreign).  Two curves are drawn, one per value of the binary moderator.{p_end}

{phang2}{cmd:. sysuse auto, clear}{break}
{cmd:. gen mpgf = mpg * foreign}{break}
{cmd:. regress price mpg foreign mpgf}{break}
{cmd:. qmodplot, model(1) fromereturn}{break}
{cmd:    xvar(mpg) mvar(foreign) xmvar(mpgf)}{break}
{cmd:    xname(MPG) mname(Foreign) yname(Price)}{break}
{cmd:    xrange(12 41) mvalues(0 1) combine}{p_end}

{hline}
{pstd}
{ul:Example 2 — Model 2: continuous moderator, multiple reference points, CI}

{pstd}
Vehicle weight is a continuous moderator.  Five reference points at
theory-driven round numbers show how the MPG–price parabola shifts and
how the turning point moves as cars get heavier.
{opt ci} adds 95% delta-method confidence bands.
{opt cutstats} reports each vertex and whether it lies within the data range.{p_end}

{phang2}{cmd:. sysuse auto, clear}{break}
{cmd:. gen mpgsq = mpg^2}{break}
{cmd:. gen mpgwt = mpg * weight}{break}
{cmd:. regress price mpg mpgsq weight mpgwt}{break}
{cmd:. qmodplot, model(2) fromereturn}{break}
{cmd:    xvar(mpg) xsqvar(mpgsq) mvar(weight) xmvar(mpgwt)}{break}
{cmd:    xname(MPG) mname(Weight) yname(Price)}{break}
{cmd:    xrange(12 41) mvalues(2000 2500 3000 3500 4000)}{break}
{cmd:    ci level(95) cutstats combine}{p_end}

{pstd}
Alternatively, derive reference points automatically from the data:{p_end}

{phang2}{cmd:. qmodplot, model(2) fromereturn}{break}
{cmd:    xvar(mpg) xsqvar(mpgsq) mvar(weight) xmvar(mpgwt)}{break}
{cmd:    xname(MPG) mname(Weight) yname(Price)}{break}
{cmd:    xrange(12 41) mdata(weight) nquantiles(4)}{break}
{cmd:    ci level(95) cutstats combine}{p_end}

{pstd}
({opt nquantiles(4)} gives p20/p40/p60/p80 — four evenly-spaced
positions across the weight distribution.)

{hline}
{pstd}
{ul:Example 3 — Model 3: fully moderated curvature, binary moderator, CI + scatter}

{pstd}
In this model the quadratic term x²·m (mpgfsq) allows the curvature of the
price–MPG parabola to differ between domestic and foreign cars — not just
the vertex location.  {opt scatter} overlays each car's fitted value and
labels it by origin.  Results are saved to a CSV file.{p_end}

{phang2}{cmd:. sysuse auto, clear}{break}
{cmd:. gen mpgsq  = mpg^2}{break}
{cmd:. gen mpgf   = mpg  * foreign}{break}
{cmd:. gen mpgfsq = mpgsq * foreign}{break}
{cmd:. regress price mpg mpgsq foreign mpgf mpgfsq}{break}
{cmd:. qmodplot, model(3) fromereturn}{break}
{cmd:    xvar(mpg) xsqvar(mpgsq) mvar(foreign) xmvar(mpgf) xsqmvar(mpgfsq)}{break}
{cmd:    xname(MPG) mname(Foreign) yname(Price)}{break}
{cmd:    xrange(12 41) mvalues(0 1)}{break}
{cmd:    xdata(mpg) ydata(price) mdata(foreign)}{break}
{cmd:    ci level(95) cutstats scatter labelvar(foreign)}{break}
{cmd:    combine savetable("qmodplot_ex3.csv")}{p_end}

{hline}
{pstd}
{ul:Example 4 — Model 2: continuous moderator, panel-mean scatter}

{pstd}
For panel data, use {opt panelid()} instead of {opt labelvar()}.
The program collapses x and m to within-unit means, computes fitted values
at those means, and labels each plotted point with the panel identifier.
Here we treat {cmd:rep78} (repair record, 1–5) as the panel ID for illustration.{p_end}

{phang2}{cmd:. sysuse auto, clear}{break}
{cmd:. drop if missing(rep78)}{break}
{cmd:. gen mpgsq = mpg^2}{break}
{cmd:. gen mpgwt = mpg * weight}{break}
{cmd:. regress price mpg mpgsq weight mpgwt}{break}
{cmd:. qmodplot, model(2) fromereturn}{break}
{cmd:    xvar(mpg) xsqvar(mpgsq) mvar(weight) xmvar(mpgwt)}{break}
{cmd:    xname(MPG) mname(Weight) yname(Price)}{break}
{cmd:    xrange(12 41) mdata(weight) nquantiles(3)}{break}
{cmd:    xdata(mpg) ydata(price)}{break}
{cmd:    cutstats scatter panelid(rep78) combine}{p_end}


{title:Saved graph names}

{pstd}
{cmd:qmodplot_curves} — conditional function curves{break}
{cmd:qmodplot_me}     — marginal effect curves{break}
{cmd:qmodplot_combined} — stacked panel ({opt combine} only){break}
{cmd:qmodplot_scatter}  — observation/panel scatter ({opt scatter} only)

{pstd}
All graphs remain in Stata's graph memory and can be redisplayed or
exported at any time:{break}
{cmd:. graph display qmodplot_curves}{break}
{cmd:. graph export "fig1.png", name(qmodplot_curves) replace}


{title:Author}

{pstd}
Noman Arshed{break}
Department of Business Analytics, Sunway Business School{break}
Sunway University, Malaysia


{title:Installation}

{pstd}
To install from SSC:{p_end}

{phang2}{cmd:. ssc install qmodplot}{p_end}

{pstd}
To update an existing installation:{p_end}

{phang2}{cmd:. ssc install qmodplot, replace}{p_end}

{pstd}
To install directly from a local file (development use):{p_end}

{phang2}{cmd:. do qmodplot.ado}{p_end}


{title:Citation}

{pstd}
If you use {cmd:qmodplot} in published work, please cite:{p_end}

{phang2}
Arshed, N. (2025). {it:qmodplot: Quadratic Moderation Plot for Stata.}
Statistical Software Components, Boston College Department of Economics.
Available from: https://ideas.repec.org/c/boc/bocode/


{title:Also see}

{psee}{helpb twoway}{p_end}
{psee}{helpb margins} (model-based marginal effects){p_end}
{psee}{helpb graph export}{p_end}
