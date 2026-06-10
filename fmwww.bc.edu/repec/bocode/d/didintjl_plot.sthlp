{smcl}
{help didintjl_plot:didintjl_plot}
{hline}

{title:didintjl_plot}

{pstd}
Produces parallel trends plots and event study plots to help assess which DID-INT model variation to use.
Based on Karim & Webb (2025) {browse "https://arxiv.org/abs/2412.14447"}.
{p_end}

{title:Command Description}

{phang}
{cmd:didintjl_plot} is a Stata command that wraps the didint_plot() function
from the DiDInt.jl Julia package. It produces either parallel trends plots (one panel per DID-INT model variation)
or event study plots with confidence intervals. It is recommended to run
{cmd:didintjl_plot} prior to {cmd:didintjl} to guide model selection.
{p_end}

{title:Requirements}

{pstd}
{cmd:didintjl_plot} and {cmd:didintjl} are tested and designed for the following versions:{p_end}

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

{title:Syntax}

{p 8 17 2}
{cmd:didintjl_plot}
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
{cmd:weights(}{it:integer}{cmd:)}
{cmd:ref_column(}{it:string}{cmd:)}
{cmd:ref_group(}{it:string}{cmd:)}
{cmd:freq(}{it:string}{cmd:)}
{cmd:freq_multiplier(}{it:integer}{cmd:)}
{cmd:start_date(}{it:string}{cmd:)}
{cmd:end_date(}{it:string}{cmd:)}
{cmd:hc(}{it:integer}{cmd:)}
{cmd:event(}{it:integer}{cmd:)}
{cmd:ci(}{it:real}{cmd:)}
{cmd:groupmin(}{it:integer}{cmd:)}
{cmd:window(}{it:numlist}{cmd:)}
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

{syntab:CCC and Weighting}
{synopt:{opt ccc(string)}}space-separated list of DID-INT model variations to plot: any combination of "hom", "time", "state", "add", "int", or "none". Defaults to all six when not specified.{p_end}
{synopt:{opt weights(integer)}}apply weighting when computing event plot estimates (0 = false, 1 = true, default: 1){p_end}

{syntab:Plot Options}
{synopt:{opt event(integer)}}plot type: 0 = parallel trends plot, 1 = event study plot (default: 0){p_end}
{synopt:{opt ci(real)}}confidence level for event study confidence intervals (default: 0.95){p_end}
{synopt:{opt groupmin(integer)}}minimum number of groups required to display confidence intervals in event study plot; observations with fewer groups than this threshold have their confidence intervals suppressed (default: 3){p_end}
{synopt:{opt window(numlist)}}two-element numlist specifying the range of periods to display. For parallel trends plots ({cmd:event(0)}), specifies the period number range. For event study plots ({cmd:event(1)}), specifies the range of periods relative to treatment (e.g., {cmd:window(-5 5)}){p_end}

{syntab:Inference}
{synopt:{opt hc(integer)}}heteroskedasticity-consistent standard error type (default: 1){p_end}

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
{bf:Parallel trends plot for a subset of states and two CCC specifications:}{p_end}

{phang2}{cmd:. use "MeritExampleDataDiDIntjl.dta", clear}{p_end}

{phang2}{cmd:. * Subset to four states to avoid a cluttered plot}{p_end}
{phang2}{cmd:. keep if inlist(state, "34", "71", "11", "14")}{p_end}

{phang2}{cmd:. didintjl_plot, outcome("coll") state("state") time("year") ///}{p_end}
{phang2}{cmd:    treatment_times("2000 1991") date_format("yyyy") ///}{p_end}
{phang2}{cmd:    covariates("asian male black") ccc("hom int")}{p_end}

{pstd}
This produces a side-by-side parallel trends plot with one panel per 'ccc' specification (DID-INT model variations),
with dashed vertical lines marking treatment times. Inspecting how trends evolve before
treatment under different specifications helps guide the choice of {cmd:ccc()} in
{cmd:didintjl}.{p_end}

{pstd}
{bf:Event study plot using gvar():}{p_end}

{phang2}{cmd:. use "MeritExampleDataDiDIntjl.dta", clear}{p_end}

{phang2}{cmd:. gen year_numeric = real(year)}{p_end}
{phang2}{cmd:. bysort state (year_numeric): egen gvar = min(cond(merit == 1, year_numeric, .))}{p_end}

{phang2}{cmd:. didintjl_plot, outcome(coll) state(state) time(year_numeric) gvar(gvar) ///}{p_end}
{phang2}{cmd:    date_format("yyyy") covariates("asian male black") event(1)}{p_end}

{pstd}
Specifying {cmd:event(1)} produces event study plots across all CCC specifications,
showing point estimates and confidence interval bands as a function of time relative
to treatment. A dotted vertical line marks period 0 (treatment onset) and a horizontal
line marks zero.{p_end}

{title:Plot Types}

{pstd}
{cmd:didintjl_plot} produces two types of plots depending on the {cmd:event()} option:

{synoptset 15 tabbed}{...}
{synopthdr:event() Value}
{synoptline}
{synopt:{bf:0}}Parallel trends plot (default). Produces one panel per 'ccc' specification, showing
the covariate-adjusted outcome over time for each state. Dashed vertical lines mark treatment
times. Useful for visually assessing whether pre-treatment trends are parallel across states.{p_end}

{synopt:{bf:1}}Event study plot. Produces one panel per 'ccc' specification, showing the
mean outcome (while controlling for covariates depending on each 'ccc' specification) 
at each period relative to treatment, along with a confidence interval band.
Periods with fewer groups than {cmd:groupmin()} have their confidence intervals suppressed.{p_end}
{synoptline}
{p2colreset}{...}

{title:CCC Options}

{pstd}
The {cmd:ccc()} option accepts a space-separated list of model specifications to plot simultaneously.
Each named specification produces its own panel in the combined graph. Valid values are:

{synoptset 15 tabbed}{...}
{synopthdr:CCC Option}
{synoptline}
{synopt:{bf:hom}}Homogeneous DID-INT.{p_end}
{synopt:{bf:state}}State-varying DID-INT.{p_end}
{synopt:{bf:time}}Time-varying DID-INT.{p_end}
{synopt:{bf:add}}Two one-way DID-INT.{p_end}
{synopt:{bf:int}}Two-way DID-INT.{p_end}
{synopt:{bf:none}}No covariates included.{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
When {cmd:ccc()} is not specified, all six specifications are plotted. Specifying a subset
(e.g., {cmd:ccc("hom int")}) restricts the output to only those panels, which can reduce
clutter when only certain specifications are of interest.{p_end}

{pstd}
For guidance on model selection, see Karim and Webb (2025) {browse "https://arxiv.org/abs/2412.14447"} (perhaps especially sections 8 & 9).{p_end}

{title:Date Format Compatibility}

{pstd}
{cmd:didintjl_plot} is compatible with the same date formats as {help didintjl:didintjl}.
The {cmd:time()} variable can be a string in any of the following formats, as long as
{cmd:date_format()} is specified appropriately:

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
If you use {cmd:didintjl_plot} in your research, please cite:{p_end}

{pstd}
Sunny Karim and Matthew D. Webb. "Good Controls Gone Bad: Difference-in-Differences with Covariates."
{browse "https://arxiv.org/abs/2412.14447"}{p_end}

{* didintjl_plot                                      }
{* written by Eric Jamieson                           }
{* version 0.0.3 2026-07-06                           }

{smcl}