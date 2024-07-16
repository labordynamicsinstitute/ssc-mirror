{smcl}
{* *! version November 2, 2023 @ 12:29:16 UK}{...}
{* link to manual entries (really meant for stata to link to its own docs}{...}
{vieweralsosee "[R] regress" "mansection R regress"}{...}
{vieweralsosee "[ME] mixed" "mansection R mixed"}{...}
{vieweralsosee "[D] statsby" "mansection D statsby"}{...}
{viewerjumpto "Syntax" "twostep##syntax"}{...}
{viewerjumpto "Description" "twostep##description"}{...}
{viewerjumpto "avplot - Macro AV-Plot" "twostep##avplot"}{...}
{viewerjumpto "cprplot - Macro CPR-Plot" "twostep##cprplot"}{...}
{viewerjumpto "dot - Dot Chart" "twostep##dot"}{...}
{viewerjumpto "edv - EDV Model" "twostep##edv"}{...}
{viewerjumpto "microcpr - Micro CPR-Plot" "twostep##microcpr"}{...}
{viewerjumpto "microdfb - Micro CPR-Plot" "twostep##microdfb"}{...}
{viewerjumpto "regby - Regression by Groups" "twostep##regby"}{...}
{viewerjumpto "mk2nd - Make Macro Data" "twostep##mk2nd"}{...}
{viewerjumpto "Acknowledgements" "twostep##acknowledgements"}{...}
{viewerjumpto "Author" "twostep##author"}{...}
{viewerjumpto "References" "twostep##references"}{...}

{title:Title}

{phang}
{cmd:twostep} {hline 2} Two-step multilevel analysis
{p_end}

{marker syntax}

{title:Syntax}

{pstd}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid}
 [{cmd:,}
 {it:twostep-options}
 ]{cmd::}
 {it:microcmd}
 {cmd:||}
 {it:macrocmd}
{p_end}

{pstd}
{it:microcmd} may be an estimation command such as {help regress}, {help logit}, etc., or 
{p_end}

{p 8 16 2}
 {cmd:microcpr}
 {depvar}
 {indepvars}
 {ifin}
 {weight}
 {p_end}

{p 8 16 2}
 {cmd:microdfb}
 {depvar}
 {indepvars}
 {ifin}
{p_end}

{pstd}
{it:macrocmd} may be one of the following special purpose commands 
{p_end}

{p 8 16 2}
 {cmd:avplot}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: avplot-options} ]
{p_end}

{p 8 16 2}
 {cmd:dot}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: dot-options} ]
{p_end}

{p 8 16 2}
 {cmd:edv}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: edv-options} ]
{p_end}

{p 8 16 2}
 {cmd:cprplot}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: cprplot-options} ]
{p_end}

{p 8 16 2}
 {cmd:regby}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: regby-options} ]
{p_end}

{p 8 16 2}
 {cmd:mk2nd}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: mk2nd-options} ]
{p_end}

{p 8 16 2}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
 [ {cmd:using} {help filename} ]
 [, {it: microcpr-options} | {it: microdfb-options} ]
{p_end}

{pstd}
or an arbitrary Stata command with the syntax
{p_end}

