{smcl}
{* *! version 1.0.0 15sep2026}{...}
{title:Title}

{phang}
{bf:itdidbounds} {hline 2} Timing-uncertainty envelopes for interval-timed difference-in-differences contrasts

{title:Syntax}

{p 8 17 2}
{cmd:itdidbounds} {it:yvar} {ifin},
{cmd:id(}{it:idvar}{cmd:)}
{cmd:time(}{it:timevar}{cmd:)}
{cmd:treated(}{it:treatedvar}{cmd:)}
{cmd:lower(}{it:lowerdatevar}{cmd:)}
{cmd:upper(}{it:upperdatevar}{cmd:)}
{cmd:never(}{it:nevervar}{cmd:)}
{cmd:event(}{it:numlist}{cmd:)}
[{cmd:unitweight(}{it:weightvar}{cmd:)}
 {cmd:saving(}{it:filename}{cmd:)}
 {cmd:detail(}{it:filename}{cmd:)}
 {cmd:replace}]

{title:Description}

{pstd}
{cmd:itdidbounds} computes numerical envelopes for panel change contrasts when
a treated unit's adoption date is known only to lie in a closed integer interval
[{cmd:lower()}, {cmd:upper()}].

{pstd}
For treated unit i, feasible candidate date g, and requested event time e, the
candidate-specific contrast is

{p 8 12 2}
[Y(i,g+e)-Y(i,g-1)] minus the mean contemporaneous change among eligible
control units.

{pstd}
A control is eligible when it is known never treated or when its earliest
possible adoption date is later than the candidate target time g+e. The focal
treated unit is never used as its own control.

{pstd}
For each supported treated-unit/event-time cell, the command takes the minimum
and maximum contrast across that unit's feasible candidate dates. It then
averages the unit-specific minima and maxima using fixed positive analysis
weights.

{pstd}
The resulting interval is a {bf:timing-uncertainty contrast envelope}. It is not
automatically a causal treatment-effect bound or a confidence interval.
Additional assumptions are required for causal interpretation.

{title:Data requirements}

{phang}
{cmd:id()} identifies panel units. It may be numeric or string.

{phang}
{cmd:time()} must be integer-valued, and {cmd:id()} and {cmd:time()} must
uniquely identify observations.

{phang}
{cmd:treated()} must be coded 0/1 and constant within unit. A value of 1
identifies units whose adoption date lies in [{cmd:lower()}, {cmd:upper()}].

{phang}
{cmd:never()} must be coded 0/1 and constant within unit. A unit cannot be both
treated and never treated.

{phang}
For treated units, {cmd:lower()} and {cmd:upper()} must be nonmissing,
integer-valued, constant within unit, and satisfy {cmd:lower()} <=
{cmd:upper()}.

{phang}
The outcome may be missing. A candidate contrast is supported only when the
treated unit and at least one eligible control have nonmissing outcomes at both
the baseline and target times.

{title:Options}

{phang}
{cmd:event(}{it:numlist}{cmd:)} specifies one or more nonnegative integer event
times. For candidate adoption date g, the baseline is g-1 and the target is
g+e.

{phang}
{cmd:unitweight(}{it:weightvar}{cmd:)} supplies positive analysis weights that
must be constant within treated units. Without this option, treated units
receive equal weight within each supported event time.

{phang}
{cmd:saving(}{it:filename}{cmd:)} writes the aggregate envelope dataset.

{phang}
{cmd:detail(}{it:filename}{cmd:)} writes the candidate-level diagnostic
dataset.

{phang}
{cmd:replace} permits {cmd:saving()} and {cmd:detail()} to overwrite existing
files.

{title:Support rule}

{pstd}
A treated-unit/event-time cell contributes to an aggregate envelope only when
every feasible candidate adoption date for that cell has a supported contrast.
Event times with no fully supported treated-unit cells are omitted. The command
stops with an error when no requested event time has any fully supported cell.

