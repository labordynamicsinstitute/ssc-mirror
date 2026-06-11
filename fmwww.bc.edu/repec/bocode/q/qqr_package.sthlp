{smcl}
{* *! version 1.1.0  29may2026}{...}
{vieweralsosee "qqr" "help qqr"}{...}
{vieweralsosee "mqqr" "help mqqr"}{...}
{vieweralsosee "qqgcause" "help qqgcause"}{...}
{vieweralsosee "qqkrls" "help qqkrls"}{...}
{vieweralsosee "qqheat" "help qqheat"}{...}
{vieweralsosee "qqsurf" "help qqsurf"}{...}
{vieweralsosee "qqsurf3d" "help qqsurf3d"}{...}
{vieweralsosee "qqcauseplot" "help qqcauseplot"}{...}
{vieweralsosee "qqtable" "help qqtable"}{...}
{vieweralsosee "qqtest" "help qqtest"}{...}
{vieweralsosee "qqribbon" "help qqribbon"}{...}
{vieweralsosee "qqdiff" "help qqdiff"}{...}
{viewerjumpto "Estimation commands" "qqr_package##est"}{...}
{viewerjumpto "Visualisation commands" "qqr_package##viz"}{...}
{viewerjumpto "Inference & diagnostics" "qqr_package##infer"}{...}
{viewerjumpto "Typical workflow" "qqr_package##flow"}{...}
{viewerjumpto "Installation" "qqr_package##inst"}{...}
{viewerjumpto "References" "qqr_package##refs"}{...}
{title:qqr package}  {hline 2}  Quantile-on-Quantile methods for Stata

{p2colset 4 22 24 2}{...}
{p2col:Author:}Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}){p_end}
{p2col:Version:}1.1.0{p_end}
{p2col:Depends:}{help krls} (SSC, for {help qqkrls}),  {help moremata} (SSC, optional){p_end}
{p2colreset}{...}

{title:Description}

{p 4 4 2}
The {bf:qqr} package implements four families of quantile-on-quantile (QQ)
estimators, a suite of MATLAB-style visualisations, publication-ready tables,
and a formal joint-bootstrap inference toolkit for the estimated surface
{it:β(τ,θ)}.  Click any command below to open its detailed help.{p_end}


{marker est}{...}
{title:Estimation commands}

{p 4 8 2}{help qqr}{...}
{col 28}{cmd:qqr} {it:y} {it:x} — bivariate QQ regression (Sim & Zhou 2015){p_end}
{p 4 8 2}{help mqqr}{...}
{col 28}{cmd:mqqr} {it:y} {it:x1 x2} ... — multivariate QQ regression{p_end}
{p 4 8 2}{help qqgcause}{...}
{col 28}{cmd:qqgcause} {it:y} {it:x} — nonparametric quantile causality (Balcilar et al.){p_end}
{p 4 8 2}{help qqkrls}{...}
{col 28}{cmd:qqkrls} {it:y} {it:x} — QQ kernel regularised least squares (Adebayo et al.){p_end}


{marker viz}{...}
{title:Visualisation commands}

{p 4 8 2}{help qqheat}{...}
{col 28}{cmd:qqheat}  using ... — MATLAB-style contour heatmap (jet / parula / viridis ...){p_end}
{p 4 8 2}{help qqsurf}{...}
{col 28}{cmd:qqsurf}  using ... — lightweight pseudo-3D scatter surface{p_end}
{p 4 8 2}{help qqsurf3d}{...}
{col 28}{cmd:qqsurf3d} using ... — filled MATLAB-{cmd:surf}-style 3D surface{p_end}
{p 4 8 2}{help qqcauseplot}{...}
{col 28}{cmd:qqcauseplot} using ... — quantile-causality test plot{p_end}
{p 4 8 2}{help qqtable}{...}
{col 28}{cmd:qqtable}  using ... — formatted console / LaTeX table{p_end}


{marker infer}{...}
{title:Inference & diagnostics}

