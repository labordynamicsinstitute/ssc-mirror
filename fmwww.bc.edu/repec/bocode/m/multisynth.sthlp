{smcl}
{* *! version 1.0.0 24apr2026}{...}
{vieweralsosee "synth (if installed)" "help synth"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{title:Title}

{p 4 8 2}
{cmd:multisynth} {hline 2} build synthetic clones for treated panel units

{title:Syntax}

{p 8 12 2}
{cmd:multisynth} {it:yvar} {ifin},
{cmd:unit(}{it:unitvar}{cmd:)}
{cmd:time(}{it:timevar}{cmd:)}
{cmd:treated(}{it:treatedvar}{cmd:)}
{cmd:post(}{it:postvar}{cmd:)}
[{cmd:controls(}{it:varlist}{cmd:)}
{cmd:ctrlweight(}{it:#}{cmd:)}
{cmd:saving(}{it:filename}{cmd:)}
{cmd:replace}
{cmd:wsaving(}{it:filename}{cmd:)}
{cmd:wreplace}
{cmd:graph}]

{title:Description}

{pstd}
{cmd:multisynth} extends the synthetic-control method of Abadie, Diamond, and
Hainmüller (2010) to panel settings with multiple treated units and staggered
treatment timing. The synthetic-control idea — finding a convex combination of
untreated units that reproduces the treated unit's pre-treatment outcome path —
is applied independently to each treated unit. Treated units are identified by
{cmd:treated()==1}; the variable {cmd:post()} defines the unit-specific split
between pre-treatment and post-treatment observations, so units need not share
a common treatment date.

{pstd}
Three aspects differ from the original {cmd:synth} command. First, treatment
timing is unit-specific: {cmd:multisynth} reads the treatment date from
{cmd:post()} for each unit separately, so staggered adoption requires no
special handling. Second, optimisation uses gradient descent with a softmax
reparameterisation of the donor weights rather than constrained quadratic
programming; this scales to many units without a QP solver, at the cost of
local rather than global convergence (rarely a practical issue with the softmax
surface). Third, the output is an augmented stacked panel appended in memory
and optionally saved with {cmd:saving()}, so the dataset is immediately usable
in {cmd:reghdfe}, {cmd:xtreg}, or any event-study estimator without further
post-processing.

{pstd}
{cmd:multisynth} is a data-preparation command. It constructs synthetic clones
and reports pre-treatment fit quality (RMSPE and R-squared per treated unit)
but does not estimate treatment effects. For treatment-effect estimation, run
a second-stage regression on the augmented panel. For single high-stakes case
studies requiring placebo inference and a globally optimal solution, the
original {cmd:synth} command remains the appropriate tool.

{pstd}
The command appends one synthetic clone to the data for each treated unit.
It generates a binary {cmd:clone} indicator, a binary {cmd:donor} indicator,
a {cmd:source_unit} variable, and a unique analysis identifier {cmd:ms_id}.

{title:Options}

{phang}
{cmd:unit(}{it:unitvar}{cmd:)} specifies the numeric panel unit identifier.

{phang}
{cmd:time(}{it:timevar}{cmd:)} specifies the panel time variable. The command
uses the within-unit ordering of this variable.

{phang}
{cmd:treated(}{it:treatedvar}{cmd:)} specifies the unit-level treatment
indicator. It must be 1 for ever-treated units and 0 for never-treated units,
and it must be constant within unit.

{phang}
{cmd:post(}{it:postvar}{cmd:)} specifies the unit-specific post-treatment
indicator. It must be 0 before treatment and 1 from first treatment onward.

{phang}
{cmd:controls(}{it:varlist}{cmd:)} supplies optional control variables.
If omitted, {cmd:multisynth} uses only the outcome path.

{phang}
{cmd:ctrlweight(}{it:#}{cmd:)} sets the weight on the control-balance penalty.
The default is {cmd:0.25}. Set {cmd:ctrlweight(0)} for a pure outcome-driven
synthetic clone when controls are supplied but should not affect matching.

{phang}
{cmd:saving(}{it:filename}{cmd:)} saves the stacked treated-versus-synthetic
panel to {it:filename}.

{phang}
{cmd:replace} allows overwriting an existing file named in {cmd:saving()}.

{phang}
{cmd:wsaving(}{it:filename}{cmd:)} saves a wide-format donor-weight dataset
with one row per treated unit. Columns are {cmd:source_unit}, then pairs
{cmd:donor_}{it:k} and {cmd:w_}{it:k} ordered by weight descending, followed
by {cmd:pre_rmspe} (root mean squared prediction error of the pre-treatment
synthetic fit) and {cmd:pre_r2} (R-squared of the pre-treatment fit).

{phang}
{cmd:wreplace} allows overwriting an existing file named in {cmd:wsaving()}.

{phang}
{cmd:graph} produces an average event-time graph comparing the mean observed
treated outcome with the mean synthetic outcome across all treated units.
Event time skips 0, so the treatment shock lies between -1 and 1 and the
graph draws a reference line at 0.

{title:Created variables}

{pstd}
After {cmd:multisynth} runs, the dataset in memory contains the original rows
plus appended clone rows. Key created variables are:

{p 8 12 2}
- {cmd:clone}: 1 for synthetic clone rows, 0 otherwise{break}
- {cmd:donor}: 1 for original never-treated donor rows, 0 for treated and clone rows{break}
- {cmd:source_unit}: treated unit that the row belongs to; for original rows it equals {cmd:unit()}{break}
- {cmd:ms_id}: unique identifier for original and clone units in the augmented data{break}
- {cmd:event_time}: periods relative to treatment onset; negative values are
pre-treatment, positive values are post-treatment; 0 is skipped so the gap
between -1 and 1 marks the treatment shock

{title:Remarks}

{pstd}
Version 1.0 requires numeric unit IDs and complete donor support over each
treated unit's observed time path. It does not yet report placebo inference,
standard errors, or second-stage treatment estimates.

{pstd}
The donor pool consists of all units with {cmd:treated()==0} that have
complete observations over the treated unit's full time span. Units with
any missing values in {it:yvar} or {cmd:controls()} during that span are
excluded from the donor pool for that treated unit.

{title:Examples}

{phang2}
{cmd:. use multisynth_example_data, clear}

{phang2}
{cmd:. multisynth y, unit(id) time(year) treated(treated) post(post)}

{phang2}
{cmd:. multisynth y, unit(id) time(year) treated(treated) post(post) controls(x1 x2 x3)}

{phang2}
{cmd:. multisynth y, unit(id) time(year) treated(treated) post(post)} ///
{cmd:  controls(x1 x2) ctrlweight(0.2) saving(stack.dta) replace} ///
{cmd:  wsaving(weights.dta) wreplace graph}

{title:Returned results}

{pstd}
{cmd:multisynth} returns:

{p 8 12 2}
- {cmd:r(treated_units_total)}: number of ever-treated units in the sample{break}
- {cmd:r(treated_units_completed)}: treated units for which a clone was built{break}
- {cmd:r(treated_units_skipped)}: treated units skipped due to insufficient donor support{break}
- {cmd:r(ctrlweight)}: control-balance penalty weight used{break}
- {cmd:r(clone_units_added)}: number of synthetic clones appended{break}
- {cmd:r(saved_file)}: path to augmented panel file, if {cmd:saving()} was used{break}
- {cmd:r(wsaved_file)}: path to weights file, if {cmd:wsaving()} was used

{title:References}

{phang}
Abadie, A., Diamond, A., and Hainmüller, J. 2010. Synthetic control methods
for comparative case studies: Estimating the effect of California's tobacco
control program. {it:Journal of the American Statistical Association}
105(490): 493–505.

{phang}
Abadie, A., Diamond, A., and Hainmüller, J. 2011. {cmd:synth}: Stata command
for synthetic control methods. {it:Statistical Software Components} S457603,
Boston College Department of Economics.

{title:Author}

{pstd}
Leonhard Benedikt Friedel{break}
WHU - Otto Beisheim School of Management{break}
leonhard.friedel@whu.edu

{title:Also see}

{psee}
{helpb synth} (if installed){p_end}
{psee}
{helpb xtset}{p_end}
