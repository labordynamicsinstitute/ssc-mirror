{smcl}
{* May2,2022}{...}
{cmd:help allsynth} 
{hline}

{title:Title} {p 19 20 0} {cmd:Beta version 0.0.9} - Release date: May 2, 2022. Tested on Stata 15.1 and above. Email bug reports to: jcwiltshire@ucdavis.edu

{p2colset 5 20 20 2}{...}
{p2col :{hi:allsynth} {hline 2}}Automates estimation of (i) bias-corrected synthetic control gaps ("treatment effects"); (ii) RMSPE-ranked {it:p}-values from 
"in-space" treatment permutations; and (iii) "stacked" synthetic controls (with many treated units and potentially staggered treatment timing); and also provides heavily-automated 
graphing functionality. See {browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf": Wiltshire (2022)} for a thorough review of {cmd:allsynth} {p_end}
{p2colreset}{...}


{title:Syntax}

{p 6 8 2}
{opt allsynth} {help synth##predoptions:{it:depvar}}  {help synth##predoptions:{it:predictorvars}} , {opt tru:nit}({it:#}) {opt trp:eriod}({it:#}) [{it: synth_options} 
{opt pval:ues} {opt bcor:rect}({it:string}) {opt gapfig:ure}({it:string}) {opt trans:form}({it:string}) {opt stacked}({it:string}) ]

{p 4 4 2}
The data must be declared as a (balanced) panel using {help tsset} (or {help xtset}) {it:panelvar} {it:timevar}.
The variables specified in {it:depvar} and {it:predictorvars} must be numeric and must not be abbreviated. 

{p 4 4 2}
The commands {cmd:synth}, {cmd:distinct} and {cmd:elasticregress} must be installed. The {help synth} command should be understood prior to 
implementation of {cmd:allsynth}.

{title:Description}

{p 4 4 2}
{cmd:allsynth} is a wrapper for the {cmd:synth} command which automates the implementation of several additional features. The primary extensions are: 
{cmd:(1)} automated estimation of "bias-corrected" synthetic control gaps to adjust for discrepancies in predictor variable values between a treated 
unit and its donor pool, proposed by {browse "https://www.tandfonline.com/doi/abs/10.1080/01621459.2021.1971535":Abadie and L'Hour (2021)} and 
{browse "https://www.tandfonline.com/doi/full/10.1080/01621459.2021.1929245":Ben-Michael, Feller and Rothstein (2021)}; 
{cmd:(2)} automated estimation RMSPE-ranked {it:p}-values based on in-space placebo tests (for "classic" and "bias-corrected" specifications) in which 
treatment status is randomly permuted across untreated units ({browse "https://onlinelibrary.wiley.com/doi/abs/10.1111/ajps.12116":Abadie, Diamond and Hainmueller (2015)}); 
{cmd:(3)} automated estimation of a "stacked" synthetic control estimator with many treated units and potentially staggered treatment timing
({browse "https://ftp.iza.org/dp8944.pdf":Dube and Zipperer (2015)}, {browse "https://justinwiltshire.com/s/JustinCWiltshire_JMP.pdf":Wiltshire (2021)}), 
yielding estimates of the average treatment effects and (if desired) associated RMSPE-ranked {it:p}-values for both classic and bias-corrected specifications; and
{cmd:(4)} greatly expanded automated graphing capability. {cmd: allsynth} also provides additional diagnostics and warnings to help practitioners with its usage.

{title:Required Settings}

{p 4 4 2}
{marker predoptions}
As with the {cmd:synth} command, {cmd:allsynth} requires specification of {cmd: depvar} (the outcome variable), 
{cmd: predictorvars} (the list of predictor variables, including if specified only for specific periods),
the option {cmd: trperiod}({it:#}), where {it:#} is observed in the panel 
time variable specified in {cmd: tsset} {it:timevar} and which corresponds to the earliest intervention period, and the 
option {cmd: trunit}({it:#}), where {it:#} is observed in the panel unit variable specified in 
{cmd: tsset} {it:unitvar} and which corresponds to the unit which received the intervention. The {cmd:allsynth} options
have further requirements and options, where [...] indicates optional specifications and {cmd:A}|{cmd:B} indicates at least
(sometimes exactly) one of {cmd:A} or {cmd:B} must be specified. Users should {it:not} include the symbols [, ], or |.

{title:allsynth Options}

{p 4 4 2} Several {cmd:allsynth} options interact with each other, and some are contingent on others being specified. 
Informative warnings are returned if the specified options need to be changed.

{p 4 8 2}
{cmd:pvalues} automates estimation of in-space placebo gaps across the donor pool units, then calculates RMSPE-ranked {it:p}-values 
for each post-treatment period. 

{p 8 8 2}If the {cmd:bcorrect}() option is also specified, then the bias-corrected placebo gaps and {it:p}-values
will also be calculated. {cmd:pvalues} must be specified for the placebo gaps to be plotted (see the entry on the {cmd:gapfigure}() 
option, below). Specifying {cmd:pvalues} will greatly extend the run-time of {cmd:allsynth}, and so it is assumed that the results should 
be saved. Accordingly, the {cmd:keep}({it:file}) option must be specified if {cmd:pvalues} is specified. The variables {it:RMSPE}, 
{it:RMSPE_rank}, and {it:p} (and their bias-corrected equivalents, if {cmd:bcorrect}() is also specified) will be merged into {it:file}.{p_end}


{p 4 8 2}
{cmd: bcorrect}({cmd:nosave|merge }[ {cmd:ridge}|{cmd:lasso}|{cmd:elastic}|{cmd:posonly figure} ]) specifies that the bias-corrected synthetic control estimates should be 
calculated alongside the classic synthetic control estimates.

{p 8 8 2}{it:Exactly one} of {cmd:nosave} or {cmd:merge} are required. If {cmd:merge} is specified, {cmd:keep}({it:file}) must also be specified. 
With {cmd:merge}, the the variables {it:gap} and {it:gap_bc} containing the classic and bias-corrected gaps, as well as the variables {it:_Y_treated_bc} and {it:_Y_synthetic_bc}
containing the bias-corrected outcome paths, are merged into {it:file}. With {cmd:nosave}, none of the additional elements from the bias-correction 
procedure will be saved and {cmd:keep}({it:file}) need not be specified.{p_end}

{p 8 8 2}Users may also specify additional {cmd:bcorrect}() options:{p_end}

{p 10 10 2}(1) {it:Exactly one} of {cmd:ridge}, {cmd:lasso}, {cmd:elastic}, or {cmd:posonly} may be specified if the bias is to be estimated 
using (respectively) ridge regression, lasso regression, elastic net regression, or ordinary least squares (OLS) regression with only those 
donor pool units for which the synthetic-control-estimated {it:w} weights are strictly positive. The default setting is to use OLS regression 
with all donor pool units to estimate the bias. See {help elasticregress}. Values for labmda, alpha, and the number of folds may not be specified. 
Note that specifying {cmd:ridge}, {cmd:lasso}, or {cmd:elastic} may greatly increase the run-time.

{p 10 10 2}(2) {cmd:figure} specifies that, analogous to {cmd:figure} in {it:synth_options}, a plot should be generated which shows the trajectories 
of the {it:bias-corrected} values of the outcome variable for the treated unit and its synthetic control. Most practitioners will have an interest 
only in the difference rather than in these variables individually; however, visual examination of this plot may be instructive.


{p 4 8 2}
{cmd:gapfigure}({cmd:classic}|{cmd:bcorrect} [ {cmd:placebos lineback, save}({it:file}) [{cmd:, replace} ]) {it:twoway_options} ]) can be used to 
automatically generate a plot of the trajectories of (at most two of) the estimated gaps, bias-corrected gaps, the set of placebo gaps, or 
the set of bias-corrected placebo gaps. The bias-corrected gaps and placebo gaps can only be plotted if the {cmd:allsynth} option {cmd:bcorrect}() 
is specified, and the placebo gaps can only be plotted if the {cmd:allsynth} option {cmd:pvalues} is specified. If {cmd:bcorrect}() is specified, 
only the bias-corrected gaps and placebo gaps can be plotted.

{p 8 8 2}{it:At least one} of {cmd:classic} or {cmd:bcorrect} must be specified, though both may also be specified if the {cmd:placebos} option 
(see option (1), below) is {it:not} specified. {cmd:classic} plots the classic estimated gaps for the treated units, and {cmd:bcorrect} plots the bias-corrected 
estimated gaps for the treated unit.{p_end}

{p 8 8 2}Users may also specify additional {cmd:gapfigure}() options:{p_end}

{p 10 10 2}(1) {cmd:placebos} plots the (classic {it:or} bias-corrected) estimated placebo gaps from in-space treatment permutations, and may only
be specified if the {cmd:allsynth} option {cmd:pvalues} is also specified. {cmd:placebos} may be specified with {it:either} {cmd:classic} {it:or} 
{cmd:bcorrect}, but not both. If the {cmd:allsynth} option {cmd:bcorrect}() is specified, then {cmd:placebos} may {it:only} be specified with {cmd:bcorrect}.

{p 10 10 2}(2) {cmd:lineback} places a vertical dotted line on the plot in the final pre-treatment period. The default setting places a vertical dotted line on the
plot in the treatment period.

{p 10 10 2}(3) {cmd:save}({it:file}) specified that the plot should be saved to the indicated {it:file}, which may include a filepath and a filename. 
The default file extension is {it:.pdf} but another extension may be specified. {cmd:replace} may be specified after a comma if any identically-named
file should be overwritten, as in {cmd:save}({it:file}{cmd:, replace}).

{p 10 10 2}(4) {it:twoway_options} may be specified to modify the plot as desired (see {help twoway_options}), but note that titles of any kind must {it:not}
be contained in quotations and will not display a comma if one is indicated.{p_end}


{p 4 8 2}{cmd:transform}({it:varlist}{cmd:, demean}|{cmd:normalize}) can be used to automatically transform specified variables in exactly one of two ways prior to synthetic control estimation: 
the variables can be demeaned over the pre-treatment period, or can be normalized to 100 in the final pre-treatment period. Only one transformation 
type may be specified.

{p 8 8 2}{it:varlist} indicates the variables that will be transformed. At least one variable must be specified. {it:Exactly one} of {cmd:demean} or
{cmd:normalize} must be specified. {cmd:demean} will (by unit) demean the specified variables over the entire pre-treatment period. {cmd:normalize}
will (by unit) normalize all specified variables to 100 times the value in a given pre-treatment period {it:t} divided by the value in the treated unit
{it:i}'s final pre-treatment period (note the donor pool units for {it:i} will also be normalized to {it:i}'s final pre-treatment period). Also note 
that this necessitates that no variable in {it:varlist} have its value in the final pre-treatment period alone be specified as a predictor.{p_end}


{p 4 8 2}{cmd:stacked}({cmd:trunits}({it:varname}) {cmd:trperiods}({it:varname}) {cmd:, clear} [ {cmd:eventtime}({it:numlist}) {cmd:avgweights}({it:varname}) 
{cmd:balanced} {cmd:donorcond}({it:string} [{cmd:,} {it:string} ]) {cmd:donorcond2}({it:string} [{cmd:,} {it:string} ]) {cmd:donorcond3}({it:string} [{cmd:,} 
{it:string} ]) {cmd:donorcond4}({it:string} [{cmd:,} {it:string} ]) {cmd:donorif}({it:string}) {cmd:unique_w} {cmd:sampleavgs}({it:real}) 
{cmd:figure}({cmd:classic}|{cmd:bcorrect} [ {cmd:placebos lineback}{cmd:, save}({it:file}) [{cmd:, replace} ]) {it:twoway_options} ]) can be used to automatically 
estimate the average treatment effect on the treated units using a stacked synthetic control estimating strategy. 

{p 8 8 2} Users may specify if the estimates should be calculated in event time or calendar time (where either are possible), may specify whether 
estimates should be balanced in the specified time-type periods, may specify unit-specific weights for calculation of the averages, and may specify 
whether the averages should include only unit-estimates associated with unique estimated {it:W} matrices. Users may also specify conditions for 
selecting treated-unit-specific donor pools.

{p 8 8 2} Users may additionally specify the automatic generation of a distribution of sampled average placebo gaps and calculate RMSPE-ranked {it:p}-values 
from that distribution, and may specify the number of placebo average gaps included in the sample distribution. 

{p 8 8 2} Similarly to the {cmd:gapfigure}() option (see above), {cmd:stacked}() allows users to automatically generate a (customizable) plot of the 
trajectories of (at most two of) the estimated average gaps, bias-corrected average gaps, the set of placebo average gaps, or the set of 
bias-corrected placebo average gaps, all in event time, or in calendar time when units are treated simultaneously. 

{p 8 8 2} The {cmd:allsynth} option {cmd:keep}({it:file}) must be specified if {cmd:stacked}() is specified, and the treated-unit-specific results for 
each treated unit {it:i} will be saved in {it:filename_panelvar_i.dta}, while the estimated average gaps by time period will be saved in 
{it:filename_ate.dta}. If the {cmd:allsynth} option {cmd:pvalues} is specified, then the estimated average gaps, placebo gaps, RMPSE, and 
RMSPE-ranked {it:p}-values will be saved in {it:filename_ate_distn.dta}.

{p 8 8 2}{cmd:trunit}({it:varname}) is required, and {it:varname} must identify a dummy variable that, in all periods, identifies the treated units with a 1 
and the donor pool units with a 0. {cmd:trperiods}({it:varname}) is required, and {it:varname} must identify an integer variable that, in all periods, contains 
the {it:timevar} period of treatment (assumed to be in calendar time) for every treated unit. If the treatment is simultaneous in {it:timevar} for all 
treated units {it:i}, results will be displayed and saved in {it:timevar} periods (assumed to be calendar periods); otherwise, results will be displayed and 
saved in event time, with each treatment period converted to event period zero. {cmd:clear} is required and {it:must} be specified after a comma. note that 
{cmd:stacked}() will clear all files with the file name specified in the {cmd:allsynth} option {cmd:keep}({it:file}) from the specified directory or from the working
directory if no directory is specified in {cmd:keep}({it:file}). Note also that the {allsynth} option {cmd:keep}({it:file}{cmd:, replace}) is required in {it:synth_options}
when {cmd:stacked}() is specified.

{p 8 8 2}Users may also specify additional {cmd:stacked}() options:{p_end}

{p 10 10 2}(1) {cmd:eventtime}({it:numlist}) must specify exactly two integers--one strictly negative, the other strictly positive--
which identify the event-time window over which the final results should be displayed and saved. No other symbols are allowed. Note that 
{cmd:eventtime}() will not restrict the period over which the pre-treatment MSPE is minimized (see {help synth}). {cmd:stacked}() will use whichever 
event window is smaller out of that specified in {cmd:eventtime}() and what is observed in any treated unit (or in a balanced sample across all 
treated units if the {cmd:balanced} option is specified. The default setting is the smaller of {cmd:eventtime}(-5 5) and the (possibly balanced) 
window observed over the treated units. 

{p 10 10 2}(2) {cmd:avgweights}({it:varname}) specifies a numeric variable that identifies the treated-unit weights to be used to calculated the 
(weighted) average treatment effects. For each treated unit {it:i} the weights must be non-missing and constant across all {it:timevar} periods.

{p 10 10 2}(3) {cmd:balanced} specifies that the estimated average treatment effects (gaps) should be displayed and saved only for those event periods 
in which {it:every} treated unit is observed. This ensures common interpretability of the estimated average gap across retained event periods (this 
is true even if the results are displayed and saved in calendar time).

{p 10 10 2}(4) {cmd:donorcond}({it:string} [, {it:string}]), {cmd:donorcond2}({it:string} [, {it:string}]), {cmd:donorcond3}({it:string} [, {it:string}]), 
and {cmd:donorcond4}({it:string} [, {it:string}]) permit users to temporarily modify the data while estimating all parameters associated with each 
treated unit {it:i}. This allows the user to set {it:i}-specific restrictions on the data for the purpose of restricting the donor pool for {it:i} 
to only those untreated units. {cmd:donorcond}(), ..., {cmd:donorcond4}() each permit a comma to separate two unique lines of code, such that up to 
eight total commands may be executed to set up the restriction of each of {it:i}'s donor pool units.

{p 10 10 2}(5) {cmd:donorif}({it:string}) permits users to specify a condition under which the untreated units should be kept in {it:i}'s donor pool. 
{cmd:donorif}({it:string}) imposes {it:keep if...} before {it:string} entry, so users {it:should not} include "{it:keep if...}" in {it:string}. 
{cmd:donorif}() only applies to untreated units, and treated unit {it:i} is always retained, so users should {it:not} specify 
{cmd:donorif}({it:string}) to condition on being an untreated unit.

{p 10 10 2}(6) {cmd:unique_w} specifies that only treated units {it:i} with unique estimated {it:W} matrices should be included in the estimated 
average treatment effect.

{p 10 10 2}(7) {cmd:sampleavgs}({it:real}) specifies an integer >=30 which is the number of placebo average gaps that should be sampled from the 
population of possibilities. The default setting is 100.

{p 10 10 2}(8) {cmd:figure}({cmd:classic}|{cmd:bcorrect} [ {cmd:placebos lineback}{cmd:, save}({it:file}) [{cmd:, replace} ]) {it:twoway_options} ]) 
can be used to automatically generate a plot of the trajectories of (at most two of) the estimated average gaps, average bias-corrected gaps, the 
set of placebo average gaps, or the set of average bias-corrected placebo gaps. It will plot these in the time type (calendar time or event time) 
of the estimates (see the entry for {cmd:eventtime}(), above). The bias-corrected gaps and placebo gaps can only be plotted if the {cmd:allsynth} 
option {cmd:bcorrect}() is specified, and the placebo gaps can only be plotted if the {cmd:allsynth} option {cmd:pvalues} is specified. {cmd:figure}() 
uses the same syntax as the {cmd:allsynth} option {cmd:gapfigure}(), but unlike {cmd:gapfigure}() it is possible to specify {cmd:figure}({cmd:classic placebos}) 
even if the {cmd:allsynth} option {cmd:bcorrect() is specified. As with {cmd:gapfigure}(), the plot can also be customized and saved. See the syntax 
for {cmd:gapfigure}() for further explanation of the syntax for {cmd:figure}().{p_end}

{p 4 4 2}
Regardless of whether any of the aforementioned additional options available with {cmd:allsynth} are specified, 
{cmd:allsynth} analyzes the {it:W} weighting matrix for (likely) uniqueness.
Warnings are produced if the {it:W} matrix is not sparse (if there is not at least one {it:w}-weight equal to zero)
or if the {it:W} matrix has more non-zero weights than predictor variables.


{title:Examples}

{p 4 4 2}
{cmd:Important note:} To use {cmd:allsynth} (and run these examples), the packages {cmd:synth} (type {cmd:ssc install synth}{cmd:, replace all}), 
{cmd:distinct} (type {cmd:ssc install distinct}), and {cmd:elasticregress} (type {cmd:ssc install elasticregress}) must be installed with the ancillary data.{p_end}

{p 4 4 2}
Examples 1-10 illustrate the use of {cmd: allsynth} when the {cmd: stacked()} option {it:is not} specified, making use of the {cmd:synth} ancillary data 
from {browse "https://www.tandfonline.com/doi/abs/10.1198/jasa.2009.ap08746":Abadie, Diamond and Hainmueller (2010)}.{p_end}

{p 4 4 2}
Examples 11-13 illustrate the use of {cmd: allsynth} when the {cmd: stacked()} option {it:is} specified, making use of {it:a subset of} the ancillary data 
from {browse "https://justinwiltshire.com/s/JustinCWiltshire_JMP.pdf":Wiltshire (2021)} and {browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf":Wiltshire (2022)}.{p_end}


{p 0 4 2}{cmd:Examples 1-10:}

{p 4 4 2}Load the example data from {browse "https://www.tandfonline.com/doi/abs/10.1198/jasa.2009.ap08746":Abadie, Diamond and Hainmueller (2010)}. 
This contains panel observations for 39 US states over the years 1970-2000:{p_end}
{p 8 4 2}{stata "use synth_smoking":use synth_smoking}{p_end}

{p 4 8 2}
Declare the dataset as a panel:{p_end}
{p 8 8 2}{stata "tsset state year":tsset state year}{p_end}

{p 4 8 2}
Example 1 - Use {cmd:allsynth} exactly as you would use {cmd:synth} to reconstruct the estimate from the {cmd:synth} help file (note: this is not
the exact specification used in Abadie, Diamond, and Hainmueller (2010)):{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989)}

{p 8 8 2}
This produces the same output as would have been produced if the {cmd:synth} command had been used in place of {cmd:allsynth}, as well as 
additional stored results in e(results), e(unique_W), and e(gaps). If {cmd:keep}({it:file}) had been specified, 
additional variables would also have been saved to {it:file}. {cmd:allsynth} additionally cautions that no bias correction or 
{it:p}-value calculations have been specified or provided.{p_end}

{p 4 8 2}
Example 2 - Use {cmd:allsynth} exactly as you would use {cmd:synth}:{p_end}
{phang}{stata allsynth cigsale beer retprice cigsale(1980), trunit(3) trperiod(1989)}

{p 8 8 2}
These results could also have been realized using the {cmd:synth} command in place of {cmd:allsynth}, but the reduction in dimensionality 
of the predictor variables (relative to Example 1) has resulted in the synthetic control optimization estimating a estimated {it:W} matrix 
with more non-zero weights than predictor variables, which is likely not unique. The produced output still includes what would have been produced 
if the {cmd:synth} command had been used in place of {cmd:allsynth}, as well as additional stored results in e(results), e(unique_W),
and e(gaps). Unlike {cmd:synth}, however, {cmd:allsynth} cautions that the estimated {it:W} matrix is likely not unique and suggests 
some ad hoc fixes.{p_end}

{p 4 4 2}
Example 3 - Calculate, display, and save the classic and the bias-corrected gaps between the treated unit outcome and the synthetic control outcome, and plot the 
bias-corrected outcome paths of the treated unit and its synthetic control:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) bcorrect(merge figure) keep(smokingresults) replace}

{p 8 8 2}
This example reproduces the estimation in Example 1, but as {cmd:bcorrect()} and its own {cmd:figure} option are specified, it also calculates
the classic and the (OLS regression estimated) bias-corrected gaps for each period (for the treated unit, 3, which is California), while plotting the bias-corrected outcome 
paths of the treated unit and its synthetic control. The classic results are saved in the working directory as {it:smokingresults.dta} as the {cmd:keep()} 
command is specified, and because {cmd:bcorrect(merge)} is also specified those results are merged and saved to the same file, and the variables 
_Y_treated and _Y_synthetic are replaced in this saved file by their bias-corrected values (meaningful only for calculating the bias-corrected gap). 
If {cmd:bcorrect(merge)} had instead been specified, _Y_treated and _Y_synthetic would have been left as their uncorrected values, and the bias-corrected
values would have been saved as _Y_treated_bc and _Y_synthetic_bc. The {cmd:replace} option is specified so {it:smokingresults.dta} 
can be saved even if the file already exists (it will be overwritten). {p_end}

{p 4 4 2}
Example 4 - Calculate, display, and save the classic and the bias-corrected gaps between the treated unit outcome and the synthetic control outcome,
and additionally plot the paths of the classic and bias-corrected gaps:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) bcorrect(merge) gapfigure(classic bcorrect) keep(smokingresults) replace}

{p 8 8 2}
This example reproduces the estimation in Example 3, but as {cmd:gapfigure()} and its own {cmd:classic} and {cmd:bcorrect} options are specified, 
it also plots the dynamic paths of the classic and the (OLS regression estimated) bias-corrected gaps against each other. 
Note how, in this case, the post-treatment bias-corrected gaps are smaller than those produced by classic synthetic control estimation.{p_end}

{p 4 4 2}
Example 5 - Calculate, display, and save the classic and the bias-corrected gaps between the treated unit outcome and the synthetic control outcome,
and additionally plot the paths of the classic and bias-corrected gaps with the dotted vertical line now indicating the treatment period immediately preceding treatment:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) bcorrect(merge) gapfigure(classic bcorrect lineback) keep(smokingresults) replace}