{p 8 16 2}
 {cmd:cmd}
 {help twostep##macrodepvar:macrodepvar} {help twostep##macroindepvars:macroindepvars}
 {ifin}
 [, {it: options} ]
{p_end}

{pstd} The latter utilization will be referred to as "fallback mode" in the
following.
{p_end}

{* the new Stata help format of putting detail before generality}
{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:avplot-options}
{synopt:{opt method(arg)}}Options allowed for the EDV-model {help twostep##edv:twostep edv}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:cprplot-options}
{synopt:{opt method(arg)}}Options allowed for the EDV-model {help twostep##edv}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway lowess}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:dot-options}
{synopt:{opt ci:opts(options)}}Options allowed for {help twoway rcap}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:edv-options}
{synopt:{opt method(arg)}}Method for macro-level estimation{p_end}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:microcpr-options}
{synopt:{opt all:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt by:opts(options)}}Options allowed for {help by_option:graph, by()}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway lowess}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:microdfb-options}
{synopt:{opt box(options)}}Options allowed for {help barlook_options}{p_end}
{synopt:{opt marker(options)}}Options allowed for {help marker_options} and {help marker_label_options}{p_end}
{synopt:{it:boxlook_options}}Boxlook options of {help graph box}{p_end}
{synopt:{it:over_options}}Over sub_opts of {help graph box##over_subopts}{p_end}
{synopt:{it:other_options}}Some other options of {help graph box}{p_end}
{syntab:regby-options}
{synopt:{opt all:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt by:opts(options)}}Options allowed for {help by_option:graph, by()}{p_end}
{synopt:{opt di:screte(varlist)}}Treat macro-level vars as discrete{p_end}
{synopt:{opt nq:uantiles(#)}}Grouping for macro-level varlist{p_end}
{synopt:{opt reg:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt u:nitby(varlist)}}Additional grouping on micro-level varlist{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:mk2nd-options}
{synopt:{opt clear}}preexisting data will be be replaced{p_end}
{syntab:twostep-options}
{synopt:{opt stats(namelist)}}Additional stats for macro-level{p_end}
{synoptline}
{p2colreset}

{p 4 6 2}{it:macroid} refers to a {varlist} identifying macro-level
units in the dataset in memory. Both {depvar} and {indepvars} refer to
variables in the dataset in memory. {help twostep##macrodepvar:macrodepvar} refers to
an implied name of regression coefficients or other model statistics
(see below). {help twostep##macroindepvars2:macroindepvars} refer to the names of
macro-level variables. Both {it:indepvars} and {it:macroindepvars} may
contain factor variables; see {help fvvarlist}.{p_end}

{p 4 6 2}{marker macrodepvar}{it:macrodepvar} is either an implied name
of an estimated regression coefficient or of a summary statistic. The implied name
of the estimated regression coefficients is specified by adding {cmd:_b_} before
the name of the variable of interest in {indepvars}. In case of factor
variables one must add {cmd:_b_#_} with # referring to the category of
the respective variable. We suggest using {cmd:twostep ... || mk2nd _all}
for checking the implied coefficient names in case of factor
variables with interactions. Other model statistics may be specified by adding
the statistics names with the prefix {cmd:_stat_}.
The statistic must have been specified in the twostep-option
{cmd:stats(}{it:name}{cmd:)}.{p_end}

{p 4 6 2}{marker macroindepvars}{it:macroindepvars} are macro-level
variables. The variables must be constant within
{it:macroid}. Moreover the variables must exist, either in the pooled
micro-level data in memory or in the file specified by {cmd:using}. {p_end}

{p 4 6 2}{cmd:using} {it:filename} refers to a dataset holding
macro-level variables. In this dataset, {it:macroid} must uniquely
identify the observations. If {cmd:using} is not specified, the
macro-level variables must exist in the dataset in memory.{p_end}

{p 4 6 2}{cmd:weight}s are allowed for {it:microcmd} if the estimation command
being used allows weights. In the case of {cmd:microcpr}, {cmd:fweight}s,
{cmd:aweight}s and {cmd:pweight}s are allowed; see help {help weight}.
{cmd:weight}s are not allowed for {cmd:microdfb} and for any {it:macrocmd}.{p_end}

{marker description}
{title:Description}

{pstd}{cmd:twostep} is a bundle of programs intended to ease multilevel
analysis with the two-step approach. The two-step approach to multilevel
analysis involves estimating a parameter of interest in a micro-level
dataset (e.g. individuals) separately for each category of a macro
level variable (e.g. countries, states, schools, etc.). The two-step
approach can be used as an alternative to one-step approaches that
estimate all parameters in a pooled dataset taking into account the
hierarchical structure of the data (e.g. cluster-robust standard
errors, fixed- and random intercept models, or multilevel
mixed-effects regression). The two-step approach offers an
attractive alternative to the one-step approach if the number of
observations at the macro-level is small (e.g. < 50) and the number of
micro-level observations within each macro-level unit is large (see Achen
{help twostep##achen05:2005}). Additionally, it may be used for 
exploratory data analysis of multilevel data, for graphical display of
modeling results, or to check model assumptions of the one-step approach. {p_end}

{pstd}Most of the methods implemented in {cmd:twostep} are wrappers
for a series of standard Stata commands. The idea of {cmd:twostep} is
to offer several related methods with very similar commands to ease
analyzing hierarchical data interactively. {p_end}

{pstd}The following examples highlight the consistent design of
{cmd:twostep} using a subset of the forth round of the European
Quality of Life Survey (EQLS). The EQLS is a survey based on probability
samples of respondents from all European Union member countries and
hence a typical example of an international comparative dataset. A
special feature of the EQLS is that it also contains a number of macro-level 
variables in the micro-level dataset. The following examples
use gdppcap, i.e. the gross-domestic-product in purchasing power
parities, as the macro-level characteristic. {p_end}

{pstd}{cmd:twostep} provides the following procedures: {p_end}

{p 4 6 4}o {it:Estimated-Dependent-Variable Model} (EDV-Model) as
described e.g. by Lewis and Linzer ({help twostep##lewis05:2005}). In this
model, the estimated regression coefficients of models fitted
separately for each macro-level unit using the micro-level data are
fed into a linear regression at the macro-level as dependent variable. 
The macro-level regression is weighted by an inverse function
of the uncertainty of the model estimates. For example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || edv _b_hhinc gdppcap"}{p_end}

{p 6 6 4}estimates an EDV-model regressing the micro-level coefficients
for hhinc (household income) on the macro-level variable gdppcap
(the gross domestic product per capita). See section {help "twostep##edv":EDV-model} for variants of the EDV-model.

{p 4 6 4}o {it:Horizontally labeled dot charts of coefficients} with
confidence intervals as shown by Bowers and Drake ({help twostep##bowers05:2005}, figure
1). For example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc gdppcap"}{p_end}

{p 6 6 4}creates a plot of all estimated micro-level coefficients for
hhinc in a dot chart, where the coefficients are sorted by the field
rank of the macro-level variable gdppcap. See section
{help "twostep##dot":Dot chart} for variants of this plot.{p_end}

{p 4 6 4}o {it:Component-plus-residual plots} for all micro-level
models. This plot is a straightforward generalization of the
multivariate scatter plots proposed by Bowers and Drake
({help "twostep##bowers05":2005}, figure 2). For example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: microcpr lsat hhinc i.sex || _b_hhinc gdppcap"}{p_end}

{p 6 6 4}creates the component-plus-residual plots of the coefficient
for hhinc for each macro-level unit (i.e. country). Every plot
shows the regression line for all observations in comparison to
regression lines and non-parametric regression lines (LOWESS) for the
respective macro-level unit. The plots are sorted by the
field rank of the macro-level variable gdppcap. See section
{help "twostep##microcpr":microcpr} for variants of this plot. Also see
{help cprplot} for a general description of the component-plus-residual plot.

{p 4 6 4}o {it:Box plots for DFBETAs} of a specified micro-level
covariate for all micro-level models. This plot is usefull to
detect influential data points in the micro-level regressions. For
example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: microdfb lsat hhinc i.sex || _b_hhinc gdppcap"}{p_end}

{p 6 6 4}creates box plots of the DFBETAs for the coefficient of hhinc
for each macro-level unit (i.e. country). The plots are sorted by the
field rank of the macro-level variable gdppcap. See section {help "twostep##microdfb":microdfb} for variants of this plot. Also see
{help dfbeta} for a general description of the
DFBETAs.{p_end}

{p 4 6 4}o {it:Added-variable plots} for the EDV regression
models. This plot is a straightforward application
of the standard added-variable plot for the EDV-model. For example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || avplot _b_hhinc gdppcap"}{p_end}

{p 6 6 4} creates an added-variable plot for the EDV-model
estimated above. 
See section {help "twostep##avplot":avplot} for variants of this
plot. Also see
{help avplot} for a general description of the added-variable plot plot. {p_end}

{p 4 6 4}o {it:Component-plus-residual plots} for the EDV regression
models. This plot is a straightforward application
of the standard component-plus-residual plot for the EDV-model. For example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || cprplot _b_hhinc gdppcap"}{p_end}

{p 6 6 4} creates a component-plus-residual plot for the EDV-model
estimated above. The plot contains the regression line as well as a
non-parametric regression line (LOWESS). See section 
{help "twostep##cprplot":cprplot} for variants of this plot.{p_end}

{p 4 6 4}o {it:Plots of grouped predictions of micro-level models} as
proposed by Bowers and Drake ({help "twostep##bowers05":2005}, figure
3) -- we call this a "regby plot" in the following. For example,
{p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || regby _b_hhinc gdppcap"}{p_end}

{p 6 6 4} uses a regby plot to show regression lines based on the
coefficient of hhinc for the micro-level regressions calculated
separately for all macro-level units. Macro-level units
are grouped into categories derived from the macro-level variable
gdppcap. See section {help "twostep##regby":regby} for
variants of this plot.{p_end}

{p 4 6 4}o {it:Distributional diagnostic plots} for the estimated
regression coefficients of the micro-level regression models. These
plots are particularly useful to inspect the distributional
assumptions for random intercept and/or random-effects (mixed-)models. For
example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || pnorm _b_hhinc"}{p_end}

{p 6 6 4} creates a standardized normal plot for the estimated regression 
coefficients of hhinc. Instead of {help pnorm} all commands described in 
{help diagnostic plots} can be used. {p_end}

{p 4 6 4}o {it:Fallback mode:} Besides the methods described,
{cmd:twostep} has a fallback mode that allows the specification of
arbitrary Stata commands for analyzing the micro-level regression
coefficients (or other model statistics) at the macro-level. For example,
{p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || summarize _b_hhinc, detail"}{p_end}

{p 6 6 4} calculates the mean and standard deviation of the
micro-level regression coefficients for hhinc. The fallback mode
assumes that the Stata command corresponds to a standard syntax with a
{varlist} immediately following the command. The first variable
of {varlist} must be {help twostep##macrodepvar:macrodepvar}. {p_end}

{p 4 6 4}o {it:Creation of macro-level dataset} As a second fallback
mode, {cmd:twostep} can be utizlized for creating a macro-level dataset
holding regression coefficients of the micro-level regressions. This is
useful for two-step multilevel analyses that cannot be
performed with any of the implemented methods. For example, {p_end}

{p 6 6 4}. {stata "use eqls2003_twostep, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || mk2nd _all gdppcap"}{p_end}

{p 6 6 4} creates a dataset holding {it:all} the macro-unit specific micro
level regression coefficients, their standard errors and the macro
level variable gdppcap. The standalone command {cmd:edv} can 
be used for estimating an EDV-model for each of the coefficents,
including the constant: {p_end}

{p 6 6 4}. {stata "edv _b_cons gdppcap"}{p_end}
{p 6 6 4}. {stata "edv _b_hhinc gdppcap"}{p_end}
{p 6 6 4}. {stata "edv _b_2_sex gdppcap"}{p_end}

{pstd} The following description of procedures is arranged in
alphabetical order. {p_end}

{marker avplot}
{title:Macro-level added-variable plot}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid} {cmd::} {it:microcmd}
 {depvar} 
 {indepvars} [, {it:micro-options}] {cmd:||} 
 {cmd:avplot}
 {help twostep##macrodepvar:macrodepvar} 
 {help twostep##macroindepvars:macroindepvars}
 [ {cmd:using} {help filename} ]
 [, {it:macro-options} ]
{p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:micro-options}
{synopt:{it:regress options}}Options allowed for {it:microcmd}{p_end}
{syntab:macro-options}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used to specify the outcome of an EDV-model
and {help twostep##macroindepvars:macroindepvars} is used to specify the independent variables of an
EDV-model. The first variable of {help twostep##macroindepvars:macroindepvars} defines the
variable for which the added-variable plot is drawn. {p_end}

{marker avplotoptions}
{title:avplot options}

{phang}{opt scopts(options)} defines the appearance of the symbols for the
macro-level observations. {it:options} can be any of the options
allowed for {cmd:twoway scatter}. Among these options,
{cmd:msymbol()}, {cmd:msize()}, and {cmd:mcolor()} may be particularly
useful. {p_end}

{phang} {opt regopts(options)} defines the appearance of the regression
line. {it:options} can be any of the options allowed for
{cmd:twoway line}. Among these options, {cmd:lcolor()}, {cmd:lwidth()}, and
{cmd:msize()} may be particularly useful. {p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker avplotexamples}
{title:avplot examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || avplot _b_hhinc gdppcap"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex age [pw=wght] || avplot _b_hhinc gdppcap urbanpop"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || avplot _b_hhinc gdppcap, regopts(lcolor(none))"}{break}
removes the linear fit from the graph.
{p_end}

{marker cprplot}
{title:Macro-level component-plus-residual plot}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid} {cmd::} {it:microcmd}
 {depvar} 
 {indepvars} [, {it:micro-options}] {cmd:||} 
 {cmd:cprplot}
 {help twostep##macrodepvar:macrodepvar} 
 {help twostep##macroindepvars:macroindepvars}
 [ {cmd:using} {help filename} ]
 [, {it:macro-options} ]
{p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:micro-options}
{synopt:{it:regress options}}Options allowed for {it:microcmd}{p_end}
{syntab:macro-options}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway lowess}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used to specify the outcome
and {help twostep##macroindepvars:macroindepvars} is used to specify the independent variables of an
EDV-model. The first variable of {it:macroindepvars} defines the
variable for which the component-plus-residual plot is shown. {p_end}

{marker cprplotoptions}
{title:cprplot options}

{phang}{opt scopts(options)} defines the appearance of the symbols for the
macro-level observations. {it:options} can be any of the options
allowed for {cmd:twoway scatter}. Among these options,
{cmd:msymbol()}, {cmd:msize()}, and {cmd:mcolor()} may be particularly
useful. {p_end}

{phang} {opt regopts(options)} defines the appearance of the regression
line. {it:options} can be any of the options allowed for
{cmd:twoway line}. Among these options, {cmd:lcolor()}, {cmd:lwidth()}, and
{cmd:msize()} may be particularly useful. {p_end}

{phang} {opt lowess(options)} defines the appearance of the lines for the
non-parametric regression line. {it:options} can be any of the options
allowed for {cmd:twoway line}. Among these options, {cmd:lcolor()},
{cmd:lwidth()}, and {cmd:msize()} may be particularly useful. {p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker cprplotexamples}
{title:cprplot examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || cprplot _b_hhinc gdppcap"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || cprplot _b_hhinc gdppcap urbanpop"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || cprplot _b_hhinc gdppcap, regopts(lcolor(none))"}{break}
erases the linear fit from the graph.
{p_end}

{marker dot}
{title:Dot-chart}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid} [, {it:twostep-options} ] {cmd::} {it:microcmd}
 {depvar} 
 {indepvars} [, {it:micro-options}] {cmd:||} 
 {cmd:dot}
 {help twostep##macrodepvar:macrodepvar} 
 [ {help twostep##macroindepvars:macroindepvars} ]
 [ {cmd:using} {help filename} ]
 [, {it:macro-options} ]
{p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:twostep}
{synopt:{opt stats(namelist)}}Additional model statistics{p_end}
{syntab:micro-options}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:macro-options}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{opt ci:opts(options)}}Options allowed for {help twoway rcap}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used to specify the coefficient (or statistic)
to be shown in the dot-chart. {help twostep##macroindepvars:macroindepvars} is used to
define the order used for the vertical axis of the chart. {p_end}

{marker dotoptions}
{title:dot options}

{phang}{opt stats(namelist)} defines the model statistics to be stored
together with the model coefficients. {it:names} can be any scalar
stored by the estimation command used for the micro-level
regression. For example, to store the R-square of a
linear regression model, use {cmd:stats(r2)}. {p_end}

{phang}{opt scopt(options)} defines the appearance of the dots. {it:options}
can be any of the options allowed for {cmd:twoway scatter}. Among
these options, {cmd:msymbol()}, {cmd:msize()}, and
{cmd:mcolor()} may be particularly useful. {p_end}

{phang} {opt ciopt(options)} defines the appearance of the confidence
intervals (if present). {it:options} can be any of the options allowed for
{cmd:twoway rcap}. Among these options, {cmd:lcolor()},
{cmd:lwidth()}, and {cmd:msize()} may be particularly useful. {p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker dotexamples}
{title:dot examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc gdppcap"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc gdppcap, scopts(mcolor(red) ms(S)) ciopts(lwidth(0))"}{break}
just to show how {cmd:scopts()} and {cmd:ciopts()} work.

{phang}. {stata "twostep cntry, stats(r2): regress lsat hhinc i.sex || dot _stat_r2"}{break}
to show R-squared instead of coefficients.
{p_end}

{phang}. {stata "twostep cntry, stats(r2): regress lsat hhinc i.sex || dot _stat_r2, title(R{superscript:2} by country) xtitle(R{superscript:2}) ysize(5) "} {break}
an example with twoway options.
{p_end}

{marker edv}
{title:EDV-model}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid} {cmd::} {it:microcmd}
 {depvar} 
 {indepvars} [, {it:micro-options}] {cmd:||} 
 {cmd:edv}
 {help twostep##macrodepvar:macrodepvar} 
 {help twostep##macroindepvars:macroindepvars}
 [ {cmd:using} {help filename} ]
 [, {it:macro-options} ]

{pstd}or{p_end}

{p 8 16 2}
 {cmd:edv}
 {help twostep##macrodepvar:macrodepvar}
 {help twostep##macroindepvars:macroindepvars}
 [, {it:macro-options} ]

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:micro-options}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:macro-options}
{synopt:{opt method(arg)}}One of ols, wls, fgls1, fgls2{p_end}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used to specify the outcome of an EDV-model
and {help twostep##macroindepvars:macroindepvars} is used to specify the independent variables of an
EDV-model. {p_end}

{pstd}{ul:Technical Note:} In addition to {cmd:regress}, {cmd:twostep}
allows a variation estimation commands for {it:microcmd}. Hence, it is
technically possible to run the EDV-model on micro-level regression
coefficients of {cmd:logit}, {cmd:probit}, {cmd:xtreg} or
other. Since the statistical properties of the EDV-model have only
been shown for linear regression, {cmd:twostep} issues a warning
message when the micro-level command is not {cmd:regress}. 
{p_end}

{marker edvoptions}
{title:edv Options}

{phang}{opt method(name)} defines the function used to weight the
observations in the EDV-model. {cmd:name} can be any of 
{cmd:fgls1} (default), {cmd:fgls2}, {cmd:ols}, and {cmd:wls}.{p_end}

{pmore}{cmd:fgls1} weights the observations using the FGLS approach
proposed by Hanushek ({help twostep##hanushek94:1974}); also see Lewis
and Linzer ({help twostep##lewis05:2005}:351-352). This is the default
if {opt method()} is not specified.{p_end}

{pmore}{cmd:fgls2} weights the observations using the FGLS approach
proposed by Lewis and Linzer ({help twostep##lewis05:2005}:352-354).{p_end}

{pmore}{cmd:ols} does not apply weights to the second level
regression; Bryan and Jenkins ({help twostep##bryan16:2016}:footnote
4) recommend this; also see Donald and Lang
({help twostep##donald07:2007}: 223-224). {p_end}

{pmore}{cmd:wls} weights the observations by the reciprocal value of
the regression coefficient's variance, as proposed by Saxonhouse
({help twostep##saxonhouse76:1976}).{p_end}

{phang}{opt regress option} options allowed for {help regress}.{p_end}

{marker edvexamples}
{title:edv examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || edv _b_hhinc gdppcap"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc age if sex == 1 || edv _b_hhinc gdppcap if !mi(eu15)"}{break}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || edv _b_hhinc gdppcap, method(ols) vce(robust)"}{break}
to regress _b_hhinc on gdppcap without any weights at all
{p_end}

{marker microcpr}
{title:Micro-level component-plus-residual plot}

{pstd}{it:Component-plus-residual plots} for all micro-level
regression models are created with the micro-level command
{cmd:microcpr}. The general syntax is: {p_end}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid}
 {cmd:}
 {cmd:: microcpr} {depvar}
 {indepvars}
 [, {it:micro-options} ]
 {cmd:||}
 {help twostep##macrodepvar:macrodepvar} 
 {help twostep##macroindepvars:macroindepvars} 
[ {cmd:using} {help filename} ]
 [, {it:macro-options} ]
{p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:micro-options}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:macro-options}
{synopt:{opt all:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used here to specify
the name of the micro-level independent variable for
which the component-plus-residual plot is drawn.
{help twostep##macroindepvars:macroindepvars} is used to specify the order
of the plots. {p_end}

{pstd}{ul:Note:} With {cmd:microdfb},  twostep is used without a macro-level command.{p_end}

{marker microcpr-options}
{title:microcpr options}

{phang} {opt allopts(options)} defines the appearance of regression line
for all micro-level models. {it:options} can be
any of the options allowed for {cmd:twoway line}. Among these options,
{cmd:lcolor()}, and {cmd:lwidth()} may be particularly
useful. {p_end}

{phang} {opt regopts(options)} defines the appearance of macro specific
regression lines. {it:options} can be any of the options allowed for
{cmd:twoway line}. Among these options, {cmd:lcolor()}, and
{cmd:lwidth()} may be particularly usefull. {p_end}

{phang} {opt lowessopts(options)} defines the appearance of macro specific
LOWESS lines. {it:options} can be any of the options allowed for
{cmd:twoway line}. Among these options, {cmd:lcolor()}, and
{cmd:lwidth()} may be particularly useful. {p_end}

{phang}{opt scopt(options)} defines the appearance of the dots. {it:options}
can be any of the options allowed for {cmd:twoway scatter}. Among
these options, {cmd:msymbol()}, {cmd:msize()}, and
{cmd:mcolor()} may be particularly useful. {p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker microcprexamples}
{title:microcpr examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: microcpr lsat hhinc i.sex || _b_hhinc"}

{phang}. {stata "twostep cntry: microcpr lsat hhinc i.sex || _b_hhinc gdppcap, scopts(ms(i)) allopts(lwidth(0))"}{break}
to show macro specific regression and LOWESS lines, only.
{p_end}

{marker microdfb}
{title:DFBETA box plots for micro-level regression}

{pstd}{it:Box plots of DFBETAs} for all the micro-level
regression models are shown with the micro-level command
{cmd:microdfb}. The general syntax is: {p_end}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid}
 {cmd:} 
 {cmd:: microdfb} {depvar}
 {indepvars}
 [, {it:micro-options} ]
 {cmd:||}
 {help twostep##macrodepvar:macrodepvar} 
 {help twostep##macroindepvars:macroindepvars} 
[ {cmd:using} {help filename} ]
 [, {it:macro-options} ]
{p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:micro-options}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:macro-options}
{synopt:{opt box(options)}}{help barlook_options}{p_end}
{synopt:{opt marker(options)}}{help marker_options} and {help marker_label_options}{p_end}
{synopt:{it:boxlook_options}}Boxlook options of {help graph box}{p_end}
{synopt:{it:other_options}}Additional options for {help graph box}{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used here to specify
the name of the independent variable of the micro-level models for
which the box plots of DFBETAs are drawn.
{help twostep##macroindepvars:macroindepvars} is used to specify the order
of the plots. {p_end}

{pstd}{ul:Note:} With {cmd:microdfb},  twostep is used without macro-level command.{p_end}

{marker microdfb-options}
{title:microdfb options}

{phang}{opt box(option)} defines the appearance of the boxes. Any options
described in {help barlook_options} can be used. {p_end}

{phang} {opt marker(options)} defines the appearance of the marker for the
outliers. Any of the options described in {help marker_options} and
{help marker_label_options} can be used. {p_end}

{phang} {opt boxlook_options} are any other of the boxlook_options
described in {help graph_box}, except {cmd:box}. {p_end}

{phang} {opt other_options} are some but not all of the options
described in {help graph_box}. Technically, {cmd:twostep} passes all
options invoked to the box-plot. Some of the options, however, may be
in conflict with the current settings. In that case they ma either be ignored or
an error message will be issued. {p_end}

{marker microdfbexamples}
{title:microdfb examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: microdfb lsat hhinc i.sex || _b_hhinc"}{p_end}

{phang}. {stata "twostep cntry: microdfb lsat hhinc i.sex || _b_hhinc, marker(mlab(id) mlabpos(12))"}{break}
to label the outliers. 
{p_end}

{marker regby}
{title:Regby plot}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid}{cmd::} {it:microcmd} {depvar}
 {indepvars} [, {it:micro-options}] {cmd:||}
 {cmd:regby}
 {help twostep##macrodepvar:macrodepvar} 
 {help twostep##macroindepvars:macroindepvars} 
 [ {cmd:using} {help filename} ]
 [, {it:macro-options} ]
{p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:micro-options}
{synopt:{it:regress options}}Options allowed for {it:microcmd}{p_end}
{syntab:macro-options}
{synopt:{opt all:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt by:opts(options)}}Options allowed for {help by_option:graph, by()}{p_end}
{synopt:{opt di:screte(varlist)}}Treat macro-level vars as discrete}{p_end}
{synopt:{opt nq:uantiles(#)}}Grouping for macro-level varlist{p_end}
{synopt:{opt reg:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt u:nitby(varlist)}}Additional grouping on micro-level varlist{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used to specify the
name of the coefficients used to define the slopes to be shown.
{help twostep##macroindepvars:macroindepvars} is used to define the
groups into which the specified macro-level units are grouped into. {p_end}

{marker regbyoptions}
{title:regby options}

{phang}{opt all:opts(options)} defines the appearance of the lines in the
background of the sub-graphs. By default, {it:regby} draws a
background graph showing the regression line for {it:all}
macro-level units. This is intended to ease the comparison of each
subgroup with the other groups. However, the background graph can be considered a
nuisance in some situations and perhaps also is a matter of
taste. The background options allows the user to fine tune the
background graph, including a complete removal. {it:options} can be
any of the options listed in {help line option}. Specify
{cmd:allopts(lcolor(none))} to remove the background graph. {p_end}

{phang}{opt by:opts(options)} is used to define the overall
arrangement of the regby plot. {it:options} can be any of the
options allowed for {help graph by}. Among these options,
{cmd:rows(#)}, {cmd:cols(#)}, and {cmd:compact} may be particularly
useful. We stress that the overall titles, subtitles, notes, and
captions should be specified here.{p_end}

{phang}{opt di:screte(varlist)} turns off the default categorization
of the variables in the varlist. Assuming continuous macro-level
variables to be the standard case, {it:regby} dichotomizes all the
macro-level variables by default. This automatic grouping is turned
off for all variables in the varlist. Note that the option allows
arbitrary groupings of the macro-level variables by feeding custom-made
variables into {it:discrete()}. See option {cmd:nquantiles()} for
other means to change the default categorization of macro-level
variables.

{phang}{opt reg:opts(options)} defines the appearance of the regression
lines. {it:options} can be any of the {help line options}. The line
options {cmd:lcolor()} and {cmd:lwidth()} may be particularly
useful.{p_end}

{phang}{opt nq:uantiles(#)} defines the number of groups created from
each of the macro-level variables. Assuming
continuous macro-level variables to be the standard case,
{it:regby} dichotimizes all the macro-level variables by
default. The option {it:nquantiles(#)} can be used to define the
number of groups to be created. Specifically, #
defines the number of quantiles by which the
macro-level variables are grouped. {cmd:nquantiles(4)}, for example, groups macro-level
variables into four groups using the 1st, 2nd, and 3rd
quartile. See option {cmd:disrete()} for other means to control
the grouping.{p_end}

{phang}{opt u:nitby(varlist)} allows additional grouping
based on micro-level variables. In presence of {it:microby()}, the
micro-level regression models are estimated separately for each
{it:combination} of the macro-level identifier and the variables
specified. The microby-variables are then also used for the definition
of the various sub-graphs.{p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker regbyexamples}
{title:regby examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || regby _b_hhinc gdppcap"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || regby _b_hhinc gdppcap urbanpop"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || regby _b_hhinc gdppcap, allopts(lcolor(none))"}{break}
removes the background graph.{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc age || regby _b_hhinc gdppcap, nq(4) microby(sex) byopts(cols(2)) ysize(8)"} {break}
demonstrates some flexibility.{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc age || regby _b_hhinc gdppcap eu15, nq(4) discrete(eu15) byopts(cols(2)) ysize(8)"} {break}
shows an example for the usage of option discrete.{p_end}

{marker mk2nd}
{title:Macro-level datasets}

{p 8 16 2}
 {cmd:twostep}
 {it:macroid}
 [ {cmd:, stats(}{it:name}{cmd:)} ]
 {cmd::} {it:microcmd} {depvar}
 {indepvars} [, {it:micro-options}] {cmd:||}
 {cmd:mk2nd}
 {help twostep##macrodepvar:macrodepvar} 
 [ {help twostep##macroindepvars:macroindepvars} ]
 [ {cmd:using} {help filename} ]
 [ {cmd:, clear} ]
{p_end}

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:twostep-options}
{synopt:{opt stats(namelist)}}Additional Stats for macro-level{p_end}
{syntab:micro-options}
{synopt:{it:model options}}Options allowed for {it:microcmd}{p_end}
{syntab:mk2nd-options}
{synopt:{cmd:clear}}Okay to replace the data in memory{p_end}
{synoptline}
{p2colreset}

{pstd} The terms of the command are defined as in the general syntax
above. {help twostep##macrodepvar:macrodepvar} is used to specify the
name of the coefficients to be stored. Here However, 
{it:macrodepvar} may also be {cmd:_all}, in which case all coefficients
and standard errors are stored. {help twostep##macroindepvars:macroindepvars} is used to specify the names
of macro-level variables to be stored. {p_end}

{marker mk2ndoptions}
{title:mk2nd options}

{phang}{opt stats(namelist)} defines the model statistics to be stored
together with the model coefficients. {it:names} can be any scalar
stored by the estimation command used for the micro-level
regression. To store the R-square of a
linear regression model, for example, use {cmd:stats(r2)}. {p_end}

{phang}{opt clear} specifies that it is okay to replace the data in
 memory, even though the current data have not been
 saved to disk.

{marker mk2ndexamples}
{title:mk2nd examples}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || mk2nd _b_hhinc gdppcap"}{break}
creates a macro-level dataset holding the (micro-level) estimated regression
coefficients of hhinc, their standard errors, the numbers of
observations, as well as the macro-level variable
gdppcap. {p_end}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || mk2nd _all gdppcap"}{break}
as before, but with all the micro-level regression
coefficients/standard errors. {p_end}

{phang}. {stata "use eqls2003_twostep, clear"}{p_end}
{phang}. {stata "twostep cntry, stats(r2 r2_a ll): regress lsat hhinc i.sex || mk2nd _all gdppcap"}{break}
as before, but including selected statistics of the micro-level regression models.{p_end}

{marker acknowledgments}
{title:Acknowledgements}

{pstd} We wish to thank Kekeli Abbey, Lena Hipp and Armin Sauermann
for beta testing. We are very gratefull to Stephen Jenkins, editor of
the Stata Journal, and to two anonymous reviewers for their rigourous
advices, which made the program much better. Ulrich Kohler wishes to
thank the participants of summer's 2017 and winter's 2020/21
multilevel seminar for commenting earlier versions of {cmd:twostep}.

{marker author}
{title:Authors}

{pstd}
Ulrich Kohler, University of Potsdam{break}
email: {browse "mailto:ukohler@uni-potsdam.de":ukohler@uni-potsdam.de}{break}
web: {browse "https://www.uni-potsdam.de/soziologie-methoden/":https://www.uni-potsdam.de/soziologie-methoden/}
{p_end}

{pstd}
Johannes Giesecke, Humboldt-University Berlin{break}
email: {browse "johannes.giesecke@hu-berlin.de":johannes.giesecke@hu-berlin.de"}
{break}
web: {browse "https://www.sowi.hu-berlin.de/de/lehrbereiche/empisoz/a-z/giesecke"}
{p_end}

{marker references}
{title:References}

{pstd} {marker achen05} Achen, C., 2005. Two-Step Hierarchical
Estimation: Beyond Regression Analysis. Political Analysis, 13,
447-456.

{pstd} {marker bowers05} Bowers, J. and K. Drake, 2005. EDA for
HLM: Visualization when Probabilistic Inference Fails. Political
Analysis, 13, 301-326.

{pstd} {marker bryan16}Bryan, M.L., and S. Jenkins, 2016. Multilevel Modeling of Country Effects: A
Cautionary Tale. Supplementary Material. European Sociological Review, 32(1), 3-22.

{pstd} {marker donald07}Donald, S.G., and K. Lang, 2008. Inference
with difference-in-difference and other panel data. Review of
Econometrics and Statistics, 89(2), 221-233.

{pstd} {marker hanushek74}Hanushek, E., 1974. Efficient Estimators for Regressing Regression Coefficients. The
American Statistician, 28(1), 66-67.

{pstd}{marker lewis05}Lewis, F.B. and D.A. Linzer, 2005. Estimating
Regression Model in Which the Dependent Variable is Based on
Estimates. Political Analysis, 13, 345-364.

{pstd} {marker saxonhouse76}Saxonhouse, G. R., 1976. Estimated Parameters as Dependent Variables. American
Economic Review, 66(1), 178-183.

