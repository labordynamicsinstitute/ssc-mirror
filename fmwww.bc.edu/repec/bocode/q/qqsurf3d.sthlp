{smcl}
{* *! version 1.0.0  29may2026}{...}
{vieweralsosee "qqr" "help qqr"}{...}
{vieweralsosee "qqheat" "help qqheat"}{...}
{vieweralsosee "qqsurf" "help qqsurf"}{...}
{vieweralsosee "qqkrls" "help qqkrls"}{...}
{vieweralsosee "qqr package overview" "help qqr_package"}{...}
{viewerjumpto "Syntax" "qqsurf3d##syntax"}{...}
{viewerjumpto "Description" "qqsurf3d##desc"}{...}
{viewerjumpto "Options" "qqsurf3d##opts"}{...}
{viewerjumpto "Reading the picture" "qqsurf3d##read"}{...}
{viewerjumpto "Tuning the look" "qqsurf3d##tune"}{...}
{viewerjumpto "Examples" "qqsurf3d##exa"}{...}
{viewerjumpto "References" "qqsurf3d##refs"}{...}
{title:Title}

{p 4 19 2}
{hi:qqsurf3d} {hline 2} MATLAB-style filled 3D surface of a QQ result {it:β(τ,θ)}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qqsurf3d} {cmd:using} {it:filename} [{cmd:,} {it:options}]

{p 4 4 2}
where {it:filename} is a long-format results dataset written by
{help qqr:qqr}, {help mqqr:mqqr} or {help qqkrls:qqkrls} (variables
{bf:tau theta} and a value column such as {bf:coef} or {bf:t}).

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt v:alue(varname)}}surface to plot: {bf:coef} (default), {bf:t}, {bf:se}, ...{p_end}
{synopt:{opt var:iable(name)}}for {help mqqr} files: which regressor's surface{p_end}
{synopt:{opt band(name)}}select one band level when several are stacked{p_end}

