{smcl}
{help didintjl:didintjl}
{hline}

{title:didintjl}

{pstd}
Estimates the average treatment effect on the treated (ATT) while accounting for covariates that may vary by state, time, or both. That is, estimates ATT while accounting for different violations of the common causal covariates assumption.
Based on Karim & Webb (2025) {browse "https://arxiv.org/abs/2412.14447"}.
{p_end}

{title:Command Description}

{phang}
{cmd:didintjl} is a Stata command that serves as a wrapper for the didint() function from the DiDInt.jl Julia package.  
It requires you to specify the names of the outcome, state, and time variables as well as either a gvar variable, or, to specifically list the treated states and their treatment times.
{p_end}

{title:Requirements}

{pstd}
{cmd:didintjl} and {cmd:didintjl_plot} are tested and designed for the following versions:{p_end}

{synoptset 35 tabbed}{...}
{synopthdr:Requirement}
{synoptline}
{synopt:{bf:Julia}}version 1.12.0 or later{p_end}
{synopt:{bf:Stata}}version 16 or later{p_end}
{synopt:{bf:julia.ado}}version 2.0.0 or later ({browse "https://github.com/droodman/julia.ado"}){p_end}
{synopt:{bf:DiDInt.jl}}version 0.9.6 or later ({browse "https://github.com/ebjamieson97/DiDInt.jl"}){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
To install {bf:julia.ado}, run:{p_end}
{phang2}{cmd:. ssc install julia}{p_end}

{pstd}
To install {bf:DiDInt.jl}, run:{p_end}
{phang2}{cmd:. jl AddPkg DiDInt}{p_end}

{title:Stored results}

{pstd}
{cmd:didintjl} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(att)}}aggregate ATT estimate{p_end}
{synopt:{cmd:r(se)}}standard error of aggregate ATT{p_end}
{synopt:{cmd:r(p)}}p-value from two-sided t-test{p_end}
{synopt:{cmd:r(jkse)}}jackknife standard error{p_end}
{synopt:{cmd:r(jkp)}}p-value using jackknife standard error{p_end}
{synopt:{cmd:r(rip)}}p-value from randomization inference{p_end}
{synopt:{cmd:r(nperm)}}number of randomizations done{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(didint)}}sub-aggregate ATT results table{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:didintjl}
{cmd:,}
{cmd:outcome(}{it:varname}{cmd:)}
{cmd:state(}{it:varname}{cmd:)}
{cmd:time(}{it:varname}{cmd:)}
{p_end}

{p 8 17 2}
[{cmd:gvar(}{it:varname}{cmd:)}
{cmd:treated_states(}{it:string}{cmd:)}
{cmd:treatment_times(}{it:string}{cmd:)}
{cmd:date_format(}{it:string}{cmd:)}
{cmd:covariates(}{it:string}{cmd:)}
{cmd:ccc(}{it:string}{cmd:)}
{cmd:agg(}{it:string}{cmd:)}
{cmd:weighting(}{it:string}{cmd:)}
{cmd:ref_column(}{it:string}{cmd:)}
{cmd:ref_group(}{it:string}{cmd:)}
{cmd:freq(}{it:string}{cmd:)}
{cmd:freq_multiplier(}{it:integer}{cmd:)}
{cmd:start_date(}{it:string}{cmd:)}
{cmd:end_date(}{it:string}{cmd:)}
{cmd:nperm(}{it:integer}{cmd:)}
{cmd:seed(}{it:integer}{cmd:)}
{cmd:truejack(}{it:integer}{cmd:)}
{cmd:notyet(}{it:integer}{cmd:)}
{cmd:use_pre_controls(}{it:integer}{cmd:)}
{cmd:hc(}{it:integer}{cmd:)}
{cmd:edgecase(}{it:integer}{cmd:)}
{cmd:process(}{it:integer}{cmd:)}]
{p_end}

{title:Parameters}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt outcome(varname)}}name of outcome variable{p_end}
{synopt:{opt state(varname)}}name of state identifier variable{p_end}
{synopt:{opt time(varname)}}name of time variable{p_end}

{syntab:Treatment Specification}
{synopt:{opt gvar(varname)}}variable indicating time of first treatment for each state{p_end}
{synopt:{opt treated_states(string)}}list of treated states (use with treatment_times){p_end}
{synopt:{opt treatment_times(string)}}list of treatment times (use with treated_states){p_end}

{syntab:Date Options}
{synopt:{opt date_format(string)}}format of time variable, start_date, end_date, and treatment_times{p_end}