{p 8 8 2}
This example reproduces the estimation in Example 4, but as the {cmd:gapfigure()} option {cmd:lineback} is also specified, 
the dotted vertical line which by default indicates the specified treatment period (here, 1989) has now been moved to the period immediately
preceding the specified treatment period. This produces a figure analogous to Figure 3 in Abadie, Diamond and Hainmueller (2010), but with the bias-corrected outcome path also added 
(note: this is not the exact specification used in Abadie, Diamond, and Hainmueller (2010), which is why the classic outcome path differs slightly from Figure 3 in that paper). {p_end}

{p 4 4 2}
Example 6 - Calculate, display, and save the classic and the bias-corrected gaps between the treated unit outcome and the synthetic control outcome.
Plot the paths of the classic and bias-corrected gaps with the dotted vertical line now indicating the treatment period immediately preceding treatment. 
Estimate the bias using elastic net regression:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) bcorrect(merge elastic) gapfigure(classic bcorrect lineback) keep(smokingresults) replace}

{p 8 8 2}
This example reproduces the estimation in Example 5, but as the {cmd:bcorrect()} option {cmd:elastic} is also specified, the bias is estimated using elastic net regression instead of OLS.{p_end}

{p 4 4 2}
Example 7 - Calculate, display, and save the classic RMSPE-ranked {it:p}-values from in-space placebo runs, and plot the dynamic paths of 
classic gaps for the treated unit and for each of the donor pool units (placebo treated units), with the dotted vertical line indicating the period immediately preceding treatment:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) gapfig(classic placebos lineback) pval keep(smokingresults) rep}

