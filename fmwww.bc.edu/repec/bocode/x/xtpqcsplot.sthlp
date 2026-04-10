{smcl}
{* *! version 1.0.1  08apr2026}{...}
{vieweralsosee "xtpqcs" "help xtpqcs"}{...}
{vieweralsosee "xtpqcsmc" "help xtpqcsmc"}{...}
{viewerjumpto "Syntax" "xtpqcsplot##syntax"}{...}
{viewerjumpto "Description" "xtpqcsplot##description"}{...}
{viewerjumpto "Options" "xtpqcsplot##options"}{...}
{viewerjumpto "Requirements" "xtpqcsplot##requirements"}{...}
{viewerjumpto "Warnings and cautions" "xtpqcsplot##warnings"}{...}
{viewerjumpto "Examples" "xtpqcsplot##examples"}{...}
{viewerjumpto "Stored results" "xtpqcsplot##results"}{...}
{viewerjumpto "References" "xtpqcsplot##references"}{...}
{viewerjumpto "Author" "xtpqcsplot##author"}{...}
{title:Title}

{phang}
{bf:xtpqcsplot} {hline 2} Quantile process plot for panel quantile
regression with common shocks


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpqcsplot} {depvar} {indepvars} {ifin}{cmd:,}
{cmdab:i:d(}{varname}{cmd:)}
{cmdab:t:ime(}{varname}{cmd:)}
[{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{cmdab:i:d(}{varname}{cmd:)}}cross-sectional unit identifier (numeric){p_end}
{synopt:{cmdab:t:ime(}{varname}{cmd:)}}time period identifier (numeric){p_end}

{syntab:Quantile grid}
{synopt:{cmdab:q:uantiles(}{it:numlist}{cmd:)}}grid of quantile indices in (0,1); default {cmd:0.10 0.25 0.50 0.75 0.90}{p_end}

{syntab:Variable selection}
{synopt:{cmdab:var:iables(}{it:varlist}{cmd:)}}subset of regressors to plot; default = all {indepvars}{p_end}

{syntab:Estimation}
{synopt:{cmdab:b:andwidth(}{it:#}{cmd:)}}kernel bandwidth, passed to {cmd:xtpqcs}; default Silverman{p_end}
{synopt:{cmdab:k:ernel(}{it:string}{cmd:)}}{cmd:gaussian} (default), {cmd:epanechnikov}, or {cmd:uniform}{p_end}
{synopt:{cmd:level(}{it:#}{cmd:)}}confidence level for CI bands; default {cmd:level(95)}{p_end}

{syntab:Plot appearance}
{synopt:{cmdab:nocl:assical}}suppress the classical Kato et al. (blue) CI band{p_end}
{synopt:{cmdab:noco:mbine}}produce one separate graph per variable (do not combine){p_end}
{synopt:{cmd:title(}{it:string}{cmd:)}}override the main title on the combined graph{p_end}
{synopt:{cmd:subtitle(}{it:string}{cmd:)}}override the subtitle on the combined graph{p_end}
{synopt:{cmdab:sc:heme(}{it:string}{cmd:)}}Stata graph scheme; default {cmd:s2color}{p_end}

{syntab:Output}
{synopt:{cmdab:sav:ing(}{it:filename}{cmd:)}}save the combined graph as a .gph file{p_end}
{synopt:{cmd:asis}}keep the results dataset in memory after the command (advanced){p_end}
{synoptline}

{pstd}
{depvar} and {indepvars} must be numeric variables.
All panel requirements of {cmd:xtpqcs} apply.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqcsplot} runs {helpb xtpqcs} at every quantile in
{cmd:quantiles()} and produces a {bf:publication-quality} coefficient
process plot of beta{subscript:j}(tau) together with two pointwise
confidence bands:

{p 8 16 2}
{err:{bf:Red shaded band}} {hline 2} Robust common-shock-aware CI from
Chiang, Galvao and Wei (2026).{p_end}
{p 8 16 2}
{res:{bf:Blue dashed band}} {hline 2} Classical Kato et al. (2012)
sandwich CI (assumes cross-sectional independence).{p_end}

{pstd}
A horizontal reference line is drawn at zero.  The two bands together
let the practitioner visually assess:

{phang2}(i) how the regression coefficient varies across quantiles
(heterogeneous effects);{p_end}
{phang2}(ii) by how much the classical procedure understates
uncertainty when common shocks are present.{p_end}

{pstd}
When {cmd:noclassical} is specified, only the robust (red) band is shown.
When multiple regressors are requested, each variable gets its own
sub-graph and they are combined into a single panel (unless
{cmd:nocombine} is given).


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmdab:i:d(}{varname}{cmd:)} specifies the cross-sectional identifier.
Same as in {helpb xtpqcs}.

{phang}
{cmdab:t:ime(}{varname}{cmd:)} specifies the time identifier.
Same as in {helpb xtpqcs}.

{dlgtab:Quantile grid}

{phang}
{cmdab:q:uantiles(}{it:numlist}{cmd:)} specifies the grid of quantile
indices at which to estimate.  All values must lie strictly between
0 and 1.  Default is {cmd:0.10 0.25 0.50 0.75 0.90}.  For a smooth
process plot use a fine grid such as {cmd:0.05(0.05)0.95} (19 points).

{dlgtab:Variable selection}

{phang}
{cmdab:var:iables(}{it:varlist}{cmd:)} selects a subset of the
independent variables to plot.  By default all {indepvars} are
plotted.  Use this when you have many regressors but only care about
one or two.

{dlgtab:Estimation}

{phang}
{cmdab:b:andwidth(}{it:#}{cmd:)}, {cmdab:k:ernel(}{it:string}{cmd:)},
and {cmd:level(}{it:#}{cmd:)} are passed through to each
{cmd:xtpqcs} call.  See {helpb xtpqcs} for details.

{dlgtab:Plot appearance}

{phang}
{cmdab:nocl:assical} suppresses the blue classical CI band.  Useful
when you only want to display the robust (common-shock-aware) band.

{phang}
{cmdab:noco:mbine} prevents the automatic {cmd:graph combine} of
multi-regressor plots.  Each variable's graph is left as a separate
named graph in memory.

{phang}
{cmd:title(}{it:string}{cmd:)} overrides the main title on the combined
panel.  Enclose text in quotes.

{phang}
{cmd:subtitle(}{it:string}{cmd:)} overrides the subtitle on the combined
panel.  Enclose text in quotes.

{phang}
{cmdab:sc:heme(}{it:string}{cmd:)} specifies the Stata graph scheme.
Default is {cmd:s2color}.

{dlgtab:Output}

{phang}
{cmdab:sav:ing(}{it:filename}{cmd:)} saves the combined graph as a
Stata .gph file.

{phang}
{cmd:asis} keeps the estimation-results dataset in memory after the
command finishes.  By default the original data is restored.  This is
an advanced option for users who wish to do custom post-processing of
the quantile-by-quantile estimates.


{marker requirements}{...}
{title:Requirements}

{phang}
{bf:Stata version:} 14.0 or later.

{phang}
{bf:Dependencies:} {cmd:xtpqcs} must be installed.  If you installed
the {cmd:xtpqcs} package, this is included automatically.

{phang}
{bf:Panel structure:} Same requirements as {helpb xtpqcs}:  balanced or
moderately unbalanced, N >= 2, T >= 5.

{phang}
{bf:Graph capability:} Results require a graph-capable Stata session.
In batch mode ({cmd:/e}), graphs are created but not displayed;  use
{cmd:graph export} to save as PNG/PDF.

{phang}
{bf:Memory:} A fine grid (e.g. 19 quantiles x 10 regressors) calls
{cmd:xtpqcs} 190 times.  This is computationally intensive for very
large panels.  Consider using a coarser grid for initial exploration.


{marker warnings}{...}
{title:Warnings and cautions}

{phang}
{err:{bf:WARNING: Computation time.}}  Each quantile x variable
combination requires a full {cmd:xtpqcs} estimation.  A fine grid
such as {cmd:0.05(0.05)0.95} on a panel with N=1000, T=50 and 3
regressors will run {cmd:xtpqcs} 19 x 3 = 57 times.  This may take
several minutes.  Start with the default 5-point grid to verify the
data work, then refine.

{phang}
{err:{bf:WARNING: Extreme quantiles.}}  Estimating at tau = 0.01 or
tau = 0.99 with small T can produce unreliable coefficients.  Stay
within [0.05, 0.95] unless T >= 100.

{phang}
{err:{bf:CAUTION: Variable labels.}}  Plot titles use {bf:variable
labels} if they exist, and fall back to variable names.  Ensure that
labels are informative (e.g., {cmd:label variable X "Expenditure"}).

{phang}
{err:{bf:CAUTION: title() with nocombine.}}  When {cmd:nocombine} is
specified, the {cmd:title()} and {cmd:subtitle()} options are ignored
because no combined graph is produced.

{phang}
{err:{bf:CAUTION: graph export.}}  After running {cmd:xtpqcsplot},
use {cmd:graph export "filename.png", replace width(1600)} to save
the plot.  The combined graph is named {cmd:xtpqcs_process}.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Default quantile process}{p_end}

{phang}{cmd:. xtpqcsplot y X, id(id) time(t)}{p_end}

{pmore}
Estimates beta(tau) at tau = 0.10, 0.25, 0.50, 0.75, 0.90-
and produces a single plot with both CI bands.

{pstd}
{bf:Example 2: Fine quantile grid (19 points)}{p_end}

{phang}{cmd:. xtpqcsplot y X, id(id) time(t) quantiles(0.05(0.05)0.95)}{p_end}

{pstd}
{bf:Example 3: Multiple regressors, combined panel}{p_end}

{phang}{cmd:. xtpqcsplot y X1 X2 X3, id(id) time(t) quantiles(0.10(0.10)0.90)}{p_end}

{pmore}
Produces three sub-graphs (one per regressor) combined into a single
panel.

{pstd}
{bf:Example 4: Plot only a subset of regressors}{p_end}

{phang}{cmd:. xtpqcsplot y X1 X2 X3, id(id) time(t) variables(X1 X2)}{p_end}

{pstd}
{bf:Example 5: Robust-only CI (no classical band)}{p_end}

{phang}{cmd:. xtpqcsplot y X, id(id) time(t) noclassical}{p_end}

{pstd}
{bf:Example 6: Custom title and export}{p_end}

{phang}{cmd:. xtpqcsplot y X, id(id) time(t)}{p_end}
{phang}{cmd:.     title("Effect of X on Y across Quantiles")}{p_end}
{phang}{cmd:.     subtitle("Robust CI (red) vs Classical CI (blue)")}{p_end}
{phang}{cmd:. graph export "quantile_process.png", replace width(1600)}{p_end}

{pstd}
{bf:Example 7: Kernel comparison}{p_end}

{phang}{cmd:. xtpqcsplot y X, id(id) time(t) kernel(gaussian) nocombine}{p_end}
{phang}{cmd:. graph rename Graph gauss_plot}{p_end}
{phang}{cmd:. xtpqcsplot y X, id(id) time(t) kernel(epanechnikov) nocombine}{p_end}
{phang}{cmd:. graph rename Graph epan_plot}{p_end}
{phang}{cmd:. graph combine gauss_plot epan_plot, title("Kernel Comparison")}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtpqcsplot} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(quantiles)}}the quantile grid used{p_end}
{synopt:{cmd:r(variables)}}the variables plotted{p_end}

{pstd}
In addition, the {cmd:e()} results from the {it:last} {cmd:xtpqcs}
call made internally remain available (the last quantile in the grid).


{marker references}{...}
{title:References}

{phang}
Chiang, H. D., A. F. Galvao, and C.-M. Wei. 2026.
{browse "https://arxiv.org/abs/2602.19201":Panel Quantile Regression with Common Shocks}.
{it:arXiv:2602.19201}.

{phang}
Kato, K., A. F. Galvao, and G. V. Montes-Rojas. 2012. Asymptotics for panel
quantile regression models with individual effects.
{it:Journal of Econometrics} 170: 76{c -}91.


{marker also_see}{...}
{title:Also see}

{psee}
{space 2}Help:  {helpb xtpqcs}, {helpb xtpqcsmc}


{marker author}{...}
{title:Author}

{pstd}
{bf:Dr. Merwan Roudane}{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
Stata implementation of Chiang, Galvao and Wei (2026).
