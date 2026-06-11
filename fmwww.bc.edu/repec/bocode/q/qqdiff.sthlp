{smcl}
{* *! version 1.0.0  29may2026}{...}
{vieweralsosee "qqr" "help qqr"}{...}
{vieweralsosee "qqtest" "help qqtest"}{...}
{vieweralsosee "qqribbon" "help qqribbon"}{...}
{vieweralsosee "qqheat" "help qqheat"}{...}
{vieweralsosee "qqr package overview" "help qqr_package"}{...}
{viewerjumpto "Syntax" "qqdiff##syntax"}{...}
{viewerjumpto "Description" "qqdiff##desc"}{...}
{viewerjumpto "Two modes" "qqdiff##modes"}{...}
{viewerjumpto "Options" "qqdiff##opts"}{...}
{viewerjumpto "Reading the map" "qqdiff##read"}{...}
{viewerjumpto "Examples" "qqdiff##exa"}{...}
{viewerjumpto "References" "qqdiff##refs"}{...}
{title:Title}

{p 4 19 2}
{hi:qqdiff} {hline 2} Difference-of-surfaces and asymmetry diagnostics for QQR


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qqdiff} {cmd:using} {it:drawsfile} [{cmd:,} {opt compare(file2)} {it:options}]

{p 4 4 2}
where {it:drawsfile} (and the optional {it:file2}) are long-format draws
datasets from {help qqr:qqr ..., bsave(}{it:...}{help qqr:)} (variables
{bf:rep tau theta beta}).

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Mode}
{synopt:{opt compare(file2)}}compare two surfaces; without it, run the asymmetry mode{p_end}

{syntab:Heatmap}
{synopt:{opt colormap(name)}}palette (default {bf:redwhitegreen}, diverging){p_end}
{synopt:{opt t:itle(string)}}graph title{p_end}
{synopt:{opt noheat}}skip the heatmap (only write the difference dataset){p_end}
{synopt:{opt name(name)}}Stata graph name{p_end}
{synopt:{opt save(filename)}}export the graph{p_end}
{synopt:{opt saving(filename)}}save the difference grid as a .dta{p_end}
{synopt:{opt replace}}overwrite the exported file / dataset{p_end}
{synopt:{it:twoway_options}}any extra option passed through to {help qqheat:qqheat}{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{p 4 4 2}
{cmd:qqdiff} computes and maps the {it:difference} between two
quantile-on-quantile surfaces, with a per-cell significance test, and renders
it as a starred diverging heatmap.  It is the surface-level analogue of
testing a contrast: instead of one effect, it shows where two surfaces (or
two halves of one surface) {it:differ} and where that difference is
statistically meaningful.{p_end}

{p 4 4 2}
Like {help qqtest:qqtest} and {help qqribbon:qqribbon}, it reads
joint-bootstrap draws files and does not re-estimate.  The default palette is
the diverging {bf:redwhitegreen} map so that the sign of the difference reads
at a glance: red = negative, white ≈ 0, green = positive.{p_end}


{marker modes}{...}
{title:Two modes}

{phang}
{bf:Asymmetry mode} (no {opt compare()}).  Computes
{it:diff(τ,θ) = β(τ,θ) − β(1−τ,θ)} from a single draws file: the surface
reflected about the median response quantile, subtracted from itself.  A
non-zero, significant cell is direct evidence of {it:tail asymmetry} — the
predictor's effect differs between matching lower and upper response
quantiles.  The per-cell p-value is a paired two-sided bootstrap p (the two
cells share each resample, so their dependence is honoured).

{phang}
{bf:Compare mode} ({opt compare(file2)}).  Computes
{it:diff(τ,θ) = β₁(τ,θ) − β₂(τ,θ)} between two separate draws files that
share the same (τ,θ) grid — e.g. two samples, two sub-periods, two countries,
or two predictors.  Because the two files come from independent estimations,
the per-cell p-value uses a normal-approximation z built from the two
bootstrap standard deviations.  The grids must match; if they do not,
{cmd:qqdiff} stops with an error.


{marker opts}{...}
{title:Options}

{phang}
{opt compare(file2)} switches on compare mode and names the second draws
file.

{phang}
{opt colormap(name)} sets the heatmap palette; a diverging map is strongly
recommended for a signed difference ({bf:redwhitegreen} (default){bf:,
redblue, redgreen}).  See {help qqheat} for the full palette list.

{phang}
{opt noheat} suppresses the graph and only writes the difference grid (use
with {opt saving()} to post-process the numbers yourself).

{phang}
{opt saving(filename)} stores the computed difference grid (variables
{bf:tau theta coef p}) as a dataset.  {opt save(filename)} exports the
rendered graph.  {opt title()}, {opt name()}, {opt replace} and any extra
{it:twoway_options} are forwarded to {help qqheat:qqheat}, which draws the
map with three-tier significance stars.


{marker read}{...}
{title:Reading the map}

{p 4 4 2}
{space 2}o  {bf:Colour} encodes the signed difference: green where surface 1
exceeds surface 2 (or the lower-tail exceeds the upper-tail in asymmetry
mode), red where it is smaller, white near zero.{p_end}
{p 4 4 2}
{space 2}o  {bf:Stars} (* p<0.10, ** p<0.05, *** p<0.01) mark cells where the
difference is significant.{p_end}
{p 4 4 2}
{space 2}o  In asymmetry mode the map is, by construction, anti-symmetric
about τ = 0.5; read the lower half (τ < 0.5) as "lower-tail minus
upper-tail".{p_end}
{p 4 4 2}
{space 2}o  Pair the map with {help qqtest:qqtest, test(symmetry)} for a
single global p-value on the whole asymmetry surface.{p_end}


{marker exa}{...}
{title:Examples}

{p 4 4 2}{bf:Asymmetry of one surface}{p_end}
{phang2}{cmd:. qqr y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) nboot(500) bsave(draws.dta) replace}{p_end}
{phang2}{cmd:. qqdiff using draws.dta, ///}{p_end}
{phang2}{cmd:.     title("QQR asymmetry: {&beta}({&tau},{&theta}) - {&beta}(1-{&tau},{&theta})") save(asym.png) replace}{p_end}

{p 4 4 2}{bf:Difference between two samples}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:.   qui keep if period==1}{p_end}
{phang2}{cmd:.   qqr y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) nboot(500) bsave(draws_sub.dta) replace}{p_end}
{phang2}{cmd:. restore}{p_end}
{phang2}{cmd:. qqdiff using draws.dta, compare(draws_sub.dta) ///}{p_end}
{phang2}{cmd:.     title("Full sample - sub-period") save(diff.png) replace}{p_end}


{marker refs}{...}
{title:References}

{phang}Sim, N. and Zhou, H. (2015). Oil prices, US stock return, and the
dependence between their quantiles. {it:Journal of Banking & Finance} 55:1-12.{p_end}


{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:See also}

{p 4 8 2}{help qqr},  {help qqtest},  {help qqribbon},  {help qqheat},
{help qqsurf3d},  {help qqr_package}{p_end}