{syntab:Period Grid Construction (Staggered Adoption Only)}
{synopt:{opt freq(string)}}time period frequency: "year", "month", "week", or "day"; triggers date matching procedure{p_end}
{synopt:{opt freq_multiplier(integer)}}multiplier for freq (default: 1); e.g., 2 for two-year periods. Has no effect unless used with {cmd:freq}.{p_end}
{synopt:{opt start_date(string)}}starting date for the period grid construction{p_end}
{synopt:{opt end_date(string)}}ending date for the period grid construction{p_end}

{syntab:Covariates}
{synopt:{opt covariates(varnames or string)}}space-separated list of covariate names{p_end}
{synopt:{opt ref_column(string)}}column name for categorical reference variable{p_end}
{synopt:{opt ref_group(string)}}reference group for categorical variable (requires ref_column){p_end}
{synopt:{opt notyet(integer)}}shorthand for {cmd:use_pre_controls()}; use pre-treatment periods from treated states as controls (0 is false, 1 is true). Overwrites {cmd:use_pre_controls()} if both are specified.{p_end}
{synopt:{opt use_pre_controls(integer)}}use pre-treatment periods from treated states as controls (0 is false, 1 is true, default: 0){p_end}

{syntab:CCC, Aggregation, and Weighting}
{synopt:{opt ccc(string)}}CCC violation to control for: "hom", "time", "state", "add", or "int" (default: "int"){p_end}
{synopt:{opt agg(string)}}aggregation method{p_end}
{synopt:{opt weighting(string)}}weighting scheme{p_end}

{syntab:Inference}
{synopt:{opt nperm(integer)}}number of permutations for randomization inference (default: 999){p_end}
{synopt:{opt seed(integer)}}random seed for replication{p_end}
{synopt:{opt truejack(integer)}}jackknife method: 1 = re-estimate from first step, 0 = use diff matrix (default: 0){p_end}
{synopt:{opt hc(integer)}}heteroskedasticity-consistent standard error type (default: 1){p_end}
{synopt:{opt edgecase(integer)}}when enabled, computes standard errors for ATTs in the edge case where only two states contribute to a long difference regression, using variance and covariance terms of the relevant means. Computationally expensive; disabled by default (0 = false, 1 = true, default: 0){p_end}

{syntab:Data Processing}
{synopt:{opt process(integer)}}automatic processing of labeled covariate variables before passing to Julia (0 = off, 1 = on, default: 1).
When enabled, any covariate with a value label attached is decoded and then tested for numeric conversion.
If all decoded values are numeric, the value label is stripped and the variable is passed as numeric.
If the decoded values contain non-numeric characters (e.g. occupation or race category names), the variable is converted from a labeled numeric to a string and passed as a string categorical.
A warning message is displayed for each variable that is converted. Set {cmd:process(0)} to skip this conversion and pass all variables as-is. By default, any labelled variables are passed 
from Stata to Julia as categorical variables, however this may not always be desired (e.g. the case of a labelled numeric variable). This argument attempts to rectify this potential issue.{p_end}
{synoptline}
{p2colreset}{...}

{title:Examples}

{pstd}
For more examples, including an example dataset and do-file, please visit the GitHub repository:{p_end}
{pstd}
{browse "https://github.com/ebjamieson97/didintjl"}{p_end}

{pstd}
{bf:Basic example using Merit scholarship data:}{p_end}

{phang2}{cmd:. use "MeritExampleDataDiDIntjl.dta", clear}{p_end}

