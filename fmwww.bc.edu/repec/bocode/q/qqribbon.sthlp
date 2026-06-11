{smcl}
{* *! version 1.0.0  29may2026}{...}
{vieweralsosee "qqr" "help qqr"}{...}
{vieweralsosee "qqtest" "help qqtest"}{...}
{vieweralsosee "qqdiff" "help qqdiff"}{...}
{vieweralsosee "qqheat" "help qqheat"}{...}
{vieweralsosee "qqr package overview" "help qqr_package"}{...}
{viewerjumpto "Syntax" "qqribbon##syntax"}{...}
{viewerjumpto "Description" "qqribbon##desc"}{...}
{viewerjumpto "Options" "qqribbon##opts"}{...}
{viewerjumpto "Reading the plot" "qqribbon##read"}{...}
{viewerjumpto "Examples" "qqribbon##exa"}{...}
{viewerjumpto "References" "qqribbon##refs"}{...}
{title:Title}

{p 4 19 2}
{hi:qqribbon} {hline 2} Per-quantile confidence-band slice of the QQR surface


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qqribbon} {cmd:using} {it:drawsfile} {cmd:,} {cmdab:theta(}{it:#}{cmd:)} {bind:|} {cmdab:tau(}{it:#}{cmd:)} [{it:options}]

{p 4 4 2}
where {it:drawsfile} is the long-format draws dataset from
{help qqr:qqr ..., bsave(}{it:drawsfile}{help qqr:)} (variables
{bf:rep tau theta beta}).  Exactly one of {opt theta()} / {opt tau()} must be
given.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Slice (choose one)}
{synopt:{opt theta(#)}}fix θ at the nearest grid value; plot β against τ{p_end}
{synopt:{opt tau(#)}}fix τ at the nearest grid value; plot β against θ{p_end}

{syntab:Bands}
{synopt:{opt lev:el(#)}}confidence level for the band (default {bf:c(level)}, usually 95){p_end}
{synopt:{opt joint}}add the wider joint (sup-t) simultaneous band{p_end}

{syntab:Titles & output}
{synopt:{opt t:itle(string)}}graph title{p_end}
{synopt:{opt subtitle(string)}}graph subtitle{p_end}
{synopt:{opt xt:itle(string)}}x-axis title{p_end}
{synopt:{opt yt:itle(string)}}y-axis title{p_end}
{synopt:{opt save(filename)}}export the graph{p_end}
{synopt:{opt name(name)}}Stata graph name{p_end}
{synopt:{opt sch:eme(name)}}graphics scheme{p_end}
{synopt:{opt replace}}overwrite the exported file{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{p 4 4 2}
{cmd:qqribbon} takes a one-dimensional {it:slice} through the
quantile-on-quantile surface and draws it as a line with a shaded confidence
band — the familiar "coefficient with CI ribbon" plot, but for a chosen
quantile path.  It answers questions the full surface makes hard to read at a
glance, such as "{it:holding the predictor at its median (θ = 0.5), how does
the effect change across the response quantiles τ?}"{p_end}

{p 4 4 2}
Fixing {opt theta()} holds the predictor quantile and varies the response
quantile τ along the x-axis; fixing {opt tau()} does the reverse.  In each
case the value you pass is snapped to the nearest point on the estimation
grid.  The point estimate is the line; the shaded region is the bootstrap
confidence band.{p_end}

{p 4 4 2}
Like {help qqtest:qqtest} and {help qqdiff:qqdiff}, {cmd:qqribbon} reads the
joint-bootstrap draws file and never re-estimates the model.{p_end}


{marker opts}{...}
{title:Options}

{phang}
{opt theta(#)} / {opt tau(#)} choose the slice.  Specify {bf:exactly one}.
{opt theta(0.5)} fixes the predictor at its median quantile and plots the
effect across response quantiles; {opt tau(0.5)} fixes the response at its
median and plots the effect across predictor quantiles.

{phang}
{opt level(#)} sets the confidence level of the {it:pointwise} percentile
band (default {bf:c(level)}, normally 95).

{phang}
{opt joint} adds a second, wider band: the {it:joint} (sup-t) simultaneous
confidence band over the whole slice.  The pointwise band is valid at each τ
(or θ) separately; the joint band is valid for {it:all} points on the slice
at once and is the honest band to use when making a statement about the slice
as a whole.

{phang}
{opt title()}, {opt subtitle()}, {opt xtitle()}, {opt ytitle()} customise the
captions; {opt save()}, {opt name()}, {opt scheme()}, {opt replace()} control
output as usual.


{marker read}{...}
{title:Reading the plot}

{p 4 4 2}
{space 2}o  The {bf:solid line} is the QQR point estimate along the slice.{p_end}
{p 4 4 2}
{space 2}o  The {bf:dark band} is the pointwise {it:level}% bootstrap CI; the
{bf:light band} (with {opt joint}) is the wider simultaneous sup-t band.{p_end}
{p 4 4 2}
{space 2}o  A dashed {bf:line at zero} is drawn for reference: where the band
excludes 0, the effect is significant at that quantile.{p_end}
{p 4 4 2}
{space 2}o  A {bf:rising or falling line} shows that the effect depends on the
quantile — the same message {help qqtest:qqtest, test(constancy)} formalises.{p_end}


{marker exa}{...}
{title:Examples}

{p 4 4 2}{bf:Effect across response quantiles, predictor held at the median}{p_end}
{phang2}{cmd:. qqr y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) nboot(500) bsave(draws.dta) replace}{p_end}
{phang2}{cmd:. qqribbon using draws.dta, theta(0.5) joint ///}{p_end}
{phang2}{cmd:.     title("Effect across {&tau} at {&theta}=0.5") save(rib_theta.png) replace}{p_end}

{p 4 4 2}{bf:Effect across predictor quantiles, response held at the median}{p_end}
{phang2}{cmd:. qqribbon using draws.dta, tau(0.5) joint ///}{p_end}
{phang2}{cmd:.     title("Effect across {&theta} at {&tau}=0.5") save(rib_tau.png) replace}{p_end}


{marker refs}{...}
{title:References}

{phang}Sim, N. and Zhou, H. (2015). Oil prices, US stock return, and the
dependence between their quantiles. {it:Journal of Banking & Finance} 55:1-12.{p_end}

{phang}Montiel Olea, J.L. and Plagborg-Møller, M. (2019). Simultaneous
confidence bands: theory, implementation, and an application to SVARs.
{it:Journal of Applied Econometrics} 34(1):1-17.{p_end}


{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:See also}

{p 4 8 2}{help qqr},  {help qqtest},  {help qqdiff},  {help qqheat},
{help qqsurf3d},  {help qqr_package}{p_end}
