{smcl}
{* *! regproject v1.0.0  April 2026}{...}
{viewerjumpto "Syntax" "regproject##syntax"}{...}
{viewerjumpto "Description" "regproject##description"}{...}
{viewerjumpto "Options" "regproject##options"}{...}
{viewerjumpto "Graphs" "regproject##graphs"}{...}
{viewerjumpto "Examples" "regproject##examples"}{...}
{viewerjumpto "Author" "regproject##author"}{...}

{title:Title}

{phang}
{bf:regproject} {hline 2} Post-estimation projection and boundary analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:regproject} {varname}
[{cmd:,}
{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Focal IV bounds (scalar — applies to focal variable only)}
{synopt:{opt ivmin(#)}}lower bound for focal IV{p_end}
{synopt:{opt ivmax(#)}}upper bound for focal IV{p_end}

{syntab:All IV bounds (positional — applies to all IVs in regression order)}
{synopt:{opt ivmins(numlist)}}lower bounds for all IVs (same order as regression output){p_end}
{synopt:{opt ivmaxs(numlist)}}upper bounds for all IVs (same order as regression output){p_end}

{syntab:DV limits}
{synopt:{opt ymin(#)}}lower limit of dependent variable{p_end}
{synopt:{opt ymax(#)}}upper limit of dependent variable{p_end}

{syntab:Output}
{synopt:{opt saving(stub)}}save graphs as {it:stub}_1.gph, {it:stub}_2.gph, ...{p_end}
{synopt:{opt combine}}combine all mode graphs into a single figure{p_end}
{synopt:{opt nodisplay}}suppress screen display (useful in batch scripts){p_end}
{synoptline}

{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:regproject} is a post-estimation command that projects the effect of a
chosen independent variable (IV) on the dependent variable (DV), while
holding all other regressors at their median values. It automatically detects
whether the current dataset is cross-sectional, time-series, or panel, and
produces a mode-appropriate set of graphs.

{pstd}
{cmd:regproject} must be run immediately after a supported estimation command.
Supported commands include: {cmd:regress}, {cmd:xtreg}, {cmd:qreg},
{cmd:xtregar}, {cmd:newey}, {cmd:arima}, {cmd:ardl}, {cmd:ivregress}.

{pstd}
{bf:Note on ivmin/ivmax vs ivmins/ivmaxs:} These option pairs are mutually
exclusive. Use {opt ivmin}/{opt ivmax} to set bounds only for the focal IV.
Use {opt ivmins}/{opt ivmaxs} to set bounds for all IVs simultaneously, in
the same order as regressors appear in regression output (excluding _cons).


{marker options}{...}
{title:Options}

{dlgtab:Focal IV bounds}

{phang}
{opt ivmin(#)} specifies the lower bound for the focal IV only. If omitted,
the minimum observed value in the data is used.

{phang}
{opt ivmax(#)} specifies the upper bound for the focal IV only. If omitted,
the maximum observed value in the data is used.

{dlgtab:All IV bounds}

{phang}
{opt ivmins(numlist)} specifies lower bounds for all IVs in the model, in
regression order (excluding _cons). The list must contain exactly as many
values as there are regressors. The value at the position of the focal IV
is used as its lower bound.

{phang}
{opt ivmaxs(numlist)} specifies upper bounds for all IVs in the model.
Same positional rules as {opt ivmins()}.

{dlgtab:DV limits}

{phang}
{opt ymin(#)} sets the lower limit of the DV. Used to shade the region below
this value on graphs, and to detect when the projected DV crosses this
threshold in time-series forward projections.

{phang}
{opt ymax(#)} sets the upper limit of the DV. Used for upper shading and
crossing detection.

{dlgtab:Output}

{phang}
{opt saving(stub)} saves all generated graphs. Graph files are named
{it:stub}_1.gph through {it:stub}_{it:n}.gph, where {it:n} is the number of
graphs for the detected data mode.

{phang}
{opt combine} combines all graphs for the detected mode into a single figure
using {cmd:graph combine}.

{phang}
{opt nodisplay} suppresses screen output of graphs. Useful in batch runs.


{marker graphs}{...}
{title:Graphs by data mode}

{dlgtab:Cross-sectional (4 graphs)}

{phang2}
{bf:Graph 1 — Entity bar chart.} Bar height equals predicted ŷ for each
entity using its own covariate values. Entities sorted ascending by focal IV.
Four horizontal reference lines show ŷ at max/min observed IV and
user-supplied IV bounds (median base for non-focal covariates).
DV limit shading applied if ymin/ymax supplied.

{phang2}
{bf:Graph 2 — Sensitivity ranking.} Horizontal bars for all IVs, ranked
by |coef × (upper − lower bound)|. Shows which variable has the most
leverage on the DV across its range. Focal IV highlighted in orange.

{phang2}
{bf:Graph 3 — Gap to boundary.} For each entity, shows headroom to the
DV upper limit (or distance below DV lower limit). Entities breaching
a limit shown in red. Requires ymin or ymax.

{phang2}
{bf:Graph 4 — Counterfactual comparison.} Grouped bars showing actual ŷ
vs counterfactual ŷ where the focal IV is replaced with its median.
The difference isolates the IV's contribution per entity.

{dlgtab:Panel data (4 graphs)}

{phang2}
{bf:Graph 1 — Latest-period dot chart.} Dot per entity at ŷ using latest
period values. Sorted ascending by focal IV. Same reference line and
shading logic as cross-sectional Graph 1.

{phang2}
{bf:Graph 2 — Spaghetti trajectories.} Entity ŷ trajectories over time,
with median trajectory overlaid in red.

{phang2}
{bf:Graph 3 — Delta IV vs Delta ŷ scatter.} Change in focal IV (first to
last period) on X; change in ŷ on Y. Theoretical slope from regression
coefficient shown as dashed reference line.

{phang2}
{bf:Graph 4 — Heat map.} Entities × time periods, with cell color
proportional to ŷ. Uses {cmd:heatplot} (SSC) if installed; falls back
to a simple scatter if not.

{dlgtab:Time series (3 graphs)}

{phang2}
{bf:Graph 1 — Static sweep.} IV swept from lower to upper bound on X;
predicted ŷ on Y. 95% CI ribbon shown. Red diamond marks the latest
observed IV value.

{phang2}
{bf:Graph 2 — IV-only forward projection.} Focal IV extrapolated 25 periods
ahead using its linear trend. All other covariates held at median.
DV limit lines drawn; first period of crossing annotated.

{phang2}
{bf:Graph 3 — Full system projection.} All covariates extrapolated 25 periods
using their individual linear trends. Inhibitor dynamics naturally reflected
in the trajectory shape.


{marker examples}{...}
{title:Examples}

{dlgtab:Cross-sectional — sysuse auto}

{pstd}
The {cmd:auto} dataset contains 74 observations on car models (1978).
No {cmd:xtset} or {cmd:tsset} is active, so {cmd:regproject} automatically
detects cross-sectional mode.{p_end}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight length}{p_end}
{phang2}{cmd:. regproject weight, ivmin(1500) ivmax(5000) ymin(3000) ymax(16000)}{p_end}

{pstd}With bounds for all IVs and combined output:{p_end}
{phang2}{cmd:. regproject weight, ivmins(10 1500 140) ivmaxs(41 5000 233) ymin(3000) ymax(16000) combine}{p_end}

{pstd}
{bf:Interpretation:} Graph 1 shows predicted price per car sorted by weight.
The four reference lines show predicted price when weight is at its
observed min/max and at user-supplied realistic bounds. Graph 2 ranks
mpg, weight, and length by their leverage on price. Graph 3 shows each
car's headroom to the price ceiling. Graph 4 shows actual vs counterfactual
predicted price if weight were replaced with its median.


{dlgtab:Time series — sysuse uslifeexp}

{pstd}
The {cmd:uslifeexp} dataset contains annual US life expectancy data 1900–1999.
After {cmd:tsset year}, {cmd:regproject} detects time-series mode and
produces three graphs including a 25-period forward projection.{p_end}

{phang2}{cmd:. sysuse uslifeexp, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. regress le_wmale le_wfemale le_bmale}{p_end}
{phang2}{cmd:. regproject le_wfemale, ymin(60) ymax(90) combine}{p_end}

{pstd}With user-supplied IV bounds:{p_end}
{phang2}{cmd:. regproject le_wfemale, ivmin(55) ivmax(95) ymin(60) ymax(90) combine}{p_end}

{pstd}
{bf:Interpretation:} Graph 1 sweeps white female life expectancy across
its range and shows where male life expectancy is projected to land, with
a CI ribbon and a dot at the latest observed value. Graph 2 projects
25 years forward using the current trend in le_wfemale only. Graph 3
projects forward using trends in all covariates simultaneously.


{dlgtab:Panel data — 10 Asian economies × 5 periods (synthetic)}

{pstd}
The panel example uses 10 named economies observed biennially 2010–2018,
with poverty rate as the outcome and GDP growth as the focal IV.
Data is generated programmatically so no external file is needed.{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 50}{p_end}
{phang2}{cmd:. generate cid  = ceil(_n / 5)}{p_end}
{phang2}{cmd:. generate year = 2010 + mod(_n-1, 5) * 2}{p_end}
{phang2}{cmd:. generate str15 cname = ""}{p_end}
{phang2}{cmd:. replace cname = "Malaysia"    if cid==1}{p_end}
{phang2}{cmd:. replace cname = "Thailand"    if cid==2}{p_end}
{phang2}{cmd:. replace cname = "Indonesia"   if cid==3}{p_end}
{phang2}{cmd:. replace cname = "Philippines" if cid==4}{p_end}
{phang2}{cmd:. replace cname = "Vietnam"     if cid==5}{p_end}
{phang2}{cmd:. replace cname = "Cambodia"    if cid==6}{p_end}
{phang2}{cmd:. replace cname = "Bangladesh"  if cid==7}{p_end}
{phang2}{cmd:. replace cname = "Pakistan"    if cid==8}{p_end}
{phang2}{cmd:. replace cname = "SriLanka"    if cid==9}{p_end}
{phang2}{cmd:. replace cname = "India"       if cid==10}{p_end}
{phang2}{cmd:. generate gdp    = 3 + 4*runiform() + 0.2*(year-2010)/2}{p_end}
{phang2}{cmd:. generate trade  = 40 + 80*runiform()}{p_end}
{phang2}{cmd:. generate govexp = 15 + 10*runiform()}{p_end}
{phang2}{cmd:. generate poverty = 35 - 1.8*gdp - 0.05*trade - 0.3*govexp + rnormal(0,1.5)}{p_end}
{phang2}{cmd:. xtset cid year}{p_end}
{phang2}{cmd:. xtreg poverty gdp trade govexp, fe}{p_end}
{phang2}{cmd:. regproject gdp, ivmins(-2 25 10) ivmaxs(10 150 35) ymin(0) ymax(40) combine}{p_end}

{pstd}
{bf:Interpretation:} Graph 1 shows each country's predicted poverty rate
at its latest-period values, sorted ascending by GDP growth, with four
horizontal benchmark lines. Graph 2 shows country-level poverty trajectories
over time with the median overlaid in red. Graph 3 scatters the change in
GDP growth against the change in predicted poverty across countries, with
the theoretical regression slope as a dashed reference. Graph 4 renders
a heat map of predicted poverty across countries and years (requires
{cmd:heatplot} from SSC; falls back to a bubble scatter otherwise).

{pstd}
For a real panel dataset (requires internet access); note: use {cmd:age} as
focal IV since {cmd:grade} is time-invariant and dropped in FE estimation:{p_end}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. xtreg ln_wage age ttl_exp tenure, fe}{p_end}
{phang2}{cmd:. regproject age, ivmin(15) ivmax(55) ymin(0) ymax(4) combine}{p_end}


{dlgtab:Generic syntax reference}

{pstd}Focal IV bounds only:{p_end}
{phang2}{cmd:. regress y x1 x2 x3}{p_end}
{phang2}{cmd:. regproject x2, ivmin(5) ivmax(25) ymin(0) ymax(100)}{p_end}

{pstd}Bounds for all IVs (positional — must match regression order):{p_end}
{phang2}{cmd:. regress y x1 x2 x3}{p_end}
{phang2}{cmd:. regproject x2, ivmins(0 5 100) ivmaxs(10 25 500) ymax(100) combine}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Noman Arshed{break}
Senior Lecturer, Department of Business Analytics{break}
Sunway Business School, Sunway University{break}
Email: {browse "mailto:nouman.arshed@gmail.com":nouman.arshed@gmail.com}{break}
GitHub: {browse "https://github.com/nomanarshed/regproject":https://github.com/nomanarshed/regproject}

{pstd}
Bug reports and feature requests welcome via GitHub Issues.


{title:Also see}

{psee}
Online: {helpb regress}, {helpb xtreg}, {helpb qreg}, {helpb margins},
{helpb marginsplot}, {helpb heatplot} (if installed)
{p_end}
