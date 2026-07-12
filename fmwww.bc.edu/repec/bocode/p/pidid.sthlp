{smcl}
{* *! version 1.0.0  11jul2026}{...}
{viewerjumpto "Syntax" "pidid##syntax"}{...}
{viewerjumpto "Description" "pidid##description"}{...}
{viewerjumpto "Options" "pidid##options"}{...}
{viewerjumpto "Stored results" "pidid##results"}{...}
{viewerjumpto "Examples" "pidid##examples"}{...}
{viewerjumpto "References" "pidid##references"}{...}
{title:Title}

{phang}
{bf:pidid} {hline 2} Path-Integrated Difference-in-Differences (PI-DiD) estimator


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:pidid} {it:depvar} {ifin} {cmd:,}
{cmd:panelvar(}{it:varname}{cmd:)}
{cmd:timevar(}{it:varname}{cmd:)}
{cmd:treatvar(}{it:varname}{cmd:)}
{cmd:t0(}{it:#}{cmd:)}
[{cmd:t1(}{it:#}{cmd:)} {cmd:graph} {cmd:notable}
{cmd:xtitle(}{it:string}{cmd:)} {cmd:ytitle(}{it:string}{cmd:)}
{cmd:title(}{it:string}{cmd:)} {cmd:name(}{it:string}{cmd:)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt panelvar(varname)}}unit (id) identifier{p_end}
{synopt:{opt timevar(varname)}}calendar/period variable{p_end}
{synopt:{opt treatvar(varname)}}time-invariant 0/1 treatment-group indicator{p_end}
{synopt:{opt t0(#)}}baseline period (start of the post-treatment window){p_end}

{syntab:Optional}
{synopt:{opt t1(#)}}evaluation horizon (endline); default is the maximum
observed value of {it:timevar}{p_end}
{synopt:{opt graph}}draw the treated vs. counterfactual paths with the
cumulative-effect area shaded{p_end}
{synopt:{opt notable}}suppress the period-by-period c0(t)/c1(t)/tau(t) table{p_end}
{synopt:{opt xtitle}{cmd:(}{it:string}{cmd:)}}graph x-axis title{p_end}
{synopt:{opt ytitle}{cmd:(}{it:string}{cmd:)}}graph y-axis title{p_end}
{synopt:{opt title}{cmd:(}{it:string}{cmd:)}}graph title{p_end}
{synopt:{opt name}{cmd:(}{it:string}{cmd:)}}graph name, passed to {cmd:name()}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:pidid} implements the Path-Integrated Difference-in-Differences
framework: instead of comparing treated and control outcomes at a single
endline date, it treats the treatment effect as a trajectory

{center:tau(t) = c1(t) - c0(t)}

{pstd}
where c1(t) and c0(t) are the (group-mean) treated and control outcome
paths over time, and integrates this gap over the post-treatment window
[t0, t1] using the trapezoidal rule to obtain the cumulative causal
effect

{center:sigma = INTEGRAL_t0^t1 tau(t) dt}

{pstd}
and the path-integrated Average Treatment Effect on the Treated,
tau-bar = sigma / (t1 - t0).  For comparison, {cmd:pidid} also reports the
conventional static two-period DiD estimate, tau(t1) - tau(t0), which is
computed only from the endpoints and can be zero (or misleadingly small)
whenever a transitory intervention's effect has fully decayed by t1, even
though sigma remains strictly positive.  See Salavi (2026) for the
underlying theory and the endpoint-subtraction-bias result.

{pstd}
{cmd:pidid} works with panel or repeated cross-section data: it first
collapses {it:depvar} to group-by-time means (control vs. treated) via
{cmd:collapse}, so {it:panelvar} does not need to be balanced across
periods.


{marker options}{...}
{title:Options}

{phang}
{opt panelvar(varname)} identifies the individual/unit. It is used only
for sample validation; it need not be balanced.

{phang}
{opt timevar(varname)} is the calendar-time or period variable over which
the trajectory is observed.

{phang}
{opt treatvar(varname)} must be a time-invariant indicator equal to 1 for
treated units and 0 for control units.

{phang}
{opt t0(#)} is the reference/baseline period marking the start of the
integration window. Under parallel pre-trends, tau(t0) should be
approximately zero; {cmd:pidid} reports tau(t0) as a diagnostic.

{phang}
{opt t1(#)} is the terminal evaluation date (endline). If omitted, it
defaults to the last period observed in the data. Setting {cmd:t1()} to an
intermediate rejoining date t2 recovers the full, horizon-invariant
cumulative effect described in the paper.

{phang}
{opt graph} produces a twoway plot of c0(t) and c1(t) with the region
between them, over [t0, t1], shaded to represent sigma.

{phang}
{opt notable} suppresses the printed c0(t)/c1(t)/tau(t) table (results are
still returned in {cmd:r()}).


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:pidid} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(sigma)}}cumulative causal effect{p_end}
{synopt:{cmd:r(att_path)}}path-integrated ATT (sigma / (t1-t0)){p_end}
{synopt:{cmd:r(did_static)}}conventional static DiD, tau(t1) - tau(t0){p_end}
{synopt:{cmd:r(tau_t0)}}pre-treatment gap at t0 (parallel-trends check){p_end}
{synopt:{cmd:r(t0)}}baseline period used{p_end}
{synopt:{cmd:r(t1)}}endline period used{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup: a two-"individual" panel representing group means, replicating the
worked example in Salavi (2026) -- a training program whose earnings premium
fully decays by year 5.{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input id time treat earnings}{p_end}
{phang2}{cmd:  1 0 0 50000}{p_end}
{phang2}{cmd:  1 1 0 52000}{p_end}
{phang2}{cmd:  1 2 0 54000}{p_end}
{phang2}{cmd:  1 3 0 56000}{p_end}
{phang2}{cmd:  1 4 0 58000}{p_end}
{phang2}{cmd:  1 5 0 60000}{p_end}
{phang2}{cmd:  2 0 1 50000}{p_end}
{phang2}{cmd:  2 1 1 62000}{p_end}
{phang2}{cmd:  2 2 1 61000}{p_end}
{phang2}{cmd:  2 3 1 59000}{p_end}
{phang2}{cmd:  2 4 1 58500}{p_end}
{phang2}{cmd:  2 5 1 60000}{p_end}
{phang2}{cmd:  end}{p_end}

{pstd}Path-integrated estimate and graph:{p_end}

{phang2}{cmd:. pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) graph}{p_end}

{pstd}
This returns sigma = 20,500, tau-bar = 4,100/year, and a static DiD of 0 --
showing exactly how a static endline comparison hides a real, sizeable
cumulative benefit.


{marker references}{...}
{title:References}

{phang}
Salavi, C. A-F. 2026. "Path-Integrated Difference in Difference (PI-DiD)
Framework." Working paper, African School of Economics.

{title:Author}

{pstd}Command implementation based on the PI-DiD framework proposed in the
paper above.{p_end}
