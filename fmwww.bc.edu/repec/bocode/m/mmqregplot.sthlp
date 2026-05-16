{smcl}
{* *! version 2.0 April 2026}{...}
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

{synoptline}


{title:Description}

{pstd}
{cmd:mmqregplot} (v2.0) is a comprehensive visualization suite that must be
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

    {hline}


{title:Returned results}

{pstd}{cmd:mmqregplot} returns the following in {cmd:r()}:{p_end}

{synoptset 12 tabbed}{...}
{synopt:{cmd:r(qq)}}matrix of quantile values plotted{p_end}
{synopt:{cmd:r(bs)}}matrix of coefficients (rows = quantiles, cols = variables){p_end}
{synopt:{cmd:r(ll)}}matrix of lower confidence bounds{p_end}
{synopt:{cmd:r(ul)}}matrix of upper confidence bounds{p_end}


{title:Authors}

{pstd}
{bf:Dr Merwan Roudane}{break}
merwanroudane920@gmail.com{p_end}

{pstd}
{bf:Fernando Rios-Avila} (original {cmd:mmqreg}){break}
friosa@gmail.com{p_end}


{title:Also see}

{psee}
{help mmqreg}, {help qregplot}, {help twoway}, {help graph combine}
