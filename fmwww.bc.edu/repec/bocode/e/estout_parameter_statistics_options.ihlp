{p 4 8 2}
{cmd:cells(}{it:array}{cmd:)} specifies the parameter statistics to be reported
and how they are to be arranged. The default is for cells to report raw
coefficients only, i.e. {cmd:cells(b)}. {cmd:cells(none)} may be used to
completely suppress the printing of parameter statistics. Alternatively,
{cmd:cells(b se)} would result in the reporting of raw coefficients and
standard errors. Multiple statistics are placed in separate rows beneath one
another by default. However, elements of {it:array} that are listed in
quotes, e.g. {cmd:cells("b se")}, are placed beside one another. For
example, {cmd:cells("b p" se)} would produce a table with raw coefficients
and standard errors beneath one another in the first column and p-values in
the top row of the second column for each model.

{p 8 8 2}
The parameter statistics available are {cmd:b} (coefficients), {cmd:se}
(standard errors), {cmd:t} (t/z-statistics), {cmd:p} (p-values),
and {cmd:ci} (confidence intervals; to display the lower and upper bounds
in separate cells use {cmd:ci_l} and {cmd:ci_u}). Any additional 
parameter statistics included in the {cmd:e()}-returns
for the models can be tabulated as well. If, for example, {cmd:e(beta)} contains
the standardized coefficients, type {cmd:cells(beta)} to tabulate them
(see help {help estadd}). Also
see the {cmd:eform} and {cmd:margin}
options for more information on the kinds of statistics that can be
displayed.

{p 8 8 2}
A set of suboptions may be specified in parentheses for each statistic
named in {it:array}. For example, to add significance stars to the
coefficients and place the standard errors in parentheses, specify
{bind:{cmd:cells(b(star) se(par))}}. The following suboptions are
available. Use:

{p 12 16 2}
  {cmd:star} to specify that stars denoting the significance of the
  coefficients be attached to the statistic: {cmd:*} for p<.05,
  {cmd:**} for p<.01, and {cmd:***} for p<.001. The symbols and the
  values for the thresholds and the number of levels are fully customizable
  (see the
  {it:{help estout_significance_stars_options:significance_stars_options}}).

{p 12 16 2}
  {cmd:fmt(%}{it:fmt} [{cmd:%}{it:fmt} ...]{cmd:)} to specify the display
  format(s) of a statistic. It defaults to the display format for raw
  coefficients ({cmd:b}), or {cmd:%9.0g}. If only one format is
  specified, it is used for all occurrences of the statistic. If multiple
  formats are specified, the first format is used for the first
  regressor in the estimates table, the second format for the second
  regressor, and so on. The last format is used for the remaining regressors if
  the number of regressors in the table is greater than the number of
  specified formats. Note that, regardless of the display format chosen,
  leading and trailing blanks are removed from the numbers. White space can
  be added by specifying a {cmd:modelwidth()} (see the
  {it:{help estout_layout_options:layout_options}}).

{p 12 16 2}
  {cmd:label(}<{it:string}>{cmd:)} to specify a label to appear in the column
  heading. The default is the name of the statistic.

{p 12 16 2}
  {cmd:par}[{cmd:(}<{it:left}> <{it:right}>{cmd:)}] to specify that the
  statistic in question be placed in parentheses. It is also possible to specify custom
  "parentheses". For example, {cmd:se(par({ }))} would display the
  standard errors in curly brackets. For {cmd:ci} the syntax is:

{p 20 20 2}
   {cmd:ci(par}[{cmd:(}<{it:left}> <{it:middle}> <{it:right}>{cmd:)}]{cmd:)}

{p 12 16 2}
  {cmd:drop(}{it:droplist}{cmd:)} to cause certain individual statistics to be
  dropped. For example, specifying {cmd:t(drop(_cons))} suppresses the
  t-statistics for the constants. A {it:droplist} comprises one or more
  specifications, separated by white space. A specification can be either a
  variable name (e.g. {cmd:price}), an equation name followed by a colon
  (e.g. {cmd:mean:}), or a full name (e.g. {cmd:mean:price}). Be sure to
  refer to the matched equation names, and not to the original equation names
  in the models, when using the {cmd:equations()} option to match equations.

{p 12 16 2}
  {cmd:keep(}{it:keeplist}{cmd:)} to cause certain individual statistics to be
  kept. For example, the specification  {cmd:t(keep(mpg))} would display the
  t-statistics exclusively for the variable {cmd:mpg}. See the {cmd:drop()}
  suboption above for further details.