{p 8 8 2}
This example reproduces the estimation in Example 1, also calculating and displaying, storing, and saving the RMSPE, RMPSE rank, and the 
{it:p}-values for the classic estimates (and saving the placebo estimates), and additionally plots the dynamic paths of the classic gaps for the treated unit and each donor pool unit,
with the dotted vertical line indicating the period immediately preceding treatment. This produces a figure analogous to Figure 4 in Abadie, Diamond and Hainmueller (2010)
(note: this is not the exact specification used in Abadie, Diamond, and Hainmueller (2010), which is why the classic outcome path differs slightly from Figure 4 in that paper).
Note that {cmd:pvalues} and {cmd:keep()} must be specified if {cmd:gapfigure(classic placebos)} is specified.{p_end}

{p 4 4 2}
Example 8 - Calculate, display, and save the classic RMSPE-ranked {it:p}-values from in-space placebo runs, and plot the dynamic paths of 
classic gaps for the treated unit and for each of the donor pool units (placebo treated units), with the dotted vertical line indicating the period immediately preceding treatment,
and with the pre-treatment mean of cigsale and retprice for each unit subtracted from those variable values in each period:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) gapfig(classic placebos lineback) pval trans(cigsale retprice, demean) keep(smokingresults) rep}

{p 8 8 2}
This example reproduces the estimation in Example 7 but with cigsale and retprice demeaned (adjusted given the pre-treatment mean of each variable for each unit) as {cmd:transform(cigsale retprice, demean)} is specified.{p_end}