{title:All-earliest and all-latest comparisons}

{pstd}
The command also reports weighted contrasts obtained by assigning every treated
unit its earliest feasible date and, separately, its latest feasible date.
These are comparison scenarios. They need not equal the numerical lower and
upper endpoints because mixed unit-specific date assignments may be more
extreme.

{title:Stored results}

{pstd}
{cmd:itdidbounds} stores the following in {cmd:r()}:

{synoptset 28 tabbed}{...}
{synopt:{cmd:r(envelope)}}matrix with columns {cmd:event},
{cmd:treated_units}, {cmd:lower}, {cmd:upper}, {cmd:width},
{cmd:all_earliest}, {cmd:all_latest}, {cmd:controls_min}, and
{cmd:controls_max}{p_end}
{synopt:{cmd:r(N_treated)}}number of treated units in the requested sample{p_end}
{synopt:{cmd:r(N_supported_events)}}number of event times returned{p_end}
{synopt:{cmd:r(command)}}{cmd:itdidbounds}{p_end}
{synopt:{cmd:r(interpretation)}}interpretive warning for the returned envelope{p_end}

{title:Aggregate file}

{pstd}
{cmd:saving()} contains exactly one row per returned event time and the
following variables:

{p2colset 9 34 36 2}{...}
{p2col:{cmd:event_time}}requested event time{p_end}
{p2col:{cmd:treated_units}}fully supported treated units{p_end}
{p2col:{cmd:envelope_lower}}weighted lower endpoint{p_end}
{p2col:{cmd:envelope_upper}}weighted upper endpoint{p_end}
{p2col:{cmd:envelope_width}}upper minus lower{p_end}
{p2col:{cmd:envelope_contains_zero}}indicator that zero lies in the envelope{p_end}
{p2col:{cmd:all_earliest}}weighted all-earliest comparison{p_end}
{p2col:{cmd:all_latest}}weighted all-latest comparison{p_end}
{p2col:{cmd:aggregate_controls_min}}smallest candidate-level control count{p_end}
{p2col:{cmd:aggregate_controls_max}}largest candidate-level control count{p_end}

{title:Detail file}

{pstd}
{cmd:detail()} contains one row for every treated unit, feasible candidate
date, and requested event time. It includes the unit label, interval endpoints,
baseline and target times, analysis weight, treated and control changes,
contrast, number of controls, support indicator, and earliest/latest candidate
indicators. The file retains unsupported candidate rows for diagnosis.

{title:Example}

{pstd}
The ancillary file {cmd:itdidbounds_demo.do} constructs a deterministic
synthetic panel and verifies the known envelope [2.5, 4.0]. After installing
the package from SSC, obtain the ancillary file using the {cmd:get} link shown
by {cmd:ssc describe itdidbounds}; then type

{phang2}{cmd:. do itdidbounds_demo.do}{p_end}

{pstd}
A minimal call has the form

{phang2}
{cmd:. itdidbounds y, id(state) time(year) treated(treated) lower(L) upper(U) never(never) event(0 1)}
{p_end}

{title:Remarks}

{pstd}
The command implements point contrasts and deterministic timing envelopes. It
does not estimate standard errors, confidence regions, placebo distributions,
or randomization inference.

{pstd}
No community-contributed dependencies are required. Stata 17 or later is
required.

{title:Author}

{pstd}
Christina Laternser

{pstd}
Support email: {bf:christina.laternser.research@gmail.com}

{title:Suggested citation}

{pstd}
Laternser, Christina. 2026. {it:itdidbounds: Timing-uncertainty envelopes for
interval-timed difference-in-differences contrasts}. Stata software, version
1.0.0.

{title:License}

{pstd}
Copyright (c) 2026 Christina Laternser. This software is distributed under
the MIT License.

{title:Version}

{pstd}
Version 1.0.0, 15 September 2026.
