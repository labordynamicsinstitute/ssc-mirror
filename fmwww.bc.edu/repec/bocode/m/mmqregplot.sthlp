{smcl}
{* *! version 2.1 May 2026}{...}
{cmd:help mmqregplot}

{hline}

{title:Title}

{p2colset 8 24 25 2}{...}
{p2col :{cmd:mmqregplot} {hline 2}}Beautiful visualization suite for {help mmqreg} results{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:mmqregplot} [{varlist}] [{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr :options}
{synoptline}

{syntab:Equation selection}
{synopt :{opt eq:plot(string)}}which result to visualize:{p_end}
{synopt :}{cmd:qtile} (default) — quantile path plots across the distribution{p_end}
{synopt :}{cmd:location} — horizontal coefplot of location (mean) equation{p_end}
{synopt :}{cmd:scale} — horizontal coefplot of scale equation{p_end}
{synopt :}{cmd:all} — all three panels combined{p_end}

{syntab:Color scheme}
{synopt :{opt colors:cheme(string)}}color palette preset:{p_end}
{synopt :}{cmd:navy} (default), {cmd:viridis}, {cmd:autumn}, {cmd:warm}, {cmd:mono}, {cmd:teal}{p_end}

{syntab:Quantile range (for eqplot=qtile or all)}
{synopt :{opt q:uantile(numlist)}}quantiles to plot (0–100); default is {cmd:10(5)90}{p_end}

{syntab:OLS reference line}
{synopt :{opt ols}}add an OLS coefficient line and confidence band{p_end}
{synopt :{opt olsopt(string)}}options passed to {cmd:regress} for OLS overlay{p_end}

{syntab:Fixed effects / Country effects}
{synopt :{opt fep:lot}}add a panel showing the distribution of absorbed
fixed effects (requires {cmd:absorb()} in {cmd:mmqreg}){p_end}
{synopt :{opt fes:tyle(string)}}style for feplot:{p_end}
{synopt :}{cmd:bar} (default, ≤60 units) — sorted horizontal bars, blue=positive/red=negative{p_end}
{synopt :}{cmd:hist} — histogram with KDE overlay{p_end}
{synopt :}{cmd:dot} — Cleveland-style dot plot{p_end}

{syntab:Graph styling}
{synopt :{opt ra:opt(string)}}rarea CI band options (overrides colorscheme defaults){p_end}
{synopt :{opt ln:opt(string)}}coefficient line options (overrides colorscheme defaults){p_end}
{synopt :{opt two:opt(string)}}options applied to every {cmd:twoway} panel{p_end}
{synopt :{opt grc:opt(string)}}options for the final {cmd:graph combine}{p_end}
{synopt :{opt noz:ero}}suppress the zero reference line{p_end}

{syntab:Labels and titles}
{synopt :{opt label}}use variable labels as subplot titles{p_end}
{synopt :{opt mt:itles(string)}}space-separated quoted panel titles (override){p_end}
{synopt :{opt cons}}include the constant as an additional subplot{p_end}
{synopt :{opt level(#)}}confidence level; default is 95{p_end}

{syntab:Graph display and saving}
{synopt :{opt show:all}}draw every panel directly (no hidden {cmd:nodraw}); each panel
stays in memory; the combined figure is produced last{p_end}
{synopt :{opt keep:graphs}}keep individual panels in memory after combining
(otherwise dropped){p_end}
{synopt :{opt noc:ombine}}skip the {cmd:graph combine} step entirely — display
each panel one by one{p_end}
{synopt :{opt sav:ing(prefix)}}save every panel and the combined figure as
{cmd:.gph} files using {it:prefix}; e.g. {cmd:saving("out/wage")} writes
{cmd:out/wage_mmqp1.gph}, {cmd:out/wage_mmqloc.gph}, {cmd:out/wage.gph}, etc.{p_end}
{synopt :{opt gf:ormat(formats)}}additional image formats to export (space-separated);
e.g. {cmd:gformat(png pdf)}{p_end}

{synoptline}


{title:Description}

{pstd}
{cmd:mmqregplot} (v2.1) is a comprehensive visualization suite that must be
run immediately after {cmd:mmqreg}. It offers four plot types:

{phang}{bf:1. Quantile path plots} ({cmd:eqplot(qtile)}, default){break}
Re-estimates the model across the requested quantile range and draws the
coefficient path with a shaded CI band. Optional OLS overlay.{p_end}

{phang}{bf:2. Location equation coefplot} ({cmd:eqplot(location)}){break}
Horizontal dot-and-spike plot of the location (mean) equation coefficients
using the stored {cmd:e(bls)} and {cmd:e(vls)} — {it:no re-estimation needed}.{p_end}

{phang}{bf:3. Scale equation coefplot} ({cmd:eqplot(scale)}){break}
Same as location but for the scale (dispersion) equation.{p_end}

{phang}{bf:4. Combined} ({cmd:eqplot(all)}){break}
Location + Scale + quantile path panels assembled with {cmd:graph combine}.{p_end}

{phang}{bf:5. Fixed effects / Country effects} ({cmd:feplot}){break}
Visualize the distribution or ranking of absorbed unit-specific effects.
Supports sorted bar chart (default for ≤60 units), histogram with KDE ({cmd:festyle(hist)}),
and Cleveland dot plot ({cmd:festyle(dot)}).{p_end}

{pstd}
Color schemes are controlled by {cmd:colorscheme()}: {cmd:navy} (default),
{cmd:viridis}, {cmd:autumn}, {cmd:warm}, {cmd:mono}, {cmd:teal}.{p_end}


{title:Graph names}

{pstd}
Every panel is created as a named graph held in Stata's memory:{p_end}

{synoptset 20 tabbed}{...}
{synopt:{cmd:mmqp1}, {cmd:mmqp2}, ...}quantile-path panel for the
{it:n}th variable (one per requested variable){p_end}
{synopt:{cmd:mmqloc}}location coefplot (when {cmd:eqplot(location)} or {cmd:all}){p_end}
{synopt:{cmd:mmqsca}}scale coefplot (when {cmd:eqplot(scale)} or {cmd:all}){p_end}
{synopt:{cmd:mmqfe}}fixed-effects panel (when {cmd:feplot}){p_end}
{synopt:{cmd:mmqcombined}}final combined figure{p_end}

{pstd}
By default, individual panels are dropped after combining (only
{cmd:mmqcombined} remains visible). Pass {cmd:keepgraphs} or {cmd:showall} to
keep them all in memory so you can browse with
{stata graph display mmqp1}, {stata graph display mmqloc}, etc.{p_end}


{title:Saving figures to disk}

{pstd}
The {opt sav:ing(prefix)} option saves every panel plus the combined figure
as Stata graph files ({cmd:.gph}). Add {opt gf:ormat()} to also export images
in any format Stata supports (png, pdf, jpg, eps, tif, svg). Example:{p_end}

{phang2}{cmd:. mmqregplot, eqplot(all) saving("out/wage") gformat(png pdf)}{p_end}

{pstd}
produces {cmd:out/wage_mmqp1.gph}, {cmd:out/wage_mmqloc.gph},
{cmd:out/wage_mmqsca.gph}, {cmd:out/wage.gph} — and a {cmd:.png} and
{cmd:.pdf} copy of each.{p_end}


{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{stata webuse nlswork, clear}{p_end}
{phang2}{stata xtset idcode year}{p_end}

{pstd}{bf:1. Quantile coefficient paths (default)}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south"}{p_end}
{phang2}{stata mmqregplot}{p_end}

{pstd}{bf:2. With OLS overlay and viridis color scheme}{p_end}
{phang2}{stata "mmqregplot age ttl_exp tenure, ols colorscheme(viridis)"}{p_end}

{pstd}{bf:3. Location equation coefplot}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, q(25 50 75)"}{p_end}
{phang2}{stata "mmqregplot, eqplot(location) colorscheme(autumn)"}{p_end}

{pstd}{bf:4. Scale equation coefplot}{p_end}
{phang2}{stata "mmqregplot, eqplot(scale)"}{p_end}

{pstd}{bf:5. All equations combined (location + scale + paths)}{p_end}
{phang2}{stata "mmqregplot age ttl_exp tenure, eqplot(all) colorscheme(teal) ols"}{p_end}

{pstd}{bf:6. Country/unit fixed effects — bar chart}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure, absorb(idcode)"}{p_end}
{phang2}{stata "mmqregplot, feplot festyle(bar) colorscheme(warm)"}{p_end}

{pstd}{bf:7. FE histogram with KDE}{p_end}
{phang2}{stata "mmqregplot, feplot festyle(hist)"}{p_end}

{pstd}{bf:8. All equations + country effects in one figure}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure, absorb(idcode) q(25 50 75)"}{p_end}
{phang2}{stata "mmqregplot age ttl_exp tenure, eqplot(all) feplot colorscheme(navy) ols"}{p_end}

{pstd}{bf:9. Mono scheme for publication}{p_end}
{phang2}{stata "mmqregplot age, eqplot(all) colorscheme(mono) level(90) nozero"}{p_end}

{pstd}{bf:10. Show every panel individually, with a combined summary at the end}{p_end}
{phang2}{stata "mmqregplot age ttl_exp tenure, eqplot(all) showall"}{p_end}

{pstd}{bf:11. Save all panels + combined to PNG and PDF}{p_end}
{phang2}{stata `"mmqregplot age ttl_exp tenure, eqplot(all) ols saving("out/wage") gformat(png pdf)"'}{p_end}

{pstd}{bf:12. Keep panels in memory and browse them manually}{p_end}
{phang2}{stata "mmqregplot, eqplot(all) keepgraphs"}{p_end}
{phang2}{stata "graph display mmqloc"}{p_end}
{phang2}{stata "graph display mmqsca"}{p_end}
{phang2}{stata "graph display mmqp1"}{p_end}

    {hline}


{title:Returned results}

{pstd}{cmd:mmqregplot} returns the following in {cmd:r()}:{p_end}

{synoptset 12 tabbed}{...}
{synopt:{cmd:r(qq)}}matrix of quantile values plotted{p_end}


{title:Authors}

{pstd}
{bf:Fernando Rios-Avila} (original {cmd:mmqreg}){break}
friosa@gmail.com{p_end}

{pstd}
{bf:Dr Merwan Roudane} ({cmd:mmqregplot} companion){break}
merwanroudane920@gmail.com{p_end}


{title:Also see}

{psee}
{help mmqreg}, {help qregplot}, {help twoway}, {help graph combine}