{p 4 4 2}
Example 9 - Calculate, display, and save and the bias-corrected gaps between the treated unit outcome and the synthetic control outcome, for the
treated unit and also for each donor pool unit (placebo treatments), and calculate the RMSPE-ranked {it:p}-values. Plot the dynamic paths of 
bias-corrected gaps for the treated unit and for each of the donor pool units (placebo treated units), with the dotted vertical line now
indicating the period immediately preceding treatment:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) bcor(merge) gapfig(bcorrect placebos lineback) pvalues keep(smokingresults) replace}

{p 8 8 2}
This example reproduces the estimation in Example 3, but as {cmd:pvalues} is specified, it additionally estimates, saves, and stores the values for each unit in the 
donor pool (placebo runs) to calculate the RMSPE {it:p}-values. {cmd:Note} that while the classic gaps (the estimated marginal 
treatment effects from Abadie, Diamond and Hainmueller (2010)) are all highly statistically significant in all post-treatment periods 
(for each post-treatment year the RMSPE is larger than that of all the donor pool units), {it:the bias-corrected gaps are not significant} at the 10% level 
before 1994, and after that the {it:p}-values are only 0.077 (the RMSPEs are ranked third among 39 total runs rather than first). As {cmd:gapfigure()} and its own 
{cmd:bcorrect}, {cmd:placebos}, and {cmd:lineback} options are specified along with {cmd:bcorrect()}, it also plots the dynamic paths of the the (bias-corrected) 
gaps for the treated unit against those for each donor pool unit against each other in a figure, with the dotted vertical line indicating the period immediately preceding treatment.{p_end}