{p 12 16 2}
  {cmd:pattern(}{it:pattern}{cmd:)} to designate a pattern of models for which
  the statistics are to be reported, where the {it:pattern} consists of zeros
  and ones. A {cmd:1} indicates that the statistic be printed; {cmd:0}
  indicates that it be suppressed. For example {cmd:beta(pattern(1 0 1))}
  would result in {cmd:beta} being reported for the first and third models,
  but not for the second.

{p 12 16 2}
  {cmd:abs} to specify that absolute t-statistics be used instead of regular
  t-statistics (relevant only if used with {cmd:t()}).

{p 4 8 2}
{cmd:drop(}{it:droplist}{cmd:)} identifies the coefficients to be dropped from
the table. This option is passed to the internal call of {cmd:estimates table}.
See help {help estimates} for details.

{p 4 8 2}
{cmd:keep(}{it:keeplist}{cmd:)} selects the coefficients to be included in the
table. The {cmd:keep()} option may also be used to change the order of the
coefficients and equations within the table. This option is passed to the
internal call of {cmd:estimates table}. See help {help estimates} for details.

{p 4 8 2}
{cmd:equations(}{it:eqmatchlist}{cmd:)} specifies how the models' equations are
to be matched. This option is passed to the internal call of
{cmd:estimates table}. See help {help estimates} on how to specify this option.

{p 4 8 2}
{cmd:eform}[{cmd:(}{it:pattern}{cmd:)}] displays the coefficient table in
exponentiated form. The exponent of {cmd:b} is displayed in lieu of the
untransformed coefficient; standard errors and confidence intervals are
transformed as well. Specify a {it:pattern} if the exponentiation is to be
applied only for certain models. For instance, {cmd:eform(1 0 1)} would
transform the statistics for Models 1 and 3, but not for Model 2. Note that,
unlike {cmd:regress} and {cmd:estimates table}, {cmd:estout} in
eform-mode does not suppress the display of the intercept. To drop the
intercept in eform-mode, specify {cmd:drop(_cons)}.

{p 4 8 2}
{cmd:margin}[{cmd:(}{{cmd:u}|{cmd:c}|{cmd:p}}{cmd:)}] indicates that the
marginal effects or elasticities be reported instead of the raw
coefficients. This option has an effect only if {cmd:mfx} has been
applied to a model before its results were stored (see help {help mfx}) or if a
{cmd:dprobit} (see help {help probit}), {cmd:truncreg,marginal}
(help {help truncreg}), or {cmd:dtobit} (Cong 2000) model is estimated. One
of the parameters {cmd:u}, {cmd:c}, or {cmd:p}, corresponding to the
unconditional, conditional, and probability marginal effects, respectively,
is required for {cmd:dtobit}. Note that the standard errors, confidence
intervals, t-statistics, and p-values are transformed as well.

{p 8 8 2}
Using the {cmd:margin} option with multiple-equation models can be tricky.
The marginal effects of variables that are used in several equations are
printed repeatedly for each equation because the equations per se are
meaningless for {cmd:mfx}. To display the effects for certain equations only,
specify the {cmd:meqs()} option. Alternatively, use the {cmd:keep()} and
{cmd:drop()} options to eliminate redundant rows. The {cmd:equations()}
option might also be of help here.

{p 4 8 2}
{cmd:discrete(}{it:string}{cmd:)} may be used to override the default symbol and
explanatory text used to identify dummy variables when reporting marginal
effects. The first token in {it:string} is used as the symbol. The default is:

{p 12 12 2}
{cmd:discrete(" (d)" marginals for discrete change of dummy variable from 0 to 1)}

{p 8 8 2}
To display explanatory text, specify either the {cmd:legend} option or use
the {cmd:@discrete} variable.

{p 8 8 2}
Use {cmd:nodiscrete} to disable the identification of dummy variables as
such. The default is to indicate the dummy variables unless they have been
interpreted as continuous variables in all of the models for which results are
reported (for {cmd:dprobit} and {cmd:dtobit}, however, dummy variables will
always be listed as discrete variables unless {cmd:nodiscrete} is specified).

{p 4 8 2}
{cmd:meqs(}{it:eq_list}{cmd:)} specifies that marginals be printed only for the
equations in {it:eq_list}. Specifying this option does not affect how the
marginals are calculated.  An {it:eq_list} comprises one or more equation
names (without colons) separated by white space. If you use the
{cmd:equations()} option to match equations, be sure to refer to the matched
equation names and not to the original equation names in the models.

{p 4 8 2}
{cmd:level({it:#})} assigns the confidence level, in percent, for the confidence
intervals of the coefficients (see help {help level}).