{syntab:Colour / resolution}
{synopt:{opt colormap(name)}}palette: {bf:jet} (default){bf:, parula, viridis, plasma, hot, cool, redblue, redgreen, redwhitegreen}{p_end}
{synopt:{opt levels(#)}}number of colour bands (default {bf:18}){p_end}
{synopt:{opt fine(#)}}interpolation grid density (default {bf:64}; higher = smoother){p_end}
{synopt:{opt ms:ize(size)}}tile marker size (default {bf:medlarge}){p_end}
{synopt:{opt cbs:ize(size)}}colour-bar swatch size (default {bf:vlarge}){p_end}

{syntab:Viewpoint}
{synopt:{opt azim:uth(#)}}horizontal rotation in degrees (default {bf:35}){p_end}
{synopt:{opt ele:vation(#)}}vertical tilt in degrees (default {bf:25}){p_end}
{synopt:{opt zsc:ale(#)}}height exaggeration of the z-axis (default {bf:0.6}){p_end}

{syntab:Labels & elements}
{synopt:{opt t:itle(string)}}graph title{p_end}
{synopt:{opt xt:itle(string)}}θ-axis title (default {bf:{&theta}}){p_end}
{synopt:{opt yt:itle(string)}}τ-axis title (default {bf:{&tau}}){p_end}
{synopt:{opt zt:itle(string)}}z / colour-bar caption (default {bf:{&beta}}){p_end}
{synopt:{opt nowire}}omit the wireframe mesh{p_end}
{synopt:{opt nocbar}}omit the side colour bar{p_end}

{syntab:Output}
{synopt:{opt save(filename)}}export the graph (e.g. {bf:fig.png}){p_end}
{synopt:{opt name(name)}}Stata graph name{p_end}
{synopt:{opt sch:eme(name)}}graphics scheme{p_end}
{synopt:{opt replace}}overwrite the exported file / graph{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{p 4 4 2}
{cmd:qqsurf3d} renders a quantile-on-quantile result as a filled,
MATLAB-{cmd:surf}-style three-dimensional surface — the look used for the
robustness figures in Sim & Zhou (2015) and Adebayo, Ozkan & Eweade (2024).
The height and colour of the surface both encode {it:β(τ,θ)}: the estimated
effect of the predictor (at its θ-quantile) on the τ-quantile of the
response.{p_end}

{p 4 4 2}
The command reads the long-format file produced by an estimation command,
builds a regular {it:θ × τ} grid, bilinearly interpolates it to a finer
{opt fine()}×{opt fine()} mesh, projects every tile with an oblique
(azimuth/elevation) projection, paints the tiles in painter's order
(far-to-near) using one colour bucket per {opt levels()} band, and overlays a
wireframe, a 3D bounding box with numbered τ/θ/β tick marks, and a vertical
colour bar.  Everything is computed in a single Mata pass, so no extra
packages are required.{p_end}

{p 4 4 2}
{cmd:qqsurf3d} is the 3D companion to the 2D {help qqheat:qqheat} contour
heatmap and the lightweight {help qqsurf:qqsurf} pseudo-3D scatter.  Use
{cmd:qqheat} for precise reading and significance stars; use {cmd:qqsurf3d}
when you want the publication-style surface.{p_end}

{p 4 4 2}
{bf:Dependencies: none beyond base Stata.}  The surface, wireframe, bounding
box, axis ticks and colour bar are all built from base {help twoway:twoway}
({cmd:scatter}/{cmd:pci}) in a single in-line Mata pass; colormaps are
generated internally.  No {cmd:heatplot}, {cmd:colorpalette}, {cmd:palettes},
{cmd:colrspace} or other add-on is required.{p_end}


{marker opts}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt value(varname)} chooses which column of the results file to render.
{bf:coef} (the slope {it:β}) is the default; {bf:t}, {bf:se} or {bf:p} are
also useful surfaces.

{phang}
{opt variable(name)} is for multivariate results from {help mqqr:mqqr}, which
stack one surface per regressor; name the regressor whose surface you want.

{phang}
{opt band(name)} selects a single level when the file contains several
stacked bands.

{dlgtab:Colour / resolution}

{phang}
{opt colormap(name)} sets the palette.  Sequential maps ({bf:jet, parula,
viridis, plasma, hot, cool}) suit one-signed surfaces; diverging maps
({bf:redblue, redgreen, redwhitegreen}) put a neutral colour at the middle of
the range and are best when {it:β} changes sign.

{phang}
{opt levels(#)} is the number of discrete colour bands (default 18).
{opt fine(#)} controls how finely the surface is interpolated before
painting (default 64).  Raising {opt fine()} closes the small white seams
between tiles and yields a smoother surface at the cost of a larger graph.

{phang}
{opt msize(size)} and {opt cbsize(size)} size the surface tiles and the
colour-bar swatches.  If you still see speckle gaps, raise {opt fine()}
first, then {opt msize()} (e.g. {bf:large}).

{dlgtab:Viewpoint}

{phang}
{opt azimuth(#)} rotates the surface horizontally and {opt elevation(#)}
tilts it vertically (both in degrees).  {opt zscale(#)} exaggerates or
compresses the vertical (β) axis; lower it for a flatter, map-like view and
raise it to emphasise peaks.

{dlgtab:Labels & elements}

{phang}
{opt title()}, {opt xtitle()}, {opt ytitle()}, {opt ztitle()} set the graph
title and the three axis captions (θ, τ, and the z/colour-bar quantity).

{phang}
{opt nowire} removes the mesh lines and {opt nocbar} removes the colour bar
for a cleaner, minimal surface.


{marker read}{...}
{title:Reading the picture}

{p 4 4 2}
{space 2}o  The {bf:floor axes} are the two quantile grids: θ (predictor
quantile) and τ (response quantile), each running 0→1.{p_end}
{p 4 4 2}
{space 2}o  {bf:Height and colour} both show {it:β(τ,θ)}.  A rising surface
means the effect grows; a saddle or twist means the effect depends jointly on
where {it:both} variables sit in their distributions.{p_end}
{p 4 4 2}
{space 2}o  The {bf:colour bar} on the right is the value key; its labels
span the true data range of {it:β} (the surface is {it:not} symmetrised, so
heights are faithful).{p_end}
{p 4 4 2}
{space 2}o  For formal statements about the surface (is it flat? symmetric?
zero?), pair the picture with {help qqtest:qqtest}.{p_end}


{marker tune}{...}
{title:Tuning the look}

{p 4 4 2}
To approach the smooth MATLAB {cmd:surf} appearance:{p_end}

{phang2}{cmd:. qqsurf3d using qq.dta, value(coef) colormap(jet) fine(80) msize(large) levels(20)}{p_end}

{p 4 4 2}
For a clean, minimal surface (no mesh, no bar) suited to slides:{p_end}

{phang2}{cmd:. qqsurf3d using qq.dta, value(coef) nowire nocbar azim(40) ele(20)}{p_end}


{marker exa}{...}
{title:Examples}

{p 4 4 2}{bf:Bivariate QQR surface}{p_end}
{phang2}{cmd:. qqr y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) saving(qq.dta) replace}{p_end}
{phang2}{cmd:. qqsurf3d using qq.dta, value(coef) colormap(jet) azim(35) ele(25) ///}{p_end}
{phang2}{cmd:.     title("QQR 3D surface: {&beta}({&tau},{&theta})") save(qqr_surf3d.png) replace}{p_end}

{p 4 4 2}{bf:QQ-KRLS marginal-effect surface}{p_end}
{phang2}{cmd:. qqkrls y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) saving(qk.dta) replace}{p_end}
{phang2}{cmd:. qqsurf3d using qk.dta, value(coef) colormap(viridis) fine(80) ///}{p_end}
{phang2}{cmd:.     title("QQ-KRLS 3D surface") save(qk_surf3d.png) replace}{p_end}


{marker refs}{...}
{title:References}

{phang}Sim, N. and Zhou, H. (2015). Oil prices, US stock return, and the
dependence between their quantiles. {it:Journal of Banking & Finance} 55:1-12.{p_end}

{phang}Adebayo, T.S., Ozkan, O. and Eweade, B.S. (2024). Do energy efficiency
R&D investments and ICT promote environmental sustainability in Sweden? A
QQKRLS investigation. {it:Journal of Cleaner Production} 440:140832.{p_end}


{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:See also}

{p 4 8 2}{help qqr},  {help qqheat},  {help qqsurf},  {help qqkrls},
{help qqtable},  {help qqr_package}{p_end}