{p 4 4 2}
Example 10 - Calculate, display, and save and the bias-corrected gaps between the treated unit outcome and the synthetic control outcome, for the
treated unit and also for each donor pool unit (placebo treatments), and calculate the RMSPE-ranked {it:p}-values. Plot the bias-corrected gaps for the treated unit and for each of the donor pool units 
(placebo treated units) with the title "Ex 10", saving the graph as "ex10.pdf" with replacement:{p_end}
{phang}{stata allsynth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) bcor(merge) gapfig(bcorrect placebos, title(Ex10) save(ex10, replace)) pval keep(smokingresults) rep}

{p 8 8 2}
This example reproduces the estimation and plot from Example 9, but as {cmd:figure} is specified it also plots the classic outcome path for the treated unit and its synthetic control.
Because {cmd:bcorrect(figure)} is specified, it also plots the bias-corrected outcome path for the treated unit and its synthetic control. Note that all the option abbreviations are used.
This plot is the bias-corrected version of the figure (from Example 7) analogous to Figure 4 in Abadie, Diamond, and Hainmueller (2010). Note that specifying the {cmd:gapfigure()} option {cmd:lineback}
results in the dotted vertical line being placed in the period immediately preceding treatment on the other graphs, as well. Specifying the {cmd:gapfigure()} options {cmd:title(Ex10) save(ex10}{cmd:, replace)} 
after the comma adds the title "Ex10" and saves the graph as "{it:ex10.pdf}", replacing any existing file with the same name.{p_end}