{p 4 4 2}
These read the joint-bootstrap {it:draws} file written by
{help qqr:qqr ..., bsave(}{it:draws.dta}{help qqr:)} and turn the QQR picture
into formal statements.{p_end}

{p 4 8 2}{help qqtest}{...}
{col 28}{cmd:qqtest}   using ... — KS / Cramér–von Mises / Wald tests (zero, symmetry, constancy){p_end}
{p 4 8 2}{help qqribbon}{...}
{col 28}{cmd:qqribbon} using ... — per-quantile CI-band slice of the surface{p_end}
{p 4 8 2}{help qqdiff}{...}
{col 28}{cmd:qqdiff}   using ... — asymmetry / difference-of-surfaces starred heatmap{p_end}


{marker flow}{...}
{title:Typical workflow}

{p 4 4 2}{bf:1. Estimate and visualise}{p_end}
{phang2}{cmd:. qqr y x, saving(qq.dta) replace}{p_end}
{phang2}{cmd:. qqheat   using qq.dta, value(coef) colormap(jet) sigmark}{p_end}
{phang2}{cmd:. qqsurf3d using qq.dta, value(coef) colormap(jet)}{p_end}
{phang2}{cmd:. qqtable  using qq.dta, value(coef) stars latex(out.tex)}{p_end}

{p 4 4 2}{bf:2. Joint-bootstrap inference}{p_end}
{phang2}{cmd:. qqr y x, nboot(500) bci bsave(draws.dta) saving(qq.dta) replace}{p_end}
{phang2}{cmd:. qqtest   using draws.dta, test(zero)}{p_end}
{phang2}{cmd:. qqtest   using draws.dta, test(symmetry)}{p_end}
{phang2}{cmd:. qqribbon using draws.dta, theta(0.5) joint}{p_end}
{phang2}{cmd:. qqdiff   using draws.dta}{p_end}

{p 4 4 2}
A complete, runnable demonstration is provided in {bf:qqr_demo.do}.{p_end}


{marker inst}{...}
{title:Installation}

{p 4 4 2}From the SSC archive:{p_end}
{phang2}{cmd:. ssc install qqr}{p_end}
{phang2}{cmd:. ssc install krls}  {space 2}// only needed for {help qqkrls}{p_end}

{p 4 4 2}{bf:Dependencies.}  The estimation, table, heatmap ({help qqheat}) and
3D-surface ({help qqsurf}, {help qqsurf3d}) commands need {bf:nothing beyond
base Stata 14+} — all graphics use built-in {help twoway:twoway}
({cmd:contour}/{cmd:scatter}/{cmd:pci}) and all MATLAB-style colormaps are
generated internally (no {cmd:heatplot}, {cmd:colorpalette}, {cmd:palettes},
{cmd:colrspace} or {cmd:grstyle} required).  The {it:only} external dependency
is {help krls:krls} (SSC), used solely by {help qqkrls}.  {help moremata}
(SSC) is optional.{p_end}


{marker refs}{...}
{title:References}

{phang}Sim, N. and Zhou, H. (2015). Oil prices, US stock return, and the
dependence between their quantiles. {it:Journal of Banking & Finance} 55:1-12.{p_end}

{phang}Balcilar, M., Gupta, R. and Pierdzioch, C. (2016). Does uncertainty move
the gold price? {it:Resources Policy} 49:74-80.{p_end}

{phang}Jeong, K., Härdle, W.K. and Song, S. (2012). A consistent nonparametric
test for causality in quantile. {it:Econometric Theory} 28(4):861-887.{p_end}

{phang}Adebayo, T.S., Ozkan, O. and Eweade, B.S. (2024). Do energy efficiency
R&D investments and ICT promote environmental sustainability in Sweden? A
QQKRLS investigation. {it:Journal of Cleaner Production} 440:140832.{p_end}

{phang}Hainmueller, J. and Hazlett, C. (2014). Kernel regularized least squares.
{it:Political Analysis} 22:143-168.{p_end}


{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