{phang2}{cmd:. didintjl, outcome("coll") state("state") time("year") ///}{p_end}
{phang2}{cmd:    treated_states("34 57 58 59 61 64 71 72 85 88") ///}{p_end}
{phang2}{cmd:    treatment_times("2000 1998 1993 1997 1999 1996 1991 1998 1997 2000") ///}{p_end}
{phang2}{cmd:    date_format("yyyy") covariates("asian male black") ccc("int")}{p_end}

{pstd}
This example estimates the effect of state merit scholarship programs on college enrollment, 
accounting for demographic covariates that vary by state and time (two-way intersection).{p_end}

{pstd}
{bf:Alternative syntax using gvar():}{p_end}

{pstd}
It is also possible to generate a gvar column and use syntax similar to csdid. 
Note that the variable merit is 1 for treated observations and 0 for non-treated observations:{p_end}

{phang2}{cmd:. gen year_numeric = real(year)}{p_end}
{phang2}{cmd:. bysort state (year_numeric): egen gvar = min(cond(merit == 1, year_numeric, .))}{p_end}
{phang2}{cmd:. replace gvar = 0 if missing(gvar)  // Optional: leave non-treated states as missing}{p_end}

{phang2}{cmd:. didintjl, outcome(coll) state(state) time(year_numeric) gvar(gvar) ///}{p_end}
{phang2}{cmd:    covariates(asian male black) seed(1234)}{p_end}


{title:CCC Violations and Model Specifications}

{pstd}
The {cmd:ccc()} option controls how {cmd:didintjl} accounts for potential violations of the 
Common Causal Covariates (CCC) assumption. Different violations require different model
specifications. The five options are:

{synoptset 15 tabbed}{...}
{synopthdr:CCC Option}
{synoptline}

{synopt:{bf:hom}}Homogeneous specification. Use when the CCC assumption seems plausible, 
meaning covariate effects on the outcome are constant across all states and time periods. 

{synopt:{bf:state}}State-varying specification. Use when covariate effects vary by state but 
are constant over time. 

{synopt:{bf:time}}Time-varying specification. Use when covariate effects vary over time but 
are constant across states.

{synopt:{bf:add}}Two one-way specification. Models covariate effects separately for each state and each time period.

{synopt:{bf:int}}Two-way specification (default). Models covariate effects uniquely for each state-time combination.


{synoptline}
{p2colreset}{...}

{pstd}
For guidance on model selection, see Karim and Webb (2025) {browse "https://arxiv.org/abs/2412.14447"} (perhaps especially sections 8 & 9).
It is also highly recommended to use the {cmd:didintjl_plot} command prior to running {cmd:didintjl} in order to help determine which model specification should be used.

{title:Aggregation Methods}

{pstd}
The {cmd:agg()} option determines which sub-aggregate ATTs are calculated and consequently affects the
calculation of the aggregate ATT. All options except {cmd:"none"} compute sub-aggregate ATTs, 
which are then combined into an aggregate ATT as a weighted mean. All options are available 
under staggered adoption, while only {cmd:"none"} and {cmd:"state"} are available for common adoption.

{synoptset 15 tabbed}{...}
{synopthdr:Aggregation Option}
{synoptline}
{synopt:{bf:cohort}}Aggregates ATTs by treatment time (cohort), computing sub-aggregate ATTs 
for each group based on when treatment begins.{p_end}

{synopt:{bf:state}}Aggregates ATTs by treated state, computing sub-aggregate ATTs for each state.{p_end}

{synopt:{bf:simple}}Aggregates ATTs by (g,t) group, where g is the first treatment time and t 
is any period from g to the end of the data. Computes sub-aggregate ATTs for each treated cohort 
in each post-treatment period.{p_end}

{synopt:{bf:sgt}}Aggregates ATTs by (s,g,t) combinations, where simple aggregation is further 
divided by state. Computes sub-aggregate ATTs for each state-cohort-period combination.{p_end}

{synopt:{bf:time}}Aggregates ATTs by periods since treatment (event time), computing sub-aggregate 
ATTs based on time elapsed since treatment began.{p_end}

{synopt:{bf:none}}No aggregation. Computes a single aggregate ATT without sub-aggregates.{p_end}
{synoptline}
{p2colreset}{...}

{pstd}

{bf:Computing Sub-Aggregate ATTs}

{pstd}
Sub-aggregate ATTs are calculated using a two-step process:

{phang}
1. Period-to-period contrasts are computed for all states. Each contrast represents the difference 
in mean outcomes (or covariate-adjusted mean outcomes) between two time periods.

{phang}
2. These contrasts are restricted to only those belonging to the sub-aggregate group, then regressed 
on an intercept and a binary indicator for whether the contrast came from a treated state. The 
resulting coefficient on the binary indicator is the sub-aggregate ATT. This is repeated for each sub-aggregate group.

{pstd}
{bf:Example with cohort aggregation:} Consider a staggered adoption scenario with treatment 
times in 1991 and 1993, where data spans 1989-1994 with yearly periods. The sub-aggregate ATT 
for the 1993 cohort uses two contrasts:

{phang}
- Mean outcome in 1993 minus mean outcome in 1992

{phang}
- Mean outcome in 1994 minus mean outcome in 1992

{pstd}
This regression includes contrasts from both the 1993 cohort (treated) and all control states 
for these same contrasts. The coefficient on the treatment indicator gives the sub-aggregate 
ATT for the 1993 cohort.

{pstd}
{bf:Example with state aggregation:} Using {cmd:agg("state")} in the same scenario performs 
a nearly identical calculation, except only contrasts from the specific state being analyzed 
(rather than all states in the 1993 cohort) are included in the treated group. 

{pstd}
For additional aggregation methods ({cmd:"simple"}, {cmd:"sgt"}, {cmd:"time"}), the same 
principle applies: contrasts are restricted to the relevant sub-aggregate grouping before 
computing the ATT estimate. Setting {cmd:"none"} skips the first step, and instead simply runs
the regression of contrasts on an intercept and binary indicator directly, without subsetting the data.

{title:Weighting Options}

{pstd}
The {cmd:weighting()} option controls how observations are weighted when computing sub-aggregate 
and aggregate ATTs. 

{synoptset 15 tabbed}{...}
{synopthdr:Weighting Option}
{synoptline}

{synopt:{bf:none}}No weighting. All contrasts receive equal weight when computing 
sub-aggregate ATTs, and all sub-aggregate ATTs receive equal weight when computing the 
aggregate ATT.{p_end}

{synopt:{bf:diff}}Difference weighting. Applies weights when computing sub-aggregate ATTs. 
Each contrast is weighted by the total number of observations used to compute it (i.e., all 
observations used to calculate both means in the contrast). Contrasts based on more observations 
receive greater weight.{p_end}

{synopt:{bf:att}}ATT weighting. Applies weights when computing the aggregate ATT from sub-aggregate 
ATTs. Each sub-aggregate ATT is weighted by the total number of treated observations included 
in its calculation (i.e., all treated observations across all contrasts used for that sub-aggregate). 
Sub-aggregates with more treated observations receive greater weight.{p_end}

{synopt:{bf:both}}Combined weighting (default). Applies both {cmd:diff} weighting (when computing sub-aggregate 
ATTs) and {cmd:att} weighting (when computing the aggregate ATT).{p_end}

{synoptline}
{p2colreset}{...}

{pstd}

{title:Date Matching Procedure for Staggered Adoption Settings}

{pstd}
If {cmd:freq} is not specified in staggered adoption settings, every unique date found in 
the data is treated as a distinct period. When {cmd:freq} is specified in staggered adoption settings,
{cmd:didintjl} performs a date matching procedure to align observations and treatment times to period boundaries:

{phang}
1. Period grid construction: A sequence of period start dates is created from {cmd:start_date} 
to {cmd:end_date} using the specified {cmd:freq} and {cmd:freq_multiplier}. By default, 
{cmd:start_date} and {cmd:end_date} are set to the minimum and maximum dates in the data 
unless explicitly specified by the user. If either {cmd:start_date} or {cmd:end_date} are specified,
then {cmd:date_format} will have to be specified as well.

{phang}
2. Observation matching: Each observation's time value is matched to the most recently passed 
period start date, with special handling for observations near treatment times. If a treatment 
occurs between two period boundaries, observations before the treatment are matched to the 
earlier period, and observations after are matched to the later period.

{phang}
3. Treatment time matching: Treatment times are matched to the first period start date that 
is greater than or equal to each treatment time. That is, if a treatment occurs between two period
boundaries (as opposed to directly at a period boundary), it is matched forward to the next period boundary.

{pstd}
{bf:Edge cases:} Observations occurring before the first period boundary are matched to the 
first period. Observations occurring at or after the last period boundary are matched to the 
last period.

{pstd}
{bf:Example:} Consider yearly data from 1989-2000 with seven treatment cohorts (1991, 1993, 
1996, 1997, 1998, 1999, 2000). Specifying {cmd:freq("year")} and {cmd:freq_multiplier(2)} 
creates a 2-year period grid: [1989, 1991, 1993, 1995, 1997, 1999]. Treatment times are 
matched forward to period boundaries: 1991→1991, 1993→1993, 1996→1997, 1998→1999,
1999→1999, 2000→1999 (capped at the last period). This consolidates the seven cohorts
into four (1991, 1993, 1997, 1999). For observations, when no treatment occurs between 
period boundaries, all observations in that interval are matched to the earlier boundary 
(e.g., observations in 1993 and 1994 both match to period 1993). However, the 1996 treatment 
splits the [1995, 1997) interval: observations in 1995 match to period 1995, while observations
in 1996 match forward to period 1997 (along with the treatment time at 1996).
Observations in 2000 are capped at the final period 1999.

{pstd}
{bf:Note:} The date matching procedure is only relevant for staggered adoption designs. 
In common adoption settings (where all treated units adopt at the same time), observations 
are simply classified as "pre" or "post" treatment, making date matching unnecessary.


{title:Randomization Inference Procedure}

{pstd}
{cmd:didintjl} implements a randomization inference procedure following MacKinnon and Webb (2020) 
to compute p-values. See the paper here: {browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407620301445"}

{pstd}
The procedure works as follows:

{phang}
1. Treatment times are randomly reassigned among states {cmd:nperm} times, ensuring each 
randomization produces a unique assignment of treatment times to states.

{phang}
2. For each randomization, sub-aggregate and aggregate ATTs are recalculated according
to the randomized treatment times assignment.

{phang}
3. The distribution of ATTs calculated from these randomizations is compared against the actual
ATT estimates from the true treatment assignment in order to compute p-values.

{pstd}
Randomization inference p-values are returned in {cmd:r(rip)} for the aggregate ATT and 
can be seen at the sub-aggregate ATT level with {cmd:matrix list r(didint)}.
Set {cmd:seed()} for reproducible results across runs with the same data.


{title:Date Format Compatibility}

{pstd}
{cmd:didintjl} is compatible with a variety of date formats. The {cmd:time()} variable can be 
a string in any of the following formats, as long as {cmd:date_format()} is specified appropriately:

{synoptset 25 tabbed}{...}
{synopthdr:Format}
{synoptline}
{synopt:{cmd:"yyyy/mm/dd"}}Example: 1997/08/25{p_end}
{synopt:{cmd:"yyyy-mm-dd"}}Example: 1997-08-25{p_end}
{synopt:{cmd:"yyyymmdd"}}Example: 19970825{p_end}
{synopt:{cmd:"yyyy/dd/mm"}}Example: 1997/25/08{p_end}
{synopt:{cmd:"yyyy-dd-mm"}}Example: 1997-25-08{p_end}
{synopt:{cmd:"yyyyddmm"}}Example: 19972508{p_end}
{synopt:{cmd:"dd/mm/yyyy"}}Example: 25/08/1997{p_end}
{synopt:{cmd:"dd-mm-yyyy"}}Example: 25-08-1997{p_end}
{synopt:{cmd:"ddmmyyyy"}}Example: 25081997{p_end}
{synopt:{cmd:"mm/dd/yyyy"}}Example: 08/25/1997{p_end}
{synopt:{cmd:"mm-dd-yyyy"}}Example: 08-25-1997{p_end}
{synopt:{cmd:"mmddyyyy"}}Example: 08251997{p_end}
{synopt:{cmd:"mm/yyyy"}}Example: 08/1997{p_end}
{synopt:{cmd:"mm-yyyy"}}Example: 08-1997{p_end}
{synopt:{cmd:"mmyyyy"}}Example: 081997{p_end}
{synopt:{cmd:"yyyy"}}Example: 1997{p_end}
{synopt:{cmd:"ddmonyyyy"}}Example: 25aug1997{p_end}
{synopt:{cmd:"yyyym00"}}Example: 1997m8{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Ensure that the format specified in {cmd:date_format()} exactly matches how dates appear 
in your {cmd:time()} variable. Note that if the {cmd:time()} variable is simply a 4-digit year, 
the {cmd:date_format()} argument does not need to be specified.

{pstd}
{bf:Important:} The {cmd:time()} variable must be of the same type as either the {cmd:treatment_times()} 
values or the {cmd:gvar()} variable depending on which argument is specified. This means:

{phang}
- If using {cmd:treatment_times()}, the {cmd:time()} variable and dates specified in {cmd:treatment_times()} 
must both be identically formatted strings matching one of the compatible date formats above

{phang}
- If using {cmd:gvar()}, both {cmd:time()} and {cmd:gvar()} should either both be numeric variables or both be string variables of the same format

{title:Further Reading}

{pstd}
For a deeper dive into the backend implementation, see the DiDInt.jl package documentation:{p_end}
{pstd}
{browse "https://ebjamieson97.github.io/DiDInt.jl/stable/details/"}{p_end}

{title:Package Author}

{pstd}
Eric Jamieson. Tell me about all the bugs in my code: ericbrucejamieson@gmail.com or at {browse "https://github.com/ebjamieson97/didintjl"}.
{p_end}

{title:Citations}

{pstd}
If you use {cmd:didintjl} in your research, please cite:{p_end}

{pstd}
Sunny Karim and Matthew D. Webb. "Good Controls Gone Bad: Difference-in-Differences with Covariates." 
{browse "https://arxiv.org/abs/2412.14447"}{p_end}

{pstd}
If you reference the randomization inference p-values in your work, please also cite:{p_end}

{pstd}
MacKinnon, James G., and Matthew D. Webb. "Randomization Inference for Difference-in-Differences 
with Few Treated Clusters." {browse "https://www.sciencedirect.com/science/article/abs/pii/S0304407620301445"}{p_end}

{* didintjl                                           }
{* written by Eric Jamieson                           }
{* version 0.7.7 2026-06-07                           }

{smcl}