{p 0 4 2}{cmd:Examples 11-13:}

{p 4 4 2}Load the example data from {browse "https://justinwiltshire.com/s/JustinCWiltshire_JMP.pdf":Wiltshire (2021)} and {browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf":Wiltshire (2022)}. 
This contains panel observations of 606 U.S. counties where Walmart tried to build a Supercenter over the years 1990-2005 (see {browse "https://justinwiltshire.com/s/JustinCWiltshire_JMP.pdf":Wiltshire (2021)} for details):{p_end}
{p 8 4 2}{stata "use allsynth_walmart":use allsynth_walmart}{p_end}

{p 4 8 2}
Declare the dataset as a panel:{p_end}
{p 8 8 2}{stata "tsset cty_fips year":tsset cty_fips year}{p_end}

{p 4 8 2}
See {browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf":Wiltshire (2022)} for discussion of the following examples without defining or calling
the macros (which is done to shorten the commands so that Stata's help file language (SMCL) will recognize them as interactive (clickable on a Windows system).

{p 4 8 2}
Define the first local macro of predictor variables (to allow the {cmd:allsynth} commands below to work interactively on a Windows system):{p_end}
{p 8 8 2}{stata local depvar_preds "emps_n10 emps_n10(1990) emps_n10(1991) emps_n10(1992) emps_n10(1990(1)1994) log_emps_n10(1990(1)1994) log_pe_salary_n10(1990(1)1994)"}{p_end}

{p 4 8 2}
Define the second local macro of predictor variables:{p_end}
{p 8 8 2}{stata local depvar_preds "`depvar_preds' log_emps_n44(1990(1)1994) log_pe_salary_n44(1990(1)1994) emps_shr_n44(1990(1)1994) pop_t(1990(1)1994)"}{p_end}

{p 4 8 2}
Define a new directory to store the output:{p_end}
{p 8 8 2}{stata capture mkdir "allsynth_walmart"}{p_end}


{p 4 4 2}
Example 11 - Calculate the "stacked" average treatment effects of Supercenter entry on aggregate county employment in Indiana only. 
Note that {cmd:trunit}({it:#}) and {cmd:trperiod}({it:#}) need not be defined because the {cmd:stacked}() option already requires variables that define these.{p_end}

{p 4 4 2}
First preserve the data so we can restrict it to only treated counties in Indiana and all donor pool counties, to speed up the run-time:{p_end}
{p 8 8 2}{stata preserve}{p_end}

{p 4 4 2}
Next, restrict the data to only the untreated counties and treated counties in Indiana:{p_end}
{p 8 8 2}{stata keep if supercenter == 0 | floor(cty_fips/1000) == 18}{p_end}

{p 4 4 2}
Estimate, display, and save the classic and bias-corrected average treatment effects (gaps) of Walmart Supercenter entry on employment in treated counties in Indiana, in percentage terms of
the employment in each county's final pre-treatment year:{p_end}
{phang}{stata allsynth `depvar_preds', transform(emps_n10, normalize) bcorrect(merge) keep(allsynth_walmart/employment, replace) stacked(trunits(supercenter) trperiods(super_year), clear figure(classic bcorrect))}

{p 8 8 2}
As {cmd:stacked}() is specified, this example estimates and plots the classic and bias-corrected average treatment effects of Walmart Supercenter entry on county employment in Indiana. 
The {it:supercenter} variable identifies with a 1 all the counties in Indiana which got their first Walmart Supercenter over this period, and identifies with a 0 all of the donor pool
counties in the sample where Walmart tried to build a Supercenter during this period but was blocked by local efforts. The {it:super_year} variable identifies (in every year) the year 
of Supercenter entry into the treated counties. Note that {cmd:, clear} is also specified within {cmd:stacked}(), as it is required (because all existing identically-named files are 
erased when {cmd:stacked}() is specified). The estimated average effects are in percentage terms as {cmd:transform}({cmd:employment, normalize}) was specified, which normalizes 
employment in in each treated county and its donor pool counties to the final pre-treatment period for that treated county. The results are displayed, stored, and saved in event time, 
as Indiana's counties were treated over several years. The classic and bias-corrected estimated average treatment effects are displayed on the graph, as the {cmd:stacked}() option
{cmd:figure}({cmd:classic bcorrect}) is specified.{p_end}

{p 4 4 2}
Example 12 - Calculate the stacked average treatment effects of Supercenter entry on aggregate county employment across the U.S. as in Wiltshire (2021), but without {it:p}-values. 
Note that the run-time for this example is 35 minutes using Stata MP on a Unix server.{p_end}

{p 4 4 2}
First restore the data to include all treated and all donor pool counties:{p_end}
{p 8 8 2}{stata restore}{p_end}

{p 4 4 2}
Next, define a macro with all non-{cmd:stacked}() specifications of {cmd:allsynth} to allow a focus on {cmd:stacked}(), and to allow the example to work interactively on a Windows system:{p_end}
{p 8 8 2}{stata local allsynth_specifications "`depvar_preds', transform(emps_n10, normalize) bcorrect(merge) keep(allsynth_walmart/employment, replace)"}{p_end}

{p 4 4 2}
And define a macro with the {cmd:donorcond}() and {cmd:donorif}() specifications of the {cmd:stacked}() option, to allow the example to work interactively:{p_end}
{p 8 8 2}{stata local donor_restrict "donorcond(sum czone if supercenter == 1, gen cz = r(mean)) donorif(czone != cz)"}{p_end}

{p 4 4 2}
Do as in Example 11, but for all U.S. counties which received their first Supercenter over this period. Weight the estimated effects by 1990 county population, and restrict to those
event years in which all treated counties are observed. Restrict the donor pool for each treated county to those donor pool counties in different commuting zones. Set the x-axis title
to "Event year", and save the graph as "ate.pdf" in the "allsynth_walmart" directory:{p_end}
{phang}{stata allsynth `allsynth_specifications' stacked(trunits(supercenter) trperiods(super_year), clear avgweights(pop_1990) balanced `donor_restrict' figure(classic bcorrect, save(allsynth_walmart/ate, replace) xtitle(Event year)))}

{p 8 8 2}
This example does as Example 11, but for all treated counties in the U.S. As {cmd:avgweights}({it:pop_1990}) is specified, the estimated average treatment effects will be calculated by
weighting the estimated marginal treatment effects of each treated county by their 1990 populations. As {cmd:balanced} is specified, the displayed, saved, and plotted estimates will be
restricted to those event years in which all treated units are observed (in this case, {cmd:balanced} does nothing as the sample is already balanced over event years {it:e}=[-5,5]). As
{cmd:donorcond}(sum czone if supercenter == 1, gen cz = r(mean)) {cmd:donorif}(czone != cz) is specified, the donor pool for each treated unit will be restricted to only those donor pool 
counties in other commuting zones. As {cmd:, save}(allsynth_walmart/ate, replace) is specified, the generated plot of classic and bias-corrected estimated average treatment effects will
be saved to allsynth_walmart/ate.pdf and will replace any existing file of the same name. As {cmd:xtitle}(Event year) is specified, the x-axis title will be changed to "Event year".{p_end}

{p 4 4 2}
Example 13 - Do as Example 12, but estimate RMSPE-ranked {it:p}-values and generate the plot for the bias-corrected estimated ATE and 1000 sampled placebo average gaps, as in Wiltshire (2021). 
Note that this example takes over 24 hours to run using Stata MP on a Unix server.{p_end}
{phang}{stata allsynth `allsynth_specifications' pvalues stacked(trunits(supercenter) trperiods(super_year), clear avgweights(pop_1990) balanced sampleavgs(1000) `donor_restrict' figure(bcorrect placebos, save(allsynth_walmart/ate, replace)))}

{p 8 8 2}
This example does as Example 12, but also calculated the RMSPE-ranked {it:p}-values as {cmd:pvalues} is specified. As {cmd:sampleavgs}(1000) is specified, these will be based on 1000 
randomly sampled placebo average gaps. The "Event year" title on the x-axis (from Example 12) is dropped, and as {cmd:figure}(bcorrect placebos) is specified, the generated plot will show the 
bias-corrected estimated average treatment effect and the sampled placebo average gaps.{p_end}

{title:References}

{p 4 8 2}
Abadie, A., and J. L'Hour, 2021. A Penalized Synthetic Control Estimator for Disaggregated Data. {it:Journal of the American Statistical Association}, 116(536): 1817-1834.

{p 4 8 2}
Abadie, A., Diamond, A., and J. Hainmueller, 2010. Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program.
{it: Journal of the American Statistical Association}, 105(490): 493-505.

{p 4 8 2}
Abadie, A., Diamond, A. and J. Hainmueller, 2015. Comparative politics and the synthetic control method. {it:American Journal of Political Science}, 59(2): 495-510.

{p 4 8 2}
Dube, A. and Ben Zipperer, 2015. Pooling multiple case studies using synthetic controls: An application to minimum wage policies. {it: Institute for the Study of Labor (IZA) Discussion Papers 8944}.

{p 4 8 2}
Ben-Michael, E., Feller, A. and J. Rothstein, 2021. The Augmented Synthetic Control Method. {it:Journal of the American Statistical Association}, 116(536): 1789-1803.

{p 4 8 2}
Wiltshire, J.C., 2021. Walmart Supercenters and Monopsony Power: How a Large, Low-Wage Employer Impacts Local Labor Markets. {it:Working paper}.

{p 4 8 2}
Wiltshire, J.C., 2022. allsynth: (Stacked) Synthetic Control Bias-Correction Utilities for Stata. {it:Working paper}.


{marker citation}{...}
{title:Citation of allsynth}

{pstd}{opt allsynth} is user-written command made freely-available to the research community. Please cite the associated paper: {p_end}

{phang}Wiltshire, J.C., 2022.
allsynth: (Stacked) Synthetic Control Bias-Correction Utilities for Stata. {it:Working paper}.
{browse "https://justinwiltshire.com/s/allsynth_Wiltshire.pdf"}.


{title:Author}

	Justin C. Wiltshire, jcwiltshire@ucdavis.edu
	University of California, Davis

{p 8 8 2}
{cmd:Acknowledgement}: In addition to directly utilizing the {cmd:synth} package, the code for {cmd:allsynth} draws unapologetically on Jens Hainmueller's code from the original {cmd:synth} package. This is an explicit acknowledgement of that fact.
	
